--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                         LRXUI  v1.0                                         ║
║              Professional Single-File Roblox UI Framework                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

local LRXUI = {}

-- ═══════════════════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════════════════

local cloneref = (cloneref or clonereference or function(svc)
	return svc
end)

local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local SoundService = cloneref(game:GetService("SoundService"))
local InputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local TeamService = cloneref(game:GetService("Teams"))
local TweenService = cloneref(game:GetService("TweenService"))

-- ═══════════════════════════════════════════════════════════════════════════
--  PLATFORM DETECTION
-- ═══════════════════════════════════════════════════════════════════════════

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

local Platform = {
	IsMobile = false,
	IsStudio = RunService:IsStudio(),
	MinSize = Vector2.new(480, 360),
}

do
	if Platform.IsStudio then
		Platform.IsMobile = InputService.TouchEnabled and not InputService.MouseEnabled
	else
		local ok, plat = pcall(function()
			return InputService:GetPlatform()
		end)
		if ok then
			Platform.IsMobile = (plat == Enum.Platform.Android or plat == Enum.Platform.IOS)
		end
	end

	if Platform.IsMobile then
		Platform.MinSize = Vector2.new(480, 240)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════════

local DEFAULT_FAST_TWEEN = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEFAULT_NOTIF_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEFAULT_OPEN_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- ═══════════════════════════════════════════════════════════════════════════
--  THEME ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local Theme = {
	--// Core palette
	Background = Color3.fromRGB(15, 15, 15),
	Surface = Color3.fromRGB(25, 25, 25),
	Accent = Color3.fromRGB(125, 85, 255),
	Border = Color3.fromRGB(40, 40, 40),
	Text = Color3.new(1, 1, 1),
	Danger = Color3.fromRGB(255, 50, 50),
	Black = Color3.new(0, 0, 0),
	White = Color3.new(1, 1, 1),

	--// Typography
	Font = Font.fromEnum(Enum.Font.Code),

	--// Shape
	Radius = 4,

	--// Transparency presets (0 = opaque, 1 = fully transparent)
	DimText = 0.4,
	DimBorder = 0.25,
	DisabledBg = 0.80,
	DisabledText = 0.8,

	--// Internal name table for registry lookups
	_names = {
		Background = "Background",
		Surface = "Surface",
		Accent = "Accent",
		Border = "Border",
		Text = "Text",
		Danger = "Danger",
		Black = "Black",
		White = "White",
	},
}

function Theme:Get(name)
	return self[name]
end

function Theme:Shade(color, add)
	-- Lighten or darken a Color3 by an absolute amount (positive = lighter)
	add = add or 0
	return Color3.fromRGB(
		math.clamp(color.R * 255 + add, 0, 255),
		math.clamp(color.G * 255 + add, 0, 255),
		math.clamp(color.B * 255 + add, 0, 255)
	)
end

function Theme:Darken(color)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, v / 2)
end

function Theme:PlaceholderColor()
	local h, s, v = self.Text:ToHSV()
	return Color3.fromHSV(h, s, v / 2)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  MATH UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════

local Mth = {}

function Mth.Round(value, decimals)
	if decimals == 0 then
		return math.floor(value + 0.5)
	end
	local factor = 10 ^ decimals
	return math.floor(value * factor + 0.5) / factor
end

function Mth.Clamp(v, min, max)
	return math.max(min, math.min(max, v))
end

function Mth.DPIApply(dim, scale, extraOffset)
	if typeof(dim) == "UDim" then
		return UDim.new(dim.Scale, dim.Offset * scale)
	end
	if extraOffset then
		return UDim2.new(
			dim.X.Scale,
			(dim.X.Offset * scale) + (extraOffset[1] * scale),
			dim.Y.Scale,
			(dim.Y.Offset * scale) + (extraOffset[2] * scale)
		)
	end
	return UDim2.new(dim.X.Scale, dim.X.Offset * scale, dim.Y.Scale, dim.Y.Offset * scale)
end

function Mth.DPIText(size, scale)
	return size * scale
end

-- ═══════════════════════════════════════════════════════════════════════════
--  STRING UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════

local Str = {}

function Str.Trim(s)
	return s:match("^%s*(.-)%s*$")
end

function Str.StartsWith(s, prefix)
	return s:sub(1, #prefix) == prefix
end

-- ═══════════════════════════════════════════════════════════════════════════
--  TABLE UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════

local Tbl = {}

function Tbl.Count(t)
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

function Tbl.ShallowCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

function Tbl.Contains(t, value)
	for _, v in ipairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

function Tbl.Merge(base, override)
	for k, v in pairs(override) do
		if base[k] == nil then
			base[k] = v
		end
	end
	return base
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SIGNAL SYSTEM (lightweight BindableEvent-free signals)
-- ═══════════════════════════════════════════════════════════════════════════

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local id = {}
	self._handlers[id] = fn
	return {
		Disconnect = function()
			self._handlers[id] = nil
		end,
		Connected = true,
	}
end

function Signal:Fire(...)
	for _, fn in pairs(self._handlers) do
		task.spawn(fn, ...)
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end

-- ═══════════════════════════════════════════════════════════════════════════
--  CONNECTION MANAGER
-- ═══════════════════════════════════════════════════════════════════════════

local Connections = {}
Connections.__index = Connections

function Connections.new()
	return setmetatable({ _list = {} }, Connections)
end

function Connections:Add(conn)
	self._list[#self._list + 1] = conn
	return conn
end

function Connections:DisconnectAll()
	for i = #self._list, 1, -1 do
		local c = table.remove(self._list, i)
		if c and c.Connected then
			c:Disconnect()
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  TWEEN ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local Tweener = {}
Tweener.__index = Tweener

function Tweener.new()
	return setmetatable({ _active = {} }, Tweener)
end

function Tweener:Play(instance, info, goals)
	if not instance or not instance.Parent then
		return
	end

	local existing = self._active[instance]
	if existing and existing.PlaybackState == Enum.PlaybackState.Playing then
		existing:Cancel()
	end

	local t = TweenService:Create(instance, info, goals)
	self._active[instance] = t
	t:Play()
	t.Completed:Connect(function()
		if self._active[instance] == t then
			self._active[instance] = nil
		end
	end)
	return t
end

function Tweener:Cancel(instance)
	local t = self._active[instance]
	if t and t.PlaybackState == Enum.PlaybackState.Playing then
		t:Cancel()
		self._active[instance] = nil
	end
end

local Anim = Tweener.new()

-- ═══════════════════════════════════════════════════════════════════════════
--  REGISTRY SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local Registry = {}

-- Maps GuiObject → { PropertyName = ThemeKey (string) or Resolver (function) }
local _colorRegistry = {}
-- Maps GuiObject → { PropertyName = (value for DPI rescaling) }
local _dpiRegistry = {}

function Registry.BindColor(obj, prop, themeKey)
	if not _colorRegistry[obj] then
		_colorRegistry[obj] = {}
	end
	_colorRegistry[obj][prop] = themeKey
end

function Registry.UnbindColor(obj, prop)
	if _colorRegistry[obj] then
		_colorRegistry[obj][prop] = nil
	end
end

function Registry.Remove(obj)
	_colorRegistry[obj] = nil
	_dpiRegistry[obj] = nil
end

function Registry.BindDPI(obj, prop, value, exclude, extraOffset)
	if not _dpiRegistry[obj] then
		_dpiRegistry[obj] = { _exclude = {}, _offsets = {} }
	end
	if exclude then
		_dpiRegistry[obj]._exclude[prop] = true
	else
		_dpiRegistry[obj][prop] = value
		if extraOffset then
			_dpiRegistry[obj]._offsets[prop] = extraOffset
		end
	end
end

function Registry.ApplyColors(scale)
	-- 'scale' is unused here; it's used in ApplyDPI. Colors don't scale.
	for obj, props in pairs(_colorRegistry) do
		if obj and obj.Parent then
			for prop, key in pairs(props) do
				if typeof(key) == "function" then
					local ok, result = pcall(key)
					if ok then
						obj[prop] = result
					end
				elseif typeof(key) == "string" then
					local color = Theme[key]
					if color then
						pcall(function()
							obj[prop] = color
						end)
					end
				end
			end
		end
	end
end

function Registry.ApplyDPI(scale)
	for obj, props in pairs(_dpiRegistry) do
		if obj and obj.Parent then
			for prop, value in pairs(props) do
				if prop == "_exclude" or prop == "_offsets" then
					continue
				end
				if props._exclude and props._exclude[prop] then
					continue
				end

				local offset = props._offsets and props._offsets[prop]
				if prop == "TextSize" then
					pcall(function()
						obj[prop] = Mth.DPIText(value, scale)
					end)
				else
					pcall(function()
						obj[prop] = Mth.DPIApply(value, scale, offset)
					end)
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  INSTANCE BUILDER
-- ═══════════════════════════════════════════════════════════════════════════

-- Global DPI scale (updated by Window)
local _dpiScale = 1.0

-- Resolve a property value against Theme or leave as-is
local function resolveValue(key, value)
	-- Color keys (string that matches a Theme entry)
	if
		typeof(value) == "string"
		and key ~= "Text"
		and key ~= "PlaceholderText"
		and key ~= "Name"
		and Theme[value] ~= nil
	then
		return Theme[value], value -- returns (resolved, themeKey)
	end
	if typeof(value) == "function" then
		local ok, result = pcall(value)
		return ok and result or nil, value
	end
	return value, nil
end

-- Builds an instance, auto-registers colors and DPI properties
local function Build(className, props)
	local obj = Instance.new(className)

	local dpiExclude = props.DPIExclude or {}
	local dpiOffsets = props.DPIOffset or {}

	for prop, rawValue in pairs(props) do
		if prop == "DPIExclude" or prop == "DPIOffset" or prop == "Parent" then
			continue
		end

		local value, themeKey = resolveValue(prop, rawValue)
		if value == nil then
			continue
		end

		-- Register for color updates
		if themeKey then
			Registry.BindColor(obj, prop, themeKey)
		end

		-- Register for DPI updates
		if not dpiExclude[prop] then
			if prop == "Position" or prop == "Size" or prop:match("Padding") then
				Registry.BindDPI(obj, prop, rawValue, false, dpiOffsets[prop])
				value = Mth.DPIApply(rawValue, _dpiScale, dpiOffsets[prop])
			elseif prop == "TextSize" then
				Registry.BindDPI(obj, prop, rawValue, false, nil)
				value = Mth.DPIText(rawValue, _dpiScale)
			end
		end

		-- Apply font from theme
		if prop == "FontFace" and value == "Font" then
			value = Theme.Font
			Registry.BindColor(obj, "FontFace", "Font")
		end

		pcall(function()
			obj[prop] = value
		end)
	end

	-- Inherit ZIndex from parent
	if props.Parent and not props.ZIndex then
		pcall(function()
			obj.ZIndex = props.Parent.ZIndex
		end)
	end

	if props.Parent then
		obj.Parent = props.Parent
	end

	return obj
end

-- ═══════════════════════════════════════════════════════════════════════════
--  INPUT UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════

local Input = {}

function Input.IsClick(inp, allowRight)
	return (
		inp.UserInputType == Enum.UserInputType.MouseButton1
		or (allowRight and inp.UserInputType == Enum.UserInputType.MouseButton2)
		or inp.UserInputType == Enum.UserInputType.Touch
	) and inp.UserInputState == Enum.UserInputState.Begin
end

function Input.IsRelease(inp)
	return (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch)
		and inp.UserInputState == Enum.UserInputState.End
end

function Input.IsMove(inp)
	return inp.UserInputType == Enum.UserInputType.MouseMovement
		or (inp.UserInputType == Enum.UserInputType.Touch and inp.UserInputState == Enum.UserInputState.Change)
end

function Input.IsDrag(inp, allowRight)
	return (
		inp.UserInputType == Enum.UserInputType.MouseButton1
		or (allowRight and inp.UserInputType == Enum.UserInputType.MouseButton2)
		or inp.UserInputType == Enum.UserInputType.Touch
	) and (inp.UserInputState == Enum.UserInputState.Begin or inp.UserInputState == Enum.UserInputState.Change)
end

function Input.KeyString(keyCode)
	if keyCode.EnumType == Enum.KeyCode and keyCode.Value > 33 and keyCode.Value < 127 then
		return string.char(keyCode.Value)
	end
	return keyCode.Name
end

-- ═══════════════════════════════════════════════════════════════════════════
--  TEXT MEASUREMENT
-- ═══════════════════════════════════════════════════════════════════════════

local TextMeasure = {}

function TextMeasure.Bounds(text, fontObj, size, maxWidth)
	text = tostring(text or "")
	size = tonumber(size) or 16
	maxWidth = maxWidth or (workspace.CurrentCamera.ViewportSize.X - 32)

	local ok, bounds = pcall(function()
		local p = Instance.new("GetTextBoundsParams")
		p.Text = text
		p.RichText = true
		p.Size = size
		p.Width = maxWidth
		p.Font = fontObj or Font.fromEnum(Enum.Font.Gotham)
		return TextService:GetTextBoundsAsync(p)
	end)

	if ok and bounds then
		return bounds.X, bounds.Y
	end

	-- Fallback
	local ok2, sz = pcall(function()
		return TextService:GetTextSize(text, size, Enum.Font.Gotham, Vector2.new(maxWidth, math.huge))
	end)
	if ok2 and sz then
		return sz.X, sz.Y
	end

	return #text * size * 0.55, size
end

-- ═══════════════════════════════════════════════════════════════════════════
--  CALLBACK RUNNER (safe, deferred errors)
-- ═══════════════════════════════════════════════════════════════════════════

local function Run(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local results = table.pack(xpcall(fn, function(err)
		task.defer(error, debug.traceback(err, 2))
		return err
	end, ...))
	if results[1] then
		return table.unpack(results, 2, results.n)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SCREEN UI SETUP
-- ═══════════════════════════════════════════════════════════════════════════

local getgenv = getgenv or function()
	return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
	return CoreGui
end

local function SafeParent(gui)
	local ok, err = pcall(function()
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui", math.huge)
	end)
	if not ok then
		warn("[LRXUI] Could not parent to PlayerGui:", err)
		pcall(function()
			gui.Parent = CoreGui
		end)
	end
end

local RootGui = Build("ScreenGui", {
	Name = "LRXUI",
	DisplayOrder = 2147483647,
	ResetOnSpawn = false,
})
SafeParent(RootGui)
pcall(protectgui, RootGui)

-- Clean up registry when instances are removed
RootGui.DescendantRemoving:Connect(function(inst)
	Registry.Remove(inst)
end)

-- Modal layer (captures clicks when dropdowns/dialogs open)
local ModalGui = Build("ScreenGui", {
	Name = "LRXUIModal",
	DisplayOrder = 2147483647,
	ResetOnSpawn = false,
})
SafeParent(ModalGui)

local ModalCapture = Build("TextButton", {
	BackgroundTransparency = 1,
	Modal = false,
	Size = UDim2.fromScale(0, 0),
	Text = "",
	ZIndex = -999,
	Parent = ModalGui,
})

-- ═══════════════════════════════════════════════════════════════════════════
--  CUSTOM CURSOR
-- ═══════════════════════════════════════════════════════════════════════════

local Cursor
do
	Cursor = Build("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		Size = UDim2.fromOffset(9, 1),
		Visible = false,
		ZIndex = 999,
		Parent = RootGui,
	})
	Build("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Black",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 2, 1, 2),
		ZIndex = 998,
		Parent = Cursor,
	})
	local vBar = Build("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1, 9),
		Parent = Cursor,
	})
	Build("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Black",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 2, 1, 2),
		ZIndex = 998,
		Parent = vBar,
	})
end

-- ═══════════════════════════════════════════════════════════════════════════
--  NOTIFICATION AREA
-- ═══════════════════════════════════════════════════════════════════════════

local NotifArea = Build("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -6, 0, 6),
	Size = UDim2.new(0, 300, 1, -6),
	Parent = RootGui,
	DPIExclude = { Position = true, Size = true },
})
local NotifLayout = Build("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 6),
	Parent = NotifArea,
})

