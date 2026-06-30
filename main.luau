-- ═══════════════════════════════════════════════════════════════════════
-- SERVICES (Roblox built-in systems we need access to)
-- ═══════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players") -- Access to player data
local TweenService = game:GetService("TweenService") -- Smooth animations
local UserInputService = game:GetService("UserInputService") -- Detects clicks/touches/keyboard
local RunService = game:GetService("RunService") -- Runs code every frame (for smooth dragging)

-- ═══════════════════════════════════════════════════════════════════════
-- PLAYER SETUP (Gets the local player who runs this script)
-- ═══════════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") -- Where UI elements are stored

-- ═══════════════════════════════════════════════════════════════════════
-- 🔧 CONFIG SECTION (Easy-to-change settings for the whole UI)
-- ═══════════════════════════════════════════════════════════════════════
local Config = {
	WindowWidth = 550, -- Default width of main window (pixels)
	WindowHeight = 300, -- Default height of main window (pixels)
	MinWindowWidth = 300, -- Minimum width when resizing (prevents too small)
	MinWindowHeight = 200, -- Minimum height when resizing
	SidebarWidth = 160, -- Width of left navigation panel
	EnableSearch = true, -- Enable the search bar feature
	ToggleButtonText = "_hub", -- Text shown on the floating toggle button
}
-- ═══════════════════════════════════════════════════════════════════════
-- 🎨 THEME SECTION (Color palette - change these to retheme the whole UI)
-- ═══════════════════════════════════════════════════════════════════════

local Theme = {
	Background = Color3.fromRGB(22, 22, 26), -- Main window background
	Sidebar = Color3.fromRGB(28, 28, 32), -- Left panel background
	Content = Color3.fromRGB(18, 18, 22), -- Right content area background
	Card = Color3.fromRGB(35, 35, 40), -- Card/button background
	CardHover = Color3.fromRGB(45, 45, 50), -- Card color when mouse hovers
	DropdownBg = Color3.fromRGB(32, 32, 38), -- Dropdown menu background
	TextPrimary = Color3.fromRGB(255, 255, 255), -- Main text color (white)
	TextSecondary = Color3.fromRGB(160, 160, 160), -- Secondary text (gray)
	TextMuted = Color3.fromRGB(100, 100, 100), -- Dimmed text
	Accent = Color3.fromRGB(147, 112, 219), -- Purple accent color
	AccentPink = Color3.fromRGB(255, 105, 180), -- Pink accent
	AccentCyan = Color3.fromRGB(0, 255, 255), -- Cyan accent
	AccentGreen = Color3.fromRGB(50, 205, 50), -- Green accent
	AccentRed = Color3.fromRGB(255, 80, 80), -- Red accent (for warnings/errors)
	AccentOrange = Color3.fromRGB(255, 165, 0), -- Orange accent
	AccentYellow = Color3.fromRGB(255, 215, 0), -- Yellow accent
	Border = Color3.fromRGB(50, 50, 55), -- Border/stroke color
	ToggleBg = Color3.fromRGB(60, 60, 65), -- Toggle switch background (OFF)
	ToggleOn = Color3.fromRGB(147, 112, 219), -- Toggle switch background (ON)
	ScrollBar = Color3.fromRGB(60, 60, 70), -- Scrollbar color
}

-- ═══════════════════════════════════════════════════════════════════════
-- ZINDEX HIERARCHY (Controls which elements appear on top of others)
-- Higher number = appears in front of lower numbers
-- ═══════════════════════════════════════════════════════════════════════
local Z = {
	Base = 1, -- Main window
	Toggle = 10, -- Floating toggle button
	MainUI = 10, -- Main UI elements
	Card = 20, -- Cards inside content area
	Dropdown = 100, -- Dropdown menus (must be above cards)
	DropScroll = 110, -- Dropdown scroll area
	DropControl = 120, -- Dropdown buttons/controls
	Modal = 200, -- Dark overlay behind popups
	ModalFrame = 210, -- Popup window itself
	ModalCtrl = 220, -- Buttons inside popup
	Search = 500, -- Search suggestions (highest priority)
}

-- ═══════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS (Reusable tools to create UI elements faster)
-- ═══════════════════════════════════════════════════════════════════════

-- Creates a new UI instance and applies properties to it
local function Create(className, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties or {}) do
		instance[property] = value
	end
	return instance
end

-- Smoothly animates a property change (like color fade, position slide)
local function Tween(instance, properties, duration)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		properties
	)
	tween:Play()
	return tween
end

-- Adds rounded corners to any UI element
local function AddCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = instance
end

-- Adds a colored border around any UI element
local function AddStroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Parent = instance
end

-- Adds hover/press visual effects to buttons
local function AddButtonEffects(btn, normalColor, hoverColor)
	normalColor = normalColor or btn.BackgroundColor3
	hoverColor = hoverColor or Theme.CardHover
	-- Mouse hover (PC)
	btn.MouseEnter:Connect(function()
		Tween(btn, { BackgroundColor3 = hoverColor }, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, { BackgroundColor3 = normalColor }, 0.15)
	end)
	-- Touch press (Mobile)
	btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Tween(btn, { BackgroundColor3 = hoverColor }, 0.1)
		end
	end)
	btn.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Tween(btn, { BackgroundColor3 = normalColor }, 0.1)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SMART SCROLLBAR (Only shows scrollbar when content overflows)
-- ═══════════════════════════════════════════════════════════════════════
local function SetupSmartScrollbar(scrollingFrame)
	local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
		or scrollingFrame:FindFirstChildOfClass("UIGridLayout")
	if not layout then
		return
	end

	-- Store original thickness so we can restore it
	local originalThickness = scrollingFrame.ScrollBarThickness

	local function Update()
		-- Calculate total content height including padding
		local contentHeight = layout.AbsoluteContentSize.Y
		local padding = 0
		local pad = scrollingFrame:FindFirstChildOfClass("UIPadding")
		if pad then
			padding = pad.PaddingTop.Offset + pad.PaddingBottom.Offset
		end
		contentHeight = contentHeight + padding

		local frameHeight = scrollingFrame.AbsoluteSize.Y

		if contentHeight <= frameHeight then
			-- Content fits: hide scrollbar and disable scrolling
			scrollingFrame.ScrollBarThickness = 0
			scrollingFrame.ScrollingEnabled = false
		else
			-- Content overflows: show scrollbar and allow scrolling
			scrollingFrame.ScrollBarThickness = originalThickness
			scrollingFrame.ScrollingEnabled = true
		end
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Update)
	scrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(Update)

	-- Initial check after layout settles
	task.defer(Update)
