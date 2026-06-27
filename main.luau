--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║           EXOTIC HUB PRO - v10.8 Draggable Toggle Button           ║
    ║          Click to toggle UI, drag to move icon anywhere            ║
    ╚══════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════════════════
-- PLAYER SETUP
-- ═══════════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════════════
-- 🔧 CONFIG SECTION
-- ═══════════════════════════════════════════════════════════════════════
local Config = {
	WindowWidth = 700,
	WindowHeight = 450,
	MinWindowWidth = 400,
	MinWindowHeight = 300,
	SidebarWidth = 160,
	EnableSearch = true,
	ToggleButtonText = "Exotic",
}

-- ═══════════════════════════════════════════════════════════════════════
-- 🎨 THEME SECTION
-- ═══════════════════════════════════════════════════════════════════════
local Theme = {
	Background = Color3.fromRGB(22, 22, 26),
	Sidebar = Color3.fromRGB(28, 28, 32),
	Content = Color3.fromRGB(18, 18, 22),
	Card = Color3.fromRGB(35, 35, 40),
	CardHover = Color3.fromRGB(45, 45, 50),
	DropdownBg = Color3.fromRGB(32, 32, 38),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(160, 160, 160),
	TextMuted = Color3.fromRGB(100, 100, 100),
	Accent = Color3.fromRGB(147, 112, 219),
	AccentPink = Color3.fromRGB(255, 105, 180),
	AccentCyan = Color3.fromRGB(0, 255, 255),
	AccentGreen = Color3.fromRGB(50, 205, 50),
	AccentRed = Color3.fromRGB(255, 80, 80),
	AccentOrange = Color3.fromRGB(255, 165, 0),
	AccentYellow = Color3.fromRGB(255, 215, 0),
	Border = Color3.fromRGB(50, 50, 55),
	ToggleBg = Color3.fromRGB(60, 60, 65),
	ToggleOn = Color3.fromRGB(147, 112, 219),
	ScrollBar = Color3.fromRGB(60, 60, 70),
}

-- ═══════════════════════════════════════════════════════════════════════
-- ZINDEX HIERARCHY
-- ═══════════════════════════════════════════════════════════════════════
local Z = {
	Base        = 1,
	Toggle      = 10,
	MainUI      = 10,
	Card        = 20,
	Dropdown    = 100,
	DropScroll  = 110,
	DropControl = 120,
	Modal       = 200,
	ModalFrame  = 210,
	ModalCtrl   = 220,
	Search      = 500,
}

-- ═══════════════════════════════════════════════════════════════════════
-- ⚙️ AUTO SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════
local AutoHatchScript = {
	Name = "AutoHatch", IsRunning = false,
	Start = function(self) self.IsRunning = true while self.IsRunning do task.wait(0.1) end end,
	Stop = function(self) self.IsRunning = false end,
	Toggle = function(self) if self.IsRunning then self:Stop() else task.spawn(function() self:Start() end) end end
}
local AutoFarmScript = {
	Name = "AutoFarm", IsRunning = false,
	Start = function(self) self.IsRunning = true while self.IsRunning do task.wait(0.1) end end,
	Stop = function(self) self.IsRunning = false end,
	Toggle = function(self) if self.IsRunning then self:Stop() else task.spawn(function() self:Start() end) end end
}
local AutoFeedScript = {
	Name = "AutoFeed", IsRunning = false,
	Start = function(self) self.IsRunning = true while self.IsRunning do task.wait(0.1) end end,
	Stop = function(self) self.IsRunning = false end,
	Toggle = function(self) if self.IsRunning then self:Stop() else task.spawn(function() self:Start() end) end end
}
local AutoCraftScript = {
	Name = "AutoCraft", IsRunning = false,
	Start = function(self) self.IsRunning = true while self.IsRunning do task.wait(0.1) end end,
	Stop = function(self) self.IsRunning = false end,
	Toggle = function(self) if self.IsRunning then self:Stop() else task.spawn(function() self:Start() end) end end
}

-- ═══════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════
local function Create(className, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties or {}) do
		instance[property] = value
	end
	return instance
end

local function Tween(instance, properties, duration)
	local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	tween:Play()
	return tween
end

local function AddCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = instance
end

local function AddStroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Parent = instance
end