-- ═══════════════════════════════════════════════════════════════════════════
--  TOOLTIP LAYER
-- ═══════════════════════════════════════════════════════════════════════════

local TooltipLabel = Build("TextLabel", {
	BackgroundColor3 = "Background",
	BorderColor3 = "Border",
	BorderSizePixel = 1,
	TextSize = 13,
	TextWrapped = true,
	Visible = false,
	ZIndex = 25,
	Parent = RootGui,
})

local _hoveredInstance = nil

TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
	local x, y = TextMeasure.Bounds(
		TooltipLabel.Text,
		TooltipLabel.FontFace,
		TooltipLabel.TextSize,
		workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 4
	)
	TooltipLabel.Size = UDim2.fromOffset(x + 8, y + 4)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  DRAGGING SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local _isVisible = false -- Framework visibility state
local _cantDrag = false -- Forced drag-lock (used during resize)

local _globalConns = Connections.new()

local function AttachDraggable(target, handle, ignoreVisible, isMainWindow)
	local startPos, framePos, dragging, releaseConn

	handle.InputBegan:Connect(function(inp)
		if not Input.IsClick(inp) then
			return
		end
		if isMainWindow and _cantDrag then
			return
		end

		startPos = inp.Position
		framePos = target.Position
		dragging = true

		releaseConn = inp.Changed:Connect(function()
			if inp.UserInputState ~= Enum.UserInputState.End then
				return
			end
			dragging = false
			if releaseConn and releaseConn.Connected then
				releaseConn:Disconnect()
				releaseConn = nil
			end
		end)
	end)

	_globalConns:Add(InputService.InputChanged:Connect(function(inp)
		if not Input.IsMove(inp) then
			return
		end
		if not dragging then
			return
		end
		if isMainWindow and _cantDrag then
			dragging = false
			return
		end
		if not (ignoreVisible or _isVisible) then
			dragging = false
			return
		end
		if not (RootGui and RootGui.Parent) then
			dragging = false
			return
		end

		local delta = inp.Position - startPos
		target.Position =
			UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
	end))
end

local function AttachResizable(target, handle, callback)
	local startPos, startSize, dragging, releaseConn

	handle.InputBegan:Connect(function(inp)
		if not Input.IsClick(inp) then
			return
		end
		startPos = inp.Position
		startSize = target.Size
		dragging = true

		releaseConn = inp.Changed:Connect(function()
			if inp.UserInputState ~= Enum.UserInputState.End then
				return
			end
			dragging = false
			if releaseConn and releaseConn.Connected then
				releaseConn:Disconnect()
				releaseConn = nil
			end
		end)
	end)

	_globalConns:Add(InputService.InputChanged:Connect(function(inp)
		if not Input.IsMove(inp) then
			return
		end
		if not dragging then
			return
		end
		if not target.Visible or not (RootGui and RootGui.Parent) then
			dragging = false
			return
		end

		local delta = inp.Position - startPos
		target.Size = UDim2.new(
			startSize.X.Scale,
			math.max(startSize.X.Offset + delta.X, Platform.MinSize.X),
			startSize.Y.Scale,
			math.max(startSize.Y.Offset + delta.Y, Platform.MinSize.Y)
		)
		if callback then
			Run(callback)
		end
	end))
end

-- ═══════════════════════════════════════════════════════════════════════════
--  LAYOUT HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function MakeOutlineFrame(parent, radius, zIndex)
	local outer = Build("Frame", {
		BackgroundColor3 = "Black",
		Position = UDim2.fromOffset(-2, -2),
		Size = UDim2.new(1, 4, 1, 4),
		ZIndex = zIndex or 0,
		Parent = parent,
		DPIExclude = { Position = true, Size = true },
	})
	local inner = Build("Frame", {
		BackgroundColor3 = "Border",
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = zIndex or 0,
		Parent = outer,
		DPIExclude = { Position = true, Size = true },
	})
	if radius and radius > 0 then
		Build("UICorner", { CornerRadius = UDim.new(0, radius + 1), Parent = outer })
		Build("UICorner", { CornerRadius = UDim.new(0, radius), Parent = inner })
	end
	return outer, inner
end

local function MakeDividerLine(parent, pos, sz)
	return Build("Frame", {
		BackgroundColor3 = "Border",
		BorderSizePixel = 0,
		Position = pos,
		Size = sz,
		Parent = parent,
		DPIExclude = { Position = true, Size = true },
	})
end

-- ═══════════════════════════════════════════════════════════════════════════
--  CONTEXT MENU SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local _activeMenu = nil

local function CreateContextMenu(anchor, size, offset, scrollable, onToggle)
	local menuFrame
	if scrollable == 2 then
		menuFrame = Build("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = "Background",
			BorderColor3 = "Border",
			BorderSizePixel = 1,
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarImageColor3 = "Border",
			ScrollBarThickness = 2,
			Size = typeof(size) == "function" and size() or size,
			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			Visible = false,
			ZIndex = 12,
			Parent = RootGui,
			DPIExclude = { Position = true },
		})
	elseif scrollable == 1 then
		menuFrame = Build("ScrollingFrame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = "Background",
			BorderColor3 = "Border",
			BorderSizePixel = 1,
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarImageColor3 = "Border",
			ScrollBarThickness = 0,
			Size = typeof(size) == "function" and size() or size,
			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			Visible = false,
			ZIndex = 12,
			Parent = RootGui,
			DPIExclude = { Position = true },
		})
	else
		menuFrame = Build("Frame", {
			BackgroundColor3 = "Background",
			BorderColor3 = "Border",
			BorderSizePixel = 1,
			Size = typeof(size) == "function" and size() or size,
			Visible = false,
			ZIndex = 12,
			Parent = RootGui,
			DPIExclude = { Position = true },
		})
	end

	local menuTable = { Menu = menuFrame, Active = false }

	local function reposition()
		local abs = anchor.AbsolutePosition
		local absSize = anchor.AbsoluteSize
		local off = typeof(offset) == "function" and offset() or (offset or { 0, 0 })
		local menuSize = typeof(size) == "function" and size() or size

		local x = abs.X + absSize.X * (1 - off[1]) + off[2]
		local y = abs.Y + absSize.Y * 0.5

		local vpSize = workspace.CurrentCamera.ViewportSize
		if x + menuSize.X.Offset > vpSize.X then
			x = abs.X - menuSize.X.Offset - off[2]
		end
		if y + menuSize.Y.Offset > vpSize.Y then
			y = vpSize.Y - menuSize.Y.Offset - 4
		end

		menuFrame.Position = UDim2.fromOffset(x, y)
	end

	function menuTable:Open()
		if _activeMenu and _activeMenu ~= menuTable then
			_activeMenu:Close()
		end
		_activeMenu = menuTable
		menuTable.Active = true

		reposition()
		menuFrame.Visible = true
		if onToggle then
			Run(onToggle, true)
		end
	end

	function menuTable:Close()
		if not menuTable.Active then
			return
		end
		menuTable.Active = false
		menuFrame.Visible = false
		if _activeMenu == menuTable then
			_activeMenu = nil
		end
		if onToggle then
			Run(onToggle, false)
		end
	end

	function menuTable:Toggle()
		if menuTable.Active then
			menuTable:Close()
		else
			menuTable:Open()
		end
	end

	return menuTable
end

-- Close active menu on outside click
_globalConns:Add(InputService.InputBegan:Connect(function(inp)
	if not Input.IsClick(inp) then
		return
	end
	if _activeMenu then
		local menu = _activeMenu.Menu
		if menu and menu.Visible then
			local abs = menu.AbsolutePosition
			local sz = menu.AbsoluteSize
			local mx, my = Mouse.X, Mouse.Y
			if mx < abs.X or mx > abs.X + sz.X or my < abs.Y or my > abs.Y + sz.Y then
				_activeMenu:Close()
			end
		end
	end
end))

-- ═══════════════════════════════════════════════════════════════════════════
--  TOOLTIP SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local function AttachTooltip(hoverObj, infoStr, disabledStr)
	local state = { disabled = false, active = false, conns = {} }

	local function showTooltip()
		if _hoveredInstance == hoverObj then
			return
		end
		if _activeMenu and _activeMenu.Menu and _activeMenu.Menu.Visible then
			return
		end
		local text = state.disabled and disabledStr or infoStr
		if not text then
			return
		end

		_hoveredInstance = hoverObj
		TooltipLabel.Text = text
		TooltipLabel.Visible = true

		while
			_isVisible
			and hoverObj
			and hoverObj.Parent
			and Mouse.X >= hoverObj.AbsolutePosition.X
			and Mouse.X <= hoverObj.AbsolutePosition.X + hoverObj.AbsoluteSize.X
			and Mouse.Y >= hoverObj.AbsolutePosition.Y
			and Mouse.Y <= hoverObj.AbsolutePosition.Y + hoverObj.AbsoluteSize.Y
			and not (_activeMenu and _activeMenu.Menu and _activeMenu.Menu.Visible)
		do
			TooltipLabel.Position = UDim2.fromOffset(Mouse.X + 14, Mouse.Y + 12)
			RunService.RenderStepped:Wait()
		end

		TooltipLabel.Visible = false
		_hoveredInstance = nil
	end

	state.conns[#state.conns + 1] = hoverObj.MouseEnter:Connect(showTooltip)
	state.conns[#state.conns + 1] = hoverObj.MouseMoved:Connect(showTooltip)
	state.conns[#state.conns + 1] = hoverObj.MouseLeave:Connect(function()
		if _hoveredInstance == hoverObj then
			TooltipLabel.Visible = false
			_hoveredInstance = nil
		end
	end)

	function state:Destroy()
		for i = #self.conns, 1, -1 do
			local c = table.remove(self.conns, i)
			if c and c.Connected then
				c:Disconnect()
			end
		end
		if _hoveredInstance == hoverObj then
			TooltipLabel.Visible = false
			_hoveredInstance = nil
		end
	end

	return state
end

-- ═══════════════════════════════════════════════════════════════════════════
--  DRAGGABLE PANEL (used for watermark and keybind panel)
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateDraggablePanel(title)
	local outerFrame, _ = MakeOutlineFrame(RootGui, Theme.Radius, 10)
	outerFrame.AutomaticSize = Enum.AutomaticSize.Y
	outerFrame.Position = UDim2.fromOffset(6, 6)
	outerFrame.Size = UDim2.fromOffset(0, 0)
	Registry.BindDPI(outerFrame, "Position", nil, true)
	Registry.BindDPI(outerFrame, "Size", nil, true)

	local body = Build("Frame", {
		BackgroundColor3 = "Surface",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = outerFrame,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", {
		CornerRadius = UDim.new(0, Theme.Radius - 1),
		Parent = body,
	})

	MakeDividerLine(body, UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 1))

	local titleLabel = Build("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Text = title,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = body,
	})
	Build("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = titleLabel,
	})

	local contentArea = Build("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 35),
		Size = UDim2.new(1, 0, 1, -35),
		Parent = body,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UIListLayout", { Padding = UDim.new(0, 7), Parent = contentArea })
	Build("UIPadding", {
		PaddingBottom = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7),
		PaddingTop = UDim.new(0, 7),
		Parent = contentArea,
	})

	AttachDraggable(outerFrame, titleLabel, true)

	return outerFrame, contentArea
end

-- ═══════════════════════════════════════════════════════════════════════════
--  WATERMARK SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local _watermarkOuter, _watermarkLabel
do
	_watermarkOuter = Build("Frame", { -- lightweight standalone container
		AnchorPoint = Vector2.new(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -6, 0, -100),
		Size = UDim2.fromOffset(0, 0),
		Visible = false,
		ZIndex = 10,
		Parent = RootGui,
		DPIExclude = { Position = true, Size = true },
	})

	local outerDecor, _ = MakeOutlineFrame(_watermarkOuter, Theme.Radius, 10)
	outerDecor.AutomaticSize = Enum.AutomaticSize.Y
	outerDecor.Position = UDim2.fromOffset(0, 0)
	outerDecor.Size = UDim2.fromScale(1, 0)
	Registry.BindDPI(outerDecor, "Position", nil, true)
	Registry.BindDPI(outerDecor, "Size", nil, true)

	local wBody = Build("Frame", {
		BackgroundColor3 = "Surface",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = outerDecor,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius - 1), Parent = wBody })

	_watermarkLabel = Build("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = wBody,
		DPIExclude = { Size = true },
	})
	Build("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = _watermarkLabel,
	})

	AttachDraggable(_watermarkOuter, _watermarkLabel, true)
end

local function _resizeWatermark()
	local x, y = TextMeasure.Bounds(_watermarkLabel.Text, _watermarkLabel.FontFace, _watermarkLabel.TextSize)
	_watermarkOuter.Size = UDim2.fromOffset((12 + x + 12 + 4) * _dpiScale, y * _dpiScale * 2 + 4)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local _notifSide = "Right"
local _liveNotifs = {}

