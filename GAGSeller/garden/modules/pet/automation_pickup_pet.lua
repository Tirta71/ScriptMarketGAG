--[[ automation_pickup_pet.lua — Pick & Place pet (EVENT-DRIVEN).
     Kestabilan: BUKAN polling GetPetCooldown (round-trip jitter 58-465ms), tapi DENGERIN
     RemoteEvent server `PetCooldownsUpdated` yang PUSH cooldown tiap berubah (nol round-trip,
     nol jitter, nol flood). Actor act dari cd real-time di memori.
       1. Listener PetCooldownsUpdated -> update cdLive[uuid] (+ cdMap buat UI).
       2. Seed sekali via GetPetCooldown pas pet pertama jadi target (biar ga nunggu push).
       3. Ready = mainCd (passive non-"Mutation" Time terbesar) <= 0 -> Unequip lalu Equip di center.
       4. Semua pet ditaruh di center PetArea (numpuk 1 titik, seperti script referensi). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = {}   -- uuid -> { data = {...} } untuk UI Monitor
	ctx.state.cdMap = cdMap

	local READY_TH = 0 -- detik; cooldown skill utama <= ini dianggap ready

	local GameEvents = RS:WaitForChild("GameEvents")
	local GetPetCooldown = GameEvents:WaitForChild("GetPetCooldown")             -- buat seed awal
	local PetCooldownsUpdated = GameEvents:WaitForChild("PetCooldownsUpdated")   -- push cd real-time

	----------------------------------------------------------------- cd real-time (event-driven)
	-- Hitung mainCd dari tabel cooldown. Skill utama = passive non-"Mutation" dgn Time terbesar.
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

	-- cdLive: cd terakhir per pet, di-update oleh event PetCooldownsUpdated (server push).
	local cdLive = {}
	ctx.state.pnpCdLive = cdLive

	-- Listener sekali; disconnect yg lama biar ga dobel pas hub reload.
	do
		local g = (getgenv and getgenv()) or _G
		if g.__pnpCdConn then pcall(function() g.__pnpCdConn:Disconnect() end) end
		g.__pnpCdConn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdTable)
			if type(uuid) ~= "string" then return end
			local m, data = computeMainCd(cdTable)
			if m ~= nil then cdLive[uuid] = m; cdMap[uuid] = { data = data } end
		end)
	end

	-- Seed: query GetPetCooldown SEKALI (pas pet pertama jadi target) biar ga nunggu push pertama.
	local function seedCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		local m, data = computeMainCd(ok and cd or nil)
		if m ~= nil then cdLive[uuid] = m; cdMap[uuid] = { data = data } end
	end

	----------------------------------------------------------------- helpers
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

	-- daftar pet dari INVENTORY buat dropdown Select Pets.
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

	-- Titik place: center PetArea (semua pet ditumpuk di sini, seperti script referensi)
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
	-- Tiap pet target punya thread sendiri: baca cdLive (dari event) -> kalau ready -> pickup-place.
	-- GA ada query cd di loop (cd datang dari PetCooldownsUpdated) -> nol jitter, nol flood.
	local petThreads = {} -- uuid -> true
	local lastPlace = {}  -- uuid -> os.clock() terakhir place (anti double-fire di window ready sama)

	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		if cdLive[uuid] == nil then seedCd(uuid) end -- seed awal biar ga nunggu push pertama
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			-- Pastikan pet masih target (equipped + lolos filter pnpUuids)
			local stillTarget = false
			for _, p in ipairs(targetPets()) do
				if p.uuid == uuid then stillTarget = true; break end
			end
			if not stillTarget then break end

			local cd = cdLive[uuid]
			local pos = placePos()
			-- ready + udah lewat jeda min sejak place terakhir (biar ga dobel sebelum event update cd)
			if pos and cd ~= nil and cd <= READY_TH and (os.clock() - (lastPlace[uuid] or 0)) > 0.25 then
				if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end
				if not (CFG.pnpEnabled and ctx.state.pnpId == myId) then break end
				-- PICKUP -> PLACE (numpuk di center)
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				task.wait(math.max(0.01, CFG.equipDelay))
				if not (CFG.pnpEnabled and ctx.state.pnpId == myId) then break end
				pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
				lastPlace[uuid] = os.clock()
			end

			task.wait(math.max(0.02, tonumber(CFG.pnpScanInterval) or 0.05))
		end
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpId = (ctx.state.pnpId or 0) + 1
		local myId = ctx.state.pnpId
		ctx.elevate()

		-- Supervisor: spawn thread untuk tiap pet target yang belum punya thread
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP: tidak ada pet target (equip pet dulu)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then
						task.spawn(runPetThread, p.uuid, myId)
					end
				end
				setStatus(("PNP jalan: %d pet (event-driven)"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
end
