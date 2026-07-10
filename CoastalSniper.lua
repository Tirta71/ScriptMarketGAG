--[[
	Coastal Sniper — Trade World (Grow a Garden)
	------------------------------------------------------------------
	Fungsi:
	  * Scan semua booth, cari pet dari "Coastal Egg" (Sea Anemone / Seahorse / Hermit Crab; Orca DIKECUALIKAN)
	  * Beli otomatis jika harga <= Max Token (editable di GUI, default 50) dan owner ada di server
	  * Jika di server ini TIDAK ADA target yang bisa dibeli -> auto server hop, lalu resume sendiri
	GUI:
	  * Input editable "Max Token"
	  * Tombol Start / Stop
	  * Toggle Auto-Hop
	  * Status + log
	Cara jalan (di executor Potassium):
	  loadstring(readfile("CoastalSniper.lua"))()
	Catatan: pembelian tetap divalidasi server (token/kepemilikan/jarak). Jika server menolak, akan dicatat di log.
--]]

-- Pengaman singleton: cegah dobel-jalan (autoexec + queue_on_teleport) di server yang sama.
-- getgenv() ter-reset tiap ganti server, jadi tetap boleh resume setelah hop.
if type(getgenv) == "function" then
	if getgenv().__CoastalSniperLoaded then return end
	getgenv().__CoastalSniperLoaded = true
end

local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

-- tunggu game & player siap (penting saat auto-resume setelah hop / fresh join)
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until Players.LocalPlayer
local LP = Players.LocalPlayer

-- boot-log: bukti script benar-benar jalan di tiap server (bisa dicek dari disk)
pcall(function()
	local line = os.date("%Y-%m-%d %H:%M:%S") .. " | JobId=" .. tostring(game.JobId) .. "\n"
	if type(appendfile) == "function" then
		appendfile("CoastalSniper_boot.log", line)
	elseif type(writefile) == "function" then
		local old = (type(isfile) == "function" and isfile("CoastalSniper_boot.log")) and readfile("CoastalSniper_boot.log") or ""
		writefile("CoastalSniper_boot.log", old .. line)
	end
end)

------------------------------------------------------------------ deps
local RR          = require(RS.Modules.ReplicationReciever)
local DataService = require(RS.Modules.DataService)
local BuyListing  = RS.GameEvents.TradeEvents.Booths.BuyListing

------------------------------------------------------------------ config
local TARGET_EGG = "Coastal Egg"
local WANTED = {                       -- pet yang mau dibeli (Orca sengaja tidak ada)
	["Sea Anemone"] = true,
	["Seahorse"]    = true,
	["Hermit Crab"] = true,
}
local CFG = {
	maxToken  = 50,      -- diubah lewat GUI
	autoHop   = true,    -- diubah lewat GUI
	buyDelay  = 0.6,     -- jeda antar pembelian (detik)
	hopDelay  = 2.0,     -- jeda sebelum teleport
	scanEvery = 3.0,     -- jeda antar scan bila masih ada target
}
local running = false

-- forward-declare biar bisa dipakai serverHop (didefinisikan di bagian GUI)
local log, setStatus

------------------------------------------------------------------ state (persist antar-hop)
local STATE_FILE = "CoastalSniper_state.json"
local function persistState()
	pcall(function()
		writefile(STATE_FILE, HttpService:JSONEncode({
			maxToken = CFG.maxToken,
			autoHop  = CFG.autoHop,
			running  = running,
		}))
	end)
end
local function loadState()
	local exists = (isfile and isfile(STATE_FILE))
	if exists then
		local ok, t = pcall(function() return HttpService:JSONDecode(readfile(STATE_FILE)) end)
		if ok and type(t) == "table" then return t end
	end
	return nil
end

------------------------------------------------------------------ util
local function getTokens()
	local ok, data = pcall(function() return DataService:GetData() end)
	if ok and type(data) == "table" and type(data.TradeData) == "table" then
		return data.TradeData.Tokens or 0
	end
	return math.huge -- kalau gagal baca, jangan blok pembelian
end

local function ownerToUserId(owner)
	return tonumber((tostring(owner):gsub("Player_", "")))
end

-- kumpulkan target dari data booth live
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
				if p and p.HatchedFrom == TARGET_EGG and WANTED[it.PetType] then
					local ply = Players:GetPlayerByUserId(ownerToUserId(owner))
					targets[#targets+1] = {
						pet     = it.PetType,
						name    = p.Name,
						price   = l.Price,
						uuid    = lid,
						owner   = ply,           -- objek Player pemilik booth (nil kalau tidak di server)
						present = ply ~= nil,
					}
				end
			end
		end
	end
	table.sort(targets, function(a, b) return a.price < b.price end)
	return targets
end

------------------------------------------------------------------ server hop
local function httpJson(url)
	local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
	if reqFn then
		local ok, res = pcall(reqFn, { Url = url, Method = "GET" })
		if ok and res and res.Body then
			local ok2, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
			if ok2 then return decoded end
		end
	end
	-- fallback game:HttpGet
	local ok3, body = pcall(function() return game:HttpGet(url) end)
	if ok3 then
		local ok4, decoded = pcall(function() return HttpService:JSONDecode(body) end)
		if ok4 then return decoded end
	end
	return nil
