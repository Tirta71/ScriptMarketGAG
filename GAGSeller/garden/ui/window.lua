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
	ctx.state.isAlive = true
	gui.Destroying:Connect(function()
		ctx.state.isAlive = false
	end)

	-- floating maximize
	local maxIcon = mk("TextButton", { Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 15, 0.5, -23), BackgroundColor3 = C.panel, Text = "AH", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.acc, Visible = false, Active = true }, gui)
	corner(maxIcon, 23); stroke(maxIcon, C.acc, 1.5)

	-- AnchorPoint tengah + Position tengah -> UIScale ngecilin dari titik tengah,
	-- jadi window tetap ke-center (penting di HP).
	local main = mk("Frame", { Size = UDim2.fromOffset(720, 470), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true }, gui)
	corner(main, 12); stroke(main, C.stroke, 1)

	-- Auto-scale: kecilin window proporsional biar muat di layar kecil (HP).
	local uiScale = Instance.new("UIScale"); uiScale.Parent = main
	local function fitScale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		-- sisain margin ~40px; jangan gede-in di atas 1x; baca ukuran window terkini
		local w, h = main.Size.X.Offset, main.Size.Y.Offset
		local s = math.min(1, (vp.X - 40) / w, (vp.Y - 40) / h)
		uiScale.Scale = math.max(0.4, s)
	end
	fitScale()
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale) end
	end)

	-- title bar
	local titleBar = mk("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, main)
	mk("TextLabel", { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, Text = "AllegiaanHub VIP | Grow a Garden", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.acc, TextXAlignment = Enum.TextXAlignment.Left }, titleBar)
	do
		local dragging, ds, sp
		titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = main.Position end end)
		UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	end

	local minBtn = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -70, 0, 8), BackgroundColor3 = C.row, Text = "-", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.txt }, titleBar)
	corner(minBtn, 6)
	local closeBtn = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -36, 0, 8), BackgroundColor3 = C.row, Text = "X", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt }, titleBar)
	corner(closeBtn, 6)

	-- Premium Hover Animations
	minBtn.MouseEnter:Connect(function() minBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65) end)
	minBtn.MouseLeave:Connect(function() minBtn.BackgroundColor3 = C.row end)
	closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = C.red; closeBtn.TextColor3 = Color3.new(1, 1, 1) end)
	closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = C.row; closeBtn.TextColor3 = C.txt end)

	minBtn.MouseButton1Click:Connect(function() main.Visible = false; maxIcon.Visible = true end)
	maxIcon.MouseButton1Click:Connect(function() maxIcon.Visible = false; main.Visible = true end)

	-- Konfirmasi sebelum close (Yes/No). Overlay modal di atas window.
	local function confirmClose()
		local overlay = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 50, Active = true }, main)
		local box = mk("Frame", { Size = UDim2.fromOffset(300, 150), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.panel, BorderSizePixel = 0, ZIndex = 51 }, overlay)
		corner(box, 12); stroke(box, C.stroke, 1)
		mk("TextLabel", { Size = UDim2.new(1, -24, 0, 36), Position = UDim2.fromOffset(12, 16), BackgroundTransparency = 1, Text = "Close AllegiaanHub?", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.acc, ZIndex = 51 }, box)
		mk("TextLabel", { Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 52), BackgroundTransparency = 1, Text = "Yakin mau nutup hub ini?", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.txt, ZIndex = 51 }, box)
		local noBtn = mk("TextButton", { Size = UDim2.fromOffset(120, 38), Position = UDim2.new(0, 18, 1, -50), BackgroundColor3 = C.row, Text = "No", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, ZIndex = 51 }, box)
		corner(noBtn, 8)
		local yesBtn = mk("TextButton", { Size = UDim2.fromOffset(120, 38), Position = UDim2.new(1, -138, 1, -50), BackgroundColor3 = C.red, Text = "Yes", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), ZIndex = 51 }, box)
		corner(yesBtn, 8)
		noBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)
		yesBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
	end
	closeBtn.MouseButton1Click:Connect(confirmClose)
	do
		local dragging, ds, sp
		maxIcon.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = maxIcon.Position end end)
		UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; maxIcon.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	end

	-- sidebar
	local sidebar = mk("Frame", { Size = UDim2.new(0, 180, 1, -52), Position = UDim2.fromOffset(8, 48), BackgroundColor3 = C.panel, BorderSizePixel = 0 }, main)
	corner(sidebar, 10); pad(sidebar, 10, 10, 10, 10)

	local tabButtonsFrame = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.acc, ScrollBarImageTransparency = 0.4,
		ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingEnabled = true,
	}, sidebar)
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

	-- Resize grip (pojok kanan-bawah). Drag buat ubah ukuran window.
	local grip = mk("TextButton", { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -22, 1, -22), BackgroundTransparency = 1, Text = "◢", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.sub, AutoButtonColor = false, Active = true, ZIndex = 20 }, main)
	grip.MouseEnter:Connect(function() grip.TextColor3 = C.acc end)
	grip.MouseLeave:Connect(function() grip.TextColor3 = C.sub end)
	do
		local rz, ds, ss
		grip.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				rz = true; ds = i.Position; ss = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if rz and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local scale = uiScale.Scale > 0 and uiScale.Scale or 1
				local d = i.Position - ds
				local w = math.clamp(ss.X + d.X / scale, 480, 1600)
				local h = math.clamp(ss.Y + d.Y / scale, 320, 1000)
				main.Size = UDim2.fromOffset(w, h)
				fitScale() -- pastiin tetap muat di layar
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then rz = false end
		end)
	end

	-- status footer (disembunyikan; automation punya panel status sendiri)
	local statusText = mk("TextLabel", { Size = UDim2.new(1, -206, 0, 18), Position = UDim2.new(0, 196, 1, -22), BackgroundTransparency = 1, Text = "Status: idle", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, Visible = false }, main)

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
