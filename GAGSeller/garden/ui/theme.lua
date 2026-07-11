--[[ theme.lua — palet + helper Instance (garden, aksen kuning ala referensi). ]]
return function(ctx)
	local C = {
		bg      = Color3.fromRGB(20, 22, 28),
		panel   = Color3.fromRGB(14, 16, 20),
		row     = Color3.fromRGB(26, 29, 36),
		rowAlt  = Color3.fromRGB(22, 25, 31),
		stroke  = Color3.fromRGB(40, 44, 54),
		acc     = Color3.fromRGB(245, 200, 45),   -- kuning
		txt     = Color3.fromRGB(238, 240, 245),
		sub     = Color3.fromRGB(140, 146, 158),
		green   = Color3.fromRGB(90, 200, 120),
		red     = Color3.fromRGB(220, 80, 80),
	}

	local function mk(cls, props, parent)
		local o = Instance.new(cls); for k, v in pairs(props) do o[k] = v end; o.Parent = parent; return o
	end
	local function corner(o, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end
	local function stroke(o, col, thick)
		return mk("UIStroke", { Color = col or C.stroke, Thickness = thick or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	end
	local function pad(o, l, r, t, b)
		mk("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r), PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b) }, o)
	end

	ctx.C = C; ctx.mk = mk; ctx.corner = corner; ctx.stroke = stroke; ctx.pad = pad
end
