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

	-- nama cakep buat key umum (override). Selain ini, nama di-generate otomatis
	-- dari key (prettify camelCase). giftKey opsional (buat tombol Gift to Player).
	local FRIENDLY = {
		SeedShopRestock         = "Seed Shop Restock",
		GearShopRestock         = "Gear Shop Restock",
		DailySeedShopRestock    = "Daily Seed Shop Restock",
		EventShopRestock        = "Event Shop Restock",
		CosmeticShopRestock     = "Cosmetic Shop Restock",
		RefreshPetShop          = "Pet Shop Restock",
		GrowAll                 = "Grow All",
		CollectAll              = "Collect All",
		StealPlant              = "Steal Plant",
		BuyGoldenEgg            = "Golden Egg",
		SaveSlotPurchase        = "Extra Save Slot",
		RestoreStreak           = "Restore Streak",
		SkipMutationMachineTime = "Skip Mutation Machine",
		SkipPetAgeLimitTime     = "Skip Pet Age Limit",
		SkipPetEggTime          = "Skip Pet Egg Time",
	}
	-- key varian Gift (buat tombol Gift to Player).
	local GIFT = {
		GrowAll        = "GrowAllGift",
		CollectAll     = "CollectAllGift",
		SkipPetEggTime = "SkipPetEggTimeGift",
	}

	-- prettify "SkipPetEggTime10" -> "Skip Pet Egg Time 10", "BuySheckles1000" -> "Buy Sheckles 1000"
	local function prettify(key)
		local s = key
		s = s:gsub("(%l)(%u)", "%1 %2")      -- huruf kecil->besar
		s = s:gsub("(%a)(%d)", "%1 %2")      -- huruf->angka
		s = s:gsub("_", " ")
		return s
	end

	-- opsi dropdown item: SEMUA key di DevProductIds yg punya PurchaseID.
	-- Skip key varian *Gift (dipakai tombol Gift, bukan item terpisah).
	function ctx.getPremiumItemOptions()
		local D = devIds()
		local out = {}
		for k, v in pairs(D) do
			if type(v) == "table" and v.PurchaseID and not k:match("Gift$") then
				out[#out + 1] = { name = k, display = FRIENDLY[k] or prettify(k) }
			end
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		return out
	end
	function ctx.getPremiumPayOptions()
		return { { name = "robux", display = "Robux" }, { name = "token", display = "Token" } }
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
		local giftKey = GIFT[CFG.premiumItem]
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
