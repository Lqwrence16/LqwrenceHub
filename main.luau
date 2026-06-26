--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              _hub MOBILE - Touch-First Script Hub            ║
    ║                        Version 1.0                           ║
    ║                                                              ║
    ║  Mobile-first design: Full screen, bottom tabs, swipe nav,   ║
    ║  touch feedback, hamburger sidebar, native-feel dropdowns    ║
    ║  Execute: loadstring(game:HttpGet("YOUR_URL"))()            ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════════
-- PLAYER SETUP
-- ═══════════════════════════════════════════════════════════════

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════
-- THEME - Same colors as desktop version
-- ═══════════════════════════════════════════════════════════════

local Theme = {
	Background = Color3.fromRGB(18, 18, 22),
	Sidebar = Color3.fromRGB(15, 15, 19),
	Header = Color3.fromRGB(20, 20, 25),
	Card = Color3.fromRGB(28, 28, 35),
	CardHover = Color3.fromRGB(35, 35, 45),
	ButtonNormal = Color3.fromRGB(35, 35, 45),
	Accent = Color3.fromRGB(147, 112, 219),
	AccentHover = Color3.fromRGB(167, 132, 239),
	Border = Color3.fromRGB(40, 40, 50),
	BorderLight = Color3.fromRGB(55, 55, 70),
	TextActive = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(130, 130, 145),
	TextDark = Color3.fromRGB(100, 100, 115),
	Danger = Color3.fromRGB(220, 60, 60),
	Success = Color3.fromRGB(60, 200, 100),
	Warning = Color3.fromRGB(234, 179, 8),
	Pink = Color3.fromRGB(236, 72, 153),
	Cyan = Color3.fromRGB(34, 211, 238),
	FontMain = Enum.Font.GothamMedium,
	FontHeader = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,
	SectionBg = Color3.fromRGB(32, 32, 40),
}

-- ═══════════════════════════════════════════════════════════════
-- MOBILE SIZES - Bigger everything for touch
-- ═══════════════════════════════════════════════════════════════

local HEADER_H = 56           -- Taller header
local TAB_H = 60              -- Bottom tab bar height
local SIDEBAR_W = 240         -- Wider slide-out sidebar
local TOUCH_MIN = 44          -- Minimum touch target size

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function stroke(parent, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function tween(obj, props, dur, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

-- Touch feedback: scale down slightly when pressed, back up when released
local function touchFeedback(btn, normalColor, pressColor)
	local pressing = false
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			pressing = true
			tween(btn, {BackgroundColor3 = pressColor or Theme.CardHover}, 0.1)
			tween(btn, {Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset, btn.Size.Y.Scale, btn.Size.Y.Offset - 2)}, 0.1)
		end
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			pressing = false
			tween(btn, {BackgroundColor3 = normalColor or Theme.Card}, 0.1)
			tween(btn, {Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset, btn.Size.Y.Scale, btn.Size.Y.Offset + 2)}, 0.1)
		end
	end)
end

local function safePrint(...)
	local args = {...}
	local msg = ""
	for i, v in ipairs(args) do
		msg = msg .. tostring(v) .. " "
	end
	print("[_hub Mobile] " .. msg)
end

-- ═══════════════════════════════════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "_hub_Mobile"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = playerGui

-- ═══════════════════════════════════════════════════════════════
-- MAIN WINDOW - Full screen with safe area consideration
-- ═══════════════════════════════════════════════════════════════

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(1, 0, 1, 0)  -- FULL SCREEN
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui

-- ═══════════════════════════════════════════════════════════════
-- DROPDOWN OVERLAY
-- ═══════════════════════════════════════════════════════════════

local dropdownOverlay = Instance.new("Frame")
dropdownOverlay.Name = "DropdownOverlay"
dropdownOverlay.Size = UDim2.new(1, 0, 1, -(HEADER_H + TAB_H))
dropdownOverlay.Position = UDim2.new(0, 0, 0, HEADER_H)
dropdownOverlay.BackgroundTransparency = 1
dropdownOverlay.ZIndex = 500
dropdownOverlay.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════
-- GLOBAL DROPDOWN TRACKER
-- ═══════════════════════════════════════════════════════════════

local activeDropdowns = {}

local function closeAllDropdowns()
	for _, entry in ipairs(activeDropdowns) do
		if entry and entry.close then
			entry.close()
		end
	end
	activeDropdowns = {}
end

-- ═══════════════════════════════════════════════════════════════
-- HEADER BAR - With hamburger menu button
-- ═══════════════════════════════════════════════════════════════

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3 = Theme.Header
header.BorderSizePixel = 0
header.ZIndex = 20
header.Parent = mainFrame

local headerBorder = Instance.new("Frame")
headerBorder.Size = UDim2.new(1, 0, 0, 1)
headerBorder.Position = UDim2.new(0, 0, 1, -1)
headerBorder.BackgroundColor3 = Theme.Border
headerBorder.BorderSizePixel = 0
headerBorder.ZIndex = 21
headerBorder.Parent = header

-- Hamburger menu button (3 lines)
local hamburgerBtn = Instance.new("TextButton")
hamburgerBtn.Name = "Hamburger"
hamburgerBtn.Size = UDim2.new(0, 48, 0, 48)
hamburgerBtn.Position = UDim2.new(0, 4, 0.5, -24)
hamburgerBtn.BackgroundColor3 = Theme.Card
hamburgerBtn.BorderSizePixel = 0
hamburgerBtn.Text = "\226\152\176"  -- Three lines icon
hamburgerBtn.TextColor3 = Theme.TextActive
hamburgerBtn.Font = Theme.FontHeader
hamburgerBtn.TextSize = 22
hamburgerBtn.AutoButtonColor = false
hamburgerBtn.ZIndex = 22
hamburgerBtn.Parent = header

touchFeedback(hamburgerBtn, Theme.Card, Theme.CardHover)

-- Logo circle with "L"
local logoIcon = Instance.new("Frame")
logoIcon.Size = UDim2.new(0, 32, 0, 32)
logoIcon.Position = UDim2.new(0, 58, 0.5, -16)
logoIcon.BackgroundColor3 = Theme.Accent
logoIcon.BorderSizePixel = 0
logoIcon.ZIndex = 22
logoIcon.Parent = header

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(1, 0)
logoCorner.Parent = logoIcon

local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Color3.fromRGB(0, 0, 0)
logoStroke.Thickness = 2
logoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
logoStroke.Parent = logoIcon

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "L"
logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
logoText.Font = Theme.FontHeader
logoText.TextSize = 18
logoText.ZIndex = 23
logoText.Parent = logoIcon

