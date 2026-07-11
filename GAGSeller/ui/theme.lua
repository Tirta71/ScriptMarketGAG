--[[ theme.lua — palet warna + helper pembuat Instance.
     Mengisi: ctx.C (warna), ctx.mk, ctx.corner, ctx.stroke, ctx.pad ]]
return function(ctx)
	local C = {
		bg     = Color3.fromRGB(15, 15, 20),      -- Jendela utama transparan
		panel  = Color3.fromRGB(10, 10, 12),      -- Left sidebar
		row    = Color3.fromRGB(24, 24, 30),      -- Kartu setting / baris
		stroke = Color3.fromRGB(35, 35, 45),      -- Pembatas kartu
		acc    = Color3.fromRGB(120, 80, 255),    -- Neon Purple
		txt    = Color3.fromRGB(240, 240, 245),
		sub    = Color3.fromRGB(140, 140, 150),
		green  = Color3.fromRGB(80, 200, 120),
		red    = Color3.fromRGB(220, 80, 80),
	}

	local function mk(cls, props, parent)
		local o = Instance.new(cls)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end

	local function corner(o, r)
		mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
	end

	local function stroke(o, col, thick)
		return mk("UIStroke", {
			Color = col or C.stroke, Thickness = thick or 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, o)
	end

	local function pad(o, l, r, t, b)
		mk("UIPadding", {
			PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r),
			PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b),
		}, o)
	end

	ctx.C      = C
	ctx.mk     = mk
	ctx.corner = corner
	ctx.stroke = stroke
	ctx.pad    = pad
end
