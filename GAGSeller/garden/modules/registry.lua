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

	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
		return EnumToMut[code] or code
	end

	ctx.reg = { PET_OPTIONS = PET_OPTIONS, MUT_OPTIONS = MUT_OPTIONS, mutDisplay = mutDisplay }
end