-- Title
local hubTitle = Instance.new("TextLabel")
hubTitle.Size = UDim2.new(0, 200, 1, 0)
hubTitle.Position = UDim2.new(0, 96, 0, 0)
hubTitle.BackgroundTransparency = 1
hubTitle.Text = "_hub"
hubTitle.TextColor3 = Theme.TextActive
hubTitle.Font = Theme.FontHeader
hubTitle.TextSize = 20
hubTitle.TextXAlignment = Enum.TextXAlignment.Left
hubTitle.ZIndex = 22
hubTitle.Parent = header

-- X Close button (hides UI)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 48, 0, 48)
closeBtn.Position = UDim2.new(1, -52, 0.5, -24)
closeBtn.BackgroundColor3 = Theme.Card
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Theme.TextMuted
closeBtn.Font = Theme.FontHeader
closeBtn.TextSize = 18
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 22
closeBtn.Parent = header

touchFeedback(closeBtn, Theme.Card, Theme.Danger)

-- ═══════════════════════════════════════════════════════════════
-- SLIDE-OUT SIDEBAR - Full screen overlay with menu items
-- ═══════════════════════════════════════════════════════════════

local sidebarOverlay = Instance.new("Frame")
sidebarOverlay.Name = "SidebarOverlay"
sidebarOverlay.Size = UDim2.new(1, 0, 1, 0)
sidebarOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sidebarOverlay.BackgroundTransparency = 1
sidebarOverlay.Visible = false
sidebarOverlay.ZIndex = 100
sidebarOverlay.Parent = mainFrame

-- Dark backdrop that fades in
local sidebarBackdrop = Instance.new("TextButton")
sidebarBackdrop.Name = "Backdrop"
sidebarBackdrop.Size = UDim2.new(1, 0, 1, 0)
sidebarBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sidebarBackdrop.BackgroundTransparency = 1
sidebarBackdrop.Text = ""
sidebarBackdrop.AutoButtonColor = false
sidebarBackdrop.ZIndex = 101
sidebarBackdrop.Parent = sidebarOverlay

-- The actual sidebar panel (slides in from left)
local sidebarPanel = Instance.new("Frame")
sidebarPanel.Name = "Panel"
sidebarPanel.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
sidebarPanel.Position = UDim2.new(0, -SIDEBAR_W, 0, 0)  -- Start off-screen left
sidebarPanel.BackgroundColor3 = Theme.Sidebar
sidebarPanel.BorderSizePixel = 0
sidebarPanel.ZIndex = 102
sidebarPanel.Parent = sidebarOverlay

local sidebarPanelStroke = Instance.new("UIStroke")
sidebarPanelStroke.Color = Theme.Border
nsidebarPanelStroke.Thickness = 1
sidebarPanelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
sidebarPanelStroke.Parent = sidebarPanel

-- Sidebar items scroll
local sidebarScroller = Instance.new("ScrollingFrame")
sidebarScroller.Name = "SidebarScroll"
sidebarScroller.Size = UDim2.new(1, 0, 1, -HEADER_H)
sidebarScroller.Position = UDim2.new(0, 0, 0, HEADER_H)
sidebarScroller.BackgroundTransparency = 1
sidebarScroller.BorderSizePixel = 0
sidebarScroller.ScrollBarThickness = 4
sidebarScroller.ScrollBarImageColor3 = Theme.BorderLight
sidebarScroller.CanvasSize = UDim2.new(0, 0, 0, 700)
sidebarScroller.ZIndex = 103
sidebarScroller.Parent = sidebarPanel

local sidebarOpen = false

local function openSidebar()
	if sidebarOpen then return end
	sidebarOpen = true
	sidebarOverlay.Visible = true
	tween(sidebarBackdrop, {BackgroundTransparency = 0.6}, 0.25)
	tween(sidebarPanel, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart)
end

local function closeSidebar()
	if not sidebarOpen then return end
	sidebarOpen = false
	tween(sidebarBackdrop, {BackgroundTransparency = 1}, 0.2)
	tween(sidebarPanel, {Position = UDim2.new(0, -SIDEBAR_W, 0, 0)}, 0.25, Enum.EasingStyle.Quart).Completed:Connect(function()
		sidebarOverlay.Visible = false
	end)
end

hamburgerBtn.MouseButton1Click:Connect(openSidebar)
sidebarBackdrop.MouseButton1Click:Connect(closeSidebar)

-- ═══════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ═══════════════════════════════════════════════════════════════

local contentArea = Instance.new("Frame")
contentArea.Name = "Content"
contentArea.Size = UDim2.new(1, 0, 1, -(HEADER_H + TAB_H))
contentArea.Position = UDim2.new(0, 0, 0, HEADER_H)
contentArea.BackgroundColor3 = Theme.Background
contentArea.BorderSizePixel = 0
contentArea.ZIndex = 15
contentArea.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════
-- BOTTOM TAB BAR - Quick access to common pages
-- ═══════════════════════════════════════════════════════════════

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, TAB_H)
tabBar.Position = UDim2.new(0, 0, 1, -TAB_H)
tabBar.BackgroundColor3 = Theme.Sidebar
tabBar.BorderSizePixel = 0
ntabBar.ZIndex = 20
tabBar.Parent = mainFrame

local tabBarBorder = Instance.new("Frame")
tabBarBorder.Size = UDim2.new(1, 0, 0, 1)
tabBarBorder.BackgroundColor3 = Theme.Border
tabBarBorder.BorderSizePixel = 0
tabBarBorder.ZIndex = 21
tabBarBorder.Parent = tabBar

-- ═══════════════════════════════════════════════════════════════
-- COMPONENT BUILDERS
-- ═══════════════════════════════════════════════════════════════

