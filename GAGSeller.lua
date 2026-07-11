--[[
	GAG Seller — Trade World (Grow a Garden)
	GUI ala PandoruyHub: multi-profile listing + portal auto-claim + booth skin selector.
	Jalan: loadstring(readfile("GAGSeller.lua"))()
--]]

local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CollectionService= game:GetService("CollectionService")

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until Players.LocalPlayer
local LP = Players.LocalPlayer

------------------------------------------------------------------ deps
local RR            = require(RS.Modules.ReplicationReciever)
local DataService   = require(RS.Modules.DataService)
local TradeBoothsData = require(RS.Data.TradeBoothsData)
local PU            = require(RS.Modules.PetServices.PetUtilities)
local PetEggs       = require(RS.Data.PetRegistry.PetEggs)
local MutReg        = require(RS.Data.PetRegistry.PetMutationRegistry)
local SkinsReg      = require(RS.Data.TradeBoothSkinRegistry)
local EnumToMut     = MutReg.EnumToPetMutation
local Booths        = RS.GameEvents.TradeEvents.Booths
local ClaimBooth    = Booths.ClaimBooth
local CreateListing = Booths.CreateListing
local RemoveBooth   = Booths.RemoveBooth
local RemoveListing = Booths.RemoveListing
local EquipSkin     = RS.GameEvents.TradeBoothSkinService.Equip

