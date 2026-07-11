--[[ accept.lua — Automation Accept.
     * Accept Gifts : gift pet LANGSUNG (tanpa trade/tiket). Remote GiftPet masuk,
                      dijawab AcceptPetGift:FireServer(true, giftId).
     * Accept Trades: auto-terima AJAKAN trade masuk (RespondRequest true) [menyusul].
     Dua hal berbeda — gift ≠ trade. ]]
return function(ctx)
	local CFG            = ctx.CFG
	local SendRequest    = ctx.deps.SendRequest
	local RespondRequest = ctx.deps.RespondRequest
	local GiftPet        = ctx.deps.GiftPet
	local AcceptPetGift  = ctx.deps.AcceptPetGift
	local function log(m) ctx.log(m) end

	----------------------------------------------------------------- AUTO ACCEPT GIFT
	-- GiftPet.OnClientEvent(giftId, petDescription, senderName)
	-- UI notif dibuat game di PlayerGui.Gift_Notification.Frame (tiap gift = 1 clone,
	-- tombolnya di notif.Holder.Frame.Accept). Kita picu klik tombol itu supaya
	-- handler asli jalan (destroy UI + fire AcceptPetGift) -> UI ikut hilang.
	local LP = ctx.LP

	local function clickAcceptButtons()
		local pg = LP:FindFirstChild("PlayerGui")
		local gn = pg and pg:FindFirstChild("Gift_Notification")
		local frame = gn and gn:FindFirstChild("Frame")
		if not frame then return 0 end
		local n = 0
		for _, notif in ipairs(frame:GetChildren()) do
			local holder = notif:FindFirstChild("Holder")
			local inner  = holder and holder:FindFirstChild("Frame")
			local accept = inner and inner:FindFirstChild("Accept")
			if accept then
				local fired = false
				if type(getconnections) == "function" then
					for _, c in ipairs(getconnections(accept.MouseButton1Click)) do
						pcall(function() c:Fire() end); fired = true
					end
				end
				if fired then n += 1 end
			end
		end
		return n
	end

	if GiftPet and AcceptPetGift then
		GiftPet.OnClientEvent:Connect(function(giftId, petDesc, sender)
			if not CFG.acceptGifts then return end
			if type(giftId) ~= "string" then return end
			log(("Gift masuk dari %s: %s"):format(tostring(sender), tostring(petDesc)))
			task.wait(0.5) -- kasih waktu game bikin UI notif-nya dulu
			local clicked = clickAcceptButtons()
			if clicked > 0 then
				log("Gift diterima ✓ (via tombol, UI ditutup)")
			else
				-- fallback: fire remote langsung + coba hapus notif
				pcall(function() AcceptPetGift:FireServer(true, giftId) end)
				local pg = LP:FindFirstChild("PlayerGui")
				local gn = pg and pg:FindFirstChild("Gift_Notification")
				local frame = gn and gn:FindFirstChild("Frame")
				if frame then for _, c in ipairs(frame:GetChildren()) do c:Destroy() end end
				log("Gift diterima ✓ (fallback remote)")
			end
		end)
	else
		warn("[AllegiaanHub] GiftPet/AcceptPetGift remote tidak ketemu — auto accept gift nonaktif.")
	end

	----------------------------------------------------------------- AUTO ACCEPT TRADE (request)
	-- SendRequest.OnClientEvent(requestId, senderPlayer, expireTime) -> RespondRequest(reqId, true)
	if SendRequest and RespondRequest then
		pcall(function()
			SendRequest.OnClientEvent:Connect(function(requestId, senderPlayer)
				if not CFG.acceptTrades then return end
				log("Auto-accept ajakan trade dari " .. tostring(senderPlayer and senderPlayer.Name or "?"))
				task.wait(0.3)
				pcall(function() RespondRequest:FireServer(requestId, true) end)
			end)
		end)
	end
end