-- ─── SECTION TITLE BOX ───
local function createSection(parent, title, icon, posY, width)
	local container = Instance.new("Frame")
	container.Name = "Section_" .. title
	container.Size = UDim2.new(1, -20, 0, 42)
	container.Position = UDim2.new(0, 10, 0, posY or 0)
	container.BackgroundColor3 = Theme.SectionBg
	container.BorderSizePixel = 0
	container.ZIndex = 30
	container.Parent = parent

	stroke(container, Theme.Border, 1)

	if icon and icon ~= "" then
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 28, 1, 0)
		iconLabel.Position = UDim2.new(0, 12, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon
		iconLabel.TextSize = 18
		iconLabel.ZIndex = 31
		iconLabel.Parent = container
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 1, 0)
	titleLabel.Position = UDim2.new(0, icon and 40 or 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Theme.TextActive
	titleLabel.Font = Theme.FontHeader
	titleLabel.TextSize = 15
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 31
	titleLabel.Parent = container

	return container
end

-- ─── DROPDOWN ───
-- Touch-optimized: bigger items, internal scroll, flush positioning
local function createDropdown(parent, title, icon, posY, items, onSelect)
	local myWidth = parent.AbsoluteSize and parent.AbsoluteSize.X - 20 or 350
	local itemHeight = 46  -- Bigger items for touch
	local maxVisibleItems = 5
	local maxDropdownHeight = maxVisibleItems * itemHeight + 8

	-- Container
	local container = Instance.new("Frame")
	container.Name = "Dropdown_" .. title
	container.Size = UDim2.new(1, -20, 0, 46)  -- Full width minus padding, taller
	container.Position = UDim2.new(0, 10, 0, posY or 0)
	container.BackgroundTransparency = 1
	container.ZIndex = 30
	container.Parent = parent

	-- Header button - bigger for touch
	local headerBtn = Instance.new("TextButton")
	headerBtn.Name = "Header"
	headerBtn.Size = UDim2.new(1, 0, 1, 0)
	headerBtn.BackgroundColor3 = Theme.Card
	headerBtn.BorderSizePixel = 0
	headerBtn.Text = ""
	headerBtn.AutoButtonColor = false
	headerBtn.ZIndex = 31
	headerBtn.Parent = container

	stroke(headerBtn, Theme.Border, 1)
	touchFeedback(headerBtn, Theme.Card, Theme.CardHover)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 28, 1, 0)
	iconLabel.Position = UDim2.new(0, 12, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon or ""
	iconLabel.TextSize = 18
	iconLabel.ZIndex = 32
	iconLabel.Parent = headerBtn

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -70, 1, 0)
	titleLabel.Position = UDim2.new(0, 40, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Dropdown"
	titleLabel.TextColor3 = Theme.TextActive
	titleLabel.Font = Theme.FontMain
	titleLabel.TextSize = 15
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 32
	titleLabel.Parent = headerBtn

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.Size = UDim2.new(0, 30, 1, 0)
	arrow.Position = UDim2.new(1, -34, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "v"
	arrow.TextColor3 = Theme.TextMuted
	arrow.TextSize = 14
	arrow.ZIndex = 32
	arrow.Parent = headerBtn

	-- Dropdown menu
	local menu = Instance.new("Frame")
	menu.Name = "DropdownMenu_" .. title
	menu.Size = UDim2.new(0, 0, 0, 0)
	menu.Position = UDim2.new(0, 0, 0, 0)
	menu.BackgroundColor3 = Theme.Card
	menu.BorderSizePixel = 0
	menu.ClipsDescendants = true
	menu.Visible = false
	menu.ZIndex = 550
	menu.Parent = dropdownOverlay

	stroke(menu, Theme.Border, 1)

	-- Internal scroller
	local menuScroller = Instance.new("ScrollingFrame")
	menuScroller.Name = "Scroller"
	menuScroller.Size = UDim2.new(1, 0, 1, 0)
	menuScroller.Position = UDim2.new(0, 0, 0, 0)
	menuScroller.BackgroundTransparency = 1
	menuScroller.BorderSizePixel = 0
	menuScroller.ScrollBarThickness = 4
	menuScroller.ScrollBarImageColor3 = Theme.BorderLight
	menuScroller.CanvasSize = UDim2.new(0, 0, 0, #items * itemHeight + 8)
	menuScroller.ZIndex = 551
	menuScroller.Parent = menu

	-- State
	local isOpen = false
	local selectedItem = nil
	local trackConnection = nil
	local myTrackerEntry = nil

	local function syncPosition()
		if not isOpen then return end
		local btnAbs = headerBtn.AbsolutePosition
		local mainAbs = mainFrame.AbsolutePosition
		local btnSize = headerBtn.AbsoluteSize
		menu.Position = UDim2.new(
			0, btnAbs.X - mainAbs.X,
			0, btnAbs.Y - mainAbs.Y + btnSize.Y
		)
		menu.Size = UDim2.new(0, btnSize.X, 0, menu.Size.Y.Offset)
	end

	local function doClose()
		if not isOpen then return end
		isOpen = false
		if trackConnection then
			trackConnection:Disconnect()
			trackConnection = nil
		end
		if myTrackerEntry then
			for i = #activeDropdowns, 1, -1 do
				if activeDropdowns[i] == myTrackerEntry then
					table.remove(activeDropdowns, i)
				end
			end
			myTrackerEntry = nil
		end
		tween(menu, {Size = UDim2.new(0, myWidth, 0, 0)}, 0.2).Completed:Connect(function()
			if not isOpen then menu.Visible = false end
		end)
		tween(arrow, {Rotation = 0}, 0.2)
	end

	local function doOpen()
		if isOpen then return end
		closeAllDropdowns()
		isOpen = true
		syncPosition()
		menu.Visible = true
		local totalItemsHeight = #items * itemHeight + 8
		local targetHeight = math.min(totalItemsHeight, maxDropdownHeight)
		tween(menu, {Size = UDim2.new(0, myWidth, 0, targetHeight)}, 0.2)
		tween(arrow, {Rotation = 180}, 0.2)
		trackConnection = RunService.RenderStepped:Connect(syncPosition)
		myTrackerEntry = {close = doClose}
		table.insert(activeDropdowns, myTrackerEntry)
	end

	local function toggleMenu()
		if isOpen then doClose() else doOpen() end
	end

	-- Build items
	for i, itemData in ipairs(items or {}) do
		local itemBtn = Instance.new("TextButton")
		itemBtn.Name = "Item_" .. tostring(i)
		itemBtn.Size = UDim2.new(1, -16, 0, itemHeight)
		itemBtn.Position = UDim2.new(0, 8, 0, 4 + (i-1) * itemHeight)
		itemBtn.BackgroundColor3 = Theme.ButtonNormal
		itemBtn.BorderSizePixel = 0
		itemBtn.Text = ""
		itemBtn.AutoButtonColor = false
		itemBtn.ZIndex = 552
		itemBtn.Parent = menuScroller

		touchFeedback(itemBtn, Theme.ButtonNormal, Theme.Accent)

		local itemText = Instance.new("TextLabel")
		itemText.Size = UDim2.new(1, -20, 1, 0)
		itemText.Position = UDim2.new(0, 10, 0, 0)
		itemText.BackgroundTransparency = 1
		if type(itemData) == "string" then
			itemText.Text = itemData
		elseif type(itemData) == "table" then
			itemText.Text = itemData.text or tostring(itemData)
		end
		itemText.TextColor3 = Theme.TextMuted
		itemText.Font = Theme.FontMain
		itemText.TextSize = 14
		itemText.TextXAlignment = Enum.TextXAlignment.Left
		itemText.ZIndex = 553
		itemText.Parent = itemBtn

		-- Visual hover/active feedback
		itemBtn.MouseEnter:Connect(function()
			tween(itemBtn, {BackgroundColor3 = Theme.Accent}, 0.1)
			itemText.TextColor3 = Theme.TextActive
		end)
		itemBtn.MouseLeave:Connect(function()
			if selectedItem ~= itemBtn then
				tween(itemBtn, {BackgroundColor3 = Theme.ButtonNormal}, 0.1)
				itemText.TextColor3 = Theme.TextMuted
			end
		end)

		itemBtn.MouseButton1Click:Connect(function()
			if selectedItem then
				tween(selectedItem, {BackgroundColor3 = Theme.ButtonNormal}, 0.1)
				local prevText = selectedItem:FindFirstChildOfClass("TextLabel")
				if prevText then prevText.TextColor3 = Theme.TextMuted end
			end
			selectedItem = itemBtn
			tween(itemBtn, {BackgroundColor3 = Theme.Accent}, 0.1)
			itemText.TextColor3 = Theme.TextActive

			if type(itemData) == "string" then
				titleLabel.Text = itemData
			elseif type(itemData) == "table" then
				titleLabel.Text = itemData.text or tostring(itemData)
			end

			doClose()

			if onSelect then
				if type(itemData) == "string" then
					onSelect(itemData)
				elseif type(itemData) == "table" then
					onSelect(itemData.value or itemData.text)
				end
			end
		end)
	end

	headerBtn.MouseButton1Click:Connect(toggleMenu)

	dropdownOverlay.InputBegan:Connect(function(input)
		if not isOpen then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = input.Position
			local menuPos = menu.AbsolutePosition
			local menuSize = menu.AbsoluteSize
			if mousePos.X < menuPos.X or mousePos.X > menuPos.X + menuSize.X
				or mousePos.Y < menuPos.Y or mousePos.Y > menuPos.Y + menuSize.Y then
				local btnPos = headerBtn.AbsolutePosition
				local btnSize = headerBtn.AbsoluteSize
				local onBtn = mousePos.X >= btnPos.X and mousePos.X <= btnPos.X + btnSize.X
					and mousePos.Y >= btnPos.Y and mousePos.Y <= btnPos.Y + btnSize.Y
				if not onBtn then doClose() end
			end
		end
	end)

	return {container = container, header = headerBtn, menu = menu}
end

-- ─── TOGGLE ───
local function createToggle(parent, label, posY, onChange)
	local container = Instance.new("Frame")
	container.Name = "Toggle_" .. (label or "Toggle")
	container.Size = UDim2.new(1, -20, 0, 52)  -- Taller for touch
	container.Position = UDim2.new(0, 10, 0, posY or 0)
	container.BackgroundColor3 = Theme.Card
	container.BorderSizePixel = 0
	container.ZIndex = 30
	container.Parent = parent

	stroke(container, Theme.Border, 1)

	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(1, -90, 1, 0)
	labelText.Position = UDim2.new(0, 14, 0, 0)
	labelText.BackgroundTransparency = 1
	labelText.Text = label or "Toggle"
	labelText.TextColor3 = Theme.TextActive
	labelText.Font = Theme.FontMain
	labelText.TextSize = 15
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.ZIndex = 31
	labelText.Parent = container

	local switchBg = Instance.new("TextButton")
	switchBg.Name = "SwitchBg"
	switchBg.Size = UDim2.new(0, 52, 0, 30)  -- Bigger switch
	switchBg.Position = UDim2.new(1, -64, 0.5, -15)
	switchBg.BackgroundColor3 = Theme.ButtonNormal
	switchBg.BorderSizePixel = 0
	switchBg.Text = ""
	switchBg.AutoButtonColor = false
	switchBg.ZIndex = 31
	switchBg.Parent = container

	local switchCorner = Instance.new("UICorner")
	switchCorner.CornerRadius = UDim.new(1, 0)
	switchCorner.Parent = switchBg

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 24, 0, 24)  -- Bigger knob
	knob.Position = UDim2.new(0, 3, 0.5, -12)
	knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	knob.BorderSizePixel = 0
	knob.ZIndex = 32
	knob.Parent = switchBg

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local enabled = false

	local function update()
		if enabled then
			tween(switchBg, {BackgroundColor3 = Theme.Success}, 0.2)
			tween(knob, {Position = UDim2.new(0, 25, 0.5, -12), BackgroundColor3 = Color3.fromRGB(255,255,255)}, 0.2)
		else
			tween(switchBg, {BackgroundColor3 = Theme.ButtonNormal}, 0.2)
			tween(knob, {Position = UDim2.new(0, 3, 0.5, -12), BackgroundColor3 = Color3.fromRGB(200,200,200)}, 0.2)
		end
		if onChange then onChange(enabled) end
	end

	switchBg.MouseButton1Click:Connect(function()
		enabled = not enabled
		update()
	end)

	return {
		container = container,
		getValue = function() return enabled end,
		setValue = function(v) enabled = v; update() end
	}
end

-- ─── BUTTON ───
local function createButton(parent, text, posY, color, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = "Button_" .. (text or "Btn")
	btn.Size = UDim2.new(1, -20, 0, 46)  -- Full width, tall for touch
	btn.Position = UDim2.new(0, 10, 0, posY or 0)
	btn.BackgroundColor3 = color or Theme.ButtonNormal
	btn.BorderSizePixel = 0
	btn.Text = text or "Button"
	btn.TextColor3 = Theme.TextActive
	btn.Font = Theme.FontMain
	btn.TextSize = 14
	btn.AutoButtonColor = false
	btn.ZIndex = 30
	btn.Parent = parent

	stroke(btn, Theme.Border, 1)
	touchFeedback(btn, color or Theme.ButtonNormal, Theme.CardHover)

	btn.MouseButton1Click:Connect(function()
		if onClick then onClick() end
	end)

	return btn
end

-- ─── SLIDER ───
local function createSlider(parent, label, posY, min, max, default, onChange)
	local container = Instance.new("Frame")
	container.Name = "Slider_" .. (label or "Slider")
	container.Size = UDim2.new(1, -20, 0, 60)
	container.Position = UDim2.new(0, 10, 0, posY or 0)
	container.BackgroundColor3 = Theme.Card
	container.BorderSizePixel = 0
	container.ZIndex = 30
	container.Parent = parent

	stroke(container, Theme.Border, 1)

	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(1, -80, 0, 24)
	labelText.Position = UDim2.new(0, 14, 0, 6)
	labelText.BackgroundTransparency = 1
	labelText.Text = label or "Slider"
	labelText.TextColor3 = Theme.TextActive
	labelText.Font = Theme.FontMain
	labelText.TextSize = 14
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.ZIndex = 31
	labelText.Parent = container

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0, 60, 0, 24)
	valueLabel.Position = UDim2.new(1, -68, 0, 6)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default or min or 0)
	valueLabel.TextColor3 = Theme.Accent
	valueLabel.Font = Theme.FontMain
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 31
	valueLabel.Parent = container

	-- Thicker track for touch
	local sliderBg = Instance.new("Frame")
	sliderBg.Name = "Track"
	sliderBg.Size = UDim2.new(1, -28, 0, 8)
	sliderBg.Position = UDim2.new(0, 14, 0, 38)
	sliderBg.BackgroundColor3 = Theme.ButtonNormal
	sliderBg.BorderSizePixel = 0
	sliderBg.ZIndex = 31
	sliderBg.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0.5, 0, 1, 0)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.ZIndex = 32
	fill.Parent = sliderBg

	-- Bigger knob for touch
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.Position = UDim2.new(0.5, -10, 0.5, -10)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 33
	knob.Parent = sliderBg

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	-- Bigger invisible hit area for easier grabbing
	local hitArea = Instance.new("TextButton")
	hitArea.Name = "HitArea"
	hitArea.Size = UDim2.new(1, 40, 1, 30)
	hitArea.Position = UDim2.new(0, -20, 0, -15)
	hitArea.BackgroundTransparency = 1
	hitArea.Text = ""
	hitArea.ZIndex = 34
	hitArea.Parent = sliderBg

	local dragging = false
	local minVal = min or 0
	local maxVal = max or 100
	local currentVal = default or minVal

	local function updateSlider(inputX)
		local sliderPos = sliderBg.AbsolutePosition.X
		local sliderWidth = sliderBg.AbsoluteSize.X
		local pos = math.clamp((inputX - sliderPos) / sliderWidth, 0, 1)
		currentVal = math.floor(minVal + (maxVal - minVal) * pos)
		fill.Size = UDim2.new(pos, 0, 1, 0)
		knob.Position = UDim2.new(pos, -10, 0.5, -10)
		valueLabel.Text = tostring(currentVal)
		if onChange then onChange(currentVal) end
	end

	hitArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateSlider(input.Position.X)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input.Position.X)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return {
		container = container,
		getValue = function() return currentVal end,
		setValue = function(v)
			currentVal = math.clamp(v, minVal, maxVal)
			local pos = (currentVal - minVal) / (maxVal - minVal)
			fill.Size = UDim2.new(pos, 0, 1, 0)
			knob.Position = UDim2.new(pos, -10, 0.5, -10)
			valueLabel.Text = tostring(currentVal)
		end
	}
