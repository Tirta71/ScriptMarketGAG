--[[ components.lua — kontrol UI garden (toggle, input, dropdown, accordion, page/tab). ]]
return function(ctx)
	local C = ctx.C
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad

	local function labels(parent, title, desc, rightPad)
		local txts = mk("Frame", { Size = UDim2.new(1, -(rightPad or 130), 1, 0), BackgroundTransparency = 1 }, parent)
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 5), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, txts)
		if desc then
			mk("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 25), BackgroundTransparency = 1, Text = desc, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, txts)
		end
	end

	local function divider(parent)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.stroke, BorderSizePixel = 0, LayoutOrder = 9999 }, parent)
	end

	----------------------------------------------------------------- toggle
	local function makeToggle(parent, title, desc, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = order }, parent)
		labels(row, title, desc, 70)
		local knob = mk("TextButton", { Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -50, 0.5, -12), BackgroundColor3 = C.panel, Text = "", AutoButtonColor = false }, row)
		corner(knob, 12); stroke(knob, C.stroke)
		local dot = mk("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.sub }, knob)
		corner(dot, 9)
		local function render()
			local on = getv()
			dot:TweenPosition(on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3), "Out", "Quad", 0.15, true)
			knob.BackgroundColor3 = on and C.acc or C.panel
			dot.BackgroundColor3 = on and Color3.new(1, 1, 1) or C.sub
		end
		knob.MouseButton1Click:Connect(function() setv(not getv()); render() end)
		render()
		return render
	end

	----------------------------------------------------------------- input
	local function makeInput(parent, title, desc, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = order }, parent)
		labels(row, title, desc, 140)
		local box = mk("TextBox", { Size = UDim2.fromOffset(120, 30), Position = UDim2.new(1, -124, 0.5, -15), BackgroundColor3 = C.panel, Text = tostring(getv()), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.acc, ClearTextOnFocus = false }, row)
		corner(box, 6); stroke(box)
		box.FocusLost:Connect(function() setv(box.Text); box.Text = tostring(getv()) end)
		return box
	end

	----------------------------------------------------------------- single dropdown (opsi = string atau {name,display})
	local function makeSingleDropdown(parent, title, desc, getOptions, getv, setv, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)
		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
		labels(head, title, desc, 200)
		local valLbl = mk("TextLabel", { Size = UDim2.new(0, 170, 1, 0), Position = UDim2.new(1, -190, 0, 0), BackgroundTransparency = 1, Text = getv() ~= "" and getv() or "Select", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.acc, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, head)
		mk("TextLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -14, 0.5, -7), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub }, head)

		local listFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 170), BackgroundColor3 = C.panel, Visible = false, LayoutOrder = 2 }, row)
		corner(listFrame, 6); stroke(listFrame)
		local search = mk("TextBox", { Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.row, PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, ClearTextOnFocus = false }, listFrame)
		corner(search, 6); stroke(search)
		local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -40), Position = UDim2.fromOffset(6, 36), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, listFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local optBtns = {}
		local function rebuild()
			for _, b in pairs(optBtns) do b:Destroy() end
			optBtns = {}
			for _, opt in ipairs(getOptions()) do
				local display = type(opt) == "table" and opt.display or opt
				local code    = type(opt) == "table" and opt.name or opt
				local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. display, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
				corner(ob, 4)
				ob.MouseButton1Click:Connect(function()
					setv(code); valLbl.Text = display; listFrame.Visible = false
				end)
				optBtns[#optBtns + 1] = ob
			end
		end
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			for _, ob in ipairs(optBtns) do ob.Visible = (q == "" or ob.Text:lower():find(q, 1, true) ~= nil) end
		end)
		head.MouseButton1Click:Connect(function()
			listFrame.Visible = not listFrame.Visible
			if listFrame.Visible then rebuild() end
		end)
		return function() valLbl.Text = getv() ~= "" and getv() or "Select" end
	end

	----------------------------------------------------------------- multi dropdown
	local function makeMultiDropdown(parent, title, desc, options, selSet, onChange, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)
		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
		labels(head, title, desc, 200)
		local valLbl = mk("TextLabel", { Size = UDim2.new(0, 170, 1, 0), Position = UDim2.new(1, -190, 0, 0), BackgroundTransparency = 1, Text = "Select", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, head)
		mk("TextLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -14, 0.5, -7), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub }, head)

		local function updateSummary()
			local sel = {}
			for _, o in ipairs(options) do if selSet[o] then sel[#sel + 1] = o end end
			if #sel == 0 then valLbl.Text = "Select"; valLbl.TextColor3 = C.sub
			else
				local txt = table.concat(sel, ", ")
				if #txt > 18 then txt = (#sel) .. " selected" end
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
		local function build()
			if built then return end; built = true
			for _, opt in ipairs(options) do
				local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. opt, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
				corner(ob, 4)
				local check = mk("TextLabel", { Size = UDim2.fromOffset(20, 24), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.green }, ob)
				local function rend() check.Text = selSet[opt] and "✓" or ""; ob.BackgroundColor3 = selSet[opt] and Color3.fromRGB(45, 44, 30) or C.row end
				ob.MouseButton1Click:Connect(function()
					if selSet[opt] then selSet[opt] = nil else selSet[opt] = true end
					rend(); updateSummary(); if onChange then onChange() end
				end)
				rend(); optBtns[opt] = ob
			end
		end
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			for opt, ob in pairs(optBtns) do ob.Visible = (q == "" or opt:lower():find(q, 1, true) ~= nil) end
		end)
		head.MouseButton1Click:Connect(function()
			if not built then build() end
			listFrame.Visible = not listFrame.Visible
		end)
		updateSummary()
		return updateSummary
	end

	----------------------------------------------------------------- multi dropdown DINAMIS (value/display)
	-- getOptions() -> { {value=<key>, display=<label>}, ... }. selSet di-key pakai value.
	-- Opsi di-rebuild tiap kali dibuka (buat list yang berubah, mis. pet equipped).
	local function makeMultiDropdownDyn(parent, title, desc, getOptions, selSet, onChange, order)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, row)
		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, row)
		labels(head, title, desc, 200)
		local valLbl = mk("TextLabel", { Size = UDim2.new(0, 170, 1, 0), Position = UDim2.new(1, -190, 0, 0), BackgroundTransparency = 1, Text = "Select", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, head)
		mk("TextLabel", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -14, 0.5, -7), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.sub }, head)

		local function countSel()
			local n = 0; for _ in pairs(selSet) do n += 1 end; return n
		end
		local function updateSummary()
			local n = countSel()
			if n == 0 then valLbl.Text = "Select (semua)"; valLbl.TextColor3 = C.sub
			else valLbl.Text = n .. " dipilih"; valLbl.TextColor3 = C.acc end
		end

		local listFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 190), BackgroundColor3 = C.panel, Visible = false, LayoutOrder = 2 }, row)
		corner(listFrame, 6); stroke(listFrame)
		local search = mk("TextBox", { Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.row, PlaceholderText = "Search...", Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, ClearTextOnFocus = false }, listFrame)
		corner(search, 6); stroke(search)
		local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -40), Position = UDim2.fromOffset(6, 36), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, listFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local optBtns = {}  -- {btn=, display=}
		local function rebuild()
			for _, o in ipairs(optBtns) do o.btn:Destroy() end
			optBtns = {}
			for _, opt in ipairs(getOptions()) do
				local value, display = opt.value, opt.display
				local ob = mk("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.row, Text = "  " .. display, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt, AutoButtonColor = false }, scroll)
				corner(ob, 4)
				local check = mk("TextLabel", { Size = UDim2.fromOffset(20, 24), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.green }, ob)
				local function rend() check.Text = selSet[value] and "✓" or ""; ob.BackgroundColor3 = selSet[value] and Color3.fromRGB(45, 44, 30) or C.row end
				ob.MouseButton1Click:Connect(function()
					if selSet[value] then selSet[value] = nil else selSet[value] = true end
					rend(); updateSummary(); if onChange then onChange() end
				end)
				rend()
				optBtns[#optBtns + 1] = { btn = ob, display = display:lower() }
			end
		end
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			for _, o in ipairs(optBtns) do o.btn.Visible = (q == "" or o.display:find(q, 1, true) ~= nil) end
		end)
		head.MouseButton1Click:Connect(function()
			listFrame.Visible = not listFrame.Visible
			if listFrame.Visible then rebuild() end
		end)
		updateSummary()
		return updateSummary
	end

	----------------------------------------------------------------- accordion
	local function makeAccordion(parent, title, order, openByDefault)
		local TS = game:GetService("TweenService")
		local container = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.row, BorderSizePixel = 0, LayoutOrder = order }, parent)
		corner(container, 8); stroke(container)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, container)
		
		local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 1 }, container)
		corner(head, 8)
		pad(head, 14, 14, 0, 0)
		
		mk("TextLabel", { Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, head)
		local arrow = mk("TextLabel", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -7, 0.5, 0), BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.acc, Rotation = openByDefault and 180 or 0 }, head)
		
		local line = mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.stroke, BorderSizePixel = 0, LayoutOrder = 2, Visible = openByDefault or false }, container)
		local body = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = openByDefault or false, LayoutOrder = 3 }, container)
		pad(body, 14, 14, 8, 12)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, body)
		
		head.MouseEnter:Connect(function()
			TS:Create(head, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.96 }):Play()
		end)
		head.MouseLeave:Connect(function()
			TS:Create(head, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		end)
		
		head.MouseButton1Click:Connect(function()
			body.Visible = not body.Visible
			line.Visible = body.Visible
			local targetRotation = body.Visible and 180 or 0
			TS:Create(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = targetRotation }):Play()
		end)
		return body
	end

	----------------------------------------------------------------- sidebar page/tab
	local function makePage(name, titleText, icon, order)
		local tabButtonsFrame = ctx.ui.tabButtonsFrame
		local content = ctx.ui.content
		local pages, tabBtns = ctx.ui.pages, ctx.ui.tabBtns

		local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.acc, BackgroundTransparency = 1, Text = "    " .. icon .. "  |  " .. name, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = C.sub, LayoutOrder = order, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left }, tabButtonsFrame)
		corner(btn, 6)
		local line = mk("Frame", { Size = UDim2.new(0, 3, 0, 20), Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = C.acc, Visible = false, BorderSizePixel = 0 }, btn)
		corner(line, 2)
		tabBtns[name] = { btn = btn, line = line }

		local pg = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = "Y", ScrollBarImageColor3 = C.acc }, content)
		mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pg)
		pages[name] = pg
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Text = titleText, Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 }, pg)

		btn.MouseButton1Click:Connect(function()
			for n, p in pairs(pages) do p.Visible = (n == name) end
			for n, b in pairs(tabBtns) do
				b.btn.BackgroundTransparency = (n == name) and 0.85 or 1
				b.btn.TextColor3 = (n == name) and C.txt or C.sub
				b.line.Visible = (n == name)
			end
		end)
		return pg
	end

	ctx.makeToggle = makeToggle
	ctx.makeInput = makeInput
	ctx.makeSingleDropdown = makeSingleDropdown
	ctx.makeMultiDropdown = makeMultiDropdown
	ctx.makeMultiDropdownDyn = makeMultiDropdownDyn
	ctx.makeAccordion = makeAccordion
	ctx.makePage = makePage
	ctx.divider = divider
end
