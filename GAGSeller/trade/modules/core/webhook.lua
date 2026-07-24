--[[ webhook.lua — Discord webhook + listener transaksi (notif terjual).
     Mengisi: ctx.sendWebhook
     Efek samping: connect AddToHistory.OnClientEvent ]]
return function(ctx)
	local LP          = ctx.LP
	local HttpService = ctx.Services.HttpService
	local CFG         = ctx.CFG
	local AddToHistory = ctx.deps.AddToHistory

	----------------------------------------------------------------- sender
	local function sendWebhook(payload)
		if not CFG.webhookEnabled or CFG.webhookUrl == "" then return end
		task.spawn(function()
			local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
			if not reqFn then return end
			pcall(reqFn, {
				Url = CFG.webhookUrl, Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload),
			})
		end)
	end
	ctx.sendWebhook = sendWebhook

	----------------------------------------------------------------- sell listener
	local lastProcessedTx = ctx.state.lastProcessedTx
	AddToHistory.OnClientEvent:Connect(function(tx)
		if not CFG.webhookEnabled or CFG.webhookUrl == "" then return end
		if not tx or type(tx) ~= "table" then return end
		if lastProcessedTx[tx.id] then return end
		lastProcessedTx[tx.id] = true

		-- Cek apakah kita adalah penjual (seller) dan transaksinya sukses
		local myId = ctx.myPlayerId()
		local isSeller = (myId == tx.seller.userId) or (LP.UserId == tx.seller.userId)
		local isSuccess = tx.status and tx.status.result ~= "Failed"

		if isSeller and isSuccess then
			-- Dapatkan detail item
			local itemType = tx.item and tx.item.type or "Unknown"
			local petType = "Unknown"
			local petName = "-"
			local petAge = "-"
			local petWeight = "-"

			if itemType == "Pet" and tx.item.data then
				local d = tx.item.data
				petType = d.PetType or "Unknown"
				if d.PetData then
					petName = d.PetData.Name or petType
					if petName == "" then petName = petType end
					petAge = tostring(d.PetData.Level or 0)
					petWeight = ("%.2f kg"):format(d.PetData.BaseWeight or 0)
				end
			else
				-- Fallback jika bukan pet
				if tx.item.data then
					if tx.item.data.ItemData then
						petType = tx.item.data.ItemData.ItemName or "Unknown"
					else
						petType = tx.item.data.PetType or tx.item.data.SkinID or "Unknown"
					end
					petName = petType
				end
			end

			local price = tx.price or 0
			local priceWithFee = math.floor(price * 0.98)

			local currentTokens = tostring(ctx.getTokens())
			local formattedTokens = currentTokens
			local numTokens = tonumber(currentTokens)
			if numTokens then
				local formatted = tostring(numTokens)
				local k
				while true do
					formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
					if k == 0 then break end
				end
				formattedTokens = formatted
			end

			local embed = {
				title = "Sell Notification",
				color = 16711680, -- warna merah
				fields = {
					{
						name = "Profile :",
						value = ("> Username : %s\n> Buyer : %s"):format(tostring(tx.seller.username), tostring(tx.buyer.username)),
						inline = false
					},
					{
						name = "Item Sold :",
						value = ("> Item Type : %s\n> Pet Type : %s\n> Pet Name : %s\n> Pet Age : %s\n> Pet Weight : %s\n> Price : %s Token\n> Price (With Fee) : %s Token"):format(
							tostring(itemType),
							tostring(petType),
							tostring(petName),
							tostring(petAge),
							tostring(petWeight),
							tostring(price),
							tostring(priceWithFee)
						),
						inline = false
					},
					{
						name = "Current Tokens :",
						value = ("> %s Token"):format(tostring(formattedTokens)),
						inline = false
					}
				},
				footer = {
					text = ("Allegiaant GAG Trade • %s"):format(os.date("%d/%m/%y, %H.%M"))
				}
			}

			sendWebhook({
				username = "AllegiaantHub GAG Seller",
				embeds = { embed }
			})
		end
	end)
end
