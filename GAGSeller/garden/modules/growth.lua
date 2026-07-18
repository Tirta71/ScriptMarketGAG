--[[ growth.lua — Growth pipeline (BATCH per-step): jalankan target pet lewat urutan
     step (default Elephant -> Mutation -> Leveling), semua pet kelar 1 step baru lanjut.
     Config TERPISAH dari fitur standalone (growth*).
     Step & kriteria "complete":
       elephant : BaseWeight >= growthElephantWeight
       mutation : dapat salah satu growthMutationTargets (aura team; mutasi salah -> shard)
       leveling : Level >= growthLevP2Target (2 phase: P1 team -> P2 team)
     Saat ganti step/phase: bersihin garden TOTAL dulu -> pasang team baru (lengkap) -> proses. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")
	local PetShardService = RS:WaitForChild("GameEvents"):WaitForChild("PetShardService_RE")
	local mutDisplay = (ctx.reg and ctx.reg.mutDisplay) or function(c) return c end

	----------------------------------------------------------------- posisi grid
	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter(); if not center then return nil end
		local i = slotOf[uuid]
		return center + Vector3.new((i % 6 - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	----------------------------------------------------------------- helper mutasi/shard
	local function mutOf(pd) return mutDisplay((pd or {}).MutationType) end
	local function hasMut(pd)
		local m = (pd or {}).MutationType
		return m ~= nil and m ~= "" and m ~= "None" and m ~= "Normal"
	end
	local function findShard()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					if t:IsA("Tool") and (t:HasTag("PetShardTool") or tostring(t.Name):find("Cleansing Pet Shard")) then return t end
				end
			end
		end
	end
	local function findPetModel(uuid)
		local pm = workspace:FindFirstChild("PetsPhysical")
		if not pm then return nil end
		for _, mover in ipairs(pm:GetChildren()) do
			local m = mover:FindFirstChild(uuid); if m then return m end
		end
	end
	local function cleansePet(uuid)
		local model = findPetModel(uuid); if not model then return end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		local shard = findShard()
		if hum and shard then pcall(function() hum:EquipTool(shard) end); task.wait(0.3) end
		local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
		if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then
			pcall(function() PetShardService:FireServer("ApplyShard", model) end)
			task.wait(0.3)
		end
	end

	----------------------------------------------------------------- kriteria complete per step
	local function stepDone(step, pd)
		pd = pd or {}
		if step == "elephant" then
			return (pd.BaseWeight or 0) >= (CFG.growthElephantWeight or 5.5)
		elseif step == "mutation" then
			local tg = CFG.growthMutationTargets or {}
			if not next(tg) then return true end
			return tg[mutOf(pd)] == true
		elseif step == "leveling" then
			return (pd.Level or 0) >= (CFG.growthLevP2Target or 500)
		end
		return true
	end

	ctx.state.growthStatus = "Idle"

	----------------------------------------------------------------- ringkasan status
	function ctx.getGrowthSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local types = CFG.growthPetTypes or {}
		local flow = CFG.growthFlow or {}
		local perStep = {}
		for _, s in ipairs(flow) do perStep[s] = { done = 0, total = 0 } end
		for _, v in pairs(inv) do
			if types[v.PetType] then
				for _, s in ipairs(flow) do
					perStep[s].total = perStep[s].total + 1
					if stepDone(s, v.PetData) then perStep[s].done = perStep[s].done + 1 end
				end
			end
		end
		local function nm(t) local o = {}; for k in pairs(t or {}) do o[#o + 1] = k end; return #o > 0 and table.concat(o, ", ") or "-" end
		return {
			status = CFG.growthEnabled and "ACTIVE" or "STOPPED",
			step = ctx.state.growthStep or "-",
			flow = (#flow > 0) and table.concat(flow, " -> ") or "-",
			types = nm(types),
			perStep = perStep,
		}
	end

	----------------------------------------------------------------- core check
	local function checkGrowth()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return end
		local eq  = d.PetsData.EquippedPets or {}
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local types = CFG.growthPetTypes or {}
		local flow = CFG.growthFlow or {}
		if not next(types) or #flow == 0 then
			ctx.state.growthStatus = "Growth: set target pet & flow dulu"
			return
		end

		-- STEP AKTIF = step pertama di flow yg belum semua target pet complete.
		local step, stepIdx
		for i, s in ipairs(flow) do
			local allDone = true
			for _, v in pairs(inv) do
				if types[v.PetType] and not stepDone(s, v.PetData) then allDone = false; break end
			end
			if not allDone then step, stepIdx = s, i; break end
		end
		if not step then
			ctx.state.growthStep = "SELESAI"
			ctx.state.growthStatus = "Growth: semua step selesai ✓"
			if ctx.state.growthClearKey ~= "__done" then ctx.state.growthClearKey = "__done"; if ctx.clearGarden then ctx.clearGarden("Growth") end end
			return
		end

		-- team / max / kriteria "masih perlu diproses" untuk step ini (leveling: sub-phase)
		local team, maxPets, needsWork
		local stepLabel = ("Step %d: %s"):format(stepIdx, step)
		if step == "elephant" then
			team, maxPets = CFG.growthElephantTeam or {}, CFG.growthElephantMax or 2
			needsWork = function(pd) return not stepDone("elephant", pd) end
		elseif step == "mutation" then
			team, maxPets = CFG.growthMutationTeam or {}, CFG.growthMutationMax or 2
			needsWork = function(pd) return not stepDone("mutation", pd) end
		else -- leveling
			local p1t = CFG.growthLevP1Target or 40
			local phase1 = false
			for _, v in pairs(inv) do
				if types[v.PetType] and not stepDone("leveling", v.PetData) and ((v.PetData or {}).Level or 0) < p1t then phase1 = true; break end
			end
			if phase1 then
				team, maxPets = CFG.growthLevP1Team or {}, CFG.growthLevP1Max or 3
				stepLabel = stepLabel .. " (Phase 1)"
				needsWork = function(pd) return (pd.Level or 0) < p1t end
			else
				team, maxPets = CFG.growthLevP2Team or {}, CFG.growthLevP2Max or 1
				stepLabel = stepLabel .. " (Phase 2)"
				needsWork = function(pd) return not stepDone("leveling", pd) end
			end
		end
		ctx.state.growthStep = stepLabel

		local localEq = {}
		for _, uuid in ipairs(eq) do localEq[uuid] = true end

		-- Transisi step/phase -> bersihin garden TOTAL dulu (verified kosong).
		if ctx.state.growthClearKey ~= nil and ctx.state.growthClearKey ~= stepLabel then
			ctx.state.growthClearing = true
		end
		ctx.state.growthClearKey = stepLabel
		if ctx.state.growthFirstRun or ctx.state.growthClearing then
			if #eq > 0 then
				ctx.state.growthStatus = ("%s: bersihin garden (%d pet)..."):format(stepLabel, #eq)
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.1)
				end
				return
			end
			ctx.state.growthFirstRun = false
			ctx.state.growthClearing = false
		end

		-- Pasang team step ini + PASTIKAN LENGKAP dulu.
		local teamComplete = true
		for uuid in pairs(team) do
			if not localEq[uuid] then
				teamComplete = false
				local pos = getPos(uuid)
				if pos then pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end); task.wait(0.15) end
			end
		end
		if not teamComplete then
			ctx.state.growthStatus = stepLabel .. ": nunggu team lengkap..."
			return
		end

		-- Klasifikasi target pet equipped: kalau ga perlu kerja lagi -> lepas.
		-- Khusus mutation: mutasi SALAH (bukan target) -> cleanse (shard) biar coba lagi.
		local active = {}
		for uuid in pairs(localEq) do
			if not team[uuid] then
				local v = inv[uuid]
				if v and types[v.PetType] then
					local pd = v.PetData or {}
					if needsWork(pd) then
						if step == "mutation" and hasMut(pd) and not (CFG.growthMutationTargets or {})[mutOf(pd)] then
							cleansePet(uuid) -- mutasi salah -> cleanse
						end
						table.insert(active, uuid)
					else
						-- pet SELESAI step ini -> kirim webhook (template per-step)
						local pt = v.PetType
						if step == "elephant" and ctx.webhookElephant and ctx.webhookElephant.onFinished then
							pcall(function() ctx.webhookElephant.onFinished(ctx, pt, pd.BaseWeight or 0) end)
						elseif step == "mutation" and ctx.webhookMutation and ctx.webhookMutation.sendClaimed then
							pcall(function() ctx.webhookMutation.sendClaimed(ctx, pt, mutOf(pd), true) end)
						elseif step == "leveling" and stepDone("leveling", pd)
							and ctx.webhookLeveling and ctx.webhookLeveling.sendFinished then
							-- CUMA Phase 2 (reached final). Phase 1 (P1Target) ga kirim.
							local remains = 0
							for _, iv in pairs(inv) do
								if types[iv.PetType] and not stepDone("leveling", iv.PetData) then remains = remains + 1 end
							end
							pcall(function() ctx.webhookLeveling.sendFinished(ctx, pt, mutOf(pd), pd.Level or 0, 0, remains) end)
						end
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.1)
					end
				end
			end
		end

		-- Tambah target pet baru yg butuh kerja di step/phase ini, sampai maxPets.
		local needed = maxPets - #active
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				if not localEq[uuid] and types[v.PetType] and needsWork(v.PetData or {}) then
					table.insert(pool, { uuid = uuid, key = (v.PetData or {}).Level or (v.PetData or {}).BaseWeight or 0 })
				end
			end
			table.sort(pool, function(a, b) return a.key < b.key end)
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i].uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i].uuid, CFrame.new(pos)) end)
					localEq[pool[i].uuid] = true
					table.insert(active, pool[i].uuid)
					task.wait(0.15)
				end
			end
		end

		ctx.state.growthStatus = ("%s: %d/%d aktif"):format(stepLabel, #active, maxPets)
	end

	----------------------------------------------------------------- loop
	local function growthLoop()
		ctx.state.growthId = (ctx.state.growthId or 0) + 1
		local myId = ctx.state.growthId
		ctx.elevate()
		ctx.state.growthFirstRun = true
		ctx.state.growthClearKey = nil
		while CFG.growthEnabled and ctx.alive() and ctx.state.growthId == myId do
			pcall(checkGrowth)
			-- pas bersihin/transisi -> cek cepat (1s) biar garden cepat bersih & lanjut;
			-- steady (proses grow/level) -> 2s (hemat, toh pet numbuh di server).
			task.wait((ctx.state.growthClearing or ctx.state.growthFirstRun) and 0.5 or 2)
		end
		ctx.state.growthStatus = "Idle"
	end

	function ctx.startGrowth()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		task.spawn(growthLoop)
	end
	function ctx.stopGrowth()
		ctx.state.growthId = (ctx.state.growthId or 0) + 1
		if ctx.clearGarden then ctx.clearGarden("Growth") end
	end
end
