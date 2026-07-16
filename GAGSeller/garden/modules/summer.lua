--[[ summer.lua — Automation Summer Event: Sam The Clam.
     Flow (state dari DataService:GetData().SamTheClam):
       RewardReady == true                      -> ClaimReward
       IsRunning / SubmittedPet ~= nil          -> Working (tunggu timer ~1 jam)
       selain itu (Waiting)                     -> pegang pet (Humanoid:EquipTool) lalu SubmitHeldPet

     Pemilihan pet (aman, wajib eksplisit):
       - Tolak summer pool (Pelican/Manta Ray) — Sam nolak.
       - Filter tipe pet (CFG.summerPetTypes), berat min/max (CFG.summerMinWeight/Max),
         dan opsi ikut-sertakan favorite (CFG.summerAllowFavorite).
       - Kalau tidak ada filter tipe & berat yang diatur -> TIDAK submit (biar ga salah feed). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local SamRE = RS:WaitForChild("GameEvents"):WaitForChild("SamTheClamService_RE")
	local Favorite_Item    = RS.GameEvents:FindFirstChild("Favorite_Item")
	local Favorite_Item_BE = RS.GameEvents:FindFirstChild("Favorite_Item_BE")

	-- Pet summer yang ditolak Sam (ambil dinamis, fallback statis)
	local rejectPool = { Pelican = true, ["Manta Ray"] = true }
	pcall(function()
		local SamData = require(RS.Data.SamTheClamData)
		if SamData and SamData.SUMMER_PET_POOL then
			rejectPool = {}
			for _, v in ipairs(SamData.SUMMER_PET_POOL) do rejectPool[v.PetName] = true end
		end
	end)

	----------------------------------------------------------------- helpers
	-- Cari RootPart Sam The Clam & TP karakter ke dekatnya (biar remote lolos cek jarak server).
	local function teleportToSam()
		local sam = workspace:FindFirstChild("Interaction")
		sam = sam and sam:FindFirstChild("UpdateItems")
		sam = sam and sam:FindFirstChild("Sam The Clam")
		local mdl = sam and sam:FindFirstChild("Sam the Clam")
		local root = mdl and (mdl:FindFirstChild("RootPart") or mdl.PrimaryPart or mdl:FindFirstChildWhichIsA("BasePart"))
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if root and hrp then
			-- berdiri ~8 stud di depan Sam
			pcall(function() hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 3, -8)) end)
			return true
		end
		return false
	end

	local function getSamState()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return nil end
		return d.SamTheClam
	end

	-- Ringkasan status Sam untuk GUI (timer live).
	function ctx.getSamSummary()
		local sam = getSamState()
		if not sam then return { state = "Unknown", timer = "-", reward = "-" } end
		local state, timer
		if sam.RewardReady then
			state, timer = "READY", "Siap diklaim!"
		elseif sam.IsRunning or sam.SubmittedPet ~= nil then
			local left = math.max(0, math.floor(tonumber(sam.TimeLeft) or 0))
			timer = ("%02d:%02d"):format(math.floor(left / 60), left % 60)
			state = "WORKING"
		else
			state, timer = "IDLE", "Bisa submit pet"
		end
		local reward = "-"
		if type(sam.Reward) == "table" then
			reward = ("%s x%s"):format(tostring(sam.Reward.Value or "?"), tostring(sam.Reward.Quantity or "?"))
		end
		local submitted = sam.SubmittedPet and sam.SubmittedPet.PetType or "-"
		return { state = state, timer = timer, reward = reward, submitted = submitted }
	end

	-- daftar tipe pet unik dari INVENTORY buat dropdown.
	-- Sekaligus auto-prune: tipe yang sudah TIDAK ADA di inventory dibuang dari pilihan
	-- (biar ga nyangkut kepilih padahal pet-nya habis).
	function ctx.getSummerPetTypes(selectedSet)
		local opts = ctx.getInventoryPetTypes and ctx.getInventoryPetTypes(selectedSet) or {}
		-- PENTING: cuma prune kalau data inventory beneran ke-load (opts tidak kosong).
		-- Kalau kosong bisa jadi data belum siap -> jangan buang pilihan valid.
		if #opts > 0 then
			local avail = {}
			for _, o in ipairs(opts) do avail[o.value] = true end
			local changed = false
			for t in pairs(CFG.summerPetTypes or {}) do
				if not avail[t] then CFG.summerPetTypes[t] = nil; changed = true end
			end
			if changed and ctx.persistState then ctx.persistState() end
		end
		return opts
	end

	-- Ambil kandidat pet Tool dari Backpack yang lolos filter, urut berat menaik (feed teringan dulu).
	local function pickPetTool()
		local bp = LP:FindFirstChildOfClass("Backpack")
		if not bp then return nil end

		local petTypes = CFG.summerPetTypes or {}
		local hasTypeFilter = next(petTypes) ~= nil
		local minW = tonumber(CFG.summerMinWeight) or 0
		local maxW = tonumber(CFG.summerMaxWeight) or 0

		-- Safety: WAJIB pilih tipe pet (berat cuma nyaring di dalam tipe).
		-- Kalau tipe habis/kosong -> stop, jangan feed pet lain sembarangan.
		if not hasTypeFilter then
			return nil, "pilih tipe pet di filter dulu (biar ga salah feed)"
		end

		local best
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("PET_UUID") then
				local petType = t:GetAttribute("f")           -- ItemName = tipe pet
				local fav     = t:GetAttribute("d") == true    -- Favorite
				local weight  = tonumber(tostring(t.Name):match("%[([%d%.]+) KG%]"))

				local pass = true
				if not petType or rejectPool[petType] then pass = false end
				if pass and hasTypeFilter and not petTypes[petType] then pass = false end
				if pass and fav and not CFG.summerAllowFavorite then pass = false end
				if pass and weight then
					if minW > 0 and weight < minW then pass = false end
					if maxW > 0 and weight > maxW then pass = false end
				end

				if pass then
					local w = weight or 0
					if not best or w < best.w then best = { tool = t, w = w, petType = petType } end
				end
			end
		end

		if not best then return nil, "tidak ada pet cocok filter" end
		return best
	end

	----------------------------------------------------------------- aksi tunggal (reusable)
	-- Claim reward (TP ke Sam dulu). return true kalau di-fire.
	function ctx.samClaimOnce()
		teleportToSam(); task.wait(0.3)
		setStatus("Summer: claim reward...")
		pcall(function() SamRE:FireServer("ClaimReward") end)
		task.wait(3)
		return true
	end

	-- Pilih pet -> TP -> pegang -> unfav (bila perlu) -> SubmitHeldPet.
	-- return true kalau berhasil submit, false + alasan kalau tidak.
	function ctx.samSubmitOnce()
		local pick, why = pickPetTool()
		if not pick then return false, why or "no pet" end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return false, "no humanoid" end
		teleportToSam(); task.wait(0.3)
		pcall(function() hum:EquipTool(pick.tool) end)
		task.wait(0.5)
		local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
		if not (held and held:GetAttribute("PET_UUID") == pick.tool:GetAttribute("PET_UUID")) then
			return false, "gagal pegang pet"
		end
		if held:GetAttribute("d") == true and Favorite_Item then
			setStatus(("Summer: unfav %s dulu..."):format(pick.petType or "?"))
			pcall(function() Favorite_Item:FireServer(held) end)
			if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(held) end) end
			task.wait(0.4)
		end
		setStatus(("Summer: submit %s (%.2f KG)"):format(pick.petType or "?", pick.w))
		pcall(function() SamRE:FireServer("SubmitHeldPet") end)
		task.wait(3)
		return true
	end

	----------------------------------------------------------------- loop utama
	local function summerLoop()
		ctx.state.summerId = (ctx.state.summerId or 0) + 1
		local myId = ctx.state.summerId
		ctx.elevate()

		while CFG.summerEventEnabled and ctx.alive() and ctx.state.summerId == myId do
			local sam = getSamState()

			if sam and sam.RewardReady then
				ctx.samClaimOnce()
			elseif sam and (sam.IsRunning or sam.SubmittedPet ~= nil) then
				local left = tonumber(sam.TimeLeft) or 0
				setStatus(("Summer: Sam sibuk (%d menit lagi)"):format(math.floor(left / 60)))
				task.wait(math.clamp(left, 5, 30))
			else
				local ok, why = ctx.samSubmitOnce()
				if ok then
					-- Konfirmasi submit beneran kebaca server sebelum lanjut.
					-- Anti double-feed: kalau replikasi telat, JANGAN submit pet kedua.
					local confirmed = false
					for _ = 1, 8 do
						local s2 = getSamState()
						if s2 and (s2.IsRunning or s2.SubmittedPet ~= nil or s2.RewardReady) then confirmed = true; break end
						task.wait(1)
					end
					if not confirmed then
						setStatus("Summer: submit belum kebaca, tunggu...")
						task.wait(2)
					end
				else
					setStatus("Summer: " .. tostring(why)); task.wait(5)
				end
			end
		end
	end

	function ctx.startSummerEvent() task.spawn(summerLoop) end
end
