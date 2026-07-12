--[[ webhook/mutation.lua — Discord webhook untuk mutation. ]]
local HttpService = game:GetService("HttpService")
local sendWebhook = require(script.Parent.sender)

local mutationWebhook = {}

-- Webhook saat mutasi di-enable
function mutationWebhook.sendEnabled(ctx, targetTypes, targetMuts, targetAge)
	local CFG = ctx.CFG
	if not CFG.webhookMutationEnabled or not CFG.webhookMutationUrl or CFG.webhookMutationUrl == "" then return end

	local typesList = {}
	for k in pairs(targetTypes) do table.insert(typesList, "`" .. k .. "`") end
	local typesText = #typesList > 0 and table.concat(typesList, ", ") or "None"

	local mutsList = {}
	for k in pairs(targetMuts) do table.insert(mutsList, "`" .. k .. "`") end
	local mutsText = #mutsList > 0 and table.concat(mutsList, ", ") or "None"

	local payload = {
		embeds = {
			{
				title = "Mutation • Machine Enabled",
				color = 10181046, -- Purple (hex 0x9b59b6 -> 10181046)
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Mutation Settings",
						value = string.format(
							"> Target Types: %s\n" ..
							"> Keep Mutations: %s\n" ..
							"> Target Age: `%s`",
							typesText,
							mutsText,
							tostring(targetAge)
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
	sendWebhook(CFG.webhookMutationUrl, payload)
end

-- Webhook saat pet disubmit ke mesin
function mutationWebhook.sendSubmitted(ctx, petType, level)
	local CFG = ctx.CFG
	if not CFG.webhookMutationEnabled or not CFG.webhookMutationUrl or CFG.webhookMutationUrl == "" then return end

	local payload = {
		embeds = {
			{
				title = "Mutation • Pet Submitted",
				color = 10181046, -- Purple
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Machine Status",
						value = string.format(
							"> Submitted Pet: `%s`\n" ..
							"> Age: `%s` (Target: `%s`)",
							petType,
							tostring(level),
							tostring(CFG.mutationTargetAge)
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
	sendWebhook(CFG.webhookMutationUrl, payload)
end

-- Webhook saat pet diklaim (hasil mutasi)
function mutationWebhook.sendClaimed(ctx, petType, outcomeMutation, isMatched)
	local CFG = ctx.CFG
	if not CFG.webhookMutationEnabled or not CFG.webhookMutationUrl or CFG.webhookMutationUrl == "" then return end

	local mutDisplay = ctx.reg.mutDisplay and ctx.reg.mutDisplay(outcomeMutation) or outcomeMutation
	local statusText = isMatched and "✅ TARGET MUTATION FOUND (Bot Stopped)" or "❌ Non-target Mutation (Continuing)"

	local payload = {
		embeds = {
			{
				title = "Mutation • Pet Claimed",
				color = isMatched and 3066993 or 10181046, -- Green or Purple
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Claim Outcome",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Outcome Mutation: `%s`\n" ..
							"> Status: **%s**",
							petType,
							mutDisplay,
							statusText
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
	sendWebhook(CFG.webhookMutationUrl, payload)
end

return mutationWebhook
