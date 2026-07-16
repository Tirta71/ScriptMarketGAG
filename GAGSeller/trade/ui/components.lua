--[[ components.lua — kontrol UI reusable.
     Mengisi: ctx.makeToggle, ctx.makeInput, ctx.makeDropdown,
              ctx.makeSingleDropdown, ctx.makeButton, ctx.makeAccordion, ctx.makePage
     Catatan: makePage membaca ctx.ui.tabButtonsFrame/content/pages/tabBtns saat
     dipanggil (dibuat oleh window.lua), jadi urutan load tetap aman. ]]
return function(ctx)
	local C      = ctx.C
	local mk     = ctx.mk
	local corner = ctx.corner
	local stroke = ctx.stroke
	local pad    = ctx.pad

	----------------------------------------------------------------- toggle
	local function makeToggle(parent, title, desc, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = order }, parent)
		local txts = mk("Frame", { Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1 }, row)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)

		local knob = mk("TextButton", { Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -38, 0.5, -9), BackgroundColor3 = C.panel, Text = "", AutoButtonColor = false }, row)
		corner(knob, 9); stroke(knob, C.stroke)
		local dot = mk("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.sub }, knob)
		corner(dot, 6)

		local function render()
			local on = getv()
			dot:TweenPosition(on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3), "Out", "Quad", 0.15, true)
			knob.BackgroundColor3 = on and C.acc or C.panel
			dot.BackgroundColor3 = on and Color3.new(1, 1, 1) or C.sub
		end
		knob.MouseButton1Click:Connect(function() setv(not getv()); render() end)
		render()
		return render
	end

	----------------------------------------------------------------- input
	local function makeInput(parent, title, desc, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = order }, parent)
		local txts = mk("Frame", { Size = UDim2.new(1, -130, 1, 0), BackgroundTransparency = 1 }, row)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 2), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 20), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)

		local box = mk("TextBox", { Size = UDim2.fromOffset(110, 26), Position = UDim2.new(1, -112, 0.5, -13), BackgroundColor3 = C.panel, Text = tostring(getv()), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.acc, ClearTextOnFocus = false }, row)
		corner(box, 6); local bs = stroke(box)
		box.Focused:Connect(function() game:GetService("TweenService"):Create(bs, TweenInfo.new(0.15), { Color = C.acc }):Play() end)
		box.FocusLost:Connect(function() game:GetService("TweenService"):Create(bs, TweenInfo.new(0.15), { Color = C.stroke }):Play(); setv(box.Text); box.Text = tostring(getv()) end)
		return box
	end

	----------------------------------------------------------------- multi dropdown
	local function makeDropdown(parent, title, desc, options, selSet, onChange, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)

		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
		local txts = mk("Frame", { Size = UDim2.new(1, -200, 1, 0), BackgroundTransparency = 1 }, head)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)

		local valLbl = mk("TextLabel", { Size = UDim2.new(0, 180, 1, 0), Position = UDim2.new(1, -200, 0, 0), BackgroundTransparency = 1, Text = "Select Options", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right }, head)
		local arrow = mk("TextLabel", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -12, 0.5, -6), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center }, head)

		local function updateSummary()
			local sel = {}
			for _, o in ipairs(options) do if selSet[o] then sel[#sel + 1] = o end end
			if #sel == 0 then valLbl.Text = "Select Options"; valLbl.TextColor3 = C.sub
			else
				local txt = table.concat(sel, ", ")
				if #txt > 20 then txt = ("%d selected"):format(#sel) end
				valLbl.Text = txt; valLbl.TextColor3 = C.acc
			end
		end

		local listFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 180), BackgroundColor3 = C.panel, Visible = false, LayoutOrder = 2 }, row)
		corner(listFrame, 6); stroke(listFrame)
		local search = mk("TextBox", { Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.row, PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, ClearTextOnFocus = false }, listFrame)
		corner(search, 6); stroke(search)
		local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -40), Position = UDim2.fromOffset(6, 36), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, listFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local built = false
		local optBtns = {}
		local rends = {} -- render checkmark tiap opsi (buat refresh dari luar, mis. Clear All)
		-- Selected-first: yang dipilih (✓) di paling atas.
		local function reorder()
			local i = 0
			for _, opt in ipairs(options) do
				if selSet[opt] and optBtns[opt] then i = i + 1; optBtns[opt].LayoutOrder = i end
			end
			for _, opt in ipairs(options) do
				if not selSet[opt] and optBtns[opt] then i = i + 1; optBtns[opt].LayoutOrder = i end
			end
		end
		local function buildOptions()
			if built then return end
			built = true
			for _, opt in ipairs(options) do
				local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. opt, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
				corner(ob, 4)
				local check = mk("TextLabel", { Size = UDim2.fromOffset(20, 24), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.green }, ob)
				local function rend() check.Text = selSet[opt] and "✓" or ""; ob.BackgroundColor3 = selSet[opt] and Color3.fromRGB(40, 44, 60) or C.row end
				ob.MouseButton1Click:Connect(function()
					if selSet[opt] then selSet[opt] = nil else selSet[opt] = true end
					rend(); updateSummary(); reorder(); if onChange then onChange() end
				end)
				rend()
				optBtns[opt] = ob
				rends[#rends + 1] = rend
			end
			reorder()
		end
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			for opt, ob in pairs(optBtns) do ob.Visible = (q == "" or opt:lower():find(q, 1, true) ~= nil) end
		end)
		head.MouseButton1Click:Connect(function()
			if not built then buildOptions() end
			listFrame.Visible = not listFrame.Visible
			arrow.Text = listFrame.Visible and "^" or "v"
			if listFrame.Visible then reorder() end
		end)
		updateSummary()
		-- refresh: sinkronin tampilan (checkmark + summary) dengan isi selSet terkini.
		-- Dipakai Clear All: setelah selSet dikosongkan, panggil ini biar centang ilang.
		local function refresh()
			for _, r in ipairs(rends) do r() end
			updateSummary()
			if built then reorder() end
		end
		return refresh
	end

	----------------------------------------------------------------- single dropdown
	local function makeSingleDropdown(parent, title, desc, options, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)

		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
		local txts = mk("Frame", { Size = UDim2.new(1, -200, 1, 0), BackgroundTransparency = 1 }, head)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 2), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 20), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)

		local initialDisplay = getv()
		for _, opt in ipairs(options) do
			if type(opt) == "table" and opt.name == getv() then
				initialDisplay = opt.display
				break
			elseif type(opt) == "string" and opt == getv() then
				initialDisplay = opt
				break
			end
		end

		local valLbl = mk("TextLabel", { Size = UDim2.new(0, 180, 1, 0), Position = UDim2.new(1, -200, 0, 0), BackgroundTransparency = 1, Text = initialDisplay, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right }, head)
		local arrow = mk("TextLabel", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -12, 0.5, -6), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center }, head)

		local listFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 160), BackgroundColor3 = C.panel, Visible = false, LayoutOrder = 2 }, row)
		corner(listFrame, 6); stroke(listFrame)
		local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, listFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local built = false
		local function buildOptions()
			if built then return end
			built = true
			for _, opt in ipairs(options) do
				local displayVal = type(opt) == "table" and opt.display or opt
				local codeVal = type(opt) == "table" and opt.name or opt
				local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. displayVal, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
				corner(ob, 4)
				ob.MouseButton1Click:Connect(function()
					setv(codeVal)
					valLbl.Text = displayVal
					listFrame.Visible = false
					arrow.Text = "v"
				end)
			end
		end
		head.MouseButton1Click:Connect(function()
			if not built then buildOptions() end
			listFrame.Visible = not listFrame.Visible
			arrow.Text = listFrame.Visible and "^" or "v"
		end)
		return head
	end

	----------------------------------------------------------------- button (minimal/elegant)
	local TS = game:GetService("TweenService")
	local function makeButton(parent, title, color, onClick, order)
		local base = color or C.acc
		local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = base, Text = title, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, LayoutOrder = order }, parent)
		corner(btn, 6); stroke(btn, C.stroke, 1)
		btn.MouseEnter:Connect(function() TS:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.1) }):Play() end)
		btn.MouseLeave:Connect(function() TS:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = base }):Play() end)
		if onClick then btn.MouseButton1Click:Connect(onClick) end
		return btn
	end

	----------------------------------------------------------------- accordion
	local function makeAccordion(parent, title, order)
		local TS = game:GetService("TweenService")
		local container = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.row, BorderSizePixel = 0, LayoutOrder = order, ClipsDescendants = false }, parent)
		corner(container, 8); stroke(container)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, container)

		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, container)
		corner(head, 8)
		pad(head, 14, 12, 0, 0)

		local lbl = mk("TextLabel", { Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, head)
		local arrow = mk("TextLabel", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0.5, 0), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center }, head)

		local line = mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.stroke, BorderSizePixel = 0, LayoutOrder = 2, Visible = false }, container)
		local body = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 3 }, container)
		pad(body, 12, 12, 8, 12)
		mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, body)

		head.MouseEnter:Connect(function()
			TS:Create(head, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.96 }):Play()
		end)
		head.MouseLeave:Connect(function()
			TS:Create(head, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		end)

		head.MouseButton1Click:Connect(function()
			body.Visible = not body.Visible
			line.Visible = body.Visible
			local open = body.Visible
			local targetRotation = open and 180 or 0
			TS:Create(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = targetRotation }):Play()
			TS:Create(arrow, TweenInfo.new(0.2), { TextColor3 = open and C.acc or C.sub }):Play()
			TS:Create(lbl, TweenInfo.new(0.2), { TextColor3 = open and C.acc or C.txt }):Play()
		end)
		return body
	end

	----------------------------------------------------------------- page + tab
	local function makePage(name, titleText, iconLabel, order)
		local tabButtonsFrame = ctx.ui.tabButtonsFrame
		local content         = ctx.ui.content
		local pages           = ctx.ui.pages
		local tabBtns         = ctx.ui.tabBtns

		local btn = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.acc, BackgroundTransparency = 1,
			Text = "     " .. iconLabel .. " | " .. name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.sub,
			LayoutOrder = order, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left
		}, tabButtonsFrame)
		corner(btn, 8)

		local line = mk("Frame", { Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 4, 0.5, -9), BackgroundColor3 = C.acc, Visible = false }, btn)
		corner(line, 2)
		tabBtns[name] = { btn = btn, line = line }

		-- hover halus buat tab non-aktif
		btn.MouseEnter:Connect(function() if not line.Visible then TS:Create(btn, TweenInfo.new(0.18), { BackgroundTransparency = 0.94 }):Play() end end)
		btn.MouseLeave:Connect(function() if not line.Visible then TS:Create(btn, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play() end end)

		local pg = mk("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 4,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc
		}, content)
		mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pg)
		pages[name] = pg

		local pageHeader = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 0 }, pg)
		mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = titleText, Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, pageHeader)

		btn.MouseButton1Click:Connect(function()
			for n, p in pairs(pages) do p.Visible = (n == name) end
			for n, b in pairs(tabBtns) do
				local on = (n == name)
				TS:Create(b.btn, TweenInfo.new(0.18), { BackgroundTransparency = on and 0.86 or 1 }):Play()
				b.btn.TextColor3 = on and C.txt or C.sub
				b.line.Visible = on
			end
		end)
		return pg
	end

	ctx.makeToggle         = makeToggle
	ctx.makeInput          = makeInput
	ctx.makeDropdown       = makeDropdown
	ctx.makeSingleDropdown = makeSingleDropdown
	ctx.makeButton         = makeButton
	ctx.makeAccordion      = makeAccordion
	ctx.makePage           = makePage
end
