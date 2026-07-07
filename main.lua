--[[
	LRXUI.lua — Professional Roblox UI Framework
	Version 1.0.0
	Single-file distribution
]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local TextService = cloneref(game:GetService("TextService"))
local SoundService = cloneref(game:GetService("SoundService"))
local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

local function protect(instance)
	local ok, result = pcall(function()
		return syn and syn.protect_gui(instance)
	end)
	if not ok then
		pcall(function()
			instance.Parent = gethui and gethui() or CoreGui
		end)
	end
	return ok
end

local Design = {
	Corner = 6,
	CornerSmall = 4,
	CornerLarge = 8,
	WindowCorner = 8,
	HeaderHeight = 44,
	FooterHeight = 24,
	SidebarWidth = 200,
	SidebarCollapsed = 48,
	CardPad = 12,
	CardGap = 8,
	ContentPad = 16,
	ItemHeight = 32,
	ItemGap = 6,
	SmallGap = 4,
	FontSize_Title = 18,
	FontSize_Header = 15,
	FontSize_Body = 14,
	FontSize_Small = 12,
	FontSize_Tiny = 11,
	AnimationFast = 0.12,
	AnimationNormal = 0.2,
	AnimationSlow = 0.35,
	TweenEase = Enum.EasingStyle.Quad,
	TweenDir = Enum.EasingDirection.Out,
	ScrollbarThickness = 4,
	TooltipDelay = 0.4,
	NotifyWidth = 320,
	NotifyGap = 6,
	NotifyDuration = 5,
}

do
	local raw = Design
	local E = Enum.EasingStyle
	raw.Info = TweenInfo.new(raw.AnimationFast, raw.TweenEase, raw.TweenDir)
	raw.InfoNormal = TweenInfo.new(raw.AnimationNormal, raw.TweenEase, raw.TweenDir)
	raw.InfoSlow = TweenInfo.new(raw.AnimationSlow, raw.TweenEase, raw.TweenDir)
	raw.InfoLinear = TweenInfo.new(raw.AnimationNormal, E.Linear, Enum.EasingDirection.InOut)
end

local Schemes = {
	Dark = {
		Background = Color3.fromRGB(15, 17, 22),
		Sidebar = Color3.fromRGB(21, 23, 29),
		Content = Color3.fromRGB(18, 20, 25),
		Surface = Color3.fromRGB(29, 32, 39),
		SurfaceAlt = Color3.fromRGB(37, 40, 48),
		Border = Color3.fromRGB(53, 57, 67),
		BorderFaint = Color3.fromRGB(42, 45, 54),
		Text = Color3.fromRGB(255, 255, 255),
		SubText = Color3.fromRGB(170, 170, 175),
		Muted = Color3.fromRGB(120, 120, 125),
		Accent = Color3.fromRGB(88, 166, 255),
		AccentDim = Color3.fromRGB(60, 120, 200),
		Success = Color3.fromRGB(60, 210, 120),
		Warning = Color3.fromRGB(255, 195, 90),
		Danger = Color3.fromRGB(255, 90, 90),
		DangerDim = Color3.fromRGB(200, 60, 60),
		Scrollbar = Color3.fromRGB(70, 74, 82),
		ScrollbarHover = Color3.fromRGB(90, 95, 105),
		Overlay = Color3.fromRGB(0, 0, 0),
	},
	Light = {
		Background = Color3.fromRGB(245, 245, 250),
		Sidebar = Color3.fromRGB(235, 235, 242),
		Content = Color3.fromRGB(250, 250, 255),
		Surface = Color3.fromRGB(255, 255, 255),
		SurfaceAlt = Color3.fromRGB(240, 240, 248),
		Border = Color3.fromRGB(210, 210, 220),
		BorderFaint = Color3.fromRGB(225, 225, 235),
		Text = Color3.fromRGB(20, 20, 30),
		SubText = Color3.fromRGB(100, 100, 115),
		Muted = Color3.fromRGB(160, 160, 170),
		Accent = Color3.fromRGB(50, 120, 220),
		AccentDim = Color3.fromRGB(70, 140, 240),
		Success = Color3.fromRGB(40, 180, 90),
		Warning = Color3.fromRGB(220, 165, 50),
		Danger = Color3.fromRGB(220, 60, 60),
		DangerDim = Color3.fromRGB(180, 40, 40),
		Scrollbar = Color3.fromRGB(190, 192, 200),
		ScrollbarHover = Color3.fromRGB(170, 172, 180),
		Overlay = Color3.fromRGB(0, 0, 0),
	},
	DarkSlate = {
		Background = Color3.fromRGB(10, 12, 16),
		Sidebar = Color3.fromRGB(16, 18, 24),
		Content = Color3.fromRGB(13, 15, 20),
		Surface = Color3.fromRGB(23, 26, 33),
		SurfaceAlt = Color3.fromRGB(31, 34, 42),
		Border = Color3.fromRGB(45, 49, 58),
		BorderFaint = Color3.fromRGB(36, 39, 48),
		Text = Color3.fromRGB(225, 230, 240),
		SubText = Color3.fromRGB(155, 160, 170),
		Muted = Color3.fromRGB(105, 110, 120),
		Accent = Color3.fromRGB(100, 180, 255),
		AccentDim = Color3.fromRGB(70, 140, 220),
		Success = Color3.fromRGB(50, 200, 110),
		Warning = Color3.fromRGB(255, 185, 80),
		Danger = Color3.fromRGB(255, 80, 80),
		DangerDim = Color3.fromRGB(200, 55, 55),
		Scrollbar = Color3.fromRGB(60, 65, 75),
		ScrollbarHover = Color3.fromRGB(80, 85, 95),
		Overlay = Color3.fromRGB(0, 0, 0),
	},
	NordicFrost = {
		Background = Color3.fromRGB(12, 18, 28),
		Sidebar = Color3.fromRGB(18, 24, 36),
		Content = Color3.fromRGB(15, 21, 32),
		Surface = Color3.fromRGB(26, 33, 46),
		SurfaceAlt = Color3.fromRGB(34, 42, 56),
		Border = Color3.fromRGB(60, 90, 130),
		BorderFaint = Color3.fromRGB(45, 65, 95),
		Text = Color3.fromRGB(200, 220, 255),
		SubText = Color3.fromRGB(140, 165, 200),
		Muted = Color3.fromRGB(100, 125, 160),
		Accent = Color3.fromRGB(75, 200, 255),
		AccentDim = Color3.fromRGB(55, 160, 220),
		Success = Color3.fromRGB(60, 220, 140),
		Warning = Color3.fromRGB(255, 210, 100),
		Danger = Color3.fromRGB(255, 100, 100),
		DangerDim = Color3.fromRGB(200, 65, 65),
		Scrollbar = Color3.fromRGB(70, 95, 130),
		ScrollbarHover = Color3.fromRGB(90, 120, 160),
		Overlay = Color3.fromRGB(0, 0, 0),
	},
	AmberGold = {
		Background = Color3.fromRGB(18, 16, 12),
		Sidebar = Color3.fromRGB(24, 21, 16),
		Content = Color3.fromRGB(21, 19, 14),
		Surface = Color3.fromRGB(33, 30, 24),
		SurfaceAlt = Color3.fromRGB(42, 38, 30),
		Border = Color3.fromRGB(100, 85, 55),
		BorderFaint = Color3.fromRGB(75, 65, 40),
		Text = Color3.fromRGB(255, 240, 210),
		SubText = Color3.fromRGB(190, 175, 145),
		Muted = Color3.fromRGB(140, 130, 105),
		Accent = Color3.fromRGB(255, 185, 65),
		AccentDim = Color3.fromRGB(220, 150, 40),
		Success = Color3.fromRGB(100, 220, 100),
		Warning = Color3.fromRGB(255, 200, 50),
		Danger = Color3.fromRGB(255, 90, 70),
		DangerDim = Color3.fromRGB(210, 60, 45),
		Scrollbar = Color3.fromRGB(100, 90, 65),
		ScrollbarHover = Color3.fromRGB(130, 115, 85),
		Overlay = Color3.fromRGB(0, 0, 0),
	},
}

local CurrentScheme = Schemes.Dark
local Palette = CurrentScheme

local Registry = {
	ThemeLinks = {},
	DPIEntries = {},
	Connections = {},
	Windows = {},
	Pages = {},
	Cards = {},
	Components = {},
	Notifications = {},
	Dialogs = {},
	DependencyBoxes = {},
	OnUnload = {},
}

local function AddThemeLink(instance, property, key)
	local links = Registry.ThemeLinks[instance]
	if not links then
		links = {}
		Registry.ThemeLinks[instance] = links
	end
	links[property] = key
end

local function RemoveThemeLink(instance)
	Registry.ThemeLinks[instance] = nil
end

local function ApplyTheme()
	for instance, props in pairs(Registry.ThemeLinks) do
		for prop, key in pairs(props) do
			local value = Palette[key]
			if value then
				instance[prop] = value
			elseif type(key) == "function" then
				instance[prop] = key()
			end
		end
	end
end

local function AddDPIEntry(instance, property, baseValue)
	local entries = Registry.DPIEntries[instance]
	if not entries then
		entries = {}
		Registry.DPIEntries[instance] = entries
	end
	entries[property] = baseValue
end

local function RemoveDPIEntry(instance)
	Registry.DPIEntries[instance] = nil
end

local DPIScale = 1

local function ScaleDP(value)
	if type(value) == "number" then
		return value * DPIScale
	end
	if type(value) == "UDim" then
		return UDim.new(value.Scale, value.Offset * DPIScale)
	end
	if type(value) == "UDim2" then
		return UDim2.new(value.X.Scale, value.X.Offset * DPIScale, value.Y.Scale, value.Y.Offset * DPIScale)
	end
	return value
end

local function ApplyDPI()
	for instance, props in pairs(Registry.DPIEntries) do
		for prop, base in pairs(props) do
			if prop == "TextSize" then
				instance[prop] = base * DPIScale
			elseif prop == "Position" or prop == "Size" or prop:match("Padding") then
				instance[prop] = ScaleDP(base)
			end
		end
	end
end

local function SetDPIScale(percent)
	DPIScale = percent / 100
	ApplyDPI()
	ApplyTheme()
	for _, win in pairs(Registry.Windows) do
		if win.ResizeAll then
			win:ResizeAll()
		end
	end
end

local function Connect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(Registry.Connections, conn)
	return conn
end

local function DisconnectAll()
	for i = #Registry.Connections, 1, -1 do
		local c = Registry.Connections[i]
		if c and c.Connected then
			c:Disconnect()
		end
		Registry.Connections[i] = nil
	end
	for _, cb in pairs(Registry.OnUnload) do
		pcall(cb)
	end
end

local function IsHover(input)
	return (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
		and input.UserInputState == Enum.UserInputState.Change
end

local function IsClick(input)
	return (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
		and input.UserInputState == Enum.UserInputState.Begin
end

local function IsDrag(input)
	return (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
		and (input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change)
end

local function Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

local function Round(value, decimals)
	decimals = decimals or 0
	if decimals == 0 then
		return math.floor(value + 0.5)
	end
	local mult = 10 ^ decimals
	return math.floor(value * mult + 0.5) / mult
end

local function Trim(str)
	return str:match("^%s*(.-)%s*$") or ""
end

local function TableSize(t)
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

local function CopyTable(t)
	if type(t) ~= "table" then
		return t
	end
	local result = {}
	for k, v in pairs(t) do
		result[k] = CopyTable(v)
	end
	return result
end

local function MergeDefaults(t, defaults)
	if type(t) ~= "table" then
		return CopyTable(defaults)
	end
	local result = CopyTable(t)
	for k, v in pairs(defaults) do
		if result[k] == nil then
			result[k] = type(v) == "table" and CopyTable(v) or v
		elseif type(v) == "table" and type(result[k]) == "table" then
			result[k] = MergeDefaults(result[k], v)
		end
	end
	return result
end

local function SafeCallback(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local args = { ... }
	local ok, result = xpcall(function()
		return fn(table.unpack(args))
	end, function(err)
		warn("[LRXUI]", debug.traceback(err, 2))
	end)
	if ok then
		return result
	end
end

local function GetTextBounds(text, font, size, width)
	text = tostring(text or "")
	size = tonumber(size) or 16
	width = width or workspace.CurrentCamera.ViewportSize.X - 32
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.RichText = true
		params.Size = size
		params.Width = width
		if typeof(font) == "Font" then
			params.Font = font
		elseif typeof(font) == "EnumItem" then
			params.Font = Font.fromEnum(font)
		end
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and bounds then
		return bounds.X, bounds.Y
	end
	local fallback = Enum.Font.Gotham
	if typeof(font) == "EnumItem" then
		fallback = font
	end
	local ok2, size2 = pcall(function()
		return TextService:GetTextSize(text, size, fallback, Vector2.new(width, math.huge))
	end)
	if ok2 and size2 then
		return size2.X, size2.Y
	end
	return #text * size * 0.55, size
end

local function GetDarkerColor(color, amount)
	amount = amount or 0.3
	return Color3.new(color.R * (1 - amount), color.G * (1 - amount), color.B * (1 - amount))
end

local ObsidianImageManager = {}
do
	local Assets = {
		TransparencyTexture = { RobloxId = 139785960036434, Type = "rbxassetid" },
		SaturationMap = { RobloxId = 123552107751229, Type = "rbxassetid" },
	}
	function ObsidianImageManager.GetAsset(name)
		local asset = Assets[name]
		if not asset then
			return ""
		end
		return asset.Type == "rbxassetid" and `rbxassetid://{asset.RobloxId}` or ""
	end
end

local FetchIcons, Icons
do
	local ok, result = pcall(function()
		return loadstring(
			game:HttpGet(
				"https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"
			)
		)()
	end)
	FetchIcons = ok
	Icons = ok and result or nil
end

local function GetIcon(IconName)
	if not FetchIcons or not Icons then
		return
	end
	local success, icon = pcall(Icons.GetAsset, IconName)
	if not success then
		return
	end
	return icon
end

local Animation = {}
do
	local active = {}

	function Animation.Play(target, properties, duration, easing, direction)
		if not target then
			return
		end
		local info =
			TweenInfo.new(duration or Design.AnimationNormal, easing or Design.TweenEase, direction or Design.TweenDir)
		if active[target] then
			active[target]:Cancel()
			active[target] = nil
		end
		local tween = TweenService:Create(target, info, properties)
		tween:Play()
		active[target] = tween
		local connection
		connection = tween.Completed:Connect(function()
			active[target] = nil
			if connection then
				connection:Disconnect()
			end
		end)
		return tween
	end

	function Animation.Cancel(target)
		if active[target] then
			active[target]:Cancel()
			active[target] = nil
		end
	end

	function Animation.CancelAll()
		for target, tween in pairs(active) do
			tween:Cancel()
		end
		table.clear(active)
	end

	function Animation.Spring(target, properties)
		return Animation.Play(
			target,
			properties,
			Design.AnimationNormal,
			Enum.EasingStyle.Spring,
			Enum.EasingDirection.Out
		)
	end

	function Animation.Fade(target, goal, duration)
		return Animation.Play(target, { BackgroundTransparency = goal }, duration or Design.AnimationSlow)
	end

	function Animation.Stop(instance)
		Animation.Cancel(instance)
	end
end

local F = {}
do
	local function New(className, props)
		local inst = Instance.new(className)
		for k, v in pairs(props) do
			if k ~= "Parent" and k ~= "DPIExclude" then
				local themeKey = Palette[v]
				if themeKey then
					inst[k] = themeKey
					AddThemeLink(inst, k, v)
				elseif type(v) == "function" then
					inst[k] = v()
					AddThemeLink(inst, k, v)
				else
					if not props.DPIExclude or not props.DPIExclude[k] then
						if k == "Position" or k == "Size" or k:match("Padding") then
							AddDPIEntry(inst, k, v)
							inst[k] = ScaleDP(v)
						elseif k == "TextSize" then
							AddDPIEntry(inst, k, v)
							inst[k] = ScaleDP(v)
						else
							inst[k] = v
						end
					else
						inst[k] = v
					end
				end
			end
		end
		if props.Parent then
			inst.Parent = props.Parent
		end
		return inst
	end

	function F.Create(className, props)
		return New(className, props or {})
	end

	function F.Corner(parent, radius)
		return New("UICorner", {
			CornerRadius = UDim.new(0, radius or Design.Corner),
			Parent = parent,
		})
	end

	function F.Padding(parent, padding)
		padding = padding or {}
		return New("UIPadding", {
			PaddingTop = UDim.new(0, padding.Top or 0),
			PaddingBottom = UDim.new(0, padding.Bottom or 0),
			PaddingLeft = UDim.new(0, padding.Left or 0),
			PaddingRight = UDim.new(0, padding.Right or 0),
			Parent = parent,
		})
	end

	function F.Stroke(parent, properties)
		properties = properties or {}
		return New("UIStroke", {
			Color = properties.Color or "Border",
			Thickness = properties.Thickness or 1,
			Transparency = properties.Transparency or 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = parent,
		})
	end

	function F.List(parent, direction)
		return New("UIListLayout", {
			FillDirection = direction or Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = parent,
		})
	end

	function F.Flex(parent)
		return New("UIFlexItem", { Parent = parent })
	end

	function F.Constraint(parent, minSize, maxSize)
		local c = Instance.new("UISizeConstraint")
		if minSize then
			c.MinSize = minSize
		end
		if maxSize then
			c.MaxSize = maxSize
		end
		c.Parent = parent
		return c
	end

	function F.Scroll(parent, props)
		props = props or {}
		return New("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarImageColor3 = "Scrollbar",
			ScrollBarThickness = Design.ScrollbarThickness,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			Parent = parent,
			DPIExclude = { Size = true, Position = true },
		})
	end

	function F.TextLabel(parent, props)
		props = props or {}
		return New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = props.Font or Enum.Font.Gotham,
			RichText = true,
			Text = props.Text or "",
			TextColor3 = props.Color or "Text",
			TextSize = props.Size or Design.FontSize_Body,
			TextXAlignment = props.XAlign or Enum.TextXAlignment.Left,
			TextYAlignment = props.YAlign or Enum.TextYAlignment.Top,
			TextWrapped = props.Wrapped or false,
			TextTruncate = props.Truncate or Enum.TextTruncate.None,
			Parent = parent,
		})
	end

	function F.TextButton(parent, props)
		props = props or {}
		return New("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = props.BgTransparency or 1,
			BorderSizePixel = 0,
			FontFace = props.Font or Enum.Font.Gotham,
			RichText = true,
			Text = props.Text or "",
			TextColor3 = props.Color or "Text",
			TextSize = props.Size or Design.FontSize_Body,
			TextXAlignment = props.XAlign or Enum.TextXAlignment.Left,
			Parent = parent,
		})
	end

	function F.TextBox(parent, props)
		props = props or {}
		return New("TextBox", {
			BackgroundColor3 = props.Background or "Surface",
			BorderSizePixel = 0,
			ClearTextOnFocus = props.ClearOnFocus or false,
			FontFace = props.Font or Enum.Font.Gotham,
			PlaceholderColor3 = "Muted",
			PlaceholderText = props.Placeholder or "",
			RichText = true,
			Text = props.Text or "",
			TextColor3 = props.Color or "Text",
			TextEditable = props.Editable ~= false,
			TextSize = props.Size or Design.FontSize_Body,
			TextXAlignment = props.XAlign or Enum.TextXAlignment.Left,
			Parent = parent,
		})
	end

	function F.Image(parent, props)
		props = props or {}
		return New("ImageLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = props.Image or "",
			ImageColor3 = props.Color or Color3.new(1, 1, 1),
			ImageTransparency = props.Transparency or 0,
			ImageRectOffset = props.RectOffset or Vector2.zero,
			ImageRectSize = props.RectSize or Vector2.zero,
			ScaleType = props.ScaleType or Enum.ScaleType.Fit,
			Parent = parent,
		})
	end

	function F.Frame(parent, props)
		props = props or {}
		return New("Frame", {
			BackgroundColor3 = props.Color or "Surface",
			BackgroundTransparency = props.BgTransparency or 0,
			BorderSizePixel = 0,
			Position = props.Position or UDim2.fromOffset(0, 0),
			Size = props.Size or UDim2.new(1, 0, 0, Design.ItemHeight),
			Parent = parent,
		})
	end

	function F.MakeOutline(parent, cornerRadius, zIndex)
		local outline = New("Frame", {
			BackgroundColor3 = "Border",
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			Parent = parent,
		})
		F.Corner(outline, cornerRadius or Design.Corner)
		return outline
	end

	local CheckIcon = GetIcon("check")
	local ChevronUpIcon = GetIcon("chevron-up")
	local MoveIcon = GetIcon("move-diagonal-2")
	local KeyIcon = GetIcon("key")

	function F.GetCheckIcon()
		return CheckIcon
	end

	function F.GetChevronUpIcon()
		return ChevronUpIcon
	end

	function F.GetMoveIcon()
		return MoveIcon
	end

	function F.GetKeyIcon()
		return KeyIcon
	end
