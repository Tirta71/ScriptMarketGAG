--[[ pages.lua — halaman garden. Tab: Pet, Elephant, Growth, Leveling, Mutation, Inventory, Shop, Misc.
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

	-- sidebar tabs (urut sesuai referensi)
	local TABS = {
		{ "Pet", "Pet", "🐾" },
		{ "Elephant", "Elephant", "🐘" },
		{ "Growth", "Growth", "🌱" },
		{ "Leveling", "Leveling", "⚡" },
		{ "Mutation", "Mutation", "🧪" },
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
	for _, name in ipairs({ "Elephant", "Growth", "Leveling", "Mutation", "Shop" }) do
		placeholder(pageRef[name])
	end

	------------------------------------------------------------------ PET (PNP)
	local pet = pageRef["Pet"]
	local pnp = makeAccordion(pet, "Automation Pickup Pet", 1, true)

	-- Pilih pet PER-UUID dari yang lagi di-equip (buka dropdown = auto-refresh daftarnya).
	makeMultiDropdownDyn(pnp, "Select Pets for Pickup", "Pilih pet equipped yang di-PNP (kosong = semua)",
		function() return ctx.equippedPetOptions() end, CFG.pnpUuids, function() persist() end, 1)

	makeInput(pnp, "Pickup Delay (Seconds)", "Jeda tiap siklus (idealnya = saat skill ready)",
		function() return CFG.pickupDelay end,
		function(txt) CFG.pickupDelay = tonumber(txt) or 0.4; persist() end, 2)

	makeInput(pnp, "Equip Delay (Seconds)", "Jeda antara unequip -> equip",
		function() return CFG.equipDelay end,
		function(txt) CFG.equipDelay = tonumber(txt) or 0.02; persist() end, 3)

	makeToggle(pnp, "Enable Automation Pickup", "Pungut & taruh lagi pet buat reset/trigger skill",
		function() return CFG.pnpEnabled end,
		function(v)
			CFG.pnpEnabled = v; persist()
			if v then ctx.startPnp() end
		end, 4)

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

	-- Trade Status
	local stFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = 8 }, at)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = "Trade Status", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, stFrame)
	local stLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = "Completed: 0 / 0\nStatus: IDLE", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, stFrame)
	function ctx.refreshTradeStatus()
		stLbl.Text = ("Completed: %d / %d\nStatus: %s"):format(ctx.state.completed, CFG.totalTrades, ctx.state.status)
	end

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

	------------------------------------------------------------------ MISC (log)
	local misc = pageRef["Misc"]
	local logCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 220), BackgroundColor3 = C.row, LayoutOrder = 1 }, misc)
	corner(logCard, 8); stroke(logCard); pad(logCard, 12, 12, 10, 10)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Console Log", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, logCard)
	local logBox = mk("TextLabel", { Size = UDim2.new(1, 0, 1, -26), Position = UDim2.fromOffset(0, 24), BackgroundColor3 = C.panel, Text = "", Font = Enum.Font.Code, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }, logCard)
	corner(logBox, 6); stroke(logBox); pad(logBox, 6, 6, 6, 6)
	ctx.ui.logBox = logBox
	logBox.Text = table.concat(ctx.state.logLines, "\n")

	ctx.refreshTradeStatus()
end