end

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN UI CREATION (Building the screen that holds everything)
-- ═══════════════════════════════════════════════════════════════════════

local ScreenGui = Create("ScreenGui", {
	Name = "ExoticHubPro",
	Parent = playerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999, -- ⬅️ Renders above ALL other game UIs
})

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN WINDOW FRAME (The big draggable window)
-- ═══════════════════════════════════════════════════════════════════════
local MainFrame = Create("Frame", {
	Name = "MainFrame",
	Parent = ScreenGui,
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -Config.WindowWidth / 2, 0.5, -Config.WindowHeight / 2), -- Centered
	Size = UDim2.new(0, Config.WindowWidth, 0, Config.WindowHeight),
	ClipsDescendants = false, -- Allows dropdowns to extend outside
	Active = true, -- Enables interaction
	ZIndex = Z.Base,
	Visible = true,
})
AddStroke(MainFrame, Theme.Border, 2)

-- ═══════════════════════════════════════════════════════════════════════
-- TOGGLE BUTTON (ICON) - Floating button to show/hide the UI
-- Click = toggle MainFrame visible/hidden
-- Drag  = move button anywhere on screen (mobile friendly)
-- ═══════════════════════════════════════════════════════════════════════
local MainIcon = Create("TextButton", {
	Name = "MainIcon",
	Parent = ScreenGui,
	BackgroundColor3 = Color3.fromRGB(15, 15, 15),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 8, 0, 8), -- Top-left corner default
	Size = UDim2.new(0, 55, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = Config.ToggleButtonText,
	TextColor3 = Theme.AccentYellow,
	TextSize = 13,
	ZIndex = Z.Toggle,
	Active = true,
	AutoButtonColor = false, -- We handle color manually
})
AddCorner(MainIcon, 6)
AddStroke(MainIcon, Theme.Border, 1)

--[[
    DRAG & CLICK DETECTION FOR TOGGLE BUTTON (Mobile Compatible)

    HOW IT WORKS:
    1. When you press down (touch or click), we record the starting position
    2. While holding, if you move more than 8 pixels, we treat it as a DRAG
    3. If you release and moved less than 8 pixels, we treat it as a CLICK (toggle UI)

    This prevents the UI from toggling when you just want to drag the button.
]]
local toggleDragActive = false -- Is user currently dragging?
local toggleDragInputObj = nil -- Stores which input is being tracked
local toggleStartInputPos = nil -- Where the touch/click started
local toggleStartBtnPos = nil -- Where the button was when touch started
local toggleClickThreshold = 8 -- Pixels of movement to distinguish click vs drag

-- When user starts touching the button
MainIcon.InputBegan:Connect(function(input)
	if ModalOverlay and ModalOverlay.Visible then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		toggleDragActive = true
		toggleDragInputObj = input
		toggleStartInputPos = input.Position
		toggleStartBtnPos = MainIcon.Position
	end
end)

-- While dragging, update button position to follow finger/mouse
UserInputService.InputChanged:Connect(function(input)
	if toggleDragActive then
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local delta = input.Position - toggleStartInputPos
			MainIcon.Position = UDim2.new(
				toggleStartBtnPos.X.Scale,
				toggleStartBtnPos.X.Offset + delta.X,
				toggleStartBtnPos.Y.Scale,
				toggleStartBtnPos.Y.Offset + delta.Y
			)
		end
	end
end)

-- When user releases touch/click
UserInputService.InputEnded:Connect(function(input)
	if toggleDragActive and input == toggleDragInputObj then
		local delta = input.Position - toggleStartInputPos
		toggleDragActive = false
		toggleDragInputObj = nil

		-- If barely moved, treat as a CLICK → toggle UI visibility
		if math.abs(delta.X) <= toggleClickThreshold and math.abs(delta.Y) <= toggleClickThreshold then
			MainFrame.Visible = not MainFrame.Visible
			Tween(MainIcon, {
				BackgroundColor3 = MainFrame.Visible and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(30, 30, 30),
			}, 0.2)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN WINDOW DRAG (Drag the top bar to move the whole window)
-- Same logic as toggle button but moves MainFrame instead
-- ═══════════════════════════════════════════════════════════════════════

local isDragging = false
local dragInput = nil
local dragStartPos = nil
local frameStartPos = nil

MainFrame.InputBegan:Connect(function(input)
	-- ⛔ BLOCK DRAG WHEN MODAL IS OPEN
	if ModalOverlay and ModalOverlay.Visible then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
		dragInput = input
		dragStartPos = input.Position
		frameStartPos = MainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDragging then
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local delta = input.Position - dragStartPos
			MainFrame.Position = UDim2.new(
				frameStartPos.X.Scale,
				frameStartPos.X.Offset + delta.X,
				frameStartPos.Y.Scale,
				frameStartPos.Y.Offset + delta.Y
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
-- RESIZING SYSTEM (Make window bigger/smaller)
-- Corner handle = resize both width and height
-- Bottom bar = resize height only
-- Position never changes (window stays anchored at top-left while resizing)
-- ═══════════════════════════════════════════════════════════════════════

-- CORNER RESIZE HANDLE (Bottom-right corner triangle)
local ResizeHandle = Create("Frame", {
	Name = "ResizeHandle",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Accent,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -14, 1, -14),
	Size = UDim2.new(0, 16, 0, 16),
	BackgroundTransparency = 9999,
	ZIndex = Z.MainUI + 2,
})

Create("TextLabel", {
	Parent = ResizeHandle,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "//",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 9,
	TextTransparency = 0.4,
	ZIndex = Z.MainUI + 3,
})

-- Invisible button on top of corner handle for easier touch targeting
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

-- BOTTOM RESIZE BAR (Drag bottom edge to change height only)
local BottomResizeBar = Create("Frame", {
	Name = "BottomResizeBar",
	Parent = MainFrame,
	BackgroundColor3 = Color3.fromRGB(160, 160, 160),
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
	TextSize = 10,
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

-- CORNER RESIZE LOGIC (Changes both width and height)
-- Uses RenderStepped for smooth 60fps resizing while dragging
local isResizingCorner = false
ResizeBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isResizingCorner = true
		local startSize = MainFrame.Size
		local startMousePos = input.Position
		local connection
		-- Runs every frame while resizing for smooth updates
		connection = RunService.RenderStepped:Connect(function()
			if not isResizingCorner then
				connection:Disconnect()
				return
			end
			local currentMouse = UserInputService:GetMouseLocation()
			local delta = currentMouse - Vector2.new(startMousePos.X, startMousePos.Y)
			-- math.max prevents shrinking below minimum size
			MainFrame.Size = UDim2.new(
				0,
				math.max(Config.MinWindowWidth, startSize.X.Offset + delta.X),
				0,
				math.max(Config.MinWindowHeight, startSize.Y.Offset + delta.Y)
			)
		end)
		-- Detect when user releases touch/click
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				isResizingCorner = false
			end
		end)
	end
end)

-- BOTTOM BAR RESIZE LOGIC (Changes height only)
local isResizingBottom = false
BottomResizeBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isResizingBottom = true
		local startSize = MainFrame.Size
		local startMousePos = input.Position
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not isResizingBottom then
				connection:Disconnect()
				return
			end
			local currentMouse = UserInputService:GetMouseLocation()
			local deltaY = currentMouse.Y - startMousePos.Y
			MainFrame.Size =
				UDim2.new(0, startSize.X.Offset, 0, math.max(Config.MinWindowHeight, startSize.Y.Offset + deltaY))
		end)
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				isResizingBottom = false
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- TOP BAR (Title area + search bar + close button)
-- ═══════════════════════════════════════════════════════════════════════
local TopBar = Create("Frame", {
	Name = "TopBar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Sidebar,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 40),
	ZIndex = Z.MainUI,
})

local TitleLabel = Create("TextLabel", {
	Name = "Title",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 12, 0, 0),
	Size = UDim2.new(0, 60, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = " _hub",
	TextColor3 = Theme.TextPrimary,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.MainUI + 1,
})

-- NEW: Page title that appears to the right of "_hub"
local PageTitle = Create("TextLabel", {
	Name = "PageTitle",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 163, 0, 6),
	Size = UDim2.new(0, 120, 0, 18),
	Font = Enum.Font.GothamBold,
	Text = "Home",
	TextColor3 = Theme.TextPrimary,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.MainUI + 1,
})