end

local function MakeDraggable(target, handle)
	local dragging = false
	local startPos, framePos
	local changed
	handle.InputBegan:Connect(function(input)
		if not IsClick(input) then
			return
		end
		startPos = input.Position
		framePos = target.Position
		dragging = true
		changed = input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End then
				return
			end
			dragging = false
			if changed and changed.Connected then
				changed:Disconnect()
				changed = nil
			end
		end)
	end)
	Connect(UserInputService.InputChanged:Connect(function(input)
		if not dragging or not IsHover(input) then
			return
		end
		local delta = input.Position - startPos
		target.Position =
			UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
	end))
end

local function MakeResizable(target, handle, onResize)
	local dragging = false
	local startPos, frameSize
	local changed
	handle.InputBegan:Connect(function(input)
		if not IsClick(input) then
			return
		end
		startPos = input.Position
		frameSize = target.Size
		dragging = true
		changed = input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End then
				return
			end
			dragging = false
			if changed and changed.Connected then
				changed:Disconnect()
				changed = nil
			end
		end)
	end)
	Connect(UserInputService.InputChanged:Connect(function(input)
		if not dragging or not IsHover(input) then
			return
		end
		local delta = input.Position - startPos
		target.Size = UDim2.new(
			frameSize.X.Scale,
			math.max(Design.WindowCorner * 20, frameSize.X.Offset + delta.X),
			frameSize.Y.Scale,
			math.max(Design.WindowCorner * 15, frameSize.Y.Offset + delta.Y)
		)
		if onResize then
			SafeCallback(onResize)
		end
	end))
end

local TooltipSystem = {}
do
	local tooltipRoot
	local tooltipLabel
	local currentHover
	local hoverTimer
	local tooltipScreenGui

	local function EnsureTooltip()
		if tooltipRoot then
			return
		end
		tooltipScreenGui = F.Create("ScreenGui", {
			Name = "LRXUITooltip",
			DisplayOrder = 2147483647,
			ResetOnSpawn = false,
		})
		protect(tooltipScreenGui)
		tooltipScreenGui.Parent = PlayerGui

		tooltipRoot = F.Create("Frame", {
			BackgroundColor3 = "Surface",
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 1000,
			Parent = tooltipScreenGui,
		})
		F.Corner(tooltipRoot, Design.CornerSmall)
		F.Stroke(tooltipRoot, { Color = "Border", Transparency = 0.3 })
		tooltipLabel = F.TextLabel(tooltipRoot, {
			Text = "",
			Size = Design.FontSize_Small,
			Wrapped = true,
		})
		F.Padding(tooltipRoot, { Left = 8, Right = 8, Top = 4, Bottom = 4 })
	end

	function TooltipSystem.Show(text, x, y)
		if not text then
			return
		end
		EnsureTooltip()
		tooltipLabel.Text = text
		local w, h = GetTextBounds(text, Enum.Font.Gotham, Design.FontSize_Small)
		tooltipRoot.Size = UDim2.fromOffset(w + 16, h + 8)
		tooltipRoot.Position = UDim2.fromOffset(x + 12, y + 12)
		tooltipRoot.Visible = true
	end

	function TooltipSystem.Hide()
		if tooltipRoot then
			tooltipRoot.Visible = false
		end
		currentHover = nil
		if hoverTimer then
			hoverTimer:Cancel()
			hoverTimer = nil
		end
	end

	local function onGlobalInput(input, processed)
		if not tooltipRoot or not tooltipRoot.Visible then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			TooltipSystem.Hide()
		end
	end

	Connect(UserInputService.InputBegan:Connect(onGlobalInput))

	function TooltipSystem.Register(instance, text, disabledText)
		local function onEnter()
			if currentHover == instance then
				return
			end
			currentHover = instance
			if hoverTimer then
				hoverTimer:Cancel()
			end
			hoverTimer = task.delay(Design.TooltipDelay, function()
				if currentHover == instance then
					TooltipSystem.Show(text, instance.AbsolutePosition.X, instance.AbsolutePosition.Y)
				end
			end)
		end
		local function onLeave()
			if currentHover == instance then
				TooltipSystem.Hide()
			end
		end
		local function onMove()
			if currentHover == instance and tooltipRoot and tooltipRoot.Visible then
				tooltipRoot.Position = UDim2.fromOffset(
					instance.AbsolutePosition.X + instance.AbsoluteSize.X + 8,
					instance.AbsolutePosition.Y + instance.AbsoluteSize.Y / 2
				)
			end
		end
		instance.MouseEnter:Connect(onEnter)
		instance.MouseLeave:Connect(onLeave)
		instance.MouseMoved:Connect(onMove)
	end
end

local function AddTooltip(text, disabledText, instance)
	if not text and not disabledText then
		return
	end
	local tooltipData = { Text = text, DisabledText = disabledText, Disabled = false }
	TooltipSystem.Register(instance, function()
		return tooltipData.Disabled and (tooltipData.DisabledText or tooltipData.Text) or tooltipData.Text
	end)
	return tooltipData
end

local WatermarkSystem = {}
do
	local watermarkRoot
	local watermarkLabel

	function WatermarkSystem.Initialize(screenGui)
		watermarkRoot = F.Create("Frame", {
			BackgroundColor3 = "Surface",
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -50, 0, -50),
			Size = UDim2.fromOffset(0, 0),
			Visible = false,
			Parent = screenGui,
			DPIExclude = { Position = true, Size = true },
		})
		F.Corner(watermarkRoot, Design.Corner)
		F.Stroke(watermarkRoot, { Color = "Border", Transparency = 0.3 })

		local inner = F.Create("Frame", {
			BackgroundColor3 = "Background",
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.new(1, -4, 1, -4),
			Parent = watermarkRoot,
		})
		F.Corner(inner, Design.CornerSmall)

		watermarkLabel = F.TextLabel(inner, {
			Text = "",
			Size = Design.FontSize_Header,
			Color = "SubText",
		})
		watermarkLabel.Size = UDim2.new(1, 0, 0, 28)
		watermarkLabel.TextXAlignment = Enum.TextXAlignment.Left
		watermarkLabel.TextYAlignment = Enum.TextYAlignment.Center
		F.Padding(watermarkLabel, { Left = 12, Right = 12 })

		MakeDraggable(watermarkRoot, watermarkLabel)
	end

	local function ResizeWatermark()
		if not watermarkLabel or not watermarkRoot then
			return
		end
		local x, y = GetTextBounds(watermarkLabel.Text, Enum.Font.Gotham, Design.FontSize_Header)
		watermarkRoot.Size = UDim2.fromOffset((12 + x + 12 + 4) * DPIScale, (y + 8) * DPIScale)
	end

	function WatermarkSystem.SetText(text)
		if not watermarkLabel then
			return
		end
		watermarkLabel.Text = text
		ResizeWatermark()
	end

	function WatermarkSystem.SetVisible(visible)
		if not watermarkRoot then
			return
		end
		watermarkRoot.Visible = visible
		if visible then
			ResizeWatermark()
		end
	end
end

local function MouseIsOverFrame(frame, position)
	if not frame or not frame.AbsolutePosition then
		return false
	end
	local pos = frame.AbsolutePosition
	local size = frame.AbsoluteSize
	return position.X >= pos.X and position.X <= pos.X + size.X and position.Y >= pos.Y and position.Y <= pos.Y + size.Y
end

local ContextMenuSystem = {}
do
	local currentMenu

	function ContextMenuSystem.Create(holder, size, offset, isList, activeCallback)
		local menu
		if isList then
			menu = F.Create("ScrollingFrame", {
				BackgroundColor3 = "Surface",
				BorderSizePixel = 1,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				AutomaticSize = Enum.AutomaticSize.Y,
				BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				CanvasSize = UDim2.fromOffset(0, 0),
				ScrollBarImageColor3 = "Scrollbar",
				ScrollBarThickness = 2,
				TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				Visible = false,
				ZIndex = 50,
				DPIExclude = { Position = true, Size = true },
			})
		else
			menu = F.Create("Frame", {
				BackgroundColor3 = "Border",
				BorderSizePixel = 1,
				Size = size,
				Visible = false,
				ZIndex = 50,
				DPIExclude = { Position = true, Size = true },
			})
		end

		local inner = F.Create("Frame", {
			BackgroundColor3 = "Surface",
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			Parent = menu,
		})
		F.Corner(inner, Design.CornerSmall)

		local tbl = {
			Active = false,
			Holder = holder,
			Menu = menu,
			Inner = inner,
			List = nil,
			Signal = nil,
			Size = size,
		}

		if isList then
			tbl.List = F.List(inner)
			F.Padding(inner, { Top = 4, Bottom = 4 })
		end

		function tbl:Open()
			if currentMenu == tbl then
				return
			end
			if currentMenu then
				currentMenu:Close()
			end
			currentMenu = tbl
			tbl.Active = true

			menu.Position = UDim2.fromOffset(
				math.floor(holder.AbsolutePosition.X + offset[1]),
				math.floor(holder.AbsolutePosition.Y + offset[2])
			)
			menu.Size = type(size) == "function" and size() or size
			menu.Visible = true

			if activeCallback then
				SafeCallback(activeCallback, true)
			end

			tbl.Signal = holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				menu.Position = UDim2.fromOffset(
					math.floor(holder.AbsolutePosition.X + offset[1]),
					math.floor(holder.AbsolutePosition.Y + offset[2])
				)
			end)
		end

		function tbl:Close()
			if currentMenu ~= tbl then
				return
			end
			menu.Visible = false
			if tbl.Signal then
				tbl.Signal:Disconnect()
				tbl.Signal = nil
			end
			tbl.Active = false
			currentMenu = nil
			if activeCallback then
				SafeCallback(activeCallback, false)
			end
		end

		function tbl:Toggle()
			if tbl.Active then
				tbl:Close()
			else
				tbl:Open()
			end
		end

		function tbl:SetSize(newSize)
			tbl.Size = newSize
			menu.Size = type(newSize) == "function" and newSize() or newSize
		end

		table.insert(Registry.OnUnload, function()
			if tbl.Signal then
				tbl.Signal:Disconnect()
			end
			menu:Destroy()
		end)

		return tbl
	end

	Connect(UserInputService.InputBegan:Connect(function(input)
		if not IsClick(input, true) then
			return
		end
		if not currentMenu then
			return
		end
		local pos = input.Position
		local menu = currentMenu.Menu
		if not (MouseIsOverFrame(menu, pos) or MouseIsOverFrame(currentMenu.Holder, pos)) then
			currentMenu:Close()
		end
	end))
end

local CustomCursor = {}
do
	local cursorRoot
	local cursorH, cursorV
	local oldMouseIconEnabled = true

	function CustomCursor.Initialize(screenGui)
		cursorRoot = F.Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.fromOffset(9, 1),
			Visible = false,
			ZIndex = 999,
			Parent = screenGui,
		})
		local cursorShadowH = F.Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 2, 1, 2),
			ZIndex = 998,
			Parent = cursorRoot,
		})
		cursorH = F.Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(1, 9),
			Parent = cursorRoot,
		})
		local cursorShadowV = F.Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 2, 1, 2),
			ZIndex = 998,
			Parent = cursorH,
		})
	end

	function CustomCursor.Start(show)
		oldMouseIconEnabled = UserInputService.MouseIconEnabled
		pcall(function()
			RunService:UnbindFromRenderStep("ShowCursor")
		end)
		RunService:BindToRenderStep("ShowCursor", Enum.RenderPriority.Last.Value, function()
			UserInputService.MouseIconEnabled = not show
			if cursorRoot then
				cursorRoot.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
				cursorRoot.Visible = show
			end
		end)
	end

	function CustomCursor.Stop()
		pcall(function()
			RunService:UnbindFromRenderStep("ShowCursor")
		end)
		UserInputService.MouseIconEnabled = oldMouseIconEnabled
		if cursorRoot then
			cursorRoot.Visible = false
		end
	end
end

