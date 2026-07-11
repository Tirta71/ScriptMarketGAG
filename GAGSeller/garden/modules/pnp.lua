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

	-- deteksi self-fire via PetCooldownsUpdated: cooldown non-mutation lompat ready(0) -> tinggi
	local ownCd = {}          -- uuid -> Time cooldown non-mutation terakhir
	local longFiredAt = {}    -- uuid -> os.clock() saat self-fire terdeteksi
	local PetCD = RS:WaitForChild("GameEvents"):FindFirstChild("PetCooldownsUpdated")
	if PetCD then
		PetCD.OnClientEvent:Connect(function(uuid, cd)
			if type(uuid) ~= "string" then return end
			-- ambil Time cooldown skill utama (non-mutation). Kalau TIDAK ada di payload ini,
			-- ABAIKAN event ini (payload cooldown itu partial/per-passive) -> anti false-fire.
			local frier
			if type(cd) == "table" then
				for _, e in ipairs(cd) do
					if not tostring(e.Passive or ""):find("Mutation") then
						frier = tonumber(e.Time)
					end
				end
			end
			if frier == nil then return end
			local prev = ownCd[uuid]
			-- Aura pet lain cuma NURUNIN cooldown. Lonjakan NAIK besar = pet ini baru nembak
			-- (cooldown reset) = animasi mulai. Kita PNP di sini buat skip animasi.
			if prev ~= nil and (frier - prev) > 200 then
				longFiredAt[uuid] = os.clock()
			end
			ownCd[uuid] = frier
		end)
	end

	local function hasLongFired(uuid)
		local fired = longFiredAt[uuid]
		if not fired then return false end
		local placed = lastPlacedAt[uuid]
		if not placed then return true end
		return fired > placed
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

	-- daftar pet equipped (buat dropdown Select Pets): {value=uuid, display=label}
	function ctx.equippedPetOptions()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		for _, uuid in ipairs(eq) do
			local v = inv and inv[uuid]
			local pt = v and v.PetType or "?"
			local age = v and v.PetData and v.PetData.Level or 0
			local mut = v and v.PetData and v.PetData.MutationType
			local mutStr = (mut and mut ~= "" and mut ~= "Normal") and (" " .. tostring(mut)) or ""
			out[#out + 1] = {
				value = uuid,
				display = ("%s%s | Age %s | #%s"):format(pt, mutStr, tostring(age), uuid:sub(2, 5)),
			}
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		return out
	end

	-- Posisi placement. Cache posisi asli pet agar tidak drift.
	local lastPos = {}
	local LP = ctx.LP

	local function playerPos()
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local GetFarm = require(RS.Modules.GetFarm)

	local function getPos(uuid)
		if lastPos[uuid] then return lastPos[uuid] end
		if PU then
			local ok, model = pcall(function() return PU:FindLocalPetModel(uuid) end)
			if ok and model and typeof(model) == "Instance" then
				local okc, cf = pcall(function() return model:GetPivot() end)
				if okc then lastPos[uuid] = cf.Position; return cf.Position end
			end
		end
		local farm = GetFarm and GetFarm(LP)
		local petArea = farm and farm:FindFirstChild("PetArea")
		if petArea then return petArea.Position end
		return playerPos()
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

					-- Pilih detektor: long-CD (Ferret dll) pakai self-fire cooldown biar nggak ketipu
					-- aura & nggak loop; short-CD (Dilo/Peacock/Mimic) tetap pakai HighlightRemote (tak diubah).
					local fired
					if isLongCD(p.petType) then
						fired = hasLongFired(p.uuid)
					else
						fired = hasSkillFired(p.uuid)
					end

					if fired then
						didAny = true

						-- 1) Tunggu pickupDelay (biar skill selesai efeknya)
						if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end
						if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

						-- 2) PICKUP (cabut pet)
						local pos = getPos(p.uuid)
						pcall(function() PetsService:FireServer("UnequipPet", p.uuid) end)

						-- 3) Tunggu equipDelay
						task.wait(math.max(0.01, CFG.equipDelay))

						-- 4) PLACE (taruh pet kembali)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", p.uuid, CFrame.new(pos)) end)
						end

						-- 5) Catat waktu penempatan
						lastPlacedAt[p.uuid] = os.clock()
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



