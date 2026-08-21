--[[ app.lua — init akhir garden: default tab Inventory + auto-resume automation. ]]
return function(ctx)
	local CFG = ctx.CFG
	local pages = ctx.ui.pages
	local tabBtns = ctx.ui.tabBtns
	local C = ctx.C

	-- toast "loaded" di pojok kanan bawah
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		local old = host:FindFirstChild("AHNotif"); if old then old:Destroy() end
		local sg = Instance.new("ScreenGui")
		sg.Name = "AHNotif"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.DisplayOrder = 9999; sg.Parent = host
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(1, 1)
		f.Position = UDim2.new(1, 280, 1, -20)     -- mulai di luar layar (buat slide-in)
		f.Size = UDim2.fromOffset(250, 62)
		f.BackgroundColor3 = C.panel or Color3.fromRGB(24, 26, 31)
		f.BorderSizePixel = 0; f.Parent = sg
		local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = f
		local strk = Instance.new("UIStroke"); strk.Color = C.acc or Color3.fromRGB(246, 197, 24); strk.Thickness = 1.2; strk.Transparency = 0.3; strk.Parent = f
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 14); pad.PaddingTop = UDim.new(0, 10); pad.Parent = f
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1; title.Size = UDim2.new(1, -14, 0, 18)
		title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left
		title.RichText = true; title.Text = 'AllegiaantHub <font color="#f6c518">Notification</font>'
		title.TextColor3 = C.txt or Color3.fromRGB(235, 238, 242); title.Parent = f
		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1; body.Size = UDim2.new(1, -14, 0, 16); body.Position = UDim2.fromOffset(0, 24)
		body.Font = Enum.Font.Gotham; body.TextSize = 13; body.TextXAlignment = Enum.TextXAlignment.Left
		body.Text = "Loaded"; body.TextColor3 = C.sub or Color3.fromRGB(150, 155, 163); body.Parent = f
		local TS = game:GetService("TweenService")
		TS:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(1, -20, 1, -20) }):Play()
		task.delay(3, function()
			pcall(function()
				TS:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(1, 280, 1, -20) }):Play()
				task.wait(0.45); sg:Destroy()
			end)
		end)
	end)

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

	ctx.log("AllegiaantHub Garden dimuat.")
	ctx.setStatus("idle")

	-- Anti-AFK: reset timer idle Roblox (kick ~20 menit) tiap Idled fire, via VirtualUser.
	pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		ctx.LP.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
			ctx.log("Anti-AFK: reset idle timer.")
		end)
		ctx.log("Anti-AFK aktif.")
	end)

	-- auto-resume Auto Chest Hunt kalau sebelumnya aktif (listener event udah kepasang di modul)
	if CFG.chestHuntEnabled and ctx.startChestHunt then
		ctx.startChestHunt()
		ctx.log("Auto-resume: Chest Hunt ON (nunggu/ikut event).")
	end

	-- auto-resume ESP label kalau sebelumnya aktif
	if CFG.espEnabled and ctx.startEsp then
		ctx.startEsp()
		ctx.log("Auto-resume: ESP Label ON.")
	end

	-- auto-resume Auto Reclaimer kalau sebelumnya aktif
	if CFG.reclaimEnabled and ctx.startReclaim then
		ctx.startReclaim()
		ctx.log("Auto-resume: Auto Reclaimer ON.")
	end

	-- auto-resume Auto Plants kalau sebelumnya aktif
	if CFG.plantSeedEnabled and ctx.startPlant then
		ctx.startPlant()
		ctx.log("Auto-resume: Auto Plants ON.")
	end

	-- auto-resume Auto Sprinkler + Shovel Sprinkler
	if CFG.sprinklerEnabled and ctx.startSprinkler then
		ctx.startSprinkler()
		ctx.log("Auto-resume: Auto Sprinkler ON.")
	end
	if CFG.shovelSprinklerEnabled and ctx.startShovelSprinkler then
		ctx.startShovelSprinkler()
		ctx.log("Auto-resume: Auto Shovel Sprinkler ON.")
	end

	-- auto-resume Auto Reconnect (biar loop rejoin lanjut tiap masuk server)
	if CFG.reconnectEnabled and ctx.startReconnect then
		ctx.startReconnect()
		ctx.log("Auto-resume: Auto Reconnect ON.")
	end

	-- auto-resume PNP kalau sebelumnya aktif (V1 polling / V2 event-driven, mutually exclusive)
	if CFG.pnpEnabled and ctx.startPnpV1 then
		task.wait(1)
		ctx.startPnpV1()
		ctx.log("Auto-resume: PNP V1 ON.")
	elseif CFG.pnpV2Enabled and ctx.startPnpV2 then
		task.wait(1)
		ctx.startPnpV2()
		ctx.log("Auto-resume: PNP V2 ON.")
	end

	-- auto-resume kalau sebelumnya aktif
	if CFG.tradeEnabled then
		task.wait(1.5)
		ctx.state.completed = 0
		ctx.startTrade()
		ctx.refreshTradeStatus()
		ctx.log("Auto-resume: automation trade ON.")
	end

	-- auto-resume Leveling kalau sebelumnya aktif
	if CFG.levelingEnabled and ctx.startLeveling then
		task.wait(2.0)
		ctx.startLeveling()
		ctx.log("Auto-resume: Leveling ON.")
	end

	-- auto-resume Leveling V2 kalau sebelumnya aktif
	if CFG.levelingV2Enabled and ctx.startLevelingV2 then
		task.wait(2.0)
		ctx.startLevelingV2()
		ctx.log("Auto-resume: Leveling V2 ON.")
	end

	-- auto-resume Auto Hatch kalau sebelumnya aktif
	if CFG.hatchEnabled and ctx.startHatch then
		task.wait(2.0)
		ctx.startHatch()
		ctx.log("Auto-resume: Auto Hatch ON.")
	end

	-- auto-resume Auto Favourite Pets kalau sebelumnya aktif
	if CFG.autoFavorite and ctx.startAutoFavorite then
		ctx.startAutoFavorite()
		ctx.log("Auto-resume: Auto Favourite ON.")
	end

	-- auto-resume Growth kalau sebelumnya aktif
	if CFG.growthEnabled and ctx.startGrowth then
		task.wait(2.0)
		ctx.startGrowth()
		ctx.log("Auto-resume: Growth ON.")
	end

	-- auto-resume Mutation kalau sebelumnya aktif
	if CFG.mutationEnabled and ctx.startMutation then
		task.wait(2.5)
		ctx.startMutation()
		ctx.log("Auto-resume: Mutation ON.")
	end

	-- auto-resume Elephant kalau sebelumnya aktif
	if CFG.elephantEnabled and ctx.startElephant then
		task.wait(2.5)
		ctx.startElephant()
		ctx.log("Auto-resume: Elephant ON.")
	end

	if CFG.elephantV2Enabled and ctx.startElephantV2 then
		task.wait(2.5)
		ctx.startElephantV2()
		ctx.log("Auto-resume: Elephant V2 ON.")
	end

	-- auto-resume Boost Pet kalau sebelumnya aktif
	if CFG.boostEnabled and ctx.startBoostPet then
		task.wait(2.5)
		ctx.startBoostPet()
		ctx.log("Auto-resume: Boost Pet ON.")
	end

	-- auto-resume Cleanse kalau sebelumnya aktif
	if CFG.cleanseEnabled and ctx.startCleanse then
		task.wait(2.5)
		ctx.startCleanse()
		ctx.log("Auto-resume: Cleanse ON.")
	end

	-- auto-resume Summer Event (Sam The Clam) kalau sebelumnya aktif
	if CFG.summerEventEnabled and ctx.startSummerEvent then
		task.wait(2.5)
		ctx.startSummerEvent()
		ctx.log("Auto-resume: Summer Event ON.")
	end

	-- auto-resume Shop (buy seed/egg/gear)
	if CFG.buySeedEnabled and ctx.startBuySeed then ctx.startBuySeed(); ctx.log("Auto-resume: Buy Seed ON.") end
	if CFG.buyEggEnabled and ctx.startBuyEgg then ctx.startBuyEgg(); ctx.log("Auto-resume: Buy Egg ON.") end
	if CFG.buyGearEnabled and ctx.startBuyGear then ctx.startBuyGear(); ctx.log("Auto-resume: Buy Gear ON.") end
	if CFG.waterEnabled and ctx.startWater then ctx.startWater(); ctx.log("Auto-resume: Auto Water ON.") end
	if CFG.shovelTreeEnabled and ctx.startShovelTree then ctx.startShovelTree(); ctx.log("Auto-resume: Auto Shovel Tree ON.") end
	if CFG.shovelFruitEnabled and ctx.startShovelFruit then ctx.startShovelFruit(); ctx.log("Auto-resume: Auto Shovel Fruit ON.") end
	if (CFG.collectWlFruitEnabled or CFG.collectWlMutEnabled or CFG.collectCombEnabled) and ctx.startCollect then
		ctx.startCollect(); ctx.log("Auto-resume: Auto Collect ON.")
	end
	if (CFG.favEnabled or CFG.unfavEnabled) and ctx.startFavorite then
		ctx.startFavorite(); ctx.log("Auto-resume: Auto Favorite ON.")
	end
	if CFG.buySummerSeedEnabled and ctx.startBuySummerSeed then ctx.startBuySummerSeed(); ctx.log("Auto-resume: Buy Summer Seed ON.") end
	if CFG.buyTideTokenEnabled and ctx.startBuyTideToken then ctx.startBuyTideToken(); ctx.log("Auto-resume: Buy Tide Token ON.") end
end