local NotificationSystem = {}
do
	local area
	local notifyList

	function NotificationSystem.Initialize(parent)
		area = F.Create("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -12, 0, 12),
			Size = UDim2.new(0, Design.NotifyWidth, 1, -24),
			Parent = parent,
			DPIExclude = { Position = true, Size = true },
		})
		notifyList = F.List(area)
		notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
		Registry.NotifyArea = area
	end

	function NotificationSystem.SetSide(side)
		if side:lower() == "left" then
			area.AnchorPoint = Vector2.new(0, 0)
			area.Position = UDim2.fromOffset(12, 12)
			notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Left
		else
			area.AnchorPoint = Vector2.new(1, 0)
			area.Position = UDim2.new(1, -12, 0, 12)
			notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
		end
	end

	function NotificationSystem.Notify(info)
		if type(info) == "string" then
			info = { Text = info }
		end
		info = MergeDefaults(info, {
			Text = "",
			Title = "",
			Duration = Design.NotifyDuration,
			Persist = false,
			Accent = "Accent",
			SoundId = nil,
		})

		local holder = F.Create("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false,
			Parent = area,
			DPIExclude = { Size = true },
		})

		local background = F.Create("Frame", {
			BackgroundColor3 = "Border",
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			Parent = holder,
		})
		F.Corner(background, Design.Corner)

		local card = F.Create("Frame", {
			BackgroundColor3 = "Surface",
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.new(1, -4, 1, -4),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = background,
		})
		F.Corner(card, Design.Corner - 1)
		F.Stroke(card, { Color = "BorderFaint", Transparency = 0.3 })

		local accentBar = F.Create("Frame", {
			BackgroundColor3 = info.Accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(0, 3, 1, 0),
			Parent = background,
		})
		F.Corner(accentBar, Design.CornerSmall)

		local inner = F.Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -16, 1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = card,
		})
		F.Padding(inner, { Top = 10, Bottom = 10, Left = 4, Right = 4 })
		F.List(inner)

		if info.Title and info.Title ~= "" then
			F.TextLabel(inner, {
				Text = info.Title,
				Size = Design.FontSize_Header,
				Color = "Text",
			})
		end

		if info.Text and info.Text ~= "" then
			F.TextLabel(inner, {
				Text = info.Text,
				Size = Design.FontSize_Body,
				Color = "SubText",
				Wrapped = true,
			})
		end

		local timerBar
		if not info.Persist then
			timerBar = F.Create("Frame", {
				BackgroundColor3 = info.Accent,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(1, 0, 0, 2),
				Parent = background,
			})
		end

		if info.SoundId then
			local soundId = info.SoundId
			if type(soundId) == "number" then
				soundId = `rbxassetid://{soundId}`
			end
			F.Create("Sound", {
				SoundId = soundId,
				Volume = 3,
				PlayOnRemove = true,
				Parent = SoundService,
			}):Destroy()
		end

		local data = { Holder = holder, Background = background, Card = card, Destroyed = false }
		Registry.Notifications[holder] = data

		holder.Visible = true
		Animation.Play(background, {
			Position = UDim2.fromOffset(-2, -2),
		}, Design.AnimationNormal)

		if info.Persist then
			return data
		end

		if timerBar then
			Animation.Play(timerBar, {
				Size = UDim2.new(0, 0, 0, 2),
			}, info.Duration, Enum.EasingStyle.Linear)
		end

		task.delay(info.Duration, function()
			if data.Destroyed then
				return
			end
			data:Destroy()
		end)

		function data:Destroy()
			if data.Destroyed then
				return
			end
			data.Destroyed = true
			Animation.Play(holder, {
				Position = UDim2.new(1, 50, 0, 0),
			}, Design.AnimationNormal, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(Design.AnimationNormal, function()
				holder:Destroy()
				Registry.Notifications[holder] = nil
			end)
		end

		function data:SetTitle(t)
			info.Title = t
		end
		function data:SetText(t)
			info.Text = t
		end

		return data
	end
end

local DialogSystem = {}
do
	local activeDialog

	function DialogSystem.Dialog(info)
		info = MergeDefaults(info, {
			Title = "Dialog",
			Text = "",
			Type = "confirm",
			Confirm = "Confirm",
			Cancel = "Cancel",
			Ok = "OK",
			Risky = false,
			Escape = true,
			Callback = function() end,
			OnConfirm = function() end,
			OnCancel = function() end,
			OnClose = function() end,
		})

		local isInfo = info.Type == "info"

		if activeDialog then
			activeDialog:Close(false, "replaced")
		end

		local sg = Registry.ScreenGui
		if not sg then
			return
		end

		local overlay = F.Create("TextButton", {
			Active = true,
			AutoButtonColor = false,
			BackgroundColor3 = "Overlay",
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Modal = true,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = 900,
			Parent = sg,
			DPIExclude = { Size = true },
		})

		local popup = F.Create("Frame", {
			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = "Surface",
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.42, 0.35),
			ZIndex = 910,
			Parent = sg,
		})
		F.Corner(popup, Design.WindowCorner)
		F.Stroke(popup, { Color = "Border", Transparency = 0.3 })

		local titleLabel = F.TextLabel(popup, {
			Text = info.Title,
			Size = Design.FontSize_Title,
			Color = "Text",
		})
		F.Padding(titleLabel, { Left = 20, Right = 20, Top = 18, Bottom = 0 })
		titleLabel.Size = UDim2.new(1, -40, 0, 28)

		local separator = F.Create("Frame", {
			BackgroundColor3 = "Border",
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(20, 52),
			Size = UDim2.new(1, -40, 0, 1),
			Parent = popup,
		})

		local desc = F.TextLabel(popup, {
			Text = info.Text,
			Size = Design.FontSize_Body,
			Color = "SubText",
			Wrapped = true,
		})
		F.Padding(desc, { Left = 20, Right = 20, Top = 0, Bottom = 0 })

		local buttons = F.Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 50),
			Parent = popup,
		})

		local function MakeButton(text, kind)
			local isConfirm = kind == "confirm"
			local btn = F.TextButton(buttons, {
				Text = text,
				Size = Design.FontSize_Header,
				Color = "Text",
				BgTransparency = isConfirm and 0 or 1,
				XAlign = Enum.TextXAlignment.Center,
			})
			if isConfirm then
				btn.BackgroundColor3 = info.Risky and Palette.Danger or Palette.Accent
			end
			btn.Size = UDim2.fromOffset(0, 34)
			F.Corner(btn, Design.CornerSmall)
			F.Stroke(btn, {
				Color = isConfirm and "Border" or "Border",
				Transparency = isConfirm and 0.5 or 0.3,
			})
			if not isConfirm then
				btn.BackgroundColor3 = Palette.Surface
				btn.BackgroundTransparency = 0.3
			end
			return btn
		end

		local confirmBtn = MakeButton(isInfo and info.Ok or info.Confirm, "confirm")
		local cancelBtn
		if not isInfo then
			cancelBtn = MakeButton(info.Cancel, "cancel")
		end

		confirmBtn.AnchorPoint = Vector2.new(1, 0.5)
		confirmBtn.Position = UDim2.new(1, -12, 0.5, 0)

		if cancelBtn then
			cancelBtn.AnchorPoint = Vector2.new(1, 0.5)
			cancelBtn.Position = UDim2.new(1, -12 - 100 - 8, 0.5, 0)
		end

		local closed = false
		local dialog = {}

		local function Finalize(accepted, reason)
			if closed then
				return
			end
			closed = true
			activeDialog = nil

			Animation.Play(popup, {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.3, 0.2),
			}, Design.AnimationSlow)
			Animation.Play(overlay, {
				BackgroundTransparency = 1,
			}, Design.AnimationNormal)

			task.delay(Design.AnimationSlow, function()
				popup:Destroy()
				overlay:Destroy()
			end)

			task.defer(function()
				if accepted then
					SafeCallback(info.OnConfirm, reason)
				else
					SafeCallback(info.OnCancel, reason)
				end
				SafeCallback(info.Callback, accepted, reason)
				SafeCallback(info.OnClose, accepted, reason)
			end)
		end

		function dialog:Close(accepted, reason)
			Finalize(accepted == true, reason or "manual")
		end

		activeDialog = dialog

		confirmBtn.MouseButton1Click:Connect(function()
			Finalize(true, isInfo and "ok" or "confirm")
		end)

		if cancelBtn then
			cancelBtn.MouseButton1Click:Connect(function()
				Finalize(false, "cancel")
			end)
		end

		Connect(UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
				Finalize(true, isInfo and "ok" or "confirm")
			end
			if info.Escape and input.KeyCode == Enum.KeyCode.Escape then
				Finalize(false, "escape")
			end
		end))

		Animation.Play(overlay, {
			BackgroundTransparency = 0.5,
		}, Design.AnimationNormal)

		MakeDraggable(popup, titleLabel)

		local function Layout()
			local vp = sg.AbsoluteSize
			local w = Clamp(vp.X * 0.42, 300, vp.X * 0.85)
			local h = Clamp(vp.Y * 0.35, 200, vp.Y * 0.7)
			popup.Size = UDim2.fromOffset(w, h)
			titleLabel.Size = UDim2.new(1, -40, 0, 28)
			separator.Position = UDim2.fromOffset(20, 52)
			desc.Position = UDim2.fromOffset(20, 64)
			desc.Size = UDim2.new(1, -40, 0, h - 124)
			local bw = 100
			confirmBtn.Position = UDim2.new(1, -12 - bw, 0.5, 0)
			confirmBtn.Size = UDim2.fromOffset(bw, 34)
			if cancelBtn then
				cancelBtn.Position = UDim2.new(1, -12 - bw * 2 - 8, 0.5, 0)
				cancelBtn.Size = UDim2.fromOffset(bw, 34)
			end
		end

		Layout()
		Connect(sg:GetPropertyChangedSignal("AbsoluteSize"):Connect(Layout))

		return dialog
	end
end

-- Dependency helpers
local function CheckDepbox(box, search)
	local visibleElements = 0
	for _, el in pairs(box.Elements or {}) do
		if el.Type == "Separator" then
			if el.Root then
				el.Root.Visible = false
			end
			continue
		end
		if el.Type == "Button" and el.SubButton then
			local visible = false
			if el.Text and el.Text:lower():match(search) and el.Visible ~= false then
				visible = true
			elseif el.Root then
				el.Root.Visible = false
			end
			if el.SubButton.Text and el.SubButton.Text:lower():match(search) and el.SubButton.Visible ~= false then
				visible = true
			elseif el.SubButton.Root then
				el.SubButton.Root.Visible = false
			end
			if el.Root then
				el.Root.Visible = visible
			end
			if visible then
				visibleElements += 1
			end
			continue
		end
		if el.Label and el.Label:lower():match(search) and el.Visible ~= false then
			if el.Root then
				el.Root.Visible = true
			end
			visibleElements += 1
		elseif el.Text and el.Text:lower():match(search) and el.Visible ~= false then
			if el.Root then
				el.Root.Visible = true
			end
			visibleElements += 1
		elseif el.Hint and el.Hint:lower():match(search) and el.Visible ~= false then
			if el.Root then
				el.Root.Visible = true
			end
			visibleElements += 1
		else
			if el.Root then
				el.Root.Visible = false
			end
		end
	end
	for _, dep in pairs(box.DependencyBoxes or {}) do
		if dep.Visible then
			visibleElements += CheckDepbox(dep, search)
		end
	end
	return visibleElements
end

local function RestoreDepbox(box)
	for _, el in pairs(box.Elements or {}) do
		if el.Root then
			el.Root.Visible = el.Visible ~= false
		end
		if el.SubButton and el.SubButton.Root then
			el.SubButton.Root.Visible = el.SubButton.Visible ~= false
		end
	end
	if box.Resize then
		box:Resize()
	end
	if box.Holder then
		box.Holder.Visible = true
	end
	for _, dep in pairs(box.DependencyBoxes or {}) do
		if dep.Visible then
			RestoreDepbox(dep)
		end
	end
end

local SearchEngine = {}
do
	local lastSearch = ""
	local lastTab = nil

	function SearchEngine.Search(text, activeTab)
		text = Trim(text):lower()
		if text == "" then
			SearchEngine.Reset(activeTab)
			return
		end

		if lastTab and lastTab ~= activeTab then
			SearchEngine.Reset(lastTab)
		end

		lastSearch = text
		lastTab = activeTab

		for _, card in pairs(activeTab.Cards or {}) do
			local visible = false
			for _, component in pairs(card.Components or {}) do
				local match = false
				if component.Label and component.Label:lower():find(text, 1, true) then
					match = true
				end
				if component.Type == "Button" and component.Text and component.Text:lower():find(text, 1, true) then
					match = true
				end
				if component.Hint and component.Hint:lower():find(text, 1, true) then
					match = true
				end
				if
					component.SubButton
					and component.SubButton.Text
					and component.SubButton.Text:lower():find(text, 1, true)
				then
					match = true
				end
				if not match and component.Root then
					component.Root.Visible = false
				elseif match then
					visible = true
					if component.Root then
						component.Root.Visible = true
					end
					if component.SubButton and component.SubButton.Root then
						component.SubButton.Root.Visible = true
					end
				end
			end
			if card.Holder then
				card.Holder.Visible = visible
			end
			if visible and card.Resize then
				card:Resize()
			end
		end

		for _, tabbox in pairs(activeTab.Tabboxes or {}) do
			local visibleTabs = 0
			local visibleElems = {}
			for name, tab in pairs(tabbox.Tabs or {}) do
				visibleElems[tab] = 0
				for _, el in pairs(tab.Elements or {}) do
					local match = false
					if el.Label and el.Label:lower():find(text, 1, true) then
						match = true
					end
					if el.Text and el.Text:lower():find(text, 1, true) then
						match = true
					end
					if el.SubButton and el.SubButton.Text and el.SubButton.Text:lower():find(text, 1, true) then
						match = true
					end
					if match and el.Root then
						el.Root.Visible = true
						visibleElems[tab] += 1
					elseif el.Root then
						el.Root.Visible = false
					end
				end
				for _, dep in pairs(tab.DependencyBoxes or {}) do
					if dep.Visible then
						visibleElems[tab] += CheckDepbox(dep, text)
					end
				end
			end
			for tab, count in pairs(visibleElems) do
				if tab.ButtonHolder then
					tab.ButtonHolder.Visible = count > 0
				end
				if count > 0 then
					visibleTabs += 1
					if tabbox.ActiveTab ~= tab and visibleElems[tabbox.ActiveTab] == 0 then
						if tab.Show then
							tab:Show()
						end
					end
				end
			end
			if tabbox.ActiveTab and tabbox.ActiveTab.Resize then
				tabbox.ActiveTab:Resize()
			end
			if tabbox.Holder then
				tabbox.Holder.Visible = visibleTabs > 0
			end
		end

		for _, depGroup in pairs(activeTab.DependencyGroupboxes or {}) do
			if not depGroup.Visible then
				continue
			end
			local vis = CheckDepbox(depGroup, text)
			if depGroup.Holder then
				depGroup.Holder.Visible = vis > 0
			end
			if vis > 0 and depGroup.Resize then
				depGroup:Resize()
			end
		end
	end

	function SearchEngine.Reset(activeTab)
		if not activeTab then
			return
		end
		for _, card in pairs(activeTab.Cards or {}) do
			if card.Holder then
				card.Holder.Visible = true
			end
			for _, component in pairs(card.Components or {}) do
				if component.Root then
					component.Root.Visible = component.Visible ~= false
				end
				if component.SubButton and component.SubButton.Root then
					component.SubButton.Root.Visible = component.SubButton.Visible ~= false
				end
			end
			if card.Resize then
				card:Resize()
			end
		end
		for _, tabbox in pairs(activeTab.Tabboxes or {}) do
			for _, tab in pairs(tabbox.Tabs or {}) do
				for _, el in pairs(tab.Elements or {}) do
					if el.Root then
						el.Root.Visible = el.Visible ~= false
					end
					if el.SubButton and el.SubButton.Root then
						el.SubButton.Root.Visible = el.SubButton.Visible ~= false
					end
				end
				for _, dep in pairs(tab.DependencyBoxes or {}) do
					if dep.Visible then
						RestoreDepbox(dep)
					end
				end
				if tab.ButtonHolder then
					tab.ButtonHolder.Visible = true
				end
			end
			if tabbox.ActiveTab and tabbox.ActiveTab.Resize then
				tabbox.ActiveTab:Resize()
			end
			if tabbox.Holder then
				tabbox.Holder.Visible = true
			end
		end
		for _, depGroup in pairs(activeTab.DependencyGroupboxes or {}) do
			if depGroup.Visible then
				for _, el in pairs(depGroup.Elements or {}) do
					if el.Root then
						el.Root.Visible = el.Visible ~= false
					end
				end
				for _, dep in pairs(depGroup.DependencyBoxes or {}) do
					if dep.Visible then
						RestoreDepbox(dep)
					end
				end
				if depGroup.Holder then
					depGroup.Holder.Visible = true
				end
			end
		end
		lastSearch = ""
		lastTab = nil
	end

	function SearchEngine.UpdateDependencyBoxes()
		for _, dep in pairs(Registry.DependencyBoxes) do
			if dep.Update then
				dep:Update(true)
			end
		end
		if lastSearch ~= "" and lastTab then
			SearchEngine.Search(lastSearch, lastTab)
		end
	end
end

local ComponentBase = {}
do
	function ComponentBase:SetVisible(visible)
		self.Visible = visible
		if self.Root then
			self.Root.Visible = visible
		end
		if self.Container and self.Container.Resize then
			self.Container:Resize()
		end
	end

	function ComponentBase:SetEnabled(enabled)
		self.Disabled = not enabled
		if self.OnStateChange then
			self:OnStateChange()
		end
	end

	function ComponentBase:SetDisabled(disabled)
		self.Disabled = disabled
		if self.OnStateChange then
			self:OnStateChange()
		end
		if self.Container and self.Container.Resize then
			self.Container:Resize()
		end
	end

	function ComponentBase:SetTooltip(text)
		self.TooltipText = text
	end

	function ComponentBase:Destroy()
		if self.Root then
			self.Root:Destroy()
		end
		Registry.Components[self] = nil
	end
end

