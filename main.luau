--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║           EXOTIC HUB PRO - v10.4 Dropdown Layer Fix                ║
    ║          Dropdown scrolls with card, renders in front              ║
    ╚══════════════════════════════════════════════════════════════════════╝

    📁 WHERE TO PUT YOUR AUTOMATION CODE:
    Search for these markers in the code:
    
    🔧 CONFIG SECTION   - Edit window size, sidebar width, etc.
    🎨 THEME SECTION    - Change colors here
    ⚙️ AUTO SCRIPT #1-4 - Insert your automation code there
    
    📝 HOW TO USE:
    1. Copy this entire script
    2. Paste into a LocalScript in StarterPlayerScripts or StarterGui
    3. Find the ⚙️ markers and replace with your scripts
]]

-- ═══════════════════════════════════════════════════════════════════════
-- SERVICES
-- We grab Roblox services once and store them in local variables.
-- This is faster than calling game:GetService() repeatedly.
-- ═══════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════════════════
-- PLAYER SETUP
-- We wait for the local player's PlayerGui folder so we can parent UI to it.
-- ═══════════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════════════
-- 🔧 CONFIG SECTION
-- Edit these values to change the window size, sidebar width, and text.
-- ═══════════════════════════════════════════════════════════════════════
local Config = {
    WindowWidth = 700,           -- How wide the UI window is (pixels)
    WindowHeight = 450,          -- How tall the UI window is (pixels)
    MinWindowWidth = 400,        -- Minimum width when resizing
    MinWindowHeight = 300,       -- Minimum height when resizing
    SidebarWidth = 160,          -- Width of the left sidebar (pixels)
    EnableSearch = true,         -- Turn search on/off
    ToggleButtonText = "Exotic", -- Text on the top-left toggle button
}

-- ═══════════════════════════════════════════════════════════════════════
-- 🎨 THEME SECTION
-- All colors used in the UI. Change these to reskin the hub.
-- ═══════════════════════════════════════════════════════════════════════
local Theme = {
    -- Main Backgrounds
    Background = Color3.fromRGB(22, 22, 26),
    Sidebar = Color3.fromRGB(28, 28, 32),
    Content = Color3.fromRGB(18, 18, 22),
    Card = Color3.fromRGB(35, 35, 40),
    CardHover = Color3.fromRGB(45, 45, 50),
    DropdownBg = Color3.fromRGB(32, 32, 38),
    
    -- Text Colors
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(160, 160, 160),
    TextMuted = Color3.fromRGB(100, 100, 100),
    
    -- Accent Colors
    Accent = Color3.fromRGB(147, 112, 219),
    AccentPink = Color3.fromRGB(255, 105, 180),
    AccentCyan = Color3.fromRGB(0, 255, 255),
    AccentGreen = Color3.fromRGB(50, 205, 50),
    AccentRed = Color3.fromRGB(255, 80, 80),
    AccentOrange = Color3.fromRGB(255, 165, 0),
    AccentYellow = Color3.fromRGB(255, 215, 0),
    
    -- UI Elements
    Border = Color3.fromRGB(50, 50, 55),
    ToggleBg = Color3.fromRGB(60, 60, 65),
    ToggleOn = Color3.fromRGB(147, 112, 219),
    ScrollBar = Color3.fromRGB(60, 60, 70),
}

-- ═══════════════════════════════════════════════════════════════════════
-- ZINDEX HIERARCHY
-- Strict ZIndex levels prevent UI layers from fighting each other.
-- Higher numbers always render in front and receive input first.
-- ═══════════════════════════════════════════════════════════════════════
local Z = {
    Base        = 1,   -- Main window background
    Toggle      = 10,  -- Top-left toggle button (outside main frame)
    MainUI      = 10,  -- Top bar, sidebar, content panels
    Card        = 20,  -- Feature cards inside content area
    Dropdown    = 100, -- Dropdown container (opens below cards)
    DropScroll  = 110, -- Scrolling area inside dropdown
    DropControl = 120, -- Buttons, toggles, labels inside dropdown
    Modal       = 200, -- Modal popup overlay (dark background)
    ModalFrame  = 210, -- Modal popup window
    ModalCtrl   = 220, -- Buttons inside modal
    Search      = 500, -- Search suggestion dropdown (in ScreenGui)
}

-- ═══════════════════════════════════════════════════════════════════════
-- ⚙️ YOUR AUTOMATION SCRIPTS SECTION
-- This is where you paste your actual game automation scripts.
-- Each script has Start/Stop/Toggle functions.
-- ═══════════════════════════════════════════════════════════════════════

-- Keep track of running scripts so we can stop them safely
local RunningScripts = {}

