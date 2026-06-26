--[[
    HYPER_HUB : Modern UI Client Script (Luau)
    Refactored, Optimized, and Redesigned for Roblox
]]

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- THEME
--==================================================

local Theme = {
	Background = Color3.fromRGB(15, 15, 22),
	Sidebar = Color3.fromRGB(22, 22, 32),
	Header = Color3.fromRGB(10, 10, 15),
	Accent = Color3.fromRGB(99, 102, 241),
	AccentHover = Color3.fromRGB(129, 140, 248),
	Card = Color3.fromRGB(28, 28, 40),
	ButtonNormal = Color3.fromRGB(33, 33, 48),
	Border = Color3.fromRGB(45, 45, 65),
	TextActive = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(156, 163, 175),
	FontMain = Enum.Font.GothamMedium,
	FontHeader = Enum.Font.GothamBold,
}

--==================================================
-- SCREEN GUI
--==================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernUI_Hub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--==================================================
-- MAIN PANEL
--==================================================

local defaultSize = UDim2.new(0, 520, 0, 340)
local savedSize: UDim2 = defaultSize
local savedPosition: UDim2 = UDim2.new(0.5, -260, 0.5, -170)

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = defaultSize
frame.Position = savedPosition
frame.BackgroundColor3 = Theme.Background
frame.BorderSizePixel = 0
frame.Visible = false
frame.ClipsDescendants = true
frame.Parent = screenGui

-- UIScale to animate open/close without breaking layouts
local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = frame

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Theme.Border
frameStroke.Thickness = 1.5
frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
frameStroke.Parent = frame

--==================================================
-- TITLE BAR
--==================================================

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Theme.Header
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 10)
titleBarCorner.Parent = titleBar

-- Mask to keep top corners round only
local titleBarMask = Instance.new("Frame")
titleBarMask.Size = UDim2.new(1, 0, 0, 10)
titleBarMask.Position = UDim2.new(0, 0, 1, -10)
titleBarMask.BackgroundColor3 = Theme.Header
titleBarMask.BorderSizePixel = 0
titleBarMask.Parent = titleBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "HYPER_HUB"
title.TextColor3 = Theme.TextActive
title.TextSize = 16
title.Font = Theme.FontHeader
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

--==================================================
-- SIDEBAR
--==================================================

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 150, 1, -45)
sidebar.Position = UDim2.new(0, 0, 0, 45)
sidebar.BackgroundColor3 = Theme.Sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = frame

local sidebarDivider = Instance.new("Frame")
sidebarDivider.Size = UDim2.new(0, 1, 1, 0)
sidebarDivider.Position = UDim2.new(1, -1, 0, 0)
sidebarDivider.BackgroundColor3 = Theme.Border
sidebarDivider.BorderSizePixel = 0
sidebarDivider.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 8)
sidebarLayout.FillDirection = Enum.FillDirection.Vertical
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
-- Changed: enforce stable order by Name instead of LayoutOrder
sidebarLayout.SortOrder = Enum.SortOrder.Name
sidebarLayout.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 15)
sidebarPadding.Parent = sidebar

--==================================================
-- PAGE CONTAINER
--==================================================

local pageContainer = Instance.new("Frame")
pageContainer.Name = "PageContainer"
pageContainer.Size = UDim2.new(1, -150, 1, -45)
pageContainer.Position = UDim2.new(0, 150, 0, 45)
pageContainer.BackgroundTransparency = 1
pageContainer.Parent = frame

local function buildBasePage(name: string): Frame
	local page = Instance.new("Frame")
	page.Name = name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = pageContainer

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = page

	return page
end

local mainPage = buildBasePage("01_MainPage")
local automationPage = buildBasePage("02_AutomationPage")
local shopPage = buildBasePage("03_ShopPage")

--==================================================
-- PAGE CONTENT
--==================================================

