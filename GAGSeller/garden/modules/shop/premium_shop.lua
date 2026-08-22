--[[ premium_shop.lua — Premium Shop (dev-product) beli via Robux atau Token.
     Sumber ID: RS.Data.DevProductIds (akurat, live). Beli:
       Robux : MarketController:PromptPurchaseRobux(id, Enum.InfoType.Product)
       Token : GameEvents.TradeEvents.TradeTokens.Purchase:InvokeServer(id)
     Gift  : prompt varian <Key>Gift kalau ada (game handle penerima). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local MPS = game:GetService("MarketplaceService")
	local LP  = ctx.LP
	local CFG = ctx.CFG

	local MC; pcall(function() MC = require(RS.Modules.MarketController) end)
	local function devIds() local ok, d = pcall(function() return require(RS.Data.DevProductIds) end); return ok and d or {} end
	local function ttFolder()
		local ge = RS:FindFirstChild("GameEvents")
		local te = ge and ge:FindFirstChild("TradeEvents")
		return te and te:FindFirstChild("TradeTokens")
	end

	-- katalog kurasi: {key di DevProductIds, display, giftKey?}. ID di-resolve live.
	local CATALOG = {
		{ "SeedShopRestock",        "Seed Shop Restock" },
		{ "GearShopRestock",        "Gear Shop Restock" },
		{ "DailySeedShopRestock",   "Daily Seed Shop Restock" },
		{ "EventShopRestock",       "Event Shop Restock" },
		{ "CosmeticShopRestock",    "Cosmetic Shop Restock" },
		{ "RefreshPetShop",         "Pet Shop Restock" },
		{ "GrowAll",                "Grow All",              "GrowAllGift" },
		{ "CollectAll",             "Collect All",           "CollectAllGift" },
		{ "StealPlant",             "Steal Plant" },
		{ "BuyGoldenEgg",           "Golden Egg" },
		{ "SaveSlotPurchase",       "Extra Save Slot" },
		{ "RestoreStreak",          "Restore Streak" },
		{ "BuySheckles100",         "Buy Sheckles (100)" },
		{ "BuySheckles250",         "Buy Sheckles (250)" },
		{ "BuySheckles1000",        "Buy Sheckles (1.000)" },
		{ "BuySheckles5000",        "Buy Sheckles (5.000)" },
		{ "SkipCrateTime",          "Skip Crate Time" },
		{ "SkipMutationMachineTime","Skip Mutation Machine" },
		{ "SkipPetAgeLimitTime",    "Skip Pet Age Limit" },
		{ "SkipPetEggTime",         "Skip Pet Egg Time",     "SkipPetEggTimeGift" },
	}

	-- opsi dropdown item: cuma yg key-nya ada di DevProductIds.
	function ctx.getPremiumItemOptions()
		local D = devIds()
		local out = {}
		for _, e in ipairs(CATALOG) do
			if D[e[1]] and D[e[1]].PurchaseID then
				out[#out + 1] = { name = e[1], display = e[2] }
			end
		end
		return out
	end
	function ctx.getPremiumPayOptions()
		return { { name = "robux", display = "Robux" }, { name = "token", display = "Token" } }
	end

	local function catEntry(key)
		for _, e in ipairs(CATALOG) do if e[1] == key then return e end end
	end
	local function idOf(key)
		local D = devIds()
		local rec = key and D[key]
		return rec and rec.PurchaseID
	end

	-- BELI item terpilih sesuai payment method.
	function ctx.premiumBuy()
		local key = CFG.premiumItem
		local id  = idOf(key)
		if not id then ctx.setStatus("Premium Shop: pilih item dulu"); return end
		if CFG.premiumPay == "token" then
			local tt = ttFolder()
			if not (tt and tt:FindFirstChild("Purchase")) then ctx.setStatus("Premium Shop: Token remote ga ada"); return end
			-- cek dulu bisa token apa ngga
			local canOk, can = pcall(function() return tt.CanPurchase:InvokeServer(id) end)
			if canOk and can then
				pcall(function() tt.Purchase:InvokeServer(id) end)
				ctx.setStatus("Premium Shop: beli via Token…")
			else
				ctx.setStatus("Premium Shop: item ini ga bisa Token, pakai Robux")
			end
		else
			if MC and MC.PromptPurchaseRobux then
				pcall(function() MC:PromptPurchaseRobux(id, Enum.InfoType.Product) end)
			else
				pcall(function() MPS:PromptProductPurchase(LP, id) end)
			end
			ctx.setStatus("Premium Shop: prompt Robux dibuka")
		end
	end

	-- GIFT: prompt varian <Key>Gift (game yg minta penerima). Robux only.
	function ctx.premiumGift()
		local e = catEntry(CFG.premiumItem)
		local giftKey = e and e[3]
		local gid = giftKey and idOf(giftKey)
		if not gid then ctx.setStatus("Premium Shop: item ini ga ada opsi Gift"); return end
		if MC and MC.PromptPurchaseRobux then
			pcall(function() MC:PromptPurchaseRobux(gid, Enum.InfoType.Product) end)
		else
			pcall(function() MPS:PromptProductPurchase(LP, gid) end)
		end
		ctx.setStatus("Premium Shop: prompt Gift dibuka")
	end
end