-- ═══════════════════════════════════════════════════════════════════════
-- ⚙️ AUTO SCRIPT #1: Auto Hatch Example
-- ═══════════════════════════════════════════════════════════════════════
local AutoHatchScript = {
    Name = "AutoHatch",
    IsRunning = false,
    
    Start = function(self)
        self.IsRunning = true
        print("🥚 Auto Hatch STARTED")
        
        -- ═══════════════════════════════════════
        -- INSERT YOUR AUTO HATCH CODE HERE
        -- ═══════════════════════════════════════
        
        while self.IsRunning do
            task.wait(0.1)
        end
    end,
    
    Stop = function(self)
        self.IsRunning = false
        print("🥚 Auto Hatch STOPPED")
    end,
    
    Toggle = function(self)
        if self.IsRunning then
            self:Stop()
        else
            task.spawn(function()
                self:Start()
            end)
        end
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- ⚙️ AUTO SCRIPT #2: Auto Farm Example
-- ═══════════════════════════════════════════════════════════════════════
local AutoFarmScript = {
    Name = "AutoFarm",
    IsRunning = false,
    
    Start = function(self)
        self.IsRunning = true
        print("🌾 Auto Farm STARTED")
        
        -- ═══════════════════════════════════════
        -- INSERT YOUR AUTO FARM CODE HERE
        -- ═══════════════════════════════════════
        
        while self.IsRunning do
            task.wait(0.1)
        end
    end,
    
    Stop = function(self)
        self.IsRunning = false
        print("🌾 Auto Farm STOPPED")
    end,
    
    Toggle = function(self)
        if self.IsRunning then
            self:Stop()
        else
            task.spawn(function()
                self:Start()
            end)
        end
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- ⚙️ AUTO SCRIPT #3: Auto Feed Pets
-- ═══════════════════════════════════════════════════════════════════════
local AutoFeedScript = {
    Name = "AutoFeed",
    IsRunning = false,
    
    Start = function(self)
        self.IsRunning = true
        print("🍼 Auto Feed STARTED")
        
        -- ═══════════════════════════════════════
        -- INSERT YOUR AUTO FEED CODE HERE
        -- ═══════════════════════════════════════
        
        while self.IsRunning do
            task.wait(0.1)
        end
    end,
    
    Stop = function(self)
        self.IsRunning = false
        print("🍼 Auto Feed STOPPED")
    end,
    
    Toggle = function(self)
        if self.IsRunning then
            self:Stop()
        else
            task.spawn(function()
                self:Start()
            end)
        end
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- ⚙️ AUTO SCRIPT #4: Auto Craft
-- ═══════════════════════════════════════════════════════════════════════
local AutoCraftScript = {
    Name = "AutoCraft",
    IsRunning = false,
    
    Start = function(self)
        self.IsRunning = true
        print("🔨 Auto Craft STARTED")
        
        -- ═══════════════════════════════════════
        -- INSERT YOUR AUTO CRAFT CODE HERE
        -- ═══════════════════════════════════════
        
        while self.IsRunning do
            task.wait(0.1)
        end
    end,
    
    Stop = function(self)
        self.IsRunning = false
        print("🔨 Auto Craft STOPPED")
    end,
    
    Toggle = function(self)
        if self.IsRunning then
            self:Stop()
        else
            task.spawn(function()
                self:Start()
            end)
        end
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- Reusable utilities that make building UI faster and cleaner.
-- ═══════════════════════════════════════════════════════════════════════

--[[
    Create is a factory that makes a new Roblox UI instance.
    Instead of writing 5 lines for every button, we write 1.
    Example: Create("TextButton", {Text = "Click", Size = UDim2.new(...)})
]]
local function Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    return instance
end

--[[
    Tween smoothly animates a property over time.
    We use Quad Easing with Out direction for a natural feel.
]]
local function Tween(instance, properties, duration)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

--[[
    AddCorner gives a frame rounded corners.
    radius = corner radius in pixels.
]]
local function AddCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = instance
end

--[[
    AddStroke draws a border outline around a frame.
]]
local function AddStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = instance
end

--[[
    AddButtonEffects adds visual feedback to a button.
    - PC: hover brightens the button
    - Mobile / PC: press darkens briefly on click/touch
    This makes the UI feel responsive on all devices.
]]
local function AddButtonEffects(btn, normalColor, hoverColor)
    normalColor = normalColor or btn.BackgroundColor3
    hoverColor = hoverColor or Theme.CardHover
    
    -- Mouse hover (PC only)
    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = hoverColor}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = normalColor}, 0.15)
    end)
    
    -- Press effect (both PC and mobile)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
           or input.UserInputType == Enum.UserInputType.Touch then
            Tween(btn, {BackgroundColor3 = hoverColor}, 0.1)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
           or input.UserInputType == Enum.UserInputType.Touch then
            Tween(btn, {BackgroundColor3 = normalColor}, 0.1)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN UI CREATION
-- We build the ScreenGui and all permanent UI elements here.
-- ═══════════════════════════════════════════════════════════════════════

