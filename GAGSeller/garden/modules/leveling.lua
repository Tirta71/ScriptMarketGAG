--[[ leveling.lua — logika leveling pet otomatis (garden). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")

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

	ctx.state.levelingStatus = "Idle"

	-- Mendapatkan ringkasan statistik leveling untuk UI
	function ctx.getLevelingSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		
		local teamCount = 0
		for _ in pairs(CFG.levelingTeamUuids) do teamCount = teamCount + 1 end
		
		local typesList = {}
		for k in pairs(CFG.levelingPetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"
		
		local readyCount = 0
		local maxLvlCount = 0
		local targetLvl = CFG.levelingTargetLevel or 500
		
		for _, v in pairs(inv) do
			local pt = v.PetType
			if CFG.levelingPetTypes[pt] then
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				if lvl < targetLvl then
					readyCount = readyCount + 1
				else
					maxLvlCount = maxLvlCount + 1
				end
			end
		end
		
		return {
			status = CFG.levelingEnabled and "ACTIVE" or "STOPPED",
			team = string.format("%d pets selected", teamCount),
			types = typesStr,
			ready = string.format("%d pets", readyCount),
			maxLvl = string.format("%d pets", maxLvlCount),
			maxInGarden = string.format("%d pets", CFG.levelingMaxPets or 2),
			targetLevel = tostring(targetLvl),
		}
	end

	-- Mendapatkan semua tipe unik pet yang dimiliki di inventory
	function ctx.getInventoryPetTypes()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not inv then return out end
		
		local seen = {}
		for _, v in pairs(inv) do
			local pt = v.PetType
			if pt and not seen[pt] then
				seen[pt] = true
				table.insert(out, { value = pt, display = pt })
			end
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		return out
	end

	local function checkLeveling()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local teamSet = CFG.levelingTeamUuids or {}
		local targetTypes = CFG.levelingPetTypes or {}
		local targetLvl = CFG.levelingTargetLevel or 500
		local maxLvlPets = CFG.levelingMaxPets or 2

		-- Lacak status equip secara lokal agar kebal dari delay replikasi server
		local localEq = {}
		local localEqCount = 0
		for _, uuid in ipairs(eq) do
			localEq[uuid] = true
			localEqCount = localEqCount + 1
		end

		-- A. DETEKSI FIRST RUN: Cabut semua pet jika ada pet aktif
		if ctx.state.levelingFirstRun then
			ctx.state.levelingFirstRun = false
			if #eq > 0 then
				ctx.state.levelingStatus = "Resetting garden..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil
					localEqCount = localEqCount - 1
					task.wait(0.25)
				end
			end
		end

		-- B. DETEKSI PERSISTENSI TEAM: Pasang kembali pet team yang dicabut oleh user/game
		for uuid, _ in pairs(teamSet) do
			if not localEq[uuid] then
				ctx.state.levelingStatus = "Re-equipping team..."
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[uuid] = true
					localEqCount = localEqCount + 1
					task.wait(0.3)
				end
			end
		end

		-- C. KLASIFIKASI PET YANG SEDANG DI-EQUIP (berdasarkan localEq terbaru)
		local currentLeveling = {}  -- list of uuids
		local otherEquipped = {}    -- list of uuids

		for uuid, _ in pairs(localEq) do
			local pInfo = inv[uuid]
			local pt = pInfo and pInfo.PetType
			local pd = pInfo and pInfo.PetData or {}
			local lvl = pd.Level or 0

			if not teamSet[uuid] then
				if targetTypes[pt] and lvl < targetLvl then
					table.insert(currentLeveling, uuid)
				else
					table.insert(otherEquipped, uuid)
				end
			end
		end

		-- D. LEPAS PET LEVELING YANG SUDAH SELESAI (mencapai target level)
		for _, uuid in ipairs(currentLeveling) do
			local pInfo = inv[uuid]
			local pd = pInfo and pInfo.PetData or {}
			local lvl = pd.Level or 0
			if lvl >= targetLvl then
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				localEq[uuid] = nil
				localEqCount = localEqCount - 1
				-- Hapus dari daftar leveling aktif kita agar hitungan di bawah langsung sinkron
				for idx, u in ipairs(currentLeveling) do
					if u == uuid then
						table.remove(currentLeveling, idx)
						break
					end
				end
				task.wait(0.25)
			end
		end

		-- E. TAMBAHKAN PET BARU DARI INVENTORY
		local currentActiveCount = #currentLeveling
		local needed = maxLvlPets - currentActiveCount

		if needed > 0 then
			-- Cari pool pet di inventory yang tidak ter-equip di localEq
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0

				if not localEq[uuid] and targetTypes[pt] and lvl < targetLvl then
					table.insert(pool, { uuid = uuid, petType = pt, level = lvl })
				end
			end
			table.sort(pool, function(a, b) return a.level < b.level end) -- Prioritaskan level terendah

			for i = 1, math.min(needed, #pool) do
				local target = pool[i]
				local pos = getPos(target.uuid)
				if pos then
					-- Jika total equipped secara lokal penuh (misal >= 15), copot non-team non-leveling
					if localEqCount >= 15 and #otherEquipped > 0 then
						local toRemove = table.remove(otherEquipped)
						pcall(function() PetsService:FireServer("UnequipPet", toRemove) end)
						localEq[toRemove] = nil
						localEqCount = localEqCount - 1
						task.wait(0.25)
					end
					
					pcall(function() PetsService:FireServer("EquipPet", target.uuid, CFrame.new(pos)) end)
					localEq[target.uuid] = true
					localEqCount = localEqCount + 1
					table.insert(currentLeveling, target.uuid)
					task.wait(0.3)
				end
			end
		end

		-- Update status akhir setelah proses
		ctx.state.levelingStatus = string.format("Leveling: %d/%d aktif", #currentLeveling, maxLvlPets)
	end

	local function levelingLoop()
		ctx.state.levelingId = (ctx.state.levelingId or 0) + 1
		local myId = ctx.state.levelingId
		ctx.elevate()
		
		ctx.state.levelingFirstRun = true
		
		while CFG.levelingEnabled and ctx.alive() and ctx.state.levelingId == myId do
			pcall(checkLeveling)
			task.wait(3.0)
		end
		ctx.state.levelingStatus = "Idle"
	end

	function ctx.startLeveling() task.spawn(levelingLoop) end
end
