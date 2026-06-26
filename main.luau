local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local WINDOW_SIZE = UDim2.new(0, 400, 0, 250)
local TOPBAR_HEIGHT = 35

local ICON_SIZE = 60
local HOVER_SIZE = 75

--------------------------------------------------
-- SCREEN GUI
--------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "_Hub"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

--------------------------------------------------
-- MAIN WINDOW
--------------------------------------------------

local frame = Instance.new("Frame")
frame.Size = WINDOW_SIZE
frame.Position = UDim2.new(
	0.5,
	-WINDOW_SIZE.X.Offset / 2,
	0.5,
	-WINDOW_SIZE.Y.Offset / 2
)
frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

--------------------------------------------------
-- TOP BAR
--------------------------------------------------

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT)
topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
topBar.BorderSizePixel = 0
topBar.Parent = frame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

--------------------------------------------------
-- TITLE
--------------------------------------------------

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "_Hub"
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.Parent = topBar

--------------------------------------------------
-- CLOSE BUTTON
--------------------------------------------------

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 2)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

--------------------------------------------------
-- MAIN BUTTON
--------------------------------------------------

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.8, 0, 0, 50)
button.Position = UDim2.new(0.1, 0, 0.5, 0)
button.Text = "Click Me"
button.TextScaled = true
button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
button.TextColor3 = Color3.new(1,1,1)
button.BorderSizePixel = 0
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = button

--------------------------------------------------
-- BUTTON TOGGLE
--------------------------------------------------

local clicked = false

button.MouseButton1Click:Connect(function()
	clicked = not clicked

	if clicked then
		button.Text = "Clicked!"
	else
		button.Text = "Click Me"
	end
end)

--------------------------------------------------
-- DRAG MAIN WINDOW
--------------------------------------------------

local draggingWindow = false
local dragStart
local startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWindow = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

topBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWindow = false
	end
end)

--------------------------------------------------
-- ICON BUTTON
--------------------------------------------------

local iconButton = Instance.new("TextButton")
iconButton.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
iconButton.Position = UDim2.new(0, 20, 1, -90)
iconButton.Text = "UI"
iconButton.TextScaled = true
iconButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
iconButton.TextColor3 = Color3.new(1,1,1)
iconButton.BorderSizePixel = 0
iconButton.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent = iconButton

--------------------------------------------------
-- HOVER ANIMATION
--------------------------------------------------

local hoverIn = TweenService:Create(
	iconButton,
	TweenInfo.new(0.15),
	{
		Size = UDim2.new(0, HOVER_SIZE, 0, HOVER_SIZE)
	}
)

local hoverOut = TweenService:Create(
	iconButton,
	TweenInfo.new(0.15),
	{
		Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	}
)

iconButton.MouseEnter:Connect(function()
	hoverIn:Play()
end)

iconButton.MouseLeave:Connect(function()
	hoverOut:Play()
end)

--------------------------------------------------
-- DRAG ICON
--------------------------------------------------

local draggingIcon = false
local iconDragStart
local iconStartPos
local moved = false

iconButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingIcon = true
		moved = false
		iconDragStart = input.Position
		iconStartPos = iconButton.Position
	end
end)

iconButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingIcon = false

		if not moved then
			frame.Visible = not frame.Visible
		end
	end
end)

--------------------------------------------------
-- INPUT CHANGED
--------------------------------------------------

UIS.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	-- Drag window
	if draggingWindow then
		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	-- Drag icon
	if draggingIcon then
		local delta = input.Position - iconDragStart

		if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
			moved = true
		end

		iconButton.Position = UDim2.new(
			iconStartPos.X.Scale,
			iconStartPos.X.Offset + delta.X,
			iconStartPos.Y.Scale,
			iconStartPos.Y.Offset + delta.Y
		)
	end
end)

--------------------------------------------------
-- CLOSE BUTTON
--------------------------------------------------

closeButton.MouseButton1Click:Connect(function()
	frame.Visible = false
end)