--[[ registry.lua — bangun opsi dropdown dari data game.
     Mengisi: ctx.reg = { comboKey, mutDisplay, PET_OPTIONS, MUT_OPTIONS, SKIN_OPTIONS } ]]
return function(ctx)
	local PetEggs   = ctx.deps.PetEggs
	local EnumToMut = ctx.deps.EnumToMut
	local SkinsReg  = ctx.deps.SkinsReg

	-- opsi dropdown = kombinasi "Pet - Egg"
	local function comboKey(petType, egg)
		return tostring(petType) .. " - " .. tostring(egg)
	end

	----------------------------------------------------------------- PET_OPTIONS
	local PET_OPTIONS = {}
	do
		local seen = {}
		for eggName, egg in pairs(PetEggs) do
			local items = egg.RarityData and egg.RarityData.Items
			if items then
				for petName in pairs(items) do
					if not tostring(petName):match("^Egg/") then
						local nameStr = tostring(petName)
						if not seen[nameStr] then
							seen[nameStr] = true
							PET_OPTIONS[#PET_OPTIONS + 1] = nameStr
						end
					end
				end
			end
		end
		table.sort(PET_OPTIONS)
	end

	----------------------------------------------------------------- MUT_OPTIONS
	local MUT_OPTIONS, seenMut = { "None" }, { None = true }
	for _, name in pairs(EnumToMut) do
		if name ~= "Normal" and not seenMut[name] then
			seenMut[name] = true
			MUT_OPTIONS[#MUT_OPTIONS + 1] = name
		end
	end
	table.sort(MUT_OPTIONS)

	----------------------------------------------------------------- SKIN_OPTIONS
	local SKIN_OPTIONS = {}
	for name, data in pairs(SkinsReg) do
		SKIN_OPTIONS[#SKIN_OPTIONS + 1] = { name = name, display = data.DisplayName or name }
	end
	table.sort(SKIN_OPTIONS, function(a, b) return a.display < b.display end)

	----------------------------------------------------------------- mutDisplay
	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then
			return "None"
		end
		return EnumToMut[code] or code
	end

	ctx.reg = {
		comboKey     = comboKey,
		mutDisplay   = mutDisplay,
		PET_OPTIONS  = PET_OPTIONS,
		MUT_OPTIONS  = MUT_OPTIONS,
		SKIN_OPTIONS = SKIN_OPTIONS,
	}
end
