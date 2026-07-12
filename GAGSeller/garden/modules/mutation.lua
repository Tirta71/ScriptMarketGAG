--[[ mutation.lua — logika mesin mutasi pet otomatis (garden). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")
	local TimeHelper  = require(RS.Modules.TimeHelper)
	local PetMutationMachineService_RE = RS:WaitForChild("GameEvents").PetMutationMachineService_RE

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		local offX = (col - (GRID_COLS - 1) / 2) * GRID_SP
		local offZ = (row - 1) * GRID_SP
		return center + Vector3.new(offX, 0, offZ)
	end

	ctx.state.mutationStatus = "Idle"
	ctx.state.mutationPhase = "Idle"

	-- Mendapatkan ringkasan statistik mutation untuk UI
	function ctx.getMutationSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local machine = ok and d and d.PetMutationMachine or {}

		local expCount = 0
		for _ in pairs(CFG.mutationExpTeam) do expCount = expCount + 1 end

		local boostCount = 0
		for _ in pairs(CFG.mutationBoostTeam) do boostCount = boostCount + 1 end

		local phoenixCount = 0
		for _ in pairs(CFG.mutationPhoenixTeam) do phoenixCount = phoenixCount + 1 end

		local typesList = {}
		for k in pairs(CFG.mutationTargetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"

		local mutsList = {}
		for k in pairs(CFG.mutationTargetMutations) do table.insert(mutsList, k) end
		table.sort(mutsList)
		local mutsStr = #mutsList > 0 and table.concat(mutsList, ", ") or "None"

		local targetAge = CFG.mutationTargetAge or 50

		-- Info mesin
		local machineStr = "Empty"
		if machine.SubmittedPet then
			local pt = machine.SubmittedPet.PetType or "?"
			local mut = machine.SubmittedPet.PetData and machine.SubmittedPet.PetData.MutationType or "Normal"
			local mutName = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mut) or mut
			machineStr = string.format("%s | %s", pt, mutName)
			if machine.PetReady then
				machineStr = machineStr .. " [Ready]"
			elseif machine.IsRunning or (machine.TimeLeft and machine.TimeLeft > 0) then
				local v2 = TimeHelper:GenerateColonFormatFromTime(machine.TimeLeft) or "00:00"
				machineStr = machineStr .. string.format(" [CD: %s]", v2)
			end
		end

		local readyCount = 0
		local doneCount = 0

		for _, v in pairs(inv) do
			local pt = v.PetType
			if CFG.mutationTargetTypes[pt] then
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"

				-- ready: level >= targetAge, dan belum termutasi target (atau Normal)
				if lvl >= targetAge and (mut == "Normal" or mut == "None" or mut == "") then
					readyCount = readyCount + 1
				end

				-- done: memiliki mutasi yang kita inginkan
				if CFG.mutationTargetMutations[mut] then
					doneCount = doneCount + 1
				end
			end
		end

		return {
			status = CFG.mutationEnabled and "ACTIVE" or "STOPPED",
			phase = ctx.state.mutationPhase or "Idle",
			expCount = expCount,
			boostCount = boostCount,
			phoenixCount = phoenixCount,
			types = typesStr,
			mutations = mutsStr,
			targetAge = targetAge,
			machine = machineStr,
			readyCount = readyCount,
			doneCount = doneCount,
		}
	end

	local function checkMutation()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		local machine = d.PetMutationMachine
		if not petsData or not machine then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local expTeam = CFG.mutationExpTeam or {}
		local boostTeam = CFG.mutationBoostTeam or {}
		local phoenixTeam = CFG.mutationPhoenixTeam or {}
		local targetTypes = CFG.mutationTargetTypes or {}
		local targetMutations = CFG.mutationTargetMutations or {}
		local targetAge = CFG.mutationTargetAge or 50
		local delayClaim = CFG.mutationDelayAutoClaim or 0.5

		-- Lacak status equip secara lokal agar kebal dari delay replikasi server
		local localEq = {}
		local localEqCount = 0
		for _, uuid in ipairs(eq) do
			localEq[uuid] = true
			localEqCount = localEqCount + 1
		end

		-- A. DETEKSI APAKAH PET READY UNTUK DICLAIM
		if machine.PetReady then
			ctx.state.mutationPhase = "Claiming Pet"
			
			-- 1. Cabut semua pet non-phoenix team
			for _, uuid in ipairs(eq) do
				if not phoenixTeam[uuid] then
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil
					localEqCount = localEqCount - 1
					task.wait(0.2)
				end
			end
			
			-- 2. Pasang phoenix team
			for uuid, _ in pairs(phoenixTeam) do
				if not localEq[uuid] then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						localEq[uuid] = true
						localEqCount = localEqCount + 1
						task.wait(0.25)
					end
				end
			end
			
			-- 3. Tunggu delay klaim
			task.wait(delayClaim)
			
			-- 4. Kirim remote klaim
			pcall(function() PetMutationMachineService_RE:FireServer("ClaimMutatedPet") end)
			task.wait(0.8)

			-- 5. Cek apakah pet hasil klaim memiliki mutasi target
			local ok3, d3 = pcall(function() return DataService:GetData() end)
			if ok3 and d3 and d3.PetsData then
				local newInv = d3.PetsData.PetInventory and d3.PetsData.PetInventory.Data or {}
				for uuid, v in pairs(newInv) do
					local pt = v.PetType
					local pd = v.PetData or {}
					local mut = pd.MutationType or "Normal"
					if targetTypes[pt] and targetMutations[mut] then
						ctx.state.mutationPhase = "Finished"
						CFG.mutationEnabled = false
						ctx.persistState()
						if ctx.state.mutationToggleRender then
							pcall(ctx.state.mutationToggleRender)
						end
						break
					end
				end
			end
			return
		end

		-- B. DETEKSI APAKAH MESIN SEDANG BERJALAN
		if machine.IsRunning or (machine.TimeLeft and machine.TimeLeft > 0) then
			ctx.state.mutationPhase = "Boosting Machine"
			
			-- 1. Cabut semua pet non-boost team
			for _, uuid in ipairs(eq) do
				if not boostTeam[uuid] then
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil
					localEqCount = localEqCount - 1
					task.wait(0.2)
				end
			end
			
			-- 2. Pasang boost team
			for uuid, _ in pairs(boostTeam) do
				if not localEq[uuid] then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						localEq[uuid] = true
						localEqCount = localEqCount + 1
						task.wait(0.25)
					end
				end
			end
			return
		end

		-- C. DETEKSI PET SUDAH DI-SUBMIT TETAPI BELUM DI-START
		if machine.SubmittedPet and not machine.IsRunning then
			ctx.state.mutationPhase = "Starting Machine"
			pcall(function() PetMutationMachineService_RE:FireServer("StartMachine") end)
			task.wait(0.5)
			return
		end

		-- D. DETEKSI MESIN KOSONG: Cari pet dari inventory untuk dimasukkan ke mesin
		if not machine.SubmittedPet then
			-- Cari pet target yang siap (level >= targetAge)
			local candidateUuid, candidateType
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"

				-- Hanya pet tipe target, dengan level >= targetAge, dan belum memiliki salah satu targetMutations (atau Normal saja)
				if targetTypes[pt] and lvl >= targetAge and (mut == "Normal" or mut == "None" or mut == "") then
					candidateUuid = uuid
					candidateType = pt
					break
				end
			end

			-- Jika ada pet yang siap, submit ke mesin!
			if candidateUuid then
				ctx.state.mutationPhase = "Submitting Target"
				
				-- 1. Cari tool pet tersebut di Backpack atau Character
				local targetTool
				for _, item in ipairs(LP.Backpack:GetChildren()) do
					if item:IsA("Tool") and item:GetAttribute("PET_UUID") == candidateUuid then
						targetTool = item
						break
					end
				end
				if not targetTool and LP.Character then
					for _, item in ipairs(LP.Character:GetChildren()) do
						if item:IsA("Tool") and item:GetAttribute("PET_UUID") == candidateUuid then
							targetTool = item
							break
						end
					end
				end

				-- 2. Equip tool pet tersebut ke tangan
				if targetTool then
					targetTool.Parent = LP.Character
					task.wait(0.5)
					pcall(function() PetMutationMachineService_RE:FireServer("SubmitHeldPet") end)
					task.wait(0.5)
				end
				return
			end

			-- Jika tidak ada pet yang siap, cari pet target yang levelnya kurang untuk kita LEVELING!
			local levelUuid, levelType, levelLvl
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"

				if targetTypes[pt] and lvl < targetAge and (mut == "Normal" or mut == "None" or mut == "") then
					-- Prioritaskan level yang paling tinggi tapi masih di bawah targetAge agar cepat jadi!
					if not levelLvl or lvl > levelLvl then
						levelUuid = uuid
						levelType = pt
						levelLvl = lvl
					end
				end
			end

			-- Jika ada pet yang perlu di-leveling:
			if levelUuid then
				ctx.state.mutationPhase = "Leveling Target"
				
				-- Kita ingin memasang:
				-- 1) Target pet tersebut
				-- 2) Seluruh expTeam
				local targetActive = {}
				targetActive[levelUuid] = true
				for uuid, _ in pairs(expTeam) do
					targetActive[uuid] = true
				end

				-- Lepas pet yang tidak ada di targetActive
				for _, uuid in ipairs(eq) do
					if not targetActive[uuid] then
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						localEqCount = localEqCount - 1
						task.wait(0.2)
					end
				end

				-- Pasang target pet + expTeam
				-- Pasang target pet dulu
				if not localEq[levelUuid] then
					local pos = getPos(levelUuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", levelUuid, CFrame.new(pos)) end)
						localEq[levelUuid] = true
						localEqCount = localEqCount + 1
						task.wait(0.25)
					end
				end

				-- Pasang expTeam
				for uuid, _ in pairs(expTeam) do
					if not localEq[uuid] then
						local pos = getPos(uuid)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
							localEq[uuid] = true
							localEqCount = localEqCount + 1
							task.wait(0.25)
						end
					end
				end
				return
			end

			-- Jika sama sekali tidak ada pet kandidat
			ctx.state.mutationPhase = "Idle (No Targets)"
		end
	end

	local function mutationLoop()
		ctx.state.mutationId = (ctx.state.mutationId or 0) + 1
		local myId = ctx.state.mutationId
		ctx.elevate()

		while CFG.mutationEnabled and ctx.alive() and ctx.state.mutationId == myId do
			pcall(checkMutation)
			task.wait(3.0)
		end
		ctx.state.mutationStatus = "Idle"
		ctx.state.mutationPhase = "Idle"
	end

	function ctx.startMutation() task.spawn(mutationLoop) end
end
