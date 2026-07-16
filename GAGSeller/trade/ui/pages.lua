--[[ pages.lua — membangun halaman: Sell, Profile 1..N, Inventory, Misc.
     Mengisi: ctx.renderInventory, ctx.ui.logBox, ctx.ui.rAutoToggle ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local C   = ctx.C
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad
	local NUM_PROFILES = ctx.NUM_PROFILES
	local NUM_LISTINGS = ctx.NUM_LISTINGS
	local reg          = ctx.reg
	local persistState = ctx.persistState
	local EquipSkin    = ctx.deps.EquipSkin
	local RemoveBooth  = ctx.deps.RemoveBooth
	local function log(msg) ctx.log(msg) end

	local makePage           = ctx.makePage
	local makeAccordion      = ctx.makeAccordion
	local makeSingleDropdown = ctx.makeSingleDropdown
	local makeToggle         = ctx.makeToggle
	local makeButton         = ctx.makeButton
	local makeDropdown       = ctx.makeDropdown
	local makeInput          = ctx.makeInput

	------------------------------------------------------------------ SELL PAGE
	local sellPage = makePage("Sell", "Sell Settings", "🛒", 1)

	-- Accordion: Booth Settings
	local boothBody = makeAccordion(sellPage, "Booth Settings", 1)
	makeSingleDropdown(boothBody, "Booth Skin", "Equip skins you own in Trade Plaza", reg.SKIN_OPTIONS,
		function() return CFG.boothSkin or "Default" end,
		function(name)
			CFG.boothSkin = name; persistState()
			pcall(function() EquipSkin:FireServer(name) end)
			log("Memasang skin booth: " .. name)
		end, 1)

	makeToggle(boothBody, "Auto Claim Booth", "Automatically claim an unclaimed booth",
		function() return CFG.autoClaim end,
		function(v) CFG.autoClaim = v; persistState() end, 2)

	makeToggle(boothBody, "Auto Switch to Booth Near Portal", "Switch to a booth closer to the lobby portal",
		function() return CFG.autoSwitchPortal end,
		function(v) CFG.autoSwitchPortal = v; persistState() end, 3)

	-- Accordion: Unlist Utilities
	local unlistBody = makeAccordion(sellPage, "Unlist Pets Utilities", 2)
	makeButton(unlistBody, "Unlist All Pets", C.red, ctx.unlistAll, 1)
	makeButton(unlistBody, "Unclaim Booth", C.row, function() pcall(function() RemoveBooth:FireServer() end) log("Unclaim booth dikirim.") end, 2)

	-- Accordion: Equip Utilities
	local equipBody = makeAccordion(sellPage, "Equip Pets Utilities", 3)
	makeButton(equipBody, "Unequip All Pets", C.row, ctx.unequipAllPets, 1)

	-- Accordion: Automation Relocate Sell (auto server-hop kalau booth idle)
	local reloBody = makeAccordion(sellPage, "Automation Relocate Sell", 4)
	makeInput(reloBody, "Idle Timeout (Minutes)", "Move server if no buyers within this duration",
		function() return CFG.relocateIdleMin or 20 end,
		function(txt) local n = tonumber(txt); CFG.relocateIdleMin = (n and n >= 1) and math.floor(n) or 20; persistState() end, 1)
	makeInput(reloBody, "Min Player Threshold", "Relocate if server has fewer players (0 = off)",
		function() return CFG.relocateMinPlayers or 0 end,
		function(txt) local n = tonumber(txt); CFG.relocateMinPlayers = (n and n >= 0) and math.floor(n) or 0; persistState() end, 2)
	makeInput(reloBody, "Preferred Lobby Size", "Find server closest to this player count",
		function() return CFG.relocatePreferred or 20 end,
		function(txt) local n = tonumber(txt); CFG.relocatePreferred = (n and n >= 1) and math.floor(n) or 20; persistState() end, 3)
	makeToggle(reloBody, "Automation Relocate Sell", "Automatically move to busier server when booth is idle",
		function() return CFG.relocateEnabled end,
		function(v)
			CFG.relocateEnabled = v; persistState()
			if v then ctx.startRelocate() else ctx.stopRelocate() end
		end, 4)
	makeButton(reloBody, "Relocate Now", C.acc, function() ctx.relocateNow() end, 5)

	------------------------------------------------------------------ LISTING PROFILE PAGES
	for i = 1, NUM_PROFILES do
		local prof = CFG.profiles[i]
		local profPage = makePage("Profile " .. i, "Listing Pets Profile " .. i, "📋", i + 1)

		for j = 1, NUM_LISTINGS do
			local sub = prof.listings[j]
			local listBody = makeAccordion(profPage, "Listing " .. j, j)

			makeDropdown(listBody, "Pet Types [Listing " .. j .. "]", "Select pet types to list", reg.PET_OPTIONS, sub.pets, function() persistState() end, 1)
			makeDropdown(listBody, "Mutation [Listing " .. j .. "]", "Empty = non-mutated only, select = must have mutation", reg.MUT_OPTIONS, sub.muts, function() persistState() end, 2)
			makeInput(listBody, "Min Weight [Listing " .. j .. "]", "Minimum weight filter (KG)", function() return sub.minW or 0 end, function(txt) local n = tonumber(txt); sub.minW = (n and n >= 0) and n or 0; persistState() end, 3)
			makeInput(listBody, "Max Weight [Listing " .. j .. "]", "Maximum weight filter (KG)", function() return sub.maxW or 0 end, function(txt) local n = tonumber(txt); sub.maxW = (n and n >= 0) and n or 0; persistState() end, 4)
			makeInput(listBody, "Max Listings [Listing " .. j .. "]", "Maximum number of listings for this profile", function() return sub.maxList or 0 end, function(txt) local n = tonumber(txt); sub.maxList = (n and n >= 0) and math.floor(n) or 0; persistState() end, 5)
			makeInput(listBody, "Price [Listing " .. j .. "]", "Price per listing (Tokens)", function() return sub.price or 100 end, function(txt) local n = tonumber(txt); sub.price = (n and n >= 0) and math.floor(n) or 0; persistState() end, 6)
		end
	end

	------------------------------------------------------------------ INVENTORY PAGE
	local invPage = makePage("Inventory", "Inventory Tracker", "🎒", 5)

	local countBox = mk("Frame", { Size = UDim2.new(1, 0, 0, 160), BackgroundColor3 = C.row, LayoutOrder = 1 }, invPage)
	corner(countBox, 8); stroke(countBox)
	pad(countBox, 12, 12, 12, 12)

	local countLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Code, TextSize = 12, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }, countBox)

	local function renderInventory()
		local summary, total = ctx.buildSummary()
		local tok = ctx.getTokens()
		countLbl.Text = ("📊 Ringkasan Inventory (%d target dicari):\n%s\n\n💰 Saldo Token: %s Tokens"):format(total, summary, tostring(tok))
	end
	ctx.renderInventory = renderInventory

	makeButton(invPage, "Refresh Inventory", C.acc, renderInventory, 2)
	ctx.ui.tabBtns["Inventory"].btn.MouseButton1Click:Connect(renderInventory)

	------------------------------------------------------------------ MISC PAGE
	local miscPage = makePage("Misc", "Miscellaneous Settings", "⚙️", 6)

	local autoListToggleRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.row, LayoutOrder = 1 }, miscPage)
	corner(autoListToggleRow, 8); stroke(autoListToggleRow); pad(autoListToggleRow, 12, 12, 0, 0)
	local rAutoToggle = makeToggle(autoListToggleRow, "Auto List Loop", "Periodically scan inventory and list matching pets",
		function() return CFG.autoSell end,
		function(v)
			CFG.autoSell = v; persistState(); ctx.setStatus(v and "active" or "idle")
			if v and not ctx.state.running then ctx.state.running = true; task.spawn(ctx.mainLoop)
			elseif not v then ctx.state.running = false end
		end, 1)
	ctx.ui.rAutoToggle = rAutoToggle

	local webhookCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 128), BackgroundColor3 = C.row, LayoutOrder = 2 }, miscPage)
	corner(webhookCard, 8); stroke(webhookCard); pad(webhookCard, 12, 12, 8, 8)
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, webhookCard)

	makeToggle(webhookCard, "Enable Webhook Notifications", "Post listings to Discord Webhook",
		function() return CFG.webhookEnabled end,
		function(v) CFG.webhookEnabled = v; persistState() end, 1)

	local whBox = mk("TextBox", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.panel, PlaceholderText = "https://discord.com/api/webhooks/...", Text = CFG.webhookUrl, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.acc, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2 }, webhookCard)
	corner(whBox, 6); stroke(whBox); pad(whBox, 6, 6, 0, 0)
	whBox.FocusLost:Connect(function() CFG.webhookUrl = whBox.Text; persistState() end)

	makeButton(webhookCard, "Test Webhook Connection", C.acc, function()
		if CFG.webhookUrl == "" then log("Webhook URL kosong."); return end
		local prev = CFG.webhookEnabled; CFG.webhookEnabled = true
		ctx.sendWebhook({ username = "AllegiaanHub GAG Seller", embeds = {{ title = "🔔 Test Sukses", description = "Seller Webhook berhasil terhubung!", color = 10181046, footer = { text = "Player: " .. LP.Name } }} })
		CFG.webhookEnabled = prev
		log("Test webhook terkirim.")
	end, 3)

	-- Logger Panel
	local loggerCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.row, LayoutOrder = 3 }, miscPage)
	corner(loggerCard, 8); stroke(loggerCard); pad(loggerCard, 12, 12, 8, 8)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "Console Log", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, loggerCard)

	local logBox = mk("TextLabel", { Size = UDim2.new(1, 0, 1, -22), BackgroundColor3 = C.panel, Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Code, TextSize = 10, TextColor3 = C.sub, TextWrapped = true, LayoutOrder = 2 }, loggerCard)
	corner(logBox, 6); stroke(logBox); pad(logBox, 6, 6, 6, 6)
	ctx.ui.logBox = logBox
	-- tampilkan log yang mungkin sudah ter-buffer sebelum logBox dibuat
	logBox.Text = table.concat(ctx.state.logLines, "\n")
end
