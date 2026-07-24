--[[ chesthunt.lua — Auto Global Chest Hunt (event Summer Chest Hunt).
     Konsep: TP ke chest -> auto-angkat (carry) -> bawa ke garden -> ulang sampai habis.
     Mekanik game (RE): touch/TP ke chest -> attribute char SummerChestHunt_CARRYING=true;
       bawa ke garden/platform buat deposit. CARRY_CAPACITY=1 (satu-satu).
     Catatan: tag chest belum kepastian (event belum spawn) -> finder robust + ctx.scanChests()
       buat verifikasi pas event live. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local CS = game:GetService("CollectionService")
	local LP = ctx.LP
	local CFG = ctx.CFG

	local function hrp() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local function rootPart(m)
		if not m then return nil end
		if m:IsA("BasePart") then return m end
		if m.PrimaryPart then return m.PrimaryPart end
		return m:FindFirstChildWhichIsA("BasePart")
	end
	local function carrying()
		local c = LP.Character
		return c and c:GetAttribute("SummerChestHunt_CARRYING") == true
	end

	-- kandidat tag chest (tebakan; finder fallback ke scan nama)
	local CHEST_TAGS = { "SummerChest", "SummerChestHuntChest", "GlobalChest", "SummerChestHunt_Chest", "ChestHuntChest", "SummerChestHuntGlobalChest" }

	-- exclude: dekorasi/NPC statis (semua di bawah Workspace.Interaction), karakter, cooler.
	-- Chest hunt asli spawn DINAMIS di luar Interaction (tersebar di map).
	local function excluded(m)
		if m:FindFirstChildOfClass("Humanoid") then return true end
		local low = tostring(m.Name):lower()
		if low:find("cooler") or low:find("egg") then return true end -- cooler & pet egg
		if m:FindFirstAncestor("Interaction") or m:FindFirstAncestor("PetEgg") then return true end
		if game.Players:GetPlayerFromCharacter(m) then return true end
		return false
	end

	-- Chest hunt asli: STRUKTUR chest (AnimationController + part Inside/Top1) = paling andal.
	-- Nama "...chest" jadi sinyal tambahan. (RARITY dipakai cuma kalau juga ada struktur.)
	local function isHuntChest(m)
		if not m:IsA("Model") or excluded(m) then return false end
		if not rootPart(m) then return false end
		local structHit = m:FindFirstChildOfClass("AnimationController") and (m:FindFirstChild("Inside") or m:FindFirstChild("Top1")) ~= nil
		local nameHit = tostring(m.Name):lower():find("chest") ~= nil
		return structHit or nameHit
	end

	local function findChests()
		local seen, out = {}, {}
		for _, tag in ipairs(CHEST_TAGS) do
			for _, inst in ipairs(CS:GetTagged(tag)) do
				if not seen[inst] then seen[inst] = true; out[#out + 1] = inst end
			end
		end
		for _, d in ipairs(workspace:GetDescendants()) do
			if isHuntChest(d) and not seen[d] then seen[d] = true; out[#out + 1] = d end
		end
		return out
	end

	-- Debug: apa yg kedetect sbg chest + semua tag baru di workspace (buat verifikasi pas event)
	function ctx.scanChests()
		local chests = findChests()
		local info = {}
		for i, c in ipairs(chests) do
			if i <= 10 then
				local r = rootPart(c)
				local pp = c:FindFirstChildWhichIsA("ProximityPrompt", true)
				info[#info + 1] = ("%s '%s' @ %s | prompt:%s"):format(c.ClassName, c.Name, r and tostring(r.Position):sub(1, 22) or "?", pp and (pp.ActionText .. "/" .. tostring(pp.HoldDuration) .. "s") or "NONE")
			end
		end
		-- semua model bernama "chest" (mentah, buat lihat kandidat + tag-nya)
		local rawChest = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			if (d:IsA("Model") or d:IsA("BasePart")) and tostring(d.Name):lower():find("chest") then
				local tg = table.concat(CS:GetTags(d), ",")
				rawChest[#rawChest + 1] = ("%s '%s' <%s> tags[%s]"):format(d.ClassName, d.Name, (d.Parent and d.Parent.Name) or "?", tg)
				if #rawChest >= 10 then break end
			end
		end
		-- model dgn STRUKTUR chest (AnimationController + Inside/Top1), by name apapun
		local structItems = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("Model") and not d:FindFirstChildOfClass("Humanoid")
				and d:FindFirstChildOfClass("AnimationController")
				and (d:FindFirstChild("Inside") or d:FindFirstChild("Top1")) then
				local r = rootPart(d)
				structItems[#structItems + 1] = ("'%s' <%s> @ %s"):format(d.Name, (d.Parent and d.Parent.Name) or "?", r and tostring(r.Position):sub(1, 24) or "?")
				if #structItems >= 10 then break end
			end
		end
		local tags = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			for _, t in ipairs(CS:GetTags(d)) do
				if (t:lower():find("chest") or t:lower():find("hunt")) then tags[t] = (tags[t] or 0) + 1 end
			end
		end
		return { chestCount = #chests, sample = info, rawChestNamed = rawChest, structChests = structItems, chestHuntTags = tags, carrying = carrying() }
	end

	local function depositPos()
		if CFG.chestHuntDeposit ~= "platform" then
			local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
			if ok and GetFarm then
				local farm = GetFarm(LP)
				local pa = farm and farm:FindFirstChild("PetArea")
				if pa then return pa.Position end
				local char = LP.Character; local h = char and char:FindFirstChild("HumanoidRootPart")
				if h then return h.Position end
			end
		end
		local plat = CS:GetTagged("SummerChestHuntPlatform")[1]
		if plat then return (plat:IsA("Model") and plat:GetPivot().Position) or (plat:IsA("BasePart") and plat.Position) end
		return nil
	end

	local function tpTo(pos, yOff)
		local h = hrp()
		if h and pos then h.CFrame = CFrame.new(pos + Vector3.new(0, yOff or 3, 0)) end
	end

	----------------------------------------------------------------- loop
	local function tick()
		if carrying() then
			ctx.state.chestStatus = "Carry -> deposit ke " .. (CFG.chestHuntDeposit or "garden")
			local dp = depositPos()
			for _ = 1, 24 do
				if not carrying() or not CFG.chestHuntEnabled then break end
				tpTo(dp, 3); task.wait(0.25)
			end
		else
			local chests = findChests()
			ctx.state.chestStatus = ("Chest tersisa: %d"):format(#chests)
			if #chests == 0 then task.wait(0.5); return end
			-- pilih chest terdekat
			local h = hrp(); local hp = h and h.Position
			local target, best = nil, math.huge
			for _, c in ipairs(chests) do
				local r = rootPart(c)
				if r then
					local dd = hp and (r.Position - hp).Magnitude or 0
					if dd < best then best = dd; target = c end
				end
			end
			if not target then return end
			local r = rootPart(target)
			-- carry = hold E (ProximityPrompt). TP deket chest -> trigger prompt-nya.
			local fireProx = fireproximityprompt or (getgenv and getgenv().fireproximityprompt)
			for _ = 1, 10 do
				if carrying() or not CFG.chestHuntEnabled or not target.Parent then break end
				tpTo(r.Position, 2)
				task.wait(0.15)
				local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt and fireProx then
					pcall(function() fireProx(prompt, prompt.HoldDuration or 0) end)
					pcall(function() fireProx(prompt) end)
				end
				task.wait(0.5)
			end
		end
	end

	ctx.state.chestStatus = "Idle"
	local function loop()
		ctx.state.chestId = (ctx.state.chestId or 0) + 1
		local my = ctx.state.chestId
		ctx.elevate()
		while CFG.chestHuntEnabled and ctx.alive() and ctx.state.chestId == my do
			pcall(tick)
			task.wait(0.3)
		end
		ctx.state.chestStatus = "Idle"
	end
	function ctx.startChestHunt() task.spawn(loop) end
	function ctx.stopChestHunt()
		ctx.state.chestId = (ctx.state.chestId or 0) + 1
		ctx.state.chestStatus = "Idle"
	end

	function ctx.getChestSummary()
		return { status = CFG.chestHuntEnabled and "ACTIVE" or "STOPPED", info = ctx.state.chestStatus or "Idle", deposit = CFG.chestHuntDeposit or "garden" }
	end

	-- Auto-trigger pas event mulai (StartGlobalChestHunt) kalau toggle nyala.
	pcall(function()
		local re = RS.GameEvents:FindFirstChild("SummerChestHunt")
		re = re and re:FindFirstChild("StartGlobalChestHunt")
		if re then
			re.OnClientEvent:Connect(function()
				if CFG.chestHuntEnabled then
					ctx.log("Chest Hunt event mulai -> auto-run.")
					ctx.startChestHunt()
				end
			end)
		end
	end)
end