-- NEW: Page subtitle under the page title
local PageSubtitle = Create("TextLabel", {
	Name = "PageSubtitle",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 163, 0, 24),
	Size = UDim2.new(0, 120, 0, 14),
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = Theme.TextMuted,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.MainUI + 1,
})

-- ═══════════════════════════════════════════════════════════════════════
-- SEARCH BAR (Find features quickly by typing)
-- ═══════════════════════════════════════════════════════════════════════
local SearchFrame = Create("Frame", {
	Name = "SearchFrame",
	Parent = TopBar,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -197, 0.5, -13),
	Size = UDim2.new(0, 190, 0, 26),
	ZIndex = Z.MainUI + 2,
})
AddCorner(SearchFrame, 12)
AddStroke(SearchFrame, Theme.Border, 1)

-- Magnifying glass icon
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

-- Text input field
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
	ClearTextOnFocus = true, -- Clears "Search" text when clicked
	Active = true,
})

-- Dropdown suggestion box (appears below search bar when typing)
local SuggestFrame = Create("Frame", {
	Name = "Suggestions",
	Parent = ScreenGui, -- Parented to ScreenGui so it can float above everything
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
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- ═══════════════════════════════════════════════════════════════════════
-- CLOSE BUTTON (Hides the main window, doesn't destroy it)
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
	Visible = false,
	AutoButtonColor = false,
})

CloseBtn.MouseEnter:Connect(function()
	Tween(CloseBtn, { TextColor3 = Theme.AccentRed }, 0.15)
end)
CloseBtn.MouseLeave:Connect(function()
	Tween(CloseBtn, { TextColor3 = Theme.TextSecondary }, 0.15)
end)
CloseBtn.Activated:Connect(function()
	MainFrame.Visible = false
end)

-- ═══════════════════════════════════════════════════════════════════════
-- LEFT SIDEBAR (Navigation menu with page buttons)
-- ═══════════════════════════════════════════════════════════════════════
local Sidebar = Create("Frame", {
	Name = "Sidebar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Sidebar,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 2, 0, 42.5),
	Size = UDim2.new(0, Config.SidebarWidth, 1, -42),
	ZIndex = Z.MainUI,
})

-- Scrollable container for sidebar buttons (in case there are many pages)
local SidebarScroll = Create("ScrollingFrame", {
	Name = "Scroll",
	Parent = Sidebar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 4),
	Size = UDim2.new(1, 0, 1, -10),
	ScrollBarThickness = 1,
	ScrollBarImageColor3 = Theme.ScrollBar,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, -- Auto-expands as buttons are added
	ZIndex = Z.MainUI + 1,
	ScrollingEnabled = true,
	Active = true,
})

