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

	------------------------------------------------------------- harga (Robux)
	-- Harga token dinamis (RAP), susah/ga stabil -> tampilkan harga Robux dari
	-- GetProductInfo. Di-cache; prefetch pelan di background (hindari rate limit).
	local priceCache = {}                       -- id -> number | false (gagal)
	local function fetchPrice(id)
		if id == nil then return nil end
		local c = priceCache[id]
		if c ~= nil then return c or nil end
		local ok, info = pcall(function() return MPS:GetProductInfo(id, Enum.InfoType.Product) end)
		local p = (ok and info and info.PriceInRobux) or false
		priceCache[id] = p
		return p or nil
	end

	local prefetchStarted = false
	local function startPrefetch(entries)
		if prefetchStarted then return end
		prefetchStarted = true
		task.spawn(function()
			for _, e in ipairs(entries) do
				if not ctx.alive() then return end
				if priceCache[e.id] == nil then
					fetchPrice(e.id)
					task.wait(0.08)             -- pelan biar ga kena throttle GetProductInfo
				end
			end
		end)
	end

	-- opsi dropdown item: SEMUA entry di GiftData yg punya NormalId.
	-- Display + harga Robux (kalau udah ke-cache). Prefetch jalan di background.
	function ctx.getPremiumItemOptions()
		local d = giftData()
		local out, ids = {}, {}
		for k, v in pairs(d) do
			if type(v) == "table" and v.NormalId then
				local disp = tostring(v.Display or k)
				local p = priceCache[v.NormalId]
				if type(p) == "number" then disp = disp .. ("  (R$ %d)"):format(p) end
				out[#out + 1] = { name = k, display = disp }
				ids[#ids + 1] = { id = v.NormalId }
			end
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		startPrefetch(ids)
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

	-- fetch harga item terpilih & tampilkan di status (dipanggil saat milih item).
	function ctx.premiumShowPrice()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.NormalId) then return end
		local name = tostring(e.Display or CFG.premiumItem)
		local p = fetchPrice(e.NormalId)
		if p then
			ctx.setStatus(("Premium: %s — R$ %d"):format(name, p))
		else
			ctx.setStatus(("Premium: %s"):format(name))
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
