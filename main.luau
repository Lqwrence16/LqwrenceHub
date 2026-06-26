--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    _hub - Roblox Script Hub                  ║
    ║                        Version 5.5                           ║
    ║                                                              ║
    ║  Dropdown: flush against button | internal scroll | scroll   ║
    ║  capture so outside page doesn't scroll when in dropdown     ║
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
-- PLATFORM DETECTION
-- ═══════════════════════════════════════════════════════════════

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ═══════════════════════════════════════════════════════════════
-- THEME
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
	DangerHover = Color3.fromRGB(240, 80, 80),
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
-- WINDOW SIZES
-- ═══════════════════════════════════════════════════════════════

local WINDOW_W = isMobile and 360 or 750
local WINDOW_H = isMobile and 520 or 480
local SIDEBAR_W = isMobile and 140 or 190
local HEADER_H = isMobile and 55 or 50
local FOOTER_H = 28

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

local function safePrint(...)
	local args = {...}
	local msg = ""
	for i, v in ipairs(args) do
		msg = msg .. tostring(v) .. " "
	end
	print("[_hub] " .. msg)
end

-- ═══════════════════════════════════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "_hub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = playerGui

-- ═══════════════════════════════════════════════════════════════
-- MAIN WINDOW FRAME
-- ═══════════════════════════════════════════════════════════════

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
mainFrame.Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui

stroke(mainFrame, Theme.Border, 1.5)

local uiScale = Instance.new("UIScale")
uiScale.Scale = isMobile and 1.05 or 1
uiScale.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════
-- DROPDOWN OVERLAY
-- ═══════════════════════════════════════════════════════════════

local dropdownOverlay = Instance.new("Frame")
dropdownOverlay.Name = "DropdownOverlay"
dropdownOverlay.Size = UDim2.new(1, -SIDEBAR_W, 1, -(HEADER_H + FOOTER_H))
dropdownOverlay.Position = UDim2.new(0, SIDEBAR_W, 0, HEADER_H)
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
-- HEADER BAR
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

-- ═══════════════════════════════════════════════════════════════
-- LOGO
-- ═══════════════════════════════════════════════════════════════

local logoIcon = Instance.new("Frame")
logoIcon.Size = UDim2.new(0, 28, 0, 28)
logoIcon.Position = UDim2.new(0, 16, 0.5, -14)
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
logoText.TextSize = 16
logoText.ZIndex = 23
logoText.Parent = logoIcon

local hubTitle = Instance.new("TextLabel")
hubTitle.Size = UDim2.new(0, 200, 1, 0)
hubTitle.Position = UDim2.new(0, 52, 0, 0)
hubTitle.BackgroundTransparency = 1
hubTitle.Text = "_hub"
hubTitle.TextColor3 = Theme.TextActive
hubTitle.Font = Theme.FontHeader
hubTitle.TextSize = 16
hubTitle.TextXAlignment = Enum.TextXAlignment.Left
hubTitle.ZIndex = 22
hubTitle.Parent = header

-- ═══════════════════════════════════════════════════════════════
-- SEARCH BAR
-- ═══════════════════════════════════════════════════════════════

local searchBar = Instance.new("Frame")
searchBar.Name = "SearchBar"
searchBar.Size = UDim2.new(0, isMobile and 130 or 200, 0, 32)
searchBar.Position = UDim2.new(1, -(isMobile and 190 or 280), 0.5, -16)
searchBar.BackgroundColor3 = Theme.Card
searchBar.BorderSizePixel = 0
searchBar.ZIndex = 22
searchBar.Parent = header

stroke(searchBar, Theme.Border, 1)

