--[[ pnp.lua — Pick & Place pet, SETELAH skill terkonfirmasi keluar.
     Deteksi via:
       1. Cooldown transition (0 ke > 0) -> Sempurna untuk Ferret & backup pet lain.
       2. HighlightRemote (tipe 3)        -> Sinyal backup untuk pet lain.
     Flow:
       Targets dikunci dari equipped pets saat start (berdasarkan UUID backpack).
       Jika pet target terlepas ke backpack -> otomatis dipasang kembali (Self-Healing).
       Jika pet target mengeluarkan skill -> unequip-equip (Ferret delay 0.01s agar NO ANIMASI). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local PU          = ctx.deps.PU
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")

	----------------------------------------------------------------- skill detection & transitions
	local skillFiredAt = {}
	local lastPlacedAt = {}
	local lastCD = {} -- Menyimpan data detik sebelumnya untuk mendeteksi transisi

	-- Sinyal 1: Deteksi perubahan cooldown dari 0 ke Non-Zero (Sempurna untuk Ferret)
	local cdMap = {}
	local PetCD = ctx.deps.PetCooldownsUpdated
	if PetCD then
		PetCD.OnClientEvent:Connect(function(uuid, cd)
			if type(uuid) ~= "string" or type(cd) ~= "table" then return end
			
			local prev = lastCD[uuid] or {}
			local current = {}
			
			for _, entry in ipairs(cd) do
				local pas = tostring(entry.Passive or "")
				local t = tonumber(entry.Time) or 0
				
				if not pas:find("Mutation") then
					current[pas] = t
					local prevTime = prev[pas] or 0
					-- Transisi dari <= 0 ke > 0 = skill baru ditembakkan!
					if prevTime <= 0 and t > 0 then
						skillFiredAt[uuid] = os.clock()
					end
				end
			end
			lastCD[uuid] = current
			cdMap[uuid] = cd
		end)
	end

	-- Sinyal 2: HighlightRemote (Lampu sorot dari server)
	local HighlightRemote = RS:WaitForChild("GameEvents"):FindFirstChild("HighlightRemote")
	if HighlightRemote then
		HighlightRemote.OnClientEvent:Connect(function(petInstance, highlightType)
			if highlightType ~= 3 then return end
			if typeof(petInstance) ~= "Instance" then return end
			
			local uuid = petInstance.Name
			if not uuid:match("^{") then
				uuid = petInstance:GetAttribute("UUID") or petInstance.Name
			end
			
			if type(uuid) == "string" and #uuid > 0 then
				skillFiredAt[uuid] = os.clock()
			end
		end)
	end

	-- Apakah pet ini sudah nge-skill SETELAH terakhir kali ditaruh?
	local function hasSkillFired(uuid)
		local fired = skillFiredAt[uuid]
		if not fired then return false end

		-- Jika belum pernah ditaruh oleh kita (initial state), cukup cek ada fired
		local placed = lastPlacedAt[uuid]
		if not placed then return true end

		-- Jika sudah ditaruh, fired harus SETELAH placed
		return fired > placed
	end

	----------------------------------------------------------------- dynamic pickup delay
	local function getPickupDelay(uuid, petType)
		local pt = tostring(petType)
		
		-- 1) Mimic pet: cek jika meniru skill berdurasi lama (Peacock/Dilo)
		if pt:find("Mimic") then
			local cd = cdMap[uuid]
			if type(cd) == "table" then
				for _, entry in ipairs(cd) do
					local pas = tostring(entry.Passive or "")
					if pas:find("Frilled") or pas:find("Beauty") or pas:find("Spat") then
						return 1.5 -- Tunggu biar animasi & efek fanning/venom selesai
					end
				end
			end
		end

		-- 2) Peacock / Dilophosaurus / Swan: butuh animasi selesai agar efeknya mendarat
		if pt:find("Peacock") or pt:find("Dilophosaurus") or pt:find("Swan") then
			return 1.5
		end
		
		-- 3) French Fry Ferret / Thieving Ferret: instant unequip untuk skip visual animasi masak/jumping!
		if pt:find("Ferret") then
			return 0.01
		end
		
		-- Default dari GUI
		return CFG.pickupDelay or 0.4
	end

	----------------------------------------------------------------- targets & equipping helpers
	local function getTargetUUIDs()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		for _, uuid in ipairs(eq) do
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(CFG.pnpPetTypes)) or (pt and CFG.pnpPetTypes[pt]) then
				out[uuid] = pt or "Unknown"
			end
		end
		return out
	end

	local function isPetEquipped(uuid)
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return false end
		local eq = d.PetsData and d.PetsData.EquippedPets
		if not eq then return false end
		for _, u in ipairs(eq) do
			if u == uuid then return true end
		end
		return false
	end

	-- Posisi placement. Cache posisi asli pet agar tidak drift.
	local lastPos = {}
	local LP = ctx.LP

	local function playerPos()
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local GetFarm = require(RS.Modules.GetFarm)

	local function getPos(uuid)
		if lastPos[uuid] then return lastPos[uuid] end
		if PU then
			local ok, model = pcall(function() return PU:FindLocalPetModel(uuid) end)
			if ok and model and typeof(model) == "Instance" then
				local okc, cf = pcall(function() return model:GetPivot() end)
				if okc then lastPos[uuid] = cf.Position; return cf.Position end
			end
		end
		local farm = GetFarm and GetFarm(LP)
		local petArea = farm and farm:FindFirstChild("PetArea")
		if petArea then return petArea.Position end
		return playerPos()
	end

	----------------------------------------------------------------- loop
	local function pnpLoop()
		ctx.state.pnpId = (ctx.state.pnpId or 0) + 1
		local myId = ctx.state.pnpId
		ctx.elevate()

		-- Kunci target pet saat start loop
		local targets = getTargetUUIDs()

		-- Kumpulkan nama pet unik untuk status GUI
		local uniqueNames = {}
		for _, petType in pairs(targets) do
			uniqueNames[petType] = true
		end
		local nameList = {}
		for name, _ in pairs(uniqueNames) do
			table.insert(nameList, name)
		end
		local petNamesStr = #nameList > 0 and table.concat(nameList, ", ") or "tidak ada"

		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			local targetCount = 0
			for _ in pairs(targets) do targetCount = targetCount + 1 end

			if targetCount == 0 then
				setStatus("PNP: tidak ada pet target (equip pet dulu)")
				task.wait(1)
			else
				local didAny = false
				for uuid, petType in pairs(targets) do
					if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

					local equipped = isPetEquipped(uuid)
					if not equipped then
						-- 🚨 SELF-HEALING: Pasang kembali pet ke kebun jika nyangkut di backpack
						local pos = getPos(uuid)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						end
						task.wait(0.2)
					else
						-- Cek apakah skill terkonfirmasi aktif
						if hasSkillFired(uuid) then
							didAny = true

							-- 1) Tunggu pickupDelay dinamis berdasarkan tipe pet (Dilo/Peacock vs Ferret)
							local delay = getPickupDelay(uuid, petType)
							if delay > 0 then task.wait(delay) end
							if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

							-- 2) PICKUP (cabut pet)
							local pos = getPos(uuid)
							pcall(function() PetsService:FireServer("UnequipPet", uuid) end)

							-- 3) Tunggu equipDelay
							task.wait(math.max(0.01, CFG.equipDelay))

							-- 4) PLACE (taruh pet kembali)
							if pos then
								pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
							end

							-- 5) Catat waktu penempatan
							lastPlacedAt[uuid] = os.clock()
						end
					end
				end
				setStatus(("PNP (%s)%s"):format(petNamesStr, didAny and "" or " (nunggu skill)"))
				task.wait(0.15)
			end
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
	-- stop cukup set CFG.pnpEnabled=false
end