-- opsi dropdown = kombinasi "Pet - Egg"
local function comboKey(petType, egg) return tostring(petType) .. " - " .. tostring(egg) end
local PET_OPTIONS = {}
do
	local seen = {}
	for eggName, egg in pairs(PetEggs) do
		local items = egg.RarityData and egg.RarityData.Items
		if items then
			for petName in pairs(items) do
				if not tostring(petName):match("^Egg/") then
					local nameStr = tostring(petName)
					if not seen[nameStr] then seen[nameStr] = true; PET_OPTIONS[#PET_OPTIONS+1] = nameStr end
				end
			end
		end
	end
	table.sort(PET_OPTIONS)
end

local MUT_OPTIONS, seenMut = { "None" }, { None = true }
for _, name in pairs(EnumToMut) do
	if name ~= "Normal" and not seenMut[name] then
		seenMut[name] = true
		MUT_OPTIONS[#MUT_OPTIONS+1] = name
	end
end
table.sort(MUT_OPTIONS)

local SKIN_OPTIONS = {}
for name, data in pairs(SkinsReg) do
	SKIN_OPTIONS[#SKIN_OPTIONS+1] = { name = name, display = data.DisplayName or name }
end
table.sort(SKIN_OPTIONS, function(a, b) return a.display < b.display end)

local function mutDisplay(code)
	if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
	return EnumToMut[code] or code
end

------------------------------------------------------------------ config + state
local NUM_PROFILES = 3
local NUM_LISTINGS = 3
local CFG = {
	autoSell         = false,
	autoClaim        = true,
	autoSwitchPortal = false,
	boothSkin        = "Default",
	profiles         = {},
	webhookUrl       = "",
	webhookEnabled   = false,
}
for i = 1, NUM_PROFILES do
	CFG.profiles[i] = { listings = {} }
	for j = 1, NUM_LISTINGS do
		CFG.profiles[i].listings[j] = { pets = {}, muts = {}, minW = 0, maxW = 0, maxList = 0, price = 100 }
	end
end
local running = false
local gui
local log, setStatus

local STATE_FILE = "GAGSeller_state.json"
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
		if st.autoClaim ~= nil then CFG.autoClaim = st.autoClaim end
		if st.autoSwitchPortal ~= nil then CFG.autoSwitchPortal = st.autoSwitchPortal end
		CFG.boothSkin = st.boothSkin or "Default"
		CFG.autoSell = st.autoSell or false
		CFG.webhookUrl = st.webhookUrl or ""
		CFG.webhookEnabled = st.webhookEnabled or false
		if type(st.profiles) == "table" then
			for i = 1, NUM_PROFILES do
				local sp = st.profiles[i] or st.profiles[tostring(i)]
				if type(sp) == "table" and type(sp.listings) == "table" then
					for j = 1, NUM_LISTINGS do
						local sl = sp.listings[j] or sp.listings[tostring(j)]
						if type(sl) == "table" then
							CFG.profiles[i].listings[j].pets    = (type(sl.pets) == "table") and sl.pets or {}
							CFG.profiles[i].listings[j].muts    = (type(sl.muts) == "table") and sl.muts or {}
							CFG.profiles[i].listings[j].minW    = tonumber(sl.minW) or 0
							CFG.profiles[i].listings[j].maxW    = tonumber(sl.maxW) or 0
							CFG.profiles[i].listings[j].maxList = tonumber(sl.maxList) or 0
							CFG.profiles[i].listings[j].price   = tonumber(sl.price) or 100
						end
					end
				end
			end
		end
	end
end

local function alive() return gui ~= nil and gui.Parent ~= nil end
local function elevate()
	pcall(function()
		local f = setthreadidentity or setidentity or (syn and syn.set_thread_identity) or (getgenv and getgenv().setthreadidentity)
		if f then f(7) end
	end)
end

------------------------------------------------------------------ helpers
local function getTokens()
	local ok, data = pcall(function() return DataService:GetData() end)
	if ok and type(data) == "table" and type(data.TradeData) == "table" then
		return data.TradeData.Tokens or 0
	end
	return 0
end
local function myPlayerId() return TradeBoothsData.getPlayerId(LP) end

local function weightOf(petType, pd)
	return pd.BaseWeight or 0
end

local function ownsBooth()
	local ok, data = pcall(function() return RR.new("Booths"):GetDataAsync() end)
	if not ok or not data then return false, nil, nil end
	local id = myPlayerId()
	local playerRecord = data.Players and data.Players[id]
	local boothName = playerRecord and playerRecord.Booth
	return boothName ~= nil, data, boothName
end

local function tryClaimNearest()
	local owns, data = ownsBooth()
	if owns then return true end
	if not data then return false end
	local charPos
	local char = LP.Character
	if char and char:FindFirstChild("HumanoidRootPart") then charPos = char.HumanoidRootPart.Position end
	local list = {}
	for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
		local b = data.Booths and data.Booths[inst.Name]
		if (b == nil) or (b.Owner == nil) then
			local dist = 999999
			if charPos then
				local ok2, piv = pcall(function() return inst:GetPivot().Position end)
				if ok2 then dist = (piv - charPos).Magnitude end
			end
			list[#list+1] = { inst = inst, dist = dist }
		end
	end
	if #list == 0 then log("Tidak ada booth kosong."); return false end
	table.sort(list, function(a, b) return a.dist < b.dist end)
	local pick = list[1]
	
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = pick.inst:GetPivot() * CFrame.new(0, 3, 3)
		task.wait(0.25)
	end
	
	pcall(function() ClaimBooth:FireServer(pick.inst) end)
	log(("Claim booth terdekat (%dstud, %d kosong)..."):format(math.floor(pick.dist), #list))
	return false
end

local function ensureBooth()
	local owns = ownsBooth()
	if owns then return true end
	if CFG.autoClaim then return tryClaimNearest() end
	return false
end

-- Auto Switch to Booth Near Portal
local function autoSwitchBoothPortal()
	if not CFG.autoSwitchPortal then return end
	local owns, data, boothName = ownsBooth()
	if not owns or not data or not boothName then return end
	-- Cari portal Trade World (bukan lobby)
	local tradeWorld = workspace:FindFirstChild("TradeWorld")
	local portal = nil
	if tradeWorld then
		local pp = tradeWorld:FindFirstChild("PortalPetePlatform")
		if pp then portal = pp:FindFirstChild("Portal") or pp end
		if not portal then portal = tradeWorld:FindFirstChild("Portal Pete", true) end
	end
	if not portal then
		portal = workspace:FindFirstChild("Portal Pete", true) or workspace:FindFirstChild("Portal", true)
	end
	local portalPos = portal and portal:GetPivot().Position or Vector3.new(0, 0, 0)

	local myBoothInst = nil
	for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
		if inst.Name == boothName then myBoothInst = inst; break end
	end
	if not myBoothInst then return end

	local myDist = (myBoothInst:GetPivot().Position - portalPos).Magnitude
	local bestBooth = nil
	local bestDist = myDist

	for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
		local b = data.Booths and data.Booths[inst.Name]
		if (b == nil) or (b.Owner == nil) then
			local pDist = (inst:GetPivot().Position - portalPos).Magnitude
			if pDist < bestDist - 8 then -- harus lebih dekat minimal 8 stud agar worth-it pindah
				bestDist = pDist
				bestBooth = inst
			end
		end
	end

	if bestBooth then
		log(("Pindah ke booth lebih dekat portal (Lama: %dstud, Baru: %dstud)"):format(math.floor(myDist), math.floor(bestDist)))
		pcall(function() RemoveBooth:FireServer() end)
		task.wait(0.5)

		local char = LP.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = bestBooth:GetPivot() * CFrame.new(0, 3, 3)
			task.wait(0.25)
		end

		pcall(function() ClaimBooth:FireServer(bestBooth) end)
	end
end

------------------------------------------------------------------ Discord Webhook
local function sendWebhook(payload)
	if not CFG.webhookEnabled or CFG.webhookUrl == "" then return end
	task.spawn(function()
		local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
		if not reqFn then return end
		pcall(reqFn, {
			Url = CFG.webhookUrl, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload),
		})
	end)
end

-- list pet di inventory
local function inventoryCounts()
	local counts = {}
	local ok, data = pcall(function() return DataService:GetData() end)
	if ok and type(data) == "table" and data.PetsData and data.PetsData.PetInventory and data.PetsData.PetInventory.Data then
		for _, v in pairs(data.PetsData.PetInventory.Data) do
			local pt = v and v.PetType
			if pt then counts[pt] = (counts[pt] or 0) + 1 end
		end
	end
	return counts
end

local function selectedPetTypes()
	local set, order = {}, {}
	for pi = 1, NUM_PROFILES do
		local prof = CFG.profiles[pi]
		if prof and type(prof.listings) == "table" then
			for li = 1, NUM_LISTINGS do
				local sub = prof.listings[li]
				if sub and type(sub.pets) == "table" then
					for petKey in pairs(sub.pets) do
						local pt = (string.split(petKey, " - ")[1]) or petKey
						if not set[pt] then set[pt] = true; order[#order+1] = pt end
					end
				end
			end
		end
	end
	table.sort(order)
	return order
end

local function buildSummary()
	local counts = inventoryCounts()
	local lines, total = {}, 0
	for _, pt in ipairs(selectedPetTypes()) do
		local c = counts[pt] or 0
		total = total + c
		lines[#lines+1] = ("%s: %d"):format(pt, c)
	end
	return (#lines > 0 and table.concat(lines, "\n") or "-"), total
end

-- satu putaran listing: STRICT SEQUENTIAL P1L1→P1L2→P1L3→P2L1→...
-- Setiap listing harus TEPAT maxList sebelum lanjut ke listing berikutnya
local listedSet = {}
local function listPass()
	local owns, bData, boothName = ownsBooth()
	if not owns or not boothName then return 0 end
	
	-- Teleport ke booth jika terlalu jauh agar lolos cek jarak server
	local myBoothInst = nil
	for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
		if inst.Name == boothName then myBoothInst = inst; break end
	end
	if myBoothInst then
		local char = LP.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local root = char.HumanoidRootPart
			if (root.Position - myBoothInst:GetPivot().Position).Magnitude > 8 then
				root.CFrame = myBoothInst:GetPivot() * CFrame.new(0, 3, 3)
				task.wait(0.25)
			end
		end
	end

	-- Ambil data booth & inventory TERBARU
	local myId = myPlayerId()
	local myRecord = bData.Players and (bData.Players[myId] or bData.Players[tostring(myId)])
	local currentList = myRecord and myRecord.Listings or {}

	-- REBUILD listedSet dari booth aktual (agar pet yang sudah dibeli otomatis hilang)
	listedSet = {}
	for _, l in pairs(currentList) do
		if l.ItemId then listedSet[l.ItemId] = true end
	end

	local ok, data = pcall(function() return DataService:GetData() end)
	if not ok or not (data and data.PetsData and data.PetsData.PetInventory) then return 0 end
	local pets  = data.PetsData.PetInventory.Data
	local locks = (data.TradeData and data.TradeData.TradeLocks and data.TradeData.TradeLocks.Pet) or {}
	
	local equippedSet = {}
	if data.PetsData and data.PetsData.EquippedPets then
		for _, eqUuid in ipairs(data.PetsData.EquippedPets) do
			equippedSet[eqUuid] = true
		end
	end

	-- Track UUID booth yang sudah di-claim listing sebelumnya (anti double-count)
	local claimedByOther = {}
	local total = 0

	-- Helper: cek pet cocok dengan listing config
	local function petMatches(petType, pd, sub)
		if not (sub.pets[petType] or sub.pets[comboKey(petType, pd.HatchedFrom or "?")]) then return false end
		local mut = mutDisplay(pd.MutationType)
		local mutOK
		if not next(sub.muts) then mutOK = (mut == "None") else mutOK = sub.muts[mut] == true end
		if not mutOK then return false end
		local w = weightOf(petType, pd)
		local minW = (sub.minW or 0) > 0 and (sub.minW - 0.5) or 0
		local maxW = (sub.maxW or 0) > 0 and (sub.maxW - 0.5) or 0
		return (w >= minW) and (maxW <= 0 or w <= maxW)
	end

	-- STRICT SEQUENTIAL: P1L1 → P1L2 → P1L3 → P2L1 → P2L2 → ...
	for pi = 1, NUM_PROFILES do
		local prof = CFG.profiles[pi]
		if prof and type(prof.listings) == "table" then
			for li = 1, NUM_LISTINGS do
				if not running then return total end
				local sub = prof.listings[li]
				if sub and next(sub.pets) and (sub.price or 0) > 0 then
					local cap = (sub.maxList and sub.maxList > 0) and sub.maxList or 0
					if cap <= 0 then -- skip listing tanpa max cap
					else
						-- STEP 1: Hitung berapa pet di booth yang cocok listing ini
						local boothCount = 0
						for _, l in pairs(currentList) do
							local itemUuid = l.ItemId
							if itemUuid and not claimedByOther[itemUuid] then
								local invPet = pets[itemUuid]
								if invPet and invPet.PetType and invPet.PetData then
									if petMatches(invPet.PetType, invPet.PetData, sub) then
										boothCount = boothCount + 1
										claimedByOther[itemUuid] = true
									end
								end
							end
						end

						-- STEP 2: Kalau belum penuh, tambah sampai tepat cap
						local needed = cap - boothCount
						if needed > 0 then
							log(("P%d-L%d: %d/%d di booth, perlu +%d"):format(pi, li, boothCount, cap, needed))
							local added = 0
							for uuid, v in pairs(pets) do
								if not running then return total end
								if added >= needed then break end
								local pd = v.PetData
								if v.PetType and pd and not pd.IsFavorite 
									and not locks[uuid] and not listedSet[uuid] 
									and not equippedSet[uuid] and not claimedByOther[uuid] then
									if petMatches(v.PetType, pd, sub) then
										local ok2, res = pcall(function() return CreateListing:InvokeServer("Pet", uuid, math.floor(sub.price)) end)
										if ok2 and res then
											listedSet[uuid] = true
											claimedByOther[uuid] = true
											added = added + 1
											total = total + 1
											local mut = mutDisplay(pd.MutationType)
											local w = weightOf(v.PetType, pd)
											log(("LIST %s [%s] %.2fkg @%d (P%d-L%d) [%d/%d]"):format(v.PetType, mut, w, sub.price, pi, li, boothCount + added, cap))
											
											sendWebhook({
												username = "GAG Seller",
												embeds = {{
													title = "📦 Pet Terpajang!",
													color = 10181046,
													fields = {
														{ name = "Pet", value = tostring(v.PetType), inline = true },
														{ name = "Mutation", value = tostring(mut), inline = true },
														{ name = "Weight", value = ("%.2f KG"):format(w), inline = true },
														{ name = "Price", value = tostring(sub.price) .. " Tokens", inline = true },
														{ name = "Profile", value = "P" .. pi .. "-L" .. li, inline = true },
													},
													footer = { text = "JobId: " .. tostring(game.JobId) }
												}}
											})
											task.wait(5)
										else
											log(("FAIL list %s (%s)"):format(v.PetType, tostring(res)))
											task.wait(3) -- tunggu rate limit hilang
										end
									end
								end
							end
							-- Kalau stock habis, SKIP ke listing berikutnya (jangan stuck)
							if boothCount + added < cap then
								log(("P%d-L%d: stock habis, baru %d/%d. Skip ke listing berikutnya."):format(pi, li, boothCount + added, cap))
							end
						end
						-- Kalau sudah penuh (needed <= 0), lanjut ke listing berikutnya ✓
					end
				end
			end
		end
	end
	return total
end

local function anyProfileActive()
	for i = 1, NUM_PROFILES do
		local prof = CFG.profiles[i]
		if prof and type(prof.listings) == "table" then
			for j = 1, NUM_LISTINGS do
				if next(prof.listings[j].pets) then return true end
			end
		end
	end
	return false
end
local currentLoopId = 0
local function mainLoop()
	currentLoopId = currentLoopId + 1
	local myLoopId = currentLoopId
	elevate()
	while running and alive() and currentLoopId == myLoopId do
		if not anyProfileActive() then
			setStatus("Pilih pet di profil listing dulu.")
			task.wait(2)
		else
			local ready = true
			if CFG.autoClaim then ready = ensureBooth() end
			if ready then
				local n = listPass()
				if n > 0 then
					setStatus(("Refill +%d | Token:%s"):format(n, tostring(getTokens())))
					task.wait(2) -- cepat cek lagi karena baru ada perubahan
				else
					setStatus(("Booth OK ✓ | Token:%s"):format(tostring(getTokens())))
					task.wait(3) -- semua penuh, monitoring mode
				end
			else
				setStatus("Menunggu booth ke-claim...")
				task.wait(2.5)
			end
		end
	end
end


-- unlist & unequip util
local function unlistAll()
	local owns, data, boothName = ownsBooth()
	if not owns or not data or not boothName then log("Kamu tidak punya booth."); return end
	
	-- Temukan booth instance untuk teleportasi (agar lolos cek jarak server)
	local myBoothInst = nil
	for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
		if inst.Name == boothName then myBoothInst = inst; break end
	end
	if myBoothInst then
		local char = LP.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = myBoothInst:GetPivot() * CFrame.new(0, 3, 3)
			task.wait(0.25)
		end
	end

	local myId = myPlayerId()
	local pd = data.Players and (data.Players[myId] or data.Players[tostring(myId)])
	local list = pd and pd.Listings or {}
	local count = 0
	for lid, _ in pairs(list) do
		local ok, res = pcall(function() return RemoveListing:InvokeServer(lid) end)
		if ok and res then count += 1; task.wait(0.1) end
	end
	listedSet = {}
	log(("Sukses menghapus %d pajangan."):format(count))
end

local function unequipAllPets()
	local ok, PetsService = pcall(require, RS.Modules.PetServices.PetsService)
	if not ok or not PetsService then log("Gagal memuat PetsService."); return end
	local ok2, data = pcall(function() return DataService:GetData() end)
	if ok2 and data and data.PetsData and data.PetsData.EquippedPets then
		local count = 0
		for _, uuid in ipairs(data.PetsData.EquippedPets) do
			local ok3 = pcall(function() PetsService:UnequipPet(uuid) end)
			if ok3 then count += 1 end
		end
		log(("Unequipped %d pets."):format(count))
	else
		log("Tidak ada pet yang aktif terpasang.")
	end
end

------------------------------------------------------------------ GUI
-- bersihkan GUI lama
pcall(function()
	local host = (gethui and gethui()) or game:GetService("CoreGui")
	local old = host:FindFirstChild("GAGSeller"); if old then old:Destroy() end
	local pg = LP:FindFirstChild("PlayerGui")
	if pg and pg:FindFirstChild("GAGSeller") then pg.GAGSeller:Destroy() end
end)

gui = Instance.new("ScreenGui")
gui.Name = "GAGSeller"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LP:WaitForChild("PlayerGui")

local C = {
	bg    = Color3.fromRGB(15, 15, 20),      -- Jendela utama transparan
	panel = Color3.fromRGB(10, 10, 12),      -- Left sidebar
	row   = Color3.fromRGB(24, 24, 30),      -- Kartu setting / baris
	stroke= Color3.fromRGB(35, 35, 45),      -- Pembatas kartu
	acc   = Color3.fromRGB(120, 80, 255),    -- Neon Purple
	txt   = Color3.fromRGB(240, 240, 245),
	sub   = Color3.fromRGB(140, 140, 150),
	green = Color3.fromRGB(80, 200, 120),
	red   = Color3.fromRGB(220, 80, 80),
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

-- Floating Maximize Button
local maxIcon = mk("TextButton", {
	Size = UDim2.fromOffset(45, 45), Position = UDim2.new(0, 15, 0.5, -22),
	BackgroundColor3 = C.panel, Text = "AH", Font = Enum.Font.GothamBold, TextSize = 14,
	TextColor3 = C.acc, Visible = false, Active = true,
}, gui)
corner(maxIcon, 22)
stroke(maxIcon, C.acc, 1.5)
do
	local dragging, ds, sp
	maxIcon.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = maxIcon.Position end end)
	UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; maxIcon.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end

-- Main Jendela
local main = mk("Frame", {
	Size = UDim2.fromOffset(650, 450), Position = UDim2.new(0.5, -325, 0.5, -225),
	BackgroundColor3 = C.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Active = true,
}, gui)
corner(main, 10)
stroke(main, C.stroke, 1)

-- Title bar & Dragger
local titleBar = mk("Frame", {
	Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.panel, BackgroundTransparency = 1, BorderSizePixel = 0
}, main)
do
	local dragging, ds, sp
	titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = main.Position end end)
	UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end

local minBtn = mk("TextButton", {
	Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -64, 0, 7), BackgroundColor3 = C.row,
	Text = "—", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.txt, ZIndex = 3,
}, titleBar)
corner(minBtn, 6)
local closeBtn = mk("TextButton", {
	Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0, 7), BackgroundColor3 = C.row,
	Text = "✕", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.txt, ZIndex = 3,
}, titleBar)
corner(closeBtn, 6)

minBtn.MouseButton1Click:Connect(function() main.Visible = false; maxIcon.Visible = true end)
maxIcon.MouseButton1Click:Connect(function() maxIcon.Visible = false; main.Visible = true end)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Left Sidebar
local sidebar = mk("Frame", {
	Size = UDim2.new(0, 160, 1, 0), BackgroundColor3 = C.panel, BorderSizePixel = 0
}, main)
corner(sidebar, 10)
pad(sidebar, 12, 12, 12, 12)

local logo = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, sidebar)
mk("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
	Text = "PandoruyHub | GAG Trade", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.acc,
	TextXAlignment = Enum.TextXAlignment.Left,
}, logo)

local tabButtonsFrame = mk("Frame", {
	Size = UDim2.new(1, 0, 1, -94), Position = UDim2.fromOffset(0, 38), BackgroundTransparency = 1
}, sidebar)
mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabButtonsFrame)

-- Profile Card di Sidebar bawah
local profileCard = mk("Frame", {
	Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44),
	BackgroundColor3 = C.row, BorderSizePixel = 0,
}, sidebar)
corner(profileCard, 8)
stroke(profileCard)
pad(profileCard, 6, 6, 6, 6)

local avatar = mk("ImageLabel", {
	Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.panel, BorderSizePixel = 0
}, profileCard)
corner(avatar, 16)
stroke(avatar, C.stroke, 1)
pcall(function()
	avatar.Image = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
end)

local nameLabel = mk("TextLabel", {
	Size = UDim2.new(1, -38, 1, 0), Position = UDim2.fromOffset(38, 0), BackgroundTransparency = 1,
	Text = LP.Name, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.txt,
	TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, profileCard)
pcall(function()
	local short = LP.DisplayName
	if #short > 11 then short = short:sub(1, 9) .. ".." end
	nameLabel.Text = short
end)

-- Right Content Frame
local content = mk("Frame", {
	Size = UDim2.new(1, -172, 1, -20), Position = UDim2.fromOffset(166, 12), BackgroundTransparency = 1
}, main)

-- reusable controls
local function makeToggle(parent, title, desc, getv, setv, order)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = order }, parent)
	local txts = mk("Frame", { Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1 }, row)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)
	
	local knob = mk("TextButton", { Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -38, 0.5, -9), BackgroundColor3 = C.panel, Text = "", AutoButtonColor = false }, row)
	corner(knob, 9); stroke(knob, C.stroke)
	local dot = mk("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.sub }, knob)
	corner(dot, 6)

	local function render()
		local on = getv()
		dot:TweenPosition(on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3), "Out", "Quad", 0.15, true)
		knob.BackgroundColor3 = on and C.acc or C.panel
		dot.BackgroundColor3 = on and Color3.new(1,1,1) or C.sub
	end
	knob.MouseButton1Click:Connect(function() setv(not getv()); render() end)
	render()
	return render
