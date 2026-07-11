--[[ pnp.lua — Pick & Place pet, cuma saat skill utama READY.
     Remote (dari spy):
       pickup: PetsService:FireServer("UnequipPet", uuid)
       place : PetsService:FireServer("EquipPet", uuid, cframeString)  (posisi semula)
     Cooldown: PetCooldownsUpdated(uuid, { {Time=<detik>, Passive=<nama>}, ... }).
       - Passive yang mengandung "Mutation" DIABAIKAN (itu passive mutation, bukan skill).
       - Pet READY kalau tidak ada passive non-mutation dengan Time > 0. ]]
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

	-- ready = tidak ada passive NON-mutation yang masih Time > 0
	local function isReady(uuid)
		local cd = cdMap[uuid]
		if type(cd) ~= "table" then return true end   -- belum ada info -> anggap ready
		for _, entry in ipairs(cd) do
			local pas = tostring(entry.Passive or "")
			if not pas:find("Mutation") and (tonumber(entry.Time) or 0) > 0 then
				return false
			end
		end
		return true
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

	-- posisi pet sekarang (buat naruh balik di tempat semula)
	local function getPos(uuid)
		if not PU then return nil end
		local ok, model = pcall(function() return PU:FindLocalPetModel(uuid) end)
		if ok and model and typeof(model) == "Instance" then
			local okc, cf = pcall(function() return model:GetPivot() end)
			if okc then return cf.Position end
		end
		return nil
	end

	-- pick & place 1 pet, lalu tunggu sampai cooldown mulai lagi (biar nggak dobel pungut)
	-- PENTING: EquipPet butuh objek CFrame (bukan string), rotasi identity, posisi dalam PetArea.
	local function pnpOne(uuid)
		if not PetsService then return false end
		local pos = getPos(uuid)
		if not pos then return false end
		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
		task.wait(math.max(0, CFG.equipDelay))
		pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
		-- tunggu skill jalan lagi (cooldown muncul) supaya loop nggak langsung pick up lagi
		local t0 = os.clock()
		repeat task.wait(0.1) until (not isReady(uuid)) or (os.clock() - t0) > 2.5
		return true
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
					if isReady(p.uuid) then
						didAny = true
						if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end  -- jeda saat skill ready
						if not CFG.pnpEnabled then break end
						pnpOne(p.uuid)
					end
				end
				setStatus(("PNP jalan: %d pet%s"):format(#pets, didAny and "" or " (nunggu skill ready)"))
				task.wait(0.15)  -- poll interval saat semua masih cooldown
			end
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
	-- stop cukup set CFG.pnpEnabled=false
end
