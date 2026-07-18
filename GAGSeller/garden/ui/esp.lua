--[[ esp.lua — label melayang (BillboardGui) di dunia 3D di atas tiap egg.
     Egg: nama egg + sisa waktu hatch (TimeToHatch) / READY.
     Toggle: CFG.espEnabled. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local bbFolder
	local billboards = {} -- key -> { gui, name, sub }

	local function ensureFolder()
		if bbFolder and bbFolder.Parent then return bbFolder end
		bbFolder = Instance.new("Folder")
		bbFolder.Name = "AllegiaanESP"
		bbFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
		return bbFolder
	end

	local function partOf(model)
		if model:IsA("BasePart") then return model end
		if model.PrimaryPart then return model.PrimaryPart end
		for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end

	local function makeBB(key, adornee, offset)
		local bb = Instance.new("BillboardGui")
		bb.Name = "esp_" .. key
		bb.Adornee = adornee
		bb.Size = UDim2.fromOffset(230, 46)
		bb.StudsOffset = Vector3.new(0, offset or 2.5, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 600
		bb.LightInfluence = 0
		bb.ClipsDescendants = false
		bb.Parent = ensureFolder()

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, 0, 0.55, 0)
		name.Font = Enum.Font.GothamBold
		name.TextSize = 15
		name.TextColor3 = Color3.fromRGB(245, 220, 90)
		name.TextStrokeTransparency = 0.25
		name.TextStrokeColor3 = Color3.new(0, 0, 0)
		name.Parent = bb

		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Position = UDim2.new(0, 0, 0.55, 0)
		sub.Size = UDim2.new(1, 0, 0.45, 0)
		sub.Font = Enum.Font.GothamBold
		sub.TextSize = 13
		sub.TextColor3 = Color3.fromRGB(235, 235, 235)
		sub.TextStrokeTransparency = 0.25
		sub.TextStrokeColor3 = Color3.new(0, 0, 0)
		sub.Parent = bb

		local rec = { gui = bb, name = name, sub = sub }
		billboards[key] = rec
		return rec
	end

	local function fmtTime(sec)
		sec = math.max(0, math.floor(sec))
		local m = math.floor(sec / 60)
		local s = sec % 60
		if m >= 60 then
			local h = math.floor(m / 60); m = m % 60
			return string.format("%dh %dm", h, m)
		end
		return string.format("%dm %02ds", m, s)
	end

	-- ambil/bikin billboard buat adornee tertentu (recreate kalau adornee ganti)
	local function acquire(key, adornee, offset)
		local rec = billboards[key]
		if (not rec) or rec.gui.Adornee ~= adornee or not rec.gui.Parent then
			if rec then rec.gui:Destroy(); billboards[key] = nil end
			rec = makeBB(key, adornee, offset)
		end
		return rec
	end

	-- nama egg: attribute EggName, fallback ke child Model (persist walau ready)
	local function eggNameOf(e)
		local n = e:GetAttribute("EggName")
		if not n or n == "" then
			for _, c in ipairs(e:GetChildren()) do
				if c:IsA("Model") then n = c.Name; break end
			end
		end
		return n or "Egg"
	end

	local function update()
		local seen = {}

		-- ===== EGG saja =====
		local farm; pcall(function() farm = require(RS.Modules.GetFarm)(LP) end)
		if farm then
			for _, e in ipairs(farm:GetDescendants()) do
				if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then
					local adornee = e:FindFirstChild("PetEgg") or partOf(e)
					if adornee then
						local key = "egg_" .. tostring(e:GetAttribute("OBJECT_UUID") or e:GetDebugId())
						seen[key] = true
						local rec = acquire(key, adornee, 3)
						rec.name.Text = eggNameOf(e)
						rec.name.TextColor3 = Color3.fromRGB(120, 235, 120)
						local t = tonumber(e:GetAttribute("TimeToHatch")) or 0
						if t <= 0 then
							rec.sub.Text = "READY"
							rec.sub.TextColor3 = Color3.fromRGB(120, 235, 120)
						else
							rec.sub.Text = "\u{23F1} " .. fmtTime(t)
							rec.sub.TextColor3 = Color3.fromRGB(255, 180, 80)
						end
					end
				end
			end
		end

		-- cleanup billboard yg targetnya udah ilang
		for key, rec in pairs(billboards) do
			if not seen[key] then rec.gui:Destroy(); billboards[key] = nil end
		end
	end

	local function clearAll()
		for _, rec in pairs(billboards) do pcall(function() rec.gui:Destroy() end) end
		billboards = {}
		if bbFolder then pcall(function() bbFolder:Destroy() end); bbFolder = nil end
	end

	local loopId = 0
	function ctx.startEsp()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			clearAll()
		end)
	end

	function ctx.stopEsp()
		loopId = loopId + 1
		clearAll()
	end
end