end

-- ─── INPUT ───
local function createInput(parent, placeholder, posY, onSubmit)
	local container = Instance.new("Frame")
	container.Name = "Input_" .. (placeholder or "Input")
	container.Size = UDim2.new(1, -20, 0, 46)
	container.Position = UDim2.new(0, 10, 0, posY or 0)
	container.BackgroundColor3 = Theme.Card
	container.BorderSizePixel = 0
	container.ZIndex = 30
	container.Parent = parent

	stroke(container, Theme.Border, 1)

	local input = Instance.new("TextBox")
	input.Name = "TextBox"
	input.Size = UDim2.new(1, -24, 1, 0)
	input.Position = UDim2.new(0, 12, 0, 0)
	input.BackgroundTransparency = 1
	input.Text = ""
	input.PlaceholderText = placeholder or "Enter text..."
	input.TextColor3 = Theme.TextActive
	input.PlaceholderColor3 = Theme.TextDark
	input.Font = Theme.FontMain
	input.TextSize = 14
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.ClearTextOnFocus = false
	input.ZIndex = 31
	input.Parent = container

	input.FocusLost:Connect(function(enterPressed)
		if enterPressed and onSubmit then
			onSubmit(input.Text)
		end
	end)

	return {
		container = container,
		getText = function() return input.Text end,
		setText = function(t) input.Text = t end
	}
