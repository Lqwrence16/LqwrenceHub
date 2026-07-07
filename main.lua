--[[
================================================================================
    __    ____  _  ___  ______
   / /   / __ \ | |/ / / /  _/
  / /   / /_/ / |   / / /  /  
 / /___/ _, _/ /   | / /__/ /   
/_____/_/ |_| /_/|_| \____/   LRXUI Desktop UI Framework (Optimized Cored)
                              Version 1.0.0
================================================================================
    Description:
        A production-grade, highly-optimized desktop UI framework for Roblox.
        Recreated to be ultra-clean, completely self-contained, and free of 
        overly long icon dictionaries, while preserving 100% of the functional
        core library capabilities.
        
    Features:
        - Dynamic Reactive Theme Engine (with Nordic, Slate, and Amber presets)
        - Unified Object Factory (centralized instance builder)
        - Conflicting Tween Auto-Cancellation & Safe Signal Cleanups
        - Fully Draggable and Resizable Windows
        - Staggered Notification Toasts & Interactive Modal Prompts
        - Comprehensive control widgets (Buttons, Toggles, Sliders, Dropdowns, etc.)
================================================================================
]]

local cloneref = (cloneref or clonereference or function(instance: any)
	return instance
end)

--==============================================================================
-- 1. SERVICES & CORE GLOBALS
--==============================================================================
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local SoundService = cloneref(game:GetService("SoundService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local TweenService = cloneref(game:GetService("TweenService"))

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

--==============================================================================
-- 2. DYNAMIC THEME SYSTEM (REACTIVE ENGINE)
--==============================================================================
local LRXUI = {
	CurrentTheme = "DarkSlate",
	Themes = {
		DarkSlate = {
			Background = Color3.fromRGB(15, 17, 22),
			Sidebar = Color3.fromRGB(21, 23, 29),
			Content = Color3.fromRGB(18, 20, 25),
			Surface = Color3.fromRGB(29, 32, 39),
			SurfaceHover = Color3.fromRGB(37, 40, 48),
			Border = Color3.fromRGB(53, 57, 67),
			Text = Color3.fromRGB(255, 255, 255),
			SubText = Color3.fromRGB(170, 170, 175),
			Muted = Color3.fromRGB(120, 120, 125),
			Accent = Color3.fromRGB(88, 166, 255),
			Success = Color3.fromRGB(60, 210, 120),
			Warning = Color3.fromRGB(255, 195, 90),
			Danger = Color3.fromRGB(255, 90, 90),
			Scrollbar = Color3.fromRGB(70, 74, 82),
		},
		NordicFrost = {
			Background = Color3.fromRGB(43, 48, 59),
			Sidebar = Color3.fromRGB(59, 66, 82),
			Content = Color3.fromRGB(46, 52, 64),
			Surface = Color3.fromRGB(76, 86, 106),
			SurfaceHover = Color3.fromRGB(94, 108, 132),
			Border = Color3.fromRGB(143, 188, 187),
			Text = Color3.fromRGB(236, 239, 244),
			SubText = Color3.fromRGB(216, 222, 233),
			Muted = Color3.fromRGB(163, 190, 140),
			Accent = Color3.fromRGB(136, 192, 208),
			Success = Color3.fromRGB(163, 190, 140),
			Warning = Color3.fromRGB(235, 203, 139),
			Danger = Color3.fromRGB(191, 97, 106),
			Scrollbar = Color3.fromRGB(129, 161, 193),
		},
		AmberGold = {
			Background = Color3.fromRGB(18, 13, 8),
			Sidebar = Color3.fromRGB(28, 20, 12),
			Content = Color3.fromRGB(23, 16, 10),
			Surface = Color3.fromRGB(43, 30, 18),
			SurfaceHover = Color3.fromRGB(56, 39, 23),
			Border = Color3.fromRGB(82, 58, 35),
			Text = Color3.fromRGB(250, 245, 235),
			SubText = Color3.fromRGB(210, 195, 175),
			Muted = Color3.fromRGB(150, 135, 115),
			Accent = Color3.fromRGB(245, 158, 11),
			Success = Color3.fromRGB(52, 211, 153),
			Warning = Color3.fromRGB(251, 191, 36),
			Danger = Color3.fromRGB(239, 68, 68),
			Scrollbar = Color3.fromRGB(120, 90, 60),
		},
	},
	Registry = {}, -- Tracks: { [Instance] = { [PropertyName] = ThemeKey } }
	Connections = {},
	UnloadSignals = {},
	ActiveWindows = {},
	OpenPopups = {},
}

function LRXUI:SetTheme(themeName: string)
	if not self.Themes[themeName] then
		return
	end
	self.CurrentTheme = themeName
	local activeColors = self.Themes[themeName]

	for instance, bindings in pairs(self.Registry) do
		pcall(function()
			for propName, themeKey in pairs(bindings) do
				instance[propName] = activeColors[themeKey]
			end
		end)
	end
end

function LRXUI:BindTheme(instance: Instance, propertyBindings: { [string]: string })
	if not self.Registry[instance] then
		self.Registry[instance] = {}
		-- Auto unbind when instance is destroyed
		local destroyedConn
		destroyedConn = instance.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				self.Registry[instance] = nil
				if destroyedConn then
					destroyedConn:Disconnect()
				end
			end
		end)
		table.insert(self.Connections, destroyedConn)
	end

	local activeColors = self.Themes[self.CurrentTheme]
	for propName, themeKey in pairs(propertyBindings) do
		self.Registry[instance][propName] = themeKey
		if activeColors[themeKey] then
			pcall(function()
				instance[propName] = activeColors[themeKey]
			end)
		end
	end
end

--==============================================================================
-- 3. SELF-CONTAINED LUCIDE ICONS (COMPACT CONFIGURATION)
--==============================================================================
local Lucide = {}
-- Mapping standard popular Lucide icons to production-grade Roblox assets
local CustomIconAssets = {
	home = "rbxassetid://10723343321",
	settings = "rbxassetid://10723351336",
	["auto-farm"] = "rbxassetid://10723374244",
	teleports = "rbxassetid://10723395982",
	success = "rbxassetid://10723346959",
	warning = "rbxassetid://10734800366",
	danger = "rbxassetid://10734800720",
	chevron = "rbxassetid://10723366911",
	folder = "rbxassetid://10723374522",
	user = "rbxassetid://10723385759",
	terminal = "rbxassetid://10723386001",
	arrow = "rbxassetid://10723348123",
}

function Lucide.GetAsset(name: string)
	local query = string.lower(name)
	local assetId = CustomIconAssets[query] or CustomIconAssets["folder"]
	return {
		IconName = name,
		Url = assetId,
		ImageRectSize = Vector2.new(24, 24),
		ImageRectOffset = Vector2.new(0, 0),
	}
end

function LRXUI:GetIcon(iconName: string)
	return Lucide.GetAsset(iconName)
end

-- Expose theme colors API for external configurations
function LRXUI:GetThemeColors()
	return self.Themes[self.CurrentTheme]
end

--==============================================================================
-- 4. VISUAL DESIGN CONSTANTS
--==============================================================================
local Design = {
	CornerRadius = 8,
	ElementPadding = 8,
	ElementHeight = 32,
	WindowSize = Vector2.new(720, 480),
	MinWindowSize = Vector2.new(500, 360),

	FontBold = Enum.Font.BuilderSansBold,
	FontSemiBold = Enum.Font.BuilderSansMedium,
	FontRegular = Enum.Font.BuilderSans,
	FontMono = Enum.Font.Code,
	FontSizeHeader = 15,
	FontSizeTitle = 14,
	FontSizeBody = 13,
	FontSizeSmall = 11,

	AnimSpeedFast = 0.1,
	AnimSpeedMedium = 0.18,
	AnimEasing = Enum.EasingStyle.Quad,
	AnimDirection = Enum.EasingDirection.Out,
}

--==============================================================================
-- 5. ANIMATION & TWEEN MANAGER
--==============================================================================
local Animation = {
	ActiveTweens = {}, -- { [Instance] = { [PropertyName] = Tween } }
}

function Animation.Play(instance: Instance, tweenInfo: TweenInfo, targetProperties: { [string]: any })
	if not Animation.ActiveTweens[instance] then
		Animation.ActiveTweens[instance] = {}
	end

	local instTweens = Animation.ActiveTweens[instance]
	for propName, _ in pairs(targetProperties) do
		if instTweens[propName] then
			instTweens[propName]:Cancel()
			instTweens[propName] = nil
		end
	end

	local tween = TweenService:Create(instance, tweenInfo, targetProperties)
	for propName, _ in pairs(targetProperties) do
		instTweens[propName] = tween
	end

	tween:Play()

	local completedConn
	completedConn = tween.Completed:Connect(function()
		for propName, _ in pairs(targetProperties) do
			if instTweens[propName] == tween then
				instTweens[propName] = nil
			end
		end
		completedConn:Disconnect()
	end)

	return tween
end

function Animation.Color(instance: Instance, targetColor: Color3, propertyName: string?, duration: number?)
	propertyName = propertyName or "BackgroundColor3"
	duration = duration or Design.AnimSpeedFast
	return Animation.Play(instance, TweenInfo.new(duration), { [propertyName] = targetColor })
end

function Animation.Stop(instance: Instance)
	local instTweens = Animation.ActiveTweens[instance]
	if instTweens then
		for _, t in pairs(instTweens) do
			t:Cancel()
		end
		Animation.ActiveTweens[instance] = nil
	end
end

--==============================================================================
-- 6. UNIFIED OBJECT FACTORY
--==============================================================================
local Factory = {}

function Factory.New(className: string, properties: { [string]: any }): Instance
	local instance = Instance.new(className)

	-- Extract and apply theme bindings
	local themeBinding = properties.ThemeBinding
	properties.ThemeBinding = nil

	for prop, val in pairs(properties) do
		pcall(function()
			instance[prop] = val
		end)
	end

	if themeBinding then
		LRXUI:BindTheme(instance, themeBinding)
	end

	return instance
end

function Factory.Corner(parent: Instance, radius: number?): UICorner
	return Factory.New("UICorner", {
		CornerRadius = UDim.new(0, radius or Design.CornerRadius),
		Parent = parent,
	})
end

function Factory.Padding(parent: Instance, top: number, bottom: number, left: number, right: number): UIPadding
	return Factory.New("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right),
		Parent = parent,
	})
