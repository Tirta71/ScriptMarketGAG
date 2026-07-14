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
		pnpPetTypes = {},     -- (lama) filter per-tipe; kosong = semua equipped
		pnpUuids    = {},     -- filter per-UUID pet equipped; kosong = semua equipped
		pickupDelay = 0.4,    -- jeda setelah place sebelum siklus berikutnya
		equipDelay  = 0.3,   -- jeda antara unequip -> equip (aman dari race condition)
		pnpScanInterval = 0.05, -- jeda antar-scan loop PNP (makin kecil = makin sering cek)
		pnpEnabled  = false,
		pnpMonitorEnabled = false,

		-- Automation Leveling
		levelingTeamUuids   = {},
		levelingPetTypes    = {},
		levelingTargetLevel = 500,
		levelingMaxPets     = 2,
		levelingEnabled     = false,

		-- Automation Mutation
		mutationExpTeam       = {},
		mutationBoostTeam     = {},
		mutationPhoenixTeam   = {},
		mutationTargetTypes   = {},
		mutationTargetMutations = {},
		mutationTargetAge     = 50,
		mutationDelayAutoClaim = 0.5,
		mutationEnabled       = false,

		-- Automation Cleanse Mutation (mutasi via aura + cleanse)
		cleanseTeamUuids     = {},   -- Pet Team for Mutation (aura pemberi mutasi)
		cleansePetTypes      = {},   -- Pet Types for Mutation (target)
		cleanseKeepMutations = {},   -- Mutations to Keep (won't cleanse)
		cleanseMaxPets       = 2,    -- Max Pets in Garden (target)
		cleanseEnabled       = false,

		-- Automation Boost Pet
		boostPetUuids  = {},
		boostItemNames = {},
		boostEnabled   = false,

		-- Automation Elephant (V1)
		elephantTeamUuids   = {},
		elephantPetTypes    = {},
		elephantTargetWeight = 5.5,
		elephantMaxPets     = 2,
		elephantEnabled     = false,

		-- Automation Event (Sam The Clam)
		summerEventEnabled = false,
		summerPetTypes     = {},   -- set tipe pet yang boleh di-feed; kosong = pakai filter berat
		summerMinWeight    = 0,    -- 0 = off
		summerMaxWeight    = 0,    -- 0 = off
		summerAllowFavorite = false,

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
			CFG.pnpUuids    = (type(st.pnpUuids) == "table") and st.pnpUuids or {}
			CFG.pickupDelay = tonumber(st.pickupDelay) or 0.4
			CFG.equipDelay  = tonumber(st.equipDelay) or 0.02
			CFG.pnpScanInterval = tonumber(st.pnpScanInterval) or 0.05
			CFG.pnpEnabled  = st.pnpEnabled or false
			CFG.pnpMonitorEnabled = st.pnpMonitorEnabled or false
			
			CFG.levelingTeamUuids   = (type(st.levelingTeamUuids) == "table") and st.levelingTeamUuids or {}
			CFG.levelingPetTypes    = (type(st.levelingPetTypes) == "table") and st.levelingPetTypes or {}
			CFG.levelingTargetLevel = tonumber(st.levelingTargetLevel) or 500
			CFG.levelingMaxPets     = tonumber(st.levelingMaxPets) or 2
			CFG.levelingEnabled     = st.levelingEnabled or false

			-- Automation Mutation
			CFG.mutationExpTeam       = (type(st.mutationExpTeam) == "table") and st.mutationExpTeam or {}
			CFG.mutationBoostTeam     = (type(st.mutationBoostTeam) == "table") and st.mutationBoostTeam or {}
			CFG.mutationPhoenixTeam   = (type(st.mutationPhoenixTeam) == "table") and st.mutationPhoenixTeam or {}
			CFG.mutationTargetTypes   = (type(st.mutationTargetTypes) == "table") and st.mutationTargetTypes or {}
			CFG.mutationTargetMutations = (type(st.mutationTargetMutations) == "table") and st.mutationTargetMutations or {}
			CFG.mutationTargetAge     = tonumber(st.mutationTargetAge) or 50
			CFG.mutationDelayAutoClaim = tonumber(st.mutationDelayAutoClaim) or 0.5
			CFG.mutationEnabled       = st.mutationEnabled or false

			CFG.cleanseTeamUuids     = (type(st.cleanseTeamUuids) == "table") and st.cleanseTeamUuids or {}
			CFG.cleansePetTypes      = (type(st.cleansePetTypes) == "table") and st.cleansePetTypes or {}
			CFG.cleanseKeepMutations = (type(st.cleanseKeepMutations) == "table") and st.cleanseKeepMutations or {}
			CFG.cleanseMaxPets       = tonumber(st.cleanseMaxPets) or 2
			CFG.cleanseEnabled       = st.cleanseEnabled or false

			CFG.boostPetUuids  = (type(st.boostPetUuids) == "table") and st.boostPetUuids or {}
			CFG.boostItemNames = (type(st.boostItemNames) == "table") and st.boostItemNames or {}
			CFG.boostEnabled   = st.boostEnabled or false

			CFG.elephantTeamUuids   = (type(st.elephantTeamUuids) == "table") and st.elephantTeamUuids or {}
			CFG.elephantPetTypes    = (type(st.elephantPetTypes) == "table") and st.elephantPetTypes or {}
			CFG.elephantTargetWeight = tonumber(st.elephantTargetWeight) or 5.5
			CFG.elephantMaxPets     = tonumber(st.elephantMaxPets) or 2
			CFG.elephantEnabled     = st.elephantEnabled or false

			CFG.summerEventEnabled = st.summerEventEnabled or false
			CFG.summerPetTypes     = (type(st.summerPetTypes) == "table") and st.summerPetTypes or {}
			CFG.summerMinWeight    = tonumber(st.summerMinWeight) or 0
			CFG.summerMaxWeight    = tonumber(st.summerMaxWeight) or 0
			CFG.summerAllowFavorite = st.summerAllowFavorite or false

			CFG.webhookUrl     = st.webhookUrl or ""
			CFG.webhookEnabled = st.webhookEnabled or false
		end
	end

	ctx.CFG = CFG
	ctx.persistState = persistState
end
