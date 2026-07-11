--[[
	GAG Hub — GARDEN app (SCAFFOLD)
	Dipanggil oleh router GAGSeller/init.lua saat berada di server Garden.
	Untuk sekarang baru RANGKA: GUI jalan + placeholder. Fitur menyusul.

	Menambah fitur nanti tinggal ikuti pola trade/ (pecah jadi modules/ + ui/).
	Sementara ini sengaja self-contained satu file biar ringkas.
--]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until Players.LocalPlayer
local LP = Players.LocalPlayer

------------------------------------------------------------------ theme (samakan dengan trade)
local C = {
	bg     = Color3.fromRGB(15, 15, 20),
	panel  = Color3.fromRGB(10, 10, 12),
	row    = Color3.fromRGB(24, 24, 30),
	stroke = Color3.fromRGB(35, 35, 45),
	acc    = Color3.fromRGB(80, 200, 120),   -- Garden = hijau (beda dari trade yang ungu)
	txt    = Color3.fromRGB(240, 240, 245),
	sub    = Color3.fromRGB(140, 140, 150),
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

------------------------------------------------------------------ bersihkan GUI lama
pcall(function()
	local host = (gethui and gethui()) or game:GetService("CoreGui")
	local old = host:FindFirstChild("GAGGarden"); if old then old:Destroy() end
	local pg = LP:FindFirstChild("PlayerGui")
	if pg and pg:FindFirstChild("GAGGarden") then pg.GAGGarden:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "GAGGarden"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LP:WaitForChild("PlayerGui")

------------------------------------------------------------------ floating maximize
local maxIcon = mk("TextButton", {
	Size = UDim2.fromOffset(45, 45), Position = UDim2.new(0, 15, 0.5, -22),
	BackgroundColor3 = C.panel, Text = "GG", Font = Enum.Font.GothamBold, TextSize = 14,
	TextColor3 = C.acc, Visible = false, Active = true,
}, gui)
corner(maxIcon, 22); stroke(maxIcon, C.acc, 1.5)

------------------------------------------------------------------ main window
local main = mk("Frame", {
	Size = UDim2.fromOffset(420, 300), Position = UDim2.new(0.5, -210, 0.5, -150),
	BackgroundColor3 = C.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Active = true,
}, gui)
corner(main, 10); stroke(main, C.stroke, 1)

local titleBar = mk("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, main)
do
	local dragging, ds, sp
	titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = main.Position end end)
	UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end

mk("TextLabel", {
	Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1,
	Text = "PandoruyHub | GAG Garden", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.acc,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

local minBtn = mk("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -64, 0, 7), BackgroundColor3 = C.row, Text = "—", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.txt }, titleBar)
corner(minBtn, 6)
local closeBtn = mk("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0, 7), BackgroundColor3 = C.row, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.txt }, titleBar)
corner(closeBtn, 6)
minBtn.MouseButton1Click:Connect(function() main.Visible = false; maxIcon.Visible = true end)
maxIcon.MouseButton1Click:Connect(function() maxIcon.Visible = false; main.Visible = true end)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

------------------------------------------------------------------ body (placeholder)
local body = mk("Frame", { Size = UDim2.new(1, -24, 1, -52), Position = UDim2.fromOffset(12, 46), BackgroundColor3 = C.row, BorderSizePixel = 0 }, main)
corner(body, 8); stroke(body)
pad(body, 16, 16, 16, 16)
mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, body)

mk("TextLabel", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "🌱 Garden Mode", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, body)
mk("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "Kamu berada di server Garden.\nFitur garden masih dalam pengembangan (rangka).", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, LayoutOrder = 2 }, body)
mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = ("PlaceId: %s"):format(tostring(game.PlaceId)), Font = Enum.Font.Code, TextSize = 11, TextColor3 = C.acc, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3 }, body)

print("[GAGGarden] scaffold dimuat. PlaceId=" .. tostring(game.PlaceId))
