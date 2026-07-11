--[[ window.lua — jendela utama garden: sidebar 8 tab, player card, status, log. ]]
return function(ctx)
	local Players = ctx.Services.Players
	local UserInputService = ctx.Services.UserInputService
	local LP = ctx.LP
	local C = ctx.C
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad

	ctx.ui.pages = {}
	ctx.ui.tabBtns = {}

	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		for _, nm in ipairs({ "GAGGarden", "AllegiaanGarden" }) do
			local old = host:FindFirstChild(nm); if old then old:Destroy() end
			local pg = LP:FindFirstChild("PlayerGui")
			if pg and pg:FindFirstChild(nm) then pg[nm]:Destroy() end
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "AllegiaanGarden"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LP:WaitForChild("PlayerGui")
	ctx.state.gui = gui

	-- floating maximize
	local maxIcon = mk("TextButton", { Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 15, 0.5, -23), BackgroundColor3 = C.panel, Text = "AH", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.acc, Visible = false, Active = true }, gui)
	corner(maxIcon, 23); stroke(maxIcon, C.acc, 1.5)

	local main = mk("Frame", { Size = UDim2.fromOffset(720, 470), Position = UDim2.new(0.5, -360, 0.5, -235), BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true }, gui)
	corner(main, 12); stroke(main, C.stroke, 1)

	-- title bar
	local titleBar = mk("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, main)
	mk("TextLabel", { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, Text = "AllegiaanHub VIP | Grow a Garden", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.acc, TextXAlignment = Enum.TextXAlignment.Left }, titleBar)
	do
		local dragging, ds, sp
		titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = main.Position end end)
		UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	end

	local minBtn = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -70, 0, 8), BackgroundColor3 = C.row, Text = "—", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt }, titleBar)
	corner(minBtn, 6)
	local closeBtn = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -36, 0, 8), BackgroundColor3 = C.row, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt }, titleBar)
	corner(closeBtn, 6)
	minBtn.MouseButton1Click:Connect(function() main.Visible = false; maxIcon.Visible = true end)
	maxIcon.MouseButton1Click:Connect(function() maxIcon.Visible = false; main.Visible = true end)
	closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
	do
		local dragging, ds, sp
		maxIcon.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = maxIcon.Position end end)
		UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; maxIcon.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	end

	-- sidebar
	local sidebar = mk("Frame", { Size = UDim2.new(0, 180, 1, -52), Position = UDim2.fromOffset(8, 48), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, main)
	corner(sidebar, 10); pad(sidebar, 10, 10, 10, 10)

	local tabButtonsFrame = mk("Frame", { Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1 }, sidebar)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabButtonsFrame)

	-- player card
	local card = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), Position = UDim2.new(0, 0, 1, -48), BackgroundColor3 = C.row, BorderSizePixel = 0 }, sidebar)
	corner(card, 8); stroke(card); pad(card, 6, 6, 6, 6)
	local avatar = mk("ImageLabel", { Size = UDim2.fromOffset(34, 34), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, card)
	corner(avatar, 17); stroke(avatar, C.stroke, 1)
	pcall(function() avatar.Image = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
	local nameLbl = mk("TextLabel", { Size = UDim2.new(1, -42, 1, 0), Position = UDim2.fromOffset(42, 0), BackgroundTransparency = 1, Text = LP.DisplayName, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)

	-- content
	local content = mk("Frame", { Size = UDim2.new(1, -206, 1, -66), Position = UDim2.fromOffset(196, 50), BackgroundTransparency = 1 }, main)

	-- status footer
	local statusText = mk("TextLabel", { Size = UDim2.new(1, -206, 0, 18), Position = UDim2.new(0, 196, 1, -22), BackgroundTransparency = 1, Text = "Status: idle", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, main)

	function ctx.setStatus(s)
		statusText.Text = "Status: " .. tostring(s)
	end

	local logLines = ctx.state.logLines
	function ctx.log(msg)
		table.insert(logLines, os.date("%H:%M:%S ") .. msg)
		while #logLines > 12 do table.remove(logLines, 1) end
		if ctx.ui.logBox then ctx.ui.logBox.Text = table.concat(logLines, "\n") end
	end

	ctx.ui.main = main
	ctx.ui.content = content
	ctx.ui.tabButtonsFrame = tabButtonsFrame
	ctx.ui.statusText = statusText
end