end

-- ─── CARD ───
local function createCard(parent, title, icon, posY, height)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. (title or "Card")
	card.Size = UDim2.new(1, -20, 0, height or 120)
	card.Position = UDim2.new(0, 10, 0, posY or 0)
	card.BackgroundColor3 = Theme.Card
	card.BorderSizePixel = 0
	card.ZIndex = 30
	card.Parent = parent

	stroke(card, Theme.Border, 1)

	local cardHeader = Instance.new("Frame")
	cardHeader.Name = "Header"
	cardHeader.Size = UDim2.new(1, 0, 0, 42)
	cardHeader.BackgroundTransparency = 1
	cardHeader.ZIndex = 31
	cardHeader.Parent = card

	if icon then
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(0, 28, 1, 0)
		iconLabel.Position = UDim2.new(0, 12, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon
		iconLabel.TextSize = 18
		iconLabel.ZIndex = 32
		iconLabel.Parent = cardHeader
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 1, 0)
	titleLabel.Position = UDim2.new(0, icon and 40 or 14, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Card"
	titleLabel.TextColor3 = Theme.TextActive
	titleLabel.Font = Theme.FontHeader
	titleLabel.TextSize = 15
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 32
	titleLabel.Parent = cardHeader

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -50)
	content.Position = UDim2.new(0, 10, 0, 44)
	content.BackgroundTransparency = 1
	content.ZIndex = 31
	content.Parent = card

	return {card = card, header = cardHeader, content = content}
end

-- ─── LABEL ───
local function createLabel(parent, text, posY, color, size)
	local label = Instance.new("TextLabel")
	label.Name = "Label_" .. (text or "Label")
	label.Size = UDim2.new(1, -24, 0, size or 24)
	label.Position = UDim2.new(0, 12, 0, posY or 0)
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextColor3 = color or Theme.TextMuted
	label.Font = Theme.FontMain
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.ZIndex = 31
	label.Parent = parent
	return label
end

-- ═══════════════════════════════════════════════════════════════
-- PAGE SYSTEM
-- ═══════════════════════════════════════════════════════════════

local pages = {}
local currentPageName = "Account"

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Position = UDim2.new(0, 0, 0, 0)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 5
	page.ScrollBarImageColor3 = Theme.BorderLight
	page.CanvasSize = UDim2.new(0, 0, 0, 1000)
	page.ZIndex = 25
	page.Visible = false
	page.Parent = contentArea
	pages[name] = page
	return page
end

local function switchPage(pageName)
	closeAllDropdowns()
	closeSidebar()
	currentPageName = pageName
	for name, page in pairs(pages) do
		page.Visible = (name == pageName)
	end
	-- Update tab bar highlighting
	for name, tab in pairs(tabButtons) do
		if name == pageName then
			tween(tab, {BackgroundColor3 = Theme.Accent}, 0.15)
			tab.TextColor3 = Theme.TextActive
		else
			tween(tab, {BackgroundColor3 = Theme.Sidebar}, 0.15)
			tab.TextColor3 = Theme.TextMuted
		end
	end
end

-- ═══════════════════════════════════════════════════════════════
-- SIDEBAR ITEMS
-- ═══════════════════════════════════════════════════════════════

