local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "_hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = titleBar

-- Status Label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 30)
status.Position = UDim2.new(0, 10, 0, 60)
status.BackgroundTransparency = 1
status.Text = "Status: Waiting..."
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 18
status.Font = Enum.Font.Gotham
status.Parent = frame

-- Button
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 40)
button.Position = UDim2.new(0.5, -100, 1, -60)
button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
button.Text = "Click Me"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 18
button.Font = Enum.Font.GothamBold
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

button.MouseButton1Click:Connect(function()
	status.Text = "Status: Button Clicked!"
end)

-- Dragging
local dragDetector = Instance.new("UIDragDetector")
dragDetector.Parent = frame -- Change to frame if you want the whole UI draggable

dragDetector.ResponseStyle = Enum.UIDragDetectorResponseStyle.Offset
dragDetector.DragStyle = Enum.UIDragDetectorDragStyle.TranslatePlane