-- Main Page
local mainTitle = Instance.new("TextLabel")
mainTitle.Name = "MainTitle"
mainTitle.Size = UDim2.new(1, 0, 0, 30)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = "Welcome Back, User"
mainTitle.TextColor3 = Theme.TextActive
mainTitle.Font = Theme.FontHeader
mainTitle.TextSize = 22
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.Parent = mainPage

local mainDesc = Instance.new("TextLabel")
mainDesc.Name = "MainDesc"
mainDesc.Size = UDim2.new(1, 0, 1, -40)
mainDesc.Position = UDim2.new(0, 0, 0, 40)
mainDesc.BackgroundTransparency = 1
mainDesc.Text = "Experience the newly designed, high-performance execution hub. Navigate through pages using the sidebar menu.\n\nAll widgets are designed to scale seamlessly with custom drag and resize support."
mainDesc.TextColor3 = Theme.TextMuted
mainDesc.Font = Theme.FontMain
mainDesc.TextSize = 14
mainDesc.TextWrapped = true
mainDesc.TextXAlignment = Enum.TextXAlignment.Left
mainDesc.TextYAlignment = Enum.TextYAlignment.Top
mainDesc.Parent = mainPage

-- Automation Page
local autoTitle = Instance.new("TextLabel")
autoTitle.Name = "AutoTitle"
autoTitle.Size = UDim2.new(1, 0, 0, 30)
autoTitle.BackgroundTransparency = 1
autoTitle.Text = "Automation Suite"
autoTitle.TextColor3 = Theme.TextActive
autoTitle.Font = Theme.FontHeader
autoTitle.TextSize = 22
autoTitle.TextXAlignment = Enum.TextXAlignment.Left
autoTitle.Parent = automationPage

local autoDesc = Instance.new("TextLabel")
autoDesc.Name = "AutoDesc"
autoDesc.Size = UDim2.new(1, 0, 1, -40)
autoDesc.Position = UDim2.new(0, 0, 0, 40)
autoDesc.BackgroundTransparency = 1
autoDesc.Text = "Automate complex gameplay tasks with optimized loops. Toggle scripts here to run concurrently without execution lag."
autoDesc.TextColor3 = Theme.TextMuted
autoDesc.Font = Theme.FontMain
autoDesc.TextSize = 14
autoDesc.TextWrapped = true
autoDesc.TextXAlignment = Enum.TextXAlignment.Left
autoDesc.TextYAlignment = Enum.TextYAlignment.Top
autoDesc.Parent = automationPage

--==================================================
-- SHOP NESTED UI
--==================================================

local shopCategoryFrame = Instance.new("Frame")
shopCategoryFrame.Name = "ShopCategories"
shopCategoryFrame.Size = UDim2.new(0, 100, 1, 0)
shopCategoryFrame.BackgroundColor3 = Theme.Sidebar
shopCategoryFrame.BorderSizePixel = 0
shopCategoryFrame.Parent = shopPage

local shopCategoryCorner = Instance.new("UICorner")
shopCategoryCorner.CornerRadius = UDim.new(0, 8)
shopCategoryCorner.Parent = shopCategoryFrame

local shopCategoryLayout = Instance.new("UIListLayout")
shopCategoryLayout.Padding = UDim.new(0, 6)
shopCategoryLayout.FillDirection = Enum.FillDirection.Vertical
shopCategoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
shopCategoryLayout.VerticalAlignment = Enum.VerticalAlignment.Top
-- Changed: order by Name
shopCategoryLayout.SortOrder = Enum.SortOrder.Name
shopCategoryLayout.Parent = shopCategoryFrame

local shopCategoryPadding = Instance.new("UIPadding")
shopCategoryPadding.PaddingTop = UDim.new(0, 8)
shopCategoryPadding.Parent = shopCategoryFrame