Create("UIListLayout", {
	Parent = SidebarScroll,
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- Apply smart scrollbar to sidebar
SetupSmartScrollbar(SidebarScroll)

-- ═══════════════════════════════════════════════════════════════════════
-- CONTENT AREA (Right side where cards and dropdowns appear)
-- ═══════════════════════════════════════════════════════════════════════
local ContentFrame = Create("Frame", {
	Name = "ContentFrame",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(0, Config.SidebarWidth, 0, 42.5),
	Size = UDim2.new(1, -Config.SidebarWidth, 1, -42),
	ZIndex = Z.MainUI,
	ClipsDescendants = true, -- Prevents content from spilling out
})

-- Scrollable grid that holds all the cards
local ContentScroll = Create("ScrollingFrame", {
	Name = "ContentScroll",
	Parent = ContentFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 11, 0, 10),
	Size = UDim2.new(1, -20, 1, -20),
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Theme.ScrollBar,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = Z.MainUI + 1,
	ScrollingEnabled = true,
	Active = true,
	ClipsDescendants = true,
})

-- Grid layout: 2 columns, each cell is 36 pixels tall
Create("UIGridLayout", {
	Parent = ContentScroll,
	CellSize = UDim2.new(0.5, -5, 0, 36),
	CellPadding = UDim2.new(0, 5, 0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- Apply smart scrollbar to content area
SetupSmartScrollbar(ContentScroll)

-- ═══════════════════════════════════════════════════════════════════════
-- DROPDOWN LAYER (Invisible container that holds dropdown menus)
-- This sits on top of content but is invisible - dropdowns are placed inside it
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
-- MODAL POPUP (Centered popup window for multi-select like "Buy Selected Seeds")
-- ═══════════════════════════════════════════════════════════════════════
local ModalOverlay = Create("Frame", {
	Name = "ModalOverlay",
	Parent = ScreenGui,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.4, -- Semi-transparent black background
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 1, 0),
	Visible = false,
	ZIndex = Z.Modal,
	Active = true,
})

-- Modal frame - BIGGER like in the video (520x420)
local ModalFrame = Create("Frame", {
	Name = "ModalFrame",
	Parent = ModalOverlay,
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -260, 0.5, -210),
	Size = UDim2.new(0, 520, 0, 420),
	ZIndex = Z.ModalFrame,
})
AddCorner(ModalFrame, 8)
AddStroke(ModalFrame, Theme.Border, 1)

-- Modal title bar with icon + title + Done button
local ModalTitleBar = Create("Frame", {
	Name = "TitleBar",
	Parent = ModalFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 12),
	Size = UDim2.new(1, -30, 0, 28),
	ZIndex = Z.ModalCtrl,
})

local ModalTitleIcon = Create("TextLabel", {
	Name = "Icon",
	Parent = ModalTitleBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 22, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "✅",
	TextColor3 = Theme.AccentGreen,
	TextSize = 14,
	ZIndex = Z.ModalCtrl,
})

local ModalTitle = Create("TextLabel", {
	Name = "Title",
	Parent = ModalTitleBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 26, 0, 0),
	Size = UDim2.new(1, -120, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "Select Item",
	TextColor3 = Theme.TextPrimary,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = Z.ModalCtrl,
})

local ModalDone = Create("TextButton", {
	Name = "DoneBtn",
	Parent = ModalTitleBar,
	BackgroundColor3 = Theme.Accent,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -75, 0, -2),
	Size = UDim2.new(0, 75, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Done",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	ZIndex = Z.ModalCtrl,
	Active = true,
	AutoButtonColor = false,
})
AddCorner(ModalDone, 6)

-- ═══════════════════════════════════════════════════════════════════════
-- MODAL SEARCH BAR (Search inside the modal - like in the video)
-- ═══════════════════════════════════════════════════════════════════════
local ModalSearchFrame = Create("Frame", {
	Name = "SearchFrame",
	Parent = ModalFrame,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 15, 0, 50),
	Size = UDim2.new(1, -30, 0, 32),
	ZIndex = Z.ModalCtrl,
})
AddCorner(ModalSearchFrame, 6)
AddStroke(ModalSearchFrame, Theme.Border, 1)

Create("TextLabel", {
	Name = "SearchIcon",
	Parent = ModalSearchFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 0),
	Size = UDim2.new(0, 20, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "🔍",
	TextColor3 = Theme.TextMuted,
	TextSize = 12,
	ZIndex = Z.ModalCtrl + 1,
})

local ModalSearchBox = Create("TextBox", {
	Name = "SearchBox",
	Parent = ModalSearchFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 32, 0, 0),
	Size = UDim2.new(1, -42, 1, 0),
	Font = Enum.Font.Gotham,
	Text = "Search items...",
	TextColor3 = Theme.TextMuted,
	TextSize = 12,
	ZIndex = Z.ModalCtrl + 1,
	ClearTextOnFocus = true,
	Active = true,
})

-- Modal scrollable list
local ModalScroll = Create("ScrollingFrame", {
	Name = "Scroll",
	Parent = ModalFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 90),
	Size = UDim2.new(1, -30, 1, -102),
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Theme.ScrollBar,
	ZIndex = Z.ModalCtrl,
	ScrollingEnabled = true,
	Active = true,
	ClipsDescendants = true,
})

