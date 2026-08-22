--[[ esp_inventory.lua — ESP Base Weight di INVENTORY (Pet Items).
     Nempel label kecil "Base X.XX KG" di tiap slot pet di backpack GUI,
     jadi pas buka inventory langsung keliatan BaseWeight tiap pet.
     Mapping: slot.ToolName.Text == Tool.Name -> Tool.PET_UUID ->
              PetData.BaseWeight (dari DataService).
     Toggle: CFG.espInvEnabled. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	local GRID_PATH = { "BackpackGui", "Backpack", "Inventory", "ScrollingFrame", "UIGridFrame" }
	local LBL_NAME  = "AH_BaseW" -- label yg kita tempel di slot

	-- ambil UIGridFrame (tempat slot-slot pet). nil kalau backpack belum ke-load.
	local function grid()
		local n = LP:FindFirstChild("PlayerGui")
		for _, seg in ipairs(GRID_PATH) do
			if not n then return nil end
			n = n:FindFirstChild(seg)
		end
		return n
	end

	-- map Tool.Name -> BaseWeight (cuma pet). Dibangun tiap refresh (ratusan tool, murah).
	local function buildWeightMap()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local byUuid = {}
		for uuid, v in pairs(inv) do
			local pd = v.PetData or {}
			if pd.BaseWeight then byUuid[uuid] = pd.BaseWeight end
		end
		local byName = {}
		local function scan(where)
			if not where then return end
			for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("ItemType") == "Pet" then
					local uuid = t:GetAttribute("PET_UUID")
					local bw = uuid and byUuid[uuid]
					if bw and byName[t.Name] == nil then byName[t.Name] = bw end
				end
			end
		end
		scan(LP.Character)
		scan(LP:FindFirstChildOfClass("Backpack"))
		return byName
	end

	-- tempel/refresh label base weight di slot; hapus dari slot non-pet.
	local function setLabel(slot, bw)
		local lbl = slot:FindFirstChild(LBL_NAME)
		if not bw then
			if lbl then lbl:Destroy() end
			return
		end
		if not lbl then
			lbl = Instance.new("TextLabel")
			lbl.Name = LBL_NAME
			lbl.AnchorPoint = Vector2.new(0.5, 1)
			lbl.Position = UDim2.new(0.5, 0, 1, -1)
			lbl.Size = UDim2.new(1, -4, 0, 14)
			lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			lbl.BackgroundTransparency = 0.35
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 11
			lbl.TextColor3 = Color3.fromRGB(124, 240, 255)
			lbl.TextStrokeTransparency = 0.4
			lbl.ZIndex = 20
			lbl.RichText = false
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = lbl
			lbl.Parent = slot
		end
		lbl.Text = ("Base %.2f KG"):format(bw)
	end

	local function clearAll()
		local g = grid()
		if not g then return end
		for _, slot in ipairs(g:GetChildren()) do
			if slot:IsA("GuiButton") then
				local lbl = slot:FindFirstChild(LBL_NAME)
				if lbl then lbl:Destroy() end
			end
		end
	end

	local function update()
		local g = grid()
		if not g then return end
		local byName = buildWeightMap()
		for _, slot in ipairs(g:GetChildren()) do
			if slot:IsA("GuiButton") then
				local tn = slot:FindFirstChild("ToolName")
				local name = tn and tn:IsA("TextLabel") and tn.Text or nil
				setLabel(slot, name and byName[name] or nil)
			end
		end
	end

	local loopId = 0
	function ctx.startEspInv()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espInvEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			pcall(clearAll)
		end)
	end

	function ctx.stopEspInv()
		loopId = loopId + 1
		pcall(clearAll)
	end
end