local shopContentFrame = Instance.new("Frame")
shopContentFrame.Name = "ShopContent"
shopContentFrame.Size = UDim2.new(1, -115, 1, 0)
shopContentFrame.Position = UDim2.new(0, 115, 0, 0)
shopContentFrame.BackgroundColor3 = Theme.Card
shopContentFrame.BorderSizePixel = 0
shopContentFrame.Parent = shopPage

local shopContentCorner = Instance.new("UICorner")
shopContentCorner.CornerRadius = UDim.new(0, 8)
shopContentCorner.Parent = shopContentFrame

local shopContentStroke = Instance.new("UIStroke")
shopContentStroke.Color = Theme.Border
shopContentStroke.Thickness = 1
shopContentStroke.Parent = shopContentFrame

local function createShopPage(text: string): Frame
	local page = Instance.new("Frame")
	page.Name = text:gsub("%s+", "") -- compact name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = shopContentFrame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.upper(text) .. "\n[Catalog Items Loading...]"
	label.TextColor3 = Theme.TextMuted
	label.Font = Theme.FontMain
	label.TextSize = 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = page

	return page
end

local seedsPage = createShopPage("Seeds Catalog")
local gearPage = createShopPage("Gear Upgrades")
local cratePage = createShopPage("Crates Storage")
seedsPage.Visible = true

--==================================================
-- NAVIGATION BUTTON BUILDER
--==================================================

local function buildNavigationButton(text: string, parent: Instance, btnSize: UDim2): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = text -- important: UIListLayout sorting by Name
	btn.Size = btnSize
	btn.BackgroundColor3 = Theme.ButtonNormal
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = text
	btn.TextColor3 = Theme.TextMuted
	btn.Font = Theme.FontMain
	btn.TextSize = 13
	btn.Parent = parent

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Theme.Border
	btnStroke.Thickness = 1
	btnStroke.Parent = btn

	-- Hover effects (only when not selected)
	btn.MouseEnter:Connect(function()
		if btn.TextColor3 ~= Theme.TextActive then
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(43, 43, 62),
				TextColor3 = Theme.TextActive,
			}):Play()
		end
	end)

	btn.MouseLeave:Connect(function()
		if btn.TextColor3 ~= Theme.TextActive then
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = Theme.ButtonNormal,
				TextColor3 = Theme.TextMuted,
			}):Play()
		end
	end)

	-- Store a reference to stroke for selection state updates
	btn:SetAttribute("IsSelected", false)
	btn:SetAttribute("StrokeSelectedColorR", Theme.Accent.R)
	btn:SetAttribute("StrokeSelectedColorG", Theme.Accent.G)
	btn:SetAttribute("StrokeSelectedColorB", Theme.Accent.B)

	-- Attach stroke to attribute for retrieval
	btn:SetAttribute("HasStroke", true)
	btnstroke_ref = btnStroke -- upvalue for selection funcs via closure if needed

	return btn
end

--==================================================
-- SIDEBAR MAIN NAV BUTTONS
--==================================================

local sidebarButtons: { [Frame]: { btn: TextButton, stroke: UIStroke } } = {}

local mainButton = buildNavigationButton("01_Main", sidebar, UDim2.new(0, 130, 0, 36))
local automationButton = buildNavigationButton("02_Automation", sidebar, UDim2.new(0, 130, 0, 36))
local shopButton = buildNavigationButton("03_Shop", sidebar, UDim2.new(0, 130, 0, 36))

-- Re-find strokes (since not returned separately)
local function getStroke(button: TextButton): UIStroke?
	for _, c in ipairs(button:GetChildren()) do
		if c:IsA("UIStroke") then
			return c
		end
	end
	return nil
end

sidebarButtons[mainPage] = { btn = mainButton, stroke = getStroke(mainButton) :: UIStroke }
sidebarButtons[automationPage] = { btn = automationButton, stroke = getStroke(automationButton) :: UIStroke }
sidebarButtons[shopPage] = { btn = shopButton, stroke = getStroke(shopButton) :: UIStroke }

