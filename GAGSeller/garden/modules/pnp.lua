--[[ pnp.lua — Pick & Place pet, SETELAH skill terkonfirmasi keluar.
     Deteksi via HighlightRemote:
       Server mengirim HighlightRemote(petInstance, 3) saat pet nge-skill.
       Arg[1] = Instance pet (Name = UUID), Arg[2] = 3 (skill activation).
       Ini sinyal paling awal & paling pasti: fire SEBELUM Notification & Cooldown.
     Flow:
       Pet di tanah → HighlightRemote(UUID, 3) terkonfirmasi
       → pickupDelay → Pickup → equipDelay → Place → repeat ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local PU          = ctx.deps.PU
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")

	----------------------------------------------------------------- skill detection via HighlightRemote
	-- skillFiredAt[uuid] = os.clock() saat HighlightRemote(petInstance, 3) diterima.
	-- lastPlacedAt[uuid] = os.clock() saat kita terakhir menaruh pet ini (EquipPet).
	local skillFiredAt = {}
	local lastPlacedAt = {}
	local cdMap = {}
	local ferretWasReady = {} -- Menandai Ferret yang cooldown-nya sudah 0 (Ready)

	-- Monitor cooldown untuk mendeteksi status "Ready" pada Ferret
	local PetCD = ctx.deps.PetCooldownsUpdated
	if PetCD then
		PetCD.OnClientEvent:Connect(function(uuid, cd)
			if type(uuid) == "string" then 
				cdMap[uuid] = cd 
				
				-- Cek apakah cooldown Friendly Frier milik Ferret sudah 0 (Ready)
				local isReady = true
				for _, entry in ipairs(cd) do
					if tostring(entry.Passive):find("Frier") and (tonumber(entry.Time) or 0) > 0 then
						isReady = false
						break
					end
				end
				if isReady then
					ferretWasReady[uuid] = true -- Tandai READY!
				end
			end
		end)
	end

	local HighlightRemote = RS:WaitForChild("GameEvents"):FindFirstChild("HighlightRemote")
	if HighlightRemote then
		HighlightRemote.OnClientEvent:Connect(function(petInstance, highlightType)
			-- Filter: hanya skill activation (type 3)
			if highlightType ~= 3 then return end
			if typeof(petInstance) ~= "Instance" then return end

			-- Ambil UUID dari nama Instance (format: "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}")
			local uuid = petInstance.Name
			if not uuid:match("^{") then
				-- Fallback: cek atribut UUID
				uuid = petInstance:GetAttribute("UUID") or petInstance.Name
			end

			if type(uuid) == "string" and #uuid > 0 then
				skillFiredAt[uuid] = os.clock()
			end
		end)
	end

	-- Apakah pet ini sudah nge-skill SETELAH terakhir kali ditaruh?
	local function hasSkillFired(uuid, petType)
		local fired = skillFiredAt[uuid]
		if not fired then return false end

		-- KHUSUS FERRET: Harus berstatus READY dulu sebelum boleh di-PNP
		if tostring(petType):find("Ferret") then
			if not ferretWasReady[uuid] then 
				return false -- Abaikan jika belum ready (menghindari spam pas baru spawn)
			end
		end

		-- Jika belum pernah ditaruh oleh kita (initial state), cukup cek ada fired
		local placed = lastPlacedAt[uuid]
		if not placed then return true end

		-- Jika sudah ditaruh, fired harus SETELAH placed
		return fired > placed
	end

	----------------------------------------------------------------- helpers
	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		for _, uuid in ipairs(eq) do
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(CFG.pnpPetTypes)) or (pt and CFG.pnpPetTypes[pt]) then
				out[#out + 1] = { uuid = uuid, petType = pt }
			end
		end
		return out
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
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP: tidak ada pet target (equip pet dulu)")
				task.wait(1)
			else
				local didAny = false
				for _, p in ipairs(pets) do
					if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

					-- CEK: HighlightRemote(UUID, 3) sudah diterima = skill PASTI keluar
					if hasSkillFired(p.uuid, p.petType) then
						didAny = true

						-- 1) Jeda cabut dinamis: Ferret 0.01s (NO ANIMASI), pet lain normal
						local delay = tostring(p.petType):find("Ferret") and 0.01 or CFG.pickupDelay
						if delay > 0 then task.wait(delay) end
						if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

						-- 2) PICKUP (cabut pet)
						local pos = getPos(p.uuid)
						pcall(function() PetsService:FireServer("UnequipPet", p.uuid) end)

						-- 3) Tunggu equipDelay
						task.wait(math.max(0.01, CFG.equipDelay))

						-- 4) PLACE (taruh pet kembali)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", p.uuid, CFrame.new(pos)) end)
						end

						-- 5) Catat waktu penempatan
						lastPlacedAt[p.uuid] = os.clock()

						-- 6) Reset status ready khusus Ferret
						if tostring(p.petType):find("Ferret") then
							ferretWasReady[p.uuid] = false
						end
					end
				end
				setStatus(("PNP jalan: %d pet%s"):format(#pets, didAny and "" or " (nunggu skill keluar)"))
				task.wait(0.15)
			end
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
	-- stop cukup set CFG.pnpEnabled=false
end