Create("UIListLayout", {
	Parent = ModalScroll,
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- Apply smart scrollbar to modal
SetupSmartScrollbar(ModalScroll)

-- ═══════════════════════════════════════════════════════════════════════
-- STATE VARIABLES (Track what's currently happening in the UI)
-- ═══════════════════════════════════════════════════════════════════════
local CurrentPage = "Home" -- Which page is currently shown
local ActiveDropdownCard = nil -- Which card opened the current dropdown
local ActiveDropdownFrame = nil -- The currently open dropdown frame
local IsClosingDropdown = false -- Prevents double-closing animation
local DropdownDebounce = false -- Prevents rapid clicking while animating
local SidebarButtons = {} -- Table storing all sidebar button functions
local SearchableItems = {} -- Table of items that can be searched
local CardLayoutOrder = 0 -- Counter for card ordering (auto-increments)
local StickyHeartbeat = nil -- Connection that updates dropdown position every frame

-- ═══════════════════════════════════════════════════════════════════════
-- STICKY DROPDOWN (Keeps dropdown attached to its card when scrolling)
-- ═══════════════════════════════════════════════════════════════════════
local CloseDropdown -- Forward declaration (defined later)

-- Updates dropdown position to stay attached to its parent card
-- Called every frame via RunService.Heartbeat while dropdown is open
local function UpdateDropdownPosition()
	if not ActiveDropdownFrame or not ActiveDropdownCard then
		return
	end
	if not ActiveDropdownCard.Parent then
		CloseDropdown()
		return
	end
	local cardAbs = ActiveDropdownCard.AbsolutePosition
	local layerAbs = DropdownLayer.AbsolutePosition
	local relX = cardAbs.X - layerAbs.X
	local relY = cardAbs.Y - layerAbs.Y + ActiveDropdownCard.AbsoluteSize.Y + 2
	ActiveDropdownFrame.Position = UDim2.new(0, relX, 0, relY)
end

-- Starts the "sticky" behavior - dropdown follows card as you scroll
local function StartStickyDropdown()
	if StickyHeartbeat then
		StickyHeartbeat:Disconnect()
		StickyHeartbeat = nil
	end
	StickyHeartbeat = RunService.Heartbeat:Connect(UpdateDropdownPosition)
end

-- Stops the sticky behavior when dropdown closes
local function StopStickyDropdown()
	if StickyHeartbeat then
		StickyHeartbeat:Disconnect()
		StickyHeartbeat = nil
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- DROPDOWN SYSTEM (Opens/closes dropdown menus under cards)
-- ═══════════════════════════════════════════════════════════════════════

-- Closes the currently open dropdown with an animation
function CloseDropdown()
	if IsClosingDropdown or not ActiveDropdownFrame then
		return
	end
	IsClosingDropdown = true
	DropdownDebounce = false
	StopStickyDropdown()

	if ActiveDropdownCard then
		local arrow = ActiveDropdownCard:FindFirstChild("Arrow")
		if arrow then
			arrow.Text = ">"
		end
		Tween(ActiveDropdownCard, { BackgroundColor3 = Theme.Card }, 0.15)
		ActiveDropdownCard = nil
	end

	local frame = ActiveDropdownFrame
	ActiveDropdownFrame = nil
	Tween(frame, { Size = UDim2.new(0, frame.Size.X.Offset, 0, 0) }, 0.15)
	task.wait(0.15)
	if frame and frame.Parent then
		frame:Destroy()
	end
	IsClosingDropdown = false
end

-- Clears all cards from the content area (called when switching pages)
local function ClearContent()
	ContentScroll.CanvasPosition = Vector2.new(0, 0) -- Reset scroll to top
	CloseDropdown()
	for _, child in pairs(ContentScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	CardLayoutOrder = 0
end

-- ═══════════════════════════════════════════════════════════════════════
-- UI BUILDERS (Functions that create reusable UI components)
-- ═══════════════════════════════════════════════════════════════════════

-- Creates a card button in the content grid
-- Usage: CreateCard("Auto Hatch", "🥚", Theme.Accent)
-- Returns: The card button instance (so you can connect click events)
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

	-- Icon label (emoji)
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

	-- Title text
	Create("TextLabel", {
		Name = "Title",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 35, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Z.Card + 1,
	})

	-- Arrow indicator (">" when closed, "v" when open)
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

	-- Hover effects (only if not the active dropdown card)
	card.MouseEnter:Connect(function()
		if ActiveDropdownCard ~= card then
			Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end
	end)
	card.MouseLeave:Connect(function()
		if ActiveDropdownCard ~= card then
			Tween(card, { BackgroundColor3 = Theme.Card }, 0.15)
		end
	end)

	return card
end

-- Opens a dropdown menu under a card
-- card: The card button that was clicked
-- buildContentFunction: A function that receives a scroll frame and adds content to it
local function ToggleDropdown(card, buildContentFunction)
	if IsClosingDropdown then
		return
	end
	if ActiveDropdownCard == card and ActiveDropdownFrame then
		CloseDropdown()
		return
	end
	if DropdownDebounce then
		return
	end
	DropdownDebounce = true

	CloseDropdown()
	ActiveDropdownCard = card
	Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)
	local arrow = card:FindFirstChild("Arrow")
	if arrow then
		arrow.Text = "v"
	end

	-- Calculate position relative to DropdownLayer so it sticks to the card
	local cardAbs = card.AbsolutePosition
	local layerAbs = DropdownLayer.AbsolutePosition
	local relX = cardAbs.X - layerAbs.X
	local relY = cardAbs.Y - layerAbs.Y + card.AbsoluteSize.Y + 2

	-- Create the dropdown container
	local drop = Create("TextButton", {
		Name = "Dropdown",
		Parent = DropdownLayer,
		BackgroundColor3 = Theme.DropdownBg,
		BorderSizePixel = 0,
		Position = UDim2.new(0, relX, 0, relY),
		Size = UDim2.new(0, card.AbsoluteSize.X, 0, 0), -- Starts at height 0, expands with animation
		ZIndex = Z.Dropdown,
		ClipsDescendants = true,
		Active = true,
		AutoButtonColor = false,
		Text = "",
	})
	AddCorner(drop, 6)
	AddStroke(drop, Theme.Border, 1)

	-- Scrollable area inside dropdown (holds toggles, labels, buttons)
	local scroll = Create("ScrollingFrame", {
		Name = "Scroll",
		Parent = drop,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
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

	-- Call the provided function to fill the dropdown with content
	buildContentFunction(scroll)
	task.wait()

	-- Calculate height based on content, cap at 260 pixels max
	local contentHeight = listLayout.AbsoluteContentSize.Y + 16
	local maxHeight = math.min(contentHeight, 260)
	local width = card.AbsoluteSize.X

	scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	ActiveDropdownFrame = drop
	Tween(drop, { Size = UDim2.new(0, width, 0, maxHeight) }, 0.2)
	StartStickyDropdown()

	-- Apply smart scrollbar to dropdown scroll (checks if content overflows dropdown height)
	local dropScrollOriginalThickness = scroll.ScrollBarThickness
	local function UpdateDropScroll()
		local pad = scroll:FindFirstChildOfClass("UIPadding")
		local padding = pad and (pad.PaddingTop.Offset + pad.PaddingBottom.Offset) or 0
		local contentH = listLayout.AbsoluteContentSize.Y + padding
		local frameH = scroll.AbsoluteSize.Y

		if contentH <= frameH then
			scroll.ScrollBarThickness = 0
			scroll.ScrollingEnabled = false
		else
			scroll.ScrollBarThickness = dropScrollOriginalThickness
			scroll.ScrollingEnabled = true
		end
	end
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateDropScroll)
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateDropScroll)
	task.defer(UpdateDropScroll)

	task.delay(0.25, function()
		DropdownDebounce = false
	end)
end

-- Creates a toggle switch (ON/OFF slider) inside a dropdown
-- Returns: The container frame, and a function to get current state
local function CreateToggle(parent, text, defaultState, onToggleCallback)
	local container = Create("Frame", {
		Name = text .. "Toggle",
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 30),
		ZIndex = Z.DropControl,
		Active = true,
	})

	-- Label text
	Create("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = Theme.TextPrimary,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Z.DropControl,
	})

	-- Toggle background (changes color based on state)
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

	-- The sliding knob
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
		Tween(toggleBg, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleBg }, 0.2)
		Tween(knob, { Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2) }, 0.2)
		if onToggleCallback then
			onToggleCallback(state)
		end
	end)

	return container, function()
		return state
	end
end

-- Creates a text label inside dropdown content
local function CreateLabel(parent, text, textColor, fontSize)
	return Create("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, fontSize or 20),
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = textColor or Theme.TextSecondary,
		TextSize = fontSize or 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Z.DropControl,
	})
end

-- Creates a standard button inside dropdown content
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

