-- AUTO-GENERATED oleh tools/bundle.js — JANGAN edit manual.
-- Edit modul-nya langsung, terus run `node tools/bundle.js`.
-- 43 modul, di-generate 2026-08-22T15:07:52.834Z
return {
	["app.lua"] = [=[
--[[ app.lua — init akhir garden: default tab Inventory + auto-resume automation. ]]
return function(ctx)
	local CFG = ctx.CFG
	local pages = ctx.ui.pages
	local tabBtns = ctx.ui.tabBtns
	local C = ctx.C

	-- toast "loaded" di pojok kanan bawah
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		local old = host:FindFirstChild("AHNotif"); if old then old:Destroy() end
		local sg = Instance.new("ScreenGui")
		sg.Name = "AHNotif"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.DisplayOrder = 9999; sg.Parent = host
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(1, 1)
		f.Position = UDim2.new(1, 280, 1, -20)     -- mulai di luar layar (buat slide-in)
		f.Size = UDim2.fromOffset(250, 62)
		f.BackgroundColor3 = C.panel or Color3.fromRGB(24, 26, 31)
		f.BorderSizePixel = 0; f.Parent = sg
		local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = f
		local strk = Instance.new("UIStroke"); strk.Color = C.acc or Color3.fromRGB(246, 197, 24); strk.Thickness = 1.2; strk.Transparency = 0.3; strk.Parent = f
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 14); pad.PaddingTop = UDim.new(0, 10); pad.Parent = f
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1; title.Size = UDim2.new(1, -14, 0, 18)
		title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left
		title.RichText = true; title.Text = 'AllegiaantHub <font color="#f6c518">Notification</font>'
		title.TextColor3 = C.txt or Color3.fromRGB(235, 238, 242); title.Parent = f
		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1; body.Size = UDim2.new(1, -14, 0, 16); body.Position = UDim2.fromOffset(0, 24)
		body.Font = Enum.Font.Gotham; body.TextSize = 13; body.TextXAlignment = Enum.TextXAlignment.Left
		body.Text = "Loaded"; body.TextColor3 = C.sub or Color3.fromRGB(150, 155, 163); body.Parent = f
		local TS = game:GetService("TweenService")
		TS:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(1, -20, 1, -20) }):Play()
		task.delay(3, function()
			pcall(function()
				TS:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(1, 280, 1, -20) }):Play()
				task.wait(0.45); sg:Destroy()
			end)
		end)
	end)

	-- default tab = Inventory
	local function selectTab(name)
		for n, p in pairs(pages) do p.Visible = (n == name) end
		for n, b in pairs(tabBtns) do
			b.btn.BackgroundTransparency = (n == name) and 0.85 or 1
			b.btn.TextColor3 = (n == name) and C.txt or C.sub
			b.line.Visible = (n == name)
		end
	end
	selectTab("Inventory")

	ctx.log("AllegiaantHub Garden dimuat.")
	ctx.setStatus("idle")

	-- Anti-AFK: reset timer idle Roblox (kick ~20 menit) tiap Idled fire, via VirtualUser.
	pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		ctx.LP.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
			ctx.log("Anti-AFK: reset idle timer.")
		end)
		ctx.log("Anti-AFK aktif.")
	end)

	-- auto-resume Auto Chest Hunt kalau sebelumnya aktif (listener event udah kepasang di modul)
	if CFG.chestHuntEnabled and ctx.startChestHunt then
		ctx.startChestHunt()
		ctx.log("Auto-resume: Chest Hunt ON (nunggu/ikut event).")
	end

	-- auto-resume ESP label kalau sebelumnya aktif
	if CFG.espEnabled and ctx.startEsp then
		ctx.startEsp()
		ctx.log("Auto-resume: ESP Label ON.")
	end
	if CFG.espInvEnabled and ctx.startEspInv then
		ctx.startEspInv()
		ctx.log("Auto-resume: ESP Base Weight (Inventory) ON.")
	end
	if CFG.noclipEnabled and ctx.setNoclip then ctx.setNoclip(true); ctx.log("Auto-resume: Noclip ON.") end
	if CFG.walkSpeedEnabled and ctx.setWalkSpeed then ctx.setWalkSpeed(true); ctx.log("Auto-resume: Walk Speed ON.") end
	if CFG.infJumpEnabled and ctx.setInfJump then ctx.setInfJump(true); ctx.log("Auto-resume: Infinity Jump ON.") end
	if CFG.hideMyPlants and ctx.setHidePlants then ctx.setHidePlants("mine", true); ctx.log("Auto-resume: Hide My Plants ON.") end
	if CFG.hideOtherPlants and ctx.setHidePlants then ctx.setHidePlants("other", true); ctx.log("Auto-resume: Hide Other Plants ON.") end
	if CFG.autoRemoveWebFx and ctx.setAutoRemoveWeb then ctx.setAutoRemoveWeb(true); ctx.log("Auto-resume: Auto Remove Web FX ON.") end
	if CFG.perfMode and CFG.perfMode ~= "off" and ctx.setPerfMode then ctx.setPerfMode(CFG.perfMode); ctx.log("Auto-resume: Performance Mode = " .. tostring(CFG.perfMode)) end
	if CFG.disable3d and ctx.setDisable3d then ctx.setDisable3d(true); ctx.log("Auto-resume: Disable 3D ON.") end

	-- auto-resume Auto Reclaimer kalau sebelumnya aktif
	if CFG.reclaimEnabled and ctx.startReclaim then
		ctx.startReclaim()
		ctx.log("Auto-resume: Auto Reclaimer ON.")
	end

	-- auto-resume Auto Plants kalau sebelumnya aktif
	if CFG.plantSeedEnabled and ctx.startPlant then
		ctx.startPlant()
		ctx.log("Auto-resume: Auto Plants ON.")
	end

	-- auto-resume Auto Sprinkler + Shovel Sprinkler
	if CFG.sprinklerEnabled and ctx.startSprinkler then
		ctx.startSprinkler()
		ctx.log("Auto-resume: Auto Sprinkler ON.")
	end
	if CFG.shovelSprinklerEnabled and ctx.startShovelSprinkler then
		ctx.startShovelSprinkler()
		ctx.log("Auto-resume: Auto Shovel Sprinkler ON.")
	end

	-- auto-resume Auto Reconnect (biar loop rejoin lanjut tiap masuk server)
	if CFG.reconnectEnabled and ctx.startReconnect then
		ctx.startReconnect()
		ctx.log("Auto-resume: Auto Reconnect ON.")
	end

	-- auto-resume PNP kalau sebelumnya aktif (V1 polling / V2 event-driven, mutually exclusive)
	if CFG.pnpEnabled and ctx.startPnpV1 then
		task.wait(1)
		ctx.startPnpV1()
		ctx.log("Auto-resume: PNP V1 ON.")
	elseif CFG.pnpV2Enabled and ctx.startPnpV2 then
		task.wait(1)
		ctx.startPnpV2()
		ctx.log("Auto-resume: PNP V2 ON.")
	end

	-- auto-resume kalau sebelumnya aktif
	if CFG.tradeEnabled then
		task.wait(1.5)
		ctx.state.completed = 0
		ctx.startTrade()
		ctx.refreshTradeStatus()
		ctx.log("Auto-resume: automation trade ON.")
	end

	-- auto-resume Leveling kalau sebelumnya aktif
	if CFG.levelingEnabled and ctx.startLeveling then
		task.wait(2.0)
		ctx.startLeveling()
		ctx.log("Auto-resume: Leveling ON.")
	end

	-- auto-resume Leveling V2 kalau sebelumnya aktif
	if CFG.levelingV2Enabled and ctx.startLevelingV2 then
		task.wait(2.0)
		ctx.startLevelingV2()
		ctx.log("Auto-resume: Leveling V2 ON.")
	end

	-- auto-resume Auto Hatch kalau sebelumnya aktif
	if CFG.hatchEnabled and ctx.startHatch then
		task.wait(2.0)
		ctx.startHatch()
		ctx.log("Auto-resume: Auto Hatch ON.")
	end

	-- auto-resume Auto Favourite Pets kalau sebelumnya aktif
	if CFG.autoFavorite and ctx.startAutoFavorite then
		ctx.startAutoFavorite()
		ctx.log("Auto-resume: Auto Favourite ON.")
	end

	-- auto-resume Growth kalau sebelumnya aktif
	if CFG.growthEnabled and ctx.startGrowth then
		task.wait(2.0)
		ctx.startGrowth()
		ctx.log("Auto-resume: Growth ON.")
	end

	-- auto-resume Mutation kalau sebelumnya aktif
	if CFG.mutationEnabled and ctx.startMutation then
		task.wait(2.5)
		ctx.startMutation()
		ctx.log("Auto-resume: Mutation ON.")
	end

	-- auto-resume Elephant kalau sebelumnya aktif
	if CFG.elephantEnabled and ctx.startElephant then
		task.wait(2.5)
		ctx.startElephant()
		ctx.log("Auto-resume: Elephant ON.")
	end

	if CFG.elephantV2Enabled and ctx.startElephantV2 then
		task.wait(2.5)
		ctx.startElephantV2()
		ctx.log("Auto-resume: Elephant V2 ON.")
	end

	-- auto-resume Boost Pet kalau sebelumnya aktif
	if CFG.boostEnabled and ctx.startBoostPet then
		task.wait(2.5)
		ctx.startBoostPet()
		ctx.log("Auto-resume: Boost Pet ON.")
	end

	-- auto-resume Cleanse kalau sebelumnya aktif
	if CFG.cleanseEnabled and ctx.startCleanse then
		task.wait(2.5)
		ctx.startCleanse()
		ctx.log("Auto-resume: Cleanse ON.")
	end

	-- auto-resume Summer Event (Sam The Clam) kalau sebelumnya aktif
	if CFG.summerEventEnabled and ctx.startSummerEvent then
		task.wait(2.5)
		ctx.startSummerEvent()
		ctx.log("Auto-resume: Summer Event ON.")
	end

	-- auto-resume Shop (buy seed/egg/gear)
	if CFG.buySeedEnabled and ctx.startBuySeed then ctx.startBuySeed(); ctx.log("Auto-resume: Buy Seed ON.") end
	if CFG.buyEggEnabled and ctx.startBuyEgg then ctx.startBuyEgg(); ctx.log("Auto-resume: Buy Egg ON.") end
	if CFG.buyGearEnabled and ctx.startBuyGear then ctx.startBuyGear(); ctx.log("Auto-resume: Buy Gear ON.") end
	if CFG.waterEnabled and ctx.startWater then ctx.startWater(); ctx.log("Auto-resume: Auto Water ON.") end
	if CFG.shovelTreeEnabled and ctx.startShovelTree then ctx.startShovelTree(); ctx.log("Auto-resume: Auto Shovel Tree ON.") end
	if CFG.shovelFruitEnabled and ctx.startShovelFruit then ctx.startShovelFruit(); ctx.log("Auto-resume: Auto Shovel Fruit ON.") end
	if (CFG.collectWlFruitEnabled or CFG.collectWlMutEnabled or CFG.collectCombEnabled) and ctx.startCollect then
		ctx.startCollect(); ctx.log("Auto-resume: Auto Collect ON.")
	end
	if (CFG.favEnabled or CFG.unfavEnabled) and ctx.startFavorite then
		ctx.startFavorite(); ctx.log("Auto-resume: Auto Favorite ON.")
	end
	if CFG.buySummerSeedEnabled and ctx.startBuySummerSeed then ctx.startBuySummerSeed(); ctx.log("Auto-resume: Buy Summer Seed ON.") end
	if CFG.buyTideTokenEnabled and ctx.startBuyTideToken then ctx.startBuyTideToken(); ctx.log("Auto-resume: Buy Tide Token ON.") end
end
]=],
	["modules/core/config.lua"] = [=[
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

		-- ===== Auto Hatch + Auto Sell =====
		hatchEnabled    = false,
		autoSellEnabled = false,
		-- teams (set uuid pet)
		hatchCoreTeam   = {},  -- team default/idle
		hatchHatchTeam  = {},  -- team saat hatch (recovery + speed)
		hatchBrontoTeam = {},  -- team bronto (hatch speed)
		hatchSellTeam   = {},  -- team saat jual (boost harga)
		-- egg config
		hatchEggName    = "Rare Egg", -- egg yg di-place & di-hatch
		hatchMaxPlaced  = 9,          -- target egg ke-place di garden
		hatchPlacePattern = "Grid",   -- pola taro egg: "Grid" (rapih) / "Random" (sebar acak)
		hatchSpeed      = 0.2,        -- delay per hatch (detik); kecil = cepat
		hatchWebhookUrl   = "",       -- webhook Discord buat Hatch Alert (bronto)
		hatchAlertEnabled = false,    -- kirim alert pas pet masuk filter bronto
		-- bronto config: egg yg pending pet-nya cocok -> hatch pakai Bronto team (+30% berat)
		brontoSpecialPets    = {},   -- set "Pet - Egg" (special: wajib bronto)
		brontoSpecialWeight  = 0,    -- special cuma kalau weight > ini (0 = ga difilter)
		brontoUniversalTypes = {},   -- set tipe pet buat aturan universal (kosong = semua)
		brontoUniversalWeight = 0,   -- pakai bronto kalau weight > ini (0 = off)
		brontoSkipSpecial    = false,-- jangan hatch special pet sama sekali
		-- sell config (filter = DIJUAL; sisanya difavoritin biar aman)
		sellPetTypes       = {},   -- set tipe pet yg dijual
		sellWeightThreshold = 4,   -- jual kalau BaseWeight < ini
		sellAgeThreshold    = 3,   -- jual kalau Age/Level < ini
		sellSpecialTypes    = {},  -- pet spesial (jual by weight)
		sellSpecialWeight   = 10,  -- 0=off
		sellMode   = "Cycle",      -- Cycle | Backpack
		sellStyle  = "All at Once",
		sellEveryNCycles = 1,
		sellWhenReach    = 100,    -- jual kalau backpack pet >= ini
		sellTeamDelay    = 5,      -- detik tunggu abis swap team sebelum jual
		autoBoostBeforeSell = false,

		-- Auto Chest Hunt (event): TP ke chest -> bawa ke garden -> ulang
		chestHuntEnabled = false,
		chestHuntDeposit = "garden", -- garden | platform

		-- Automation Accept
		acceptGifts   = false,
		acceptTrades  = false,

		-- Automation Favourite Pets (placeholder)
		autoFavorite      = false,
		favoritePetTypes  = {},

		-- PNP (Pick & Place) pet
		pnpPetTypes = {},     -- (lama) filter per-tipe; kosong = semua equipped
		-- PnP V1 (polling)
		pnpUuids    = {},     -- filter per-UUID pet equipped; kosong = semua equipped
		pickupDelay = 0.4,    -- jeda setelah place sebelum siklus berikutnya
		equipDelay  = 0.3,   -- jeda antara unequip -> equip (aman dari race condition)
		pnpScanInterval = 0.05, -- jeda antar-scan loop PNP (makin kecil = makin sering cek)
		pnpEnabled  = false,
		-- PnP V2 (event-driven, config terpisah dari V1)
		pnpV2Uuids       = {},
		pnpV2PickupDelay = 0.05,
		pnpV2EquipDelay  = 0.03,
		pnpV2ScanInterval = 0.05,
		pnpV2Enabled     = false,
		espEnabled  = false, -- label melayang (ESP) pet+egg di dunia
		espInvEnabled = false, -- ESP base weight di tiap slot pet inventory
		espInvMode  = "age",   -- tampilan ESP inv: "age" (base+age) / "max" (base+max@500)
		noclipEnabled    = false, -- Player: tembus tembok
		walkSpeedEnabled = false, -- Player: pakai custom walk speed
		walkSpeed        = 16,    -- Player: walk speed custom (default 16)
		infJumpEnabled   = false, -- Player: lompat tak terbatas di udara
		hideMyPlants     = false, -- Perf: sembunyiin plant kebun sendiri
		hideOtherPlants  = false, -- Perf: sembunyiin plant kebun lain
		autoRemoveWebFx  = false, -- Perf: auto hapus efek spider web
		perfMode         = "off", -- Perf: off / low / extreme
		disable3d        = false, -- Perf: matiin 3D rendering
		premiumItem      = "",     -- Premium Shop: key item terpilih (DevProductIds)
		premiumPay       = "robux",-- Premium Shop: robux / token

		-- Automation Leveling
		levelingTeamUuids   = {},
		levelingPetTypes    = {},
		levelingTargetLevel = 500,
		levelingMaxPets     = 2,
		levelingEnabled     = false,

		-- Automation Leveling V2 (2 phase)
		levelingV2PetTypes = {},
		levelingV2P1Team   = {},
		levelingV2P1Target = 40,
		levelingV2P1Max    = 3,
		levelingV2P2Team   = {},
		levelingV2P2Target = 500,
		levelingV2P2Max    = 1,
		levelingV2Enabled  = false,

		-- Growth (pipeline: Elephant -> Mutation -> Leveling, batch per-step, config TERPISAH)
		growthEnabled      = false,
		growthPetTypes     = {},                                   -- target pet types (dipakai semua step)
		growthFlow         = { "elephant", "mutation", "leveling" }, -- urutan Step 1/2/3
		-- step Elephant
		growthElephantTeam   = {},
		growthElephantWeight = 5.5,
		growthElephantMax    = 2,
		-- step Mutation (aura)
		growthMutationTeam    = {},
		growthMutationTargets = {},   -- target mutasi (mis. Ember/Nightmare/Rainbow)
		growthMutationMax     = 2,
		-- step Leveling (2 phase)
		growthLevP1Team   = {},
		growthLevP1Target = 40,
		growthLevP1Max    = 3,
		growthLevP2Team   = {},
		growthLevP2Target = 500,
		growthLevP2Max    = 1,

		-- Automation Mutation
		mutationExpTeam       = {},
		mutationBoostTeam     = {},
		mutationPhoenixTeam   = {},
		mutationTargetTypes   = {},
		mutationTargetMutations = {},
		mutationTargetAge     = 50,
		mutationDelayAutoClaim = 0.5,
		mutationEnabled       = false,

		-- Automation Shop (buy seed/egg/gear)
		buySeedNames   = {},
		buySeedEnabled = false,
		buyEggNames    = {},
		buyEggEnabled  = false,
		buyGearNames   = {},
		buyGearEnabled = false,

		-- Automation Water (siram plant terpilih pakai Watering Can / Water_RE)
		waterFruitNames = {},
		waterEnabled    = false,
		waterDelay      = 1,

		-- Automation Shovel (hapus plant / fruit via Remove_Item)
		shovelTreeNames    = {},
		shovelTreeEnabled  = false,
		shovelTreeDelay    = 0,
		shovelFruitNames    = {},
		shovelFruitMuts     = {},
		shovelFruitVariants = {},
		shovelFruitMode     = ">= (berat minimal)",
		shovelFruitWeight   = 0,
		shovelFruitEnabled  = false,
		shovelFruitDelay    = 0,

		-- Automation Collection (harvest fruit via Crops.Collect)
		collectDelay          = 0,
		collectStopIfFull     = false,
		collectAutoSellIfFull = false,
		collectWlFruitNames   = {},
		collectWlFruitEnabled = false,
		collectWlMutNames     = {},
		collectWlMutEnabled   = false,
		collectCombFruitNames = {},
		collectCombMutNames   = {},
		collectCombVariants   = {},
		collectCombMode       = ">= (berat minimal)",
		collectCombWeight     = 0,
		collectCombEnabled    = false,

		-- Automation Favorite (favorite/unfavorite fruit via Favorite Tool)
		favFruitNames = {},
		favMutNames   = {},
		favMode       = ">= (berat minimal)",
		favWeight     = 0,
		favDelay      = 1,
		favEnabled    = false,
		unfavEnabled  = false,

		-- Automation Summer Shop (event: Summer Seed Shop + Tide Token Shop)
		buySummerSeedNames   = {},
		buySummerSeedEnabled = false,
		buyTideTokenNames    = {},
		buyTideTokenEnabled  = false,

		-- Automation Reclaimer (Farm): reclaim plant terpilih pakai tool Reclaimer
		reclaimPlantNames = {},
		reclaimEnabled    = false,
		reclaimSpeed      = 0.15,

		-- Automation Plants (Farm): tanam seed dari inventory
		plantSeedNames   = {},
		plantPosition    = "Random",
		plantDelay       = 0,
		plantSeedEnabled = false,

		-- Automation Sprinkler (Farm): pasang + shovel sprinkler
		sprinklerNames        = {},
		sprinklerPlantNames   = {},
		sprinklerPosition     = "Random",
		sprinklerDelay        = 0,
		sprinklerEnabled      = false,
		shovelSprinklerNames  = {},
		shovelSprinklerDelay  = 0,
		shovelSprinklerEnabled = false,

		-- Automation Reconnect (Misc): auto rejoin tiap interval
		reconnectEnabled  = false,
		reconnectInterval = 5,   -- menit

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
		-- Elephant V2: swap gajah keluar-masuk saat target hit level 40 (barengan PNP)
		elephantV2Team      = {},   -- sumber pet Switch (team standby di garden)
		elephantV2Types     = {},   -- tipe pet target yg dipantau levelnya
		elephantV2Weight    = 5.5,  -- berat max target sebelum dilepas
		elephantV2MaxPets   = 3,    -- jumlah pet target aktif barengan
		elephantV2Gajah     = "",   -- uuid pet gajah (booster berat)
		elephantV2Switch    = "",   -- uuid pet team yg ditukar sama gajah
		elephantV2Level     = 40,   -- ambang level target buat masukin gajah
		elephantV2Interval  = 0.1,  -- interval baca level (detik)
		elephantV2Enabled   = false,

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

	-- Semua data hub disimpan di folder AllegiaantHUB/ (biar rapih, ga berserakan di root).
	local FOLDER = "AllegiaantHUB"
	local STATE_FILE = FOLDER .. "/garden_state.json"
	-- lokasi lama (buat migrasi otomatis, urut dari yg paling baru)
	local OLD_FILES = { "AllegiaanHUB/garden_state.json", "AllegiaanHub_garden_state.json" }

	local function ensureFolder()
		if type(makefolder) == "function" and (type(isfolder) ~= "function" or not isfolder(FOLDER)) then
			pcall(function() makefolder(FOLDER) end)
		end
	end

	local function persistState()
		ensureFolder()
		pcall(function() writefile(STATE_FILE, HttpService:JSONEncode(CFG)) end)
	end

	local function loadState()
		for _, f in ipairs({ STATE_FILE, OLD_FILES[1], OLD_FILES[2] }) do
			if type(isfile) == "function" and isfile(f) then
				local ok, t = pcall(function() return HttpService:JSONDecode(readfile(f)) end)
				if ok and type(t) == "table" then return t end
			end
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
			-- Auto Hatch + Auto Sell
			CFG.hatchEnabled    = st.hatchEnabled or false
			CFG.autoSellEnabled = st.autoSellEnabled or false
			local function tbl(v) return (type(v) == "table") and v or {} end
			CFG.hatchCoreTeam   = tbl(st.hatchCoreTeam)
			CFG.hatchHatchTeam  = tbl(st.hatchHatchTeam)
			CFG.hatchBrontoTeam = tbl(st.hatchBrontoTeam)
			CFG.hatchSellTeam   = tbl(st.hatchSellTeam)
			CFG.hatchEggName    = st.hatchEggName or "Rare Egg"
			CFG.hatchMaxPlaced  = tonumber(st.hatchMaxPlaced) or 9
			CFG.hatchPlacePattern = st.hatchPlacePattern or "Grid"
			CFG.hatchSpeed      = tonumber(st.hatchSpeed) or 0.2
			CFG.hatchWebhookUrl   = st.hatchWebhookUrl or ""
			CFG.hatchAlertEnabled = st.hatchAlertEnabled or false
			CFG.brontoSpecialPets    = tbl(st.brontoSpecialPets)
			CFG.brontoSpecialWeight  = tonumber(st.brontoSpecialWeight) or 0
			CFG.brontoUniversalTypes = tbl(st.brontoUniversalTypes)
			CFG.brontoUniversalWeight = tonumber(st.brontoUniversalWeight) or 0
			CFG.brontoSkipSpecial    = st.brontoSkipSpecial or false
			CFG.sellPetTypes    = tbl(st.sellPetTypes)
			CFG.sellWeightThreshold = tonumber(st.sellWeightThreshold) or 4
			CFG.sellAgeThreshold    = tonumber(st.sellAgeThreshold) or 3
			CFG.sellSpecialTypes    = tbl(st.sellSpecialTypes)
			CFG.sellSpecialWeight   = tonumber(st.sellSpecialWeight) or 10
			CFG.sellMode   = st.sellMode or "Cycle"
			CFG.sellStyle  = st.sellStyle or "All at Once"
			CFG.sellEveryNCycles = tonumber(st.sellEveryNCycles) or 1
			CFG.sellWhenReach    = tonumber(st.sellWhenReach) or 100
			CFG.sellTeamDelay    = tonumber(st.sellTeamDelay) or 5
			CFG.autoBoostBeforeSell = st.autoBoostBeforeSell or false
			CFG.chestHuntEnabled = st.chestHuntEnabled or false
			CFG.chestHuntDeposit = st.chestHuntDeposit or "garden"
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
			CFG.pnpV2Uuids       = (type(st.pnpV2Uuids) == "table") and st.pnpV2Uuids or {}
			CFG.pnpV2PickupDelay = tonumber(st.pnpV2PickupDelay) or 0.05
			CFG.pnpV2EquipDelay  = tonumber(st.pnpV2EquipDelay) or 0.03
			CFG.pnpV2ScanInterval = tonumber(st.pnpV2ScanInterval) or 0.05
			CFG.pnpV2Enabled     = st.pnpV2Enabled or false
			CFG.espEnabled = st.espEnabled or false
			CFG.espInvEnabled = st.espInvEnabled or false
			CFG.espInvMode = st.espInvMode or "age"
			CFG.noclipEnabled = st.noclipEnabled or false
			CFG.walkSpeedEnabled = st.walkSpeedEnabled or false
			CFG.walkSpeed = tonumber(st.walkSpeed) or 16
			CFG.infJumpEnabled = st.infJumpEnabled or false
			CFG.hideMyPlants = st.hideMyPlants or false
			CFG.hideOtherPlants = st.hideOtherPlants or false
			CFG.autoRemoveWebFx = st.autoRemoveWebFx or false
			CFG.perfMode = st.perfMode or "off"
			CFG.disable3d = st.disable3d or false
			CFG.premiumItem = st.premiumItem or ""
			CFG.premiumPay = st.premiumPay or "robux"
			
			CFG.levelingTeamUuids   = (type(st.levelingTeamUuids) == "table") and st.levelingTeamUuids or {}
			CFG.levelingPetTypes    = (type(st.levelingPetTypes) == "table") and st.levelingPetTypes or {}
			CFG.levelingTargetLevel = tonumber(st.levelingTargetLevel) or 500
			CFG.levelingMaxPets     = tonumber(st.levelingMaxPets) or 2
			CFG.levelingEnabled     = st.levelingEnabled or false

			-- Leveling V2
			CFG.levelingV2PetTypes = (type(st.levelingV2PetTypes) == "table") and st.levelingV2PetTypes or {}
			CFG.levelingV2P1Team   = (type(st.levelingV2P1Team) == "table") and st.levelingV2P1Team or {}
			CFG.levelingV2P1Target = tonumber(st.levelingV2P1Target) or 40
			CFG.levelingV2P1Max    = tonumber(st.levelingV2P1Max) or 3
			CFG.levelingV2P2Team   = (type(st.levelingV2P2Team) == "table") and st.levelingV2P2Team or {}
			CFG.levelingV2P2Target = tonumber(st.levelingV2P2Target) or 500
			CFG.levelingV2P2Max    = tonumber(st.levelingV2P2Max) or 1
			CFG.levelingV2Enabled  = st.levelingV2Enabled or false

			-- Growth
			CFG.growthEnabled  = st.growthEnabled or false
			CFG.growthPetTypes = (type(st.growthPetTypes) == "table") and st.growthPetTypes or {}
			CFG.growthFlow     = (type(st.growthFlow) == "table") and st.growthFlow or { "elephant", "mutation", "leveling" }
			CFG.growthElephantTeam   = (type(st.growthElephantTeam) == "table") and st.growthElephantTeam or {}
			CFG.growthElephantWeight = tonumber(st.growthElephantWeight) or 5.5
			CFG.growthElephantMax    = tonumber(st.growthElephantMax) or 2
			CFG.growthMutationTeam    = (type(st.growthMutationTeam) == "table") and st.growthMutationTeam or {}
			CFG.growthMutationTargets = (type(st.growthMutationTargets) == "table") and st.growthMutationTargets or {}
			CFG.growthMutationMax     = tonumber(st.growthMutationMax) or 2
			CFG.growthLevP1Team   = (type(st.growthLevP1Team) == "table") and st.growthLevP1Team or {}
			CFG.growthLevP1Target = tonumber(st.growthLevP1Target) or 40
			CFG.growthLevP1Max    = tonumber(st.growthLevP1Max) or 3
			CFG.growthLevP2Team   = (type(st.growthLevP2Team) == "table") and st.growthLevP2Team or {}
			CFG.growthLevP2Target = tonumber(st.growthLevP2Target) or 500
			CFG.growthLevP2Max    = tonumber(st.growthLevP2Max) or 1

			-- Automation Mutation
			CFG.mutationExpTeam       = (type(st.mutationExpTeam) == "table") and st.mutationExpTeam or {}
			CFG.mutationBoostTeam     = (type(st.mutationBoostTeam) == "table") and st.mutationBoostTeam or {}
			CFG.mutationPhoenixTeam   = (type(st.mutationPhoenixTeam) == "table") and st.mutationPhoenixTeam or {}
			CFG.mutationTargetTypes   = (type(st.mutationTargetTypes) == "table") and st.mutationTargetTypes or {}
			CFG.mutationTargetMutations = (type(st.mutationTargetMutations) == "table") and st.mutationTargetMutations or {}
			CFG.mutationTargetAge     = tonumber(st.mutationTargetAge) or 50
			CFG.mutationDelayAutoClaim = tonumber(st.mutationDelayAutoClaim) or 0.5
			CFG.mutationEnabled       = st.mutationEnabled or false

			CFG.buySeedNames   = (type(st.buySeedNames) == "table") and st.buySeedNames or {}
			CFG.buySeedEnabled = st.buySeedEnabled or false
			CFG.buyEggNames    = (type(st.buyEggNames) == "table") and st.buyEggNames or {}
			CFG.buyEggEnabled  = st.buyEggEnabled or false
			CFG.buyGearNames   = (type(st.buyGearNames) == "table") and st.buyGearNames or {}
			CFG.buyGearEnabled = st.buyGearEnabled or false

			CFG.waterFruitNames = (type(st.waterFruitNames) == "table") and st.waterFruitNames or {}
			CFG.waterEnabled    = st.waterEnabled or false
			CFG.waterDelay      = tonumber(st.waterDelay) or 1

			CFG.shovelTreeNames    = (type(st.shovelTreeNames) == "table") and st.shovelTreeNames or {}
			CFG.shovelTreeEnabled  = st.shovelTreeEnabled or false
			CFG.shovelTreeDelay    = tonumber(st.shovelTreeDelay) or 0
			CFG.shovelFruitNames    = (type(st.shovelFruitNames) == "table") and st.shovelFruitNames or {}
			CFG.shovelFruitMuts     = (type(st.shovelFruitMuts) == "table") and st.shovelFruitMuts or {}
			CFG.shovelFruitVariants = (type(st.shovelFruitVariants) == "table") and st.shovelFruitVariants or {}
			CFG.shovelFruitMode     = st.shovelFruitMode or ">= (berat minimal)"
			CFG.shovelFruitWeight   = tonumber(st.shovelFruitWeight) or 0
			CFG.shovelFruitEnabled  = st.shovelFruitEnabled or false
			CFG.shovelFruitDelay    = tonumber(st.shovelFruitDelay) or 0

			CFG.collectDelay          = tonumber(st.collectDelay) or 0
			CFG.collectStopIfFull     = st.collectStopIfFull or false
			CFG.collectAutoSellIfFull = st.collectAutoSellIfFull or false
			CFG.collectWlFruitNames   = (type(st.collectWlFruitNames) == "table") and st.collectWlFruitNames or {}
			CFG.collectWlFruitEnabled = st.collectWlFruitEnabled or false
			CFG.collectWlMutNames     = (type(st.collectWlMutNames) == "table") and st.collectWlMutNames or {}
			CFG.collectWlMutEnabled   = st.collectWlMutEnabled or false
			CFG.collectCombFruitNames = (type(st.collectCombFruitNames) == "table") and st.collectCombFruitNames or {}
			CFG.collectCombMutNames   = (type(st.collectCombMutNames) == "table") and st.collectCombMutNames or {}
			CFG.collectCombVariants   = (type(st.collectCombVariants) == "table") and st.collectCombVariants or {}
			CFG.collectCombMode       = st.collectCombMode or ">= (berat minimal)"
			CFG.collectCombWeight     = tonumber(st.collectCombWeight) or 0
			CFG.collectCombEnabled    = st.collectCombEnabled or false

			CFG.favFruitNames = (type(st.favFruitNames) == "table") and st.favFruitNames or {}
			CFG.favMutNames   = (type(st.favMutNames) == "table") and st.favMutNames or {}
			CFG.favMode       = st.favMode or ">= (berat minimal)"
			CFG.favWeight     = tonumber(st.favWeight) or 0
			CFG.favDelay      = tonumber(st.favDelay) or 1
			CFG.favEnabled    = st.favEnabled or false
			CFG.unfavEnabled  = st.unfavEnabled or false

			CFG.buySummerSeedNames   = (type(st.buySummerSeedNames) == "table") and st.buySummerSeedNames or {}
			CFG.buySummerSeedEnabled = st.buySummerSeedEnabled or false
			CFG.buyTideTokenNames    = (type(st.buyTideTokenNames) == "table") and st.buyTideTokenNames or {}
			CFG.buyTideTokenEnabled  = st.buyTideTokenEnabled or false
			CFG.reclaimPlantNames = (type(st.reclaimPlantNames) == "table") and st.reclaimPlantNames or {}
			CFG.reclaimEnabled    = st.reclaimEnabled or false
			CFG.reclaimSpeed      = tonumber(st.reclaimSpeed) or 0.15
			CFG.plantSeedNames   = (type(st.plantSeedNames) == "table") and st.plantSeedNames or {}
			CFG.plantPosition    = (st.plantPosition == "Player Position") and "Player Position" or "Random"
			CFG.plantDelay       = tonumber(st.plantDelay) or 0
			CFG.plantSeedEnabled = st.plantSeedEnabled or false
			CFG.sprinklerNames        = (type(st.sprinklerNames) == "table") and st.sprinklerNames or {}
			CFG.sprinklerPlantNames   = (type(st.sprinklerPlantNames) == "table") and st.sprinklerPlantNames or {}
			CFG.sprinklerPosition     = (st.sprinklerPosition == "Player Position") and "Player Position" or "Random"
			CFG.sprinklerDelay        = tonumber(st.sprinklerDelay) or 0
			CFG.sprinklerEnabled      = st.sprinklerEnabled or false
			CFG.shovelSprinklerNames  = (type(st.shovelSprinklerNames) == "table") and st.shovelSprinklerNames or {}
			CFG.shovelSprinklerDelay  = tonumber(st.shovelSprinklerDelay) or 0
			CFG.shovelSprinklerEnabled = st.shovelSprinklerEnabled or false
			CFG.reconnectEnabled  = st.reconnectEnabled or false
			CFG.reconnectInterval = tonumber(st.reconnectInterval) or 5

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
			CFG.elephantV2Team      = (type(st.elephantV2Team) == "table") and st.elephantV2Team or {}
			CFG.elephantV2Types     = (type(st.elephantV2Types) == "table") and st.elephantV2Types or {}
			CFG.elephantV2Weight    = tonumber(st.elephantV2Weight) or 5.5
			CFG.elephantV2MaxPets   = tonumber(st.elephantV2MaxPets) or 3
			CFG.elephantV2Gajah     = (type(st.elephantV2Gajah) == "string") and st.elephantV2Gajah or ""
			CFG.elephantV2Switch    = (type(st.elephantV2Switch) == "string") and st.elephantV2Switch or ""
			CFG.elephantV2Level     = tonumber(st.elephantV2Level) or 40
			CFG.elephantV2Interval  = tonumber(st.elephantV2Interval) or 0.1
			CFG.elephantV2Enabled   = st.elephantV2Enabled or false

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
]=],
	["modules/core/registry.lua"] = [=[
--[[ registry.lua — opsi dropdown pet type & mutation. ]]
return function(ctx)
	local PetEggs   = ctx.deps.PetEggs
	local EnumToMut = ctx.deps.EnumToMut

	-- Daftar pet type unik (nama saja, tanpa egg) untuk filter trade.
	-- + peta pet->egg (buat label "Pet - Egg" di filter sell).
	local PET_OPTIONS = {}
	local petEggMap = {}   -- petType -> eggName (egg pertama yg punya pet ini)
	do
		local seen = {}
		for eggName, egg in pairs(PetEggs) do
			local items = egg.RarityData and egg.RarityData.Items
			if items then
				-- skip egg catch-all/admin (mis. "Fake Egg" isi 431 pet) dari peta pet->egg
				local cnt = 0; for _ in pairs(items) do cnt = cnt + 1 end
				local realEgg = eggName ~= "Fake Egg" and cnt <= 40
				for petName in pairs(items) do
					local s = tostring(petName):match("([^/]+)$") or tostring(petName)
					if not tostring(petName):match("^Egg/") and not seen[s] then
						seen[s] = true
						PET_OPTIONS[#PET_OPTIONS + 1] = s
					end
					if realEgg and not petEggMap[s] then petEggMap[s] = eggName end
				end
			end
		end
		table.sort(PET_OPTIONS)
	end

	-- Opsi filter sell: "Pet - Egg". Label = value (dipakai sbg key filter).
	local PET_EGG_OPTIONS = {}
	for _, pt in ipairs(PET_OPTIONS) do
		local egg = petEggMap[pt]
		PET_EGG_OPTIONS[#PET_EGG_OPTIONS + 1] = egg and (pt .. " - " .. egg) or pt
	end
	local function petEggLabel(pt)
		local egg = petEggMap[pt]
		return egg and (pt .. " - " .. egg) or pt
	end

	-- CUMA pet yang punya egg asli (format "Pet - Egg"). Buat filter yang wajib ada egg-nya
	-- (Special Pets, Universal, Pet to Sell) — pet tanpa egg tidak ditampilkan.
	local PET_EGG_ONLY = {}
	for _, pt in ipairs(PET_OPTIONS) do
		if petEggMap[pt] then PET_EGG_ONLY[#PET_EGG_ONLY + 1] = pt .. " - " .. petEggMap[pt] end
	end

	local MUT_OPTIONS, seenMut = { "None" }, { None = true }
	for _, name in pairs(EnumToMut) do
		if name ~= "Normal" and not seenMut[name] then
			seenMut[name] = true
			MUT_OPTIONS[#MUT_OPTIONS + 1] = name
		end
	end
	table.sort(MUT_OPTIONS)

	-- Mutasi yang bisa dari mesin: MachineMutationTypes (base) + Level500MutationTypes (500 only).
	local MACHINE_MUT_OPTIONS = { "None" }
	do
		local ok, MutReg = pcall(function()
			return require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetMutationRegistry)
		end)
		local names, seen = {}, {}
		if ok and MutReg then
			for _, src in ipairs({ MutReg.MachineMutationTypes, MutReg.Level500MutationTypes }) do
				if type(src) == "table" then
					for name in pairs(src) do
						local n = tostring(name)
						if not seen[n] then seen[n] = true; names[#names + 1] = n end
					end
				end
			end
			-- Ice Golem-exclusive dari Mutation Machine (via passive Cold Gears): ada di
			-- PetMutationRegistry tapi bukan di MachineMutationTypes/Level500 -> tambah manual.
			for _, n in ipairs({ "ChristmasRally", "JollyDecorator", "MerryNursery", "GiantGolem" }) do
				local pmr = MutReg.PetMutationRegistry
				if type(pmr) == "table" and pmr[n] and not seen[n] then
					seen[n] = true; names[#names + 1] = n
				end
			end
		end
		if #names > 0 then
			table.sort(names)
			for _, n in ipairs(names) do MACHINE_MUT_OPTIONS[#MACHINE_MUT_OPTIONS + 1] = n end
		else
			MACHINE_MUT_OPTIONS = MUT_OPTIONS -- fallback: semua mutasi
		end
	end

	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
		return EnumToMut[code] or code
	end

	ctx.reg = {
		PET_OPTIONS = PET_OPTIONS,
		PET_EGG_OPTIONS = PET_EGG_OPTIONS,
		PET_EGG_ONLY = PET_EGG_ONLY,
		petEggLabel = petEggLabel,
		MUT_OPTIONS = MUT_OPTIONS,
		MACHINE_MUT_OPTIONS = MACHINE_MUT_OPTIONS,
		mutDisplay = mutDisplay,
	}
end
]=],
	["modules/core/services.lua"] = [=[
--[[ services.lua — services + deps game (garden). ]]
return function(ctx)
	local Players     = game:GetService("Players")
	local RS          = game:GetService("ReplicatedStorage")
	local HttpService = game:GetService("HttpService")
	local UserInputService = game:GetService("UserInputService")

	if not game:IsLoaded() then game.Loaded:Wait() end
	repeat task.wait() until Players.LocalPlayer

	ctx.Services = {
		Players = Players, RS = RS, HttpService = HttpService, UserInputService = UserInputService,
	}
	ctx.LP = Players.LocalPlayer

	local DataService = require(RS.Modules.DataService)
	local PetEggs     = require(RS.Data.PetRegistry.PetEggs)
	local MutReg      = require(RS.Data.PetRegistry.PetMutationRegistry)
	local okPU, PU    = pcall(require, RS.Modules.PetServices.PetUtilities)

	-- TradingController singleton (buat baca state trade aktif)
	local okTC, TradingController = pcall(require, RS.Modules.TradeControllers.TradingController)

	local TradeEvents = RS.GameEvents.TradeEvents

	ctx.deps = {
		DataService      = DataService,
		PetEggs          = PetEggs,
		MutReg           = MutReg,
		EnumToMut        = MutReg.EnumToPetMutation,
		TradingController = okTC and TradingController or nil,

		TradeEvents   = TradeEvents,
		SendRequest   = TradeEvents.SendRequest,
		RespondRequest = TradeEvents.RespondRequest,
		AddItem       = TradeEvents.AddItem,
		RemoveItem    = TradeEvents.RemoveItem,
		Accept        = TradeEvents.Accept,
		Confirm       = TradeEvents.Confirm,
		Decline       = TradeEvents.Decline,
		FavoriteItem  = RS.GameEvents:FindFirstChild("Favorite_Item"),
		Gift          = RS.GameEvents:FindFirstChild("Gift"),
		-- Gift pet langsung (beda dari trade): GiftPet masuk, AcceptPetGift buat terima.
		GiftPet       = RS.GameEvents:FindFirstChild("GiftPet"),
		AcceptPetGift = RS.GameEvents:FindFirstChild("AcceptPetGift"),
		-- PNP (pick & place): PetsService("UnequipPet",uuid) / ("EquipPet",uuid,cframeStr)
		PetsService   = RS.GameEvents:FindFirstChild("PetsService"),
		PU            = okPU and PU or nil,
		-- cooldown skill: PetCooldownsUpdated(uuid, {{Time=,Passive=},...})
		PetCooldownsUpdated = RS.GameEvents:FindFirstChild("PetCooldownsUpdated"),
	}
end
]=],
	["modules/core/webhook.lua"] = [=[
--[[ sender.lua — Helper kirim webhook Discord dengan bypass proxy. ]]
local HttpService = game:GetService("HttpService")

local function sendWebhook(url, payload, ctx)
	if not url or url == "" then return end

	-- Trim leading and trailing whitespace
	local cleanUrl = url:match("^%s*(.-)%s*$")
	if not cleanUrl or cleanUrl == "" then return end

	-- Nama & avatar pengirim webhook (override default). Semua notif tampil "AllegiaantHub".
	if type(payload) == "table" then
		if not payload.username then payload.username = "AllegiaantHub" end
		if not payload.avatar_url then payload.avatar_url = "https://i.pinimg.com/736x/52/0e/d5/520ed52b650b318e20e9460eca77ced8.jpg" end
	end
	
	-- Gunakan proxy jika menggunakan HttpService standard karena Discord memblokir Roblox UA
	local proxiedUrl = cleanUrl:gsub("discord.com/api/webhooks/", "webhook.lewis.es/api/webhooks/")
	proxiedUrl = proxiedUrl:gsub("discordapp.com/api/webhooks/", "webhook.lewis.es/api/webhooks/")
	
	local jsonPayload = HttpService:JSONEncode(payload)

	-- Kirim di thread TERPISAH (fire-and-forget) supaya request HTTP yg blocking
	-- (~100-500ms) TIDAK nge-freeze loop automation yg manggil -> cegah stutter.
	task.spawn(function()
	local sent = false
	local reqErr = ""

	-- 1. Coba gunakan executor HTTP request (client-side, bypass blocks)
	-- Mendukung baik key uppercase maupun lowercase untuk menjamin kompatibilitas 100% executor
	local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
	if reqFn then
		local success, res = pcall(function()
			return reqFn({
				Url = cleanUrl,
				url = cleanUrl,
				Method = "POST",
				method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["content-type"] = "application/json"
				},
				headers = {
					["Content-Type"] = "application/json",
					["content-type"] = "application/json"
				},
				Body = jsonPayload,
				body = jsonPayload
			})
		end)
		if success and res then
			if res.StatusCode == 200 or res.StatusCode == 204 then
				sent = true
			else
				reqErr = "StatusCode: " .. tostring(res.StatusCode) .. " - " .. tostring(res.Body or "No response body")
			end
		else
			reqErr = tostring(res or "Unknown executor request error")
		end
	else
		reqErr = "Executor tidak memiliki fungsi request/http_request"
	end

	-- 2. Fallback ke HttpService:PostAsync (menggunakan proxy) jika executor request gagal atau tidak tersedia
	if not sent then
		local success, err = pcall(function()
			HttpService:PostAsync(proxiedUrl, jsonPayload, Enum.HttpContentType.ApplicationJson)
		end)
		if success then
			sent = true
		else
			local errMsg = "Fallback failed: " .. tostring(err) .. " | Exec error: " .. reqErr
			warn("[AllegiaanGarden Webhook] " .. errMsg)
			if ctx and ctx.log then
				ctx.log("[Webhook Error] " .. errMsg)
			end
		end
	end
	end)
end

return sendWebhook
]=],
	["modules/elephant/automation_elephant_v1.lua"] = [=[
--[[ elephant.lua — Automation Elephant (V1).
     Sama seperti Leveling, tapi patokan = BERAT (PetData.BaseWeight, KG), bukan Level.
     Passive elephant numbuhin berat pet target; kalau pet sudah mencapai Target Weight
     (mis. 5.5 KG = max), dicabut dan diganti pet target lain yang belum max. ]]
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

	ctx.state.elephantStatus = "Idle"

	-- Ringkasan statistik untuk UI Status
	function ctx.getElephantSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamCount = 0
		for _ in pairs(CFG.elephantTeamUuids) do teamCount = teamCount + 1 end

		local typesList = {}
		for k in pairs(CFG.elephantPetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"

		local readyCount, maxKgCount = 0, 0
		local targetW = CFG.elephantTargetWeight or 5.5

		for _, v in pairs(inv) do
			local pt = v.PetType
			if CFG.elephantPetTypes[pt] then
				local pd = v.PetData or {}
				local w = pd.BaseWeight or 0
				if not pd.IsFavorite then
					if w < targetW then readyCount = readyCount + 1 else maxKgCount = maxKgCount + 1 end
				end
			end
		end

		return {
			status = CFG.elephantEnabled and "ACTIVE" or "STOPPED",
			team = string.format("%d pets", teamCount),
			types = typesStr,
			ready = string.format("%d pets", readyCount),
			maxKg = string.format("%d pets", maxKgCount),
			maxTarget = string.format("%d pets", CFG.elephantMaxPets or 2),
			targetWeight = string.format("%.1f KG", targetW),
		}
	end

	local function checkElephant()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local teamSet = CFG.elephantTeamUuids or {}
		local targetTypes = CFG.elephantPetTypes or {}
		local targetW = CFG.elephantTargetWeight or 5.5
		local maxPets = CFG.elephantMaxPets or 2

		-- Lacak equip lokal (kebal delay replikasi)
		local localEq, localEqCount = {}, 0
		for _, uuid in ipairs(eq) do localEq[uuid] = true; localEqCount = localEqCount + 1 end

		-- A. FIRST RUN: cabut semua pet aktif
		if ctx.state.elephantFirstRun then
			ctx.state.elephantFirstRun = false
			if #eq > 0 then
				ctx.state.elephantStatus = "Resetting garden..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil; localEqCount = localEqCount - 1
					task.wait(0.25)
				end
			end
		end

		-- B. PERSISTENSI TEAM: pasang lagi pet team yang kecabut
		for uuid, _ in pairs(teamSet) do
			if not localEq[uuid] then
				ctx.state.elephantStatus = "Re-equipping team..."
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[uuid] = true; localEqCount = localEqCount + 1
					task.wait(0.3)
				end
			end
		end

		-- C. KLASIFIKASI pet target yang di-equip (by BaseWeight)
		local currentGrowing = {}  -- weight < target
		local finishedMax = {}     -- weight >= target
		local otherEquipped = {}
		for uuid, _ in pairs(localEq) do
			if not teamSet[uuid] then
				local pInfo = inv[uuid]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				local w = pd.BaseWeight or 0
				if targetTypes[pt] then
					if w < targetW then
						table.insert(currentGrowing, uuid)
						-- catat waktu mulai growing (buat Duration di webhook per-pet)
						ctx.state.elephantStartTime = ctx.state.elephantStartTime or {}
						if not ctx.state.elephantStartTime[uuid] then
							ctx.state.elephantStartTime[uuid] = os.time()
						end
					else table.insert(finishedMax, uuid) end
				else
					table.insert(otherEquipped, uuid)
				end
			end
		end

		-- D. LEPAS pet yang sudah MAX KG (+ webhook agregat + kartu per-pet)
		for _, uuid in ipairs(finishedMax) do
			local pInfo = inv[uuid]
			local pd = pInfo and pInfo.PetData or {}
			local pt = pInfo and pInfo.PetType or "?"
			local w = pd.BaseWeight or 0
			-- Durasi: dari mulai growing sampai sekarang; nil kalau start ga kecatat (mis. reload)
			local duration
			if ctx.state.elephantStartTime and ctx.state.elephantStartTime[uuid] then
				duration = os.time() - ctx.state.elephantStartTime[uuid]
				ctx.state.elephantStartTime[uuid] = nil
			end
			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil; localEqCount = localEqCount - 1
			if ctx.webhookElephant then
				if ctx.webhookElephant.onFinished then
					pcall(function() ctx.webhookElephant.onFinished(ctx, pt, w) end)
				end
				if ctx.webhookElephant.sendFinished then
					pcall(function() ctx.webhookElephant.sendFinished(ctx, pt, w, pd.MutationType, pd.Level or 0, duration) end)
				end
			end
			task.wait(0.25)
		end

		-- E. TAMBAH pet baru dari inventory (BaseWeight terendah dulu)
		local needed = maxPets - #currentGrowing
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local w = pd.BaseWeight or 0
				if not localEq[uuid] and targetTypes[pt] and w < targetW and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, weight = w })
				end
			end
			table.sort(pool, function(a, b) return a.weight < b.weight end)

			for i = 1, math.min(needed, #pool) do
				local target = pool[i]
				local pos = getPos(target.uuid)
				if pos then
					if localEqCount >= 15 and #otherEquipped > 0 then
						local toRemove = table.remove(otherEquipped)
						pcall(function() PetsService:FireServer("UnequipPet", toRemove) end)
						localEq[toRemove] = nil; localEqCount = localEqCount - 1
						task.wait(0.25)
					end
					pcall(function() PetsService:FireServer("EquipPet", target.uuid, CFrame.new(pos)) end)
					localEq[target.uuid] = true; localEqCount = localEqCount + 1
					table.insert(currentGrowing, target.uuid)
					ctx.state.elephantStartTime = ctx.state.elephantStartTime or {}
					ctx.state.elephantStartTime[target.uuid] = os.time()
					task.wait(0.3)
				end
			end
		end

		ctx.state.elephantStatus = string.format("Elephant: %d/%d aktif", #currentGrowing, maxPets)
	end

	local function elephantLoop()
		ctx.state.elephantId = (ctx.state.elephantId or 0) + 1
		local myId = ctx.state.elephantId
		ctx.elevate()
		ctx.state.elephantFirstRun = true

		-- Webhook saat enable (sama seperti leveling: cukup URL keisi, sender cek URL sendiri)
		task.spawn(function()
			if ctx.webhookElephant then
				pcall(function() ctx.webhookElephant.sendEnabled(ctx) end)
			end
		end)

		while CFG.elephantEnabled and ctx.alive() and ctx.state.elephantId == myId do
			pcall(checkElephant)
			task.wait(3.0)
		end
		ctx.state.elephantStatus = "Idle"
	end

	function ctx.startElephant()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda dari fitur lain
		ctx.state.elephantCfgOverride = nil -- webhook elephant pakai config standalone (bukan Growth)
		ctx.state.elephantWebhookPost = nil -- standalone: edit pesan (bukan POST tiap selesai)
		task.spawn(elephantLoop)
	end

	-- Matikan: hentikan loop lalu CABUT SEMUA pet dari garden sampai kosong total.
	function ctx.stopElephant()
		ctx.state.elephantId = (ctx.state.elephantId or 0) + 1 -- invalidate loop yang jalan
		task.spawn(function()
			ctx.state.elephantStatus = "Clearing garden..."
			task.wait(0.3)
			for _ = 1, 30 do
				local ok, d = pcall(function() return DataService:GetData() end)
				local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
				if #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				task.wait(0.4)
			end
			ctx.state.elephantStatus = "Idle (garden kosong)"
		end)
	end
end
]=],
	["modules/elephant/automation_elephant_v2.lua"] = [=[
--[[ elephant_v2.lua — Automation Elephant V2.
     Sama seperti V1 (equip team + rotasi pet target by BaseWeight, lepas pas
     capai Target Weight, jaga Max Target Pets aktif), TAPI plus swap GAJAH:
     gajah normalnya di luar garden; begitu ada target >= Trigger Level (mis. 40)
     gajah di-swap MASUK nuker 1 pet Switch (tanpa delay), keluar lagi pas ga ada
     target di level itu. Leveling target dilakukan PNP (jalan barengan).

     2 loop terpisah:
       - rotationLoop: pelan (~1.5s) — jaga team + rotasi target (ala V1).
       - swapLoop: cepat (0.1s) — cuma swap gajah <-> switch. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")

	local function farmCenter()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		local farm = ok and GetFarm and GetFarm(LP)
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
		return c + Vector3.new(((i % 6) - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	local function snapshot()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return nil, nil end
		return d.PetsData.EquippedPets or {}, (d.PetsData.PetInventory and d.PetsData.PetInventory.Data) or {}
	end
	local function isEquipped(eq, uuid)
		if not uuid or uuid == "" or not eq then return false end
		for _, u in ipairs(eq) do if u == uuid then return true end end
		return false
	end

	----------------------------------------------------- STATUS
	function ctx.getElephantV2Summary()
		local _, inv = snapshot()
		inv = inv or {}
		local teamCount = 0
		for _ in pairs(CFG.elephantV2Team or {}) do teamCount = teamCount + 1 end
		local typesList = {}
		for k in pairs(CFG.elephantV2Types or {}) do table.insert(typesList, k) end
		table.sort(typesList)
		local targetW = CFG.elephantV2Weight or 5.5
		local readyCount, maxKgCount = 0, 0
		for _, v in pairs(inv) do
			if CFG.elephantV2Types[v.PetType] then
				local pd = v.PetData or {}
				if not pd.IsFavorite then
					if (pd.BaseWeight or 0) < targetW then readyCount = readyCount + 1 else maxKgCount = maxKgCount + 1 end
				end
			end
		end
		return {
			status = CFG.elephantV2Enabled and "ACTIVE" or "STOPPED",
			info   = ctx.state.elephantV2Status or "Idle",
			team   = string.format("%d pets", teamCount),
			types  = #typesList > 0 and table.concat(typesList, ", ") or "None",
			ready  = string.format("%d pets", readyCount),
			maxKg  = string.format("%d pets", maxKgCount),
			maxTarget = string.format("%d pets", CFG.elephantV2MaxPets or 3),
			targetWeight = string.format("%.1f KG", targetW),
			gajah  = ctx.elephantV2Label(CFG.elephantV2Gajah),
			switch = ctx.elephantV2Label(CFG.elephantV2Switch),
			level  = tostring(CFG.elephantV2Level or 40),
		}
	end

	----------------------------------------------------- ROTASI (ala V1)
	-- absentSince[uuid] = os.clock() sejak pet TERAKHIR kali kebaca ga ke-equip. Dipakai di
	-- reserved mode: elephant cuma re-equip pet yg absent >= 5 detik (biar ga ngerebut PnP yg
	-- cuma unequip sebentar pas pickup). Reset ke nil begitu pet kebaca ke-equip lagi.
	local absentSince = {}
	local ABSENT_GRACE = 5 -- detik
	local function absentLongEnough(uuid)
		absentSince[uuid] = absentSince[uuid] or os.clock()
		return (os.clock() - absentSince[uuid]) >= ABSENT_GRACE
	end
	local function checkRotation()
		local eq, inv = snapshot()
		if not eq then return end
		local teamSet = CFG.elephantV2Team or {}
		local targetTypes = CFG.elephantV2Types or {}
		local targetW = CFG.elephantV2Weight or 5.5
		local maxPets = CFG.elephantV2MaxPets or 3
		local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
		local gajahIn = isEquipped(eq, gajah)

		-- A. FIRST RUN (pas enable): reset garden dulu — TAPI di mode reserved (switch kosong)
		--    reset-all DILEWATI biar pet PnP yg lagi jalan ga ke-wipe. Langsung lanjut naruh team.
		local reserved = (switch == nil or switch == "")
		if ctx.state.elephantV2FirstRun then
			ctx.state.elephantV2FirstRun = false
			if not reserved and #eq > 0 then
				ctx.state.elephantV2Status = "Reset garden (cabut semua pet)..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				return
			end
			-- reserved: jangan reset, lanjut ke penempatan team di bawah
		end

		local localEq, localEqCount = {}, 0
		for _, uuid in ipairs(eq) do localEq[uuid] = true; localEqCount = localEqCount + 1 end
		-- pet yg lagi ke-equip -> reset timer absent-nya (dia lagi ada)
		for uuid in pairs(localEq) do absentSince[uuid] = nil end

		-- B. PERSISTENSI TEAM: pasang lagi team yg kecabut (skip gajah; skip switch pas gajah in).
		--    RESERVED mode: cuma re-equip kalau udah absent >= 5s -> ga ngerebut PnP yg unequip
		--    sebentar pas pickup (PnP bakal balikin sendiri jauh sebelum 5s).
		for uuid in pairs(teamSet) do
			if uuid ~= gajah and not (gajahIn and uuid == switch) then
				if not localEq[uuid] then
					if (not reserved) or absentLongEnough(uuid) then
						local pos = getPos(uuid)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
							localEq[uuid] = true; localEqCount = localEqCount + 1
							absentSince[uuid] = nil
							task.wait(0.25)
						end
					end
				end
			end
		end

		-- C. KLASIFIKASI target equipped by BaseWeight (jangan sentuh team & gajah)
		local currentGrowing, finishedMax = {}, {}
		for uuid in pairs(localEq) do
			if not teamSet[uuid] and uuid ~= gajah then
				local pInfo = inv[uuid]
				local pd = pInfo and pInfo.PetData or {}
				local pt = pInfo and pInfo.PetType
				if pt and targetTypes[pt] then
					if (pd.BaseWeight or 0) < targetW then table.insert(currentGrowing, uuid)
					else table.insert(finishedMax, uuid) end
				end
			end
		end

		-- D. LEPAS target yang sudah MAX KG
		for _, uuid in ipairs(finishedMax) do
			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil; localEqCount = localEqCount - 1
			task.wait(0.2)
		end

		-- E. TAMBAH target baru (BaseWeight terendah dulu) sampai maxPets
		local needed = maxPets - #currentGrowing
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pd = v.PetData or {}
				if not localEq[uuid] and targetTypes[v.PetType] and (pd.BaseWeight or 0) < targetW and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, weight = pd.BaseWeight or 0 })
				end
			end
			table.sort(pool, function(a, b) return a.weight < b.weight end)
			for i = 1, math.min(needed, #pool) do
				local uuid = pool[i].uuid
				-- RESERVED: skip pet yg baru aja absent (<5s) -> kemungkinan cuma lagi di-PnP
				-- (unequip sebentar). Cuma tambahin yg beneran nganggur/absent lama.
				if (not reserved) or absentLongEnough(uuid) then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						localEq[uuid] = true; localEqCount = localEqCount + 1
						absentSince[uuid] = nil
						table.insert(currentGrowing, uuid)
						task.wait(0.3)
					end
				end
			end
		end
	end

	----------------------------------------------------- SWAP GAJAH (cepat)
	-- Cuma trigger kalau ada target yang LAGI KE-EQUIP, masih growing (weight < target),
	-- dan level >= ambang. Pet maxed / yang cuma nganggur di inventory TIDAK dihitung.
	local function anyTargetReady(eq, inv)
		local types = CFG.elephantV2Types or {}
		local thr = CFG.elephantV2Level or 40
		local targetW = CFG.elephantV2Weight or 5.5
		for _, u in ipairs(eq) do
			local v = inv[u]
			if v and types[v.PetType] then
				local pd = v.PetData or {}
				if (pd.BaseWeight or 0) < targetW and (pd.Level or 0) >= thr then return true end
			end
		end
		return false
	end
	local function eqCount(eq) return eq and #eq or 0 end

	-- Masukin GAJAH dengan AMAN: gajah HANYA boleh nuker SWITCH, atau pakai slot yang
	-- beneran kosong. Kalau Switch lagi ga ke-equip DAN garden penuh -> SKIP (biar
	-- ga bump pet lain sembarangan). Ini kunci: slot bebas WAJIB dari switch dulu.
	local function swapInGajah(gajah, switch)
		local eq = snapshot()
		if isEquipped(eq, gajah) then return true end
		local pos = farmCenter()
		if isEquipped(eq, switch) then
			-- cabut switch, TUNGGU beneran kecabut (slot bebas), baru masukin gajah
			pcall(function() PetsService:FireServer("UnequipPet", switch) end)
			for _ = 1, 8 do
				task.wait(0.04)
				eq = snapshot()
				if not isEquipped(eq, switch) then break end
			end
			if isEquipped(eq, switch) then return false end -- gagal cabut switch, jangan equip
		elseif eqCount(eq) >= 8 then
			return false -- switch ga ada & garden penuh -> jangan bump pet lain
		end
		-- slot dijamin ada (dari switch / emang kosong)
		if pos then pcall(function() PetsService:FireServer("EquipPet", gajah, CFrame.new(pos)) end) end
		for _ = 1, 3 do task.wait(0.06); if isEquipped(snapshot(), gajah) then return true end end
		return false
	end

	-- Keluarin GAJAH: cabut gajah, balikin SWITCH ke slot yang bebas.
	local function swapOutGajah(gajah, switch)
		local eq = snapshot()
		if not isEquipped(eq, gajah) then return true end
		local pos = farmCenter()
		pcall(function() PetsService:FireServer("UnequipPet", gajah) end)
		for _ = 1, 8 do
			task.wait(0.04)
			eq = snapshot()
			if not isEquipped(eq, gajah) then break end
		end
		-- reserved mode (switch kosong): slot dibiarin kosong, JANGAN equip apa2 (biar PnP aman)
		if switch and switch ~= "" and pos then pcall(function() PetsService:FireServer("EquipPet", switch, CFrame.new(pos)) end) end
		return true
	end

	-- Cari 1 pet target yang lagi ke-equip, tipe cocok, weight < target, level >= ambang.
	-- Return uuid + BaseWeight-nya. Dipakai buat mode reserved (boost by 0.1kg).
	local function getReadyTarget(eq, inv)
		local types = CFG.elephantV2Types or {}
		local thr = CFG.elephantV2Level or 40
		local targetW = CFG.elephantV2Weight or 5.5
		for _, u in ipairs(eq) do
			local v = inv[u]
			if v and types[v.PetType] then
				local pd = v.PetData or {}
				if (pd.BaseWeight or 0) < targetW and (pd.Level or 0) >= thr then return u, (pd.BaseWeight or 0) end
			end
		end
		return nil
	end
	local function baseWOf(inv, uuid)
		local v = inv and inv[uuid]; local pd = v and v.PetData
		return pd and (pd.BaseWeight or 0) or nil
	end

	local function rotationLoop(myId)
		while CFG.elephantV2Enabled and ctx.alive() and ctx.state.elephantV2Id == myId do
			-- Rotasi TETAP jalan (naruh team + rotasi target). Yang dimatiin cuma reset-all pas
			-- reserved (di checkRotation) biar pet PnP ga ke-wipe.
			pcall(checkRotation)
			task.wait(1.5)
		end
	end

	local function swapLoop(myId)
		while CFG.elephantV2Enabled and ctx.alive() and ctx.state.elephantV2Id == myId do
			local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
			local reserved = (switch == nil or switch == "")
			if gajah == "" or gajah == nil then
				ctx.state.elephantV2Status = "Pilih Gajah dulu"
				task.wait(1)
			else
				local eq, inv = snapshot()
				if eq then
					local gajahIn = isEquipped(eq, gajah)
					if reserved then
						-- ===== MODE RESERVED: gajah masuk pas ada target lvl 40, keluar pas target +0.1kg =====
						local tUuid = getReadyTarget(eq, inv)
						if not tUuid then
							if gajahIn then
								swapOutGajah(gajah, switch)
								ctx.state.elephantV2TargetUuid = nil
								ctx.state.elephantV2Status = "Standby (ga ada target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
							else
								ctx.state.elephantV2Status = "Standby (nunggu target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
							end
						else
							if not gajahIn then
								-- masuk pakai slot kosong yang kamu reserve; catat berat target saat masuk
								if swapInGajah(gajah, switch) then
									ctx.state.elephantV2TargetUuid = tUuid
									ctx.state.elephantV2TargetW0 = baseWOf(inv, tUuid)
									ctx.state.elephantV2Status = "Gajah MASUK (boost target)"
								end
							else
								-- gajah in: cek target yg ditrack udah naik 0.1kg? kalau ya -> keluar
								local trackU = ctx.state.elephantV2TargetUuid
								local w0 = ctx.state.elephantV2TargetW0
								local wc = trackU and baseWOf(inv, trackU) or nil
								if (not trackU) or (not wc) or (w0 and wc >= w0 + 0.1) then
									swapOutGajah(gajah, switch)
									ctx.state.elephantV2TargetUuid = nil
									ctx.state.elephantV2Status = "Gajah keluar (target +0.1kg)"
								else
									ctx.state.elephantV2Status = ("Boost... (+%.2f/0.10 kg)"):format(math.max(0, wc - (w0 or wc)))
								end
							end
						end
					else
						-- ===== MODE NORMAL (pakai switch): perilaku lama =====
						local ready = anyTargetReady(eq, inv)
						if ready and not gajahIn then
							swapInGajah(gajah, switch)
							ctx.state.elephantV2Status = "Gajah MASUK (target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
						elseif not ready and gajahIn then
							swapOutGajah(gajah, switch)
							ctx.state.elephantV2Status = "Standby (gajah keluar)"
						else
							ctx.state.elephantV2Status = gajahIn and "Gajah aktif" or "Standby"
						end
					end
				end
				task.wait(CFG.elephantV2Interval or 0.1)
			end
		end
	end

	function ctx.startElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		local myId = ctx.state.elephantV2Id
		ctx.state.elephantV2FirstRun = true -- pas enable: reset garden dulu (cabut semua)
		ctx.elevate()
		task.spawn(function() rotationLoop(myId) end)
		task.spawn(function() swapLoop(myId) end)
	end
	function ctx.stopElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		ctx.state.elephantV2FirstRun = false
		ctx.state.elephantV2TargetUuid = nil
		local switch = CFG.elephantV2Switch
		local reserved = (switch == nil or switch == "")
		if reserved then
			-- MODE RESERVED: CUMA cabut gajah, JANGAN sentuh pet lain (PnP tetep aman jalan)
			ctx.state.elephantV2Status = "Cabut gajah..."
			task.spawn(function()
				local gajah = CFG.elephantV2Gajah
				for _ = 1, 5 do
					local eq = snapshot()
					if not eq or not isEquipped(eq, gajah) then break end
					pcall(function() PetsService:FireServer("UnequipPet", gajah) end)
					task.wait(0.12)
				end
				ctx.state.elephantV2Status = "Idle (gajah keluar, PnP jalan terus)"
			end)
			return
		end
		ctx.state.elephantV2Status = "Cabut semua pet (bersihin garden)..."
		-- Cabut SEMUA pet aktif di garden sampai bener2 bersih (multi-pass, kebal delay replikasi)
		task.spawn(function()
			for _ = 1, 5 do
				local eq = snapshot()
				if not eq or #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.12)
				end
				task.wait(0.2)
			end
			ctx.state.elephantV2Status = "Idle (garden bersih)"
		end)
	end

	----------------------------------------------------- UI helpers
	local function petLabel(uuid)
		if not uuid or uuid == "" then return "Select" end
		local _, inv = snapshot()
		local v = inv and inv[uuid]
		if not v then return "#" .. tostring(uuid):sub(2, 5) end
		local pd = v.PetData or {}
		local mut = pd.MutationType
		local mutName = (mut and ctx.reg and ctx.reg.mutDisplay) and ctx.reg.mutDisplay(mut) or mut
		local pre = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
		return ("%s%s | Age %s | #%s"):format(pre, v.PetType or "?", tostring(pd.Level or 0), tostring(uuid):sub(2, 5))
	end
	ctx.elephantV2Label = petLabel

	function ctx.elephantV2GajahOptions()
		local out = { { name = "", display = "\u{274C} Kosongkan" } }
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			out[#out + 1] = { name = o.value, display = o.display }
		end
		return out
	end
	function ctx.elephantV2SwitchOptions()
		-- Opsi Kosongkan di paling atas (buat mode reserved: slot dibiarin kosong).
		-- Tampilin SEMUA pet inventory (bukan cuma team) biar pilihan selalu keliatan.
		local out = { { name = "", display = "\u{274C} Kosongkan (reserved slot)" } }
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			out[#out + 1] = { name = o.value, display = o.display }
		end
		return out
	end
end
]=],
	["modules/elephant/webhook.lua"] = [=[
--[[ webhook/elephant.lua — Discord webhook untuk Automation Elephant.
     Konsep:
       - sendEnabled: kirim 1 pesan (Boosting Statistics KOSONG), tangkap message id.
       - onFinished:  tiap pet target selesai (>= max KG), tambah ke tally lalu
                      EDIT pesan yang sama (boosting stats keisi bertahap).
     Pakai executor request() langsung (POST ?wait=true buat dapat id, PATCH buat edit). ]]
local HttpService = game:GetService("HttpService")
local elephantWebhook = {}

local USERNAME = "AllegiaantHub"
local AVATAR = "https://i.pinimg.com/736x/52/0e/d5/520ed52b650b318e20e9460eca77ced8.jpg"

local function bracketLabel(w)
	local lo = math.floor(w * 10) / 10
	return string.format("%.2f-%.2f KG", lo + 0.01, lo + 0.09)
end

-- Format durasi detik -> "Xh Ym Zs" / "Xm Ys" / "Ys". nil/false -> "-" (start ga kecatat).
local function fmtDuration(sec)
	if sec == nil then return "-" end
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	if sec >= 3600 then return string.format("%dh %dm %ds", math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60) end
	if sec >= 60 then return string.format("%dm %ds", math.floor(sec / 60), sec % 60) end
	return string.format("%ds", sec)
end

local function reqFn()
	return (syn and syn.request) or (http and http.request) or http_request or request
end

-- Sumber config: override Growth (ctx.state.elephantCfgOverride) kalau ada, else CFG standalone.
local function ecfg(ctx)
	local o = ctx.state and ctx.state.elephantCfgOverride
	if o then return o.team or {}, o.types or {}, o.weight or 5.5 end
	local CFG = ctx.CFG
	return CFG.elephantTeamUuids or {}, CFG.elephantPetTypes or {}, CFG.elephantTargetWeight or 5.5
end

-- Scan inventory live: pisah pet target jadi 'selesai' (>= target KG) dan 'sisa' (< target KG).
-- Yang selesai dikelompokkan per type + bracket berat (byType), plus total maxCount.
-- Sumber angka Boosting Statistics & Pets at Max KG = SEMUA pet target yang sudah max di data,
-- bukan cuma yang selesai selama sesi ini (tahan reload / re-enable).
local function scanTargets(ctx)
	local ok, d = pcall(function() return ctx.deps.DataService:GetData() end)
	local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
	local _, tt, tw = ecfg(ctx)
	local byType, maxCount, remains = {}, 0, 0
	for _, v in pairs(inv) do
		if v.PetType and tt[v.PetType] and not (v.PetData or {}).IsFavorite then
			local w = (v.PetData or {}).BaseWeight or 0
			if w < tw then
				remains = remains + 1
			else
				maxCount = maxCount + 1
				local bt = byType[v.PetType]
				if not bt then bt = { total = 0, brackets = {}, order = {} }; byType[v.PetType] = bt end
				bt.total = bt.total + 1
				local lbl = bracketLabel(w)
				if not bt.brackets[lbl] then bt.brackets[lbl] = 0; bt.order[#bt.order + 1] = lbl end
				bt.brackets[lbl] = bt.brackets[lbl] + 1
			end
		end
	end
	return byType, maxCount, remains
end

local function buildPayload(ctx)
	local base = ctx.state.elephantBase or {}
	local byType, maxCount, remains = scanTargets(ctx)

	local typeKeys = {}
	for t in pairs(byType) do typeKeys[#typeKeys + 1] = t end
	table.sort(typeKeys)
	local lines = {}
	for _, t in ipairs(typeKeys) do
		local bt = byType[t]
		lines[#lines + 1] = string.format("**%s:** %d", t, bt.total)
		table.sort(bt.order)
		for _, lbl in ipairs(bt.order) do
			lines[#lines + 1] = string.format("\226\128\162 %s (%s): %d", t, lbl, bt.brackets[lbl])
		end
	end
	local boostText = #lines > 0 and table.concat(lines, "\n") or "*Belum ada pet selesai*"

	local desc = string.format(
		"**Profile :**\n> \240\159\145\164 Username : ||%s||\n\n" ..
		"**Teams :**\n> Elephant Team: `%s`\n\n" ..
		"**Target Types :**\n> `%s`\n\n" ..
		"**Boosting Statistics :**\n%s\n\n" ..
		"**Pets at Max KG :** `%d`\n" ..
		"**Remains Queue :** `%d`",
		ctx.LP.Name, base.teamText or "None", base.typesText or "None",
		boostText, maxCount, remains)
	if #desc > 4000 then desc = desc:sub(1, 3980) .. "\n... (truncated)" end

	return {
		username = USERNAME,
		avatar_url = AVATAR,
		embeds = {
			{
				title = "\240\159\147\138 Growth \226\128\162 Elephant Statistics",
				color = 3066993,
				description = desc,
				footer = { text = os.date("%B %d | %I:%M %p"), icon_url = "https://i.imgur.com/H1Zh6V6.png" },
			}
		}
	}
end

-- Kirim saat enable: reset tally, kirim pesan (boosting kosong), simpan message id.
function elephantWebhook.sendEnabled(ctx)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	-- base info (team + target types)
	local ok, d = pcall(function() return ctx.deps.DataService:GetData() end)
	local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
	local teamSet, typesSet = ecfg(ctx)
	local teamCount, teamOrder = {}, {}
	for uuid in pairs(teamSet) do
		local v = inv[uuid]
		if v then
			local pt = v.PetType or "?"
			local mut = v.PetData and v.PetData.MutationType
			local mutName = (mut and ctx.reg and ctx.reg.mutDisplay) and ctx.reg.mutDisplay(mut) or mut
			local disp = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " " .. pt) or pt
			if not teamCount[disp] then teamCount[disp] = 0; teamOrder[#teamOrder + 1] = disp end
			teamCount[disp] = teamCount[disp] + 1
		end
	end
	table.sort(teamOrder)
	local teamParts = {}
	for _, disp in ipairs(teamOrder) do teamParts[#teamParts + 1] = teamCount[disp] .. " " .. disp end

	local typesList = {}
	for t in pairs(typesSet) do typesList[#typesList + 1] = t end
	table.sort(typesList)

	ctx.state.elephantBase = {
		teamText = #teamParts > 0 and table.concat(teamParts, ", ") or "None",
		typesText = #typesList > 0 and table.concat(typesList, ", ") or "None",
	}
	ctx.state.elephantTally = { byType = {}, maxCount = 0 }
	ctx.state.elephantMsgId = nil

	-- POST ?wait=true buat dapat message id
	local f = reqFn()
	if not f then return end
	local url = CFG.webhookUrl
	local sep = url:find("?", 1, true) and "&" or "?"
	local body = HttpService:JSONEncode(buildPayload(ctx))
	local okReq, res = pcall(function()
		return f({
			Url = url .. sep .. "wait=true", Method = "POST",
			Headers = { ["Content-Type"] = "application/json" }, Body = body,
		})
	end)
	if okReq and res and res.Body then
		local okj, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
		if okj and type(data) == "table" and data.id then
			ctx.state.elephantMsgId = tostring(data.id)
		end
	end
end

-- Tiap pet target selesai (>= max KG): kirim/EDIT pesan. Angka dihitung live dari
-- data di buildPayload (scanTargets), jadi tidak perlu tally manual lagi.
function elephantWebhook.onFinished(ctx, petType, weight)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	-- Mode POST (Growth: kirim pesan baru tiap pet selesai) ATAU edit pesan (standalone).
	local f = reqFn()
	if not f then return end
	local body = HttpService:JSONEncode(buildPayload(ctx))
	local postMode = ctx.state and ctx.state.elephantWebhookPost
	-- Request HTTP di thread terpisah (non-blocking) biar ga nge-freeze loop automation
	task.spawn(function()
		if ctx.state.elephantMsgId and not postMode then
			pcall(function()
				f({
					Url = CFG.webhookUrl .. "/messages/" .. ctx.state.elephantMsgId, Method = "PATCH",
					Headers = { ["Content-Type"] = "application/json" }, Body = body,
				})
			end)
		elseif ctx.sendWebhook then
			pcall(function() ctx.sendWebhook(CFG.webhookUrl, HttpService:JSONDecode(body), ctx) end)
		end
	end)
end

-- Kartu PER-PET saat 1 pet capai Max KG. Dikirim TIAP pet beres (pesan baru),
-- pelengkap statistik agregat. durationSec = nil -> "Duration: -" (start ga kecatat).
function elephantWebhook.sendFinished(ctx, petType, weight, mutation, age, durationSec)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end
	local mutDisplay = (ctx.reg and ctx.reg.mutDisplay and ctx.reg.mutDisplay(mutation)) or mutation or "None"
	local _, _, remains = scanTargets(ctx)

	local payload = {
		username = USERNAME,
		avatar_url = AVATAR,
		embeds = {
			{
				title = "\240\159\144\152 Growth \226\128\162 Elephant", -- 🐘
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Max KG Reached",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Weight: `%.2f KG`\n" ..
							"> Age: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Remains Queue: `%s`",
							tostring(petType or "?"),
							tostring(mutDisplay),
							tonumber(weight) or 0,
							tostring(age or "-"),
							fmtDuration(durationSec),
							tostring(remains)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return elephantWebhook
]=],
	["modules/event/auto_chest_hunt.lua"] = [=[
--[[ chesthunt.lua — Auto Global Chest Hunt (event Summer Chest Hunt).
     Konsep: TP ke chest -> auto-angkat (carry) -> bawa ke garden -> ulang sampai habis.
     Mekanik game (RE): touch/TP ke chest -> attribute char SummerChestHunt_CARRYING=true;
       bawa ke garden/platform buat deposit. CARRY_CAPACITY=1 (satu-satu).
     Catatan: tag chest belum kepastian (event belum spawn) -> finder robust + ctx.scanChests()
       buat verifikasi pas event live. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local CS = game:GetService("CollectionService")
	local LP = ctx.LP
	local CFG = ctx.CFG

	local function hrp() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local function rootPart(m)
		if not m then return nil end
		if m:IsA("BasePart") then return m end
		if m.PrimaryPart then return m.PrimaryPart end
		return m:FindFirstChildWhichIsA("BasePart")
	end
	local function carrying()
		local c = LP.Character
		return c and c:GetAttribute("SummerChestHunt_CARRYING") == true
	end

	-- kandidat tag chest (tebakan; finder fallback ke scan nama)
	local CHEST_TAGS = { "SummerChest", "SummerChestHuntChest", "GlobalChest", "SummerChestHunt_Chest", "ChestHuntChest", "SummerChestHuntGlobalChest" }

	-- exclude: dekorasi/NPC statis (semua di bawah Workspace.Interaction), karakter, cooler.
	-- Chest hunt asli spawn DINAMIS di luar Interaction (tersebar di map).
	local function excluded(m)
		if m:FindFirstChildOfClass("Humanoid") then return true end
		local low = tostring(m.Name):lower()
		if low:find("cooler") or low:find("egg") then return true end -- cooler & pet egg
		if m:FindFirstAncestor("Interaction") or m:FindFirstAncestor("PetEgg") then return true end
		if game.Players:GetPlayerFromCharacter(m) then return true end
		return false
	end

	-- Chest hunt asli: STRUKTUR chest (AnimationController + part Inside/Top1) = paling andal.
	-- Nama "...chest" jadi sinyal tambahan. (RARITY dipakai cuma kalau juga ada struktur.)
	local function isHuntChest(m)
		if not m:IsA("Model") or excluded(m) then return false end
		if not rootPart(m) then return false end
		local structHit = m:FindFirstChildOfClass("AnimationController") and (m:FindFirstChild("Inside") or m:FindFirstChild("Top1")) ~= nil
		local nameHit = tostring(m.Name):lower():find("chest") ~= nil
		return structHit or nameHit
	end

	local function findChests()
		local seen, out = {}, {}
		for _, tag in ipairs(CHEST_TAGS) do
			for _, inst in ipairs(CS:GetTagged(tag)) do
				if not seen[inst] then seen[inst] = true; out[#out + 1] = inst end
			end
		end
		for _, d in ipairs(workspace:GetDescendants()) do
			if isHuntChest(d) and not seen[d] then seen[d] = true; out[#out + 1] = d end
		end
		return out
	end

	-- Debug: apa yg kedetect sbg chest + semua tag baru di workspace (buat verifikasi pas event)
	function ctx.scanChests()
		local chests = findChests()
		local info = {}
		for i, c in ipairs(chests) do
			if i <= 10 then
				local r = rootPart(c)
				local pp = c:FindFirstChildWhichIsA("ProximityPrompt", true)
				info[#info + 1] = ("%s '%s' @ %s | prompt:%s"):format(c.ClassName, c.Name, r and tostring(r.Position):sub(1, 22) or "?", pp and (pp.ActionText .. "/" .. tostring(pp.HoldDuration) .. "s") or "NONE")
			end
		end
		-- semua model bernama "chest" (mentah, buat lihat kandidat + tag-nya)
		local rawChest = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			if (d:IsA("Model") or d:IsA("BasePart")) and tostring(d.Name):lower():find("chest") then
				local tg = table.concat(CS:GetTags(d), ",")
				rawChest[#rawChest + 1] = ("%s '%s' <%s> tags[%s]"):format(d.ClassName, d.Name, (d.Parent and d.Parent.Name) or "?", tg)
				if #rawChest >= 10 then break end
			end
		end
		-- model dgn STRUKTUR chest (AnimationController + Inside/Top1), by name apapun
		local structItems = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("Model") and not d:FindFirstChildOfClass("Humanoid")
				and d:FindFirstChildOfClass("AnimationController")
				and (d:FindFirstChild("Inside") or d:FindFirstChild("Top1")) then
				local r = rootPart(d)
				structItems[#structItems + 1] = ("'%s' <%s> @ %s"):format(d.Name, (d.Parent and d.Parent.Name) or "?", r and tostring(r.Position):sub(1, 24) or "?")
				if #structItems >= 10 then break end
			end
		end
		local tags = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			for _, t in ipairs(CS:GetTags(d)) do
				if (t:lower():find("chest") or t:lower():find("hunt")) then tags[t] = (tags[t] or 0) + 1 end
			end
		end
		return { chestCount = #chests, sample = info, rawChestNamed = rawChest, structChests = structItems, chestHuntTags = tags, carrying = carrying() }
	end

	local function depositPos()
		if CFG.chestHuntDeposit ~= "platform" then
			local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
			if ok and GetFarm then
				local farm = GetFarm(LP)
				local pa = farm and farm:FindFirstChild("PetArea")
				if pa then return pa.Position end
				local char = LP.Character; local h = char and char:FindFirstChild("HumanoidRootPart")
				if h then return h.Position end
			end
		end
		local plat = CS:GetTagged("SummerChestHuntPlatform")[1]
		if plat then return (plat:IsA("Model") and plat:GetPivot().Position) or (plat:IsA("BasePart") and plat.Position) end
		return nil
	end

	local function tpTo(pos, yOff)
		local h = hrp()
		if h and pos then h.CFrame = CFrame.new(pos + Vector3.new(0, yOff or 3, 0)) end
	end

	----------------------------------------------------------------- loop
	local function tick()
		if carrying() then
			ctx.state.chestStatus = "Carry -> deposit ke " .. (CFG.chestHuntDeposit or "garden")
			local dp = depositPos()
			for _ = 1, 24 do
				if not carrying() or not CFG.chestHuntEnabled then break end
				tpTo(dp, 3); task.wait(0.25)
			end
		else
			local chests = findChests()
			ctx.state.chestStatus = ("Chest tersisa: %d"):format(#chests)
			if #chests == 0 then task.wait(0.5); return end
			-- pilih chest terdekat
			local h = hrp(); local hp = h and h.Position
			local target, best = nil, math.huge
			for _, c in ipairs(chests) do
				local r = rootPart(c)
				if r then
					local dd = hp and (r.Position - hp).Magnitude or 0
					if dd < best then best = dd; target = c end
				end
			end
			if not target then return end
			local r = rootPart(target)
			-- carry = hold E (ProximityPrompt). TP deket chest -> trigger prompt-nya.
			local fireProx = fireproximityprompt or (getgenv and getgenv().fireproximityprompt)
			for _ = 1, 10 do
				if carrying() or not CFG.chestHuntEnabled or not target.Parent then break end
				tpTo(r.Position, 2)
				task.wait(0.15)
				local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt and fireProx then
					pcall(function() fireProx(prompt, prompt.HoldDuration or 0) end)
					pcall(function() fireProx(prompt) end)
				end
				task.wait(0.5)
			end
		end
	end

	ctx.state.chestStatus = "Idle"
	local function loop()
		ctx.state.chestId = (ctx.state.chestId or 0) + 1
		local my = ctx.state.chestId
		ctx.elevate()
		while CFG.chestHuntEnabled and ctx.alive() and ctx.state.chestId == my do
			pcall(tick)
			task.wait(0.3)
		end
		ctx.state.chestStatus = "Idle"
	end
	function ctx.startChestHunt() task.spawn(loop) end
	function ctx.stopChestHunt()
		ctx.state.chestId = (ctx.state.chestId or 0) + 1
		ctx.state.chestStatus = "Idle"
	end

	function ctx.getChestSummary()
		return { status = CFG.chestHuntEnabled and "ACTIVE" or "STOPPED", info = ctx.state.chestStatus or "Idle", deposit = CFG.chestHuntDeposit or "garden" }
	end

	-- Auto-trigger pas event mulai (StartGlobalChestHunt) kalau toggle nyala.
	pcall(function()
		local re = RS.GameEvents:FindFirstChild("SummerChestHunt")
		re = re and re:FindFirstChild("StartGlobalChestHunt")
		if re then
			re.OnClientEvent:Connect(function()
				if CFG.chestHuntEnabled then
					ctx.log("Chest Hunt event mulai -> auto-run.")
					ctx.startChestHunt()
				end
			end)
		end
	end)
end
]=],
	["modules/event/automation_summer_event.lua"] = [=[
--[[ summer.lua — Automation Summer Event: Sam The Clam.
     Flow (state dari DataService:GetData().SamTheClam):
       RewardReady == true                      -> ClaimReward
       IsRunning / SubmittedPet ~= nil          -> Working (tunggu timer ~1 jam)
       selain itu (Waiting)                     -> pegang pet (Humanoid:EquipTool) lalu SubmitHeldPet

     Pemilihan pet (aman, wajib eksplisit):
       - Tolak summer pool (Pelican/Manta Ray) — Sam nolak.
       - Filter tipe pet (CFG.summerPetTypes), berat min/max (CFG.summerMinWeight/Max),
         dan opsi ikut-sertakan favorite (CFG.summerAllowFavorite).
       - Kalau tidak ada filter tipe & berat yang diatur -> TIDAK submit (biar ga salah feed). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local SamRE = RS:WaitForChild("GameEvents"):WaitForChild("SamTheClamService_RE")
	local Favorite_Item    = RS.GameEvents:FindFirstChild("Favorite_Item")
	local Favorite_Item_BE = RS.GameEvents:FindFirstChild("Favorite_Item_BE")

	-- Pet summer yang ditolak Sam (ambil dinamis, fallback statis)
	local rejectPool = { Pelican = true, ["Manta Ray"] = true }
	pcall(function()
		local SamData = require(RS.Data.SamTheClamData)
		if SamData and SamData.SUMMER_PET_POOL then
			rejectPool = {}
			for _, v in ipairs(SamData.SUMMER_PET_POOL) do rejectPool[v.PetName] = true end
		end
	end)

	----------------------------------------------------------------- helpers
	local function getSamState()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return nil end
		return d.SamTheClam
	end

	-- Ringkasan status Sam untuk GUI (timer live).
	function ctx.getSamSummary()
		local sam = getSamState()
		if not sam then return { state = "Unknown", timer = "-", reward = "-" } end
		local state, timer
		if sam.RewardReady then
			state, timer = "READY", "Siap diklaim!"
		elseif sam.IsRunning or sam.SubmittedPet ~= nil then
			local left = math.max(0, math.floor(tonumber(sam.TimeLeft) or 0))
			timer = ("%02d:%02d"):format(math.floor(left / 60), left % 60)
			state = "WORKING"
		else
			state, timer = "IDLE", "Bisa submit pet"
		end
		local reward = "-"
		if type(sam.Reward) == "table" then
			reward = ("%s x%s"):format(tostring(sam.Reward.Value or "?"), tostring(sam.Reward.Quantity or "?"))
		end
		local submitted = sam.SubmittedPet and sam.SubmittedPet.PetType or "-"
		return { state = state, timer = timer, reward = reward, submitted = submitted }
	end

	-- Master list SEMUA tipe pet (dari PetRegistry.PetList), di-cache sekali.
	local masterPetNames
	local function getMasterPetNames()
		if masterPetNames then return masterPetNames end
		local names = {}
		pcall(function()
			local m = require(RS.Data.PetRegistry)
			local pl = m.PetList
			if type(pl) == "table" then
				if pl[1] ~= nil then
					for _, v in ipairs(pl) do
						local n = type(v) == "table" and (v.PetName or v.Name) or v
						if n then names[#names + 1] = tostring(n) end
					end
				else
					for k in pairs(pl) do names[#names + 1] = tostring(k) end
				end
			end
		end)
		table.sort(names)
		masterPetNames = names
		return names
	end

	-- daftar tipe pet buat dropdown Summer — TAMPILKAN SEMUA pet (walau belum punya),
	-- biar bisa pra-filter sebelum pet-nya ada. Pet yang ditolak Sam disembunyikan.
	-- Yang lagi dipunya ditandai "(x N)", yang kepilih ditaruh paling atas.
	function ctx.getSummerPetTypes(selectedSet)
		-- info kepemilikan dari inventory (display biasanya sudah bawa jumlah)
		local owned = {}
		local inv = ctx.getInventoryPetTypes and ctx.getInventoryPetTypes(selectedSet) or {}
		for _, o in ipairs(inv) do owned[o.value] = o.display end

		local sel = selectedSet or CFG.summerPetTypes or {}
		local opts, shown = {}, {}
		for _, name in ipairs(getMasterPetNames()) do
			if not rejectPool[name] then
				opts[#opts + 1] = { value = name, display = owned[name] or name }
				shown[name] = true
			end
		end
		-- tipe kepilih yang ga ada di master (jaga-jaga) tetap dimunculkan
		for t in pairs(sel) do
			if not shown[t] and not rejectPool[t] then
				opts[#opts + 1] = { value = t, display = owned[t] or t }
			end
		end
		-- kepilih dulu, lalu alfabet
		table.sort(opts, function(a, b)
			local sa, sb = sel[a.value] and 1 or 0, sel[b.value] and 1 or 0
			if sa ~= sb then return sa > sb end
			return a.value < b.value
		end)
		return opts
	end

	-- Ambil kandidat pet Tool dari Backpack yang lolos filter, urut berat menaik (feed teringan dulu).
	local function pickPetTool()
		local bp = LP:FindFirstChildOfClass("Backpack")
		if not bp then return nil end

		local petTypes = CFG.summerPetTypes or {}
		local hasTypeFilter = next(petTypes) ~= nil
		local minW = tonumber(CFG.summerMinWeight) or 0
		local maxW = tonumber(CFG.summerMaxWeight) or 0

		-- Safety: WAJIB pilih tipe pet (berat cuma nyaring di dalam tipe).
		-- Kalau tipe habis/kosong -> stop, jangan feed pet lain sembarangan.
		if not hasTypeFilter then
			return nil, "pilih tipe pet di filter dulu (biar ga salah feed)"
		end

		local best
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("PET_UUID") then
				local petType = t:GetAttribute("f")           -- ItemName = tipe pet
				local fav     = t:GetAttribute("d") == true    -- Favorite
				local weight  = tonumber(tostring(t.Name):match("%[([%d%.]+) KG%]"))

				local pass = true
				if not petType or rejectPool[petType] then pass = false end
				if pass and hasTypeFilter and not petTypes[petType] then pass = false end
				if pass and fav and not CFG.summerAllowFavorite then pass = false end
				if pass and weight then
					if minW > 0 and weight < minW then pass = false end
					if maxW > 0 and weight > maxW then pass = false end
				end

				if pass then
					local w = weight or 0
					if not best or w < best.w then best = { tool = t, w = w, petType = petType } end
				end
			end
		end

		if not best then return nil, "tidak ada pet cocok filter" end
		return best
	end

	----------------------------------------------------------------- aksi tunggal (reusable)
	-- Claim reward (TP ke Sam dulu). return true kalau di-fire.
	-- ClaimReward TIDAK butuh dekat Sam (server ga cek jarak) -> ga usah TP.
	function ctx.samClaimOnce()
		setStatus("Summer: claim reward...")
		pcall(function() SamRE:FireServer("ClaimReward") end)
		task.wait(3)
		return true
	end

	-- Pilih pet -> TP -> pegang -> unfav (bila perlu) -> SubmitHeldPet.
	-- return true kalau berhasil submit, false + alasan kalau tidak.
	function ctx.samSubmitOnce()
		local pick, why = pickPetTool()
		if not pick then return false, why or "no pet" end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return false, "no humanoid" end
		-- Submit TIDAK butuh dekat Sam (server ga cek jarak, sudah dites live).
		-- Yang wajib cuma megang pet-nya (EquipTool).
		pcall(function() hum:EquipTool(pick.tool) end)
		task.wait(0.5)
		local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
		if not (held and held:GetAttribute("PET_UUID") == pick.tool:GetAttribute("PET_UUID")) then
			return false, "gagal pegang pet"
		end
		if held:GetAttribute("d") == true and Favorite_Item then
			setStatus(("Summer: unfav %s dulu..."):format(pick.petType or "?"))
			pcall(function() Favorite_Item:FireServer(held) end)
			if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(held) end) end
			task.wait(0.4)
		end
		setStatus(("Summer: submit %s (%.2f KG)"):format(pick.petType or "?", pick.w))
		pcall(function() SamRE:FireServer("SubmitHeldPet") end)
		task.wait(3)
		return true
	end

	----------------------------------------------------------------- loop utama
	local function summerLoop()
		ctx.state.summerId = (ctx.state.summerId or 0) + 1
		local myId = ctx.state.summerId
		ctx.elevate()

		while CFG.summerEventEnabled and ctx.alive() and ctx.state.summerId == myId do
			local sam = getSamState()

			if sam and sam.RewardReady then
				ctx.samClaimOnce()
			elseif sam and (sam.IsRunning or sam.SubmittedPet ~= nil) then
				local left = tonumber(sam.TimeLeft) or 0
				setStatus(("Summer: Sam sibuk (%d menit lagi)"):format(math.floor(left / 60)))
				task.wait(math.clamp(left, 5, 30))
			else
				local ok, why = ctx.samSubmitOnce()
				if ok then
					-- Konfirmasi submit beneran kebaca server sebelum lanjut.
					-- Anti double-feed: kalau replikasi telat, JANGAN submit pet kedua.
					local confirmed = false
					for _ = 1, 8 do
						local s2 = getSamState()
						if s2 and (s2.IsRunning or s2.SubmittedPet ~= nil or s2.RewardReady) then confirmed = true; break end
						task.wait(1)
					end
					if not confirmed then
						setStatus("Summer: submit belum kebaca, tunggu...")
						task.wait(2)
					end
				else
					setStatus("Summer: " .. tostring(why)); task.wait(0.5)
				end
			end
		end
	end

	function ctx.startSummerEvent() task.spawn(summerLoop) end
end
]=],
	["modules/event/automation_summer_shop.lua"] = [=[
--[[ automation_summer_shop.lua — Auto Buy Summer Shop (event).
     Dua shop event:
       Summer Seed Shop  -> beli seed pakai Sheckles
       Tide Token Shop   -> beli item pakai TideTokens
     Opsi dropdown dari registry EventShopData (katalog, semua item tampil walau habis stock).
     Ada opsi "All" = beli semua yang lagi ada stock.
     Remote: BuyEventShopStock:FireServer(itemKey, shopName)
     Beli hanya saat restock (ShopSeed berubah) biar murah & ga lag.
     Fungsi: ctx.startBuySummerSeed / ctx.startBuyTideToken. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local BuyEventShopStock = GE:WaitForChild("BuyEventShopStock")
	local function setStatus(s) ctx.setStatus(s) end

	local SUMMER_SEED = "Summer Seed Shop"
	local TIDE_TOKEN  = "Tide Token Shop"

	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	-- Opsi dropdown dari katalog EventShopData[shop] (semua item DisplayInShop).
	local function shopOptions(shopName)
		local out = { { value = "All", display = "All (beli semua)" } }
		local ok, data = pcall(function() return require(RS.Data.EventShopData)[shopName] end)
		if ok and type(data) == "table" then
			local names = {}
			for key, v in pairs(data) do
				if type(v) == "table" and v.DisplayInShop then names[#names + 1] = key end
			end
			table.sort(names)
			for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		end
		return out
	end
	function ctx.getSummerSeedShopOptions() return shopOptions(SUMMER_SEED) end
	function ctx.getTideTokenShopOptions() return shopOptions(TIDE_TOKEN) end

	----------------------------------------------------------------- loop beli (per-shop)
	local POLL = 2
	local function buyLoop(shopName, enabledKey, selKey, idKey, label)
		ctx.state[idKey] = (ctx.state[idKey] or 0) + 1
		local myId = ctx.state[idKey]
		ctx.elevate()
		local lastSeed
		while CFG[enabledKey] and ctx.alive() and ctx.state[idKey] == myId do
			local d = getData()
			local shop = d and d.EventShopStock and d.EventShopStock[shopName]
			local seed = shop and shop.ShopSeed
			if shop and seed ~= lastSeed then -- restock baru (atau pertama jalan) -> beli
				lastSeed = seed
				local st = shop.Stocks or {}
				local sel = CFG[selKey] or {}
				local all = sel["All"]
				local bought = 0
				for itemKey, v in pairs(st) do
					if all or sel[itemKey] then
						local stock = type(v) == "table" and v.Stock or 0
						for _ = 1, stock do
							if not CFG[enabledKey] or ctx.state[idKey] ~= myId then break end
							pcall(function() BuyEventShopStock:FireServer(itemKey, shopName) end)
							bought = bought + 1; task.wait(0.2)
						end
					end
				end
				setStatus(("%s: restock -> beli %d"):format(label, bought))
			else
				setStatus(("%s: nunggu restock"):format(label))
			end
			task.wait(POLL)
		end
	end

	function ctx.startBuySummerSeed()
		task.spawn(function() buyLoop(SUMMER_SEED, "buySummerSeedEnabled", "buySummerSeedNames", "buySummerSeedId", "Summer Seed") end)
	end
	function ctx.startBuyTideToken()
		task.spawn(function() buyLoop(TIDE_TOKEN, "buyTideTokenEnabled", "buyTideTokenNames", "buyTideTokenId", "Tide Token") end)
	end
end
]=],
	["modules/farm/automation_collect.lua"] = [=[
--[[ automation_collect.lua — Auto Collect fruit (harvest ke backpack).
     Remote (dari CollectController): GameEvents.Crops.Collect:FireServer({fruitModel,...})
       — batch collect list FRUIT MODEL. Jalan walau jauh (server ga cek proximity).
     Backpack full: require(Modules.InventoryService):IsMaxInventory().
     Auto-sell: GameEvents.SellFood_RE:FireServer().
     3 mode (bisa barengan), collect fruit yang cocok SALAH SATU mode aktif:
       1) Whitelist Fruit   : tipe fruit terpilih
       2) Whitelist Mutation: fruit punya mutasi terpilih
       3) Combined          : fruit + mutasi + variant + berat (SEMUA kriteria) ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Collect = RS.GameEvents:WaitForChild("Crops"):WaitForChild("Collect")
	local SellInv = RS.GameEvents:WaitForChild("Sell_Inventory")
	local IS
	pcall(function() IS = require(RS.Modules.InventoryService) end)

	-- Jual semua fruit: HARUS deket NPC jual (Steven) — teleport bentar, jual, balik.
	local function sellAllFruits()
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local npcs = workspace:FindFirstChild("NPCS")
		local steven = npcs and npcs:FindFirstChild("Steven")
		local shrp = steven and steven:FindFirstChild("HumanoidRootPart")
		if not shrp then return end
		local orig = hrp.CFrame
		hrp.CFrame = shrp.CFrame * CFrame.new(0, 0, 4) -- deket Steven
		task.wait(0.5)
		pcall(function() SellInv:FireServer() end)
		task.wait(0.8)
		pcall(function() if hrp and hrp.Parent then hrp.CFrame = orig end end) -- balik
	end

	local NOT_MUTATION = {
		FruitVersion = true, MaxAge = true, GrowRateMulti = true, WeightMulti = true,
		DoneGrowTime = true, FruitSpawnIndex = true, OfflineGrowthTarget = true,
		MasteryGrowthMulti = true, MasterySizeMulti = true,
	}

	local function backpackFull()
		if not IS then return false end
		local ok, full = pcall(function() return IS:IsMaxInventory() end)
		return ok and full == true
	end

	local function eachFruit(fn)
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return end
		for _, garden in ipairs(Farm:GetChildren()) do
			if not garden:GetAttribute("CommunityGarden") then
				local imp = garden:FindFirstChild("Important")
				local pp = imp and imp:FindFirstChild("Plants_Physical")
				if pp then for _, plant in ipairs(pp:GetChildren()) do
					local fr = plant:FindFirstChild("Fruits")
					if fr then for _, f in ipairs(fr:GetChildren()) do fn(f) end end
				end end
			end
		end
	end

	----------------------------------------------------------------- opsi UI
	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getCollectFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getCollectVariantOptions()
		local set = { Normal = true, Gold = true, Rainbow = true }
		eachFruit(function(f) local v = f:FindFirstChild("Variant"); if v and v.Value ~= "" then set[tostring(v.Value)] = true end end)
		local names = {} for k in pairs(set) do names[#names + 1] = k end; table.sort(names)
		return optionsFrom(names, "All (semua variant)")
	end
	function ctx.getCollectMutationOptions()
		-- daftar LENGKAP semua mutasi buah dari registry (MutationHandler.MutationNames)
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (semua mutasi)")
	end
	function ctx.getCollectModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end

	----------------------------------------------------------------- match per-mode
	local function hasSelMut(f, muts)
		for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then return true end end
		return false
	end
	local function fruitVariant(f) local v = f:FindFirstChild("Variant"); return v and tostring(v.Value) or "Normal" end
	local function fruitWeight(f) local w = f:FindFirstChild("Weight"); return w and tonumber(w.Value) or 0 end

	-- mode 1: whitelist fruit type
	local function matchWlFruit(f)
		if not CFG.collectWlFruitEnabled then return false end
		local sel = CFG.collectWlFruitNames or {}
		return sel["All"] == true or sel[f.Name] == true
	end
	-- mode 2: whitelist mutation
	local function matchWlMut(f)
		if not CFG.collectWlMutEnabled then return false end
		local muts = CFG.collectWlMutNames or {}
		if muts["All"] then return true end
		return hasSelMut(f, muts)
	end
	-- mode 3: combined (SEMUA kriteria)
	local function matchCombined(f)
		if not CFG.collectCombEnabled then return false end
		local sel  = CFG.collectCombFruitNames or {}
		local muts = CFG.collectCombMutNames or {}
		local vars = CFG.collectCombVariants or {}
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		if not (next(muts) == nil or muts["All"] or hasSelMut(f, muts)) then return false end
		if not (next(vars) == nil or vars["All"] or vars[fruitVariant(f)]) then return false end
		local thr = tonumber(CFG.collectCombWeight) or 0
		if thr > 0 then
			local w = fruitWeight(f)
			if (CFG.collectCombMode or ">="):find("<=") then if not (w <= thr) then return false end
			else if not (w >= thr) then return false end end
		end
		return true
	end

	local function shouldCollect(f)
		return matchWlFruit(f) or matchWlMut(f) or matchCombined(f)
	end
	local function anyEnabled()
		return CFG.collectWlFruitEnabled or CFG.collectWlMutEnabled or CFG.collectCombEnabled
	end

	----------------------------------------------------------------- loop
	local running = false
	local function collectLoop()
		ctx.state.collectId = (ctx.state.collectId or 0) + 1
		local myId = ctx.state.collectId
		ctx.elevate()
		while anyEnabled() and ctx.alive() and ctx.state.collectId == myId do
			-- backpack full handling
			if backpackFull() then
				if CFG.collectAutoSellIfFull then
					ctx.setStatus("Auto Collect: backpack penuh -> jual (ke Steven)")
					sellAllFruits()
					task.wait(0.5)
				elseif CFG.collectStopIfFull then
					ctx.setStatus("Auto Collect: backpack penuh -> stop")
					task.wait(math.max(1, tonumber(CFG.collectDelay) or 0))
					-- lanjut cek lagi (ga collect)
				end
			end
			if not (backpackFull() and CFG.collectStopIfFull and not CFG.collectAutoSellIfFull) then
				-- kumpulin fruit yg cocok
				local batch = {}
				eachFruit(function(f) if shouldCollect(f) then batch[#batch + 1] = f end end)
				-- fire per-chunk (biar payload ga kegedean)
				local n = 0
				for i = 1, #batch, 40 do
					if not anyEnabled() or ctx.state.collectId ~= myId then break end
					local chunk = {}
					for j = i, math.min(i + 39, #batch) do chunk[#chunk + 1] = batch[j] end
					pcall(function() Collect:FireServer(chunk) end)
					n = n + #chunk
					task.wait(0.1)
					if backpackFull() then break end
				end
				ctx.setStatus(("Auto Collect: collect %d fruit"):format(n))
			end
			task.wait(math.max(0.5, tonumber(CFG.collectDelay) or 0) + 0.5)
		end
		running = false
	end

	-- 1 loop dipakai bareng semua mode; idempotent (semua toggle panggil ini).
	function ctx.startCollect()
		if running then return end
		running = true
		task.spawn(collectLoop)
	end
	function ctx.stopCollect() ctx.state.collectId = (ctx.state.collectId or 0) + 1 end
end
]=],
	["modules/farm/automation_favorite.lua"] = [=[
--[[ automation_favorite.lua — Auto Favorite/Unfavorite fruit.
     Favorite = "lock" buah biar ga kejual/keshovel. Pakai Favorite Tool (equip + guard).
     Remote (dari Favorite Tool script): LockToolRemote:InvokeServer(favTool, fruitModel, state)
       state=true -> favorite, false -> unfavorite. RemoteFunction.
     State fruit: fruit:GetAttribute("Favorited") (boolean). Cuma fruit tag "Harvestable".
     Filter: tipe fruit + mutasi (required) + berat (mode + threshold). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	-- Ambil remote LAZY (jangan WaitForChild di module-load -> bisa nge-block init).
	local function favRemote()
		local GE = RS:FindFirstChild("GameEvents"); if not GE then return nil end
		return GE:FindFirstChild("FavoriteToolRemote") or GE:FindFirstChild("Favorite_Item")
	end
	-- Panggil remote: RemoteFunction -> InvokeServer, RemoteEvent -> FireServer.
	local function doFav(tool, fruit, state)
		local re = favRemote(); if not re then return end
		pcall(function()
			if re:IsA("RemoteFunction") then re:InvokeServer(tool, fruit, state)
			else re:FireServer(tool, fruit, state) end
		end)
	end

	----------------------------------------------------------------- tool equip + guard
	local function findTool()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and tostring(t.Name):find("Favorite") then return t end
			end end
		end
	end
	local function heldTool()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Favorite") then return t end
		end
	end
	local function equipTool()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldTool() then return true end
		local tl = findTool()
		if not tl then return false end
		pcall(function() hum:EquipTool(tl) end)
		task.wait(0.2)
		return heldTool() ~= nil
	end
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while (CFG.favEnabled or CFG.unfavEnabled) and ctx.alive() do
				if not heldTool() then equipTool() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	----------------------------------------------------------------- opsi UI
	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getFavFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getFavMutationOptions()
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (mutasi apapun)")
	end
	function ctx.getFavModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end

	----------------------------------------------------------------- match filter
	local function fruitWeight(f) local w = f:FindFirstChild("Weight"); return w and tonumber(w.Value) or 0 end
	local function fruitMatches(f)
		local sel  = CFG.favFruitNames or {}
		local muts = CFG.favMutNames or {}
		-- tipe (kosong = any)
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		-- mutasi required (kosong = any). Fruit harus punya salah satu mutasi terpilih.
		if not (next(muts) == nil or muts["All"]) then
			local hit = false
			for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then hit = true; break end end
			if not hit then return false end
		end
		-- berat (0 = off)
		local thr = tonumber(CFG.favWeight) or 0
		if thr > 0 then
			local w = fruitWeight(f)
			if (CFG.favMode or ">="):find("<=") then if not (w <= thr) then return false end
			else if not (w >= thr) then return false end end
		end
		return true
	end

	local function eachHarvestable(fn)
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return end
		for _, garden in ipairs(Farm:GetChildren()) do
			if not garden:GetAttribute("CommunityGarden") then
				local imp = garden:FindFirstChild("Important")
				local pp = imp and imp:FindFirstChild("Plants_Physical")
				if pp then for _, plant in ipairs(pp:GetChildren()) do
					local fr = plant:FindFirstChild("Fruits")
					if fr then for _, f in ipairs(fr:GetChildren()) do
						if f:HasTag("Harvestable") then fn(f) end
					end end
				end end
			end
		end
	end

	----------------------------------------------------------------- loop
	local function favLoop()
		ctx.state.favId = (ctx.state.favId or 0) + 1
		local myId = ctx.state.favId
		ctx.elevate()
		while (CFG.favEnabled or CFG.unfavEnabled) and ctx.alive() and ctx.state.favId == myId do
			local tool = heldTool() or findTool()
			if not tool then
				ctx.setStatus("Auto Favorite: Favorite Tool ga ada")
			else
				local n = 0
				eachHarvestable(function(f)
					if not (CFG.favEnabled or CFG.unfavEnabled) or ctx.state.favId ~= myId then return end
					if not fruitMatches(f) then return end
					local isFav = f:GetAttribute("Favorited") == true
					if CFG.favEnabled and not isFav then
						doFav(tool, f, true); n = n + 1; task.wait(0.08)
					elseif CFG.unfavEnabled and isFav then
						doFav(tool, f, false); n = n + 1; task.wait(0.08)
					end
				end)
				ctx.setStatus(("Auto Favorite: proses %d buah"):format(n))
			end
			task.wait(math.max(0.5, tonumber(CFG.favDelay) or 1) + 0.5)
		end
	end

	function ctx.startFavorite()
		equipTool(); ensureGuard()
		task.spawn(favLoop)
	end
	function ctx.stopFavorite() ctx.state.favId = (ctx.state.favId or 0) + 1 end
end
]=],
	["modules/farm/automation_plants.lua"] = [=[
--[[ automation_plants.lua — Auto Plant seed (Farm).
     Tanam seed dari inventory ke farm.
     Remote: Plant_RE:FireServer(Vector3 pos, "SeedName")
     Seed & jumlah dari DataService InventoryData (ItemType="Seed", ItemData.ItemName/Quantity).
     WAJIB megang tool seed-nya pas Plant_RE -> equip ulang tiap mau tanam (kayak reclaimer).
     Posisi: Random (titik acak di Can_Plant) / Player Position (posisi karakter).
     Fungsi: ctx.getPlantSeedOptions / ctx.startPlant. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local Plant_RE = GE:WaitForChild("Plant_RE")
	local DataService = ctx.deps.DataService
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end
	local function important() local f = myFarm(); return f and f:FindFirstChild("Important") end
	local function canPlantParts()
		local imp = important()
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end

	----------------------------------------------------------------- seed inventory
	-- name -> total quantity (dari semua entry Seed di InventoryData)
	local function seedInventory()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok and d and type(d.InventoryData) == "table" then
			for _, v in pairs(d.InventoryData) do
				if type(v) == "table" and v.ItemType == "Seed" and v.ItemData then
					local nm = v.ItemData.ItemName
					local q = tonumber(v.ItemData.Quantity) or 0
					if nm then out[nm] = (out[nm] or 0) + q end
				end
			end
		end
		return out
	end

	-- Opsi dropdown seed: "Nama (jumlah)". Sekalian buang seed yg udah 0 dari selection.
	local function seedOptions()
		local inv = seedInventory()
		local sel = CFG.plantSeedNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if (inv[nm] or 0) <= 0 then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n, q in pairs(inv) do if q > 0 then names[#names + 1] = n end end
		table.sort(names)
		local out = {}
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = ("%s (%d)"):format(n, inv[n]) } end
		return out
	end
	function ctx.getPlantSeedOptions() return seedOptions() end

	----------------------------------------------------------------- posisi
	local function randomPos()
		local parts = canPlantParts()
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		local x = p.Position.X + (math.random() * 2 - 1) * hx
		local z = p.Position.Z + (math.random() * 2 - 1) * hz
		return Vector3.new(x, p.Position.Y, z)
	end
	local function playerPos()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local parts = canPlantParts()
		local y = parts[1] and parts[1].Position.Y or 0
		return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
	end

	----------------------------------------------------------------- equip seed
	-- Tool seed namanya "<Nama> Seed [Xjumlah]". Server WAJIB kamu megang tool-nya
	-- pas Plant_RE, jadi equip ulang tiap mau tanam (walau user pindah manual).
	local function seedBase(t)
		return t:IsA("Tool") and t.Name:match("^(.-) Seed %[X%d+%]") or nil
	end
	local function holdingSeed(name)
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do if seedBase(t) == name then return true end end end
		return false
	end
	local function equipSeed(name)
		if holdingSeed(name) then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if seedBase(t) == name then tool = t; break end end end
		if tool then
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return holdingSeed(name)
	end

	----------------------------------------------------------------- loop tanam
	local function plantLoop(myId)
		ctx.elevate()
		while CFG.plantSeedEnabled and ctx.alive() and ctx.state.plantId == myId do
			local sel = CFG.plantSeedNames or {}
			if next(sel) then
				local inv = seedInventory()
				local mode = CFG.plantPosition == "Player Position" and "Player Position" or "Random"
				-- Kecepatan sepenuhnya ikut Delay input (0 = secepat mungkin).
				local planted, anySeed = 0, false
				for name in pairs(sel) do
					local qty = inv[name] or 0
					if qty > 0 then
						anySeed = true
						for _ = 1, qty do
							if not CFG.plantSeedEnabled or ctx.state.plantId ~= myId then break end
							if equipSeed(name) then -- equip seed tiap mau tanam
								local pos = (mode == "Player Position") and playerPos() or randomPos()
								if pos then
									pcall(function() Plant_RE:FireServer(pos, name) end)
									planted = planted + 1
								end
							end
							task.wait(tonumber(CFG.plantDelay) or 0)
						end
					end
				end
				if not anySeed then setStatus("Plants: seed terpilih habis")
				else setStatus(("Plants: tanam %d (%s)"):format(planted, mode)) end
			else
				setStatus("Plants: pilih seed dulu")
			end
			task.wait(1)
		end
	end

	function ctx.startPlant()
		ctx.state.plantId = (ctx.state.plantId or 0) + 1
		local myId = ctx.state.plantId
		task.spawn(function() plantLoop(myId) end)
	end
end
]=],
	["modules/farm/automation_reclaimer.lua"] = [=[
--[[ automation_reclaimer.lua — Auto Reclaimer plant (Farm).
     Reclaim plant yg ditanam di garden pakai tool Reclaimer.
     Remote: ReclaimerService_RE:FireServer("TryReclaim", plantModel)
       plantModel = Model di Farm.Important.Plants_Physical (mis. "Blueberry").
     Dropdown "Select Plants": jenis plant unik yg ada di garden (+ "All").
     Butuh tool Reclaimer (auto-equip di loop). Tiap reclaim makan 1 charge Reclaimer.
     Fungsi: ctx.getReclaimPlantOptions / ctx.startReclaim. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local ReclaimRE = GE:WaitForChild("ReclaimerService_RE")
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end

	local function plantsFolder()
		local f = myFarm()
		local imp = f and f:FindFirstChild("Important")
		return imp and imp:FindFirstChild("Plants_Physical")
	end

	-- Jenis plant unik yg lagi ada di garden.
	local function existingTypes()
		local seen = {}
		local pf = plantsFolder()
		if pf then for _, m in ipairs(pf:GetChildren()) do if m.Name then seen[m.Name] = true end end end
		return seen
	end

	-- Buang plant terpilih yg udah ga ada di garden (kecuali "All"),
	-- biar ga kepilih tapi tanamannya udah abis.
	local function pruneSelection(existing)
		local sel = CFG.reclaimPlantNames
		if type(sel) ~= "table" then return end
		local changed = false
		for name in pairs(sel) do
			if name ~= "All" and not existing[name] then sel[name] = nil; changed = true end
		end
		if changed and ctx.persistState then pcall(ctx.persistState) end
	end

	-- Opsi dropdown: "All" + jenis plant yg lagi ada. Sekalian prune selection stale.
	local function plantOptions()
		local existing = existingTypes()
		pruneSelection(existing)
		local out = { { value = "All", display = "All (semua plant)" } }
		local names = {}
		for n in pairs(existing) do names[#names + 1] = n end
		table.sort(names)
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	function ctx.getReclaimPlantOptions() return plantOptions() end

	-- Nama tool di inventory ada suffix jumlah (mis. "Reclaimer x50634"),
	-- jadi cocokin per-prefix, bukan exact.
	local function isReclaimer(t)
		return t:IsA("Tool") and t.Name:match("^Reclaimer") ~= nil
	end
	local function heldReclaimer()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do if isReclaimer(t) then return t end end
		return nil
	end

	-- Equip tool Reclaimer dari Backpack kalau belum kepegang.
	local function equipReclaimer()
		local char = LP.Character
		if not char then return false end
		if heldReclaimer() then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if isReclaimer(t) then tool = t; break end end end
		if tool then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return heldReclaimer() ~= nil
	end

	----------------------------------------------------------------- loop reclaim
	local POLL = 1
	local function reclaimLoop(myId)
		ctx.elevate()
		while CFG.reclaimEnabled and ctx.alive() and ctx.state.reclaimId == myId do
			local pf = plantsFolder()
			local sel = CFG.reclaimPlantNames or {}
			local all = sel["All"]
			if pf and (all or next(sel)) then
				local hasTool = equipReclaimer()
				if not hasTool then
					setStatus("Reclaimer: tool 'Reclaimer' ga ada di inventory")
				else
					local n = 0
					for _, m in ipairs(pf:GetChildren()) do
						if not CFG.reclaimEnabled or ctx.state.reclaimId ~= myId then break end
						if all or sel[m.Name] then
							pcall(function() ReclaimRE:FireServer("TryReclaim", m) end)
							n = n + 1
							task.wait(CFG.reclaimSpeed or 0.15)
						end
					end
					setStatus(("Reclaimer: proses %d plant"):format(n))
				end
			else
				setStatus("Reclaimer: pilih plant dulu")
			end
			task.wait(POLL)
		end
	end

	-- Guard: selama enable, tool Reclaimer WAJIB tetap kepegang. Kalau user pindah
	-- manual ke pet/tool lain, langsung equip ulang Reclaimer (cek cepat 0.25s).
	local function keepEquipped(myId)
		while CFG.reclaimEnabled and ctx.alive() and ctx.state.reclaimId == myId do
			if not heldReclaimer() then equipReclaimer() end
			task.wait(0.25)
		end
	end

	function ctx.startReclaim()
		ctx.state.reclaimId = (ctx.state.reclaimId or 0) + 1
		local myId = ctx.state.reclaimId
		equipReclaimer() -- equip langsung pas enable
		task.spawn(function() reclaimLoop(myId) end)
		task.spawn(function() keepEquipped(myId) end)
	end
end
]=],
	["modules/farm/automation_shovel.lua"] = [=[
--[[ automation_shovel.lua — Auto Shovel (2 mode):
       1) Shovel Tree/Plant  : hapus plant dari tipe terpilih (CFG.shovelTreeNames).
       2) Shovel Fruit        : hapus plant kalau punya FRUIT yang cocok filter
                                (tipe + mutasi + variant + berat vs threshold).
     Mekanisme (dari remote spy + tes live): Remove_Item:FireServer(plant.PrimaryPart)
     — hapus SELURUH plant. Ga perlu equip Shovel (server terima langsung).
     Plant ada di workspace.Farm.<garden>.Important.Plants_Physical (nama = tipe).
     Tiap plant.Fruits berisi fruit models: child Weight (NumberValue), Variant (StringValue),
     + attribute mutasi boolean (Wet/Twisted/dll). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Remove = RS:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

	-- cari + equip Shovel dulu (server nolak kalau ga pegang shovel)
	local function findShovel()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					if t:IsA("Tool") and tostring(t.Name):find("Shovel") then return t end
				end
			end
		end
	end
	local function heldShovel()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Shovel") then return t end
		end
	end
	local function equipShovel()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldShovel() then return true end
		local sh = findShovel()
		if not sh then return false end
		pcall(function() hum:EquipTool(sh) end)
		task.wait(0.2)
		return heldShovel() ~= nil
	end

	-- Guard (mirip reclaimer): selama shovel aktif, Shovel WAJIB tetap kepegang.
	-- Kalau user pindah manual ke tool lain, langsung equip ulang (cek 0.25s).
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while (CFG.shovelTreeEnabled or CFG.shovelFruitEnabled) and ctx.alive() do
				if not heldShovel() then equipShovel() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	-- attribute fruit yang BUKAN mutasi (metadata) — dibuang pas listing opsi mutasi
	local NOT_MUTATION = {
		FruitVersion = true, MaxAge = true, GrowRateMulti = true, WeightMulti = true,
		DoneGrowTime = true, FruitSpawnIndex = true, OfflineGrowthTarget = true,
		MasteryGrowthMulti = true, MasterySizeMulti = true,
	}

	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	-- iterasi plant di garden SENDIRI
	local function eachPlant(fn)
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return end
		for _, garden in ipairs(Farm:GetChildren()) do
			if not garden:GetAttribute("CommunityGarden") then
				local imp = garden:FindFirstChild("Important")
				local pp = imp and imp:FindFirstChild("Plants_Physical")
				if pp then for _, plant in ipairs(pp:GetChildren()) do fn(plant) end end
			end
		end
	end

	-- shovel SELURUH plant (Remove_Item di part plant)
	local function shovel(plant)
		local part = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
		if part then pcall(function() Remove:FireServer(part) end) end
	end
	-- shovel 1 BUAH aja (Remove_Item di part buah -> plant tetap)
	local function shovelFruit(fruit)
		local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
		if part then pcall(function() Remove:FireServer(part) end) end
	end

	----------------------------------------------------------------- opsi (buat UI)
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getShovelTreeOptions()  return optionsFrom(catalog(), "All (semua plant)") end
	function ctx.getShovelFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getShovelVariantOptions()
		-- kumpulin variant yg ADA di garden + base
		local set = { Normal = true, Gold = true, Rainbow = true }
		eachPlant(function(plant)
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do
				local v = f:FindFirstChild("Variant"); if v and v.Value ~= "" then set[tostring(v.Value)] = true end
			end end
		end)
		local names = {} for k in pairs(set) do names[#names + 1] = k end; table.sort(names)
		return optionsFrom(names, "All (semua variant)")
	end
	function ctx.getShovelMutationOptions()
		-- daftar LENGKAP semua mutasi buah dari registry (MutationHandler.MutationNames)
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (semua mutasi)")
	end
	function ctx.getShovelModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end

	----------------------------------------------------------------- cek fruit cocok filter
	local function fruitMatches(f)
		local sel  = CFG.shovelFruitNames or {}
		local muts = CFG.shovelFruitMuts or {}
		local vars = CFG.shovelFruitVariants or {}
		-- tipe
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		-- variant
		if not (next(vars) == nil or vars["All"]) then
			local fv = f:FindFirstChild("Variant")
			local vn = fv and tostring(fv.Value) or "Normal"
			if not vars[vn] then return false end
		end
		-- mutasi (fruit harus punya salah satu mutasi terpilih)
		if not (next(muts) == nil or muts["All"]) then
			local hit = false
			for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then hit = true; break end end
			if not hit then return false end
		end
		-- berat vs threshold
		local thr = tonumber(CFG.shovelFruitWeight) or 0
		if thr > 0 then
			local w = f:FindFirstChild("Weight")
			local wv = w and tonumber(w.Value) or 0
			local mode = CFG.shovelFruitMode or ">="
			if mode:find("<=") then if not (wv <= thr) then return false end
			else if not (wv >= thr) then return false end end
		end
		return true
	end

	----------------------------------------------------------------- loop: shovel tree/plant
	local function treeLoop()
		ctx.state.shovelTreeId = (ctx.state.shovelTreeId or 0) + 1
		local myId = ctx.state.shovelTreeId
		ctx.elevate()
		while CFG.shovelTreeEnabled and ctx.alive() and ctx.state.shovelTreeId == myId do
			if not equipShovel() then
				ctx.setStatus("Auto Shovel Tree: Shovel ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.shovelTreeDelay) or 0))
			else
				local sel = CFG.shovelTreeNames or {}
				local all = sel["All"]
				local n = 0
				eachPlant(function(plant)
					if not CFG.shovelTreeEnabled or ctx.state.shovelTreeId ~= myId then return end
					if all or sel[plant.Name] then
						shovel(plant); n = n + 1; task.wait(0.12)
					end
				end)
				ctx.setStatus(("Auto Shovel Tree: cabut %d plant"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.shovelTreeDelay) or 0) + 0.5)
			end
		end
	end

	----------------------------------------------------------------- loop: shovel fruit
	local function fruitLoop()
		ctx.state.shovelFruitId = (ctx.state.shovelFruitId or 0) + 1
		local myId = ctx.state.shovelFruitId
		ctx.elevate()
		while CFG.shovelFruitEnabled and ctx.alive() and ctx.state.shovelFruitId == myId do
			if not equipShovel() then
				ctx.setStatus("Auto Shovel Fruit: Shovel ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.shovelFruitDelay) or 0))
			else
				local n = 0
				eachPlant(function(plant)
					if not CFG.shovelFruitEnabled or ctx.state.shovelFruitId ~= myId then return end
					local fr = plant:FindFirstChild("Fruits")
					if not fr then return end
					-- hapus TIAP buah yg cocok filter (plant tetap ada)
					for _, f in ipairs(fr:GetChildren()) do
						if not CFG.shovelFruitEnabled or ctx.state.shovelFruitId ~= myId then break end
						if fruitMatches(f) then shovelFruit(f); n = n + 1; task.wait(0.12) end
					end
				end)
				ctx.setStatus(("Auto Shovel Fruit: cabut %d buah"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.shovelFruitDelay) or 0) + 0.5)
			end
		end
	end

	function ctx.startShovelTree()  equipShovel(); ensureGuard(); task.spawn(treeLoop) end
	function ctx.stopShovelTree()   ctx.state.shovelTreeId = (ctx.state.shovelTreeId or 0) + 1 end
	function ctx.startShovelFruit() equipShovel(); ensureGuard(); task.spawn(fruitLoop) end
	function ctx.stopShovelFruit()  ctx.state.shovelFruitId = (ctx.state.shovelFruitId or 0) + 1 end
end
]=],
	["modules/farm/automation_sprinkler.lua"] = [=[
--[[ automation_sprinkler.lua — Auto Sprinkler + Sprinkler Shovel (Farm).
     Pasang sprinkler:  equip tool sprinkler -> SprinklerService:FireServer("Create", CFrame)
     Cabut sprinkler:   equip Shovel        -> DeleteObject:FireServer(sprinklerModel)
     Sprinkler & jumlah dari Backpack tool "<Nama> Sprinkler x<jumlah>".
     Posisi pasang: kalau "Sprinkler Plants" dipilih -> di posisi plant itu;
                    kalau kosong -> Position mode (Random / Player Position).
     Fungsi: ctx.getSprinklerOptions / ctx.getSprinklerPlantOptions /
             ctx.getShovelSprinklerOptions / ctx.startSprinkler / ctx.startShovelSprinkler ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local SprinklerService = GE:WaitForChild("SprinklerService")
	local DeleteObject     = GE:WaitForChild("DeleteObject")
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 then return f end end
		return nil
	end
	local function important() local f = myFarm(); return f and f:FindFirstChild("Important") end
	local function plantsFolder() local imp = important(); return imp and imp:FindFirstChild("Plants_Physical") end
	local function objectsFolder() local imp = important(); return imp and imp:FindFirstChild("Objects_Physical") end
	local function canPlantParts()
		local imp = important(); local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end

	----------------------------------------------------------------- inventory sprinkler
	local function sprinklerBase(t) return t:IsA("Tool") and t.Name:match("^(.- Sprinkler) x%d+") or nil end
	-- name -> jumlah (dari Backpack + Character)
	local function sprinklerInventory()
		local out = {}
		for _, where in ipairs({ LP:FindFirstChild("Backpack"), LP.Character }) do
			if where then for _, t in ipairs(where:GetChildren()) do
				local b = sprinklerBase(t)
				if b then out[b] = (out[b] or 0) + (tonumber(t.Name:match("x(%d+)$")) or 0) end
			end end
		end
		return out
	end
	local function sprinklerOptions()
		local inv = sprinklerInventory()
		-- prune sprinkler terpilih yg stok-nya udah 0
		local sel = CFG.sprinklerNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if (inv[nm] or 0) <= 0 then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n, q in pairs(inv) do if q > 0 then names[#names + 1] = n end end
		table.sort(names)
		local out = {}
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = ("%s (%d)"):format(n, inv[n]) } end
		return out
	end
	ctx.getSprinklerOptions = sprinklerOptions

	-- jenis plant unik di garden (buat "place near plants") + "All"
	function ctx.getSprinklerPlantOptions()
		local out = { { value = "All", display = "All (semua plant)" } }
		local pf = plantsFolder()
		if pf then
			local seen, names = {}, {}
			for _, m in ipairs(pf:GetChildren()) do if m.Name and not seen[m.Name] then seen[m.Name] = true; names[#names + 1] = m.Name end end
			table.sort(names)
			for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		end
		return out
	end

	-- Opsi shovel: gabungan jenis sprinkler yg kamu punya (inventory) + yg lagi
	-- terpasang, + "All". Daftar dari inventory bikin stabil (ga ilang pas objek
	-- expire). Sekalian prune pilihan yg jenisnya udah ga ada sama sekali.
	function ctx.getShovelSprinklerOptions()
		local set = {}
		for n in pairs(sprinklerInventory()) do set[n] = true end
		local of = objectsFolder()
		if of then for _, o in ipairs(of:GetChildren()) do
			local ty = o:GetAttribute("OBJECT_TYPE") or o.Name
			if ty then set[ty] = true end
		end end
		local sel = CFG.shovelSprinklerNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if nm ~= "All" and not set[nm] then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n in pairs(set) do names[#names + 1] = n end
		table.sort(names)
		local out = { { value = "All", display = "All (semua terpasang)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	----------------------------------------------------------------- equip helper
	local function heldName() local c = LP.Character; local t = c and c:FindFirstChildOfClass("Tool"); return t and t.Name end
	local function equipByPredicate(pred)
		local c = LP.Character
		if c then for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and pred(t) then return true end end end
		local bp = LP:FindFirstChild("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and pred(t) then
			local hum = c and c:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:EquipTool(t) end) end
			break
		end end end
		if c then for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and pred(t) then return true end end end
		return false
	end
	local function equipSprinkler(name) return equipByPredicate(function(t) return sprinklerBase(t) == name end) end
	local function equipShovel() return equipByPredicate(function(t) return t.Name == "Shovel [Destroy Plants]" or t.Name:match("^Shovel") end) end

	----------------------------------------------------------------- posisi
	local function randomPos()
		local parts = canPlantParts(); if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		return Vector3.new(p.Position.X + (math.random() * 2 - 1) * hx, p.Position.Y, p.Position.Z + (math.random() * 2 - 1) * hz)
	end
	local function playerPos()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
		local parts = canPlantParts(); local y = parts[1] and parts[1].Position.Y or 0
		return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
	end
	-- posisi plant yg tipenya dipilih (buat "place near plants")
	local function plantPositions(sel)
		local out = {}
		local pf = plantsFolder(); if not pf then return out end
		local all = sel["All"]
		for _, m in ipairs(pf:GetChildren()) do
			if all or sel[m.Name] then
				local piv = m:GetPivot(); out[#out + 1] = Vector3.new(piv.X, piv.Y, piv.Z)
			end
		end
		return out
	end

	----------------------------------------------------------------- loop PASANG
	local function sprinklerLoop(myId)
		ctx.elevate()
		while CFG.sprinklerEnabled and ctx.alive() and ctx.state.sprinklerId == myId do
			local selSpr = CFG.sprinklerNames or {}
			local inv = sprinklerInventory()
			-- daftar tipe sprinkler terpilih yg masih ada stok (urut stabil)
			local types = {}
			for n in pairs(selSpr) do if (inv[n] or 0) > 0 then types[#types + 1] = n end end
			table.sort(types)
			if #types == 0 then
				setStatus("Sprinkler: pilih sprinkler (stok kosong?)")
			else
				-- posisi target
				local plantsSel = CFG.sprinklerPlantNames or {}
				local positions
				if next(plantsSel) then
					positions = plantPositions(plantsSel)
				else
					local mode = CFG.sprinklerPosition == "Player Position" and "Player Position" or "Random"
					positions = { mode == "Player Position" and playerPos() or randomPos() }
				end
				local placed = 0
				for _, pos in ipairs(positions) do
					if not CFG.sprinklerEnabled or ctx.state.sprinklerId ~= myId then break end
					if pos then
						-- rotasi 1-1 antar tipe, indeks persist antar-siklus (biar ga tipe pertama terus)
						ctx.state.sprRotIdx = (ctx.state.sprRotIdx or 0) % #types + 1
						local name = types[ctx.state.sprRotIdx]
						if equipSprinkler(name) then
							pcall(function() SprinklerService:FireServer("Create", CFrame.new(pos)) end)
							placed = placed + 1
							task.wait(tonumber(CFG.sprinklerDelay) or 0)
						end
					end
				end
				setStatus(("Sprinkler: pasang %d"):format(placed))
			end
			task.wait(1)
		end
	end
	function ctx.startSprinkler()
		ctx.state.sprinklerId = (ctx.state.sprinklerId or 0) + 1
		local myId = ctx.state.sprinklerId
		task.spawn(function() sprinklerLoop(myId) end)
	end

	----------------------------------------------------------------- loop CABUT (shovel)
	local function shovelLoop(myId)
		ctx.elevate()
		while CFG.shovelSprinklerEnabled and ctx.alive() and ctx.state.shovelSprId == myId do
			local sel = CFG.shovelSprinklerNames or {}
			local of = objectsFolder()
			if of and next(sel) then
				local all = sel["All"]
				equipShovel()
				local removed = 0
				for _, o in ipairs(of:GetChildren()) do
					if not CFG.shovelSprinklerEnabled or ctx.state.shovelSprId ~= myId then break end
					local ty = o:GetAttribute("OBJECT_TYPE") or o.Name
					if all or sel[ty] then
						pcall(function() DeleteObject:FireServer(o) end)
						removed = removed + 1
						task.wait(tonumber(CFG.shovelSprinklerDelay) or 0)
					end
				end
				setStatus(("Shovel Sprinkler: cabut %d"):format(removed))
			else
				setStatus("Shovel Sprinkler: pilih sprinkler dulu")
			end
			task.wait(1)
		end
	end
	function ctx.startShovelSprinkler()
		ctx.state.shovelSprId = (ctx.state.shovelSprId or 0) + 1
		local myId = ctx.state.shovelSprId
		task.spawn(function() shovelLoop(myId) end)
	end
end
]=],
	["modules/farm/automation_water.lua"] = [=[
--[[ automation_water.lua — Auto Water Fruits.
     Siram plant terpilih pakai Watering Can. Mekanisme (dari remote spy):
       Water_RE:FireServer(plant:GetPivot().Position)
     Ga perlu equip can — server auto-decrement uses dari Watering Can di inventory.
     Loop tiap CFG.waterDelay detik, cuma siram plant yang tipenya ada di CFG.waterFruitNames
     (atau "All"). Plant ada di workspace.Farm.<garden>.Important.Plants_Physical (nama = tipe fruit). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Water = RS:WaitForChild("GameEvents"):WaitForChild("Water_RE")

	-- cari Watering Can (prioritas regular = uses banyak; fallback Super/Sugar/apapun)
	local function findCan()
		local best, fallback
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					local n = tostring(t.Name)
					if t:IsA("Tool") and n:find("Watering Can") then
						if not n:find("Super") and not n:find("Sugar") then best = best or t
						else fallback = fallback or t end
					end
				end
			end
		end
		return best or fallback
	end

	local function heldCan()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Watering Can") then return t end
		end
	end
	-- pastiin Watering Can ke-equip (server nyiram cuma pas can dipegang)
	local function equipCan()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldCan() then return true end
		local can = findCan()
		if not can then return false end
		pcall(function() hum:EquipTool(can) end)
		task.wait(0.2)
		return heldCan() ~= nil
	end

	-- Guard (mirip reclaimer): selama auto water aktif, Watering Can WAJIB tetap kepegang.
	-- Kalau user pindah manual ke tool lain, langsung equip ulang (cek 0.25s).
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while CFG.waterEnabled and ctx.alive() do
				if not heldCan() then equipCan() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	-- opsi fruit = katalog seed (semua yang bisa ditanam). Format sama kayak shop.
	local function optionsFrom(names)
		local out = { { value = "All", display = "All (siram semua)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	function ctx.getWaterFruitOptions()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do
				local n = tostring(k)
				if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end
			end
			table.sort(names)
		end
		return optionsFrom(names)
	end

	-- iterasi plant di garden SENDIRI (skip community garden)
	local function eachPlant(fn)
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return end
		for _, garden in ipairs(Farm:GetChildren()) do
			if not garden:GetAttribute("CommunityGarden") then
				local imp = garden:FindFirstChild("Important")
				local pp = imp and imp:FindFirstChild("Plants_Physical")
				if pp then for _, plant in ipairs(pp:GetChildren()) do fn(plant) end end
			end
		end
	end

	local function waterLoop()
		ctx.state.waterId = (ctx.state.waterId or 0) + 1
		local myId = ctx.state.waterId
		ctx.elevate()
		while CFG.waterEnabled and ctx.alive() and ctx.state.waterId == myId do
			local sel = CFG.waterFruitNames or {}
			local all = sel["All"]
			local n = 0
			-- equip can dulu; kalau ga ada, kasih tau & tunggu
			if not equipCan() then
				ctx.setStatus("Auto Water: Watering Can ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.waterDelay) or 1))
			else
			eachPlant(function(plant)
				if not CFG.waterEnabled or ctx.state.waterId ~= myId then return end
				if all or sel[plant.Name] then
					local ok, pos = pcall(function() return plant:GetPivot().Position end)
					if ok and pos then
						pcall(function() Water:FireServer(pos) end)
						n = n + 1
						task.wait(0.05) -- jeda antar-fire biar ga flood remote
					end
				end
			end)
				ctx.setStatus(("Auto Water: siram %d plant"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.waterDelay) or 1))
			end
		end
	end

	function ctx.startWater() equipCan(); ensureGuard(); task.spawn(waterLoop) end
	function ctx.stopWater() ctx.state.waterId = (ctx.state.waterId or 0) + 1 end
end
]=],
	["modules/growth/automation_growth.lua"] = [=[
--[[ growth.lua — Growth pipeline (BATCH per-step): jalankan target pet lewat urutan
     step (default Elephant -> Mutation -> Leveling), semua pet kelar 1 step baru lanjut.
     Config TERPISAH dari fitur standalone (growth*).
     Step & kriteria "complete":
       elephant : BaseWeight >= growthElephantWeight
       mutation : dapat salah satu growthMutationTargets (aura team; mutasi salah -> shard)
       leveling : Level >= growthLevP2Target (2 phase: P1 team -> P2 team)
     Saat ganti step/phase: bersihin garden TOTAL dulu -> pasang team baru (lengkap) -> proses. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")
	local PetShardService = RS:WaitForChild("GameEvents"):WaitForChild("PetShardService_RE")
	local mutDisplay = (ctx.reg and ctx.reg.mutDisplay) or function(c) return c end

	----------------------------------------------------------------- posisi grid
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
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter(); if not center then return nil end
		local i = slotOf[uuid]
		return center + Vector3.new((i % 6 - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	----------------------------------------------------------------- helper mutasi/shard
	-- pet yang di-favorite JANGAN diproses & JANGAN dihitung di step manapun
	-- (elephant/mutation/leveling). Kalau ikut dihitung, pet fav yg ga pernah beres
	-- bikin step "belum semua selesai" selamanya -> growth mandek.
	local function isFav(pd) return (pd or {}).IsFavorite == true end
	-- Flow efektif: buang step kosong/"none" (mis. cuma mau Mutation+Leveling, Step 3 dikosongin).
	local function effFlow()
		local out = {}
		for _, s in ipairs(CFG.growthFlow or {}) do
			if s == "elephant" or s == "mutation" or s == "leveling" then out[#out + 1] = s end
		end
		return out
	end
	local function mutOf(pd) return mutDisplay((pd or {}).MutationType) end
	local function hasMut(pd)
		local m = (pd or {}).MutationType
		return m ~= nil and m ~= "" and m ~= "None" and m ~= "Normal"
	end
	local function findShard()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					if t:IsA("Tool") and (t:HasTag("PetShardTool") or tostring(t.Name):find("Cleansing Pet Shard")) then return t end
				end
			end
		end
	end
	local function findPetModel(uuid)
		local pm = workspace:FindFirstChild("PetsPhysical")
		if not pm then return nil end
		for _, mover in ipairs(pm:GetChildren()) do
			local m = mover:FindFirstChild(uuid); if m then return m end
		end
	end
	local function cleansePet(uuid)
		local model = findPetModel(uuid); if not model then return end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		local shard = findShard()
		if hum and shard then pcall(function() hum:EquipTool(shard) end); task.wait(0.3) end
		local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
		if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then
			pcall(function() PetShardService:FireServer("ApplyShard", model) end)
			task.wait(0.3)
		end
	end

	----------------------------------------------------------------- kriteria complete per step
	local function stepDone(step, pd)
		pd = pd or {}
		if step == "elephant" then
			return (pd.BaseWeight or 0) >= (CFG.growthElephantWeight or 5.5)
		elseif step == "mutation" then
			local tg = CFG.growthMutationTargets or {}
			if not next(tg) then return true end
			return tg[mutOf(pd)] == true
		elseif step == "leveling" then
			return (pd.Level or 0) >= (CFG.growthLevP2Target or 500)
		end
		return true
	end

	ctx.state.growthStatus = "Idle"

	----------------------------------------------------------------- ringkasan status
	function ctx.getGrowthSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local types = CFG.growthPetTypes or {}
		local flow = effFlow()
		local perStep = {}
		for _, s in ipairs(flow) do perStep[s] = { done = 0, total = 0 } end
		for _, v in pairs(inv) do
			if types[v.PetType] and not isFav(v.PetData) then
				for _, s in ipairs(flow) do
					perStep[s].total = perStep[s].total + 1
					if stepDone(s, v.PetData) then perStep[s].done = perStep[s].done + 1 end
				end
			end
		end
		local function nm(t) local o = {}; for k in pairs(t or {}) do o[#o + 1] = k end; return #o > 0 and table.concat(o, ", ") or "-" end
		-- ringkas team: hitung per tipe pet -> "Peacock x3, Dog x2" (biar ga kepanjangan)
		local function teamNm(teamSet)
			local count, order, total = {}, {}, 0
			for uuid in pairs(teamSet or {}) do
				local v = inv[uuid]
				local pt = (v and v.PetType) or "?"
				if not count[pt] then order[#order + 1] = pt end
				count[pt] = (count[pt] or 0) + 1
				total = total + 1
			end
			if total == 0 then return "-" end
			local parts = {}
			for _, pt in ipairs(order) do
				parts[#parts + 1] = count[pt] > 1 and (pt .. " x" .. count[pt]) or pt
			end
			return ("(%d) %s"):format(total, table.concat(parts, ", "))
		end
		return {
			status = CFG.growthEnabled and "ACTIVE" or "STOPPED",
			step = ctx.state.growthStep or "-",
			flow = (#flow > 0) and table.concat(flow, " -> ") or "-",
			types = nm(types),
			perStep = perStep,
			teamElephant = teamNm(CFG.growthElephantTeam),
			teamMutation = teamNm(CFG.growthMutationTeam),
			teamLevP1 = teamNm(CFG.growthLevP1Team),
			teamLevP2 = teamNm(CFG.growthLevP2Team),
		}
	end

	----------------------------------------------------------------- core check
	local function checkGrowth()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return end
		local eq  = d.PetsData.EquippedPets or {}
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local types = CFG.growthPetTypes or {}
		local flow = effFlow()
		if not next(types) or #flow == 0 then
			ctx.state.growthStatus = "Growth: set target pet & flow dulu"
			return
		end

		-- STEP AKTIF = step pertama di flow yg belum semua target pet complete.
		local step, stepIdx
		for i, s in ipairs(flow) do
			local allDone = true
			for _, v in pairs(inv) do
				if types[v.PetType] and not isFav(v.PetData) and not stepDone(s, v.PetData) then allDone = false; break end
			end
			if not allDone then step, stepIdx = s, i; break end
		end
		if not step then
			ctx.state.growthStep = "SELESAI"
			ctx.state.growthStatus = "Growth: semua step selesai ✓"
			if ctx.state.growthClearKey ~= "__done" then ctx.state.growthClearKey = "__done"; if ctx.clearGarden then ctx.clearGarden("Growth") end end
			return
		end

		-- team / max / kriteria "masih perlu diproses" untuk step ini (leveling: sub-phase)
		local team, maxPets, needsWork
		local stepLabel = ("Step %d: %s"):format(stepIdx, step)
		if step == "elephant" then
			team, maxPets = CFG.growthElephantTeam or {}, CFG.growthElephantMax or 2
			needsWork = function(pd) return not stepDone("elephant", pd) end
		elseif step == "mutation" then
			team, maxPets = CFG.growthMutationTeam or {}, CFG.growthMutationMax or 2
			needsWork = function(pd) return not stepDone("mutation", pd) end
		else -- leveling
			local p1t = CFG.growthLevP1Target or 40
			local phase1 = false
			for _, v in pairs(inv) do
				if types[v.PetType] and not isFav(v.PetData) and not stepDone("leveling", v.PetData) and ((v.PetData or {}).Level or 0) < p1t then phase1 = true; break end
			end
			if phase1 then
				team, maxPets = CFG.growthLevP1Team or {}, CFG.growthLevP1Max or 3
				stepLabel = stepLabel .. " (Phase 1)"
				needsWork = function(pd) return (pd.Level or 0) < p1t end
			else
				team, maxPets = CFG.growthLevP2Team or {}, CFG.growthLevP2Max or 1
				stepLabel = stepLabel .. " (Phase 2)"
				needsWork = function(pd) return not stepDone("leveling", pd) end
			end
		end
		ctx.state.growthStep = stepLabel

		-- Kirim webhook "enabled" SEKALI pas MASUK step baru (mis. enable -> elephant duluan).
		if ctx.state.growthLastStepName ~= step then
			ctx.state.growthLastStepName = step
			if step == "elephant" and ctx.webhookElephant and ctx.webhookElephant.sendEnabled then
				pcall(function() ctx.webhookElephant.sendEnabled(ctx) end)
			end
			-- leveling: TIDAK kirim webhook "enabled" pas masuk step; cuma pas pet beres (sendFinished).
			-- mutation (aura/cleanse) ga punya sendEnabled -> notif cuma per pet dapat mutasi
		end

		local localEq = {}
		for _, uuid in ipairs(eq) do localEq[uuid] = true end

		-- Transisi step/phase -> bersihin garden TOTAL dulu (verified kosong).
		if ctx.state.growthClearKey ~= nil and ctx.state.growthClearKey ~= stepLabel then
			ctx.state.growthClearing = true
		end
		ctx.state.growthClearKey = stepLabel
		if ctx.state.growthFirstRun or ctx.state.growthClearing then
			if #eq > 0 then
				ctx.state.growthStatus = ("%s: bersihin garden (%d pet)..."):format(stepLabel, #eq)
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.1)
				end
				return
			end
			ctx.state.growthFirstRun = false
			ctx.state.growthClearing = false
		end

		-- Pasang team step ini + PASTIKAN LENGKAP dulu.
		local teamComplete = true
		for uuid in pairs(team) do
			if not localEq[uuid] then
				teamComplete = false
				local pos = getPos(uuid)
				if pos then pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end); task.wait(0.15) end
			end
		end
		if not teamComplete then
			ctx.state.growthStatus = stepLabel .. ": nunggu team lengkap..."
			return
		end

		-- Klasifikasi target pet equipped: kalau ga perlu kerja lagi -> lepas.
		-- Khusus mutation: mutasi SALAH (bukan target) -> cleanse (shard) biar coba lagi.
		local active = {}
		for uuid in pairs(localEq) do
			if not team[uuid] then
				local v = inv[uuid]
				if v and types[v.PetType] then
					local pd = v.PetData or {}
					if pd.IsFavorite then
						-- Favorite -> JANGAN cleanse, JANGAN biarin di garden. Keluarkan.
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.1)
					elseif needsWork(pd) then
						if step == "mutation" and hasMut(pd) and not (CFG.growthMutationTargets or {})[mutOf(pd)] then
							cleansePet(uuid) -- mutasi salah -> cleanse
						end
						table.insert(active, uuid)
						if step == "elephant" then
							ctx.state.growthElephantStart = ctx.state.growthElephantStart or {}
							if not ctx.state.growthElephantStart[uuid] then
								ctx.state.growthElephantStart[uuid] = os.time()
							end
						end
					else
						-- pet SELESAI step ini -> kirim webhook (template per-step)
						local pt = v.PetType
						if step == "elephant" and ctx.webhookElephant and ctx.webhookElephant.onFinished then
							-- Durasi: dari pet masuk garden (equip) sampai lepas; nil kalau ga kecatat
							local dur
							if ctx.state.growthElephantStart and ctx.state.growthElephantStart[uuid] then
								dur = os.time() - ctx.state.growthElephantStart[uuid]
								ctx.state.growthElephantStart[uuid] = nil
							end
							pcall(function() ctx.webhookElephant.onFinished(ctx, pt, pd.BaseWeight or 0) end)
							if ctx.webhookElephant.sendFinished then
								pcall(function() ctx.webhookElephant.sendFinished(ctx, pt, pd.BaseWeight or 0, pd.MutationType, pd.Level or 0, dur) end)
							end
						elseif step == "mutation" and ctx.webhookCleanse and ctx.webhookCleanse.sendObtained then
							-- aura/cleanse webhook (bukan mutasi mesin)
							local remainsM = 0
							for _, iv in pairs(inv) do
								if types[iv.PetType] and not isFav(iv.PetData) and not stepDone("mutation", iv.PetData) then remainsM = remainsM + 1 end
							end
							pcall(function() ctx.webhookCleanse.sendObtained(ctx, pt, mutOf(pd), pd.Level or 0, remainsM) end)
						elseif step == "leveling" and stepDone("leveling", pd)
							and ctx.webhookLeveling and ctx.webhookLeveling.sendFinished then
							-- CUMA Phase 2 (reached final). Phase 1 (P1Target) ga kirim.
							local remains = 0
							for _, iv in pairs(inv) do
								if types[iv.PetType] and not isFav(iv.PetData) and not stepDone("leveling", iv.PetData) then remains = remains + 1 end
							end
							pcall(function() ctx.webhookLeveling.sendFinished(ctx, pt, mutOf(pd), pd.Level or 0, 0, remains) end)
						end
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.1)
					end
				end
			end
		end

		-- Tambah target pet baru yg butuh kerja di step/phase ini, sampai maxPets.
		local needed = maxPets - #active
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				if not localEq[uuid] and types[v.PetType] and not (v.PetData or {}).IsFavorite and needsWork(v.PetData or {}) then
					table.insert(pool, { uuid = uuid, key = (v.PetData or {}).Level or (v.PetData or {}).BaseWeight or 0 })
				end
			end
			table.sort(pool, function(a, b) return a.key < b.key end)
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i].uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i].uuid, CFrame.new(pos)) end)
					localEq[pool[i].uuid] = true
					table.insert(active, pool[i].uuid)
					if step == "elephant" then
						ctx.state.growthElephantStart = ctx.state.growthElephantStart or {}
						ctx.state.growthElephantStart[pool[i].uuid] = os.time()
					end
					task.wait(0.15)
				end
			end
		end

		ctx.state.growthStatus = ("%s: %d/%d aktif"):format(stepLabel, #active, maxPets)
	end

	----------------------------------------------------------------- loop
	local function growthLoop()
		ctx.state.growthId = (ctx.state.growthId or 0) + 1
		local myId = ctx.state.growthId
		ctx.elevate()
		ctx.state.growthFirstRun = true
		ctx.state.growthClearKey = nil
		while CFG.growthEnabled and ctx.alive() and ctx.state.growthId == myId do
			pcall(checkGrowth)
			-- pas bersihin/transisi -> cek cepat (1s) biar garden cepat bersih & lanjut;
			-- steady (proses grow/level) -> 2s (hemat, toh pet numbuh di server).
			task.wait((ctx.state.growthClearing or ctx.state.growthFirstRun) and 0.5 or 2)
		end
		ctx.state.growthStatus = "Idle"
	end

	function ctx.startGrowth()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		-- override config webhook elephant -> baca config GROWTH (bukan standalone)
		ctx.state.elephantCfgOverride = { team = CFG.growthElephantTeam, types = CFG.growthPetTypes, weight = CFG.growthElephantWeight }
		ctx.state.elephantWebhookPost = true -- Growth: POST pesan baru tiap pet selesai (bukan edit)
		ctx.state.growthLastStepName = nil -- reset biar step pertama kirim webhook "enabled"
		task.spawn(growthLoop)
	end
	function ctx.stopGrowth()
		ctx.state.growthId = (ctx.state.growthId or 0) + 1
		ctx.state.elephantCfgOverride = nil -- balikin webhook elephant ke config standalone
		ctx.state.elephantWebhookPost = nil -- balikin webhook elephant ke mode edit (standalone)
		if ctx.clearGarden then ctx.clearGarden("Growth") end
	end
end
]=],
	["modules/hatch/automation_hatch.lua"] = [=[
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

	-- LISTEN notif game = recovery ASLI (1 notif = 1 egg balik). Sumber paling akurat.
	--   Hatch: "Lucky Hatch! Your egg has been recovered."
	--   Sell : "Lucky Pet! You got a ... egg back from selling your pet!"
	do
		local g = (getgenv and getgenv()) or _G
		if g.__hatchNotifConn then pcall(function() g.__hatchNotifConn:Disconnect() end) end
		local NotifRemote = RS.GameEvents:FindFirstChild("Notification")
		if NotifRemote then
			g.__hatchNotifConn = NotifRemote.OnClientEvent:Connect(function(msg)
				if type(msg) ~= "string" or not CFG.hatchEnabled then return end
				local l = msg:lower()
				if l:find("egg has been recovered") then
					ctx.state.periodHatchRec = (ctx.state.periodHatchRec or 0) + 1
				elseif l:find("egg back from selling") then
					ctx.state.periodSellRec = (ctx.state.periodSellRec or 0) + 1
				end
			end)
		end
	end

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
	-- ActivePetsService: sumber pet yg beneran AKTIF (model spawn + passive kebaca).
	local ActivePets; pcall(function() ActivePets = require(RS.Modules.PetServices.ActivePetsService) end)
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
	-- Semua anggota team udah AKTIF di garden (ClientPetState) -> passive-nya kebaca.
	local function teamActive(teamSet)
		if not next(teamSet or {}) then return true end
		if not ActivePets or not ActivePets.ClientPetState then return true end -- ga bisa cek -> anggap ok
		local cps = ActivePets.ClientPetState[LP.Name]
		if not cps then return false end
		for u in pairs(teamSet) do if cps[u] == nil then return false end end
		return true
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

	-- Equip team: BLOK sampai team LENGKAP ter-equip (data). Boost/passive (bronto/koi/seal)
	-- diterapin server-side pas pet KE-EQUIP, BUKAN pas model kerender di client. ClientPetState
	-- (spawn model) cuma dipake sbg sinyal cepat kalau kebaca — tapi di LOW PERFORMANCE MODE
	-- model pet sering ga spawn, jadi JANGAN jadiin gate. Kalau ga kebaca aktif, tetap lanjut
	-- setelah settle delay (team udah ke-equip = boost udah masuk server).
	local function equipTeam(teamSet, label)
		if not next(teamSet or {}) then return true end
		if teamMatches(teamSet) and teamActive(teamSet) then return true end -- fast path
		ctx.state.hatchStatus = (label or "Team") .. ": equipping..."
		-- 1) pasang sampai data-equipped lengkap
		for _ = 1, 6 do
			if teamMatches(teamSet) then break end
			equipTeamOnce(teamSet)
			task.wait(0.2)
		end
		if not teamMatches(teamSet) then return false end -- beneran ga bisa equip -> gagal
		-- 2) best-effort tunggu pet aktif (model spawn) — poll max ~4s. Begitu kebaca, lanjut.
		for _ = 1, 20 do
			if teamActive(teamSet) then return true end
			ctx.state.hatchStatus = (label or "Team") .. ": nunggu pet aktif..."
			task.wait(0.2)
		end
		-- 3) ga kebaca aktif (kemungkinan low-perf, model ga spawn) TAPI udah ke-equip di data.
		--    Boost server tetap kepasang -> LANJUT (jgn skip). Settle bentar buat jaga2.
		ctx.state.hatchStatus = (label or "Team") .. ": ke-equip (settle)..."
		task.wait(1.5)
		return true
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
	-- PENTING: pakai berat TAMPIL (BaseWeight*(1+0.1*Level)) = yg keliatan di game/dropdown,
	-- BUKAN BaseWeight mentah (beda angka -> salah keep/favorite). Weight & Age = AND
	-- (harus dua-duanya kepenuhi; 0 = filter itu dimatiin).
	local function shouldSell(petType, pd)
		pd = pd or {}
		local age = pd.Level or 0
		local w = (pd.BaseWeight or 0) * (1 + 0.1 * age)
		local key = petEggLabel(petType)
		if (CFG.sellPetTypes or {})[key] then
			local wt = CFG.sellWeightThreshold or 0
			local at = CFG.sellAgeThreshold or 0
			local wOk = wt <= 0 or w < wt
			local aOk = at <= 0 or age < at
			if (wt > 0 or at > 0) and wOk and aOk then return true end
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
	-- Sebar egg ACAK di dalam area, tetap jaga jarak antar-egg biar ga "Too close".
	local function randomPositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4 -- jarak minimum antar egg
		local halfX = math.max(SP, p.Size.X / 2 - 2)
		local halfZ = math.max(SP, p.Size.Z / 2 - 2)
		local y = p.Size.Y / 2 + 0.2
		local out, tries = {}, 0
		-- generate lebih banyak dari n (buffer) biar tetap bisa penuh walau ada yg bentrok
		while #out < n * 2 and tries < n * 40 do
			tries = tries + 1
			local cand = p.Position + Vector3.new((math.random() * 2 - 1) * halfX, y, (math.random() * 2 - 1) * halfZ)
			local ok = true
			for _, e in ipairs(out) do
				if (Vector3.new(e.X, 0, e.Z) - Vector3.new(cand.X, 0, cand.Z)).Magnitude < SP then ok = false; break end
			end
			if ok then out[#out + 1] = cand end
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
	-- return tool egg yg lagi dipegang (scan SEMUA tool, bukan cuma yg pertama) + apakah ada
	-- tool lain (pet/egg beda) yg ikut nyangkut.
	local function scanHeld(eggName)
		local char = LP.Character
		local heldEgg, otherCount = nil, 0
		if char then for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") then
				if not t:GetAttribute("PET_UUID") and tostring(t.Name):find(eggName, 1, true) then heldEgg = t
				else otherCount = otherCount + 1 end
			end
		end end
		return heldEgg, otherCount
	end
	local function equipEggTool(eggName)
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end
		local heldEgg, otherCount = scanHeld(eggName)
		-- udah megang egg yg bener DAN ga ada tool lain nyangkut -> ok
		if heldEgg and otherCount == 0 then return heldEgg end
		-- ada pet/egg-lain ke-pegang barengan (bug double-hold) -> lepas SEMUA biar bersih
		pcall(function() hum:UnequipTools() end); task.wait(0.15)
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find(eggName, 1, true) and not t:GetAttribute("PET_UUID") then
				pcall(function() hum:EquipTool(t) end); task.wait(0.35)
				-- pastiin abis equip ga ada tool lain nyusup lagi
				local eg2, oc2 = scanHeld(eggName)
				if eg2 and oc2 > 0 then pcall(function() hum:UnequipTools() end); task.wait(0.1); pcall(function() hum:EquipTool(t) end); task.wait(0.25) end
				return t
			end
		end end
		return nil
	end
	-- Isi egg RAPIH ke grid, cuma di slot yg kosong. Retry sampai penuh (target).
	local function placeEggs(target)
		local eggName = CFG.hatchEggName or "Rare Egg"
		if not equipEggTool(eggName) then ctx.state.hatchStatus = "Egg '" .. eggName .. "' ga ada di backpack"; return 0 end
		local start = placedEggCount()
		local isRandom = (CFG.hatchPlacePattern == "Random")
		-- isi slot kosong sampai TEPAT target; berhenti kalau 1 pass ga nambah (mentok)
		for _ = 1, 3 do
			if placedEggCount() >= target then break end
			local before = placedEggCount()
			-- Random: sebar ulang tiap pass (spot baru). Grid: pola tetap.
			local grid = isRandom and randomPositions(target) or gridPositions(target)
			local eggs = currentEggs()
			for _, pos in ipairs(grid) do
				if not CFG.hatchEnabled or placedEggCount() >= target then break end
				if not slotOccupied(pos, eggs) then
					equipEggTool(eggName)
					-- pastiin bener-bener MEGANG egg (scan semua tool, bukan cuma yg pertama;
					-- kadang pet hasil hatch ikut ke-pegang). Kalau ada pet nyangkut, equipEggTool
					-- di atas udah bersihin -> re-scan.
					local held = scanHeld(eggName)
					if held then
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
				title = "AllegiaantHub \u{2014} Hatch Alerts",
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

	-- Kategori Hunt: Special (dari filter Bronto Config) + tier berat.
	-- Huge 5-6.9 | Titan 7-8.9 | Godly 9-9.9 | Colossal 10+. Urutan tampil (selalu muncul).
	local TIER_ORDER = { "Special", "Huge", "Titan", "Godly", "Colossal" }
	local function weightTier(w)
		w = tonumber(w) or 0
		if w >= 10 then return "Colossal"
		elseif w >= 9 then return "Godly"
		elseif w >= 7 then return "Titan"
		elseif w >= 5 then return "Huge"
		else return nil end -- <5kg & bukan special: ga masuk kategori manapun
	end
	-- Apakah pet masuk filter Special di Bronto Configuration?
	local function isBrontoSpecial(petType, w)
		local key = petEggLabel(petType)
		if (CFG.brontoSpecialPets or {})[key] ~= true then return false end
		if (CFG.brontoSpecialWeight or 0) > 0 and (w or 0) <= CFG.brontoSpecialWeight then return false end
		return true
	end
	-- akumulasi pet ke-hatch per KATEGORI -> per tipe (buat Hunt Statistics)
	local function trackHatch(petType, dispW, special)
		ctx.state.hatchTiers = ctx.state.hatchTiers or {}
		local tier = special and "Special" or weightTier(dispW)
		if not tier then return end -- <5kg non-special: skip dari Hunt
		local bucket = ctx.state.hatchTiers[tier]
		if not bucket then bucket = {}; ctx.state.hatchTiers[tier] = bucket end
		local t = bucket[petType]
		if not t then t = { n = 0, minW = math.huge, maxW = 0 }; bucket[petType] = t end
		t.n = t.n + 1
		if dispW < t.minW then t.minW = dispW end
		if dispW > t.maxW then t.maxW = dispW end
	end
	ctx.hatchIsBrontoSpecial = isBrontoSpecial

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
	-- Recovery stat DIHITUNG dari team yg dipilih (formula game, bukan empiris).
	-- Per pet: value = clamp(Base + Scale*scaledLevel, 0, Max). scaledLevel diminishing
	-- di atas 100. Total di-cap 50% (cap per egg). Koi @ Hatch team, Seal @ Sell team.
	local function scaledLevel(lv)
		lv = lv or 0
		if lv <= 100 then return lv
		elseif lv <= 120 then return (lv - 100) * 0.25 + 100
		else return (lv - 120) * 0.1 + 105 end
	end
	local function passivePct(teamSet, typeMatch, base, scale, maxPer)
		local inv = inventory()
		local n, total = 0, 0
		for u in pairs(teamSet or {}) do
			local v = inv[u]
			if v and tostring(v.PetType):find(typeMatch) then
				n = n + 1
				local val = base + scale * scaledLevel((v.PetData or {}).Level or 0)
				total = total + math.clamp(val, 0, maxPer) -- per-pet asli (Max 10), total ga di-cap
			end
		end
		return n, total
	end
	-- Koi (Fish of Fortune): Base1 Scale0.22 Max10. Seal (Seal the Deal): Base1 Scale0.05 Max10.
	function ctx.getRecoveryStat()
		local kn, kp = passivePct(CFG.hatchHatchTeam, "Koi", 1, 0.22, 10)
		local sn, sp = passivePct(CFG.hatchSellTeam, "Seal", 1, 0.05, 10)
		return {
			koiCount = kn, koiPct = kp,
			sealCount = sn, sealPct = sp,
		}
	end

	-- Recovery ASLI dihitung dari notif game (listener di atas): periodHatchRec / periodSellRec.
	-- periodHatched / periodSold = jumlah aksi (buat hitung % efektif).

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
		-- Hunt Statistics: grup per TIER berat -> per tipe (count + range berat)
		local TIER_ICON = { Colossal = "\u{1F30B}", Godly = "\u{1F396}\u{FE0F}", Titan = "\u{1F3C6}", Huge = "\u{1F525}", Special = "\u{2B50}" }
		local tiers = ctx.state.hatchTiers or {}
		local huntParts, totalPets = {}, 0
		for _, tier in ipairs(TIER_ORDER) do
			local bucket = tiers[tier] or {}
			local lines, tierN, keys = {}, 0, {}
			for pt in pairs(bucket) do keys[#keys + 1] = pt end
			table.sort(keys)
			for _, pt in ipairs(keys) do
				local t = bucket[pt]; tierN = tierN + t.n; totalPets = totalPets + t.n
				local rng = (t.minW == t.maxW) and ("%.2f kg"):format(t.maxW)
					or ("%.2f-%.2f kg"):format(t.minW == math.huge and 0 or t.minW, t.maxW)
				lines[#lines + 1] = ("> \u{2022} %s x%d (%s)"):format(pt, t.n, rng)
			end
			-- selalu tampil kategori (walau 0); bullet cuma kalau ada. Style '>' samain field lain
			local head = ("> %s %s: %d"):format(TIER_ICON[tier] or "", tier, tierN)
			huntParts[#huntParts + 1] = #lines > 0 and (head .. "\n" .. table.concat(lines, "\n")) or head
		end
		local hunt = table.concat(huntParts, "\n"):sub(1, 1020)
		-- Recovery deterministik (cap 50%). Koi dari Hatch+Bronto team; Seal dari Sell team.
		local rec = ctx.getRecoveryStat()
		local periodHatched = ctx.state.periodHatched or 0
		local sellDone = ctx.state.sellDoneThisReport == true
		local periodSold = sellDone and (ctx.state.periodSold or 0) or 0
		local recHatchCycle = math.floor((ctx.state.periodHatchRec or 0) + 0.5)
		local recSellCycle = sellDone and math.floor((ctx.state.periodSellRec or 0) + 0.5) or 0
		-- % = PASSIVE Koi/Seal yg aktif di garden (bukan rate balik). Sell 0 kalau blm sell.
		local koiPctShown = rec.koiPct
		local sellPctShown = sellDone and rec.sealPct or 0
		local totalRecovery = recHatchCycle + recSellCycle -- per cycle (Hatch + Sell laporan ini)
		-- Current Amount = egg di backpack APA ADANYA (yg keliatan di game). Diukur SETELAH
		-- garden ke-refill (place egg lagi) -> egg balik udah nyampe & ke-place, jadi ga miss.
		-- Net Result = Current Amount - Egg Before (dua-duanya raw backpack, patokan konsisten).
		local curAdj = curAmt
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
				{ name = "Egg Statistics :", value = ("> Egg Before: `%d`\n> Current Amount: `%d`\n> Net Result: `%+d`\n> Lucky Hatch: `%d` ( %.2f%% )\n> Lucky Sell: `%d` ( %.2f%% )\n> Total Recovery: `%d`")
					:format(eggBefore, curAdj, curAdj - eggBefore, recHatchCycle, koiPctShown, recSellCycle, sellPctShown, totalRecovery), inline = false },
				{ name = "Hatch Statistics :", value = ("> Hatch Cycles: `%d`\n> Total Hatched: `%d`\n> Sell Cycle: `%d / %d`\n> Cycle Duration: `%s`\n> All Time Duration: `%s`")
					:format(hatchCycles, hatched, (ctx.state.hatchReportSellProg or ((ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0))), CFG.sellEveryNCycles or 1,
						fmtDur(os.time() - (ctx.state.hatchCycleStartTime or os.time())), fmtDur(os.time() - (ctx.state.hatchStartTime or os.time()))), inline = false },
			},
			footer = { text = os.date("%B %d | %I:%M %p") },
		} } }
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
		ctx.state.hatchCycleStartTime = os.time()
		-- reset counter periode (Lucky Hatch/Sell dihitung ulang tiap webhook)
		ctx.state.periodHatched, ctx.state.periodSold, ctx.state.sellDoneThisReport = 0, 0, false
		ctx.state.periodHatchRec, ctx.state.periodSellRec = 0, 0
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
			proc = ctx.getRecoveryStat(),
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
			local sold = doSell()
			ctx.state.periodSold = (ctx.state.periodSold or 0) + (tonumber(sold) or 0)
			ctx.state.sellDoneThisReport = true
			-- simpan progress sell-cycle SEBELUM reset (biar webhook nampilin 2/2 bukan 0/2)
			ctx.state.hatchReportSellProg = cycle - (ctx.state.hatchLastSellCycle or 0)
			ctx.state.hatchLastSellCycle = cycle
			-- report DITUNDA: dikirim nanti setelah garden ke-refill (place egg lagi), biar
			-- Current Amount stabil & Lucky Sell (egg balik) udah nyampe.
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

		-- REPORT: garden udah ke-refill (place selesai). Kalau ada report pending dari
		-- hatch/sell sebelumnya, KIRIM sekarang -> Current Amount = backpack + garden (stabil).
		if ctx.state.hatchPendingReport then
			ctx.state.hatchPendingReport = false
			task.spawn(sendCycleStats)
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
					if pt then trackHatch(pt, w, isBrontoSpecial(pt, w)) end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
					task.wait(CFG.hatchSpeed or 0.2)
				end
			end
			-- pass NORMAL -> Hatch Team (Koi recovery, tanpa boost berat)
			if #normal > 0 then
				if next(CFG.hatchHatchTeam or {}) and not equipTeam(CFG.hatchHatchTeam, "Hatch Team") then return end
				ctx.state.hatchPhase = ("Hatching Hatch-team (%d)"):format(#normal)
				hatchList(normal)
			end
			-- pass BRONTO -> Bronto Team (+30% berat) + kirim Hatch Alert per pet
			if #bronto > 0 then
				if next(CFG.hatchBrontoTeam or {}) and not equipTeam(CFG.hatchBrontoTeam, "Bronto Team") then return end
				ctx.state.hatchPhase = ("Hatching Bronto-team (%d)"):format(#bronto)
				for _, e in ipairs(bronto) do
					if not CFG.hatchEnabled then break end
					local pt, w = eggPending(e)
					-- pet ini di-hatch pakai Bronto team -> berat aktual +30% (buat tier Hunt)
					if pt then trackHatch(pt, w * 1.3, isBrontoSpecial(pt, w)); task.spawn(function() sendHatchAlert(pt, CFG.hatchEggName or "Rare Egg", w) end) end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
					task.wait(CFG.hatchSpeed or 0.2)
				end
			end
			-- jumlah hatch (recovery-nya diisi listener notif). Beri jeda biar notif nyusul.
			ctx.state.periodHatched = (ctx.state.periodHatched or 0) + #normal + #bronto
			task.wait(1.5)
			-- 1 batch (normal+bronto) selesai = 1 ronde/cycle
			ctx.state.hatchRounds = (ctx.state.hatchRounds or 0) + 1
			-- TANDAI report pending. Webhook ga dikirim di sini — ditunda sampai garden
			-- ke-refill (place egg lagi) biar Current Amount stabil & Lucky Hatch keitung.
			if not (ctx.state.sellDoneThisReport) then ctx.state.hatchReportSellProg = nil end
			ctx.state.hatchPendingReport = true
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
		-- RESET semua statistik: tiap nyalain ulang mulai dari awal (webhook + live status)
		ctx.state.hatchEggsHatched = 0
		ctx.state.hatchRounds = 0
		ctx.state.hatchLastSellCycle = 0
		ctx.state.hatchReportSellProg = nil
		ctx.state.hatchSellCycles = 0
		ctx.state.hatchTiers = {}
		ctx.state.periodHatched = 0
		ctx.state.periodSold = 0
		ctx.state.periodHatchRec = 0
		ctx.state.periodSellRec = 0
		ctx.state.sellDoneThisReport = false
		ctx.state.hatchPendingReport = false
		-- catat jumlah egg terpilih di awal (buat "Egg Before") = backpack apa adanya
		local eggName = CFG.hatchEggName or "Rare Egg"
		ctx.state.hatchEggBefore = 0
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and not t:GetAttribute("PET_UUID") and tostring(t.Name):find(eggName, 1, true) then
					local _, cnt = tostring(t.Name):match("^(.-)%s*x(%d+)$"); if tonumber(cnt) then ctx.state.hatchEggBefore = tonumber(cnt) end
				end
			end end
		end
		ctx.state.hatchStartTime = os.time()
		ctx.state.hatchCycleStartTime = os.time()
		task.spawn(loop)
	end
	function ctx.stopHatch()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		ctx.state.hatchStatus = "Idle"
	end

	----------------------------------------------------------------- AUTO FAVORITE
	-- Favoritin otomatis pet yg tipenya ada di CFG.favoritePetTypes (biar ga ke-sell).
	-- favoritePetTypes = key PET_OPTIONS (nama pet polos); tool attribute "f" = nama pet.
	function ctx.startAutoFavorite()
		ctx.state.autoFavId = (ctx.state.autoFavId or 0) + 1
		local my = ctx.state.autoFavId
		ctx.elevate()
		task.spawn(function()
			while CFG.autoFavorite and ctx.alive() and ctx.state.autoFavId == my do
				if next(CFG.favoritePetTypes or {}) then
					for _, t in ipairs(petTools()) do
						local pt = t:GetAttribute("f")
						if pt and (CFG.favoritePetTypes)[pt] and not isFav(t) then
							setFav(t, true)
						end
					end
				end
				task.wait(3)
			end
		end)
	end
	function ctx.stopAutoFavorite()
		ctx.state.autoFavId = (ctx.state.autoFavId or 0) + 1
	end
end
]=],
	["modules/inventory/automation_accept.lua"] = [=[
--[[ accept.lua — Automation Accept.
     * Accept Gifts : gift pet LANGSUNG (tanpa trade/tiket). Remote GiftPet masuk,
                      dijawab AcceptPetGift:FireServer(true, giftId).
     * Accept Trades: auto-terima AJAKAN trade masuk (RespondRequest true) [menyusul].
     Dua hal berbeda — gift ≠ trade. ]]
return function(ctx)
	local CFG            = ctx.CFG
	local SendRequest    = ctx.deps.SendRequest
	local RespondRequest = ctx.deps.RespondRequest
	local GiftPet        = ctx.deps.GiftPet
	local AcceptPetGift  = ctx.deps.AcceptPetGift
	local TC             = ctx.deps.TradingController
	local Accept         = ctx.deps.Accept
	local Confirm        = ctx.deps.Confirm
	local function log(m) ctx.log(m) end

	----------------------------------------------------------------- AUTO ACCEPT GIFT
	-- GiftPet.OnClientEvent(giftId, petDescription, senderName)
	-- UI notif dibuat game di PlayerGui.Gift_Notification.Frame (tiap gift = 1 clone,
	-- tombolnya di notif.Holder.Frame.Accept). Kita picu klik tombol itu supaya
	-- handler asli jalan (destroy UI + fire AcceptPetGift) -> UI ikut hilang.
	local LP = ctx.LP

	local function clickAcceptButtons()
		local pg = LP:FindFirstChild("PlayerGui")
		local gn = pg and pg:FindFirstChild("Gift_Notification")
		local frame = gn and gn:FindFirstChild("Frame")
		if not frame then return 0 end
		local n = 0
		for _, notif in ipairs(frame:GetChildren()) do
			local holder = notif:FindFirstChild("Holder")
			local inner  = holder and holder:FindFirstChild("Frame")
			local accept = inner and inner:FindFirstChild("Accept")
			if accept then
				local fired = false
				if type(getconnections) == "function" then
					for _, c in ipairs(getconnections(accept.MouseButton1Click)) do
						pcall(function() c:Fire() end); fired = true
					end
				end
				if fired then n += 1 end
			end
		end
		return n
	end

	if GiftPet and AcceptPetGift then
		GiftPet.OnClientEvent:Connect(function(giftId, petDesc, sender)
			if not CFG.acceptGifts then return end
			if type(giftId) ~= "string" then return end
			log(("Gift masuk dari %s: %s"):format(tostring(sender), tostring(petDesc)))
			task.wait(0.5) -- kasih waktu game bikin UI notif-nya dulu
			local clicked = clickAcceptButtons()
			if clicked > 0 then
				log("Gift diterima ✓ (via tombol, UI ditutup)")
			else
				-- fallback: fire remote langsung + coba hapus notif
				pcall(function() AcceptPetGift:FireServer(true, giftId) end)
				local pg = LP:FindFirstChild("PlayerGui")
				local gn = pg and pg:FindFirstChild("Gift_Notification")
				local frame = gn and gn:FindFirstChild("Frame")
				if frame then for _, c in ipairs(frame:GetChildren()) do c:Destroy() end end
				log("Gift diterima ✓ (fallback remote)")
			end
		end)
	else
		warn("[AllegiaantHub] GiftPet/AcceptPetGift remote tidak ketemu — auto accept gift nonaktif.")
	end

	----------------------------------------------------------------- AUTO ACCEPT TRADE
	-- 1) Terima AJAKAN masuk: SendRequest.OnClientEvent(reqId, sender) -> RespondRequest(reqId,true)
	if SendRequest and RespondRequest then
		pcall(function()
			SendRequest.OnClientEvent:Connect(function(requestId, senderPlayer)
				if not CFG.acceptTrades then return end
				log("Auto-terima ajakan trade dari " .. tostring(senderPlayer and senderPlayer.Name or "?"))
				task.wait(0.3)
				pcall(function() RespondRequest:FireServer(requestId, true) end)
			end)
		end)
	end

	-- 2) Di window trade masuk: auto Accept (pas cooldown habis) -> tunggu lawan -> Confirm.
	--    Penerima ngasih kosong. Guard: jangan ganggu Automation Trade kita sendiri.
	if TC and TC.OnTradeCreated and Accept and Confirm then
		TC.OnTradeCreated:Connect(function()
			if not CFG.acceptTrades then return end
			if ctx.state.tradeRunning then return end -- kita lagi jadi pengirim, jangan diganggu
			task.spawn(function()
				log("Window trade masuk — auto accept + confirm.")
				-- auto accept: spam pelan sampai status KITA jadi Accepted (cooldown habis)
				local myOk, a0 = false, os.clock()
				repeat
					pcall(function() Accept:FireServer() end)
					task.wait(1)
					local s = ctx.myState and ctx.myState(ctx.replicatorData())
					if s == "Accepted" or s == "Confirmed" then myOk = true; break end
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - a0) > 20
				if not myOk or not (TC and TC.CurrentTradeReplicator) then return end

				-- tunggu lawan accept
				local t0 = os.clock()
				local otherOk = false
				repeat
					task.wait(0.5)
					if ctx.otherAccepted and ctx.otherAccepted(ctx.replicatorData()) then otherOk = true; break end
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 60
				if not otherOk or not (TC and TC.CurrentTradeReplicator) then return end

				-- confirm sampai trade tertutup
				t0 = os.clock()
				repeat
					pcall(function() Confirm:FireServer() end)
					task.wait(1.5)
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 15
				log("Trade masuk selesai (confirmed).")
			end)
		end)
	end
end
]=],
	["modules/inventory/automation_trade.lua"] = [=[
--[[ trade.lua — inti Automation Trade.
     Alur per-trade: SendRequest -> tunggu window kebuka -> AddItem pets -> Accept
                     -> tunggu lawan accept -> Confirm -> tunggu selesai.
     Mengisi: ctx.getPlayers, ctx.getData, ctx.matchingPetUuids,
              ctx.startTrade, ctx.stopTrade ]]
return function(ctx)
	local Players     = ctx.Services.Players
	local LP          = ctx.LP
	local CFG         = ctx.CFG
	local DataService = ctx.deps.DataService
	local TC          = ctx.deps.TradingController
	local SendRequest = ctx.deps.SendRequest
	local AddItem     = ctx.deps.AddItem
	local Accept      = ctx.deps.Accept
	local Confirm     = ctx.deps.Confirm
	local Decline     = ctx.deps.Decline
	local FavoriteItem = ctx.deps.FavoriteItem
	local function log(m) ctx.log(m) end
	local function setStatus(s) ctx.setStatus(s) end

	----------------------------------------------------------------- data helpers
	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok then return d end
		return nil
	end
	ctx.getData = getData

	local function getPlayers()
		local list = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then list[#list + 1] = p.Name end
		end
		table.sort(list)
		return list
	end
	ctx.getPlayers = getPlayers

	-- cek pet cocok dengan filter CFG
	local function petPasses(v)
		local pt = v.PetType
		local pd = v.PetData
		if not (pt and pd) then return false end
		-- filter type (kosong = semua)
		if next(CFG.petTypes) and not CFG.petTypes[pt] then return false end
		-- weight: berat TAMPIL di game = BaseWeight + 0.5 (pakai angka tampilan di filter)
		local w = (pd.BaseWeight or 0) + 0.5
		local wf = CFG.weightFilter or 0
		if wf > 0 and w < wf then return false end
		if wf < 0 and w > -wf then return false end
		-- age (Level)
		local age = pd.Level or 0
		local af = CFG.ageFilter or 0
		if af > 0 and age < af then return false end
		if af < 0 and age > -af then return false end
		return true
	end

	-- kumpulkan uuid pet yang cocok (maksimal `limit`)
	local function matchingPetUuids(limit)
		local out = {}
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return out end
		-- pet yang lagi di-equip jangan di-trade
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		for uuid, v in pairs(pinv) do
			if #out >= limit then break end
			if not equipped[uuid] and petPasses(v) then
				local fav = v.PetData.IsFavorite
				if (not fav) or CFG.autoUnfavorite then
					out[#out + 1] = { uuid = uuid, fav = fav, petType = v.PetType }
				end
			end
		end
		return out
	end
	ctx.matchingPetUuids = matchingPetUuids

	-- Hitung SEMUA pet yang cocok filter (tanpa limit) untuk status GUI.
	function ctx.countMatchingPets()
		local n = 0
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return 0 end
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		for uuid, v in pairs(pinv) do
			if not equipped[uuid] and petPasses(v) then
				local fav = v.PetData.IsFavorite
				if (not fav) or CFG.autoUnfavorite then n = n + 1 end
			end
		end
		return n
	end

	-- PRE-PASS: unfavorite SEMUA pet favorite yang lolos filter dulu (dipanggil di awal
	-- trade). Biar ga ke-race pas add item (unfav satu-satu tiap batch rawan gagal).
	local function unfavoriteAllMatching()
		if not (CFG.autoUnfavorite and FavoriteItem) then return end
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return end
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		local favSet, favCount = {}, 0
		for uuid, v in pairs(pinv) do
			if not equipped[uuid] and petPasses(v) and v.PetData.IsFavorite then
				favSet[uuid] = true; favCount = favCount + 1
			end
		end
		if favCount == 0 then return end
		setStatus(("Unfavorite %d pet target dulu..."):format(favCount))
		local Favorite_Item_BE = game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item_BE")
		local done = 0
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				local u = t:IsA("Tool") and t:GetAttribute("PET_UUID")
				if u and favSet[u] then
					pcall(function() FavoriteItem:FireServer(t) end)
					if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(t) end) end
					favSet[u] = nil; done = done + 1
					task.wait(0.1)
				end
			end end
		end
		if done > 0 then task.wait(0.5) end -- kasih waktu sync sebelum mulai trade
	end
	ctx.unfavoriteAllMatching = unfavoriteAllMatching

	----------------------------------------------------------------- trade-state read
	local function replicatorData()
		if not (TC and TC.CurrentTradeReplicator) then return nil end
		local rep = TC.CurrentTradeReplicator
		local ok, d = pcall(function() return rep:GetDataAsync() end)
		if ok and d then return d end
		ok, d = pcall(function() return rep:GetData() end)
		if ok then return d end
		return nil
	end

	ctx.replicatorData = replicatorData

	-- Skema (dari remote-spy): d.players = {p1,p2}, d.states = {[1]="None"/"Accepted", [2]=...}
	-- state index sejajar dengan players. Lawan dianggap accept kalau statenya "Accepted"/"Confirmed".
	local function stateOf(d, wantSelf)
		if type(d) ~= "table" then return nil end
		local players = d.players or d.Players
		local states  = d.states or d.States
		if type(players) ~= "table" or type(states) ~= "table" then return nil end
		local idx
		for i, p in ipairs(players) do
			if wantSelf then if p == LP then idx = i end
			else if p ~= LP then idx = i end end
		end
		if not idx then return nil end
		return states[idx]
	end
	local function otherState(d) return stateOf(d, false) end
	local function myState(d) return stateOf(d, true) end
	ctx.myState = myState
	local function otherAccepted(d)
		local s = otherState(d)
		return s == "Accepted" or s == "Confirmed"
	end
	ctx.otherAccepted = otherAccepted

	-- Trade cuma bisa dikirim kalau kita lagi MEGANG Trading Ticket.
	local function equipTradingTicket()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		-- sudah megang tiket?
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name:find("Trading Ticket") then return true end
		end
		local bp = LP:FindFirstChild("Backpack")
		if not bp then return false end
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t.Name:find("Trading Ticket") then
				pcall(function() hum:EquipTool(t) end)
				task.wait(0.3)
				return true
			end
		end
		return false
	end
	ctx.equipTradingTicket = equipTradingTicket

	----------------------------------------------------------------- one trade
	local function doOneTrade(target)
		-- pegang tiket dulu, wajib biar panel trade kebuka
		if not equipTradingTicket() then
			log("Trading Ticket tidak ada / gagal di-equip. Stop.")
			ctx.state.tradeRunning = false
			return false
		end
		setStatus("Kirim ajakan ke " .. target.Name)
		pcall(function() SendRequest:FireServer(target) end)

		-- tunggu window trade kebuka (lawan accept request)
		local t0 = os.clock()
		repeat task.wait(0.3) until (not ctx.state.tradeRunning) or (TC and TC.CurrentTradeReplicator) or (os.clock() - t0) > 20
		if not ctx.state.tradeRunning then return false end
		if not (TC and TC.CurrentTradeReplicator) then
			log("Timeout: " .. target.Name .. " tidak accept ajakan.")
			return false
		end

		-- kumpulkan pet
		local pets = matchingPetUuids(CFG.petsPerTrade)
		if #pets == 0 then
			log("Tidak ada pet cocok filter. Batalkan trade.")
			pcall(function() Decline:FireServer() end)
			return false
		end

		-- auto unfavorite dulu kalau perlu.
		-- PENTING: Favorite_Item butuh TOOL object (bukan uuid). Cari tool di Backpack/Character.
		if CFG.autoUnfavorite and FavoriteItem then
			local Favorite_Item_BE = game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item_BE")
			local function findToolByUuid(uuid)
				local bp = LP:FindFirstChildOfClass("Backpack")
				if bp then for _, t in ipairs(bp:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
				end end
				if LP.Character then for _, t in ipairs(LP.Character:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
				end end
				return nil
			end
			for _, p in ipairs(pets) do
				if p.fav then
					local tool = findToolByUuid(p.uuid)
					if tool then
						pcall(function() FavoriteItem:FireServer(tool) end)
						if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(tool) end) end
						task.wait(0.15)
					end
				end
			end
			task.wait(0.3)
		end

		-- add item
		log(("Cocok %d pet. Contoh uuid=%s"):format(#pets, tostring(pets[1] and pets[1].uuid)))
		setStatus(("Menambah %d pet..."):format(#pets))
		for _, p in ipairs(pets) do
			if not ctx.state.tradeRunning then break end
			pcall(function() AddItem:FireServer("Pet", p.uuid) end)
			task.wait(0.3)
		end

		-- verifikasi berapa pet yang benar-benar masuk ke offer kita
		task.wait(0.5)
		do
			local d = replicatorData()
			local myIdx
			if d and d.players then for i, pl in ipairs(d.players) do if pl == LP then myIdx = i end end end
			local n = 0
			if d and myIdx and d.offers and d.offers[myIdx] then
				for _ in pairs(d.offers[myIdx].items or {}) do n += 1 end
			end
			log(("Pet masuk ke offer: %d/%d"):format(n, #pets))
			if n == 0 then
				log("AddItem tidak masuk — cek: pet favorit? equipped? uuid?")
			end
		end

		-- Auto-accept: game punya cooldown anti-scam sebelum tombol Accept aktif.
		-- Daripada nebak durasinya, kita spam Accept pelan sampai status KITA jadi
		-- "Accepted" (artinya cooldown sudah habis & Accept kebaca). Otomatis nunggu pas.
		setStatus("Accept (nunggu cooldown game)...")
		local myOk = false
		local a0 = os.clock()
		repeat
			pcall(function() Accept:FireServer() end)
			task.wait(1)
			local s = myState(replicatorData())
			if s == "Accepted" or s == "Confirmed" then myOk = true; break end
		until (not ctx.state.tradeRunning) or (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - a0) > 20
		if not ctx.state.tradeRunning or not (TC and TC.CurrentTradeReplicator) then return false end
		if not myOk then
			log("Accept kita belum kebaca setelah 20s. Batalkan.")
			pcall(function() Decline:FireServer() end)
			return false
		end
		log("Accept kita OK.")
		setStatus("Menunggu lawan accept...")

		-- tunggu lawan accept
		t0 = os.clock()
		local accepted = false
		repeat
			task.wait(0.5)
			if otherAccepted(replicatorData()) then accepted = true; break end
		until (not ctx.state.tradeRunning) or (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 30
		if not ctx.state.tradeRunning then return false end
		if not (TC and TC.CurrentTradeReplicator) then
			log("Trade ditutup sebelum selesai.")
			return false
		end
		if not accepted then
			log("Lawan tidak accept (timeout). Batalkan.")
			pcall(function() Decline:FireServer() end)
			return false
		end

		-- confirm (retry sampai trade tertutup)
		setStatus("Confirm... menunggu selesai")
		t0 = os.clock()
		repeat
			pcall(function() Confirm:FireServer() end)
			task.wait(1.5)
		until (not (TC and TC.CurrentTradeReplicator)) or (not ctx.state.tradeRunning) or (os.clock() - t0) > 15
		if TC and TC.CurrentTradeReplicator then
			log("Confirm terkirim tapi trade belum tertutup.")
			return false
		end
		return true
	end

	----------------------------------------------------------------- loop
	local function tradeLoop()
		ctx.elevate()
		unfavoriteAllMatching() -- unfav semua target favorite dulu, baru mulai trade
		while ctx.state.tradeRunning do
			if ctx.state.completed >= CFG.totalTrades then
				ctx.state.status = "DONE"
				setStatus(("Selesai %d/%d trade."):format(ctx.state.completed, CFG.totalTrades))
				ctx.state.tradeRunning = false
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				break
			end
			-- Stop kalau pet cocok filter sudah habis -> jangan kirim trade lagi.
			if ctx.countMatchingPets() == 0 then
				ctx.state.status = "DONE"
				setStatus("Pet habis (sesuai filter). Trade dihentikan.")
				ctx.state.tradeRunning = false
				CFG.tradeEnabled = false
				if ctx.persistState then ctx.persistState() end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				break
			end

			local target = CFG.targetPlayer ~= "" and Players:FindFirstChild(CFG.targetPlayer) or nil
			if not target then
				setStatus("Target player tidak ada / belum dipilih.")
				task.wait(2)
			else
				ctx.state.status = "RUNNING"
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				local ok = doOneTrade(target)
				if ok then
					ctx.state.completed += 1
					log(("Trade sukses (%d/%d)"):format(ctx.state.completed, CFG.totalTrades))
					if ctx.notifyTrade then ctx.notifyTrade(target, #matchingPetUuids(CFG.petsPerTrade)) end
				end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				task.wait(1.5)
			end
		end
	end

	function ctx.startTrade()
		if ctx.state.tradeRunning then return end
		ctx.state.tradeRunning = true
		ctx.state.status = "RUNNING"
		task.spawn(tradeLoop)
	end

	function ctx.stopTrade()
		ctx.state.tradeRunning = false
		ctx.state.status = "IDLE"
	end
end
]=],
	["modules/leveling/automation_leveling_v1.lua"] = [=[
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

	-- Mendapatkan ringkasan statistik leveling untuk UI
	function ctx.getLevelingSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		
		local teamCount = 0
		for _ in pairs(CFG.levelingTeamUuids) do teamCount = teamCount + 1 end
		
		local typesList = {}
		for k in pairs(CFG.levelingPetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"
		
		local readyCount = 0
		local maxLvlCount = 0
		local targetLvl = CFG.levelingTargetLevel or 500
		
		for _, v in pairs(inv) do
			local pt = v.PetType
			if CFG.levelingPetTypes[pt] then
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				if not pd.IsFavorite then
					if lvl < targetLvl then
						readyCount = readyCount + 1
					else
						maxLvlCount = maxLvlCount + 1
					end
				end
			end
		end
		
		return {
			status = CFG.levelingEnabled and "ACTIVE" or "STOPPED",
			team = string.format("%d pets selected", teamCount),
			types = typesStr,
			ready = string.format("%d pets", readyCount),
			maxLvl = string.format("%d pets", maxLvlCount),
			maxInGarden = string.format("%d pets", CFG.levelingMaxPets or 2),
			targetLevel = tostring(targetLvl),
		}
	end

	-- Mendapatkan semua tipe unik pet yang dimiliki di inventory
	function ctx.getInventoryPetTypes(selectedSet)
		local out, seen = {}, {}
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if inv then
			for _, v in pairs(inv) do
				local pt = v.PetType
				if pt and not seen[pt] then
					seen[pt] = true
					table.insert(out, { value = pt, display = pt })
				end
			end
		end
		-- Selalu tampilkan tipe yang DIPILIH walau stok 0 (biar pilihan ga ilang dari filter).
		if selectedSet then
			for t in pairs(selectedSet) do
				if not seen[t] then
					seen[t] = true
					table.insert(out, { value = t, display = t .. " (0 di inventory)" })
				end
			end
		end
		table.sort(out, function(a, b)
			local selA = selectedSet and selectedSet[a.value] and 1 or 0
			local selB = selectedSet and selectedSet[b.value] and 1 or 0
			if selA ~= selB then
				return selA > selB
			end
			return a.display < b.display
		end)
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

		-- Lacak status equip secara lokal agar kebal dari delay replikasi server
		local localEq = {}
		local localEqCount = 0
		for _, uuid in ipairs(eq) do
			localEq[uuid] = true
			localEqCount = localEqCount + 1
		end

		-- A. DETEKSI FIRST RUN: Cabut semua pet jika ada pet aktif
		if ctx.state.levelingFirstRun then
			ctx.state.levelingFirstRun = false
			if #eq > 0 then
				ctx.state.levelingStatus = "Resetting garden..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil
					localEqCount = localEqCount - 1
					task.wait(0.25)
				end
			end
		end

		-- B. DETEKSI PERSISTENSI TEAM: Pasang kembali pet team yang dicabut oleh user/game
		for uuid, _ in pairs(teamSet) do
			if not localEq[uuid] then
				ctx.state.levelingStatus = "Re-equipping team..."
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[uuid] = true
					localEqCount = localEqCount + 1
					task.wait(0.3)
				end
			end
		end

		-- C. KLASIFIKASI PET YANG SEDANG DI-EQUIP (berdasarkan localEq terbaru)
		local currentLeveling = {}   -- list of active leveling uuids (lvl < targetLvl)
		local finishedLeveling = {}  -- list of finished leveling uuids (lvl >= targetLvl)
		local otherEquipped = {}     -- list of other uuids (not team, not target type)

		for uuid, _ in pairs(localEq) do
			if not teamSet[uuid] then
				local pInfo = inv[uuid]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				local lvl = pd.Level or 0

				if targetTypes[pt] then
					if lvl < targetLvl then
						table.insert(currentLeveling, uuid)
						-- Catat waktu mulai jika belum ada
						ctx.state.levelingStartTime = ctx.state.levelingStartTime or {}
						if not ctx.state.levelingStartTime[uuid] then
							ctx.state.levelingStartTime[uuid] = os.time()
						end
					else
						table.insert(finishedLeveling, uuid)
					end
				else
					table.insert(otherEquipped, uuid)
				end
			end
		end

		-- D. LEPAS PET LEVELING YANG SUDAH SELESAI (mencapai target level)
		for _, uuid in ipairs(finishedLeveling) do
			local duration = 0
			if ctx.state.levelingStartTime and ctx.state.levelingStartTime[uuid] then
				duration = os.time() - ctx.state.levelingStartTime[uuid]
				ctx.state.levelingStartTime[uuid] = nil
			end

			local pInfo = inv[uuid]
			local petType = pInfo and pInfo.PetType or "Unknown"
			local pd = pInfo and pInfo.PetData or {}
			local mutation = pd.MutationType or "Normal"
			local finalAge = pd.Level or targetLvl

			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil
			localEqCount = localEqCount - 1
			task.wait(0.25)

			-- Hitung sisa antrean
			local remainsQueue = 0
			for otherUuid, v in pairs(inv) do
				local pt = v.PetType
				if targetTypes[pt] and not localEq[otherUuid] then
					local otherPd = v.PetData or {}
					local otherLvl = otherPd.Level or 0
					if otherLvl < targetLvl and not otherPd.IsFavorite then
						remainsQueue = remainsQueue + 1
					end
				end
			end

			-- Kirim Webhook Finished
			task.spawn(function()
				local WebhookLev = ctx.webhookLeveling
				if WebhookLev then
					pcall(function() WebhookLev.sendFinished(ctx, petType, mutation, finalAge, duration, remainsQueue) end)
				end
			end)
		end

		-- E. TAMBAHKAN PET BARU DARI INVENTORY
		local currentActiveCount = #currentLeveling
		local needed = maxLvlPets - currentActiveCount

		if needed > 0 then
			-- Cari pool pet di inventory yang tidak ter-equip di localEq
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0

				if not localEq[uuid] and targetTypes[pt] and lvl < targetLvl and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, petType = pt, level = lvl })
				end
			end
			table.sort(pool, function(a, b) return a.level < b.level end) -- Prioritaskan level terendah

			for i = 1, math.min(needed, #pool) do
				local target = pool[i]
				local pos = getPos(target.uuid)
				if pos then
					-- Jika total equipped secara lokal penuh (misal >= 15), copot non-team non-leveling
					if localEqCount >= 15 and #otherEquipped > 0 then
						local toRemove = table.remove(otherEquipped)
						pcall(function() PetsService:FireServer("UnequipPet", toRemove) end)
						localEq[toRemove] = nil
						localEqCount = localEqCount - 1
						task.wait(0.25)
					end
					
					pcall(function() PetsService:FireServer("EquipPet", target.uuid, CFrame.new(pos)) end)
					localEq[target.uuid] = true
					localEqCount = localEqCount + 1
					table.insert(currentLeveling, target.uuid)
					-- Catat waktu mulai
					ctx.state.levelingStartTime = ctx.state.levelingStartTime or {}
					ctx.state.levelingStartTime[target.uuid] = os.time()
					task.wait(0.3)
				end
			end
		end

		-- Update status akhir setelah proses
		ctx.state.levelingStatus = string.format("Leveling: %d/%d aktif", #currentLeveling, maxLvlPets)
	end

	local function levelingLoop()
		ctx.state.levelingId = (ctx.state.levelingId or 0) + 1
		local myId = ctx.state.levelingId
		ctx.elevate()
		
		ctx.state.levelingFirstRun = true

		-- Kirim webhook Enabled
		task.spawn(function()
			local WebhookLev = ctx.webhookLeveling
			if WebhookLev then
				local queueList = {}
				local teamList = {}
				local okData, d = pcall(function() return DataService:GetData() end)
				if okData and d and d.PetsData then
					local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
					
					-- 1. Antrean pet target
					local targetTypes = CFG.levelingPetTypes or {}
					local targetLvl = CFG.levelingTargetLevel or 500
					for _, v in pairs(inv) do
						local pt = v.PetType
						if targetTypes[pt] then
							local pd = v.PetData or {}
							local lvl = pd.Level or 0
							if lvl < targetLvl then
								table.insert(queueList, { type = pt, level = lvl })
							end
						end
					end

					-- 2. Nama pet dalam EXP team
					local teamUuids = CFG.levelingTeamUuids or {}
					for uuid, _ in pairs(teamUuids) do
						local pInfo = inv[uuid]
						if pInfo then
							table.insert(teamList, pInfo.PetType)
						end
					end
				end
				pcall(function() WebhookLev.sendEnabled(ctx, queueList, teamList) end)
			end
		end)
		
		while CFG.levelingEnabled and ctx.alive() and ctx.state.levelingId == myId do
			pcall(checkLeveling)
			task.wait(3.0)
		end
		ctx.state.levelingStatus = "Idle"
	end

	function ctx.startLeveling()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(levelingLoop) -- loop set firstRun=true -> reset garden + equip team
	end

	-- Batalkan clearGarden yang mungkin lagi jalan (dipanggil saat fitur di-ENABLE lagi,
	-- biar pet team yang baru dipasang ga ke-unequip balik oleh clear yang tertunda).
	function ctx.cancelClearGarden()
		ctx.state.clearGardenId = (ctx.state.clearGardenId or 0) + 1
	end

	-- Lepas SEMUA pet dari garden (dipakai stop leveling/mutation/cleanse, mirror elephant).
	function ctx.clearGarden(label)
		ctx.state.clearGardenId = (ctx.state.clearGardenId or 0) + 1
		local myGen = ctx.state.clearGardenId
		task.spawn(function()
			if ctx.setStatus then ctx.setStatus((label or "Clear") .. ": lepas pet dari garden...") end
			task.wait(0.3)
			for _ = 1, 30 do
				if ctx.state.clearGardenId ~= myGen then return end -- dibatalkan (fitur di-enable lagi)
				local ok, d = pcall(function() return DataService:GetData() end)
				local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
				if #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					if ctx.state.clearGardenId ~= myGen then return end
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				task.wait(0.4)
			end
			if ctx.state.clearGardenId == myGen and ctx.setStatus then ctx.setStatus((label or "Clear") .. ": garden kosong.") end
		end)
	end

	function ctx.stopLeveling()
		ctx.state.levelingId = (ctx.state.levelingId or 0) + 1 -- matikan loop
		ctx.clearGarden("Leveling")
	end
end
]=],
	["modules/leveling/automation_leveling_v2.lua"] = [=[
--[[ leveling_v2.lua — Automation Leveling V2 (2 phase).
     Konsep sama dengan V1 tapi bertahap:
       Phase 1: pakai Phase 1 Team, level target pet dari age 1 s/d Phase 1 Target,
                max Phase 1 Max Pets di garden.
       Phase 2: setelah semua target pet >= Phase 1 Target, ganti ke Phase 2 Team,
                level s/d Phase 2 Target (final), max Phase 2 Max Pets.
     Team & jumlah pet di garden beda per-phase (mis. cepat di awal, sedikit di akhir). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")

	----------------------------------------------------------------- posisi grid
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
		return center + Vector3.new((col - (GRID_COLS - 1) / 2) * GRID_SP, 0, (row - 1) * GRID_SP)
	end

	ctx.state.levelingV2Status = "Idle"

	----------------------------------------------------------------- ringkasan status
	function ctx.getLevelingV2Summary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local types = CFG.levelingV2PetTypes or {}
		local p1t = CFG.levelingV2P1Target or 40
		local p2t = CFG.levelingV2P2Target or 500
		local p1q, p2q = 0, 0
		for _, v in pairs(inv) do
			if types[v.PetType] and not (v.PetData or {}).IsFavorite then
				local lvl = (v.PetData or {}).Level or 0
				if lvl < p1t then p1q = p1q + 1 elseif lvl < p2t then p2q = p2q + 1 end
			end
		end
		local function cnt(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
		local function nm(t) local o = {}; for k in pairs(t or {}) do o[#o + 1] = k end; return #o > 0 and table.concat(o, ", ") or "-" end
		return {
			status = CFG.levelingV2Enabled and "ACTIVE" or "STOPPED",
			phase = ctx.state.levelingV2Phase or "-",
			types = nm(types),
			p1team = cnt(CFG.levelingV2P1Team), p2team = cnt(CFG.levelingV2P2Team),
			p1queue = p1q, p2queue = p2q,
			p1target = p1t, p2target = p2t,
		}
	end

	----------------------------------------------------------------- core check
	local function checkV2()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq  = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local targetTypes = CFG.levelingV2PetTypes or {}
		local p1Team = CFG.levelingV2P1Team or {}
		local p2Team = CFG.levelingV2P2Team or {}
		local p1Target = CFG.levelingV2P1Target or 40
		local p2Target = CFG.levelingV2P2Target or 500
		local p1Max = CFG.levelingV2P1Max or 3
		local p2Max = CFG.levelingV2P2Max or 1

		-- Tentukan phase aktif: ada target pet < p1Target -> Phase 1, else Phase 2.
		local phase1Work = 0
		for _, v in pairs(inv) do
			if targetTypes[v.PetType] and ((v.PetData or {}).Level or 0) < p1Target and not (v.PetData or {}).IsFavorite then phase1Work = phase1Work + 1 end
		end
		local phase = (phase1Work > 0) and 1 or 2
		ctx.state.levelingV2Phase = "Phase " .. phase
		local team       = (phase == 1) and p1Team or p2Team
		local otherTeam  = (phase == 1) and p2Team or p1Team
		local phaseTarget = (phase == 1) and p1Target or p2Target
		local phaseMin    = (phase == 1) and 0 or p1Target  -- batas bawah level utk phase ini
		local maxPets     = (phase == 1) and p1Max or p2Max

		-- Deteksi TRANSISI phase -> picu pembersihan garden TOTAL.
		if ctx.state.levelingV2LastPhase ~= nil and ctx.state.levelingV2LastPhase ~= phase then
			ctx.state.levelingV2Clearing = true
		end
		ctx.state.levelingV2LastPhase = phase

		local localEq = {}
		for _, uuid in ipairs(eq) do localEq[uuid] = true end

		-- A. First run / TRANSISI phase: bersihin garden TOTAL & pastikan BENAR-BENAR kosong
		-- dulu (verified) sebelum pasang team phase baru. Cegah sisa pet phase 1 nyangkut.
		if ctx.state.levelingV2FirstRun or ctx.state.levelingV2Clearing then
			if #eq > 0 then
				ctx.state.levelingV2Status = ("Phase %d: bersihin garden dulu (%d pet)..."):format(phase, #eq)
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				return -- cek ulang cycle berikutnya sampai garden BENAR-BENAR kosong
			end
			-- garden udah kosong -> pembersihan selesai, lanjut pasang team
			ctx.state.levelingV2FirstRun = false
			ctx.state.levelingV2Clearing = false
		end

		-- C. Pasang team phase ini + PASTIKAN LENGKAP dulu sebelum proses target pet.
		-- Cek dari data equipped asli; kalau belum lengkap, equip lalu RETURN (recheck).
		local teamComplete = true
		for uuid in pairs(team) do
			if not localEq[uuid] then
				teamComplete = false
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					task.wait(0.25)
				end
			end
		end
		if not teamComplete then
			ctx.state.levelingV2Status = ("Phase %d: nunggu team lengkap..."):format(phase)
			return -- tunggu team komplit dulu, baru proses target pet
		end

		-- D. Target pet yang lulus phase (level >= phaseTarget) -> lepas
		local active = {}
		for uuid in pairs(localEq) do
			if not team[uuid] and not otherTeam[uuid] then
				local v = inv[uuid]
				if v and targetTypes[v.PetType] then
					local pd  = v.PetData or {}
					local lvl = pd.Level or 0
					if lvl >= phaseTarget then
						-- Webhook HANYA pas phase 2 (pet mencapai target final). Phase 1 = intermediate, skip.
						if phase == 2 then
							local petType  = v.PetType or "Unknown"
							local mutation = pd.MutationType or "Normal"
							local finalAge = pd.Level or phaseTarget
							local duration = 0
							ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
							if ctx.state.levelingV2StartTime[uuid] then
								duration = os.time() - ctx.state.levelingV2StartTime[uuid]
								ctx.state.levelingV2StartTime[uuid] = nil
							end
							-- Sisa antrean phase 2 (target type, level dalam [p1Target, p2Target), belum equipped, bukan favorite)
							local remainsQueue = 0
							for ou, ov in pairs(inv) do
								if ou ~= uuid and not localEq[ou] and targetTypes[ov.PetType] then
									local ol = (ov.PetData or {}).Level or 0
									if ol >= p1Target and ol < p2Target and not (ov.PetData or {}).IsFavorite then
										remainsQueue = remainsQueue + 1
									end
								end
							end
							task.spawn(function()
								local W = ctx.webhookLeveling
								if W and W.sendFinished then
									pcall(function() W.sendFinished(ctx, petType, mutation, finalAge, duration, remainsQueue) end)
								end
							end)
						end
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.2)
					else
						table.insert(active, uuid)
						-- Catat waktu mulai leveling phase 2 (buat Duration di webhook)
						if phase == 2 then
							ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
							if not ctx.state.levelingV2StartTime[uuid] then
								ctx.state.levelingV2StartTime[uuid] = os.time()
							end
						end
					end
				end
			end
		end

		-- E. Tambah target pet baru buat phase ini (level dalam [phaseMin, phaseTarget))
		local needed = maxPets - #active
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local lvl = (v.PetData or {}).Level or 0
				if not localEq[uuid] and targetTypes[v.PetType] and lvl >= phaseMin and lvl < phaseTarget and not (v.PetData or {}).IsFavorite then
					table.insert(pool, { uuid = uuid, level = lvl })
				end
			end
			table.sort(pool, function(a, b) return a.level < b.level end) -- level terendah dulu
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i].uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i].uuid, CFrame.new(pos)) end)
					localEq[pool[i].uuid] = true
					table.insert(active, pool[i].uuid)
					-- Catat waktu mulai leveling phase 2 (buat Duration di webhook)
					if phase == 2 then
						ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
						ctx.state.levelingV2StartTime[pool[i].uuid] = os.time()
					end
					task.wait(0.25)
				end
			end
		end

		ctx.state.levelingV2Status = ("Phase %d: %d/%d aktif"):format(phase, #active, maxPets)
	end

	----------------------------------------------------------------- loop
	local function loopV2()
		ctx.state.levelingV2Id = (ctx.state.levelingV2Id or 0) + 1
		local myId = ctx.state.levelingV2Id
		ctx.elevate()
		ctx.state.levelingV2FirstRun = true
		ctx.state.levelingV2LastPhase = nil -- reset biar ga false-trigger transisi di cycle pertama
		while CFG.levelingV2Enabled and ctx.alive() and ctx.state.levelingV2Id == myId do
			pcall(checkV2)
			task.wait(3)
		end
		ctx.state.levelingV2Status = "Idle"
	end

	function ctx.startLevelingV2()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(loopV2)
	end
	function ctx.stopLevelingV2()
		ctx.state.levelingV2Id = (ctx.state.levelingV2Id or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Leveling V2") end
	end
end
]=],
	["modules/leveling/webhook.lua"] = [=[
--[[ webhook/leveling.lua — Discord webhook untuk leveling.
     Di-load via HttpGet loader; sender diambil dari ctx.sendWebhook (bukan require script). ]]
local HttpService = game:GetService("HttpService")

local levelingWebhook = {}

local function formatDuration(sec)
	if not sec or sec <= 0 then return "Unknown" end
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	local parts = {}
	if h > 0 then table.insert(parts, h .. "h") end
	if m > 0 then table.insert(parts, m .. "m") end
	if s > 0 or #parts == 0 then table.insert(parts, s .. "s") end
	return table.concat(parts, " ")
end

-- Webhook saat leveling di-enable
function levelingWebhook.sendEnabled(ctx, queueList, teamList, targetAge)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end
	queueList = queueList or {}
	teamList = teamList or {}

	local petLines = {}
	for _, p in ipairs(queueList) do
		table.insert(petLines, string.format("> - `%s` (Level %d)", p.type, p.level))
	end
	local petsText = #petLines > 0 and table.concat(petLines, "\n") or "> - Tidak ada pet di antrean"

	local teamLines = {}
	for _, pName in ipairs(teamList) do
		table.insert(teamLines, "`" .. pName .. "`")
	end
	local teamText = #teamLines > 0 and table.concat(teamLines, ", ") or "None"

	local payload = {
		embeds = {
			{
				title = "Growth • Leveling Enabled",
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Leveling Configuration",
						value = string.format(
							"> EXP Pet Team: %s\n" ..
							"> Target Age: `%s`\n" ..
							"> Queue Count: `%d`",
							teamText,
							tostring(targetAge or CFG.levelingTargetLevel or 500),
							#queueList
						),
						inline = false
					},
					{
						name = "Leveling Queue Status",
						value = petsText,
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Webhook saat pet selesai leveling
function levelingWebhook.sendFinished(ctx, petType, mutation, age, durationSec, remainsQueue)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local mutDisplay = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mutation) or mutation
	local durationStr = formatDuration(durationSec)

	local payload = {
		embeds = {
			{
				title = "Growth • Leveling",
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Final Age Reached",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Age: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Remains Queue: `%s`",
							petType,
							mutDisplay,
							tostring(age),
							durationStr,
							tostring(remainsQueue)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return levelingWebhook
]=],
	["modules/misc/automation_reconnect.lua"] = [=[
--[[ automation_reconnect.lua — Auto Reconnect/Rejoin tiap interval (Misc).
     Tiap X menit: queue loader (biar hub auto jalan lagi abis rejoin) lalu
     teleport ke server yg SAMA (reconnect), fallback server baru kalau gagal.
     Config: CFG.reconnectEnabled (toggle), CFG.reconnectInterval (menit).
     Fungsi: ctx.startReconnect. Auto-resume di app.lua biar loop lanjut tiap masuk. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local TeleportService = game:GetService("TeleportService")
	local function setStatus(s) ctx.setStatus(s) end

	local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"

	-- queue loader hub biar auto jalan lagi setelah rejoin (branch dijaga).
	local function queueLoader()
		local q = (syn and syn.queue_on_teleport) or queue_on_teleport
			or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
		if q then
			local cmd = ('if getgenv then getgenv().GAG_BRANCH=%q end loadstring(game:HttpGet("https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/%s/GAGSeller/init.lua"))()'):format(branch, branch)
			pcall(function() q(cmd) end)
		end
	end

	-- Cache reference Teleport SEKARANG (bukan pas dipanggil) biar bypass hook
	-- __namecall yg mungkin dipasang game buat block teleport pihak-3.
	local TeleportFn = TeleportService.Teleport

	local function doReconnect()
		queueLoader()
		task.wait(0.4)
		-- Teleport(placeId, player) via cached-ref. Pas di private server, Roblox
		-- rejoin ke private server juga (bukan publik) -> stay private. Kalau di
		-- server publik, ke publik. TeleportToPlaceInstance JANGAN dipakai (773 +
		-- diblok buat private).
		local ok = pcall(function() TeleportFn(TeleportService, game.PlaceId, LP) end)
		if not ok then
			pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
		end
	end

	local function reconnectLoop(myId)
		while CFG.reconnectEnabled and ctx.alive() and ctx.state.reconnectId == myId do
			local mins = tonumber(CFG.reconnectInterval) or 5
			if mins <= 0 then mins = 5 end
			local total = mins * 60
			local t0 = os.clock()
			while os.clock() - t0 < total do
				if not CFG.reconnectEnabled or ctx.state.reconnectId ~= myId or not ctx.alive() then
					ctx.state.reconnectRemaining = nil; return
				end
				local rem = math.ceil(total - (os.clock() - t0))
				ctx.state.reconnectRemaining = rem
				setStatus(("Reconnect: %d dtk lagi"):format(rem))
				task.wait(1)
			end
			if CFG.reconnectEnabled and ctx.state.reconnectId == myId then
				setStatus("Reconnect: rejoin...")
				doReconnect()
				return -- instance ini bakal ilang setelah teleport
			end
		end
	end

	function ctx.startReconnect()
		ctx.state.reconnectId = (ctx.state.reconnectId or 0) + 1
		local myId = ctx.state.reconnectId
		task.spawn(function() reconnectLoop(myId) end)

		-- Listener DISCONNECT: rejoin pas kena error/kick/server shutdown.
		-- ErrorMessageChanged nyala pas dialog error/disconnect muncul.
		-- Slot global biar ga numpuk antar-reload (disconnect yg lama dulu).
		if _G.__AH_ReconnectDC then pcall(function() _G.__AH_ReconnectDC:Disconnect() end) end
		pcall(function()
			local GuiService = game:GetService("GuiService")
			_G.__AH_ReconnectDC = GuiService.ErrorMessageChanged:Connect(function()
				if CFG.reconnectEnabled then
					setStatus("Reconnect: disconnect kedetect, rejoin...")
					task.wait(1)
					doReconnect()
				end
			end)
		end)
	end
end
]=],
	["modules/misc/esp_inventory.lua"] = [=[
--[[ esp_inventory.lua — ESP Base Weight di INVENTORY (Pet Items).
     Nempel label kecil "Base X.XX KG" di tiap slot pet di backpack GUI,
     jadi pas buka inventory langsung keliatan BaseWeight tiap pet.
     Mapping: slot.ToolName.Text == Tool.Name -> Tool.PET_UUID ->
              PetData.BaseWeight (dari DataService).
     Toggle: CFG.espInvEnabled. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	local GRID_PATH   = { "BackpackGui", "Backpack", "Inventory", "ScrollingFrame", "UIGridFrame" }
	local HOTBAR_PATH = { "BackpackGui", "Backpack", "Hotbar" }
	local LBL_NAME    = "AH_BaseW" -- label yg kita tempel di slot

	local function byPath(path)
		local n = LP:FindFirstChild("PlayerGui")
		for _, seg in ipairs(path) do
			if not n then return nil end
			n = n:FindFirstChild(seg)
		end
		return n
	end
	-- container slot pet: grid inventory + hotbar (bar bawah, termasuk pet yg dipegang).
	local function containers()
		local out = {}
		local g = byPath(GRID_PATH);   if g then out[#out + 1] = g end
		local h = byPath(HOTBAR_PATH); if h then out[#out + 1] = h end
		return out
	end

	-- map Tool.Name -> {base, level} (cuma pet). Dibangun tiap refresh (murah).
	local function buildWeightMap()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local byUuid = {}
		for uuid, v in pairs(inv) do
			local pd = v.PetData or {}
			if pd.BaseWeight then byUuid[uuid] = { base = pd.BaseWeight, level = pd.Level or 0 } end
		end
		local byName = {}
		local function scan(where)
			if not where then return end
			for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("ItemType") == "Pet" then
					local uuid = t:GetAttribute("PET_UUID")
					local e = uuid and byUuid[uuid]
					if e and byName[t.Name] == nil then byName[t.Name] = e end
				end
			end
		end
		scan(LP.Character)
		scan(LP:FindFirstChildOfClass("Backpack"))
		return byName
	end

	-- Game: Weight = BaseWeight * (1 + 0.1*Level). MAX_LEVEL = umur 500.
	-- Berat "dasar" (level dasar) yg biasa dilihat = BaseWeight * 1.1, di-floor
	-- 1 desimal — persis game (5.5 base -> 6.0, 5.6 -> 6.1). Max = base*(1+0.1*500).
	local WEIGHT_MULT = 1.1
	local MAX_LEVEL   = 500
	local function floor1(n) return math.floor(n * 10) / 10 end
	local function baseKG(bw) return floor1(bw * WEIGHT_MULT) end
	local function maxKG(bw)  return floor1(bw * (1 + 0.1 * MAX_LEVEL)) end

	-- teks label sesuai mode CFG.espInvMode ("base" / "age" / "max").
	local function labelText(e)
		local base = baseKG(e.base)
		local mode = ctx.CFG.espInvMode
		if mode == "max" then
			return ("%.1f \u{2192} %.1f KG"):format(base, maxKG(e.base))
		elseif mode == "base" then
			return ("%.1f KG"):format(base)
		end
		return ("%.1f KG A%d"):format(base, e.level or 0)
	end

	-- tempel/refresh label di slot; hapus dari slot non-pet.
	local function setLabel(slot, e)
		local lbl = slot:FindFirstChild(LBL_NAME)
		if not e then
			if lbl then lbl:Destroy() end
			return
		end
		if not lbl then
			lbl = Instance.new("TextLabel")
			lbl.Name = LBL_NAME
			lbl.AnchorPoint = Vector2.new(0.5, 1)
			lbl.Position = UDim2.new(0.5, 0, 1, 0)
			lbl.Size = UDim2.new(1, 0, 0, 15)
			lbl.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
			lbl.BackgroundTransparency = 0.15
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 11
			lbl.TextScaled = true -- auto-fit biar muat di slot sempit
			lbl.TextColor3 = Color3.fromRGB(255, 214, 92) -- gold, senada tema
			lbl.TextStrokeTransparency = 0.5
			lbl.ZIndex = 20
			lbl.RichText = false
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = lbl
			local con = Instance.new("UITextSizeConstraint")
			con.MaxTextSize = 12
			con.Parent = lbl
			lbl.Parent = slot
		end
		lbl.Text = labelText(e)
	end

	local function clearAll()
		for _, c in ipairs(containers()) do
			for _, slot in ipairs(c:GetChildren()) do
				if slot:IsA("GuiButton") then
					local lbl = slot:FindFirstChild(LBL_NAME)
					if lbl then lbl:Destroy() end
				end
			end
		end
	end

	local function update()
		local cs = containers()
		if #cs == 0 then return end
		local byName = buildWeightMap()
		for _, c in ipairs(cs) do
			for _, slot in ipairs(c:GetChildren()) do
				if slot:IsA("GuiButton") then
					local tn = slot:FindFirstChild("ToolName")
					local name = tn and tn:IsA("TextLabel") and tn.Text or nil
					setLabel(slot, name and byName[name] or nil)
				end
			end
		end
	end

	local loopId = 0
	function ctx.startEspInv()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espInvEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			pcall(clearAll)
		end)
	end

	function ctx.stopEspInv()
		loopId = loopId + 1
		pcall(clearAll)
	end
end
]=],
	["modules/misc/esp_label.lua"] = [=[
--[[ esp.lua — label melayang (BillboardGui) di dunia 3D di atas tiap egg.
     Egg: nama egg + ISI-nya (pet yang bakal menetas + berat) dari
          SaveSlots.AllSlots.<slot>.SavedObjects.<uuid>.Data (Type/BaseWeight),
          fallback sisa waktu hatch / READY.
     Toggle: CFG.espEnabled. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.1 (bukan raw BaseWeight).
	local WEIGHT_MULT = 1.1

	local bbFolder
	local billboards = {} -- key -> { gui, lbl }
	local eggSlotKey  -- cache slot aktif yg nyimpen SavedObjects

	local function ensureFolder()
		if bbFolder and bbFolder.Parent then return bbFolder end
		bbFolder = Instance.new("Folder")
		bbFolder.Name = "AllegiaanESP"
		bbFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
		return bbFolder
	end

	local function partOf(model)
		if model:IsA("BasePart") then return model end
		if model.PrimaryPart then return model.PrimaryPart end
		for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end

	local function makeBB(key, adornee, offset)
		local bb = Instance.new("BillboardGui")
		bb.Name = "esp_" .. key
		bb.Adornee = adornee
		bb.Size = UDim2.fromOffset(240, 58)
		bb.StudsOffset = Vector3.new(0, offset or 2.5, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 600
		bb.LightInfluence = 0
		bb.ClipsDescendants = false
		bb.Parent = ensureFolder()

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 14
		lbl.RichText = true
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextStrokeTransparency = 0.2
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		lbl.TextYAlignment = Enum.TextYAlignment.Bottom
		lbl.Parent = bb

		local rec = { gui = bb, lbl = lbl }
		billboards[key] = rec
		return rec
	end

	local function acquire(key, adornee, offset)
		local rec = billboards[key]
		if (not rec) or rec.gui.Adornee ~= adornee or not rec.gui.Parent then
			if rec then rec.gui:Destroy(); billboards[key] = nil end
			rec = makeBB(key, adornee, offset)
		end
		return rec
	end

	local function fmtTime(sec)
		sec = math.max(0, math.floor(sec))
		local m = math.floor(sec / 60)
		local s = sec % 60
		if m >= 60 then local h = math.floor(m / 60); m = m % 60; return string.format("%dh %dm", h, m) end
		return string.format("%dm %02ds", m, s)
	end

	-- Data isi egg (pet yg bakal menetas + berat) dari SavedObjects by uuid.
	local function eggDataOf(uuid)
		if not uuid then return nil end
		local ok, d = pcall(function() return DataService:GetData() end)
		local slots = ok and d and d.SaveSlots and d.SaveSlots.AllSlots
		if not slots then return nil end
		-- coba slot yg di-cache dulu
		local s = eggSlotKey and slots[eggSlotKey]
		if s and s.SavedObjects and s.SavedObjects[uuid] then return s.SavedObjects[uuid].Data end
		-- scan semua slot
		for sn, slot in pairs(slots) do
			if type(slot) == "table" and slot.SavedObjects and slot.SavedObjects[uuid] then
				eggSlotKey = sn
				return slot.SavedObjects[uuid].Data
			end
		end
		return nil
	end

	local function eggNameFallback(e)
		local n = e:GetAttribute("EggName")
		if not n or n == "" then
			for _, c in ipairs(e:GetChildren()) do if c:IsA("Model") then n = c.Name; break end end
		end
		return n or "Egg"
	end

	local function update()
		local seen = {}

		-- ===== EGG (nama + isi: pet + berat) =====
		local farm; pcall(function() farm = require(RS.Modules.GetFarm)(LP) end)
		if farm then
			for _, e in ipairs(farm:GetDescendants()) do
				if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then
					local adornee = e:FindFirstChild("PetEgg") or partOf(e)
					if adornee then
						local uuid = e:GetAttribute("OBJECT_UUID")
						local key = "egg_" .. tostring(uuid or e:GetDebugId())
						seen[key] = true
						local rec = acquire(key, adornee, 3)
						local data = eggDataOf(uuid)
						local lines = { ("<font color='#00E676'>%s</font>"):format(eggNameFallback(e)) }
						if data and data.Type then
							lines[#lines + 1] = ("<font color='#FFEB3B'>%s</font>"):format(tostring(data.Type))
							local w = tonumber(data.BaseWeight)
							if w then lines[#lines + 1] = ("<font color='#7CF0FF'>%.2f KG</font>"):format(w * WEIGHT_MULT) end
						end
						local t = tonumber(e:GetAttribute("TimeToHatch")) or (data and tonumber(data.TimeToHatch)) or 0
						if t > 0 then
							lines[#lines + 1] = ("<font color='#FFB450'>\u{23F1} %s</font>"):format(fmtTime(t))
						elseif not (data and data.Type) then
							lines[#lines + 1] = "<font color='#00E676'>READY</font>"
						end
						rec.lbl.Text = table.concat(lines, "\n")
					end
				end
			end
		end

		for key, rec in pairs(billboards) do
			if not seen[key] then rec.gui:Destroy(); billboards[key] = nil end
		end
	end

	local function clearAll()
		for _, rec in pairs(billboards) do pcall(function() rec.gui:Destroy() end) end
		billboards = {}
		if bbFolder then pcall(function() bbFolder:Destroy() end); bbFolder = nil end
	end

	local loopId = 0
	function ctx.startEsp()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			clearAll()
		end)
	end

	function ctx.stopEsp()
		loopId = loopId + 1
		clearAll()
	end
end
]=],
	["modules/misc/perf_mods.lua"] = [=[
--[[ perf_mods.lua — Performance / Graphics Optimization.
     - Hide My/Other Garden Plants : sembunyiin plant (LocalTransparencyModifier) buat FPS.
     - Auto Remove Spider Web FX    : hapus particle/trail/beam efek web terus-menerus.
     - Performance Mode (off/low/extreme) : matiin shadow & (extreme) semua efek partikel.
     - Disable 3D Rendering          : RunService:Set3dRenderingEnabled(false).
     Toggle: CFG.hideMyPlants / hideOtherPlants / autoRemoveWebFx / perfMode / disable3d. ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local LP  = ctx.LP
	local CFG = ctx.CFG

	local function myFarm()
		local f; pcall(function() f = require(RS.Modules.GetFarm)(LP) end)
		return f
	end
	-- iterasi Plants_Physical: which = "mine" / "other"
	local function eachPlantContainer(which, fn)
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return end
		local mine = myFarm()
		for _, g in ipairs(Farm:GetChildren()) do
			local isMine = (g == mine)
			if (which == "mine" and isMine) or (which == "other" and not isMine) then
				local imp = g:FindFirstChild("Important")
				local pp = imp and imp:FindFirstChild("Plants_Physical")
				if pp then fn(pp) end
			end
		end
	end

	------------------------------------------------------------------- hide plants
	local function applyHide(which, hidden)
		eachPlantContainer(which, function(pp)
			for _, d in ipairs(pp:GetDescendants()) do
				if d:IsA("BasePart") then d.LocalTransparencyModifier = hidden and 1 or 0 end
			end
		end)
	end

	local hideConn
	local function hideLoopActive() return CFG.hideMyPlants or CFG.hideOtherPlants end
	local function ensureHideLoop()
		if hideConn then return end
		hideConn = task.spawn(function()
			while ctx.alive() and hideLoopActive() do
				if CFG.hideMyPlants then applyHide("mine", true) end
				if CFG.hideOtherPlants then applyHide("other", true) end
				task.wait(1) -- catch plant baru; ga perlu tiap frame
			end
			hideConn = nil
		end)
	end
	function ctx.setHidePlants(which, v)
		if which == "mine" then CFG.hideMyPlants = v else CFG.hideOtherPlants = v end
		if v then ensureHideLoop() else applyHide(which, false) end
	end

	------------------------------------------------------------------- spider web FX
	local WEB_MATCH = { "web", "spider", "cobweb" }
	local WEB_CLASS = { ParticleEmitter = true, Trail = true, Beam = true, Decal = true, Texture = true }
	local function isWeb(d)
		if not WEB_CLASS[d.ClassName] then return false end
		local n = d.Name:lower()
		for _, m in ipairs(WEB_MATCH) do if n:find(m) then return true end end
		return false
	end
	local webConn
	function ctx.setAutoRemoveWeb(v)
		CFG.autoRemoveWebFx = v
		if v then
			if webConn then return end
			webConn = task.spawn(function()
				while ctx.alive() and CFG.autoRemoveWebFx do
					for _, d in ipairs(workspace:GetDescendants()) do
						if isWeb(d) then pcall(function() d:Destroy() end) end
					end
					task.wait(1)
				end
				webConn = nil
			end)
		end
	end

	------------------------------------------------------------------- performance mode
	local FX_CLASS = { ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true, Sparkles = true, Explosion = true }
	local function setAllFxEnabled(on)
		for _, d in ipairs(workspace:GetDescendants()) do
			if FX_CLASS[d.ClassName] then pcall(function() d.Enabled = on end) end
		end
	end
	local pmConn
	local function stopPmLoop() if pmConn then task.cancel(pmConn); pmConn = nil end end
	function ctx.setPerfMode(mode)
		CFG.perfMode = mode
		stopPmLoop()
		if mode == "off" then
			pcall(function() Lighting.GlobalShadows = true end)
			setAllFxEnabled(true)
		elseif mode == "low" then
			pcall(function() Lighting.GlobalShadows = false end)
		elseif mode == "extreme" then
			pcall(function() Lighting.GlobalShadows = false end)
			-- terus-terusan matiin efek partikel (extreme FPS)
			pmConn = task.spawn(function()
				while ctx.alive() and CFG.perfMode == "extreme" do
					setAllFxEnabled(false)
					task.wait(1.5)
				end
			end)
		end
	end
	function ctx.getPerfModeOptions()
		return { { name = "off", display = "Off" }, { name = "low", display = "Low" }, { name = "extreme", display = "Extreme" } }
	end

	------------------------------------------------------------------- disable 3D
	function ctx.setDisable3d(v)
		CFG.disable3d = v
		ctx.elevate()
		pcall(function() RunService:Set3dRenderingEnabled(not v) end)
	end
end
]=],
	["modules/misc/player_mods.lua"] = [=[
--[[ player_mods.lua — utilitas Player: Noclip, Walk Speed, Infinity Jump.
     Semua toggle-able & guarded (auto re-apply tiap frame selama aktif).
     Toggle: CFG.noclipEnabled / CFG.walkSpeedEnabled (+CFG.walkSpeed) / CFG.infJumpEnabled. ]]
return function(ctx)
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local DEFAULT_WS = 16

	local function char() return LP.Character end
	local function hum()
		local c = char()
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	------------------------------------------------------------------- NOCLIP
	local noclipConn
	local function startNoclip()
		if noclipConn then return end
		noclipConn = RunService.Stepped:Connect(function()
			local c = char()
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end)
	end
	local function stopNoclip()
		if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	end
	function ctx.setNoclip(v)
		CFG.noclipEnabled = v
		if v then startNoclip() else stopNoclip() end
	end

	------------------------------------------------------------------- WALK SPEED
	local wsConn
	local function startWS()
		if wsConn then return end
		wsConn = RunService.Stepped:Connect(function()
			local h = hum()
			if h then
				local target = tonumber(CFG.walkSpeed) or DEFAULT_WS
				if h.WalkSpeed ~= target then h.WalkSpeed = target end
			end
		end)
	end
	local function stopWS()
		if wsConn then wsConn:Disconnect(); wsConn = nil end
		local h = hum()
		if h then h.WalkSpeed = DEFAULT_WS end
	end
	function ctx.setWalkSpeed(v)
		CFG.walkSpeedEnabled = v
		if v then startWS() else stopWS() end
	end
	-- dipanggil pas nilai input berubah (biar langsung kepakai kalau lagi ON)
	function ctx.applyWalkSpeed()
		if not CFG.walkSpeedEnabled then return end
		local h = hum()
		if h then h.WalkSpeed = tonumber(CFG.walkSpeed) or DEFAULT_WS end
	end

	------------------------------------------------------------------- INFINITY JUMP
	local jumpConn
	local function startInfJump()
		if jumpConn then return end
		jumpConn = UIS.JumpRequest:Connect(function()
			local h = hum()
			if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
		end)
	end
	local function stopInfJump()
		if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
	end
	function ctx.setInfJump(v)
		CFG.infJumpEnabled = v
		if v then startInfJump() else stopInfJump() end
	end
end
]=],
	["modules/mutation/automation_mutation_machine.lua"] = [=[
--[[ mutation.lua — logika mesin mutasi pet otomatis (garden). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")
	local TimeHelper  = require(RS.Modules.TimeHelper)
	local PetMutationMachineService_RE = RS:WaitForChild("GameEvents").PetMutationMachineService_RE

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local function cleanUuid(u)
		if not u then return "" end
		return tostring(u):lower():gsub("[{}]", "")
	end

	local function hasTargetMutation(pd, targetMutations)
		if not pd then return false end
		local mut = pd.MutationType
		local display = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mut) or tostring(mut or "None")
		return targetMutations[display] == true
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

	-- Helper untuk memastikan tim pet terpasang 100% dengan benar (dengan retry loop)
	local function ensureEquippedTeam(targetTeamSet, targetPetUuid)
		local targetActive = {}
		if targetPetUuid then
			targetActive[cleanUuid(targetPetUuid)] = true
		end
		for u, _ in pairs(targetTeamSet) do
			targetActive[cleanUuid(u)] = true
		end

		for attempt = 1, 3 do
			local ok, d = pcall(function() return DataService:GetData() end)
			if not ok or not d or not d.PetsData then break end
			local eq = d.PetsData.EquippedPets or {}
			
			local localEq = {}
			for _, uuid in ipairs(eq) do
				localEq[cleanUuid(uuid)] = true
			end

			-- 1. Lepas pet yang tidak diijinkan berada di garden
			local unequippedAny = false
			for _, uuid in ipairs(eq) do
				local cu = cleanUuid(uuid)
				if not targetActive[cu] then
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					unequippedAny = true
					task.wait(0.1)
				end
			end

			-- 2. Pasang target pet (jika leveling)
			local equippedAny = false
			if targetPetUuid and not localEq[cleanUuid(targetPetUuid)] then
				local pos = getPos(targetPetUuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", targetPetUuid, CFrame.new(pos)) end)
					equippedAny = true
					task.wait(0.1)
				end
			end

			-- 3. Pasang sisa anggota team yang belum terpasang
			for uuid, _ in pairs(targetTeamSet) do
				local cu = cleanUuid(uuid)
				if not localEq[cu] then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						equippedAny = true
						task.wait(0.1)
					end
				end
			end

			-- Jika tidak ada aktivitas unequip/equip lagi, berarti kebun sudah sinkron
			if not unequippedAny and not equippedAny then
				break
			end
			task.wait(0.3)
		end

		-- Verifikasi kelengkapan: SEMUA anggota target harus benar-benar ke-equip (no miss).
		local ok, d = pcall(function() return DataService:GetData() end)
		local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
		local eqSet = {}
		for _, uuid in ipairs(eq) do eqSet[cleanUuid(uuid)] = true end
		for cu in pairs(targetActive) do
			if not eqSet[cu] then return false end
		end
		return true
	end

	ctx.state.mutationStatus = "Idle"
	ctx.state.mutationPhase = "Idle"

	-- Mendapatkan ringkasan statistik mutation untuk UI
	function ctx.getMutationSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local machine = ok and d and d.PetMutationMachine or {}

		local expCount = 0
		for _ in pairs(CFG.mutationExpTeam) do expCount = expCount + 1 end

		local boostCount = 0
		for _ in pairs(CFG.mutationBoostTeam) do boostCount = boostCount + 1 end

		local phoenixCount = 0
		for _ in pairs(CFG.mutationPhoenixTeam) do phoenixCount = phoenixCount + 1 end

		local typesList = {}
		for k in pairs(CFG.mutationTargetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"

		local mutsList = {}
		for k in pairs(CFG.mutationTargetMutations) do table.insert(mutsList, k) end
		table.sort(mutsList)
		local mutsStr = #mutsList > 0 and table.concat(mutsList, ", ") or "None"

		local targetAge = CFG.mutationTargetAge or 50

		-- Info mesin
		local machineStr = "Empty"
		if machine.SubmittedPet then
			local pt = machine.SubmittedPet.PetType or "?"
			local mut = machine.SubmittedPet.PetData and machine.SubmittedPet.PetData.MutationType or "Normal"
			local mutName = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mut) or mut
			machineStr = string.format("%s | %s", pt, mutName)
			if machine.PetReady then
				machineStr = machineStr .. " [Ready]"
			elseif machine.IsRunning or (machine.TimeLeft and machine.TimeLeft > 0) then
				local v2 = TimeHelper:GenerateColonFormatFromTime(machine.TimeLeft) or "00:00"
				machineStr = machineStr .. string.format(" [CD: %s]", v2)
			end
		end

		local readyCount = 0
		local doneCount = 0

		for _, v in pairs(inv) do
			local pt = v.PetType
			if CFG.mutationTargetTypes[pt] then
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				if not isFav then
					if hasTargetMutation(pd, CFG.mutationTargetMutations) then
						doneCount = doneCount + 1
					else
						-- Belum punya mutasi target = masih perlu diproses (bakal di-leveling
						-- dulu kalau age belum cukup, lalu di-submit). Hitung semua, lepas dari level.
						readyCount = readyCount + 1
					end
				end
			end
		end

		return {
			status = CFG.mutationEnabled and "ACTIVE" or "STOPPED",
			phase = ctx.state.mutationPhase or "Idle",
			expCount = expCount,
			boostCount = boostCount,
			phoenixCount = phoenixCount,
			types = typesStr,
			mutations = mutsStr,
			targetAge = targetAge,
			machine = machineStr,
			readyCount = readyCount,
			doneCount = doneCount,
		}
	end

	local function checkMutation()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		local machine = d.PetMutationMachine
		if not petsData or not machine then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local expTeam = CFG.mutationExpTeam or {}
		local boostTeam = CFG.mutationBoostTeam or {}
		local phoenixTeam = CFG.mutationPhoenixTeam or {}
		local targetTypes = CFG.mutationTargetTypes or {}
		local targetMutations = CFG.mutationTargetMutations or {}
		local targetAge = CFG.mutationTargetAge or 50
		local delayClaim = CFG.mutationDelayAutoClaim or 0.5

		-- CATATAN: passing team ASLI (uuid ber-kurawal) ke ensureEquippedTeam. cleanUuid dipakai
		-- HANYA buat matching di dalam fungsi; EquipPet butuh uuid format asli (dengan {}).

		-- A. DETEKSI APAKAH PET READY UNTUK DICLAIM
		if machine.PetReady then
			-- Validasi Phoenix team LENGKAP dulu (no miss) sebelum claim.
			if not ensureEquippedTeam(phoenixTeam) then
				ctx.state.mutationPhase = "Menunggu Phoenix Team lengkap..."
				return
			end
			ctx.state.mutationPhase = "Claiming Pet"

			-- Tunggu delay klaim
			task.wait(delayClaim)
			
			-- 1. Ambil snapshot mutasi pet di inventory sebelum klaim
			local preSnapshot = {}
			local okSnap, snapD = pcall(function() return DataService:GetData() end)
			if okSnap and snapD and snapD.PetsData then
				local invD = snapD.PetsData.PetInventory and snapD.PetsData.PetInventory.Data or {}
				for u, v in pairs(invD) do
					if targetTypes[v.PetType] then
						preSnapshot[u] = v.PetData and v.PetData.MutationType or "Normal"
					end
				end
			end

			-- Kirim remote klaim
			pcall(function() PetMutationMachineService_RE:FireServer("ClaimMutatedPet") end)
			task.wait(1.0)

			-- 2. Tentukan pet hasil klaim.
			-- Sumber UTAMA = machine.SubmittedPet (pet yg barusan diproses) -> reliable, ga
			-- jadi "Unknown" walau data inventory telat sync. Diff inventory dipakai buat
			-- refine (mis. dapat mutasi hasil terbaru) kalau ketemu.
			local sp = machine.SubmittedPet or {}
			local claimedPetType = sp.PetType or "Unknown"
			local outcomeMutation = (sp.PetData and sp.PetData.MutationType) or "Normal"

			local ok3, d3 = pcall(function() return DataService:GetData() end)
			if ok3 and d3 and d3.PetsData then
				local newInv = d3.PetsData.PetInventory and d3.PetsData.PetInventory.Data or {}
				for u, v in pairs(newInv) do
					if targetTypes[v.PetType] then
						local pd = v.PetData or {}
						local mut = pd.MutationType or "Normal"
						if not preSnapshot[u] or preSnapshot[u] ~= mut then
							claimedPetType = v.PetType
							outcomeMutation = mut
							break
						end
					end
				end
			end
			local isMatched = hasTargetMutation({ MutationType = outcomeMutation }, targetMutations)

			-- Durasi proses: dari submit sampai klaim
			local duration = 0
			if ctx.state.mutationSubmitTime then
				duration = os.time() - ctx.state.mutationSubmitTime
				ctx.state.mutationSubmitTime = nil
			end

			-- Kirim Webhook Claimed
			task.spawn(function()
				local WebhookMut = ctx.webhookMutation
				if WebhookMut then
					pcall(function() WebhookMut.sendClaimed(ctx, claimedPetType, outcomeMutation, isMatched, duration) end)
				end
			end)

			if isMatched then
				-- Pet ini dapat mutasi target. JANGAN matikan automation — lanjut proses
				-- pet ready berikutnya (section D sudah auto-skip pet yg sudah hasTargetMutation,
				-- jadi pet ini ga bakal diproses ulang).
				ctx.state.mutationPhase = "Matched! Lanjut next target..."
			else
				ctx.state.mutationPhase = "Non-target, lanjut..."
			end
			return
		end

		-- B. DETEKSI APAKAH MESIN SEDANG BERJALAN
		if machine.IsRunning or (machine.TimeLeft and machine.TimeLeft > 0) then
			-- Validasi Boost team LENGKAP dulu (no miss) baru dianggap boosting.
			if ensureEquippedTeam(boostTeam) then
				ctx.state.mutationPhase = "Boosting Machine"
			else
				ctx.state.mutationPhase = "Menunggu Boost Team lengkap..."
			end
			return
		end

		-- C. DETEKSI PET SUDAH DI-SUBMIT TETAPI BELUM DI-START
		if machine.SubmittedPet and not machine.IsRunning then
			ctx.state.mutationPhase = "Starting Machine"
			pcall(function() PetMutationMachineService_RE:FireServer("StartMachine") end)
			task.wait(0.5)
			return
		end

		-- D. DETEKSI MESIN KOSONG: Cari pet dari inventory untuk dimasukkan ke mesin
		if not machine.SubmittedPet then
			-- Cari pet target yang siap (level >= targetAge)
			local candidateUuid, candidateType
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				-- Hanya pet tipe target, dengan level >= targetAge, bukan favorite, dan belum memiliki mutasi target
				if targetTypes[pt] and lvl >= targetAge and not isFav and not hasTargetMutation(pd, targetMutations) then
					candidateUuid = uuid
					candidateType = pt
					break
				end
			end

			-- Jika ada pet yang siap, submit ke mesin!
			if candidateUuid then
				ctx.state.mutationPhase = "Submitting Target"
				
				-- 1. Pastikan dicopot dari garden dulu sebelum di-submit
				pcall(function() PetsService:FireServer("UnequipPet", candidateUuid) end)
				task.wait(0.25)

				-- 2. Cari tool pet tersebut di Backpack atau Character
				local targetTool
				for _, item in ipairs(LP.Backpack:GetChildren()) do
					if item:IsA("Tool") and cleanUuid(item:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
						targetTool = item
						break
					end
				end
				if not targetTool and LP.Character then
					for _, item in ipairs(LP.Character:GetChildren()) do
						if item:IsA("Tool") and cleanUuid(item:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
							targetTool = item
							break
						end
					end
				end

				-- 3. Equip pet ke tangan lalu VERIFIKASI beneran dipegang sebelum submit.
				--    Cegah submit KOSONG kalau equip gagal/ke-race (mesin nerima submit hampa
				--    -> langsung "ready" tanpa isi). Kalau gagal pegang, JANGAN submit.
				if targetTool then
					local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
					local held
					for _ = 1, 4 do
						pcall(function()
							if hum then hum:EquipTool(targetTool) else targetTool.Parent = LP.Character end
						end)
						task.wait(0.35)
						local h = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
						if h and cleanUuid(h:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
							held = h
							break
						end
					end

					if held then
						pcall(function() PetMutationMachineService_RE:FireServer("SubmitHeldPet") end)
						-- Duration: dari mulai EXP leveling kalau pet ini sempat di-level, else dari submit
						ctx.state.mutationStartTime = ctx.state.mutationStartTime or {}
						ctx.state.mutationSubmitTime = ctx.state.mutationStartTime[candidateUuid] or os.time()
						ctx.state.mutationStartTime[candidateUuid] = nil
						task.wait(0.5)

						-- Kirim Webhook Submitted
						task.spawn(function()
							local WebhookMut = ctx.webhookMutation
							if WebhookMut then
								local petLevel = inv[candidateUuid] and inv[candidateUuid].PetData and inv[candidateUuid].PetData.Level or 50
								pcall(function() WebhookMut.sendSubmitted(ctx, candidateType, petLevel) end)
							end
						end)

						-- Jalankan mesin langsung di detik yang sama
						pcall(function() PetMutationMachineService_RE:FireServer("StartMachine") end)
						task.wait(0.3)
					else
						ctx.state.mutationPhase = "Gagal pegang pet, retry..."
					end
				end
				return
			end

			-- Jika tidak ada pet yang siap, cari pet target yang levelnya kurang untuk kita LEVELING!
			local levelUuid, levelType, levelLvl
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				if targetTypes[pt] and lvl < targetAge and not isFav and not hasTargetMutation(pd, targetMutations) then
					-- Prioritaskan level yang paling tinggi tapi masih di bawah targetAge agar cepat jadi!
					if not levelLvl or lvl > levelLvl then
						levelUuid = uuid
						levelType = pt
						levelLvl = lvl
					end
				end
			end

			-- Jika ada pet yang perlu di-leveling:
			if levelUuid then
				-- Validasi EXP team + target pet LENGKAP dulu (no miss).
				if ensureEquippedTeam(expTeam, levelUuid) then
					ctx.state.mutationPhase = "Leveling Target"
					-- Catat mulai proses EXP leveling pet ini (buat Duration total)
					ctx.state.mutationStartTime = ctx.state.mutationStartTime or {}
					if not ctx.state.mutationStartTime[levelUuid] then
						ctx.state.mutationStartTime[levelUuid] = os.time()
					end
				else
					ctx.state.mutationPhase = "Menunggu EXP Team lengkap..."
				end
				return
			end

			-- Jika sama sekali tidak ada pet kandidat
			ctx.state.mutationPhase = "Idle (No Targets)"
		end
	end

	local function mutationLoop()
		ctx.state.mutationId = (ctx.state.mutationId or 0) + 1
		local myId = ctx.state.mutationId
		ctx.elevate()

		-- Kirim Webhook Enabled
		task.spawn(function()
			local WebhookMut = ctx.webhookMutation
			if WebhookMut then
				local expTeamList = {}
				local boostTeamList = {}
				local phoenixTeamList = {}

				local okData, d = pcall(function() return DataService:GetData() end)
				if okData and d and d.PetsData then
					local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

					-- 1. EXP Team
					for uuid, _ in pairs(CFG.mutationExpTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(expTeamList, pInfo.PetType) end
					end

					-- 2. Boost Team
					for uuid, _ in pairs(CFG.mutationBoostTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(boostTeamList, pInfo.PetType) end
					end

					-- 3. Phoenix Team
					for uuid, _ in pairs(CFG.mutationPhoenixTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(phoenixTeamList, pInfo.PetType) end
					end
				end

				pcall(function() 
					WebhookMut.sendEnabled(ctx, CFG.mutationTargetTypes, CFG.mutationTargetMutations, CFG.mutationTargetAge, expTeamList, boostTeamList, phoenixTeamList)
				end)
			end
		end)

		while CFG.mutationEnabled and ctx.alive() and ctx.state.mutationId == myId do
			pcall(checkMutation)
			task.wait(3.0)
		end
		ctx.state.mutationStatus = "Idle"
		ctx.state.mutationPhase = "Idle"
	end

	function ctx.startMutation()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		task.spawn(mutationLoop)
	end

	function ctx.stopMutation()
		ctx.state.mutationId = (ctx.state.mutationId or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Mutation") end
	end
end
]=],
	["modules/mutation/automation_mutation.lua"] = [=[
--[[ cleanse.lua — Automation Cleanse Mutation (mutasi via aura + auto cleanse).
     - Pet Team for Mutation (aura pemberi mutasi) tetap di garden.
     - Pet target (Pet Types) dirotasi di garden (max = Max Pets in Garden) buat kena aura.
     - Target dapat mutasi di "Keep" -> disimpan (dikeluarkan dari garden).
     - Target dapat mutasi LAIN -> di-cleanse (Cleansing Pet Shard) biar coba lagi.
     Cleanse: pegang shard lalu PetShardService_RE:FireServer("ApplyShard", petModel). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetShardService = RS:WaitForChild("GameEvents"):WaitForChild("PetShardService_RE")
	local function setStatus(s) ctx.setStatus(s) end

	local function mutName(code)
		if ctx.reg and ctx.reg.mutDisplay then return ctx.reg.mutDisplay(code) end
		return tostring(code)
	end
	local function cleanUuid(u) return (tostring(u):gsub("[{}]", "")) end

	----------------------------------------------------------------- placement
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
		local center = farmCenter(); if not center then return nil end
		local i = slotOf[uuid]
		local col, row = i % GRID_COLS, math.floor(i / GRID_COLS)
		return center + Vector3.new((col - (GRID_COLS - 1) / 2) * GRID_SP, 0, (row - 1) * GRID_SP)
	end

	----------------------------------------------------------------- shard cleanse
	local function findShard()
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and (t:HasTag("PetShardTool") or tostring(t.Name):find("Cleansing Pet Shard")) then return t end
			end end
		end
		return nil
	end
	local function findPetModel(uuid)
		local pp = workspace:FindFirstChild("PetsPhysical")
		if not pp then return nil end
		for _, d in ipairs(pp:GetDescendants()) do
			if d.Name == uuid then return d end
		end
		return nil
	end
	-- Cleanse pet yang SUDAH equipped (model ada di garden).
	local function cleansePet(uuid)
		local model = findPetModel(uuid)
		if not model then return false, "model tidak ada" end
		local shard = findShard()
		if not shard then return false, "shard habis" end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return false, "no humanoid" end
		local held
		for _ = 1, 3 do
			pcall(function() hum:EquipTool(shard) end); task.wait(0.3)
			held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
			if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then break end
			shard = findShard(); if not shard then break end
		end
		if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then
			pcall(function() PetShardService:FireServer("ApplyShard", model) end)
			task.wait(0.4)
			return true
		end
		return false, "gagal pegang shard"
	end

	----------------------------------------------------------------- mutasi helpers
	local function hasMut(pd)
		local m = pd.MutationType
		if not m or m == "" or m == "Normal" or m == "m" then return false end
		return mutName(m) ~= "None"
	end
	local function isKept(pd)
		return hasMut(pd) and CFG.cleanseKeepMutations[mutName(pd.MutationType)] == true
	end

	ctx.state.cleansePhase = "Idle"

	-- Ringkasan status untuk UI
	function ctx.getCleanseSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamCount = 0
		for _ in pairs(CFG.cleanseTeamUuids or {}) do teamCount = teamCount + 1 end
		local typesList = {}
		for k in pairs(CFG.cleansePetTypes or {}) do typesList[#typesList + 1] = k end
		table.sort(typesList)
		local keepOrder = {}
		for k in pairs(CFG.cleanseKeepMutations or {}) do keepOrder[#keepOrder + 1] = k end
		table.sort(keepOrder)

		local ready, already = 0, {}
		for _, k in ipairs(keepOrder) do already[k] = 0 end
		for _, v in pairs(inv) do
			local pt = v.PetType
			if pt and CFG.cleansePetTypes[pt] then
				local pd = v.PetData or {}
				local disp = hasMut(pd) and mutName(pd.MutationType) or "None"
				if CFG.cleanseKeepMutations[disp] then
					already[disp] = (already[disp] or 0) + 1
				elseif not pd.IsFavorite then
					ready = ready + 1
				end
			end
		end

		return {
			status = CFG.cleanseEnabled and "ACTIVE" or "STOPPED",
			team = teamCount,
			types = #typesList > 0 and table.concat(typesList, ", ") or "None",
			keep = #keepOrder > 0 and table.concat(keepOrder, ", ") or "None",
			ready = ready,
			already = already,
			keepOrder = keepOrder,
			maxPets = CFG.cleanseMaxPets or 2,
			phase = ctx.state.cleansePhase or "Idle",
		}
	end

	----------------------------------------------------------------- loop utama
	local function checkCleanse()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return end
		local eq = d.PetsData.EquippedPets or {}
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamSet = CFG.cleanseTeamUuids or {}
		local targetTypes = CFG.cleansePetTypes or {}
		local maxPets = CFG.cleanseMaxPets or 2

		local localEq = {}
		for _, u in ipairs(eq) do localEq[cleanUuid(u)] = u end -- clean->original

		-- A. FIRST RUN: reset garden
		if ctx.state.cleanseFirstRun then
			ctx.state.cleanseFirstRun = false
			for _, uuid in ipairs(eq) do
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				localEq[cleanUuid(uuid)] = nil
				task.wait(0.1)
			end
		end

		-- B. Pasang team aura (persisten)
		for uuid in pairs(teamSet) do
			if not localEq[cleanUuid(uuid)] then
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[cleanUuid(uuid)] = uuid
					task.wait(0.1)
				end
			end
		end

		-- C. Proses pet target yang equipped
		local activeTargets = 0
		for cu, origUuid in pairs(localEq) do
			if not teamSet[origUuid] and not teamSet["{" .. cu .. "}"] then
				local pInfo = inv[origUuid] or inv["{" .. cu .. "}"]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				if pt and targetTypes[pt] then
					if pd.IsFavorite then
						-- Favorite -> JANGAN cleanse (lindungi mutasi). Keluarkan dari garden.
						ctx.state.cleansePhase = "Skip favorite (protected)"
						pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
						localEq[cu] = nil
						task.wait(0.1)
					elseif isKept(pd) then
						-- Harvest: mutasi bagus -> keluarkan dari garden (disimpan)
						ctx.state.cleansePhase = "Harvest " .. mutName(pd.MutationType)
						pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
						localEq[cu] = nil
						task.wait(0.15)

						-- Webhook: mutasi didapat
						if ctx.webhookCleanse then
							local gotType, gotMut, gotAge = pt, mutName(pd.MutationType), pd.Level or 0
							local remains = 0
							for _, iv in pairs(inv) do
								local ipt = iv.PetType
								if ipt and targetTypes[ipt] then
									local ipd = iv.PetData or {}
									if not ipd.IsFavorite and not isKept(ipd) then remains = remains + 1 end
								end
							end
							task.spawn(function()
								pcall(function() ctx.webhookCleanse.sendObtained(ctx, gotType, gotMut, gotAge, remains) end)
							end)
						end
					elseif hasMut(pd) then
						-- Mutasi salah -> cleanse (tetap di garden buat coba lagi)
						ctx.state.cleansePhase = "Cleanse " .. mutName(pd.MutationType)
						cleansePet(origUuid)
						activeTargets = activeTargets + 1
					else
						-- Normal -> lagi nunggu aura
						activeTargets = activeTargets + 1
					end
				elseif not (pt and targetTypes[pt]) then
					-- pet lain (bukan team, bukan target) -> keluarkan
					pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
					localEq[cu] = nil
					task.wait(0.1)
				end
			end
		end

		-- D. Isi garden dengan target baru sampai maxPets (belum punya mutasi keep)
		local needed = maxPets - activeTargets
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				if not localEq[cleanUuid(uuid)] and pt and targetTypes[pt] and not pd.IsFavorite and not isKept(pd) then
					pool[#pool + 1] = uuid
				end
			end
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i])
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i], CFrame.new(pos)) end)
					localEq[cleanUuid(pool[i])] = pool[i]
					activeTargets = activeTargets + 1
					task.wait(0.15)
				end
			end
		end

		ctx.state.cleansePhase = string.format("Farming: %d/%d target", activeTargets, maxPets)
	end

	local function cleanseLoop()
		ctx.state.cleanseId = (ctx.state.cleanseId or 0) + 1
		local myId = ctx.state.cleanseId
		ctx.elevate()
		ctx.state.cleanseFirstRun = true

		while CFG.cleanseEnabled and ctx.alive() and ctx.state.cleanseId == myId do
			if not next(CFG.cleansePetTypes or {}) then
				setStatus("Cleanse: pilih Pet Types dulu")
				task.wait(3)
			else
				pcall(checkCleanse)
				setStatus("Cleanse " .. tostring(ctx.state.cleansePhase))
				task.wait(3)
			end
		end
		ctx.state.cleansePhase = "Idle"
	end

	function ctx.startCleanse()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(cleanseLoop) -- loop set firstRun=true -> reset garden + equip team aura
	end

	function ctx.stopCleanse()
		ctx.state.cleanseId = (ctx.state.cleanseId or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Auto Mutation") end
	end
end
]=],
	["modules/mutation/cleanse_webhook.lua"] = [=[
--[[ webhook/cleanse.lua — webhook Automation Mutation (aura + cleanse).
     Dikirim saat pet target dapat mutasi "keep" (harvest). ]]
local cleanseWebhook = {}

function cleanseWebhook.sendObtained(ctx, petType, mutation, age, remainsQueue)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local payload = {
		embeds = {
			{
				title = "\240\159\140\177 Growth \226\128\162 Mutation",
				color = 3066993,
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false,
					},
					{
						name = "Mutation Obtained",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Age: `%s`\n" ..
							"> Remains Queue: `%s`",
							tostring(petType or "?"),
							tostring(mutation or "?"),
							tostring(age or 0),
							tostring(remainsQueue or 0)
						),
						inline = false,
					},
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png",
				},
			},
		},
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return cleanseWebhook
]=],
	["modules/mutation/webhook.lua"] = [=[
--[[ webhook/mutation.lua — Discord webhook untuk mutation.
     Di-load via HttpGet loader; sender diambil dari ctx.sendWebhook (bukan require script). ]]
local HttpService = game:GetService("HttpService")

local mutationWebhook = {}

-- Webhook saat mutasi di-enable
function mutationWebhook.sendEnabled(ctx, targetTypes, targetMuts, targetAge, expTeamList, boostTeamList, phoenixTeamList)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local typesList = {}
	for k in pairs(targetTypes) do table.insert(typesList, "`" .. k .. "`") end
	local typesText = #typesList > 0 and table.concat(typesList, ", ") or "None"

	local mutsList = {}
	for k in pairs(targetMuts) do table.insert(mutsList, "`" .. k .. "`") end
	local mutsText = #mutsList > 0 and table.concat(mutsList, ", ") or "None"

	local expText = #expTeamList > 0 and table.concat(expTeamList, ", ") or "None"
	local boostText = #boostTeamList > 0 and table.concat(boostTeamList, ", ") or "None"
	local phText = #phoenixTeamList > 0 and table.concat(phoenixTeamList, ", ") or "None"

	local payload = {
		embeds = {
			{
				title = "Mutation • Machine Enabled",
				color = 10181046, -- Purple (hex 0x9b59b6 -> 10181046)
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Mutation Configuration",
						value = string.format(
							"> Target Types: %s\n" ..
							"> Keep Mutations: %s\n" ..
							"> Target Age: `%s`",
							typesText,
							mutsText,
							tostring(targetAge)
						),
						inline = false
					},
					{
						name = "Mutation Support Teams",
						value = string.format(
							"> EXP Team: %s\n" ..
							"> Boost Team: %s\n" ..
							"> Phoenix Team: %s",
							expText,
							boostText,
							phText
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Webhook saat pet disubmit ke mesin
function mutationWebhook.sendSubmitted(ctx, petType, level)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local payload = {
		embeds = {
			{
				title = "Mutation • Pet Submitted",
				color = 10181046, -- Purple
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Machine Status",
						value = string.format(
							"> Submitted Pet: `%s`\n" ..
							"> Age: `%s` (Target: `%s`)",
							petType,
							tostring(level),
							tostring(CFG.mutationTargetAge)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Format detik -> "Xm Ys" / "Ys"
local function fmtDuration(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	if sec >= 60 then return string.format("%dm %ds", math.floor(sec / 60), sec % 60) end
	return string.format("%ds", sec)
end

-- Webhook saat pet diklaim (hasil mutasi)
function mutationWebhook.sendClaimed(ctx, petType, outcomeMutation, isMatched, duration)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local mutDisplay = ctx.reg.mutDisplay and ctx.reg.mutDisplay(outcomeMutation) or outcomeMutation
	local statusText = isMatched and "✅ Target Found" or "❌ Non-target"

	local payload = {
		embeds = {
			{
				title = "Mutation • Pet Claimed",
				color = isMatched and 3066993 or 10181046, -- Green or Purple
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Claim Outcome",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Outcome Mutation: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Status: **%s**",
							petType,
							mutDisplay,
							fmtDuration(duration),
							statusText
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return mutationWebhook
]=],
	["modules/pet/automation_boost_pet.lua"] = [=[
--[[ boostpet.lua — Automation Boost Pet.
     Pilih pet + item boost (Pet Toy). Otomatis apply boost ke pet;
     re-apply pas boost habis (berdasar durasi item, atribut "p" = boostTime detik).
     Mekanik: pegang Tool bertag "PetBoost" lalu PetBoostService:FireServer("ApplyBoost", petUuid). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetBoostService = RS:WaitForChild("GameEvents"):WaitForChild("PetBoostService")
	local function setStatus(s) ctx.setStatus(s) end

	-- "Medium Pet Toy x42[Passive Boost]" -> "Medium Pet Toy"
	local function baseName(n) return (tostring(n):gsub("%s*x%d+.*$", "")) end

	-- Daftar item boost (tag PetBoost) di backpack, dedupe per base name -> dropdown.
	function ctx.getBoostItemOptions(selectedSet)
		local out, seen = {}, {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if not bp then return out end
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t:HasTag("PetBoost") then
				local bn = baseName(t.Name)
				if not seen[bn] then
					seen[bn] = true
					local dur = t:GetAttribute("p")
					out[#out + 1] = { value = bn, display = dur and (bn .. " (" .. tostring(dur) .. "s)") or bn }
				end
			end
		end
		table.sort(out, function(a, b)
			local sa = selectedSet and selectedSet[a.value] and 1 or 0
			local sb = selectedSet and selectedSet[b.value] and 1 or 0
			if sa ~= sb then return sa > sb end
			return a.display < b.display
		end)
		return out
	end

	local THRESHOLD = 5 -- detik; boost dianggap habis kalau sisa <= ini

	-- Key unik per varian boost: type + amount. Small & Medium Pet Toy sama-sama
	-- PASSIVE_BOOST tapi amount beda (0.1 vs 0.2) dan BISA di-stack, jadi harus dibedakan.
	local function boostKey(btype, amount)
		local n = tonumber(amount)
		return tostring(btype) .. "|" .. (n and tostring(n) or tostring(amount))
	end

	-- Baca boost yang MASIH aktif di pet (dari PetData.Boosts, sisa Time > THRESHOLD).
	-- Keyed by type+amount supaya varian beda amount tidak saling menutupi.
	local function petActiveTypes(uuid)
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		local data = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		local pd = data and data[uuid]
		local boosts = pd and pd.PetData and pd.PetData.Boosts
		if type(boosts) == "table" then
			for _, b in ipairs(boosts) do
				if b.BoostType and (tonumber(b.Time) or 0) > THRESHOLD then
					out[boostKey(b.BoostType, b.BoostAmount)] = true
				end
			end
		end
		return out
	end

	-- Pet dianggap AKTIF di garden kalau uuid-nya ada di PetsData.EquippedPets (array uuid).
	-- Boost cuma berlaku ke pet yang lagi placed; kalau nggak placed, skip (percuma).
	local function isPetActive(uuid)
		local ok, d = pcall(function() return DataService:GetData() end)
		local eq = ok and d and d.PetsData and d.PetsData.EquippedPets
		return type(eq) == "table" and table.find(eq, uuid) ~= nil
	end

	-- Cari tool boost dipilih (Character dulu) yang varian (type+amount)-nya BELUM aktif di pet.
	local function findToolForMissing(activeTypes)
		local sel = CFG.boostItemNames or {}
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then
				for _, t in ipairs(src:GetChildren()) do
					if t:IsA("Tool") and t:HasTag("PetBoost") and sel[baseName(t.Name)] then
						local bt = t:GetAttribute("q")
						if bt and not activeTypes[boostKey(bt, t:GetAttribute("o"))] then return t end
					end
				end
			end
		end
		return nil
	end

	local function boostLoop()
		ctx.state.boostId = (ctx.state.boostId or 0) + 1
		local myId = ctx.state.boostId
		ctx.elevate()

		while CFG.boostEnabled and ctx.alive() and ctx.state.boostId == myId do
			local pets = CFG.boostPetUuids or {}
			if not next(pets) then
				setStatus("Boost: pilih pet dulu")
				task.wait(3)
			else
				for uuid in pairs(pets) do
					if not CFG.boostEnabled or ctx.state.boostId ~= myId then break end
					-- Skip pet yang nggak aktif/placed di garden (boost ga guna)
					if not isPetActive(uuid) then continue end
					-- Cek state asli: boost apa yang masih aktif di pet ini
					local active = petActiveTypes(uuid)
					local tool = findToolForMissing(active)
					if tool then
						local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							-- pastikan item bener-bener dipegang sebelum ApplyBoost
							local held
							for _ = 1, 3 do
								pcall(function() hum:EquipTool(tool) end)
								task.wait(0.35)
								held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
								if held and held:HasTag("PetBoost") then break end
								tool = findToolForMissing(active)
								if not tool then break end
							end
							if held and held:HasTag("PetBoost") then
								pcall(function() PetBoostService:FireServer("ApplyBoost", uuid) end)
								setStatus(("Boost: %s -> #%s"):format(baseName(held.Name), uuid:sub(2, 5)))
								task.wait(0.6)
							end
						end
					end
				end
				task.wait(2)
			end
		end
	end

	function ctx.startBoostPet() task.spawn(boostLoop) end
end
]=],
	["modules/pet/automation_pickup_pet_v1.lua"] = [=[
--[[ automation_pickup_pet_v1.lua — PnP V1 (POLLING).
     Tiap pet target punya thread sendiri: query GetPetCooldown -> kalau ready pickup-place.
     Langsung & simpel, tapi kena JITTER latency server (round-trip tiap cek).
     Config SENDIRI: pnpUuids, pickupDelay, equipDelay, pnpScanInterval, pnpEnabled.
     Fungsi: ctx.startPnpV1 / ctx.stopPnpV1. Juga expose ctx.inventoryPetOptions (dipakai V1 & V2). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = ctx.state.cdMap or {}
	ctx.state.cdMap = cdMap
	local READY_TH = 0

	local GetPetCooldown = RS:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")

	local function readMainCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		if not ok or type(cd) ~= "table" then return nil end
		local data, mainCd = {}, 0
		for _, e in ipairs(cd) do
			local t = tonumber(e.Time) or 0
			data[#data + 1] = { Passive = e.Passive, Time = t }
			if not tostring(e.Passive or ""):find("Mutation") then
				if t > mainCd then mainCd = t end
			end
		end
		cdMap[uuid] = { data = data }
		return mainCd
	end

	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		local sel = CFG.pnpUuids or {}
		for _, uuid in ipairs(eq) do
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = pt }
			end
		end
		return out
	end

	-- daftar pet dari INVENTORY buat dropdown Select Pets (SHARED: dipakai V1 & V2).
	function ctx.inventoryPetOptions(selectedSet)
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not inv then return out end
		local eq = d.PetsData.EquippedPets or {}
		local eqSet = {}; for _, u in ipairs(eq) do eqSet[u] = true end
		for uuid, v in pairs(inv) do
			local pt = v.PetType or "?"
			local pd = v.PetData or {}
			local age = pd.Level or 0
			local mut = pd.MutationType
			local mutName = mut
			if mut and ctx.reg and ctx.reg.mutDisplay then mutName = ctx.reg.mutDisplay(mut) end
			local mutPrefix = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
			local weight = (pd.BaseWeight or 0) * (1 + 0.1 * age)
			local tag = eqSet[uuid] and " [aktif]" or ""
			out[#out + 1] = {
				value = uuid,
				display = ("%s%s | %.2f KG | Age %s | #%s%s"):format(mutPrefix, pt, weight, tostring(age), uuid:sub(2, 5), tag),
			}
		end
		if selectedSet and next(inv) then
			local valid = {}
			for uuid in pairs(inv) do valid[uuid] = true end
			local changed = false
			for u in pairs(selectedSet) do
				if not valid[u] then selectedSet[u] = nil; changed = true end
			end
			if changed and ctx.persistState then ctx.persistState() end
		end
		table.sort(out, function(a, b)
			local selA = selectedSet and selectedSet[a.value] and 1 or 0
			local selB = selectedSet and selectedSet[b.value] and 1 or 0
			if selA ~= selB then return selA > selB end
			return a.display < b.display
		end)
		return out
	end

	local GetFarm = require(RS.Modules.GetFarm)
	local function placePos()
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	----------------------------------------------------------------- loop (polling, paralel per-pet)
	local petThreads = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpV1Id == myId do
			local stillTarget = false
			for _, p in ipairs(targetPets()) do
				if p.uuid == uuid then stillTarget = true; break end
			end
			if not stillTarget then break end

			local mainCd = readMainCd(uuid)
			local pos = placePos()
			if pos and mainCd ~= nil and mainCd <= READY_TH then
				if (CFG.pickupDelay or 0) > 0 then task.wait(CFG.pickupDelay) end
				if not (CFG.pnpEnabled and ctx.state.pnpV1Id == myId) then break end
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				task.wait(math.max(0.01, CFG.equipDelay or 0.03))
				if not (CFG.pnpEnabled and ctx.state.pnpV1Id == myId) then break end
				pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
			end
			task.wait(math.max(0.01, tonumber(CFG.pnpScanInterval) or 0.05))
		end
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1
		local myId = ctx.state.pnpV1Id
		ctx.elevate()
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpV1Id == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP V1: tidak ada pet target (equip pet dulu)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId) end
				end
				setStatus(("PNP V1 (polling): %d pet"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV1() task.spawn(pnpLoop) end
	function ctx.stopPnpV1() ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1 end -- bump id -> loop lama mati
end
]=],
	["modules/pet/automation_pickup_pet_v2.lua"] = [=[
--[[ automation_pickup_pet_v2.lua — PnP V2 (EVENT-DRIVEN).
     BUKAN polling. Dengerin RemoteEvent server `PetCooldownsUpdated` yang PUSH cooldown tiap
     berubah (nol round-trip -> nol jitter -> stabil). Actor act dari cd real-time di memori.
     Config SENDIRI: pnpV2Uuids, pnpV2PickupDelay, pnpV2EquipDelay, pnpV2ScanInterval, pnpV2Enabled.
     Fungsi: ctx.startPnpV2 / ctx.stopPnpV2. Dropdown pakai ctx.inventoryPetOptions (dari V1). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = ctx.state.cdMap or {}
	ctx.state.cdMap = cdMap
	local READY_TH = 0

	local GameEvents = RS:WaitForChild("GameEvents")
	local GetPetCooldown = GameEvents:WaitForChild("GetPetCooldown")           -- seed awal
	local PetCooldownsUpdated = GameEvents:WaitForChild("PetCooldownsUpdated") -- push cd real-time

	local function computeMainCd(cd)
		if type(cd) ~= "table" then return nil end
		local data, mainCd = {}, 0
		for _, e in ipairs(cd) do
			local t = tonumber(e.Time) or 0
			data[#data + 1] = { Passive = e.Passive, Time = t }
			if not tostring(e.Passive or ""):find("Mutation") then
				if t > mainCd then mainCd = t end
			end
		end
		return mainCd, data
	end

	-- cdLive: cd real-time per pet, di-update oleh event PetCooldownsUpdated (server push).
	local cdLive = {}
	ctx.state.pnpV2CdLive = cdLive
	do
		local g = (getgenv and getgenv()) or _G
		if g.__pnpV2CdConn then pcall(function() g.__pnpV2CdConn:Disconnect() end) end
		g.__pnpV2CdConn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdTable)
			if type(uuid) ~= "string" then return end
			local m, data = computeMainCd(cdTable)
			if m ~= nil then cdLive[uuid] = m; cdMap[uuid] = { data = data } end
		end)
	end
	local function seedCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		local m, data = computeMainCd(ok and cd or nil)
		if m ~= nil then cdLive[uuid] = m; cdMap[uuid] = { data = data } end
	end

	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		local sel = CFG.pnpV2Uuids or {}
		for _, uuid in ipairs(eq) do
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = pt }
			end
		end
		return out
	end

	local GetFarm = require(RS.Modules.GetFarm)
	local function placePos()
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	----------------------------------------------------------------- loop (event-driven, paralel per-pet)
	local petThreads = {}
	local lastPlace = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		if cdLive[uuid] == nil then seedCd(uuid) end
		while CFG.pnpV2Enabled and ctx.alive() and ctx.state.pnpV2Id == myId do
			local stillTarget = false
			for _, p in ipairs(targetPets()) do
				if p.uuid == uuid then stillTarget = true; break end
			end
			if not stillTarget then break end

			local cd = cdLive[uuid]
			local pos = placePos()
			if pos and cd ~= nil and cd <= READY_TH and (os.clock() - (lastPlace[uuid] or 0)) > 0.25 then
				if (CFG.pnpV2PickupDelay or 0) > 0 then task.wait(CFG.pnpV2PickupDelay) end
				if not (CFG.pnpV2Enabled and ctx.state.pnpV2Id == myId) then break end
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				task.wait(math.max(0.01, CFG.pnpV2EquipDelay or 0.03))
				if not (CFG.pnpV2Enabled and ctx.state.pnpV2Id == myId) then break end
				pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
				lastPlace[uuid] = os.clock()
			end
			task.wait(math.max(0.02, tonumber(CFG.pnpV2ScanInterval) or 0.05))
		end
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpV2Id = (ctx.state.pnpV2Id or 0) + 1
		local myId = ctx.state.pnpV2Id
		ctx.elevate()
		while CFG.pnpV2Enabled and ctx.alive() and ctx.state.pnpV2Id == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP V2: tidak ada pet target (equip pet dulu)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId) end
				end
				setStatus(("PNP V2 (event-driven): %d pet"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV2() task.spawn(pnpLoop) end
	function ctx.stopPnpV2() ctx.state.pnpV2Id = (ctx.state.pnpV2Id or 0) + 1 end
end
]=],
	["modules/shop/automation_shop.lua"] = [=[
--[[ shop.lua — Automation Buy Seed / Egg / Gear.
     Opsi dropdown diambil dari REGISTRY katalog shop (bukan stock), jadi semua
     item tampil walau lagi habis; item baru dari update game auto masuk.
       Seed -> SeedShopData
       Gear -> GearShopData.Gear
       Egg  -> PetEggData
     Ada opsi "All" = beli semua yang lagi ada stock.
     Remote:
       BuySeedStock:FireServer("Shop", seedName)
       BuyGearStock:FireServer(gearName)
       BuyPetEgg:FireServer(eggIndex) ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local BuySeedStock = GE:WaitForChild("BuySeedStock")
	local BuyGearStock = GE:WaitForChild("BuyGearStock")
	local BuyPetEgg    = GE:WaitForChild("BuyPetEgg")
	local function setStatus(s) ctx.setStatus(s) end

	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	-- Ambil daftar nama dari registry katalog; buang key non-item (RefreshTime, Gear).
	local function catalogNames(getTbl)
		local ok, t = pcall(getTbl)
		local out = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do
				local n = tostring(k)
				if n ~= "RefreshTime" and n ~= "Gear" then out[#out + 1] = n end
			end
			table.sort(out)
		end
		return out
	end

	local function optionsFrom(names, sel)
		local out = { { value = "All", display = "All (beli semua)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	function ctx.getSeedShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.SeedShopData) end), sel)
	end
	function ctx.getGearShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.GearShopData).Gear end), sel)
	end
	function ctx.getEggShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.PetEggData) end), sel)
	end

	----------------------------------------------------------------- loop beli
	-- Poll = cek marker restock (cuma BACA, bukan beli -> murah, ga lag).
	-- Beli tetap hanya saat marker berubah (restock). 2s biar deteksi cepat (minim miss).
	local POLL = 2

	local function buySeedLoop()
		ctx.state.buySeedId = (ctx.state.buySeedId or 0) + 1
		local myId = ctx.state.buySeedId
		ctx.elevate()
		local lastMarker
		while CFG.buySeedEnabled and ctx.alive() and ctx.state.buySeedId == myId do
			local d = getData()
			-- Game mindahin stok seed ke d.SeedStocks.Shop (d.SeedStock singular udah BEKU:
			-- markernya ga update lagi -> loop lama cuma beli sekali terus stuck "nunggu restock").
			-- Prefer path baru; fallback ke singular biar aman kalau server balikin lagi.
			local shop = d and ((d.SeedStocks and d.SeedStocks.Shop) or d.SeedStock)
			local marker = shop and shop.Seed
			if marker ~= lastMarker then -- restock baru (atau pertama jalan) -> beli
				lastMarker = marker
				local st = shop and shop.Stocks or {}
				local sel = CFG.buySeedNames or {}
				local all = sel["All"]
				local bought = 0
				for name, v in pairs(st) do
					if all or sel[name] then
						local stock = type(v) == "table" and v.Stock or 0
						for _ = 1, stock do
							if not CFG.buySeedEnabled or ctx.state.buySeedId ~= myId then break end
							pcall(function() BuySeedStock:FireServer("Shop", name) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Seed: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Seed: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	local function buyGearLoop()
		ctx.state.buyGearId = (ctx.state.buyGearId or 0) + 1
		local myId = ctx.state.buyGearId
		ctx.elevate()
		local lastMarker
		while CFG.buyGearEnabled and ctx.alive() and ctx.state.buyGearId == myId do
			local d = getData()
			local marker = d and d.GearStock and d.GearStock.Gear
			if marker ~= lastMarker then
				lastMarker = marker
				local st = d and d.GearStock and d.GearStock.Stocks or {}
				local sel = CFG.buyGearNames or {}
				local all = sel["All"]
				local bought = 0
				for name, v in pairs(st) do
					if all or sel[name] then
						local stock = type(v) == "table" and v.Stock or 0
						for _ = 1, stock do
							if not CFG.buyGearEnabled or ctx.state.buyGearId ~= myId then break end
							pcall(function() BuyGearStock:FireServer(name) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Gear: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Gear: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	local function buyEggLoop()
		ctx.state.buyEggId = (ctx.state.buyEggId or 0) + 1
		local myId = ctx.state.buyEggId
		ctx.elevate()
		local lastMarker
		while CFG.buyEggEnabled and ctx.alive() and ctx.state.buyEggId == myId do
			local d = getData()
			local marker = d and d.PetEggStock and d.PetEggStock.Egg
			if marker ~= lastMarker then
				lastMarker = marker
				local st = d and d.PetEggStock and d.PetEggStock.Stocks or {}
				local sel = CFG.buyEggNames or {}
				local all = sel["All"]
				local bought = 0
				for index, v in pairs(st) do
					local nm = type(v) == "table" and v.EggName
					local stock = type(v) == "table" and v.Stock or 0
					if nm and (all or sel[nm]) then
						for _ = 1, stock do
							if not CFG.buyEggEnabled or ctx.state.buyEggId ~= myId then break end
							pcall(function() BuyPetEgg:FireServer(index) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Egg: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Egg: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	function ctx.startBuySeed() task.spawn(buySeedLoop) end
	function ctx.startBuyGear() task.spawn(buyGearLoop) end
	function ctx.startBuyEgg() task.spawn(buyEggLoop) end
end
]=],
	["modules/shop/premium_shop.lua"] = [=[
--[[ premium_shop.lua — Premium Shop beli via Robux atau Token.
     Sumber katalog: RS.Data.GiftData (sama seperti sc lain, ~394 item, live).
       tiap entry: { Display, NormalId (beli sendiri), GiftId (gift ke player) }.
     Beli:
       Token : GameEvents.TradeEvents.TradeTokens.Purchase:InvokeServer(id)
       Robux : MarketController:PromptPurchaseRobux(id, Enum.InfoType.Product)
     Gift  : pakai GiftId (game handle penerima). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local MPS = game:GetService("MarketplaceService")
	local LP  = ctx.LP
	local CFG = ctx.CFG

	local MC; pcall(function() MC = require(RS.Modules.MarketController) end)
	local function giftData()
		local ok, d = pcall(function() return require(RS.Data.GiftData) end)
		return ok and d or {}
	end
	local function ttFolder()
		local ge = RS:FindFirstChild("GameEvents")
		local te = ge and ge:FindFirstChild("TradeEvents")
		return te and te:FindFirstChild("TradeTokens")
	end

	-- entry katalog berdasarkan key CFG.premiumItem.
	local function entryOf(key)
		local d = giftData()
		return key and d[key] or nil
	end

	------------------------------------------------------------- harga (Robux)
	-- Harga token dinamis (RAP), susah/ga stabil -> tampilkan harga Robux dari
	-- GetProductInfo. Di-cache; prefetch pelan di background (hindari rate limit).
	-- id -> number (harga) | false (id ga valid / ga dijual Robux) | nil (belum kebaca)
	-- PENTING: kegagalan karena throttle TIDAK di-cache (biar dicoba lagi), cuma
	-- id==0 / hasil valid-tanpa-harga yg di-cache false permanen.
	local priceCache = {}
	-- Harga dari MarketplaceService:GetProductInfo(id, Product) — HARUS pakai
	-- InfoType.Product (MC:GetProductInfo cache-nya di-key by id doang, bisa
	-- ketuker sama info Asset). Engine nge-cache hasil per (id,infoType), jadi
	-- id yg udah pernah kefetch (mis. sama shop asli game) balik instan.
	-- RetryPcall manual: throttle ga di-cache -> diulang di pass prefetch berikut.
	local function fetchPrice(id)
		if id == nil or id == 0 then return nil end
		local c = priceCache[id]
		if c ~= nil then return c or nil end
		local ok, info = pcall(function() return MPS:GetProductInfo(id, Enum.InfoType.Product) end)
		if not ok then return nil end           -- throttle/error: jangan cache, coba lagi nanti
		local p = info and info.PriceInRobux
		priceCache[id] = p or false             -- ok tapi ga ada harga = ga dijual Robux
		return p or nil
	end

	local prefetchStarted = false
	local function startPrefetch(entries)
		if prefetchStarted then return end
		prefetchStarted = true
		task.spawn(function()
			-- beberapa pass: yg kena throttle (belum ke-cache) diulang sampai kelar.
			for pass = 1, 4 do
				local remaining = 0
				for _, e in ipairs(entries) do
					if not ctx.alive() then return end
					if e.id ~= 0 and priceCache[e.id] == nil then
						fetchPrice(e.id)
						if priceCache[e.id] == nil then remaining = remaining + 1 end
						task.wait(0.1)          -- pelan biar ga kena throttle GetProductInfo
					end
				end
				if remaining == 0 then break end
				task.wait(1)
			end
		end)
	end

	-- opsi dropdown item: SEMUA entry di GiftData yg punya NormalId.
	-- Display + harga Robux (kalau udah ke-cache). Prefetch jalan di background.
	function ctx.getPremiumItemOptions()
		local d = giftData()
		local out, ids = {}, {}
		for k, v in pairs(d) do
			if type(v) == "table" and v.NormalId then
				local disp = tostring(v.Display or k)
				local p = priceCache[v.NormalId]
				if v.NormalId == 0 then
					disp = disp .. "  (Token)"     -- ga ada produk Robux
				elseif type(p) == "number" then
					disp = disp .. ("  (R$ %d)"):format(p)
				end
				out[#out + 1] = { name = k, display = disp }
				ids[#ids + 1] = { id = v.NormalId }
			end
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		startPrefetch(ids)
		return out
	end
	function ctx.getPremiumPayOptions()
		return { { name = "robux", display = "Robux" }, { name = "token", display = "Token" } }
	end

	-- prompt beli 1 id sesuai payment method (token / robux).
	local function purchaseId(id, label)
		if CFG.premiumPay == "token" then
			local tt = ttFolder()
			if not (tt and tt:FindFirstChild("Purchase")) then ctx.setStatus("Premium Shop: Token remote ga ada"); return end
			local canOk, can = pcall(function() return tt.CanPurchase:InvokeServer(id) end)
			if canOk and can then
				pcall(function() tt.Purchase:InvokeServer(id) end)
				ctx.setStatus("Premium Shop: " .. label .. " via Token…")
			else
				ctx.setStatus("Premium Shop: item ini ga bisa Token, pakai Robux")
			end
		else
			if MC and MC.PromptPurchaseRobux then
				pcall(function() MC:PromptPurchaseRobux(id, Enum.InfoType.Product) end)
			else
				pcall(function() MPS:PromptProductPurchase(LP, id) end)
			end
			ctx.setStatus("Premium Shop: prompt Robux " .. label .. " dibuka")
		end
	end

	-- fetch harga item terpilih & tampilkan di status (dipanggil saat milih item).
	function ctx.premiumShowPrice()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.NormalId) then return end
		local name = tostring(e.Display or CFG.premiumItem)
		local p = fetchPrice(e.NormalId)
		if p then
			ctx.setStatus(("Premium: %s — R$ %d"):format(name, p))
		else
			ctx.setStatus(("Premium: %s"):format(name))
		end
	end

	-- BELI buat diri sendiri (NormalId).
	function ctx.premiumBuy()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.NormalId) then ctx.setStatus("Premium Shop: pilih item dulu"); return end
		purchaseId(e.NormalId, "beli")
	end

	-- GIFT ke player (GiftId). Game yg minta penerima.
	function ctx.premiumGift()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.GiftId) then ctx.setStatus("Premium Shop: item ini ga ada opsi Gift"); return end
		purchaseId(e.GiftId, "gift")
	end
end
]=],
	["ui/components.lua"] = [=[
--[[ components.lua — kontrol UI garden (toggle, input, dropdown, accordion, page/tab). ]]
return function(ctx)
	local C = ctx.C
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad

	local function labels(parent, title, desc, rightPad)
		local txts = mk("Frame", { Size = UDim2.new(1, -(rightPad or 130), 1, 0), BackgroundTransparency = 1 }, parent)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 5), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
		if desc then
			mk("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 25), BackgroundTransparency = 1, Text = desc, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)
		end
	end

	local function divider(parent)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.stroke, BorderSizePixel = 0, LayoutOrder = 9999 }, parent)
	end

	----------------------------------------------------------------- toggle
	local function makeToggle(parent, title, desc, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = order }, parent)
		labels(row, title, desc, 70)
		local knob = mk("TextButton", { Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -50, 0.5, -12), BackgroundColor3 = C.panel, Text = "", AutoButtonColor = false }, row)
		corner(knob, 12); stroke(knob, C.stroke)
		local dot = mk("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.sub }, knob)
		corner(dot, 9)
		local function render()
			local on = getv()
			dot:TweenPosition(on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3), "Out", "Quad", 0.15, true)
			knob.BackgroundColor3 = on and C.acc or C.panel
			dot.BackgroundColor3 = on and Color3.new(1, 1, 1) or C.sub
		end
		knob.MouseButton1Click:Connect(function()
			local nv = not getv()
			setv(nv); render()
			if ctx.log then ctx.log(title .. (nv and " -> ON" or " -> OFF")) end
		end)
		render()
		return render
	end

	----------------------------------------------------------------- input
	local function makeInput(parent, title, desc, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = order }, parent)
		labels(row, title, desc, 140)
		local box = mk("TextBox", { 
			Size = UDim2.fromOffset(120, 30), 
			Position = UDim2.new(1, -124, 0.5, -15), 
			BackgroundColor3 = C.panel, 
			Text = tostring(getv()), 
			Font = Enum.Font.GothamMedium, 
			TextSize = 11, 
			TextColor3 = C.txt, 
			ClearTextOnFocus = false,
			ClipsDescendants = true,
			TextXAlignment = Enum.TextXAlignment.Left
		}, row)
		corner(box, 6); stroke(box)
		pad(box, 8, 8, 0, 0)
		box:GetPropertyChangedSignal("Text"):Connect(function() setv(box.Text) end)
		box.FocusLost:Connect(function() setv(box.Text); box.Text = tostring(getv()) end)
		return box
	end

	----------------------------------------------------------------- single dropdown (opsi = string atau {name,display})
	local function makeSingleDropdown(parent, title, desc, getOptions, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)
		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
		labels(head, title, desc, 200)
		local valLbl = mk("TextLabel", { Size = UDim2.new(0, 170, 1, 0), Position = UDim2.new(1, -190, 0, 0), BackgroundTransparency = 1, Text = getv() ~= "" and getv() or "Select", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.acc, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, head)
		mk("TextLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -14, 0.5, -7), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub }, head)

		local listFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 170), BackgroundColor3 = C.panel, Visible = false, LayoutOrder = 2 }, row)
		corner(listFrame, 6); stroke(listFrame)
		local search = mk("TextBox", { Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.row, PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, ClearTextOnFocus = false }, listFrame)
		corner(search, 6); stroke(search)
		local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -40), Position = UDim2.fromOffset(6, 36), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, listFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local optBtns = {}
		local function rebuild()
			for _, b in pairs(optBtns) do b:Destroy() end
			optBtns = {}
			local cur = getv()
			-- selected-first: opsi yg lagi dipilih diurut ke paling atas
			local raw = getOptions()
			local ordered, rest = {}, {}
			for _, opt in ipairs(raw) do
				local display = type(opt) == "table" and opt.display or opt
				local code    = type(opt) == "table" and opt.name or opt
				if display == cur or code == cur then ordered[#ordered + 1] = opt else rest[#rest + 1] = opt end
			end
			for _, opt in ipairs(rest) do ordered[#ordered + 1] = opt end
			for _, opt in ipairs(ordered) do
				local display = type(opt) == "table" and opt.display or opt
				local code    = type(opt) == "table" and opt.name or opt
				local isSel = (display == cur or code == cur)
				local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = isSel and C.acc or C.row, Text = (isSel and "  \u{2713} " or "  ") .. display, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = isSel and C.panel or C.txt, AutoButtonColor = false }, scroll)
				corner(ob, 4)
				ob.MouseButton1Click:Connect(function()
					setv(code); valLbl.Text = display; listFrame.Visible = false
				end)
				optBtns[#optBtns + 1] = ob
			end
		end
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			for _, ob in ipairs(optBtns) do ob.Visible = (q == "" or ob.Text:lower():find(q, 1, true) ~= nil) end
		end)
		head.MouseButton1Click:Connect(function()
			listFrame.Visible = not listFrame.Visible
			if listFrame.Visible then rebuild() end
		end)
		return function() valLbl.Text = getv() ~= "" and getv() or "Select" end
	end

	----------------------------------------------------------------- multi dropdown
	local function makeMultiDropdown(parent, title, desc, options, selSet, onChange, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)
		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
		labels(head, title, desc, 200)
		local valLbl = mk("TextLabel", { Size = UDim2.new(0, 170, 1, 0), Position = UDim2.new(1, -190, 0, 0), BackgroundTransparency = 1, Text = "Select", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, head)
		mk("TextLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -14, 0.5, -7), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub }, head)

		local function updateSummary()
			local sel = {}
			for _, o in ipairs(options) do if selSet[o] then sel[#sel + 1] = o end end
			if #sel == 0 then valLbl.Text = "Select"; valLbl.TextColor3 = C.sub
			else
				local txt = table.concat(sel, ", ")
				if #txt > 18 then txt = (#sel) .. " selected" end
				valLbl.Text = txt; valLbl.TextColor3 = C.acc
			end
		end

		local listFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 180), BackgroundColor3 = C.panel, Visible = false, LayoutOrder = 2 }, row)
		corner(listFrame, 6); stroke(listFrame)
		local search = mk("TextBox", { Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.row, PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, ClearTextOnFocus = false }, listFrame)
		corner(search, 6); stroke(search)
		local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -40), Position = UDim2.fromOffset(6, 36), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, listFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local built = false
		local optBtns = {}
		-- Urutkan: yang dipilih (✓) di paling atas, sisanya ikut urutan asli.
		local function reorder()
			local i = 0
			for _, opt in ipairs(options) do
				if selSet[opt] and optBtns[opt] then i = i + 1; optBtns[opt].LayoutOrder = i end
			end
			for _, opt in ipairs(options) do
				if not selSet[opt] and optBtns[opt] then i = i + 1; optBtns[opt].LayoutOrder = i end
			end
		end
		local function build()
			if built then return end; built = true
			for _, opt in ipairs(options) do
				local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. opt, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
				corner(ob, 4)
				local check = mk("TextLabel", { Size = UDim2.fromOffset(20, 24), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.green }, ob)
				local function rend() check.Text = selSet[opt] and "✓" or ""; ob.BackgroundColor3 = selSet[opt] and Color3.fromRGB(45, 44, 30) or C.row end
				ob.MouseButton1Click:Connect(function()
					if selSet[opt] then selSet[opt] = nil else selSet[opt] = true end
					rend(); updateSummary(); reorder(); if onChange then onChange() end
				end)
				rend(); optBtns[opt] = ob
			end
			reorder()
		end
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			for opt, ob in pairs(optBtns) do ob.Visible = (q == "" or opt:lower():find(q, 1, true) ~= nil) end
		end)
		head.MouseButton1Click:Connect(function()
			if not built then build() end
			listFrame.Visible = not listFrame.Visible
			if listFrame.Visible then reorder() end
		end)
		updateSummary()
		return updateSummary
	end

	----------------------------------------------------------------- multi dropdown DINAMIS (value/display)
	-- getOptions() -> { {value=<key>, display=<label>}, ... }. selSet di-key pakai value.
	-- Opsi di-rebuild tiap kali dibuka (buat list yang berubah, mis. pet equipped).
	local function makeMultiDropdownDyn(parent, title, desc, getOptions, selSet, onChange, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)
		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
		labels(head, title, desc, 200)
		local valLbl = mk("TextLabel", { Size = UDim2.new(0, 170, 1, 0), Position = UDim2.new(1, -190, 0, 0), BackgroundTransparency = 1, Text = "Select", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, head)
		mk("TextLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -14, 0.5, -7), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub }, head)

		local function countSel()
			local n = 0; for _ in pairs(selSet) do n += 1 end; return n
		end
		local function updateSummary()
			local n = countSel()
			if n == 0 then valLbl.Text = "Select (semua)"; valLbl.TextColor3 = C.sub
			else valLbl.Text = n .. " dipilih"; valLbl.TextColor3 = C.acc end
		end

		local listFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 190), BackgroundColor3 = C.panel, Visible = false, LayoutOrder = 2 }, row)
		corner(listFrame, 6); stroke(listFrame)
		local search = mk("TextBox", { Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.row, PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, ClearTextOnFocus = false }, listFrame)
		corner(search, 6); stroke(search)
		local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -40), Position = UDim2.fromOffset(6, 36), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, listFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local optBtns = {}  -- {btn=, display=}
		local function rebuild()
			for _, o in ipairs(optBtns) do o.btn:Destroy() end
			optBtns = {}
			-- Selected-first konsisten: yang dipilih (✓) di atas, urutan asli dipertahankan.
			local raw = getOptions()
			local ordered, sel, unsel = {}, {}, {}
			for _, o in ipairs(raw) do
				if selSet[o.value] then sel[#sel + 1] = o else unsel[#unsel + 1] = o end
			end
			for _, o in ipairs(sel) do ordered[#ordered + 1] = o end
			for _, o in ipairs(unsel) do ordered[#ordered + 1] = o end
			for _, opt in ipairs(ordered) do
				local value, display = opt.value, opt.display
				local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. display, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
				corner(ob, 4)
				local check = mk("TextLabel", { Size = UDim2.fromOffset(20, 24), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.green }, ob)
				local function rend() check.Text = selSet[value] and "✓" or ""; ob.BackgroundColor3 = selSet[value] and Color3.fromRGB(45, 44, 30) or C.row end
				ob.MouseButton1Click:Connect(function()
					if selSet[value] then selSet[value] = nil else selSet[value] = true end
					rend(); updateSummary(); if onChange then onChange() end
				end)
				rend()
				optBtns[#optBtns + 1] = { btn = ob, display = display:lower() }
			end
			-- refresh label "N dipilih" (selSet bisa berubah oleh auto-prune di getOptions)
			updateSummary()
		end
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			for _, o in ipairs(optBtns) do o.btn.Visible = (q == "" or o.display:find(q, 1, true) ~= nil) end
		end)
		head.MouseButton1Click:Connect(function()
			listFrame.Visible = not listFrame.Visible
			if listFrame.Visible then rebuild() end
		end)
		updateSummary()
		return updateSummary
	end

	----------------------------------------------------------------- accordion
	local function makeAccordion(parent, title, order, openByDefault)
		openByDefault = false -- semua accordion mulai tertutup saat pertama load
		local TS = game:GetService("TweenService")
		local container = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.row, BorderSizePixel = 0, LayoutOrder = order }, parent)
		corner(container, 8); stroke(container)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, container)
		
		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, container)
		corner(head, 8)
		pad(head, 14, 14, 0, 0)
		
		mk("TextLabel", { Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, head)
		local arrow = mk("TextLabel", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -7, 0.5, 0), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.acc, Rotation = openByDefault and 180 or 0 }, head)
		
		local line = mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.stroke, BorderSizePixel = 0, LayoutOrder = 2, Visible = openByDefault or false }, container)
		local body = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = openByDefault or false, LayoutOrder = 3 }, container)
		pad(body, 14, 14, 8, 12)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, body)
		
		head.MouseEnter:Connect(function()
			TS:Create(head, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.96 }):Play()
		end)
		head.MouseLeave:Connect(function()
			TS:Create(head, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		end)
		
		head.MouseButton1Click:Connect(function()
			body.Visible = not body.Visible
			line.Visible = body.Visible
			local targetRotation = body.Visible and 180 or 0
			TS:Create(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = targetRotation }):Play()
		end)
		return body
	end

	----------------------------------------------------------------- sidebar page/tab
	local function makePage(name, titleText, icon, order)
		local tabButtonsFrame = ctx.ui.tabButtonsFrame
		local content = ctx.ui.content
		local pages, tabBtns = ctx.ui.pages, ctx.ui.tabBtns

		local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.acc, BackgroundTransparency = 1, Text = "    " .. icon .. "  |  " .. name, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = C.sub, LayoutOrder = order, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left }, tabButtonsFrame)
		corner(btn, 6)
		local line = mk("Frame", { Size = UDim2.new(0, 3, 0, 20), Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = C.acc, Visible = false, BorderSizePixel = 0 }, btn)
		corner(line, 2)
		tabBtns[name] = { btn = btn, line = line }

		local pg = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, content)
		mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pg)
		pages[name] = pg
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Text = titleText, Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 }, pg)

		btn.MouseButton1Click:Connect(function()
			for n, p in pairs(pages) do p.Visible = (n == name) end
			for n, b in pairs(tabBtns) do
				b.btn.BackgroundTransparency = (n == name) and 0.85 or 1
				b.btn.TextColor3 = (n == name) and C.txt or C.sub
				b.line.Visible = (n == name)
			end
		end)
		return pg
	end

	----------------------------------------------------------------- button
	local function makeButton(parent, title, desc, onClick, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = order }, parent)
		labels(row, title, desc, 140)
		local btn = mk("TextButton", { Size = UDim2.fromOffset(120, 30), Position = UDim2.new(1, -124, 0.5, -15), BackgroundColor3 = C.panel, Text = "Execute", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.acc, AutoButtonColor = true }, row)
		corner(btn, 6); stroke(btn, C.acc)
		btn.MouseButton1Click:Connect(onClick)
		return btn
	end

	ctx.makeToggle = makeToggle
	ctx.makeInput = makeInput
	ctx.makeSingleDropdown = makeSingleDropdown
	ctx.makeMultiDropdown = makeMultiDropdown
	ctx.makeMultiDropdownDyn = makeMultiDropdownDyn
	ctx.makeAccordion = makeAccordion
	ctx.makePage = makePage
	ctx.makeButton = makeButton
	ctx.divider = divider
end
]=],
	["ui/pages.lua"] = [=[
--[[ pages.lua — halaman garden. Tab: Pet, Elephant, Growth, Leveling, Mutation, Event, Inventory, Shop, Misc.
     Isi utama ada di tab Inventory (Automation Trade + Automation Accept + Automation Favourite). ]]
return function(ctx)
	local C = ctx.C
	local CFG = ctx.CFG
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad
	local persist = ctx.persistState
	local reg = ctx.reg
	local function log(m) ctx.log(m) end

	-- True kalau GuiObject benar-benar kelihatan di layar (tab aktif + accordion kebuka
	-- + window ga diminimize). Dipakai supaya loop status berhenti hitung/redraw label
	-- yang lagi nggak dilihat — cegah layout-thrashing yang bikin CPU naik.
	local function onScreen(o)
		while o and o ~= game do
			if o:IsA("GuiObject") and not o.Visible then return false end
			o = o.Parent
		end
		return o == game
	end

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
		{ "Farm", "Farm", "🌾" },
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
	------------------------------------------------------------------ FARM
	do
		local farmPage = pageRef["Farm"]

		-- Automation Plants (fitur aktif): pilih seed + posisi + delay + toggle
		local plAcc = makeAccordion(farmPage, "Automation Plants", 1, false)
		makeMultiDropdownDyn(plAcc, "Select Seeds", "Pilih seed dari inventory (angka = jumlah).",
			function() return ctx.getPlantSeedOptions() end, CFG.plantSeedNames, function() persist() end, 1)
		makeSingleDropdown(plAcc, "Select Position", "Lokasi tanam di farm.",
			function() return { "Random", "Player Position" } end,
			function() return CFG.plantPosition end,
			function(v) CFG.plantPosition = v; persist() end, 2)
		makeInput(plAcc, "Delay To Plants", "Extra delay (detik) tiap tanam seed.",
			function() return tostring(CFG.plantDelay) end,
			function(t) CFG.plantDelay = tonumber(t) or 0; persist() end, 3)
		makeToggle(plAcc, "Auto Plants Seed", "Tanam seed terpilih otomatis.",
			function() return CFG.plantSeedEnabled end,
			function(v) CFG.plantSeedEnabled = v; persist(); if v and ctx.startPlant then ctx.startPlant() end end, 4)

		-- Automation Sprinkler (fitur aktif): pasang sprinkler + shovel sprinkler
		local sprAcc = makeAccordion(farmPage, "Automation Sprinkler", 2, false)
		makeMultiDropdownDyn(sprAcc, "Select Sprinkler", "Sprinkler yg mau dipasang (angka = jumlah).",
			function() return ctx.getSprinklerOptions() end, CFG.sprinklerNames, function() persist() end, 1)
		makeMultiDropdownDyn(sprAcc, "Select Sprinkler Plants", "Pasang dekat plant ini. Kosong = pakai Position.",
			function() return ctx.getSprinklerPlantOptions() end, CFG.sprinklerPlantNames, function() persist() end, 2)
		makeSingleDropdown(sprAcc, "Select Sprinkler Position", "Lokasi pasang kalau Plants kosong.",
			function() return { "Random", "Player Position" } end,
			function() return CFG.sprinklerPosition end,
			function(v) CFG.sprinklerPosition = v; persist() end, 3)
		makeInput(sprAcc, "Delay To Sprinkler", "Extra delay (detik) tiap pasang.",
			function() return tostring(CFG.sprinklerDelay) end,
			function(t) CFG.sprinklerDelay = tonumber(t) or 0; persist() end, 4)
		makeToggle(sprAcc, "Auto Sprinkler", "Pasang sprinkler terpilih otomatis.",
			function() return CFG.sprinklerEnabled end,
			function(v) CFG.sprinklerEnabled = v; persist(); if v and ctx.startSprinkler then ctx.startSprinkler() end end, 5)

		-- sub-accordion: Sprinkler Shovel (cabut sprinkler terpasang, butuh Shovel)
		local shAcc = makeAccordion(sprAcc, "Sprinkler Shovel", 6, false)
		makeMultiDropdownDyn(shAcc, "Select Shovel Sprinkler", "Jenis sprinkler terpasang yg mau dicabut. 'All' = semua.",
			function() return ctx.getShovelSprinklerOptions() end, CFG.shovelSprinklerNames, function() persist() end, 1)
		makeInput(shAcc, "Delay To Shovel Sprinkler", "Extra delay (detik) tiap cabut.",
			function() return tostring(CFG.shovelSprinklerDelay) end,
			function(t) CFG.shovelSprinklerDelay = tonumber(t) or 0; persist() end, 2)
		makeToggle(shAcc, "Auto Shovel Sprinkler", "Cabut sprinkler terpilih otomatis (equip Shovel).",
			function() return CFG.shovelSprinklerEnabled end,
			function(v) CFG.shovelSprinklerEnabled = v; persist(); if v and ctx.startShovelSprinkler then ctx.startShovelSprinkler() end end, 3)

		-- Automation Water (fitur aktif): siram plant terpilih pakai Watering Can (Water_RE)
		local watAcc = makeAccordion(farmPage, "Automation Water", 3, false)
		makeMultiDropdownDyn(watAcc, "Select Water Fruits", "Pilih fruit/plant yang mau disiram. 'All' = semua.",
			function() return ctx.getWaterFruitOptions() end, CFG.waterFruitNames, function() persist() end, 1)
		makeInput(watAcc, "Delay to Water", "Extra delay (detik) tiap siklus siram.",
			function() return tostring(CFG.waterDelay) end,
			function(t) CFG.waterDelay = tonumber(t) or 1; persist() end, 2)
		makeToggle(watAcc, "Auto Water Fruits", "Siram fruit terpilih otomatis.",
			function() return CFG.waterEnabled end,
			function(v) CFG.waterEnabled = v; persist(); if v and ctx.startWater then ctx.startWater() end end, 3)

		-- Automation Shovel (fitur aktif): shovel tree/plant + shovel fruit (filter)
		local shvAcc = makeAccordion(farmPage, "Automation Shovel", 4, false)
		makeMultiDropdownDyn(shvAcc, "Select Tree", "Pilih tree/plant yang mau di-shovel. 'All' = semua.",
			function() return ctx.getShovelTreeOptions() end, CFG.shovelTreeNames, function() persist() end, 1)
		makeInput(shvAcc, "Delay To Shovel Tree", "Extra delay (detik) tiap siklus shovel tree.",
			function() return tostring(CFG.shovelTreeDelay) end,
			function(t) CFG.shovelTreeDelay = tonumber(t) or 0; persist() end, 2)
		makeToggle(shvAcc, "Auto Shovel Tree", "Shovel tree/plant terpilih otomatis.",
			function() return CFG.shovelTreeEnabled end,
			function(v) CFG.shovelTreeEnabled = v; persist(); if v and ctx.startShovelTree then ctx.startShovelTree() end end, 3)

		-- sub: Fruits Shovel (shovel plant kalau fruit-nya cocok filter)
		local frShv = makeAccordion(shvAcc, "Fruits Shovel", 4, false)
		makeMultiDropdownDyn(frShv, "Select Shovel Fruits", "Tipe fruit yang mau di-shovel. 'All' = semua.",
			function() return ctx.getShovelFruitOptions() end, CFG.shovelFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(frShv, "Select Shovel Mutation", "Filter mutasi. Kosong/'All' = abaikan.",
			function() return ctx.getShovelMutationOptions() end, CFG.shovelFruitMuts, function() persist() end, 2)
		makeMultiDropdownDyn(frShv, "Select Shovel Variant", "Filter variant (Gold/Rainbow/dll). Kosong/'All' = abaikan.",
			function() return ctx.getShovelVariantOptions() end, CFG.shovelFruitVariants, function() persist() end, 3)
		makeSingleDropdown(frShv, "Select Shovel Threshold Mode", "Cara banding berat fruit.",
			function() return ctx.getShovelModeOptions() end,
			function() return CFG.shovelFruitMode end,
			function(v) CFG.shovelFruitMode = v; persist() end, 4)
		makeInput(frShv, "Shovel Weight Threshold", "Kalau ga mau pakai, isi '0'.",
			function() return tostring(CFG.shovelFruitWeight) end,
			function(t) CFG.shovelFruitWeight = tonumber(t) or 0; persist() end, 5)
		makeInput(frShv, "Delay To Shovel Fruit", "Extra delay (detik) tiap siklus shovel fruit.",
			function() return tostring(CFG.shovelFruitDelay) end,
			function(t) CFG.shovelFruitDelay = tonumber(t) or 0; persist() end, 6)
		makeToggle(frShv, "Auto Shovel Fruits", "Shovel plant yang fruit-nya cocok filter.",
			function() return CFG.shovelFruitEnabled end,
			function(v) CFG.shovelFruitEnabled = v; persist(); if v and ctx.startShovelFruit then ctx.startShovelFruit() end end, 7)

		-- Accordion yg masih kerangka (belum diisi)
		-- Automation Collection (fitur aktif): auto harvest fruit (3 mode whitelist)
		local colAcc = makeAccordion(farmPage, "Automation Collection", 5, false)
		makeInput(colAcc, "Delay To Collect", "Extra delay (detik) tiap siklus collect.",
			function() return tostring(CFG.collectDelay) end,
			function(t) CFG.collectDelay = tonumber(t) or 0; persist() end, 1)
		makeToggle(colAcc, "Stop Collect If Backpack Is Full Max", "Stop collect pas backpack penuh.",
			function() return CFG.collectStopIfFull end,
			function(v) CFG.collectStopIfFull = v; persist() end, 2)
		makeToggle(colAcc, "Auto Sell Fruit If Backpack Full", "Jual semua fruit pas backpack penuh.",
			function() return CFG.collectAutoSellIfFull end,
			function(v) CFG.collectAutoSellIfFull = v; persist() end, 3)

		-- sub: Whitelist Fruit
		local colWf = makeAccordion(colAcc, "Collect Whitelist Fruit", 4, false)
		makeMultiDropdownDyn(colWf, "Select Whitelist Fruit", "Pilih tipe fruit yang mau di-collect.",
			function() return ctx.getCollectFruitOptions() end, CFG.collectWlFruitNames, function() persist() end, 1)
		makeToggle(colWf, "Auto Collect Whitelisted Fruits", "Collect cuma tipe fruit yang di-whitelist.",
			function() return CFG.collectWlFruitEnabled end,
			function(v) CFG.collectWlFruitEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 2)

		-- sub: Whitelist Mutation
		local colWm = makeAccordion(colAcc, "Collect Whitelist Mutation", 5, false)
		makeMultiDropdownDyn(colWm, "Select Whitelist Mutations", "Pilih mutasi yang mau di-collect.",
			function() return ctx.getCollectMutationOptions() end, CFG.collectWlMutNames, function() persist() end, 1)
		makeToggle(colWm, "Auto Collect Whitelisted Mutations", "Collect cuma fruit dgn mutasi yang di-whitelist.",
			function() return CFG.collectWlMutEnabled end,
			function(v) CFG.collectWlMutEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 2)

		-- sub: Combined (semua kriteria)
		local colCb = makeAccordion(colAcc, "Collect Whitelist Combined", 6, false)
		makeMultiDropdownDyn(colCb, "Select Combined Fruits", "Filter by fruit type.",
			function() return ctx.getCollectFruitOptions() end, CFG.collectCombFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(colCb, "Select Combined Mutation", "Filter by mutation type.",
			function() return ctx.getCollectMutationOptions() end, CFG.collectCombMutNames, function() persist() end, 2)
		makeMultiDropdownDyn(colCb, "Select Combined Variant", "Filter by variant type.",
			function() return ctx.getCollectVariantOptions() end, CFG.collectCombVariants, function() persist() end, 3)
		makeSingleDropdown(colCb, "Whitelist Weight Mode", "Cara banding berat fruit.",
			function() return ctx.getCollectModeOptions() end,
			function() return CFG.collectCombMode end,
			function(v) CFG.collectCombMode = v; persist() end, 4)
		makeInput(colCb, "Whitelist Weight", "Kalau ga dipakai, isi '0'.",
			function() return tostring(CFG.collectCombWeight) end,
			function(t) CFG.collectCombWeight = tonumber(t) or 0; persist() end, 5)
		makeToggle(colCb, "Auto Collect Fruits", "Collect fruit yang cocok SEMUA kriteria combined.",
			function() return CFG.collectCombEnabled end,
			function(v) CFG.collectCombEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 6)

		-- Automation Favorite (fitur aktif): favorite/unfavorite fruit via Favorite Tool
		local favAcc = makeAccordion(farmPage, "Automation Favorite", 6, false)
		makeMultiDropdownDyn(favAcc, "Select Fruits", "Tipe fruit di garden buat di-favorite (kosong = any).",
			function() return ctx.getFavFruitOptions() end, CFG.favFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(favAcc, "Filter Mutations", "Mutasi yang diperluin (kosong = mutasi apapun OK).",
			function() return ctx.getFavMutationOptions() end, CFG.favMutNames, function() persist() end, 2)
		makeSingleDropdown(favAcc, "Weight Mode", "Banding berat fruit (kosong = off).",
			function() return ctx.getFavModeOptions() end,
			function() return CFG.favMode end,
			function(v) CFG.favMode = v; persist() end, 3)
		makeInput(favAcc, "Weight Value", "Threshold berat (0 = off).",
			function() return tostring(CFG.favWeight) end,
			function(t) CFG.favWeight = tonumber(t) or 0; persist() end, 4)
		makeInput(favAcc, "Delay To Favorite", "Detik tiap siklus scan favorite.",
			function() return tostring(CFG.favDelay) end,
			function(t) CFG.favDelay = tonumber(t) or 1; persist() end, 5)
		makeToggle(favAcc, "Auto Favorite Fruits", "Favorite fruit garden yang cocok filter.",
			function() return CFG.favEnabled end,
			function(v) CFG.favEnabled = v; persist(); if v and ctx.startFavorite then ctx.startFavorite() end end, 6)
		makeToggle(favAcc, "Auto Unfavorite Fruits", "Unfavorite fruit garden yang cocok filter.",
			function() return CFG.unfavEnabled end,
			function(v) CFG.unfavEnabled = v; persist(); if v and ctx.startFavorite then ctx.startFavorite() end end, 7)

		-- Automation Reclaimer (fitur aktif): pilih plant + toggle auto reclaim
		local recAcc = makeAccordion(farmPage, "Automation Reclaimer", 7, false)
		makeMultiDropdownDyn(recAcc, "Select Plants", "Pilih plant yg mau di-reclaim. 'All' = semua.",
			function() return ctx.getReclaimPlantOptions() end, CFG.reclaimPlantNames, function() persist() end, 1)
		makeToggle(recAcc, "Auto Reclaimer Plants", "Auto reclaim plant terpilih pakai tool Reclaimer",
			function() return CFG.reclaimEnabled end,
			function(v) CFG.reclaimEnabled = v; persist(); if v and ctx.startReclaim then ctx.startReclaim() end end, 2)
	end

	------------------------------------------------------------------ GROWTH (pipeline batch per-step)
	do
		local growthPage = pageRef["Growth"]
		local FLOW_OPTS = { { name = "none", display = "None (kosong)" }, { name = "elephant", display = "Elephant" }, { name = "mutation", display = "Mutation" }, { name = "leveling", display = "Leveling" } }
		local function capStep(s) for _, o in ipairs(FLOW_OPTS) do if o.name == s then return o.display end end return "Select" end

		-- Growth Control (status + target + enable)
		local gCtrl = makeAccordion(growthPage, "Growth Control", 1, true)
		local gLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "Loading...", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LineHeight = 1.35, RichText = true, LayoutOrder = 0 }, gCtrl)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, gCtrl)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(growthPage) then task.wait(1) continue end
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
				if not onScreen(hatchPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getHatchSummary() end)
				if ok and s then
					local col = s.status == "RUNNING" and "#5acc78" or "#dc5050"
					local gr = "#b8bdc7"
					hLbl.Text = string.format(
						"<b>Live Status</b>\n" ..
						"Status: <font color=\"%s\"><b>%s</b></font>\nPhase: <font color=\"#f5c82d\">%s</font>\n\n" ..
						"Core Team: <font color=\"%s\">%s</font>\nHatch Team: <font color=\"%s\">%s</font>\n" ..
						"Bronto Team: <font color=\"%s\">%s</font>\nSell Team: <font color=\"%s\">%s</font>\n\n" ..
						"Pet on Backpack: <font color=\"%s\">%d/%d</font>\n\n" ..
						"Current Egg: <font color=\"%s\">%s</font>\nEgg Before: <font color=\"%s\">%d</font>\n" ..
						"Current Amount: <font color=\"%s\">%d</font>\nPlaced: <font color=\"%s\">%d/%d</font>\n" ..
						"Eggs Hatched: <font color=\"%s\">%d</font>\nSell Cycle: <font color=\"%s\">%d/%d</font>\n\n" ..
						"<b>Recovery Stat (dari Team)</b>\n" ..
						"Koi (hatch): <font color=\"%s\">%d ekor \226\134\146 %.1f%%</font>\n" ..
						"Seal (sell): <font color=\"%s\">%d ekor \226\134\146 %.1f%%</font>",
						col, s.status, s.phase,
						gr, s.core, gr, s.hatch, gr, s.bronto, gr, s.sell,
						gr, s.backpack, s.maxBackpack,
						gr, s.currentEgg, gr, s.eggBefore, gr, s.currentAmount, gr, s.placed, s.maxPlaced,
						gr, s.eggsHatched, gr, s.cycleProg, s.cycleTarget,
						gr, (s.proc or {}).koiCount or 0, (s.proc or {}).koiPct or 0,
						gr, (s.proc or {}).sealCount or 0, (s.proc or {}).sealPct or 0)
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
		makeSingleDropdown(hEgg, "Placement Pattern", "Pola taro egg: Grid (rapih) / Random (sebar acak)",
			function() return { "Grid", "Random" } end,
			function() return CFG.hatchPlacePattern or "Grid" end,
			function(code) CFG.hatchPlacePattern = code; persist() end, 2)
		makeInput(hEgg, "Max Placed", "Maksimal egg ke-place di garden",
			function() return tostring(CFG.hatchMaxPlaced) end, function(t) CFG.hatchMaxPlaced = tonumber(t) or 9; persist() end, 3)
		makeInput(hEgg, "Hatch Speed (delay/hatch, sec)", "Jeda per hatch; makin kecil makin cepat (mis. 0.1)",
			function() return tostring(CFG.hatchSpeed) end, function(t) CFG.hatchSpeed = math.max(0.05, tonumber(t) or 0.2); persist() end, 4)

		-- Bronto Configuration (kapan pakai Bronto team buat +30% berat)
		local hBr = makeAccordion(hatchPage, "Bronto Configuration", 4, true)
		makeMultiDropdown(hBr, "Special Pets", "Pet yg WAJIB di-hatch pakai Bronto team",
			reg.PET_EGG_ONLY, CFG.brontoSpecialPets, function() persist() end, 1)
		makeInput(hBr, "Special Pets Weight Filter", "Special cuma kalau weight > ini (0 = ga difilter)",
			function() return tostring(CFG.brontoSpecialWeight) end, function(t) CFG.brontoSpecialWeight = tonumber(t) or 0; persist() end, 2)
		makeMultiDropdown(hBr, "Universal Weight Pet Types", "Tipe pet buat aturan universal (kosong = semua). Tampil dgn tipe egg-nya.",
			reg.PET_EGG_ONLY, CFG.brontoUniversalTypes, function() persist() end, 3)
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
			reg.PET_EGG_ONLY, CFG.sellSpecialTypes, function() persist() end, 4)
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

		-- Premium Shop (dev-product: Robux / Token + Gift)
		local premAcc = makeAccordion(shopPage, "Premium Shop", 4, false)
		makeSingleDropdown(premAcc, "Select Item", "Select gamepass/product to purchase",
			function() return ctx.getPremiumItemOptions() end,
			function()
				for _, o in ipairs(ctx.getPremiumItemOptions()) do if o.name == CFG.premiumItem then return o.display end end
				return "Select Option"
			end,
			function(code) CFG.premiumItem = code; persist(); if ctx.premiumShowPrice then ctx.premiumShowPrice() end end, 1)
		makeSingleDropdown(premAcc, "Payment Method", "Robux atau Token",
			function() return ctx.getPremiumPayOptions() end,
			function() return CFG.premiumPay == "token" and "Token" or "Robux" end,
			function(code) CFG.premiumPay = code; persist() end, 2)
		makeButton(premAcc, "Purchase Item", "Beli item terpilih dengan payment method di atas",
			function() if ctx.premiumBuy then ctx.premiumBuy() end end, 3)
		makeButton(premAcc, "Gift to Player", "Beli varian Gift item ini (kalau tersedia)",
			function() if ctx.premiumGift then ctx.premiumGift() end end, 4)
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
				if not onScreen(elephantPage) then task.wait(1) continue end
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

		-- ===================== ELEPHANT V2 (swap gajah on lvl 40) =====================
		local acc2 = makeAccordion(elephantPage, "Automation Elephant V2", 2, false)

		local v2Lbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading...",
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, acc2)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, acc2)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(elephantPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getElephantV2Summary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					v2Lbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
						"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n" ..
						"Max Target Pets: <font color=\"#8c929e\">%s</font>  |  Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Gajah: <font color=\"#8c929e\">%s</font>\n" ..
						"Switch: <font color=\"#8c929e\">%s</font>\n" ..
						"Gajah masuk saat target Age >= <font color=\"#f5c82d\"><b>%s</b></font>",
						col, s.status, s.info, s.team, s.types, s.ready, s.maxKg, s.maxTarget, s.targetWeight, s.gajah, s.switch, s.level)
				end
				task.wait(0.5)
			end
		end)

		makeMultiDropdownDyn(acc2, "V2 Elephant Team", "Team standby di garden (sumber pilihan Pet Switch)",
			function() return ctx.inventoryPetOptions(CFG.elephantV2Team) end, CFG.elephantV2Team, function() persist() end, 2)
		makeMultiDropdown(acc2, "V2 Target Pet Types", "Tipe pet target yg dipantau levelnya (yg di-level PNP)",
			reg.PET_OPTIONS, CFG.elephantV2Types, function() persist() end, 3)
		makeSingleDropdown(acc2, "Pet Gajah", "Pet booster berat yg di-swap masuk pas target lvl 40",
			function() return ctx.elephantV2GajahOptions() end,
			function() return ctx.elephantV2Label(CFG.elephantV2Gajah) end,
			function(uuid) CFG.elephantV2Gajah = uuid; persist() end, 4)
		makeSingleDropdown(acc2, "Pet Switch", "Pet team yg ditukar sama gajah (dari V2 Elephant Team)",
			function() return ctx.elephantV2SwitchOptions() end,
			function() return ctx.elephantV2Label(CFG.elephantV2Switch) end,
			function(uuid) CFG.elephantV2Switch = uuid; persist() end, 5)
		makeInput(acc2, "Target Weight (KG)", "Berat max target sebelum dilepas (mis. 5.5)",
			function() return tostring(CFG.elephantV2Weight) end,
			function(txt) CFG.elephantV2Weight = tonumber(txt) or 5.5; persist() end, 6)
		makeInput(acc2, "Max Target Pets", "Jumlah pet target aktif barengan di garden",
			function() return tostring(CFG.elephantV2MaxPets) end,
			function(txt) CFG.elephantV2MaxPets = tonumber(txt) or 3; persist() end, 7)
		makeInput(acc2, "Trigger Level", "Level target buat masukin gajah (default 40)",
			function() return tostring(CFG.elephantV2Level) end,
			function(txt) CFG.elephantV2Level = tonumber(txt) or 40; persist() end, 8)
		makeToggle(acc2, "Enable Elephant V2", "Rotasi target + swap gajah otomatis saat target lvl 40. Jalan barengan PNP.",
			function() return CFG.elephantV2Enabled end,
			function(v)
				CFG.elephantV2Enabled = v; persist()
				if v then ctx.startElephantV2() else ctx.stopElephantV2() end
			end, 9)
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
				if not onScreen(levelingPage) then task.wait(1) continue end
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
				if not onScreen(levelingPage) then task.wait(1) continue end
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
				if not onScreen(mutationPage) then task.wait(1) continue end
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
				if not onScreen(mutationPage) then task.wait(1) continue end
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
		-- Accordion pembungkus: Automation Summer Event
		local summerAcc = makeAccordion(eventPage, "Automation Summer Event", 1, true)

		-- Sub-accordion 1: Sam The Clam (status timer live + config feed)
		local samAcc = makeAccordion(summerAcc, "Sam The Clam", 1, true)
		local samLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Sam: loading...",
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, samAcc)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(eventPage) then task.wait(1) continue end
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
		makeMultiDropdownDyn(samAcc, "Pilih Pet (Feed ke Sam)", "Tipe pet yang boleh dikorbankan. Kosong = pakai filter berat.",
			function() return ctx.getSummerPetTypes(CFG.summerPetTypes) end, CFG.summerPetTypes, function() persist() end, 1)

		-- Berat minimum (KG)
		makeInput(samAcc, "Berat Min (KG)", "Hanya feed pet >= berat ini. 0 = off",
			function() return tostring(CFG.summerMinWeight) end,
			function(txt) CFG.summerMinWeight = tonumber(txt) or 0; persist() end, 2)

		-- Berat maksimum (KG)
		makeInput(samAcc, "Berat Max (KG)", "Hanya feed pet <= berat ini. 0 = off",
			function() return tostring(CFG.summerMaxWeight) end,
			function(txt) CFG.summerMaxWeight = tonumber(txt) or 0; persist() end, 3)

		-- Ikutkan pet favorite
		makeToggle(samAcc, "Ikut Feed Pet Favorite", "Kalau ON, pet favorite juga boleh dikorbankan",
			function() return CFG.summerAllowFavorite end,
			function(v) CFG.summerAllowFavorite = v; persist() end, 4)

		-- Enable Automation Summer Event (Toggle) — auto TP ke Sam sudah otomatis di dalam logic
		makeToggle(samAcc, "Enable Automation Summer Event", "Auto TP ke Sam + submit pet + claim reward saat timer habis.",
			function() return CFG.summerEventEnabled end,
			function(v)
				CFG.summerEventEnabled = v; persist()
				if v and ctx.startSummerEvent then ctx.startSummerEvent() end
			end, 6)

		-- Sub-accordion 2: Auto Chest Hunt (deposit selalu ke Garden)
		local chAcc = makeAccordion(summerAcc, "Auto Chest Hunt", 2, true)
		local chLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "Idle", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, RichText = true, LayoutOrder = 0 }, chAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 1 }, chAcc)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(eventPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getChestSummary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					chLbl.Text = ("Status: <font color=\"%s\"><b>%s</b></font>\n<font color=\"#8c929e\">%s</font>"):format(col, s.status, s.info)
				end
				task.wait(0.5)
			end
		end)
		-- Deposit selalu ke Garden
		CFG.chestHuntDeposit = "garden"
		makeToggle(chAcc, "Enable Auto Chest Hunt", "TP ke chest -> bawa ke garden -> ulang (auto pas event mulai)",
			function() return CFG.chestHuntEnabled end,
			function(v) CFG.chestHuntEnabled = v; persist(); if v then ctx.startChestHunt() else ctx.stopChestHunt() end end, 2)

		------------------------------------------------------------------ Summer Shop (auto buy)
		local shopAcc = makeAccordion(eventPage, "Summer Shop", 2, false)

		-- Sub-accordion 1: Summer Seed Shop (beli seed pakai Sheckles)
		local ssAcc = makeAccordion(shopAcc, "Summer Seed Shop", 1, true)
		makeMultiDropdownDyn(ssAcc, "Pilih Seed", "'All' = beli semua yg ada stock.",
			function() return ctx.getSummerSeedShopOptions() end, CFG.buySummerSeedNames, function() persist() end, 1)
		makeToggle(ssAcc, "Enable Auto Buy Summer Seed", "Auto-beli tiap restock (Sheckles)",
			function() return CFG.buySummerSeedEnabled end,
			function(v) CFG.buySummerSeedEnabled = v; persist(); if v and ctx.startBuySummerSeed then ctx.startBuySummerSeed() end end, 2)

		-- Sub-accordion 2: Tide Tokens (beli item pakai TideTokens)
		local ttAcc = makeAccordion(shopAcc, "Tide Tokens Shop", 2, true)
		makeMultiDropdownDyn(ttAcc, "Pilih Item", "'All' = beli semua yg ada stock.",
			function() return ctx.getTideTokenShopOptions() end, CFG.buyTideTokenNames, function() persist() end, 1)
		makeToggle(ttAcc, "Enable Auto Buy Tide Token", "Auto-beli tiap restock (Tide Tokens)",
			function() return CFG.buyTideTokenEnabled end,
			function(v) CFG.buyTideTokenEnabled = v; persist(); if v and ctx.startBuyTideToken then ctx.startBuyTideToken() end end, 2)
	end

	------------------------------------------------------------------ PET (PNP)
	local pet = pageRef["Pet"]
	local v1Render, v2Render -- buat sync visual mutual-exclusion

	------------------------------------------------------------------ PnP V1 (polling)
	local pnp = makeAccordion(pet, "Automation Pickup Pet V1", 1, true)
	makeMultiDropdownDyn(pnp, "Select Pets for Pickup [V1]", "Pilih pet dari backpack (kosong = semua yg di garden)",
		function() return ctx.inventoryPetOptions(CFG.pnpUuids) end, CFG.pnpUuids, function() persist() end, 1)
	makeInput(pnp, "Pickup Delay (Seconds) [V1]", "Jeda tiap siklus (idealnya = saat skill ready)",
		function() return CFG.pickupDelay end,
		function(txt) CFG.pickupDelay = tonumber(txt) or 0.4; persist() end, 2)
	makeInput(pnp, "Equip Delay (Seconds) [V1]", "Jeda antara unequip -> equip",
		function() return CFG.equipDelay end,
		function(txt) CFG.equipDelay = tonumber(txt) or 0.02; persist() end, 3)
	makeInput(pnp, "Scan Interval (Seconds) [V1]", "Frekuensi cek cooldown (kecil = makin ketat, min 0.01)",
		function() return CFG.pnpScanInterval end,
		function(txt) CFG.pnpScanInterval = math.max(0.01, tonumber(txt) or 0.05); persist() end, 4)
	v1Render = makeToggle(pnp, "Enable Automation Pickup V1", "Polling GetPetCooldown (lama). Nyalain ini matiin V2.",
		function() return CFG.pnpEnabled end,
		function(v)
			CFG.pnpEnabled = v; persist()
			if v then
				CFG.pnpV2Enabled = false; persist()
				if ctx.stopPnpV2 then ctx.stopPnpV2() end
				if v2Render then v2Render() end -- sync visual toggle V2 -> OFF
				if ctx.startPnpV1 then ctx.startPnpV1() end
			else
				if ctx.stopPnpV1 then ctx.stopPnpV1() end
			end
		end, 5)

	------------------------------------------------------------------ PnP V2 (event-driven)
	local pnp2 = makeAccordion(pet, "Automation Pickup Pet V2", 2, false)
	makeMultiDropdownDyn(pnp2, "Select Pets for Pickup [V2]", "Pilih pet dari backpack (kosong = semua yg di garden)",
		function() return ctx.inventoryPetOptions(CFG.pnpV2Uuids) end, CFG.pnpV2Uuids, function() persist() end, 1)
	makeInput(pnp2, "Pickup Delay (Seconds) [V2]", "Jeda sebelum tiap pickup",
		function() return CFG.pnpV2PickupDelay end,
		function(txt) CFG.pnpV2PickupDelay = tonumber(txt) or 0.05; persist() end, 2)
	makeInput(pnp2, "Equip Delay (Seconds) [V2]", "Jeda antara unequip -> equip",
		function() return CFG.pnpV2EquipDelay end,
		function(txt) CFG.pnpV2EquipDelay = tonumber(txt) or 0.03; persist() end, 3)
	makeInput(pnp2, "Scan Interval (Seconds) [V2]", "Frekuensi cek cd dari cache event (min 0.02)",
		function() return CFG.pnpV2ScanInterval end,
		function(txt) CFG.pnpV2ScanInterval = math.max(0.02, tonumber(txt) or 0.05); persist() end, 4)
	v2Render = makeToggle(pnp2, "Enable Automation Pickup V2", "Event-driven (PetCooldownsUpdated), stabil. Nyalain ini matiin V1.",
		function() return CFG.pnpV2Enabled end,
		function(v)
			CFG.pnpV2Enabled = v; persist()
			if v then
				CFG.pnpEnabled = false; persist()
				if ctx.stopPnpV1 then ctx.stopPnpV1() end
				if v1Render then v1Render() end -- sync visual toggle V1 -> OFF
				if ctx.startPnpV2 then ctx.startPnpV2() end
			else
				if ctx.stopPnpV2 then ctx.stopPnpV2() end
			end
		end, 5)

	-- Accordion: Automation Boost Pet
	local boostAcc = makeAccordion(pet, "Automation Boost Pet", 3, false)
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
			if not onScreen(stLbl) then task.wait(2) continue end
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
		function(v) CFG.autoFavorite = v; persist(); if v then ctx.startAutoFavorite() else ctx.stopAutoFavorite() end end, 1)
	makeMultiDropdown(fav, "Favourite Pet Types", "Pet types to keep favorited",
		reg.PET_OPTIONS, CFG.favoritePetTypes, function() persist() end, 2)

	------------------------------------------------------------------ MISC (log & webhooks)
	local misc = pageRef["Misc"]

	-- Player Accordion (Noclip / Walk Speed / Infinity Jump)
	local plAcc = makeAccordion(misc, "Player", 0, false)
	makeToggle(plAcc, "Noclip", "Walk through walls and obstacles",
		function() return CFG.noclipEnabled end,
		function(v) if ctx.setNoclip then ctx.setNoclip(v) end; persist() end, 1)
	makeInput(plAcc, "Walk Speed", "Player walk speed (default 16)",
		function() return tostring(CFG.walkSpeed) end,
		function(t) CFG.walkSpeed = tonumber(t) or 16; if ctx.applyWalkSpeed then ctx.applyWalkSpeed() end; persist() end, 2)
	makeToggle(plAcc, "Enable Walk Speed", "Apply custom walk speed",
		function() return CFG.walkSpeedEnabled end,
		function(v) if ctx.setWalkSpeed then ctx.setWalkSpeed(v) end; persist() end, 3)
	makeToggle(plAcc, "Infinity Jump", "Jump in mid-air infinitely",
		function() return CFG.infJumpEnabled end,
		function(v) if ctx.setInfJump then ctx.setInfJump(v) end; persist() end, 4)

	-- ESP Label Accordion
	local espAcc = makeAccordion(misc, "ESP Label (Pet & Egg)", 1, false)
	makeToggle(espAcc, "Enable ESP Label", "Label melayang di atas pet (nama+berat) & egg (nama+waktu hatch)",
		function() return CFG.espEnabled end,
		function(v)
			CFG.espEnabled = v; persist()
			if v then ctx.startEsp() else ctx.stopEsp() end
		end, 1)

	-- ESP Base Weight (Inventory) Accordion
	local espInvAcc = makeAccordion(misc, "ESP Base Weight (Inventory)", 2, false)
	makeToggle(espInvAcc, "Enable ESP Base Weight", "Tampilkan Base Weight di tiap slot pet saat buka inventory",
		function() return CFG.espInvEnabled end,
		function(v)
			CFG.espInvEnabled = v; persist()
			if v then ctx.startEspInv() else ctx.stopEspInv() end
		end, 1)
	local espInvModeOpts = { { name = "base", display = "Base Weight Only" }, { name = "age", display = "Base + Age" }, { name = "max", display = "Base + Max" } }
	makeSingleDropdown(espInvAcc, "Tampilan", "Pilih data yang tampil di label pet.",
		function() return espInvModeOpts end,
		function() for _, o in ipairs(espInvModeOpts) do if o.name == CFG.espInvMode then return o.display end end return "Base + Age" end,
		function(code) CFG.espInvMode = code; persist() end, 2)

	-- Automation Reconnect Accordion
	local rcAcc = makeAccordion(misc, "Automation Reconnect", 3, false)
	-- countdown live di paling atas
	local rcLbl = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Text = "Reconnect: OFF", Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0,
	}, rcAcc)
	mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 0 }, rcAcc)
	task.spawn(function()
		while ctx.alive() do
			if CFG.reconnectEnabled then
				local rem = ctx.state.reconnectRemaining
				if rem then
					rcLbl.Text = ("⏱ Reconnect in: %d:%02d"):format(math.floor(rem / 60), rem % 60)
				else
					rcLbl.Text = "⏱ Reconnect: ON"
				end
				rcLbl.TextColor3 = C.acc
			else
				rcLbl.Text = "Reconnect: OFF"
				rcLbl.TextColor3 = C.sub
			end
			task.wait(0.5)
		end
	end)
	makeInput(rcAcc, "Interval (menit)", "Auto reconnect/rejoin tiap sekian menit (mis. 1 = tiap 1 menit).",
		function() return tostring(CFG.reconnectInterval) end,
		function(t) CFG.reconnectInterval = tonumber(t) or 5; persist() end, 1)
	makeToggle(rcAcc, "Auto Reconnect", "Automatically rejoin server on disconnect",
		function() return CFG.reconnectEnabled end,
		function(v) CFG.reconnectEnabled = v; persist(); if v and ctx.startReconnect then ctx.startReconnect() end end, 2)

	-- Webhook Settings Accordion
	local whAcc = makeAccordion(misc, "Discord Webhook Settings", 4, true)

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

	-- Performance / Graphics Optimization Accordion
	local perfAcc = makeAccordion(misc, "Performance", 5, false)
	makeToggle(perfAcc, "Hide My Garden Plants", "Hide plants on your own farm for better FPS",
		function() return CFG.hideMyPlants end,
		function(v) if ctx.setHidePlants then ctx.setHidePlants("mine", v) end; persist() end, 1)
	makeToggle(perfAcc, "Hide Other Gardens Plants", "Hide plants on other players' farms",
		function() return CFG.hideOtherPlants end,
		function(v) if ctx.setHidePlants then ctx.setHidePlants("other", v) end; persist() end, 2)
	makeToggle(perfAcc, "Auto Remove Spider Web FX", "Continuously remove spider web particle effects",
		function() return CFG.autoRemoveWebFx end,
		function(v) if ctx.setAutoRemoveWeb then ctx.setAutoRemoveWeb(v) end; persist() end, 3)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "- [ Graphics Optimization ] -", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4 }, perfAcc)
	makeSingleDropdown(perfAcc, "Performance Mode", "Off: normal. Low: matiin shadow. Extreme: matiin semua efek partikel.",
		function() return ctx.getPerfModeOptions() end,
		function() local m = CFG.perfMode or "off"; for _, o in ipairs(ctx.getPerfModeOptions()) do if o.name == m then return o.display end end return "Off" end,
		function(code) if ctx.setPerfMode then ctx.setPerfMode(code) end; persist() end, 5)
	makeToggle(perfAcc, "Disable 3D Rendering", "Stop rendering the 3D world (huge FPS, black screen)",
		function() return CFG.disable3d end,
		function(v) if ctx.setDisable3d then ctx.setDisable3d(v) end; persist() end, 6)

	ctx.refreshTradeStatus()
end
]=],
	["ui/theme.lua"] = [=[
--[[ theme.lua — palet + helper Instance (garden, aksen kuning ala referensi). ]]
return function(ctx)
	local C = {
		bg      = Color3.fromRGB(20, 22, 28),
		panel   = Color3.fromRGB(14, 16, 20),
		row     = Color3.fromRGB(26, 29, 36),
		rowAlt  = Color3.fromRGB(22, 25, 31),
		stroke  = Color3.fromRGB(40, 44, 54),
		acc     = Color3.fromRGB(245, 200, 45),   -- kuning
		txt     = Color3.fromRGB(238, 240, 245),
		sub     = Color3.fromRGB(140, 146, 158),
		green   = Color3.fromRGB(90, 200, 120),
		red     = Color3.fromRGB(220, 80, 80),
	}

	local function mk(cls, props, parent)
		local o = Instance.new(cls); for k, v in pairs(props) do o[k] = v end; o.Parent = parent; return o
	end
	local function corner(o, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end
	local function stroke(o, col, thick)
		return mk("UIStroke", { Color = col or C.stroke, Thickness = thick or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	end
	local function pad(o, l, r, t, b)
		mk("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r), PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b) }, o)
	end

	ctx.C = C; ctx.mk = mk; ctx.corner = corner; ctx.stroke = stroke; ctx.pad = pad
end
]=],
	["ui/window.lua"] = [=[
--[[ window.lua — jendela utama garden: sidebar 8 tab, player card, status, log. ]]
return function(ctx)
	local Players = ctx.Services.Players
	local UserInputService = ctx.Services.UserInputService
	local LP = ctx.LP
	local C = ctx.C
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad

	ctx.ui.pages = {}
	ctx.ui.tabBtns = {}

	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		for _, nm in ipairs({ "GAGGarden", "AllegiaanGarden" }) do
			local old = host:FindFirstChild(nm); if old then old:Destroy() end
			local pg = LP:FindFirstChild("PlayerGui")
			if pg and pg:FindFirstChild(nm) then pg[nm]:Destroy() end
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "AllegiaanGarden"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LP:WaitForChild("PlayerGui")
	ctx.state.gui = gui
	ctx.state.isAlive = true
	gui.Destroying:Connect(function()
		ctx.state.isAlive = false
	end)

	-- floating maximize (logo AH)
	local maxIcon = mk("TextButton", { Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 15, 0.5, -23), BackgroundColor3 = C.panel, Text = "AH", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.acc, Visible = false, Active = true }, gui)
	corner(maxIcon, 23); stroke(maxIcon, C.acc, 1.5)
	pcall(function()
		local logo = ctx.getLogo and ctx.getLogo()
		if logo then
			maxIcon.Text = ""
			local img = mk("ImageLabel", { Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Fit }, maxIcon)
			corner(img, 21)
		end
	end)

	-- AnchorPoint tengah + Position tengah -> UIScale ngecilin dari titik tengah,
	-- jadi window tetap ke-center (penting di HP).
	local main = mk("Frame", { Size = UDim2.fromOffset(720, 470), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true }, gui)
	corner(main, 12); stroke(main, C.stroke, 1)

	-- Auto-scale: kecilin window proporsional biar muat di layar kecil (HP).
	local uiScale = Instance.new("UIScale"); uiScale.Parent = main
	local function fitScale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		-- sisain margin ~40px; jangan gede-in di atas 1x; baca ukuran window terkini
		local w, h = main.Size.X.Offset, main.Size.Y.Offset
		local s = math.min(1, (vp.X - 40) / w, (vp.Y - 40) / h)
		uiScale.Scale = math.max(0.4, s)
	end
	fitScale()
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale) end
	end)

	-- title bar
	local titleBar = mk("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, main)
	mk("TextLabel", { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, Text = "AllegiaantHub VIP | Grow a Garden", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.acc, TextXAlignment = Enum.TextXAlignment.Left }, titleBar)
	do
		local dragging, ds, sp
		titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = main.Position end end)
		UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	end

	local minBtn = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -70, 0, 8), BackgroundColor3 = C.row, Text = "-", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.txt }, titleBar)
	corner(minBtn, 6)
	local closeBtn = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -36, 0, 8), BackgroundColor3 = C.row, Text = "X", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt }, titleBar)
	corner(closeBtn, 6)

	-- Premium Hover Animations
	minBtn.MouseEnter:Connect(function() minBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65) end)
	minBtn.MouseLeave:Connect(function() minBtn.BackgroundColor3 = C.row end)
	closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = C.red; closeBtn.TextColor3 = Color3.new(1, 1, 1) end)
	closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = C.row; closeBtn.TextColor3 = C.txt end)

	minBtn.MouseButton1Click:Connect(function() main.Visible = false; maxIcon.Visible = true end)
	maxIcon.MouseButton1Click:Connect(function() maxIcon.Visible = false; main.Visible = true end)

	-- Konfirmasi sebelum close (Yes/No). Overlay modal di atas window.
	local function confirmClose()
		local overlay = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 50, Active = true }, main)
		local box = mk("Frame", { Size = UDim2.fromOffset(300, 150), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.panel, BorderSizePixel = 0, ZIndex = 51 }, overlay)
		corner(box, 12); stroke(box, C.stroke, 1)
		mk("TextLabel", { Size = UDim2.new(1, -24, 0, 36), Position = UDim2.fromOffset(12, 16), BackgroundTransparency = 1, Text = "Close AllegiaantHub?", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.acc, ZIndex = 51 }, box)
		mk("TextLabel", { Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 52), BackgroundTransparency = 1, Text = "Yakin mau nutup hub ini?", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt, ZIndex = 51 }, box)
		local noBtn = mk("TextButton", { Size = UDim2.fromOffset(120, 38), Position = UDim2.new(0, 18, 1, -50), BackgroundColor3 = C.row, Text = "No", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, ZIndex = 51 }, box)
		corner(noBtn, 8)
		local yesBtn = mk("TextButton", { Size = UDim2.fromOffset(120, 38), Position = UDim2.new(1, -138, 1, -50), BackgroundColor3 = C.red, Text = "Yes", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), ZIndex = 51 }, box)
		corner(yesBtn, 8)
		noBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)
		yesBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
	end
	closeBtn.MouseButton1Click:Connect(confirmClose)
	do
		local dragging, ds, sp
		maxIcon.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = maxIcon.Position end end)
		UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; maxIcon.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	end

	-- sidebar
	local sidebar = mk("Frame", { Size = UDim2.new(0, 180, 1, -52), Position = UDim2.fromOffset(8, 48), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, main)
	corner(sidebar, 10); pad(sidebar, 10, 10, 10, 10)

	local tabButtonsFrame = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.acc, ScrollBarImageTransparency = 0.4,
		ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingEnabled = true,
	}, sidebar)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabButtonsFrame)

	-- player card
	local card = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), Position = UDim2.new(0, 0, 1, -48), BackgroundColor3 = C.row, BorderSizePixel = 0 }, sidebar)
	corner(card, 8); stroke(card); pad(card, 6, 6, 6, 6)
	local avatar = mk("ImageLabel", { Size = UDim2.fromOffset(34, 34), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, card)
	corner(avatar, 17); stroke(avatar, C.stroke, 1)
	pcall(function() avatar.Image = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
	local nameLbl = mk("TextLabel", { Size = UDim2.new(1, -42, 1, 0), Position = UDim2.fromOffset(42, 0), BackgroundTransparency = 1, Text = LP.DisplayName, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)

	-- content
	local content = mk("Frame", { Size = UDim2.new(1, -206, 1, -66), Position = UDim2.fromOffset(196, 50), BackgroundTransparency = 1 }, main)

	-- Resize grip (pojok kanan-bawah). Drag buat ubah ukuran window.
	local grip = mk("TextButton", { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -22, 1, -22), BackgroundTransparency = 1, Text = "◢", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.sub, AutoButtonColor = false, Active = true, ZIndex = 20 }, main)
	grip.MouseEnter:Connect(function() grip.TextColor3 = C.acc end)
	grip.MouseLeave:Connect(function() grip.TextColor3 = C.sub end)
	do
		local rz, ds, ss
		grip.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				rz = true; ds = i.Position; ss = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if rz and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local scale = uiScale.Scale > 0 and uiScale.Scale or 1
				local d = i.Position - ds
				local w = math.clamp(ss.X + d.X / scale, 480, 1600)
				local h = math.clamp(ss.Y + d.Y / scale, 320, 1000)
				main.Size = UDim2.fromOffset(w, h)
				fitScale() -- pastiin tetap muat di layar
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then rz = false end
		end)
	end

	-- status footer (disembunyikan; automation punya panel status sendiri)
	local statusText = mk("TextLabel", { Size = UDim2.new(1, -206, 0, 18), Position = UDim2.new(0, 196, 1, -22), BackgroundTransparency = 1, Text = "Status: idle", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, Visible = false }, main)

	function ctx.setStatus(s)
		statusText.Text = "Status: " .. tostring(s)
	end

	local logLines = ctx.state.logLines
	function ctx.log(msg)
		table.insert(logLines, os.date("%H:%M:%S ") .. msg)
		while #logLines > 12 do table.remove(logLines, 1) end
		if ctx.ui.logBox then ctx.ui.logBox.Text = table.concat(logLines, "\n") end
	end

	ctx.ui.main = main
	ctx.ui.content = content
	ctx.ui.tabButtonsFrame = tabButtonsFrame
	ctx.ui.statusText = statusText
end
]=],
}
