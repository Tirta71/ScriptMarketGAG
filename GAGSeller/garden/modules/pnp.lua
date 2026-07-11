--[[ pnp.lua — Pick & Place pet, SETELAH skill terkonfirmasi keluar.
     Remote (dari spy):
       pickup: PetsService:FireServer("UnequipPet", uuid)
       place : PetsService:FireServer("EquipPet", uuid, CFrame)  (posisi semula)
     Cooldown: PetCooldownsUpdated(uuid, { {Time=<detik>, Passive=<nama>}, ... }).
       - Passive yang mengandung "Mutation" DIABAIKAN (itu passive mutation, bukan skill).
     Flow baru:
       Place → tunggu skill fired (cooldown muncul) → pickupDelay → Pickup → equipDelay → Place → repeat ]]
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

	-- Deteksi apakah pet SUDAH menembakkan skill-nya (cooldown muncul dengan Time > 0).
	-- Ini kebalikan dari isReady: kita cari KONFIRMASI bahwa skill beneran keluar.
	local function hasSkillFired(uuid, petType)
		local cd = cdMap[uuid]
		if type(cd) ~= "table" then return false end

		local isMimic = tostring(petType):find("Mimic") ~= nil

		for _, entry in ipairs(cd) do
			local pas = tostring(entry.Passive or "")
			local t   = tonumber(entry.Time) or 0
			if not pas:find("Mutation") and t > 0 then
				-- Untuk pet Mimic, hanya deteksi cooldown bawaan "Mimicry"
				-- (abaikan cooldown skill copasan seperti "Rainbow Frilled Reptile")
				if isMimic then
					if pas == "Mimicry" then return true end
				else
					return true
				end
			end
		end
		return false
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

	-- Posisi placement. Model pet BISA hilang (low performance mode) -> FindLocalPetModel nil.
	-- Strategi: baca dari model kalau ada (sambil di-cache), else pakai cache terakhir,
	-- else fallback ke PetArea kebun sendiri, terakhir posisi player.
	local lastPos = {}
	local LP = ctx.LP

	local function playerPos()
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local RS = game:GetService("ReplicatedStorage")
	local GetFarm = require(RS.Modules.GetFarm)

	-- Cache posisi PERTAMA yang kebaca dan JANGAN ditimpa -> pet selalu balik ke spot asli
	-- (bukan spot hasil PNP), biar nggak drift ngumpul ke player.
	local function getPos(uuid)
		if lastPos[uuid] then return lastPos[uuid] end
		if PU then
			local ok, model = pcall(function() return PU:FindLocalPetModel(uuid) end)
			if ok and model and typeof(model) == "Instance" then
				local okc, cf = pcall(function() return model:GetPivot() end)
				if okc then lastPos[uuid] = cf.Position; return cf.Position end
			end
		end
		-- Fallback 1: Pusat PetArea kebun kita sendiri (garansi 100% aman di dalam kebun)
		local farm = GetFarm and GetFarm(LP)
		local petArea = farm and farm:FindFirstChild("PetArea")
		if petArea then
			return petArea.Position
		end
		-- Fallback 2: Posisi player
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

					-- CEK: Apakah pet ini sudah nge-skill? (cooldown muncul = skill terkonfirmasi keluar)
					if hasSkillFired(p.uuid, p.petType) then
						didAny = true

						-- 1) Tunggu pickupDelay (biar skill selesai animasinya dulu)
						if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end
						if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

						-- 2) PICKUP (cabut pet dari tanah)
						local pos = getPos(p.uuid) -- simpan posisi SEBELUM cabut
						pcall(function() PetsService:FireServer("UnequipPet", p.uuid) end)

						-- 3) Tunggu equipDelay
						task.wait(math.max(0.01, CFG.equipDelay))

						-- 4) PLACE (taruh pet kembali ke posisi semula)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", p.uuid, CFrame.new(pos)) end)
						end
					end
				end
				setStatus(("PNP jalan: %d pet%s"):format(#pets, didAny and "" or " (nunggu skill keluar)"))
				task.wait(0.15)  -- poll interval
			end
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
	-- stop cukup set CFG.pnpEnabled=false
end