end

local function makeInput(parent, title, desc, getv, setv, order)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = order }, parent)
	local txts = mk("Frame", { Size = UDim2.new(1, -130, 1, 0), BackgroundTransparency = 1 }, row)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 2), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 20), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)
	
	local box = mk("TextBox", { Size = UDim2.fromOffset(110, 26), Position = UDim2.new(1, -112, 0.5, -13), BackgroundColor3 = C.panel, Text = tostring(getv()), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.acc, ClearTextOnFocus = false }, row)
	corner(box, 6); stroke(box)
	box.FocusLost:Connect(function() setv(box.Text); box.Text = tostring(getv()) end)
	return box
end

local function makeDropdown(parent, title, desc, options, selSet, onChange, order)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)
	
	local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
	local txts = mk("Frame", { Size = UDim2.new(1, -200, 1, 0), BackgroundTransparency = 1 }, head)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)
	
	local valLbl = mk("TextLabel", { Size = UDim2.new(0, 180, 1, 0), Position = UDim2.new(1, -200, 0, 0), BackgroundTransparency = 1, Text = "Select Options", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right }, head)
	local arrow = mk("TextLabel", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -12, 0.5, -6), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center }, head)

	local function updateSummary()
		local sel = {}
		for _, o in ipairs(options) do if selSet[o] then sel[#sel+1] = o end end
		if #sel == 0 then valLbl.Text = "Select Options"; valLbl.TextColor3 = C.sub
		else
			local txt = table.concat(sel, ", ")
			if #txt > 20 then txt = ("%d selected"):format(#sel) end
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
	local function buildOptions()
		if built then return end
		built = true
		for _, opt in ipairs(options) do
			local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. opt, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
			corner(ob, 4)
			local check = mk("TextLabel", { Size = UDim2.fromOffset(20, 24), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.green }, ob)
			local function rend() check.Text = selSet[opt] and "✓" or ""; ob.BackgroundColor3 = selSet[opt] and Color3.fromRGB(40, 44, 60) or C.row end
			ob.MouseButton1Click:Connect(function()
				if selSet[opt] then selSet[opt] = nil else selSet[opt] = true end
				rend(); updateSummary(); if onChange then onChange() end
			end)
			rend()
			optBtns[opt] = ob
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = search.Text:lower()
		for opt, ob in pairs(optBtns) do ob.Visible = (q == "" or opt:lower():find(q, 1, true) ~= nil) end
	end)
	head.MouseButton1Click:Connect(function()
		if not built then buildOptions() end
		listFrame.Visible = not listFrame.Visible
		arrow.Text = listFrame.Visible and "^" or "v"
	end)
	updateSummary()
	return updateSummary