local function AddButtonEffects(btn, normalColor, hoverColor)
	normalColor = normalColor or btn.BackgroundColor3
	hoverColor = hoverColor or Theme.CardHover
	btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = hoverColor}, 0.15) end)
	btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = normalColor}, 0.15) end)
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Tween(btn, {BackgroundColor3 = hoverColor}, 0.1)
		end
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Tween(btn, {BackgroundColor3 = normalColor}, 0.1)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN UI CREATION
-- ═══════════════════════════════════════════════════════════════════════
local ScreenGui = Create("ScreenGui", {
	Name = "ExoticHubPro",
	Parent = playerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN WINDOW FRAME
-- ═══════════════════════════════════════════════════════════════════════
local MainFrame = Create("Frame", {
	Name = "MainFrame",
	Parent = ScreenGui,
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -Config.WindowWidth / 2, 0.5, -Config.WindowHeight / 2),
	Size = UDim2.new(0, Config.WindowWidth, 0, Config.WindowHeight),
	ClipsDescendants = false,
	Active = true,
	ZIndex = Z.Base,
	Visible = true,
})
AddCorner(MainFrame, 12)
AddStroke(MainFrame, Theme.Border, 2)

-- ═══════════════════════════════════════════════════════════════════════
-- TOGGLE BUTTON (ICON)
-- Click = toggle MainFrame visible/hidden
-- Drag  = move button anywhere on screen
-- ═══════════════════════════════════════════════════════════════════════
local ToggleBtn = Create("TextButton", {
	Name = "ToggleBtn",
	Parent = ScreenGui,
	BackgroundColor3 = Color3.fromRGB(15, 15, 15),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 8, 0, 8),
	Size = UDim2.new(0, 55, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = Config.ToggleButtonText,
	TextColor3 = Theme.AccentYellow,
	TextSize = 13,
	ZIndex = Z.Toggle,
	Active = true,
	AutoButtonColor = false,
})
AddCorner(ToggleBtn, 6)
AddStroke(ToggleBtn, Theme.Border, 1)

--[[
    DRAG & CLICK DETECTION FOR TOGGLE BUTTON
    We track the starting input position and the button's starting position.
    On InputChanged, we move the button by the delta.
    On InputEnded, if total movement was small, we treat it as a click.
]]
local toggleDragActive = false
local toggleDragInputObj = nil
local toggleStartInputPos = nil
local toggleStartBtnPos = nil
local toggleClickThreshold = 8  -- pixels

ToggleBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.Touch then
		toggleDragActive = true
		toggleDragInputObj = input
		toggleStartInputPos = input.Position
		toggleStartBtnPos = ToggleBtn.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if toggleDragActive then
		if input.UserInputType == Enum.UserInputType.MouseMovement 
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - toggleStartInputPos
			ToggleBtn.Position = UDim2.new(
				toggleStartBtnPos.X.Scale,
				toggleStartBtnPos.X.Offset + delta.X,
				toggleStartBtnPos.Y.Scale,
				toggleStartBtnPos.Y.Offset + delta.Y
			)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if toggleDragActive and input == toggleDragInputObj then
		local delta = input.Position - toggleStartInputPos
		toggleDragActive = false
		toggleDragInputObj = nil

		-- If barely moved, treat as a click → toggle UI
		if math.abs(delta.X) <= toggleClickThreshold and math.abs(delta.Y) <= toggleClickThreshold then
			MainFrame.Visible = not MainFrame.Visible
			Tween(ToggleBtn, {
				BackgroundColor3 = MainFrame.Visible and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(30, 30, 30)
			}, 0.2)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN WINDOW DRAG
-- ═══════════════════════════════════════════════════════════════════════
local isDragging = false
local dragInput = nil
local dragStartPos = nil
local frameStartPos = nil

MainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
		dragInput = input
		dragStartPos = input.Position
		frameStartPos = MainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDragging then
		if input.UserInputType == Enum.UserInputType.MouseMovement 
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStartPos
			MainFrame.Position = UDim2.new(
				frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
				frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
			)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == dragInput then
		isDragging = false
		dragInput = nil
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- RESIZING SYSTEM
-- Corner = both axes. Bottom bar = height only. Position never changes.
-- ═══════════════════════════════════════════════════════════════════════
local ResizeHandle = Create("Frame", {
	Name = "ResizeHandle",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Accent,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 16, 0, 16),
	BackgroundTransparency = 0.3,
	ZIndex = Z.MainUI + 2,
})
AddCorner(ResizeHandle, 4)

Create("TextLabel", {
	Parent = ResizeHandle,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "◢",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 10,
	TextTransparency = 0.4,
	ZIndex = Z.MainUI + 3,
})

local ResizeBtn = Create("TextButton", {
	Name = "ResizeBtn",
	Parent = ResizeHandle,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Text = "",
	ZIndex = Z.MainUI + 3,
	Active = true,
	AutoButtonColor = false,
})

local BottomResizeBar = Create("Frame", {
	Name = "BottomResizeBar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Accent,
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 40, 1, -6),
	Size = UDim2.new(1, -80, 0, 6),
	ZIndex = Z.MainUI + 2,
})
AddCorner(BottomResizeBar, 3)

Create("TextLabel", {
	Parent = BottomResizeBar,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "• • •",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 8,
	TextTransparency = 0.5,
	ZIndex = Z.MainUI + 3,
})

local BottomResizeBtn = Create("TextButton", {
	Name = "BottomResizeBtn",
	Parent = BottomResizeBar,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Text = "",
	ZIndex = Z.MainUI + 3,
	Active = true,
	AutoButtonColor = false,
})

-- Corner resize
local isResizingCorner = false
ResizeBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.Touch then
		isResizingCorner = true
		local startSize = MainFrame.Size
		local startMousePos = input.Position
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not isResizingCorner then connection:Disconnect() return end
			local currentMouse = UserInputService:GetMouseLocation()
			local delta = currentMouse - Vector2.new(startMousePos.X, startMousePos.Y)
			MainFrame.Size = UDim2.new(
				0, math.max(Config.MinWindowWidth, startSize.X.Offset + delta.X),
				0, math.max(Config.MinWindowHeight, startSize.Y.Offset + delta.Y)
			)
		end)
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then isResizingCorner = false end
		end)
	end
end)

-- Bottom bar resize
local isResizingBottom = false
BottomResizeBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.Touch then
		isResizingBottom = true
		local startSize = MainFrame.Size
		local startMousePos = input.Position
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not isResizingBottom then connection:Disconnect() return end
			local currentMouse = UserInputService:GetMouseLocation()
			local deltaY = currentMouse.Y - startMousePos.Y
			MainFrame.Size = UDim2.new(
				0, startSize.X.Offset,
				0, math.max(Config.MinWindowHeight, startSize.Y.Offset + deltaY)
			)
		end)
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then isResizingBottom = false end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- TOP BAR
-- ═══════════════════════════════════════════════════════════════════════
local TopBar = Create("Frame", {
	Name = "TopBar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Sidebar,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 40),
	ZIndex = Z.MainUI,
})
AddCorner(TopBar, 12)

local TitleLabel = Create("TextLabel", {
	Name = "Title",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 0),
	Size = UDim2.new(0, 200, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "Exotic Hub ",
	TextColor3 = Theme.TextPrimary,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.MainUI + 1,
})

Create("TextLabel", {
	Name = "ProSuffix",
	Parent = TitleLabel,
	BackgroundTransparency = 1,
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.new(0, 40, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "PRO",
	TextColor3 = Theme.AccentPink,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.MainUI + 1,
})

-- ═══════════════════════════════════════════════════════════════════════
-- SEARCH BAR
-- ═══════════════════════════════════════════════════════════════════════
local SearchFrame = Create("Frame", {
	Name = "SearchFrame",
	Parent = TopBar,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -220, 0.5, -13),
	Size = UDim2.new(0, 190, 0, 26),
	ZIndex = Z.MainUI + 2,
})
AddCorner(SearchFrame, 12)
AddStroke(SearchFrame, Theme.Border, 1)

Create("TextLabel", {
	Name = "SearchIcon",
	Parent = SearchFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 8, 0, 0),
	Size = UDim2.new(0, 20, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "🔍",
	TextColor3 = Theme.TextMuted,
	TextSize = 12,
	ZIndex = Z.MainUI + 3,
})

