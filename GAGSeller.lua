--[[
	GAG Seller — Trade World (Grow a Garden)
	GUI ala PandoruyHub (layout kembar dgn GAG Sniper). Fitur:
	  * Auto Claim Booth: klaim booth kosong terdekat otomatis
	  * Tab Sell: Auto List + 5 profil listing
	      - Pet Types (multi-select), Mutation (multi-select), Min/Max Weight, Max Listings, Price
	      - Mutation kosong = HANYA non-mutasi; ada pilihan = WAJIB mutasi itu
	  * Auto-list pet dari inventory via TradeEvents.Booths.CreateListing:InvokeServer("Pet", uuid, price)
	  * Skip pet favorit & yang lagi trade-lock
	  * Persist setting + auto-resume
	Jalan: loadstring(readfile("GAGSeller.lua"))()  (atau autoexec)
--]]

-- Anti-double & anti-"mati suri setelah hop": loop hidup selama GUI-nya masih ada (lihat alive()).
-- GUI lama dihapus saat re-run / auto ke-destroy saat pindah server -> loop lama berhenti sendiri.

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
local EnumToMut     = MutReg.EnumToPetMutation
local Booths        = RS.GameEvents.TradeEvents.Booths
local ClaimBooth    = Booths.ClaimBooth
local CreateListing = Booths.CreateListing
local RemoveBooth   = Booths.RemoveBooth

