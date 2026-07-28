--[[ automation_reclaimer.lua — Auto Reclaimer plant (Farm).
     Reclaim plant yg ditanam di garden pakai tool Reclaimer.
     Remote: ReclaimerService_RE:FireServer("TryReclaim", plantModel)
       plantModel = Model di Farm.Important.Plants_Physical (mis. "Blueberry").
     Dropdown "Select Plants": jenis plant unik yg ada di garden (+ "All").
     Butuh tool Reclaimer (auto-equip di loop). Tiap reclaim makan 1 charge Reclaimer.
     Fungsi: ctx.getReclaimPlantOptions / ctx.startReclaim. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local ReclaimRE = GE:WaitForChild("ReclaimerService_RE")
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end

	local function plantsFolder()
		local f = myFarm()
		local imp = f and f:FindFirstChild("Important")
		return imp and imp:FindFirstChild("Plants_Physical")
	end

	-- Opsi dropdown: jenis plant unik yg lagi ada di garden + "All".
	local function plantOptions()
		local out = { { value = "All", display = "All (semua plant)" } }
		local pf = plantsFolder()
		if pf then
			local seen, names = {}, {}
			for _, m in ipairs(pf:GetChildren()) do
				local n = m.Name
				if n and not seen[n] then seen[n] = true; names[#names + 1] = n end
			end
			table.sort(names)
			for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		end
		return out
	end
	function ctx.getReclaimPlantOptions() return plantOptions() end

	-- Nama tool di inventory ada suffix jumlah (mis. "Reclaimer x50634"),
	-- jadi cocokin per-prefix, bukan exact.
	local function isReclaimer(t)
		return t:IsA("Tool") and t.Name:match("^Reclaimer") ~= nil
	end
	local function heldReclaimer()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do if isReclaimer(t) then return t end end
		return nil
	end

	-- Equip tool Reclaimer dari Backpack kalau belum kepegang.
	local function equipReclaimer()
		local char = LP.Character
		if not char then return false end
		if heldReclaimer() then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if isReclaimer(t) then tool = t; break end end end
		if tool then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return heldReclaimer() ~= nil
	end

	----------------------------------------------------------------- loop reclaim
	local POLL = 1
	local function reclaimLoop()
		ctx.state.reclaimId = (ctx.state.reclaimId or 0) + 1
		local myId = ctx.state.reclaimId
		ctx.elevate()
		while CFG.reclaimEnabled and ctx.alive() and ctx.state.reclaimId == myId do
			local pf = plantsFolder()
			local sel = CFG.reclaimPlantNames or {}
			local all = sel["All"]
			if pf and (all or next(sel)) then
				local hasTool = equipReclaimer()
				if not hasTool then
					setStatus("Reclaimer: tool 'Reclaimer' ga ada di inventory")
				else
					local n = 0
					for _, m in ipairs(pf:GetChildren()) do
						if not CFG.reclaimEnabled or ctx.state.reclaimId ~= myId then break end
						if all or sel[m.Name] then
							pcall(function() ReclaimRE:FireServer("TryReclaim", m) end)
							n = n + 1
							task.wait(CFG.reclaimSpeed or 0.15)
						end
					end
					setStatus(("Reclaimer: proses %d plant"):format(n))
				end
			else
				setStatus("Reclaimer: pilih plant dulu")
			end
			task.wait(POLL)
		end
	end
	function ctx.startReclaim()
		task.spawn(reclaimLoop)
	end
end