local sidebarItems = {
	{name = "Account",    icon = "", color = Theme.Accent},
	{name = "Home",       icon = "",  color = Theme.TextMuted},
	{name = "Premium",    icon = "", color = Theme.Pink},
	{name = "Hatching",   icon = "",   color = Theme.Pink},
	{name = "Eggs",       icon = "",    color = Theme.TextMuted},
	{name = "PetSell",    icon = "",    color = Theme.TextMuted},
	{name = "Plants",     icon = "",   color = Theme.Pink},
	{name = "Event",      icon = "",   color = Theme.Cyan},
	{name = "PetManager", icon = "",    color = Theme.TextMuted},
	{name = "Craft",      icon = "",  color = Theme.Warning},
	{name = "Fruit",      icon = "",   color = Theme.TextMuted},
	{name = "Shopping",   icon = "", color = Theme.TextMuted},
	{name = "Selling",    icon = "",    color = Theme.TextMuted},
	{name = "Misc",       icon = "",  color = Theme.TextMuted},
	{name = "Settings",   icon = "", color = Theme.TextMuted},
}

local sidebarButtonsList = {}

-- Build sidebar items (bigger touch targets)
for i, data in ipairs(sidebarItems) do
	local btn = Instance.new("TextButton")
	btn.Name = data.name
	btn.Size = UDim2.new(1, -16, 0, 46)
	btn.Position = UDim2.new(0, 8, 0, 8 + (i - 1) * 50)
	btn.BackgroundColor3 = data.name == "Account" and Theme.Card or Color3.fromRGB(0,0,0)
	btn.BackgroundTransparency = data.name == "Account" and 0 or 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.ZIndex = 104
	btn.Parent = sidebarScroller

	touchFeedback(btn, data.name == "Account" and Theme.Card or Theme.Sidebar, Theme.CardHover)

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 28, 1, 0)
	icon.Position = UDim2.new(0, 12, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = data.icon
	icon.TextSize = 20
	icon.ZIndex = 105
	icon.Parent = btn

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -48, 1, 0)
	label.Position = UDim2.new(0, 42, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = data.name
	label.TextColor3 = data.name == "Account" and data.color or Theme.TextMuted
	label.Font = Theme.FontMain
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 105
	label.Parent = btn

	btn.MouseButton1Click:Connect(function()
		-- Deselect all
		for _, b in ipairs(sidebarButtonsList) do
			tween(b, {BackgroundTransparency = 1}, 0.1)
			local lbl = b:FindFirstChild("Label")
			if lbl then lbl.TextColor3 = Theme.TextMuted end
		end
		-- Select this
		tween(btn, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Card}, 0.1)
		label.TextColor3 = data.color
		switchPage(data.name)
	end)

	table.insert(sidebarButtonsList, btn)
end

-- ═══════════════════════════════════════════════════════════════
-- BOTTOM TAB BAR - 4 quick-access tabs
-- ═══════════════════════════════════════════════════════════════

local tabButtons = {}
local tabData = {
	{name = "Account", icon = "", color = Theme.Accent},
	{name = "Home",    icon = "",  color = Theme.TextMuted},
	{name = "Premium", icon = "", color = Theme.Pink},
	{name = "Settings",icon = "", color = Theme.TextMuted},
}

local tabWidth = 1 / #tabData

for i, data in ipairs(tabData) do
	local tab = Instance.new("TextButton")
	tab.Name = "Tab_" .. data.name
	tab.Size = UDim2.new(tabWidth, 0, 1, 0)
	tab.Position = UDim2.new((i - 1) * tabWidth, 0, 0, 0)
	tab.BackgroundColor3 = data.name == "Account" and Theme.Accent or Theme.Sidebar
	tab.BorderSizePixel = 0
	tab.Text = data.icon .. "\n" .. data.name
	tab.TextColor3 = Theme.TextActive
	tab.Font = Theme.FontMain
	tab.TextSize = 11
	tab.AutoButtonColor = false
	tab.ZIndex = 22
	tab.Parent = tabBar

	touchFeedback(tab, data.name == "Account" and Theme.Accent or Theme.Sidebar, Theme.CardHover)

	tab.MouseButton1Click:Connect(function()
		switchPage(data.name)
	end)

	tabButtons[data.name] = tab
end

-- ═══════════════════════════════════════════════════════════════
-- SWIPE NAVIGATION - Swipe left/right to switch between pages
-- ═══════════════════════════════════════════════════════════════

local swipeStart = nil
local swipePageOrder = {"Account", "Home", "Premium", "Hatching", "Eggs", "PetSell", "Plants", "Event", "PetManager", "Craft", "Fruit", "Shopping", "Selling", "Misc", "Settings"}

contentArea.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		swipeStart = input.Position
	end
end)

contentArea.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch and swipeStart then
		local delta = input.Position.X - swipeStart.X
		if math.abs(delta) > 80 then  -- Min 80px swipe
			-- Find current index
			local currentIdx = 1
			for i, name in ipairs(swipePageOrder) do
				if name == currentPageName then
					currentIdx = i
					break
				end
			end
			if delta < 0 and currentIdx < #swipePageOrder then
				-- Swipe left = next page
				switchPage(swipePageOrder[currentIdx + 1])
			elseif delta > 0 and currentIdx > 1 then
				-- Swipe right = previous page
				switchPage(swipePageOrder[currentIdx - 1])
			end
		end
		swipeStart = nil
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- CLOSE BUTTON
-- ═══════════════════════════════════════════════════════════════

closeBtn.MouseButton1Click:Connect(function()
	safePrint("Hiding UI...")
	open = false
	closeAllDropdowns()
	closeSidebar()
	mainFrame.Visible = false
end)

-- ═══════════════════════════════════════════════════════════════
-- ACCOUNT PAGE
-- ═══════════════════════════════════════════════════════════════

local accountPage = createPage("Account")

createSection(accountPage, "Account", "", 8)
createLabel(accountPage, "Account settings and key management", 56, Theme.TextDark, 20)

createDropdown(accountPage, "Account", "", 82, {
	{text = "Account Settings", value = "settings"},
	{text = "Profile", value = "profile"},
	{text = "Billing", value = "billing"},
	{text = "API Keys", value = "api"},
}, function(value)
	safePrint("Account option:", value)
end)

createSection(accountPage, "Key Status", nil, 140)

local keyCard = createCard(accountPage, "", nil, 190, 100)
createLabel(keyCard.content, "Key expires in 5 days 18 hours 2 min", 0, Theme.TextMuted, 22)

createButton(keyCard.content, "Join Discord", 32, Theme.ButtonNormal, function()
	safePrint("Joining Discord...")
end)

createSection(accountPage, "Logout", nil, 306)

