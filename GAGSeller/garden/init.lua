--[[
	AllegiaanHub — GARDEN app (loader)
	Dipanggil router GAGSeller/init.lua saat berada di server Garden.
	Pola sama seperti trade/: tiap modul `return function(ctx)`, berbagi tabel ctx.
--]]

local branch = _G.GAG_BRANCH or "main"
local BASE = "https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/" .. branch .. "/GAGSeller/garden"

local function loadModule(relPath)
	local full = BASE .. "/" .. relPath .. "?t=" .. os.time()
	local ok, src = pcall(function() return game:HttpGet(full) end)
	if not ok or type(src) ~= "string" or src == "" then
		error(("[AllegiaanHub/garden] gagal ambil %s: %s"):format(full, tostring(src)))
	end
	local chunk, err = loadstring(src, "@" .. relPath)
	if not chunk then
		error(("[AllegiaanHub/garden] gagal compile %s: %s"):format(full, tostring(err)))
	end
	local mod = chunk()
	if type(mod) ~= "function" then
		error(("[AllegiaanHub/garden] modul %s harus 'return function(ctx)'"):format(full))
	end
	return mod
end

local ctx = {
	BASE  = BASE,
	state = {
		tradeRunning = false,
		completed    = 0,
		status       = "IDLE",
		logLines     = {},
		gui          = nil,
	},
	ui   = {},
	reg  = {},
	deps = {},
}

function ctx.alive()
	return ctx.state.isAlive ~= false
end
function ctx.elevate()
	pcall(function()
		local f = setthreadidentity or setidentity
			or (syn and syn.set_thread_identity)
			or (getgenv and getgenv().setthreadidentity)
		if f then f(7) end
	end)
end

-- Loader untuk file yang BUKAN pola return function(ctx) (mis. webhook helper/formatter).
-- Karena app di-load via HttpGet (bukan ModuleScript), require(script...) nggak jalan —
-- jadi file webhook di-fetch di sini dan hasilnya ditaruh di ctx.
local function loadRaw(relPath)
	local full = BASE .. "/" .. relPath .. "?t=" .. os.time()
	local ok, src = pcall(function() return game:HttpGet(full) end)
	if not ok or type(src) ~= "string" then return nil end
	local chunk = loadstring(src, "@" .. relPath)
	if not chunk then return nil end
	local okr, val = pcall(chunk)
	return okr and val or nil
end
ctx.sendWebhook     = loadRaw("webhook/sender.lua")      -- function(url, payload, ctx)
ctx.webhookMutation = loadRaw("webhook/mutation.lua")    -- table {sendEnabled, sendSubmitted, sendClaimed}
ctx.webhookLeveling = loadRaw("webhook/leveling.lua")    -- table leveling webhook
ctx.webhookElephant = loadRaw("webhook/elephant.lua")    -- table elephant webhook
ctx.webhookCleanse  = loadRaw("webhook/cleanse.lua")     -- table cleanse/mutation webhook

local MODULES = {
	"modules/services.lua",
	"modules/registry.lua",
	"modules/config.lua",
	"ui/theme.lua",
	"modules/trade.lua",
	"modules/accept.lua",
	"modules/pnp.lua",
	"modules/boostpet.lua",
	"modules/shop.lua",
	"modules/leveling.lua",
	"modules/leveling_v2.lua",
	"modules/elephant.lua",
	"modules/elephant_v2.lua",
	"modules/growth.lua",
	"modules/hatch.lua",
	"modules/chesthunt.lua",
	"modules/mutation.lua",
	"modules/cleanse.lua",
	"modules/summer.lua",
	"ui/components.lua",
	"ui/esp.lua",
	"ui/window.lua",
	"ui/pages.lua",
	"app.lua",
}

for _, rel in ipairs(MODULES) do
	loadModule(rel)(ctx)
end

return ctx