local function _createNotification(data)
	local fakeHolder = Build("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		Visible = false,
		Parent = NotifArea,
		DPIExclude = { Size = true },
	})

	local outerDecor, _ = MakeOutlineFrame(fakeHolder, Theme.Radius, 5)
	outerDecor.AutomaticSize = Enum.AutomaticSize.Y
	outerDecor.Position = _notifSide:lower() == "left" and UDim2.new(-1, -6, 0, -2) or UDim2.new(1, 6, 0, -2)
	outerDecor.Size = UDim2.fromScale(1, 0)
	Registry.BindDPI(outerDecor, "Position", nil, true)
	Registry.BindDPI(outerDecor, "Size", nil, true)

	local notifBody = Build("Frame", {
		BackgroundColor3 = "Surface",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = outerDecor,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius - 1), Parent = notifBody })
	Build("UIListLayout", { Padding = UDim.new(0, 4), Parent = notifBody })
	Build("UIPadding", {
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		Parent = notifBody,
	})

	local titleLabel, descLabel
	local titleW, descW = 0, 0

	if data.Title then
		titleLabel = Build("TextLabel", {
			BackgroundTransparency = 1,
			Text = tostring(data.Title),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = notifBody,
			DPIExclude = { Size = true },
		})
	end
	if data.Description then
		descLabel = Build("TextLabel", {
			BackgroundTransparency = 1,
			Text = tostring(data.Description),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = notifBody,
			DPIExclude = { Size = true },
		})
	end

	local timerHolder = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 7),
		Visible = (data.Persist ~= true and typeof(data.Time) ~= "Instance") or typeof(data.Steps) == "number",
		Parent = notifBody,
		DPIExclude = { Size = true },
	})
	local timerBar = Build("Frame", {
		BackgroundColor3 = "Background",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(0, 3),
		Size = UDim2.new(1, 0, 0, 2),
		Parent = timerHolder,
		DPIExclude = { Position = true, Size = true },
	})
	local timerFill = Build("Frame", {
		BackgroundColor3 = "Accent",
		Size = UDim2.fromScale(1, 1),
		Parent = timerBar,
		DPIExclude = { Size = true },
	})

	if typeof(data.Time) == "Instance" then
		timerFill.Size = UDim2.fromScale(0, 1)
	end

	if data.SoundId then
		local sid = data.SoundId
		if typeof(sid) == "number" then
			sid = ("rbxassetid://%d"):format(sid)
		end
		Build("Sound", {
			SoundId = sid,
			Volume = 3,
			PlayOnRemove = true,
			Parent = SoundService,
		}):Destroy()
	end

	local notif = { _destroyed = false }

	local function measure()
		local maxW = NotifArea.AbsoluteSize.X - (24 * _dpiScale)
		if titleLabel then
			local tx, ty = TextMeasure.Bounds(titleLabel.Text, titleLabel.FontFace, titleLabel.TextSize, maxW)
			titleLabel.Size = UDim2.fromOffset(math.ceil(tx), ty)
			titleW = tx
		end
		if descLabel then
			local dx, dy = TextMeasure.Bounds(descLabel.Text, descLabel.FontFace, descLabel.TextSize, maxW)
			descLabel.Size = UDim2.fromOffset(math.ceil(dx), dy)
			descW = dx
		end
		fakeHolder.Size = UDim2.fromOffset(math.max(titleW, descW) + (24 * _dpiScale), 0)
	end

	function notif:Resize()
		measure()
	end

	function notif:ChangeTitle(newText)
		data.Title = tostring(newText)
		if titleLabel then
			titleLabel.Text = data.Title
			measure()
		end
	end

	function notif:ChangeDescription(newText)
		data.Description = tostring(newText)
		if descLabel then
			descLabel.Text = data.Description
			measure()
		end
	end

	function notif:ChangeStep(step)
		if timerFill and data.Steps then
			local s = math.clamp(step or 0, 0, data.Steps)
			timerFill.Size = UDim2.fromScale(s / data.Steps, 1)
		end
	end

	function notif:Destroy()
		notif._destroyed = true
		Anim:Play(outerDecor, DEFAULT_NOTIF_TWEEN, {
			Position = _notifSide:lower() == "left" and UDim2.new(-1, -6, 0, -2) or UDim2.new(1, 6, 0, -2),
		})
		task.delay(DEFAULT_NOTIF_TWEEN.Time, function()
			_liveNotifs[fakeHolder] = nil
			pcall(function()
				fakeHolder:Destroy()
			end)
		end)
	end

	measure()
	_liveNotifs[fakeHolder] = notif

	fakeHolder.Visible = true
	Anim:Play(outerDecor, DEFAULT_NOTIF_TWEEN, { Position = UDim2.fromOffset(-2, -2) })

	task.delay(DEFAULT_NOTIF_TWEEN.Time, function()
		if notif._destroyed then
			return
		end
		if data.Persist then
			return
		end

		if typeof(data.Time) == "Instance" then
			repeat
				task.wait()
			until notif._destroyed
		else
			Anim:Play(
				timerFill,
				TweenInfo.new(data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
				{ Size = UDim2.fromScale(0, 1) }
			)
			task.wait(data.Time)
		end

		if not notif._destroyed then
			notif:Destroy()
		end
	end)

	return notif
end

-- ═══════════════════════════════════════════════════════════════════════════
--  DIALOG SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local _activeDialog = nil

local function CreateDialog(info)
	local isInfo = (info.Type == "info")
	local closed = false
	local conns = Connections.new()
	local prevModal = ModalCapture.Modal

	ModalCapture.Modal = true

	local blocker = Build("Frame", {
		BackgroundColor3 = "Black",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Parent = RootGui,
		DPIExclude = { Size = true },
	})

	local popup = Build("Frame", {
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.38),
		ZIndex = 51,
		Parent = RootGui,
		DPIExclude = { Position = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 2), Parent = popup })

	local headerBg = Build("Frame", {
		BackgroundColor3 = "Background",
		BorderSizePixel = 0,
		ZIndex = 51,
		Parent = popup,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 2), Parent = headerBg })

	local headerLine = Build("Frame", {
		BackgroundColor3 = "Border",
		BorderSizePixel = 0,
		ZIndex = 52,
		Parent = popup,
		DPIExclude = { Position = true, Size = true },
	})

	local header = Build("Frame", {
		BackgroundTransparency = 1,
		ZIndex = 52,
		Parent = popup,
		DPIExclude = { Position = true, Size = true },
	})
	local titleLabel = Build("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(info.Title or "Dialog"),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 53,
		Parent = header,
		DPIExclude = { Size = true },
	})

	local body = Build("Frame", {
		BackgroundTransparency = 1,
		ZIndex = 52,
		Parent = popup,
		DPIExclude = { Position = true, Size = true },
	})
	local descScroll = Build("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 2,
		ZIndex = 53,
		Parent = body,
		DPIExclude = { Position = true, Size = true },
	})
	local descLabel = Build("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(info.Description or ""),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 54,
		Parent = descScroll,
		DPIExclude = { Size = true },
	})

	local buttonsHolder = Build("Frame", {
		BackgroundTransparency = 1,
		ZIndex = 53,
		Parent = body,
		DPIExclude = { Position = true, Size = true },
	})

	local function makeBtn(text, kind)
		local btn = Build("TextButton", {
			BackgroundColor3 = kind == "confirm" and Theme.Accent:Lerp(Theme.Surface, 0.2) or Theme.Surface,
			BorderColor3 = kind == "confirm" and Theme.Accent:Lerp(Theme.White, 0.2) or Theme.Border,
			BorderSizePixel = 1,
			Text = text,
			TextSize = 14,
			ZIndex = 54,
			Parent = buttonsHolder,
			DPIExclude = { Position = true, Size = true },
		})
		Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius), Parent = btn })
		return btn
	end

	local confirmBtn =
		makeBtn(isInfo and tostring(info.OkText or "OK") or tostring(info.ConfirmText or "Confirm"), "confirm")
	local cancelBtn = not isInfo and makeBtn(tostring(info.CancelText or "Cancel"), "cancel") or nil

	local function applyLayout()
		local vp = workspace.CurrentCamera.ViewportSize
		local portrait = vp.Y > vp.X or vp.X < 760
		local w, h = popup.AbsoluteSize.X, popup.AbsoluteSize.Y

		local px = math.max(12, math.floor(w * 0.04))
		local py = math.max(10, math.floor(h * 0.05))
		local gap = math.max(8, math.floor(h * 0.03))
		local headH = math.max(32, math.floor(h * 0.19))
		local btnH = math.max(32, math.floor(h * 0.13))
		local titleSz = math.clamp(math.floor(h * 0.09), 13, 21)
		local descSz = math.clamp(math.floor(h * 0.07), 12, 17)

		header.Position = UDim2.fromOffset(px, py)
		header.Size = UDim2.new(1, -px * 2, 0, headH)
		titleLabel.Size = UDim2.fromScale(1, 1)
		titleLabel.TextSize = titleSz

		headerBg.Position = UDim2.fromOffset(0, 0)
		headerBg.Size = UDim2.new(1, 0, 0, py + headH + math.floor(gap * 0.5))
		headerLine.Position = UDim2.fromOffset(0, py + headH + math.floor(gap * 0.5))
		headerLine.Size = UDim2.new(1, 0, 0, 1)

		local bodyTop = py + headH + gap + 2
		body.Position = UDim2.fromOffset(px, bodyTop)
		body.Size = UDim2.new(1, -px * 2, 1, -(bodyTop + py))

		local ix = math.max(10, math.floor(px * 0.75))
		local iy = math.max(10, math.floor(py * 0.75))
		local stacked = portrait and not isInfo

		local footerH = isInfo and btnH or (stacked and (btnH * 2 + gap) or btnH)
		buttonsHolder.Size = UDim2.new(1, -ix * 2, 0, footerH)
		buttonsHolder.Position = UDim2.new(0, ix, 1, -(iy + footerH))

		confirmBtn.TextSize = math.max(12, descSz)
		if cancelBtn then
			cancelBtn.TextSize = confirmBtn.TextSize
		end

		if isInfo then
			local bw = math.max(110, math.floor(buttonsHolder.AbsoluteSize.X * 0.5))
			confirmBtn.Size = UDim2.fromOffset(bw, btnH)
			confirmBtn.Position = UDim2.new(0.5, -math.floor(bw / 2), 0, 0)
		elseif stacked then
			confirmBtn.Size = UDim2.new(1, 0, 0, btnH)
			confirmBtn.Position = UDim2.fromOffset(0, 0)
			cancelBtn.Size = UDim2.new(1, 0, 0, btnH)
			cancelBtn.Position = UDim2.fromOffset(0, btnH + gap)
		else
			local totalW = buttonsHolder.AbsoluteSize.X
			local bw = math.max(96, math.floor((totalW - gap) / 2))
			confirmBtn.Size = UDim2.fromOffset(bw, btnH)
			confirmBtn.Position = UDim2.fromOffset(0, 0)
			cancelBtn.Size = UDim2.fromOffset(bw, btnH)
			cancelBtn.Position = UDim2.new(1, -bw, 0, 0)
		end

		local descH = math.max(54, body.AbsoluteSize.Y - (iy + footerH + gap + iy))
		descScroll.Position = UDim2.fromOffset(ix, iy)
		descScroll.Size = UDim2.new(1, -ix * 2, 0, descH)
		descLabel.TextSize = descSz
		descLabel.Size = UDim2.new(1, -6, 0, 0)

		local tx, ty = TextMeasure.Bounds(
			descLabel.Text,
			descLabel.FontFace,
			descLabel.TextSize,
			math.max(16, descScroll.AbsoluteSize.X - 8)
		)
		descLabel.Size = UDim2.fromOffset(math.max(0, math.ceil(tx)), math.max(descH, math.ceil(ty)))
		descScroll.CanvasSize = UDim2.fromOffset(0, math.ceil(ty))
		descScroll.CanvasPosition = Vector2.zero
	end

	local resultSignal = Signal.new()
	local dialog = {}
	_activeDialog = dialog

	local function finalize(accepted, reason)
		if closed then
			return
		end
		closed = true

		if _activeDialog == dialog then
			_activeDialog = nil
		end

		conns:DisconnectAll()
		ModalCapture.Modal = prevModal

		resultSignal:Fire(accepted, reason)

		task.defer(function()
			if accepted then
				Run(info.OnConfirm, reason)
			else
				Run(info.OnCancel, reason)
			end
			Run(info.Callback, accepted, reason)
			Run(info.OnClose, accepted, reason)
		end)

		Anim:Play(blocker, DEFAULT_FAST_TWEEN, { BackgroundTransparency = 1 })
		task.delay(DEFAULT_FAST_TWEEN.Time, function()
			pcall(function()
				popup:Destroy()
			end)
			pcall(function()
				blocker:Destroy()
			end)
		end)
	end

	function dialog:Close(accepted, reason)
		finalize(accepted == true, reason or "manual")
	end

	conns:Add(confirmBtn.Activated:Connect(function()
		finalize(true, isInfo and "ok" or "confirm")
	end))
	if cancelBtn then
		conns:Add(cancelBtn.Activated:Connect(function()
			finalize(false, "cancel")
		end))
	end
	conns:Add(InputService.InputBegan:Connect(function(inp, processed)
		if processed then
			return
		end
		if inp.KeyCode == Enum.KeyCode.Return or inp.KeyCode == Enum.KeyCode.KeypadEnter then
			finalize(true, isInfo and "ok" or "confirm")
		elseif info.AllowEscape and inp.KeyCode == Enum.KeyCode.Escape then
			finalize(false, "escape")
		end
	end))
	conns:Add(RootGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout))

	AttachDraggable(popup, header, true)
	applyLayout()
	Anim:Play(blocker, DEFAULT_FAST_TWEEN, { BackgroundTransparency = 0.52 })

	if info.Wait then
		return resultSignal:Wait()
	end
	return dialog
end

-- ═══════════════════════════════════════════════════════════════════════════
--  KEYBIND PANEL
-- ═══════════════════════════════════════════════════════════════════════════

local _keybindPanel, _keybindContainer
local _keybindRows = {}

local function _initKeybindPanel()
	if _keybindPanel then
		return
	end
	_keybindPanel, _keybindContainer = CreateDraggablePanel("Keybinds")
	_keybindPanel.AnchorPoint = Vector2.new(0, 0.5)
	_keybindPanel.Position = UDim2.new(0, 6, 0.5, 0)
	_keybindPanel.Visible = false
	Registry.BindDPI(_keybindPanel, "Position", nil, true)
	Registry.BindDPI(_keybindPanel, "Size", nil, true)
end

local function _updateKeybindPanelWidth()
	if not _keybindPanel then
		return
	end
	local maxX = 0
	for _, row in pairs(_keybindRows) do
		if row.Holder.Visible then
			local full = row.Label.Size.X.Offset + row.Label.Position.X.Offset
			if full > maxX then
				maxX = full
			end
		end
	end
	_keybindPanel.Size = UDim2.fromOffset(maxX + 18 * _dpiScale, 0)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  VALIDATION HELPER (fills missing keys from a template)
-- ═══════════════════════════════════════════════════════════════════════════

local function Validate(input, template)
	if typeof(input) ~= "table" then
		return Tbl.ShallowCopy(template)
	end
	for k, v in pairs(template) do
		if typeof(k) == "number" then
			continue
		end
		if typeof(v) == "table" then
			input[k] = Validate(input[k], v)
		elseif input[k] == nil then
			input[k] = v
		end
	end
	return input
end

-- ═══════════════════════════════════════════════════════════════════════════
--  COMPONENT BASE CLASS
-- ═══════════════════════════════════════════════════════════════════════════
-- Every widget carries: Holder, Type, Text, Visible, Disabled
-- and must implement :_refresh() to rebuild visual state.

local Component = {}
Component.__index = Component

function Component.new(kind)
	local self = setmetatable({}, Component)
	self.Type = kind
	self.Visible = true
	self.Disabled = false
	self.Addons = {}
	return self
end

function Component:_refresh() end -- overridden by each widget

function Component:SetVisible(visible)
	self.Visible = visible
	if self.Holder then
		self.Holder.Visible = visible
	end
	if self._groupbox then
		self._groupbox:Resize()
	end
end

function Component:SetDisabled(disabled)
	self.Disabled = disabled
	if self.TooltipHandle then
		self.TooltipHandle.disabled = disabled
	end
	self:_refresh()
end

function Component:OnChanged(fn)
	self._changedFn = fn
end

function Component:_fireChanged(value)
	Run(self._changedFn, value)
	Run(self.Changed, value)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ADDON: KEY PICKER
-- ═══════════════════════════════════════════════════════════════════════════

