--[[ shop.lua — Automation Buy Seed / Egg / Gear.
     Opsi dropdown diambil REALTIME dari stock shop game (DataService), jadi
     kalau game update shop, otomatis ikut (tanpa ubah kode).
     Remote:
       BuySeedStock:FireServer("Shop", seedName)
       BuyGearStock:FireServer(gearName)
       BuyPetEgg:FireServer(eggIndex) ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local BuySeedStock = GE:WaitForChild("BuySeedStock")
	local BuyGearStock = GE:WaitForChild("BuyGearStock")
	local BuyPetEgg    = GE:WaitForChild("BuyPetEgg")
	local function setStatus(s) ctx.setStatus(s) end

	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	----------------------------------------------------------------- opsi realtime
	local function sortSel(out, sel)
		table.sort(out, function(a, b)
			local sa = sel and sel[a.value] and 1 or 0
			local sb = sel and sel[b.value] and 1 or 0
			if sa ~= sb then return sa > sb end
			return a.display < b.display
		end)
		return out
	end

	function ctx.getSeedShopOptions(sel)
		local out = {}
		local d = getData()
		local st = d and d.SeedStock and d.SeedStock.Stocks
		if type(st) == "table" then
			for name, v in pairs(st) do
				out[#out + 1] = { value = name, display = ("%s (x%s)"):format(name, tostring(type(v) == "table" and v.Stock or v)) }
			end
		end
		return sortSel(out, sel)
	end

	function ctx.getGearShopOptions(sel)
		local out = {}
		local d = getData()
		local st = d and d.GearStock and d.GearStock.Stocks
		if type(st) == "table" then
			for name, v in pairs(st) do
				out[#out + 1] = { value = name, display = ("%s (x%s)"):format(name, tostring(type(v) == "table" and v.Stock or v)) }
			end
		end
		return sortSel(out, sel)
	end

	function ctx.getEggShopOptions(sel)
		local out, seen = {}, {}
		local d = getData()
		local st = d and d.PetEggStock and d.PetEggStock.Stocks
		if type(st) == "table" then
			for _, v in pairs(st) do
				local nm = type(v) == "table" and v.EggName
				if nm and not seen[nm] then
					seen[nm] = true
					out[#out + 1] = { value = nm, display = nm }
				end
			end
		end
		return sortSel(out, sel)
	end

	----------------------------------------------------------------- loop beli
	local function buySeedLoop()
		ctx.state.buySeedId = (ctx.state.buySeedId or 0) + 1
		local myId = ctx.state.buySeedId
		ctx.elevate()
		while CFG.buySeedEnabled and ctx.alive() and ctx.state.buySeedId == myId do
			local d = getData()
			local st = d and d.SeedStock and d.SeedStock.Stocks or {}
			local bought = 0
			for name in pairs(CFG.buySeedNames or {}) do
				local v = st[name]
				local stock = type(v) == "table" and v.Stock or 0
				for _ = 1, stock do
					if not CFG.buySeedEnabled or ctx.state.buySeedId ~= myId then break end
					pcall(function() BuySeedStock:FireServer("Shop", name) end)
					bought = bought + 1
					task.wait(0.15)
				end
			end
			setStatus(bought > 0 and ("Buy Seed: beli %d"):format(bought) or "Buy Seed: nunggu stock")
			task.wait(2)
		end
	end

	local function buyGearLoop()
		ctx.state.buyGearId = (ctx.state.buyGearId or 0) + 1
		local myId = ctx.state.buyGearId
		ctx.elevate()
		while CFG.buyGearEnabled and ctx.alive() and ctx.state.buyGearId == myId do
			local d = getData()
			local st = d and d.GearStock and d.GearStock.Stocks or {}
			local bought = 0
			for name in pairs(CFG.buyGearNames or {}) do
				local v = st[name]
				local stock = type(v) == "table" and v.Stock or 0
				for _ = 1, stock do
					if not CFG.buyGearEnabled or ctx.state.buyGearId ~= myId then break end
					pcall(function() BuyGearStock:FireServer(name) end)
					bought = bought + 1
					task.wait(0.15)
				end
			end
			setStatus(bought > 0 and ("Buy Gear: beli %d"):format(bought) or "Buy Gear: nunggu stock")
			task.wait(2)
		end
	end

	local function buyEggLoop()
		ctx.state.buyEggId = (ctx.state.buyEggId or 0) + 1
		local myId = ctx.state.buyEggId
		ctx.elevate()
		while CFG.buyEggEnabled and ctx.alive() and ctx.state.buyEggId == myId do
			local d = getData()
			local st = d and d.PetEggStock and d.PetEggStock.Stocks or {}
			local bought = 0
			for index, v in pairs(st) do
				local nm = type(v) == "table" and v.EggName
				local stock = type(v) == "table" and v.Stock or 0
				if nm and (CFG.buyEggNames or {})[nm] then
					for _ = 1, stock do
						if not CFG.buyEggEnabled or ctx.state.buyEggId ~= myId then break end
						pcall(function() BuyPetEgg:FireServer(index) end)
						bought = bought + 1
						task.wait(0.15)
					end
				end
			end
			setStatus(bought > 0 and ("Buy Egg: beli %d"):format(bought) or "Buy Egg: nunggu stock")
			task.wait(2)
		end
	end

	function ctx.startBuySeed() task.spawn(buySeedLoop) end
	function ctx.startBuyGear() task.spawn(buyGearLoop) end
	function ctx.startBuyEgg() task.spawn(buyEggLoop) end
end
