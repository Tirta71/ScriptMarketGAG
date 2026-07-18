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

	-- filter disimpan pakai label "Pet - Egg"; cocokin pakai label yg sama.
	local petEggLabel = (ctx.reg and ctx.reg.petEggLabel) or function(p) return p end
	-- apakah pet ini termasuk yg DIJUAL (cocok filter)?
	local function shouldSell(petType, pd)
		pd = pd or {}
		local w = pd.BaseWeight or 0
		local age = pd.Level or 0
		local key = petEggLabel(petType)
		if (CFG.sellPetTypes or {})[key] then
			if w < (CFG.sellWeightThreshold or 0) then return true end
			if age < (CFG.sellAgeThreshold or 0) then return true end
		end
		if (CFG.sellSpecialTypes or {})[key] then
			local sw = CFG.sellSpecialWeight or 0
			if sw > 0 and w < sw then return true end
		end
		return false
	end

	-- Jalankan sell: pet yg keep -> favorit; pet yg dijual -> unfavorit lalu jual.
	local function doSell()
		-- GUARD: filter kosong -> batalin (biar ga ada kecelakaan)
		if not next(CFG.sellPetTypes or {}) and not next(CFG.sellSpecialTypes or {}) then
			ctx.state.hatchStatus = "Sell dibatalin: filter 'Pets to Sell' kosong"
			return 0
		end
		local inv = inventory()
		local keeps, sells = {}, {}
		for _, t in ipairs(petTools()) do
			local uuid = t:GetAttribute("PET_UUID")
			local v = inv[uuid]
			local pt = (v and v.PetType) or t:GetAttribute("f")
			local pd = v and v.PetData
			if shouldSell(pt, pd) then sells[#sells + 1] = t else keeps[#keeps + 1] = t end
		end

		if CFG.sellStyle == "All at Once" then
			-- proteksi: favoritin semua keep, unfavorit yg mau dijual
			ctx.state.hatchStatus = "Selling: favorit proteksi..."
			for _, t in ipairs(keeps) do setFav(t, true) end
			for _, t in ipairs(sells) do setFav(t, false) end
			-- VERIFY: tunggu sync + cek SEMUA keep bener favorit; retry; abort kalau gagal.
			local safe = false
			for _ = 1, 4 do
				task.wait(0.5)
				local bad = {}
				for _, t in ipairs(keeps) do if t.Parent and not isFav(t) then bad[#bad + 1] = t end end
				if #bad == 0 then safe = true; break end
				ctx.state.hatchStatus = ("Verify: %d keep-pet belum favorit, retry..."):format(#bad)
				for _, t in ipairs(bad) do setFav(t, true) end
			end
			if not safe then
				ctx.state.hatchStatus = "Sell DIBATALIN: ada keep-pet belum favorit (aman, ga jadi jual)"
				return 0
			end
			if SellAll then pcall(function() SellAll:FireServer() end) end
			ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
			ctx.state.hatchStatus = ("Sold all-at-once (%d matched)"):format(#sells)
			return #sells
		else
			-- One by One: cuma jual yg cocok filter, targeted (aman by design)
			ctx.state.hatchStatus = "Selling one-by-one..."
			for _, t in ipairs(sells) do
				if t.Parent then
					setFav(t, false)
					if SellPet then pcall(function() SellPet:FireServer(t, true) end) end
					task.wait(0.1)
				end
			end
			ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
			ctx.state.hatchStatus = ("Sold %d pet (one by one)"):format(#sells)
			return #sells
		end
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

	-- Daftar egg di backpack + jumlah (buat dropdown Egg Configuration).
	function ctx.getEggBackpackOptions()
		local out = {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Egg") and not t:GetAttribute("PET_UUID") then
				local nm = tostring(t.Name)
				local base, cnt = nm:match("^(.-)%s*x(%d+)$")
				base = base or nm
				out[#out + 1] = { name = base, display = cnt and (base .. " x" .. cnt) or base }
			end
		end end
		table.sort(out, function(a, b) return a.name < b.name end)
		return out
	end

	----------------------------------------------------------------- PLACE EGG
	local function placedEggCount()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local n = 0
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then n = n + 1 end
		end end
		return n
	end
	local function plantLocPart()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local PL = farm and farm:FindFirstChild("Plant_Locations", true)
		if not PL then return nil end
		if PL:IsA("BasePart") then return PL end
		for _, d in ipairs(PL:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end
	local function placePos()
		local p = plantLocPart(); if not p then return nil end
		local hx = math.max(1, p.Size.X / 2 - 3)
		local hz = math.max(1, p.Size.Z / 2 - 3)
		return p.Position + Vector3.new(math.random() * hx * 2 - hx, p.Size.Y / 2 + 0.2, math.random() * hz * 2 - hz)
	end
	local function equipEggTool(eggName)
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end
		local held = LP.Character:FindFirstChildWhichIsA("Tool")
		if held and tostring(held.Name):find(eggName, 1, true) then return held end
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find(eggName, 1, true) and not t:GetAttribute("PET_UUID") then
				pcall(function() hum:EquipTool(t) end); task.wait(0.3); return t
			end
		end end
		return nil
	end
	local function placeEggs(need)
		local eggName = CFG.hatchEggName or "Rare Egg"
		if not equipEggTool(eggName) then ctx.state.hatchStatus = "Egg '" .. eggName .. "' ga ada di backpack"; return 0 end
		local done = 0
		for _ = 1, need do
			if not CFG.hatchEnabled then break end
			local pos = placePos(); if not pos then break end
			pcall(function() EggRemote:FireServer("CreateEgg", pos) end)
			done = done + 1
			task.wait(0.25)
		end
		ctx.state.hatchStatus = ("Placed %d egg"):format(done)
		return done
	end
	local function unionTeam(a, b)
		local u = {}
		for k in pairs(a or {}) do u[k] = true end
		for k in pairs(b or {}) do u[k] = true end
		return u
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
			placed = placedEggCount(),
			maxPlaced = CFG.hatchMaxPlaced or 9,
		}
	end

	----------------------------------------------------------------- LOOP
	local function tick()
		local bpc = backpackPetCount()
		-- 1) SELL: backpack penuh -> Sell Team -> jual (Seal balikin egg)
		if CFG.autoSellEnabled and bpc >= (CFG.sellWhenReach or 100) then
			ctx.state.hatchPhase = "Selling Pets"
			if next(CFG.hatchSellTeam or {}) and not teamMatches(CFG.hatchSellTeam) then
				equipTeam(CFG.hatchSellTeam, "Sell Team")
				task.wait(CFG.sellTeamDelay or 5)
			end
			doSell()
			return
		end
		-- 2) HATCH: ada egg READY -> Hatch Team + Bronto (Koi recovery + +30% berat)
		local ready = readyEggs()
		if #ready > 0 then
			ctx.state.hatchPhase = "Hatching"
			local hteam = unionTeam(CFG.hatchHatchTeam, CFG.hatchBrontoTeam)
			if next(hteam) and not equipTeam(hteam, "Hatch Team") then return end -- nunggu team sesuai
			for _, e in ipairs(ready) do
				if not CFG.hatchEnabled then break end
				pcall(function() EggRemote:FireServer("HatchPet", e) end)
				ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
				task.wait(CFG.hatchSpeed or 0.2)
			end
			return
		end
		-- 3) PLACE: egg di garden kurang -> Core Team (speed) + place egg baru
		local placed = placedEggCount()
		local maxP = CFG.hatchMaxPlaced or 9
		if placed < maxP then
			ctx.state.hatchPhase = ("Placing Eggs (%d/%d)"):format(placed, maxP)
			if next(CFG.hatchCoreTeam or {}) then equipTeam(CFG.hatchCoreTeam, "Core Team") end
			placeEggs(maxP - placed)
			return
		end
		-- 4) INCUBATE: nunggu ready -> Core Team (speed)
		ctx.state.hatchPhase = ("Incubating (%d egg)"):format(placed)
		if next(CFG.hatchCoreTeam or {}) then equipTeam(CFG.hatchCoreTeam, "Core Team") end
		ctx.state.hatchStatus = "Nunggu egg ready..."
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
