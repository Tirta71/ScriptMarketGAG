--[[ app.lua — inisialisasi akhir: default page, supervisor auto-claim, auto-resume. ]]
return function(ctx)
	local CFG     = ctx.CFG
	local pages   = ctx.ui.pages
	local tabBtns = ctx.ui.tabBtns
	local C       = ctx.C
	local function log(msg) ctx.log(msg) end

	------------------------------------------------------------------ Default page
	pages["Sell"].Visible = true
	tabBtns["Sell"].btn.BackgroundTransparency = 0.9
	tabBtns["Sell"].btn.TextColor3 = C.txt
	tabBtns["Sell"].line.Visible = true

	log("AllegiaanHub GAG Seller v1.2.5 dimuat.")
	ctx.renderInventory()

	------------------------------------------------------------------ Auto Claim Supervisor Loop
	task.spawn(function()
		ctx.elevate()
		local lastState
		while ctx.alive() do
			local delay = 3
			local ok, err = pcall(function()
				if CFG.autoClaim then
					local owns, data, boothName = ctx.ownsBooth()
					if owns then
						if lastState ~= "own" then log("Booth aman: " .. tostring(boothName)); lastState = "own" end
						ctx.autoSwitchBoothPortal()
						delay = 6
					else
						if lastState ~= "hunt" then log("Booth hilang, mencari terdekat..."); lastState = "hunt" end
						ctx.tryClaimNearest()
						delay = 5
					end
				else
					lastState = nil
					delay = 1
				end
			end)
			if not ok then log("claim-loop err: " .. tostring(err)) end
			task.wait(delay)
		end
	end)

	------------------------------------------------------------------ Auto Resume
	if CFG.autoSell then
		task.wait(1.5)
		ctx.state.running = true
		if ctx.ui.rAutoToggle then ctx.ui.rAutoToggle() end
		task.spawn(ctx.mainLoop)
		log("Auto-resume: loop dinyalakan.")
	end
end