local SearchBox = Create("TextBox", {
	Name = "SearchBox",
	Parent = SearchFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 30, 0, 0),
	Size = UDim2.new(1, -40, 1, 0),
	Font = Enum.Font.Gotham,
	Text = "Search",
	TextColor3 = Theme.TextMuted,
	TextSize = 12,
	ZIndex = Z.MainUI + 3,
	ClearTextOnFocus = true,
	Active = true,
})

local SuggestFrame = Create("Frame", {
	Name = "Suggestions",
	Parent = ScreenGui,
	BackgroundColor3 = Theme.DropdownBg,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 190, 0, 0),
	Visible = false,
	ZIndex = Z.Search,
	ClipsDescendants = true,
	Active = true,
})
AddCorner(SuggestFrame, 6)
AddStroke(SuggestFrame, Theme.Border, 1)

local SuggestScroll = Create("ScrollingFrame", {
	Name = "Scroll",
	Parent = SuggestFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 5),
	Size = UDim2.new(1, 0, 1, -10),
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Theme.ScrollBar,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = Z.Search + 1,
	ScrollingEnabled = true,
	Active = true,
})

Create("UIListLayout", {
	Parent = SuggestScroll,
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder
})

-- ═══════════════════════════════════════════════════════════════════════
-- CLOSE BUTTON
-- ═══════════════════════════════════════════════════════════════════════
local CloseBtn = Create("TextButton", {
	Name = "CloseBtn",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -28, 0, 6),
	Size = UDim2.new(0, 22, 0, 22),
	Font = Enum.Font.GothamBold,
	Text = "×",
	TextColor3 = Theme.TextSecondary,
	TextSize = 20,
	ZIndex = Z.MainUI + 1,
	Active = true,
	AutoButtonColor = false,
})

CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {TextColor3 = Theme.AccentRed}, 0.15) end)
CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {TextColor3 = Theme.TextSecondary}, 0.15) end)
CloseBtn.Activated:Connect(function() MainFrame.Visible = false end)

-- ═══════════════════════════════════════════════════════════════════════
-- LEFT SIDEBAR
-- ═══════════════════════════════════════════════════════════════════════
local Sidebar = Create("Frame", {
	Name = "Sidebar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Sidebar,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 0, 40),
	Size = UDim2.new(0, Config.SidebarWidth, 1, -40),
	ZIndex = Z.MainUI,
})
AddCorner(Sidebar, 12)

local SidebarScroll = Create("ScrollingFrame", {
	Name = "Scroll",
	Parent = Sidebar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 5),
	Size = UDim2.new(1, 0, 1, -10),
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Theme.ScrollBar,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = Z.MainUI + 1,
	ScrollingEnabled = true,
	Active = true,
})

Create("UIListLayout", {
	Parent = SidebarScroll,
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder
})

-- ═══════════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ═══════════════════════════════════════════════════════════════════════
local ContentFrame = Create("Frame", {
	Name = "ContentFrame",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(0, Config.SidebarWidth, 0, 40),
	Size = UDim2.new(1, -Config.SidebarWidth, 1, -40),
	ZIndex = Z.MainUI,
	ClipsDescendants = true,
})
AddCorner(ContentFrame, 12)

local ContentTitle = Create("TextLabel", {
	Name = "Title",
	Parent = ContentFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 10),
	Size = UDim2.new(1, -30, 0, 22),
	Font = Enum.Font.GothamBold,
	Text = "Home",
	TextColor3 = Theme.TextPrimary,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.MainUI + 1,
})

local ContentSubtitle = Create("TextLabel", {
	Name = "Subtitle",
	Parent = ContentFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 32),
	Size = UDim2.new(1, -30, 0, 15),
	Font = Enum.Font.Gotham,
	Text = "Game Version: v2984 [US]",
	TextColor3 = Theme.TextMuted,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.MainUI + 1,
})

local ContentScroll = Create("ScrollingFrame", {
	Name = "ContentScroll",
	Parent = ContentFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 52),
	Size = UDim2.new(1, -20, 1, -62),
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Theme.ScrollBar,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = Z.MainUI + 1,
	ScrollingEnabled = true,
	Active = true,
	ClipsDescendants = true,
})

Create("UIGridLayout", {
	Parent = ContentScroll,
	CellSize = UDim2.new(0.5, -5, 0, 36),
	CellPadding = UDim2.new(0, 5, 0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder
})

-- ═══════════════════════════════════════════════════════════════════════
-- DROPDOWN LAYER
-- ═══════════════════════════════════════════════════════════════════════
local DropdownLayer = Create("Frame", {
	Name = "DropdownLayer",
	Parent = ContentFrame,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 10, 0, 52),
	Size = UDim2.new(1, -20, 1, -62),
	ZIndex = Z.Dropdown,
	ClipsDescendants = true,
	Active = false,
})

-- ═══════════════════════════════════════════════════════════════════════
-- MODAL POPUP
-- ═══════════════════════════════════════════════════════════════════════
local ModalOverlay = Create("Frame", {
	Name = "ModalOverlay",
	Parent = ScreenGui,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 1, 0),
	Visible = false,
	ZIndex = Z.Modal,
	Active = true,
})

local ModalFrame = Create("Frame", {
	Name = "ModalFrame",
	Parent = ModalOverlay,
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -150, 0.5, -75),
	Size = UDim2.new(0, 300, 0, 150),
	ZIndex = Z.ModalFrame,
})
AddCorner(ModalFrame, 8)
AddStroke(ModalFrame, Theme.Border, 2)

local ModalTitle = Create("TextLabel", {
	Name = "Title",
	Parent = ModalFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 10),
	Size = UDim2.new(1, -30, 0, 25),
	Font = Enum.Font.GothamBold,
	Text = "Select Item",
	TextColor3 = Theme.TextPrimary,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.ModalCtrl,
})

local ModalDone = Create("TextButton", {
	Name = "DoneBtn",
	Parent = ModalFrame,
	BackgroundColor3 = Theme.Accent,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -85, 0, 8),
	Size = UDim2.new(0, 75, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Done",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	ZIndex = Z.ModalCtrl,
	Active = true,
	AutoButtonColor = false,
})
AddCorner(ModalDone, 6)

local ModalScroll = Create("ScrollingFrame", {
	Name = "Scroll",
	Parent = ModalFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 45),
	Size = UDim2.new(1, -20, 1, -55),
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Theme.ScrollBar,
	ZIndex = Z.ModalCtrl,
	ScrollingEnabled = true,
	Active = true,
})

Create("UIListLayout", {
	Parent = ModalScroll,
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder
})