local searchInput = Instance.new("TextBox")
searchInput.Name = "SearchInput"
searchInput.Size = UDim2.new(1, -36, 1, 0)
searchInput.Position = UDim2.new(0, 32, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.Text = "Search"
searchInput.TextColor3 = Theme.TextMuted
searchInput.Font = Theme.FontLight
searchInput.TextSize = 13
searchInput.ClearTextOnFocus = true
searchInput.ZIndex = 23
searchInput.Parent = searchBar

-- ═══════════════════════════════════════════════════════════════
-- SEARCH SUGGESTIONS
-- ═══════════════════════════════════════════════════════════════

local searchSuggestions = Instance.new("Frame")
searchSuggestions.Name = "SearchSuggestions"
searchSuggestions.Size = UDim2.new(0, isMobile and 130 or 200, 0, 0)
searchSuggestions.Position = UDim2.new(1, -(isMobile and 190 or 280), 0, HEADER_H + 4)
searchSuggestions.BackgroundColor3 = Theme.Card
searchSuggestions.BorderSizePixel = 0
searchSuggestions.ClipsDescendants = true
searchSuggestions.Visible = false
searchSuggestions.ZIndex = 600
searchSuggestions.Parent = header

stroke(searchSuggestions, Theme.Border, 1)

-- ═══════════════════════════════════════════════════════════════
-- SIDEBAR
-- ═══════════════════════════════════════════════════════════════

local sidebar = Instance.new("ScrollingFrame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -(HEADER_H + FOOTER_H))
sidebar.Position = UDim2.new(0, 0, 0, HEADER_H)
sidebar.BackgroundColor3 = Theme.Sidebar
sidebar.BorderSizePixel = 0
sidebar.ScrollBarThickness = 3
sidebar.ScrollBarImageColor3 = Theme.Border
sidebar.CanvasSize = UDim2.new(0, 0, 0, 600)
sidebar.ZIndex = 20
sidebar.Parent = mainFrame

local sidebarRightBorder = Instance.new("Frame")
sidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
sidebarRightBorder.Position = UDim2.new(1, -1, 0, 0)
sidebarRightBorder.BackgroundColor3 = Theme.Border
sidebarRightBorder.BorderSizePixel = 0
sidebarRightBorder.ZIndex = 21
sidebarRightBorder.Parent = sidebar

-- ═══════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ═══════════════════════════════════════════════════════════════

local contentArea = Instance.new("Frame")
contentArea.Name = "Content"
contentArea.Size = UDim2.new(1, -SIDEBAR_W, 1, -(HEADER_H + FOOTER_H))
contentArea.Position = UDim2.new(0, SIDEBAR_W, 0, HEADER_H)
contentArea.BackgroundColor3 = Theme.Background
contentArea.BorderSizePixel = 0
contentArea.ZIndex = 20
contentArea.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════
-- COMPONENT BUILDERS
-- ═══════════════════════════════════════════════════════════════

-- ─── SECTION TITLE BOX ───
local function createSection(parent, title, icon, posY, width)
	local container = Instance.new("Frame")
	container.Name = "Section_" .. title
	container.Size = UDim2.new(0, width or 340, 0, 36)
	container.Position = UDim2.new(0, 0, 0, posY or 0)
	container.BackgroundColor3 = Theme.SectionBg
	container.BorderSizePixel = 0
	container.ZIndex = 30
	container.Parent = parent

	stroke(container, Theme.Border, 1)

	if icon and icon ~= "" then
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 24, 1, 0)
		iconLabel.Position = UDim2.new(0, 10, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon
		iconLabel.TextSize = 14
		iconLabel.ZIndex = 31
		iconLabel.Parent = container
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -16, 1, 0)
	titleLabel.Position = UDim2.new(0, icon and 36 or 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Theme.TextActive
	titleLabel.Font = Theme.FontMain
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 31
	titleLabel.Parent = container

	return container
end

-- ─── DROPDOWN ───
-- KEY CHANGES:
-- 1. Dropdown positioned FLUSH against the bottom of the button (0 gap)
-- 2. Internal ScrollingFrame so dropdown can scroll its own items
-- 3. Mouse wheel capture - scroll inside dropdown doesn't affect parent page
-- 4. Max height cap so dropdown never gets too tall
local function createDropdown(parent, title, icon, posY, width, items, onSelect)
	local myWidth = width or 300
	local itemHeight = 34
	local maxVisibleItems = 6  -- Show max 6 items before scrolling
	local maxDropdownHeight = maxVisibleItems * itemHeight + 8  -- Cap height

	-- Container (holds the button, sits on the page)
	local container = Instance.new("Frame")
	container.Name = "Dropdown_" .. title
	container.Size = UDim2.new(0, myWidth, 0, 36)
	container.Position = UDim2.new(0, 0, 0, posY or 0)
	container.BackgroundTransparency = 1
	container.ZIndex = 30
	container.Parent = parent

	-- Header button
	local headerBtn = Instance.new("TextButton")
	headerBtn.Name = "Header"
	headerBtn.Size = UDim2.new(1, 0, 0, 36)
	headerBtn.BackgroundColor3 = Theme.Card
	headerBtn.BorderSizePixel = 0
	headerBtn.Text = ""
	headerBtn.AutoButtonColor = false
	headerBtn.ZIndex = 31
	headerBtn.Parent = container

	stroke(headerBtn, Theme.Border, 1)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 24, 1, 0)
	iconLabel.Position = UDim2.new(0, 10, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon or ""
	iconLabel.TextSize = 14
	iconLabel.ZIndex = 32
	iconLabel.Parent = headerBtn

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 36, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Dropdown"
	titleLabel.TextColor3 = Theme.TextActive
	titleLabel.Font = Theme.FontMain
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 32
	titleLabel.Parent = headerBtn

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -24, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "v"
	arrow.TextColor3 = Theme.TextMuted
	arrow.TextSize = 12
	arrow.ZIndex = 32
	arrow.Parent = headerBtn

	-- ═══════════════════════════════════════════════════════════
	-- DROPDOWN MENU - With internal scrolling
	-- ═══════════════════════════════════════════════════════════

	-- Outer menu frame (positioned flush against button)
	local menu = Instance.new("Frame")
	menu.Name = "DropdownMenu_" .. title
	menu.Size = UDim2.new(0, myWidth, 0, 0)
	menu.Position = UDim2.new(0, 0, 0, 0)  -- Set dynamically
	menu.BackgroundColor3 = Theme.Card
	menu.BorderSizePixel = 0
	menu.ClipsDescendants = true
	menu.Visible = false
	menu.ZIndex = 550
	menu.Parent = dropdownOverlay

	stroke(menu, Theme.Border, 1)

	-- INTERNAL SCROLLING FRAME - This is the key addition
	-- Items go inside here, not directly on the menu
	local menuScroller = Instance.new("ScrollingFrame")
	menuScroller.Name = "Scroller"
	menuScroller.Size = UDim2.new(1, 0, 1, 0)  -- Fills the menu
	menuScroller.Position = UDim2.new(0, 0, 0, 0)
	menuScroller.BackgroundTransparency = 1
	menuScroller.BorderSizePixel = 0
	menuScroller.ScrollBarThickness = 3
	menuScroller.ScrollBarImageColor3 = Theme.BorderLight
	menuScroller.CanvasSize = UDim2.new(0, 0, 0, #items * itemHeight + 8)
	menuScroller.ZIndex = 551
	menuScroller.Parent = menu

	-- State
	local isOpen = false
	local selectedItem = nil
	local trackConnection = nil
	local myTrackerEntry = nil

	-- Position the menu exactly at the bottom edge of the button (0 gap)
	local function syncPosition()
		if not isOpen then return end
		local btnAbs = headerBtn.AbsolutePosition
		local mainAbs = mainFrame.AbsolutePosition
		local btnSize = headerBtn.AbsoluteSize
		-- Position menu's TOP edge exactly at button's BOTTOM edge (flush, 0 gap)
		menu.Position = UDim2.new(
			0, btnAbs.X - mainAbs.X,
			0, btnAbs.Y - mainAbs.Y + btnSize.Y
		)
	end

	-- CLOSE
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
			if not isOpen then
				menu.Visible = false
			end
		end)
		tween(arrow, {Rotation = 0}, 0.2)
	end

	-- OPEN
	local function doOpen()
		if isOpen then return end
		closeAllDropdowns()
		isOpen = true

		syncPosition()
		menu.Visible = true

		-- Calculate target height: cap at maxDropdownHeight
		local totalItemsHeight = #items * itemHeight + 8
		local targetHeight = math.min(totalItemsHeight, maxDropdownHeight)

		tween(menu, {Size = UDim2.new(0, myWidth, 0, targetHeight)}, 0.2)
		tween(arrow, {Rotation = 180}, 0.2)

		trackConnection = RunService.RenderStepped:Connect(syncPosition)

		myTrackerEntry = {close = doClose}
		table.insert(activeDropdowns, myTrackerEntry)
	end

	-- TOGGLE
	local function toggleMenu()
		if isOpen then
			doClose()
		else
			doOpen()
		end
	end

	-- ═══════════════════════════════════════════════════════════
	-- BUILD MENU ITEMS (inside the ScrollingFrame)
	-- ═══════════════════════════════════════════════════════════

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
		itemBtn.Parent = menuScroller  -- PARENT TO SCROLLER, not menu

		local itemText = Instance.new("TextLabel")
		itemText.Size = UDim2.new(1, -16, 1, 0)
		itemText.Position = UDim2.new(0, 8, 0, 0)
		itemText.BackgroundTransparency = 1
		if type(itemData) == "string" then
			itemText.Text = itemData
		elseif type(itemData) == "table" then
			itemText.Text = itemData.text or tostring(itemData)
		else
			itemText.Text = tostring(itemData)
		end
		itemText.TextColor3 = Theme.TextMuted
		itemText.Font = Theme.FontMain
		itemText.TextSize = 12
		itemText.TextXAlignment = Enum.TextXAlignment.Left
		itemText.ZIndex = 553
		itemText.Parent = itemBtn

		-- Hover
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

		-- Click item
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

	-- ═══════════════════════════════════════════════════════════
	-- SCROLL CAPTURE - Prevent scroll from affecting parent page
	-- ═══════════════════════════════════════════════════════════
	-- When mouse is over the dropdown menu and user scrolls,
	-- capture the input so it only scrolls the dropdown's scroller
	-- and doesn't scroll the parent ScrollingFrame behind it.
	-- ═══════════════════════════════════════════════════════════

	local scrollConnection = nil

	local function startScrollCapture()
		-- Disconnect any existing connection first
		if scrollConnection then
			scrollConnection:Disconnect()
			scrollConnection = nil
		end

		-- Capture mouse wheel input while dropdown is open
		scrollConnection = UIS.InputChanged:Connect(function(input, gameProcessed)
			if not isOpen then return end
			-- Only handle mouse wheel
			if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end

			-- Check if mouse is over the dropdown menu
			local mousePos = UIS:GetMouseLocation()
			local menuPos = menu.AbsolutePosition
			local menuSize = menu.AbsoluteSize

			local overMenu = mousePos.X >= menuPos.X
				and mousePos.X <= menuPos.X + menuSize.X
				and mousePos.Y >= menuPos.Y
				and mousePos.Y <= menuPos.Y + menuSize.Y

			if overMenu then
				-- Manually scroll the dropdown's scroller
				local scrollAmount = -input.Position.Z * 30  -- 30 pixels per wheel tick
				local newPos = menuScroller.CanvasPosition.Y + scrollAmount
				newPos = math.clamp(newPos, 0,
					math.max(0, menuScroller.CanvasSize.Y.Offset - menuScroller.AbsoluteSize.Y))
				menuScroller.CanvasPosition = Vector2.new(0, newPos)
			end
		end)
	end

	-- Click header to toggle
	headerBtn.MouseButton1Click:Connect(toggleMenu)

	-- Click outside to close
	dropdownOverlay.InputBegan:Connect(function(input)
		if not isOpen then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = input.Position
			local menuPos = menu.AbsolutePosition
			local menuSize = menu.AbsoluteSize
			if mousePos.X < menuPos.X
				or mousePos.X > menuPos.X + menuSize.X
				or mousePos.Y < menuPos.Y
				or mousePos.Y > menuPos.Y + menuSize.Y then
				local btnPos = headerBtn.AbsolutePosition
				local btnSize = headerBtn.AbsoluteSize
				local onBtn = mousePos.X >= btnPos.X
					and mousePos.X <= btnPos.X + btnSize.X
					and mousePos.Y >= btnPos.Y
					and mousePos.Y <= btnPos.Y + btnSize.Y
				if not onBtn then
					doClose()
				end
			end
		end
	end)

	-- Cleanup scroll connection when dropdown closes
	-- We hook into doClose via a wrapper
	local originalDoClose = doClose
	-- (doClose is local, can't reassign - but the scrollConnection checks isOpen)

	-- Periodically clean up disconnected scroll connection
	task.spawn(function()
		while menu and menu.Parent do
			task.wait(1)
			if not isOpen and scrollConnection then
				scrollConnection:Disconnect()
				scrollConnection = nil
			end
		end
	end)

	-- Start the scroll capture system
	startScrollCapture()

	return {
		container = container,
		header = headerBtn,
		menu = menu,
		setSelected = function(text)
			titleLabel.Text = text
		end
	}
end

-- ─── TOGGLE ───
local function createToggle(parent, label, posY, width, onChange)
	local container = Instance.new("Frame")
	container.Name = "Toggle_" .. (label or "Toggle")
	container.Size = UDim2.new(0, width or 300, 0, 40)
	container.Position = UDim2.new(0, 0, 0, posY or 0)
	container.BackgroundColor3 = Theme.Card
	container.BorderSizePixel = 0
	container.ZIndex = 30
	container.Parent = parent

	stroke(container, Theme.Border, 1)

	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(1, -70, 1, 0)
	labelText.Position = UDim2.new(0, 14, 0, 0)
	labelText.BackgroundTransparency = 1
	labelText.Text = label or "Toggle"
	labelText.TextColor3 = Theme.TextActive
	labelText.Font = Theme.FontMain
	labelText.TextSize = 13
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.ZIndex = 31
	labelText.Parent = container

	local switchBg = Instance.new("TextButton")
	switchBg.Name = "SwitchBg"
	switchBg.Size = UDim2.new(0, 44, 0, 24)
	switchBg.Position = UDim2.new(1, -56, 0.5, -12)
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
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.Position = UDim2.new(0, 3, 0.5, -9)
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
			tween(knob, {Position = UDim2.new(0, 23, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255,255,255)}, 0.2)
		else
			tween(switchBg, {BackgroundColor3 = Theme.ButtonNormal}, 0.2)
			tween(knob, {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(200,200,200)}, 0.2)
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
		setValue = function(v)
			enabled = v
			update()
		end
	}
end

-- ─── BUTTON ───
local function createButton(parent, text, posY, width, color, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = "Button_" .. (text or "Btn")
	btn.Size = UDim2.new(0, width or 300, 0, 34)
	btn.Position = UDim2.new(0, 0, 0, posY or 0)
	btn.BackgroundColor3 = color or Theme.ButtonNormal
	btn.BorderSizePixel = 0
	btn.Text = text or "Button"
	btn.TextColor3 = Theme.TextActive
	btn.Font = Theme.FontMain
	btn.TextSize = 12
	btn.AutoButtonColor = false
	btn.ZIndex = 30
	btn.Parent = parent

	stroke(btn, Theme.Border, 1)

	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = Theme.CardHover}, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = color or Theme.ButtonNormal}, 0.15)
	end)

	btn.MouseButton1Click:Connect(function()
		if onClick then onClick() end
	end)

	return btn