local logoutCard = createCard(accountPage, "", nil, 356, 76)

createButton(logoutCard.content, "Logout", 8, Theme.Danger, function()
	safePrint("Logging out...")
end)

-- ═══════════════════════════════════════════════════════════════
-- HOME PAGE
-- ═══════════════════════════════════════════════════════════════

local homePage = createPage("Home")

createSection(homePage, "Dashboard", "", 8)
createLabel(homePage, "Welcome to _hub Mobile! Swipe left/right to navigate between pages. Use the sidebar or bottom tabs to jump to any section.", 56, Theme.TextMuted, 60)

local statsCard = createCard(homePage, "Statistics", "", 120, 140)
createLabel(statsCard.content, "Scripts Executed: 1,247", 0, Theme.TextMuted, 26)
createLabel(statsCard.content, "Active Sessions: 3", 30, Theme.TextMuted, 26)
createLabel(statsCard.content, "Last Login: Just now", 60, Theme.TextMuted, 26)

-- ═══════════════════════════════════════════════════════════════
-- PREMIUM PAGE
-- ═══════════════════════════════════════════════════════════════

local premiumPage = createPage("Premium")

createSection(premiumPage, "Premium Features", "", 8)

createDropdown(premiumPage, "Premium Plan", "", 54, {
	{text = "Basic ($5/mo)", value = "basic"},
	{text = "Pro ($10/mo)", value = "pro"},
	{text = "Elite ($20/mo)", value = "elite"},
}, function(val)
	safePrint("Premium plan:", val)
end)

createSlider(premiumPage, "Farm Speed", 114, 1, 10, 5, function(val)
	safePrint("Farm Speed:", val)
end)

createSlider(premiumPage, "Collection Range", 186, 1, 50, 25, function(val)
	safePrint("Collection Range:", val)
end)

createToggle(premiumPage, "Auto Farm Premium", 258, function(val)
	safePrint("Premium Auto Farm:", val)
end)

