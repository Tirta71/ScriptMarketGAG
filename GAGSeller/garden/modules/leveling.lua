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

		-- 1) Klasifikasikan pet yang sedang di-equip
		local currentTeam = {}      -- uuid -> true
		local currentLeveling = {}  -- list of uuids
		local otherEquipped = {}    -- list of uuids

		for _, uuid in ipairs(eq) do
			local pInfo = inv[uuid]
			local pt = pInfo and pInfo.PetType
			local pd = pInfo and pInfo.PetData or {}
			local lvl = pd.Level or 0

			if teamSet[uuid] then
				currentTeam[uuid] = true
			elseif targetTypes[pt] and lvl < targetLvl then
				table.insert(currentLeveling, uuid)
			else
				table.insert(otherEquipped, uuid)
			end
		end

		ctx.state.levelingStatus = string.format("Leveling: %d/%d aktif", #currentLeveling, maxLvlPets)

		-- 2) Lepas pet leveling yang sudah mencapai target level
		for _, uuid in ipairs(currentLeveling) do
			local pInfo = inv[uuid]
			local pd = pInfo and pInfo.PetData or {}
			local lvl = pd.Level or 0
			if lvl >= targetLvl then
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				task.wait(0.25)
			end
		end

		-- 3) Tambahkan pet baru dari inventory jika kuota leveling kurang
		local currentActiveCount = 0
		-- Hitung ulang setelah unequip di atas
		ok, d = pcall(function() return DataService:GetData() end)
		if ok and d and d.PetsData then
			local activeEq = d.PetsData.EquippedPets or {}
			for _, uuid in ipairs(activeEq) do
				local pInfo = inv[uuid]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				local lvl = pd.Level or 0
				if not teamSet[uuid] and targetTypes[pt] and lvl < targetLvl then
					currentActiveCount = currentActiveCount + 1
				end
			end
		end

		local needed = maxLvlPets - currentActiveCount
		if needed > 0 then
			-- Bangun pool pet dari inventory yang belum di-equip dan butuh leveling
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local isEquipped = false
				for _, eqUuid in ipairs(eq) do
					if eqUuid == uuid then isEquipped = true; break end
				end

				if not isEquipped and targetTypes[pt] and lvl < targetLvl then
					table.insert(pool, { uuid = uuid, petType = pt, level = lvl })
				end
			end
			table.sort(pool, function(a, b) return a.level < b.level end) -- prioritas level terendah

			for i = 1, math.min(needed, #pool) do
				local target = pool[i]
				local pos = getPos(target.uuid)
				if pos then
					-- Jika slot equip penuh (misal >= 15), lepas pet non-team non-leveling dulu
					if #eq >= 15 and #otherEquipped > 0 then
						local toRemove = table.remove(otherEquipped)
						pcall(function() PetsService:FireServer("UnequipPet", toRemove) end)
						task.wait(0.25)
					end
					
					pcall(function() PetsService:FireServer("EquipPet", target.uuid, CFrame.new(pos)) end)
					task.wait(0.3)
				end
			end
		end
	end

	local function levelingLoop()
		ctx.state.levelingId = (ctx.state.levelingId or 0) + 1
		local myId = ctx.state.levelingId
		ctx.elevate()
		
		while CFG.levelingEnabled and ctx.alive() and ctx.state.levelingId == myId do
			pcall(checkLeveling)
			task.wait(5.0)
		end
		ctx.state.levelingStatus = "Idle"
	end

	function ctx.startLeveling() task.spawn(levelingLoop) end
end