end

-- ─── SLIDER ───
local function createSlider(parent, label, posY, width, min, max, default, onChange)
	local container = Instance.new("Frame")
	container.Name = "Slider_" .. (label or "Slider")
	container.Size = UDim2.new(0, width or 300, 0, 50)
	container.Position = UDim2.new(0, 0, 0, posY or 0)
	container.BackgroundColor3 = Theme.Card
	container.BorderSizePixel = 0
	container.ZIndex = 30
	container.Parent = parent

	stroke(container, Theme.Border, 1)

	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(1, -70, 0, 20)
	labelText.Position = UDim2.new(0, 12, 0, 6)
	labelText.BackgroundTransparency = 1
	labelText.Text = label or "Slider"
	labelText.TextColor3 = Theme.TextActive
	labelText.Font = Theme.FontMain
	labelText.TextSize = 12
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.ZIndex = 31
	labelText.Parent = container

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0, 50, 0, 20)
	valueLabel.Position = UDim2.new(1, -58, 0, 6)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default or min or 0)
	valueLabel.TextColor3 = Theme.Accent
	valueLabel.Font = Theme.FontMain
	valueLabel.TextSize = 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 31
	valueLabel.Parent = container

	local sliderBg = Instance.new("Frame")
	sliderBg.Name = "Track"
	sliderBg.Size = UDim2.new(1, -24, 0, 6)
	sliderBg.Position = UDim2.new(0, 12, 0, 32)
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

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(0.5, -7, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 33
	knob.Parent = sliderBg

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local hitArea = Instance.new("TextButton")
	hitArea.Name = "HitArea"
	hitArea.Size = UDim2.new(1, 20, 1, 20)
	hitArea.Position = UDim2.new(0, -10, 0, -10)
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
		knob.Position = UDim2.new(pos, -7, 0.5, -7)
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
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			) then
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
			knob.Position = UDim2.new(pos, -7, 0.5, -7)
			valueLabel.Text = tostring(currentVal)
		end
	}
