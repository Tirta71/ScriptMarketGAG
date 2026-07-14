--[[ shop.lua — Automation Buy Seed / Egg / Gear.
     Opsi dropdown diambil dari REGISTRY katalog shop (bukan stock), jadi semua
     item tampil walau lagi habis; item baru dari update game auto masuk.
       Seed -> SeedShopData
       Gear -> GearShopData.Gear
       Egg  -> PetEggData
     Ada opsi "All" = beli semua yang lagi ada stock.
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

	-- Ambil daftar nama dari registry katalog; buang key non-item (RefreshTime, Gear).
	local function catalogNames(getTbl)
		local ok, t = pcall(getTbl)
		local out = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do
				local n = tostring(k)
				if n ~= "RefreshTime" and n ~= "Gear" then out[#out + 1] = n end
			end
			table.sort(out)
		end
		return out
	end

	local function optionsFrom(names, sel)
		local out = { { value = "All", display = "All (beli semua)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	function ctx.getSeedShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.SeedShopData) end), sel)
	end
	function ctx.getGearShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.GearShopData).Gear end), sel)
	end
	function ctx.getEggShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.PetEggData) end), sel)
	end

	----------------------------------------------------------------- loop beli
	local function buySeedLoop()
		ctx.state.buySeedId = (ctx.state.buySeedId or 0) + 1
		local myId = ctx.state.buySeedId
		ctx.elevate()
		while CFG.buySeedEnabled and ctx.alive() and ctx.state.buySeedId == myId do
			local d = getData()
			local st = d and d.SeedStock and d.SeedStock.Stocks or {}
			local sel = CFG.buySeedNames or {}
			local all = sel["All"]
			local bought = 0
			for name, v in pairs(st) do
				if all or sel[name] then
					local stock = type(v) == "table" and v.Stock or 0
					for _ = 1, stock do
						if not CFG.buySeedEnabled or ctx.state.buySeedId ~= myId then break end
						pcall(function() BuySeedStock:FireServer("Shop", name) end)
						bought = bought + 1; task.wait(0.15)
					end
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
			local sel = CFG.buyGearNames or {}
			local all = sel["All"]
			local bought = 0
			for name, v in pairs(st) do
				if all or sel[name] then
					local stock = type(v) == "table" and v.Stock or 0
					for _ = 1, stock do
						if not CFG.buyGearEnabled or ctx.state.buyGearId ~= myId then break end
						pcall(function() BuyGearStock:FireServer(name) end)
						bought = bought + 1; task.wait(0.15)
					end
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
			local sel = CFG.buyEggNames or {}
			local all = sel["All"]
			local bought = 0
			for index, v in pairs(st) do
				local nm = type(v) == "table" and v.EggName
				local stock = type(v) == "table" and v.Stock or 0
				if nm and (all or sel[nm]) then
					for _ = 1, stock do
						if not CFG.buyEggEnabled or ctx.state.buyEggId ~= myId then break end
						pcall(function() BuyPetEgg:FireServer(index) end)
						bought = bought + 1; task.wait(0.15)
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