end

function Factory.Stroke(parent: Instance, themeKey: string, thickness: number?, transparency: number?): UIStroke
	return Factory.New("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		ThemeBinding = { Color = themeKey },
		Parent = parent,
	})
end

function Factory.Shadow(parent: Instance): ImageLabel
	return Factory.New("ImageLabel", {
		Name = "DropShadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015886854",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.4,
		Position = UDim2.new(0, -15, 0, -15),
		Size = UDim2.new(1, 30, 1, 30),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(17, 17, 283, 283),
		ZIndex = math.max(1, parent.ZIndex - 1),
		Parent = parent,
	})
end

function Factory.List(parent: Instance, padding: UDim?, direction: Enum.FillDirection?): UIListLayout
	return Factory.New("UIListLayout", {
		Padding = padding or UDim.new(0, Design.ElementPadding),
		FillDirection = direction or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function Factory.Grid(parent: Instance, cellSize: UDim2, padding: UDim2): UIGridLayout
	return Factory.New("UIGridLayout", {
		CellSize = cellSize,
		CellPadding = padding,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function Factory.Constraint(parent: Instance, minSize: Vector2?, maxSize: Vector2?): UISizeConstraint
	return Factory.New("UISizeConstraint", {
		MinSize = minSize or Design.MinWindowSize,
		MaxSize = maxSize or Vector2.new(2000, 2000),
		Parent = parent,
	})
end

--==============================================================================
-- 7. CORE UTILITY FUNCTIONS
--==============================================================================
local Utility = {}

function Utility:GetTextSize(text: string, fontSize: number, font: Enum.Font, maxWidth: number?): Vector2
	local width = maxWidth or 10000
	local size = Vector2.zero
	pcall(function()
		size = TextService:GetTextSize(text, fontSize, font, Vector2.new(width, 10000))
	end)
	return size
end

function Utility:MakeDraggable(frame: GuiObject, dragHandle: GuiObject)
	local dragStart, startPos

	local handleInput = dragHandle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragStart = input.Position
			startPos = frame.Position

			local inputChangedConn, inputEndedConn

			inputChangedConn = UserInputService.InputChanged:Connect(function(changedInput)
				if
					changedInput.UserInputType == Enum.UserInputType.MouseMovement
					or changedInput.UserInputType == Enum.UserInputType.Touch
				then
					local delta = changedInput.Position - dragStart
					frame.Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)
				end
			end)

			inputEndedConn = UserInputService.InputEnded:Connect(function(endedInput)
				if
					endedInput.UserInputType == Enum.UserInputType.MouseButton1
					or endedInput.UserInputType == Enum.UserInputType.Touch
				then
					inputChangedConn:Disconnect()
					inputEndedConn:Disconnect()
				end
			end)

			table.insert(LRXUI.Connections, inputChangedConn)
			table.insert(LRXUI.Connections, inputEndedConn)
		end
	end)
	table.insert(LRXUI.Connections, handleInput)
end

function Utility:MakeResizable(frame: GuiObject, handle: GuiObject, minSize: Vector2)
	local resizeStart, startSize

	local handleInput = handle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			resizeStart = input.Position
			startSize = frame.AbsoluteSize

			local inputChangedConn, inputEndedConn

			inputChangedConn = UserInputService.InputChanged:Connect(function(changedInput)
				if
					changedInput.UserInputType == Enum.UserInputType.MouseMovement
					or changedInput.UserInputType == Enum.UserInputType.Touch
				then
					local delta = changedInput.Position - resizeStart
					local newX = math.clamp(startSize.X + delta.X, minSize.X, 2000)
					local newY = math.clamp(startSize.Y + delta.Y, minSize.Y, 2000)
					frame.Size = UDim2.fromOffset(newX, newY)
				end
			end)

			inputEndedConn = UserInputService.InputEnded:Connect(function(endedInput)
				if
					endedInput.UserInputType == Enum.UserInputType.MouseButton1
					or endedInput.UserInputType == Enum.UserInputType.Touch
				then
					inputChangedConn:Disconnect()
					inputEndedConn:Disconnect()
				end
			end)

			table.insert(LRXUI.Connections, inputChangedConn)
			table.insert(LRXUI.Connections, inputEndedConn)
		end
	end)
	table.insert(LRXUI.Connections, handleInput)
end

function Utility:RunSafeCallback(callback, ...)
	if callback and typeof(callback) == "function" then
		local success, err = xpcall(callback, function(e)
			return debug.traceback(e, 2)
		end, ...)
		if not success then
			warn("[LRXUI Callback Exception]: " .. tostring(err))
		end
	end
end

--==============================================================================
-- 8. TOAST NOTIFICATIONS & MODAL DIALOGS
--==============================================================================
local NotificationArea
local NotificationList

local function InitializeNotifications(parent: Instance)
	if NotificationArea then
		return
	end
	NotificationArea = Factory.New("Frame", {
		Name = "ToastArea",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, 300, 1, -32),
		ZIndex = 1000,
		Parent = parent,
	})
	NotificationList = Factory.List(NotificationArea, UDim.new(0, 10))
	NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
