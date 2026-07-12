--[[ pnp.lua — Pick & Place pet, berbasis sisa Cooldown (Ready-only PNP).
     Menerapkan pemantauan cooldown murni dari server (PetCooldownsUpdated) untuk semua pet.
     Pet yang cooldown-nya <= 10 detik dianggap READY dan langsung di-PNP. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local PU          = ctx.deps.PU
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local ownCd = {}   -- uuid -> sisa cooldown skill utama
	local cdMap = {}   -- uuid -> tabel cooldown mentah dari server (untuk UI Monitor)
	ctx.state.cdMap = cdMap

	----------------------------------------------------------------- helpers
	local function isPetEquipped(uuid)
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return false end
		local eq = d.PetsData and d.PetsData.EquippedPets
		if not eq then return false end
		for _, u in ipairs(eq) do
			if u == uuid then return true end
		end
		return false
	end

	-- Monitor Cooldown dari Server
	local PetCD = RS:WaitForChild("GameEvents"):FindFirstChild("PetCooldownsUpdated")
	if PetCD then
		PetCD.OnClientEvent:Connect(function(uuid, cd)
			if type(uuid) ~= "string" then return end
			
			local oldEntry = cdMap[uuid]
			local data = {}
			local mainCD = nil
			if type(cd) == "table" then
				for _, e in ipairs(cd) do
					local duration = tonumber(e.Time) or 0
					
					-- Cari passive yang sama di data lama
					local oldPassive = nil
					if oldEntry and type(oldEntry.data) == "table" then
						for _, oldE in ipairs(oldEntry.data) do
							if oldE.Passive == e.Passive then
								oldPassive = oldE
								break
							end
						end
					end
					
					local expireTime
					if oldPassive and oldPassive.expireTime then
						local localVal = math.max(0, oldPassive.expireTime - tick())
						-- Jika perbedaan kecil (<= 2.0 detik), pertahankan expireTime lama agar berdetik mulus
						if math.abs(localVal - duration) <= 2.0 then
							expireTime = oldPassive.expireTime
						else
							expireTime = tick() + duration
						end
					else
						expireTime = tick() + duration
					end
					
					table.insert(data, {
						Passive = e.Passive,
						Time = duration,
						expireTime = expireTime
					})
					
					if not tostring(e.Passive or ""):find("Mutation") then
						mainCD = expireTime - tick()
					end
				end
			end
			cdMap[uuid] = { data = data }

			-- Simpan waktu kedaluwarsa (timestamp)
			if isPetEquipped(uuid) then
				if mainCD then
					ownCd[uuid] = tick() + mainCD
				else
					ownCd[uuid] = 0
				end
			else
				ownCd[uuid] = nil
			end
		end)
	end

	local READY_TH = 0 -- detik; cooldown <= ini dianggap ready/siap tembak

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

	-- daftar pet dari INVENTORY (semua pet, bukan cuma yang di-garden) buat dropdown Select Pets.
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
		table.sort(out, function(a, b)
			local selA = CFG.pnpUuids and CFG.pnpUuids[a.value] and 1 or 0
			local selB = CFG.pnpUuids and CFG.pnpUuids[b.value] and 1 or 0
			if selA ~= selB then
				return selA > selB
			end
			return a.display < b.display
		end)
		return out
	end

	-- Posisi placement
	local GetFarm = require(RS.Modules.GetFarm)
	local function farmCenter()
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3   -- 6 kolom, jarak 3 stud (rapat)
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

	local function getPetMaxCd(petType)
		local name = tostring(petType)
		
		-- 1) Cari dari database internal game secara dinamis
		local PetList, PassiveRegistry
		pcall(function() PetList = require(RS.Data.PetRegistry.PetList) end)
		pcall(function() PassiveRegistry = require(RS.Data.PetRegistry.PassiveRegistry) end)
		
		local p = PetList and PetList[name]
		local pas = p and p.Passives
		local passiveName = type(pas) == "table" and pas[1] or nil
		local reg = passiveName and PassiveRegistry and PassiveRegistry[passiveName]
		local cd = reg and reg.States and reg.States.Cooldown
		if type(cd) == "table" then
			local m = tonumber(cd.Min) or tonumber(cd.Base)
			if m then return m end
		end
		
		-- 2) Fallback jika database game gagal dibaca
		if name:find("Ferret") then return 1200 end
		if name:find("Peacock") then return 15 end
		if name:find("Dilophosaurus") then return 60 end
		return 60
	end

	local processing = {} -- Lacak pet yang sedang diproses PNP agar tidak dobel thread

	----------------------------------------------------------------- loop utama
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

					-- Pet dianggap ready jika sisa cooldown-nya nil atau di bawah READY_TH (10s)
					local expireTime = ownCd[p.uuid]
					local cdVal = expireTime and (expireTime - tick())
					local isReady = (cdVal == nil) or (cdVal <= READY_TH)

					if isReady and not processing[p.uuid] then
						didAny = true
						processing[p.uuid] = true

						task.spawn(function()
							-- Jeda penjemputan dinamis sebelum dilepas
							if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end
							if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then
								processing[p.uuid] = nil
								return
							end

							-- PICKUP -> PLACE
							local pos = getPos(p.uuid)
							pcall(function() PetsService:FireServer("UnequipPet", p.uuid) end)
							
							task.wait(math.max(0.01, CFG.equipDelay))
							if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then
								processing[p.uuid] = nil
								return
							end
							
							if pos then
								pcall(function() PetsService:FireServer("EquipPet", p.uuid, CFrame.new(pos)) end)
								-- Set cooldown lokal secara instan untuk mencegah loop sebelum server mereplikasi
								ownCd[p.uuid] = tick() + getPetMaxCd(p.petType)
							end
							
							processing[p.uuid] = nil
						end)
					end
				end
				
				if not CFG.pnpMonitorEnabled then
					setStatus(("PNP jalan: %d pet%s"):format(#pets, didAny and "" or " (nunggu skill keluar)"))
				end
				task.wait(0.15)
			end
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
end
