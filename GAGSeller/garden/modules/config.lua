--[[ config.lua — CFG default + persist/load state JSON (garden). ]]
return function(ctx)
	local HttpService = ctx.Services.HttpService

	local CFG = {
		-- Automation Trade
		targetPlayer  = "",      -- nama player tujuan
		petTypes      = {},      -- set: {["Fire Wisp"]=true}; kosong = semua non-favorite
		weightFilter  = 0,       -- 0=off | +N = minimal Nkg | -N = maksimal Nkg
		ageFilter     = 0,       -- 0=off | +N = minimal age N | -N = maksimal age N
		petsPerTrade  = 12,
		totalTrades   = 14,
		autoUnfavorite = false,
		tradeEnabled  = false,   -- Enable Automation Trade

		-- Automation Accept
		acceptGifts   = false,
		acceptTrades  = false,

		-- Automation Favourite Pets (placeholder)
		autoFavorite      = false,
		favoritePetTypes  = {},

		-- PNP (Pick & Place) pet
		pnpPetTypes = {},     -- set pet type yang di-PNP; kosong = semua equipped
		pickupDelay = 0.4,    -- jeda setelah place sebelum siklus berikutnya
		equipDelay  = 0.3,   -- jeda antara unequip -> equip (aman dari race condition)
		pnpEnabled  = false,

		-- webhook (opsional)
		webhookUrl     = "",
		webhookEnabled = false,
	}

	local STATE_FILE = "AllegiaanHub_garden_state.json"

	local function persistState()
		pcall(function() writefile(STATE_FILE, HttpService:JSONEncode(CFG)) end)
	end

	local function loadState()
		if type(isfile) == "function" and isfile(STATE_FILE) then
			local ok, t = pcall(function() return HttpService:JSONDecode(readfile(STATE_FILE)) end)
			if ok and type(t) == "table" then return t end
		end
		return nil
	end

	do
		local st = loadState()
		if st then
			CFG.targetPlayer   = st.targetPlayer or ""
			CFG.petTypes       = (type(st.petTypes) == "table") and st.petTypes or {}
			CFG.weightFilter   = tonumber(st.weightFilter) or 0
			CFG.ageFilter      = tonumber(st.ageFilter) or 0
			CFG.petsPerTrade   = tonumber(st.petsPerTrade) or 12
			CFG.totalTrades    = tonumber(st.totalTrades) or 14
			CFG.autoUnfavorite = st.autoUnfavorite or false
			CFG.tradeEnabled   = st.tradeEnabled or false
			CFG.acceptGifts    = st.acceptGifts or false
			CFG.acceptTrades   = st.acceptTrades or false
			CFG.autoFavorite   = st.autoFavorite or false
			CFG.favoritePetTypes = (type(st.favoritePetTypes) == "table") and st.favoritePetTypes or {}
			CFG.pnpPetTypes = (type(st.pnpPetTypes) == "table") and st.pnpPetTypes or {}
			CFG.pickupDelay = tonumber(st.pickupDelay) or 0.4
			CFG.equipDelay  = tonumber(st.equipDelay) or 0.02
			CFG.pnpEnabled  = st.pnpEnabled or false
			CFG.webhookUrl     = st.webhookUrl or ""
			CFG.webhookEnabled = st.webhookEnabled or false
		end
	end

	ctx.CFG = CFG
	ctx.persistState = persistState
end
