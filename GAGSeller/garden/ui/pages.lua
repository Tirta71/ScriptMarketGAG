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
	for _, name in ipairs({ "Growth", "Shop" }) do
		placeholder(pageRef[name])
	end

	------------------------------------------------------------------ ELEPHANT (V1)
	do
		local elephantPage = pageRef["Elephant"]
		-- Status
		local statusAcc = makeAccordion(elephantPage, "Status", 1, true)
		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading stats...",
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.35, RichText = true, LayoutOrder = 1
		}, statusAcc)
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

		-- Settings
		local setAcc = makeAccordion(elephantPage, "Automation Elephant Settings", 2, true)
		makeMultiDropdownDyn(setAcc, "V1 Pet Team", "Select elephant pet team (tetap di garden)",
			function() return ctx.inventoryPetOptions(CFG.elephantTeamUuids) end, CFG.elephantTeamUuids, function() persist() end, 1)
		makeMultiDropdownDyn(setAcc, "V1 Target Pet Types", "Select pet types to auto-elephant",
			function() return ctx.getInventoryPetTypes(CFG.elephantPetTypes) end, CFG.elephantPetTypes, function() persist() end, 2)
		makeInput(setAcc, "Target Weight (KG)", "Berat max sebelum diganti (mis. 5.5)",
			function() return tostring(CFG.elephantTargetWeight) end,
			function(txt) CFG.elephantTargetWeight = tonumber(txt) or 5.5; persist() end, 3)
		makeInput(setAcc, "Max Target Pets", "Jumlah pet target aktif barengan",
			function() return tostring(CFG.elephantMaxPets) end,
			function(txt) CFG.elephantMaxPets = tonumber(txt) or 2; persist() end, 4)
		makeToggle(setAcc, "Enable Automation Elephant", "Rotasi pet target otomatis berdasarkan berat",
			function() return CFG.elephantEnabled end,
			function(v)
				CFG.elephantEnabled = v; persist()
				if v then ctx.startElephant() end
			end, 5)
	end

	------------------------------------------------------------------ LEVELING
	local levelingPage = pageRef["Leveling"]
	do
		-- 1. Leveling Mode Status Accordion
		local statusAcc = makeAccordion(levelingPage, "Leveling Mode Status", 1, true)
		
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
			LayoutOrder = 1
		}, statusAcc)
		
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

		-- 2. Automation Leveling Settings Accordion
		local settingsAcc = makeAccordion(levelingPage, "Automation Leveling Settings", 2, true)

		-- Leveling Pet Team (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Leveling Pet Team", "Select pets to keep in garden while leveling",
			function() return ctx.inventoryPetOptions(CFG.levelingTeamUuids) end, CFG.levelingTeamUuids, function() persist() end, 1)

		-- Leveling Pet Types (Multi-dropdown Pet Types)
		makeMultiDropdownDyn(settingsAcc, "Leveling Pet Types", "Select pet types to auto-level",
			function() return ctx.getInventoryPetTypes(CFG.levelingPetTypes) end, CFG.levelingPetTypes, function() persist() end, 2)

		-- Target Level (Input)
		makeInput(settingsAcc, "Target Level", "Target level to reach before un-equipping",
			function() return tostring(CFG.levelingTargetLevel) end,
			function(txt) CFG.levelingTargetLevel = tonumber(txt) or 500; persist() end, 3)

		-- Max Pets in Garden (Input)
		makeInput(settingsAcc, "Max Pets in Garden", "Maximum active leveling pets allowed in garden",
			function() return tostring(CFG.levelingMaxPets) end,
			function(txt) CFG.levelingMaxPets = tonumber(txt) or 2; persist() end, 4)

		-- Enable Automation Leveling (Toggle)
		makeToggle(settingsAcc, "Enable Automation Leveling", "Equip and rotate pets automatically based on settings",
			function() return CFG.levelingEnabled end,
			function(v)
				CFG.levelingEnabled = v; persist()
				if v then ctx.startLeveling() end
			end, 5)
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
			LayoutOrder = 1
		}, statusAcc)
		
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

		-- 2. Settings Accordion
		local settingsAcc = makeAccordion(mutationPage, "Mutation Settings", 2, true)

		-- EXP Team (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "EXP Team (Leveling)", "Pets for leveling target to age 50/500",
			function() return ctx.inventoryPetOptions(CFG.mutationExpTeam) end, CFG.mutationExpTeam, function() persist() end, 1)

		-- Boost Team (Machine) (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Boost Team (Machine)", "Pets for boosting mutation machine speed",
			function() return ctx.inventoryPetOptions(CFG.mutationBoostTeam) end, CFG.mutationBoostTeam, function() persist() end, 2)

		-- Phoenix Team (Claim) (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Phoenix Team (Claim)", "Pets for claiming mutated pet",
			function() return ctx.inventoryPetOptions(CFG.mutationPhoenixTeam) end, CFG.mutationPhoenixTeam, function() persist() end, 3)

		-- Target Pet Types (Multi-dropdown Pet Types)
		makeMultiDropdownDyn(settingsAcc, "Target Pet Types", "Pet types to mutate",
			function() return ctx.getInventoryPetTypes(CFG.mutationTargetTypes) end, CFG.mutationTargetTypes, function() persist() end, 4)

		-- Target Mutations (Multi-dropdown Mutations)
		makeMultiDropdown(settingsAcc, "Target Mutations (Machine)", "Stop when pet gets these mutations",
			ctx.reg.MUT_OPTIONS or {"None"}, CFG.mutationTargetMutations, function() persist() end, 5)

		-- Target Age (Input)
		makeInput(settingsAcc, "Target Age", "Level to reach before submitting (e.g. 50 or 500)",
			function() return tostring(CFG.mutationTargetAge) end,
			function(txt) CFG.mutationTargetAge = tonumber(txt) or 50; persist() end, 6)

		-- Delay Auto Claim (Input)
		makeInput(settingsAcc, "Delay Auto Claim (sec)", "Wait before claiming mutated pet from machine",
			function() return tostring(CFG.mutationDelayAutoClaim) end,
			function(txt) CFG.mutationDelayAutoClaim = tonumber(txt) or 0.5; persist() end, 7)

		-- Enable Auto Mutation Machine (Toggle)
		ctx.state.mutationToggleRender = makeToggle(settingsAcc, "Enable Auto Mutation Machine", "Submit, start, and claim mutated pets automatically",
			function() return CFG.mutationEnabled end,
			function(v)
				CFG.mutationEnabled = v; persist()
				if v then ctx.startMutation() end
			end, 8)
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

		-- Full Loop (auto hop Trade World). Bisa dimulai dari garden juga.
		makeToggle(summerAcc, "Enable Full Loop (Auto Hop)", "Auto hop + claim/submit. Set filter pet dulu.",
			function() return ctx.samLoopActive and ctx.samLoopActive() end,
			function(v)
				if v then
					if ctx.startSamLoopGarden then ctx.startSamLoopGarden() end
				else
					if ctx.stopSamLoopGarden then ctx.stopSamLoopGarden() end
				end
			end, 7)
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

	-- Webhook Settings Accordion
	local whAcc = makeAccordion(misc, "Discord Webhook Settings", 1, true)

	-- Discord Webhook URL Input
	makeInput(whAcc, "Discord Webhook URL", "Webhook URL for automation updates (Leveling & Mutation)",
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

	local logCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 220), BackgroundColor3 = C.row, LayoutOrder = 2 }, misc)
	corner(logCard, 8); stroke(logCard); pad(logCard, 12, 12, 10, 10)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Console Log", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, logCard)
	local logBox = mk("TextLabel", { Size = UDim2.new(1, 0, 1, -26), Position = UDim2.fromOffset(0, 24), BackgroundColor3 = C.panel, Text = "", Font = Enum.Font.Code, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }, logCard)
	corner(logBox, 6); stroke(logBox); pad(logBox, 6, 6, 6, 6)
	ctx.ui.logBox = logBox
	logBox.Text = table.concat(ctx.state.logLines, "\n")

	ctx.refreshTradeStatus()
end
