local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)

local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Teams = cloneref(game:GetService("Teams"))

local getgenv = getgenv or function() return shared end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function() return CoreGui end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local LRXUI = {
    Name = "LRX_Hub",
    Version = "v1.0",

    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,

    ScreenGui = nil,
    ActiveTab = nil,
    Tabs = {},

    Notifications = {},
    ToggleKeybind = Enum.KeyCode.RightControl,

    Toggled = false,
    Unloaded = false,

    Options = {},

    Signals = {},
    UnloadSignals = {},

    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,

    Scheme = {
        BackgroundColor = Color3.fromRGB(22, 22, 26),
        MainColor = Color3.fromRGB(28, 28, 32),
        AccentColor = Color3.fromRGB(147, 112, 219),
        OutlineColor = Color3.fromRGB(50, 50, 55),
        FontColor = Color3.fromRGB(255, 255, 255),
        FontColorSecondary = Color3.fromRGB(160, 160, 160),
        FontColorMuted = Color3.fromRGB(100, 100, 100),
        CardColor = Color3.fromRGB(35, 35, 40),
        CardHoverColor = Color3.fromRGB(45, 45, 50),
        ContentColor = Color3.fromRGB(18, 18, 22),
        DropdownBg = Color3.fromRGB(32, 32, 38),
        ToggleBg = Color3.fromRGB(60, 60, 65),
        ToggleOn = Color3.fromRGB(147, 112, 219),
        ScrollBar = Color3.fromRGB(60, 60, 70),
        Red = Color3.fromRGB(255, 80, 80),
        Green = Color3.fromRGB(50, 205, 50),
        Yellow = Color3.fromRGB(255, 215, 0),
        Pink = Color3.fromRGB(255, 105, 180),
        Cyan = Color3.fromRGB(0, 255, 255),
        Font = Font.fromEnum(Enum.Font.Gotham),
        FontBold = Font.fromEnum(Enum.Font.GothamBold),
        FontSemibold = Font.fromEnum(Enum.Font.GothamSemibold),
    },
}

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        LRXUI.IsMobile = true
        LRXUI.MinSize = Vector2.new(480, 240)
    end
else
    pcall(function()
        LRXUI.DevicePlatform = UserInputService:GetPlatform()
    end)
    LRXUI.IsMobile = (LRXUI.DevicePlatform == Enum.Platform.Android or LRXUI.DevicePlatform == Enum.Platform.IOS)
    LRXUI.MinSize = LRXUI.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

function LRXUI:SafeCallback(callback, ...)
    if not callback then return end
    local success, result = pcall(callback, ...)
    if not success then
        warn("[LRXUI] Callback error: " .. tostring(result))
    end
    return success, result
end

function LRXUI:GiveSignal(signal)
    table.insert(self.Signals, signal)
end

function LRXUI:Unload()
    self.Unloaded = true
    for _, signal in ipairs(self.Signals) do
        if typeof(signal) == "RBXScriptConnection" then
            signal:Disconnect()
        elseif typeof(signal) == "Instance" then
            signal:Destroy()
        end
    end
    for _, signal in ipairs(self.UnloadSignals) do
        if typeof(signal) == "RBXScriptConnection" then
            signal:Disconnect()
        elseif typeof(signal) == "Instance" then
            signal:Destroy()
        end
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    self.ScreenGui = nil
end

function LRXUI:Create(className, properties, children)
    local instance = Instance.new(className)
    if properties then
        for prop, value in pairs(properties) do
            instance[prop] = value
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    return instance
end

function LRXUI:SetProps(instance, properties)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

function LRXUI:SetChildren(instance, children)
    for _, child in ipairs(children) do
        child.Parent = instance
    end
    return instance
end

function LRXUI:Tween(instance, properties, duration, easingStyle, easingDirection, callback)
    duration = duration or 0.2
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out

    local tween = TweenService:Create(instance, TweenInfo.new(duration, easingStyle, easingDirection), properties)
    if callback then
        tween.Completed:Connect(callback)
    end
    tween:Play()
    return tween
end

function LRXUI:MakeDraggable(dragPoint, mainFrame)
    local dragging = false
    local dragInput = nil
    local mousePos = nil
    local framePos = nil

    dragPoint.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragPoint.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            mainFrame.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)
end