end

local function makeSingleDropdown(parent, title, desc, options, getv, setv, order)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)

	local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
	local txts = mk("Frame", { Size = UDim2.new(1, -200, 1, 0), BackgroundTransparency = 1 }, head)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 2), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 20), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)

	local initialDisplay = getv()
	for _, opt in ipairs(options) do
		if type(opt) == "table" and opt.name == getv() then
			initialDisplay = opt.display
			break
		elseif type(opt) == "string" and opt == getv() then
			initialDisplay = opt
			break
		end
	end

	local valLbl = mk("TextLabel", { Size = UDim2.new(0, 180, 1, 0), Position = UDim2.new(1, -200, 0, 0), BackgroundTransparency = 1, Text = initialDisplay, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right }, head)
	local arrow = mk("TextLabel", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -12, 0.5, -6), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center }, head)

	local listFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 160), BackgroundColor3 = C.panel, Visible = false, LayoutOrder = 2 }, row)
	corner(listFrame, 6); stroke(listFrame)
	local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, listFrame)
	mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

	local built = false
	local function buildOptions()
		if built then return end
		built = true
		for _, opt in ipairs(options) do
			local displayVal = type(opt) == "table" and opt.display or opt
			local codeVal = type(opt) == "table" and opt.name or opt
			local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. displayVal, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
			corner(ob, 4)
			ob.MouseButton1Click:Connect(function()
				setv(codeVal)
				valLbl.Text = displayVal
				listFrame.Visible = false
				arrow.Text = "v"
			end)
		end
	end
	head.MouseButton1Click:Connect(function()
		if not built then buildOptions() end
		listFrame.Visible = not listFrame.Visible
		arrow.Text = listFrame.Visible and "^" or "v"
	end)
	return head