local function BuildKeyPicker(owner, idx, info)
	info = Validate(info, {
		Text = "KeyPicker",
		Default = "None",
		Mode = "Toggle",
		Modes = { "Always", "Toggle", "Hold" },
		SyncToggleState = false,
		NoUI = false,
		Callback = function() end,
		ChangedCallback = function() end,
		Changed = function() end,
		Clicked = function() end,
	})

	_initKeybindPanel()

	if info.Mode == "Press" then
		assert(owner.Type == "Label", "KeyPicker 'Press' mode requires a Label parent.")
		info.SyncToggleState = false
		info.Modes = { "Press" }
	end
	if info.SyncToggleState then
		info.Modes = { "Toggle" }
		info.Mode = "Toggle"
	end

	local kp = {
		Type = "KeyPicker",
		Text = info.Text,
		Value = info.Default,
		Toggled = false,
		Mode = info.Mode,
		SyncToggleState = info.SyncToggleState,
		Callback = info.Callback,
		ChangedCallback = info.ChangedCallback,
		Changed = info.Changed,
		Clicked = info.Clicked,
	}

	local parentLabel = owner.TextLabel or owner.Holder

	local pickerBtn = Build("TextButton", {
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Size = UDim2.fromOffset(18, 18),
		Text = kp.Value,
		TextSize = 13,
		Parent = parentLabel,
	})

	-- Keybind panel row
	local kbRow = { Normal = kp.Mode ~= "Toggle" }
	do
		local rowHolder = Build("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Text = "",
			Visible = not info.NoUI,
			Parent = _keybindContainer,
		})
		local rowLabel = Build("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextSize = 13,
			TextTransparency = 0.5,
			Parent = rowHolder,
			DPIExclude = { Size = true },
		})
		local rowCheck = Build("Frame", {
			BackgroundColor3 = "Surface",
			Size = UDim2.fromOffset(14, 14),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Parent = rowHolder,
		})
		Build("UICorner", {
			CornerRadius = UDim.new(0, math.floor(Theme.Radius / 2)),
			Parent = rowCheck,
		})
		Build("UIStroke", { Color = "Border", Parent = rowCheck })
		local rowCheckMark = Build("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 1, -4),
			Position = UDim2.fromOffset(2, 2),
			Text = "✓",
			TextSize = 10,
			TextTransparency = 1,
			Parent = rowCheck,
		})

		function kbRow:Display(state)
			rowLabel.TextTransparency = state and 0 or 0.5
			rowCheckMark.TextTransparency = state and 0 or 1
		end

		function kbRow:SetText(text)
			local x = TextMeasure.Bounds(text, rowLabel.FontFace, rowLabel.TextSize)
			rowLabel.Text = text
			rowLabel.Size = UDim2.new(0, x, 1, 0)
		end

		function kbRow:SetVisibility(vis)
			rowHolder.Visible = vis
		end

		function kbRow:SetNormal(normal)
			kbRow.Normal = normal
			rowHolder.Active = not normal
			rowLabel.Position = normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22 * _dpiScale, 0)
			rowCheck.Visible = not normal
		end

		rowHolder.MouseButton1Click:Connect(function()
			if kbRow.Normal then
				return
			end
			kp.Toggled = not kp.Toggled
			kp:DoClick()
		end)

		kbRow.Holder = rowHolder
		kbRow.Label = rowLabel
		kbRow.Checkbox = rowCheck
		table.insert(_keybindRows, kbRow)
	end

	-- Context menu for mode selection
	local modeMenu = CreateContextMenu(pickerBtn, UDim2.fromOffset(62, 0), function()
		return { pickerBtn.AbsoluteSize.X + 1.5, 0.5 }
	end, 1)
	kp.Menu = modeMenu

	local modeBtns = {}
	for _, modeName in ipairs(info.Modes) do
		local modeBtn = {}
		local btn = Build("TextButton", {
			BackgroundColor3 = "Surface",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 21),
			Text = modeName,
			TextSize = 13,
			TextTransparency = 0.5,
			Parent = modeMenu.Menu,
		})

		function modeBtn:Select()
			for _, mb in pairs(modeBtns) do
				mb:Deselect()
			end
			kp.Mode = modeName
			btn.BackgroundTransparency = 0
			btn.TextTransparency = 0
			modeMenu:Close()
		end

		function modeBtn:Deselect()
			btn.BackgroundTransparency = 1
			btn.TextTransparency = 0.5
		end

		btn.MouseButton1Click:Connect(function()
			modeBtn:Select()
		end)
		if kp.Mode == modeName then
			modeBtn:Select()
		end

		table.insert(modeBtns, modeBtn)
	end

	local SpecialKeys = {
		MB1 = Enum.UserInputType.MouseButton1,
		MB2 = Enum.UserInputType.MouseButton2,
		MB3 = Enum.UserInputType.MouseButton3,
	}
	local SpecialKeysReverse = {
		[Enum.UserInputType.MouseButton1] = "MB1",
		[Enum.UserInputType.MouseButton2] = "MB2",
		[Enum.UserInputType.MouseButton3] = "MB3",
	}

	local _waitingForKey = false

	function kp:Update()
		local valueStr = kp.Value == "None" and "None" or kp.Value
		pickerBtn.Text = valueStr
		kbRow:SetText(("[%s]"):format(valueStr))

		local isToggle = kp.Mode == "Toggle"
		kbRow:SetNormal(not isToggle)
		if isToggle then
			kbRow:Display(kp.Toggled)
		end
		_updateKeybindPanelWidth()
	end

	function kp:DoClick()
		Run(kp.Callback, kp.Toggled)
		Run(kp.Clicked)
		kbRow:Display(kp.Toggled)
	end

	function kp:SetValue(value)
		kp.Value = tostring(value or "None")
		kp:Update()
		Run(kp.ChangedCallback, kp.Value)
		Run(kp.Changed, kp.Value)
	end

	-- Listening for key press/release
	_globalConns:Add(InputService.InputBegan:Connect(function(inp, processed)
		if processed and not _waitingForKey then
			return
		end

		if _waitingForKey then
			_waitingForKey = false
			pickerBtn.Text = kp.Value

			local newVal
			if SpecialKeysReverse[inp.UserInputType] then
				newVal = SpecialKeysReverse[inp.UserInputType]
			elseif inp.KeyCode ~= Enum.KeyCode.Unknown and inp.UserInputType == Enum.UserInputType.Keyboard then
				newVal = inp.KeyCode.Name
			end

			if newVal then
				kp:SetValue(newVal)
			end
			return
		end

		local target = SpecialKeys[kp.Value] or (kp.Value ~= "None" and Enum.KeyCode[kp.Value])

		if not target then
			return
		end

		local triggered = (typeof(target) == "EnumItem" and target.EnumType == Enum.UserInputType)
				and inp.UserInputType == target
			or (typeof(target) == "EnumItem" and target.EnumType == Enum.KeyCode and inp.KeyCode == target)

		if not triggered then
			return
		end

		if kp.Mode == "Toggle" then
			kp.Toggled = not kp.Toggled
			kp:DoClick()
		elseif kp.Mode == "Always" then
			kp.Toggled = true
			kp:DoClick()
		elseif kp.Mode == "Hold" then
			kp.Toggled = true
			kp:DoClick()
		elseif kp.Mode == "Press" then
			kp.Toggled = true
			Run(kp.Callback, true)
			Run(kp.Clicked)
		end
	end))

	_globalConns:Add(InputService.InputEnded:Connect(function(inp)
		if kp.Mode ~= "Hold" then
			return
		end
		local target = SpecialKeys[kp.Value] or (kp.Value ~= "None" and Enum.KeyCode[kp.Value])
		if not target then
			return
		end
		local ended = (
			typeof(target) == "EnumItem"
			and target.EnumType == Enum.UserInputType
			and inp.UserInputType == target
		) or (typeof(target) == "EnumItem" and target.EnumType == Enum.KeyCode and inp.KeyCode == target)
		if ended then
			kp.Toggled = false
			kp:DoClick()
		end
	end))

	pickerBtn.MouseButton1Click:Connect(function()
		_waitingForKey = true
		pickerBtn.Text = "..."
	end)

	pickerBtn.MouseButton2Click:Connect(function()
		modeMenu:Toggle()
	end)

	kp:Update()

	if owner.Addons then
		table.insert(owner.Addons, kp)
	end

	if idx then
		LRXUI.Options[idx] = kp
	end

	return kp
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ADDON: COLOR PICKER
-- ═══════════════════════════════════════════════════════════════════════════

local function BuildColorPicker(owner, idx, info)
	info = Validate(info, {
		Default = Color3.new(1, 1, 1),
		Transparency = false,
		Callback = function() end,
		Changed = function() end,
	})

	local cp = {
		Type = "ColorPicker",
		Hue = 0,
		Sat = 1,
		Vib = 1,
		Transparency = 0,
		Value = info.Default,
		Callback = info.Callback,
		Changed = info.Changed,
	}

	cp.Hue, cp.Sat, cp.Vib = info.Default:ToHSV()

	local parentLabel = owner.TextLabel or owner.Holder

	local swatchBtn = Build("TextButton", {
		BackgroundColor3 = info.Default,
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Size = UDim2.fromOffset(18, 18),
		Text = "",
		Parent = parentLabel,
		DPIExclude = { Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = swatchBtn })
	local swatchTransLayer = Build("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		Size = UDim2.fromScale(1, 1),
		Parent = swatchBtn,
	})

	-- Picker popup
	local pickerPopup = Build("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(220, info.Transparency and 230 or 200),
		Visible = false,
		ZIndex = 15,
		Parent = RootGui,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 2), Parent = pickerPopup })
	Build("UIStroke", { Color = "Border", Transparency = 0.3, Parent = pickerPopup })

	-- Saturation-Value map
	local svMap = Build("Frame", {
		BackgroundColor3 = Color3.fromHSV(0, 1, 1),
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -50, 0, 150),
		ZIndex = 16,
		Parent = pickerPopup,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = svMap })

	local svWhiteGrad = Build("Frame", {
		BackgroundColor3 = "White",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 17,
		Parent = svMap,
	})
	Build("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		}),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Parent = svWhiteGrad,
	})

	local svBlackGrad = Build("Frame", {
		BackgroundColor3 = "Black",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 17,
		Parent = svMap,
	})
	Build("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
		}),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
		Rotation = 90,
		Parent = svBlackGrad,
	})

	local svCursor = Build("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		BorderColor3 = "Black",
		BorderSizePixel = 1,
		Size = UDim2.fromOffset(8, 8),
		ZIndex = 18,
		Parent = svMap,
		DPIExclude = { Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svCursor })

	-- Hue slider
	local hueTrack = Build("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.new(0, 14, 0, 150),
		ZIndex = 16,
		Parent = pickerPopup,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = hueTrack })
	Build("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0 / 6, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
		Rotation = 90,
		Parent = hueTrack,
	})
	local hueCursor = Build("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		BorderColor3 = "Black",
		BorderSizePixel = 1,
		Size = UDim2.new(1, 2, 0, 4),
		ZIndex = 18,
		Parent = hueTrack,
		DPIExclude = { Size = true },
	})

	-- Transparency slider (optional)
	local transTrack, transCursor, transColorLayer
	if info.Transparency then
		transTrack = Build("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 168),
			Size = UDim2.new(0, 14, 0, 30),
			ZIndex = 16,
			Parent = pickerPopup,
			DPIExclude = { Position = true, Size = true },
		})
		Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = transTrack })
		transColorLayer = Build("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 17,
			Parent = transTrack,
		})
		Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = transColorLayer })
		Build("UIGradient", {
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Rotation = 90,
			Parent = transColorLayer,
		})
		transCursor = Build("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = "White",
			BorderColor3 = "Black",
			BorderSizePixel = 1,
			Size = UDim2.new(1, 2, 0, 4),
			ZIndex = 18,
			Parent = transTrack,
			DPIExclude = { Size = true },
		})
	end

	-- Hex and RGB inputs
	local inputsArea = Build("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 168),
		Size = UDim2.new(1, -(info.Transparency and 50 or 50), 0, 24),
		ZIndex = 16,
		Parent = pickerPopup,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		Parent = inputsArea,
	})
	local hexInput = Build("TextBox", {
		BackgroundColor3 = "Background",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		PlaceholderText = "#FFFFFF",
		Size = UDim2.new(0.45, 0, 1, 0),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 17,
		Parent = inputsArea,
		DPIExclude = { Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = hexInput })
	local rgbInput = Build("TextBox", {
		BackgroundColor3 = "Background",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		PlaceholderText = "255, 255, 255",
		Size = UDim2.new(0.55, -4, 1, 0),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 17,
		Parent = inputsArea,
		DPIExclude = { Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = rgbInput })

	local pickerMenu = { Menu = pickerPopup, Active = false }

	function pickerMenu:Open()
		if _activeMenu and _activeMenu ~= pickerMenu then
			_activeMenu:Close()
		end
		_activeMenu = pickerMenu
		pickerMenu.Active = true
		-- position near swatch
		local absPos = swatchBtn.AbsolutePosition
		local absSz = swatchBtn.AbsoluteSize
		local vpSz = workspace.CurrentCamera.ViewportSize
		local pw, ph = pickerPopup.Size.X.Offset, pickerPopup.Size.Y.Offset
		local x = absPos.X + absSz.X + 4
		local y = absPos.Y
		if x + pw > vpSz.X then
			x = absPos.X - pw - 4
		end
		if y + ph > vpSz.Y then
			y = vpSz.Y - ph - 4
		end
		pickerPopup.Position = UDim2.fromOffset(x, y)
		pickerPopup.Visible = true
	end

	function pickerMenu:Close()
		if not pickerMenu.Active then
			return
		end
		pickerMenu.Active = false
		pickerPopup.Visible = false
		if _activeMenu == pickerMenu then
			_activeMenu = nil
		end
	end

	function pickerMenu:Toggle()
		if pickerMenu.Active then
			pickerMenu:Close()
		else
			pickerMenu:Open()
		end
	end

	function cp:Display()
		cp.Value = Color3.fromHSV(cp.Hue, cp.Sat, cp.Vib)

		swatchBtn.BackgroundColor3 = cp.Value
		swatchBtn.BorderColor3 = Theme:Darken(cp.Value)
		swatchTransLayer.ImageTransparency = 1 - cp.Transparency

		svMap.BackgroundColor3 = Color3.fromHSV(cp.Hue, 1, 1)
		if transColorLayer then
			transColorLayer.BackgroundColor3 = cp.Value
		end

		svCursor.Position = UDim2.fromScale(cp.Sat, 1 - cp.Vib)
		hueCursor.Position = UDim2.fromScale(0.5, cp.Hue)
		if transCursor then
			transCursor.Position = UDim2.fromScale(0.5, cp.Transparency)
		end

		hexInput.Text = "#" .. cp.Value:ToHex()
		rgbInput.Text = ("%d, %d, %d"):format(
			math.floor(cp.Value.R * 255),
			math.floor(cp.Value.G * 255),
			math.floor(cp.Value.B * 255)
		)
	end

	function cp:Update()
		cp:Display()
		Run(cp.Callback, cp.Value)
		Run(cp.Changed, cp.Value)
	end

	function cp:OnChanged(fn)
		cp.Changed = fn
	end

	function cp:SetValue(hsv, transparency)
		local color = Color3.fromHSV(hsv[1], hsv[2], hsv[3])
		cp.Transparency = info.Transparency and (transparency or 0) or 0
		cp.Hue, cp.Sat, cp.Vib = color:ToHSV()
		cp:Update()
	end

	function cp:SetValueRGB(color, transparency)
		cp.Transparency = info.Transparency and (transparency or 0) or 0
		cp.Hue, cp.Sat, cp.Vib = color:ToHSV()
		cp:Update()
	end

	-- Drag interactions
	local function dragOnMap(inp)
		while Input.IsDrag(inp) do
			local minX = svMap.AbsolutePosition.X
			local maxX = minX + svMap.AbsoluteSize.X
			local minY = svMap.AbsolutePosition.Y
			local maxY = minY + svMap.AbsoluteSize.Y

			local oldSat, oldVib = cp.Sat, cp.Vib
			cp.Sat = (Mth.Clamp(Mouse.X, minX, maxX) - minX) / (maxX - minX)
			cp.Vib = 1 - (Mth.Clamp(Mouse.Y, minY, maxY) - minY) / (maxY - minY)

			if cp.Sat ~= oldSat or cp.Vib ~= oldVib then
				cp:Update()
			end
			RunService.RenderStepped:Wait()
		end
	end

	local function dragOnHue(inp)
		while Input.IsDrag(inp) do
			local minY = hueTrack.AbsolutePosition.Y
			local maxY = minY + hueTrack.AbsoluteSize.Y
			local oldHue = cp.Hue
			cp.Hue = (Mth.Clamp(Mouse.Y, minY, maxY) - minY) / (maxY - minY)
			if cp.Hue ~= oldHue then
				cp:Update()
			end
			RunService.RenderStepped:Wait()
		end
	end

	svMap.InputBegan:Connect(function(inp)
		if Input.IsClick(inp) then
			dragOnMap(inp)
		end
	end)
	hueTrack.InputBegan:Connect(function(inp)
		if Input.IsClick(inp) then
			dragOnHue(inp)
		end
	end)

	if transTrack then
		transTrack.InputBegan:Connect(function(inp)
			if not Input.IsClick(inp) then
				return
			end
			while Input.IsDrag(inp) do
				local minY = transTrack.AbsolutePosition.Y
				local maxY = minY + transTrack.AbsoluteSize.Y
				local oldT = cp.Transparency
				cp.Transparency = (Mth.Clamp(Mouse.Y, minY, maxY) - minY) / (maxY - minY)
				if cp.Transparency ~= oldT then
					cp:Update()
				end
				RunService.RenderStepped:Wait()
			end
		end)
	end

	hexInput.FocusLost:Connect(function(enter)
		if not enter then
			return
		end
		local ok, color = pcall(Color3.fromHex, hexInput.Text:gsub("#", ""))
		if ok and typeof(color) == "Color3" then
			cp.Hue, cp.Sat, cp.Vib = color:ToHSV()
		end
		cp:Update()
	end)

	rgbInput.FocusLost:Connect(function(enter)
		if not enter then
			return
		end
		local r, g, b = rgbInput.Text:match("(%d+),%s*(%d+),%s*(%d+)")
		if r and g and b then
			cp.Hue, cp.Sat, cp.Vib = Color3.fromRGB(r, g, b):ToHSV()
		end
		cp:Update()
	end)

	swatchBtn.MouseButton1Click:Connect(function()
		pickerMenu:Toggle()
	end)

	-- Close on outside click
	_globalConns:Add(InputService.InputBegan:Connect(function(inp)
		if not Input.IsClick(inp) then
			return
		end
		if not pickerMenu.Active then
			return
		end
		local abs = pickerPopup.AbsolutePosition
		local sz = pickerPopup.AbsoluteSize
		if Mouse.X < abs.X or Mouse.X > abs.X + sz.X or Mouse.Y < abs.Y or Mouse.Y > abs.Y + sz.Y then
			pickerMenu:Close()
		end
	end))

	cp:Display()

	if owner.Addons then
		table.insert(owner.Addons, cp)
	end
	if idx then
		LRXUI.Options[idx] = cp
	end

	return owner -- chainable
end

-- ═══════════════════════════════════════════════════════════════════════════
--  GROUPBOX CLASS
-- ═══════════════════════════════════════════════════════════════════════════

local GroupboxMeta = {}
GroupboxMeta.__index = GroupboxMeta

local function _createGroupbox(tab, parentColumn, info, windowRadius)
	local cornerRadius = windowRadius or Theme.Radius
	local headerHeight = 40
	local contentPadTop = 8
	local contentPadBot = 12
	local outerInset = 6

	local boxHolder = Build("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		Parent = parentColumn,
	})
	Build("UIListLayout", { Padding = UDim.new(0, 6), Parent = boxHolder })

	local outerDecor, _ = MakeOutlineFrame(boxHolder, cornerRadius)
	outerDecor.Size = UDim2.fromScale(1, 0)
	Registry.BindDPI(outerDecor, "Size", nil, true)

	local innerBody = Build("Frame", {
		BackgroundColor3 = "Background",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = outerDecor,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", {
		CornerRadius = UDim.new(0, math.max(cornerRadius - 1, 0)),
		Parent = innerBody,
	})

	MakeDividerLine(innerBody, UDim2.fromOffset(0, headerHeight), UDim2.new(1, 0, 0, 1))

	local headerFrame = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, headerHeight),
		Parent = innerBody,
		DPIExclude = { Size = true },
	})

	local leftOffset = 12
	if info.IconName then
		local iconCard = Build("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.5,
			Position = UDim2.fromOffset(8, 7),
			Size = UDim2.fromOffset(26, 26),
			Parent = headerFrame,
			DPIExclude = { Position = true, Size = true },
		})
		Build("UICorner", { CornerRadius = UDim.new(0, 6), Parent = iconCard })
		-- Icon image would be filled if icon loading is available
		leftOffset = 40
	end

	local nameLabel = Build("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(leftOffset, info.Description and 2 or 0),
		Size = UDim2.new(1, -(leftOffset + 38), 0, info.Description and 20 or headerHeight),
		Text = tostring(info.Name or "Group"),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = info.Description and Enum.TextYAlignment.Bottom or Enum.TextYAlignment.Center,
		Parent = headerFrame,
		DPIExclude = { Position = true, Size = true },
	})

	if info.Description then
		Build("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(leftOffset, 19),
			Size = UDim2.new(1, -(leftOffset + 38), 0, 16),
			Text = tostring(info.Description),
			TextSize = 11,
			TextColor3 = Color3.fromRGB(178, 178, 178),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerFrame,
			DPIExclude = { Position = true, Size = true },
		})
	end

	local collapseIcon = Build("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -28, 0, 10),
		Text = "",
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 12,
		Font = Enum.Font.Code,
		Parent = headerFrame,
		DPIExclude = { Position = true, Size = true },
	})

	local contentFrame = Build("Frame", {
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.67,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(outerInset, headerHeight + outerInset),
		Size = UDim2.new(1, -(outerInset * 2), 1, -(headerHeight + outerInset * 2)),
		Parent = innerBody,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, 9), Parent = contentFrame })

	local contentLayout = Build("UIListLayout", {
		Padding = UDim.new(0, 8),
		Parent = contentFrame,
	})
	Build("UIPadding", {
		PaddingTop = UDim.new(0, contentPadTop),
		PaddingBottom = UDim.new(0, contentPadBot),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = contentFrame,
	})

	local gb = setmetatable({
		BoxHolder = boxHolder,
		Holder = outerDecor,
		Container = contentFrame,
		ToggleIcon = collapseIcon,
		Tab = tab,
		DependencyBoxes = {},
		Elements = {},
		Visible = true,
		IsKeyTab = (tab and tab.IsKeyTab) or false,
	}, GroupboxMeta)

	local collapsed = (info.StartCollapsed == true)

	local activeTween

	local function contentHeight()
		local listH = (contentLayout and contentLayout.AbsoluteContentSize and contentLayout.AbsoluteContentSize.Y) or 0
		return headerHeight + outerInset + (listH + contentPadTop + contentPadBot) + outerInset
	end

	local function targetH()
		return collapsed and headerHeight or contentHeight()
	end

	local function syncArrow()
		collapseIcon.Text = collapsed and "›" or "∨"
	end

	function gb:Resize(animated)
		if not outerDecor or not outerDecor.Parent then
			return
		end
		local sz = UDim2.new(1, 0, 0, math.max(0, math.floor(targetH() + 0.5)))
		if activeTween then
			activeTween:Cancel()
		end
		if animated then
			activeTween = TweenService:Create(outerDecor, DEFAULT_OPEN_TWEEN, { Size = sz })
			activeTween:Play()
		else
			outerDecor.Size = sz
		end
	end

	local function toggleCollapse()
		collapsed = not collapsed
		syncArrow()
		if not collapsed then
			contentFrame.Visible = true
			gb:Resize(true)
		else
			gb:Resize(true)
			task.delay(DEFAULT_OPEN_TWEEN.Time, function()
				if collapsed and contentFrame and contentFrame.Parent then
					contentFrame.Visible = false
				end
			end)
		end
	end

	local hconns = Connections.new()
	local touchObj, touchStart
	local MAX_TAP_MOVE = 4

	hconns:Add(headerFrame.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			toggleCollapse()
		elseif inp.UserInputType == Enum.UserInputType.Touch then
			touchObj = inp
			touchStart = inp.Position
		end
	end))
	hconns:Add(InputService.InputChanged:Connect(function(inp)
		if inp ~= touchObj or not touchStart then
			return
		end
		local delta = inp.Position - touchStart
		if math.abs(delta.X) > MAX_TAP_MOVE or math.abs(delta.Y) > MAX_TAP_MOVE then
			touchObj = nil
			touchStart = nil
		end
	end))
	hconns:Add(InputService.InputEnded:Connect(function(inp)
		if inp ~= touchObj then
			return
		end
		toggleCollapse()
		touchObj = nil
		touchStart = nil
	end))
	hconns:Add(contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if not collapsed then
			gb:Resize(false)
		end
	end))
	hconns:Add(boxHolder.AncestryChanged:Connect(function(_, newParent)
		if newParent == nil then
			hconns:DisconnectAll()
		end
	end))

	syncArrow()
	contentFrame.Visible = not collapsed
	gb:Resize(false)

	return gb