-- ScreenGui is the root container that holds everything.
local ScreenGui = Create("ScreenGui", {
    Name = "ExoticHubPro",
    Parent = playerGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- Toggle Button sits in the top-left corner of the screen.
-- It shows/hides the main window.
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
AddCorner(ToggleBtn, 4)
AddStroke(ToggleBtn, Theme.Border, 1)

-- Main Window Frame is the big central panel.
local MainFrame = Create("Frame", {
    Name = "MainFrame",
    Parent = ScreenGui,
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, -Config.WindowWidth / 2, 0.5, -Config.WindowHeight / 2),
    Size = UDim2.new(0, Config.WindowWidth, 0, Config.WindowHeight),
    ClipsDescendants = false,
    Active = true,
    ZIndex = Z.Base
})
AddCorner(MainFrame, 8)
AddStroke(MainFrame, Theme.Border, 2)

-- Toggle button click handler.
-- Uses Activated so it works on both PC and mobile.
ToggleBtn.Activated:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    Tween(ToggleBtn, {
        BackgroundColor3 = MainFrame.Visible 
            and Color3.fromRGB(15, 15, 15) 
            or Color3.fromRGB(30, 30, 30)
    }, 0.2)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- DRAGGING SYSTEM
-- Lets the user drag the window by pressing anywhere on the main frame.
-- Works with mouse and touch.
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

-- We listen on UserInputService so dragging continues even if the
-- cursor/touch leaves the window area.
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and isDragging then
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
-- Bottom-right corner handle that lets the user resize the window.
-- ═══════════════════════════════════════════════════════════════════════
local ResizeHandle = Create("Frame", {
    Name = "ResizeHandle",
    Parent = MainFrame,
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.new(0, 14, 0, 14),
    BackgroundTransparency = 0.4,
    ZIndex = Z.MainUI,
})
AddCorner(ResizeHandle, 3)

local ResizeBtn = Create("TextButton", {
    Name = "ResizeBtn",
    Parent = ResizeHandle,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Text = "",
    ZIndex = Z.MainUI + 1,
    Active = true,
    AutoButtonColor = false,
})

local isResizing = false

ResizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
       or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        local startSize = MainFrame.Size
        local startMousePos = input.Position
        
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not isResizing then
                connection:Disconnect()
                return
            end
            
            local currentMouse = UserInputService:GetMouseLocation()
            local delta = currentMouse - Vector2.new(startMousePos.X, startMousePos.Y)
            
            MainFrame.Size = UDim2.new(
                0, math.max(Config.MinWindowWidth, startSize.X.Offset + delta.X),
                0, math.max(Config.MinWindowHeight, startSize.Y.Offset + delta.Y)
            )
        end)
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isResizing = false
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- TOP BAR
-- Contains the title and the search box.
-- ═══════════════════════════════════════════════════════════════════════
local TopBar = Create("Frame", {
    Name = "TopBar",
    Parent = MainFrame,
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    ZIndex = Z.MainUI,
})

-- Title: "Exotic Hub PRO"
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

-- "PRO" suffix in pink
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

-- Search icon (magnifying glass)
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

-- Search text input
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

-- Search suggestions dropdown (parented to ScreenGui so it floats above everything)
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

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, {TextColor3 = Theme.AccentRed})
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, {TextColor3 = Theme.TextSecondary})
end)
CloseBtn.Activated:Connect(function()
    MainFrame.Visible = false
end)

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
-- Right panel where feature cards and dropdowns appear.
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

-- Page title
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

-- Page subtitle
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

-- Scrollable grid for cards
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
-- This invisible frame sits exactly on top of ContentScroll.
-- Dropdowns are created inside here instead of inside cards.
-- Benefits:
--   1. Dropdowns render at Z=100, above all cards (Z=20)
--   2. ClipsDescendants=true clips dropdowns when they scroll past edges
--   3. Same position/size as ContentScroll = identical clipping behavior
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
-- Used for multi-select menus (like picking a pet).
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
        if child:IsA("TextButton") then
            child:Destroy()
        end
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
-- These track what the UI is currently doing.
-- ═══════════════════════════════════════════════════════════════════════
local CurrentPage = "Home"           -- Which page is currently showing
local ActiveDropdownCard = nil       -- Which card opened the current dropdown
local ActiveDropdownFrame = nil      -- The dropdown frame instance
local IsClosingDropdown = false      -- Prevents double-closing animations
local DropdownDebounce = false       -- Prevents rapid-click spam
local SidebarButtons = {}            -- Stores all sidebar button functions
local SearchableItems = {}           -- Stores items that can be searched
local CardLayoutOrder = 0            -- Counter for consistent card ordering
local StickyHeartbeat = nil          -- Connection that keeps dropdown stuck to card

-- ═══════════════════════════════════════════════════════════════════════
-- STICKY DROPDOWN SYSTEM
-- Every frame, we recalculate the dropdown's position so it follows
-- its parent card when the user scrolls the content area.
-- ═══════════════════════════════════════════════════════════════════════

--[[
    UpdateDropdownPosition recalculates where the dropdown should be
    based on the card's current absolute position on screen.
    This runs every frame while a dropdown is open.
]]
local function UpdateDropdownPosition()
    if not ActiveDropdownFrame or not ActiveDropdownCard then
        return
    end
    -- If the card was destroyed (page switched), close the dropdown
    if not ActiveDropdownCard.Parent then
        CloseDropdown()
        return
    end
    
    -- Get absolute positions
    local cardAbs = ActiveDropdownCard.AbsolutePosition
    local layerAbs = DropdownLayer.AbsolutePosition
    
    -- Convert to coordinates relative to DropdownLayer
    local relX = cardAbs.X - layerAbs.X
    local relY = cardAbs.Y - layerAbs.Y + ActiveDropdownCard.AbsoluteSize.Y + 2
    
    -- Apply the new position
    ActiveDropdownFrame.Position = UDim2.new(0, relX, 0, relY)
end

--[[
    StartStickyDropdown begins the heartbeat loop that updates position.
    We use Heartbeat instead of CanvasPosition events because it also
    catches window resizing and other layout changes automatically.
]]
local function StartStickyDropdown()
    if StickyHeartbeat then
        StickyHeartbeat:Disconnect()
        StickyHeartbeat = nil
    end
    StickyHeartbeat = RunService.Heartbeat:Connect(UpdateDropdownPosition)
