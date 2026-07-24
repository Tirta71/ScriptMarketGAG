--[[
	AllegiaanHub — GARDEN app (loader)
	Dipanggil router GAGSeller/init.lua saat berada di server Garden.
	Pola sama seperti trade/: tiap modul `return function(ctx)`, berbagi tabel ctx.
--]]

local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"
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
ctx.sendWebhook     = loadRaw("modules/core/webhook.lua")     -- function(url, payload, ctx)
ctx.webhookMutation = loadRaw("modules/mutation/webhook.lua") -- table {sendEnabled, sendSubmitted, sendClaimed}
ctx.webhookLeveling = loadRaw("modules/leveling/webhook.lua") -- table leveling webhook
ctx.webhookElephant = loadRaw("modules/elephant/webhook.lua") -- table elephant webhook
ctx.webhookCleanse  = loadRaw("modules/mutation/cleanse_webhook.lua") -- table cleanse/mutation webhook

-- Modul dikelompokkan per-menu: tiap fitur punya folder sendiri (varian = v1/v2),
-- infra bersama di modules/core/. Urutan load tetap dijaga (dependency).
local MODULES = {
	"modules/core/services.lua",
	"modules/core/registry.lua",
	"modules/core/config.lua",
	"ui/theme.lua",
	"modules/inventory/automation_trade.lua",
	"modules/inventory/automation_accept.lua",
	"modules/pet/automation_pickup_pet.lua",
	"modules/pet/automation_boost_pet.lua",
	"modules/shop/automation_shop.lua",
	"modules/leveling/automation_leveling_v1.lua",
	"modules/leveling/automation_leveling_v2.lua",
	"modules/elephant/automation_elephant_v1.lua",
	"modules/elephant/automation_elephant_v2.lua",
	"modules/growth/automation_growth.lua",
	"modules/hatch/automation_hatch.lua",
	"modules/event/auto_chest_hunt.lua",
	"modules/mutation/automation_mutation_machine.lua",
	"modules/mutation/automation_mutation.lua",
	"modules/event/automation_summer_event.lua",
	"ui/components.lua",
	"modules/misc/esp_label.lua",
	"ui/window.lua",
	"ui/pages.lua",
	"app.lua",
}

for _, rel in ipairs(MODULES) do
	loadModule(rel)(ctx)
end

return ctx
