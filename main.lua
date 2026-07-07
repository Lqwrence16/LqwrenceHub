local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

--===============================================================================
-- 1. THEME ENGINE
--===============================================================================
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
    Registry = {},
    ActiveWindows = {},
}

function LRXUI:SetTheme(themeName)
    if not self.Themes[themeName] then
        return
    end

    self.CurrentTheme = themeName
    local colors = self.Themes[themeName]

    for instance, bindings in pairs(self.Registry) do
        pcall(function()
            for propName, themeKey in pairs(bindings) do
                instance[propName] = colors[themeKey]
            end
        end)
    end
end

function LRXUI:BindTheme(instance, propertyBindings)
    if not self.Registry[instance] then
        self.Registry[instance] = {}
    end

    local colors = self.Themes[self.CurrentTheme]
    for propName, themeKey in pairs(propertyBindings) do
        self.Registry[instance][propName] = themeKey
        if colors[themeKey] then
            pcall(function()
                instance[propName] = colors[themeKey]
            end)
        end
    end
end

function LRXUI:GetThemeColors()
    return self.Themes[self.CurrentTheme]
end

--===============================================================================
-- 2. DESIGN CONSTANTS AND HELPERS
--===============================================================================
local Design = {
    CornerRadius = 8,
    Padding = 8,
    ElementHeight = 32,
    WindowSize = Vector2.new(720, 480),
    FontBold = Enum.Font.GothamSemibold,
    FontRegular = Enum.Font.Gotham,
    FontMono = Enum.Font.Code,
}

local function New(className, properties)
    local instance = Instance.new(className)
    local themeBinding = properties.ThemeBinding
    properties.ThemeBinding = nil

    for propName, value in pairs(properties) do
        pcall(function()
            instance[propName] = value
        end)
    end

    if themeBinding then
        LRXUI:BindTheme(instance, themeBinding)
    end

    return instance
end

local function MakeCorner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or Design.CornerRadius),
        Parent = parent,
    })
end

local function MakePadding(parent, top, bottom, left, right)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent,
    })
end

local function MakeStroke(parent, thickness)
    return New("UIStroke", {
        Color = LRXUI:GetThemeColors().Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
        ThemeBinding = {
            Color = "Border",
        },
    })
end

