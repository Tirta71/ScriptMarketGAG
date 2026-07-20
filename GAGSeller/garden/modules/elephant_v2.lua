--[[ elephant_v2.lua — Automation Elephant V2.
     Sama seperti V1 (equip team + rotasi pet target by BaseWeight, lepas pas
     capai Target Weight, jaga Max Target Pets aktif), TAPI plus swap GAJAH:
     gajah normalnya di luar garden; begitu ada target >= Trigger Level (mis. 40)
     gajah di-swap MASUK nuker 1 pet Switch (tanpa delay), keluar lagi pas ga ada
     target di level itu. Leveling target dilakukan PNP (jalan barengan).

     2 loop terpisah:
       - rotationLoop: pelan (~1.5s) — jaga team + rotasi target (ala V1).
       - swapLoop: cepat (0.1s) — cuma swap gajah <-> switch. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")

	local function farmCenter()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		local farm = ok and GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local c = farmCenter(); if not c then return nil end
		local i = slotOf[uuid]
		return c + Vector3.new(((i % 6) - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	local function snapshot()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return nil, nil end
		return d.PetsData.EquippedPets or {}, (d.PetsData.PetInventory and d.PetsData.PetInventory.Data) or {}
	end
	local function isEquipped(eq, uuid)
		if not uuid or uuid == "" or not eq then return false end
		for _, u in ipairs(eq) do if u == uuid then return true end end
		return false
	end

	----------------------------------------------------- STATUS
	function ctx.getElephantV2Summary()
		local _, inv = snapshot()
		inv = inv or {}
		local teamCount = 0
		for _ in pairs(CFG.elephantV2Team or {}) do teamCount = teamCount + 1 end
		local typesList = {}
		for k in pairs(CFG.elephantV2Types or {}) do table.insert(typesList, k) end
		table.sort(typesList)
		local targetW = CFG.elephantV2Weight or 5.5
		local readyCount, maxKgCount = 0, 0
		for _, v in pairs(inv) do
			if CFG.elephantV2Types[v.PetType] then
				local pd = v.PetData or {}
				if not pd.IsFavorite then
					if (pd.BaseWeight or 0) < targetW then readyCount = readyCount + 1 else maxKgCount = maxKgCount + 1 end
				end
			end
		end
		return {
			status = CFG.elephantV2Enabled and "ACTIVE" or "STOPPED",
			info   = ctx.state.elephantV2Status or "Idle",
			team   = string.format("%d pets", teamCount),
			types  = #typesList > 0 and table.concat(typesList, ", ") or "None",
			ready  = string.format("%d pets", readyCount),
			maxKg  = string.format("%d pets", maxKgCount),
			maxTarget = string.format("%d pets", CFG.elephantV2MaxPets or 3),
			targetWeight = string.format("%.1f KG", targetW),
			gajah  = ctx.elephantV2Label(CFG.elephantV2Gajah),
			switch = ctx.elephantV2Label(CFG.elephantV2Switch),
			level  = tostring(CFG.elephantV2Level or 40),
		}
	end

	----------------------------------------------------- ROTASI (ala V1)
	local function checkRotation()
		local eq, inv = snapshot()
		if not eq then return end
		local teamSet = CFG.elephantV2Team or {}
		local targetTypes = CFG.elephantV2Types or {}
		local targetW = CFG.elephantV2Weight or 5.5
		local maxPets = CFG.elephantV2MaxPets or 3
		local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
		local gajahIn = isEquipped(eq, gajah)

		local localEq, localEqCount = {}, 0
		for _, uuid in ipairs(eq) do localEq[uuid] = true; localEqCount = localEqCount + 1 end

		-- B. PERSISTENSI TEAM: pasang lagi team yg kecabut (skip gajah; skip switch pas gajah in)
		for uuid in pairs(teamSet) do
			if uuid ~= gajah and not (gajahIn and uuid == switch) then
				if not localEq[uuid] then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						localEq[uuid] = true; localEqCount = localEqCount + 1
						task.wait(0.25)
					end
				end
			end
		end

		-- C. KLASIFIKASI target equipped by BaseWeight (jangan sentuh team & gajah)
		local currentGrowing, finishedMax = {}, {}
		for uuid in pairs(localEq) do
			if not teamSet[uuid] and uuid ~= gajah then
				local pInfo = inv[uuid]
				local pd = pInfo and pInfo.PetData or {}
				local pt = pInfo and pInfo.PetType
				if pt and targetTypes[pt] then
					if (pd.BaseWeight or 0) < targetW then table.insert(currentGrowing, uuid)
					else table.insert(finishedMax, uuid) end
				end
			end
		end

		-- D. LEPAS target yang sudah MAX KG
		for _, uuid in ipairs(finishedMax) do
			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil; localEqCount = localEqCount - 1
			task.wait(0.2)
		end

		-- E. TAMBAH target baru (BaseWeight terendah dulu) sampai maxPets
		local needed = maxPets - #currentGrowing
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pd = v.PetData or {}
				if not localEq[uuid] and targetTypes[v.PetType] and (pd.BaseWeight or 0) < targetW and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, weight = pd.BaseWeight or 0 })
				end
			end
			table.sort(pool, function(a, b) return a.weight < b.weight end)
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i].uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i].uuid, CFrame.new(pos)) end)
					localEq[pool[i].uuid] = true; localEqCount = localEqCount + 1
					table.insert(currentGrowing, pool[i].uuid)
					task.wait(0.3)
				end
			end
		end
	end

	----------------------------------------------------- SWAP GAJAH (cepat)
	local function anyTargetReady(inv)
		local types = CFG.elephantV2Types or {}
		local thr = CFG.elephantV2Level or 40
		for _, v in pairs(inv) do
			if v.PetType and types[v.PetType] and ((v.PetData or {}).Level or 0) >= thr then return true end
		end
		return false
	end
	local function swap(outUuid, inUuid)
		if not inUuid or inUuid == "" then return false end
		local pos = getPos(inUuid)
		for _ = 1, 3 do
			if outUuid and outUuid ~= "" then pcall(function() PetsService:FireServer("UnequipPet", outUuid) end) end
			if pos then pcall(function() PetsService:FireServer("EquipPet", inUuid, CFrame.new(pos)) end) end
			task.wait(0.12)
			local eq = snapshot()
			if isEquipped(eq, inUuid) then return true end
		end
		return false
	end

	local function rotationLoop(myId)
		while CFG.elephantV2Enabled and ctx.alive() and ctx.state.elephantV2Id == myId do
			pcall(checkRotation)
			task.wait(1.5)
		end
	end
	local function swapLoop(myId)
		while CFG.elephantV2Enabled and ctx.alive() and ctx.state.elephantV2Id == myId do
			local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
			if gajah == "" or switch == "" then
				ctx.state.elephantV2Status = "Pilih Gajah & Switch dulu"
				task.wait(1)
			else
				local eq, inv = snapshot()
				if eq then
					local gajahIn = isEquipped(eq, gajah)
					local ready = anyTargetReady(inv)
					if ready and not gajahIn then
						swap(switch, gajah)
						ctx.state.elephantV2Status = "Gajah MASUK (target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
					elseif not ready and gajahIn then
						swap(gajah, switch)
						ctx.state.elephantV2Status = "Standby (gajah keluar)"
					else
						ctx.state.elephantV2Status = gajahIn and "Gajah aktif" or "Standby"
					end
				end
				task.wait(CFG.elephantV2Interval or 0.1)
			end
		end
	end

	function ctx.startElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		local myId = ctx.state.elephantV2Id
		ctx.elevate()
		task.spawn(function() rotationLoop(myId) end)
		task.spawn(function() swapLoop(myId) end)
	end
	function ctx.stopElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
		if gajah ~= "" and switch ~= "" then
			local eq = snapshot()
			if isEquipped(eq, gajah) then task.spawn(function() swap(gajah, switch) end) end
		end
		ctx.state.elephantV2Status = "Idle"
	end

	----------------------------------------------------- UI helpers
	local function petLabel(uuid)
		if not uuid or uuid == "" then return "Select" end
		local _, inv = snapshot()
		local v = inv and inv[uuid]
		if not v then return "#" .. tostring(uuid):sub(2, 5) end
		local pd = v.PetData or {}
		local mut = pd.MutationType
		local mutName = (mut and ctx.reg and ctx.reg.mutDisplay) and ctx.reg.mutDisplay(mut) or mut
		local pre = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
		return ("%s%s | Age %s | #%s"):format(pre, v.PetType or "?", tostring(pd.Level or 0), tostring(uuid):sub(2, 5))
	end
	ctx.elephantV2Label = petLabel

	function ctx.elephantV2GajahOptions()
		local out = {}
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			out[#out + 1] = { name = o.value, display = o.display }
		end
		return out
	end
	function ctx.elephantV2SwitchOptions()
		local team = CFG.elephantV2Team or {}
		local out = {}
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			if team[o.value] then out[#out + 1] = { name = o.value, display = o.display } end
		end
		return out
	end
end