function LRXUI:Notify(title, message, notifType, duration)
    title = title or "Notification"
    message = message or ""
    notifType = notifType or "info"
    duration = duration or 5

    local notifColors = {
        info = self.Scheme.AccentColor,
        success = self.Scheme.Green,
        warning = self.Scheme.Yellow,
        error = self.Scheme.Red,
    }
    local color = notifColors[notifType] or self.Scheme.AccentColor

    local holder = self.NotificationHolder
    if not holder then
        holder = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 300, 1, -25),
            Position = UDim2.new(1, -25, 1, -25),
            AnchorPoint = Vector2.new(1, 1),
            Parent = self.ScreenGui,
        }, {
            self:Create("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 5),
            }),
        })
        self.NotificationHolder = holder
    end

    local notifParent = self:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = holder,
    })

    local notifFrame = self:SetChildren(self:Create("Frame", {
        BackgroundColor3 = self.Scheme.MainColor,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(1, -55, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = notifParent,
    }, {
        self:Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        self:Create("UIStroke", { Color = self.Scheme.OutlineColor, Thickness = 1 }),
        self:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
        }),
    }), {
        self:SetProps(self:Create("Frame"), {
            Size = UDim2.new(0, 4, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Name = "AccentBar",
        }),
        self:SetProps(self:Create("TextLabel"), {
            Text = title,
            Font = self.Scheme.FontBold,
            TextSize = 15,
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 12, 0, 0),
            Name = "Title",
            BackgroundTransparency = 1,
            TextColor3 = self.Scheme.FontColor,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        self:SetProps(self:Create("TextLabel"), {
            Text = message,
            TextColor3 = self.Scheme.FontColorSecondary,
            TextSize = 13,
            Size = UDim2.new(1, -20, 0, 0),
            Position = UDim2.new(0, 12, 0, 24),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            Name = "Content",
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })

    self:Tween(notifFrame, { Position = UDim2.new(0, 0, 0, 0) }, 0.5, Enum.EasingStyle.Quint)

    task.delay(duration - 0.88, function()
        self:Tween(notifFrame, { BackgroundTransparency = 0.6 }, 0.8, Enum.EasingStyle.Quint)
        local accent = notifFrame:FindFirstChild("AccentBar")
        if accent then self:Tween(accent, { BackgroundTransparency = 0.9 }, 0.6, Enum.EasingStyle.Quint) end
        self:Tween(notifFrame.Title, { TextTransparency = 0.4 }, 0.6, Enum.EasingStyle.Quint)
        self:Tween(notifFrame.Content, { TextTransparency = 0.5 }, 0.6, Enum.EasingStyle.Quint)
        task.wait(0.05)
        self:Tween(notifFrame, { Position = UDim2.new(1, 20, 0, 0) }, 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
            task.wait(1.35)
            notifFrame:Destroy()
        end)
    end)
end

function LRXUI:CreateWindow(windowInfo)
    windowInfo = windowInfo or {}
    windowInfo.Title = windowInfo.Title or "LRX_Hub"
    windowInfo.SubTitle = windowInfo.SubTitle or ""
    windowInfo.TabWidth = windowInfo.TabWidth or 160
    windowInfo.Size = windowInfo.Size or UDim2.fromOffset(580, 420)

    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end

    local screenGui = self:Create("ScreenGui", {
        Name = "LRX_Hub",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })

    protectgui(screenGui)

    if gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = CoreGui
    end

    self.ScreenGui = screenGui

    if gethui then
        for _, child in ipairs(gethui():GetChildren()) do
            if child.Name == "LRX_Hub" and child ~= screenGui then
                child:Destroy()
            end
        end
    else
        for _, child in ipairs(CoreGui:GetChildren()) do
            if child.Name == "LRX_Hub" and child ~= screenGui then
                child:Destroy()
            end
        end
    end

    local mainFrame = self:SetChildren(self:Create("Frame", {
        BackgroundColor3 = self.Scheme.BackgroundColor,
        Size = windowInfo.Size,
        Position = UDim2.new(0.5, -windowInfo.Size.X.Offset / 2, 0.5, -windowInfo.Size.Y.Offset / 2),
        ClipsDescendants = true,
        Name = "MainWindow",
        Parent = screenGui,
    }, {
        self:Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        self:Create("UIStroke", { Color = self.Scheme.OutlineColor, Thickness = 1 }),
    }), {
        self:SetChildren(self:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = self.Scheme.MainColor,
            Name = "TopBar",
            BorderSizePixel = 0,
        }, {
            self:Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        }), {
            self:SetProps(self:Create("TextLabel"), {
                Text = windowInfo.Title,
                Font = self.Scheme.FontBold,
                TextSize = 18,
                Size = UDim2.new(1, -120, 1, 0),
                Position = UDim2.new(0, 16, 0, 0),
                Name = "Title",
                BackgroundTransparency = 1,
                TextColor3 = self.Scheme.FontColor,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            self:SetProps(self:Create("TextLabel"), {
                Text = windowInfo.SubTitle,
                TextColor3 = self.Scheme.FontColorSecondary,
                TextSize = 12,
                Size = UDim2.new(1, -120, 0, 16),
                Position = UDim2.new(0, 16, 1, -18),
                Name = "SubTitle",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            self:SetChildren(self:Create("TextButton", {
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -38, 0, 7),
                BackgroundColor3 = self.Scheme.CardColor,
                Name = "CloseBtn",
                AutoButtonColor = false,
            }, {
                self:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            }), {
                self:SetProps(self:Create("TextLabel"), {
                    Text = "✕",
                    TextColor3 = self.Scheme.FontColor,
                    TextSize = 16,
                    Size = UDim2.new(1, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    BackgroundTransparency = 1,
                }),
            }),
            self:SetChildren(self:Create("TextButton", {
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -72, 0, 7),
                BackgroundColor3 = self.Scheme.CardColor,
                Name = "MinimizeBtn",
                AutoButtonColor = false,
            }, {
                self:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            }), {
                self:SetProps(self:Create("TextLabel"), {
                    Text = "─",
                    TextColor3 = self.Scheme.FontColor,
                    TextSize = 16,
                    Size = UDim2.new(1, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    BackgroundTransparency = 1,
                }),
            }),
        }),
    })

    local dragPoint = mainFrame.TopBar
    self:MakeDraggable(dragPoint, mainFrame)

    local uiHidden = false
    mainFrame.TopBar.CloseBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        uiHidden = true
        self:Notify("Interface Hidden", "Tap RightShift to reopen", "info", 5)
    end)

    local minimized = false
    mainFrame.TopBar.MinimizeBtn.MouseButton1Click:Connect(function()
        if minimized then
            self:Tween(mainFrame, { Size = windowInfo.Size }, 0.5, Enum.EasingStyle.Quint)
            mainFrame.ClipsDescendants = false
            for _, child in ipairs(mainFrame:GetChildren()) do
                if child.Name ~= "TopBar" then
                    child.Visible = true
                end
            end
        else
            mainFrame.ClipsDescendants = true
            self:Tween(mainFrame, { Size = UDim2.new(0, mainFrame.TopBar.Title.TextBounds.X + 140, 0, 44) }, 0.5, Enum.EasingStyle.Quint)
            for _, child in ipairs(mainFrame:GetChildren()) do
                if child.Name ~= "TopBar" then
                    child.Visible = false
                end
            end
        end
        minimized = not minimized
    end)

    self:GiveSignal(UserInputService.InputBegan:Connect(function(input)
        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == self.ToggleKeybind then
            if uiHidden then
                mainFrame.Visible = true
                uiHidden = false
            else
                self.Toggled = not self.Toggled
                mainFrame.Visible = self.Toggled
            end
        end
    end))

    local sidebar = self:SetChildren(self:Create("Frame", {
        BackgroundColor3 = self.Scheme.MainColor,
        Size = UDim2.new(0, windowInfo.TabWidth, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        Name = "Sidebar",
        BorderSizePixel = 0,
        Parent = mainFrame,
    }, {
        self:Create("UICorner", { CornerRadius = UDim.new(0, 0) }),
    }), {
        self:SetChildren(self:Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, -60),
            Position = UDim2.new(0, 0, 0, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Name = "TabContainer",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = self.Scheme.ScrollBar,
            MidImage = "rbxassetid://7445543667",
            TopImage = "rbxassetid://7445543667",
            BottomImage = "rbxassetid://7445543667",
        }, {
            self:Create("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            self:Create("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
            }),
        }), {}),
        self:SetChildren(self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 1, -50),
            Name = "BottomInfo",
        }, {
            self:Create("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }),
        }), {
            self:SetProps(self:Create("TextLabel"), {
                Text = self.Name .. " " .. self.Version,
                TextColor3 = self.Scheme.FontColorMuted,
                TextSize = 11,
                Size = UDim2.new(1, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Center,
                BackgroundTransparency = 1,
            }),
        }),
    })

    local contentArea = self:Create("Frame", {
        BackgroundColor3 = self.Scheme.ContentColor,
        Size = UDim2.new(1, -windowInfo.TabWidth, 1, -44),
        Position = UDim2.new(0, windowInfo.TabWidth, 0, 44),
        Name = "ContentArea",
        BorderSizePixel = 0,
        Parent = mainFrame,
    }, {
        self:Create("UICorner", { CornerRadius = UDim.new(0, 0) }),
    })

    local contentScroll = self:SetChildren(self:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Name = "ContentScroll",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Scheme.ScrollBar,
        MidImage = "rbxassetid://7445543667",
        TopImage = "rbxassetid://7445543667",
        BottomImage = "rbxassetid://7445543667",
        Parent = contentArea,
    }, {
        self:Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        self:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
        }),
    }), {})

    local tabHolder = sidebar.TabContainer

    local firstTab = true
    local tabs = {}

    local function SwitchTab(tabButton, tabContent)
        for _, tab in ipairs(tabs) do
            tab.Button.BackgroundColor3 = LRXUI.Scheme.MainColor
            tab.Button.Title.TextColor3 = LRXUI.Scheme.FontColorSecondary
            tab.Button.Title.Font = LRXUI.Scheme.Font
            tab.Content.Visible = false
        end

        tabButton.BackgroundColor3 = LRXUI.Scheme.AccentColor
        tabButton.Title.TextColor3 = LRXUI.Scheme.FontColor
        tabButton.Title.Font = LRXUI.Scheme.FontBold
        tabContent.Visible = true

        LRXUI.ActiveTab = tabButton
    end

    local TabSystem = {}

    function TabSystem:AddTab(tabInfo)
        tabInfo = tabInfo or {}
        tabInfo.Name = tabInfo.Name or "Tab"
        tabInfo.Icon = tabInfo.Icon or ""

        local tabButton = LRXUI:SetChildren(LRXUI:Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = LRXUI.Scheme.MainColor,
            Name = tabInfo.Name .. "Tab",
            AutoButtonColor = false,
            Parent = tabHolder,
        }, {
            LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        }), {
            LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                Text = tabInfo.Icon ~= "" and (tabInfo.Icon .. "  " .. tabInfo.Name) or tabInfo.Name,
                Font = LRXUI.Scheme.Font,
                TextColor3 = LRXUI.Scheme.FontColorSecondary,
                TextSize = 14,
                Size = UDim2.new(1, -12, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Name = "Title",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
        })

        local tabContent = LRXUI:SetChildren(LRXUI:Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Name = tabInfo.Name .. "Content",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = LRXUI.Scheme.ScrollBar,
            MidImage = "rbxassetid://7445543667",
            TopImage = "rbxassetid://7445543667",
            BottomImage = "rbxassetid://7445543667",
            Parent = contentArea,
        }, {
            LRXUI:Create("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            LRXUI:Create("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
            }),
        }), {})

        tabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContent.UIListLayout.AbsoluteContentSize.Y + 20)
        end)

        local tabData = {
            Button = tabButton,
            Content = tabContent,
            Name = tabInfo.Name,
        }
        table.insert(tabs, tabData)

        if firstTab then
            firstTab = false
            tabButton.BackgroundColor3 = LRXUI.Scheme.AccentColor
            tabButton.Title.TextColor3 = LRXUI.Scheme.FontColor
            tabButton.Title.Font = LRXUI.Scheme.FontBold
            tabContent.Visible = true
            LRXUI.ActiveTab = tabButton
        end

        tabButton.MouseButton1Click:Connect(function()
            SwitchTab(tabButton, tabContent)
        end)

        local ElementBuilder = {}

        function ElementBuilder:AddSection(sectionInfo)
            sectionInfo = sectionInfo or {}
            sectionInfo.Name = sectionInfo.Name or "Section"

            local sectionFrame = LRXUI:SetChildren(LRXUI:Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
                AutomaticSize = Enum.AutomaticSize.Y,
                Name = sectionInfo.Name,
                Parent = tabContent,
            }, {
                LRXUI:Create("UIListLayout", {
                    Padding = UDim.new(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            }), {
                LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                    Text = sectionInfo.Name,
                    Font = LRXUI.Scheme.FontSemibold,
                    TextColor3 = LRXUI.Scheme.FontColorSecondary,
                    TextSize = 13,
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
            })

            local SectionElements = {}

            function SectionElements:AddToggle(toggleInfo)
                toggleInfo = toggleInfo or {}
                toggleInfo.Name = toggleInfo.Name or "Toggle"
                toggleInfo.Default = toggleInfo.Default or false
                toggleInfo.Callback = toggleInfo.Callback or function() end
                toggleInfo.Flag = toggleInfo.Flag or nil

                local toggleState = { Value = toggleInfo.Default }

                local toggleFrame = LRXUI:SetChildren(LRXUI:Create("Frame", {
                    BackgroundColor3 = LRXUI.Scheme.CardColor,
                    Size = UDim2.new(1, 0, 0, 40),
                    Name = toggleInfo.Name,
                    BorderSizePixel = 0,
                    Parent = sectionFrame,
                }, {
                    LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    LRXUI:Create("UIStroke", { Color = LRXUI.Scheme.OutlineColor, Thickness = 1 }),
                }), {
                    LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                        Text = toggleInfo.Name,
                        Font = LRXUI.Scheme.Font,
                        TextSize = 14,
                        Size = UDim2.new(1, -60, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Name = "Label",
                        BackgroundTransparency = 1,
                        TextColor3 = LRXUI.Scheme.FontColor,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }),
                    LRXUI:SetChildren(LRXUI:Create("Frame", {
                        Size = UDim2.new(0, 40, 0, 22),
                        Position = UDim2.new(1, -52, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = toggleInfo.Default and LRXUI.Scheme.ToggleOn or LRXUI.Scheme.ToggleBg,
                        Name = "ToggleBox",
                        BorderSizePixel = 0,
                    }, {
                        LRXUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    }), {
                        LRXUI:SetProps(LRXUI:Create("Frame"), {
                            Size = UDim2.new(0, 18, 0, 18),
                            Position = toggleInfo.Default and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                            AnchorPoint = Vector2.new(0, 0.5),
                            BackgroundColor3 = LRXUI.Scheme.FontColor,
                            Name = "Knob",
                            BorderSizePixel = 0,
                        }), {
                            LRXUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                        }),
                    }),
                    LRXUI:SetProps(LRXUI:Create("TextButton"), {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Name = "ClickArea",
                        AutoButtonColor = false,
                    }),
                })

                local toggleBox = toggleFrame.ToggleBox
                local knob = toggleBox.Knob

                function toggleState:Set(value)
                    self.Value = value
                    LRXUI:Tween(toggleBox, { BackgroundColor3 = value and LRXUI.Scheme.ToggleOn or LRXUI.Scheme.ToggleBg }, 0.2)
                    LRXUI:Tween(knob, { Position = value and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, 0.2)
                    LRXUI:SafeCallback(toggleInfo.Callback, value)

                    if toggleInfo.Flag then
                        LRXUI.Options[toggleInfo.Flag] = toggleState
                    end
                end

                toggleFrame.ClickArea.MouseButton1Click:Connect(function()
                    toggleState:Set(not toggleState.Value)
                end)

                toggleFrame.ClickArea.MouseEnter:Connect(function()
                    LRXUI:Tween(toggleFrame, { BackgroundColor3 = LRXUI.Scheme.CardHoverColor }, 0.15)
                end)
                toggleFrame.ClickArea.MouseLeave:Connect(function()
                    LRXUI:Tween(toggleFrame, { BackgroundColor3 = LRXUI.Scheme.CardColor }, 0.15)
                end)

                if toggleInfo.Flag then
                    LRXUI.Options[toggleInfo.Flag] = toggleState
                end

                return toggleState
            end

            function SectionElements:AddButton(buttonInfo)
                buttonInfo = buttonInfo or {}
                buttonInfo.Name = buttonInfo.Name or "Button"
                buttonInfo.Callback = buttonInfo.Callback or function() end

                local buttonFrame = LRXUI:SetChildren(LRXUI:Create("TextButton", {
                    BackgroundColor3 = LRXUI.Scheme.CardColor,
                    Size = UDim2.new(1, 0, 0, 36),
                    Name = buttonInfo.Name,
                    AutoButtonColor = false,
                    Parent = sectionFrame,
                    BorderSizePixel = 0,
                }, {
                    LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    LRXUI:Create("UIStroke", { Color = LRXUI.Scheme.OutlineColor, Thickness = 1 }),
                }), {
                    LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                        Text = buttonInfo.Name,
                        Font = LRXUI.Scheme.FontBold,
                        TextSize = 14,
                        Size = UDim2.new(1, 0, 1, 0),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        BackgroundTransparency = 1,
                        TextColor3 = LRXUI.Scheme.FontColor,
                    }),
                })

                buttonFrame.MouseButton1Click:Connect(function()
                    LRXUI:SafeCallback(buttonInfo.Callback)
                end)

                buttonFrame.MouseEnter:Connect(function()
                    LRXUI:Tween(buttonFrame, { BackgroundColor3 = LRXUI.Scheme.CardHoverColor }, 0.15)
                end)
                buttonFrame.MouseLeave:Connect(function()
                    LRXUI:Tween(buttonFrame, { BackgroundColor3 = LRXUI.Scheme.CardColor }, 0.15)
                end)

                return buttonFrame
            end

            function SectionElements:AddLabel(labelInfo)
                labelInfo = labelInfo or {}
                labelInfo.Text = labelInfo.Text or "Label"

                local label = LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                    Text = labelInfo.Text,
                    Font = LRXUI.Scheme.Font,
                    TextColor3 = LRXUI.Scheme.FontColorSecondary,
                    TextSize = 13,
                    Size = UDim2.new(1, 0, 0, 20),
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = sectionFrame,
                })

                local labelObj = {}
                function labelObj:Set(text)
                    label.Text = text
                end

                return labelObj
            end

            function SectionElements:AddDropdown(dropdownInfo)
                dropdownInfo = dropdownInfo or {}
                dropdownInfo.Name = dropdownInfo.Name or "Dropdown"
                dropdownInfo.Options = dropdownInfo.Options or {}
                dropdownInfo.Default = dropdownInfo.Default or ""
                dropdownInfo.Callback = dropdownInfo.Callback or function() end
                dropdownInfo.Flag = dropdownInfo.Flag or nil

                local dropdownState = {
                    Value = dropdownInfo.Default,
                    Options = dropdownInfo.Options,
                    Toggled = false,
                    Type = "Dropdown",
                }

                local dropdownFrame = LRXUI:SetChildren(LRXUI:Create("Frame", {
                    BackgroundColor3 = LRXUI.Scheme.CardColor,
                    Size = UDim2.new(1, 0, 0, 40),
                    ClipsDescendants = true,
                    Name = dropdownInfo.Name,
                    BorderSizePixel = 0,
                    Parent = sectionFrame,
                }, {
                    LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    LRXUI:Create("UIStroke", { Color = LRXUI.Scheme.OutlineColor, Thickness = 1 }),
                }), {
                    LRXUI:SetChildren(LRXUI:Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 40),
                        BackgroundTransparency = 1,
                        Name = "Header",
                    }, {}), {
                        LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                            Text = dropdownInfo.Name,
                            Font = LRXUI.Scheme.Font,
                            TextSize = 14,
                            Size = UDim2.new(1, -100, 1, 0),
                            Position = UDim2.new(0, 12, 0, 0),
                            Name = "Label",
                            BackgroundTransparency = 1,
                            TextColor3 = LRXUI.Scheme.FontColor,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        }),
                        LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                            Text = dropdownInfo.Default ~= "" and dropdownInfo.Default or "Select...",
                            Font = LRXUI.Scheme.Font,
                            TextColor3 = LRXUI.Scheme.FontColorSecondary,
                            TextSize = 13,
                            Size = UDim2.new(0, 80, 1, 0),
                            Position = UDim2.new(1, -92, 0, 0),
                            TextXAlignment = Enum.TextXAlignment.Right,
                            Name = "Selected",
                            BackgroundTransparency = 1,
                        }),
                        LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                            Text = "▼",
                            Font = LRXUI.Scheme.Font,
                            TextColor3 = LRXUI.Scheme.FontColorSecondary,
                            TextSize = 12,
                            Size = UDim2.new(0, 20, 1, 0),
                            Position = UDim2.new(1, -24, 0, 0),
                            TextXAlignment = Enum.TextXAlignment.Center,
                            Name = "Arrow",
                            BackgroundTransparency = 1,
                        }),
                        LRXUI:SetProps(LRXUI:Create("TextButton"), {
                            Size = UDim2.new(1, 0, 0, 40),
                            BackgroundTransparency = 1,
                            Name = "ClickArea",
                            AutoButtonColor = false,
                        }),
                    }),
                    LRXUI:SetChildren(LRXUI:Create("Frame", {
                        Size = UDim2.new(1, 0, 1, -40),
                        Position = UDim2.new(0, 0, 0, 40),
                        BackgroundTransparency = 1,
                        Name = "OptionsContainer",
                    }, {
                        LRXUI:Create("UIListLayout", {
                            Padding = UDim.new(0, 2),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                        }),
                        LRXUI:Create("UIPadding", {
                            PaddingLeft = UDim.new(0, 8),
                            PaddingRight = UDim.new(0, 8),
                            PaddingTop = UDim.new(0, 4),
                            PaddingBottom = UDim.new(0, 4),
                        }),
                    }), {}),
                })

                local optionsContainer = dropdownFrame.OptionsContainer
                local optionButtons = {}

                local function BuildOptions()
                    for _, btn in ipairs(optionButtons) do
                        btn:Destroy()
                    end
                    table.clear(optionButtons)

                    for _, option in ipairs(dropdownState.Options) do
                        local optBtn = LRXUI:SetProps(LRXUI:Create("TextButton", {
                            Text = option,
                            Font = LRXUI.Scheme.Font,
                            TextColor3 = LRXUI.Scheme.FontColorSecondary,
                            TextSize = 13,
                            Size = UDim2.new(1, 0, 0, 28),
                            BackgroundColor3 = LRXUI.Scheme.DropdownBg,
                            BackgroundTransparency = 1,
                            AutoButtonColor = false,
                            Parent = optionsContainer,
                            BorderSizePixel = 0,
                        }), {
                            LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                        })
                        table.insert(optionButtons, optBtn)

                        optBtn.MouseButton1Click:Connect(function()
                            dropdownState.Value = option
                            dropdownFrame.Header.Selected.Text = option
                            dropdownState:Set(false)
                            LRXUI:SafeCallback(dropdownInfo.Callback, option)
                        end)

                        optBtn.MouseEnter:Connect(function()
                            LRXUI:Tween(optBtn, { BackgroundTransparency = 0 }, 0.1)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            LRXUI:Tween(optBtn, { BackgroundTransparency = 1 }, 0.1)
                        end)
                    end
                end

                function dropdownState:Set(open)
                    self.Toggled = open
                    local targetSize = open and UDim2.new(1, 0, 0, 40 + math.min(#self.Options * 30, 150)) or UDim2.new(1, 0, 0, 40)
                    LRXUI:Tween(dropdownFrame, { Size = targetSize }, 0.2)
                    LRXUI:Tween(dropdownFrame.Header.Arrow, { Rotation = open and 180 or 0 }, 0.2)
                end

                dropdownFrame.Header.ClickArea.MouseButton1Click:Connect(function()
                    dropdownState:Set(not dropdownState.Toggled)
                end)

                BuildOptions()

                function dropdownState:Refresh(newOptions)
                    self.Options = newOptions
                    BuildOptions()
                end

                if dropdownInfo.Flag then
                    LRXUI.Options[dropdownInfo.Flag] = dropdownState
                end

                return dropdownState
            end

            function SectionElements:AddSlider(sliderInfo)
                sliderInfo = sliderInfo or {}
                sliderInfo.Name = sliderInfo.Name or "Slider"
                sliderInfo.Min = sliderInfo.Min or 0
                sliderInfo.Max = sliderInfo.Max or 100
                sliderInfo.Default = sliderInfo.Default or sliderInfo.Min
                sliderInfo.Increment = sliderInfo.Increment or 1
                sliderInfo.ValueName = sliderInfo.ValueName or ""
                sliderInfo.Callback = sliderInfo.Callback or function() end
                sliderInfo.Flag = sliderInfo.Flag or nil

                local sliderState = { Value = sliderInfo.Default }
                local dragging = false

                local sliderFrame = LRXUI:SetChildren(LRXUI:Create("Frame", {
                    BackgroundColor3 = LRXUI.Scheme.CardColor,
                    Size = UDim2.new(1, 0, 0, 50),
                    Name = sliderInfo.Name,
                    BorderSizePixel = 0,
                    Parent = sectionFrame,
                }, {
                    LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    LRXUI:Create("UIStroke", { Color = LRXUI.Scheme.OutlineColor, Thickness = 1 }),
                }), {
                    LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                        Text = sliderInfo.Name,
                        Font = LRXUI.Scheme.Font,
                        TextSize = 14,
                        Size = UDim2.new(1, -60, 0, 20),
                        Position = UDim2.new(0, 12, 0, 6),
                        Name = "Label",
                        BackgroundTransparency = 1,
                        TextColor3 = LRXUI.Scheme.FontColor,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }),
                    LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                        Text = tostring(sliderInfo.Default) .. " " .. sliderInfo.ValueName,
                        Font = LRXUI.Scheme.Font,
                        TextColor3 = LRXUI.Scheme.FontColorSecondary,
                        TextSize = 13,
                        Size = UDim2.new(0, 60, 0, 20),
                        Position = UDim2.new(1, -68, 0, 6),
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Name = "ValueLabel",
                        BackgroundTransparency = 1,
                    }),
                    LRXUI:SetChildren(LRXUI:Create("Frame", {
                        Size = UDim2.new(1, -24, 0, 6),
                        Position = UDim2.new(0, 12, 0, 32),
                        BackgroundColor3 = LRXUI.Scheme.ToggleBg,
                        Name = "Bar",
                        BorderSizePixel = 0,
                    }, {
                        LRXUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    }), {
                        LRXUI:SetProps(LRXUI:Create("Frame"), {
                            Size = UDim2.new((sliderInfo.Default - sliderInfo.Min) / (sliderInfo.Max - sliderInfo.Min), 0, 1, 0),
                            BackgroundColor3 = LRXUI.Scheme.AccentColor,
                            Name = "Fill",
                            BorderSizePixel = 0,
                        }), {
                            LRXUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                        }),
                    }),
                    LRXUI:SetProps(LRXUI:Create("TextButton"), {
                        Size = UDim2.new(1, 0, 0, 50),
                        BackgroundTransparency = 1,
                        Name = "ClickArea",
                        AutoButtonColor = false,
                    }),
                })

                local bar = sliderFrame.Bar
                local fill = bar.Fill

                function sliderState:Set(value)
                    self.Value = math.clamp(
                        math.floor((value - sliderInfo.Min) / sliderInfo.Increment + 0.5) * sliderInfo.Increment + sliderInfo.Min,
                        sliderInfo.Min,
                        sliderInfo.Max
                    )
                    local scale = (self.Value - sliderInfo.Min) / (sliderInfo.Max - sliderInfo.Min)
                    LRXUI:Tween(fill, { Size = UDim2.new(scale, 0, 1, 0) }, 0.15)
                    sliderFrame.ValueLabel.Text = tostring(self.Value) .. " " .. sliderInfo.ValueName
                    LRXUI:SafeCallback(sliderInfo.Callback, self.Value)
                end

                sliderFrame.ClickArea.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                    end
                end)

                sliderFrame.ClickArea.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local scale = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                        local value = sliderInfo.Min + (sliderInfo.Max - sliderInfo.Min) * scale
                        sliderState:Set(value)
                    end
                end)

                if sliderInfo.Flag then
                    LRXUI.Options[sliderInfo.Flag] = sliderState
                end

                return sliderState
            end

            function SectionElements:AddTextBox(textboxInfo)
                textboxInfo = textboxInfo or {}
                textboxInfo.Name = textboxInfo.Name or "TextBox"
                textboxInfo.Default = textboxInfo.Default or ""
                textboxInfo.Placeholder = textboxInfo.Placeholder or "Enter text..."
                textboxInfo.Callback = textboxInfo.Callback or function() end

                local textboxFrame = LRXUI:SetChildren(LRXUI:Create("Frame", {
                    BackgroundColor3 = LRXUI.Scheme.CardColor,
                    Size = UDim2.new(1, 0, 0, 40),
                    Name = textboxInfo.Name,
                    BorderSizePixel = 0,
                    Parent = sectionFrame,
                }, {
                    LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    LRXUI:Create("UIStroke", { Color = LRXUI.Scheme.OutlineColor, Thickness = 1 }),
                }), {
                    LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                        Text = textboxInfo.Name,
                        Font = LRXUI.Scheme.Font,
                        TextSize = 14,
                        Size = UDim2.new(0.4, 0, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Name = "Label",
                        BackgroundTransparency = 1,
                        TextColor3 = LRXUI.Scheme.FontColor,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }),
                    LRXUI:SetProps(LRXUI:Create("TextBox"), {
                        Text = textboxInfo.Default,
                        PlaceholderText = textboxInfo.Placeholder,
                        Font = LRXUI.Scheme.Font,
                        TextSize = 13,
                        Size = UDim2.new(0.55, -12, 0, 28),
                        Position = UDim2.new(0.45, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = LRXUI.Scheme.DropdownBg,
                        TextColor3 = LRXUI.Scheme.FontColor,
                        ClearTextOnFocus = false,
                        Parent = textboxFrame,
                        BorderSizePixel = 0,
                    }, {
                        LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                        LRXUI:Create("UIPadding", {
                            PaddingLeft = UDim.new(0, 8),
                            PaddingRight = UDim.new(0, 8),
                        }),
                    }),
                })

                local textBox = textboxFrame:FindFirstChildWhichIsA("TextBox")

                textBox.FocusLost:Connect(function()
                    LRXUI:SafeCallback(textboxInfo.Callback, textBox.Text)
                end)

                return textBox
            end

            function SectionElements:AddKeybind(keybindInfo)
                keybindInfo = keybindInfo or {}
                keybindInfo.Name = keybindInfo.Name or "Keybind"
                keybindInfo.Default = keybindInfo.Default or Enum.KeyCode.Unknown
                keybindInfo.Callback = keybindInfo.Callback or function() end
                keybindInfo.Flag = keybindInfo.Flag or nil

                local keybindState = { Value = keybindInfo.Default, Binding = false }

                local keybindFrame = LRXUI:SetChildren(LRXUI:Create("Frame", {
                    BackgroundColor3 = LRXUI.Scheme.CardColor,
                    Size = UDim2.new(1, 0, 0, 40),
                    Name = keybindInfo.Name,
                    BorderSizePixel = 0,
                    Parent = sectionFrame,
                }, {
                    LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    LRXUI:Create("UIStroke", { Color = LRXUI.Scheme.OutlineColor, Thickness = 1 }),
                }), {
                    LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                        Text = keybindInfo.Name,
                        Font = LRXUI.Scheme.Font,
                        TextSize = 14,
                        Size = UDim2.new(1, -80, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Name = "Label",
                        BackgroundTransparency = 1,
                        TextColor3 = LRXUI.Scheme.FontColor,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }),
                    LRXUI:SetChildren(LRXUI:Create("TextButton", {
                        Size = UDim2.new(0, 60, 0, 26),
                        Position = UDim2.new(1, -70, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = LRXUI.Scheme.DropdownBg,
                        Name = "BindBox",
                        AutoButtonColor = false,
                        Parent = keybindFrame,
                        BorderSizePixel = 0,
                    }, {
                        LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    }), {
                        LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                            Text = keybindInfo.Default.Name ~= "Unknown" and keybindInfo.Default.Name or "None",
                            Font = LRXUI.Scheme.FontBold,
                            TextSize = 12,
                            Size = UDim2.new(1, 0, 1, 0),
                            TextXAlignment = Enum.TextXAlignment.Center,
                            Name = "Value",
                            BackgroundTransparency = 1,
                            TextColor3 = LRXUI.Scheme.FontColor,
                        }),
                    }),
                })

                local bindBox = keybindFrame.BindBox
                local valueLabel = bindBox.Value

                function keybindState:Set(key)
                    self.Binding = false
                    self.Value = key or self.Value
                    valueLabel.Text = self.Value.Name ~= "Unknown" and self.Value.Name or "None"
                    LRXUI:SafeCallback(keybindInfo.Callback, self.Value)
                end

                bindBox.MouseButton1Click:Connect(function()
                    if keybindState.Binding then return end
                    keybindState.Binding = true
                    valueLabel.Text = "..."
                end)

                LRXUI:GiveSignal(UserInputService.InputBegan:Connect(function(input)
                    if UserInputService:GetFocusedTextBox() then return end
                    if keybindState.Binding then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            keybindState:Set(input.KeyCode)
                        end
                    elseif input.KeyCode == keybindState.Value then
                        LRXUI:SafeCallback(keybindInfo.Callback)
                    end
                end))

                if keybindInfo.Flag then
                    LRXUI.Options[keybindInfo.Flag] = keybindState
                end

                return keybindState
            end

            function SectionElements:AddParagraph(paragraphInfo)
                paragraphInfo = paragraphInfo or {}
                paragraphInfo.Title = paragraphInfo.Title or "Title"
                paragraphInfo.Content = paragraphInfo.Content or "Content"

                local paragraphFrame = LRXUI:SetChildren(LRXUI:Create("Frame", {
                    BackgroundColor3 = LRXUI.Scheme.CardColor,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Name = paragraphInfo.Title,
                    BorderSizePixel = 0,
                    Parent = sectionFrame,
                }, {
                    LRXUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    LRXUI:Create("UIStroke", { Color = LRXUI.Scheme.OutlineColor, Thickness = 1 }),
                    LRXUI:Create("UIPadding", {
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        PaddingTop = UDim.new(0, 10),
                        PaddingBottom = UDim.new(0, 10),
                    }),
                }), {
                    LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                        Text = paragraphInfo.Title,
                        Font = LRXUI.Scheme.FontBold,
                        TextSize = 15,
                        Size = UDim2.new(1, 0, 0, 18),
                        Name = "Title",
                        BackgroundTransparency = 1,
                        TextColor3 = LRXUI.Scheme.FontColor,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }),
                    LRXUI:SetProps(LRXUI:Create("TextLabel"), {
                        Text = paragraphInfo.Content,
                        Font = LRXUI.Scheme.Font,
                        TextColor3 = LRXUI.Scheme.FontColorSecondary,
                        TextSize = 13,
                        Size = UDim2.new(1, 0, 0, 0),
                        Position = UDim2.new(0, 0, 0, 22),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        TextWrapped = true,
                        Name = "Content",
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }),
                })

                local paragraphObj = {}
                function paragraphObj:Set(content)
                    paragraphFrame.Content.Text = content
                end

                return paragraphObj
            end

            return SectionElements
        end

        return ElementBuilder
    end

    local Window = {
        Frame = mainFrame,
        AddTab = TabSystem.AddTab,
    }

    return Window
end

getgenv().LRXUI = LRXUI
return LRXUI