-- opsi dropdown = kombinasi "Pet - Egg" (sama seperti Sniper)
local function comboKey(petType, egg) return tostring(petType) .. " - " .. tostring(egg) end
local PET_OPTIONS = {}
do
	local seen = {}
	for eggName, egg in pairs(PetEggs) do
		local items = egg.RarityData and egg.RarityData.Items
		if items then
			for petName in pairs(items) do
				if not tostring(petName):match("^Egg/") then
					local k = comboKey(petName, eggName)
					if not seen[k] then seen[k] = true; PET_OPTIONS[#PET_OPTIONS+1] = k end
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

local function mutDisplay(code)
	if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
	return EnumToMut[code] or code
end

------------------------------------------------------------------ config + state
local NUM_PROFILES = 5
local CFG = {
	autoSell  = false,
	autoClaim = true,
	profiles  = {},
}
for i = 1, NUM_PROFILES do
	CFG.profiles[i] = { pets = {}, muts = {}, minW = 0, maxW = 0, maxList = 0, price = 100 }
end
local running = false
local gui             -- forward decl (ScreenGui utama)
local log, setStatus  -- forward decl
local function alive() return gui ~= nil and gui.Parent ~= nil end

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
		CFG.autoSell = st.autoSell or false
		if type(st.profiles) == "table" then
			for i = 1, NUM_PROFILES do
				local sp = st.profiles[i] or st.profiles[tostring(i)]
				if type(sp) == "table" then
					CFG.profiles[i].pets    = (type(sp.pets) == "table") and sp.pets or {}
					CFG.profiles[i].muts    = (type(sp.muts) == "table") and sp.muts or {}
					CFG.profiles[i].minW    = tonumber(sp.minW) or 0
					CFG.profiles[i].maxW    = tonumber(sp.maxW) or 0
					CFG.profiles[i].maxList = tonumber(sp.maxList) or 0
					CFG.profiles[i].price   = tonumber(sp.price) or 100
				end
			end
		end
	end
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

-- berat yg ditampilkan game = BaseWeight*(1+0.1*Level); Chubby Chipmunk = BaseWeight
local function weightOf(petType, pd)
	local ok, w = pcall(function() return PU:CalculateWeight(pd.BaseWeight, pd.Level, petType) end)
	return (ok and w) or (pd.BaseWeight or 0)
end

-- apakah kita sudah punya booth? return (bool, dataBooths)
local function ownsBooth()
	local ok, data = pcall(function() return RR.new("Booths"):GetDataAsync() end)
	if not ok or not data then return false, nil end
	local id = myPlayerId()
	local has = data.Players and data.Players[id] and data.Players[id].Booth and true or false
	return has, data
end

-- klaim booth kosong TERDEKAT (nearest dulu; kalau keserobot, pass berikutnya ambil yg belakang)
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
			local dist = 0
			if charPos then
				local ok2, piv = pcall(function() return inst:GetPivot().Position end)
				if ok2 then dist = (piv - charPos).Magnitude end
			end
			list[#list+1] = { inst = inst, dist = dist }
		end
	end
	if #list == 0 then log("Tidak ada booth kosong."); return false end
	table.sort(list, function(a, b) return a.dist < b.dist end) -- terdekat -> terjauh (belakang)
	local pick = list[1]
	pcall(function() ClaimBooth:FireServer(pick.inst) end)
	log(("Claim booth terdekat (%dstud, %d kosong)..."):format(math.floor(pick.dist), #list))
	return false
end

-- untuk listing: pastikan punya booth (claim kalau autoClaim ON)
local function ensureBooth()
	local owns = ownsBooth()
	if owns then return true end
	if CFG.autoClaim then return tryClaimNearest() end
	return false
end


-- satu putaran listing: cek inventory, cocokkan tiap profil, buat listing
local listedSet = {}  -- uuid -> true (jaga2 double invoke antar-pass)
local function listPass()
	local ok, data = pcall(function() return DataService:GetData() end)
	if not ok or not (data and data.PetsData and data.PetsData.PetInventory) then return 0 end
	local pets  = data.PetsData.PetInventory.Data
	local locks = (data.TradeData and data.TradeData.TradeLocks and data.TradeData.TradeLocks.Pet) or {}
	local total = 0
	for pi = 1, NUM_PROFILES do
		local prof = CFG.profiles[pi]
		if next(prof.pets) and (prof.price or 0) > 0 then
			local cap = (prof.maxList and prof.maxList > 0) and prof.maxList or math.huge
			local count = 0
			for uuid, v in pairs(pets) do
				if not running then break end
				if count >= cap then break end
				local pd = v.PetData
				if v.PetType and pd and not pd.IsFavorite and not locks[uuid] and not listedSet[uuid] then
					if prof.pets[comboKey(v.PetType, pd.HatchedFrom or "?")] then
						local mut = mutDisplay(pd.MutationType)
						local mutOK
						if not next(prof.muts) then mutOK = (mut == "None") else mutOK = prof.muts[mut] == true end
						local w = weightOf(v.PetType, pd)
						local wOK = (w >= (prof.minW or 0)) and ((prof.maxW or 0) <= 0 or w <= prof.maxW)
						if mutOK and wOK then
							local ok2, res = pcall(function() return CreateListing:InvokeServer("Pet", uuid, math.floor(prof.price)) end)
							if ok2 and res then
								listedSet[uuid] = true
								count += 1; total += 1
								log(("LIST %s [%s] %.2fkg @%d (L%d)"):format(v.PetType, mut, w, prof.price, pi))
								task.wait(0.5)
							else
								log(("FAIL list %s (%s)"):format(v.PetType, tostring(res)))
								task.wait(0.3)
							end
						end
					end
				end
			end
		end
	end
	return total
end

local function anyProfileActive()
	for i = 1, NUM_PROFILES do if next(CFG.profiles[i].pets) then return true end end
	return false
end
local function mainLoop()
	while running and alive() do
		if not anyProfileActive() then
			setStatus("Pilih pet di profil listing dulu.")
			task.wait(2)
		else
			local ready = true
			if CFG.autoClaim then ready = ensureBooth() end
			if ready then
				local n = listPass()
				setStatus(("Listing pass: +%d | Token:%s"):format(n, tostring(getTokens())))
				task.wait(4)
			else
				setStatus("Menunggu booth ke-claim...")
				task.wait(2.5)
			end
		end
	end
end

------------------------------------------------------------------ GUI
-- hapus instance lama (setelah re-run / hop) biar nggak dobel GUI
pcall(function()
	local host = (gethui and gethui()) or game:GetService("CoreGui")
	local old = host:FindFirstChild("GAGSeller"); if old then old:Destroy() end
	local pg = LP:FindFirstChild("PlayerGui")
	if pg and pg:FindFirstChild("GAGSeller") then pg.GAGSeller:Destroy() end
end)

gui = Instance.new("ScreenGui")
gui.Name = "GAGSeller"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local C = {
	bg    = Color3.fromRGB(18, 20, 27),
	panel = Color3.fromRGB(26, 29, 38),
	row   = Color3.fromRGB(32, 36, 47),
	acc   = Color3.fromRGB(140, 100, 255),
	txt   = Color3.fromRGB(230, 232, 238),
	sub   = Color3.fromRGB(150, 155, 168),
	green = Color3.fromRGB(80, 200, 120),
	red   = Color3.fromRGB(220, 80, 80),
}
local function mk(cls, props, parent)
	local o = Instance.new(cls); for k, v in pairs(props) do o[k] = v end; o.Parent = parent; return o
end
local function corner(o, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end
local function pad(o, p) mk("UIPadding", { PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p) }, o) end

local main = mk("Frame", {
	Size = UDim2.fromOffset(600, 400), Position = UDim2.new(0.5, -300, 0.5, -200),
	BackgroundColor3 = C.bg, BorderSizePixel = 0,
}, gui)
corner(main, 12)
mk("UIStroke", { Color = C.acc, Thickness = 1, Transparency = 0.3 }, main)

local bar = mk("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, main)
corner(bar, 12)
mk("TextLabel", {
	Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1,
	Text = "Allegiaant Hub | GAG Seller", TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.acc,
}, bar)
local closeBtn = mk("TextButton", {
	Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -36, 0, 5), BackgroundColor3 = C.row,
	Text = "✕", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt,
}, bar)
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = not gui.Enabled end)
do
	local dragging, ds, sp
	bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = main.Position end end)
	UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end

local rail = mk("Frame", { Size = UDim2.new(0, 130, 1, -48), Position = UDim2.fromOffset(8, 44), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, main)
corner(rail, 10); pad(rail, 8)
mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, rail)

local content = mk("Frame", { Size = UDim2.new(1, -154, 1, -48), Position = UDim2.fromOffset(146, 44), BackgroundTransparency = 1 }, main)

local tabs, tabBtns = {}, {}
local function makeTab(name, order)
	local page = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false,
		ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarImageColor3 = C.acc,
	}, content)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	tabs[name] = page
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.row, Text = "  " .. name,
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextSize = 14,
		TextColor3 = C.sub, LayoutOrder = order, AutoButtonColor = false,
	}, rail)
	corner(btn, 8); tabBtns[name] = btn
	btn.MouseButton1Click:Connect(function()
		for n, p in pairs(tabs) do p.Visible = (n == name) end
		for n, b in pairs(tabBtns) do b.BackgroundColor3 = (n == name) and C.acc or C.row; b.TextColor3 = (n == name) and Color3.new(1,1,1) or C.sub end
	end)
	return page