end

local function queueResume()
	local q = queue_on_teleport or (syn and syn.queue_on_teleport) or queueteleport
	if q then
		pcall(q, [[loadstring(readfile("CoastalSniper.lua"))()]])
	end
end

-- ambil daftar jobId server yang belum penuh (dgn paging)
local function getOpenServers(placeId)
	local list, cursor, tries = {}, nil, 0
	repeat
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(placeId)
		if cursor then url = url .. "&cursor=" .. cursor end
		local data = httpJson(url)
		if data and data.data then
			for _, s in ipairs(data.data) do
				if s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 0) then
					list[#list+1] = s.id
				end
			end
			cursor = data.nextPageCursor
		else
			cursor = nil
		end
		tries += 1
	until not cursor or tries >= 6
	return list
end

-- HOP dengan RETRY sampai benar-benar pindah.
-- Teleport yang sukses akan mengakhiri sesi ini, jadi loop otomatis berhenti saat berhasil.
local hopInProgress = false
local function serverHop(reason)
	if not CFG.autoHop then return false end
	if hopInProgress then return true end
	hopInProgress = true
	queueResume()
	local placeId = game.PlaceId

	local tried = {}                     -- jobId yang sudah gagal, jangan diulang
	local function attempt()
		if not running then return end
		local servers = getOpenServers(placeId)
		-- buang yang sudah gagal
		local pool = {}
		for _, id in ipairs(servers) do if not tried[id] then pool[#pool+1] = id end end
		if #pool > 0 then
			local jobId = pool[math.random(1, #pool)]
			tried[jobId] = true
			setStatus("Hop -> server baru... (" .. #pool .. " kandidat)")
			local ok = pcall(function() TeleportService:TeleportToPlaceInstance(placeId, jobId, LP) end)
			if not ok then task.wait(1); attempt() end
		else
			-- tidak ada kandidat baru (API limit / semua sudah dicoba) -> teleport acak
			setStatus("Tidak ada kandidat, teleport acak...")
			local ok = pcall(function() TeleportService:Teleport(placeId, LP) end)
			if not ok then task.wait(2); attempt() end
		end
	end

	-- retry otomatis kalau teleport GAGAL diinisiasi (server penuh, error, dsb.)
	local conn
	conn = TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
		if plr == LP then
			log("Teleport gagal: " .. tostring(msg) .. " -> coba server lain")
			task.wait(1.5)
			if running then attempt() end
		end
	end)
	-- kalau kelamaan belum pindah, retry lagi (jaga-jaga event tidak nembak)
	task.spawn(function()
		while hopInProgress and running do
			task.wait(12)
			if hopInProgress and running then
				log("Belum pindah, retry hop...")
				attempt()
			end
		end
		if conn then conn:Disconnect() end
	end)

	attempt()
	return true
end

------------------------------------------------------------------ GUI
local gui = Instance.new("ScreenGui")
gui.Name = "CoastalSniper"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local main = mk("Frame", {
	Size = UDim2.fromOffset(280, 250),
	Position = UDim2.new(0.5, -140, 0.35, 0),
	BackgroundColor3 = Color3.fromRGB(20, 24, 32),
	BorderSizePixel = 0,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
mk("UIStroke", { Color = Color3.fromRGB(0, 208, 255), Thickness = 1.5 }, main)

local title = mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = Color3.fromRGB(0, 208, 255),
	Text = "  Coastal Sniper",
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBold, TextSize = 15,
	TextColor3 = Color3.fromRGB(10, 14, 20),
}, main)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, title)

-- drag
do
	local dragging, dragStart, startPos
	title.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = i.Position; startPos = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

-- Max Token row
mk("TextLabel", {
	Size = UDim2.new(0.5, -12, 0, 30), Position = UDim2.fromOffset(10, 44),
	BackgroundTransparency = 1, Text = "Max Token / pet",
	TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham,
	TextSize = 13, TextColor3 = Color3.fromRGB(220, 225, 230),
}, main)
local tokenBox = mk("TextBox", {
	Size = UDim2.new(0.5, -12, 0, 30), Position = UDim2.new(0.5, 2, 0, 44),
	BackgroundColor3 = Color3.fromRGB(34, 40, 50), BorderSizePixel = 0,
	Text = tostring(CFG.maxToken), PlaceholderText = "50",
	Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(0, 208, 255),
	ClearTextOnFocus = false,
}, main)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, tokenBox)
tokenBox.FocusLost:Connect(function()
	local n = tonumber(tokenBox.Text)
	if n and n > 0 then CFG.maxToken = math.floor(n) end
	tokenBox.Text = tostring(CFG.maxToken)
	persistState()
end)

-- Auto-hop toggle
local hopBtn = mk("TextButton", {
	Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 82),
	BackgroundColor3 = Color3.fromRGB(34, 40, 50), BorderSizePixel = 0,
	Text = "Auto-Hop: ON", Font = Enum.Font.Gotham, TextSize = 13,
	TextColor3 = Color3.fromRGB(120, 255, 160),
}, main)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, hopBtn)
hopBtn.MouseButton1Click:Connect(function()
	CFG.autoHop = not CFG.autoHop
	hopBtn.Text = "Auto-Hop: " .. (CFG.autoHop and "ON" or "OFF")
	hopBtn.TextColor3 = CFG.autoHop and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 120, 120)
	persistState()