end

-- ─── INPUT ───
local function createInput(parent, placeholder, posY, width, onSubmit)
	local container = Instance.new("Frame")
	container.Name = "Input_" .. (placeholder or "Input")
	container.Size = UDim2.new(0, width or 300, 0, 36)
	container.Position = UDim2.new(0, 0, 0, posY or 0)
	container.BackgroundColor3 = Theme.Card
	container.BorderSizePixel = 0
	container.ZIndex = 30
	container.Parent = parent

	stroke(container, Theme.Border, 1)

	local input = Instance.new("TextBox")
	input.Name = "TextBox"
	input.Size = UDim2.new(1, -20, 1, 0)
	input.Position = UDim2.new(0, 10, 0, 0)
	input.BackgroundTransparency = 1
	input.Text = ""
	input.PlaceholderText = placeholder or "Enter text..."
	input.TextColor3 = Theme.TextActive
	input.PlaceholderColor3 = Theme.TextDark
	input.Font = Theme.FontMain
	input.TextSize = 12
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
local function createCard(parent, title, icon, posY, width, height)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. (title or "Card")
	card.Size = UDim2.new(0, width or 300, 0, height or 100)
	card.Position = UDim2.new(0, 0, 0, posY or 0)
	card.BackgroundColor3 = Theme.Card
	card.BorderSizePixel = 0
	card.ZIndex = 30
	card.Parent = parent

	stroke(card, Theme.Border, 1)

	local cardHeader = Instance.new("Frame")
	cardHeader.Name = "Header"
	cardHeader.Size = UDim2.new(1, 0, 0, 36)
	cardHeader.BackgroundTransparency = 1
	cardHeader.ZIndex = 31
	cardHeader.Parent = card

	if icon then
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(0, 24, 1, 0)
		iconLabel.Position = UDim2.new(0, 10, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon
		iconLabel.TextSize = 14
		iconLabel.ZIndex = 32
		iconLabel.Parent = cardHeader
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, icon and 36 or 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Card"
	titleLabel.TextColor3 = Theme.TextActive
	titleLabel.Font = Theme.FontMain
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 32
	titleLabel.Parent = cardHeader

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -44)
	content.Position = UDim2.new(0, 10, 0, 38)
	content.BackgroundTransparency = 1
	content.ZIndex = 31
	content.Parent = card

	return {
		card = card,
		header = cardHeader,
		content = content,
		setTitle = function(t) titleLabel.Text = t end
	}
end

-- ─── LABEL ───
local function createLabel(parent, text, posY, color, size)
	local label = Instance.new("TextLabel")
	label.Name = "Label_" .. (text or "Label")
	label.Size = UDim2.new(1, -20, 0, size or 20)
	label.Position = UDim2.new(0, 10, 0, posY or 0)
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextColor3 = color or Theme.TextMuted
	label.Font = Theme.FontMain
	label.TextSize = 12
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

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, -20, 1, -16)
	page.Position = UDim2.new(0, 10, 0, 8)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = Theme.BorderLight
	page.CanvasSize = UDim2.new(0, 0, 0, 800)
	page.ZIndex = 25
	page.Visible = false
	page.Parent = contentArea
	pages[name] = page
	return page
end

local function switchPage(pageName)
	closeAllDropdowns()
	for name, page in pairs(pages) do
		page.Visible = (name == pageName)
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

local sidebarButtons = {}
local selectedSidebarBtn = nil

local function createSidebarItem(data, index)
	local btn = Instance.new("TextButton")
	btn.Name = data.name
	btn.Size = UDim2.new(1, -16, 0, isMobile and 32 or 28)
	btn.Position = UDim2.new(0, 8, 0, 8 + (index - 1) * (isMobile and 34 or 30))
	btn.BackgroundColor3 = data.name == "Account" and Theme.Card or Color3.fromRGB(0,0,0)
	btn.BackgroundTransparency = data.name == "Account" and 0 or 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.ZIndex = 22
	btn.Parent = sidebar

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 20, 1, 0)
	icon.Position = UDim2.new(0, 8, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = data.icon
	icon.TextSize = 14
	icon.ZIndex = 23
	icon.Parent = btn

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -36, 1, 0)
	label.Position = UDim2.new(0, 30, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = data.name
	label.TextColor3 = data.color
	label.Font = Theme.FontMain
	label.TextSize = isMobile and 11 or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 23
	label.Parent = btn

	btn.MouseEnter:Connect(function()
		if selectedSidebarBtn ~= btn then
			tween(btn, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Card}, 0.1)
		end
	end)

	btn.MouseLeave:Connect(function()
		if selectedSidebarBtn ~= btn then
			tween(btn, {BackgroundTransparency = 1}, 0.1)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		if selectedSidebarBtn then
			tween(selectedSidebarBtn, {BackgroundTransparency = 1}, 0.1)
			local prevLabel = selectedSidebarBtn:FindFirstChild("Label")
			if prevLabel then
				prevLabel.TextColor3 = Theme.TextMuted
			end
		end

		selectedSidebarBtn = btn
		tween(btn, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Card}, 0.1)
		label.TextColor3 = data.color

		switchPage(data.name)
	end)

	sidebarButtons[data.name] = btn
	return btn