ModalDone.Activated:Connect(function()
	ModalOverlay.Visible = false
	for _, child in pairs(ModalScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- FOOTER
-- ═══════════════════════════════════════════════════════════════════════
Create("TextLabel", {
	Name = "Footer",
	Parent = MainFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, Config.SidebarWidth, 1, -20),
	Size = UDim2.new(1, -Config.SidebarWidth, 0, 20),
	Font = Enum.Font.Gotham,
	Text = "exotichub.app/join",
	TextColor3 = Theme.TextMuted,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = Z.MainUI + 1,
})

-- ═══════════════════════════════════════════════════════════════════════
-- STATE VARIABLES
-- ═══════════════════════════════════════════════════════════════════════
local CurrentPage = "Home"
local ActiveDropdownCard = nil
local ActiveDropdownFrame = nil
local IsClosingDropdown = false
local DropdownDebounce = false
local SidebarButtons = {}
local SearchableItems = {}
local CardLayoutOrder = 0
local StickyHeartbeat = nil

-- ═══════════════════════════════════════════════════════════════════════
-- STICKY DROPDOWN
-- ═══════════════════════════════════════════════════════════════════════
local CloseDropdown  -- forward declaration so UpdateDropdownPosition can call it

local function UpdateDropdownPosition()
	if not ActiveDropdownFrame or not ActiveDropdownCard then return end
	if not ActiveDropdownCard.Parent then CloseDropdown() return end
	local cardAbs = ActiveDropdownCard.AbsolutePosition
	local layerAbs = DropdownLayer.AbsolutePosition
	local relX = cardAbs.X - layerAbs.X
	local relY = cardAbs.Y - layerAbs.Y + ActiveDropdownCard.AbsoluteSize.Y + 2
	ActiveDropdownFrame.Position = UDim2.new(0, relX, 0, relY)
end

local function StartStickyDropdown()
	if StickyHeartbeat then StickyHeartbeat:Disconnect() StickyHeartbeat = nil end
	StickyHeartbeat = RunService.Heartbeat:Connect(UpdateDropdownPosition)
end

local function StopStickyDropdown()
	if StickyHeartbeat then StickyHeartbeat:Disconnect() StickyHeartbeat = nil end
end

-- ═══════════════════════════════════════════════════════════════════════
-- DROPDOWN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════
function CloseDropdown()
	if IsClosingDropdown or not ActiveDropdownFrame then return end
	IsClosingDropdown = true
	DropdownDebounce = false
	StopStickyDropdown()

	if ActiveDropdownCard then
		local arrow = ActiveDropdownCard:FindFirstChild("Arrow")
		if arrow then arrow.Text = ">" end
		Tween(ActiveDropdownCard, {BackgroundColor3 = Theme.Card}, 0.15)
		ActiveDropdownCard = nil
	end

	local frame = ActiveDropdownFrame
	ActiveDropdownFrame = nil
	Tween(frame, {Size = UDim2.new(0, frame.Size.X.Offset, 0, 0)}, 0.15)
	task.wait(0.15)
	if frame and frame.Parent then frame:Destroy() end
	IsClosingDropdown = false
end

local function ClearContent()
	ContentScroll.CanvasPosition = Vector2.new(0, 0)
	CloseDropdown()
	for _, child in pairs(ContentScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
	end
	CardLayoutOrder = 0
end

-- ═══════════════════════════════════════════════════════════════════════
-- UI BUILDERS
-- ═══════════════════════════════════════════════════════════════════════
local function CreateCard(title, icon, iconColor)
	local card = Create("TextButton", {
		Name = title,
		Parent = ContentScroll,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = CardLayoutOrder,
		Font = Enum.Font.Gotham,
		Text = "",
		ZIndex = Z.Card,
		Active = true,
		AutoButtonColor = false,
	})
	CardLayoutOrder = CardLayoutOrder + 1
	AddCorner(card, 6)
	AddStroke(card, Theme.Border, 1)

	Create("TextLabel", {
		Name = "Icon",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 20, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = icon or "⚙",
		TextColor3 = iconColor or Theme.Accent,
		TextSize = 14,
		ZIndex = Z.Card + 1,
	})

	Create("TextLabel", {
		Name = "Title",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 35, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Z.Card + 1,
	})

	Create("TextLabel", {
		Name = "Arrow",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -22, 0, 0),
		Size = UDim2.new(0, 18, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = ">",
		TextColor3 = Theme.TextSecondary,
		TextSize = 14,
		ZIndex = Z.Card + 1,
	})

	card.MouseEnter:Connect(function()
		if ActiveDropdownCard ~= card then Tween(card, {BackgroundColor3 = Theme.CardHover}, 0.15) end
	end)
	card.MouseLeave:Connect(function()
		if ActiveDropdownCard ~= card then Tween(card, {BackgroundColor3 = Theme.Card}, 0.15) end
	end)

	return card
end

local function ToggleDropdown(card, buildContentFunction)
	if IsClosingDropdown then return end
	if ActiveDropdownCard == card and ActiveDropdownFrame then CloseDropdown() return end
	if DropdownDebounce then return end
	DropdownDebounce = true

	CloseDropdown()
	ActiveDropdownCard = card
	Tween(card, {BackgroundColor3 = Theme.CardHover}, 0.15)
	local arrow = card:FindFirstChild("Arrow")
	if arrow then arrow.Text = "v" end

	local cardAbs = card.AbsolutePosition
	local layerAbs = DropdownLayer.AbsolutePosition
	local relX = cardAbs.X - layerAbs.X
	local relY = cardAbs.Y - layerAbs.Y + card.AbsoluteSize.Y + 2

	local drop = Create("TextButton", {
		Name = "Dropdown",
		Parent = DropdownLayer,
		BackgroundColor3 = Theme.DropdownBg,
		BorderSizePixel = 0,
		Position = UDim2.new(0, relX, 0, relY),
		Size = UDim2.new(0, card.AbsoluteSize.X, 0, 0),
		ZIndex = Z.Dropdown,
		ClipsDescendants = true,
		Active = true,
		AutoButtonColor = false,
		Text = "",
	})
	AddCorner(drop, 6)
	AddStroke(drop, Theme.Border, 1)

	local closeDropBtn = Create("TextButton", {
		Name = "CloseBtn",
		Parent = drop,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -24, 0, 4),
		Size = UDim2.new(0, 20, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Theme.TextSecondary,
		TextSize = 16,
		ZIndex = Z.DropControl,
		Active = true,
		AutoButtonColor = false,
	})
	closeDropBtn.Activated:Connect(CloseDropdown)
	closeDropBtn.MouseEnter:Connect(function() Tween(closeDropBtn, {TextColor3 = Theme.AccentRed}, 0.15) end)
	closeDropBtn.MouseLeave:Connect(function() Tween(closeDropBtn, {TextColor3 = Theme.TextSecondary}, 0.15) end)

	local scroll = Create("ScrollingFrame", {
		Name = "Scroll",
		Parent = drop,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 1, -26),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = Z.DropScroll,
		ClipsDescendants = true,
		Active = true,
		ScrollingEnabled = true,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})

	local listLayout = Create("UIListLayout", {
		Parent = scroll,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})

	Create("UIPadding", {
		Parent = scroll,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	buildContentFunction(scroll)
	task.wait()

	local contentHeight = listLayout.AbsoluteContentSize.Y + 16
	local maxHeight = math.min(contentHeight, 260)
	local width = card.AbsoluteSize.X

	scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	ActiveDropdownFrame = drop
	Tween(drop, {Size = UDim2.new(0, width, 0, maxHeight)}, 0.2)
	StartStickyDropdown()

	task.delay(0.25, function() DropdownDebounce = false end)
end

local function CreateToggle(parent, text, defaultState, onToggleCallback)
	local container = Create("Frame", {
		Name = text .. "Toggle",
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 30),
		ZIndex = Z.DropControl,
		Active = true,
	})

	Create("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = Theme.TextPrimary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Z.DropControl,
	})

	local toggleBg = Create("TextButton", {
		Parent = container,
		BackgroundColor3 = defaultState and Theme.ToggleOn or Theme.ToggleBg,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -46, 0.5, -10),
		Size = UDim2.new(0, 40, 0, 20),
		ZIndex = Z.DropControl,
		Active = true,
		AutoButtonColor = false,
		Text = "",
	})
	AddCorner(toggleBg, 10)

	local knob = Create("Frame", {
		Parent = toggleBg,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = defaultState and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = Z.DropControl + 1,
	})
	AddCorner(knob, 8)

	local state = defaultState or false
	toggleBg.Activated:Connect(function()
		state = not state
		Tween(toggleBg, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleBg}, 0.2)
		Tween(knob, {Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)}, 0.2)
		if onToggleCallback then onToggleCallback(state) end
	end)

	return container, function() return state end