end)

-- Start/Stop
local runBtn = mk("TextButton", {
	Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 120),
	BackgroundColor3 = Color3.fromRGB(0, 170, 90), BorderSizePixel = 0,
	Text = "START", Font = Enum.Font.GothamBold, TextSize = 15,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, main)
mk("UICorner", { CornerRadius = UDim.new(0, 8) }, runBtn)

-- status + log
local status = mk("TextLabel", {
	Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 160),
	BackgroundTransparency = 1, Text = "Idle. Token: " .. tostring(getTokens()),
	TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham,
	TextSize = 12, TextColor3 = Color3.fromRGB(200, 210, 220),
}, main)
local logBox = mk("TextLabel", {
	Size = UDim2.new(1, -20, 1, -190), Position = UDim2.fromOffset(10, 182),
	BackgroundColor3 = Color3.fromRGB(14, 17, 23), BorderSizePixel = 0,
	Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	Font = Enum.Font.Code, TextSize = 11, TextColor3 = Color3.fromRGB(170, 180, 190),
	TextWrapped = true,
}, main)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, logBox)

local logLines = {}
function log(msg)   -- assign ke forward-decl di atas (bukan local baru)
	table.insert(logLines, msg)
	while #logLines > 8 do table.remove(logLines, 1) end
	logBox.Text = table.concat(logLines, "\n")
end
function setStatus(s) status.Text = s end

------------------------------------------------------------------ core loop
local function buyPass()
	local targets = collectTargets()
	local presentBuyable = 0
	local bought = 0
	for _, t in ipairs(targets) do
		if not running then break end
		if t.present and t.price <= CFG.maxToken then
			presentBuyable += 1
			if getTokens() >= t.price then
				local ok, success, msg = pcall(function() return BuyListing:InvokeServer(t.owner, t.uuid) end)
				if ok and success then
					bought += 1
					log(("BUY %s '%s' @ %d"):format(t.pet, tostring(t.name), t.price))
				else
					log(("FAIL %s @ %d (%s)"):format(t.pet, t.price, tostring(msg or success)))
				end
				task.wait(CFG.buyDelay)
			else
				log("Token kurang untuk " .. t.pet .. " @ " .. t.price)
			end
		end
	end
	return #targets, presentBuyable, bought
end

local function mainLoop()
	while running do
		setStatus(("Scan... Token:%s"):format(tostring(getTokens())))
		local total, buyable, bought = buyPass()
		if not running then break end
		setStatus(("Target:%d  Beli:%d  Token:%s"):format(total, bought, tostring(getTokens())))
		if buyable > 0 and bought > 0 then
			-- masih ada yang kebeli, cek lagi sebentar (mungkin ada sisa)
			task.wait(CFG.scanEvery)
		else
			-- tidak ada target yang bisa dibeli di server ini
			if CFG.autoHop then
				setStatus("Tidak ada target <= " .. CFG.maxToken .. " token. Hop server...")
				log("No target. Hopping server...")
				task.wait(CFG.hopDelay)
				serverHop("no-target")
				break
			else
				setStatus("Tidak ada target. (Auto-Hop OFF) Menunggu...")
				task.wait(CFG.scanEvery)
			end
		end
	end
end

local function startRun()
	if running then return end
	running = true
	runBtn.Text = "STOP"
	runBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	persistState()
	task.spawn(mainLoop)
end
local function stopRun()
	running = false
	runBtn.Text = "START"
	runBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
	setStatus("Dihentikan.")
	persistState()
end

runBtn.MouseButton1Click:Connect(function()
	if running then stopRun() else startRun() end
end)

log("Target: Sea Anemone/Seahorse/Hermit Crab (Coastal Egg)")

-- muat state & auto-resume setelah hop
local st = loadState()
if st then
	if type(st.maxToken) == "number" and st.maxToken > 0 then
		CFG.maxToken = math.floor(st.maxToken)
		tokenBox.Text = tostring(CFG.maxToken)
	end
	if type(st.autoHop) == "boolean" then
		CFG.autoHop = st.autoHop
		hopBtn.Text = "Auto-Hop: " .. (CFG.autoHop and "ON" or "OFF")
		hopBtn.TextColor3 = CFG.autoHop and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 120, 120)
	end
	if st.running then
		log("Auto-resume setelah hop -> START otomatis.")
		task.wait(1.5)   -- beri jeda agar data booth ter-replikasi
		startRun()
	else
		log("Siap. Set Max Token lalu START.")
	end
else
	log("Siap. Set Max Token lalu START.")
end