createToggle(premiumPage, "Priority Queue", 320, function(val)
	safePrint("Priority Queue:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- HATCHING PAGE
-- ═══════════════════════════════════════════════════════════════

local hatchingPage = createPage("Hatching")

createSection(hatchingPage, "Hatching Teams", "", 8)

createDropdown(hatchingPage, "Select Team", "", 54, {
	{text = "Team Alpha", value = "alpha"},
	{text = "Team Beta", value = "beta"},
	{text = "Team Gamma", value = "gamma"},
}, function(val)
	safePrint("Selected team:", val)
end)

createSlider(hatchingPage, "Hatch Speed", 114, 1, 100, 50, function(val)
	safePrint("Hatch Speed:", val)
end)

createToggle(hatchingPage, "Auto Hatch", 186, function(val)
	safePrint("Auto Hatch:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- EGGS PAGE
-- ═══════════════════════════════════════════════════════════════

local eggsPage = createPage("Eggs")

createSection(eggsPage, "Eggs Priority", "", 8)

createDropdown(eggsPage, "Egg Type", "", 54, {
	{text = "Golden Egg", value = "golden"},
	{text = "Crystal Egg", value = "crystal"},
	{text = "Mystic Egg", value = "mystic"},
	{text = "Basic Egg", value = "basic"},
}, function(val)
	safePrint("Selected egg:", val)
end)

createSlider(eggsPage, "Buy Amount", 114, 1, 100, 10, function(val)
	safePrint("Buy amount:", val)
end)

createToggle(eggsPage, "Auto Buy Eggs", 186, function(val)
	safePrint("Auto Buy Eggs:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- PET SELL PAGE
-- ═══════════════════════════════════════════════════════════════

local petSellPage = createPage("PetSell")

createSection(petSellPage, "Pet Sell Settings", "", 8)

createDropdown(petSellPage, "Sell Mode", "", 54, {
	{text = "Sell All Below", value = "below"},
	{text = "Sell Duplicates", value = "duplicates"},
	{text = "Sell Selected", value = "selected"},
}, function(val)
	safePrint("Sell mode:", val)
end)

createSlider(petSellPage, "Minimum Rarity", 114, 1, 5, 3, function(val)
	safePrint("Min rarity:", val)
end)

createToggle(petSellPage, "Auto Sell Common", 186, function(val)
	safePrint("Auto Sell Common:", val)
end)

createToggle(petSellPage, "Auto Sell Uncommon", 248, function(val)
	safePrint("Auto Sell Uncommon:", val)
end)

createToggle(petSellPage, "Auto Sell Rare", 310, function(val)
	safePrint("Auto Sell Rare:", val)
end)

createInput(petSellPage, "Minimum sell price...", 372, function(text)
	safePrint("Min sell price:", text)
end)

-- ═══════════════════════════════════════════════════════════════
-- PLANTS PAGE
-- ═══════════════════════════════════════════════════════════════

local plantsPage = createPage("Plants")

createSection(plantsPage, "Plants & Packs", "", 8)

createDropdown(plantsPage, "Plant Type", "", 54, {
	{text = "Sunflower", value = "sunflower"},
	{text = "Rose", value = "rose"},
	{text = "Cactus", value = "cactus"},
}, function(val)
	safePrint("Selected plant:", val)
end)

createSlider(plantsPage, "Growth Speed", 114, 1, 10, 5, function(val)
	safePrint("Growth speed:", val)
end)

createToggle(plantsPage, "Auto Harvest", 186, function(val)
	safePrint("Auto Harvest:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- EVENT PAGE
-- ═══════════════════════════════════════════════════════════════

local eventPage = createPage("Event")

createSection(eventPage, "Event & Mutation", "", 8)

createDropdown(eventPage, "Current Event", "", 54, {
	{text = "Summer Event 2026", value = "summer"},
	{text = "Winter Event", value = "winter"},
	{text = "Halloween Event", value = "halloween"},
}, function(val)
	safePrint("Selected event:", val)
end)

createSlider(eventPage, "Event Difficulty", 114, 1, 10, 5, function(val)
	safePrint("Difficulty:", val)
end)

createToggle(eventPage, "Auto Event", 186, function(val)
	safePrint("Auto Event:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- PET MANAGER PAGE
-- ═══════════════════════════════════════════════════════════════

local petManagerPage = createPage("PetManager")

createSection(petManagerPage, "Pet Manager", "", 8)

createDropdown(petManagerPage, "Manage Pets", "", 54, {
	{text = "Equip Best", value = "equip"},
	{text = "Unequip All", value = "unequip"},
	{text = "Delete Duplicates", value = "delete"},
}, function(val)
	safePrint("Pet action:", val)
end)

createSlider(petManagerPage, "Max Pets", 114, 1, 50, 20, function(val)
	safePrint("Max pets:", val)
end)

createToggle(petManagerPage, "Auto Equip Best", 186, function(val)
	safePrint("Auto Equip Best:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- CRAFT PAGE
-- ═══════════════════════════════════════════════════════════════

local craftPage = createPage("Craft")

createSection(craftPage, "Craft and Cook", "", 8)

createDropdown(craftPage, "Recipe", "", 54, {
	{text = "Health Potion", value = "health"},
	{text = "Speed Potion", value = "speed"},
	{text = "Strength Potion", value = "strength"},
}, function(val)
	safePrint("Selected recipe:", val)
end)

createSlider(craftPage, "Craft Amount", 114, 1, 100, 10, function(val)
	safePrint("Craft amount:", val)
end)

createSlider(craftPage, "Quality Level", 186, 1, 5, 3, function(val)
	safePrint("Quality:", val)
end)

createToggle(craftPage, "Auto Craft", 258, function(val)
	safePrint("Auto Craft:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- FRUIT PAGE
-- ═══════════════════════════════════════════════════════════════

local fruitPage = createPage("Fruit")

createSection(fruitPage, "Fruit Collection", "", 8)

createDropdown(fruitPage, "Fruit Type", "", 54, {
	{text = "Apple", value = "apple"},
	{text = "Banana", value = "banana"},
	{text = "Orange", value = "orange"},
}, function(val)
	safePrint("Selected fruit:", val)
end)

createSlider(fruitPage, "Collection Radius", 114, 1, 50, 25, function(val)
	safePrint("Radius:", val)
end)

createToggle(fruitPage, "Auto Collect", 186, function(val)
	safePrint("Auto Collect Fruit:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- SHOPPING PAGE
-- ═══════════════════════════════════════════════════════════════

local shoppingPage = createPage("Shopping")

createSection(shoppingPage, "Shopping", "", 8)

createDropdown(shoppingPage, "Shop Category", "", 54, {
	{text = "Weapons", value = "weapons"},
	{text = "Armor", value = "armor"},
	{text = "Consumables", value = "consumables"},
}, function(val)
	safePrint("Shop category:", val)
end)

createSlider(shoppingPage, "Buy Limit", 114, 1, 100, 10, function(val)
	safePrint("Buy limit:", val)
end)

createToggle(shoppingPage, "Auto Buy", 186, function(val)
	safePrint("Auto Buy:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- SELLING PAGE
-- ═══════════════════════════════════════════════════════════════

local sellingPage = createPage("Selling")

createSection(sellingPage, "Selling", "", 8)

createDropdown(sellingPage, "Sell Strategy", "", 54, {
	{text = "Quick Sell", value = "quick"},
	{text = "Market Price", value = "market"},
	{text = "Hold for Value", value = "hold"},
}, function(val)
	safePrint("Sell strategy:", val)
end)

createSlider(sellingPage, "Sell Below Rarity", 114, 1, 5, 3, function(val)
	safePrint("Sell below rarity:", val)
end)

createToggle(sellingPage, "Auto Sell", 186, function(val)
	safePrint("Auto Sell:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- MISC PAGE
-- ═══════════════════════════════════════════════════════════════

local miscPage = createPage("Misc")

createSection(miscPage, "Misc Shops", "", 8)

createDropdown(miscPage, "Shop", "", 54, {
	{text = "General Store", value = "general"},
	{text = "Black Market", value = "blackmarket"},
	{text = "Premium Shop", value = "premium"},
}, function(val)
	safePrint("Misc shop:", val)
end)

createSlider(miscPage, "Refresh Interval", 114, 1, 60, 30, function(val)
	safePrint("Refresh interval:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS PAGE
-- ═══════════════════════════════════════════════════════════════

local settingsPage = createPage("Settings")

createSection(settingsPage, "Settings", "", 8)

createDropdown(settingsPage, "Theme", "", 54, {
	{text = "Dark", value = "dark"},
	{text = "Darker", value = "darker"},
	{text = "AMOLED", value = "amoled"},
}, function(val)
	safePrint("Theme:", val)
end)

createSlider(settingsPage, "UI Scale", 114, 50, 150, 100, function(val)
	safePrint("UI Scale:", val .. "%")
end)

createSlider(settingsPage, "Transparency", 186, 0, 100, 0, function(val)
	safePrint("Transparency:", val .. "%")
end)

createToggle(settingsPage, "Anti-AFK", 258, function(val)
	safePrint("Anti-AFK:", val)
end)

createToggle(settingsPage, "Auto Rejoin", 320, function(val)
	safePrint("Auto Rejoin:", val)
end)

createToggle(settingsPage, "Discord RPC", 382, function(val)
	safePrint("Discord RPC:", val)
end)

createButton(settingsPage, "Reset All Settings", 450, Theme.Danger, function()
	safePrint("Resetting all settings...")
end)

-- ═══════════════════════════════════════════════════════════════
-- SHOW ACCOUNT PAGE BY DEFAULT
-- ═══════════════════════════════════════════════════════════════

switchPage("Account")

-- ═══════════════════════════════════════════════════════════════
-- LAUNCHER ICON - Big and touchable
-- ═══════════════════════════════════════════════════════════════

local open = false

local launcher = Instance.new("TextButton")
launcher.Name = "Launcher"
launcher.Size = UDim2.new(0, 58, 0, 58)
launcher.Position = UDim2.new(0, 16, 0, 16)
launcher.BackgroundColor3 = Theme.Accent
launcher.BorderSizePixel = 0
launcher.Text = "L"
launcher.TextSize = 26
launcher.Font = Theme.FontHeader
launcher.TextColor3 = Color3.fromRGB(255, 255, 255)
launcher.AutoButtonColor = false
launcher.ZIndex = 100
launcher.Parent = screenGui

local launcherCorner = Instance.new("UICorner")
launcherCorner.CornerRadius = UDim.new(1, 0)
launcherCorner.Parent = launcher

stroke(launcher, Theme.AccentHover, 2)

touchFeedback(launcher, Theme.Accent, Theme.AccentHover)

launcher.MouseButton1Click:Connect(function()
	if open then
		open = false
		closeAllDropdowns()
		closeSidebar()
		mainFrame.Visible = false
	else
		open = true
		mainFrame.Visible = true
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

print("")
print("╔══════════════════════════════════════════╗")
print("║      _hub MOBILE v1.0 - LOADED           ║")
print("╠══════════════════════════════════════════╣")
print("║  Full screen | Bottom tabs | Swipe nav   ║")
print("║  Touch feedback | Slide sidebar          ║")
print("╠══════════════════════════════════════════╣")
print("║  Open: Tap purple 'L' launcher           ║")
print("║  Navigate: Swipe left/right or tap tabs  ║")
print("║  Menu: Tap hamburger (3 lines)           ║")
print("╚══════════════════════════════════════════╝")
print("")