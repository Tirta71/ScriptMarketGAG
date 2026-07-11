--[[ app.lua — init akhir garden: default tab Inventory + auto-resume automation. ]]
return function(ctx)
	local CFG = ctx.CFG
	local pages = ctx.ui.pages
	local tabBtns = ctx.ui.tabBtns
	local C = ctx.C

	-- default tab = Inventory
	local function selectTab(name)
		for n, p in pairs(pages) do p.Visible = (n == name) end
		for n, b in pairs(tabBtns) do
			b.btn.BackgroundTransparency = (n == name) and 0.85 or 1
			b.btn.TextColor3 = (n == name) and C.txt or C.sub
			b.line.Visible = (n == name)
		end
	end
	selectTab("Inventory")

	ctx.log("AllegiaanHub Garden dimuat.")
	ctx.setStatus("idle")

	-- auto-resume kalau sebelumnya aktif
	if CFG.tradeEnabled then
		task.wait(1.5)
		ctx.state.completed = 0
		ctx.startTrade()
		ctx.refreshTradeStatus()
		ctx.log("Auto-resume: automation trade ON.")
	end
end
