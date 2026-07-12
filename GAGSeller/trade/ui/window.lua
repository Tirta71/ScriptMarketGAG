--[[ window.lua — jendela utama: sidebar, title bar, drag, min/max/close, content, status, log.
     Mengisi: ctx.state.gui, ctx.ui.{main,maxIcon,content,tabButtonsFrame,sidebar,pages,tabBtns,statusText,logBox}
              ctx.log, ctx.setStatus ]]
return function(ctx)
	local Players          = ctx.Services.Players
	local UserInputService = ctx.Services.UserInputService
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local C   = ctx.C
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad

	ctx.ui.pages   = {}
	ctx.ui.tabBtns = {}

	----------------------------------------------------------------- bersihkan GUI lama
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		local old = host:FindFirstChild("GAGSeller"); if old then old:Destroy() end
		local pg = LP:FindFirstChild("PlayerGui")
		if pg and pg:FindFirstChild("GAGSeller") then pg.GAGSeller:Destroy() end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "GAGSeller"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LP:WaitForChild("PlayerGui")
	ctx.state.gui = gui
	ctx.state.isAlive = true
	gui.Destroying:Connect(function()
		ctx.state.isAlive = false
	end)

	----------------------------------------------------------------- Floating Maximize Button
	local maxIcon = mk("TextButton", {
		Size = UDim2.fromOffset(45, 45), Position = UDim2.new(0, 15, 0.5, -22),
		BackgroundColor3 = C.panel, Text = "AH", Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = C.acc, Visible = false, Active = true,
	}, gui)
	corner(maxIcon, 22)
	stroke(maxIcon, C.acc, 1.5)
	do
		local dragging, ds, sp
		maxIcon.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = maxIcon.Position end end)
		UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; maxIcon.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	end

	----------------------------------------------------------------- Main Jendela
	local main = mk("Frame", {
		Size = UDim2.fromOffset(650, 450), Position = UDim2.new(0.5, -325, 0.5, -225),
		BackgroundColor3 = C.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Active = true,
	}, gui)
	corner(main, 10)
	stroke(main, C.stroke, 1)

	-- Title bar & Dragger
	local titleBar = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.panel, BackgroundTransparency = 1, BorderSizePixel = 0
	}, main)
	do
		local dragging, ds, sp
		titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = main.Position end end)
		UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	end

	local minBtn = mk("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -64, 0, 7), BackgroundColor3 = C.row,
		Text = "-", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, ZIndex = 3,
	}, titleBar)
	corner(minBtn, 6)
	local closeBtn = mk("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0, 7), BackgroundColor3 = C.row,
		Text = "X", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.txt, ZIndex = 3,
	}, titleBar)
	corner(closeBtn, 6)

	-- Premium Hover Animations
	minBtn.MouseEnter:Connect(function() minBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65) end)
	minBtn.MouseLeave:Connect(function() minBtn.BackgroundColor3 = C.row end)
	closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = C.red; closeBtn.TextColor3 = Color3.new(1, 1, 1) end)
	closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = C.row; closeBtn.TextColor3 = C.txt end)

	minBtn.MouseButton1Click:Connect(function() main.Visible = false; maxIcon.Visible = true end)
	maxIcon.MouseButton1Click:Connect(function() maxIcon.Visible = false; main.Visible = true end)
	closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

	----------------------------------------------------------------- Left Sidebar
	local sidebar = mk("Frame", {
		Size = UDim2.new(0, 160, 1, 0), BackgroundColor3 = C.panel, BorderSizePixel = 0
	}, main)
	corner(sidebar, 10)
	pad(sidebar, 12, 12, 12, 12)

	local logo = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, sidebar)
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		Text = "AllegiaanHub | GAG Trade", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.acc,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, logo)

	local tabButtonsFrame = mk("Frame", {
		Size = UDim2.new(1, 0, 1, -94), Position = UDim2.fromOffset(0, 38), BackgroundTransparency = 1
	}, sidebar)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabButtonsFrame)

	-- Profile Card di Sidebar bawah
	local profileCard = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44),
		BackgroundColor3 = C.row, BorderSizePixel = 0,
	}, sidebar)
	corner(profileCard, 8)
	stroke(profileCard)
	pad(profileCard, 6, 6, 6, 6)

	local avatar = mk("ImageLabel", {
		Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.panel, BorderSizePixel = 0
	}, profileCard)
	corner(avatar, 16)
	stroke(avatar, C.stroke, 1)
	pcall(function()
		avatar.Image = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)

	local nameLabel = mk("TextLabel", {
		Size = UDim2.new(1, -38, 1, 0), Position = UDim2.fromOffset(38, 0), BackgroundTransparency = 1,
		Text = LP.Name, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.txt,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, profileCard)
	pcall(function()
		local short = LP.DisplayName
		if #short > 11 then short = short:sub(1, 9) .. ".." end
		nameLabel.Text = short
	end)

	-- Right Content Frame
	local content = mk("Frame", {
		Size = UDim2.new(1, -172, 1, -20), Position = UDim2.fromOffset(166, 12), BackgroundTransparency = 1
	}, main)

	----------------------------------------------------------------- Status footer
	local statusFooter = mk("Frame", { Size = UDim2.new(1, -172, 0, 18), Position = UDim2.new(0, 166, 1, -22), BackgroundTransparency = 1 }, main)
	local statusText = mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Status: idle", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, statusFooter)

	function ctx.setStatus(s)
		statusText.Text = ("Status: %s | Loop: %s"):format(s, CFG.autoSell and "ON" or "OFF")
	end

	----------------------------------------------------------------- Logger
	-- logBox dibuat di pages.lua (halaman Misc) lalu di-set ke ctx.ui.logBox.
	-- ctx.log tetap aman dipanggil sebelum logBox ada (hanya buffer ke logLines).
	local logLines = ctx.state.logLines
	function ctx.log(msg)
		table.insert(logLines, os.date("%H:%M:%S ") .. msg)
		while #logLines > 10 do table.remove(logLines, 1) end
		if ctx.ui.logBox then ctx.ui.logBox.Text = table.concat(logLines, "\n") end
	end

	ctx.ui.main            = main
	ctx.ui.maxIcon         = maxIcon
	ctx.ui.content         = content
	ctx.ui.tabButtonsFrame = tabButtonsFrame
	ctx.ui.sidebar         = sidebar
	ctx.ui.statusText      = statusText
end
