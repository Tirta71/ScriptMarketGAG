--[[ pnp.lua — Pick & Place pet, SETELAH skill terkonfirmasi keluar.
     Deteksi via HighlightRemote:
       Server mengirim HighlightRemote(petInstance, 3) saat pet nge-skill.
       Arg[1] = Instance pet (Name = UUID), Arg[2] = 3 (skill activation).
       Ini sinyal paling awal & paling pasti: fire SEBELUM Notification & Cooldown.
     Flow:
       Pet di tanah → HighlightRemote(UUID, 3) terkonfirmasi
       → pickupDelay → Pickup → equipDelay → Place → repeat ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local PU          = ctx.deps.PU
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")

	----------------------------------------------------------------- skill detection via HighlightRemote
	-- skillFiredAt[uuid] = os.clock() saat HighlightRemote(petInstance, 3) diterima.
	-- lastPlacedAt[uuid] = os.clock() saat kita terakhir menaruh pet ini (EquipPet).
	local skillFiredAt = {}
	local lastPlacedAt = {}

	local HighlightRemote = RS:WaitForChild("GameEvents"):FindFirstChild("HighlightRemote")
	if HighlightRemote then
		HighlightRemote.OnClientEvent:Connect(function(petInstance, highlightType)
			-- Filter: hanya skill activation (type 3)
			if highlightType ~= 3 then return end
			if typeof(petInstance) ~= "Instance" then return end

			-- Ambil UUID dari nama Instance (format: "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}")
			local uuid = petInstance.Name
			if not uuid:match("^{") then
				-- Fallback: cek atribut UUID
				uuid = petInstance:GetAttribute("UUID") or petInstance.Name
			end

			if type(uuid) == "string" and #uuid > 0 then
				skillFiredAt[uuid] = os.clock()
			end
		end)
	end

	-- Apakah pet ini sudah nge-skill SETELAH terakhir kali ditaruh?
	local function hasSkillFired(uuid)
		local fired = skillFiredAt[uuid]
		if not fired then return false end

		-- Jika belum pernah ditaruh oleh kita (initial state), cukup cek ada fired
		local placed = lastPlacedAt[uuid]
		if not placed then return true end

		-- Jika sudah ditaruh, fired harus SETELAH placed
		return fired > placed
	end

	----------------------------------------------------------------- LONG-CD (mis. Ferret): deteksi self-fire via cooldown
	-- Pet long-CD (skill cooldown lama) TIDAK bisa force-fire lewat re-place, dan HighlightRemote(3)-nya
	-- sering FALSE POSITIVE (ke-highlight aura pet lain, mis. Peacock). Sinyal bersih "pet ini beneran
	-- nembak sendiri" = cooldown-nya sendiri LOMPAT dari ready (0) -> penuh. Aura cuma NURUNIN cooldown,
	-- jadi transisi naik (rendah->tinggi) pasti = self-fire. PNP dipakai buat SKIP animasi skill yg lama.
	local PetList, PassiveRegistry
	pcall(function() PetList = require(RS.Data.PetRegistry.PetList) end)
	pcall(function() PassiveRegistry = require(RS.Data.PetRegistry.PassiveRegistry) end)

	local LONG_CD_THRESHOLD = 120  -- detik; >= ini dianggap long-CD

	-- klasifikasi per petType (cache): true = long-CD
	local longClass = {}
	local function isLongCD(petType)
		if not petType then return false end
		local c = longClass[petType]
		if c ~= nil then return c end
		local res = false
		local p = PetList and PetList[petType]
		local pas = p and p.Passives
		local passiveName = type(pas) == "table" and pas[1] or nil
		local reg = passiveName and PassiveRegistry and PassiveRegistry[passiveName]
		local cd = reg and reg.States and reg.States.Cooldown
		if type(cd) == "table" then
			local m = tonumber(cd.Min) or tonumber(cd.Base)
			if m and m >= LONG_CD_THRESHOLD then res = true end
		end
		longClass[petType] = res
		return res
	end

	-- Deteksi READY via PetCooldownsUpdated: cooldown skill utama (non-mutation) turun ke ~0.
	-- Aura Peacock nurunin cooldown; pas nyampe ~0 = skill READY -> langsung PNP (skip animasi).
	-- longArmed dipakai biar sekali PNP per siklus: di-arm pas cooldown tinggi lagi (habis reset),
	-- di-disarm pas kita PNP. Jadi nggak spam & nggak ke-trigger sama reset PNP kita sendiri.
	local ownCd     = {}   -- uuid -> Time cooldown skill utama terkini
	local longArmed = {}   -- uuid -> boolean, boleh trigger saat ready
	local READY_TH  = 10   -- detik; <= ini = ready (mau nembak)
	local RESET_TH  = 300  -- detik; > ini = cooldown baru di-reset -> arm ulang
	local PetCD = RS:WaitForChild("GameEvents"):FindFirstChild("PetCooldownsUpdated")
	if PetCD then
		PetCD.OnClientEvent:Connect(function(uuid, cd)
			if type(uuid) ~= "string" then return end
			-- Time cooldown skill utama. Kalau TIDAK ada di payload ini, abaikan (payload partial).
			local frier
			if type(cd) == "table" then
				for _, e in ipairs(cd) do
					if not tostring(e.Passive or ""):find("Mutation") then
						frier = tonumber(e.Time)
					end
				end
			end
			if frier == nil then return end
			ownCd[uuid] = frier
			if frier > RESET_TH then longArmed[uuid] = true end  -- cooldown tinggi lagi -> siap trigger
		end)
	end

	local function hasLongReady(uuid)
		return (longArmed[uuid] == true) and (ownCd[uuid] ~= nil) and (ownCd[uuid] <= READY_TH)
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
			-- filter per-UUID: kosong = semua equipped; kalau ada pilihan, hanya yang dicentang
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = pt }
			end
		end
		return out
	end

	-- daftar pet dari INVENTORY (semua pet, bukan cuma yang di-garden) buat dropdown Select Pets.
	-- {value=uuid, display=label}. Pet yang dipilih tapi belum di-garden bakal auto-di-taruh oleh loop.
	function ctx.inventoryPetOptions()
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
			local mutStr = (mut and mut ~= "" and mut ~= "Normal") and (" " .. tostring(mut)) or ""
			local tag = eqSet[uuid] and " [aktif]" or ""
			out[#out + 1] = {
				value = uuid,
				display = ("%s%s | Age %s | #%s%s"):format(pt, mutStr, tostring(age), uuid:sub(2, 5), tag),
			}
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		return out
	end

	-- Posisi placement: tiap pet dikasih SLOT grid tetap yang rapat di sekitar center farm.
	-- Kalau banyak pet ditaruh di titik sama, game nyebar mereka (anti-overlap) -> mencar.
	-- Grid rapat (jarak ~SP stud) = nggak overlap TAPI tetap ngumpul dalam jangkauan aura Peacock.
	-- Slot deterministik per pet -> posisi stabil, nggak drift/loncat.
	local LP = ctx.LP

	local function playerPos()
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local GetFarm = require(RS.Modules.GetFarm)
	local function farmCenter()
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		return playerPos()
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3   -- 6 kolom, jarak 3 stud (rapat, dalam aura)
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

	----------------------------------------------------------------- loop
	local function pnpLoop()
		ctx.state.pnpId = (ctx.state.pnpId or 0) + 1
		local myId = ctx.state.pnpId
		ctx.elevate()
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP: tidak ada pet target (equip pet dulu)")
				task.wait(1)
			else
				local didAny = false
				for _, p in ipairs(pets) do
					if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

					-- Pilih detektor:
					--   long-CD (Ferret dll): READY (cooldown ~0) -> PNP SEKETIKA biar animasi ke-skip.
					--   short-CD (Dilo/Peacock/Mimic): HighlightRemote force-fire (tak diubah).
					local isLong = isLongCD(p.petType)
					local fired
					if isLong then
						fired = hasLongReady(p.uuid)
					else
						fired = hasSkillFired(p.uuid)
					end

					if fired then
						didAny = true

						-- long-CD: langsung pick (skip animasi). short-CD: pakai pickupDelay.
						if not isLong and CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end
						if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

						-- PICKUP -> equipDelay -> PLACE (posisi cache/center, sama kaya pet lain)
						local pos = getPos(p.uuid)
						pcall(function() PetsService:FireServer("UnequipPet", p.uuid) end)
						task.wait(math.max(0.01, CFG.equipDelay))
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", p.uuid, CFrame.new(pos)) end)
						end
						lastPlacedAt[p.uuid] = os.clock()

						-- disarm long-CD sampai cooldown ke-reset tinggi lagi (anti dobel-PNP)
						if isLong then longArmed[p.uuid] = false end
					end
				end
				setStatus(("PNP jalan: %d pet%s"):format(#pets, didAny and "" or " (nunggu skill keluar)"))
				task.wait(0.15)
			end
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
	-- stop cukup set CFG.pnpEnabled=false
end