local Components = {}
do
	function Components.Label(container, info)
		info = MergeDefaults(info, {
			Text = "Label",
			Size = Design.FontSize_Body,
			Color = "Text",
			Visible = true,
		})

		local root = F.TextLabel(container, {
			Text = info.Text,
			Size = info.Size,
			Color = info.Color,
		})
		root.Size = UDim2.new(1, 0, 0, 20)

		local self = setmetatable({
			Type = "Label",
			Root = root,
			Container = container,
			Label = info.Text,
			Visible = info.Visible,
			Text = info.Text,
		}, { __index = ComponentBase })

		root.Visible = self.Visible

		function self:SetText(text)
			self.Text = text
			self.Label = text
			root.Text = text
		end

		function self:SetColor(color)
			root.TextColor3 = color
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Button(container, info)
		info = MergeDefaults(info, {
			Text = "Button",
			Callback = function() end,
			Risky = false,
			Disabled = false,
			Visible = true,
			Tooltip = nil,
			DoubleClick = false,
			SubButton = nil,
		})

		local root = F.TextButton(container, {
			Text = info.Text,
			Size = Design.FontSize_Body,
			Color = info.Risky and "Danger" or "Text",
			BgTransparency = 0.82,
			XAlign = Enum.TextXAlignment.Center,
		})
		root.BackgroundColor3 = Palette.Surface
		root.Size = UDim2.new(1, 0, 0, Design.ItemHeight)
		F.Corner(root, Design.CornerSmall)
		F.Stroke(root, { Color = "Border", Transparency = 0.35 })

		local self = setmetatable({
			Type = "Button",
			Root = root,
			Container = container,
			Text = info.Text,
			Disabled = info.Disabled,
			Visible = info.Visible,
			TooltipText = info.Tooltip,
			Hint = info.Text,
			DoubleClick = info.DoubleClick,
			SubButton = nil,
			Locked = false,
		}, { __index = ComponentBase })

		root.Visible = self.Visible

		if info.SubButton then
			local subInfo = info.SubButton
			local subRoot = F.TextButton(root, {
				Text = subInfo.Text or "",
				Size = Design.FontSize_Small,
				Color = subInfo.Risky and "Danger" or "SubText",
				BgTransparency = 0.85,
				XAlign = Enum.TextXAlignment.Center,
			})
			subRoot.BackgroundColor3 = Palette.SurfaceAlt
			subRoot.AnchorPoint = Vector2.new(1, 0.5)
			subRoot.Position = UDim2.new(1, -4, 0.5, 0)
			subRoot.Size = UDim2.fromOffset(60, 24)
			F.Corner(subRoot, Design.CornerSmall)
			F.Stroke(subRoot, { Color = "Border", Transparency = 0.4 })

			local subButton = {
				Type = "SubButton",
				Root = subRoot,
				Text = subInfo.Text,
				Disabled = subInfo.Disabled or false,
				Visible = subInfo.Visible ~= false,
				Callback = subInfo.Callback or function() end,
				Risky = subInfo.Risky or false,
				Container = container,
				Hint = subInfo.Text,
			}
			self.SubButton = subButton

			subRoot.MouseButton1Click:Connect(function()
				if subButton.Disabled or self.Locked then
					return
				end
				if subInfo.DoubleClick then
					self.Locked = true
					root.Text = "Are you sure?"
					local clicked = false
					local conn
					conn = subRoot.MouseButton1Click:Connect(function()
						clicked = true
						if conn then
							conn:Disconnect()
						end
					end)
					task.wait(0.5)
					root.Text = self.Text
					self.Locked = false
					if clicked then
						SafeCallback(subInfo.Callback)
					end
				else
					SafeCallback(subInfo.Callback)
				end
			end)

			subRoot.MouseEnter:Connect(function()
				if subButton.Disabled then
					return
				end
				Animation.Play(subRoot, { BackgroundTransparency = 0.7 }, Design.AnimationFast)
			end)
			subRoot.MouseLeave:Connect(function()
				if subButton.Disabled then
					return
				end
				Animation.Play(subRoot, { BackgroundTransparency = 0.85 }, Design.AnimationFast)
			end)
		end

		local clickLock = false
		root.MouseButton1Click:Connect(function()
			if self.Disabled or self.Locked or clickLock then
				return
			end
			if self.DoubleClick then
				self.Locked = true
				root.Text = "Are you sure?"
				clickLock = true
				local conn
				conn = root.MouseButton1Click:Connect(function()
					clickLock = false
					self.Locked = false
					if conn then
						conn:Disconnect()
					end
					SafeCallback(info.Callback)
					root.Text = self.Text
				end)
				task.delay(0.5, function()
					root.Text = self.Text
					self.Locked = false
					clickLock = false
					if conn then
						conn:Disconnect()
					end
				end)
			else
				SafeCallback(info.Callback)
			end
		end)

		root.MouseEnter:Connect(function()
			if self.Disabled or self.Locked then
				return
			end
			Animation.Play(root, { BackgroundTransparency = 0.7 }, Design.AnimationFast)
		end)

		root.MouseLeave:Connect(function()
			if self.Disabled or self.Locked then
				return
			end
			Animation.Play(root, { BackgroundTransparency = 0.82 }, Design.AnimationFast)
		end)

		function self:SetText(text)
			self.Text = text
			self.Hint = text
			root.Text = text
		end

		function self:OnStateChange()
			root.Active = not self.Disabled
			root.TextTransparency = self.Disabled and 0.6 or 0
			root.BackgroundTransparency = self.Disabled and 0.9 or 0.82
		end

		if info.Tooltip then
			TooltipSystem.Register(root, info.Tooltip)
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Toggle(container, info)
		info = MergeDefaults(info, {
			Text = "Toggle",
			Default = false,
			Callback = function() end,
			Changed = function() end,
			Disabled = false,
			Risky = false,
			Visible = true,
			Tooltip = nil,
		})

		local root = F.TextButton(container, {
			Text = "",
			BgTransparency = 1,
			XAlign = Enum.TextXAlignment.Left,
		})
		root.Size = UDim2.new(1, 0, 0, Design.ItemHeight)

		local label = F.TextLabel(root, {
			Text = info.Text,
			Size = Design.FontSize_Body,
			Color = "Text",
		})
		label.Size = UDim2.new(1, -50, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center

		local track = F.Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = "SurfaceAlt",
			BorderSizePixel = 0,
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.fromOffset(36, 20),
			Parent = root,
		})
		F.Corner(track, 10)
		local trackStroke = F.Stroke(track, { Color = "Border", Transparency = 0.3 })

		local thumb = F.Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = "Text",
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(3, 0),
			Size = UDim2.fromOffset(14, 14),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Parent = track,
		})
		F.Corner(thumb, 7)

		local value = info.Default

		local self = setmetatable({
			Type = "Toggle",
			Root = root,
			Container = container,
			Text = info.Text,
			Value = value,
			Disabled = info.Disabled,
			Visible = info.Visible,
			Risky = info.Risky,
			TooltipText = info.Tooltip,
			Label = info.Text,
			Addons = {},
		}, { __index = ComponentBase })

		root.Visible = self.Visible

		local function UpdateVisuals(animated)
			local targetX = value and 19 or 3
			local trackColor = value and Palette.Accent or Palette.SurfaceAlt
			local strokeColor = value and Palette.Accent or Palette.Border

			track.BackgroundColor3 = trackColor
			trackStroke.Color = strokeColor

			if animated then
				Animation.Play(track, { BackgroundColor3 = trackColor }, Design.AnimationFast)
				Animation.Play(thumb, { Position = UDim2.fromOffset(targetX, 0) }, Design.AnimationFast)
			else
				track.BackgroundColor3 = trackColor
				thumb.Position = UDim2.fromOffset(targetX, 0)
			end

			label.TextTransparency = self.Disabled and 0.6 or 0
			root.Active = not self.Disabled
		end

		UpdateVisuals(false)

		root.MouseButton1Click:Connect(function()
			if self.Disabled then
				return
			end
			self:SetValue(not value)
		end)

		function self:SetValue(v)
			if self.Disabled then
				return
			end
			value = v
			self.Value = v
			UpdateVisuals(true)
			for _, addon in pairs(self.Addons) do
				if addon.Type == "KeyPicker" and addon.SyncToggleState then
					addon.Toggled = value
					if addon.Update then
						addon:Update()
					end
				end
			end
			SafeCallback(info.Callback, v)
			SafeCallback(info.Changed, v)
			SearchEngine.UpdateDependencyBoxes()
		end

		function self:SetText(text)
			self.Text = text
			self.Label = text
			label.Text = text
		end

		function self:OnStateChange()
			root.Active = not self.Disabled
			UpdateVisuals(false)
		end

		if info.Tooltip then
			TooltipSystem.Register(root, info.Tooltip)
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Slider(container, info)
		info = MergeDefaults(info, {
			Text = "Slider",
			Default = 0,
			Min = 0,
			Max = 100,
			Rounding = 0,
			Prefix = "",
			Suffix = "",
			Callback = function() end,
			Changed = function() end,
			Disabled = false,
			Visible = true,
			Tooltip = nil,
		})

		local root = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 38),
			Parent = container,
		})

		local label = F.TextLabel(root, {
			Text = info.Text,
			Size = Design.FontSize_Body,
			Color = "Text",
		})
		label.Size = UDim2.new(1, -60, 0, 18)

		local valueLabel = F.TextLabel(root, {
			Text = tostring(info.Default),
			Size = Design.FontSize_Body,
			Color = "SubText",
		})
		valueLabel.AnchorPoint = Vector2.new(1, 0)
		valueLabel.Position = UDim2.new(1, 0, 0, 0)
		valueLabel.Size = UDim2.new(0, 56, 0, 18)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right

		local barBg = F.Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = "SurfaceAlt",
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(1, 0, 0, 12),
			Text = "",
			Parent = root,
		})
		F.Corner(barBg, 6)
		F.Stroke(barBg, { Color = "Border", Transparency = 0.3 })

		local fill = F.Create("Frame", {
			BackgroundColor3 = "Accent",
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0, 1),
			Parent = barBg,
		})
		F.Corner(fill, 6)

		local value = Clamp(info.Default, info.Min, info.Max)

		local self = setmetatable({
			Type = "Slider",
			Root = root,
			Container = container,
			Text = info.Text,
			Value = value,
			Min = info.Min,
			Max = info.Max,
			Disabled = info.Disabled,
			Visible = info.Visible,
			TooltipText = info.Tooltip,
			Label = info.Text,
		}, { __index = ComponentBase })

		root.Visible = self.Visible

		local function Display()
			local pct = Clamp((value - info.Min) / (info.Max - info.Min), 0, 1)
			fill.Size = UDim2.fromScale(pct, 1)
			local display = value
			if info.Rounding then
				display = Round(value, info.Rounding)
			end
			valueLabel.Text = info.Prefix .. tostring(display) .. info.Suffix
		end

		Display()

		local function HandleInput(input)
			if self.Disabled then
				return
			end
			local dragging = true
			local function Update()
				local pos = UserInputService:GetMouseLocation()
				local absPos = barBg.AbsolutePosition
				local absSize = barBg.AbsoluteSize
				local pct = Clamp((pos.X - absPos.X) / absSize.X, 0, 1)
				local newVal = info.Min + (info.Max - info.Min) * pct
				if info.Rounding then
					newVal = Round(newVal, info.Rounding)
				end
				if newVal ~= value then
					value = newVal
					self.Value = value
					Display()
					SafeCallback(info.Callback, value)
					SafeCallback(info.Changed, value)
				end
			end
			Update()
			local conn
			conn = UserInputService.InputChanged:Connect(function(inp)
				if not dragging then
					if conn then
						conn:Disconnect()
					end
					return
				end
				if IsHover(inp) then
					Update()
				end
			end)
			local endConn
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if conn then
						conn:Disconnect()
					end
					if endConn then
						endConn:Disconnect()
					end
				end
			end)
		end

		barBg.InputBegan:Connect(function(input)
			if IsClick(input) then
				HandleInput(input)
			end
		end)

		function self:SetValue(v)
			if self.Disabled then
				return
			end
			value = Clamp(v, info.Min, info.Max)
			self.Value = value
			Display()
			SafeCallback(info.Callback, value)
			SafeCallback(info.Changed, value)
		end

		function self:SetText(text)
			self.Text = text
			self.Label = text
			label.Text = text
		end

		function self:OnStateChange()
			barBg.Active = not self.Disabled
			label.TextTransparency = self.Disabled and 0.6 or 0
			valueLabel.TextTransparency = self.Disabled and 0.6 or 0
			fill.BackgroundTransparency = self.Disabled and 0.5 or 0
		end

		if info.Tooltip then
			TooltipSystem.Register(barBg, info.Tooltip)
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Input(container, info)
		info = MergeDefaults(info, {
			Text = "Input",
			Default = "",
			Placeholder = "",
			Numeric = false,
			Finished = false,
			ClearOnFocus = true,
			MaxLength = nil,
			Callback = function() end,
			Changed = function() end,
			Disabled = false,
			Visible = true,
		})

		local root = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 48),
			Parent = container,
		})

		local label = F.TextLabel(root, {
			Text = info.Text,
			Size = Design.FontSize_Body,
			Color = "Text",
		})
		label.Size = UDim2.new(1, 0, 0, 16)

		local box = F.TextBox(root, {
			Text = tostring(info.Default),
			Placeholder = info.Placeholder,
			ClearOnFocus = info.ClearOnFocus,
			Editable = not info.Disabled,
			Background = "Surface",
		})
		box.AnchorPoint = Vector2.new(0, 1)
		box.Position = UDim2.fromScale(0, 1)
		box.Size = UDim2.new(1, 0, 0, 28)
		box.TextXAlignment = Enum.TextXAlignment.Left
		F.Corner(box, Design.CornerSmall)
		F.Padding(box, { Left = 10, Right = 10 })
		F.Stroke(box, { Color = "Border", Transparency = 0.3 })

		local focusLine = F.Create("Frame", {
			BackgroundColor3 = "Accent",
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(0, 0, 0, 2),
			AnchorPoint = Vector2.new(0.5, 0),
			Parent = box,
		})

		local currentValue = tostring(info.Default)

		local self = setmetatable({
			Type = "Input",
			Root = root,
			Container = container,
			Text = info.Text,
			Value = currentValue,
			Disabled = info.Disabled,
			Visible = info.Visible,
			Label = info.Text,
		}, { __index = ComponentBase })

		root.Visible = self.Visible

		box.Focused:Connect(function()
			if self.Disabled then
				return
			end
			Animation.Play(focusLine, { Size = UDim2.new(1, 0, 0, 2) }, Design.AnimationFast)
		end)

		box.FocusLost:Connect(function(enter)
			Animation.Play(focusLine, { Size = UDim2.new(0, 0, 0, 2) }, Design.AnimationFast)
			if not enter then
				return
			end
			if info.Finished then
				self:SetValue(box.Text)
			end
		end)

		if not info.Finished then
			box:GetPropertyChangedSignal("Text"):Connect(function()
				self:SetValue(box.Text)
			end)
		end

		function self:SetValue(text)
			if info.Numeric and #text > 0 and not tonumber(text) then
				box.Text = currentValue
				return
			end
			if info.MaxLength and #text > info.MaxLength then
				text = text:sub(1, info.MaxLength)
				box.Text = text
			end
			currentValue = text
			self.Value = text
			if not self.Disabled then
				SafeCallback(info.Callback, text)
				SafeCallback(info.Changed, text)
			end
		end

		function self:SetText(text)
			self.Text = text
			self.Label = text
			label.Text = text
		end

		function self:OnStateChange()
			box.TextEditable = not self.Disabled
			box.ClearTextOnFocus = not self.Disabled and info.ClearOnFocus
			label.TextTransparency = self.Disabled and 0.6 or 0
			box.TextTransparency = self.Disabled and 0.6 or 0
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Separator(container, info)
		info = MergeDefaults(info, { Visible = true })

		local root = F.Create("Frame", {
			BackgroundColor3 = "Border",
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			Parent = container,
		})

		local self = setmetatable({
			Type = "Separator",
			Root = root,
			Container = container,
			Visible = info.Visible,
		}, { __index = ComponentBase })

		root.Visible = self.Visible
		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Keybind(container, info)
		info = MergeDefaults(info, {
			Text = "Keybind",
			Default = "None",
			Mode = "Toggle",
			Modes = { "Always", "Toggle", "Hold" },
			SyncToggleState = false,
			NoUI = false,
			Callback = function() end,
			Changed = function() end,
			Clicked = function() end,
			Disabled = false,
			Visible = true,
		})

		local root = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Design.ItemHeight),
			Parent = container,
		})

		local label = F.TextLabel(root, {
			Text = info.Text,
			Size = Design.FontSize_Body,
			Color = "Text",
		})
		label.Size = UDim2.new(1, -60, 1, 0)
		label.TextYAlignment = Enum.TextYAlignment.Center

		local pickerBtn = F.TextButton(root, {
			Text = info.Default,
			Size = Design.FontSize_Small,
			Color = "SubText",
			BgTransparency = 0.85,
			XAlign = Enum.TextXAlignment.Center,
		})
		pickerBtn.AnchorPoint = Vector2.new(1, 0.5)
		pickerBtn.BackgroundColor3 = Palette.Surface
		pickerBtn.Position = UDim2.new(1, -4, 0.5, 0)
		pickerBtn.Size = UDim2.fromOffset(50, 24)
		F.Corner(pickerBtn, Design.CornerSmall)
		F.Stroke(pickerBtn, { Color = "Border", Transparency = 0.3 })

		local mode = info.Mode
		local currentKey = info.Default
		local picking = false
		local toggled = false
		local keybindTogglesLoaded = false
		local kbToggleHolder
		local kbToggleLabel
		local kbToggleCheckbox
		local kbToggleCheckImage

		local SpecialKeys = {
			["MB1"] = Enum.UserInputType.MouseButton1,
			["MB2"] = Enum.UserInputType.MouseButton2,
			["MB3"] = Enum.UserInputType.MouseButton3,
		}

		local SpecialReverse = {
			[Enum.UserInputType.MouseButton1] = "MB1",
			[Enum.UserInputType.MouseButton2] = "MB2",
			[Enum.UserInputType.MouseButton3] = "MB3",
		}

		local self = setmetatable({
			Type = "Keybind",
			Root = root,
			Container = container,
			Text = info.Text,
			Value = currentKey,
			Mode = mode,
			Toggled = false,
			Disabled = info.Disabled,
			Visible = info.Visible,
			Label = info.Text,
			SyncToggleState = info.SyncToggleState,
			Addons = {},
		}, { __index = ComponentBase })

		root.Visible = self.Visible

		if info.SyncToggleState then
			mode = "Toggle"
			info.Modes = { "Toggle" }
		end

		local modeMenu = ContextMenuSystem.Create(pickerBtn, UDim2.fromOffset(80, 0), function()
			return { pickerBtn.AbsoluteSize.X + 1.5, 0.5 }
		end, 1)

		local modeButtons = {}
		for _, m in pairs(info.Modes) do
			local modeBtn = F.TextButton(modeMenu and modeMenu.Inner or root, {
				Text = m,
				Size = Design.FontSize_Small,
				Color = mode == m and "Text" or "SubText",
				BgTransparency = mode == m and 0.85 or 1,
				XAlign = Enum.TextXAlignment.Center,
			})
			modeBtn.Size = UDim2.new(1, 0, 0, 22)
			modeBtn.BackgroundColor3 = Palette.Surface
			if modeMenu and modeMenu.Inner then
				modeBtn.Parent = modeMenu.Inner
			end

			local btnData = {
				Button = modeBtn,
				Select = function()
					mode = m
					self.Mode = m
					for _, b in pairs(modeButtons) do
						b.Button.BackgroundTransparency = 1
						b.Button.TextColor3 = Palette.SubText
					end
					modeBtn.BackgroundTransparency = 0.85
					modeBtn.TextColor3 = Palette.Text
					if modeMenu then
						modeMenu:Close()
					end
					self:Update()
				end,
			}

			modeBtn.MouseButton1Click:Connect(function()
				btnData.Select()
			end)

			table.insert(modeButtons, btnData)
		end

		if modeMenu then
			F.Padding(modeMenu.Inner, { Top = 4, Bottom = 4 })
		end

		local function CreateKeybindToggle()
			if info.NoUI or not Registry.KeybindContainer then
				return
			end
			kbToggleHolder = F.Create("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				Text = "",
				Visible = true,
				Parent = Registry.KeybindContainer,
			})
			local checkIcon = F.GetCheckIcon()
			kbToggleLabel = F.TextLabel(kbToggleHolder, {
				Text = ("[%s] %s (%s)"):format(currentKey, info.Text, mode),
				Size = Design.FontSize_Small,
				Color = "SubText",
			})
			kbToggleLabel.Size = UDim2.fromScale(1, 1)
			kbToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
			kbToggleLabel.TextYAlignment = Enum.TextYAlignment.Center

			kbToggleCheckbox = F.Create("Frame", {
				BackgroundColor3 = "Surface",
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(14, 14),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Parent = kbToggleHolder,
			})
			F.Corner(kbToggleCheckbox, Design.CornerSmall)
			F.Stroke(kbToggleCheckbox, { Color = "Border", Transparency = 0.3 })

			kbToggleCheckImage = F.Image(kbToggleCheckbox, {
				Image = checkIcon and checkIcon.Url or "",
				Color = "Text",
				RectOffset = checkIcon and checkIcon.ImageRectOffset or Vector2.zero,
				RectSize = checkIcon and checkIcon.ImageRectSize or Vector2.zero,
			})
			kbToggleCheckImage.ImageTransparency = 1
			kbToggleCheckImage.Size = UDim2.new(1, -4, 1, -4)
			kbToggleCheckImage.Position = UDim2.fromOffset(2, 2)

			kbToggleHolder.MouseButton1Click:Connect(function()
				if mode ~= "Toggle" then
					return
				end
				toggled = not toggled
				self.Toggled = toggled
				SafeCallback(info.Callback, toggled)
				SafeCallback(info.Clicked, toggled)
				self:Update()
			end)

			kbToggleHolder.Visible = false
			keybindTogglesLoaded = true
			if Registry.KeybindToggles then
				table.insert(Registry.KeybindToggles, kbToggleHolder)
			end
		end

		function self:Update()
			local x, y = GetTextBounds(currentKey, Enum.Font.Gotham, Design.FontSize_Small)
			pickerBtn.Text = currentKey
			pickerBtn.Size = UDim2.fromOffset(math.max(x + 16, 50), 24)

			if info.NoUI then
				return
			end

			if
				mode == "Toggle"
				and container.ParentObj
				and container.ParentObj.Type == "Toggle"
				and container.ParentObj.Disabled
			then
				if kbToggleHolder then
					kbToggleHolder.Visible = false
				end
				if Registry.UpdateKeybindFrame then
					Registry.UpdateKeybindFrame()
				end
				return
			end

			if kbToggleHolder then
				kbToggleLabel.Text = ("[%s] %s (%s)"):format(currentKey, info.Text, mode)
				local tx, ty = GetTextBounds(kbToggleLabel.Text, Enum.Font.Gotham, Design.FontSize_Small)
				kbToggleLabel.Size = UDim2.fromOffset(tx, 18)

				local showCheck = mode == "Toggle"
				kbToggleCheckbox.Visible = showCheck
				if showCheck then
					kbToggleCheckbox.Position = UDim2.fromOffset(tx + 8, 2)
					kbToggleCheckImage.ImageTransparency = toggled and 0 or 1
				end

				if
					mode == "Toggle"
					and container.ParentObj
					and container.ParentObj.Type == "Toggle"
					and container.ParentObj.SyncToggleState
				then
					toggled = container.ParentObj.Value
					self.Toggled = toggled
				end

				kbToggleHolder.Visible = true
				if Registry.UpdateKeybindFrame then
					Registry.UpdateKeybindFrame()
				end
			end
		end

		function self:GetState()
			if mode == "Always" then
				return true
			end
			if mode == "Hold" then
				if currentKey == "None" then
					return false
				end
				if SpecialKeys[currentKey] then
					return UserInputService:IsMouseButtonPressed(SpecialKeys[currentKey])
				else
					return UserInputService:IsKeyDown(Enum.KeyCode[currentKey])
				end
			end
			return toggled
		end

		function self:DoClick()
			if
				mode == "Toggle"
				and container.ParentObj
				and container.ParentObj.Type == "Toggle"
				and self.SyncToggleState
			then
				container.ParentObj:SetValue(toggled)
			end
			SafeCallback(info.Callback, toggled)
			SafeCallback(info.Clicked, toggled)
			self:Update()
		end

		function self:SetValue(data)
			if type(data) == "table" then
				currentKey = data[1] or currentKey
				if data[2] then
					for _, btn in pairs(modeButtons) do
						if btn.Button.Text == data[2] then
							btn:Select()
							break
						end
					end
				end
			else
				currentKey = data
			end
			self.Value = currentKey
			self:Update()
		end

		pickerBtn.MouseButton1Click:Connect(function()
			if picking or self.Disabled then
				return
			end
			picking = true
			pickerBtn.Text = "..."
			pickerBtn.Size = UDim2.fromOffset(40, 24)

			local input = UserInputService.InputBegan:Wait()
			local key = "Unknown"
			if SpecialReverse[input.UserInputType] then
				key = SpecialReverse[input.UserInputType]
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
				key = input.KeyCode == Enum.KeyCode.Escape and "None" or input.KeyCode.Name
			end

			currentKey = key
			self.Value = key
			pickerBtn.Text = key
			picking = false
			task.wait()

			SafeCallback(info.Changed, key)
			self:Update()
		end)

		pickerBtn.MouseButton2Click:Connect(function()
			if modeMenu then
				modeMenu:Toggle()
			end
		end)

		Connect(UserInputService.InputBegan:Connect(function(input, processed)
			if
				processed
				or mode == "Always"
				or currentKey == "None"
				or currentKey == "Unknown"
				or picking
				or UserInputService:GetFocusedTextBox()
			then
				return
			end
			local match = false
			if SpecialReverse[input.UserInputType] == currentKey then
				match = true
			elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == currentKey then
				match = true
			end
			if not match then
				return
			end
			if mode == "Toggle" then
				toggled = not toggled
				self.Toggled = toggled
				self:DoClick()
			end
			self:Update()
		end))

		function self:OnStateChange()
			pickerBtn.Active = not self.Disabled
		end

		task.defer(function()
			CreateKeybindToggle()
			self:Update()
		end)

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Dropdown(container, info)
		info = MergeDefaults(info, {
			Text = "Dropdown",
			Values = {},
			Default = nil,
			Multi = false,
			Searchable = false,
			Callback = function() end,
			Changed = function() end,
			Disabled = false,
			Visible = true,
			MaxVisibleItems = 8,
			VirtualThreshold = 80,
		})

		local root = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, info.Text and 48 or 32),
			Parent = container,
		})

		local label
		if info.Text then
			label = F.TextLabel(root, {
				Text = info.Text,
				Size = Design.FontSize_Body,
				Color = "Text",
			})
			label.Size = UDim2.new(1, 0, 0, 16)
		end

		local display = F.TextButton(root, {
			Text = "---",
			Size = Design.FontSize_Small,
			Color = "SubText",
			BgTransparency = 0.85,
			XAlign = Enum.TextXAlignment.Left,
		})
		display.BackgroundColor3 = Palette.Surface
		display.AnchorPoint = Vector2.new(0, 1)
		display.Position = UDim2.fromScale(0, 1)
		display.Size = UDim2.new(1, 0, 0, 28)
		F.Corner(display, Design.CornerSmall)
		F.Stroke(display, { Color = "Border", Transparency = 0.3 })
		F.Padding(display, { Left = 10, Right = 10 })

		local arrow = F.TextLabel(display, {
			Text = "▼",
			Size = Design.FontSize_Tiny,
			Color = "Muted",
		})
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -6, 0.5, 0)
		arrow.Size = UDim2.fromOffset(12, 12)

		local selectedValues = info.Multi and {} or nil
		local selectedKey = nil

		if info.Default ~= nil then
			if info.Multi and type(info.Default) == "table" then
				selectedValues = {}
				for _, v in pairs(info.Default) do
					selectedValues[v] = true
				end
			elseif not info.Multi then
				selectedKey = info.Default
			end
		end

		local self = setmetatable({
			Type = "Dropdown",
			Root = root,
			Container = container,
			Text = info.Text,
			Values = info.Values,
			Value = info.Multi and selectedValues or selectedKey,
			Disabled = info.Disabled,
			Visible = info.Visible,
			Multi = info.Multi,
			Label = info.Text or "",
		}, { __index = ComponentBase })

		root.Visible = self.Visible

		local function GetDisplayString()
			if info.Multi then
				local parts = {}
				local count = 0
				for _, v in pairs(info.Values) do
					if selectedValues[v] then
						table.insert(parts, tostring(v))
						count += 1
					end
				end
				return count == 0 and "---" or table.concat(parts, ", ")
			else
				return selectedKey and tostring(selectedKey) or "---"
			end
		end

		local function UpdateDisplay()
			display.Text = GetDisplayString()
		end

		UpdateDisplay()

		-- Popup system
		local overlay = F.Create("TextButton", {
			Active = true,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = 500,
			Visible = false,
		})
		if Registry.ScreenGui then
			overlay.Parent = Registry.ScreenGui
		end

		local popup = F.Create("Frame", {
			BackgroundColor3 = "Surface",
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(200, 200),
			Visible = false,
			ZIndex = 510,
		})
		F.Corner(popup, Design.Corner)
		F.Stroke(popup, { Color = "Border", Transparency = 0.3 })
		if Registry.ScreenGui then
			popup.Parent = Registry.ScreenGui
		end

		local popupHeader = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 32),
			Parent = popup,
		})
		F.Padding(popupHeader, { Left = 12, Right = 12 })

		local popupTitle = F.TextLabel(popupHeader, {
			Text = info.Text or "Select",
			Size = Design.FontSize_Header,
			Color = "Text",
		})
		popupTitle.Size = UDim2.new(1, -30, 1, 0)
		popupTitle.TextYAlignment = Enum.TextYAlignment.Center

		local closeBtn = F.TextButton(popupHeader, {
			Text = "✕",
			Size = Design.FontSize_Body,
			Color = "Muted",
			BgTransparency = 1,
			XAlign = Enum.TextXAlignment.Center,
		})
		closeBtn.AnchorPoint = Vector2.new(1, 0.5)
		closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
		closeBtn.Size = UDim2.fromOffset(24, 24)

		local searchBox
		if info.Searchable then
			searchBox = F.TextBox(popup, {
				Placeholder = "Search...",
				Background = "SurfaceAlt",
				ClearOnFocus = false,
			})
			searchBox.Size = UDim2.new(1, -20, 0, 28)
			searchBox.Position = UDim2.fromOffset(10, 38)
			F.Corner(searchBox, Design.CornerSmall)
			F.Stroke(searchBox, { Color = "Border", Transparency = 0.3 })
			F.Padding(searchBox, { Left = 8, Right = 8 })
		end

		local listHolder = F.Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, searchBox and 74 or 36),
			Size = UDim2.new(1, 0, 1, -(searchBox and 80 or 42)),
			Parent = popup,
		})

		local listScroll = F.Scroll(listHolder)
		listScroll.Size = UDim2.new(1, 0, 1, 0)
		listScroll.ScrollBarThickness = Design.ScrollbarThickness
		local listLayout = F.List(listScroll)
		F.Padding(listScroll, { Top = 4, Bottom = 4 })

		local popupOpen = false
		local buttonCache = {}

		local function ClosePopup()
			popupOpen = false
			popup.Visible = false
			overlay.Visible = false
		end

		local function BuildList(searchText)
			for _, btn in pairs(buttonCache) do
				if btn.Root then
					btn.Root:Destroy()
				end
			end
			table.clear(buttonCache)

			local search = searchText and Trim(searchText):lower() or ""
			local visibleCount = 0

			local orderedValues = {}
			for _, v in pairs(info.Values) do
				table.insert(orderedValues, v)
			end

			for _, v in pairs(orderedValues) do
				local vs = tostring(v):lower()
				if search == "" or vs:find(search, 1, true) then
					local isSelected = info.Multi and selectedValues[v] or selectedKey == v
					local btn = F.TextButton(listScroll, {
						Text = tostring(v),
						Size = Design.FontSize_Body,
						Color = isSelected and "Accent" or "Text",
						BgTransparency = isSelected and 0.85 or 1,
						XAlign = Enum.TextXAlignment.Left,
					})
					btn.Size = UDim2.new(1, 0, 0, 30)
					btn.BackgroundColor3 = Palette.Surface
					btn.BorderSizePixel = 0
					btn.TextXAlignment = Enum.TextXAlignment.Left
					F.Padding(btn, { Left = 10, Right = 10 })
					btn.AutomaticSize = Enum.AutomaticSize.None
					btn.ZIndex = 511

					local btnData = { Root = btn, Value = v }

					btn.MouseButton1Click:Connect(function()
						if self.Disabled then
							return
						end
						if info.Multi then
							if selectedValues[v] then
								selectedValues[v] = nil
							else
								selectedValues[v] = true
							end
							self.Value = selectedValues
							SafeCallback(info.Callback, selectedValues)
							SafeCallback(info.Changed, selectedValues)
							UpdateDisplay()
							BuildList(searchText)
						else
							selectedKey = v
							self.Value = v
							SafeCallback(info.Callback, v)
							SafeCallback(info.Changed, v)
							UpdateDisplay()
							ClosePopup()
						end
					end)

					btn.MouseEnter:Connect(function()
						Animation.Play(btn, { BackgroundTransparency = 0.7 }, Design.AnimationFast)
					end)
					btn.MouseLeave:Connect(function()
						Animation.Play(btn, { BackgroundTransparency = isSelected and 0.85 or 1 }, Design.AnimationFast)
					end)

					table.insert(buttonCache, btnData)
					visibleCount += 1
				end
			end

			-- Size popup
			local itemH = 30
			local headerH = searchBox and 74 or 36
			local maxH = info.MaxVisibleItems * itemH
			local visH = math.min(visibleCount * itemH, maxH)
			local popupW = math.max(200, display.AbsoluteSize.X + 20)

			local absPos = display.AbsolutePosition
			local vp = Registry.ScreenGui and Registry.ScreenGui.AbsoluteSize or Vector2.new(800, 600)
			local popupX = math.min(absPos.X, vp.X - popupW - 10)
			local popupY = absPos.Y + display.AbsoluteSize.Y + 2
			if popupY + visH + headerH > vp.Y then
				popupY = absPos.Y - visH - headerH - 2
			end

			popup.Position = UDim2.fromOffset(popupX, popupY)
			popup.Size = UDim2.fromOffset(popupW, visH + headerH + 8)
			listScroll.CanvasSize = UDim2.fromOffset(0, listLayout and listLayout.AbsoluteContentSize.Y or 0)

			if Registry.ScreenGui then
				overlay.Parent = Registry.ScreenGui
				popup.Parent = Registry.ScreenGui
			end
		end

		local function OpenPopup()
			if self.Disabled then
				return
			end
			popupOpen = true
			overlay.Visible = true
			popup.Visible = true
			BuildList("")
		end

		display.MouseButton1Click:Connect(function()
			if popupOpen then
				ClosePopup()
			else
				OpenPopup()
			end
		end)

		overlay.MouseButton1Click:Connect(ClosePopup)
		closeBtn.MouseButton1Click:Connect(ClosePopup)

		if searchBox then
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				if popupOpen then
					BuildList(searchBox.Text)
				end
			end)
		end

		function self:SetValue(v)
			if self.Disabled then
				return
			end
			if info.Multi and type(v) == "table" then
				selectedValues = {}
				for _, val in pairs(v) do
					selectedValues[val] = true
				end
				self.Value = selectedValues
			else
				selectedKey = v
				self.Value = v
			end
			UpdateDisplay()
			SafeCallback(info.Callback, self.Value)
			SafeCallback(info.Changed, self.Value)
		end

		function self:SetValues(vals)
			info.Values = vals
			self.Values = vals
		end

		function self:SetText(text)
			self.Text = text
			self.Label = text
			if label then
				label.Text = text
			end
			if popupTitle then
				popupTitle.Text = text or "Select"
			end
		end

		function self:OnStateChange()
			display.Active = not self.Disabled
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.ColorPicker(container, info)
		info = MergeDefaults(info, {
			Default = Color3.new(1, 1, 1),
			Title = nil,
			Transparency = nil,
			Callback = function() end,
			Changed = function() end,
			Visible = true,
		})

		local root = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Design.ItemHeight),
			Parent = container,
		})

		local label = F.TextLabel(root, {
			Text = info.Title or "Color",
			Size = Design.FontSize_Body,
			Color = "Text",
		})
		label.Size = UDim2.new(1, -50, 1, 0)
		label.TextYAlignment = Enum.TextYAlignment.Center

		local swatch = F.Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = info.Default,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			Parent = root,
		})
		F.Corner(swatch, Design.CornerSmall)
		F.Stroke(swatch, { Color = "Border", Transparency = 0.3 })

		local swatchTransparency
		if info.Transparency ~= nil then
			swatchTransparency = F.Image(swatch, {
				Image = ObsidianImageManager.GetAsset("TransparencyTexture"),
				ImageTransparency = 1 - info.Transparency,
				ScaleType = Enum.ScaleType.Tile,
				TileSize = UDim2.fromOffset(8, 8),
			})
		end

		local currentColor = info.Default
		local currentHue, currentSat, currentVib = Color3.toHSV(info.Default)
		local currentTransparency = info.Transparency or 0

		if not currentHue then
			currentHue, currentSat, currentVib = 0, 0, 1
		end

		local self = setmetatable({
			Type = "ColorPicker",
			Root = root,
			Container = container,
			Value = currentColor,
			Transparency = currentTransparency,
			Visible = info.Visible,
			Label = info.Title or "Color",
			Addons = {},
		}, { __index = ComponentBase })

		root.Visible = self.Visible

		local colorMenu = ContextMenuSystem.Create(swatch, UDim2.fromOffset(256, 0), function()
			return { 0.5, swatch.AbsoluteSize.Y + 1.5 }
		end, 1)

		local UpdateColor

		if colorMenu and colorMenu.Inner then
			F.Padding(colorMenu.Inner, { Top = 6, Bottom = 6, Left = 6, Right = 6 })

			if info.Title and type(info.Title) == "string" then
				local titleLbl = F.TextLabel(colorMenu.Inner, {
					Text = info.Title,
					Size = Design.FontSize_Header,
					Color = "Text",
				})
				titleLbl.Size = UDim2.new(1, 0, 0, 20)
			end

			local pickerHolder = F.Create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 200),
				Parent = colorMenu.Inner,
			})

			local function MakeHueSequence()
				local seq = {}
				for h = 0, 1, 0.1 do
					table.insert(seq, ColorSequenceKeypoint.new(h, Color3.fromHSV(h, 1, 1)))
				end
				return ColorSequence.new(seq)
			end

			local pickerLayout = F.List(pickerHolder, Enum.FillDirection.Horizontal)
			pickerLayout.Padding = UDim.new(0, 6)

			local svMap = F.Create("ImageButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1),
				Image = ObsidianImageManager.GetAsset("SaturationMap"),
				Size = UDim2.fromOffset(200, 200),
				Parent = pickerHolder,
			})

			local svCursor = F.Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(8, 8),
				Parent = svMap,
			})
			F.Corner(svCursor, 4)
			F.Stroke(svCursor, { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.5 })

			local hueBar = F.Create("TextButton", {
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(16, 200),
				Text = "",
				Parent = pickerHolder,
			})
			local hueGradient = Instance.new("UIGradient")
			hueGradient.Color = MakeHueSequence()
			hueGradient.Rotation = 90
			hueGradient.Parent = hueBar

			local hueCursor = F.Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 1,
				Position = UDim2.fromScale(0.5, currentHue),
				Size = UDim2.new(1, 2, 0, 2),
				Parent = hueBar,
			})
			F.Stroke(hueCursor, { Color = Color3.fromRGB(0, 0, 0), Thickness = 1 })

			local transBar, transColor, transCursor
			if info.Transparency ~= nil then
				transBar = F.Create("ImageButton", {
					AutoButtonColor = false,
					Image = ObsidianImageManager.GetAsset("TransparencyTexture"),
					ScaleType = Enum.ScaleType.Tile,
					Size = UDim2.fromOffset(16, 200),
					TileSize = UDim2.fromOffset(8, 8),
					Parent = pickerHolder,
				})
				transColor = F.Create("Frame", {
					BackgroundColor3 = currentColor,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1, 1),
					Parent = transBar,
				})
				local transGradient = Instance.new("UIGradient")
				transGradient.Rotation = 90
				transGradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				})
				transGradient.Parent = transColor

				transCursor = F.Create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 1,
					Position = UDim2.fromScale(0.5, currentTransparency),
					Size = UDim2.new(1, 2, 0, 2),
					Parent = transBar,
				})
				F.Stroke(transCursor, { Color = Color3.fromRGB(0, 0, 0), Thickness = 1 })
			end

			local inputHolder = F.Create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				Parent = colorMenu.Inner,
			})
			local inputLayout = F.List(inputHolder, Enum.FillDirection.Horizontal)
			inputLayout.Padding = UDim.new(0, 8)

			local hexBox = F.TextBox(inputHolder, {
				Text = "#" .. currentColor:ToHex(),
				Size = Design.FontSize_Small,
				Color = "Text",
				Background = "SurfaceAlt",
				ClearOnFocus = false,
			})
			F.Corner(hexBox, Design.CornerSmall)
			F.Stroke(hexBox, { Color = "Border", Transparency = 0.3 })
			F.Padding(hexBox, { Left = 6, Right = 6 })

			local rgbBox = F.TextBox(inputHolder, {
				Text = ("%d, %d, %d"):format(
					math.floor(currentColor.R * 255),
					math.floor(currentColor.G * 255),
					math.floor(currentColor.B * 255)
				),
				Size = Design.FontSize_Small,
				Color = "Text",
				Background = "SurfaceAlt",
				ClearOnFocus = false,
			})
			F.Corner(rgbBox, Design.CornerSmall)
			F.Stroke(rgbBox, { Color = "Border", Transparency = 0.3 })
			F.Padding(rgbBox, { Left = 6, Right = 6 })

			UpdateColor = function()
				currentColor = Color3.fromHSV(currentHue, currentSat, currentVib)
				swatch.BackgroundColor3 = currentColor
				svMap.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
				svCursor.Position = UDim2.fromScale(currentSat, 1 - currentVib)
				hueCursor.Position = UDim2.fromScale(0.5, currentHue)
				if transColor then
					transColor.BackgroundColor3 = currentColor
				end
				if transCursor then
					transCursor.Position = UDim2.fromScale(0.5, currentTransparency)
				end
				hexBox.Text = "#" .. currentColor:ToHex()
				rgbBox.Text = ("%d, %d, %d"):format(
					math.floor(currentColor.R * 255),
					math.floor(currentColor.G * 255),
					math.floor(currentColor.B * 255)
				)
				self.Value = currentColor
				self.Transparency = currentTransparency
				SafeCallback(info.Callback, currentColor)
				SafeCallback(info.Changed, currentColor)
			end

			-- SV map drag
			svMap.InputBegan:Connect(function(input)
				if not IsClick(input) then
					return
				end
				while IsDrag(input) do
					local minX = svMap.AbsolutePosition.X
					local maxX = minX + svMap.AbsoluteSize.X
					local locX = Clamp(Mouse.X, minX, maxX)
					local minY = svMap.AbsolutePosition.Y
					local maxY = minY + svMap.AbsoluteSize.Y
					local locY = Clamp(Mouse.Y, minY, maxY)
					currentSat = (locX - minX) / (maxX - minX)
					currentVib = 1 - ((locY - minY) / (maxY - minY))
					UpdateColor()
					RunService.RenderStepped:Wait()
				end
			end)

			-- Hue bar drag
			hueBar.InputBegan:Connect(function(input)
				if not IsClick(input) then
					return
				end
				while IsDrag(input) do
					local minY = hueBar.AbsolutePosition.Y
					local maxY = minY + hueBar.AbsoluteSize.Y
					local locY = Clamp(Mouse.Y, minY, maxY)
					currentHue = (locY - minY) / (maxY - minY)
					UpdateColor()
					RunService.RenderStepped:Wait()
				end
			end)

			-- Transparency bar drag
			if transBar then
				transBar.InputBegan:Connect(function(input)
					if not IsClick(input) then
						return
					end
					while IsDrag(input) do
						local minY = transBar.AbsolutePosition.Y
						local maxY = minY + transBar.AbsoluteSize.Y
						local locY = Clamp(Mouse.Y, minY, maxY)
						currentTransparency = (locY - minY) / (maxY - minY)
						UpdateColor()
						RunService.RenderStepped:Wait()
					end
				end)
			end

			-- Hex input
			hexBox.FocusLost:Connect(function(enter)
				if not enter then
					return
				end
				local ok, color = pcall(Color3.fromHex, hexBox.Text)
				if ok and typeof(color) == "Color3" then
					currentHue, currentSat, currentVib = Color3.toHSV(color)
					if not currentHue then
						currentHue = 0
					end
					UpdateColor()
				end
			end)

			-- RGB input
			rgbBox.FocusLost:Connect(function(enter)
				if not enter then
					return
				end
				local r, g, b = rgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
				if r and g and b then
					local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
					currentHue, currentSat, currentVib = Color3.toHSV(color)
					if not currentHue then
						currentHue = 0
					end
					UpdateColor()
				end
			end)
		end

		if not UpdateColor then
			UpdateColor = function()
				currentColor = Color3.fromHSV(currentHue or 0, currentSat or 0, currentVib or 1)
				swatch.BackgroundColor3 = currentColor
				self.Value = currentColor
				self.Transparency = currentTransparency
				SafeCallback(info.Callback, currentColor)
				SafeCallback(info.Changed, currentColor)
			end
		end

		swatch.MouseButton1Click:Connect(function()
			if self.Disabled then
				return
			end
			if colorMenu then
				colorMenu:Toggle()
			end
		end)

		function self:SetValue(color, transparency)
			if type(color) == "Color3" then
				currentColor = color
				local h, s, v = Color3.toHSV(color)
				currentHue = h or 0
				currentSat = s or 0
				currentVib = v or 1
			end
			if transparency ~= nil and info.Transparency ~= nil then
				currentTransparency = transparency
			end
			UpdateColor()
		end

		function self:SetText(text)
			self.Label = text
			label.Text = text or "Color"
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Viewport(container, info)
		info = MergeDefaults(info, {
			Object = nil,
			Camera = nil,
			Clone = true,
			AutoFocus = true,
			Interactive = false,
			Height = 200,
			Visible = true,
		})

		assert(info.Object, "Viewport requires an Object")

		local root = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, info.Height),
			Visible = info.Visible,
			Parent = container,
		})

		local box = F.Create("Frame", {
			BackgroundColor3 = "Surface",
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 1),
			Parent = root,
		})
		F.Corner(box, Design.CornerSmall)
		F.Stroke(box, { Color = "Border", Transparency = 0.3 })

		local viewportObj = info.Clone and info.Object:Clone() or info.Object
		local camera = info.Camera or Instance.new("Camera")

		local viewportFrame = Instance.new("ViewportFrame")
		viewportFrame.BackgroundTransparency = 1
		viewportFrame.BorderSizePixel = 0
		viewportFrame.Size = UDim2.fromScale(1, 1)
		viewportFrame.CurrentCamera = camera
		viewportFrame.Active = info.Interactive
		viewportFrame.Parent = box

		viewportObj.Parent = viewportFrame

		if info.AutoFocus then
			local function FocusCamera()
				local modelSize
				if viewportObj:IsA("BasePart") then
					modelSize = viewportObj.Size
				else
					modelSize = select(2, viewportObj:GetBoundingBox())
				end
				local maxExt = math.max(modelSize.X, modelSize.Y, modelSize.Z)
				local dist = maxExt * 2
				local modelPos = viewportObj:GetPivot().Position
				camera.CFrame = CFrame.new(modelPos + Vector3.new(0, maxExt / 2, dist), modelPos)
			end
			FocusCamera()
		end

		local dragging = false
		local pinching = false
		local lastMousePos

		viewportFrame.InputBegan:Connect(function(input)
			if not info.Interactive then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				dragging = true
				lastMousePos = input.Position
			end
		end)

		Connect(UserInputService.InputEnded:Connect(function(input)
			if not info.Interactive then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				dragging = false
			end
		end))

		Connect(UserInputService.InputChanged:Connect(function(input)
			if not info.Interactive or not dragging then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			local delta = input.Position - lastMousePos
			lastMousePos = input.Position
			local pos = viewportObj:GetPivot().Position
			local rotY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -delta.X * 0.01)
			camera.CFrame = CFrame.new(pos) * rotY * CFrame.new(-pos) * camera.CFrame
			local rotX = CFrame.fromAxisAngle(camera.CFrame.RightVector, -delta.Y * 0.01)
			local pitched = CFrame.new(pos) * rotX * CFrame.new(-pos) * camera.CFrame
			if pitched.UpVector.Y > 0.1 then
				camera.CFrame = pitched
			end
		end))

		viewportFrame.InputChanged:Connect(function(input)
			if not info.Interactive then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local zoom = input.Position.Z * 2
				camera.CFrame += camera.CFrame.LookVector * zoom
			end
		end)

		local self = setmetatable({
			Type = "Viewport",
			Root = root,
			Container = container,
			Object = viewportObj,
			Camera = camera,
			ViewportFrame = viewportFrame,
			Visible = info.Visible,
			Label = "Viewport",
		}, { __index = ComponentBase })

		function self:SetObject(obj, clone)
			if clone then
				obj = obj:Clone()
			end
			if self.Object then
				self.Object:Destroy()
			end
			self.Object = obj
			self.Object.Parent = viewportFrame
		end

		function self:SetHeight(height)
			root.Size = UDim2.new(1, 0, 0, height)
			if container.Resize then
				container:Resize()
			end
		end

		function self:Focus()
			local modelSize
			if viewportObj:IsA("BasePart") then
				modelSize = viewportObj.Size
			else
				modelSize = select(2, viewportObj:GetBoundingBox())
			end
			local maxExt = math.max(modelSize.X, modelSize.Y, modelSize.Z)
			local dist = maxExt * 2
			local modelPos = viewportObj:GetPivot().Position
			camera.CFrame = CFrame.new(modelPos + Vector3.new(0, maxExt / 2, dist), modelPos)
		end

		function self:SetCamera(newCam)
			camera = newCam
			viewportFrame.CurrentCamera = newCam
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end

	function Components.Image(container, info)
		info = MergeDefaults(info, {
			Image = "",
			Transparency = 0,
			Color = Color3.new(1, 1, 1),
			RectOffset = Vector2.zero,
			RectSize = Vector2.zero,
			ScaleType = Enum.ScaleType.Fit,
			Height = 200,
			Visible = true,
		})

		local imageUrl = info.Image
		local imgRectOffset = info.RectOffset
		local imgRectSize = info.RectSize

		if
			not (imageUrl:match("rbxasset") or imageUrl:match("roblox%.com/asset/") or imageUrl:match("rbxthumb://"))
		then
			local icon = GetIcon(imageUrl)
			if icon then
				imageUrl = icon.Url
				imgRectOffset = icon.ImageRectOffset
				imgRectSize = icon.ImageRectSize
			end
		end

		local root = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, info.Height),
			Visible = info.Visible,
			Parent = container,
		})

		local box = F.Create("Frame", {
			BackgroundColor3 = "Surface",
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 1),
			Parent = root,
		})
		F.Corner(box, Design.CornerSmall)
		F.Stroke(box, { Color = "Border", Transparency = 0.3 })

		local imageLabel = F.Image(box, {
			Image = imageUrl,
			Color = info.Color,
			Transparency = info.Transparency,
			RectOffset = imgRectOffset,
			RectSize = imgRectSize,
			ScaleType = info.ScaleType,
		})
		imageLabel.Size = UDim2.fromScale(1, 1)

		local self = setmetatable({
			Type = "Image",
			Root = root,
			Container = container,
			Image = imageLabel,
			ImageUrl = imageUrl,
			Visible = info.Visible,
			Label = "Image",
		}, { __index = ComponentBase })

		function self:SetHeight(height)
			root.Size = UDim2.new(1, 0, 0, height)
			if container.Resize then
				container:Resize()
			end
		end

		function self:SetImage(newImage)
			if
				not (
					newImage:match("rbxasset")
					or newImage:match("roblox%.com/asset/")
					or newImage:match("rbxthumb://")
				)
			then
				local icon = GetIcon(newImage)
				if icon then
					newImage = icon.Url
					imageLabel.ImageRectOffset = icon.ImageRectOffset
					imageLabel.ImageRectSize = icon.ImageRectSize
				end
			end
			imageLabel.Image = newImage
			self.ImageUrl = newImage
		end

		function self:SetColor(color)
			imageLabel.ImageColor3 = color
		end

		function self:SetTransparency(transparency)
			imageLabel.ImageTransparency = transparency
		end

		table.insert(container.Components, self)
		Registry.Components[self] = self
		if container.Resize then
			container:Resize()
		end
		return self
	end
