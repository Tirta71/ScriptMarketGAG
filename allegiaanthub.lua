--[[
	GAG Sniper — Trade World (Grow a Garden)
	GUI ala PandoruyHub: multi-profile pet sniper + Discord webhook.
	Fitur:
	  * Tab Buy: Auto Snipe toggle + 5 profil (Pet Types multi-select, Mutation multi-select, Max Price)
	  * Auto server-hop (retry sampai berhasil) saat tidak ada target
	  * Tab Misc: Auto-Hop toggle, Discord Webhook (input URL + enable + Test)
	  * Auto-buy via TradeEvents.Booths.BuyListing:InvokeServer(ownerPlayer, listingUUID)
	  * Persist setting antar-hop (state file) + auto-resume
	Jalan: loadstring(readfile("GAGSniper.lua"))()  (atau taruh di autoexec)
--]]

if type(getgenv) == "function" then
	if getgenv().__GAGSniperLoaded then return end
	getgenv().__GAGSniperLoaded = true
end

local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until Players.LocalPlayer
local LP = Players.LocalPlayer

------------------------------------------------------------------ deps
local RR          = require(RS.Modules.ReplicationReciever)
local DataService = require(RS.Modules.DataService)
local BuyListing  = RS.GameEvents.TradeEvents.Booths.BuyListing
local PetEggs     = require(RS.Data.PetRegistry.PetEggs)
local MutReg      = require(RS.Data.PetRegistry.PetMutationRegistry)
local EnumToMut   = MutReg.EnumToPetMutation

-- opsi dropdown = kombinasi "Pet - Egg" (premium vs biasa otomatis kebedain).
-- key yang disimpan = label; saat cocokkan listing pakai PetType .. " - " .. HatchedFrom
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

-- kode mutasi listing -> nama tampilan
local function mutDisplay(code)
	if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
	return EnumToMut[code] or code
end

------------------------------------------------------------------ config + state
local NUM_PROFILES = 5
local CFG = {
	autoSnipe      = false,
	autoHop        = true,
	webhookUrl     = "",
	webhookEnabled = false,
	profiles       = {},
}
for i = 1, NUM_PROFILES do
	CFG.profiles[i] = { pets = {}, muts = {}, maxPrice = 0 }
end
local running = false
local log, setStatus, refreshStatus  -- forward decl

local STATE_FILE = "GAGSniper_state.json"
local function persistState()
	pcall(function()
		writefile(STATE_FILE, HttpService:JSONEncode(CFG))
	end)
end
local function loadState()
	if type(isfile) == "function" and isfile(STATE_FILE) then
		local ok, t = pcall(function() return HttpService:JSONDecode(readfile(STATE_FILE)) end)
		if ok and type(t) == "table" then return t end
	end
	return nil
end

-- muat state KE CFG sebelum GUI dibangun, supaya semua widget terinisialisasi benar
do
	local st = loadState()
	if st then
		if st.autoHop ~= nil then CFG.autoHop = st.autoHop end
		CFG.webhookUrl     = st.webhookUrl or CFG.webhookUrl
		CFG.webhookEnabled = st.webhookEnabled or false
		CFG.autoSnipe      = st.autoSnipe or false
		if type(st.profiles) == "table" then
			for i = 1, NUM_PROFILES do
				local sp = st.profiles[i] or st.profiles[tostring(i)]
				if type(sp) == "table" then
					CFG.profiles[i].pets     = (type(sp.pets) == "table") and sp.pets or {}
					CFG.profiles[i].muts     = (type(sp.muts) == "table") and sp.muts or {}
					CFG.profiles[i].maxPrice = tonumber(sp.maxPrice) or 0
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
	return math.huge
end
local function ownerToUserId(owner) return tonumber((tostring(owner):gsub("Player_", ""))) end

