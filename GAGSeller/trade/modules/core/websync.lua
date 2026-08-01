--[[ websync.lua — sinkron opsi/config trade ke dashboard web (AllegiaantHUB Monitor).
     STEP 1: push OPTIONS (daftar pet/mutasi/skin) supaya dropdown web sama persis in-game.
     Jalan di THREAD TERPISAH (task.spawn) + semua pcall = non-blocking, ga ganggu automation.

     Endpoint: POST https://allegiaant-web.vercel.app/api/options
     Payload : { pets, petCombo, muts, skins }  (lihat web src/lib/types.ts TradeOptions) ]]
return function(ctx)
	local WEB_BASE = "https://allegiaant-web.vercel.app"
	local API_KEY  = "ae3858d4a2def3306d6cbff26ff2bd72eee9319b1aae27d1"

	local HttpService = game:GetService("HttpService")
	local httpReq = (syn and syn.request) or (http and http.request) or http_request or request

	-- Bangun payload options dari ctx.reg (yang udah diisi registry.lua).
	local function buildOptions()
		local reg = ctx.reg or {}
		local skins = {}
		for _, s in ipairs(reg.SKIN_OPTIONS or {}) do
			-- CFG.boothSkin nyimpen nama internal (opt.name) -> kirim itu biar round-trip cocok.
			skins[#skins + 1] = (type(s) == "table" and s.name) or tostring(s)
		end
		return {
			pets     = reg.PET_OPTIONS or {},
			petCombo = reg.PET_COMBO_OPTIONS or {},
			muts     = reg.MUT_OPTIONS or {},
			skins    = skins,
		}
	end

	-- Push options ke web (sekali panggil). Non-blocking.
	function ctx.webPushOptions()
		if not httpReq then return end
		task.spawn(function()
			pcall(function()
				httpReq({
					Url = WEB_BASE .. "/api/options",
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = API_KEY },
					Body = HttpService:JSONEncode(buildOptions()),
				})
			end)
		end)
	end

	-- Auto-push sekali pas hub load (kasih jeda kecil biar registry & inventory siap).
	task.spawn(function()
		task.wait(5)
		ctx.webPushOptions()
	end)
end