end

-- Tab-in-Tab (Tabbox within a tab page)
local function CreateTabbox(page, info)
	info = MergeDefaults(info, {
		Side = 1,
		Name = nil,
	})

	local boxHolder = F.Create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		Parent = page.Scroll,
	})

	local background = F.Create("Frame", {
		BackgroundColor3 = "Border",
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Parent = boxHolder,
	})
	F.Corner(background, Design.Corner)
	background.AutomaticSize = Enum.AutomaticSize.Y

	local inner = F.Create("Frame", {
		BackgroundColor3 = "Surface",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = background,
	})
	F.Corner(inner, Design.CornerSmall)

	local tabButtons = F.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = inner,
	})
	local tabBtnList = F.List(tabButtons, Enum.FillDirection.Horizontal)
	tabBtnList.HorizontalFlex = Enum.UIFlexAlignment.Fill

	local tabbox = {
		ActiveTab = nil,
		BoxHolder = boxHolder,
		Holder = background,
		Inner = inner,
		Tabs = {},
	}

	function tabbox:AddTab(name)
		local button = F.TextButton(tabButtons, {
			Text = name,
			Size = Design.FontSize_Body,
			Color = "SubText",
			BgTransparency = 0,
			XAlign = Enum.TextXAlignment.Center,
		})
		button.BackgroundColor3 = Palette.SurfaceAlt
		button.Size = UDim2.fromOffset(0, 34)
		button.BorderSizePixel = 0

		local line = F.Create("Frame", {
			BackgroundColor3 = "Accent",
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 2),
			Visible = false,
			Parent = button,
		})

		local container = F.Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 35),
			Size = UDim2.new(1, 0, 1, -35),
			Visible = false,
			Parent = inner,
		})
		F.Padding(container, { Top = 7, Bottom = 7, Left = 7, Right = 7 })
		local list = F.List(container)

		local tab = {
			ButtonHolder = button,
			Container = container,
			Line = line,
			Elements = {},
			DependencyBoxes = {},
			Tabbox = tabbox,
		}

		function tab:Resize()
			if tabbox.ActiveTab ~= tab then
				return
			end
			local h = (list and list.AbsoluteContentSize.Y or 0) + 53
			background.Size = UDim2.fromScale(1, 0)
			background.AutomaticSize = Enum.AutomaticSize.Y
			task.defer(function()
				background.Size = UDim2.new(1, 0, 0, h)
				background.AutomaticSize = Enum.AutomaticSize.None
			end)
		end

		function tab:Show()
			if tabbox.ActiveTab and tabbox.ActiveTab ~= tab then
				tabbox.ActiveTab:Hide()
			end
			button.BackgroundColor3 = Palette.Surface
			button.TextColor3 = Palette.Text
			line.Visible = true
			container.Visible = true
			tabbox.ActiveTab = tab
			tab:Resize()
		end

		function tab:Hide()
			button.BackgroundColor3 = Palette.SurfaceAlt
			button.TextColor3 = Palette.SubText
			line.Visible = false
			container.Visible = false
		end

		button.MouseButton1Click:Connect(function()
			tab:Show()
		end)

		if not tabbox.ActiveTab then
			tab:Show()
		end

		tabbox.Tabs[name] = tab
		return tab
	end

	table.insert(page.Tabboxes, tabbox)
	Registry.Cards[tabbox] = tabbox

	return tabbox