end

local function makeButton(parent, title, color, onClick, order)
	local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = color or C.acc, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1,1,1), LayoutOrder = order }, parent)
	corner(btn, 6); stroke(btn, C.stroke)
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function makeAccordion(parent, title, order)
	local container = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.row, BorderSizePixel = 0, LayoutOrder = order, ClipsDescendants = false }, parent)
	corner(container, 8); stroke(container)
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, container)
	
	local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, container)
	pad(head, 12, 12, 0, 0)
	
	local lbl = mk("TextLabel", { Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, head)
	local arrow = mk("TextLabel", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -12, 0.5, -6), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center }, head)
	
	local body = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2 }, container)
	pad(body, 12, 12, 0, 12)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	
	head.MouseButton1Click:Connect(function()
		body.Visible = not body.Visible
		arrow.Text = body.Visible and "^" or "v"
	end)
	return body
end

-- Tab Management
local pages, tabBtns = {}, {}
local function makePage(name, titleText, iconLabel, order)
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 1,
		Text = "     " .. iconLabel .. " | " .. name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.sub,
		LayoutOrder = order, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left
	}, tabButtonsFrame)
	corner(btn, 6)
	
	local line = mk("Frame", { Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 4, 0.5, -9), BackgroundColor3 = C.acc, Visible = false }, btn)
	corner(line, 2)
	tabBtns[name] = { btn = btn, line = line }

	local pg = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 4,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc
	}, content)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pg)
	pages[name] = pg

	local pageHeader = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 0 }, pg)
	mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = titleText, Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, pageHeader)

	btn.MouseButton1Click:Connect(function()
		for n, p in pairs(pages) do p.Visible = (n == name) end
		for n, b in pairs(tabBtns) do
			b.btn.BackgroundTransparency = (n == name) and 0.9 or 1
			b.btn.TextColor3 = (n == name) and C.txt or C.sub
			b.line.Visible = (n == name)
		end
	end)
	return pg
