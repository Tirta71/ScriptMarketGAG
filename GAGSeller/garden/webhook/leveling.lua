--[[ webhook/leveling.lua — Discord webhook untuk leveling. ]]
local HttpService = game:GetService("HttpService")
local sendWebhook = require(script.Parent.sender)

local levelingWebhook = {}

local function formatDuration(sec)
	if not sec or sec <= 0 then return "Unknown" end
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	local parts = {}
	if h > 0 then table.insert(parts, h .. "h") end
	if m > 0 then table.insert(parts, m .. "m") end
	if s > 0 or #parts == 0 then table.insert(parts, s .. "s") end
	return table.concat(parts, " ")
end

-- Webhook saat leveling di-enable
function levelingWebhook.sendEnabled(ctx, queueList)
	local CFG = ctx.CFG
	if not CFG.webhookLevelingEnabled or not CFG.webhookLevelingUrl or CFG.webhookLevelingUrl == "" then return end

	local petLines = {}
	local count = 0
	for _, p in ipairs(queueList) do
		count = count + 1
		table.insert(petLines, string.format("> - `%s` (Level %d)", p.type, p.level))
	end
	local petsText = #petLines > 0 and table.concat(petLines, "\n") or "> - Tidak ada pet di antrean"

	local payload = {
		embeds = {
			{
				title = "Growth • Leveling Enabled",
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = string.format("Leveling Queue Status (%d Pets)", count),
						value = petsText,
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	sendWebhook(CFG.webhookLevelingUrl, payload)
end

-- Webhook saat pet selesai leveling
function levelingWebhook.sendFinished(ctx, petType, mutation, age, durationSec, remainsQueue)
	local CFG = ctx.CFG
	if not CFG.webhookLevelingEnabled or not CFG.webhookLevelingUrl or CFG.webhookLevelingUrl == "" then return end

	local mutDisplay = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mutation) or mutation
	local durationStr = formatDuration(durationSec)

	local payload = {
		embeds = {
			{
				title = "Growth • Leveling",
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Final Age Reached",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Age: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Remains Queue: `%s`",
							petType,
							mutDisplay,
							tostring(age),
							durationStr,
							tostring(remainsQueue)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://i.imgur.com/H1Zh6V6.png"
				}
			}
		}
	}
	sendWebhook(CFG.webhookLevelingUrl, payload)
end

return levelingWebhook