end

function LRXUI:Notify(title: string, desc: string, duration: number?, statusType: string?)
	duration = duration or 4
	statusType = statusType or "Success" -- "Success", "Warning", "Danger"

	local accentKey = "Success"
	if statusType == "Warning" then
		accentKey = "Warning"
	elseif statusType == "Danger" then
		accentKey = "Danger"
	end

	local shell = Factory.New("Frame", {
		Name = "ToastShell",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = NotificationArea,
	})

	local panel = Factory.New("Frame", {
		Name = "ToastPanel",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ThemeBinding = { BackgroundColor3 = "Surface" },
		Parent = shell,
	})
	Factory.Corner(panel, 6)
	Factory.Stroke(panel, "Border")
	Factory.Padding(panel, 10, 10, 14, 10)

	-- Accent Left Border Strip
	local borderStrip = Factory.New("Frame", {
		Name = "BorderAccent",
		Size = UDim2.new(0, 4, 1, 0),
		BorderSizePixel = 0,
		ThemeBinding = { BackgroundColor3 = accentKey },
		Parent = panel,
	})
	Factory.Corner(borderStrip, 2)

	local textContainer = Factory.New("Frame", {
		Name = "TextContainer",
		Size = UDim2.new(1, -12, 0, 0),
		Position = UDim2.fromOffset(10, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = panel,
	})
	Factory.List(textContainer, UDim.new(0, 4))

	local titleLabel = Factory.New("TextLabel", {
		Name = "ToastTitle",
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = title,
		Font = Design.FontBold,
		TextSize = Design.FontSizeTitle,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = textContainer,
	})

	local descLabel = Factory.New("TextLabel", {
		Name = "ToastDesc",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = desc,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "SubText" },
		Parent = textContainer,
	})

	-- Stagger animation entrance
	panel.Position = UDim2.fromScale(1, 0)
	Animation.Play(panel, TweenInfo.new(Design.AnimSpeedMedium), { Position = UDim2.fromScale(0, 0) })

	task.delay(duration, function()
		local tween = Animation.Play(panel, TweenInfo.new(Design.AnimSpeedMedium), { Position = UDim2.fromScale(1, 0) })
		tween.Completed:Wait()
		shell:Destroy()
	end)
end

-- Dynamic Interactive Confirmation Prompt dialog
function LRXUI:Prompt(title: string, desc: string, callback: () -> ())
	-- Create confirmation panel modal overlay
	local Window = self.ActiveWindows[1]
	if not Window then
		return
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "PromptOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 100

	local dialog = Instance.new("Frame")
	dialog.Name = "PromptDialog"
	dialog.Size = UDim2.fromOffset(360, 180)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.BackgroundColor3 = self:GetThemeColors().Surface
	dialog.BorderSizePixel = 0
	dialog.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = dialog

	local stroke = Instance.new("UIStroke")
	stroke.Color = self:GetThemeColors().Border
	stroke.Thickness = 1
	stroke.Parent = dialog

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -24, 0, 32)
	titleLabel.Position = UDim2.fromOffset(12, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 18
	titleLabel.TextColor3 = self:GetThemeColors().Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = dialog

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -24, 0, 64)
	descLabel.Position = UDim2.fromOffset(12, 44)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = desc
	descLabel.Font = Enum.Font.SourceSans
	descLabel.TextSize = 14
	descLabel.TextColor3 = self:GetThemeColors().SubText
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = dialog

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.fromOffset(100, 32)
	cancelBtn.Position = UDim2.new(1, -224, 1, -44)
	cancelBtn.BackgroundColor3 = self:GetThemeColors().SurfaceHover
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = self:GetThemeColors().Text
	cancelBtn.Font = Enum.Font.SourceSansBold
	cancelBtn.TextSize = 14
	cancelBtn.Parent = dialog

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelBtn

	local okBtn = Instance.new("TextButton")
	okBtn.Size = UDim2.fromOffset(100, 32)
	okBtn.Position = UDim2.new(1, -112, 1, -44)
	okBtn.BackgroundColor3 = self:GetThemeColors().Accent
	okBtn.Text = "Confirm"
	okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	okBtn.Font = Enum.Font.SourceSansBold
	okBtn.TextSize = 14
	okBtn.Parent = dialog

	local okCorner = Instance.new("UICorner")
	okCorner.CornerRadius = UDim.new(0, 4)
	okCorner.Parent = okBtn

	cancelBtn.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)

	okBtn.MouseButton1Click:Connect(function()
		overlay:Destroy()
		Utility:RunSafeCallback(callback)
	end)

	overlay.Parent = Window.MainFrame
end

--==============================================================================
-- 9. WINDOW SYSTEM
--==============================================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", math.huge)
local WindowSystem = {}
WindowSystem.__index = WindowSystem

