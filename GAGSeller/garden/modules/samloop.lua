--[[ samloop.lua (Garden) — sisi garden dari full-loop Sam The Clam.
     Dijalankan otomatis saat hub load DAN state loop aktif DAN kita di garden.
     Langkah: claim reward (kalau ready) -> submit pet baru -> teleport balik Trade World.
     Pakai ctx.samClaimOnce / ctx.samSubmitOnce dari summer.lua. ]]
return function(ctx)
	local TeleportService = game:GetService("TeleportService")
	local HttpService = ctx.Services.HttpService
	local DataService = ctx.deps.DataService
	local LP = ctx.LP
	local function setStatus(s) if ctx.setStatus then ctx.setStatus(s) end end

	local TRADE_PLACE = 129954712878723
	local LOOP_FILE = "AllegiaanHub_samloop.json"
	local ROUTER = "loadstring(game:HttpGet('https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/main/GAGSeller/init.lua'))()"

	local function readLoop()
		if type(isfile) == "function" and isfile(LOOP_FILE) then
			local ok, t = pcall(function() return HttpService:JSONDecode(readfile(LOOP_FILE)) end)
			if ok and type(t) == "table" then return t end
		end
		return { active = false }
	end
	local function writeLoop(t) pcall(function() writefile(LOOP_FILE, HttpService:JSONEncode(t)) end) end

	local function getSam()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d and d.SamTheClam or nil
	end

	local function queueHub()
		local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
		if q then pcall(function() q(ROUTER) end) end
	end

	local function backToTradeWorld()
		local st = readLoop(); st.hops = 0; writeLoop(st)
		queueHub()
		pcall(function() TeleportService:Teleport(TRADE_PLACE, LP) end)
	end

	local function gardenStep()
		ctx.elevate()
		task.wait(3) -- tunggu summer.lua & data siap

		local st = readLoop()
		if not st.active then return end

		-- 1. Claim kalau reward siap
		local sam = getSam()
		local tries = 0
		while sam and sam.RewardReady and tries < 3 do
			setStatus("SamLoop: claim reward di garden...")
			if ctx.samClaimOnce then ctx.samClaimOnce() end
			task.wait(2); sam = getSam(); tries = tries + 1
		end

		-- 2. Submit pet baru kalau Sam kosong (Waiting)
		sam = getSam()
		if sam and not sam.RewardReady and not (sam.IsRunning or sam.SubmittedPet ~= nil) then
			setStatus("SamLoop: submit pet baru...")
			local ok, why = false, "no fn"
			if ctx.samSubmitOnce then ok, why = ctx.samSubmitOnce() end
			if not ok then
				-- gagal (mis. filter belum diatur) -> stop loop biar ga muter kosong
				setStatus("SamLoop STOP: gagal submit (" .. tostring(why) .. "). Atur filter pet di tab Event garden.")
				st.active = false; writeLoop(st)
				return
			end
			task.wait(2)
		end

		-- 3. Balik ke Trade World buat hop lagi
		setStatus("SamLoop: balik ke Trade World...")
		task.wait(1)
		if readLoop().active then backToTradeWorld() end
	end

	-- Auto-run kalau loop aktif (dipanggil saat hub load di garden)
	if readLoop().active then task.spawn(gardenStep) end
end