end

-- DependencyBox
local function CreateDependencyBox(parentContainer)
	local depContainer = F.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = parentContainer,
	})
	local depList = F.List(depContainer)

	local depbox = {
		Visible = false,
		Dependencies = {},
		Holder = depContainer,
		Container = depContainer,
		Elements = {},
		DependencyBoxes = {},
	}

	function depbox:Resize()
		depContainer.Size = UDim2.new(1, 0, 0, depList.AbsoluteContentSize.Y)
		if depbox.ParentResize then
			depbox:ParentResize()
		end
	end

	function depbox:Update(cancelSearch)
		for _, dep in pairs(depbox.Dependencies) do
			local el = dep[1]
			local expected = dep[2]
			if el.Type == "Toggle" and el.Value ~= expected then
				depContainer.Visible = false
				depbox.Visible = false
				return
			elseif el.Type == "Dropdown" then
				if type(el.Value) == "table" then
					if not el.Value[expected] then
						depContainer.Visible = false
						depbox.Visible = false
						return
					end
				elseif el.Value ~= expected then
					depContainer.Visible = false
					depbox.Visible = false
					return
				end
			end
		end
		depbox.Visible = true
		depContainer.Visible = true
		if not cancelSearch then
			if SearchEngine and Registry.DependencyBoxes then
				SearchEngine.UpdateDependencyBoxes()
			end
		end
		depbox:Resize()
	end

	function depbox:SetupDependencies(deps)
		for _, dep in pairs(deps) do
			assert(type(dep) == "table" and dep[1] and dep[2] ~= nil, "Dependency must be {element, expectedValue}")
		end
		depbox.Dependencies = deps
		depbox:Update()
	end

	setmetatable(
		depbox,
		{
			__index = {
				AddLabel = function(_, i)
					return Components.Label(depContainer, i)
				end,
				AddButton = function(_, i)
					return Components.Button(depContainer, i)
				end,
				AddToggle = function(_, i)
					return Components.Toggle(depContainer, i)
				end,
				AddSlider = function(_, i)
					return Components.Slider(depContainer, i)
				end,
				AddInput = function(_, i)
					return Components.Input(depContainer, i)
				end,
				AddDropdown = function(_, i)
					return Components.Dropdown(depContainer, i)
				end,
				AddSeparator = function()
					return Components.Separator(depContainer)
				end,
				AddKeybind = function(_, i)
					return Components.Keybind(depContainer, i)
				end,
				AddColorPicker = function(_, i)
					return Components.ColorPicker(depContainer, i)
				end,
				AddViewport = function(_, i)
					return Components.Viewport(depContainer, i)
				end,
				AddImage = function(_, i)
					return Components.Image(depContainer, i)
				end,
				AddDependencyBox = function()
					return CreateDependencyBox(depContainer)
				end,
			},
		}
	)

	table.insert(Registry.DependencyBoxes, depbox)
	return depbox
