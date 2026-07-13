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
	ctx.readSamLoop = ctx.readSamLoop or readLoop

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

		if not readLoop().active then return end

		-- Kerjakan claim + submit dengan retry sampai Sam kembali "Working" (pet ke-submit).
		-- Error permanen (filter belum diset / tidak ada pet cocok) -> stop loop.
		-- Error transien (gagal pegang pet dll) -> coba lagi. Ada deadline biar ga nyangkut.
		local deadline = os.clock() + 90
		local submitTries = 0
		local done = false

		while readLoop().active and os.clock() < deadline and not done do
			local sam = getSam()
			if not sam then
				setStatus("SamLoop: data Sam belum siap...")
				task.wait(2)
			elseif sam.RewardReady then
				setStatus("SamLoop: claim reward...")
				if ctx.samClaimOnce then ctx.samClaimOnce() end
				task.wait(2)
			elseif sam.IsRunning or sam.SubmittedPet ~= nil then
				-- Sudah Working (pet ke-submit) -> selesai, balik hop
				done = true
			else
				-- Waiting -> submit pet
				submitTries = submitTries + 1
				setStatus(("SamLoop: submit pet (coba %d)..."):format(submitTries))
				local ok, why = false, "no fn"
				if ctx.samSubmitOnce then ok, why = ctx.samSubmitOnce() end
				if ok then
					task.wait(2) -- biar state update jadi Working
				else
					local w = tostring(why or "")
					if w:find("filter") or w:find("cocok") then
						setStatus("SamLoop STOP: " .. w .. ". Atur filter pet di tab Event garden.")
						local st = readLoop(); st.active = false; writeLoop(st)
						return
					end
					if submitTries >= 5 then
						setStatus("SamLoop STOP: submit gagal terus (" .. w .. ")")
						local st = readLoop(); st.active = false; writeLoop(st)
						return
					end
					task.wait(2) -- transien, coba lagi
				end
			end
		end

		-- Balik ke Trade World buat hop lagi
		setStatus("SamLoop: balik ke Trade World...")
		task.wait(1)
		if readLoop().active then backToTradeWorld() end
	end

	-- Start dari garden: aktifkan loop lalu jalankan gardenStep (claim/submit -> TP Trade World)
	function ctx.startSamLoopGarden()
		local st = readLoop(); st.active = true; writeLoop(st)
		task.spawn(gardenStep)
	end
	function ctx.stopSamLoopGarden()
		local st = readLoop(); st.active = false; writeLoop(st)
		setStatus("SamLoop: dimatikan")
	end
	function ctx.samLoopActive() return readLoop().active end

	-- Auto-run kalau loop aktif (dipanggil saat hub load di garden)
	if readLoop().active then task.spawn(gardenStep) end
end