function WindowSystem.new(config)
	local self = setmetatable({}, WindowSystem)

	self.Title = config.Title or "LRXUI Window"
	self.Version = config.Version or "1.0.0"
	self.Size = config.Size or UDim2.fromOffset(Design.WindowSize.X, Design.WindowSize.Y)
	self.Pages = {}
	self.ActivePage = nil

	-- Main Core ScreenGui container
	self.ScreenGui = Factory.New("ScreenGui", {
		Name = "LRX_UI_Core",
		ResetOnSpawn = false,
		DisplayOrder = 10,
		ZindexBehavior = 999,
		Parent = PlayerGui,
	})

	-- Modal Blur effect
	local blurEffect = Factory.New("DepthOfFieldEffect", {
		Name = "UI_Blur",
		FarIntensity = 0.5,
		FocusDistance = 10,
		InFocusRadius = 20,
		NearIntensity = 0.5,
		Parent = game:GetService("Lighting"),
	})

	self.MainFrame = Factory.New("Frame", {
		Name = "MainWindow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = self.Size,
		Position = UDim2.fromScale(0.5, 0.5),
		ThemeBinding = { BackgroundColor3 = "Background" },
		Parent = self.ScreenGui,
	})
	Factory.Corner(self.MainFrame)
	Factory.Stroke(self.MainFrame, "Border")
	Factory.Shadow(self.MainFrame)
	Factory.Constraint(self.MainFrame)

	-- Top drag and title header handle
	local headerHandle = Factory.New("Frame", {
		Name = "WindowHeader",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = self.MainFrame,
	})
	Utility:MakeDraggable(self.MainFrame, headerHandle)

	local titleLabel = Factory.New("TextLabel", {
		Size = UDim2.new(1, -200, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		BackgroundTransparency = 1,
		Text = self.Title,
		Font = Design.FontBold,
		TextSize = Design.FontSizeHeader,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = headerHandle,
	})

	-- Bottom corner resize handle
	local resizeHandle = Factory.New("ImageButton", {
		Name = "ResizeHandle",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -16, 1, -16),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10628935055",
		ThemeBinding = { ImageColor3 = "Muted" },
		Parent = self.MainFrame,
	})
	Utility:MakeResizable(self.MainFrame, resizeHandle, Design.MinWindowSize)

	-- Left Navigation bar Sidebar
	self.Sidebar = Factory.New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 180, 1, -48),
		Position = UDim2.fromOffset(0, 48),
		ThemeBinding = { BackgroundColor3 = "Sidebar" },
		Parent = self.MainFrame,
	})
	Factory.Corner(self.Sidebar)
	Factory.Padding(self.Sidebar, 8, 8, 8, 8)

	local sidebarLayout = Factory.List(self.Sidebar, UDim.new(0, 4))

	-- Main body container for loaded tab frames
	self.BodyFrame = Factory.New("Frame", {
		Name = "WindowBody",
		Size = UDim2.new(1, -180, 1, -72),
		Position = UDim2.fromOffset(180, 48),
		BackgroundTransparency = 1,
		Parent = self.MainFrame,
	})

	-- Status footer bar row
	self.Footer = Factory.New("Frame", {
		Name = "WindowFooter",
		Size = UDim2.new(1, -180, 0, 24),
		Position = UDim2.new(0, 180, 1, -24),
		BackgroundTransparency = 1,
		Parent = self.MainFrame,
	})
	Factory.Padding(self.Footer, 0, 0, 16, 16)

	self.StatusLabel = Factory.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "Core Loaded successfully",
		Font = Design.FontMono,
		TextSize = Design.FontSizeSmall,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Muted" },
		Parent = self.Footer,
	})

	InitializeNotifications(self.ScreenGui)

	table.insert(LRXUI.ActiveWindows, self)
	return self
end

function WindowSystem:UpdateStatus(newStatus: string)
	self.StatusLabel.Text = newStatus
end

function WindowSystem:ToggleVisibility()
	self.MainFrame.Visible = not self.MainFrame.Visible
end

function WindowSystem:Destroy()
	self.ScreenGui:Destroy()
	-- Clean connections and theme entries
	for i, w in ipairs(LRXUI.ActiveWindows) do
		if w == self then
			table.remove(LRXUI.ActiveWindows, i)
			break
		end
	end
end

--==============================================================================
-- 10. PAGE SYSTEM
--==============================================================================
local PageSystem = {}
PageSystem.__index = PageSystem

function PageSystem.new(window, title: string)
	local self = setmetatable({}, PageSystem)

	self.Window = window
	self.Title = title
	self.Cards = {}

	-- Individual Scroll Body for active elements
	self.Frame = Factory.New("ScrollingFrame", {
		Name = "Page_" .. title,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = LRXUI.Themes[LRXUI.CurrentTheme].Scrollbar,
		Visible = false,
		Parent = window.BodyFrame,
	})
	Factory.Padding(self.Frame, 16, 16, 16, 16)
	Factory.List(self.Frame, UDim.new(0, 12))

	-- Left navigation sidebar button
	self.SidebarButton = Factory.New("TextButton", {
		Name = "Tab_" .. title,
		Size = UDim2.new(1, 0, 0, 36),
		ThemeBinding = { BackgroundColor3 = "Background" },
		Text = "",
		AutoButtonColor = false,
		Parent = window.Sidebar,
	})
	Factory.Corner(self.SidebarButton, 6)

	local icon = Factory.New("ImageLabel", {
		Name = "TabIcon",
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(8, 9),
		BackgroundTransparency = 1,
		Image = LRXUI:GetIcon(title).Url,
		ThemeBinding = { ImageColor3 = "SubText" },
		Parent = self.SidebarButton,
	})

	local btnLabel = Factory.New("TextLabel", {
		Size = UDim2.new(1, -38, 1, 0),
		Position = UDim2.fromOffset(32, 0),
		BackgroundTransparency = 1,
		Text = title,
		Font = Design.FontSemiBold,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "SubText" },
		Parent = self.SidebarButton,
	})

	self.SidebarButton.MouseButton1Click:Connect(function()
		self:Select()
	end)

	table.insert(window.Pages, self)

	if #window.Pages == 1 then
		self:Select()
	end

	return self
end

function PageSystem:Select()
	for _, otherPage in ipairs(self.Window.Pages) do
		otherPage.Frame.Visible = false
		otherPage.SidebarButton.BackgroundColor3 = LRXUI.Themes[LRXUI.CurrentTheme].Background
		LRXUI:BindTheme(otherPage.SidebarButton, { BackgroundColor3 = "Background" })
		LRXUI:BindTheme(otherPage.SidebarButton.TextLabel, { TextColor3 = "SubText" })
		otherPage.SidebarButton.TabIcon.ImageColor3 = LRXUI.Themes[LRXUI.CurrentTheme].SubText
	end

	self.Frame.Visible = true
	self.Window.ActivePage = self
	self.SidebarButton.BackgroundColor3 = LRXUI.Themes[LRXUI.CurrentTheme].Surface
	LRXUI:BindTheme(self.SidebarButton, { BackgroundColor3 = "Surface" })
	LRXUI:BindTheme(self.SidebarButton.TextLabel, { TextColor3 = "Accent" })
	self.SidebarButton.TabIcon.ImageColor3 = LRXUI.Themes[LRXUI.CurrentTheme].Accent
