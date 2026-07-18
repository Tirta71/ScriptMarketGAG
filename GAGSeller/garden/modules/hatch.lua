--[[ hatch.lua — Auto Hatch + Auto Sell (Stage 1).
     - Team-swap dengan GUARD: team ga diproses kalau yg ke-equip udah sesuai.
     - Auto Hatch: equip hatch team -> hatch semua egg READY -> hitung cycle.
     - Auto Sell: pet yg COCOK filter dijual; sisanya DIFAVORITIN biar aman.
       Favorite via Favorite_Item (toggle), jual via SellPet_RE / SellAllPets_RE.
     Catatan: auto-place egg baru & bronto phase = stage berikutnya. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local CFG = ctx.CFG
	local DataService = ctx.deps.DataService
	local PetsRemote = RS.GameEvents.PetsService
	local FavoriteRemote = RS.GameEvents:FindFirstChild("Favorite_Item")
	local SellPet = RS.GameEvents:FindFirstChild("SellPet_RE")
	local SellAll = RS.GameEvents:FindFirstChild("SellAllPets_RE")
	local EggRemote = RS.GameEvents.PetEggService
	local FAV_KEY = "d"
	pcall(function() FAV_KEY = require(RS.Data.EnumRegistry.InventoryServiceEnums).Favorite end)

	----------------------------------------------------------------- util
	local function getData() local ok, d = pcall(function() return DataService:GetData() end); return ok and d or nil end
	local function inventory() local d = getData(); return d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {} end
	local function equippedList() local d = getData(); return d and d.PetsData and d.PetsData.EquippedPets or {} end

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local c = farmCenter(); if not c then return nil end
		local i = slotOf[uuid]
		return c + Vector3.new((i % 6 - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	----------------------------------------------------------------- TEAM + GUARD
	-- teamSet = { [uuid]=true }. Return true kalau equipped PERSIS == teamSet.
	local function teamMatches(teamSet)
		if not next(teamSet or {}) then return true end -- team kosong = ga usah proses
		local eq = equippedList()
		local eqSet, eqN = {}, 0
		for _, u in ipairs(eq) do eqSet[u] = true; eqN = eqN + 1 end
		local tN = 0
		for u in pairs(teamSet) do if not eqSet[u] then return false end; tN = tN + 1 end
		return eqN == tN
	end

	-- Equip team dgn guard: skip total kalau udah sesuai. Return true kalau team siap.
	local function equipTeam(teamSet, label)
		if not next(teamSet or {}) then return true end
		if teamMatches(teamSet) then return true end -- GUARD
		local eq = equippedList()
		local keep = {}
		for u in pairs(teamSet) do keep[u] = true end
		-- cabut yg bukan anggota team
		for _, u in ipairs(eq) do
			if not keep[u] then
				pcall(function() PetsRemote:FireServer("UnequipPet", u) end)
				task.wait(0.12)
			end
		end
		-- pasang anggota team yg belum ke-equip
		local eqNow = {}
		for _, u in ipairs(equippedList()) do eqNow[u] = true end
		for u in pairs(teamSet) do
			if not eqNow[u] then
				local pos = getPos(u)
				if pos then pcall(function() PetsRemote:FireServer("EquipPet", u, CFrame.new(pos)) end); task.wait(0.15) end
			end
		end
		ctx.state.hatchStatus = (label or "Team") .. ": equipping..."
		return teamMatches(teamSet)
	end

	----------------------------------------------------------------- FAVORITE / SELL
	local function petTools()
		local out = {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		for _, src in ipairs({ bp, LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("PET_UUID") then out[#out + 1] = t end
			end end
		end
		return out
	end
	local function isFav(tool) return tool:GetAttribute(FAV_KEY) == true end
	local function setFav(tool, want)
		if isFav(tool) ~= want and FavoriteRemote then
			pcall(function() FavoriteRemote:FireServer(tool) end); task.wait(0.06)
		end
	end

	-- apakah pet ini termasuk yg DIJUAL (cocok filter)?
	local function shouldSell(petType, pd)
		pd = pd or {}
		local w = pd.BaseWeight or 0
		local age = pd.Level or 0
		if (CFG.sellPetTypes or {})[petType] then
			if w < (CFG.sellWeightThreshold or 0) then return true end
			if age < (CFG.sellAgeThreshold or 0) then return true end
		end
		if (CFG.sellSpecialTypes or {})[petType] then
			local sw = CFG.sellSpecialWeight or 0
			if sw > 0 and w < sw then return true end
		end
		return false
	end

	-- Jalankan sell: pet yg keep -> favorit; pet yg dijual -> unfavorit lalu jual.
	local function doSell()
		local inv = inventory()
		local tools = petTools()
		local toSell = {}
		ctx.state.hatchStatus = "Selling: favorit proteksi..."
		for _, t in ipairs(tools) do
			local uuid = t:GetAttribute("PET_UUID")
			local v = inv[uuid]
			local pt = (v and v.PetType) or t:GetAttribute("f")
			local pd = v and v.PetData
			if shouldSell(pt, pd) then
				setFav(t, false)           -- pastikan ga favorit biar bisa dijual
				toSell[#toSell + 1] = t
			else
				setFav(t, true)            -- proteksi: favoritin
			end
		end
		-- jual
		if CFG.sellStyle == "All at Once" and SellAll then
			pcall(function() SellAll:FireServer() end) -- jual semua non-favorit
		elseif SellPet then
			for _, t in ipairs(toSell) do
				if t.Parent then pcall(function() SellPet:FireServer(t, true) end); task.wait(0.1) end
			end
		end
		ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
		ctx.state.hatchStatus = ("Sold %d pet"):format(#toSell)
		return #toSell
	end
	ctx.hatchDoSell = doSell -- expose buat tombol manual

	----------------------------------------------------------------- HATCH
	local function readyEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name and e:GetAttribute("READY") then t[#t + 1] = e end
		end end
		return t
	end
	local function backpackPetCount()
		local n = 0
		for _, t in ipairs(petTools()) do local _ = t; n = n + 1 end
		return n
	end

	----------------------------------------------------------------- STATUS
	ctx.state.hatchStatus = "Idle"
	function ctx.getHatchSummary()
		local function nm(set)
			local o = {}; for u in pairs(set or {}) do
				local v = inventory()[u]; o[#o + 1] = (v and v.PetType) or "?"
			end
			-- ringkas per tipe
			local c, order = {}, {}
			for _, x in ipairs(o) do if not c[x] then order[#order + 1] = x end; c[x] = (c[x] or 0) + 1 end
			local p = {}; for _, x in ipairs(order) do p[#p + 1] = (c[x] > 1 and (x .. " x" .. c[x]) or x) end
			return #p > 0 and table.concat(p, ", ") or "-"
		end
		return {
			status = CFG.hatchEnabled and "RUNNING" or "STOPPED",
			phase = ctx.state.hatchPhase or "-",
			core = nm(CFG.hatchCoreTeam), hatch = nm(CFG.hatchHatchTeam),
			bronto = nm(CFG.hatchBrontoTeam), sell = nm(CFG.hatchSellTeam),
			backpack = backpackPetCount(),
			eggsHatched = ctx.state.hatchEggsHatched or 0,
			sellCycles = ctx.state.hatchSellCycles or 0,
			ready = #readyEggs(),
		}
	end

	----------------------------------------------------------------- LOOP
	local function tick()
		-- SELL phase kalau backpack penuh
		local bpc = backpackPetCount()
		if CFG.autoSellEnabled and bpc >= (CFG.sellWhenReach or 100) then
			ctx.state.hatchPhase = "Selling Pets"
			if next(CFG.hatchSellTeam or {}) and not teamMatches(CFG.hatchSellTeam) then
				equipTeam(CFG.hatchSellTeam, "Sell Team")
				task.wait(CFG.sellTeamDelay or 5)
			end
			doSell()
			return
		end
		-- HATCH phase
		ctx.state.hatchPhase = "Hatching"
		if not equipTeam(CFG.hatchHatchTeam, "Hatch Team") then return end -- nunggu team sesuai
		local eggs = readyEggs()
		for _, e in ipairs(eggs) do
			if not CFG.hatchEnabled then break end
			pcall(function() EggRemote:FireServer("HatchPet", e) end)
			ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
			task.wait(0.2)
		end
		ctx.state.hatchStatus = ("Hatched %d ready egg"):format(#eggs)
	end

	local function loop()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		local my = ctx.state.hatchId
		ctx.elevate()
		while CFG.hatchEnabled and ctx.alive() and ctx.state.hatchId == my do
			pcall(tick)
			task.wait(1.0)
		end
		ctx.state.hatchStatus = "Idle"
	end

	function ctx.startHatch()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		task.spawn(loop)
	end
	function ctx.stopHatch()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		ctx.state.hatchStatus = "Idle"
	end
end