-- ═══════════════════════════════════════════════════════════════════════
-- MODAL SYSTEM (Multi-select modal with search)
-- ═══════════════════════════════════════════════════════════════════════

-- Rarity color mapping (matches video colors)
local RarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(80, 220, 80),
	Rare = Color3.fromRGB(100, 150, 255),
	Epic = Color3.fromRGB(180, 130, 255),
	Legendary = Color3.fromRGB(255, 215, 0),
	Super = Color3.fromRGB(255, 100, 100),
	Mythic = Color3.fromRGB(255, 105, 180),
}

-- Format price to match video (e.g. $1.00, $20.00K, $90.00M)
local function FormatPrice(value)
	if not value or value == 0 then
		return "$0"
	elseif value >= 1000000 then
		return string.format("$%.2fM", value / 1000000)
	elseif value >= 1000 then
		return string.format("$%.2fK", value / 1000)
	else
		return string.format("$%.2f", value)
	end
end

-- Modal internal state
local ModalItems = {}
local ModalItemRows = {}
local ModalSelectedItems = {}
local ModalOnDoneCallback = nil
local ModalCurrentFilter = ""

-- Build/rebuild modal item rows based on filter and selection
local function BuildModalItems()
	-- Clear existing rows
	for _, child in pairs(ModalScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	ModalItemRows = {}

	local filter = ModalCurrentFilter:lower()
	local layoutOrder = 0

	for _, item in ipairs(ModalItems) do
		if filter == "" or item.Name:lower():find(filter, 1, true) then
			local isSelected = ModalSelectedItems[item.Name] == true

			local row = Create("TextButton", {
				Name = item.Name,
				Parent = ModalScroll,
				BackgroundColor3 = isSelected and Color3.fromRGB(55, 45, 75) or Theme.Card,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 32),
				LayoutOrder = layoutOrder,
				Font = Enum.Font.Gotham,
				Text = "",
				ZIndex = Z.ModalCtrl,
				Active = true,
				AutoButtonColor = false,
			})
			layoutOrder = layoutOrder + 1
			AddCorner(row, 4)

			-- Seed Name (left side)
			Create("TextLabel", {
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(0, 140, 1, 0),
				Font = Enum.Font.Gotham,
				Text = item.Name,
				TextColor3 = Theme.TextPrimary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z.ModalCtrl + 1,
			})

			-- Price (green, like in video)
			Create("TextLabel", {
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 155, 0, 0),
				Size = UDim2.new(0, 80, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = item.Price,
				TextColor3 = Color3.fromRGB(80, 220, 80),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z.ModalCtrl + 1,
			})

			-- Rarity (colored based on rarity)
			local rarityColor = RarityColors[item.Rarity] or Theme.TextSecondary
			Create("TextLabel", {
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 240, 0, 0),
				Size = UDim2.new(0, 70, 1, 0),
				Font = Enum.Font.Gotham,
				Text = item.Rarity,
				TextColor3 = rarityColor,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z.ModalCtrl + 1,
			})

			-- Type (Single/Multi)
			Create("TextLabel", {
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 315, 0, 0),
				Size = UDim2.new(0, 50, 1, 0),
				Font = Enum.Font.Gotham,
				Text = item.Type,
				TextColor3 = Theme.TextSecondary,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z.ModalCtrl + 1,
			})

			-- Checkmark indicator when selected
			if isSelected then
				Create("TextLabel", {
					Parent = row,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -30, 0, 0),
					Size = UDim2.new(0, 20, 1, 0),
					Font = Enum.Font.GothamBold,
					Text = "✓",
					TextColor3 = Theme.Accent,
					TextSize = 14,
					ZIndex = Z.ModalCtrl + 1,
				})
			end

			-- Click to toggle selection
			row.Activated:Connect(function()
				ModalSelectedItems[item.Name] = not (ModalSelectedItems[item.Name] == true)
				BuildModalItems() -- Rebuild to update visuals
			end)

			table.insert(ModalItemRows, row)
		end
	end

	ModalScroll.CanvasSize = UDim2.new(0, 0, 0, #ModalItemRows * 35)
end

-- Modal search handler
ModalSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local text = ModalSearchBox.Text
	if text == "Search items..." then
		text = ""
	end
	ModalCurrentFilter = text
	BuildModalItems()
end)

ModalSearchBox.FocusLost:Connect(function()
	if ModalSearchBox.Text == "" then
		ModalSearchBox.Text = "Search items..."
	end
end)

-- Done button closes modal and returns selections
ModalDone.Activated:Connect(function()
	ModalOverlay.Visible = false
	if ModalOnDoneCallback then
		ModalOnDoneCallback(ModalSelectedItems)
	end
end)

-- ShowModal: opens the modal with items, supports multi-select + search
-- items: array of {Name, Price, Rarity, Type}
-- onDoneCallback: function(selectedDict) where selectedDict = {[name] = true}
-- preSelected: optional dict of pre-selected item names
local function ShowModal(titleText, items, onDoneCallback, preSelected)
	ModalTitle.Text = titleText
	ModalItems = items or {}
	ModalSelectedItems = {}
	if preSelected then
		for k, v in pairs(preSelected) do
			ModalSelectedItems[k] = v
		end
	end
	ModalOnDoneCallback = onDoneCallback
	ModalCurrentFilter = ""
	ModalSearchBox.Text = "Search items..."

	BuildModalItems()
	ModalOverlay.Visible = true
end

-- ═══════════════════════════════════════════════════════════════════════
-- SEARCH SYSTEM (Register items and filter them when typing)
-- ═══════════════════════════════════════════════════════════════════════

-- Adds an item to the searchable database
-- Usage: RegisterSearch("Auto Hatch", "Home", "🥚", function() ... end)
local function RegisterSearch(name, pageName, icon, action)
	table.insert(SearchableItems, { Name = name, Page = pageName, Icon = icon, Action = action })
end