end

function WindowSystem:AddPage(title: string)
	return PageSystem.new(self, title)
end

--==============================================================================
-- 11. CARD SYSTEM
--==============================================================================
local CardSystem = {}
CardSystem.__index = CardSystem

function CardSystem.new(page, title: string, layoutType: string?)
	local self = setmetatable({}, CardSystem)

	self.Page = page
	self.Title = title
	self.Components = {}

	self.Frame = Factory.New("Frame", {
		Name = "Card_" .. title,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ThemeBinding = { BackgroundColor3 = "Surface" },
		Parent = page.Frame,
	})
	Factory.Corner(self.Frame, 8)
	Factory.Stroke(self.Frame, "Border")
	Factory.Padding(self.Frame, 12, 12, 14, 14)

	-- Custom card layouts (Vertical lists vs Horizontal flex grids)
	self.ContentFrame = Factory.New("Frame", {
		Name = "CardContent",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.Frame,
	})

	if layoutType == "Grid" then
		Factory.Grid(self.ContentFrame, UDim2.new(0.5, -4, 0, Design.ElementHeight), UDim2.fromOffset(8, 8))
	else
		Factory.List(self.ContentFrame, UDim.new(0, Design.ElementPadding))
	end

	table.insert(page.Cards, self)
	return self
end

function PageSystem:AddCard(title: string, layoutType: string?)
	return CardSystem.new(self, title, layoutType)
end

--==============================================================================
-- 12. BASE COMPONENT CLASS API
--==============================================================================
local BaseComponent = {}
BaseComponent.__index = BaseComponent

function BaseComponent:Init(card, holder, layoutOrder)
	self.Card = card
	self.Holder = holder
	self.LayoutOrder = layoutOrder or (#card.Components + 1)
	self.Holder.LayoutOrder = self.LayoutOrder
	self.Enabled = true

	table.insert(card.Components, self)
end

function BaseComponent:SetVisible(visible: boolean)
	self.Holder.Visible = visible
end

function BaseComponent:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	Animation.Play(self.Holder, TweenInfo.new(Design.AnimSpeedFast), {
		GroupTransparency = enabled and 0 or 0.45,
	})
end

function BaseComponent:SetDisabled(disabled: boolean)
	self:SetEnabled(not disabled)
end

function BaseComponent:SetParent(parent: Instance)
	self.Holder.Parent = parent
end

function BaseComponent:Destroy()
	self.Holder:Destroy()
	for i, c in ipairs(self.Card.Components) do
		if c == self then
			table.remove(self.Card.Components, i)
			break
		end
	end
end

function BaseComponent:SetTooltip(tooltipText: string)
	if self.TooltipConn then
		self.TooltipConn:Disconnect()
	end

	self.TooltipConn = self.Holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			-- Tooltip layout logic
		end
	end)
	table.insert(LRXUI.Connections, self.TooltipConn)
end

--==============================================================================
-- 12.1 COMPONENT: LABEL
--==============================================================================
local LabelComp = setmetatable({}, BaseComponent)
LabelComp.__index = LabelComp

function LabelComp.new(card, text: string, align: Enum.TextXAlignment?)
	local self = setmetatable({}, LabelComp)

	local holder = Factory.New("CanvasGroup", {
		Name = "LabelComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local textLabel = Factory.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextWrapped = true,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = holder,
	})
	self.TextLabel = textLabel

	self:Init(card, holder)
	return self
end

function LabelComp:SetText(text: string)
	self.TextLabel.Text = text
end

function CardSystem:AddLabel(text: string, align: Enum.TextXAlignment?)
	return LabelComp.new(self, text, align)
end

--==============================================================================
-- 12.2 COMPONENT: BUTTON
--==============================================================================
local ButtonComp = setmetatable({}, BaseComponent)
ButtonComp.__index = ButtonComp

function ButtonComp.new(card, text: string, callback: () -> (), doubleClick: boolean?)
	local self = setmetatable({}, ButtonComp)
	self.Callback = callback
	self.DoubleClick = doubleClick or false
	self.LastClickTime = 0

	local holder = Factory.New("CanvasGroup", {
		Name = "ButtonComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local btn = Factory.New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		ThemeBinding = { BackgroundColor3 = "SurfaceHover" },
		Text = "",
		AutoButtonColor = false,
		Parent = holder,
	})
	Factory.Corner(btn, 6)
	Factory.Stroke(btn, "Border")

	local btnLabel = Factory.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontSemiBold,
		TextSize = Design.FontSizeBody,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = btn,
	})
	self.Button = btn
	self.Label = btnLabel

	btn.MouseEnter:Connect(function()
		if not self.Enabled then
			return
		end
		Animation.Color(btn, LRXUI.Themes[LRXUI.CurrentTheme].Accent)
	end)
	btn.MouseLeave:Connect(function()
		if not self.Enabled then
			return
		end
		Animation.Color(btn, LRXUI.Themes[LRXUI.CurrentTheme].SurfaceHover)
	end)
	btn.MouseButton1Down:Connect(function()
		if not self.Enabled then
			return
		end
		Animation.Play(
			btn,
			TweenInfo.new(Design.AnimSpeedFast),
			{ Size = UDim2.new(0.98, 0, 0.94, 0), Position = UDim2.new(0.01, 0, 0.03, 0) }
		)
	end)
	btn.MouseButton1Up:Connect(function()
		if not self.Enabled then
			return
		end
		Animation.Play(
			btn,
			TweenInfo.new(Design.AnimSpeedFast),
			{ Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 0) }
		)
	end)

	btn.MouseButton1Click:Connect(function()
		if not self.Enabled then
			return
		end
		if self.DoubleClick then
			local now = tick()
			if now - self.LastClickTime < 0.5 then
				Utility:RunSafeCallback(self.Callback)
				btnLabel.Text = text
			else
				self.LastClickTime = now
				btnLabel.Text = "Click again to confirm..."
				task.delay(1.5, function()
					if btnLabel.Text == "Click again to confirm..." then
						btnLabel.Text = text
					end
				end)
			end
		else
			Utility:RunSafeCallback(self.Callback)
		end
	end)

	self:Init(card, holder)
	return self
end

function CardSystem:AddButton(text: string, callback: () -> (), doubleClick: boolean?)
	return ButtonComp.new(self, text, callback, doubleClick)
end

--==============================================================================
-- 12.3 COMPONENT: TOGGLE
--==============================================================================
local ToggleComp = setmetatable({}, BaseComponent)
ToggleComp.__index = ToggleComp

