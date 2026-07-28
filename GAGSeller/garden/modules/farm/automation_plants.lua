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
	local STEP = 2
	local function cellKey(x, z) return math.floor(x / STEP) .. "," .. math.floor(z / STEP) end

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
	-- Sel grid yg udah keisi plant (biar Good Position ga numpuk).
	local function occupancy()
		local occ = {}
		local pf = plantsFolder()
		if pf then
			for _, m in ipairs(pf:GetChildren()) do
				local p = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
				if p then occ[cellKey(p.Position.X, p.Position.Z)] = true end
			end
		end
		return occ
	end

	----------------------------------------------------------------- loop tanam
	local function plantLoop(myId)
		ctx.elevate()
		while CFG.plantSeedEnabled and ctx.alive() and ctx.state.plantId == myId do
			local sel = CFG.plantSeedNames or {}
			if next(sel) then
				local inv = seedInventory()
				-- antrian seed yg mau ditanam (sesuai jumlah)
				local queue = {}
				for name in pairs(sel) do
					for _ = 1, (inv[name] or 0) do queue[#queue + 1] = name end
				end
				if #queue == 0 then
					setStatus("Plants: seed terpilih habis")
				else
					local mode = CFG.plantPosition or "Good Position"
					local cells, occ, ci
					if mode == "Good Position" then cells = goodCells(); occ = occupancy(); ci = 0 end
					local planted = 0
					for _, name in ipairs(queue) do
						if not CFG.plantSeedEnabled or ctx.state.plantId ~= myId then break end
						local pos
						if mode == "Random" then
							pos = randomPos()
						elseif mode == "Player Position" then
							pos = playerPos()
						else -- Good Position: cari cell kosong berikutnya
							while ci < #cells do
								ci = ci + 1
								local c = cells[ci]
								local k = cellKey(c.X, c.Z)
								if not occ[k] then occ[k] = true; pos = c; break end
							end
							if not pos then break end -- cell penuh
						end
						if pos then
							pcall(function() Plant_RE:FireServer(pos, name) end)
							planted = planted + 1
							task.wait(0.15 + (tonumber(CFG.plantDelay) or 0))
						end
					end
					setStatus(("Plants: tanam %d (%s)"):format(planted, mode))
				end
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