end

local function sectionLabel(parent, title, sub, order)
	local f = mk("Frame", { Size = UDim2.new(1, 0, 0, sub and 40 or 24), BackgroundTransparency = 1, LayoutOrder = order }, parent)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = title, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt }, f)
	if sub then mk("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 20), BackgroundTransparency = 1, Text = sub, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub }, f) end
	return f
end

local function makeToggle(parent, title, sub, getv, setv, order)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.row, LayoutOrder = order }, parent)
	corner(row, 8)
	mk("TextLabel", { Size = UDim2.new(1, -70, 0, 20), Position = UDim2.fromOffset(12, 5), BackgroundTransparency = 1, Text = title, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt }, row)
	mk("TextLabel", { Size = UDim2.new(1, -70, 0, 14), Position = UDim2.fromOffset(12, 25), BackgroundTransparency = 1, Text = sub or "", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub }, row)
	local knob = mk("TextButton", { Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -58, 0.5, -12), BackgroundColor3 = C.bg, Text = "", AutoButtonColor = false }, row)
	corner(knob, 12)
	local dot = mk("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.sub }, knob)
	corner(dot, 9)
	local function render()
		local on = getv()
		dot.Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
		dot.BackgroundColor3 = on and C.green or C.sub
		knob.BackgroundColor3 = on and Color3.fromRGB(40, 60, 45) or C.bg
	end
	knob.MouseButton1Click:Connect(function() setv(not getv()); render() end)
	render()
	return render
end

local function makeInput(parent, title, sub, getv, setv, order)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.row, LayoutOrder = order }, parent)
	corner(row, 8)
	mk("TextLabel", { Size = UDim2.new(1, -160, 0, 20), Position = UDim2.fromOffset(12, 5), BackgroundTransparency = 1, Text = title, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt }, row)
	mk("TextLabel", { Size = UDim2.new(1, -160, 0, 14), Position = UDim2.fromOffset(12, 25), BackgroundTransparency = 1, Text = sub or "", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub }, row)
	local box = mk("TextBox", { Size = UDim2.fromOffset(120, 30), Position = UDim2.new(1, -132, 0.5, -15), BackgroundColor3 = C.bg, Text = tostring(getv()), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.acc, ClearTextOnFocus = false }, row)
	corner(box, 6)
	box.FocusLost:Connect(function() setv(box.Text); box.Text = tostring(getv()) end)
	return box