end

--[[
    StopStickyDropdown kills the heartbeat loop.
    Call this whenever the dropdown closes.
]]
local function StopStickyDropdown()
    if StickyHeartbeat then
        StickyHeartbeat:Disconnect()
        StickyHeartbeat = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- DROPDOWN SYSTEM
-- The dropdown is created inside DropdownLayer (a sibling of ContentScroll).
-- DropdownLayer has the same position/size as ContentScroll and clips
-- descendants, so the dropdown is clipped identically to how it would be
-- if it were inside ContentScroll. But because DropdownLayer is at
-- ZIndex 100, the dropdown renders IN FRONT of all cards.
-- ═══════════════════════════════════════════════════════════════════════

--[[
    CloseDropdown animates the current dropdown shut and cleans up.
    It is safe to call even if no dropdown is open.
]]
local function CloseDropdown()
    if IsClosingDropdown or not ActiveDropdownFrame then
        return
    end
    IsClosingDropdown = true
    DropdownDebounce = false  -- reset so user can open another immediately
    
    -- Stop the sticky follower so we don't waste CPU
    StopStickyDropdown()
    
    -- Restore the card's normal appearance
    if ActiveDropdownCard then
        local arrow = ActiveDropdownCard:FindFirstChild("Arrow")
        if arrow then
            arrow.Text = ">"
        end
        Tween(ActiveDropdownCard, {BackgroundColor3 = Theme.Card}, 0.15)
        ActiveDropdownCard = nil
    end
    
    -- Animate height to zero, then destroy
    local frame = ActiveDropdownFrame
    ActiveDropdownFrame = nil
    
    Tween(frame, {
        Size = UDim2.new(0, frame.Size.X.Offset, 0, 0)
    }, 0.15)
    
    task.wait(0.15)
    
    if frame and frame.Parent then
        frame:Destroy()
    end
    
    IsClosingDropdown = false
end

--[[
    ClearContent removes all cards from the content area.
    It also closes any open dropdown so we don't leave orphans.
]]
local function ClearContent()
    ContentScroll.CanvasPosition = Vector2.new(0, 0)
    CloseDropdown()
    for _, child in pairs(ContentScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
    CardLayoutOrder = 0
end

-- ═══════════════════════════════════════════════════════════════════════
-- UI ELEMENT BUILDERS
-- Reusable components for cards, toggles, buttons, and labels.
-- ═══════════════════════════════════════════════════════════════════════

--[[
    CreateCard builds a clickable row in the content grid.
    Each card shows an icon, title, and a right-arrow.
    Clicking a card opens its dropdown menu.
]]
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
    
    -- Icon on the left
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
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Z.Card + 1,
    })
    
    -- Right arrow indicator
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
    
    -- Hover effect (PC only). If this card has an active dropdown,
    -- we skip the hover so it stays highlighted.
    card.MouseEnter:Connect(function()
        if ActiveDropdownCard ~= card then
            Tween(card, {BackgroundColor3 = Theme.CardHover}, 0.15)
        end
    end)
    card.MouseLeave:Connect(function()
        if ActiveDropdownCard ~= card then
            Tween(card, {BackgroundColor3 = Theme.Card}, 0.15)
        end
    end)
    
    return card
end

--[[
    ToggleDropdown opens a dropdown menu below the given card.
    
    SAFETY RULES:
    1. If this card already has an open dropdown, CLOSE it.
       (Clicking the same card again toggles it off.)
    2. If another dropdown is open, close it first.
    3. Rapid clicks are ignored via debounce and IsClosingDropdown flags.
    
    The dropdown is parented to DropdownLayer (not the card).
    DropdownLayer sits at the same screen position as ContentScroll
    and has ClipsDescendants=true, so the dropdown is clipped when
    it scrolls past the visible area. Because DropdownLayer is at
    ZIndex 100, the dropdown renders IN FRONT of all cards.
]]
local function ToggleDropdown(card, buildContentFunction)
    -- Block while another dropdown is in the middle of closing
    if IsClosingDropdown then return end
    
    -- Rule 1: If this card already has an open dropdown, CLOSE it.
    if ActiveDropdownCard == card and ActiveDropdownFrame then
        CloseDropdown()
        return
    end
    
    -- Rule 2: Debounce prevents spam-clicking different cards
    if DropdownDebounce then return end
    DropdownDebounce = true
    
    -- Close any existing dropdown first
    CloseDropdown()
    
    -- Mark this card as the owner
    ActiveDropdownCard = card
    
    -- Highlight the card
    Tween(card, {BackgroundColor3 = Theme.CardHover}, 0.15)
    local arrow = card:FindFirstChild("Arrow")
    if arrow then
        arrow.Text = "v"
    end
    
    -- Calculate the card's position relative to DropdownLayer.
    -- DropdownLayer and ContentScroll have the same absolute position,
    -- so we just subtract DropdownLayer's absolute position from the card's.
    local cardAbs = card.AbsolutePosition
    local layerAbs = DropdownLayer.AbsolutePosition
    local relX = cardAbs.X - layerAbs.X
    local relY = cardAbs.Y - layerAbs.Y + card.AbsoluteSize.Y + 2
    
    -- Create the dropdown container inside DropdownLayer.
    -- DropdownLayer has ZIndex 100 and ClipsDescendants=true.
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
    
    -- Manual close button (X) in the top-right corner
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
    
    -- Hover effect for the close button
    closeDropBtn.MouseEnter:Connect(function()
        Tween(closeDropBtn, {TextColor3 = Theme.AccentRed}, 0.15)
    end)
    closeDropBtn.MouseLeave:Connect(function()
        Tween(closeDropBtn, {TextColor3 = Theme.TextSecondary}, 0.15)
    end)
    
    -- Scrolling area inside the dropdown
    local scroll = Create("ScrollingFrame", {
        Name = "Scroll",
        Parent = drop,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 26), -- leave room for close button
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
    
    -- Let the user build toggles, buttons, labels inside the scroll
    buildContentFunction(scroll)
    
    -- Wait one frame for UIListLayout to measure content height
    task.wait()
    
    local contentHeight = listLayout.AbsoluteContentSize.Y + 16
    local maxHeight = math.min(contentHeight, 260)
    local width = card.AbsoluteSize.X
    
    -- Set canvas size so scrolling works on mobile
    scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
    
    -- Store reference and animate open
    ActiveDropdownFrame = drop
    Tween(drop, {Size = UDim2.new(0, width, 0, maxHeight)}, 0.2)
    
    -- Start the sticky follower so the dropdown moves with the card
    StartStickyDropdown()
    
    -- Release debounce after animation finishes
    task.delay(0.25, function()
        DropdownDebounce = false
    end)
end

--[[
    CreateToggle builds an ON/OFF switch inside a dropdown.
    Uses Activated so it works on both PC and mobile.
    Returns the container and a function to read the current state.
]]
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
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Z.DropControl,
    })
    
    -- Toggle track (clickable background)
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
    
    -- Sliding knob (white circle)
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
    
    -- Activated handles both mouse and touch in one place
    toggleBg.Activated:Connect(function()
        state = not state
        
        Tween(toggleBg, {
            BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleBg
        }, 0.2)
        
        Tween(knob, {
            Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
        }, 0.2)
        
        if onToggleCallback then
            onToggleCallback(state)
        end
    end)
    
    return container, function() return state end
