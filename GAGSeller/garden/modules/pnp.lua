--[[ pnp.lua — Pick & Place pet, SETELAH skill terkonfirmasi keluar.
     Deteksi hybrid:
       1. GameEvents.Notification → notif teks dari server saat pet nge-skill
       2. PetCooldownsUpdated     → konfirmasi UUID spesifik mana yang cooldown-nya aktif
     Flow:
       Pet sudah di tanah → tunggu notif skill + cooldown muncul
       → pickupDelay → Pickup → equipDelay → Place → repeat ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local PU          = ctx.deps.PU
	local PetCD       = ctx.deps.PetCooldownsUpdated
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	----------------------------------------------------------------- cooldown tracking
	-- cdMap[uuid] = array {Time, Passive} terbaru dari server.
	local cdMap = {}
	if PetCD then
		PetCD.OnClientEvent:Connect(function(uuid, cd)
			if type(uuid) == "string" then cdMap[uuid] = cd end
		end)
	end

	----------------------------------------------------------------- skill notification tracking
	-- skillNotifAt[petType] = os.clock() terakhir kali notif skill untuk tipe pet ini diterima.
	-- lastPlacedAt[uuid] = os.clock() saat kita terakhir menaruh pet ini (EquipPet).
	local skillNotifAt = {}
	local lastPlacedAt = {}

	local RS = game:GetService("ReplicatedStorage")
	local NotifEvent = RS:WaitForChild("GameEvents"):FindFirstChild("Notification")
	if NotifEvent then
		NotifEvent.OnClientEvent:Connect(function(text)
			if type(text) ~= "string" then return end
			-- Filter: hanya tangkap notif yang berkaitan dengan skill pet
			-- Contoh: "Mimic Octopus copied ...", "Rainbow Dilophosaurus spat venom and granted 6000 XP ..."
			if text:find("granted") or text:find("copied") or text:find("advancing") then
				-- Cocokkan nama tipe pet dari daftar target PNP
				for petType, _ in pairs(CFG.pnpPetTypes) do
					if text:find(petType, 1, true) then
						skillNotifAt[petType] = os.clock()
					end
				end
				-- Jika filter pnpPetTypes kosong (semua pet), cocokkan dari pet yang sedang equipped
				if not next(CFG.pnpPetTypes) then
					local ok, d = pcall(function() return DataService:GetData() end)
					if ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data then
						for _, petData in pairs(d.PetsData.PetInventory.Data) do
							local pt = petData.PetType
							if pt and text:find(pt, 1, true) then
								skillNotifAt[pt] = os.clock()
							end
						end
					end
				end
			end
		end)
	end

	----------------------------------------------------------------- detection
	-- Cek apakah UUID ini punya cooldown aktif (non-mutation, non-copied-for-mimic)
	local function hasCooldownActive(uuid, petType)
		local cd = cdMap[uuid]
		if type(cd) ~= "table" then return false end
		local isMimic = tostring(petType):find("Mimic") ~= nil
		for _, entry in ipairs(cd) do
			local pas = tostring(entry.Passive or "")
			local t   = tonumber(entry.Time) or 0
			if not pas:find("Mutation") and t > 0 then
				if isMimic then
					if pas == "Mimicry" then return true end
				else
					return true
				end
			end
		end
		return false
	end

	-- HYBRID: Konfirmasi skill sudah keluar lewat notifikasi + cooldown UUID.
	local function hasSkillFired(uuid, petType)
		-- Cek cooldown per UUID (wajib, ini konfirmasi UUID spesifik)
		if not hasCooldownActive(uuid, petType) then return false end

		-- Jika kita belum pernah menaruh pet ini sendiri (initial state saat script start),
		-- cukup cek cooldown saja (pet sudah di tanah dari awal, langsung bisa di-PNP).
		local placed = lastPlacedAt[uuid]
		if not placed then return true end

		-- Jika sudah pernah ditaruh oleh kita, butuh konfirmasi notifikasi skill
		-- yang datang SETELAH kita menaruh pet ini terakhir kali.
		local notif = skillNotifAt[petType] or 0
		return notif > placed
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

					-- CEK HYBRID: Notifikasi skill + cooldown UUID terkonfirmasi?
					if hasSkillFired(p.uuid, p.petType) then
						didAny = true

						-- 1) Tunggu pickupDelay (biar skill selesai efeknya)
						if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end
						if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

						-- 2) PICKUP (cabut pet dari tanah)
						local pos = getPos(p.uuid)
						pcall(function() PetsService:FireServer("UnequipPet", p.uuid) end)

						-- 3) Tunggu equipDelay
						task.wait(math.max(0.01, CFG.equipDelay))

						-- 4) PLACE (taruh pet kembali ke posisi semula)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", p.uuid, CFrame.new(pos)) end)
						end

						-- 5) Catat waktu penempatan untuk deteksi notif berikutnya
						lastPlacedAt[p.uuid] = os.clock()
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


