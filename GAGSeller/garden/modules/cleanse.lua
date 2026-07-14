--[[ cleanse.lua — Automation Cleanse Mutation.
     Pet target yang mutasinya BUKAN di "Mutations to Keep" -> di-cleanse pakai
     Cleansing Pet Shard (mutasi dihapus jadi Normal, siap dimutasi ulang).
     Mekanik: pet harus equipped (model di Workspace.PetsPhysical.PetMover.{uuid}),
     pegang Cleansing Pet Shard, lalu PetShardService_RE:FireServer("ApplyShard", petModel). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetShardService = RS:WaitForChild("GameEvents"):WaitForChild("PetShardService_RE")
	local function setStatus(s) ctx.setStatus(s) end

	local function mutName(code)
		if ctx.reg and ctx.reg.mutDisplay then return ctx.reg.mutDisplay(code) end
		return tostring(code)
	end

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local function getPos()
		local c = farmCenter()
		return c and (c + Vector3.new(0, 0, -3)) or nil
	end

	-- Cari tool Cleansing Pet Shard (Character dulu lalu Backpack).
	local function findShard()
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then
				for _, t in ipairs(src:GetChildren()) do
					if t:IsA("Tool") and (t:HasTag("PetShardTool") or tostring(t.Name):find("Cleansing Pet Shard")) then
						return t
					end
				end
			end
		end
		return nil
	end

	-- Cari Model pet equipped di workspace berdasarkan uuid (nama model = "{uuid}").
	local function findPetModel(uuid)
		local pp = workspace:FindFirstChild("PetsPhysical")
		if not pp then return nil end
		for _, d in ipairs(pp:GetDescendants()) do
			if d.Name == uuid then return d end
		end
		return nil
	end

	-- Apakah pet perlu di-cleanse: tipe target, punya mutasi, mutasi TIDAK di keep, bukan favorite.
	local function needsCleanse(v)
		local pt = v.PetType
		if not (pt and CFG.cleansePetTypes[pt]) then return false end
		local pd = v.PetData or {}
		if pd.IsFavorite then return false end
		local mut = pd.MutationType
		if not mut or mut == "" or mut == "Normal" or mut == "m" then return false end
		local disp = mutName(mut)
		if disp == "None" then return false end
		if CFG.cleanseKeepMutations[disp] then return false end -- mutasi ini di-keep
		return true
	end

	local function cleanseOne(uuid)
		-- pastikan pet equipped (model ada)
		local model = findPetModel(uuid)
		local equippedByUs = false
		if not model then
			local pos = getPos()
			if pos then
				pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
				equippedByUs = true
			end
			for _ = 1, 20 do
				task.wait(0.15)
				model = findPetModel(uuid)
				if model then break end
			end
		end
		if not model then return false, "model pet tidak muncul" end

		-- pegang shard (retry sampai benar dipegang)
		local shard = findShard()
		if not shard then return false, "shard habis" end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			local held
			for _ = 1, 3 do
				pcall(function() hum:EquipTool(shard) end)
				task.wait(0.3)
				held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
				if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then break end
				shard = findShard()
				if not shard then break end
			end
			if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then
				pcall(function() PetShardService:FireServer("ApplyShard", model) end)
				task.wait(0.6)
			end
		end

		if equippedByUs then
			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			task.wait(0.2)
		end
		return true
	end

	local function cleanseLoop()
		ctx.state.cleanseId = (ctx.state.cleanseId or 0) + 1
		local myId = ctx.state.cleanseId
		ctx.elevate()

		while CFG.cleanseEnabled and ctx.alive() and ctx.state.cleanseId == myId do
			if not next(CFG.cleansePetTypes or {}) then
				setStatus("Cleanse: pilih tipe pet dulu")
				task.wait(3)
			else
				local ok, d = pcall(function() return DataService:GetData() end)
				local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
				local targetUuid, targetV
				for uuid, v in pairs(inv) do
					if needsCleanse(v) then targetUuid, targetV = uuid, v; break end
				end
				if targetUuid then
					setStatus(("Cleanse: %s (%s)"):format(targetV.PetType, mutName(targetV.PetData.MutationType)))
					local okc, why = cleanseOne(targetUuid)
					if not okc then
						setStatus("Cleanse: " .. tostring(why))
						if why == "shard habis" then task.wait(3) end
					end
					task.wait(0.5)
				else
					setStatus("Cleanse: tidak ada pet perlu cleanse")
					task.wait(3)
				end
			end
		end
	end

	function ctx.startCleanse() task.spawn(cleanseLoop) end
end