end

-- DependencyGroupbox (full groupbox that shows/hides)
local function CreateDependencyGroupbox(page)
	local bg = F.Create("Frame", {
		BackgroundColor3 = "Border",
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Visible = false,
		Parent = page.Scroll,
	})
	F.Corner(bg, Design.Corner)
	bg.AutomaticSize = Enum.AutomaticSize.Y

	local inner = F.Create("Frame", {
		BackgroundColor3 = "Surface",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = bg,
	})
	F.Corner(inner, Design.CornerSmall)
	F.Padding(inner, { Top = 7, Bottom = 7, Left = 7, Right = 7 })
	local list = F.List(inner)

	local depGroup = {
		Visible = false,
		Dependencies = {},
		Holder = bg,
		Container = inner,
		Page = page,
		Elements = {},
		DependencyBoxes = {},
	}

	function depGroup:Resize()
		local h = list.AbsoluteContentSize.Y + 18
		bg.Size = UDim2.new(1, 0, 0, h)
		bg.AutomaticSize = Enum.AutomaticSize.None
	end

	function depGroup:Update(cancelSearch)
		for _, dep in pairs(depGroup.Dependencies) do
			local el = dep[1]
			local expected = dep[2]
			if el.Type == "Toggle" and el.Value ~= expected then
				bg.Visible = false
				depGroup.Visible = false
				return
			elseif el.Type == "Dropdown" then
				if type(el.Value) == "table" then
					if not el.Value[expected] then
						bg.Visible = false
						depGroup.Visible = false
						return
					end
				elseif el.Value ~= expected then
					bg.Visible = false
					depGroup.Visible = false
					return
				end
			end
		end
		depGroup.Visible = true
		bg.Visible = true
		if not cancelSearch then
			SearchEngine.UpdateDependencyBoxes()
		end
		depGroup:Resize()
	end

	function depGroup:SetupDependencies(deps)
		for _, dep in pairs(deps) do
			assert(type(dep) == "table" and dep[1] and dep[2] ~= nil)
		end
		depGroup.Dependencies = deps
		depGroup:Update()
	end

	setmetatable(
		depGroup,
		{
			__index = {
				AddLabel = function(_, i)
					return Components.Label(inner, i)
				end,
				AddButton = function(_, i)
					return Components.Button(inner, i)
				end,
				AddToggle = function(_, i)
					return Components.Toggle(inner, i)
				end,
				AddSlider = function(_, i)
					return Components.Slider(inner, i)
				end,
				AddInput = function(_, i)
					return Components.Input(inner, i)
				end,
				AddDropdown = function(_, i)
					return Components.Dropdown(inner, i)
				end,
				AddSeparator = function()
					return Components.Separator(inner)
				end,
				AddKeybind = function(_, i)
					return Components.Keybind(inner, i)
				end,
				AddColorPicker = function(_, i)
					return Components.ColorPicker(inner, i)
				end,
				AddViewport = function(_, i)
					return Components.Viewport(inner, i)
				end,
				AddImage = function(_, i)
					return Components.Image(inner, i)
				end,
				AddDependencyBox = function()
					return CreateDependencyBox(inner)
				end,
			},
		}
	)

	table.insert(Registry.DependencyBoxes, depGroup)
	return depGroup
end

local function CreateCard(page, info)
	info = MergeDefaults(info, {
		Title = "Card",
		Description = nil,
		Icon = nil,
	})

	local holder = F.Create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = page.Scroll,
	})

	local card = F.Create("Frame", {
		BackgroundColor3 = "Surface",
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = holder,
	})
	F.Corner(card, Design.Corner)
	F.Stroke(card, { Color = "Border", Transparency = 0.35 })

	if info.Title then
		local header = F.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 36),
			Parent = card,
		})

		local titleLabel = F.TextLabel(header, {
			Text = info.Title,
			Size = Design.FontSize_Header,
			Color = "Text",
		})
		titleLabel.Size = UDim2.new(1, -Design.CardPad * 2, 1, 0)
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		F.Padding(titleLabel, { Left = Design.CardPad, Right = Design.CardPad })

		if info.Description then
			titleLabel.Size = UDim2.new(1, -Design.CardPad * 2, 0, 20)
			local desc = F.TextLabel(header, {
				Text = info.Description,
				Size = Design.FontSize_Small,
				Color = "SubText",
			})
			desc.Position = UDim2.fromOffset(Design.CardPad, 20)
			desc.Size = UDim2.new(1, -Design.CardPad * 2, 0, 14)
		end

		local separator = F.Create("Frame", {
			BackgroundColor3 = "BorderFaint",
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, Design.CardPad, 1, -1),
			Size = UDim2.new(1, -Design.CardPad * 2, 0, 1),
			Parent = header,
		})
	end

	local content = F.Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, info.Title and 36 or 2),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	F.Padding(content, {
		Top = Design.CardPad,
		Bottom = Design.CardPad,
		Left = Design.CardPad,
		Right = Design.CardPad,
	})
	local list = F.List(content)

	local cardObject = {
		Holder = holder,
		Card = card,
		Content = content,
		Title = info.Title,
		Description = info.Description,
		Page = page,
		Components = {},
	}

	function cardObject:AddLabel(labelInfo)
		return Components.Label(self.Content, labelInfo)
	end

	function cardObject:AddButton(btnInfo)
		return Components.Button(self.Content, btnInfo)
	end

	function cardObject:AddToggle(toggleInfo)
		return Components.Toggle(self.Content, toggleInfo)
	end

	function cardObject:AddSlider(sliderInfo)
		return Components.Slider(self.Content, sliderInfo)
	end

	function cardObject:AddInput(inputInfo)
		return Components.Input(self.Content, inputInfo)
	end

	function cardObject:AddDropdown(dropdownInfo)
		return Components.Dropdown(self.Content, dropdownInfo)
	end

	function cardObject:AddSeparator()
		return Components.Separator(self.Content)
	end

	function cardObject:AddKeybind(keybindInfo)
		return Components.Keybind(self.Content, keybindInfo)
	end

	function cardObject:AddColorPicker(cpInfo)
		return Components.ColorPicker(self.Content, cpInfo)
	end

	function cardObject:AddViewport(vpInfo)
		return Components.Viewport(self.Content, vpInfo)
	end

	function cardObject:AddImage(imgInfo)
		return Components.Image(self.Content, imgInfo)
	end

	function cardObject:AddDependencyBox()
		local db = CreateDependencyBox(self.Content)
		db.ParentResize = function()
			cardObject:Resize()
		end
		return db
	end

	function cardObject:Resize()
		local contentHeight = list and list.AbsoluteContentSize.Y or 0
		if contentHeight > 0 then
			contentHeight += Design.CardPad * 2
		end
		if info.Title then
			contentHeight += 36
		end
		holder.Size = UDim2.new(1, 0, 0, contentHeight + Design.CardGap)
		if page.OnCardResized then
			page:OnCardResized()
		end
	end

	function cardObject:SetVisible(visible)
		holder.Visible = visible
	end

	function cardObject:Destroy()
		holder:Destroy()
		page.Cards[cardObject] = nil
	end

	table.insert(page.Cards, cardObject)
	Registry.Cards[cardObject] = cardObject

	return cardObject
end

local PageMethods = {}

function PageMethods:AddCard(info)
	return CreateCard(self, info)
end

function PageMethods:AddTabbox(info)
	return CreateTabbox(self, info or {})
end

function PageMethods:AddLeftTabbox(name)
	return CreateTabbox(self, { Name = name, Side = 1 })
end

function PageMethods:AddRightTabbox(name)
	return CreateTabbox(self, { Name = name, Side = 2 })
end

function PageMethods:AddDependencyGroupbox()
	return CreateDependencyGroupbox(self)
end

function PageMethods:OnCardResized()
	task.defer(function()
		if self.Scroll then
			self.Scroll.CanvasSize = UDim2.fromOffset(0, self.List and self.List.AbsoluteContentSize.Y or 0)
		end
	end)
end

function PageMethods:Show()
	if not self.Window then
		return
	end
	self.Window:ShowPage(self)
end