end

------------------------------------------------------------------ SELL PAGE
local sellPage = makePage("Sell", "Sell Settings", "🛒", 1)

-- Accordion: Booth Settings
local boothBody = makeAccordion(sellPage, "Booth Settings", 1)
makeSingleDropdown(boothBody, "Booth Skin", "Equip skins you own in Trade Plaza", SKIN_OPTIONS,
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
makeButton(unlistBody, "Unlist All Pets", C.red, unlistAll, 1)
makeButton(unlistBody, "Unclaim Booth", C.row, function() pcall(function() RemoveBooth:FireServer() end) log("Unclaim booth dikirim.") end, 2)

-- Accordion: Equip Utilities
local equipBody = makeAccordion(sellPage, "Equip Pets Utilities", 3)
makeButton(equipBody, "Unequip All Pets", C.row, unequipAllPets, 1)

------------------------------------------------------------------ LISTING PROFILE PAGES (Moved to menu)
for i = 1, NUM_PROFILES do
	local prof = CFG.profiles[i]
	local profPage = makePage("Profile " .. i, "Listing Pets Profile " .. i, "📋", i + 1)
	
	for j = 1, NUM_LISTINGS do
		local sub = prof.listings[j]
		local listBody = makeAccordion(profPage, "Listing " .. j, j)
		
		makeDropdown(listBody, "Pet Types [Listing " .. j .. "]", "Select pet types to list", PET_OPTIONS, sub.pets, function() persistState() end, 1)
		makeDropdown(listBody, "Mutation [Listing " .. j .. "]", "Empty = non-mutated only, select = must have mutation", MUT_OPTIONS, sub.muts, function() persistState() end, 2)
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
	local summary, total = buildSummary()
	local tok = getTokens()
	countLbl.Text = ("📊 Ringkasan Inventory (%d target dicari):\n%s\n\n💰 Saldo Token: %s Tokens"):format(total, summary, tostring(tok))
end

local refreshBtn = makeButton(invPage, "Refresh Inventory", C.acc, renderInventory, 2)
tabBtns["Inventory"].btn.MouseButton1Click:Connect(renderInventory)

------------------------------------------------------------------ MISC PAGE
local miscPage = makePage("Misc", "Miscellaneous Settings", "⚙️", 6)

local autoListToggleRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.row, LayoutOrder = 1 }, miscPage)
corner(autoListToggleRow, 8); stroke(autoListToggleRow); pad(autoListToggleRow, 12, 12, 0, 0)
local rAutoToggle = makeToggle(autoListToggleRow, "Auto List Loop", "Periodically scan inventory and list matching pets",
	function() return CFG.autoSell end,
	function(v)
		CFG.autoSell = v; persistState(); setStatus(v and "active" or "idle")
		if v and not running then running = true; task.spawn(mainLoop)
		elseif not v then running = false end
	end, 1)

local webhookCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 128), BackgroundColor3 = C.row, LayoutOrder = 2 }, miscPage)
corner(webhookCard, 8); stroke(webhookCard); pad(webhookCard, 12, 12, 8, 8)
mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, webhookCard)

makeToggle(webhookCard, "Enable Webhook Notifications", "Post listings to Discord Webhook",
	function() return CFG.webhookEnabled end,
	function(v) CFG.webhookEnabled = v; persistState() end, 1)

local whBox = mk("TextBox", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.panel, PlaceholderText = "https://discord.com/api/webhooks/...", Text = CFG.webhookUrl, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.acc, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2 }, webhookCard)
corner(whBox, 6); stroke(whBox); pad(whBox, 6, 6, 0, 0)
whBox.FocusLost:Connect(function() CFG.webhookUrl = whBox.Text; persistState() end)

local testWhBtn = makeButton(webhookCard, "Test Webhook Connection", C.acc, function()
	if CFG.webhookUrl == "" then log("Webhook URL kosong."); return end
	local prev = CFG.webhookEnabled; CFG.webhookEnabled = true
	sendWebhook({ username = "GAG Seller Test", embeds = {{ title = "🔔 Test Sukses", description = "Seller Webhook berhasil terhubung!", color = 10181046, footer = { text = "Player: " .. LP.Name } }} })
	CFG.webhookEnabled = prev
	log("Test webhook terkirim.")
end, 3)