function ToggleComp.new(card, text: string, default: boolean, callback: (boolean) -> ())
	local self = setmetatable({}, ToggleComp)
	self.Value = default
	self.Callback = callback

	local holder = Factory.New("CanvasGroup", {
		Name = "ToggleComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local toggleBtn = Factory.New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Parent = holder,
	})

	local label = Factory.New("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = toggleBtn,
	})

	local switch = Factory.New("Frame", {
		Name = "SwitchOuter",
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.new(1, -44, 0.5, -10),
		ThemeBinding = { BackgroundColor3 = "SurfaceHover" },
		Parent = toggleBtn,
	})
	Factory.Corner(switch, 10)
	local stroke = Factory.Stroke(switch, "Border")

	local knob = Factory.New("Frame", {
		Name = "SwitchKnob",
		Size = UDim2.fromOffset(14, 14),
		Position = default and UDim2.fromOffset(22, 3) or UDim2.fromOffset(4, 3),
		ThemeBinding = { BackgroundColor3 = "Text" },
		Parent = switch,
	})
	Factory.Corner(knob, 7)

	local function renderState()
		local activeColor = LRXUI.Themes[LRXUI.CurrentTheme].Accent
		local disabledColor = LRXUI.Themes[LRXUI.CurrentTheme].SurfaceHover

		Animation.Play(knob, TweenInfo.new(Design.AnimSpeedFast), {
			Position = self.Value and UDim2.fromOffset(22, 3) or UDim2.fromOffset(4, 3),
		})
		Animation.Color(switch, self.Value and activeColor or disabledColor)
		stroke.Color = self.Value and activeColor or LRXUI.Themes[LRXUI.CurrentTheme].Border
	end

	toggleBtn.MouseButton1Click:Connect(function()
		if not self.Enabled then
			return
		end
		self.Value = not self.Value
		renderState()
		Utility:RunSafeCallback(self.Callback, self.Value)
	end)

	renderState()
	self:Init(card, holder)
	return self
end

function CardSystem:AddToggle(text: string, default: boolean, callback: (boolean) -> ())
	return ToggleComp.new(self, text, default, callback)
end

--==============================================================================
-- 12.4 COMPONENT: SLIDER
--==============================================================================
local SliderComp = setmetatable({}, BaseComponent)
SliderComp.__index = SliderComp

function SliderComp.new(card, text: string, config, callback: (number) -> ())
	local self = setmetatable({}, SliderComp)
	self.Min = config.Min or 0
	self.Max = config.Max or 100
	self.Value = math.clamp(config.Default or self.Min, self.Min, self.Max)
	self.Rounding = config.Rounding or 0
	self.Suffix = config.Suffix or ""
	self.Callback = callback

	local holder = Factory.New("CanvasGroup", {
		Name = "SliderComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight + 14),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local label = Factory.New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = holder,
	})

	local valLabel = Factory.New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = tostring(self.Value) .. self.Suffix,
		Font = Design.FontMono,
		TextSize = Design.FontSizeSmall,
		TextXAlignment = Enum.TextXAlignment.Right,
		ThemeBinding = { TextColor3 = "SubText" },
		Parent = holder,
	})

	local track = Factory.New("TextButton", {
		Name = "SliderTrack",
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 1, -12),
		ThemeBinding = { BackgroundColor3 = "Surface" },
		Text = "",
		AutoButtonColor = false,
		Parent = holder,
	})
	Factory.Corner(track, 4)
	Factory.Stroke(track, "Border")

	local fill = Factory.New("Frame", {
		Name = "SliderFill",
		Size = UDim2.fromScale(0, 1),
		ThemeBinding = { BackgroundColor3 = "Accent" },
		Parent = track,
	})
	Factory.Corner(fill, 4)

	local function updatePosition(absX)
		local scale = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local rawVal = self.Min + (self.Max - self.Min) * scale

		-- Rounding factor calculation
		local factor = 10 ^ self.Rounding
		self.Value = math.floor(rawVal * factor + 0.5) / factor

		fill.Size = UDim2.fromScale(scale, 1)
		valLabel.Text = tostring(self.Value) .. self.Suffix
		Utility:RunSafeCallback(self.Callback, self.Value)
	end

	track.InputBegan:Connect(function(input)
		if not self.Enabled then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			updatePosition(input.Position.X)

			local dragConn, endConn
			dragConn = UserInputService.InputChanged:Connect(function(changedInput)
				if
					changedInput.UserInputType == Enum.UserInputType.MouseMovement
					or changedInput.UserInputType == Enum.UserInputType.Touch
				then
					updatePosition(changedInput.Position.X)
				end
			end)

			endConn = UserInputService.InputEnded:Connect(function(endedInput)
				if
					endedInput.UserInputType == Enum.UserInputType.MouseButton1
					or endedInput.UserInputType == Enum.UserInputType.Touch
				then
					dragConn:Disconnect()
					endConn:Disconnect()
				end
			end)

			table.insert(LRXUI.Connections, dragConn)
			table.insert(LRXUI.Connections, endConn)
		end
	end)

	-- Set Initial scale positioning
	local startScale = (self.Value - self.Min) / (self.Max - self.Min)
	fill.Size = UDim2.fromScale(startScale, 1)

	self:Init(card, holder)
	return self
end

function CardSystem:AddSlider(text: string, config, callback: (number) -> ())
	return SliderComp.new(self, text, config, callback)
end

--==============================================================================
-- 12.5 COMPONENT: INPUT / TEXTBOX
--==============================================================================
local InputComp = setmetatable({}, BaseComponent)
InputComp.__index = InputComp

function InputComp.new(card, text: string, placeholder: string?, callback: (string) -> ())
	local self = setmetatable({}, InputComp)
	self.Callback = callback

	local holder = Factory.New("CanvasGroup", {
		Name = "InputComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local label = Factory.New("TextLabel", {
		Size = UDim2.new(0.4, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = holder,
	})

	local boxFrame = Factory.New("Frame", {
		Name = "InputBoxFrame",
		Size = UDim2.new(0.6, -4, 1, -4),
		Position = UDim2.new(0.4, 4, 0, 2),
		ThemeBinding = { BackgroundColor3 = "SurfaceHover" },
		Parent = holder,
	})
	Factory.Corner(boxFrame, 6)
	local stroke = Factory.Stroke(boxFrame, "Border")

	local txtBox = Factory.New("TextBox", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = placeholder or "Type inside...",
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = boxFrame,
	})

	txtBox.Focused:Connect(function()
		Animation.Color(boxFrame, LRXUI.Themes[LRXUI.CurrentTheme].Accent, "BorderColor3")
		stroke.Color = LRXUI.Themes[LRXUI.CurrentTheme].Accent
	end)

	txtBox.FocusLost:Connect(function()
		Animation.Color(boxFrame, LRXUI.Themes[LRXUI.CurrentTheme].Border, "BorderColor3")
		stroke.Color = LRXUI.Themes[LRXUI.CurrentTheme].Border
		Utility:RunSafeCallback(self.Callback, txtBox.Text)
	end)

	self:Init(card, holder)
	return self
end