end

-- Groupbox element adders (widgets go here)
function GroupboxMeta:AddDivider()
	local holder = Build("Frame", {
		BackgroundColor3 = "Border",
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		Parent = self.Container,
	})
	self:Resize(false)
	table.insert(self.Elements, { Holder = holder, Type = "Divider", Visible = true })
	return self
end

function GroupboxMeta:AddSpacer(height)
	height = (typeof(height) == "number" and height) or 20
	local holder = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		Parent = self.Container,
	})
	self:Resize(false)
	table.insert(self.Elements, { Holder = holder, Type = "Spacer", Visible = true })
	return self
end

function GroupboxMeta:AddLabel(textOrInfo, doesWrap, idx)
	local data = {}
	if typeof(textOrInfo) == "table" then
		data.Text = textOrInfo.Text or ""
		data.DoesWrap = textOrInfo.DoesWrap or false
		data.Size = textOrInfo.Size or 13
		data.Visible = textOrInfo.Visible ~= false
		data.Idx = textOrInfo.Idx or idx
	else
		data.Text = tostring(textOrInfo or "")
		data.DoesWrap = doesWrap or false
		data.Size = 13
		data.Visible = true
		data.Idx = idx
	end

	local gb = self

	local widget = {
		Text = data.Text,
		DoesWrap = data.DoesWrap,
		Visible = data.Visible,
		Type = "Label",
		Addons = {},
	}

	local textLabel = Build("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = widget.Text,
		TextSize = data.Size,
		TextWrapped = widget.DoesWrap,
		TextXAlignment = gb.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		Parent = gb.Container,
	})

	if not data.DoesWrap then
		Build("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 6),
			Parent = textLabel,
		})
	else
		local lastSize = textLabel.AbsoluteSize
		textLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if textLabel.AbsoluteSize == lastSize then
				return
			end
			lastSize = textLabel.AbsoluteSize
			local _, y =
				TextMeasure.Bounds(widget.Text, textLabel.FontFace, textLabel.TextSize, textLabel.AbsoluteSize.X)
			textLabel.Size = UDim2.new(1, 0, 0, y + 4 * _dpiScale)
			gb:Resize(false)
		end)
	end

	function widget:SetText(text)
		widget.Text = text
		textLabel.Text = text
		if widget.DoesWrap then
			local _, y = TextMeasure.Bounds(text, textLabel.FontFace, textLabel.TextSize, textLabel.AbsoluteSize.X)
			textLabel.Size = UDim2.new(1, 0, 0, y + 4 * _dpiScale)
		end
		gb:Resize(false)
	end

	function widget:SetVisible(visible)
		widget.Visible = visible
		textLabel.Visible = visible
		gb:Resize(false)
	end

	function widget:AddKeyPicker(kidx, kinfo)
		return BuildKeyPicker(self, kidx, kinfo)
	end
	function widget:AddColorPicker(cidx, cinfo)
		return BuildColorPicker(self, cidx, cinfo)
	end

	widget.TextLabel = textLabel
	widget.Holder = textLabel
	widget.Container = gb.Container

	gb:Resize(false)
	table.insert(gb.Elements, widget)

	if data.Idx then
		LRXUI.Labels[data.Idx] = widget
	else
		table.insert(LRXUI.Labels, widget)
	end

	return widget
end

function GroupboxMeta:AddButton(textOrInfo, func, idx)
	local info = {}
	if typeof(textOrInfo) == "table" then
		info = textOrInfo
	else
		info.Text = tostring(textOrInfo or "")
		info.Func = func or function() end
		info.Idx = idx
		info.Risky = false
		info.Disabled = false
		info.Visible = true
		info.DoubleClick = false
	end
	info = Validate(info, {
		Text = "",
		Func = function() end,
		Idx = nil,
		Risky = false,
		Disabled = false,
		Visible = true,
		DoubleClick = false,
		Tooltip = nil,
		DisabledTooltip = nil,
	})

	local gb = self

	local function buildSingleButton(parentFrame, bInfo)
		local widget = {
			Text = bInfo.Text,
			Func = bInfo.Func,
			Risky = bInfo.Risky,
			Disabled = bInfo.Disabled,
			Visible = bInfo.Visible,
			DoubleClick = bInfo.DoubleClick,
			Type = "Button",
			_tween = nil,
		}

		local base = Build("TextButton", {
			Active = not bInfo.Disabled,
			BackgroundColor3 = bInfo.Disabled and "Background" or "Surface",
			BackgroundTransparency = bInfo.Disabled and 0.80 or 0.38,
			Size = UDim2.new(1, 0, 0, 22),
			Text = "",
			Visible = bInfo.Visible,
			Parent = parentFrame,
		})
		Build("UICorner", { CornerRadius = UDim.new(0, 4), Parent = base })

		local stroke = Build("UIStroke", {
			Color = "Border",
			Transparency = bInfo.Disabled and 0.70 or 0.25,
			Parent = base,
		})

		local accentBar = Build("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = "Accent",
			BackgroundTransparency = bInfo.Disabled and 0.92 or 0.45,
			Position = UDim2.new(0, 4, 0.5, 0),
			Size = UDim2.fromOffset(2, 10),
			ZIndex = 2,
			Parent = base,
			DPIExclude = { Position = true, Size = true },
		})
		Build("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accentBar })

		local label = Build("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 3),
			Size = UDim2.new(1, -16, 0, 0),
			Text = bInfo.Text,
			TextColor3 = bInfo.Risky and Theme.Danger or Theme.Text,
			TextSize = 13,
			TextTransparency = bInfo.Disabled and 0.8 or 0.4,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = base,
		})
		if bInfo.Risky then
			Registry.BindColor(label, "TextColor3", "Danger")
		end

		label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local h = math.max(label.AbsoluteSize.Y + 6, 22)
			base.Size = UDim2.new(1, 0, 0, h)
			gb:Resize(false)
		end)
		task.defer(function()
			local h = math.max(label.AbsoluteSize.Y + 6, 22)
			base.Size = UDim2.new(1, 0, 0, h)
			gb:Resize(false)
		end)

		function widget:UpdateColors()
			Anim:Cancel(base)
			base.BackgroundColor3 = widget.Disabled and Theme.Background or Theme.Surface
			label.TextTransparency = widget.Disabled and 0.8 or 0.4
			stroke.Transparency = widget.Disabled and 0.5 or 0.0
			Registry.BindColor(base, "BackgroundColor3", widget.Disabled and "Background" or "Surface")
		end

		function widget:SetDisabled(dis)
			widget.Disabled = dis
			base.Active = not dis
			if widget.TooltipHandle then
				widget.TooltipHandle.disabled = dis
			end
			widget:UpdateColors()
		end

		function widget:SetVisible(vis)
			widget.Visible = vis
			base.Visible = vis
			gb:Resize(false)
		end

		function widget:SetText(text)
			widget.Text = text
			label.Text = text
		end

		base.MouseEnter:Connect(function()
			if widget.Disabled then
				return
			end
			Anim:Play(label, DEFAULT_FAST_TWEEN, { TextTransparency = 0 })
		end)
		base.MouseLeave:Connect(function()
			if widget.Disabled then
				return
			end
			Anim:Play(label, DEFAULT_FAST_TWEEN, { TextTransparency = 0.4 })
		end)

		local _locked = false
		base.MouseButton1Click:Connect(function()
			if widget.Disabled or _locked then
				return
			end
			if widget.DoubleClick then
				_locked = true
				label.Text = "Are you sure?"
				label.TextColor3 = Theme.Accent
				Registry.BindColor(label, "TextColor3", "Accent")

				local bind = Instance.new("BindableEvent")
				local conn = base.MouseButton1Click:Once(function()
					bind:Fire(true)
				end)
				task.delay(0.5, function()
					conn:Disconnect()
					bind:Fire(false)
				end)
				local clicked = bind.Event:Wait()
				bind:Destroy()

				label.Text = widget.Text
				label.TextColor3 = widget.Risky and Theme.Danger or Theme.Text
				Registry.BindColor(label, "TextColor3", widget.Risky and "Danger" or "Text")
				RunService.RenderStepped:Wait()
				_locked = false
				if clicked then
					Run(widget.Func)
				end
				return
			end
			Run(widget.Func)
		end)

		if typeof(bInfo.Tooltip) == "string" or typeof(bInfo.DisabledTooltip) == "string" then
			widget.TooltipHandle = AttachTooltip(base, bInfo.Tooltip, bInfo.DisabledTooltip)
			widget.TooltipHandle.disabled = widget.Disabled
		end

		widget.Base = base
		widget.Stroke = stroke
		widget:UpdateColors()
		return widget
	end

	-- Build the row holder
	local rowHolder = Build("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = gb.Container,
	})
	Build("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = UDim.new(0, 6),
		Parent = rowHolder,
	})

	local btn = buildSingleButton(rowHolder, info)

	function btn:AddButton(subInfo)
		if typeof(subInfo) == "string" then
			subInfo = { Text = subInfo, Func = func }
		end
		subInfo = Validate(subInfo, {
			Text = "",
			Func = function() end,
			Risky = false,
			Disabled = false,
			Visible = true,
			DoubleClick = false,
		})
		local subBtn = buildSingleButton(rowHolder, subInfo)
		btn.SubButton = subBtn
		gb:Resize(false)
		if subInfo.Idx then
			LRXUI.Buttons[subInfo.Idx] = subBtn
		else
			table.insert(LRXUI.Buttons, subBtn)
		end
		return subBtn
	end

	btn.Holder = rowHolder
	table.insert(gb.Elements, btn)
	gb:Resize(false)

	if info.Idx then
		LRXUI.Buttons[info.Idx] = btn
	else
		table.insert(LRXUI.Buttons, btn)
	end

	return btn