-- Updates the suggestion dropdown based on search text
local function UpdateSuggestions()
	-- Clear previous suggestions
	for _, child in pairs(SuggestScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local text = SearchBox.Text:lower()
	if text == "" or text == "search" then
		SuggestFrame.Visible = false
		return
	end

	-- Find matching items
	local matches = {}
	for _, item in pairs(SearchableItems) do
		if item.Name:lower():find(text, 1, true) then
			table.insert(matches, item)
		end
	end

	if #matches == 0 then
		SuggestFrame.Visible = false
		return
	end

	-- Position suggestion box directly below search bar
	local absPos = SearchFrame.AbsolutePosition
	local absSize = SearchFrame.AbsoluteSize
	SuggestFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
	SuggestFrame.Size = UDim2.new(0, absSize.X, 0, math.min(#matches * 32 + 10, 200))

	-- Create suggestion buttons
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
			if item.Action then
				item.Action()
			end
		end)
	end

	SuggestScroll.CanvasSize = UDim2.new(0, 0, 0, #matches * 32)
	SuggestFrame.Visible = true
end

-- Update suggestions as user types
SearchBox:GetPropertyChangedSignal("Text"):Connect(UpdateSuggestions)
-- Hide suggestions when focus is lost
SearchBox.FocusLost:Connect(function()
	if SearchBox.Text == "" then
		SearchBox.Text = "Search"
	end
	task.wait(0.2)
	SuggestFrame.Visible = false
end)
-- Show suggestions again if text exists when focused
SearchBox.Focused:Connect(function()
	if SearchBox.Text ~= "Search" and SearchBox.Text ~= "" then
		UpdateSuggestions()
	end
end)

-- Apply smart scrollbar to search suggestions (after UpdateSuggestions is defined)
SetupSmartScrollbar(SuggestScroll)

-- ═══════════════════════════════════════════════════════════════════════
-- GLOBAL CLICK HANDLER (Closes dropdowns/suggestions when clicking outside)
-- This runs for EVERY click/touch on screen
-- ═══════════════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Only handle mouse clicks and touches
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	-- Ignore if game processed it (like clicking a TextBox)
	if gameProcessed then
		return
	end

	local pos = input.Position

	-- Helper: Check if click is inside a GUI element
	local function isInside(gui)
		if not gui or not gui.Parent then
			return false
		end
		local ap = gui.AbsolutePosition
		local as = gui.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end

	-- Close search suggestions if clicking outside
	if SuggestFrame and SuggestFrame.Visible then
		if not isInside(SearchFrame) and not isInside(SuggestFrame) then
			SuggestFrame.Visible = false
		end
	end

	-- Close dropdown if clicking outside of it AND outside its parent card
	if ActiveDropdownFrame and ActiveDropdownFrame.Parent then
		if isInside(ActiveDropdownFrame) then
			return
		end
		if ActiveDropdownCard and isInside(ActiveDropdownCard) then
			return
		end
		CloseDropdown()
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE SYSTEM (Switches between different sections of the hub)
-- ═══════════════════════════════════════════════════════════════════════

-- Switches to a new page with title, subtitle, and custom content
local function SwitchPage(pageName, title, subtitle, contentBuilder)
	CurrentPage = pageName
	PageTitle.Text = title
	PageSubtitle.Text = subtitle or ""
	ClearContent()
	contentBuilder()
end

-- Table that holds all page functions
local Pages = {}

-- ═══════════════════════════════════════════════════════════════════════
-- PAGES (Each function defines the content of a sidebar section)
-- ═══════════════════════════════════════════════════════════════════════

-- ACCOUNT PAGE (User account info, logout)
function Pages.Account()
	SwitchPage("Account", "Account", "", function()
		local accountCard = CreateCard("Account", "👤", Theme.Accent)
		accountCard.Activated:Connect(function()
			ToggleDropdown(accountCard, function(scroll) end)
		end)
	end)
end
RegisterSearch("Account", "Account", "👤", function()
	SidebarButtons["Account"]()
end)

-- HOME PAGE (Main features: Auto Hatch, System, Farm)
function Pages.Home()
	SwitchPage("Home", "Home", "Game Version: ---- ", function() end)
end
RegisterSearch("Home", "Home", "🏠", function()
	SidebarButtons["Home"]()
end)

-- PREMIUM PAGE (Paid features, gifting, trading)
function Pages.Premium()
	SwitchPage("Premium", "Premium", "Premium Features", function() end)
end
RegisterSearch("Premium", "Premium", "💎", function()
	SidebarButtons["Premium"]()
end)

-- ═══════════════════════════════════════════════════════════════════════
-- SHOP PAGE (Seed Shop + Gear Shop - matches the video exactly)
-- ═══════════════════════════════════════════════════════════════════════
local Networking, SeedData

pcall(function()
	Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)

	SeedData = require(game:GetService("ReplicatedStorage").SharedModules.SeedData)
end)

local SelectedSeeds = {}
local EnableSeedShop = false

function Pages.Shop()
	SwitchPage("Shop", "Shop", "Shop Features", function()
		local seedShopCard = CreateCard("Seed Shop", "🌱", Theme.Accent)

		seedShopCard.Activated:Connect(function()
			ToggleDropdown(seedShopCard, function(scroll)
				------------------------------------------------
				-- HEADER
				------------------------------------------------

				local header = Create("TextLabel", {
					Parent = scroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 18),
					Font = Enum.Font.GothamBold,
					Text = "✅ Buy Selected Seeds",
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = Z.DropControl,
				})

				------------------------------------------------
				-- SELECTED SEED BUTTON
				------------------------------------------------

				local selectedSeedBtn = Create("TextButton", {
					Parent = scroll,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Size = UDim2.new(1, -8, 0, 30),
					Text = "",
					AutoButtonColor = false,
					ZIndex = Z.DropControl,
				})

				AddCorner(selectedSeedBtn, 4)
				AddStroke(selectedSeedBtn, Theme.Border, 1)
				AddButtonEffects(selectedSeedBtn, Theme.Card)

				local selectedSeedText = Create("TextLabel", {
					Parent = selectedSeedBtn,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -35, 1, 0),
					Font = Enum.Font.Gotham,
					Text = "Click to select seeds",
					TextColor3 = Theme.TextSecondary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = Z.DropControl + 1,
				})

				local arrow = Create("TextLabel", {
					Parent = selectedSeedBtn,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -20, 0, 0),
					Size = UDim2.new(0, 20, 1, 0),
					Font = Enum.Font.GothamBold,
					Text = "▼",
					TextColor3 = Theme.TextSecondary,
					TextSize = 11,
					ZIndex = Z.DropControl + 1,
				})

				------------------------------------------------
				-- UPDATE DISPLAY
				------------------------------------------------

				local function UpdateSelectedDisplay()
					local count = 0
					local firstSeed

					for seedName, selected in pairs(SelectedSeeds) do
						if selected then
							count += 1

							if not firstSeed then
								firstSeed = seedName
							end
						end
					end

					if count == 0 then
						selectedSeedText.Text = "Click to select seeds"

						selectedSeedText.TextColor3 = Theme.TextSecondary
					elseif count == 1 then
						selectedSeedText.Text = firstSeed

						selectedSeedText.TextColor3 = Theme.TextPrimary
					else
						selectedSeedText.Text = firstSeed .. " +" .. (count - 1)

						selectedSeedText.TextColor3 = Theme.TextPrimary
					end
				end

				UpdateSelectedDisplay()

				------------------------------------------------
				-- BUTTONS
				------------------------------------------------

				local buttonFrame = Create("Frame", {
					Parent = scroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 30),
				})

				local selectAllBtn = Create("TextButton", {
					Parent = buttonFrame,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0.48, 0, 1, 0),
					Text = "✅ Select All",
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
				})

				AddCorner(selectAllBtn, 4)
				AddStroke(selectAllBtn, Theme.Border, 1)

				local clearBtn = Create("TextButton", {
					Parent = buttonFrame,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0.52, 0, 0, 0),
					Size = UDim2.new(0.48, 0, 1, 0),
					Text = "🧹 Clear",
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
				})

				AddCorner(clearBtn, 4)
				AddStroke(clearBtn, Theme.Border, 1)

				selectAllBtn.Activated:Connect(function()
					for _, seed in ipairs(SeedData) do
						if seed.SeedName then
							SelectedSeeds[seed.SeedName] = true
						end
					end

					UpdateSelectedDisplay()
				end)

				clearBtn.Activated:Connect(function()
					table.clear(SelectedSeeds)
					UpdateSelectedDisplay()
				end)

				------------------------------------------------
				-- OPEN MODAL
				------------------------------------------------

				selectedSeedBtn.Activated:Connect(function()
					local modalItems = {}

					for _, seed in ipairs(SeedData) do
						if seed.SeedName and seed.PurchasePrice then
							table.insert(modalItems, {
								Name = seed.SeedName,
								Price = seed.PurchasePrice,
								Rarity = seed.Rarity,
								Single = seed.IsSingleHarvest and "Single" or "Multi",
							})
						end
					end

					ShowModal("Buy Selected Seeds", modalItems, function(newSelection)
						for seedName, selected in pairs(newSelection) do
							SelectedSeeds[seedName] = selected
						end

						UpdateSelectedDisplay()
					end, SelectedSeeds)
				end)

				------------------------------------------------
				-- ENABLE TOGGLE
				------------------------------------------------

				CreateToggle(scroll, "Enable Seed Shop", false, function(state)
					EnableSeedShop = state
				end)
			end)
		end)
	end)
