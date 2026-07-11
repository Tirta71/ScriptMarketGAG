--[[
	AllegiaanHub — GARDEN app (loader)
	Dipanggil router GAGSeller/init.lua saat berada di server Garden.
	Pola sama seperti trade/: tiap modul `return function(ctx)`, berbagi tabel ctx.
--]]

local BASE = "https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/main/GAGSeller/garden"

local function loadModule(relPath)
	local full = BASE .. "/" .. relPath
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
	return ctx.state.gui ~= nil and ctx.state.gui.Parent ~= nil
end
function ctx.elevate()
	pcall(function()
		local f = setthreadidentity or setidentity
			or (syn and syn.set_thread_identity)
			or (getgenv and getgenv().setthreadidentity)
		if f then f(7) end
	end)
end

local MODULES = {
	"modules/services.lua",
	"modules/registry.lua",
	"modules/config.lua",
	"ui/theme.lua",
	"modules/trade.lua",
	"modules/accept.lua",
	"ui/components.lua",
	"ui/window.lua",
	"ui/pages.lua",
	"app.lua",
}

for _, rel in ipairs(MODULES) do
	loadModule(rel)(ctx)
end

return ctx