end

function GroupboxMeta:AddToggle(idx, info)
	info = Validate(info, {
		Text = "Toggle",
		Default = false,
		Risky = false,
		Disabled = false,
		Visible = true,
		Tooltip = nil,
		DisabledTooltip = nil,
		Callback = function() end,
		Changed = function() end,
	})

	local gb = self

	local widget = {
		Text = info.Text,
		Value = info.Default,
		Risky = info.Risky,
		Disabled = info.Disabled,
		Visible = info.Visible,
		Callback = info.Callback,
		Changed = info.Changed,
		Addons = {},
		Type = "Toggle",
	}

	local btn = Build("TextButton", {
		Active = not info.Disabled,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = "",
		Visible = info.Visible,
		Parent = gb.Container,
	})

	local textLabel = Build("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(1, -26, 1, 0),
		Text = info.Text,
		TextSize = 13,
		TextTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = btn,
		DPIExclude = { Position = true },
	})
	Build("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		Parent = textLabel,
	})

	local checkBox = Build("Frame", {
		BackgroundColor3 = "Surface",
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Parent = btn,
	})
	Build("UICorner", {
		CornerRadius = UDim.new(0, math.floor(Theme.Radius / 2)),
		Parent = checkBox,
	})
	local checkStroke = Build("UIStroke", { Color = "Border", Parent = checkBox })
	local checkMark = Build("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		Text = "✓",
		TextColor3 = "Text",
		TextSize = 11,
		TextTransparency = 1,
		Parent = checkBox,
		DPIExclude = { Size = true, Position = true },
	})

	function widget:_refresh()
		checkStroke.Transparency = widget.Disabled and 0.5 or 0

		if widget.Disabled then
			textLabel.TextTransparency = 0.8
			checkMark.TextTransparency = widget.Value and 0.8 or 1
			checkBox.BackgroundColor3 = Theme.Background
			Registry.BindColor(checkBox, "BackgroundColor3", "Background")
			return
		end

		Anim:Play(textLabel, DEFAULT_FAST_TWEEN, { TextTransparency = widget.Value and 0 or 0.4 })
		Anim:Play(checkMark, DEFAULT_FAST_TWEEN, { TextTransparency = widget.Value and 0 or 1 })
		checkBox.BackgroundColor3 = Theme.Surface
		Registry.BindColor(checkBox, "BackgroundColor3", "Surface")
	end

	function widget:OnChanged(fn)
		self.Changed = fn
	end

	function widget:SetValue(value)
		if widget.Disabled then
			return
		end
		widget.Value = value
		widget:_refresh()

		for _, addon in ipairs(widget.Addons) do
			if addon.Type == "KeyPicker" and addon.SyncToggleState then
				addon.Toggled = widget.Value
				addon:Update()
			end
		end

		Run(widget.Callback, widget.Value)
		Run(widget.Changed, widget.Value)
		LRXUI:_updateDependencyBoxes()
	end

	function widget:SetDisabled(dis)
		widget.Disabled = dis
		btn.Active = not dis
		if widget.TooltipHandle then
			widget.TooltipHandle.disabled = dis
		end
		for _, addon in ipairs(widget.Addons) do
			if addon.Type == "KeyPicker" and addon.SyncToggleState then
				addon:Update()
			end
		end
		widget:_refresh()
	end

	function widget:SetVisible(vis)
		widget.Visible = vis
		btn.Visible = vis
		gb:Resize(false)
	end

	function widget:SetText(text)
		widget.Text = text
		textLabel.Text = text
	end

	function widget:AddKeyPicker(kidx, kinfo)
		return BuildKeyPicker(self, kidx, kinfo)
	end
	function widget:AddColorPicker(cidx, cinfo)
		return BuildColorPicker(self, cidx, cinfo)
	end

	btn.MouseButton1Click:Connect(function()
		if widget.Disabled then
			return
		end
		widget:SetValue(not widget.Value)
	end)

	if typeof(info.Tooltip) == "string" or typeof(info.DisabledTooltip) == "string" then
		widget.TooltipHandle = AttachTooltip(btn, info.Tooltip, info.DisabledTooltip)
		widget.TooltipHandle.disabled = widget.Disabled
	end

	widget.TextLabel = textLabel
	widget.Holder = btn
	widget._groupbox = gb

	widget:_refresh()
	gb:Resize(false)
	table.insert(gb.Elements, widget)

	if idx then
		LRXUI.Toggles[idx] = widget
	else
		table.insert(LRXUI.Toggles, widget)
	end

	return widget
end

function GroupboxMeta:AddSlider(idx, info)
	info = Validate(info, {
		Text = "Slider",
		Default = 0,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Prefix = "",
		Suffix = "",
		Compact = false,
		HideMax = false,
		Disabled = false,
		Visible = true,
		Tooltip = nil,
		DisabledTooltip = nil,
		Callback = function() end,
		Changed = function() end,
	})

	local gb = self

	local widget = {
		Text = info.Text,
		Value = math.clamp(info.Default, info.Min, info.Max),
		Min = info.Min,
		Max = info.Max,
		Rounding = info.Rounding,
		Prefix = info.Prefix,
		Suffix = info.Suffix,
		Disabled = info.Disabled,
		Visible = info.Visible,
		Callback = info.Callback,
		Changed = info.Changed,
		Type = "Slider",
	}

	local holder = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, info.Text and 34 or 24),
		Visible = info.Visible,
		Parent = gb.Container,
		DPIExclude = { Size = true },
	})

	local sliderLabel
	if info.Text and not info.Compact then
		sliderLabel = Build("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Text = info.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = holder,
			DPIExclude = { Size = true },
		})
	end

	local bar = Build("TextButton", {
		Active = not info.Disabled,
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = "Background",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, info.Text and not info.Compact and 18 or 24),
		Text = "",
		Parent = holder,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = bar })

	local fill = Build("Frame", {
		BackgroundColor3 = "Accent",
		Size = UDim2.fromScale(0, 1),
		Parent = bar,
		DPIExclude = { Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })

	local displayLabel = Build("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextSize = 12,
		ZIndex = 2,
		Parent = bar,
	})
	Build("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Color = "Black",
		LineJoinMode = Enum.LineJoinMode.Miter,
		Parent = displayLabel,
	})

	function widget:_refresh()
		if sliderLabel then
			sliderLabel.TextTransparency = widget.Disabled and 0.8 or 0
		end
		displayLabel.TextTransparency = widget.Disabled and 0.8 or 0
		fill.BackgroundColor3 = widget.Disabled and Theme.Border or Theme.Accent
		Registry.BindColor(fill, "BackgroundColor3", widget.Disabled and "Border" or "Accent")
	end

	function widget:Display()
		local v = widget.Value
		local frac = (v - widget.Min) / math.max(widget.Max - widget.Min, 1e-9)
		fill.Size = UDim2.fromScale(frac, 1)

		if info.Compact then
			displayLabel.Text = ("%s: %s%s%s"):format(widget.Text, widget.Prefix, v, widget.Suffix)
		elseif info.HideMax then
			displayLabel.Text = ("%s%s%s"):format(widget.Prefix, v, widget.Suffix)
		else
			displayLabel.Text = ("%s%s%s/%s%s%s"):format(
				widget.Prefix,
				v,
				widget.Suffix,
				widget.Prefix,
				widget.Max,
				widget.Suffix
			)
		end
	end

	function widget:OnChanged(fn)
		self.Changed = fn
	end

	function widget:SetValue(raw)
		if widget.Disabled then
			return
		end
		local num = tonumber(raw)
		if not num then
			return
		end
		local clamped = Mth.Clamp(Mth.Round(num, widget.Rounding), widget.Min, widget.Max)
		widget.Value = clamped
		widget:Display()
		Run(widget.Callback, widget.Value)
		Run(widget.Changed, widget.Value)
	end

	function widget:SetMin(v)
		assert(v < widget.Max, "Min must be less than Max")
		widget.Min = v
		widget.Value = Mth.Clamp(widget.Value, v, widget.Max)
		widget:Display()
	end

	function widget:SetMax(v)
		assert(v > widget.Min, "Max must be greater than Min")
		widget.Max = v
		widget.Value = Mth.Clamp(widget.Value, widget.Min, v)
		widget:Display()
	end

	function widget:SetDisabled(dis)
		widget.Disabled = dis
		bar.Active = not dis
		if widget.TooltipHandle then
			widget.TooltipHandle.disabled = dis
		end
		widget:_refresh()
	end

	function widget:SetVisible(vis)
		widget.Visible = vis
		holder.Visible = vis
		gb:Resize(false)
	end

	function widget:SetText(text)
		widget.Text = text
		if sliderLabel then
			sliderLabel.Text = text
		else
			widget:Display()
		end
	end

	function widget:SetPrefix(p)
		widget.Prefix = p
		widget:Display()
	end
	function widget:SetSuffix(s)
		widget.Suffix = s
		widget:Display()
	end

	bar.InputBegan:Connect(function(inp)
		if not Input.IsClick(inp) or widget.Disabled then
			return
		end

		-- disable scroll while dragging
		if gb.Tab and gb.Tab.Sides then
			for _, side in pairs(gb.Tab.Sides) do
				pcall(function()
					side.ScrollingEnabled = false
				end)
			end
		end

		while Input.IsDrag(inp) do
			local scale = Mth.Clamp((Mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local old = widget.Value
			local raw = widget.Min + (widget.Max - widget.Min) * scale
			widget.Value = Mth.Clamp(Mth.Round(raw, widget.Rounding), widget.Min, widget.Max)
			widget:Display()
			if widget.Value ~= old then
				Run(widget.Callback, widget.Value)
				Run(widget.Changed, widget.Value)
			end
			RunService.RenderStepped:Wait()
		end

		if gb.Tab and gb.Tab.Sides then
			for _, side in pairs(gb.Tab.Sides) do
				pcall(function()
					side.ScrollingEnabled = true
				end)
			end
		end
	end)

	if typeof(info.Tooltip) == "string" or typeof(info.DisabledTooltip) == "string" then
		widget.TooltipHandle = AttachTooltip(bar, info.Tooltip, info.DisabledTooltip)
		widget.TooltipHandle.disabled = widget.Disabled
	end

	widget.Holder = holder
	widget._groupbox = gb

	widget:_refresh()
	widget:Display()
	gb:Resize(false)
	table.insert(gb.Elements, widget)

	if idx then
		LRXUI.Options[idx] = widget
	end

	return widget
end

function GroupboxMeta:AddTextbox(idx, info)
	info = Validate(info, {
		Text = "Textbox",
		Default = "",
		Placeholder = "",
		Numeric = false,
		ClearTextOnFocus = true,
		Finished = false,
		AllowEmpty = true,
		EmptyReset = "---",
		Disabled = false,
		Visible = true,
		Tooltip = nil,
		DisabledTooltip = nil,
		Callback = function() end,
		Changed = function() end,
	})

	local gb = self

	local widget = {
		Text = info.Text,
		Value = info.Default,
		Disabled = info.Disabled,
		Visible = info.Visible,
		Callback = info.Callback,
		Changed = info.Changed,
		Type = "Input",
	}

	local holder = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, info.Text and 44 or 26),
		Visible = info.Visible,
		Parent = gb.Container,
		DPIExclude = { Size = true },
	})

	if info.Text then
		Build("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Text = info.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = holder,
			DPIExclude = { Size = true },
		})
	end

	local inputBox = Build("TextBox", {
		Active = not info.Disabled,
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		ClearTextOnFocus = info.ClearTextOnFocus,
		PlaceholderText = info.Placeholder,
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 26),
		Text = info.Default,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius), Parent = inputBox })
	Build("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = inputBox,
	})

	function widget:SetValue(text)
		widget.Value = tostring(text or "")
		inputBox.Text = widget.Value
	end

	function widget:SetDisabled(dis)
		widget.Disabled = dis
		inputBox.Active = not dis
		inputBox.TextTransparency = dis and 0.6 or 0
		if widget.TooltipHandle then
			widget.TooltipHandle.disabled = dis
		end
	end

	function widget:SetVisible(vis)
		widget.Visible = vis
		holder.Visible = vis
		gb:Resize(false)
	end

	function widget:OnChanged(fn)
		self.Changed = fn
	end

	local function emit()
		local text = inputBox.Text
		if info.Numeric then
			local n = tonumber(text)
			if not n then
				inputBox.Text = tostring(widget.Value)
				return
			end
			text = tostring(n)
		end
		if not info.AllowEmpty and Str.Trim(text) == "" then
			inputBox.Text = info.EmptyReset
			return
		end
		widget.Value = text
		Run(widget.Callback, widget.Value)
		Run(widget.Changed, widget.Value)
	end

	inputBox.FocusLost:Connect(function(enter)
		if info.Finished and not enter then
			return
		end
		emit()
	end)
	if not info.Finished then
		inputBox:GetPropertyChangedSignal("Text"):Connect(function()
			if not inputBox:IsFocused() then
				return
			end
			Run(widget.Changed, inputBox.Text)
		end)
	end

	if typeof(info.Tooltip) == "string" or typeof(info.DisabledTooltip) == "string" then
		widget.TooltipHandle = AttachTooltip(inputBox, info.Tooltip, info.DisabledTooltip)
		widget.TooltipHandle.disabled = widget.Disabled
	end

	widget.Holder = holder
	widget._groupbox = gb

	gb:Resize(false)
	table.insert(gb.Elements, widget)

	if idx then
		LRXUI.Options[idx] = widget
	end

	return widget
end