-- cari target dari data booth, cocokkan ke profil (index profil = prioritas)
local function collectTargets()
	local data = RR.new("Booths"):GetDataAsync()
	local targets = {}
	if not data then return targets end
	for _, b in pairs(data.Booths or {}) do
		local owner = b.Owner
		local pd = owner and data.Players and data.Players[owner]
		if pd and pd.Listings then
			for lid, l in pairs(pd.Listings) do
				local it = pd.Items and pd.Items[l.ItemId]
				local p  = it and it.PetData
				if p and it.PetType then
					local disp = mutDisplay(p.MutationType)
					local key  = comboKey(it.PetType, p.HatchedFrom or "?")
					for pi = 1, NUM_PROFILES do
						local prof = CFG.profiles[pi]
						if next(prof.pets) and prof.pets[key] then
							local mutOK   = (not next(prof.muts)) or prof.muts[disp]
							local priceOK = (prof.maxPrice or 0) <= 0 or l.Price <= prof.maxPrice
							if mutOK and priceOK then
								local ply = Players:GetPlayerByUserId(ownerToUserId(owner))
								targets[#targets+1] = {
									profile = pi, pet = it.PetType, name = p.Name,
									mut = disp, price = l.Price, uuid = lid,
									owner = ply, present = ply ~= nil,
								}
								break -- profil prioritas tertinggi menang
							end
						end
					end
				end
			end
		end
	end
	table.sort(targets, function(a, b)
		if a.profile ~= b.profile then return a.profile < b.profile end
		return a.price < b.price
	end)
	return targets
end

------------------------------------------------------------------ discord webhook
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

local function notifyBuy(t)
	local seller = (t.owner and (t.owner.DisplayName or t.owner.Name)) or "?"
	sendWebhook({
		username = "GAG Sniper",
		embeds = {{
			title = "✅ Pet Sniped!",
			color = 3066993,
			fields = {
				{ name = "Pet",      value = tostring(t.pet),   inline = true },
				{ name = "Mutation", value = tostring(t.mut),   inline = true },
				{ name = "Price",    value = tostring(t.price) .. " Tokens", inline = true },
				{ name = "Nickname", value = tostring(t.name),  inline = true },
				{ name = "Profile",  value = "Snipe " .. t.profile, inline = true },
				{ name = "Seller",   value = "@" .. seller,     inline = true },
			},
			footer = { text = "JobId: " .. tostring(game.JobId) },
		}},
	})
end

------------------------------------------------------------------ server hop (retry sampai pindah)
local function httpJson(url)
	local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
	if reqFn then
		local ok, res = pcall(reqFn, { Url = url, Method = "GET" })
		if ok and res and res.Body then
			local ok2, d = pcall(function() return HttpService:JSONDecode(res.Body) end)
			if ok2 then return d end
		end
	end
	local ok3, body = pcall(function() return game:HttpGet(url) end)
	if ok3 then local ok4, d = pcall(function() return HttpService:JSONDecode(body) end) if ok4 then return d end end
	return nil
end
-- ingatan server yang sudah dikunjungi (persist antar-hop biar nggak balik lagi)
local HOP_FILE = "GAGSniper_hops.json"
local HOP_TTL  = 120 -- detik; server dianggap "baru lagi" setelah 2 menit
local visited  = {}
do
	if type(isfile) == "function" and isfile(HOP_FILE) then
		local ok, d = pcall(function() return HttpService:JSONDecode(readfile(HOP_FILE)) end)
		if ok and type(d) == "table" then
			local now = os.time()
			for job, ts in pairs(d) do if type(ts) == "number" and (now - ts) < HOP_TTL then visited[job] = ts end end
		end
	end
end
local function saveVisited() pcall(function() writefile(HOP_FILE, HttpService:JSONEncode(visited)) end) end
local function markVisited(job)
	if job and job ~= "" then visited[job] = os.time(); saveVisited() end
end
-- server tempat kita berada sekarang wajib dianggap sudah dikunjungi
markVisited(game.JobId)