local function setSidebarSelection(activePage: Frame)
	for page, data in pairs(sidebarButtons) do
		local selected = (page == activePage)
		local targetBtn = data.btn
		local stroke = data.stroke
		if selected then
			TweenService:Create(targetBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = Theme.Accent,
				TextColor3 = Theme.TextActive,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Accent }):Play()
			end
		else
			TweenService:Create(targetBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = Theme.ButtonNormal,
				TextColor3 = Theme.TextMuted,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Border }):Play()
			end
		end
	end
end

local function switchActivePage(activePage: Frame)
	for page in pairs(sidebarButtons) do
		page.Visible = (page == activePage)
	end
	setSidebarSelection(activePage)
end

switchActivePage(mainPage)

mainButton.MouseButton1Click:Connect(function() switchActivePage(mainPage) end)
automationButton.MouseButton1Click:Connect(function() switchActivePage(automationPage) end)
shopButton.MouseButton1Click:Connect(function() switchActivePage(shopPage) end)

--==================================================
-- SHOP CATEGORY BUTTONS
--==================================================

local shopButtons: { [Frame]: { btn: TextButton, stroke: UIStroke } } = {}

local seedsButton = buildNavigationButton("01_Seeds", shopCategoryFrame, UDim2.new(0, 88, 0, 36))
local gearButton = buildNavigationButton("02_Gear", shopCategoryFrame, UDim2.new(0, 88, 0, 36))
local crateButton = buildNavigationButton("03_Crates", shopCategoryFrame, UDim2.new(0, 88, 0, 36))

shopButtons[seedsPage] = { btn = seedsButton, stroke = getStroke(seedsButton) :: UIStroke }
shopButtons[gearPage] = { btn = gearButton, stroke = getStroke(gearButton) :: UIStroke }
shopButtons[cratePage] = { btn = crateButton, stroke = getStroke(crateButton) :: UIStroke }

local function setShopSelection(activeShop: Frame)
	for page, data in pairs(shopButtons) do
		local selected = (page == activeShop)
		local targetBtn = data.btn
		local stroke = data.stroke
		if selected then
			TweenService:Create(targetBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = Theme.Accent,
				TextColor3 = Theme.TextActive,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Accent }):Play()
			end
		else
			TweenService:Create(targetBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = Theme.ButtonNormal,
				TextColor3 = Theme.TextMuted,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.15), { Color = Theme.Border }):Play()
			end
		end
	end
end

local function switchShopPage(activeShop: Frame)
	for page in pairs(shopButtons) do
		page.Visible = (page == activeShop)
	end
	setShopSelection(activeShop)
end

switchShopPage(seedsPage)

seedsButton.MouseButton1Click:Connect(function() switchShopPage(seedsPage) end)
gearButton.MouseButton1Click:Connect(function() switchShopPage(gearPage) end)
crateButton.MouseButton1Click:Connect(function() switchShopPage(cratePage) end)

--==================================================
-- LAUNCH ICON
--==================================================

local open = false

local icon = Instance.new("ImageButton")
icon.Name = "LauncherIcon"
icon.Size = UDim2.new(0, 48, 0, 48)
icon.Position = UDim2.new(0, 20, 0, 20)
icon.BackgroundColor3 = Theme.Sidebar
icon.BorderSizePixel = 0
icon.AutoButtonColor = false
icon.ZIndex = 100
icon.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Theme.Accent
iconStroke.Thickness = 2
iconStroke.Parent = icon

local iconText = Instance.new("TextLabel")
iconText.Size = UDim2.new(1, 0, 1, 0)
iconText.BackgroundTransparency = 1
iconText.Text = "H"
iconText.TextSize = 20
iconText.Font = Theme.FontHeader
iconText.TextColor3 = Theme.TextActive
iconText.ZIndex = 101
iconText.Parent = icon