function GroupboxMeta:AddDropdown(idx, info)
	info = Validate(info, {
		Text = nil,
		Values = {},
		DisabledValues = {},
		Multi = false,
		AllowNull = false,
		Searchable = false,
		Disabled = false,
		Visible = true,
		Tooltip = nil,
		DisabledTooltip = nil,
		Callback = function() end,
		Changed = function() end,
	})

	local gb = self

	local widget = {
		Text = info.Text,
		Value = info.Multi and {} or nil,
		Values = info.Values,
		DisabledValues = info.DisabledValues,
		Multi = info.Multi,
		AllowNull = info.AllowNull,
		Disabled = info.Disabled,
		Visible = info.Visible,
		Callback = info.Callback,
		Changed = info.Changed,
		Type = "Dropdown",
	}

	local function isSelected(v)
		if info.Multi then
			return widget.Value[v] == true
		end
		return widget.Value == v
	end

	local function activeCount()
		if info.Multi then
			local n = 0
			for _ in pairs(widget.Value) do
				n += 1
			end
			return n
		end
		return widget.Value ~= nil and 1 or 0
	end

	local holder = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, info.Text and 46 or 28),
		Visible = info.Visible,
		Parent = gb.Container,
		DPIExclude = { Size = true },
	})

	if info.Text then
		Build("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Text = info.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = holder,
			DPIExclude = { Size = true },
		})
	end

	local display = Build("TextButton", {
		Active = not info.Disabled,
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 28),
		Text = "---",
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius), Parent = display })
	Build("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 4),
		Parent = display,
	})

	local arrowLabel = Build("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Text = "▼",
		TextColor3 = "Text",
		TextTransparency = 0.5,
		TextSize = 10,
		ZIndex = 2,
		Parent = display,
		DPIExclude = { Position = true, Size = true },
	})

	-- Popup layer
	local blocker = Build("TextButton", {
		Active = true,
		AutoButtonColor = false,
		BackgroundColor3 = "Black",
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Visible = false,
		ZIndex = 119,
		Parent = RootGui,
		DPIExclude = { Size = true },
	})

	local popup = Build("Frame", {
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.56, 0.76),
		Visible = false,
		ZIndex = 120,
		Parent = RootGui,
		DPIExclude = { Position = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 4), Parent = popup })
	Build("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1.2,
		Transparency = 0.15,
		Color = Theme.Border:Lerp(Theme.Accent, 0.28),
		Parent = popup,
	})

	local popHeaderBg = Build("Frame", {
		BackgroundColor3 = "Background",
		BorderSizePixel = 0,
		ZIndex = 120,
		Parent = popup,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 4), Parent = popHeaderBg })
	local popHeaderLine = Build("Frame", {
		BackgroundColor3 = "Border",
		BorderSizePixel = 0,
		ZIndex = 121,
		Parent = popup,
		DPIExclude = { Position = true, Size = true },
	})

	local popBody = Build("Frame", {
		BackgroundColor3 = "Background",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		ZIndex = 121,
		Parent = popup,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 2), Parent = popBody })

	local popHeader = Build("Frame", {
		Active = true,
		BackgroundTransparency = 1,
		ZIndex = 122,
		Parent = popup,
		DPIExclude = { Position = true, Size = true },
	})
	local popTitle = Build("TextLabel", {
		BackgroundTransparency = 1,
		Text = widget.Text or "Select",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 123,
		Parent = popHeader,
		DPIExclude = { Size = true },
	})
	local popCloseBtn = Build("TextButton", {
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		Text = info.Multi and "Done" or "Close",
		ZIndex = 123,
		Parent = popHeader,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 1), Parent = popCloseBtn })
	local popCloseStroke = Build("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Transparency = 0.25,
		Parent = popCloseBtn,
	})

	local searchInput = Build("TextBox", {
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		PlaceholderText = "Search...",
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = info.Searchable == true,
		ZIndex = 123,
		Parent = popBody,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 1), Parent = searchInput })
	Build("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 8),
		Parent = searchInput,
	})

	local list = Build("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = "Surface",
		BorderColor3 = "Border",
		BorderSizePixel = 1,
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarImageColor3 = "Border",
		ScrollBarThickness = 4,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		ZIndex = 123,
		Parent = popBody,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 1), Parent = list })
	local listLayout = Build("UIListLayout", { Parent = list })

	local popScale = { W = 0.56, H = 0.76 }
	local rowH = 40
	local optTextSz = 14
	local entryTable = {}
	local popOpen = false

	local function applyPopupLayout()
		local vp = workspace.CurrentCamera.ViewportSize
		local portrait = vp.Y > vp.X
		local minW = portrait and 0.78 or 0.42
		local maxW = portrait and 0.96 or 0.82
		local minH = portrait and 0.48 or 0.52

		popScale.W = Mth.Clamp(popScale.W, minW, maxW)
		popScale.H = Mth.Clamp(popScale.H, minH, 0.90)

		local w, h = vp.X * popScale.W, vp.Y * popScale.H
		popup.Size = UDim2.fromScale(popScale.W, popScale.H)

		local padX = w * 0.036
		local padY = h * 0.03
		local headH = h * 0.08
		local searchH = h * 0.085
		local gap = h * 0.018
		local closeH = math.floor(headH * 0.72)
		local closeW = math.max(78, math.floor(closeH * 2.05))

		popHeader.Position = UDim2.fromOffset(padX, padY)
		popHeader.Size = UDim2.new(1, -padX * 2, 0, headH)

		popTitle.Position = UDim2.fromOffset(0, 0)
		popTitle.Size = UDim2.new(1, -(closeW + 12), 1, 0)
		popTitle.TextSize = math.clamp(math.floor(h * 0.038), 13, 22)

		popCloseBtn.Size = UDim2.fromOffset(closeW, closeH)
		popCloseBtn.Position = UDim2.new(1, -closeW, 0.5, -math.floor(closeH / 2))
		popCloseBtn.TextSize = math.max(12, math.clamp(math.floor(h * 0.031), 12, 18) - 1)

		popHeaderBg.Position = UDim2.fromOffset(0, 0)
		popHeaderBg.Size = UDim2.new(1, 0, 0, padY + headH + gap * 0.65)
		popHeaderLine.Position = UDim2.fromOffset(0, math.floor(padY + headH + gap * 0.65))
		popHeaderLine.Size = UDim2.new(1, 0, 0, 1)

		local bodyTop = math.floor(padY + headH + gap + 2)
		popBody.Position = UDim2.fromOffset(padX, bodyTop)
		popBody.Size = UDim2.new(1, -padX * 2, 1, -(bodyTop + padY))

		local ix = math.max(10, math.floor(padX * 0.7))
		local iy = math.max(10, math.floor(padY * 0.65))

		if searchInput.Visible then
			searchInput.Position = UDim2.fromOffset(ix, iy)
			searchInput.Size = UDim2.new(1, -ix * 2, 0, searchH)
			searchInput.TextSize = math.clamp(math.floor(h * 0.031), 12, 18)
			local listTop = iy + searchH + gap
			list.Position = UDim2.fromOffset(ix, listTop)
			list.Size = UDim2.new(1, -ix * 2, 1, -(listTop + iy))
		else
			list.Position = UDim2.fromOffset(ix, iy)
			list.Size = UDim2.new(1, -ix * 2, 1, -iy * 2)
		end

		rowH = Mth.Clamp(h * 0.078, 30, 52)
		optTextSz = Mth.Clamp(math.floor(h * 0.027), 12, 17)
		listLayout.Padding = UDim.new(0, math.max(4, math.floor(gap * 0.45)))

		for btn, entry in pairs(entryTable) do
			btn.Size = UDim2.new(1, -8, 0, rowH)
			btn.TextSize = optTextSz
		end
	end

	local function buildOrderedValues(query)
		local selected, rest = {}, {}
		for _, v in ipairs(widget.Values) do
			local text = tostring(v)
			if query ~= "" and not text:lower():find(query, 1, true) then
				continue
			end
			if isSelected(v) then
				table.insert(selected, v)
			else
				table.insert(rest, v)
			end
		end
		for _, v in ipairs(rest) do
			table.insert(selected, v)
		end
		return selected
	end

	local function updateDisplay()
		if widget.Value == nil or (info.Multi and next(widget.Value) == nil) then
			display.Text = "---"
			return
		end
		if info.Multi then
			local parts = {}
			for v in pairs(widget.Value) do
				table.insert(parts, tostring(v))
			end
			display.Text = table.concat(parts, ", ")
		else
			display.Text = tostring(widget.Value)
		end
	end

	local function refreshButtons()
		for btn, entry in pairs(entryTable) do
			local sel = isSelected(entry.value)
			local disabled = Tbl.Contains(widget.DisabledValues, entry.value)
			btn.BackgroundTransparency = sel and 0.5 or 1
			btn.BackgroundColor3 = Theme.Surface:Lerp(Theme.Accent, 0.15)
			btn.TextTransparency = disabled and 0.8 or (sel and 0.04 or 0.45)
		end
	end

	local function rebuildList(query)
		for btn in pairs(entryTable) do
			btn:Destroy()
		end
		table.clear(entryTable)

		local values = buildOrderedValues(query or "")
		for i, v in ipairs(values) do
			local disabled = Tbl.Contains(widget.DisabledValues, v)
			local btn = Build("TextButton", {
				BackgroundColor3 = "Surface",
				BackgroundTransparency = isSelected(v) and 0.5 or 1,
				LayoutOrder = i,
				Size = UDim2.new(1, -8, 0, rowH),
				Text = tostring(v),
				TextSize = optTextSz,
				TextTransparency = disabled and 0.8 or (isSelected(v) and 0.04 or 0.45),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 123,
				Parent = list,
				DPIExclude = { Size = true },
			})
			Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius + 1), Parent = btn })
			Build("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 10),
				Parent = btn,
			})

			entryTable[btn] = { value = v, disabled = disabled }

			btn.MouseButton1Click:Connect(function()
				local entry = entryTable[btn]
				if not entry or entry.disabled or widget.Disabled then
					return
				end

				if not isSelected(v) or activeCount() > 1 or info.AllowNull then
					if info.Multi then
						widget.Value[v] = not isSelected(v) and true or nil
					else
						widget.Value = not isSelected(v) and v or nil
					end
					updateDisplay()
					refreshButtons()
					Run(widget.Callback, widget.Value)
					Run(widget.Changed, widget.Value)
					LRXUI:_updateDependencyBoxes()
					if not info.Multi then
						closePopup()
					end
				end
			end)

			btn:GetPropertyChangedSignal("BackgroundColor3"):Connect(function() end) -- keep binding active
		end
	end

	local function openPopup()
		if popOpen then
			return
		end
		popOpen = true
		blocker.Visible = true
		popup.Visible = true
		applyPopupLayout()
		rebuildList("")
		AttachDraggable(popup, popHeader, true)
	end

	local function closePopup()
		if not popOpen then
			return
		end
		popOpen = false
		blocker.Visible = false
		popup.Visible = false
		for btn in pairs(entryTable) do
			btn:Destroy()
		end
		table.clear(entryTable)
		if InputService:GetFocusedTextBox() == searchInput then
			pcall(function()
				searchInput:ReleaseFocus()
			end)
		end
	end

	function widget:Display()
		updateDisplay()
	end

	function widget:UpdateColors()
		display.BackgroundColor3 = widget.Disabled and Theme.Background or Theme.Surface
		display.TextTransparency = widget.Disabled and 0.6 or 0
		Registry.BindColor(display, "BackgroundColor3", widget.Disabled and "Background" or "Surface")
	end

	function widget:SetValue(value)
		if info.Multi then
			widget.Value = {}
			if typeof(value) == "table" then
				for _, v in ipairs(value) do
					widget.Value[v] = true
				end
			end
		else
			widget.Value = value
		end
		updateDisplay()
		Run(widget.Callback, widget.Value)
		Run(widget.Changed, widget.Value)
		LRXUI:_updateDependencyBoxes()
	end

	function widget:SetValues(newValues)
		widget.Values = newValues
		if popOpen then
			rebuildList("")
		end
	end

	function widget:SetDisabled(dis)
		widget.Disabled = dis
		display.Active = not dis
		if widget.TooltipHandle then
			widget.TooltipHandle.disabled = dis
		end
		widget:UpdateColors()
	end

	function widget:SetVisible(vis)
		widget.Visible = vis
		holder.Visible = vis
		gb:Resize(false)
	end

	function widget:OnChanged(fn)
		self.Changed = fn
	end

	function widget:GetActiveValues()
		return activeCount()
	end

	display.MouseButton1Click:Connect(function()
		if widget.Disabled then
			return
		end
		openPopup()
	end)
	blocker.MouseButton1Click:Connect(closePopup)
	popCloseBtn.MouseButton1Click:Connect(closePopup)

	if info.Searchable then
		searchInput:GetPropertyChangedSignal("Text"):Connect(function()
			rebuildList(searchInput.Text:lower())
		end)
	end

	RootGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if popOpen then
			applyPopupLayout()
		end
	end)

	if typeof(info.Tooltip) == "string" or typeof(info.DisabledTooltip) == "string" then
		widget.TooltipHandle = AttachTooltip(display, info.Tooltip, info.DisabledTooltip)
		widget.TooltipHandle.disabled = widget.Disabled
	end

	widget.Holder = holder
	widget._groupbox = gb

	widget:UpdateColors()
	widget:Display()
	gb:Resize(false)
	table.insert(gb.Elements, widget)

	if idx then
		LRXUI.Options[idx] = widget
	end

	return widget
end

-- Forward compatibility: alias AddCheckbox → AddToggle
GroupboxMeta.AddCheckbox = GroupboxMeta.AddToggle

-- Dependency box setup (groupbox with conditional visibility)
function GroupboxMeta:SetupDependencies(deps)
	for _, dep in ipairs(deps) do
		assert(dep[1] ~= nil, "Dependency missing element reference.")
		assert(dep[2] ~= nil, "Dependency missing expected value.")
	end
	self.Dependencies = deps
	self:_updateVisibility()
end

