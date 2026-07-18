--[[ registry.lua — opsi dropdown pet type & mutation. ]]
return function(ctx)
	local PetEggs   = ctx.deps.PetEggs
	local EnumToMut = ctx.deps.EnumToMut

	-- Daftar pet type unik (nama saja, tanpa egg) untuk filter trade.
	local PET_OPTIONS = {}
	do
		local seen = {}
		for _, egg in pairs(PetEggs) do
			local items = egg.RarityData and egg.RarityData.Items
			if items then
				for petName in pairs(items) do
					local s = tostring(petName)
					if not s:match("^Egg/") and not seen[s] then
						seen[s] = true
						PET_OPTIONS[#PET_OPTIONS + 1] = s
					end
				end
			end
		end
		table.sort(PET_OPTIONS)
	end

	local MUT_OPTIONS, seenMut = { "None" }, { None = true }
	for _, name in pairs(EnumToMut) do
		if name ~= "Normal" and not seenMut[name] then
			seenMut[name] = true
			MUT_OPTIONS[#MUT_OPTIONS + 1] = name
		end
	end
	table.sort(MUT_OPTIONS)

	-- Mutasi yang bisa dari mesin: MachineMutationTypes (base) + Level500MutationTypes (500 only).
	local MACHINE_MUT_OPTIONS = { "None" }
	do
		local ok, MutReg = pcall(function()
			return require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetMutationRegistry)
		end)
		local names, seen = {}, {}
		if ok and MutReg then
			for _, src in ipairs({ MutReg.MachineMutationTypes, MutReg.Level500MutationTypes }) do
				if type(src) == "table" then
					for name in pairs(src) do
						local n = tostring(name)
						if not seen[n] then seen[n] = true; names[#names + 1] = n end
					end
				end
			end
			-- Ice Golem-exclusive dari Mutation Machine (via passive Cold Gears): ada di
			-- PetMutationRegistry tapi bukan di MachineMutationTypes/Level500 -> tambah manual.
			for _, n in ipairs({ "ChristmasRally", "JollyDecorator", "MerryNursery", "GiantGolem" }) do
				local pmr = MutReg.PetMutationRegistry
				if type(pmr) == "table" and pmr[n] and not seen[n] then
					seen[n] = true; names[#names + 1] = n
				end
			end
		end
		if #names > 0 then
			table.sort(names)
			for _, n in ipairs(names) do MACHINE_MUT_OPTIONS[#MACHINE_MUT_OPTIONS + 1] = n end
		else
			MACHINE_MUT_OPTIONS = MUT_OPTIONS -- fallback: semua mutasi
		end
	end

	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
		return EnumToMut[code] or code
	end

	ctx.reg = {
		PET_OPTIONS = PET_OPTIONS,
		MUT_OPTIONS = MUT_OPTIONS,
		MACHINE_MUT_OPTIONS = MACHINE_MUT_OPTIONS,
		mutDisplay = mutDisplay,
	}
end
