--[[ pnp.lua — Pick & Place pet.
     Logic disamakan dengan script PNP stabil (hasil analisa remote spy):
       1. Baca ready via RemoteFunction GetPetCooldown (tanya server real-time), BUKAN tebak event pasif.
       2. Semua pet ditaruh NUMPUK di 1 titik = center PetArea (bukan grid nyebar).
       3. Ready = passive non-"Mutation" Time <= 0 → Unequip lalu Equip di center. ]]
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

	-- RemoteFunction untuk tanya cooldown asli ke server (kunci kestabilan)
	local GetPetCooldown = RS:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")

	----------------------------------------------------------------- helpers
	-- Baca cooldown skill utama sebuah pet langsung dari server.
	-- Return: mainCd (angka, detik) atau nil kalau gagal.
	local function readMainCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		if not ok or type(cd) ~= "table" then return nil end

		local data = {}
		local mainCd = 0
		for _, e in ipairs(cd) do
			local t = tonumber(e.Time) or 0
			data[#data + 1] = { Passive = e.Passive, Time = t }
			-- Abaikan passive mutasi; skill utama = passive non-"Mutation" dengan CD terbesar
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
			-- Format: "Mutasi Nama | Berat | Age" (mutasi penuh, mis. "EV" -> "Everchanted").
			local mutName = mut
			if mut and ctx.reg and ctx.reg.mutDisplay then mutName = ctx.reg.mutDisplay(mut) end
			local mutPrefix = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
			-- berat tampil game = BaseWeight * (1 + 0.1*Level)
			local weight = (pd.BaseWeight or 0) * (1 + 0.1 * age)
			local tag = eqSet[uuid] and " [aktif]" or ""
			out[#out + 1] = {
				value = uuid,
				display = ("%s%s | %.2f KG | Age %s | #%s%s"):format(mutPrefix, pt, weight, tostring(age), uuid:sub(2, 5), tag),
			}
		end
		-- Auto-prune UUID kepilih yang pet-nya udah ga ada di inventory (biar ga nyangkut
		-- kepilih padahal pet-nya udah ilang). Cuma kalau inventory beneran ada isinya,
		-- biar ga salah hapus saat data telat ke-load.
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

	----------------------------------------------------------------- loop (decouple: reader + actor)
	-- Masalah: query GetPetCooldown itu round-trip server dgn latency JITTER (58-465ms). Kalau
	-- 1 thread query->act->ulang, jitter query nge-block eksekusi -> "kadang responsif kadang ngga".
	-- Solusi: pisah dua peran per pet:
	--   READER : query cd terus -> simpen ke cache. Jitter diserap di sini (ga ganggu act).
	--            Pet cd-PANJANG di-throttle (query jarang) -> ngurangin flood; pet ready/low-cd
	--            tetep query ngebut biar nangkep window ready.
	--   ACTOR  : baca CACHE (instan, ga nunggu network) -> pickup-place di interval tetap.
	--            -> eksekusi KONSISTEN, ga ke-gate jitter query. cd check TETAP (dari cache).
	local cdCache = ctx.state.pnpCdCache or {}
	ctx.state.pnpCdCache = cdCache
	local spawned = {} -- uuid -> true (reader+actor udah dispawn)

	local function isTarget(uuid)
		for _, p in ipairs(targetPets()) do if p.uuid == uuid then return true end end
		return false
	end

	local function runReader(uuid, myId)
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			if not isTarget(uuid) then break end
			local cd = readMainCd(uuid) -- update cdMap (UI) + return mainCd
			cdCache[uuid] = cd
			-- throttle by cd: jauh -> santai (kurangi flood); low/ready -> ngebut (nangkep window)
			local w
			if cd == nil then w = 0.3
			elseif cd > 20 then w = math.clamp(cd / 4, 1, 4)
			else w = 0.05 end
			task.wait(w)
		end
		cdCache[uuid] = nil
		spawned[uuid] = nil
	end

	local function runActor(uuid, myId)
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			if not isTarget(uuid) then break end
			local cd = cdCache[uuid]
			local pos = placePos()
			if pos and cd ~= nil and cd <= READY_TH then
				if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end
				if not (CFG.pnpEnabled and ctx.state.pnpId == myId) then break end
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				task.wait(math.max(0.01, CFG.equipDelay))
				if not (CFG.pnpEnabled and ctx.state.pnpId == myId) then break end
				pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
				-- optimistic: anggap on-cd dulu sampai reader konfirmasi cd baru (anti spam re-equip)
				cdCache[uuid] = math.huge
			end
			task.wait(math.max(0.03, tonumber(CFG.pnpScanInterval) or 0.05))
		end
	end

	local function pnpLoop()
		ctx.state.pnpId = (ctx.state.pnpId or 0) + 1
		local myId = ctx.state.pnpId
		ctx.elevate()

		-- Supervisor: tiap pet target dapet 1 reader + 1 actor (sekali spawn)
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP: tidak ada pet target (equip pet dulu)")
			else
				for _, p in ipairs(pets) do
					if not spawned[p.uuid] then
						spawned[p.uuid] = true
						task.spawn(runReader, p.uuid, myId)
						task.spawn(runActor, p.uuid, myId)
					end
				end
				setStatus(("PNP jalan: %d pet (reader+actor)"):format(#pets))
			end
			task.wait(1) -- supervisor cek pet baru tiap 1 detik
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
end