end

local function makeDropdown(parent, title, sub, options, selSet, onChange, order)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.row, LayoutOrder = order }, parent)
	corner(row, 8)
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, row)
	local head = mk("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 1 }, row)
	mk("TextLabel", { Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(12, 5), BackgroundTransparency = 1, Text = title, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt }, head)
	mk("TextLabel", { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 25), BackgroundTransparency = 1, Text = sub or "", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub }, head)
	local summary = mk("TextButton", { Size = UDim2.new(0, 200, 0, 30), Position = UDim2.new(1, -212, 0.5, -15), BackgroundColor3 = C.bg, Text = "Select Options  ▾", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right, AutoButtonColor = false }, head)
	corner(summary, 6); pad(summary, 8)

	local function updateSummary()
		local sel = {}
		for _, o in ipairs(options) do if selSet[o] then sel[#sel+1] = o end end
		if #sel == 0 then summary.Text = "Select Options  ▾"; summary.TextColor3 = C.sub
		else
			local txt = table.concat(sel, ", ")
			if #txt > 26 then txt = ("%d selected"):format(#sel) end
			summary.Text = txt .. "  ▾"; summary.TextColor3 = C.acc
		end
	end

	local listFrame = mk("Frame", { Size = UDim2.new(1, -16, 0, 200), Position = UDim2.fromOffset(8, 0), BackgroundColor3 = C.bg, Visible = false, LayoutOrder = 2 }, row)
	corner(listFrame, 6)
	local search = mk("TextBox", { Size = UDim2.new(1, -12, 0, 28), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.panel, PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.txt, ClearTextOnFocus = false }, listFrame)
	corner(search, 6)
	local optScroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -42), Position = UDim2.fromOffset(6, 38), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = C.acc }, listFrame)
	mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, optScroll)

	local built = false
	local optButtons = {}
	local function buildOptions()
		if built then return end
		built = true
		for _, opt in ipairs(options) do
			local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.row, Text = "  " .. opt, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.txt, AutoButtonColor = false }, optScroll)
			corner(ob, 4)
			local check = mk("TextLabel", { Size = UDim2.fromOffset(20, 26), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.green }, ob)
			local function rend() check.Text = selSet[opt] and "✓" or ""; ob.BackgroundColor3 = selSet[opt] and Color3.fromRGB(40, 44, 60) or C.row end
			ob.MouseButton1Click:Connect(function()
				if selSet[opt] then selSet[opt] = nil else selSet[opt] = true end
				rend(); updateSummary(); if onChange then onChange() end
			end)
			rend()
			optButtons[opt] = ob
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = search.Text:lower()
		for opt, ob in pairs(optButtons) do ob.Visible = (q == "" or opt:lower():find(q, 1, true) ~= nil) end
	end)
	summary.MouseButton1Click:Connect(function()
		if not built then buildOptions() end
		listFrame.Visible = not listFrame.Visible
	end)
	updateSummary()
	return updateSummary
end

------------------------------------------------------------------ SELL tab
local sell = makeTab("Sell", 1)

