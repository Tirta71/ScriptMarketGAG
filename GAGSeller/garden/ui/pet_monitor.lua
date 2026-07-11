--[[ pet_monitor.lua — jendela visual monitoring cooldown pet (garden, aksen kuning). ]]
return function(ctx)
	local C = ctx.C
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad
	local LP = ctx.LP
	local UserInputService = game:GetService("UserInputService")
	local RS = game:GetService("ReplicatedStorage")

	local PetList, PassiveRegistry
	pcall(function() PetList = require(RS.Data.PetRegistry.PetList) end)
	pcall(function() PassiveRegistry = require(RS.Data.PetRegistry.PassiveRegistry) end)

	local function getPassiveMaxCD(passiveName)
		local name = tostring(passiveName)
		if name:find("Frier") then return 1200 end       -- Ferret: 20m
		if name:find("Beauty") then return 15 end        -- Peacock: 15s
		if name:find("Frilled") then return 60 end       -- Dilo: 60s
		if name:find("Mimicry") then return 15 end       -- Mimicry: 15s
		if name:find("Mutation") then return 900 end     -- Mutation: 15m
		
		local reg = PassiveRegistry and PassiveRegistry[passiveName]
		local cd = reg and reg.States and reg.States.Cooldown
		if type(cd) == "table" then
			return tonumber(cd.Min) or tonumber(cd.Base) or 60
		end
		return 60
	end

	local main = nil -- Jendela utama
	local badgeLbl = nil
	local scroll = nil
	local uiCards = {}

	local function getTargetPets()
		local out = {}
		local ok, d = pcall(function() return ctx.deps.DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		
		local sel = ctx.CFG.pnpUuids or {}
		for _, uuid in ipairs(eq) do
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(sel)) or sel[uuid] then
				table.insert(out, {
					uuid = uuid,
					petType = pt or "Unknown",
					equipped = true,
					level = inv[uuid] and inv[uuid].PetData and inv[uuid].PetData.Level or 0,
					weight = inv[uuid] and inv[uuid].PetData and ((inv[uuid].PetData.BaseWeight or 0) + 0.5) or 0.5,
					mutation = inv[uuid] and inv[uuid].PetData and inv[uuid].PetData.MutationType or "Normal",
				})
			end
		end
		
		table.sort(out, function(a, b) return a.petType < b.petType end)
		return out
	end

	local function updateMonitor()
		if not main or not main.Visible then return end
		local pets = getTargetPets()
		if badgeLbl then badgeLbl.Text = tostring(#pets) end

		-- Hapus card UI yang sudah tidak ada di targets
		for uuid, card in pairs(uiCards) do
			local found = false
			for _, p in ipairs(pets) do
				if p.uuid == uuid then found = true; break end
			end
			if not found then
				card.frame:Destroy()
				uiCards[uuid] = nil
			end
		end

		-- Buat / Update card
		for idx, p in ipairs(pets) do
			local card = uiCards[p.uuid]
			if not card then
				local cardFrame = mk("Frame", {
					Size = UDim2.new(1, -8, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = C.row,
					BorderSizePixel = 0,
					LayoutOrder = idx,
				}, scroll)
				corner(cardFrame, 8); stroke(cardFrame); pad(cardFrame, 10, 10, 10, 10)
				
				local cardLayout = mk("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}, cardFrame)

				-- Header row (Dot + Name)
				local header = mk("Frame", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
				}, cardFrame)

				local statusDot = mk("Frame", {
					Size = UDim2.fromOffset(8, 8),
					Position = UDim2.new(0, 0, 0.5, -4),
					BorderSizePixel = 0,
				}, header)
				corner(statusDot, 4)

				local nameLbl = mk("TextLabel", {
					Size = UDim2.new(1, -16, 1, 0),
					Position = UDim2.fromOffset(14, 0),
					BackgroundTransparency = 1,
					Text = "",
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextColor3 = C.txt,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, header)

				-- Subtitle row (Weight + Age)
				local subLbl = mk("TextLabel", {
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundTransparency = 1,
					Text = "",
					Font = Enum.Font.Gotham,
					TextSize = 10,
					TextColor3 = C.sub,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 2,
				}, cardFrame)

				card = {
					frame = cardFrame,
					statusDot = statusDot,
					nameLbl = nameLbl,
					subLbl = subLbl,
					passives = {},
				}
				uiCards[p.uuid] = card
			end

			-- Update basic info
			card.frame.LayoutOrder = idx
			card.statusDot.BackgroundColor3 = p.equipped and C.green or Color3.fromRGB(240, 140, 40)
			
			local mutStr = (p.mutation and p.mutation ~= "" and p.mutation ~= "Normal") and (p.mutation .. " ") or ""
			card.nameLbl.Text = mutStr .. p.petType
			card.subLbl.Text = string.format("%.2f KG  •  Age %d", p.weight, p.level)

			-- Ambil semua passive untuk ditampilkan
			local passivesToDisplay = {}
			local petInfo = PetList and PetList[p.petType]
			if petInfo and type(petInfo.Passives) == "table" then
				for _, pas in ipairs(petInfo.Passives) do
					table.insert(passivesToDisplay, pas)
				end
			end
			-- Masukkan juga passive mutasi jika ada cooldown aktif
			local cdEntry = ctx.state.cdMap and ctx.state.cdMap[p.uuid]
			if type(cdEntry) == "table" and type(cdEntry.data) == "table" then
				for _, entry in ipairs(cdEntry.data) do
					local pas = tostring(entry.Passive)
					if pas:find("Mutation") then
						local exists = false
						for _, v in ipairs(passivesToDisplay) do
							if v == pas then exists = true; break end
						end
						if not exists then table.insert(passivesToDisplay, pas) end
					end
				end
			end

			-- Hapus UI passive lama yang sudah tidak aktif
			for pasName, row in pairs(card.passives) do
				local found = false
				for _, v in ipairs(passivesToDisplay) do
					if v == pasName then found = true; break end
				end
				if not found then
					row.frame:Destroy()
					card.passives[pasName] = nil
				end
			end

			-- Buat / Update passive rows
			for pIdx, pasName in ipairs(passivesToDisplay) do
				local row = card.passives[pasName]
				if not row then
					local rowFrame = mk("Frame", {
						Size = UDim2.new(1, 0, 0, 24),
						BackgroundTransparency = 1,
						LayoutOrder = 10 + pIdx,
					}, card.frame)

					local label = mk("TextLabel", {
						Size = UDim2.new(0.6, 0, 0, 14),
						BackgroundTransparency = 1,
						Text = pasName,
						Font = Enum.Font.Gotham,
						TextSize = 11,
						TextColor3 = C.sub,
						TextXAlignment = Enum.TextXAlignment.Left,
					}, rowFrame)

					local status = mk("TextLabel", {
						Size = UDim2.new(0.4, 0, 0, 14),
						Position = UDim2.new(0.6, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = "",
						Font = Enum.Font.GothamBold,
						TextSize = 11,
						TextColor3 = C.green,
						TextXAlignment = Enum.TextXAlignment.Right,
					}, rowFrame)

					-- Progress Bar
					local pBar = mk("Frame", {
						Size = UDim2.new(1, 0, 0, 4),
						Position = UDim2.new(0, 0, 1, -4),
						BackgroundColor3 = C.panel,
						BorderSizePixel = 0,
					}, rowFrame)
					corner(pBar, 2)

					local pFill = mk("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = C.green,
						BorderSizePixel = 0,
					}, pBar)
					corner(pFill, 2)

					row = {
						frame = rowFrame,
						label = label,
						status = status,
						pFill = pFill,
					}
					card.passives[pasName] = row
				end

				-- Dapatkan nilai cooldown secara real-time (ticking down locally)
				local timeVal = 0
				local cdEntry = ctx.state.cdMap and ctx.state.cdMap[p.uuid]
				if type(cdEntry) == "table" and type(cdEntry.data) == "table" then
					local elapsed = tick() - cdEntry.receivedAt
					for _, entry in ipairs(cdEntry.data) do
						if tostring(entry.Passive) == pasName then
							timeVal = math.max(0, (tonumber(entry.Time) or 0) - elapsed)
							break
						end
					end
				end

				-- Tampilkan teks & progress bar
				local maxCd = getPassiveMaxCD(pasName)
				if timeVal <= 0 then
					row.status.Text = "READY"
					row.status.TextColor3 = C.green
					row.pFill.BackgroundColor3 = C.green
					row.pFill.Size = UDim2.new(1, 0, 1, 0)
				else
					local statusStr
					if timeVal >= 60 then
						statusStr = string.format("%dm %02ds", math.floor(timeVal / 60), math.floor(timeVal % 60))
					else
						statusStr = string.format("%ds", math.floor(timeVal))
					end
					row.status.Text = statusStr
					row.status.TextColor3 = C.txt
					
					-- Aksen orange jika sedang cooldown
					row.pFill.BackgroundColor3 = Color3.fromRGB(240, 140, 40)
					local pct = math.clamp(1 - (timeVal / maxCd), 0, 1)
					row.pFill.Size = UDim2.new(pct, 0, 1, 0)
				end
			end
		end
	end

	local function createMonitorWindow()
		if main then return end
		local gui = ctx.state.gui
		if not gui then return end

		-- Floating Pet Monitor window
		main = mk("Frame", {
			Size = UDim2.fromOffset(300, 420),
			Position = UDim2.new(0.5, -520, 0.5, -210), -- di sebelah kiri main window
			BackgroundColor3 = C.bg,
			BorderSizePixel = 0,
			Active = true,
			Visible = false,
		}, gui)
		corner(main, 12); stroke(main, C.stroke, 1)

		-- Title Bar
		local titleBar = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 1,
		}, main)
		
		-- Yellow dot
		local titleDot = mk("Frame", {
			Size = UDim2.fromOffset(8, 8),
			Position = UDim2.new(0, 16, 0.5, -4),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
		}, titleBar)
		corner(titleDot, 4)

		local titleLbl = mk("TextLabel", {
			Size = UDim2.new(1, -130, 1, 0),
			Position = UDim2.fromOffset(32, 0),
			BackgroundTransparency = 1,
			Text = "Pet Monitor",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, titleBar)

		-- Pet Count Badge (yellow circular badge)
		local badge = mk("Frame", {
			Size = UDim2.fromOffset(22, 22),
			Position = UDim2.new(1, -94, 0.5, -11),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
		}, titleBar)
		corner(badge, 11)
		badgeLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "0",
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = C.panel,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, badge)

		local minBtn = mk("TextButton", {
			Size = UDim2.fromOffset(26, 26),
			Position = UDim2.new(1, -62, 0, 9),
			BackgroundColor3 = C.row,
			Text = "—",
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = C.txt,
			AutoButtonColor = true,
		}, titleBar)
		corner(minBtn, 6)

		local closeBtn = mk("TextButton", {
			Size = UDim2.fromOffset(26, 26),
			Position = UDim2.new(1, -30, 0, 9),
			BackgroundColor3 = C.red,
			Text = "✕",
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = true,
		}, titleBar)
		corner(closeBtn, 6)

		-- Dragging
		do
			local dragging, ds, sp
			titleBar.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = true; ds = i.Position; sp = main.Position
				end
			end)
			UserInputService.InputChanged:Connect(function(i)
				if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
					local d = i.Position - ds
					main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
				end
			end)
			UserInputService.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
		end

		-- Scrolling list of pets
		scroll = mk("ScrollingFrame", {
			Size = UDim2.new(1, -16, 1, -54),
			Position = UDim2.fromOffset(8, 46),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = "Y",
			ScrollBarImageColor3 = C.acc,
		}, main)
		local listLayout = mk("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, scroll)

		-- Event handlers
		minBtn.MouseButton1Click:Connect(function()
			main.Visible = false
			ctx.state.pnpMonitorBtnRender() -- sync toggle UI state
		end)
		closeBtn.MouseButton1Click:Connect(function()
			main.Visible = false
			ctx.CFG.pnpMonitorEnabled = false
			ctx.persistState()
			ctx.state.pnpMonitorBtnRender() -- sync toggle
		end)
	end

	-- Thread pemantau update visual
	task.spawn(function()
		while ctx.alive() do
			pcall(updateMonitor)
			task.wait(0.15)
		end
	end)

	function ctx.showPetMonitor()
		createMonitorWindow()
		if main then
			main.Visible = true
			updateMonitor()
		end
	end

	function ctx.hidePetMonitor()
		if main then
			main.Visible = false
		end
	end

	-- Lazy activation jika diaktifkan dari config (dipanggil di app.lua setelah GUI siap)
	task.spawn(function()
		task.wait(1.5)
		if ctx.CFG.pnpMonitorEnabled then
			ctx.showPetMonitor()
		end
	end)
end