end

RegisterSearch("Shop", "Shop", "🏪", function()
	SidebarButtons["Shop"]()
end)

----------------------------------------------------
-- AUTO BUY LOOP
----------------------------------------------------

task.spawn(function()
	while task.wait(1) do
		if EnableSeedShop and Networking and Networking.SeedShop and Networking.SeedShop.PurchaseSeed then
			for seedName, selected in pairs(SelectedSeeds) do
				if selected then
					pcall(function()
						Networking.SeedShop.PurchaseSeed(seedName)
					end)
				end
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- SIDEBAR SETUP (Creates the left navigation buttons)
-- ═══════════════════════════════════════════════════════════════════════

local SidebarItems = {
	{ Name = "Account", Icon = "👤", Color = Theme.Accent, Page = Pages.Account },
	{ Name = "Home", Icon = "🏠", Color = Theme.Accent, Page = Pages.Home },
	{ Name = "Premium", Icon = "💎", Color = Theme.AccentPink, Page = Pages.Premium },
	{ Name = "Shop", Icon = "🏪", Color = Theme.Accent, Page = Pages.Shop },
}

-- Create each sidebar button from the list above
for index, item in ipairs(SidebarItems) do
	local btn = Create("TextButton", {
		Name = item.Name,
		Parent = SidebarScroll,
		BackgroundColor3 = (index == 2) and Theme.Card or Theme.Sidebar, -- Home is selected by default
		BorderSizePixel = 0,
		Size = UDim2.new(1, -10, 0, 32),
		Position = UDim2.new(0, 5, 0, 0),
		Font = Enum.Font.Gotham,
		Text = "  " .. item.Icon .. "  " .. item.Name,
		TextColor3 = item.Color,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		ZIndex = Z.MainUI + 2,
		Active = true,
	})
	AddCorner(btn, 4)

	-- Store the button's click function so we can call it from search
	SidebarButtons[item.Name] = function()
		CurrentPage = item.Name
		-- Highlight the selected button, dim others
		for _, child in pairs(SidebarScroll:GetChildren()) do
			if child:IsA("TextButton") then
				local isSelected = (child.Name == item.Name)
				Tween(child, { BackgroundColor3 = isSelected and Theme.Card or Theme.Sidebar }, 0.2)
			end
		end
		item.Page() -- Load the page content
	end

	-- Hover effects (only if not currently selected)
	btn.MouseEnter:Connect(function()
		if CurrentPage ~= item.Name then
			Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end
	end)
	btn.MouseLeave:Connect(function()
		if CurrentPage ~= item.Name then
			Tween(btn, { BackgroundColor3 = Theme.Sidebar }, 0.15)
		end
	end)
	btn.Activated:Connect(SidebarButtons[item.Name])
	RegisterSearch(item.Name, item.Name, item.Icon, SidebarButtons[item.Name])
end

-- ═══════════════════════════════════════════════════════════════════════
-- MOBILE SUPPORT (Auto-adjusts UI size for smaller screens)
-- If the device has a touchscreen, we shrink the window to fit the screen
-- ═══════════════════════════════════════════════════════════════════════
if UserInputService.TouchEnabled then
	local viewport = workspace.CurrentCamera.ViewportSize
	-- Shrink window to fit within screen with 20px padding on sides, 40px on top/bottom
	MainFrame.Size =
		UDim2.new(0, math.min(Config.WindowWidth, viewport.X - 20), 0, math.min(Config.WindowHeight, viewport.Y - 40))
	-- Re-center the window
	MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
end

-- ═══════════════════════════════════════════════════════════════════════
-- STARTUP (Runs when the script first loads)
-- ═══════════════════════════════════════════════════════════════════════
Pages.Home() -- Load the Home page by default