icon.MouseEnter:Connect(function()
	TweenService:Create(icon, TweenInfo.new(0.2), {
		BackgroundColor3 = Theme.Background,
		Size = UDim2.new(0, 52, 0, 52),
	}):Play()
end)

icon.MouseLeave:Connect(function()
	TweenService:Create(icon, TweenInfo.new(0.2), {
		BackgroundColor3 = Theme.Sidebar,
		Size = UDim2.new(0, 48, 0, 48),
	}):Play()
end)

--==================================================
-- RESIZE HANDLE
--==================================================

local resizeHandle = Instance.new("TextButton")
resizeHandle.Name = "ResizeHandle"
resizeHandle.Size = UDim2.new(0, 18, 0, 18)
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -4, 1, -4)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = "◢"
resizeHandle.TextSize = 12
resizeHandle.Font = Theme.FontHeader
resizeHandle.TextColor3 = Theme.TextMuted
resizeHandle.ZIndex = 200
resizeHandle.Parent = frame

local resizing = false
local resizeStart: Vector2? = nil
local resizeSize: UDim2? = nil

resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		resizeStart = input.Position
		resizeSize = frame.Size
	end
end)

UIS.InputChanged:Connect(function(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		if resizeStart and resizeSize then
			local delta = input.Position - resizeStart
			frame.Size = UDim2.new(
				0,
				math.max(380, resizeSize.X.Offset + delta.X),
				0,
				math.max(220, resizeSize.Y.Offset + delta.Y)
			)
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		resizing = false
		savedSize = frame.Size
		savedPosition = frame.Position
	end
end)

--==================================================
-- DRAG WINDOW (TITLE BAR)
--==================================================

local draggingFrame = false
local dragStart: Vector2? = nil
local frameStart: UDim2? = nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingFrame = true
		dragStart = input.Position
		frameStart = frame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if draggingFrame and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		if dragStart and frameStart then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				frameStart.X.Scale,
				frameStart.X.Offset + delta.X,
				frameStart.Y.Scale,
				frameStart.Y.Offset + delta.Y
			)
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if draggingFrame and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		draggingFrame = false
		savedPosition = frame.Position
	end
end)

--==================================================
-- DRAG LAUNCH ICON + TOGGLE
--==================================================

local draggingIcon = false
local iconStart: Vector2? = nil
local iconPosition: UDim2? = nil
local iconMoved = false

icon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingIcon = true
		iconMoved = false
		iconStart = input.Position
		iconPosition = icon.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if draggingIcon and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		if iconStart and iconPosition then
			local delta = input.Position - iconStart
			if delta.Magnitude > 15 then
				iconMoved = true
			end
			icon.Position = UDim2.new(
				iconPosition.X.Scale,
				iconPosition.X.Offset + delta.X,
				iconPosition.Y.Scale,
				iconPosition.Y.Offset + delta.Y
			)
		end
	end
end)

local function openHub()
	open = true

	-- If first open at default center, spawn near icon
	local defaultCenter = UDim2.new(0.5, -260, 0.5, -170)
	local spawnNearIcon = UDim2.new(
		0,
		icon.Position.X.Offset + icon.AbsoluteSize.X + 20,
		0,
		icon.Position.Y.Offset
	)
	if savedPosition == defaultCenter then
		savedPosition = spawnNearIcon
	end

	uiScale.Scale = 0
	frame.Size = savedSize
	frame.Position = savedPosition
	frame.Visible = true

	TweenService:Create(
		uiScale,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
end

local function closeHub()
	open = false
	local scaleDown = TweenService:Create(
		uiScale,
		TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		{ Scale = 0 }
	)
	scaleDown:Play()
	scaleDown.Completed:Connect(function()
		if not open then
			frame.Visible = false
		end
	end)
end

icon.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if draggingIcon then
			draggingIcon = false
			if iconMoved then
				return
			end
			if open then
				closeHub()
			else
				openHub()
			end
		end
	end
end)