end

local function CreateLabel(parent, text, textColor, fontSize)
	return Create("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, fontSize or 20),
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = textColor or Theme.TextSecondary,
		TextSize = fontSize or 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Z.DropControl,
	})
end

local function CreateBtn(parent, text, bgColor, width)
	local btn = Create("TextButton", {
		Parent = parent,
		BackgroundColor3 = bgColor or Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(0, width or 70, 0, 26),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = Theme.TextPrimary,
		TextSize = 11,
		ZIndex = Z.DropControl,
		Active = true,
		AutoButtonColor = false,
	})
	AddCorner(btn, 5)
	AddStroke(btn, Theme.Border, 1)
	AddButtonEffects(btn, bgColor or Theme.Card)
	return btn
end

local function ShowModal(titleText, items, onSelectCallback)
	ModalFrame.Title.Text = titleText
	for _, item in pairs(items) do
		local btn = Create("TextButton", {
			Parent = ModalScroll,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, 34),
			Font = Enum.Font.Gotham,
			Text = item,
			TextColor3 = Theme.TextPrimary,
			TextSize = 13,
			ZIndex = Z.ModalCtrl,
			Active = true,
			AutoButtonColor = false,
		})
		AddCorner(btn, 4)
		AddButtonEffects(btn, Theme.Card)
		btn.Activated:Connect(function()
			if onSelectCallback then onSelectCallback(item) end
			btn.BackgroundColor3 = Theme.Accent
			task.wait(0.1)
			btn.BackgroundColor3 = Theme.Card
		end)
	end
	ModalScroll.CanvasSize = UDim2.new(0, 0, 0, #items * 37)
	ModalOverlay.Visible = true
end

-- ═══════════════════════════════════════════════════════════════════════
-- SEARCH SYSTEM
-- ═══════════════════════════════════════════════════════════════════════
local function RegisterSearch(name, pageName, icon, action)
	table.insert(SearchableItems, {Name = name, Page = pageName, Icon = icon, Action = action})
end

local function UpdateSuggestions()
	for _, child in pairs(SuggestScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local text = SearchBox.Text:lower()
	if text == "" or text == "search" then SuggestFrame.Visible = false return end

	local matches = {}
	for _, item in pairs(SearchableItems) do
		if item.Name:lower():find(text, 1, true) then table.insert(matches, item) end
	end

	if #matches == 0 then SuggestFrame.Visible = false return end

	local absPos = SearchFrame.AbsolutePosition
	local absSize = SearchFrame.AbsoluteSize
	SuggestFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
	SuggestFrame.Size = UDim2.new(0, absSize.X, 0, math.min(#matches * 32 + 10, 200))

	for _, item in pairs(matches) do
		local btn = Create("TextButton", {
			Parent = SuggestScroll,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, 30),
			Position = UDim2.new(0, 5, 0, 0),
			Font = Enum.Font.Gotham,
			Text = item.Icon .. "  " .. item.Name,
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = Z.Search + 1,
			Active = true,
			AutoButtonColor = false,
		})
		AddCorner(btn, 4)
		AddButtonEffects(btn, Theme.Card)
		btn.Activated:Connect(function()
			SuggestFrame.Visible = false
			SearchBox.Text = "Search"
			if item.Action then item.Action() end
		end)
	end

	SuggestScroll.CanvasSize = UDim2.new(0, 0, 0, #matches * 32)
	SuggestFrame.Visible = true
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(UpdateSuggestions)
SearchBox.FocusLost:Connect(function()
	if SearchBox.Text == "" then SearchBox.Text = "Search" end
	task.wait(0.2)
	SuggestFrame.Visible = false
end)
SearchBox.Focused:Connect(function()
	if SearchBox.Text ~= "Search" and SearchBox.Text ~= "" then UpdateSuggestions() end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- GLOBAL CLICK HANDLER
-- ═══════════════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 
		and input.UserInputType ~= Enum.UserInputType.Touch then return end
	if gameProcessed then return end

	local pos = input.Position
	local function isInside(gui)
		if not gui or not gui.Parent then return false end
		local ap = gui.AbsolutePosition
		local as = gui.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end

	if SuggestFrame and SuggestFrame.Visible then
		if not isInside(SearchFrame) and not isInside(SuggestFrame) then
			SuggestFrame.Visible = false
		end
	end

	if ActiveDropdownFrame and ActiveDropdownFrame.Parent then
		if isInside(ActiveDropdownFrame) then return end
		if ActiveDropdownCard and isInside(ActiveDropdownCard) then return end
		CloseDropdown()
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE SYSTEM
-- ═══════════════════════════════════════════════════════════════════════
local function SwitchPage(pageName, title, subtitle, contentBuilder)
	CurrentPage = pageName
	ContentTitle.Text = title
	ContentSubtitle.Text = subtitle or ""
	ClearContent()
	contentBuilder()
end

local Pages = {}

-- ═══════════════════════════════════════════════════════════════════════
-- PAGES
-- ═══════════════════════════════════════════════════════════════════════
function Pages.Account()
	SwitchPage("Account", "Account", "Exotic Hub account", function()
		local accountCard = CreateCard("Account", "👤", Theme.Accent)
		accountCard.Activated:Connect(function()
			ToggleDropdown(accountCard, function(scroll)
				CreateLabel(scroll, "Key expires in 5 days 15\nhours 32 min", Theme.TextSecondary, 12)
				local discordBtn = CreateBtn(scroll, "Join Discord", Theme.Card, 120)
				discordBtn.Size = UDim2.new(1, -8, 0, 30)
			end)
		end)

		local logoutCard = CreateCard("Logout", "🔒", Theme.AccentRed)
		logoutCard.Activated:Connect(function()
			ToggleDropdown(logoutCard, function(scroll)
				local logoutBtn = CreateBtn(scroll, "Logout", Theme.AccentRed, 120)
				logoutBtn.Size = UDim2.new(1, -8, 0, 30)
				logoutBtn.Activated:Connect(function() print("Logout clicked!") end)
			end)
		end)
	end)
end
RegisterSearch("Account", "Account", "👤", function() SidebarButtons["Account"]() end)
RegisterSearch("Logout", "Account", "🔒", function() SidebarButtons["Account"]() end)

function Pages.Home()
	SwitchPage("Home", "Home", "Game Version: v2984 [US]", function()
		local hatchCard = CreateCard("Auto Hatch", "🥚", Theme.Accent)
		hatchCard.Activated:Connect(function()
			ToggleDropdown(hatchCard, function(scroll)
				CreateLabel(scroll, "🟢 Hatching Complete.\n\nPets In Inventory: 235 / 235\nMax Eggs Allowed: 13\nMax Pets Equip Allowed: 8\nEggs Planted: 13", Theme.TextSecondary, 11)
				CreateLabel(scroll, "⚠️ [Warning] Do not trade,\nunfavourite or gift while\nthe hatching system is\nactive!", Theme.AccentRed, 11)
				CreateToggle(scroll, "Enable Auto Hatch", false, function(isEnabled)
					if isEnabled then AutoHatchScript:Toggle() else AutoHatchScript:Toggle() end
				end)
			end)
		end)
		RegisterSearch("Auto Hatch", "Home", "🥚", function() SidebarButtons["Home"]() end)

		local systemCard = CreateCard("System", "⚙", Theme.Accent)
		systemCard.Activated:Connect(function()
			ToggleDropdown(systemCard, function(scroll)
				CreateLabel(scroll, "⏸️ Pause all systems.\nThis does NOT pause\nhatching or mutation.", Theme.AccentOrange, 11)
				CreateToggle(scroll, "Pause All Systems", false, function(isEnabled) print("Pause All:", isEnabled) end)
			end)
		end)
		RegisterSearch("System", "Home", "⚙", function() SidebarButtons["Home"]() end)

		local farmCard = CreateCard("Farm Details", "🌾", Theme.AccentGreen)
		farmCard.Activated:Connect(function()
			ToggleDropdown(farmCard, function(scroll)
				CreateLabel(scroll, "Plants In Farm x0", Theme.AccentGreen, 12)
				CreateToggle(scroll, "Enable Auto Farm", false, function(isEnabled)
					if isEnabled then AutoFarmScript:Toggle() else AutoFarmScript:Toggle() end
				end)
			end)
		end)
	end)
end
RegisterSearch("Home", "Home", "🏠", function() SidebarButtons["Home"]() end)

function Pages.Premium()
	SwitchPage("Premium", "Premium", "Premium Features", function()
		local giftCard = CreateCard("🎁 Gifting / Trade 💎", "🎁", Theme.Accent)
		giftCard.Activated:Connect(function()
			ToggleDropdown(giftCard, function(scroll)
				CreateToggle(scroll, "Auto Accept Gift", false, function(state) print("Auto Accept Gift:", state) end)
				CreateToggle(scroll, "Auto Accept Trade", false, function(state) print("Auto Accept Trade:", state) end)
				CreateLabel(scroll, "🐾 Pets", Theme.TextSecondary, 12)

				local petSelBtn = Create("TextButton", {
					Parent = scroll,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Size = UDim2.new(1, -8, 0, 26),
					Font = Enum.Font.Gotham,
					Text = "Mimic Octopus    ^",
					TextColor3 = Theme.TextPrimary,
					TextSize = 12,
					ZIndex = Z.DropControl,
					Active = true,
					AutoButtonColor = false,
				})
				AddCorner(petSelBtn, 4)
				AddStroke(petSelBtn, Theme.Border, 1)
				AddButtonEffects(petSelBtn, Theme.Card)
				petSelBtn.Activated:Connect(function()
					ShowModal("Select Pet", {"Mimic Octopus", "Rainbow Bird", "Bacon Pig", "Parasaurolophus", "Goose", "Seal"}, function(selected)
						petSelBtn.Text = selected .. "    ^"
					end)
				end)

				local btnRow = Create("Frame", {Parent = scroll, BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 26), ZIndex = Z.DropControl})
				local selAllBtn = CreateBtn(btnRow, "Select All", Theme.Accent, 70)
				selAllBtn.Position = UDim2.new(0, 0, 0, 0)
				local remAllBtn = CreateBtn(btnRow, "Remove All", Theme.AccentRed, 70)
				remAllBtn.Position = UDim2.new(0, 75, 0, 0)

				CreateLabel(scroll, "🧬 Mutations\n---", Theme.TextSecondary, 11)
				CreateLabel(scroll, "Min Level 1\n1", Theme.TextSecondary, 11)
				CreateLabel(scroll, "Max Level 99\n99", Theme.TextSecondary, 11)
			end)
		end)

		local premiumItems = {
			{"Pick Place", "🎯", Theme.AccentCyan},
			{"PickPlace Override", "⚡", Theme.AccentYellow},
			{"Enhancer Pro", "🔥", Theme.AccentOrange},
			{"Test Options", "🧪", Theme.AccentGreen},
			{"Horseman & Elephant", "🐴", Theme.Accent},
			{"Premium Market", "🛒", Theme.Accent},
			{"Matching Options", "🔥", Theme.AccentRed},
			{"Experiments", "🧪", Theme.AccentGreen},
			{"Trade World", "🌐", Theme.Accent}
		}

		for _, item in pairs(premiumItems) do
			local card = CreateCard(item[1], item[2], item[3])
			card.Activated:Connect(function()
				ToggleDropdown(card, function(scroll)
					CreateLabel(scroll, "Options for " .. item[1], Theme.TextSecondary, 12)
				end)
			end)
			RegisterSearch(item[1], "Premium", item[2], function() SidebarButtons["Premium"]() end)
		end
	end)
end
RegisterSearch("Premium", "Premium", "💎", function() SidebarButtons["Premium"]() end)
RegisterSearch("Gifting", "Premium", "🎁", function() SidebarButtons["Premium"]() end)
RegisterSearch("Trade", "Premium", "💎", function() SidebarButtons["Premium"]() end)

function Pages.HatchingTeams()
	SwitchPage("Hatching Teams", "Hatching Teams", "Manage teams used for\nhatching pets efficiently.", function()
		local eggCard = CreateCard("Egg Reduction [Peacock]", "🥚", Theme.Accent)
		eggCard.Activated:Connect(function()
			ToggleDropdown(eggCard, function(scroll)
				CreateLabel(scroll, "⭐ Speeds up egg timer.\nPets: Mimics, Peacock,\nBald Eagles", Theme.AccentYellow, 11)
				CreateLabel(scroll, "Selected: 8/8", Theme.TextSecondary, 11)

				local btnRow = Create("Frame", {Parent = scroll, BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 26), ZIndex = Z.DropControl})
				local equipBtn = CreateBtn(btnRow, "Equip", Theme.Accent, 55)
				equipBtn.Position = UDim2.new(0, 0, 0, 0)
				local unequipBtn = CreateBtn(btnRow, "UnEquip", Theme.AccentRed, 55)
				unequipBtn.Position = UDim2.new(0, 60, 0, 0)
				local reloadBtn = CreateBtn(btnRow, "Reload", Theme.AccentGreen, 55)
				reloadBtn.Position = UDim2.new(0, 120, 0, 0)

				CreateLabel(scroll, "🍬 Pet Boosts\n---", Theme.TextSecondary, 11)
				CreateToggle(scroll, "Enable Boosts", false, function(state) end)

				local teamBtn = CreateBtn(scroll, "🥚 Egg Reduction Team", Theme.Card, 180)
				teamBtn.Size = UDim2.new(1, -8, 0, 26)
				teamBtn.Activated:Connect(function()
					ShowModal("Reduction Team", {
						"⭐61.05kg [UF]Rainbow Birb",
						"⭐283.57kg [VE]Mimic Octopus",
						"⭐284.98kg [UF]Mimic Octopus",
						"⭐329.58kg [UF]Mimic Octopus",
						"⭐355.93kg [UF]Mimic Octopus"
					}, nil)
				end)
			end)
		end)

		local teamItems = {
			{"Hatch Egg [Koi]", "🐟", Theme.Accent},
			{"Pet Size [Bronto]", "📏", Theme.Accent},
			{"Sell Egg [Seal]", "💰", Theme.Accent},
			{"Options", "⚙", Theme.Accent},
			{"Auto Rejoin", "🔄", Theme.Accent},
			{"Sticky Pets", "🧪", Theme.AccentGreen},
			{"Pet Overrides", "🐾", Theme.Accent},
			{"Egg Overrides", "🥚", Theme.Accent},
			{"Pet Mutations", "🧬", Theme.Accent}
		}

		for _, item in pairs(teamItems) do
			local card = CreateCard(item[1], item[2], item[3])
			card.Activated:Connect(function()
				ToggleDropdown(card, function(scroll)
					CreateLabel(scroll, "Options for " .. item[1], Theme.TextSecondary, 12)
				end)
			end)
		end
	end)
end
RegisterSearch("Hatching Teams", "Hatching Teams", "🥚", function() SidebarButtons["Hatching Teams"]() end)

function Pages.PetManager()
	SwitchPage("Pet Manager", "Pet Manager", "Feed, grow, and manage\nyour pets with ease.", function()
		local feedCard = CreateCard("Pet Feeding System", "🍼", Theme.Accent)
		feedCard.Activated:Connect(function()
			ToggleDropdown(feedCard, function(scroll)
				CreateLabel(scroll, "🔴 Not running", Theme.AccentRed, 11)
				CreateLabel(scroll, "🐾 Exclude Pets\nSeal, Brontosaurus, Koi", Theme.TextSecondary, 11)
				CreateLabel(scroll, "🌱 Exclude Plants\nFour Leaf Clover", Theme.TextSecondary, 11)
				CreateLabel(scroll, "⚠️ Feeds all active pets\nwith hunger under 60%.", Theme.AccentYellow, 10)
				CreateToggle(scroll, "Auto Feed Pet", false, function(isEnabled)
					if isEnabled then AutoFeedScript:Toggle() else AutoFeedScript:Toggle() end
				end)
			end)
		end)

		local petItems = {
			{"Auto Toys", "🧸", Theme.AccentOrange},
			{"Pet Marmot", "🐿", Theme.Accent},
			{"Pet Level-Up", "⬆", Theme.AccentCyan},
			{"Red Panda", "🐼", Theme.AccentRed},
			{"Chubby Chipmunk", "🐿", Theme.Accent},
			{"Favorite Pets", "⭐", Theme.Accent},
			{"Magpie Rewards", "🎁", Theme.AccentPink},
			{"Easter Bunny", "🐰", Theme.Accent},
			{"Bearded Dragon", "🐉", Theme.AccentGreen}
		}

		for _, item in pairs(petItems) do
			local card = CreateCard(item[1], item[2], item[3])
			card.Activated:Connect(function()
				ToggleDropdown(card, function(scroll)
					CreateLabel(scroll, "Options for " .. item[1], Theme.TextSecondary, 12)
				end)
			end)
		end
	end)
end
RegisterSearch("Pet Manager", "Pet Manager", "🐾", function() SidebarButtons["Pet Manager"]() end)

function Pages.CraftAndCook()
	SwitchPage("Craft and Cook", "Craft and Cook", "Automatically craft items\nand manage your workbench", function()
		local benchCard = CreateCard("🔥 Work Bench(s) 🔥", "🔥", Theme.AccentOrange)
		benchCard.Activated:Connect(function()
			ToggleDropdown(benchCard, function(scroll)
				CreateLabel(scroll, "🔴 Not running", Theme.AccentRed, 11)
				CreateLabel(scroll, "ℹ️ Select recipes and\n[Enable] to craft.", Theme.AccentCyan, 11)
				CreateLabel(scroll, "⚠️ Auto-Craft your items\nautomatically.", Theme.AccentYellow, 10)
				CreateToggle(scroll, "Auto-Craft", false, function(isEnabled)
					if isEnabled then AutoCraftScript:Toggle() else AutoCraftScript:Toggle() end
				end)
			end)
		end)

		local cookCard = CreateCard("Cooking Pots", "🍳", Theme.AccentGreen)
		cookCard.Activated:Connect(function()
			ToggleDropdown(cookCard, function(scroll)
				CreateLabel(scroll, "Cooking options...", Theme.TextSecondary, 12)
			end)
		end)

		local teamCard = CreateCard("Craft Teams", "⚔", Theme.AccentCyan)
		teamCard.Activated:Connect(function()
			ToggleDropdown(teamCard, function(scroll)
				CreateLabel(scroll, "Team options...", Theme.TextSecondary, 12)
			end)
		end)
	end)
end
RegisterSearch("Craft and Cook", "Craft and Cook", "🔥", function() SidebarButtons["Craft and Cook"]() end)

function Pages.Placeholder(title, subtitle, icon)
	return function()
		SwitchPage(title, title, subtitle or "", function()
			CreateCard("Coming Soon", icon or "📦", Theme.TextMuted)
			CreateLabel(ContentScroll, "This feature is not yet available.", Theme.TextMuted, 16)
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SIDEBAR SETUP
-- ═══════════════════════════════════════════════════════════════════════
local SidebarItems = {
	{ Name = "Account",      Icon = "👤", Color = Theme.Accent,       Page = Pages.Account },
	{ Name = "Home",         Icon = "🏠", Color = Theme.Accent,       Page = Pages.Home },
	{ Name = "Premium",      Icon = "💎", Color = Theme.AccentPink,   Page = Pages.Premium },
	{ Name = "Hatching Teams", Icon = "🥚", Color = Theme.AccentOrange, Page = Pages.HatchingTeams },
	{ Name = "Eggs Priority", Icon = "🥚", Color = Theme.Accent, Page = Pages.Placeholder("Eggs Priority", "Manage egg priorities", "🥚") },
	{ Name = "Pet Sell Settings", Icon = "💰", Color = Theme.Accent, Page = Pages.Placeholder("Pet Sell Settings", "Configure auto-sell", "💰") },
	{ Name = "Plants & Packs", Icon = "🌱", Color = Theme.AccentGreen, Page = Pages.Placeholder("Plants & Packs", "Manage plants", "🌱") },
	{ Name = "Event & Mutation", Icon = "🧬", Color = Theme.AccentCyan, Page = Pages.Placeholder("Event & Mutation", "Event settings", "🧬") },
	{ Name = "Pet Manager",  Icon = "🐾", Color = Theme.AccentYellow, Page = Pages.PetManager },
	{ Name = "Craft and Cook", Icon = "🔥", Color = Theme.AccentOrange, Page = Pages.CraftAndCook },
	{ Name = "Fruit Collection", Icon = "🍎", Color = Theme.Accent, Page = Pages.Placeholder("Fruit Collection", "Collect fruits", "🍎") }
}

for index, item in ipairs(SidebarItems) do
	local btn = Create("TextButton", {
		Name = item.Name,
		Parent = SidebarScroll,
		BackgroundColor3 = (index == 2) and Theme.Card or Theme.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -10, 0, 32),
		Position = UDim2.new(0, 5, 0, 0),
		Font = Enum.Font.Gotham,
		Text = "  " .. item.Icon .. "  " .. item.Name,
		TextColor3 = item.Color,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		ZIndex = Z.MainUI + 2,
		Active = true,
	})
	AddCorner(btn, 4)

	SidebarButtons[item.Name] = function()
		CurrentPage = item.Name
		for _, child in pairs(SidebarScroll:GetChildren()) do
			if child:IsA("TextButton") then
				local isSelected = (child.Name == item.Name)
				Tween(child, {BackgroundColor3 = isSelected and Theme.Card or Theme.Sidebar}, 0.2)
			end
		end
		item.Page()
	end

	btn.MouseEnter:Connect(function()
		if CurrentPage ~= item.Name then Tween(btn, {BackgroundColor3 = Theme.CardHover}, 0.15) end
	end)
	btn.MouseLeave:Connect(function()
		if CurrentPage ~= item.Name then Tween(btn, {BackgroundColor3 = Theme.Sidebar}, 0.15) end
	end)
	btn.Activated:Connect(SidebarButtons[item.Name])
	RegisterSearch(item.Name, item.Name, item.Icon, SidebarButtons[item.Name])
end

-- ═══════════════════════════════════════════════════════════════════════
-- MOBILE SUPPORT
-- ═══════════════════════════════════════════════════════════════════════
if UserInputService.TouchEnabled then
	local viewport = workspace.CurrentCamera.ViewportSize
	MainFrame.Size = UDim2.new(0, math.min(Config.WindowWidth, viewport.X - 20), 0, math.min(Config.WindowHeight, viewport.Y - 40))
	MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
end

-- ═══════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════
Pages.Home()
print("✅ Exotic Hub PRO v10.8 loaded successfully!")
print("📁 Click the 'Exotic' toggle button to show/hide the UI.")
print("📁 Drag the toggle button to move it anywhere on screen.")