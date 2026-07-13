--[[
	GAG Seller — Trade World (Grow a Garden)  [Refactored / Modular]
	App TRADE WORLD. Biasanya tidak dijalankan langsung — dipanggil oleh router
	GAGSeller/init.lua saat PlaceId == Trade World. Bisa juga dijalankan manual:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/main/GAGSeller/trade/init.lua"))()

	init.lua bertugas:
	  1. Membangun satu tabel `ctx` yang dibagi ke semua modul.
	  2. Me-load tiap modul secara berurutan (HttpGet raw GitHub + loadstring).
	  3. Menjalankan app.lua sebagai langkah terakhir.

	Setiap modul berbentuk:  return function(ctx) ... end
	dan menambahkan field/fungsi ke `ctx` supaya modul lain bisa memakainya.

	Struktur logika 100% sama dengan GAGSeller.lua single-file, hanya dipecah.
--]]

-- Base URL raw GitHub tempat semua modul berada.
-- Ganti user/repo/branch di sini kalau repo dipindah/di-fork.
local BASE = "https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/main/GAGSeller/trade"

--------------------------------------------------------------------- loader
local function loadModule(relPath)
	local full = BASE .. "/" .. relPath
	local ok, src = pcall(function() return game:HttpGet(full) end)
	if not ok or type(src) ~= "string" or src == "" then
		error(("[GAGSeller] gagal ambil %s: %s"):format(full, tostring(src)))
	end
	local chunk, err = loadstring(src, "@" .. relPath)
	if not chunk then
		error(("[GAGSeller] gagal compile %s: %s"):format(full, tostring(err)))
	end
	local mod = chunk()
	if type(mod) ~= "function" then
		error(("[GAGSeller] modul %s harus 'return function(ctx)'"):format(full))
	end
	return mod
end

--------------------------------------------------------------------- context
local ctx = {
	BASE  = BASE,
	state = {
		running        = false,
		gui            = nil,
		listedSet      = {},
		currentLoopId  = 0,
		lastProcessedTx = {},
		logLines       = {},
	},
	ui   = {},   -- referensi elemen GUI (diisi window.lua / pages.lua)
	reg  = {},   -- opsi dropdown (diisi registry.lua)
	deps = {},   -- module require game (diisi services.lua)
}

-- Fungsi util global kecil yang dibutuhkan banyak modul.
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

--------------------------------------------------------------------- boot
-- Urutan load penting: modul bawah bergantung pada modul di atasnya.
local MODULES = {
	"modules/services.lua",   -- game services + deps require
	"modules/registry.lua",   -- PET/MUT/SKIN options
	"modules/config.lua",     -- CFG default + load/persist state
	"ui/theme.lua",           -- warna + helper Instance
	"modules/booth.lua",      -- booth claim / tokens
	"modules/webhook.lua",    -- webhook + sell listener
	"modules/listing.lua",    -- listPass / mainLoop / util
	"ui/components.lua",      -- toggle/input/dropdown/accordion/tab
	"ui/window.lua",          -- jendela utama + log + status
	"modules/samloop.lua",    -- full-loop Sam The Clam (server-hop)
	"ui/pages.lua",           -- halaman Sell/Profile/Inventory/Misc
	"app.lua",                -- init akhir + supervisor loop
}

for _, rel in ipairs(MODULES) do
	loadModule(rel)(ctx)
end

return ctx