function CardSystem:AddInput(text: string, placeholder: string?, callback: (string) -> ())
	return InputComp.new(self, text, placeholder, callback)
end

--==============================================================================
-- 12.6 COMPONENT: DROPDOWN
--==============================================================================
local DropdownComp = setmetatable({}, BaseComponent)
DropdownComp.__index = DropdownComp

function DropdownComp.new(card, text: string, options: { string }, callback: (string) -> ())
	local self = setmetatable({}, DropdownComp)
	self.Options = options
	self.Selected = options[1] or ""
	self.Callback = callback
	self.Open = false

	local holder = Factory.New("CanvasGroup", {
		Name = "DropdownComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local label = Factory.New("TextLabel", {
		Size = UDim2.new(0.4, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = holder,
	})

	local selectFrame = Factory.New("TextButton", {
		Name = "SelectFrame",
		Size = UDim2.new(0.6, -4, 1, -4),
		Position = UDim2.new(0.4, 4, 0, 2),
		ThemeBinding = { BackgroundColor3 = "SurfaceHover" },
		Text = "",
		AutoButtonColor = false,
		Parent = holder,
	})
	Factory.Corner(selectFrame, 6)
	local stroke = Factory.Stroke(selectFrame, "Border")

	local valueLabel = Factory.New("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
		Text = self.Selected,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = selectFrame,
	})

	local arrow = Factory.New("ImageLabel", {
		Name = "DropdownArrow",
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -20, 0.5, -6),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10723366911", -- Arrow icon asset
		ThemeBinding = { ImageColor3 = "Muted" },
		Parent = selectFrame,
	})

	-- Option selection layout popup scroll list
	local popList = Factory.New("ScrollingFrame", {
		Name = "OptionPopupList",
		Size = UDim2.new(0.6, -4, 0, 0),
		Position = UDim2.new(0.4, 4, 0, Design.ElementHeight + 2),
		ThemeBinding = { BackgroundColor3 = "Surface" },
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		Visible = false,
		ZIndex = 50,
		Parent = holder,
	})
	Factory.Corner(popList, 6)
	Factory.Stroke(popList, "Border")
	Factory.Padding(popList, 4, 4, 4, 4)
	local listLayout = Factory.List(popList, UDim.new(0, 2))

	local function renderOptions()
		for _, opt in ipairs(popList:GetChildren()) do
			if opt:IsA("TextButton") then
				opt:Destroy()
			end
		end

		for _, optVal in ipairs(self.Options) do
			local optBtn = Factory.New("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = "",
				Parent = popList,
			})
			Factory.Corner(optBtn, 4)

			local optLabel = Factory.New("TextLabel", {
				Size = UDim2.new(1, -8, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				BackgroundTransparency = 1,
				Text = optVal,
				Font = Design.FontRegular,
				TextSize = Design.FontSizeBody,
				TextXAlignment = Enum.TextXAlignment.Left,
				ThemeBinding = { TextColor3 = "Text" },
				Parent = optBtn,
			})

			optBtn.MouseEnter:Connect(function()
				Animation.Color(optBtn, LRXUI.Themes[LRXUI.CurrentTheme].SurfaceHover)
			end)
			optBtn.MouseLeave:Connect(function()
				Animation.Color(optBtn, Color3.fromRGB(0, 0, 0), "BackgroundColor3", nil, function()
					optBtn.BackgroundTransparency = 1
				end)
			end)

			optBtn.MouseButton1Click:Connect(function()
				self.Selected = optVal
				valueLabel.Text = optVal
				self:ToggleDropdown(false)
				Utility:RunSafeCallback(self.Callback, optVal)
			end)
		end
	end

	function DropdownComp:ToggleDropdown(state)
		self.Open = state
		popList.Visible = state

		Animation.Play(arrow, TweenInfo.new(Design.AnimSpeedFast), {
			Rotation = state and 180 or 0,
		})

		if state then
			holder.Size = UDim2.new(1, 0, 0, Design.ElementHeight + math.min(#self.Options * 26 + 12, 120))
			renderOptions()
		else
			holder.Size = UDim2.new(1, 0, 0, Design.ElementHeight)
		end

		-- Resize parent card containers seamlessly
		self.Card.Frame.Size = UDim2.fromScale(1, 0)
	end

	selectFrame.MouseButton1Click:Connect(function()
		if not self.Enabled then
			return
		end
		self:ToggleDropdown(not self.Open)
	end)

	self:Init(card, holder)
	return self
end

function CardSystem:AddDropdown(text: string, options: { string }, callback: (string) -> ())
	return DropdownComp.new(self, text, options, callback)
end

--==============================================================================
-- 12.7 COMPONENT: KEYBIND / KEYPICKER
--==============================================================================
local KeybindComp = setmetatable({}, BaseComponent)
KeybindComp.__index = KeybindComp

function KeybindComp.new(card, text: string, defaultKey: Enum.KeyCode, callback: () -> ())
	local self = setmetatable({}, KeybindComp)
	self.Key = defaultKey
	self.Callback = callback
	self.Binding = false

	local holder = Factory.New("CanvasGroup", {
		Name = "KeybindComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local label = Factory.New("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = holder,
	})

	local bindFrame = Factory.New("TextButton", {
		Name = "BindFrame",
		Size = UDim2.new(0.5, -4, 1, -4),
		Position = UDim2.new(0.5, 4, 0, 2),
		ThemeBinding = { BackgroundColor3 = "SurfaceHover" },
		Text = "",
		AutoButtonColor = false,
		Parent = holder,
	})
	Factory.Corner(bindFrame, 6)
	local stroke = Factory.Stroke(bindFrame, "Border")

	local keyLabel = Factory.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = self.Key.Name,
		Font = Design.FontMono,
		TextSize = Design.FontSizeBody,
		ThemeBinding = { TextColor3 = "SubText" },
		Parent = bindFrame,
	})

	bindFrame.MouseButton1Click:Connect(function()
		if not self.Enabled then
			return
		end
		self.Binding = true
		keyLabel.Text = "[ Press Any Key... ]"
		stroke.Color = LRXUI.Themes[LRXUI.CurrentTheme].Accent

		local tempConn
		tempConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self.Key = input.KeyCode
				keyLabel.Text = input.KeyCode.Name
				self.Binding = false
				stroke.Color = LRXUI.Themes[LRXUI.CurrentTheme].Border
				tempConn:Disconnect()
			end
		end)
	end)

	local pressConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or self.Binding then
			return
		end
		if input.KeyCode == self.Key then
			Utility:RunSafeCallback(self.Callback)
		end
	end)
	table.insert(LRXUI.Connections, pressConn)

	self:Init(card, holder)
	return self
end

function CardSystem:AddKeybind(text: string, defaultKey: Enum.KeyCode, callback: () -> ())
	return KeybindComp.new(self, text, defaultKey, callback)
end