local statusBox = mk("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.panel, LayoutOrder = 0 }, sell)
corner(statusBox, 8)
mk("TextLabel", { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(12, 6), BackgroundTransparency = 1, Text = "Selling Status", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt }, statusBox)
local statusLbl = mk("TextLabel", { Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(12, 24), BackgroundTransparency = 1, Text = "Status: OFF", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextWrapped = true }, statusBox)

makeToggle(sell, "Auto Claim Booth", "Klaim booth kosong terdekat (jalan sendiri)",
	function() return CFG.autoClaim end,
	function(v)
		CFG.autoClaim = v; persistState()
	end, 1)

local rAutoToggle = makeToggle(sell, "Auto List Pets", "Auto list pet dari inventory sesuai profil 1-5",
	function() return CFG.autoSell end,
	function(v)
		CFG.autoSell = v; persistState()
		if v and not running then running = true; task.spawn(mainLoop)
		elseif not v then running = false end
	end, 2)

local ord = 3
for i = 1, NUM_PROFILES do
	local prof = CFG.profiles[i]
	makeDropdown(sell, "Pet Types [List " .. i .. "]", "Pilih jenis pet yang mau dijual",
		PET_OPTIONS, prof.pets, function() persistState() end, ord); ord += 1
	makeDropdown(sell, "Mutation [List " .. i .. "]", "Kosong = non-mutasi saja, pilih = wajib mutasi itu",
		MUT_OPTIONS, prof.muts, function() persistState() end, ord); ord += 1
	makeInput(sell, "Min Weight [List " .. i .. "]", "Berat minimum (KG)",
		function() return prof.minW or 0 end,
		function(txt) local n = tonumber(txt); prof.minW = (n and n >= 0) and n or 0; persistState() end, ord); ord += 1
	makeInput(sell, "Max Weight [List " .. i .. "]", "0 = tanpa batas atas",
		function() return prof.maxW or 0 end,
		function(txt) local n = tonumber(txt); prof.maxW = (n and n >= 0) and n or 0; persistState() end, ord); ord += 1
	makeInput(sell, "Max Listings [List " .. i .. "]", "Maks jumlah listing profil ini (0 = semua)",
		function() return prof.maxList or 0 end,
		function(txt) local n = tonumber(txt); prof.maxList = (n and n >= 0) and math.floor(n) or 0; persistState() end, ord); ord += 1
	makeInput(sell, "Price [List " .. i .. "]", "Harga per listing (Tokens)",
		function() return prof.price or 0 end,
		function(txt) local n = tonumber(txt); prof.price = (n and n >= 0) and math.floor(n) or 0; persistState() end, ord); ord += 1
end

------------------------------------------------------------------ MISC tab
local misc = makeTab("Misc", 2)
sectionLabel(misc, "Manual", nil, 0)
local sellNowBtn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.acc, Text = "List Sekarang (1x)", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1), LayoutOrder = 1 }, misc)
corner(sellNowBtn, 8)
sellNowBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		local wasRun = running; running = true
		if CFG.autoClaim then ensureBooth() end
		local n = listPass()
		running = wasRun
		log(("Manual list selesai: +%d"):format(n))
	end)
end)

local unclaimBtn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.red, Text = "Unclaim Booth", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1), LayoutOrder = 2 }, misc)
corner(unclaimBtn, 8)
unclaimBtn.MouseButton1Click:Connect(function()
	pcall(function() RemoveBooth:FireServer() end)
	log("Unclaim booth dikirim.")
end)

sectionLabel(misc, "Log", nil, 3)
local logBox = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.bg, Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Code, TextSize = 11, TextColor3 = C.sub, TextWrapped = true, LayoutOrder = 4 }, misc)
corner(logBox, 6); pad(logBox, 6)
local logLines = {}
function log(msg)
	table.insert(logLines, os.date("%H:%M:%S ") .. msg)
	while #logLines > 12 do table.remove(logLines, 1) end
	logBox.Text = table.concat(logLines, "\n")
end
function setStatus(s) statusLbl.Text = ("Status: %s | %s"):format(CFG.autoSell and "ON" or "OFF", s) end

------------------------------------------------------------------ init
for n, p in pairs(tabs) do p.Visible = (n == "Sell") end
tabBtns["Sell"].BackgroundColor3 = C.acc; tabBtns["Sell"].TextColor3 = Color3.new(1,1,1)

log("Ready. Set profil listing di tab Sell lalu Auto List ON.")
setStatus("idle")

-- supervisor auto-claim: SATU loop permanen, cek CFG.autoClaim tiap tick (anti-race, nggak bisa mati diam2)
task.spawn(function()
	local lastState
	while alive() do
		if CFG.autoClaim then
			local owns = ownsBooth()
			if owns then
				if lastState ~= "own" then log("Booth aman: " .. tostring(owns):sub(1,8)); lastState = "own" end
				task.wait(6)
			else
				if lastState ~= "hunt" then log("Booth hilang, cari terdekat..."); lastState = "hunt" end
				tryClaimNearest()   -- klaim booth kosong terdekat
				task.wait(5)        -- hormati cooldown claim server
			end
		else
			lastState = nil
			task.wait(1)
		end
	end
end)

if CFG.autoSell then
	task.wait(1.5)
	running = true
	rAutoToggle()
	task.spawn(mainLoop)
	log("Auto-resume: Auto List ON.")
end
