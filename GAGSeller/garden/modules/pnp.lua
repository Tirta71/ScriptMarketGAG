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
	local function isReady(uuid, petType)
		local cd = cdMap[uuid]
		if type(cd) ~= "table" then return true end   -- belum ada info -> anggap ready
		
		-- Deteksi tipe pet Mimic
		local isMimic = tostring(petType):find("Mimic") ~= nil
		
		for _, entry in ipairs(cd) do
			local pas = tostring(entry.Passive or "")
			if not pas:find("Mutation") and (tonumber(entry.Time) or 0) > 0 then
				-- Jika pet Mimic, abaikan cooldown selain "Mimicry" (abaikan skill hasil copy)
				if isMimic and pas ~= "Mimicry" then
					-- Abaikan cooldown skill copasan
				else
					return false
				end
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

	-- Posisi placement. Model pet BISA hilang (low performance mode) -> FindLocalPetModel nil.
	-- Strategi: baca dari model kalau ada (sambil di-cache), else pakai cache terakhir,
	-- else fallback ke posisi player (pasti di dalam PetArea saat main di farm sendiri).
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

	-- pick & place 1 pet, lalu tunggu sampai cooldown mulai lagi (biar nggak dobel pungut)
	-- PENTING: EquipPet butuh objek CFrame (bukan string), rotasi identity, posisi dalam PetArea.
	local function pnpOne(uuid, petType)
		if not PetsService then return false end
		local pos = getPos(uuid)  -- ambil SEBELUM unequip
		if not pos then return false end
		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
		task.wait(math.max(0, CFG.equipDelay))
		pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
		
		-- JEDA REPLIKASI: Tunggu server memproses equip & memicu skill sebelum cek cooldown
		task.wait(0.5)
		
		-- tunggu skill jalan lagi (cooldown muncul) supaya loop nggak langsung pick up lagi
		local t0 = os.clock()
		repeat task.wait(0.1) until (not isReady(uuid, petType)) or (os.clock() - t0) > 2.0
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
					if isReady(p.uuid, p.petType) then
						didAny = true
						if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end  -- jeda saat skill ready
						if not CFG.pnpEnabled then break end
						pnpOne(p.uuid, p.petType)
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