local function MakeList(parent, padding)
    return New("UIListLayout", {
        Padding = padding or UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

--===============================================================================
-- 3. UTILITY FUNCTIONS
--===============================================================================
local Utility = {}

function Utility:RunSafeCallback(callback, ...)
    if callback and typeof(callback) == "function" then
        local success, result = pcall(callback, ...)
        if not success then
            warn(result)
        end
    end
end

function Utility:MakeDraggable(frame, handle)
    local dragging = false
    local dragStart
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

--===============================================================================
-- 4. WINDOW SYSTEM
--===============================================================================
local WindowSystem = {}
WindowSystem.__index = WindowSystem

function WindowSystem.new(config)
    local self = setmetatable({}, WindowSystem)
    self.Name = config and config.Title or "LqwrenceHub"
    self.Pages = {}
    self.ActivePage = nil

    local colors = LRXUI:GetThemeColors()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    self.ScreenGui = New("ScreenGui", {
        Name = self.Name .. "_UI",
        ResetOnSpawn = false,
        Parent = playerGui,
    })

    self.Window = New("Frame", {
        Name = "MainWindow",
        Size = config and config.Size or UDim2.fromOffset(Design.WindowSize.X, Design.WindowSize.Y),
        Position = UDim2.fromOffset(60, 60),
        BackgroundColor3 = colors.Surface,
        Parent = self.ScreenGui,
        ThemeBinding = {
            BackgroundColor3 = "Surface",
        },
    })
    MakeCorner(self.Window, 10)
    MakeStroke(self.Window, 1)

    self.Header = New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = self.Window,
    })

    self.TitleLabel = New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Font = Design.FontBold,
        TextSize = 15,
        Text = self.Name,
        TextColor3 = colors.Text,
        Parent = self.Header,
        ThemeBinding = {
            TextColor3 = "Text",
        },
    })

    self.CloseButton = New("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -42, 0.5, -16),
        BackgroundColor3 = colors.SurfaceHover,
        Text = "X",
        Font = Design.FontBold,
        TextColor3 = colors.Text,
        Parent = self.Header,
        ThemeBinding = {
            BackgroundColor3 = "SurfaceHover",
            TextColor3 = "Text",
        },
    })
    MakeCorner(self.CloseButton, 8)
    self.CloseButton.MouseButton1Click:Connect(function()
        self.ScreenGui:Destroy()
    end)

    self.Sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 180, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = colors.Sidebar,
        Parent = self.Window,
        ThemeBinding = {
            BackgroundColor3 = "Sidebar",
        },
    })
    MakePadding(self.Sidebar, 8, 8, 8, 8)
    MakeList(self.Sidebar, UDim.new(0, 8))

    self.Content = New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -180, 1, -48),
        Position = UDim2.new(0, 180, 0, 48),
        BackgroundColor3 = colors.Content,
        Parent = self.Window,
        ThemeBinding = {
            BackgroundColor3 = "Content",
        },
    })
    MakePadding(self.Content, 12, 12, 12, 12)

    Utility:MakeDraggable(self.Window, self.Header)
    LRXUI.ActiveWindows[#LRXUI.ActiveWindows + 1] = self

    return self
end

function WindowSystem:AddPage(title)
    local page = PageSystem.new(self, title)
    self.Pages[#self.Pages + 1] = page
    if not self.ActivePage then
        page:Select()
    end
    return page
end

--===============================================================================
-- 5. PAGE SYSTEM
--===============================================================================
local PageSystem = {}
PageSystem.__index = PageSystem

function PageSystem.new(window, title)
    local self = setmetatable({}, PageSystem)
    self.Window = window
    self.Title = title
    self.Cards = {}

    self.Button = New("TextButton", {
        Name = title .. "Button",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = LRXUI:GetThemeColors().Surface,
        Text = title,
        Font = Design.FontRegular,
        TextColor3 = LRXUI:GetThemeColors().SubText,
        Parent = window.Sidebar,
        ThemeBinding = {
            BackgroundColor3 = "Surface",
            TextColor3 = "SubText",
        },
    })
    MakeCorner(self.Button, 8)
    self.Button.MouseButton1Click:Connect(function()
        self:Select()
    end)

    self.Frame = New("Frame", {
        Name = title .. "Page",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = window.Content,
    })
    MakeList(self.Frame, UDim.new(0, 10))

    return self
end

function PageSystem:Select()
    for _, page in ipairs(self.Window.Pages) do
        page.Frame.Visible = false
        page.Button.BackgroundColor3 = LRXUI:GetThemeColors().Surface
        page.Button.TextColor3 = LRXUI:GetThemeColors().SubText
    end

    self.Frame.Visible = true
    self.Button.BackgroundColor3 = LRXUI:GetThemeColors().Accent
    self.Button.TextColor3 = LRXUI:GetThemeColors().Text
    self.Window.ActivePage = self
end

function PageSystem:AddCard(title)
    local card = CardSystem.new(self, title)
    self.Cards[#self.Cards + 1] = card
    return card
end

--===============================================================================
-- 6. CARD SYSTEM
--===============================================================================
local CardSystem = {}
CardSystem.__index = CardSystem

function CardSystem.new(page, title)
    local self = setmetatable({}, CardSystem)
    self.Page = page
    self.Title = title

    self.Frame = New("Frame", {
        Name = title .. "Card",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = LRXUI:GetThemeColors().Surface,
        Parent = page.Frame,
        ThemeBinding = {
            BackgroundColor3 = "Surface",
        },
    })
    MakeCorner(self.Frame, 8)
    MakeStroke(self.Frame, 1)
    MakePadding(self.Frame, 10, 10, 12, 12)

    self.TitleLabel = New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -8, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Design.FontBold,
        TextSize = 14,
        Text = title,
        TextColor3 = LRXUI:GetThemeColors().Text,
        Parent = self.Frame,
        ThemeBinding = {
            TextColor3 = "Text",
        },
    })

    self.Content = New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -28),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    })
    MakeList(self.Content, UDim.new(0, 8))

    self.Frame.Size = UDim2.new(1, 0, 0, 28 + 24)
    return self
end

function CardSystem:AddLabel(text)
    local label = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        Font = Design.FontRegular,
        TextSize = 13,
        TextColor3 = LRXUI:GetThemeColors().SubText,
        Parent = self.Content,
        ThemeBinding = {
            TextColor3 = "SubText",
        },
    })
    return label
end

function CardSystem:AddButton(text, callback)
    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = LRXUI:GetThemeColors().SurfaceHover,
        Text = text,
        Font = Design.FontRegular,
        TextSize = 13,
        TextColor3 = LRXUI:GetThemeColors().Text,
        Parent = self.Content,
        ThemeBinding = {
            BackgroundColor3 = "SurfaceHover",
            TextColor3 = "Text",
        },
    })
    MakeCorner(button, 8)
    button.MouseButton1Click:Connect(function()
        Utility:RunSafeCallback(callback)
    end)
    return button
end

function CardSystem:AddToggle(text, default, callback)
    local toggle = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = LRXUI:GetThemeColors().SurfaceHover,
        Text = text .. "  [OFF]",
        Font = Design.FontRegular,
        TextSize = 13,
        TextColor3 = LRXUI:GetThemeColors().Text,
        Parent = self.Content,
        ThemeBinding = {
            BackgroundColor3 = "SurfaceHover",
            TextColor3 = "Text",
        },
    })
    MakeCorner(toggle, 8)

    local enabled = default or false
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggle.Text = text .. (enabled and "  [ON]" or "  [OFF]")
        toggle.BackgroundColor3 = enabled and LRXUI:GetThemeColors().Accent or LRXUI:GetThemeColors().SurfaceHover
        Utility:RunSafeCallback(callback, enabled)
    end)

    return toggle
