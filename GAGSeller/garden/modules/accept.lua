--[[ accept.lua — Automation Accept.
     * Accept Trades: auto-terima AJAKAN trade masuk (RespondRequest true).
     * Accept Gifts : saat ada trade window masuk (bukan kita yang mulai),
                      auto Accept + Confirm untuk menerima pet/gift dari lawan.
     Guard: gift-receive hanya jalan kalau Automation Trade kita TIDAK sedang aktif. ]]
return function(ctx)
	local CFG           = ctx.CFG
	local TC            = ctx.deps.TradingController
	local SendRequest   = ctx.deps.SendRequest
	local RespondRequest = ctx.deps.RespondRequest
	local Accept        = ctx.deps.Accept
	local Confirm       = ctx.deps.Confirm
	local function log(m) ctx.log(m) end

	----------------------------------------------------------------- accept trade requests
	-- SendRequest.OnClientEvent(requestId, senderPlayer, expireTime)
	pcall(function()
		SendRequest.OnClientEvent:Connect(function(requestId, sender)
			if not CFG.acceptTrades then return end
			log("Auto-accept ajakan trade dari " .. tostring(sender and sender.Name or "?"))
			task.wait(0.3)
			pcall(function() RespondRequest:FireServer(requestId, true) end)
		end)
	end)

	----------------------------------------------------------------- receive gifts (incoming trade)
	if TC and TC.OnTradeCreated then
		TC.OnTradeCreated:Connect(function()
			if not CFG.acceptGifts then return end
			if ctx.state.tradeRunning then return end -- jangan ganggu automation trade kita
			task.spawn(function()
				log("Gift/trade masuk — auto accept + confirm.")
				task.wait(0.6)
				pcall(function() Accept:FireServer() end)
				-- tunggu lawan accept lalu confirm
				local t0 = os.clock()
				local ok = false
				repeat
					task.wait(0.5)
					if ctx.otherAccepted and ctx.otherAccepted(ctx.replicatorData()) then ok = true; break end
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 30
				if ok and TC.CurrentTradeReplicator then
					pcall(function() Confirm:FireServer() end)
					log("Gift diterima (confirm terkirim).")
				end
			end)
		end)
	end
end
