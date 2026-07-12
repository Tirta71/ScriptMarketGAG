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

	-- daftar tipe pet unik dari INVENTORY buat dropdown (reuse kalau ada, atau bikin di sini)
	function ctx.getSummerPetTypes(selectedSet)
		if ctx.getInventoryPetTypes then return ctx.getInventoryPetTypes(selectedSet) end
		return {}
	end

	-- Ambil kandidat pet Tool dari Backpack yang lolos filter, urut berat menaik (feed teringan dulu).
	local function pickPetTool()
		local bp = LP:FindFirstChildOfClass("Backpack")
		if not bp then return nil end

		local petTypes = CFG.summerPetTypes or {}
		local hasTypeFilter = next(petTypes) ~= nil
		local minW = tonumber(CFG.summerMinWeight) or 0
		local maxW = tonumber(CFG.summerMaxWeight) or 0

		-- Safety: wajib ada minimal 1 filter (tipe atau berat) supaya tidak asal feed
		if not hasTypeFilter and minW <= 0 and maxW <= 0 then
			return nil, "atur filter pet/berat dulu (biar ga salah feed)"
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

	----------------------------------------------------------------- loop utama
	local function summerLoop()
		ctx.state.summerId = (ctx.state.summerId or 0) + 1
		local myId = ctx.state.summerId
		ctx.elevate()

		while CFG.summerEventEnabled and ctx.alive() and ctx.state.summerId == myId do
			local sam = getSamState()

			if sam and sam.RewardReady then
				-- Reward siap -> claim
				if CFG.summerAutoTP then teleportToSam(); task.wait(0.3) end
				setStatus("Summer: claim reward...")
				pcall(function() SamRE:FireServer("ClaimReward") end)
				task.wait(3)

			elseif sam and (sam.IsRunning or sam.SubmittedPet ~= nil) then
				-- Lagi dicerna -> tunggu
				local left = tonumber(sam.TimeLeft) or 0
				local mins = math.floor(left / 60)
				setStatus(("Summer: Sam sibuk (%d menit lagi)"):format(mins))
				task.wait(math.clamp(left, 5, 30))

			else
				-- Waiting -> pilih & submit pet
				local pick, why = pickPetTool()
				if not pick then
					setStatus("Summer: " .. tostring(why or "nunggu"))
					task.wait(5)
				else
					local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						if CFG.summerAutoTP then teleportToSam(); task.wait(0.3) end
						pcall(function() hum:EquipTool(pick.tool) end)
						task.wait(0.5)
						-- Pastikan pet yang mau di-feed benar-benar dipegang
						local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
						if held and held:GetAttribute("PET_UUID") == pick.tool:GetAttribute("PET_UUID") then
							setStatus(("Summer: submit %s (%.2f KG)"):format(pick.petType or "?", pick.w))
							pcall(function() SamRE:FireServer("SubmitHeldPet") end)
							task.wait(3)
						else
							setStatus("Summer: gagal pegang pet, coba lagi")
							task.wait(2)
						end
					else
						setStatus("Summer: humanoid tidak ada")
						task.wait(2)
					end
				end
			end
		end
	end

	function ctx.startSummerEvent() task.spawn(summerLoop) end
end
