--[[ automation_summer_shop.lua — Auto Buy Summer Shop (event).
     Dua shop event:
       Summer Seed Shop  -> beli seed pakai Sheckles
       Tide Token Shop   -> beli item pakai TideTokens
     Opsi dropdown dari registry EventShopData (katalog, semua item tampil walau habis stock).
     Ada opsi "All" = beli semua yang lagi ada stock.
     Remote: BuyEventShopStock:FireServer(itemKey, shopName)
     Beli hanya saat restock (ShopSeed berubah) biar murah & ga lag.
     Fungsi: ctx.startBuySummerSeed / ctx.startBuyTideToken. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local BuyEventShopStock = GE:WaitForChild("BuyEventShopStock")
	local function setStatus(s) ctx.setStatus(s) end

	local SUMMER_SEED = "Summer Seed Shop"
	local TIDE_TOKEN  = "Tide Token Shop"

	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	-- Opsi dropdown dari katalog EventShopData[shop] (semua item DisplayInShop).
	local function shopOptions(shopName)
		local out = { { value = "All", display = "All (beli semua)" } }
		local ok, data = pcall(function() return require(RS.Data.EventShopData)[shopName] end)
		if ok and type(data) == "table" then
			local names = {}
			for key, v in pairs(data) do
				if type(v) == "table" and v.DisplayInShop then names[#names + 1] = key end
			end
			table.sort(names)
			for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		end
		return out
	end
	function ctx.getSummerSeedShopOptions() return shopOptions(SUMMER_SEED) end
	function ctx.getTideTokenShopOptions() return shopOptions(TIDE_TOKEN) end

	----------------------------------------------------------------- loop beli (per-shop)
	local POLL = 2
	local function buyLoop(shopName, enabledKey, selKey, idKey, label)
		ctx.state[idKey] = (ctx.state[idKey] or 0) + 1
		local myId = ctx.state[idKey]
		ctx.elevate()
		local lastSeed
		while CFG[enabledKey] and ctx.alive() and ctx.state[idKey] == myId do
			local d = getData()
			local shop = d and d.EventShopStock and d.EventShopStock[shopName]
			local seed = shop and shop.ShopSeed
			if shop and seed ~= lastSeed then -- restock baru (atau pertama jalan) -> beli
				lastSeed = seed
				local st = shop.Stocks or {}
				local sel = CFG[selKey] or {}
				local all = sel["All"]
				local bought = 0
				for itemKey, v in pairs(st) do
					if all or sel[itemKey] then
						local stock = type(v) == "table" and v.Stock or 0
						for _ = 1, stock do
							if not CFG[enabledKey] or ctx.state[idKey] ~= myId then break end
							pcall(function() BuyEventShopStock:FireServer(itemKey, shopName) end)
							bought = bought + 1; task.wait(0.2)
						end
					end
				end
				setStatus(("%s: restock -> beli %d"):format(label, bought))
			else
				setStatus(("%s: nunggu restock"):format(label))
			end
			task.wait(POLL)
		end
	end

	function ctx.startBuySummerSeed()
		task.spawn(function() buyLoop(SUMMER_SEED, "buySummerSeedEnabled", "buySummerSeedNames", "buySummerSeedId", "Summer Seed") end)
	end
	function ctx.startBuyTideToken()
		task.spawn(function() buyLoop(TIDE_TOKEN, "buyTideTokenEnabled", "buyTideTokenNames", "buyTideTokenId", "Tide Token") end)
	end
end
