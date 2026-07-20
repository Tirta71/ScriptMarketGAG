--[[ elephant_v2.lua — Automation Elephant V2 (swap gajah on-demand).
     Passive gajah kasih +0.1 KG tiap pet target hit level 40. Gajah normalnya
     DI LUAR garden biar slot dipakai maksimalin leveling target ke 40 (garden
     mentok 8 slot). Begitu ada target >= level 40, gajah di-swap MASUK (nuker 1
     pet Switch dari team) TANPA delay; keluar lagi pas ga ada target di 40.

     Leveling target dilakukan PNP (jalan barengan). Modul ini CUMA pegang
     Gajah + Switch — TIDAK menyentuh pet target — jadi ga tabrakan sama PNP. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")

	-- posisi equip = tengah PetArea (game auto-snap ke slot kosong)
	local function equipPos()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		local farm = ok and GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
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

	-- Ada pet target (tipe dipilih) yang level >= ambang? (scan inventory penuh, biar
	-- kedeteksi walau PNP lagi angkat-turunin target di detik itu)
	local function anyTargetReady(inv)
		local types = CFG.elephantV2Types or {}
		local thr = CFG.elephantV2Level or 40
		for _, v in pairs(inv) do
			if v.PetType and types[v.PetType] and ((v.PetData or {}).Level or 0) >= thr then return true end
		end
		return false
	end

	-- Swap: cabut outUuid, masukin inUuid — back-to-back (nol wait di jalur fire).
	-- Verifikasi read-back + retry ringan biar aman dari slot-drop pas garden 8/8.
	local function swap(outUuid, inUuid)
		if not inUuid or inUuid == "" then return false end
		local pos = equipPos()
		for _ = 1, 3 do
			if outUuid and outUuid ~= "" then pcall(function() PetsService:FireServer("UnequipPet", outUuid) end) end
			if pos then pcall(function() PetsService:FireServer("EquipPet", inUuid, CFrame.new(pos)) end) end
			task.wait(0.12)
			local eq = snapshot()
			if isEquipped(eq, inUuid) then return true end
		end
		return false
	end

	local function loop()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		local myId = ctx.state.elephantV2Id
		ctx.elevate()
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
						swap(switch, gajah) -- gajah MASUK, switch keluar
						ctx.state.elephantV2Status = "Gajah MASUK (ada target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
					elseif not ready and gajahIn then
						swap(gajah, switch) -- gajah KELUAR, switch balik
						ctx.state.elephantV2Status = "Standby (gajah keluar)"
					else
						ctx.state.elephantV2Status = gajahIn and "Gajah aktif" or "Standby"
					end
				end
				task.wait(CFG.elephantV2Interval or 0.1)
			end
		end
	end

	function ctx.startElephantV2() task.spawn(loop) end
	function ctx.stopElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		-- restore resting: gajah keluar, switch balik
		local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
		if gajah ~= "" and switch ~= "" then
			local eq = snapshot()
			if isEquipped(eq, gajah) then task.spawn(function() swap(gajah, switch) end) end
		end
		ctx.state.elephantV2Status = "Idle"
	end

	------------------------------------------------------------- UI helpers
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

	-- opsi Gajah = semua pet inventory (single-select)
	function ctx.elephantV2GajahOptions()
		local out = {}
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			out[#out + 1] = { name = o.value, display = o.display }
		end
		return out
	end
	-- opsi Switch = HANYA anggota Elephant V2 Team (single-select)
	function ctx.elephantV2SwitchOptions()
		local team = CFG.elephantV2Team or {}
		local out = {}
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			if team[o.value] then out[#out + 1] = { name = o.value, display = o.display } end
		end
		return out
	end

	function ctx.getElephantV2Summary()
		return {
			status = CFG.elephantV2Enabled and "ACTIVE" or "STOPPED",
			info   = ctx.state.elephantV2Status or "Idle",
			gajah  = petLabel(CFG.elephantV2Gajah),
			switch = petLabel(CFG.elephantV2Switch),
			level  = tostring(CFG.elephantV2Level or 40),
		}
	end
end