function GroupboxMeta:_updateVisibility()
	if not self.Dependencies then
		return
	end

	local allMet = true
	for _, dep in ipairs(self.Dependencies) do
		local element = dep[1]
		local expected = dep[2]
		local current = element.Value
		if typeof(expected) == "boolean" then
			if current ~= expected then
				allMet = false
				break
			end
		elseif typeof(expected) == "string" then
			if info.Multi then
				if not current[expected] then
					allMet = false
					break
				end
			else
				if current ~= expected then
					allMet = false
					break
				end
			end
		end
	end

	self.Holder.Visible = allMet
	if allMet then
		self:Resize(false)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  TAB SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local function _createTab(tabButton, windowRadius)
	local tab = {
		Button = tabButton,
		Groupboxes = {},
		DependencyGroupboxes = {},
		Sides = {},
		IsKeyTab = false,
	}

	local tabFrame = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = RootGui, -- will be reparented during window setup
	})

	local leftSide = Build("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 0,
		Size = UDim2.fromScale(0.5, 1),
		Parent = tabFrame,
		DPIExclude = { Size = true },
	})
	Build("UIListLayout", { Padding = UDim.new(0, 8), Parent = leftSide })
	Build("UIPadding", {
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 8),
		Parent = leftSide,
	})

	local rightSide = Build("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.fromOffset(0, 0),
		Position = UDim2.fromScale(1, 0),
		ScrollBarThickness = 0,
		Size = UDim2.fromScale(0.5, 1),
		Parent = tabFrame,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UIListLayout", { Padding = UDim.new(0, 8), Parent = rightSide })
	Build("UIPadding", {
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		Parent = rightSide,
	})

	tab.Frame = tabFrame
	tab.LeftSide = leftSide
	tab.RightSide = rightSide
	tab.Sides = { leftSide, rightSide }

	function tab:AddGroupbox(groupInfo)
		if typeof(groupInfo) == "string" then
			groupInfo = { Name = groupInfo, Side = 1 }
		end
		groupInfo = Validate(groupInfo, {
			Name = "Group",
			Side = 1,
			StartCollapsed = false,
			Description = nil,
			IconName = nil,
		})

		local column = (groupInfo.Side == 2) and rightSide or leftSide
		local gb = _createGroupbox(tab, column, groupInfo, windowRadius)
		gb._groupbox = gb
		self.Groupboxes[groupInfo.Name] = gb
		return gb
	end

	function tab:AddLeftGroupbox(nameOrInfo)
		if typeof(nameOrInfo) == "string" then
			nameOrInfo = { Name = nameOrInfo }
		end
		nameOrInfo.Side = 1
		return tab:AddGroupbox(nameOrInfo)
	end

	function tab:AddRightGroupbox(nameOrInfo)
		if typeof(nameOrInfo) == "string" then
			nameOrInfo = { Name = nameOrInfo }
		end
		nameOrInfo.Side = 2
		return tab:AddGroupbox(nameOrInfo)
	end

	function tab:Show()
		tabFrame.Visible = true
	end

	function tab:Hide()
		tabFrame.Visible = false
	end

	return tab
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SEARCH ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local _searchText = ""
local _isSearching = false
local _lastSearchTab = nil

local function _runSearch(searchStr, activeTab)
	_searchText = searchStr
	local query = Str.Trim(searchStr:lower())

	-- Restore previous tab first
	if _lastSearchTab and _lastSearchTab ~= activeTab then
		for _, gb in pairs(_lastSearchTab.Groupboxes) do
			for _, elem in ipairs(gb.Elements) do
				if typeof(elem.Visible) == "boolean" then
					elem.Holder.Visible = elem.Visible
				end
			end
			gb.Holder.Visible = true
			gb:Resize(false)
		end
	end

	if query == "" then
		_isSearching = false
		_lastSearchTab = nil
		return
	end

	_isSearching = true
	_lastSearchTab = activeTab

	for _, gb in pairs(activeTab.Groupboxes) do
		local visible = 0
		for _, elem in ipairs(gb.Elements) do
			if elem.Type == "Divider" or elem.Type == "Spacer" then
				elem.Holder.Visible = false
				continue
			end
			local text = elem.Text or ""
			local match = text:lower():find(query, 1, true) and elem.Visible
			elem.Holder.Visible = match and true or false
			if match then
				visible += 1
			end
		end
		gb.Holder.Visible = visible > 0
		if visible > 0 then
			gb:Resize(false)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  WINDOW CLASS
-- ═══════════════════════════════════════════════════════════════════════════

function LRXUI:CreateWindow(windowInfo)
	windowInfo = Validate(windowInfo or {}, {
		Title = "LRXUI",
		Footer = "",
		Size = UDim2.fromOffset(720, 580),
		Center = true,
		Resizable = true,
		CornerRadius = 4,
		Font = Enum.Font.Code,
		ToggleKeybind = Enum.KeyCode.RightControl,
		NotifySide = "Right",
		ShowCustomCursor = false,
		DisableSearch = false,
		AutoShow = true,
		Icon = nil,
	})

	-- Apply window-level settings
	Theme.Radius = windowInfo.CornerRadius
	_isVisible = windowInfo.AutoShow

	if typeof(windowInfo.Font) == "EnumItem" then
		Theme.Font = Font.fromEnum(windowInfo.Font)
	elseif typeof(windowInfo.Font) == "Font" then
		Theme.Font = windowInfo.Font
	end

	LRXUI.ToggleKeybind = windowInfo.ToggleKeybind

	-- Clamp size to viewport
	local vp = workspace.CurrentCamera.ViewportSize
	if vp.X <= 5 and vp.Y <= 5 then
		repeat
			vp = workspace.CurrentCamera.ViewportSize
			task.wait()
		until vp.X > 5
	end

	local function clampSize(sz)
		return UDim2.fromOffset(
			Mth.Clamp(sz.X.Offset, Platform.MinSize.X, vp.X - 64),
			Mth.Clamp(sz.Y.Offset, Platform.MinSize.Y, vp.Y - 64)
		)
	end

	windowInfo.Size = clampSize(windowInfo.Size)

	-- Notify side
	local function applyNotifySide(side)
		_notifSide = side
		if side:lower() == "left" then
			NotifArea.AnchorPoint = Vector2.new(0, 0)
			NotifArea.Position = UDim2.fromOffset(6, 6)
			NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		else
			NotifArea.AnchorPoint = Vector2.new(1, 0)
			NotifArea.Position = UDim2.new(1, -6, 0, 6)
			NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		end
	end
	pcall(applyNotifySide, windowInfo.NotifySide)

	-- Main frame
	local mainFrame = Build("Frame", {
		BackgroundColor3 = function()
			return Theme:Shade(Theme.Background, -1)
		end,
		Name = "LRXUIWindow",
		Position = windowInfo.Center
				and UDim2.new(0.5, -windowInfo.Size.X.Offset / 2, 0.5, -windowInfo.Size.Y.Offset / 2)
			or UDim2.fromOffset(6, 6),
		Size = windowInfo.Size,
		Visible = false,
		Active = true,
		Parent = RootGui,
		DPIExclude = { Position = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius - 1), Parent = mainFrame })

	-- Structural lines
	MakeDividerLine(mainFrame, UDim2.fromOffset(0, 48), UDim2.new(1, 0, 0, 1))
	MakeDividerLine(mainFrame, UDim2.fromScale(0.3, 0), UDim2.new(0, 1, 1, -21))
	MakeDividerLine(mainFrame, UDim2.new(0, 0, 1, -20), UDim2.new(1, 0, 0, 1))
	MakeOutlineFrame(mainFrame, Theme.Radius, 0)

	-- Top bar
	local topBar = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 48),
		Parent = mainFrame,
		DPIExclude = { Size = true },
	})
	AttachDraggable(mainFrame, topBar, false, true)

	-- Title area
	local titleHolder = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.3, 1),
		Parent = topBar,
		DPIExclude = { Size = true },
	})
	Build("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = titleHolder,
	})
	local titleW = TextMeasure.Bounds(windowInfo.Title, Theme.Font, 19, titleHolder.AbsoluteSize.X - 12)
	Build("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, titleW, 1, 0),
		Text = windowInfo.Title,
		TextSize = 19,
		Parent = titleHolder,
		DPIExclude = { Size = true },
	})

	-- Right bar (search + tab info)
	local rightBar = Build("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.3, 8, 0.5, 0),
		Size = UDim2.new(0.7, -57, 1, -16),
		Parent = topBar,
		DPIExclude = { Position = true, Size = true },
	})
	Build("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = rightBar,
	})

	local searchBox
	if not windowInfo.DisableSearch then
		searchBox = Build("TextBox", {
			BackgroundColor3 = "Surface",
			PlaceholderText = "Search...",
			Size = UDim2.fromScale(1, 1),
			TextScaled = true,
			Parent = rightBar,
			DPIExclude = { Size = true },
		})
		Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius), Parent = searchBox })
		Build("UIPadding", {
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			Parent = searchBox,
		})
		Build("UIStroke", { Color = "Border", Parent = searchBox })
	end

	-- Tab button bar
	local tabBar = Build("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.fromScale(0.3, 1),
		Parent = topBar,
		DPIExclude = { Position = true, Size = true },
	})

	-- Content area
	local contentArea = Build("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -68),
		Parent = mainFrame,
		DPIExclude = { Position = true, Size = true },
	})

	-- Tab list (left sidebar)
	local tabList = Build("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.3, 1),
		Parent = contentArea,
		DPIExclude = { Size = true },
	})
	Build("UIListLayout", { Padding = UDim.new(0, 2), Parent = tabList })
	Build("UIPadding", {
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		Parent = tabList,
	})

	-- Main content pane (right of tab list)
	local pane = Build("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.7, 1),
		Parent = contentArea,
		DPIExclude = { Position = true, Size = true },
	})

	-- Footer
	local footer = Build("TextLabel", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 20),
		Text = windowInfo.Footer,
		TextSize = 12,
		TextTransparency = 0.5,
		Parent = mainFrame,
		DPIExclude = { Position = true, Size = true },
	})

	-- Resize handle
	if windowInfo.Resizable then
		local resizeHandle = Build("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			AutoButtonColor = false,
			BackgroundColor3 = "Surface",
			BorderColor3 = "Border",
			BorderSizePixel = 1,
			Position = UDim2.fromScale(1, 1),
			Size = UDim2.fromOffset(18, 18),
			Text = "⇲",
			TextSize = 10,
			ZIndex = 5,
			Parent = mainFrame,
			DPIExclude = { Position = true, Size = true },
		})
		Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = resizeHandle })
		AttachResizable(mainFrame, resizeHandle)
	end

	-- Show window
	if windowInfo.AutoShow then
		mainFrame.Visible = true
	end

	-- Tab management
	local tabs = {}
	local activeTab = nil

	local function activateTab(tab)
		if activeTab then
			activeTab:Hide()
			activeTab.Button.BackgroundTransparency = 1
			activeTab.Button.TextTransparency = 0.4
		end
		activeTab = tab
		tab:Show()
		tab.Button.BackgroundTransparency = 0
		tab.Button.TextTransparency = 0
		if _isSearching then
			_runSearch("", activeTab)
		end
	end

	local window = {}

	function window:AddTab(nameOrInfo)
		if typeof(nameOrInfo) == "string" then
			nameOrInfo = { Title = nameOrInfo }
		end
		local tabInfo = Validate(nameOrInfo, {
			Title = "Tab",
			Description = nil,
		})

		local tabBtn = Build("TextButton", {
			BackgroundColor3 = "Surface",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 28),
			Text = tabInfo.Title,
			TextSize = 13,
			TextTransparency = 0.4,
			Parent = tabList,
			DPIExclude = { Size = true },
		})
		Build("UICorner", { CornerRadius = UDim.new(0, 3), Parent = tabBtn })

		local tab = _createTab(tabBtn, Theme.Radius)
		tab.Frame.Parent = pane

		tabBtn.MouseButton1Click:Connect(function()
			activateTab(tab)
			if searchBox then
				searchBox.Text = ""
			end
		end)

		tabBtn.MouseEnter:Connect(function()
			if activeTab == tab then
				return
			end
			Anim:Play(tabBtn, DEFAULT_FAST_TWEEN, { TextTransparency = 0.1 })
		end)
		tabBtn.MouseLeave:Connect(function()
			if activeTab == tab then
				return
			end
			Anim:Play(tabBtn, DEFAULT_FAST_TWEEN, { TextTransparency = 0.4 })
		end)

		table.insert(tabs, tab)
		table.insert(LRXUI.Tabs, tab)

		if not activeTab then
			activateTab(tab)
		end

		return tab
	end

	-- Search wiring
	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if activeTab then
				_runSearch(searchBox.Text, activeTab)
			end
		end)
	end

	-- Toggle keybind
	_globalConns:Add(InputService.InputBegan:Connect(function(inp, processed)
		if processed then
			return
		end
		if inp.KeyCode == LRXUI.ToggleKeybind then
			_isVisible = not _isVisible
			mainFrame.Visible = _isVisible
			Cursor.Visible = _isVisible and windowInfo.ShowCustomCursor
		end
	end))

	-- Custom cursor
	if windowInfo.ShowCustomCursor then
		_globalConns:Add(RunService.RenderStepped:Connect(function()
			if not _isVisible then
				return
			end
			Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
		end))
	end

	function window:Show()
		mainFrame.Visible = true
		_isVisible = true
	end
	function window:Hide()
		mainFrame.Visible = false
		_isVisible = false
	end

	function window:SetTitle(text)
		-- find and update title label
		for _, child in pairs(titleHolder:GetChildren()) do
			if child:IsA("TextLabel") then
				child.Text = text
				break
			end
		end
	end

	function window:SetFooter(text)
		footer.Text = text
	end

	return window
end

-- ═══════════════════════════════════════════════════════════════════════════
--  LRXUI STATE & PUBLIC TABLES
-- ═══════════════════════════════════════════════════════════════════════════

LRXUI.Labels = {}
LRXUI.Buttons = {}
LRXUI.Toggles = {}
LRXUI.Options = {}
LRXUI.Tabs = {}
LRXUI.ToggleKeybind = Enum.KeyCode.RightControl

LRXUI._dependencyBoxes = {}

function LRXUI:_updateDependencyBoxes()
	for _, depBox in ipairs(self._dependencyBoxes) do
		if depBox._updateVisibility then
			depBox:_updateVisibility()
		end
	end
	if _isSearching and _lastSearchTab then
		_runSearch(_searchText, _lastSearchTab)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PUBLIC API — NOTIFICATION
-- ═══════════════════════════════════════════════════════════════════════════

function LRXUI:Notify(dataOrText, time, soundId)
	local data = {}
	if typeof(dataOrText) == "table" then
		data = dataOrText
	else
		data.Description = tostring(dataOrText)
		data.Time = time or 5
		data.SoundId = soundId
	end
	data.Time = data.Time or 5
	return _createNotification(data)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PUBLIC API — DIALOGS
-- ═══════════════════════════════════════════════════════════════════════════

function LRXUI:Dialog(info)
	return CreateDialog(info)
end

function LRXUI:Confirm(titleOrInfo, description, callback)
	local info = typeof(titleOrInfo) == "table" and titleOrInfo
		or {
			Title = titleOrInfo or "Confirm",
			Description = description or "",
			Callback = callback,
		}
	info.Type = "confirm"
	return CreateDialog(info)
end

function LRXUI:InfoPopup(titleOrInfo, description, callback)
	local info = typeof(titleOrInfo) == "table" and titleOrInfo
		or {
			Title = titleOrInfo or "Info",
			Description = description or "",
			Callback = callback,
		}
	info.Type = "info"
	return CreateDialog(info)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PUBLIC API — WATERMARK
-- ═══════════════════════════════════════════════════════════════════════════

function LRXUI:SetWatermark(text)
	_watermarkLabel.Text = tostring(text)
	_resizeWatermark()
end

function LRXUI:SetWatermarkVisible(visible)
	_watermarkOuter.Visible = visible
	if visible then
		_resizeWatermark()
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PUBLIC API — THEME
-- ═══════════════════════════════════════════════════════════════════════════

function LRXUI:SetAccentColor(color)
	Theme.Accent = color
	Registry.ApplyColors()
end

function LRXUI:SetFont(fontFace)
	if typeof(fontFace) == "EnumItem" then
		fontFace = Font.fromEnum(fontFace)
	end
	Theme.Font = fontFace
	Registry.ApplyColors()
end

function LRXUI:SetTheme(overrides)
	for key, value in pairs(overrides) do
		if Theme[key] ~= nil then
			Theme[key] = value
		end
	end
	Registry.ApplyColors()
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PUBLIC API — DPI SCALING
-- ═══════════════════════════════════════════════════════════════════════════

function LRXUI:SetDPIScale(scale)
	_dpiScale = scale / 100
	Platform.MinSize = Platform.MinSize * _dpiScale
	Registry.ApplyDPI(_dpiScale)

	for _, tab in ipairs(LRXUI.Tabs) do
		for _, gb in pairs(tab.Groupboxes) do
			gb:Resize(false)
		end
	end

	for _, notif in pairs(_liveNotifs) do
		if notif.Resize then
			notif:Resize()
		end
	end

	_updateKeybindPanelWidth()
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PUBLIC API — NOTIFY SIDE
-- ═══════════════════════════════════════════════════════════════════════════

function LRXUI:SetNotifySide(side)
	_notifSide = side
	if side:lower() == "left" then
		NotifArea.AnchorPoint = Vector2.new(0, 0)
		NotifArea.Position = UDim2.fromOffset(6, 6)
		NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	else
		NotifArea.AnchorPoint = Vector2.new(1, 0)
		NotifArea.Position = UDim2.new(1, -6, 0, 6)
		NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PUBLIC API — UNLOAD
-- ═══════════════════════════════════════════════════════════════════════════

local _unloadCallbacks = {}

function LRXUI:OnUnload(fn)
	table.insert(_unloadCallbacks, fn)
end

function LRXUI:Unload()
	_globalConns:DisconnectAll()
	for _, fn in ipairs(_unloadCallbacks) do
		Run(fn)
	end
	pcall(function()
		RootGui:Destroy()
	end)
	pcall(function()
		ModalGui:Destroy()
	end)
	if getgenv then
		pcall(function()
			getgenv().LRXUI = nil
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PUBLIC API — DRAGGABLE BUTTON / MENU HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

function LRXUI:AddDraggableButton(text, callback)
	local handle = {}

	local btn = Build("TextButton", {
		BackgroundColor3 = "Background",
		Position = UDim2.fromOffset(6, 6),
		TextSize = 15,
		ZIndex = 10,
		Parent = RootGui,
		DPIExclude = { Position = true },
	})
	Build("UICorner", { CornerRadius = UDim.new(0, Theme.Radius - 1), Parent = btn })
	MakeOutlineFrame(btn, Theme.Radius, 9)

	handle.Button = btn
	btn.MouseButton1Click:Connect(function()
		Run(callback, handle)
	end)
	AttachDraggable(btn, btn, true)

	function handle:SetText(newText)
		local x, y = TextMeasure.Bounds(newText, Theme.Font, 15)
		btn.Text = newText
		btn.Size = UDim2.fromOffset(x * _dpiScale * 2, y * _dpiScale * 2)
	end

	handle:SetText(text)
	return handle
end

function LRXUI:AddDraggableMenu(title)
	local panel, container = CreateDraggablePanel(title)
	panel.Parent = RootGui
	return panel, container
end

-- ═══════════════════════════════════════════════════════════════════════════
--  REGISTER ON GLOBAL (optional)
-- ═══════════════════════════════════════════════════════════════════════════

if getgenv then
	pcall(function()
		getgenv().LRXUI = LRXUI
	end)
end

return LRXUI
