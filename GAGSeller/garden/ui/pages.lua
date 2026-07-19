--[[ pages.lua — halaman garden. Tab: Pet, Elephant, Growth, Leveling, Mutation, Event, Inventory, Shop, Misc.
     Isi utama ada di tab Inventory (Automation Trade + Automation Accept + Automation Favourite). ]]
return function(ctx)
	local C = ctx.C
	local CFG = ctx.CFG
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad
	local persist = ctx.persistState
	local reg = ctx.reg
	local function log(m) ctx.log(m) end

	local makePage = ctx.makePage
	local makeAccordion = ctx.makeAccordion
	local makeToggle = ctx.makeToggle
	local makeInput = ctx.makeInput
	local makeSingleDropdown = ctx.makeSingleDropdown
	local makeMultiDropdown = ctx.makeMultiDropdown
	local makeMultiDropdownDyn = ctx.makeMultiDropdownDyn
	local makeButton = ctx.makeButton

	-- sidebar tabs (urut sesuai referensi)
	local TABS = {
		{ "Pet", "Pet", "🐾" },
		{ "Elephant", "Elephant", "🐘" },
		{ "Growth", "Growth", "🌱" },
		{ "Hatch", "Hatch", "🥚" },
		{ "Leveling", "Leveling", "⚡" },
		{ "Mutation", "Mutation", "🧪" },
		{ "Event", "Event", "☀️" },
		{ "Inventory", "Inventory", "🎒" },
		{ "Shop", "Shop", "🛒" },
		{ "Misc", "Misc", "⚙️" },
	}
	local pageRef = {}
	for i, t in ipairs(TABS) do
		pageRef[t[1]] = makePage(t[1], t[2], t[3], i)
	end

	-- placeholder untuk tab yang belum diisi
	local function placeholder(page)
		local box = mk("Frame", { Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = C.row, LayoutOrder = 1 }, page)
		corner(box, 8); stroke(box); pad(box, 14, 14, 12, 12)
		mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Fitur untuk tab ini belum tersedia.", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, box)
	end
	------------------------------------------------------------------ GROWTH (pipeline batch per-step)
	do
		local growthPage = pageRef["Growth"]
		local FLOW_OPTS = { { name = "elephant", display = "Elephant" }, { name = "mutation", display = "Mutation" }, { name = "leveling", display = "Leveling" } }
		local function capStep(s) for _, o in ipairs(FLOW_OPTS) do if o.name == s then return o.display end end return "Select" end

		-- Growth Control (status + target + enable)
		local gCtrl = makeAccordion(growthPage, "Growth Control", 1, true)
		local gLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "Loading...", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LineHeight = 1.35, RichText = true, LayoutOrder = 0 }, gCtrl)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, gCtrl)
		task.spawn(function()
			while ctx.alive() do
				local ok, s = pcall(function() return ctx.getGrowthSummary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					local steps = ""
					for _, st in ipairs({ "elephant", "mutation", "leveling" }) do
						local ps = s.perStep[st]
						if ps then steps = steps .. ("%s: <font color=\"#8c929e\">%d/%d</font>\n"):format(st, ps.done, ps.total) end
					end
					gLbl.Text = string.format(
						"Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n" ..
						"Flow: <font color=\"#8c929e\">%s</font>\nTarget: <font color=\"#8c929e\">%s</font>\n\n%s\n" ..
						"Team Elephant: <font color=\"#8c929e\">%s</font>\n" ..
						"Team Mutation: <font color=\"#8c929e\">%s</font>\n" ..
						"Team Leveling P1: <font color=\"#8c929e\">%s</font>\n" ..
						"Team Leveling P2: <font color=\"#8c929e\">%s</font>",
						col, s.status, s.step, s.flow, s.types, steps,
						s.teamElephant or "-", s.teamMutation or "-", s.teamLevP1 or "-", s.teamLevP2 or "-")
				end
				task.wait(1.5)
			end
		end)
		makeMultiDropdown(gCtrl, "Growth Target Pet Types", "Pet yang diproses lewat semua step (semua pet game)",
			reg.PET_OPTIONS, CFG.growthPetTypes, function() persist() end, 2)
		makeToggle(gCtrl, "Enable Growth", "Jalankan pipeline (batch per-step sesuai flow)",
			function() return CFG.growthEnabled end,
			function(v) CFG.growthEnabled = v; persist(); if v then ctx.startGrowth() else ctx.stopGrowth() end end, 3)

		-- Configuration Auto Elephant
		local gEle = makeAccordion(growthPage, "Configuration Auto Elephant", 2, true)
		makeMultiDropdownDyn(gEle, "Elephant Pet Team", "Team aura buat grow weight",
			function() return ctx.inventoryPetOptions(CFG.growthElephantTeam) end, CFG.growthElephantTeam, function() persist() end, 1)
		makeInput(gEle, "Target Weight (KG)", "Berat target sebelum lanjut step berikutnya (mis. 5.5)",
			function() return tostring(CFG.growthElephantWeight) end, function(t) CFG.growthElephantWeight = tonumber(t) or 5.5; persist() end, 2)
		makeInput(gEle, "Max Target Pets", "Max pet target di garden (step Elephant)",
			function() return tostring(CFG.growthElephantMax) end, function(t) CFG.growthElephantMax = tonumber(t) or 2; persist() end, 3)

		-- Configuration Auto Mutation
		local gMut = makeAccordion(growthPage, "Configuration Auto Mutation", 3, true)
		makeMultiDropdownDyn(gMut, "Mutation Pet Team", "Team aura pemberi mutasi",
			function() return ctx.inventoryPetOptions(CFG.growthMutationTeam) end, CFG.growthMutationTeam, function() persist() end, 1)
		makeMultiDropdown(gMut, "Target Mutations", "Mutasi yang diinginkan (mutasi salah -> auto cleanse)",
			reg.MUT_OPTIONS, CFG.growthMutationTargets, function() persist() end, 2)
		makeInput(gMut, "Max Target Pets", "Max pet target di garden (step Mutation)",
			function() return tostring(CFG.growthMutationMax) end, function(t) CFG.growthMutationMax = tonumber(t) or 2; persist() end, 3)

		-- Configuration Auto Leveling (2 phase)
		local gLev = makeAccordion(growthPage, "Configuration Auto Leveling", 4, true)
		makeMultiDropdownDyn(gLev, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
			function() return ctx.inventoryPetOptions(CFG.growthLevP1Team) end, CFG.growthLevP1Team, function() persist() end, 1)
		makeInput(gLev, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
			function() return tostring(CFG.growthLevP1Target) end, function(t) CFG.growthLevP1Target = tonumber(t) or 40; persist() end, 2)
		makeInput(gLev, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
			function() return tostring(CFG.growthLevP1Max) end, function(t) CFG.growthLevP1Max = tonumber(t) or 3; persist() end, 3)
		makeMultiDropdownDyn(gLev, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
			function() return ctx.inventoryPetOptions(CFG.growthLevP2Team) end, CFG.growthLevP2Team, function() persist() end, 4)
		makeInput(gLev, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
			function() return tostring(CFG.growthLevP2Target) end, function(t) CFG.growthLevP2Target = tonumber(t) or 500; persist() end, 5)
		makeInput(gLev, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
			function() return tostring(CFG.growthLevP2Max) end, function(t) CFG.growthLevP2Max = tonumber(t) or 1; persist() end, 6)

		-- Configuration Flow (Step 1/2/3)
		local gFlow = makeAccordion(growthPage, "Configuration Flow", 5, true)
		local stepDesc = { "First step in growth flow", "Second step in growth flow", "Third step in growth flow" }
		for i = 1, 3 do
			makeSingleDropdown(gFlow, "Step " .. i, stepDesc[i],
				function() return FLOW_OPTS end,
				function() return capStep((CFG.growthFlow or {})[i]) end,
				function(code) CFG.growthFlow = CFG.growthFlow or {}; CFG.growthFlow[i] = code; persist() end, i)
		end
	end

	------------------------------------------------------------------ HATCH (auto hatch + auto sell)
	do
		local hatchPage = pageRef["Hatch"]

		-- Status & Control
		local hCtrl = makeAccordion(hatchPage, "Status & Control", 1, false)
		local hLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "Loading...", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LineHeight = 1.35, RichText = true, LayoutOrder = 0 }, hCtrl)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, hCtrl)
		task.spawn(function()
			while ctx.alive() do
				local ok, s = pcall(function() return ctx.getHatchSummary() end)
				if ok and s then
					local col = s.status == "RUNNING" and "#5acc78" or "#dc5050"
					hLbl.Text = string.format(
						"Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n" ..
						"Core Team: <font color=\"#8c929e\">%s</font>\nHatch Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Bronto Team: <font color=\"#8c929e\">%s</font>\nSell Team: <font color=\"#8c929e\">%s</font>\n\n" ..
						"Backpack pet: <font color=\"#8c929e\">%d</font>\nEgg placed: <font color=\"#8c929e\">%d/%d</font>  |  ready: <font color=\"#8c929e\">%d</font>\n" ..
						"Eggs hatched: <font color=\"#8c929e\">%d</font>\nSell cycle (%s): <font color=\"#8c929e\">%d/%d</font>  |  sold: <font color=\"#8c929e\">%d</font>",
						col, s.status, s.phase, s.core, s.hatch, s.bronto, s.sell, s.backpack, s.placed, s.maxPlaced, s.ready, s.eggsHatched, s.sellMode, s.cycleProg, s.cycleTarget, s.sellCycles)
				end
				task.wait(1.0)
			end
		end)
		makeToggle(hCtrl, "Auto Hatch", "Start/Stop auto hatching (equip Hatch team + hatch egg ready)",
			function() return CFG.hatchEnabled end,
			function(v) CFG.hatchEnabled = v; persist(); if v then ctx.startHatch() else ctx.stopHatch() end end, 2)
		makeToggle(hCtrl, "Auto Sell", "Auto jual pet pas backpack penuh (filter + favorite proteksi)",
			function() return CFG.autoSellEnabled end, function(v) CFG.autoSellEnabled = v; persist() end, 3)

		-- Teams
		local hTeam = makeAccordion(hatchPage, "Teams (Core / Hatch / Bronto / Sell)", 2, true)
		makeMultiDropdownDyn(hTeam, "Core Team", "Percepat egg (incubation speed)",
			function() return ctx.inventoryPetOptions(CFG.hatchCoreTeam) end, CFG.hatchCoreTeam, function() persist() end, 1)
		makeMultiDropdownDyn(hTeam, "Hatch Team", "Hatch egg ready (Koi = balikin egg)",
			function() return ctx.inventoryPetOptions(CFG.hatchHatchTeam) end, CFG.hatchHatchTeam, function() persist() end, 2)
		makeMultiDropdownDyn(hTeam, "Bronto Team", "+30% berat pet pas hatch (Brontosaurus)",
			function() return ctx.inventoryPetOptions(CFG.hatchBrontoTeam) end, CFG.hatchBrontoTeam, function() persist() end, 3)
		makeMultiDropdownDyn(hTeam, "Sell Team", "Jual + balikin pet jadi egg (Seal the Deal)",
			function() return ctx.inventoryPetOptions(CFG.hatchSellTeam) end, CFG.hatchSellTeam, function() persist() end, 4)

		-- Egg Configuration
		local hEgg = makeAccordion(hatchPage, "Egg Configuration", 3, true)
		makeSingleDropdown(hEgg, "Egg to Hatch", "Egg dari backpack yg di-place & di-hatch (+ jumlah)",
			function() return ctx.getEggBackpackOptions() end,
			function() return tostring(CFG.hatchEggName or "") end,
			function(code) CFG.hatchEggName = code; persist() end, 1)
		makeInput(hEgg, "Max Placed", "Maksimal egg ke-place di garden",
			function() return tostring(CFG.hatchMaxPlaced) end, function(t) CFG.hatchMaxPlaced = tonumber(t) or 9; persist() end, 2)
		makeInput(hEgg, "Hatch Speed (delay/hatch, sec)", "Jeda per hatch; makin kecil makin cepat (mis. 0.1)",
			function() return tostring(CFG.hatchSpeed) end, function(t) CFG.hatchSpeed = math.max(0.05, tonumber(t) or 0.2); persist() end, 3)

		-- Bronto Configuration (kapan pakai Bronto team buat +30% berat)
		local hBr = makeAccordion(hatchPage, "Bronto Configuration", 4, true)
		makeMultiDropdown(hBr, "Special Pets", "Pet yg WAJIB di-hatch pakai Bronto team",
			reg.PET_EGG_OPTIONS, CFG.brontoSpecialPets, function() persist() end, 1)
		makeInput(hBr, "Special Pets Weight Filter", "Special cuma kalau weight > ini (0 = ga difilter)",
			function() return tostring(CFG.brontoSpecialWeight) end, function(t) CFG.brontoSpecialWeight = tonumber(t) or 0; persist() end, 2)
		makeMultiDropdown(hBr, "Universal Weight Pet Types", "Tipe pet buat aturan universal (kosong = semua)",
			reg.PET_OPTIONS, CFG.brontoUniversalTypes, function() persist() end, 3)
		makeInput(hBr, "Universal Weight Threshold", "Pakai Bronto team kalau weight > ini (0 = off)",
			function() return tostring(CFG.brontoUniversalWeight) end, function(t) CFG.brontoUniversalWeight = tonumber(t) or 0; persist() end, 4)
		makeToggle(hBr, "Don't Hatch Special Pets", "Skip special pet sama sekali (jangan di-hatch)",
			function() return CFG.brontoSkipSpecial end, function(v) CFG.brontoSkipSpecial = v; persist() end, 5)

		-- Sell Configuration
		local hSell = makeAccordion(hatchPage, "Sell Configuration", 5, true)
		makeMultiDropdown(hSell, "Pets to Sell", "Tipe pet yg DIJUAL (sisanya difavoritin biar aman)",
			reg.PET_EGG_OPTIONS, CFG.sellPetTypes, function() persist() end, 1)
		makeInput(hSell, "Sell Weight Threshold", "Jual kalau base weight < ini",
			function() return tostring(CFG.sellWeightThreshold) end, function(t) CFG.sellWeightThreshold = tonumber(t) or 4; persist() end, 2)
		makeInput(hSell, "Sell Age Threshold", "Jual kalau age < ini",
			function() return tostring(CFG.sellAgeThreshold) end, function(t) CFG.sellAgeThreshold = tonumber(t) or 3; persist() end, 3)
		makeMultiDropdown(hSell, "Special Pets to Sell", "Pet spesial (jual by weight)",
			reg.PET_EGG_OPTIONS, CFG.sellSpecialTypes, function() persist() end, 4)
		makeInput(hSell, "Special Pet Weight Threshold", "Jual pet spesial dgn weight < ini (0=off)",
			function() return tostring(CFG.sellSpecialWeight) end, function(t) CFG.sellSpecialWeight = tonumber(t) or 10; persist() end, 5)
		local SELLMODE = { { name = "Cycle", display = "Cycle" }, { name = "Backpack", display = "Backpack" } }
		makeSingleDropdown(hSell, "Sell Mode", "Kapan trigger jual",
			function() return SELLMODE end, function() return CFG.sellMode or "Cycle" end,
			function(code) CFG.sellMode = code; persist() end, 6)
		local SELLSTYLE = { { name = "All at Once", display = "All at Once" }, { name = "One by One", display = "One by One" } }
		makeSingleDropdown(hSell, "Sell Style", "All at Once = jual semua matched sekaligus",
			function() return SELLSTYLE end, function() return CFG.sellStyle or "All at Once" end,
			function(code) CFG.sellStyle = code; persist() end, 7)
		makeInput(hSell, "Sell Every N Cycles", "Jual tiap N cycle hatch",
			function() return tostring(CFG.sellEveryNCycles) end, function(t) CFG.sellEveryNCycles = tonumber(t) or 1; persist() end, 8)
		makeInput(hSell, "Sell When Pets Reach", "Jual kalau backpack pet >= ini",
			function() return tostring(CFG.sellWhenReach) end, function(t) CFG.sellWhenReach = tonumber(t) or 100; persist() end, 9)
		makeInput(hSell, "Sell Team Delay (sec)", "Tunggu abis swap team sebelum jual",
			function() return tostring(CFG.sellTeamDelay) end, function(t) CFG.sellTeamDelay = tonumber(t) or 5; persist() end, 10)
		makeToggle(hSell, "Auto Boost Before Sell", "Boost pet aktif pakai toy sebelum jual",
			function() return CFG.autoBoostBeforeSell end, function(v) CFG.autoBoostBeforeSell = v; persist() end, 11)
		makeButton(hSell, "Sell Now (manual)", "Jalankan sell sekali sekarang",
			function() task.spawn(function() pcall(ctx.hatchDoSell) end) end, 12)
	end

	------------------------------------------------------------------ SHOP
	do
		local shopPage = pageRef["Shop"]

		local seedAcc = makeAccordion(shopPage, "Automation Buy Seed", 1, false)
		makeMultiDropdownDyn(seedAcc, "Select Seeds to Buy", "Pilih seed buat auto-beli (stock realtime)",
			function() return ctx.getSeedShopOptions(CFG.buySeedNames) end, CFG.buySeedNames, function() persist() end, 1)
		makeToggle(seedAcc, "Enable Automation Buy Seed", "Auto-beli seed terpilih tiap ada stock",
			function() return CFG.buySeedEnabled end,
			function(v) CFG.buySeedEnabled = v; persist(); if v then ctx.startBuySeed() end end, 2)

		local eggAcc = makeAccordion(shopPage, "Automation Buy Egg", 2, false)
		makeMultiDropdownDyn(eggAcc, "Select Eggs to Buy", "Pilih egg buat auto-beli (stock realtime)",
			function() return ctx.getEggShopOptions(CFG.buyEggNames) end, CFG.buyEggNames, function() persist() end, 1)
		makeToggle(eggAcc, "Enable Automation Buy Egg", "Auto-beli egg terpilih tiap ada stock",
			function() return CFG.buyEggEnabled end,
			function(v) CFG.buyEggEnabled = v; persist(); if v then ctx.startBuyEgg() end end, 2)

		local gearAcc = makeAccordion(shopPage, "Automation Buy Gear", 3, false)
		makeMultiDropdownDyn(gearAcc, "Select Gear to Buy", "Pilih gear buat auto-beli (stock realtime)",
			function() return ctx.getGearShopOptions(CFG.buyGearNames) end, CFG.buyGearNames, function() persist() end, 1)
		makeToggle(gearAcc, "Enable Automation Buy Gear", "Auto-beli gear terpilih tiap ada stock",
			function() return CFG.buyGearEnabled end,
			function(v) CFG.buyGearEnabled = v; persist(); if v then ctx.startBuyGear() end end, 2)
	end

	------------------------------------------------------------------ ELEPHANT (V1)
	do
		local elephantPage = pageRef["Elephant"]
		local acc = makeAccordion(elephantPage, "Automation Elephant V1", 1, true)

		-- Status (live)
		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading stats...",
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, acc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, acc)
		task.spawn(function()
			while ctx.alive() do
				local ok, s = pcall(function() return ctx.getElephantSummary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n\n" ..
						"Max Target Pets: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>",
						col, s.status, s.team, s.types, s.ready, s.maxKg, s.maxTarget, s.targetWeight)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (dalam accordion yang sama)
		makeMultiDropdownDyn(acc, "V1 Pet Team", "Select elephant pet team (tetap di garden)",
			function() return ctx.inventoryPetOptions(CFG.elephantTeamUuids) end, CFG.elephantTeamUuids, function() persist() end, 2)
		makeMultiDropdown(acc, "V1 Target Pet Types", "Select pet types to auto-elephant (semua pet di game)",
			reg.PET_OPTIONS, CFG.elephantPetTypes, function() persist() end, 3)
		makeInput(acc, "Target Weight (KG)", "Berat max sebelum diganti (mis. 5.5)",
			function() return tostring(CFG.elephantTargetWeight) end,
			function(txt) CFG.elephantTargetWeight = tonumber(txt) or 5.5; persist() end, 4)
		makeInput(acc, "Max Target Pets", "Jumlah pet target aktif barengan",
			function() return tostring(CFG.elephantMaxPets) end,
			function(txt) CFG.elephantMaxPets = tonumber(txt) or 2; persist() end, 5)
		makeToggle(acc, "Enable Automation Elephant", "Rotasi pet target otomatis. OFF = cabut semua pet dari garden.",
			function() return CFG.elephantEnabled end,
			function(v)
				CFG.elephantEnabled = v; persist()
				if v then ctx.startElephant() else ctx.stopElephant() end
			end, 6)
	end

	------------------------------------------------------------------ LEVELING
	local levelingPage = pageRef["Leveling"]
	do
		-- Automation Leveling V1 — status + settings jadi satu accordion
		local levAcc = makeAccordion(levelingPage, "Automation Leveling V1", 1, true)

		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "Loading stats...",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LineHeight = 1.35,
			RichText = true,
			LayoutOrder = 0
		}, levAcc)
		-- spacer pemisah status & settings
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, levAcc)

		task.spawn(function()
			while ctx.alive() do
				local ok, s = pcall(function() return ctx.getLevelingSummary() end)
				if ok and s then
					local statusColor = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"<b>Current Settings:</b>\n" ..
						"Pet Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Pets Ready to Level: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max Level: <font color=\"#8c929e\">%s</font>\n" ..
						"Max in Garden: <font color=\"#8c929e\">%s</font>\n\n" ..
						"Target Level: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Ready: Settings configured",
						statusColor, s.status,
						s.team,
						s.types,
						s.ready,
						s.maxLvl,
						s.maxInGarden,
						s.targetLevel
					)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (di accordion yang sama, setelah status + spacer)
		-- Leveling Pet Team (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(levAcc, "Leveling Pet Team", "Select pets to keep in garden while leveling",
			function() return ctx.inventoryPetOptions(CFG.levelingTeamUuids) end, CFG.levelingTeamUuids, function() persist() end, 2)

		-- Leveling Pet Types (semua pet di game, bukan cuma yang di inventory)
		makeMultiDropdown(levAcc, "Leveling Pet Types", "Select pet types to auto-level (semua pet di game)",
			reg.PET_OPTIONS, CFG.levelingPetTypes, function() persist() end, 3)

		-- Target Level (Input)
		makeInput(levAcc, "Target Level", "Target level to reach before un-equipping",
			function() return tostring(CFG.levelingTargetLevel) end,
			function(txt) CFG.levelingTargetLevel = tonumber(txt) or 500; persist() end, 4)

		-- Max Pets in Garden (Input)
		makeInput(levAcc, "Max Pets in Garden", "Maximum active leveling pets allowed in garden",
			function() return tostring(CFG.levelingMaxPets) end,
			function(txt) CFG.levelingMaxPets = tonumber(txt) or 2; persist() end, 5)

		-- Enable Automation Leveling (Toggle)
		makeToggle(levAcc, "Enable Automation Leveling", "Equip and rotate pets automatically based on settings",
			function() return CFG.levelingEnabled end,
			function(v)
				CFG.levelingEnabled = v; persist()
				if v then ctx.startLeveling() else ctx.stopLeveling() end
			end, 6)

		---------------------------------------------------------- Automation Leveling V2 (2 phase)
		local lv2 = makeAccordion(levelingPage, "Automation Leveling V2", 2, true)

		local lv2Lbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			Text = "Loading...", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, lv2)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, lv2)
		task.spawn(function()
			while ctx.alive() do
				local ok, s = pcall(function() return ctx.getLevelingV2Summary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					lv2Lbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
						"<b>Target Types:</b> <font color=\"#8c929e\">%s</font>\n\n" ..
						"<b>Phase 1</b> (→%s): team <font color=\"#8c929e\">%d</font> | antre <font color=\"#f5c82d\">%d</font> pet\n" ..
						"<b>Phase 2</b> (→%s): team <font color=\"#8c929e\">%d</font> | antre <font color=\"#f5c82d\">%d</font> pet",
						col, s.status, s.phase, s.types,
						tostring(s.p1target), s.p1team, s.p1queue,
						tostring(s.p2target), s.p2team, s.p2queue)
				end
				task.wait(1.5)
			end
		end)

		-- Target Pet Types (semua pet di game)
		makeMultiDropdown(lv2, "Leveling Target Pet Types", "Pet types to level up (semua pet di game)",
			reg.PET_OPTIONS, CFG.levelingV2PetTypes, function() persist() end, 2)

		-- Phase 1
		makeMultiDropdownDyn(lv2, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
			function() return ctx.inventoryPetOptions(CFG.levelingV2P1Team) end, CFG.levelingV2P1Team, function() persist() end, 3)
		makeInput(lv2, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
			function() return tostring(CFG.levelingV2P1Target) end,
			function(txt) CFG.levelingV2P1Target = tonumber(txt) or 40; persist() end, 4)
		makeInput(lv2, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
			function() return tostring(CFG.levelingV2P1Max) end,
			function(txt) CFG.levelingV2P1Max = tonumber(txt) or 3; persist() end, 5)

		-- Phase 2
		makeMultiDropdownDyn(lv2, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
			function() return ctx.inventoryPetOptions(CFG.levelingV2P2Team) end, CFG.levelingV2P2Team, function() persist() end, 6)
		makeInput(lv2, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
			function() return tostring(CFG.levelingV2P2Target) end,
			function(txt) CFG.levelingV2P2Target = tonumber(txt) or 500; persist() end, 7)
		makeInput(lv2, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
			function() return tostring(CFG.levelingV2P2Max) end,
			function(txt) CFG.levelingV2P2Max = tonumber(txt) or 1; persist() end, 8)

		-- Enable
		makeToggle(lv2, "Enable Automation Leveling V2", "Level pet 2 tahap (Phase 1 team -> Phase 2 team)",
			function() return CFG.levelingV2Enabled end,
			function(v)
				CFG.levelingV2Enabled = v; persist()
				if v then ctx.startLevelingV2() else ctx.stopLevelingV2() end
			end, 9)
	end

	------------------------------------------------------------------ MUTATION
	local mutationPage = pageRef["Mutation"]
	do
		-- 1. Status Accordion
		local statusAcc = makeAccordion(mutationPage, "Automation Mutation Machine", 1, true)
		
		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "Loading stats...",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LineHeight = 1.35,
			RichText = true,
			LayoutOrder = 0
		}, statusAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, statusAcc)

		task.spawn(function()
			while ctx.alive() do
				local ok, s = pcall(function() return ctx.getMutationSummary() end)
				if ok and s then
					local statusColor = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Status: <font color=\"%s\"><b>%s</b></font>\n" ..
						"Phase: <b>%s</b>\n\n" ..
						"EXP Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Boost Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Phoenix Team: <font color=\"#8c929e\">%d pets</font>\n\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Keep Mutations: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Age: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Machine: <font color=\"#85d0ff\"><b>%s</b></font>\n\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Target Pets Done: <font color=\"#5acc78\"><b>%d pets</b></font>",
						statusColor, s.status,
						s.phase,
						s.expCount,
						s.boostCount,
						s.phoenixCount,
						s.types,
						s.mutations,
						tostring(s.targetAge),
						s.machine,
						s.readyCount,
						s.doneCount
					)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (dalam accordion yang sama dengan status)
		local settingsAcc = statusAcc

		-- EXP Team (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "EXP Team (Leveling)", "Pets for leveling target to age 50/500",
			function() return ctx.inventoryPetOptions(CFG.mutationExpTeam) end, CFG.mutationExpTeam, function() persist() end, 2)

		-- Boost Team (Machine) (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Boost Team (Machine)", "Pets for boosting mutation machine speed",
			function() return ctx.inventoryPetOptions(CFG.mutationBoostTeam) end, CFG.mutationBoostTeam, function() persist() end, 3)

		-- Phoenix Team (Claim) (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Phoenix Team (Claim)", "Pets for claiming mutated pet",
			function() return ctx.inventoryPetOptions(CFG.mutationPhoenixTeam) end, CFG.mutationPhoenixTeam, function() persist() end, 4)

		-- Target Pet Types (semua pet di game, bukan cuma yang di inventory)
		makeMultiDropdown(settingsAcc, "Target Pet Types", "Pet types to mutate (semua pet di game)",
			reg.PET_OPTIONS, CFG.mutationTargetTypes, function() persist() end, 5)

		-- Target Mutations (Multi-dropdown Mutations)
		makeMultiDropdown(settingsAcc, "Target Mutations (Machine)", "Stop when pet gets these mutations (hanya mutasi mesin)",
			ctx.reg.MACHINE_MUT_OPTIONS or ctx.reg.MUT_OPTIONS or {"None"}, CFG.mutationTargetMutations, function() persist() end, 6)

		-- Target Age (Input)
		makeInput(settingsAcc, "Target Age", "Level to reach before submitting (e.g. 50 or 500)",
			function() return tostring(CFG.mutationTargetAge) end,
			function(txt) CFG.mutationTargetAge = tonumber(txt) or 50; persist() end, 7)

		-- Delay Auto Claim (Input)
		makeInput(settingsAcc, "Delay Auto Claim (sec)", "Wait before claiming mutated pet from machine",
			function() return tostring(CFG.mutationDelayAutoClaim) end,
			function(txt) CFG.mutationDelayAutoClaim = tonumber(txt) or 0.5; persist() end, 8)

		-- Enable Auto Mutation Machine (Toggle)
		ctx.state.mutationToggleRender = makeToggle(settingsAcc, "Enable Auto Mutation Machine", "Submit, start, and claim mutated pets automatically",
			function() return CFG.mutationEnabled end,
			function(v)
				CFG.mutationEnabled = v; persist()
				if v then ctx.startMutation() else ctx.stopMutation() end
			end, 9)

		-- Accordion: Automation Mutation (mutasi via aura + cleanse)
		local cleanseAcc = makeAccordion(mutationPage, "Automation Mutation", 2, false)

		-- Status (live)
		local cleanseLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading stats...",
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, cleanseAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, cleanseAcc)
		task.spawn(function()
			while ctx.alive() do
				local ok, s = pcall(function() return ctx.getCleanseSummary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					local alreadyLines = ""
					for _, k in ipairs(s.keepOrder) do
						alreadyLines = alreadyLines .. string.format("- Already %s: <font color=\"#8c929e\">%d pets</font>\n", k, s.already[k] or 0)
					end
					cleanseLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"Mutation Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Mutations to Keep: <font color=\"#f5c82d\">%s</font>\n\n" ..
						"Pet Statistics:\n" ..
						"- Pets Ready to Mutation: <font color=\"#8c929e\">%d pets</font>\n" ..
						"%s\n" ..
						"Max in Garden: <font color=\"#8c929e\">%d pets</font>\n\n" ..
						"Status: <font color=\"#85d0ff\">%s</font>",
						col, s.status, s.team, s.types, s.keep, s.ready, alreadyLines, s.maxPets, s.phase)
				end
				task.wait(1.5)
			end
		end)

		makeMultiDropdownDyn(cleanseAcc, "Pet Team for Mutation", "Pet aura pemberi mutasi (tetap di garden)",
			function() return ctx.inventoryPetOptions(CFG.cleanseTeamUuids) end, CFG.cleanseTeamUuids, function() persist() end, 2)
		makeMultiDropdown(cleanseAcc, "Pet Types for Mutation", "Tipe pet target yang mau dimutasi (semua pet di game)",
			reg.PET_OPTIONS, CFG.cleansePetTypes, function() persist() end, 3)
		makeMultiDropdown(cleanseAcc, "Mutations to Keep", "Mutasi ini disimpan (won't be cleansed)",
			ctx.reg.MUT_OPTIONS or {"None"}, CFG.cleanseKeepMutations, function() persist() end, 4)
		makeInput(cleanseAcc, "Max Pets in Garden", "Max pet target di garden barengan",
			function() return tostring(CFG.cleanseMaxPets) end,
			function(txt) CFG.cleanseMaxPets = tonumber(txt) or 2; persist() end, 5)
		makeToggle(cleanseAcc, "Enable Auto Mutation", "Mutasi target via aura; cleanse mutasi salah, simpan mutasi keep",
			function() return CFG.cleanseEnabled end,
			function(v)
				CFG.cleanseEnabled = v; persist()
				if v then ctx.startCleanse() else ctx.stopCleanse() end
			end, 6)
	end

	------------------------------------------------------------------ EVENT
	local eventPage = pageRef["Event"]
	do
		local summerAcc = makeAccordion(eventPage, "Automation Summer Event", 1, true)

		-- Status timer Sam (live)
		local samLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Sam: loading...",
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, summerAcc)
		task.spawn(function()
			while ctx.alive() do
				local ok, s = pcall(function() return ctx.getSamSummary() end)
				if ok and s then
					local col = s.state == "READY" and "#5acc78" or (s.state == "WORKING" and "#f5c82d" or "#8c929e")
					samLbl.Text = string.format(
						"Sam The Clam: <font color=\"%s\"><b>%s</b></font>\n" ..
						"Timer: <font color=\"%s\"><b>%s</b></font>\n" ..
						"Sedang dicerna: <font color=\"#8c929e\">%s</font>\n" ..
						"Reward: <font color=\"#8c929e\">%s</font>",
						col, s.state, col, s.timer, tostring(s.submitted or "-"), tostring(s.reward or "-"))
				end
				task.wait(1)
			end
		end)

		-- Pilih tipe pet yang boleh di-feed ke Sam (kosong = pakai filter berat saja)
		makeMultiDropdownDyn(summerAcc, "Pilih Pet (Feed ke Sam)", "Tipe pet yang boleh dikorbankan. Kosong = pakai filter berat.",
			function() return ctx.getSummerPetTypes(CFG.summerPetTypes) end, CFG.summerPetTypes, function() persist() end, 1)

		-- Berat minimum (KG)
		makeInput(summerAcc, "Berat Min (KG)", "Hanya feed pet >= berat ini. 0 = off",
			function() return tostring(CFG.summerMinWeight) end,
			function(txt) CFG.summerMinWeight = tonumber(txt) or 0; persist() end, 2)

		-- Berat maksimum (KG)
		makeInput(summerAcc, "Berat Max (KG)", "Hanya feed pet <= berat ini. 0 = off",
			function() return tostring(CFG.summerMaxWeight) end,
			function(txt) CFG.summerMaxWeight = tonumber(txt) or 0; persist() end, 3)

		-- Ikutkan pet favorite
		makeToggle(summerAcc, "Ikut Feed Pet Favorite", "Kalau ON, pet favorite juga boleh dikorbankan",
			function() return CFG.summerAllowFavorite end,
			function(v) CFG.summerAllowFavorite = v; persist() end, 4)

		-- Enable Automation Summer Event (Toggle) — auto TP ke Sam sudah otomatis di dalam logic
		makeToggle(summerAcc, "Enable Automation Summer Event", "Auto TP ke Sam + submit pet + claim reward saat timer habis.",
			function() return CFG.summerEventEnabled end,
			function(v)
				CFG.summerEventEnabled = v; persist()
				if v and ctx.startSummerEvent then ctx.startSummerEvent() end
			end, 6)
	end

	------------------------------------------------------------------ PET (PNP)
	local pet = pageRef["Pet"]
	local pnp = makeAccordion(pet, "Automation Pickup Pet", 1, true)

	-- Pilih pet PER-UUID dari INVENTORY/backpack (buka dropdown = auto-refresh daftarnya).
	-- Cuma pet yang dicentang DAN sudah kamu taruh di garden yang bakal di-PNP.
	makeMultiDropdownDyn(pnp, "Select Pets for Pickup", "Pilih pet dari backpack (kosong = semua yg di garden)",
		function() return ctx.inventoryPetOptions(CFG.pnpUuids) end, CFG.pnpUuids, function() persist() end, 1)

	makeInput(pnp, "Pickup Delay (Seconds)", "Jeda tiap siklus (idealnya = saat skill ready)",
		function() return CFG.pickupDelay end,
		function(txt) CFG.pickupDelay = tonumber(txt) or 0.4; persist() end, 2)

	makeInput(pnp, "Equip Delay (Seconds)", "Jeda antara unequip -> equip",
		function() return CFG.equipDelay end,
		function(txt) CFG.equipDelay = tonumber(txt) or 0.02; persist() end, 3)

	makeInput(pnp, "Scan Interval (Seconds)", "Frekuensi cek cooldown (kecil = makin ketat, min 0.01)",
		function() return CFG.pnpScanInterval end,
		function(txt)
			local n = tonumber(txt) or 0.05
			CFG.pnpScanInterval = math.max(0.01, n); persist()
		end, 4)

	makeToggle(pnp, "Enable Automation Pickup", "Pungut & taruh lagi pet buat reset/trigger skill",
		function() return CFG.pnpEnabled end,
		function(v)
			CFG.pnpEnabled = v; persist()
			if v then ctx.startPnp() end
		end, 5)

	local pnpMonitorBtnRender = makeToggle(pnp, "Enable Pet Monitor CD", "Buka jendela mengambang untuk memantau cooldown pet secara live",
		function() return CFG.pnpMonitorEnabled end,
		function(v)
			CFG.pnpMonitorEnabled = v; persist()
			if v then
				ctx.showPetMonitor()
			else
				ctx.hidePetMonitor()
			end
		end, 5)
	ctx.state.pnpMonitorBtnRender = pnpMonitorBtnRender

	-- Accordion: Automation Boost Pet
	local boostAcc = makeAccordion(pet, "Automation Boost Pet", 2, false)
	makeMultiDropdownDyn(boostAcc, "Select Pets to Boost", "Pilih pet yang mau di-boost (aktif di garden)",
		function() return ctx.inventoryPetOptions(CFG.boostPetUuids) end, CFG.boostPetUuids, function() persist() end, 1)
	makeMultiDropdownDyn(boostAcc, "Select Boost Items", "Pilih item boost (Pet Toy) yang dipakai",
		function() return ctx.getBoostItemOptions(CFG.boostItemNames) end, CFG.boostItemNames, function() persist() end, 2)
	makeToggle(boostAcc, "Enable Automation Boost", "Auto apply boost item ke pet, re-apply pas boost habis",
		function() return CFG.boostEnabled end,
		function(v)
			CFG.boostEnabled = v; persist()
			if v then ctx.startBoostPet() end
		end, 3)

	------------------------------------------------------------------ INVENTORY
	local inv = pageRef["Inventory"]

	-- Accordion: Automation Trade
	local at = makeAccordion(inv, "Automation Trade", 1, true)

	local targetOptions = function()
		local out = {}
		for _, n in ipairs(ctx.getPlayers()) do out[#out + 1] = n end
		return out
	end
	makeSingleDropdown(at, "Target Player", "Select player to trade with", targetOptions,
		function() return CFG.targetPlayer end,
		function(v) CFG.targetPlayer = v; persist() end, 1)

	makeMultiDropdown(at, "Pet Types to Trade", "Filter pets by type (empty = all non-favorite)",
		reg.PET_OPTIONS, CFG.petTypes, function() persist() end, 2)

	makeInput(at, "Weight Filter (KG)", "pakai berat tampilan game | 0=off | +6 = min 6kg | -6 = max 6kg",
		function() return CFG.weightFilter end,
		function(txt) CFG.weightFilter = tonumber(txt) or 0; persist() end, 3)

	makeInput(at, "Age Filter", "0 = off | +50 = at least age 50 | -50 = at most age 50",
		function() return CFG.ageFilter end,
		function(txt) CFG.ageFilter = tonumber(txt) or 0; persist() end, 4)

	makeInput(at, "Pets Per Trade", "Number of pets to add each trade",
		function() return CFG.petsPerTrade end,
		function(txt) local n = tonumber(txt); CFG.petsPerTrade = (n and n > 0) and math.floor(n) or 1; persist() end, 5)

	makeInput(at, "Total Trades", "How many trades to perform",
		function() return CFG.totalTrades end,
		function(txt) local n = tonumber(txt); CFG.totalTrades = (n and n >= 0) and math.floor(n) or 0; persist() end, 6)

	makeToggle(at, "Auto Unfavorite [Trade]", "Remove favorite before trading",
		function() return CFG.autoUnfavorite end,
		function(v) CFG.autoUnfavorite = v; persist() end, 7)

	-- Trade Status (di paling atas)
	local stFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = 0 }, at)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = "Trade Status", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, stFrame)
	local stLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = "Completed: 0 / 0\nPet cocok filter: -\nStatus: IDLE", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = true }, stFrame)
	function ctx.refreshTradeStatus()
		local avail = ctx.countMatchingPets and ctx.countMatchingPets() or 0
		local availCol = avail > 0 and "#5acc78" or "#dc5050"
		stLbl.Text = ("Completed: %d / %d\nPet cocok filter: <font color=\"%s\"><b>%d</b></font>\nStatus: %s"):format(
			ctx.state.completed, CFG.totalTrades, availCol, avail, ctx.state.status)
	end
	-- refresh live tiap 2 detik biar jumlah pet update walau filter berubah
	task.spawn(function()
		while ctx.alive() do
			pcall(function() ctx.refreshTradeStatus() end)
			task.wait(2)
		end
	end)

	-- Enable Automation Trade
	makeToggle(at, "Enable Automation Trade", "Send trade, add pets, wait for accept, confirm",
		function() return CFG.tradeEnabled end,
		function(v)
			CFG.tradeEnabled = v; persist()
			if v then
				ctx.state.completed = 0
				ctx.startTrade()
			else
				ctx.stopTrade()
			end
			ctx.refreshTradeStatus()
		end, 9)

	-- Accordion: Automation Accept
	local acc = makeAccordion(inv, "Automation Accept", 2, false)
	makeToggle(acc, "Automation Accept Gifts", "Automation accept incoming gifts",
		function() return CFG.acceptGifts end,
		function(v) CFG.acceptGifts = v; persist() end, 1)
	makeToggle(acc, "Automation Accept Trades", "Automation accept incoming trades",
		function() return CFG.acceptTrades end,
		function(v) CFG.acceptTrades = v; persist() end, 2)

	-- Accordion: Automation Favourite Pets
	local fav = makeAccordion(inv, "Automation Favourite Pets", 3, false)
	makeToggle(fav, "Auto Favourite Pets", "Automatically favorite selected pet types",
		function() return CFG.autoFavorite end,
		function(v) CFG.autoFavorite = v; persist() end, 1)
	makeMultiDropdown(fav, "Favourite Pet Types", "Pet types to keep favorited",
		reg.PET_OPTIONS, CFG.favoritePetTypes, function() persist() end, 2)

	------------------------------------------------------------------ MISC (log & webhooks)
	local misc = pageRef["Misc"]

	-- ESP Label Accordion
	local espAcc = makeAccordion(misc, "ESP Label (Pet & Egg)", 1, false)
	makeToggle(espAcc, "Enable ESP Label", "Label melayang di atas pet (nama+berat) & egg (nama+waktu hatch)",
		function() return CFG.espEnabled end,
		function(v)
			CFG.espEnabled = v; persist()
			if v then ctx.startEsp() else ctx.stopEsp() end
		end, 1)

	-- Auto Chest Hunt Accordion (event)
	local chAcc = makeAccordion(misc, "Auto Chest Hunt (Event)", 2, false)
	local chLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "Idle", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, RichText = true, LayoutOrder = 0 }, chAcc)
	mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 1 }, chAcc)
	task.spawn(function()
		while ctx.alive() do
			local ok, s = pcall(function() return ctx.getChestSummary() end)
			if ok and s then
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				chLbl.Text = ("Status: <font color=\"%s\"><b>%s</b></font>  |  deposit: <font color=\"#8c929e\">%s</font>\n<font color=\"#8c929e\">%s</font>"):format(col, s.status, s.deposit, s.info)
			end
			task.wait(0.5)
		end
	end)
	makeToggle(chAcc, "Enable Auto Chest Hunt", "TP ke chest -> bawa ke garden -> ulang (auto pas event mulai)",
		function() return CFG.chestHuntEnabled end,
		function(v) CFG.chestHuntEnabled = v; persist(); if v then ctx.startChestHunt() else ctx.stopChestHunt() end end, 2)
	local DEP = { { name = "garden", display = "Garden" }, { name = "platform", display = "Platform" } }
	makeSingleDropdown(chAcc, "Deposit ke", "Bawa chest ke Garden atau Platform NPC",
		function() return DEP end, function() return CFG.chestHuntDeposit == "platform" and "Platform" or "Garden" end,
		function(code) CFG.chestHuntDeposit = code; persist() end, 3)
	makeButton(chAcc, "Scan Chest (debug)", "Cek apa yg kedetect sbg chest (jalanin pas event live)",
		function() task.spawn(function()
			local s = ctx.scanChests()
			ctx.log(("[ChestScan] found=%d carrying=%s"):format(s.chestCount, tostring(s.carrying)))
			for _, x in ipairs(s.sample) do ctx.log("[ChestScan] hit: " .. x) end
			for _, x in ipairs(s.structChests or {}) do ctx.log("[ChestScan] struct: " .. x) end
			for _, x in ipairs(s.rawChestNamed or {}) do ctx.log("[ChestScan] raw: " .. x) end
			for t, n in pairs(s.chestHuntTags) do ctx.log(("[ChestScan] tag '%s' x%d"):format(t, n)) end
		end) end, 4)

	-- Webhook Settings Accordion
	local whAcc = makeAccordion(misc, "Discord Webhook Settings", 3, true)

	-- Discord Webhook URL Input
	makeInput(whAcc, "Discord Webhook URL", "Webhook URL for automation updates (Leveling, Mutation & Elephant)",
		function() return CFG.webhookUrl end,
		function(txt) CFG.webhookUrl = txt; persist() end, 1)

	-- Test Webhook Connection (Button)
	makeButton(whAcc, "Test Webhook Connection", "Send a test notification to your Discord channel",
		function()
			if not CFG.webhookUrl or CFG.webhookUrl == "" then
				ctx.log("[Webhook Test] Gagal: Webhook URL kosong!")
				return
			end
			ctx.log("[Webhook Test] Mengirim test payload...")
			task.spawn(function()
				local sendWebhook = ctx.sendWebhook
				if sendWebhook then
					pcall(function()
						sendWebhook(CFG.webhookUrl, {
							embeds = {
								{
									title = "Webhook Connection Test",
									description = "Koneksi Discord Webhook berhasil tersambung dengan Allegiaan Garden!",
									color = 3066993, -- Green
									fields = {
										{
											name = "Profile :",
											value = string.format("> Username : ||%s||", ctx.LP.Name),
											inline = false
										}
									},
									footer = {
										text = os.date("%B %d | %I:%M %p"),
										icon_url = "https://i.imgur.com/H1Zh6V6.png"
									}
								}
							}
						}, ctx)
					end)
				else
					ctx.log("[Webhook Test] Gagal meload modul sender.")
				end
			end)
		end, 2)

	local logCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 220), BackgroundColor3 = C.row, LayoutOrder = 4 }, misc)
	corner(logCard, 8); stroke(logCard); pad(logCard, 12, 12, 10, 10)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Console Log", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, logCard)
	local logBox = mk("TextLabel", { Size = UDim2.new(1, 0, 1, -26), Position = UDim2.fromOffset(0, 24), BackgroundColor3 = C.panel, Text = "", Font = Enum.Font.Code, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }, logCard)
	corner(logBox, 6); stroke(logBox); pad(logBox, 6, 6, 6, 6)
	ctx.ui.logBox = logBox
	logBox.Text = table.concat(ctx.state.logLines, "\n")

	ctx.refreshTradeStatus()
end
