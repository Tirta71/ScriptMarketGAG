--[[ webhook/elephant.lua — Discord webhook untuk Automation Elephant.
     Di-load via HttpGet loader; sender diambil dari ctx.sendWebhook.
     Dikirim saat auto elephant di-enable: statistik boosting per tipe + bracket berat. ]]
local elephantWebhook = {}

-- Label bracket berat 0.1 KG, mis. 6.05 -> "6.01-6.09 KG"
local function bracketLabel(w)
	local lo = math.floor(w * 10) / 10
	return string.format("%.2f-%.2f KG", lo + 0.01, lo + 0.09)
end

function elephantWebhook.sendEnabled(ctx)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local DataService = ctx.deps.DataService
	local ok, d = pcall(function() return DataService:GetData() end)
	if not ok or not d or not d.PetsData then return end
	local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

	local targetTypes = CFG.elephantPetTypes or {}
	local targetW = CFG.elephantTargetWeight or 5.5
	local teamSet = CFG.elephantTeamUuids or {}

	-- Teams: hitung per display (mutasi + tipe), mis. "2 Rainbow Dilophosaurus"
	local teamCount, teamOrder = {}, {}
	for uuid in pairs(teamSet) do
		local v = inv[uuid]
		if v then
			local pt = v.PetType or "?"
			local mut = v.PetData and v.PetData.MutationType
			local mutName = (mut and ctx.reg and ctx.reg.mutDisplay) and ctx.reg.mutDisplay(mut) or mut
			local disp = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " " .. pt) or pt
			if not teamCount[disp] then teamCount[disp] = 0; teamOrder[#teamOrder + 1] = disp end
			teamCount[disp] = teamCount[disp] + 1
		end
	end
	table.sort(teamOrder)
	local teamParts = {}
	for _, disp in ipairs(teamOrder) do teamParts[#teamParts + 1] = teamCount[disp] .. " " .. disp end
	local teamText = #teamParts > 0 and table.concat(teamParts, ", ") or "None"

	-- Target types
	local typesList = {}
	for t in pairs(targetTypes) do typesList[#typesList + 1] = t end
	table.sort(typesList)
	local typesText = #typesList > 0 and table.concat(typesList, ", ") or "None"

	-- Boosting stats = pet yang SUDAH SELESAI (>= target/max KG), dikelompokkan per bracket.
	-- Remains Queue = pet target yang belum max.
	local byType = {}
	local maxCount, queueCount = 0, 0
	for _, v in pairs(inv) do
		local pt = v.PetType
		if pt and targetTypes[pt] then
			local w = (v.PetData or {}).BaseWeight or 0
			if w >= targetW then
				maxCount = maxCount + 1
				local bt = byType[pt]
				if not bt then bt = { total = 0, brackets = {}, order = {} }; byType[pt] = bt end
				bt.total = bt.total + 1
				local lbl = bracketLabel(w)
				if not bt.brackets[lbl] then bt.brackets[lbl] = 0; bt.order[#bt.order + 1] = lbl end
				bt.brackets[lbl] = bt.brackets[lbl] + 1
			else
				queueCount = queueCount + 1
			end
		end
	end

	local typeKeys = {}
	for t in pairs(byType) do typeKeys[#typeKeys + 1] = t end
	table.sort(typeKeys)
	local boostLines = {}
	for _, t in ipairs(typeKeys) do
		local bt = byType[t]
		boostLines[#boostLines + 1] = string.format("**%s:** %d", t, bt.total)
		table.sort(bt.order)
		for _, lbl in ipairs(bt.order) do
			boostLines[#boostLines + 1] = string.format("• %s (%s): %d", t, lbl, bt.brackets[lbl])
		end
	end
	local boostText = #boostLines > 0 and table.concat(boostLines, "\n") or "Tidak ada pet dalam antrean"

	local desc = string.format(
		"**Profile :**\n> \240\159\145\164 Username : ||%s||\n\n" ..
		"**Teams :**\n> Elephant Team: `%s`\n\n" ..
		"**Target Types :**\n> `%s`\n\n" ..
		"**Boosting Statistics :**\n%s\n\n" ..
		"**Pets at Max KG :** `%d`\n" ..
		"**Remains Queue :** `%d`",
		ctx.LP.Name, teamText, typesText, boostText, maxCount, queueCount)
	if #desc > 4000 then desc = desc:sub(1, 3980) .. "\n... (truncated)" end

	local payload = {
		embeds = {
			{
				title = "\240\159\147\138 Growth \226\128\162 Elephant Statistics",
				color = 3066993,
				description = desc,
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return elephantWebhook
