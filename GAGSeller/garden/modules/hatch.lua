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

	-- 1 pass: cabut non-team, pasang anggota team yg belum ke-equip.
	local function equipTeamOnce(teamSet)
		local keep = {}
		for u in pairs(teamSet) do keep[u] = true end
		for _, u in ipairs(equippedList()) do
			if not keep[u] then
				pcall(function() PetsRemote:FireServer("UnequipPet", u) end)
				task.wait(0.1)
			end
		end
		local eqNow = {}
		for _, u in ipairs(equippedList()) do eqNow[u] = true end
		for u in pairs(teamSet) do
			if not eqNow[u] then
				local pos = getPos(u)
				if pos then pcall(function() PetsRemote:FireServer("EquipPet", u, CFrame.new(pos)) end); task.wait(0.15) end
			end
		end
	end

	-- Equip team dgn guard: skip kalau udah sesuai. BLOK sampai team LENGKAP (retry).
	local function equipTeam(teamSet, label)
		if not next(teamSet or {}) then return true end
		if teamMatches(teamSet) then return true end -- GUARD
		ctx.state.hatchStatus = (label or "Team") .. ": equipping..."
		for _ = 1, 6 do
			if teamMatches(teamSet) then return true end
			equipTeamOnce(teamSet)
			task.wait(0.2)
		end
		return teamMatches(teamSet)
	end

	-- EKSPERIMEN: cabut lalu pasang lagi anggota team dengan CEPAT (biar berakhir ke-equip).
	-- Dipakai buat nguji teori "re-equip pas hatch/sell ngaruh ke recovery" (default off).
	local function quickReequip(teamSet)
		if not next(teamSet or {}) then return end
		for u in pairs(teamSet) do
			pcall(function() PetsRemote:FireServer("UnequipPet", u) end)
		end
		task.wait(0.06)
		for u in pairs(teamSet) do
			local pos = getPos(u)
			if pos then pcall(function() PetsRemote:FireServer("EquipPet", u, CFrame.new(pos)) end) end
		end
		task.wait(0.12) -- pastiin balik ke-equip sebelum aksi (hatch/sell) di-fire
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
			if isFav(t) then
				keeps[#keeps + 1] = t              -- udah favorit = MUTLAK ga dijual (walau filter cocok)
			elseif shouldSell(pt, pd) then
				sells[#sells + 1] = t
			else
				keeps[#keeps + 1] = t
			end
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
			if CFG.hatchReequipTrick then quickReequip(CFG.hatchSellTeam) end -- eksperimen: cabut-pasang Seal
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
					if CFG.hatchReequipTrick then quickReequip(CFG.hatchSellTeam) end -- eksperimen: cabut-pasang Seal
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
	-- Egg ready = timer habis (TimeToHatch <= 0). Egg yg timer-nya jalan = belum ready.
	local function readyEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then
				local tth = tonumber(e:GetAttribute("TimeToHatch")) or 0
				if tth <= 0 then t[#t + 1] = e end
			end
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
	-- Grid FIX & rapih: n slot, center di area, baris rata (spacing 4 studs).
	-- + sedikit baris cadangan di belakang biar tetap bisa penuh kalau ada egg nyempil.
	local function gridPositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4 -- jarak antar egg (min server = 3, kasih margin biar ga "Too close")
		local usableX = math.max(SP, p.Size.X - 4)
		local cols = math.max(1, math.min(n, math.floor(usableX / SP) + 1))
		-- baris = cukup buat n + 1 baris cadangan (anti-stuck, tetap rapi)
		local rows = math.ceil(n / cols) + 1
		local startX = -((cols - 1) * SP) / 2
		local startZ = -((rows - 1) * SP) / 2
		local out = {}
		for r = 0, rows - 1 do
			for c = 0, cols - 1 do
				out[#out + 1] = p.Position + Vector3.new(startX + c * SP, p.Size.Y / 2 + 0.2, startZ + r * SP)
			end
		end
		return out
	end
	local function currentEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then t[#t + 1] = e end
		end end
		return t
	end
	local function slotOccupied(pos, eggs)
		for _, e in ipairs(eggs) do
			local ep = e:GetPivot().Position
			if (Vector3.new(ep.X, 0, ep.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < 3.5 then return true end
		end
		return false
	end
	local function equipEggTool(eggName)
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end
		local held = LP.Character:FindFirstChildWhichIsA("Tool")
		-- udah megang egg yg bener (bukan pet) -> ok
		if held and not held:GetAttribute("PET_UUID") and tostring(held.Name):find(eggName, 1, true) then return held end
		-- lepas dulu tool lama (mis. PET hasil hatch yg auto ke-pegang) biar ga konflik
		if held then pcall(function() hum:UnequipTools() end); task.wait(0.15) end
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find(eggName, 1, true) and not t:GetAttribute("PET_UUID") then
				pcall(function() hum:EquipTool(t) end); task.wait(0.35); return t
			end
		end end
		return nil
	end
	-- Isi egg RAPIH ke grid, cuma di slot yg kosong. Retry sampai penuh (target).
	local function placeEggs(target)
		local eggName = CFG.hatchEggName or "Rare Egg"
		if not equipEggTool(eggName) then ctx.state.hatchStatus = "Egg '" .. eggName .. "' ga ada di backpack"; return 0 end
		local start = placedEggCount()
		local grid = gridPositions(target)
		-- isi slot kosong sampai TEPAT target; berhenti kalau 1 pass ga nambah (mentok)
		for _ = 1, 3 do
			if placedEggCount() >= target then break end
			local before = placedEggCount()
			local eggs = currentEggs()
			for _, pos in ipairs(grid) do
				if not CFG.hatchEnabled or placedEggCount() >= target then break end
				if not slotOccupied(pos, eggs) then
					equipEggTool(eggName)
					-- pastiin bener-bener MEGANG egg (bukan pet hasil hatch) sebelum place
					local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
					if held and not held:GetAttribute("PET_UUID") and tostring(held.Name):find(eggName, 1, true) then
						pcall(function() EggRemote:FireServer("CreateEgg", pos) end)
						task.wait(0.3)
						eggs = currentEggs() -- refresh biar ga dobel di slot sama
						ctx.state.hatchStatus = ("Placing: %d/%d egg"):format(placedEggCount(), target)
					end
				end
			end
			if placedEggCount() <= before then break end -- ga nambah -> mentok
		end
		return placedEggCount() - start
	end
	local function unionTeam(a, b)
		local u = {}
		for k in pairs(a or {}) do u[k] = true end
		for k in pairs(b or {}) do u[k] = true end
		return u
	end

	-- Pending pet dari egg (dari SavedObjects): return petType, displayWeight (base*1.1)
	local eggSlotKey
	local function eggPending(egg)
		local uuid = egg:GetAttribute("OBJECT_UUID"); if not uuid then return nil, 0 end
		local d = getData(); local slots = d and d.SaveSlots and d.SaveSlots.AllSlots
		if not slots then return nil, 0 end
		local function fromSlot(s) local so = s and s.SavedObjects and s.SavedObjects[uuid]; return so and so.Data end
		local dt = eggSlotKey and fromSlot(slots[eggSlotKey])
		if not dt then for sn, slot in pairs(slots) do if type(slot) == "table" then local x = fromSlot(slot); if x then eggSlotKey = sn; dt = x; break end end end end
		if not dt then return nil, 0 end
		return dt.Type, (tonumber(dt.BaseWeight) or 0) * 1.1
	end

	-- Klasifikasi egg buat bronto: "skip" | "bronto" | "normal"
	local function classifyEgg(egg)
		local pt, w = eggPending(egg)
		local isSpecial = pt ~= nil and (CFG.brontoSpecialPets or {})[petEggLabel(pt)] == true
		if isSpecial and (CFG.brontoSpecialWeight or 0) > 0 and w <= CFG.brontoSpecialWeight then isSpecial = false end
		if isSpecial and CFG.brontoSkipSpecial then return "skip" end
		local isUni = false
		if (CFG.brontoUniversalWeight or 0) > 0 and w > CFG.brontoUniversalWeight then
			local types = CFG.brontoUniversalTypes or {}
			if not next(types) or (pt and types[petEggLabel(pt)]) then isUni = true end
		end
		if isSpecial or isUni then return "bronto" end
		return "normal"
	end

	----------------------------------------------------------------- Hatch Alert (webhook bronto)
	local PetList; pcall(function() PetList = require(RS.Data.PetRegistry.PetList) end)
	local PetRegistry; pcall(function() PetRegistry = require(RS.Data.PetRegistry) end)
	local function petSize(eggName, petType, baseW)
		local egg = PetRegistry and PetRegistry.PetEggs and PetRegistry.PetEggs[eggName]
		local item = egg and egg.RarityData and egg.RarityData.Items and egg.RarityData.Items[petType]
		local wr = item and item.GeneratedPetData and item.GeneratedPetData.WeightRange
		if type(wr) == "table" and wr[1] and wr[2] and wr[2] > wr[1] then
			local f = (baseW - wr[1]) / (wr[2] - wr[1])
			if f < 0.33 then return "Small" elseif f < 0.7 then return "Normal" else return "Big" end
		end
		return "Normal"
	end
	-- dispWeight = berat tampil (base*1.1). Bronto = dispWeight*1.3 (+30%).
	local function sendHatchAlert(petType, eggName, dispWeight)
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local baseW = dispWeight / 1.1
		local rarity = (PetList and PetList[petType] and PetList[petType].Rarity) or "?"
		local payload = {
			content = "@everyone",
			embeds = { {
				title = "AllegiaanHub \u{2014} Hatch Alerts",
				color = 5814783,
				fields = {
					{ name = "Profile :", value = ("> Username : ||%s||"):format(LP.Name), inline = false },
					{ name = "Hatched :", value = ("> Pet Name: `%s`\n> Hatched From: `%s`\n> Rarity: `%s`\n> Weight: `%.2f KG`\n> Status: `%s`\n> Bronto: `%.2f KG`")
						:format(petType, eggName, rarity, dispWeight, petSize(eggName, petType, baseW), dispWeight * 1.3), inline = false },
				},
				footer = { text = os.date("%B %d | %I:%M %p") },
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	----------------------------------------------------------------- Cycle Statistics (webhook)
	-- Team ringkas: "N Nama Lengkap" (mutasi + tipe), grup per nama.
	local function teamNames(set)
		local mutDisplay = (ctx.reg and ctx.reg.mutDisplay) or function(x) return x end
		local inv = inventory()
		local order, c = {}, {}
		for u in pairs(set or {}) do
			local v = inv[u]; local full = "?"
			if v then
				local mut = (v.PetData or {}).MutationType
				local mutStr = (mut and mut ~= "" and mut ~= "None" and mut ~= "Normal") and (mutDisplay(mut) .. " ") or ""
				full = mutStr .. v.PetType
			end
			if not c[full] then order[#order + 1] = full end
			c[full] = (c[full] or 0) + 1
		end
		local p = {}; for _, x in ipairs(order) do p[#p + 1] = c[x] .. " " .. x end
		return #p > 0 and table.concat(p, ", ") or "-"
	end
	ctx.hatchTeamNames = teamNames

	-- akumulasi pet ke-hatch per tipe (buat Hunt Statistics)
	local function trackHatch(petType, dispW)
		ctx.state.hatchByType = ctx.state.hatchByType or {}
		local t = ctx.state.hatchByType[petType]
		if not t then t = { n = 0, minW = math.huge, maxW = 0 }; ctx.state.hatchByType[petType] = t end
		t.n = t.n + 1
		if dispW < t.minW then t.minW = dispW end
		if dispW > t.maxW then t.maxW = dispW end
	end

	local function eggAmount(eggName)
		local n = 0
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and not t:GetAttribute("PET_UUID") and tostring(t.Name):find(eggName, 1, true) then
					local _, cnt = tostring(t.Name):match("^(.-)%s*x(%d+)$"); if tonumber(cnt) then n = tonumber(cnt) end
				end
			end end
		end
		return n
	end
	-- Total SEMUA egg di backpack+character (buat ukur recovery real, egg apa pun).
	-- Egg tanpa suffix "xN" = 1 biji.
	local function totalEggCount()
		local n = 0
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and not t:GetAttribute("PET_UUID") and tostring(t.Name):find("Egg") then
					local _, cnt = tostring(t.Name):match("^(.-)%s*x(%d+)$")
					n = n + (tonumber(cnt) or 1)
				end
			end end
		end
		return n
	end
	-- Empirical proc: catat berapa lemparan (rolls) & berapa yg balik egg (hits).
	-- Koi = recovery pas hatch; Seal = recovery pas sell. Beda fase = beda sumber.
	local function recordProc(kind, rolls, hits)
		local s = ctx.state
		hits = math.max(0, math.floor((hits or 0) + 0.5))
		rolls = math.max(0, rolls or 0)
		if kind == "koi" then
			s.procKoiRolls = (s.procKoiRolls or 0) + rolls
			s.procKoiHits  = (s.procKoiHits or 0) + hits
		else
			s.procSealRolls = (s.procSealRolls or 0) + rolls
			s.procSealHits  = (s.procSealHits or 0) + hits
		end
	end
	ctx.hatchTotalEggCount = totalEggCount
	-- Recovery egg balik dari server sering TELAT replikasi (bisa 1-4 detik).
	-- Poll: tungguin egg naik dari baseline, ambil PUNCAK (bukan snapshot sekejap)
	-- biar egg balik yg telat ga ke-miss. Berhenti awal kalau udah stabil.
	local function measureRecovery(baseline, maxSec)
		local hi = totalEggCount()
		if hi < baseline then hi = baseline end
		local stable = 0
		local steps = math.max(1, math.floor((maxSec or 4) / 0.4))
		for _ = 1, steps do
			task.wait(0.4)
			local n = totalEggCount()
			if n > hi then hi = n; stable = 0 else stable = stable + 1 end
			if stable >= 3 then break end -- 1.2s ga nambah = udah selesai balik
		end
		return hi - baseline
	end
	function ctx.getProcStats()
		local s = ctx.state
		local kr, kh = s.procKoiRolls or 0, s.procKoiHits or 0
		local sr, sh = s.procSealRolls or 0, s.procSealHits or 0
		return {
			koiRolls = kr, koiHits = kh, koiPct = kr > 0 and (kh / kr * 100) or 0,
			sealRolls = sr, sealHits = sh, sealPct = sr > 0 and (sh / sr * 100) or 0,
			-- net egg estimasi per egg placed: (Koi% + Seal%)/100 - 1
			netPerEgg = ((kr > 0 and kh / kr or 0) + (sr > 0 and sh / sr or 0)) - 1,
		}
	end
	function ctx.resetProcStats()
		ctx.state.procKoiRolls, ctx.state.procKoiHits = 0, 0
		ctx.state.procSealRolls, ctx.state.procSealHits = 0, 0
	end

	local function fmtDur(sec)
		sec = math.max(0, math.floor(sec))
		local h = math.floor(sec / 3600); local m = math.floor((sec % 3600) / 60); local s = sec % 60
		local p = {}
		if h > 0 then p[#p + 1] = h .. "h" end
		if m > 0 then p[#p + 1] = m .. "m" end
		p[#p + 1] = s .. "s"
		return table.concat(p, " ")
	end

	local function sendCycleStats()
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local eggName = CFG.hatchEggName or "Rare Egg"
		local maxP = CFG.hatchMaxPlaced or 9
		local hatched = ctx.state.hatchEggsHatched or 0
		local eggBefore = ctx.state.hatchEggBefore or 0
		local curAmt = eggAmount(eggName)
		local consumed = eggBefore - curAmt
		local recovery = math.max(0, hatched - consumed)
		local luckyHatch = hatched > 0 and (recovery / hatched * 100) or 0
		-- Hunt Statistics: pet per tipe + range berat
		local huntLines, totalPets = {}, 0
		for pt, t in pairs(ctx.state.hatchByType or {}) do
			totalPets = totalPets + t.n
			huntLines[#huntLines + 1] = ("`%s x%d` (%.2f-%.2f kg)"):format(pt, t.n, t.minW == math.huge and 0 or t.minW, t.maxW)
		end
		table.sort(huntLines)
		local hunt = #huntLines > 0 and table.concat(huntLines, "\n") or "-"
		local maxBp = 0
		local d = getData(); if d then maxBp = tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0 end
		local hatchCycles = ctx.state.hatchRounds or 0
		local payload = { embeds = { {
			title = "\u{1F4CA} Hatch Cycle Statistics",
			color = 5793266,
			fields = {
				{ name = "Profile :", value = ("> Username : ||%s||\n> Egg Name: `%s`\n> Pet on backpack: `%d/%d`\n> Server Version: `%s`")
					:format(LP.Name, eggName, backpackPetCount(), maxBp, tostring(game.PlaceVersion)), inline = false },
				{ name = "Teams :", value = ("> Core: %s\n> Hatch: %s\n> Bronto: %s\n> Sell: %s")
					:format(teamNames(CFG.hatchCoreTeam), teamNames(CFG.hatchHatchTeam), teamNames(CFG.hatchBrontoTeam), teamNames(CFG.hatchSellTeam)):sub(1, 1020), inline = false },
				{ name = ("Hunt Statistics (%d):"):format(totalPets), value = hunt, inline = false },
				{ name = "Egg Statistics :", value = ("> Egg Before: `%d`\n> Current Amount: `%d`\n> Net Result: `%d`\n> Lucky Hatch: `%d` ( %.2f%% )\n> Total Recovery: `%d`")
					:format(eggBefore, curAmt, curAmt - eggBefore, recovery, luckyHatch, recovery), inline = false },
				{ name = "Recovery Proc (Real) :", value = (function()
					local p = ctx.getProcStats()
					return ("> Koi (hatch): `%d/%d` ( %.1f%% )\n> Seal (sell): `%d/%d` ( %.1f%% )\n> Net per egg: `%+.2f` %s")
						:format(p.koiHits, p.koiRolls, p.koiPct, p.sealHits, p.sealRolls, p.sealPct, p.netPerEgg,
							p.netPerEgg >= 0 and "\u{2705}" or "\u{26A0}\u{FE0F} bocor")
				end)(), inline = false },
				{ name = "Hatch Statistics :", value = ("> Hatch Cycles: `%d`\n> Total Hatched: `%d`\n> Sell Cycle: `%d / %d`\n> Cycle Duration: `%s`\n> All Time Duration: `%s`")
					:format(hatchCycles, hatched, ((ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0)), CFG.sellEveryNCycles or 1,
						fmtDur(os.time() - (ctx.state.hatchCycleStartTime or os.time())), fmtDur(os.time() - (ctx.state.hatchStartTime or os.time()))), inline = false },
			},
			footer = { text = os.date("%B %d | %I:%M %p") },
		} } }
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
		ctx.state.hatchCycleStartTime = os.time()
	end
	ctx.hatchSendCycleStats = sendCycleStats
	ctx.hatchTrack = trackHatch

	----------------------------------------------------------------- STATUS
	ctx.state.hatchStatus = "Idle"
	function ctx.getHatchSummary()
		-- team: format per pet "Mutasi - Nama - Berat - Age" (pakai teamNames global)
		local nm = teamNames
		-- max backpack + jumlah egg terpilih
		local d = getData()
		local maxBp = d and d.PetsData and d.PetsData.MutableStats and tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0
		local eggName = CFG.hatchEggName or "Rare Egg"
		local curEgg = 0
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and not t:GetAttribute("PET_UUID") and tostring(t.Name):find(eggName, 1, true) then
					local _, cnt = tostring(t.Name):match("^(.-)%s*x(%d+)$"); if tonumber(cnt) then curEgg = tonumber(cnt) end
				end
			end end
		end
		return {
			status = CFG.hatchEnabled and "RUNNING" or "STOPPED",
			phase = ctx.state.hatchPhase or "-",
			core = nm(CFG.hatchCoreTeam), hatch = nm(CFG.hatchHatchTeam),
			bronto = nm(CFG.hatchBrontoTeam), sell = nm(CFG.hatchSellTeam),
			backpack = backpackPetCount(), maxBackpack = maxBp,
			currentEgg = eggName, eggBefore = ctx.state.hatchEggBefore or curEgg, currentAmount = curEgg,
			eggsHatched = ctx.state.hatchEggsHatched or 0,
			sellCycles = ctx.state.hatchSellCycles or 0,
			ready = #readyEggs(),
			placed = placedEggCount(),
			maxPlaced = CFG.hatchMaxPlaced or 9,
			sellMode = CFG.sellMode or "Cycle",
			cycleProg = (ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0),
			cycleTarget = CFG.sellEveryNCycles or 1,
			proc = ctx.getProcStats(),
		}
	end

	----------------------------------------------------------------- LOOP
	local function tick()
		local bpc = backpackPetCount()
		local maxP = CFG.hatchMaxPlaced or 9
		-- cycle = jumlah RONDE hatch (tiap 1 batch garden selesai di-hatch = 1 cycle)
		local cycle = ctx.state.hatchRounds or 0
		-- 1) SELL trigger: mode "Cycle" (tiap N cycle) atau "Backpack" (pas penuh)
		local sellNow = false
		if CFG.autoSellEnabled then
			if CFG.sellMode == "Cycle" then
				sellNow = (cycle - (ctx.state.hatchLastSellCycle or 0)) >= (CFG.sellEveryNCycles or 1)
			else
				sellNow = bpc >= (CFG.sellWhenReach or 100)
			end
		end
		if sellNow then
			ctx.state.hatchPhase = "Selling Pets"
			if next(CFG.hatchSellTeam or {}) and not equipTeam(CFG.hatchSellTeam, "Sell Team") then return end -- team wajib lengkap
			task.wait(CFG.sellTeamDelay or 5)
			-- ukur recovery Seal: egg total sebelum vs sesudah sell (nunggu server sync)
			local eggBeforeSell = totalEggCount()
			local sold = doSell()
			recordProc("seal", sold or 0, measureRecovery(eggBeforeSell, 5))
			ctx.state.hatchLastSellCycle = cycle
			task.spawn(sendCycleStats) -- summary per sell cycle
			return
		end
		-- clamp target ke kapasitas farm biar ga nyangkut (mis. Max Placed > MaxEggsInFarm)
		local d = getData()
		local farmCap = d and d.PetsData and d.PetsData.MutableStats and d.PetsData.MutableStats.MaxEggsInFarm or maxP
		maxP = math.min(maxP, farmCap)

		local placed = placedEggCount()

		-- 2) PLACE (best-effort): tambah egg kalau kurang. JANGAN stuck kalau ga bisa penuh
		--    (grid bentrok egg recovered / kapasitas farm mentok) -> lanjut proses egg yg ada.
		if placed < maxP then
			ctx.state.hatchPhase = ("Placing Eggs (%d/%d)"):format(placed, maxP)
			if not equipTeam(CFG.hatchCoreTeam, "Core Team") then return end -- team wajib lengkap dulu
			local added = placeEggs(maxP)
			placed = placedEggCount()
			if added > 0 and placed < maxP then return end -- masih nambah -> lanjut place tick berikut
			-- added==0 (mentok) & belum penuh -> anti-stuck: lanjut proses egg yg udah ada
		end

		local ready = readyEggs()
		-- 3) HATCH: HANYA kalau SEMUA egg (yg ke-place) udah READY (jangan switch selama timer jalan)
		if placed > 0 and #ready >= placed then
			ctx.state.hatchPhase = "Hatching"
			-- klasifikasi tiap egg: normal (Hatch team) / bronto (Bronto team) / skip
			local normal, bronto = {}, {}
			for _, e in ipairs(ready) do
				local c = classifyEgg(e)
				if c == "bronto" then bronto[#bronto + 1] = e
				elseif c == "normal" then normal[#normal + 1] = e end
			end
			local function hatchList(list)
				for _, e in ipairs(list) do
					if not CFG.hatchEnabled then break end
					local pt, w = eggPending(e)
					if pt then trackHatch(pt, w) end
					if CFG.hatchReequipTrick then quickReequip(CFG.hatchHatchTeam) end -- eksperimen: cabut-pasang Koi
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
					task.wait(CFG.hatchSpeed or 0.2)
				end
			end
			-- pass NORMAL -> Hatch Team (Koi recovery, tanpa boost berat)
			if #normal > 0 then
				if next(CFG.hatchHatchTeam or {}) and not equipTeam(CFG.hatchHatchTeam, "Hatch Team") then return end
				ctx.state.hatchPhase = ("Hatching Hatch-team (%d)"):format(#normal)
				-- ukur recovery Koi: egg total naik selama pass hatch = egg balik dari Koi
				local eggBeforeHatch = totalEggCount()
				hatchList(normal)
				recordProc("koi", #normal, measureRecovery(eggBeforeHatch, 5))
			end
			-- pass BRONTO -> Bronto Team (+30% berat) + kirim Hatch Alert per pet
			if #bronto > 0 then
				if next(CFG.hatchBrontoTeam or {}) and not equipTeam(CFG.hatchBrontoTeam, "Bronto Team") then return end
				ctx.state.hatchPhase = ("Hatching Bronto-team (%d)"):format(#bronto)
				for _, e in ipairs(bronto) do
					if not CFG.hatchEnabled then break end
					local pt, w = eggPending(e)
					if pt then trackHatch(pt, w); task.spawn(function() sendHatchAlert(pt, CFG.hatchEggName or "Rare Egg", w) end) end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
					task.wait(CFG.hatchSpeed or 0.2)
				end
			end
			-- 1 batch (normal+bronto) selesai = 1 ronde/cycle
			ctx.state.hatchRounds = (ctx.state.hatchRounds or 0) + 1
			return
		end

		-- 4) INCUBATE: masih ada egg belum ready -> TETAP Core Team (speed), jangan switch/hatch
		ctx.state.hatchPhase = ("Incubating (%d/%d ready)"):format(#ready, placed)
		equipTeam(CFG.hatchCoreTeam, "Core Team")
		ctx.state.hatchStatus = ("Nunggu egg ready (%d/%d)..."):format(#ready, placed)
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
		-- catat jumlah egg terpilih di awal (buat "Egg Before") — scan Backpack + Character
		local eggName = CFG.hatchEggName or "Rare Egg"
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and not t:GetAttribute("PET_UUID") and tostring(t.Name):find(eggName, 1, true) then
					local _, cnt = tostring(t.Name):match("^(.-)%s*x(%d+)$"); if tonumber(cnt) then ctx.state.hatchEggBefore = tonumber(cnt) end
				end
			end end
		end
		ctx.state.hatchStartTime = ctx.state.hatchStartTime or os.time()
		ctx.state.hatchCycleStartTime = os.time()
		task.spawn(loop)
	end
	function ctx.stopHatch()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		ctx.state.hatchStatus = "Idle"
	end
end