end

--[[
    CreateLabel adds a text line inside a dropdown.
]]
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

--[[
    CreateBtn makes a standard button for dropdowns or modals.
    Includes hover and press effects.
]]
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

--[[
    ShowModal opens a centered popup with a list of choices.
    When the user picks one, onSelectCallback runs.
]]
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
            if onSelectCallback then
                onSelectCallback(item)
            end
            -- Flash effect to confirm selection
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

--[[
    RegisterSearch adds an item to the search index.
    When the user types in the search box, matching items appear.
]]
local function RegisterSearch(name, pageName, icon, action)
    table.insert(SearchableItems, {
        Name = name,
        Page = pageName,
        Icon = icon,
        Action = action
    })
end

--[[
    UpdateSuggestions rebuilds the dropdown list under the search box
    based on what the user typed.
]]
local function UpdateSuggestions()
    -- Clear old suggestions
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
    
    -- Find matches
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
    
    -- Position below the search box
    local absPos = SearchFrame.AbsolutePosition
    local absSize = SearchFrame.AbsoluteSize
    SuggestFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
    SuggestFrame.Size = UDim2.new(0, absSize.X, 0, math.min(#matches * 32 + 10, 200))
    
    -- Build suggestion buttons
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

-- Search box events
SearchBox:GetPropertyChangedSignal("Text"):Connect(UpdateSuggestions)

SearchBox.FocusLost:Connect(function()
    if SearchBox.Text == "" then
        SearchBox.Text = "Search"
    end
    task.wait(0.2)
    SuggestFrame.Visible = false
end)

SearchBox.Focused:Connect(function()
    if SearchBox.Text ~= "Search" and SearchBox.Text ~= "" then
        UpdateSuggestions()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- GLOBAL CLICK HANDLER
-- Closes dropdowns when clicking outside.
-- ═══════════════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Ignore non-click inputs (keyboard, gamepad, etc.)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 
       and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    
    -- If Roblox already handled this (chat, etc.), ignore
    if gameProcessed then return end
    
    local pos = input.Position
    
    -- Helper: checks if a screen point is inside a GUI's absolute bounds
    local function isInside(gui)
        if not gui or not gui.Parent then return false end
        local ap = gui.AbsolutePosition
        local as = gui.AbsoluteSize
        return pos.X >= ap.X and pos.X <= ap.X + as.X
           and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
    end
    
    -- Close search suggestions when clicking outside
    if SuggestFrame and SuggestFrame.Visible then
        if not isInside(SearchFrame) and not isInside(SuggestFrame) then
            SuggestFrame.Visible = false
        end
    end
    
    -- DROPDOWN LOGIC
    if ActiveDropdownFrame and ActiveDropdownFrame.Parent then
        -- 1. Clicked INSIDE the dropdown? Do nothing.
        if isInside(ActiveDropdownFrame) then
            return
        end
        
        -- 2. Clicked on the card that opened the dropdown?
        --    Let the card's Activated event handle closing it.
        if ActiveDropdownCard and isInside(ActiveDropdownCard) then
            return
        end
        
        -- 3. Clicked anywhere else? Close the dropdown.
        CloseDropdown()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE SYSTEM
-- Each page is a function that clears the content area and fills it.
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
-- PAGE: Account
-- ═══════════════════════════════════════════════════════════════════════
function Pages.Account()
    SwitchPage("Account", "Account", "Exotic Hub account", function()
        
        local accountCard = CreateCard("Account", "👤", Theme.Accent)
        accountCard.Activated:Connect(function()
            ToggleDropdown(accountCard, function(scroll)
                CreateLabel(scroll, "Key expires in 5 days 15\nhours 32 min", Theme.TextSecondary, 12)
                
                local discordBtn = CreateBtn(scroll, "Join Discord", Theme.Card, 120)
                discordBtn.Size = UDim2.new(1, -8, 0, 30)
                
                -- ═══════════════════════════
                -- ⚙️ INSERT ACCOUNT CODE HERE
                -- ═══════════════════════════
            end)
        end)
        
        local logoutCard = CreateCard("Logout", "🔒", Theme.AccentRed)
        logoutCard.Activated:Connect(function()
            ToggleDropdown(logoutCard, function(scroll)
                local logoutBtn = CreateBtn(scroll, "Logout", Theme.AccentRed, 120)
                logoutBtn.Size = UDim2.new(1, -8, 0, 30)
                logoutBtn.Activated:Connect(function()
                    -- ═══════════════════════════
                    -- ⚙️ INSERT LOGOUT CODE HERE
                    -- ═══════════════════════════
                    print("Logout clicked!")
                end)
            end)
        end)
        
    end)
end

RegisterSearch("Account", "Account", "👤", function() SidebarButtons["Account"]() end)
RegisterSearch("Logout", "Account", "🔒", function() SidebarButtons["Account"]() end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE: Home
-- ═══════════════════════════════════════════════════════════════════════
function Pages.Home()
    SwitchPage("Home", "Home", "Game Version: v2984 [US]", function()
        
        -- Auto Hatch Card
        local hatchCard = CreateCard("Auto Hatch", "🥚", Theme.Accent)
        hatchCard.Activated:Connect(function()
            ToggleDropdown(hatchCard, function(scroll)
                CreateLabel(scroll, 
                    "🟢 Hatching Complete.\n\n" ..
                    "Pets In Inventory: 235 / 235\n" ..
                    "Max Eggs Allowed: 13\n" ..
                    "Max Pets Equip Allowed: 8\n" ..
                    "Eggs Planted: 13", 
                    Theme.TextSecondary, 11
                )
                CreateLabel(scroll, 
                    "⚠️ [Warning] Do not trade,\n" ..
                    "unfavourite or gift while\n" ..
                    "the hatching system is\n" ..
                    "active!", 
                    Theme.AccentRed, 11
                )
                
                CreateToggle(scroll, "Enable Auto Hatch", false, function(isEnabled)
                    if isEnabled then
                        print("🥚 Auto Hatch ENABLED")
                        AutoHatchScript:Toggle()
                    else
                        print("🥚 Auto Hatch DISABLED")
                        AutoHatchScript:Toggle()
                    end
                end)
            end)
        end)
        RegisterSearch("Auto Hatch", "Home", "🥚", function() SidebarButtons["Home"]() end)
        
        -- System Card
        local systemCard = CreateCard("System", "⚙", Theme.Accent)
        systemCard.Activated:Connect(function()
            ToggleDropdown(systemCard, function(scroll)
                CreateLabel(scroll, 
                    "⏸️ Pause all systems.\n" ..
                    "This does NOT pause\n" ..
                    "hatching or mutation.", 
                    Theme.AccentOrange, 11
                )
                
                CreateToggle(scroll, "Pause All Systems", false, function(isEnabled)
                    -- ═══════════════════════════
                    -- ⚙️ INSERT PAUSE CODE HERE
                    -- ═══════════════════════════
                    print("Pause All:", isEnabled)
                end)
            end)
        end)
        RegisterSearch("System", "Home", "⚙", function() SidebarButtons["Home"]() end)
        
        -- Farm Details Card
        local farmCard = CreateCard("Farm Details", "🌾", Theme.AccentGreen)
        farmCard.Activated:Connect(function()
            ToggleDropdown(farmCard, function(scroll)
                CreateLabel(scroll, "Plants In Farm x0", Theme.AccentGreen, 12)
                
                CreateToggle(scroll, "Enable Auto Farm", false, function(isEnabled)
                    if isEnabled then
                        print("🌾 Auto Farm ENABLED")
                        AutoFarmScript:Toggle()
                    else
                        print("🌾 Auto Farm DISABLED")
                        AutoFarmScript:Toggle()
                    end
                end)
            end)
        end)
        
    end)
end

RegisterSearch("Home", "Home", "🏠", function() SidebarButtons["Home"]() end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE: Premium
-- ═══════════════════════════════════════════════════════════════════════
function Pages.Premium()
    SwitchPage("Premium", "Premium", "Premium Features", function()
        
        local giftCard = CreateCard("🎁 Gifting / Trade 💎", "🎁", Theme.Accent)
        giftCard.Activated:Connect(function()
            ToggleDropdown(giftCard, function(scroll)
                CreateToggle(scroll, "Auto Accept Gift", false, function(state)
                    -- ⚙️ INSERT GIFT CODE HERE
                    print("Auto Accept Gift:", state)
                end)
                
                CreateToggle(scroll, "Auto Accept Trade", false, function(state)
                    -- ⚙️ INSERT TRADE CODE HERE
                    print("Auto Accept Trade:", state)
                end)
                
                CreateLabel(scroll, "🐾 Pets", Theme.TextSecondary, 12)
                
                -- Pet selector button
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
                    ShowModal("Select Pet", {
                        "Mimic Octopus",
                        "Rainbow Bird",
                        "Bacon Pig",
                        "Parasaurolophus",
                        "Goose",
                        "Seal"
                    }, function(selected)
                        petSelBtn.Text = selected .. "    ^"
                    end)
                end)
                
                -- Select/Remove All row
                local btnRow = Create("Frame", {
                    Parent = scroll,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -8, 0, 26),
                    ZIndex = Z.DropControl,
                })
                
                local selAllBtn = CreateBtn(btnRow, "Select All", Theme.Accent, 70)
                selAllBtn.Position = UDim2.new(0, 0, 0, 0)
                selAllBtn.Activated:Connect(function()
                    -- ⚙️ INSERT SELECT ALL CODE HERE
                end)
                
                local remAllBtn = CreateBtn(btnRow, "Remove All", Theme.AccentRed, 70)
                remAllBtn.Position = UDim2.new(0, 75, 0, 0)
                remAllBtn.Activated:Connect(function()
                    -- ⚙️ INSERT REMOVE ALL CODE HERE
                end)
                
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
                    -- ⚙️ INSERT YOUR CODE FOR THIS FEATURE
                end)
            end)
            RegisterSearch(item[1], "Premium", item[2], function() SidebarButtons["Premium"]() end)
        end
        
    end)
end

RegisterSearch("Premium", "Premium", "💎", function() SidebarButtons["Premium"]() end)
RegisterSearch("Gifting", "Premium", "🎁", function() SidebarButtons["Premium"]() end)
RegisterSearch("Trade", "Premium", "💎", function() SidebarButtons["Premium"]() end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE: Hatching Teams
-- ═══════════════════════════════════════════════════════════════════════
function Pages.HatchingTeams()
    SwitchPage("Hatching Teams", "Hatching Teams", 
        "Manage teams used for\nhatching pets efficiently.", function()
        
        local eggCard = CreateCard("Egg Reduction [Peacock]", "🥚", Theme.Accent)
        eggCard.Activated:Connect(function()
            ToggleDropdown(eggCard, function(scroll)
                CreateLabel(scroll, 
                    "⭐ Speeds up egg timer.\n" ..
                    "Pets: Mimics, Peacock,\n" ..
                    "Bald Eagles", 
                    Theme.AccentYellow, 11
                )
                CreateLabel(scroll, "Selected: 8/8", Theme.TextSecondary, 11)
                
                local btnRow = Create("Frame", {
                    Parent = scroll,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -8, 0, 26),
                    ZIndex = Z.DropControl,
                })
                
                local equipBtn = CreateBtn(btnRow, "Equip", Theme.Accent, 55)
                equipBtn.Position = UDim2.new(0, 0, 0, 0)
                equipBtn.Activated:Connect(function()
                    -- ⚙️ INSERT EQUIP CODE HERE
                end)
                
                local unequipBtn = CreateBtn(btnRow, "UnEquip", Theme.AccentRed, 55)
                unequipBtn.Position = UDim2.new(0, 60, 0, 0)
                unequipBtn.Activated:Connect(function()
                    -- ⚙️ INSERT UNEQUIP CODE HERE
                end)
                
                local reloadBtn = CreateBtn(btnRow, "Reload", Theme.AccentGreen, 55)
                reloadBtn.Position = UDim2.new(0, 120, 0, 0)
                reloadBtn.Activated:Connect(function()
                    -- ⚙️ INSERT RELOAD CODE HERE
                end)
                
                CreateLabel(scroll, "🍬 Pet Boosts\n---", Theme.TextSecondary, 11)
                CreateToggle(scroll, "Enable Boosts", false, function(state)
                    -- ⚙️ INSERT BOOST CODE HERE
                end)
                
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
                    -- ⚙️ INSERT YOUR CODE FOR THIS FEATURE
                end)
            end)
        end
        
    end)
end

RegisterSearch("Hatching Teams", "Hatching Teams", "🥚", function() SidebarButtons["Hatching Teams"]() end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE: Pet Manager
-- ═══════════════════════════════════════════════════════════════════════
function Pages.PetManager()
    SwitchPage("Pet Manager", "Pet Manager", 
        "Feed, grow, and manage\nyour pets with ease.", function()
        
        local feedCard = CreateCard("Pet Feeding System", "🍼", Theme.Accent)
        feedCard.Activated:Connect(function()
            ToggleDropdown(feedCard, function(scroll)
                CreateLabel(scroll, "🔴 Not running", Theme.AccentRed, 11)
                CreateLabel(scroll, 
                    "🐾 Exclude Pets\n" ..
                    "Seal, Brontosaurus, Koi", 
                    Theme.TextSecondary, 11
                )
                CreateLabel(scroll, 
                    "🌱 Exclude Plants\n" ..
                    "Four Leaf Clover", 
                    Theme.TextSecondary, 11
                )
                CreateLabel(scroll, 
                    "⚠️ Feeds all active pets\n" ..
                    "with hunger under 60%.", 
                    Theme.AccentYellow, 10
                )
                
                CreateToggle(scroll, "Auto Feed Pet", false, function(isEnabled)
                    if isEnabled then
                        print("🍼 Auto Feed ENABLED")
                        AutoFeedScript:Toggle()
                    else
                        print("🍼 Auto Feed DISABLED")
                        AutoFeedScript:Toggle()
                    end
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
                    -- ⚙️ INSERT YOUR CODE FOR THIS FEATURE
                end)
            end)
        end
        
    end)
end

RegisterSearch("Pet Manager", "Pet Manager", "🐾", function() SidebarButtons["Pet Manager"]() end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE: Craft and Cook
-- ═══════════════════════════════════════════════════════════════════════
function Pages.CraftAndCook()
    SwitchPage("Craft and Cook", "Craft and Cook", 
        "Automatically craft items\nand manage your workbench", function()
        
        local benchCard = CreateCard("🔥 Work Bench(s) 🔥", "🔥", Theme.AccentOrange)
        benchCard.Activated:Connect(function()
            ToggleDropdown(benchCard, function(scroll)
                CreateLabel(scroll, "🔴 Not running", Theme.AccentRed, 11)
                CreateLabel(scroll, 
                    "ℹ️ Select recipes and\n" ..
                    "[Enable] to craft.", 
                    Theme.AccentCyan, 11
                )
                CreateLabel(scroll, 
                    "⚠️ Auto-Craft your items\n" ..
                    "automatically.", 
                    Theme.AccentYellow, 10
                )
                
                CreateToggle(scroll, "Auto-Craft", false, function(isEnabled)
                    if isEnabled then
                        print("🔨 Auto Craft ENABLED")
                        AutoCraftScript:Toggle()
                    else
                        print("🔨 Auto Craft DISABLED")
                        AutoCraftScript:Toggle()
                    end
                end)
            end)
        end)
        
        local cookCard = CreateCard("Cooking Pots", "🍳", Theme.AccentGreen)
        cookCard.Activated:Connect(function()
            ToggleDropdown(cookCard, function(scroll)
                CreateLabel(scroll, "Cooking options...", Theme.TextSecondary, 12)
                -- ⚙️ INSERT COOKING CODE HERE
            end)
        end)
        
        local teamCard = CreateCard("Craft Teams", "⚔", Theme.AccentCyan)
        teamCard.Activated:Connect(function()
            ToggleDropdown(teamCard, function(scroll)
                CreateLabel(scroll, "Team options...", Theme.TextSecondary, 12)
                -- ⚙️ INSERT CRAFT TEAM CODE HERE
            end)
        end)
        
    end)
end

RegisterSearch("Craft and Cook", "Craft and Cook", "🔥", function() SidebarButtons["Craft and Cook"]() end)

-- ═══════════════════════════════════════════════════════════════════════
-- PAGE: Placeholder
-- For pages that are not ready yet.
-- ═══════════════════════════════════════════════════════════════════════
function Pages.Placeholder(title, subtitle, icon)
    return function()
        SwitchPage(title, title, subtitle or "", function()
            CreateCard("Coming Soon", icon or "📦", Theme.TextMuted)
            CreateLabel(ContentScroll, 
                "This feature is not yet available.", 
                Theme.TextMuted, 16
            )
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SIDEBAR SETUP
-- We loop through the menu list and create a button for each page.
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
    
    -- Store the click function so we can call it from search
    SidebarButtons[item.Name] = function()
        CurrentPage = item.Name
        
        -- Highlight the selected button, dim the others
        for _, child in pairs(SidebarScroll:GetChildren()) do
            if child:IsA("TextButton") then
                local isSelected = (child.Name == item.Name)
                Tween(child, {
                    BackgroundColor3 = isSelected and Theme.Card or Theme.Sidebar
                }, 0.2)
            end
        end
        
        -- Open the page (this also closes any open dropdown)
        item.Page()
    end
    
    -- Hover effects
    btn.MouseEnter:Connect(function()
        if CurrentPage ~= item.Name then
            Tween(btn, {BackgroundColor3 = Theme.CardHover}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if CurrentPage ~= item.Name then
            Tween(btn, {BackgroundColor3 = Theme.Sidebar}, 0.15)
        end
    end)
    
    -- Activated works for both mouse and touch
    btn.Activated:Connect(SidebarButtons[item.Name])
    
    -- Register for search
    RegisterSearch(item.Name, item.Name, item.Icon, SidebarButtons[item.Name])
end

-- ═══════════════════════════════════════════════════════════════════════
-- MOBILE SUPPORT
-- If the device has a touch screen, we shrink the window slightly
-- so it fits comfortably on smaller screens.
-- ═══════════════════════════════════════════════════════════════════════
if UserInputService.TouchEnabled then
    local viewport = workspace.CurrentCamera.ViewportSize
    MainFrame.Size = UDim2.new(
        0, math.min(Config.WindowWidth, viewport.X - 20),
        0, math.min(Config.WindowHeight, viewport.Y - 40)
    )
    MainFrame.Position = UDim2.new(
        0.5, -MainFrame.Size.X.Offset / 2,
        0.5, -MainFrame.Size.Y.Offset / 2
    )
end

-- ═══════════════════════════════════════════════════════════════════════
-- STARTUP
-- Open the Home page by default and print a success message.
-- ═══════════════════════════════════════════════════════════════════════
Pages.Home()
print("✅ Exotic Hub PRO v10.4 loaded successfully!")
print("📁 Look for ⚙️ markers to insert your automation scripts")