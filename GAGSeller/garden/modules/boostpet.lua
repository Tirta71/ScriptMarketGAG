--[[ boostpet.lua — Automation Boost Pet.
     Pilih pet + item boost (Pet Toy). Otomatis apply boost ke pet;
     re-apply pas boost habis (berdasar durasi item, atribut "p" = boostTime detik).
     Mekanik: pegang Tool bertag "PetBoost" lalu PetBoostService:FireServer("ApplyBoost", petUuid). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetBoostService = RS:WaitForChild("GameEvents"):WaitForChild("PetBoostService")
	local function setStatus(s) ctx.setStatus(s) end

	-- "Medium Pet Toy x42[Passive Boost]" -> "Medium Pet Toy"
	local function baseName(n) return (tostring(n):gsub("%s*x%d+.*$", "")) end

	-- Daftar item boost (tag PetBoost) di backpack, dedupe per base name -> dropdown.
	function ctx.getBoostItemOptions(selectedSet)
		local out, seen = {}, {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if not bp then return out end
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t:HasTag("PetBoost") then
				local bn = baseName(t.Name)
				if not seen[bn] then
					seen[bn] = true
					local dur = t:GetAttribute("p")
					out[#out + 1] = { value = bn, display = dur and (bn .. " (" .. tostring(dur) .. "s)") or bn }
				end
			end
		end
		table.sort(out, function(a, b)
			local sa = selectedSet and selectedSet[a.value] and 1 or 0
			local sb = selectedSet and selectedSet[b.value] and 1 or 0
			if sa ~= sb then return sa > sb end
			return a.display < b.display
		end)
		return out
	end

	-- Cari 1 tool boost yang dipilih (Character dulu = yang lagi dipegang, lalu Backpack).
	local function findBoostTool()
		local sel = CFG.boostItemNames or {}
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then
				for _, t in ipairs(src:GetChildren()) do
					if t:IsA("Tool") and t:HasTag("PetBoost") and sel[baseName(t.Name)] then
						return t
					end
				end
			end
		end
		return nil
	end

	local nextApply = {} -- uuid -> os.clock() kapan boleh re-apply

	local function boostLoop()
		ctx.state.boostId = (ctx.state.boostId or 0) + 1
		local myId = ctx.state.boostId
		ctx.elevate()

		while CFG.boostEnabled and ctx.alive() and ctx.state.boostId == myId do
			local pets = CFG.boostPetUuids or {}
			if not next(pets) then
				setStatus("Boost: pilih pet dulu")
				task.wait(3)
			else
				for uuid in pairs(pets) do
					if not CFG.boostEnabled or ctx.state.boostId ~= myId then break end
					if os.clock() >= (nextApply[uuid] or 0) then
						local tool = findBoostTool()
						if not tool then
							setStatus("Boost: item habis / belum dipilih")
						else
							local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
							if hum then
								-- Pastikan item boost BENAR-BENAR dipegang sebelum ApplyBoost (retry equip).
								local held
								for _ = 1, 3 do
									pcall(function() hum:EquipTool(tool) end)
									task.wait(0.35)
									held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
									if held and held:HasTag("PetBoost") then break end
									tool = findBoostTool() -- tool bisa berubah instance
									if not tool then break end
								end
								if held and held:HasTag("PetBoost") then
									pcall(function() PetBoostService:FireServer("ApplyBoost", uuid) end)
									local dur = tonumber(held:GetAttribute("p")) or 300
									nextApply[uuid] = os.clock() + dur
									setStatus(("Boost: %s -> #%s (re-apply %ds)"):format(baseName(held.Name), uuid:sub(2, 5), math.floor(dur)))
									task.wait(0.4)
								else
									-- gagal pegang item -> JANGAN majuin timer, coba lagi loop berikutnya
									setStatus("Boost: gagal pegang item, retry...")
									task.wait(0.5)
								end
							end
						end
					end
				end
				task.wait(2)
			end
		end
	end

	function ctx.startBoostPet() task.spawn(boostLoop) end
end
