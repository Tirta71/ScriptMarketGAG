--[[ premium_shop.lua — Premium Shop beli via Robux atau Token.
     Sumber katalog: RS.Data.GiftData (sama seperti sc lain, ~394 item, live).
       tiap entry: { Display, NormalId (beli sendiri), GiftId (gift ke player) }.
     Beli:
       Token : GameEvents.TradeEvents.TradeTokens.Purchase:InvokeServer(id)
       Robux : MarketController:PromptPurchaseRobux(id, Enum.InfoType.Product)
     Gift  : pakai GiftId (game handle penerima). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local MPS = game:GetService("MarketplaceService")
	local LP  = ctx.LP
	local CFG = ctx.CFG

	local MC; pcall(function() MC = require(RS.Modules.MarketController) end)
	local function giftData()
		local ok, d = pcall(function() return require(RS.Data.GiftData) end)
		return ok and d or {}
	end
	local function ttFolder()
		local ge = RS:FindFirstChild("GameEvents")
		local te = ge and ge:FindFirstChild("TradeEvents")
		return te and te:FindFirstChild("TradeTokens")
	end

	-- entry katalog berdasarkan key CFG.premiumItem.
	local function entryOf(key)
		local d = giftData()
		return key and d[key] or nil
	end

	-- opsi dropdown item: SEMUA entry di GiftData yg punya NormalId.
	function ctx.getPremiumItemOptions()
		local d = giftData()
		local out = {}
		for k, v in pairs(d) do
			if type(v) == "table" and v.NormalId then
				out[#out + 1] = { name = k, display = tostring(v.Display or k) }
			end
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		return out
	end
	function ctx.getPremiumPayOptions()
		return { { name = "robux", display = "Robux" }, { name = "token", display = "Token" } }
	end

	-- prompt beli 1 id sesuai payment method (token / robux).
	local function purchaseId(id, label)
		if CFG.premiumPay == "token" then
			local tt = ttFolder()
			if not (tt and tt:FindFirstChild("Purchase")) then ctx.setStatus("Premium Shop: Token remote ga ada"); return end
			local canOk, can = pcall(function() return tt.CanPurchase:InvokeServer(id) end)
			if canOk and can then
				pcall(function() tt.Purchase:InvokeServer(id) end)
				ctx.setStatus("Premium Shop: " .. label .. " via Token…")
			else
				ctx.setStatus("Premium Shop: item ini ga bisa Token, pakai Robux")
			end
		else
			if MC and MC.PromptPurchaseRobux then
				pcall(function() MC:PromptPurchaseRobux(id, Enum.InfoType.Product) end)
			else
				pcall(function() MPS:PromptProductPurchase(LP, id) end)
			end
			ctx.setStatus("Premium Shop: prompt Robux " .. label .. " dibuka")
		end
	end

	-- BELI buat diri sendiri (NormalId).
	function ctx.premiumBuy()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.NormalId) then ctx.setStatus("Premium Shop: pilih item dulu"); return end
		purchaseId(e.NormalId, "beli")
	end

	-- GIFT ke player (GiftId). Game yg minta penerima.
	function ctx.premiumGift()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.GiftId) then ctx.setStatus("Premium Shop: item ini ga ada opsi Gift"); return end
		purchaseId(e.GiftId, "gift")
	end
end
