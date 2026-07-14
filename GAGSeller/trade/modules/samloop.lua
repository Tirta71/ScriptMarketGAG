--[[ samloop.lua (Trade World) — Full-loop Sam The Clam via server-hop.
     Hop server Trade World nurunin timer Sam. Coordinator:
       - TimeLeft > target  -> queue hub + hop server Trade World (ulang di server baru)
       - TimeLeft <= target / ready -> queue hub + teleport ke Garden (di sana claim+submit)
     State disimpan di file (dibaca app garden juga). queue_on_teleport bikin hub
     auto-jalan lagi tiap landing. Loop auto-resume kalau state aktif. ]]
return function(ctx)
	local TeleportService = game:GetService("TeleportService")
	local HttpService = ctx.Services.HttpService
	local DataService = ctx.deps.DataService
	local LP = ctx.LP
	local function setStatus(s) if ctx.setStatus then ctx.setStatus(s) end end

	local TRADE_PLACE  = 129954712878723
	local GARDEN_PLACE = 126884695634066
	local LOOP_FILE = "AllegiaanHub_samloop.json"
	local ROUTER = "loadstring(game:HttpGet('https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/main/GAGSeller/init.lua'))()"
	local MAX_HOPS = 60 -- pengaman biar ga hop selamanya

	----------------------------------------------------------------- state file
	local function readLoop()
		if type(isfile) == "function" and isfile(LOOP_FILE) then
			local ok, t = pcall(function() return HttpService:JSONDecode(readfile(LOOP_FILE)) end)
			if ok and type(t) == "table" then return t end
		end
		return { active = false, target = 0, hops = 0 }
	end
	local function writeLoop(t) pcall(function() writefile(LOOP_FILE, HttpService:JSONEncode(t)) end) end
	ctx.readSamLoop = readLoop
	ctx.writeSamLoop = writeLoop

	local function getSam()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d and d.SamTheClam or nil
	end

	-- Ringkasan buat GUI
	function ctx.getSamSummary()
		local sam = getSam()
		local st = readLoop()
		if not sam then return { state = "Unknown", timer = "-", hops = st.hops or 0 } end
		local state, timer
		if sam.RewardReady then
			state, timer = "READY", "Siap diklaim"
		elseif sam.IsRunning or sam.SubmittedPet ~= nil then
			local left = math.max(0, math.floor(tonumber(sam.TimeLeft) or 0))
			state, timer = "WORKING", ("%02d:%02d"):format(math.floor(left / 60), left % 60)
		else
			state, timer = "IDLE", "Bisa submit"
		end
		return {
			state = state, timer = timer, hops = st.hops or 0,
			submitted = sam.SubmittedPet and sam.SubmittedPet.PetType or "-",
			target = st.target or 0, active = st.active or false,
		}
	end

	----------------------------------------------------------------- teleport
	local function queueHub()
		local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
		if q then pcall(function() q(ROUTER) end) end
	end

	-- Teleport dengan retry otomatis (nutup celah flood/gagal teleport).
	-- Target disimpan di _G biar handler tunggal (per-sesi) tau harus retry ke mana.
	local function doTeleport(placeId)
		_G.__AH_lastTarget = placeId
		queueHub()
		pcall(function() TeleportService:Teleport(placeId, LP) end)
	end
	if not _G.__AH_tpHandler then
		_G.__AH_tpHandler = true
		pcall(function()
			TeleportService.TeleportInitFailed:Connect(function(_, result, _, _)
				if not readLoop().active or not _G.__AH_lastTarget then return end
				local wait = (result == Enum.TeleportResult.Flooded) and 20 or 6
				setStatus(("SamLoop: teleport gagal (%s), retry %ds..."):format(tostring(result), wait))
				task.wait(wait)
				if readLoop().active and _G.__AH_lastTarget then doTeleport(_G.__AH_lastTarget) end
			end)
		end)
	end

	local function coordinator()
		-- Guard single-instance lintas re-load (auto-exec + queue_on_teleport bisa load 2x).
		-- Coordinator terbaru menang; duplikat lama berhenti.
		_G.__AH_samloopGen = (_G.__AH_samloopGen or 0) + 1
		local myGen = _G.__AH_samloopGen
		ctx.state.samLoopId = (ctx.state.samLoopId or 0) + 1
		local myId = ctx.state.samLoopId
		ctx.elevate()
		task.wait(2) -- tunggu data kebaca

		while ctx.alive() and ctx.state.samLoopId == myId and _G.__AH_samloopGen == myGen do
			local st = readLoop()
			if not st.active then break end

			local sam = getSam()
			if not sam then
				setStatus("SamLoop: data Sam belum siap...")
				task.wait(2)
			else
				local tl = tonumber(sam.TimeLeft) or 0
				local ready = sam.RewardReady or tl <= (tonumber(st.target) or 0)

				-- jendela stop: kasih waktu user matiin toggle sebelum pindah
				local goGarden = ready
				local reason = ready and "timer siap -> ke Garden"
					or (("hop #%d (sisa %ds)"):format((st.hops or 0) + 1, math.floor(tl)))
				local win = math.max(3, math.floor(tonumber(readLoop().hopDelay) or 10))
				for i = win, 1, -1 do
					if not readLoop().active or ctx.state.samLoopId ~= myId or _G.__AH_samloopGen ~= myGen then return end
					setStatus(("SamLoop: %s | pindah %ds (matikan toggle buat stop)"):format(reason, i))
					task.wait(1)
				end
				if not readLoop().active or ctx.state.samLoopId ~= myId or _G.__AH_samloopGen ~= myGen then return end

				if (st.hops or 0) >= MAX_HOPS and not goGarden then
					setStatus("SamLoop: batas hop tercapai, stop.")
					st.active = false; writeLoop(st); return
				end

				if goGarden then
					doTeleport(GARDEN_PLACE)
				else
					st.hops = (st.hops or 0) + 1; writeLoop(st)
					doTeleport(TRADE_PLACE)
				end
				return -- script mati setelah teleport; lanjut di server baru
			end
		end
		setStatus("SamLoop: berhenti")
	end

	function ctx.startSamLoop()
		local st = readLoop(); st.active = true; st.hops = 0; writeLoop(st)
		task.spawn(coordinator)
	end
	function ctx.stopSamLoop()
		local st = readLoop(); st.active = false; writeLoop(st)
		ctx.state.samLoopId = (ctx.state.samLoopId or 0) + 1
		setStatus("SamLoop: dimatikan")
	end
	function ctx.setSamLoopTarget(mins)
		local st = readLoop(); st.target = math.max(0, (tonumber(mins) or 0) * 60); writeLoop(st)
	end
	function ctx.setSamLoopHopDelay(secs)
		local st = readLoop(); st.hopDelay = math.max(3, math.floor(tonumber(secs) or 10)); writeLoop(st)
	end
	function ctx.samLoopActive() return readLoop().active end

	-- Auto-resume setelah landing dari teleport
	if readLoop().active then task.spawn(coordinator) end
end
