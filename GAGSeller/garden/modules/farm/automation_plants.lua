--[[ automation_plants.lua — Auto Plant seed (Farm).
     Tanam seed dari inventory ke farm.
     Remote: Plant_RE:FireServer(Vector3 pos, "SeedName")
     Seed & jumlah dari DataService InventoryData (ItemType="Seed", ItemData.ItemName/Quantity).
     Posisi: Random / Player Position / Good Position (grid rapi di Can_Plant, hindari numpuk).
     Fungsi: ctx.getPlantSeedOptions / ctx.startPlant. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local Plant_RE = GE:WaitForChild("Plant_RE")
	local DataService = ctx.deps.DataService
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end
	local function important() local f = myFarm(); return f and f:FindFirstChild("Important") end
	local function plantsFolder() local imp = important(); return imp and imp:FindFirstChild("Plants_Physical") end
	local function canPlantParts()
		local imp = important()
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end

	----------------------------------------------------------------- seed inventory
	-- name -> total quantity (dari semua entry Seed di InventoryData)
	local function seedInventory()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok and d and type(d.InventoryData) == "table" then
			for _, v in pairs(d.InventoryData) do
				if type(v) == "table" and v.ItemType == "Seed" and v.ItemData then
					local nm = v.ItemData.ItemName
					local q = tonumber(v.ItemData.Quantity) or 0
					if nm then out[nm] = (out[nm] or 0) + q end
				end
			end
		end
		return out
	end

	-- Opsi dropdown seed: "Nama (jumlah)". Sekalian buang seed yg udah 0 dari selection.
	local function seedOptions()
		local inv = seedInventory()
		-- prune selection yg udah abis
		local sel = CFG.plantSeedNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if (inv[nm] or 0) <= 0 then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n, q in pairs(inv) do if q > 0 then names[#names + 1] = n end end
		table.sort(names)
		local out = {}
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = ("%s (%d)"):format(n, inv[n]) } end
		return out
	end
	function ctx.getPlantSeedOptions() return seedOptions() end

	----------------------------------------------------------------- posisi
	local STEP = 2      -- jarak antar tanaman (game izinin ~2 stud)
	local MIND = 1.9    -- radius minimum ke plant lain biar ga ketolak/numpuk
	local function bkey(x, z) return math.floor(x / STEP) .. "," .. math.floor(z / STEP) end

	local function randomPos()
		local parts = canPlantParts()
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		local x = p.Position.X + (math.random() * 2 - 1) * hx
		local z = p.Position.Z + (math.random() * 2 - 1) * hz
		return Vector3.new(x, p.Position.Y, z)
	end

	local function playerPos()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local parts = canPlantParts()
		local y = parts[1] and parts[1].Position.Y or 0
		return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
	end

	-- Grid titik-titik rapi di seluruh Can_Plant (buat "Good Position").
	local function goodCells()
		local cells = {}
		for _, part in ipairs(canPlantParts()) do
			local hx, hz = part.Size.X / 2 - 1, part.Size.Z / 2 - 1
			local y = part.Position.Y
			local x = part.Position.X - hx
			while x <= part.Position.X + hx do
				local z = part.Position.Z - hz
				while z <= part.Position.Z + hz do
					cells[#cells + 1] = Vector3.new(x, y, z)
					z = z + STEP
				end
				x = x + STEP
			end
		end
		return cells
	end
	-- Spatial hash posisi plant yg ada -> cek cepat apakah suatu titik kosong.
	local function buildBuckets()
		local b = {}
		local pf = plantsFolder()
		if pf then
			for _, m in ipairs(pf:GetChildren()) do
				local p = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
				if p then
					local k = bkey(p.Position.X, p.Position.Z)
					b[k] = b[k] or {}
					table.insert(b[k], Vector2.new(p.Position.X, p.Position.Z))
				end
			end
		end
		return b
	end
	local function isFree(buckets, x, z)
		local cx, cz = math.floor(x / STEP), math.floor(z / STEP)
		local pt = Vector2.new(x, z)
		for dx = -1, 1 do for dz = -1, 1 do
			local b = buckets[(cx + dx) .. "," .. (cz + dz)]
			if b then for _, v in ipairs(b) do if (pt - v).Magnitude < MIND then return false end end end
		end end
		return true
	end
	local function markPlanted(buckets, x, z)
		local k = bkey(x, z)
		buckets[k] = buckets[k] or {}
		table.insert(buckets[k], Vector2.new(x, z))
	end

	-- Tool seed di inventory namanya "<Nama> Seed [Xjumlah]". Server WAJIB kamu
	-- megang tool seed-nya pas Plant_RE, jadi equip dulu sebelum tanam.
	local function seedBase(t)
		return t:IsA("Tool") and t.Name:match("^(.-) Seed %[X%d+%]") or nil
	end
	local function holdingSeed(name)
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do if seedBase(t) == name then return true end end end
		return false
	end
	local function equipSeed(name)
		if holdingSeed(name) then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if seedBase(t) == name then tool = t; break end end end
		if tool then
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return holdingSeed(name)
	end

	----------------------------------------------------------------- loop tanam
	local function plantLoop(myId)
		ctx.elevate()
		while CFG.plantSeedEnabled and ctx.alive() and ctx.state.plantId == myId do
			local sel = CFG.plantSeedNames or {}
			if next(sel) then
				local inv = seedInventory()
				local mode = CFG.plantPosition or "Good Position"
				local cells, buckets, ci
				if mode == "Good Position" then cells = goodCells(); buckets = buildBuckets(); ci = 0 end
				local function nextPos()
					if mode == "Random" then return randomPos() end
					if mode == "Player Position" then return playerPos() end
					-- Good Position: cell yg beneran kosong (radius) berikutnya
					while ci < #cells do
						ci = ci + 1
						local c = cells[ci]
						if isFree(buckets, c.X, c.Z) then
							markPlanted(buckets, c.X, c.Z) -- reserve biar ga dipake 2x
							return c
						end
					end
					return nil
				end

				local planted, anySeed = 0, false
				for name in pairs(sel) do
					local qty = inv[name] or 0
					if qty > 0 then
						anySeed = true
						if equipSeed(name) then -- equip tool seed dulu
							for _ = 1, qty do
								if not CFG.plantSeedEnabled or ctx.state.plantId ~= myId then break end
								local pos = nextPos()
								if not pos then break end -- Good Position: cell penuh
								pcall(function() Plant_RE:FireServer(pos, name) end)
								planted = planted + 1
								task.wait(0.15 + (tonumber(CFG.plantDelay) or 0))
							end
						end
					end
				end
				if not anySeed then setStatus("Plants: seed terpilih habis")
				else setStatus(("Plants: tanam %d (%s)"):format(planted, mode)) end
			else
				setStatus("Plants: pilih seed dulu")
			end
			task.wait(1)
		end
	end

	function ctx.startPlant()
		ctx.state.plantId = (ctx.state.plantId or 0) + 1
		local myId = ctx.state.plantId
		task.spawn(function() plantLoop(myId) end)
	end
end