-- Logger Panel
local loggerCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.row, LayoutOrder = 3 }, miscPage)
corner(loggerCard, 8); stroke(loggerCard); pad(loggerCard, 12, 12, 8, 8)
mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "Console Log", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, loggerCard)

local logBox = mk("TextLabel", { Size = UDim2.new(1, 0, 1, -22), BackgroundColor3 = C.panel, Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Code, TextSize = 10, TextColor3 = C.sub, TextWrapped = true, LayoutOrder = 2 }, loggerCard)
corner(logBox, 6); stroke(logBox); pad(logBox, 6, 6, 6, 6)

local logLines = {}
function log(msg)
	table.insert(logLines, os.date("%H:%M:%S ") .. msg)
	while #logLines > 10 do table.remove(logLines, 1) end
	logBox.Text = table.concat(logLines, "\n")
end

-- Status Indicator di Bawah Jendela Utama
local statusFooter = mk("Frame", { Size = UDim2.new(1, -172, 0, 18), Position = UDim2.new(0, 166, 1, -22), BackgroundTransparency = 1 }, main)
local statusText = mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Status: idle", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, statusFooter)
function setStatus(s)
	statusText.Text = ("Status: %s | Loop: %s"):format(s, CFG.autoSell and "ON" or "OFF")
end

------------------------------------------------------------------ INIT
-- Default page setup
pages["Sell"].Visible = true
tabBtns["Sell"].btn.BackgroundTransparency = 0.9
tabBtns["Sell"].btn.TextColor3 = C.txt
tabBtns["Sell"].line.Visible = true

log("PandoruyHub GAG Seller v1.2.5 dimuat.")
renderInventory()

-- Auto Claim Supervisor Loop
task.spawn(function()
	elevate()
	local lastState
	while alive() do
		local delay = 3
		local ok, err = pcall(function()
			if CFG.autoClaim then
				local owns, data, boothName = ownsBooth()
				if owns then
					if lastState ~= "own" then log("Booth aman: " .. tostring(boothName)); lastState = "own" end
					autoSwitchBoothPortal()
					delay = 6
				else
					if lastState ~= "hunt" then log("Booth hilang, mencari terdekat..."); lastState = "hunt" end
					tryClaimNearest()
					delay = 5
				end
			else
				lastState = nil
				delay = 1
			end
		end)
		if not ok then log("claim-loop err: " .. tostring(err)) end
		task.wait(delay)
	end
end)

-- Auto Resume
if CFG.autoSell then
	task.wait(1.5)
	running = true
	if rAutoToggle then rAutoToggle() end
	task.spawn(mainLoop)
	log("Auto-resume: loop dinyalakan.")
end