end

function CardSystem:AddSlider(text, minValue, maxValue, defaultValue, callback)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        Parent = self.Content,
    })

    local label = New("TextLabel", {
        Size = UDim2.new(1, -60, 0, 18),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Design.FontRegular,
        TextSize = 13,
        TextColor3 = LRXUI:GetThemeColors().SubText,
        Parent = holder,
        ThemeBinding = {
            TextColor3 = "SubText",
        },
    })

    local valueLabel = New("TextLabel", {
        Size = UDim2.new(0, 48, 0, 18),
        Position = UDim2.new(1, -48, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(defaultValue or 0),
        Font = Design.FontRegular,
        TextSize = 13,
        TextColor3 = LRXUI:GetThemeColors().Accent,
        Parent = holder,
        ThemeBinding = {
            TextColor3 = "Accent",
        },
    })

    local bar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = LRXUI:GetThemeColors().SurfaceHover,
        Parent = holder,
        ThemeBinding = {
            BackgroundColor3 = "SurfaceHover",
        },
    })
    MakeCorner(bar, 4)

    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = LRXUI:GetThemeColors().Accent,
        Parent = bar,
        ThemeBinding = {
            BackgroundColor3 = "Accent",
        },
    })
    MakeCorner(fill, 4)

    local function update(percent)
        local clamped = math.clamp(percent, 0, 1)
        local value = minValue + (maxValue - minValue) * clamped
        valueLabel.Text = tostring(math.floor(value + 0.5))
        fill.Size = UDim2.new(clamped, 0, 1, 0)
        Utility:RunSafeCallback(callback, value)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        local relative = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        update(relative)

        local changed
        changed = UserInputService.InputChanged:Connect(function(change)
            if change.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end
            local newRelative = math.clamp((change.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            update(newRelative)
        end)

        local ended
        ended = UserInputService.InputEnded:Connect(function(change)
            if change.UserInputType == Enum.UserInputType.MouseButton1 then
                changed:Disconnect()
                ended:Disconnect()
            end
        end)
    end)

    update((defaultValue or minValue) / maxValue)
    return holder
end

function CardSystem:AddInput(text, placeholder, callback)
    local input = New("TextBox", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = LRXUI:GetThemeColors().SurfaceHover,
        Text = "",
        PlaceholderText = placeholder or "",
        ClearTextOnFocus = false,
        Font = Design.FontRegular,
        TextSize = 13,
        TextColor3 = LRXUI:GetThemeColors().Text,
        Parent = self.Content,
        ThemeBinding = {
            BackgroundColor3 = "SurfaceHover",
            TextColor3 = "Text",
        },
    })
    MakeCorner(input, 8)
    MakeStroke(input, 1)

    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            Utility:RunSafeCallback(callback, input.Text)
        end
    end)

    return input
end

function CardSystem:AddDropdown(text, options, callback)
    local dropdown = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = LRXUI:GetThemeColors().SurfaceHover,
        Text = text .. "  ▾",
        Font = Design.FontRegular,
        TextSize = 13,
        TextColor3 = LRXUI:GetThemeColors().Text,
        Parent = self.Content,
        ThemeBinding = {
            BackgroundColor3 = "SurfaceHover",
            TextColor3 = "Text",
        },
    })
    MakeCorner(dropdown, 8)

    dropdown.MouseButton1Click:Connect(function()
        local choice = options[1]
        if choice then
            dropdown.Text = text .. "  " .. choice
            Utility:RunSafeCallback(callback, choice)
        end
    end)

    return dropdown
end

--===============================================================================
-- 7. MAIN LIBRARY WRAPPER
--===============================================================================
local Library = {}

function Library:CreateWindow(config)
    return WindowSystem.new(config)
end

function Library:Notify(title, description, duration)
    duration = duration or 3

    local notification = New("Frame", {
        Size = UDim2.new(0, 220, 0, 58),
        BackgroundColor3 = LRXUI:GetThemeColors().Surface,
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ThemeBinding = {
            BackgroundColor3 = "Surface",
        },
    })
    MakeCorner(notification, 8)
    MakeStroke(notification, 1)

    local titleLabel = New("TextLabel", {
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        Font = Design.FontBold,
        Text = title,
        TextSize = 13,
        TextColor3 = LRXUI:GetThemeColors().Text,
        Parent = notification,
        ThemeBinding = {
            TextColor3 = "Text",
        },
    })

    local descLabel = New("TextLabel", {
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.new(0, 8, 0, 30),
        BackgroundTransparency = 1,
        Font = Design.FontRegular,
        Text = description,
        TextSize = 12,
        TextColor3 = LRXUI:GetThemeColors().SubText,
        Parent = notification,
        ThemeBinding = {
            TextColor3 = "SubText",
        },
    })

    notification.Position = UDim2.new(1, -236, 0, 16 + (#LRXUI.ActiveWindows * 64))

    task.delay(duration, function()
        if notification and notification.Parent then
            notification:Destroy()
        end
    end)

    return notification
end

return Library
