--[[ sender.lua — Helper kirim webhook Discord dengan bypass proxy. ]]
local HttpService = game:GetService("HttpService")

local function sendWebhook(url, payload)
	if not url or url == "" then return end
	
	-- Gunakan proxy lewis.es jika menggunakan HttpService standard karena Discord memblokir Roblox UA
	local proxiedUrl = url:gsub("discord.com/api/webhooks/", "webhook.lewis.es/api/webhooks/")
	
	local success, err = pcall(function()
		local jsonPayload = HttpService:JSONEncode(payload)
		
		-- Cari executor request function
		local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
		if reqFn then
			reqFn({
				Url = url,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
				},
				Body = jsonPayload
			})
		else
			HttpService:PostAsync(proxiedUrl, jsonPayload, Enum.HttpContentType.ApplicationJson)
		end
	end)
	if not success then
		warn("[AllegiaanGarden Webhook] Gagal mengirim: " .. tostring(err))
	end
end

return sendWebhook