--==============================================================================
-- 12.8 COMPONENT: COLOR PICKER
--==============================================================================
local ColorComp = setmetatable({}, BaseComponent)
ColorComp.__index = ColorComp

function ColorComp.new(card, text: string, defaultColor: Color3, callback: (Color3) -> ())
	local self = setmetatable({}, ColorComp)
	self.Color = defaultColor
	self.Callback = callback

	local holder = Factory.New("CanvasGroup", {
		Name = "ColorComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local label = Factory.New("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = holder,
	})

	local colorPreview = Factory.New("TextButton", {
		Name = "ColorPreview",
		Size = UDim2.new(0.5, -4, 1, -4),
		Position = UDim2.new(0.5, 4, 0, 2),
		BackgroundColor3 = defaultColor,
		Text = "",
		Parent = holder,
	})
	Factory.Corner(colorPreview, 6)
	Factory.Stroke(colorPreview, "Border")

	-- Dynamic hue cycle callback mock for simplicity
	colorPreview.MouseButton1Click:Connect(function()
		if not self.Enabled then
			return
		end
		local h, s, v = self.Color:ToHSV()
		local nextColor = Color3.fromHSV((h + 0.15) % 1, s, v)
		self.Color = nextColor
		colorPreview.BackgroundColor3 = nextColor
		Utility:RunSafeCallback(self.Callback, nextColor)
	end)

	self:Init(card, holder)
	return self
end

function CardSystem:AddColorPicker(text: string, defaultColor: Color3, callback: (Color3) -> ())
	return ColorComp.new(self, text, defaultColor, callback)
end

--==============================================================================
-- 12.9 COMPONENT: SEPARATOR
--==============================================================================
local SeparatorComp = setmetatable({}, BaseComponent)
SeparatorComp.__index = SeparatorComp

function SeparatorComp.new(card)
	local self = setmetatable({}, SeparatorComp)

	local holder = Factory.New("Frame", {
		Name = "SeparatorLine",
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		ThemeBinding = { BackgroundColor3 = "Border" },
		Parent = card.ContentFrame,
	})

	self:Init(card, holder)
	return self
end

function CardSystem:AddSeparator()
	return SeparatorComp.new(self)
end

--==============================================================================
-- 12.10 COMPONENT: PROGRESS BAR
--==============================================================================
local ProgressBarComp = setmetatable({}, BaseComponent)
ProgressBarComp.__index = ProgressBarComp

function ProgressBarComp.new(card, text: string, defaultPercent: number)
	local self = setmetatable({}, ProgressBarComp)
	self.Percent = defaultPercent

	local holder = Factory.New("CanvasGroup", {
		Name = "ProgressComp",
		Size = UDim2.new(1, 0, 0, Design.ElementHeight + 8),
		BackgroundTransparency = 1,
		Parent = card.ContentFrame,
	})

	local label = Factory.New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = text,
		Font = Design.FontRegular,
		TextSize = Design.FontSizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ThemeBinding = { TextColor3 = "Text" },
		Parent = holder,
	})

	local track = Factory.New("Frame", {
		Name = "ProgressTrack",
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -10),
		ThemeBinding = { BackgroundColor3 = "SurfaceHover" },
		Parent = holder,
	})
	Factory.Corner(track, 3)

	local bar = Factory.New("Frame", {
		Name = "ProgressBar",
		Size = UDim2.fromScale(defaultPercent / 100, 1),
		ThemeBinding = { BackgroundColor3 = "Success" },
		Parent = track,
	})
	Factory.Corner(bar, 3)
	self.Bar = bar

	self:Init(card, holder)
	return self
end

function ProgressBarComp:SetProgress(percent: number)
	self.Percent = math.clamp(percent, 0, 100)
	Animation.Play(self.Bar, TweenInfo.new(Design.AnimSpeedMedium), { Size = UDim2.fromScale(self.Percent / 100, 1) })
end

function CardSystem:AddProgressBar(text: string, defaultPercent: number)
	return ProgressBarComp.new(self, text, defaultPercent)
end

--==============================================================================
-- 12.11 COMPONENT: VIEWPORT
--==============================================================================
local ViewportComp = setmetatable({}, BaseComponent)
ViewportComp.__index = ViewportComp

function ViewportComp.new(card, partInstance: Instance)
	local self = setmetatable({}, ViewportComp)

	local holder = Factory.New("Frame", {
		Name = "ViewportComp",
		Size = UDim2.new(1, 0, 0, 110),
		ThemeBinding = { BackgroundColor3 = "Background" },
		Parent = card.ContentFrame,
	})
	Factory.Corner(holder, 6)
	Factory.Stroke(holder, "Border")

	local viewport = Factory.New("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = holder,
	})

	local camera = Instance.new("Camera")
	camera.FieldOfView = 50
	viewport.CurrentCamera = camera
	camera.Parent = viewport

	-- Clone model/part inside viewport frame
	local asset = partInstance:Clone()
	if asset:IsA("BasePart") then
		asset.Position = Vector3.zero
	elseif asset:IsA("Model") then
		asset:PivotTo(CFrame.new(Vector3.zero))
	end
	asset.Parent = viewport

	camera.CFrame = CFrame.new(Vector3.new(0, 3, 5), Vector3.zero)

	-- Gentle rotating animation
	local rotationAngle = 0
	local spinConn
	spinConn = RunService.RenderStepped:Connect(function(dt)
		if not viewport.Parent then
			spinConn:Disconnect()
			return
		end
		rotationAngle = rotationAngle + dt * 45
		if asset:IsA("BasePart") then
			asset.CFrame = CFrame.Angles(0, math.rad(rotationAngle), 0)
		elseif asset:IsA("Model") then
			asset:PivotTo(CFrame.Angles(0, math.rad(rotationAngle), 0))
		end
	end)
	table.insert(LRXUI.Connections, spinConn)

	self:Init(card, holder)
	return self
end

function CardSystem:AddViewport(partInstance: Instance)
	return ViewportComp.new(self, partInstance)
end

--==============================================================================
-- 13. MAIN WINDOW CONSTRUCTOR WRAPPER
--==============================================================================
function LRXUI:CreateWindow(config)
	return WindowSystem.new(config)
end

--==============================================================================
-- 14. CLEANUP & UNLOAD ENGINE
--==============================================================================
function LRXUI:OnUnload(callback)
	table.insert(self.UnloadSignals, callback)
end

function LRXUI:Unload()
	-- Fire custom unload bindings
	for _, cb in ipairs(self.UnloadSignals) do
		Utility:RunSafeCallback(cb)
	end
	table.clear(self.UnloadSignals)

	-- Remove Roblox instances
	for _, win in ipairs(self.ActiveWindows) do
		win:Destroy()
	end
	table.clear(self.ActiveWindows)

	-- Disconnect core events
	for _, conn in ipairs(self.Connections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(self.Connections)

	table.clear(self.Registry)
	Animation.ActiveTweens = {}
end

return LRXUI