local function CreatePage(window, info)
	info = MergeDefaults(info, {
		Name = "Page",
		Icon = nil,
		Description = nil,
	})

	local button = F.TextButton(window.SidebarList, {
		Text = "",
		BgTransparency = 1,
		XAlign = Enum.TextXAlignment.Left,
	})
	button.Size = UDim2.new(1, 0, 0, 40)
	button.AutomaticSize = Enum.AutomaticSize.None

	local iconLabel
	if info.Icon then
		local icon = GetIcon(info.Icon)
		if icon then
			iconLabel = F.Image(button, {
				Image = icon.Url,
				Color = "Muted",
				RectOffset = icon.ImageRectOffset,
				RectSize = icon.ImageRectSize,
			})
			iconLabel.Size = UDim2.fromOffset(24, 24)
		end
	end
	if not iconLabel and info.Icon then
		iconLabel = F.TextLabel(button, {
			Text = info.Icon,
			Size = Design.FontSize_Header,
			Color = "Muted",
		})
		iconLabel.Size = UDim2.fromOffset(24, 40)
		iconLabel.TextXAlignment = Enum.TextXAlignment.Center
		iconLabel.TextYAlignment = Enum.TextYAlignment.Center
		F.Padding(button, { Left = 8 })
	elseif iconLabel then
		F.Padding(button, { Left = 8 })
	else
		F.Padding(button, { Left = 12 })
	end

	local nameLabel = F.TextLabel(button, {
		Text = info.Name,
		Size = Design.FontSize_Body,
		Color = "Muted",
	})
	nameLabel.Position = iconLabel and UDim2.fromOffset(36, 0) or UDim2.fromOffset(12, 0)
	nameLabel.Size = UDim2.new(1, -(iconLabel and 40 or 16), 1, 0)
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center

	local scroll = F.Scroll(window.ContentArea)
	scroll.Visible = false
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.Position = UDim2.fromOffset(0, 0)

	local list = F.List(scroll)
	list.Padding = UDim.new(0, Design.CardGap)
	F.Padding(scroll, {
		Top = Design.ContentPad,
		Bottom = Design.ContentPad,
		Left = Design.ContentPad,
		Right = Design.ContentPad,
	})

	local IsKeyTab = info.Name == "Keybinds" or info.IsKeyTab

	local page = {
		Window = window,
		Button = button,
		NameLabel = nameLabel,
		IconLabel = iconLabel,
		Scroll = scroll,
		List = list,
		Info = info,
		Name = info.Name,
		Description = info.Description,
		Cards = {},
		Tabboxes = {},
		DependencyGroupboxes = {},
		Active = false,
		IsKeyTab = IsKeyTab,
	}

	for k, v in pairs(PageMethods) do
		page[k] = v
	end

	local function OnClick()
		window:ShowPage(page)
	end

	button.MouseButton1Click:Connect(OnClick)

	function page:Activate()
		scroll.Visible = true
		page.Active = true
		nameLabel.TextColor3 = Palette.Text
		nameLabel.TextTransparency = 0
		if iconLabel then
			iconLabel.ImageColor3 = Palette.Accent
		end
		button.BackgroundColor3 = Palette.SurfaceAlt
		button.BackgroundTransparency = 0.5
	end

	function page:Deactivate()
		scroll.Visible = false
		page.Active = false
		nameLabel.TextColor3 = Palette.Muted
		if iconLabel then
			iconLabel.ImageColor3 = Palette.Muted
		end
		button.BackgroundColor3 = Color3.new(0, 0, 0)
		button.BackgroundTransparency = 1
	end

	function page:Destroy()
		scroll:Destroy()
		button:Destroy()
		window.Pages[page] = nil
	end

	table.insert(window.Pages, page)
	Registry.Pages[page] = page

	task.defer(function()
		scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y or 0)
	end)

	return page
end

local function CreateWindow(info)
	info = MergeDefaults(info, {
		Title = "LRXUI",
		SubTitle = "Framework",
		Size = UDim2.fromOffset(900, 600),
		Position = UDim2.fromOffset(50, 50),
		Resizable = true,
		Theme = "Dark",
		Footer = "Version 1.0",
		MinSize = Vector2.new(640, 400),
		ToggleKey = Enum.KeyCode.RightControl,
		ShowCustomCursor = false,
		DisableSearch = false,
		AutoShow = true,
		WatermarkEnabled = false,
		WatermarkText = "",
	})

	CurrentScheme = Schemes[info.Theme] or Schemes.Dark
	Palette = CurrentScheme
	LRXUI.Palette = Palette
	LRXUI.CurrentScheme = CurrentScheme

	local screenGui = F.Create("ScreenGui", {
		Name = "LRXUI",
		DisplayOrder = 2147483647,
		ResetOnSpawn = false,
	})
	protect(screenGui)
	screenGui.Parent = PlayerGui
	Registry.ScreenGui = screenGui

	local modalGui = F.Create("ScreenGui", {
		Name = "LRXUIModal",
		DisplayOrder = 2147483647,
		ResetOnSpawn = false,
	})
	protect(modalGui)
	modalGui.Parent = PlayerGui

	-- Keybind frame
	local keybindFrame, keybindContainer
	do
		local bg = F.Create("Frame", {
			BackgroundColor3 = "Border",
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(6, 6),
			Visible = false,
			Parent = screenGui,
			DPIExclude = { Position = true, Size = true },
		})
		F.Corner(bg, Design.Corner)

		local holder = F.Create("Frame", {
			BackgroundColor3 = "Surface",
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.new(1, -4, 1, -4),
			Parent = bg,
		})
		F.Corner(holder, Design.CornerSmall)

		local kbLabel = F.TextLabel(holder, {
			Text = "Keybinds",
			Size = Design.FontSize_Header,
			Color = "Text",
		})
		kbLabel.Size = UDim2.new(1, 0, 0, 34)
		kbLabel.TextXAlignment = Enum.TextXAlignment.Left
		F.Padding(kbLabel, { Left = 12 })

		local kbSeparator = F.Create("Frame", {
			BackgroundColor3 = "BorderFaint",
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 34),
			Size = UDim2.new(1, 0, 0, 1),
			Parent = holder,
		})

		keybindContainer = F.Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 35),
			Size = UDim2.new(1, 0, 1, -35),
			Parent = holder,
		})
		F.Padding(keybindContainer, { Top = 7, Bottom = 7, Left = 7, Right = 7 })
		F.List(keybindContainer)
		keybindContainer.Padding = UDim.new(0, 6)

		keybindFrame = bg
		Registry.KeybindContainer = keybindContainer
		Registry.KeybindFrame = keybindFrame
		Registry.KeybindToggles = {}

		function Registry.UpdateKeybindFrame()
			local maxX = 0
			for _, toggle in pairs(Registry.KeybindToggles) do
				if toggle and toggle.Visible and toggle.AbsoluteSize then
					local w = toggle.AbsoluteSize.X
					if w > maxX then
						maxX = w
					end
				end
			end
			keybindFrame.Size = UDim2.fromOffset(maxX + 18, 0)
		end

		MakeDraggable(keybindFrame, kbLabel)
	end

	-- Watermark
	WatermarkSystem.Initialize(screenGui)

	-- Custom Cursor
	CustomCursor.Initialize(screenGui)

	-- IsMobile detection
	local IsMobile = false
	do
		if RunService:IsStudio() then
			IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
		else
			local ok, platform = pcall(function()
				return UserInputService:GetPlatform()
			end)
			IsMobile = ok and (platform == Enum.Platform.Android or platform == Enum.Platform.IOS)
		end
	end

	-- Window frame
	local window = F.Create("Frame", {
		Active = true,
		BackgroundColor3 = "Background",
		BorderSizePixel = 0,
		Position = info.Position,
		Size = info.Size,
		Visible = true,
		Parent = screenGui,
		DPIExclude = { Position = true },
	})
	F.Corner(window, Design.WindowCorner)
	F.Stroke(window, { Color = "Border", Transparency = 0.4 })

	-- Header
	local header = F.Create("Frame", {
		BackgroundColor3 = "Sidebar",
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Design.HeaderHeight),
		Parent = window,
	})
	F.Corner(header, Design.WindowCorner)
	local headerClip = F.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Design.HeaderHeight),
		Parent = header,
		ClipsDescendants = true,
	})

	local titleText = F.TextLabel(header, {
		Text = info.Title,
		Size = Design.FontSize_Title,
		Color = "Text",
	})
	titleText.Size = UDim2.new(0, 200, 1, 0)
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	F.Padding(titleText, { Left = 16 })

	local subtitleText = F.TextLabel(header, {
		Text = info.SubTitle,
		Size = Design.FontSize_Small,
		Color = "Muted",
	})
	subtitleText.Position = UDim2.fromOffset(16 + 200 + 8, 0)
	subtitleText.Size = UDim2.new(0, 200, 1, 0)
	subtitleText.TextYAlignment = Enum.TextYAlignment.Center

	-- Search box in header
	local searchBox
	if not info.DisableSearch then
		local searchIcon = GetIcon("search")
		searchBox = F.TextBox(headerClip, {
			Placeholder = "Search...",
			Background = "SurfaceAlt",
			ClearOnFocus = false,
		})
		searchBox.Size = UDim2.fromOffset(180, 28)
		searchBox.TextSize = Design.FontSize_Small
		searchBox.AnchorPoint = Vector2.new(1, 0.5)
		searchBox.Position = UDim2.new(1, -12, 0.5, 0)
		F.Corner(searchBox, Design.CornerSmall)
		F.Stroke(searchBox, { Color = "Border", Transparency = 0.3 })
		F.Padding(searchBox, { Left = 8, Right = 8 })

		if searchIcon then
			local searchImg = F.Image(searchBox, {
				Image = searchIcon.Url,
				Color = "Muted",
				RectOffset = searchIcon.ImageRectOffset,
				RectSize = searchIcon.ImageRectSize,
			})
			searchImg.Size = UDim2.fromOffset(16, 16)
			searchImg.AnchorPoint = Vector2.new(1, 0.5)
			searchImg.Position = UDim2.new(1, -4, 0.5, 0)
		end
	end

	MakeDraggable(window, header)

	-- Main area
	local mainArea = F.Create("Frame", {
		BackgroundColor3 = "Content",
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, Design.HeaderHeight),
		Size = UDim2.new(1, 0, 1, -(Design.HeaderHeight + Design.FooterHeight)),
		Parent = window,
	})

	-- Sidebar
	local sidebar = F.Create("Frame", {
		BackgroundColor3 = "Sidebar",
		BorderSizePixel = 0,
		Size = UDim2.new(0, Design.SidebarWidth, 1, 0),
		Parent = mainArea,
	})

	local sidebarScroll = F.Scroll(sidebar)
	sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
	sidebarScroll.ScrollBarThickness = 0
	sidebarScroll.CanvasSize = UDim2.fromOffset(0, 0)

	local sidebarList = F.List(sidebarScroll)
	F.Padding(sidebarScroll, { Top = 8, Bottom = 8 })

	local sidebarSeparator = F.Create("Frame", {
		BackgroundColor3 = "Border",
		BorderSizePixel = 0,
		Position = UDim2.new(0, Design.SidebarWidth, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		Parent = mainArea,
	})

	-- Content area
	local contentArea = F.Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(Design.SidebarWidth + 1, 0),
		Size = UDim2.new(1, -(Design.SidebarWidth + 1), 1, 0),
		Parent = mainArea,
	})

	-- Footer
	local footer = F.Create("Frame", {
		BackgroundColor3 = "Sidebar",
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, Design.FooterHeight),
		Parent = window,
	})

	local versionLabel = F.TextLabel(footer, {
		Text = info.Footer,
		Size = Design.FontSize_Small,
		Color = "Muted",
	})
	versionLabel.Size = UDim2.new(0, 200, 1, 0)
	versionLabel.TextXAlignment = Enum.TextXAlignment.Left
	F.Padding(versionLabel, { Left = 16 })

	local statusLabel = F.TextLabel(footer, {
		Text = "",
		Size = Design.FontSize_Small,
		Color = "Muted",
	})
	statusLabel.AnchorPoint = Vector2.new(1, 0)
	statusLabel.Size = UDim2.new(0, 200, 1, 0)
	statusLabel.Position = UDim2.new(1, -16, 0, 0)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- Notification area
	NotificationSystem.Initialize(window)

	-- Window object
	local windowObject = {
		ScreenGui = screenGui,
		ModalGui = modalGui,
		Window = window,
		Header = header,
		MainArea = mainArea,
		Sidebar = sidebar,
		SidebarScroll = sidebarScroll,
		SidebarList = sidebarList,
		ContentArea = contentArea,
		Footer = footer,
		Pages = {},
		ActivePage = nil,
		Info = info,
		Visible = true,
		Toggled = true,
	}

	table.insert(Registry.Windows, windowObject)

	function windowObject:AddPage(pageInfo)
		if type(pageInfo) == "string" then
			pageInfo = { Name = pageInfo }
		end
		local page = CreatePage(self, pageInfo)
		if not self.ActivePage then
			self:ShowPage(page)
		end
		return page
	end

	function windowObject:ShowPage(page)
		if self.ActivePage == page then
			return
		end
		if self.ActivePage then
			self.ActivePage:Deactivate()
			SearchEngine.Reset(self.ActivePage)
		end
		self.ActivePage = page
		page:Activate()
		if statusLabel then
			statusLabel.Text = page.Name
		end
	end

	function windowObject:SetTitle(title)
		titleText.Text = title
	end

	function windowObject:SetFooter(text)
		versionLabel.Text = text
	end

	function windowObject:SetStatus(text)
		statusLabel.Text = text
	end

	function windowObject:Toggle()
		self.Toggled = not self.Toggled
		window.Visible = self.Toggled

		if self.Toggled and not IsMobile then
			if info.ShowCustomCursor then
				CustomCursor.Start(true)
			end
			if info.WatermarkEnabled then
				WatermarkSystem.SetVisible(true)
			end
			if keybindFrame and #(Registry.KeybindToggles or {}) > 0 then
				keybindFrame.Visible = true
				Registry.UpdateKeybindFrame()
			end
		elseif not self.Toggled then
			CustomCursor.Stop()
			if keybindFrame then
				keybindFrame.Visible = false
			end
		end
	end

	function windowObject:Destroy()
		for _, page in pairs(self.Pages) do
			page:Destroy()
		end
		screenGui:Destroy()
		modalGui:Destroy()
		Registry.Windows[windowObject] = nil
	end

	function windowObject:SetTheme(themeName)
		CurrentScheme = Schemes[themeName] or Schemes.Dark
		Palette = CurrentScheme
		ApplyTheme()

		window.BackgroundColor3 = Palette.Background
		header.BackgroundColor3 = Palette.Sidebar
		sidebar.BackgroundColor3 = Palette.Sidebar
		mainArea.BackgroundColor3 = Palette.Content
		footer.BackgroundColor3 = Palette.Sidebar

		for _, page in pairs(self.Pages) do
			if page.Active then
				page:Activate()
			else
				page:Deactivate()
			end
		end
	end

	function windowObject:Notify(info)
		return NotificationSystem.Notify(info)
	end

	function windowObject:Dialog(info)
		return DialogSystem.Dialog(info)
	end

	function windowObject:Confirm(info)
		if type(info) == "string" then
			info = { Title = "Confirm", Text = info }
		elseif type(info) ~= "table" then
			info = {}
		end
		info.Type = "confirm"
		return DialogSystem.Dialog(info)
	end

	function windowObject:InfoPopup(info)
		if type(info) == "string" then
			info = { Title = "Info", Text = info }
		elseif type(info) ~= "table" then
			info = {}
		end
		info.Type = "info"
		return DialogSystem.Dialog(info)
	end

	function windowObject:ResizeAll()
		for _, page in pairs(self.Pages) do
			if page.List then
				page.Scroll.CanvasSize = UDim2.fromOffset(0, page.List.AbsoluteContentSize.Y or 0)
			end
			for _, card in pairs(page.Cards) do
				card:Resize()
			end
		end
	end

	function windowObject:SetWatermark(text)
		WatermarkSystem.SetText(text)
	end

	function windowObject:SetWatermarkVisibility(visible)
		WatermarkSystem.SetVisible(visible)
	end

	function windowObject:ShowKeybindFrame()
		if keybindFrame then
			keybindFrame.Visible = true
			Registry.UpdateKeybindFrame()
		end
	end

	function windowObject:HideKeybindFrame()
		if keybindFrame then
			keybindFrame.Visible = false
		end
	end

	if info.Resizable then
		local resizeHandle = F.Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -12, 1, -12),
			Size = UDim2.fromOffset(12, 12),
			Parent = window,
		})
		MakeResizable(window, resizeHandle, function()
			windowObject:ResizeAll()
		end)
	end

	-- Search connection
	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if windowObject.ActivePage then
				SearchEngine.Search(searchBox.Text, windowObject.ActivePage)
			end
		end)
	end

	-- Toggle keybind
	Connect(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == info.ToggleKey then
			windowObject:Toggle()
		end
	end))

	-- Show keybind frame on K key (or any key you want)
	local showKeybindKey = Enum.KeyCode.K
	Connect(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == showKeybindKey then
			windowObject:ShowKeybindFrame()
		end
	end))

	-- Initial layout
	windowObject:ResizeAll()

	-- Auto show
	if info.AutoShow then
		task.defer(function()
			windowObject:Toggle()
		end)
	end

	-- Set watermark if enabled
	if info.WatermarkEnabled and info.WatermarkText and info.WatermarkText ~= "" then
		WatermarkSystem.SetText(info.WatermarkText)
	end

	return windowObject
end

local LRXUI = {
	Version = "1.0.0",
	Design = Design,
	Schemes = Schemes,
	CurrentScheme = CurrentScheme,
	Palette = Palette,
	Registry = Registry,

	CreateWindow = CreateWindow,
	Notify = NotificationSystem.Notify,
	Dialog = DialogSystem.Dialog,
	SetScale = SetDPIScale,
	SetNotifySide = NotificationSystem.SetSide,
	GetScale = function()
		return DPIScale
	end,
	GetTheme = function()
		return CurrentScheme
	end,
	SetTheme = function(name)
		CurrentScheme = Schemes[name] or Schemes.Dark
		Palette = CurrentScheme
		LRXUI.Palette = Palette
		LRXUI.CurrentScheme = CurrentScheme
		ApplyTheme()
	end,
	OnUnload = function(callback)
		table.insert(Registry.OnUnload, callback)
	end,
	Unload = function()
		DisconnectAll()
		for _, win in pairs(Registry.Windows) do
			win:Destroy()
		end
		for _, notif in pairs(Registry.Notifications) do
			if notif.Holder then
				notif.Holder:Destroy()
			end
		end
		Animation.CancelAll()
		CustomCursor.Stop()
		table.clear(Registry)
	end,
	ApplyTheme = ApplyTheme,
	GetIcon = GetIcon,
}

return LRXUI