end

for i, item in ipairs(sidebarItems) do
	createSidebarItem(item, i)
end

selectedSidebarBtn = sidebarButtons["Account"]

-- ═══════════════════════════════════════════════════════════════
-- SEARCH SUGGESTIONS
-- ═══════════════════════════════════════════════════════════════

local searchItemsList = {
	"Account", "Home", "Premium", "Hatching", "Eggs",
	"PetSell", "Plants", "Event", "PetManager", "Craft",
	"Fruit", "Shopping", "Selling", "Misc", "Settings",
	"Key Status", "Logout", "Join Discord", "Auto Farm",
	"Auto Hatch", "Auto Craft", "Anti-AFK", "Auto Rejoin"
}

local suggestionButtons = {}

for i, itemText in ipairs(searchItemsList) do
	local btn = Instance.new("TextButton")
	btn.Name = "Suggestion_" .. itemText
	btn.Size = UDim2.new(1, -16, 0, 28)
	btn.Position = UDim2.new(0, 8, 0, 4 + (i-1) * 30)
	btn.BackgroundColor3 = Theme.Card
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Visible = false
	btn.ZIndex = 601
	btn.Parent = searchSuggestions

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -10, 1, 0)
	lbl.Position = UDim2.new(0, 5, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = itemText
	lbl.TextColor3 = Theme.TextMuted
	lbl.Font = Theme.FontMain
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 602
	lbl.Parent = btn

	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = Theme.ButtonNormal}, 0.1)
		lbl.TextColor3 = Theme.TextActive
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = Theme.Card}, 0.1)
		lbl.TextColor3 = Theme.TextMuted
	end)

	btn.MouseButton1Click:Connect(function()
		for _, pageData in ipairs(sidebarItems) do
			if pageData.name:lower() == itemText:lower() then
				local sidebarBtn = sidebarButtons[pageData.name]
				if sidebarBtn then
					sidebarBtn.MouseButton1Click:Fire()
				end
				break
			end
		end
		searchInput.Text = ""
		searchInput.TextColor3 = Theme.TextMuted
		searchSuggestions.Visible = false
		for _, data in ipairs(suggestionButtons) do
			data.button.Visible = false
		end
	end)

	table.insert(suggestionButtons, {button = btn, text = itemText:lower()})
end

local function updateSuggestions(text)
	if text == "" or text == "Search" then
		searchSuggestions.Visible = false
		return
	end

	local lowerText = text:lower()
	local matchCount = 0

	for _, data in ipairs(suggestionButtons) do
		if data.text:find(lowerText, 1, true) then
			data.button.Visible = true
			matchCount = matchCount + 1
		else
			data.button.Visible = false
		end
	end

	if matchCount > 0 then
		searchSuggestions.Visible = true
		searchSuggestions.Size = UDim2.new(
			0, searchSuggestions.Size.X.Offset,
			0, math.min(matchCount * 30 + 8, 200)
		)
	else
		searchSuggestions.Visible = false
	end
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	local text = searchInput.Text
	if text == "Search" then return end
	updateSuggestions(text)
end)

searchInput.Focused:Connect(function()
	if searchInput.Text == "Search" then
		searchInput.Text = ""
		searchInput.TextColor3 = Theme.TextActive
	end
end)

searchInput.FocusLost:Connect(function()
	if searchInput.Text == "" then
		searchInput.Text = "Search"
		searchInput.TextColor3 = Theme.TextMuted
	end
	task.delay(0.15, function()
		searchSuggestions.Visible = false
		for _, data in ipairs(suggestionButtons) do
			data.button.Visible = false
		end
	end)
end)

-- ═══════════════════════════════════════════════════════════════
-- X CLOSE BUTTON
-- ═══════════════════════════════════════════════════════════════

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -44, 0.5, -16)
closeBtn.BackgroundColor3 = Theme.Card
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Theme.TextMuted
closeBtn.Font = Theme.FontHeader
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 22
closeBtn.Parent = header

stroke(closeBtn, Theme.Border, 1)

closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, {BackgroundColor3 = Theme.Danger, TextColor3 = Theme.TextActive}, 0.15)
end)
closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, {BackgroundColor3 = Theme.Card, TextColor3 = Theme.TextMuted}, 0.15)
end)
closeBtn.MouseButton1Click:Connect(function()
	safePrint("Hiding UI...")
	open = false
	closeAllDropdowns()
	tween(uiScale, {Scale = 0}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		.Completed:Connect(function()
			if not open then
				mainFrame.Visible = false
			end
		end)
end)

-- ═══════════════════════════════════════════════════════════════
-- ACCOUNT PAGE
-- ═══════════════════════════════════════════════════════════════

local accountPage = createPage("Account")

createSection(accountPage, "Account", "", 0, 340)
createLabel(accountPage, "Account settings and key management", 42, Theme.TextDark, 18)

local accountDropdown = createDropdown(accountPage, "Account", "", 68, 340, {
	{text = "Account Settings", value = "settings"},
	{text = "Profile", value = "profile"},
	{text = "Billing", value = "billing"},
	{text = "API Keys", value = "api"},
}, function(value)
	safePrint("Account option:", value)
end)

createSection(accountPage, "Key Status", nil, 118, 340)

local keyCard = createCard(accountPage, "", nil, 162, 340, 90)
createLabel(keyCard.content, "Key expires in 5 days 18 hours 2 min", 0, Theme.TextMuted, 20)

createButton(keyCard.content, "Join Discord", 28, 320, Theme.ButtonNormal, function()
	safePrint("Joining Discord...")
end)

createSection(accountPage, "Logout", nil, 268, 340)

local logoutCard = createCard(accountPage, "", nil, 312, 340, 70)

createButton(logoutCard.content, "Logout", 4, 320, Theme.Danger, function()
	safePrint("Logging out...")
end)

-- ═══════════════════════════════════════════════════════════════
-- HOME PAGE
-- ═══════════════════════════════════════════════════════════════

local homePage = createPage("Home")

createSection(homePage, "Dashboard", "", 0, 340)
createLabel(homePage, "Welcome to _hub. Use the sidebar to navigate through different features.", 42, Theme.TextMuted, 40)

local statsCard = createCard(homePage, "Statistics", "", 90, 340, 120)
createLabel(statsCard.content, "Scripts Executed: 1,247", 0, Theme.TextMuted, 22)
createLabel(statsCard.content, "Active Sessions: 3", 24, Theme.TextMuted, 22)
createLabel(statsCard.content, "Last Login: Just now", 48, Theme.TextMuted, 22)

-- ═══════════════════════════════════════════════════════════════
-- PREMIUM PAGE
-- ═══════════════════════════════════════════════════════════════

local premiumPage = createPage("Premium")

createSection(premiumPage, "Premium Features", "", 0, 340)

createDropdown(premiumPage, "Premium Plan", "", 42, 340, {
	{text = "Basic ($5/mo)", value = "basic"},
	{text = "Pro ($10/mo)", value = "pro"},
	{text = "Elite ($20/mo)", value = "elite"},
}, function(val)
	safePrint("Premium plan:", val)
end)

createSlider(premiumPage, "Farm Speed", 92, 340, 1, 10, 5, function(val)
	safePrint("Farm Speed:", val)
end)

createSlider(premiumPage, "Collection Range", 152, 340, 1, 50, 25, function(val)
	safePrint("Collection Range:", val)
end)

createToggle(premiumPage, "Auto Farm Premium", 212, 340, function(val)
	safePrint("Premium Auto Farm:", val)
end)

createToggle(premiumPage, "Priority Queue", 262, 340, function(val)
	safePrint("Priority Queue:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- HATCHING PAGE
-- ═══════════════════════════════════════════════════════════════

local hatchingPage = createPage("Hatching")

createSection(hatchingPage, "Hatching Teams", "", 0, 340)

createDropdown(hatchingPage, "Select Team", "", 42, 340, {
	{text = "Team Alpha", value = "alpha"},
	{text = "Team Beta", value = "beta"},
	{text = "Team Gamma", value = "gamma"},
}, function(val)
	safePrint("Selected team:", val)
end)

createSlider(hatchingPage, "Hatch Speed", 92, 340, 1, 100, 50, function(val)
	safePrint("Hatch Speed:", val)
end)

createToggle(hatchingPage, "Auto Hatch", 152, 340, function(val)
	safePrint("Auto Hatch:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- EGGS PAGE
-- ═══════════════════════════════════════════════════════════════

local eggsPage = createPage("Eggs")

createSection(eggsPage, "Eggs Priority", "", 0, 340)

createDropdown(eggsPage, "Egg Type", "", 42, 340, {
	{text = "Golden Egg", value = "golden"},
	{text = "Crystal Egg", value = "crystal"},
	{text = "Mystic Egg", value = "mystic"},
	{text = "Basic Egg", value = "basic"},
}, function(val)
	safePrint("Selected egg:", val)
end)

createSlider(eggsPage, "Buy Amount", 92, 340, 1, 100, 10, function(val)
	safePrint("Buy amount:", val)
end)

createToggle(eggsPage, "Auto Buy Eggs", 152, 340, function(val)
	safePrint("Auto Buy Eggs:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- PET SELL PAGE
-- ═══════════════════════════════════════════════════════════════

local petSellPage = createPage("PetSell")

createSection(petSellPage, "Pet Sell Settings", "", 0, 340)

createDropdown(petSellPage, "Sell Mode", "", 42, 340, {
	{text = "Sell All Below", value = "below"},
	{text = "Sell Duplicates", value = "duplicates"},
	{text = "Sell Selected", value = "selected"},
}, function(val)
	safePrint("Sell mode:", val)
end)

createSlider(petSellPage, "Minimum Rarity", 92, 340, 1, 5, 3, function(val)
	safePrint("Min rarity:", val)
end)

createToggle(petSellPage, "Auto Sell Common", 152, 340, function(val)
	safePrint("Auto Sell Common:", val)
end)

createToggle(petSellPage, "Auto Sell Uncommon", 202, 340, function(val)
	safePrint("Auto Sell Uncommon:", val)
end)

createToggle(petSellPage, "Auto Sell Rare", 252, 340, function(val)
	safePrint("Auto Sell Rare:", val)
end)

createInput(petSellPage, "Minimum sell price...", 307, 340, function(text)
	safePrint("Min sell price:", text)
end)

-- ═══════════════════════════════════════════════════════════════
-- PLANTS PAGE
-- ═══════════════════════════════════════════════════════════════

local plantsPage = createPage("Plants")

createSection(plantsPage, "Plants & Packs", "", 0, 340)

createDropdown(plantsPage, "Plant Type", "", 42, 340, {
	{text = "Sunflower", value = "sunflower"},
	{text = "Rose", value = "rose"},
	{text = "Cactus", value = "cactus"},
}, function(val)
	safePrint("Selected plant:", val)
end)

createSlider(plantsPage, "Growth Speed", 92, 340, 1, 10, 5, function(val)
	safePrint("Growth speed:", val)
end)

createToggle(plantsPage, "Auto Harvest", 152, 340, function(val)
	safePrint("Auto Harvest:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- EVENT PAGE
-- ═══════════════════════════════════════════════════════════════

local eventPage = createPage("Event")

createSection(eventPage, "Event & Mutation", "", 0, 340)

createDropdown(eventPage, "Current Event", "", 42, 340, {
	{text = "Summer Event 2026", value = "summer"},
	{text = "Winter Event", value = "winter"},
	{text = "Halloween Event", value = "halloween"},
}, function(val)
	safePrint("Selected event:", val)
end)

createSlider(eventPage, "Event Difficulty", 92, 340, 1, 10, 5, function(val)
	safePrint("Difficulty:", val)
end)

createToggle(eventPage, "Auto Event", 152, 340, function(val)
	safePrint("Auto Event:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- PET MANAGER PAGE
-- ═══════════════════════════════════════════════════════════════

local petManagerPage = createPage("PetManager")

createSection(petManagerPage, "Pet Manager", "", 0, 340)

createDropdown(petManagerPage, "Manage Pets", "", 42, 340, {
	{text = "Equip Best", value = "equip"},
	{text = "Unequip All", value = "unequip"},
	{text = "Delete Duplicates", value = "delete"},
}, function(val)
	safePrint("Pet action:", val)
end)

createSlider(petManagerPage, "Max Pets", 92, 340, 1, 50, 20, function(val)
	safePrint("Max pets:", val)
end)

createToggle(petManagerPage, "Auto Equip Best", 152, 340, function(val)
	safePrint("Auto Equip Best:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- CRAFT PAGE
-- ═══════════════════════════════════════════════════════════════

local craftPage = createPage("Craft")

createSection(craftPage, "Craft and Cook", "", 0, 340)

createDropdown(craftPage, "Recipe", "", 42, 340, {
	{text = "Health Potion", value = "health"},
	{text = "Speed Potion", value = "speed"},
	{text = "Strength Potion", value = "strength"},
}, function(val)
	safePrint("Selected recipe:", val)
end)

createSlider(craftPage, "Craft Amount", 92, 340, 1, 100, 10, function(val)
	safePrint("Craft amount:", val)
end)

createSlider(craftPage, "Quality Level", 152, 340, 1, 5, 3, function(val)
	safePrint("Quality:", val)
end)

createToggle(craftPage, "Auto Craft", 212, 340, function(val)
	safePrint("Auto Craft:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- FRUIT PAGE
-- ═══════════════════════════════════════════════════════════════

local fruitPage = createPage("Fruit")

createSection(fruitPage, "Fruit Collection", "", 0, 340)

createDropdown(fruitPage, "Fruit Type", "", 42, 340, {
	{text = "Apple", value = "apple"},
	{text = "Banana", value = "banana"},
	{text = "Orange", value = "orange"},
}, function(val)
	safePrint("Selected fruit:", val)
end)

createSlider(fruitPage, "Collection Radius", 92, 340, 1, 50, 25, function(val)
	safePrint("Radius:", val)
end)

createToggle(fruitPage, "Auto Collect", 152, 340, function(val)
	safePrint("Auto Collect Fruit:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- SHOPPING PAGE
-- ═══════════════════════════════════════════════════════════════

local shoppingPage = createPage("Shopping")

createSection(shoppingPage, "Shopping", "", 0, 340)

createDropdown(shoppingPage, "Shop Category", "", 42, 340, {
	{text = "Weapons", value = "weapons"},
	{text = "Armor", value = "armor"},
	{text = "Consumables", value = "consumables"},
}, function(val)
	safePrint("Shop category:", val)
end)

createSlider(shoppingPage, "Buy Limit", 92, 340, 1, 100, 10, function(val)
	safePrint("Buy limit:", val)
end)

createToggle(shoppingPage, "Auto Buy", 152, 340, function(val)
	safePrint("Auto Buy:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- SELLING PAGE
-- ═══════════════════════════════════════════════════════════════

local sellingPage = createPage("Selling")

createSection(sellingPage, "Selling", "", 0, 340)

createDropdown(sellingPage, "Sell Strategy", "", 42, 340, {
	{text = "Quick Sell", value = "quick"},
	{text = "Market Price", value = "market"},
	{text = "Hold for Value", value = "hold"},
}, function(val)
	safePrint("Sell strategy:", val)
end)

createSlider(sellingPage, "Sell Below Rarity", 92, 340, 1, 5, 3, function(val)
	safePrint("Sell below rarity:", val)
end)

createToggle(sellingPage, "Auto Sell", 152, 340, function(val)
	safePrint("Auto Sell:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- MISC PAGE
-- ═══════════════════════════════════════════════════════════════

local miscPage = createPage("Misc")

createSection(miscPage, "Misc Shops", "", 0, 340)

createDropdown(miscPage, "Shop", "", 42, 340, {
	{text = "General Store", value = "general"},
	{text = "Black Market", value = "blackmarket"},
	{text = "Premium Shop", value = "premium"},
}, function(val)
	safePrint("Misc shop:", val)
end)

createSlider(miscPage, "Refresh Interval", 92, 340, 1, 60, 30, function(val)
	safePrint("Refresh interval:", val)
end)

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS PAGE
-- ═══════════════════════════════════════════════════════════════

local settingsPage = createPage("Settings")

createSection(settingsPage, "Settings", "", 0, 340)

createDropdown(settingsPage, "Theme", "", 42, 340, {
	{text = "Dark", value = "dark"},
	{text = "Darker", value = "darker"},
	{text = "AMOLED", value = "amoled"},
}, function(val)
	safePrint("Theme:", val)
end)

createSlider(settingsPage, "UI Scale", 92, 340, 50, 150, 100, function(val)
	safePrint("UI Scale:", val .. "%")
end)

createSlider(settingsPage, "Transparency", 152, 340, 0, 100, 0, function(val)
	safePrint("Transparency:", val .. "%")
end)

createToggle(settingsPage, "Anti-AFK", 212, 340, function(val)
	safePrint("Anti-AFK:", val)
end)

createToggle(settingsPage, "Auto Rejoin", 262, 340, function(val)
	safePrint("Auto Rejoin:", val)
end)

createToggle(settingsPage, "Discord RPC", 312, 340, function(val)
	safePrint("Discord RPC:", val)
end)

createButton(settingsPage, "Reset All Settings", 372, 340, Theme.Danger, function()
	safePrint("Resetting all settings...")
end)

-- ═══════════════════════════════════════════════════════════════
-- SHOW ACCOUNT PAGE BY DEFAULT
-- ═══════════════════════════════════════════════════════════════

switchPage("Account")

-- ═══════════════════════════════════════════════════════════════
-- FOOTER
-- ═══════════════════════════════════════════════════════════════

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
footer.BackgroundColor3 = Theme.Sidebar
footer.BorderSizePixel = 0
footer.ZIndex = 20
footer.Parent = mainFrame

local footerBorder = Instance.new("Frame")
footerBorder.Name = "FooterBorder"
footerBorder.Size = UDim2.new(1, 0, 0, 1)
footerBorder.BackgroundColor3 = Theme.Border
footerBorder.BorderSizePixel = 0
footerBorder.ZIndex = 21
footerBorder.Parent = footer

local footerText = Instance.new("TextLabel")
footerText.Name = "Website"
footerText.Size = UDim2.new(1, -40, 1, 0)
footerText.Position = UDim2.new(0, 10, 0, 0)
footerText.BackgroundTransparency = 1
footerText.Text = "_hub.app/join"
footerText.TextColor3 = Theme.TextDark
footerText.Font = Theme.FontLight
footerText.TextSize = 11
footerText.TextXAlignment = Enum.TextXAlignment.Left
footerText.ZIndex = 22
footerText.Parent = footer

-- Resizer indicator
local resizerContainer = Instance.new("Frame")
resizerContainer.Name = "ResizerContainer"
resizerContainer.Size = UDim2.new(0, 40, 0, FOOTER_H)
resizerContainer.Position = UDim2.new(1, -40, 0, 0)
resizerContainer.BackgroundTransparency = 1
resizerContainer.ZIndex = 22
resizerContainer.Parent = footer

local line1 = Instance.new("Frame")
line1.Size = UDim2.new(0, 1, 0, 6)
line1.Position = UDim2.new(1, -8, 0.5, -3)
line1.BackgroundColor3 = Theme.TextDark
line1.BorderSizePixel = 0
line1.Rotation = -45
line1.ZIndex = 23
line1.Parent = resizerContainer

local line2 = Instance.new("Frame")
line2.Size = UDim2.new(0, 1, 0, 8)
line2.Position = UDim2.new(1, -12, 0.5, -4)
line2.BackgroundColor3 = Theme.TextDark
line2.BorderSizePixel = 0
line2.Rotation = -45
line2.ZIndex = 23
line2.Parent = resizerContainer

local line3 = Instance.new("Frame")
line3.Size = UDim2.new(0, 1, 0, 10)
line3.Position = UDim2.new(1, -16, 0.5, -5)
line3.BackgroundColor3 = Theme.TextDark
line3.BorderSizePixel = 0
line3.Rotation = -45
line3.ZIndex = 23
line3.Parent = resizerContainer

local resizeHandle = Instance.new("TextButton")
resizeHandle.Name = "ResizeHandle"
resizeHandle.Size = UDim2.new(0, 40, 0, FOOTER_H)
resizeHandle.Position = UDim2.new(1, -40, 0, 0)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = ""
resizeHandle.ZIndex = 24
resizeHandle.Parent = footer

if isMobile then
	resizerContainer.Visible = false
	resizeHandle.Visible = false
end

-- ═══════════════════════════════════════════════════════════════
-- WINDOW DRAGGING
-- ═══════════════════════════════════════════════════════════════

local dragging = false
local dragStart
local frameStart

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		frameStart = mainFrame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			frameStart.X.Scale,
			frameStart.X.Offset + delta.X,
			frameStart.Y.Scale,
			frameStart.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- WINDOW RESIZING
-- ═══════════════════════════════════════════════════════════════

local resizing = false
local resizeStartPos
local resizeStartSize

resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		resizeStartPos = input.Position
		resizeStartSize = Vector2.new(mainFrame.Size.X.Offset, mainFrame.Size.Y.Offset)
	end
end)

UIS.InputChanged:Connect(function(input)
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - resizeStartPos
		local newW = math.max(500, resizeStartSize.X + delta.X)
		local newH = math.max(350, resizeStartSize.Y + delta.Y)
		mainFrame.Size = UDim2.new(0, newW, 0, newH)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = false
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- LAUNCHER ICON
-- ═══════════════════════════════════════════════════════════════

local open = false

local launcher = Instance.new("TextButton")
launcher.Name = "Launcher"
launcher.Size = UDim2.new(0, isMobile and 52 or 44, 0, isMobile and 52 or 44)
launcher.Position = UDim2.new(0, 20, 0, 20)
launcher.BackgroundColor3 = Theme.Accent
launcher.BorderSizePixel = 0
launcher.Text = "L"
launcher.TextSize = isMobile and 22 or 18
launcher.Font = Theme.FontHeader
launcher.TextColor3 = Color3.fromRGB(255, 255, 255)
launcher.AutoButtonColor = false
launcher.ZIndex = 100
launcher.Parent = screenGui

local launcherCorner = Instance.new("UICorner")
launcherCorner.CornerRadius = UDim.new(1, 0)
launcherCorner.Parent = launcher

stroke(launcher, Theme.AccentHover, 2)

launcher.MouseEnter:Connect(function()
	tween(launcher, {
		BackgroundColor3 = Theme.AccentHover,
		Size = UDim2.new(0, isMobile and 56 or 48, 0, isMobile and 56 or 48)
	}, 0.2)
end)

launcher.MouseLeave:Connect(function()
	tween(launcher, {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, isMobile and 52 or 44, 0, isMobile and 52 or 44)
	}, 0.2)
end)

-- ═══════════════════════════════════════════════════════════════
-- LAUNCHER DRAGGING + TOGGLE
-- ═══════════════════════════════════════════════════════════════

local draggingIcon = false
local iconStart
local iconPos
local iconMoved = false

launcher.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		draggingIcon = true
		iconMoved = false
		iconStart = input.Position
		iconPos = launcher.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if draggingIcon and (
		input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
		local delta = input.Position - iconStart
		if delta.Magnitude > 15 then
			iconMoved = true
		end
		launcher.Position = UDim2.new(
			iconPos.X.Scale,
			iconPos.X.Offset + delta.X,
			iconPos.Y.Scale,
			iconPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		if draggingIcon then
			draggingIcon = false
			if iconMoved then return end

			if open then
				open = false
				closeAllDropdowns()
				tween(uiScale, {Scale = 0}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
					.Completed:Connect(function()
						if not open then mainFrame.Visible = false end
					end)
			else
				open = true
				uiScale.Scale = 0
				mainFrame.Position = UDim2.new(
					0,
					launcher.Position.X.Offset + launcher.AbsoluteSize.X + 20,
					0,
					launcher.Position.Y.Offset
				)
				mainFrame.Visible = true
				tween(uiScale, {Scale = isMobile and 1.05 or 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- KEYBOARD SHORTCUT
-- ═══════════════════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if open then
			open = false
			closeAllDropdowns()
			tween(uiScale, {Scale = 0}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
				.Completed:Connect(function()
					if not open then mainFrame.Visible = false end
				end)
		else
			open = true
			uiScale.Scale = 0
			mainFrame.Visible = true
			tween(uiScale, {Scale = isMobile and 1.05 or 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

print("")
print("╔══════════════════════════════════════════╗")
print("║         _hub v5.5 - LOADED               ║")
print("╠══════════════════════════════════════════╣")
print("║  Dropdown scroll | Flush pos | Capture   ║")
print("║  Platform: " .. (isMobile and "Mobile    " or "PC        ") .. "            ║")
print("║  Pages: 15 | Components: 8 types         ║")
print("╠══════════════════════════════════════════╣")
print("║  Open: Click purple 'L' or RightShift    ║")
print("║  Close: Click X button (reopenable)      ║")
print("╚══════════════════════════════════════════╝")
print("")