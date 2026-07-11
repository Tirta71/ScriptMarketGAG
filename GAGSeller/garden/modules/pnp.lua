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
			cdMap[uuid] = { data = cd, receivedAt = tick() }

			local mainCD
			if type(cd) == "table" then
				for _, e in ipairs(cd) do
					if not tostring(e.Passive or ""):find("Mutation") then
						mainCD = tonumber(e.Time)
					end
				end
			end

			-- Sinyal kosong = cooldown 0 (ready).
			if isPetEquipped(uuid) then
				ownCd[uuid] = mainCD or 0
			else
				ownCd[uuid] = nil
			end
		end)
	end

	local READY_TH = 10 -- detik; cooldown <= ini dianggap ready/siap tembak

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

					-- Pet dianggap ready jika sisa cooldown-nya di bawah READY_TH (10s)
					local cdVal = ownCd[p.uuid]
					local isReady = cdVal ~= nil and cdVal <= READY_TH

					if isReady then
						didAny = true

						-- Jeda penjemputan dinamis sebelum dilepas
						if CFG.pickupDelay > 0 then task.wait(CFG.pickupDelay) end
						if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end

						-- PICKUP -> PLACE
						local pos = getPos(p.uuid)
						pcall(function() PetsService:FireServer("UnequipPet", p.uuid) end)
						
						task.wait(math.max(0.01, CFG.equipDelay))
						if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end
						
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", p.uuid, CFrame.new(pos)) end)
						end
						
						-- Jeda 0.5 detik setelah ditaruh agar server sempat sinkronisasi cooldown barunya
						task.wait(0.5)
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
