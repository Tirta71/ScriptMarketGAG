--[[ pnp_event_test.lua — TEST PNP EVENT-DRIVEN (standalone).
     Dengerin PetCooldownsUpdated (server push) buat trigger pickup — TANPA polling
     round-trip GetPetCooldown. Target = pet yang lagi kepilih di filter PNP
     (CFG.pnpUuids dari AllegiaanHub_garden_state.json); kalau filter kosong = semua
     pet equipped.

     PENTING: MATIIN dulu "Enable Automation Pickup" di GAG Hub biar ga dobel cycle.
     STOP test: getgenv().__pnpev_stop = true
     Lihat jumlah pickup: getgenv().__pnpev_count ]]

local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LP = game.Players.LocalPlayer

local GameEvents = RS:WaitForChild("GameEvents")
local PetsService = GameEvents:WaitForChild("PetsService")
local PetCooldownsUpdated = GameEvents:WaitForChild("PetCooldownsUpdated")
local GetPetCooldown = GameEvents:WaitForChild("GetPetCooldown")
local DataService = require(RS.Modules.DataService)
local GetFarm = require(RS.Modules.GetFarm)

-- baca filter + delay dari config GAG
local pnpUuids, pickupDelay, equipDelay = {}, 0, 0.1
pcall(function()
	if isfile and isfile("AllegiaanHub_garden_state.json") then
		local cfg = HttpService:JSONDecode(readfile("AllegiaanHub_garden_state.json"))
		pnpUuids   = cfg.pnpUuids or {}
		pickupDelay = tonumber(cfg.pickupDelay) or 0
		equipDelay  = tonumber(cfg.equipDelay) or 0.1
	end
end)

pcall(function()
	local f = setthreadidentity or setidentity or (syn and syn.set_thread_identity)
	if f then f(7) end
end)

local function placePos()
	local farm = GetFarm(LP)
	local pa = farm and farm:FindFirstChild("PetArea")
	if pa then return pa.Position end
	local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position
end

local function mainCdOf(arr)
	local m = 0
	for _, e in ipairs(arr) do
		if not tostring(e.Passive or ""):find("Mutation") then
			local t = tonumber(e.Time) or 0
			if t > m then m = t end
		end
	end
	return m
end

local g = getgenv()
g.__pnpev_stop = false
g.__pnpev_count = 0

-- cache equipped set, refresh tiap 1s (jangan GetData tiap event)
local eqSet = {}
local function refreshEq()
	local d = DataService:GetData()
	local eq = d.PetsData and d.PetsData.EquippedPets or {}
	local s = {}
	for _, u in ipairs(eq) do s[u] = true end
	eqSet = s
end
refreshEq()

local function isTarget(uuid)
	if not eqSet[uuid] then return false end
	if not next(pnpUuids) then return true end
	return pnpUuids[uuid] == true
end

local busy = {}
local function pickup(uuid)
	if busy[uuid] or g.__pnpev_stop then return end
	busy[uuid] = true
	local pos = placePos()
	if pos then
		if pickupDelay > 0 then task.wait(pickupDelay) end
		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
		task.wait(math.max(0.01, equipDelay))
		pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
		g.__pnpev_count = g.__pnpev_count + 1
	end
	busy[uuid] = false
end

-- LISTENER: server push cooldown -> pas target ready langsung pickup (nol round-trip)
local conn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, arr)
	if g.__pnpev_stop or type(arr) ~= "table" then return end
	if mainCdOf(arr) <= 0 and isTarget(uuid) and not busy[uuid] then
		task.spawn(pickup, uuid)
	end
end)

-- SAFETY POLL 1s: jaring-jaring kalau ada push kelewat
task.spawn(function()
	while not g.__pnpev_stop do
		refreshEq()
		for uuid in pairs(eqSet) do
			if isTarget(uuid) and not busy[uuid] then
				pcall(function()
					local r = GetPetCooldown:InvokeServer(uuid)
					if type(r) == "table" and mainCdOf(r) <= 0 then task.spawn(pickup, uuid) end
				end)
			end
		end
		task.wait(1)
	end
end)

-- auto-stop 5 menit + cleanup + report tiap 30s
task.spawn(function()
	local start = os.clock()
	local lastReport = 0
	while not g.__pnpev_stop and os.clock() - start < 300 do
		task.wait(1)
		if os.clock() - lastReport >= 30 then
			lastReport = os.clock()
			print(("[PNP-EVENT] pickup=%d  (%.0fs)"):format(g.__pnpev_count, os.clock() - start))
		end
	end
	g.__pnpev_stop = true
	if conn then conn:Disconnect() end
	print(("[PNP-EVENT] SELESAI. total pickup=%d"):format(g.__pnpev_count))
end)

local n = 0; for _ in pairs(pnpUuids) do n = n + 1 end
print(("[PNP-EVENT] START. filter=%d pet (0=semua equipped), pickupDelay=%s equipDelay=%s"):format(n, tostring(pickupDelay), tostring(equipDelay)))