-- ambil server publik yang BELUM dikunjungi & masih ada slot, hasil diacak
local function getOpenServers(placeId)
	local list, cursor, tries = {}, nil, 0
	repeat
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(placeId)
		if cursor then url = url .. "&cursor=" .. cursor end
		local data = httpJson(url)
		if data and data.data then
			for _, s in ipairs(data.data) do
				local full = (s.playing or 0) >= (s.maxPlayers or 0)
				if s.id ~= game.JobId and not visited[s.id] and not full then list[#list+1] = s.id end
			end
			cursor = data.nextPageCursor
		else cursor = nil end
		tries += 1
	until not cursor or tries >= 12 or #list >= 80
	-- acak (Fisher-Yates) supaya nggak selalu nyangkut di server teratas
	for i = #list, 2, -1 do local j = math.random(1, i); list[i], list[j] = list[j], list[i] end
	return list
end
local function queueResume()
	local q = queue_on_teleport or (syn and syn.queue_on_teleport) or queueteleport
	if q then pcall(q, [[loadstring(readfile("allegiaanthub.lua"))()]]) end
end
local hopInProgress = false
local function serverHop()
	if not CFG.autoHop or hopInProgress then return end
	hopInProgress = true
	queueResume()
	local placeId = game.PlaceId

	-- 1. Kumpulkan semua petType unik yang dicentang di profil
	local searchTargets = {}
	local seenTargets = {}
	for pi = 1, NUM_PROFILES do
		local prof = CFG.profiles[pi]
		for petKey in pairs(prof.pets) do
			local petType = string.split(petKey, " - ")[1] or petKey
			if not seenTargets[petType] then
				seenTargets[petType] = true
				table.insert(searchTargets, petType)
			end
		end
	end

	-- Helper untuk mencari JobId di dalam table tpData (mendeteksi standard UUID)
	local function findJobId(tbl)
		if type(tbl) ~= "table" then return nil end
		for k, v in pairs(tbl) do
			if type(v) == "string" and v:match("^%w+-%w+-%w+-%w+-%w+$") then
				return v
			elseif type(v) == "table" then
				local res = findJobId(v)
				if res then return res end
			end
		end
		return nil
	end

	local function attempt()
		if not running then return end

		-- Acak searchTargets agar bervariasi setiap kali pencarian di-retry
		for i = #searchTargets, 2, -1 do
			local j = math.random(1, i)
			searchTargets[i], searchTargets[j] = searchTargets[j], searchTargets[i]
		end

		-- Coba cari seller via Global Index
		if #searchTargets > 0 then
			setStatus("Mencari seller online di Global Index...")
			for _, petType in ipairs(searchTargets) do
				if not running then return end
				setStatus(("Mencari seller: %s"):format(petType))
				
				-- Buat itemData default (seperti saat klik pet di UI game)
				local itemData = {
					PetType = petType,
					PetData = {
						MutationType = "Normal",
						Level = 0,
						LevelProgress = 0,
						Hunger = 0,
						BaseWeight = 1,
						Boosts = {}
					},
					PetAbility = {}
				}
				
				local ok, success, tpData = pcall(function()
					return RS.GameEvents.TradeEvents.TokenRAPs.FindSellers:InvokeServer("Pet", itemData)
				end)
				
				if ok and success and tpData then
					local targetJobId = findJobId(tpData)
					if targetJobId then
						if targetJobId == game.JobId then
							log(("Seller %s ada di server saat ini. Lewati."):format(petType))
						elseif visited[targetJobId] then
							log(("Seller %s ada di server yang sudah dikunjungi (%s). Lewati."):format(petType, targetJobId:sub(1, 8)))
						else
							setStatus(("Seller ditemukan! Teleport ke %s..."):format(petType))
							markVisited(targetJobId) -- Tandai server agar tidak kembali ke sini
							local tpOk = pcall(function()
								return RS.GameEvents.TradeEvents.TokenRAPs.TeleportToListing:InvokeServer(tpData, true)
							end)
							if tpOk then
								return -- Teleport sukses dikirim ke server
							end
						end
					else
						-- Fallback jika JobId tidak terdeteksi di table, coba langsung teleport
						setStatus(("Teleport ke seller %s..."):format(petType))
						local tpOk = pcall(function()
							return RS.GameEvents.TradeEvents.TokenRAPs.TeleportToListing:InvokeServer(tpData, true)
						end)
						if tpOk then
							return
						end
					end
				end
				task.wait(0.4) -- jeda kecil antar pencarian pet agar tidak spam remote
			end
		end

		-- Jika tidak ada seller baru/valid di Global Index, tunggu 2.5 detik lalu coba lagi (tanpa random hop)
		setStatus("Tidak ada seller baru/valid. Menunggu 2.5 detik...")
		task.wait(2.5)
		if running then
			attempt()
		end
	end

	local conn
	conn = TeleportService.TeleportInitFailed:Connect(function(plr, _, msg)
		if plr == LP then
			log("Teleport gagal: " .. tostring(msg))
			task.wait(1.5)
			if running then attempt() end
		end
	end)

	task.spawn(function()
		repeat task.wait(1) until not running or not hopInProgress
		if conn then conn:Disconnect() end
		hopInProgress = false
	end)

	attempt()
end

------------------------------------------------------------------ core loop
local function anyProfileActive()
	for i = 1, NUM_PROFILES do if next(CFG.profiles[i].pets) then return true end end
	return false
end
local function buyPass()
	local targets = collectTargets()
	local buyable, bought = 0, 0
	for _, t in ipairs(targets) do
		if not running then break end
		if t.present then
			buyable += 1
			if getTokens() >= t.price then
				local ok, success, m = pcall(function() return BuyListing:InvokeServer(t.owner, t.uuid) end)
				if ok and success then
					bought += 1
					log(("BUY %s [%s] @%d (P%d)"):format(t.pet, t.mut, t.price, t.profile))
					notifyBuy(t)
				else
					log(("FAIL %s @%d (%s)"):format(t.pet, t.price, tostring(m or success)))
				end
				task.wait(0.6)
			end
		end
	end
	return #targets, buyable, bought
end
local function mainLoop()
	while running do
		if not anyProfileActive() then
			setStatus("Tidak ada pet dipilih di profil manapun.")
			task.wait(2)
		else
			setStatus(("Scan... Token:%s"):format(tostring(getTokens())))
			local total, buyable, bought = buyPass()
			if not running then break end
			setStatus(("Target:%d Beli:%d Token:%s"):format(total, bought, tostring(getTokens())))
			if buyable > 0 and bought > 0 then
				task.wait(3)
			elseif CFG.autoHop then
				setStatus("Tidak ada target. Hop...")
				task.wait(2); serverHop(); break
			else
				task.wait(3)
			end
		end
	end
end

------------------------------------------------------------------ GUI
local gui = Instance.new("ScreenGui")
gui.Name = "GAGSniper"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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

-- title bar
local bar = mk("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, main)
corner(bar, 12)
mk("TextLabel", {
	Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1,
	Text = "Allegiaant Hub | GAG Sniper", TextXAlignment = Enum.TextXAlignment.Left,
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

-- left rail
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

-- reusable widgets ------------------------------------------------
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

-- multi-select dropdown (expand inline)
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

------------------------------------------------------------------ BUY tab
local buy = makeTab("Buy", 1)

local statusBox = mk("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.panel, LayoutOrder = 0 }, buy)
corner(statusBox, 8)
mk("TextLabel", { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(12, 6), BackgroundTransparency = 1, Text = "Snipe Status", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt }, statusBox)
local statusLbl = mk("TextLabel", { Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(12, 24), BackgroundTransparency = 1, Text = "Status: OFF", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextWrapped = true }, statusBox)

function refreshStatus()
	local parts = {}
	for i = 1, NUM_PROFILES do
		local pr = CFG.profiles[i]
		if next(pr.pets) then
			local first
			for _, o in ipairs(PET_OPTIONS) do if pr.pets[o] then first = o break end end
			parts[#parts+1] = ("[P%d] %s | Max %s"):format(i, first or "?", (pr.maxPrice or 0) > 0 and pr.maxPrice or "∞")
		end
	end
	statusLbl.Text = ("Status: %s\n%s"):format(CFG.autoSnipe and "ON" or "OFF", (#parts > 0 and table.concat(parts, "\n") or "No profile set"))
end

local rAutoToggle = makeToggle(buy, "Auto Snipe Pet", "Automatically scan and buy matching pets (profiles 1-5)",
	function() return CFG.autoSnipe end,
	function(v)
		CFG.autoSnipe = v; persistState(); refreshStatus()
		if v and not running then running = true; task.spawn(mainLoop)
		elseif not v then running = false; hopInProgress = false end
	end, 1)

local ord = 2
local profileSummaries = {}
for i = 1, NUM_PROFILES do
	local prof = CFG.profiles[i]
	local upP = makeDropdown(buy, "Pet Types [Snipe " .. i .. "]", "Select pet types to snipe (order = priority)",
		PET_OPTIONS, prof.pets, function() persistState(); refreshStatus() end, ord); ord += 1
	local upM = makeDropdown(buy, "Mutation [Snipe " .. i .. "]", "Unselect = no filter (all mutations)",
		MUT_OPTIONS, prof.muts, function() persistState() end, ord); ord += 1
	makeInput(buy, "Max Price [Snipe " .. i .. "]", "0 = no filter",
		function() return prof.maxPrice or 0 end,
		function(txt) local n = tonumber(txt); prof.maxPrice = (n and n >= 0) and math.floor(n) or 0; persistState(); refreshStatus() end, ord); ord += 1
	profileSummaries[i] = { upP, upM }
end

------------------------------------------------------------------ MISC tab
local misc = makeTab("Misc", 2)
sectionLabel(misc, "Server Hop", nil, 0)
makeToggle(misc, "Auto Server Hop", "Hop bila tidak ada target di server ini",
	function() return CFG.autoHop end, function(v) CFG.autoHop = v; persistState() end, 1)

sectionLabel(misc, "Discord Webhook", nil, 2)
makeToggle(misc, "Enable Webhook", "Kirim notif ke Discord saat berhasil beli",
	function() return CFG.webhookEnabled end, function(v) CFG.webhookEnabled = v; persistState() end, 3)
local whRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.row, LayoutOrder = 4 }, misc)
corner(whRow, 8)
mk("TextLabel", { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(12, 6), BackgroundTransparency = 1, Text = "Webhook URL", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt }, whRow)
local whBox = mk("TextBox", { Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 28), BackgroundColor3 = C.bg, PlaceholderText = "https://discord.com/api/webhooks/...", Text = CFG.webhookUrl, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.acc, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, whRow)
corner(whBox, 6); pad(whBox, 6)
whBox.FocusLost:Connect(function() CFG.webhookUrl = whBox.Text; persistState() end)

local testBtn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.acc, Text = "Test Webhook", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1), LayoutOrder = 5 }, misc)
corner(testBtn, 8)
testBtn.MouseButton1Click:Connect(function()
	if CFG.webhookUrl == "" then log("Webhook URL kosong."); return end
	local prev = CFG.webhookEnabled; CFG.webhookEnabled = true
	sendWebhook({ username = "GAG Sniper", embeds = {{ title = "🔔 Test Webhook", description = "Webhook GAG Sniper berhasil terhubung!", color = 10181046, footer = { text = "Player: " .. LP.Name } }} })
	CFG.webhookEnabled = prev
	log("Test webhook terkirim.")
end)

-- console/log kecil di Misc
sectionLabel(misc, "Log", nil, 6)
local logBox = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = C.bg, Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Code, TextSize = 11, TextColor3 = C.sub, TextWrapped = true, LayoutOrder = 7 }, misc)
corner(logBox, 6); pad(logBox, 6)
local logLines = {}
function log(msg)
	table.insert(logLines, os.date("%H:%M:%S ") .. msg)
	while #logLines > 10 do table.remove(logLines, 1) end
	logBox.Text = table.concat(logLines, "\n")
end
function setStatus(s) statusLbl.Text = ("Status: %s | %s"):format(CFG.autoSnipe and "ON" or "OFF", s) end

------------------------------------------------------------------ init
-- default tab
for n, p in pairs(tabs) do p.Visible = (n == "Buy") end
tabBtns["Buy"].BackgroundColor3 = C.acc; tabBtns["Buy"].TextColor3 = Color3.new(1,1,1)

refreshStatus()
log("Ready. Pilih pet di tab Buy lalu Auto Snipe ON.")

-- auto-resume setelah hop
if CFG.autoSnipe then
	task.wait(1.5)
	running = true
	rAutoToggle()  -- render toggle ON
	task.spawn(mainLoop)
	log("Auto-resume: snipe ON.")
end
