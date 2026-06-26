local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "_Hub"
screenGui.Parent = playerGui

--------------------------------------------------
-- MAIN WINDOW
--------------------------------------------------

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
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
topBar.Size = UDim2.new(1, 0, 0, 35)
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
title.TextColor3 = Color3.fromRGB(255, 255, 255)
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
closeButton.TextColor3 = Color3.new(1, 1, 1)
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
button.Font = Enum.Font.SourceSans
button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
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

local dragging = false
local dragStart
local startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

--------------------------------------------------
-- FLOATING ICON
--------------------------------------------------

local iconButton = Instance.new("TextButton")
iconButton.Size = UDim2.new(0, 60, 0, 60)
iconButton.Position = UDim2.new(0, 20, 1, -80)
iconButton.Text = "UI"
iconButton.TextScaled = true
iconButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
iconButton.TextColor3 = Color3.fromRGB(255, 255, 255)
iconButton.BorderSizePixel = 0
iconButton.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = iconButton

--------------------------------------------------
-- HOVER EFFECT
--------------------------------------------------

local normalSize = UDim2.new(0, 60, 0, 60)
local hoverSize = UDim2.new(0, 70, 0, 70)

local hoverIn = TweenService:Create(
	iconButton,
	TweenInfo.new(0.15, Enum.EasingStyle.Quad),
	{Size = hoverSize}
)

local hoverOut = TweenService:Create(
	iconButton,
	TweenInfo.new(0.15, Enum.EasingStyle.Quad),
	{Size = normalSize}
)

--------------------------------------------------
-- DRAG ICON
--------------------------------------------------

local draggingIcon = false
local iconDragStart
local iconStartPos

iconButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingIcon = true

		hoverOut:Play()

		iconDragStart = input.Position
		iconStartPos = iconButton.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingIcon = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if draggingIcon and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - iconDragStart

		iconButton.Position = UDim2.new(
			iconStartPos.X.Scale,
			iconStartPos.X.Offset + delta.X,
			iconStartPos.Y.Scale,
			iconStartPos.Y.Offset + delta.Y
		)
	end
end)

--------------------------------------------------
-- ICON HOVER
--------------------------------------------------

iconButton.MouseEnter:Connect(function()
	if not draggingIcon then
		hoverIn:Play()
	end
end)

iconButton.MouseLeave:Connect(function()
	if not draggingIcon then
		hoverOut:Play()
	end
end)

--------------------------------------------------
-- TOGGLE UI
--------------------------------------------------

iconButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

closeButton.MouseButton1Click:Connect(function()
	frame.Visible = false
end)