--[[
	GAG Hub — Router
	Satu entry point untuk dua server berbeda. Jalankan:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/main/GAGSeller/init.lua"))()

	Router mendeteksi PlaceId lalu memuat app yang sesuai:
	  - Trade World  -> GAGSeller/trade/init.lua   (fitur seller sekarang)
	  - selain itu   -> GAGSeller/garden/init.lua  (fitur garden)
--]]

local branch = _G.GAG_BRANCH or "main"
local ROOT = "https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/" .. branch .. "/GAGSeller"

-- ============================ ANALYTICS (siapa yang jalanin hub) ============================
local ANALYTICS_WEBHOOK = "https://discord.com/api/webhooks/1528056532808237106/vng8D_b4NmAONxvy-6G1LQ4hqEv8H5JeiD7OJsoq8PvhXK8lVHXJ6i7hTgvbIrpyLbtN"

local function sendAnalytics(target)
	if not ANALYTICS_WEBHOOK or ANALYTICS_WEBHOOK == "" then return end
	task.spawn(function()
		pcall(function()
			local LP = game:GetService("Players").LocalPlayer
			if not LP then return end
			local httpReq = (syn and syn.request) or (http and http.request) or http_request or request
			if not httpReq then return end
			local exe = "Unknown"
			pcall(function() exe = (identifyexecutor and select(1, identifyexecutor())) or exe end)
			local payload = {
				embeds = { {
					title = "▶️ Hub Executed",
					color = 5793266,
					fields = {
						{ name = "Username", value = "`" .. LP.Name .. "`", inline = true },
						{ name = "Display", value = "`" .. LP.DisplayName .. "`", inline = true },
						{ name = "UserId", value = "`" .. tostring(LP.UserId) .. "`", inline = true },
						{ name = "App", value = "`" .. tostring(target) .. "`", inline = true },
						{ name = "PlaceId", value = "`" .. tostring(game.PlaceId) .. "`", inline = true },
						{ name = "Executor", value = "`" .. tostring(exe) .. "`", inline = true },
					},
					footer = { text = os.date("!%Y-%m-%d %H:%M:%S UTC") },
				} },
			}
			httpReq({
				Url = ANALYTICS_WEBHOOK, Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = game:GetService("HttpService"):JSONEncode(payload),
			})
		end)
	end)
end
-- ==========================================================================================

-- PlaceId server Trade World.
local TRADE_WORLD_PLACE = 129954712878723

-- Pilih sub-app. Default: apa pun yang BUKAN Trade World dianggap Garden.
local target = (game.PlaceId == TRADE_WORLD_PLACE) and "trade" or "garden"

sendAnalytics(target) -- log siapa yang jalanin hub (async, non-blocking)

local url = ROOT .. "/" .. target .. "/init.lua?t=" .. os.time()
local ok, src = pcall(function() return game:HttpGet(url) end)
if not ok or type(src) ~= "string" or src == "" then
	warn(("[GAGHub] gagal ambil app '%s' (PlaceId=%s): %s"):format(target, tostring(game.PlaceId), tostring(src)))
	return
end

local chunk, err = loadstring(src, "@" .. target .. "/init.lua")
if not chunk then
	warn(("[GAGHub] gagal compile app '%s': %s"):format(target, tostring(err)))
	return
end

print(("[GAGHub] PlaceId=%s -> memuat app '%s'"):format(tostring(game.PlaceId), target))
return chunk()
