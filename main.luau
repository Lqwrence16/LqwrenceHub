local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- SCREEN GUI
--------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

--------------------------------------------------
-- ICON
--------------------------------------------------

local open = false

local icon = Instance.new("ImageButton")
icon.Size = UDim2.new(0, 60, 0, 60)
icon.Position = UDim2.new(0, 20, 0.5, -30)
icon.BackgroundColor3 = Color3.fromRGB(20,20,20)
icon.BorderSizePixel = 0
icon.AutoButtonColor = false
icon.ZIndex = 100
icon.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1,0)
iconCorner.Parent = icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(100,100,255)
iconStroke.Thickness = 2
iconStroke.Parent = icon

local iconText = Instance.new("TextLabel")
iconText.Size = UDim2.new(1,0,1,0)
iconText.BackgroundTransparency = 1
iconText.Text = "L"
iconText.TextScaled = true
iconText.Font = Enum.Font.GothamBold
iconText.TextColor3 = Color3.new(1,1,1)
iconText.ZIndex = 101
iconText.Parent = icon

--------------------------------------------------
-- MAIN FRAME
--------------------------------------------------

local defaultSize = UDim2.new(0,300,0,200)
local savedSize = defaultSize
local savedPosition = UDim2.new(0.5,-150,0.5,-100)

local frame = Instance.new("Frame")
frame.Size = defaultSize
frame.Position = savedPosition
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0,10)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(65,65,65)
frameStroke.Thickness = 1
frameStroke.Parent = frame

--------------------------------------------------
-- TITLE BAR
--------------------------------------------------

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,35)
titleBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
titleBar.BorderSizePixel = 0
titleBar.ClipsDescendants = true
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0,10)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "_hub"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = titleBar

--------------------------------------------------
-- FRAME DRAGGING
--------------------------------------------------

local frameDragDetector = Instance.new("UIDragDetector")
frameDragDetector.Parent = frame

frameDragDetector.ResponseStyle =
	Enum.UIDragDetectorResponseStyle.Offset

frameDragDetector.DragStyle =
	Enum.UIDragDetectorDragStyle.TranslatePlane

frameDragDetector.DragEnd:Connect(function()
	savedPosition = frame.Position
end)

--------------------------------------------------
-- RESIZE HANDLE
--------------------------------------------------

local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0,18,0,18)
resizeHandle.AnchorPoint = Vector2.new(1,1)
resizeHandle.Position = UDim2.new(1,-4,1,-4)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = "◢"
resizeHandle.TextSize = 14
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.TextColor3 = Color3.fromRGB(180,180,180)
resizeHandle.ZIndex = 50
resizeHandle.Parent = frame

local resizing = false
local startPos
local startSize

resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		resizing = true
		frameDragDetector.Enabled = false

		startPos = input.Position
		startSize = frame.Size
	end
end)

UIS.InputEnded:Connect(function(input)
	if resizing and (
		input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		) then
		resizing = false
		frameDragDetector.Enabled = true

		savedSize = frame.Size
		savedPosition = frame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if resizing and (
		input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then

		local delta = input.Position - startPos

		frame.Size = UDim2.new(
			0,
			math.max(200, startSize.X.Offset + delta.X),
			0,
			math.max(120, startSize.Y.Offset + delta.Y)
		)
	end
end)

--------------------------------------------------
-- ICON DRAGGING
--------------------------------------------------

local draggingIcon = false
local iconDragStart
local iconStartPos
local moved = false

icon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		draggingIcon = true
		moved = false

		iconDragStart = input.Position
		iconStartPos = icon.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if draggingIcon and (
		input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then

		local delta = input.Position - iconDragStart

		if delta.Magnitude > 20 then
			moved = true
		end

		icon.Position = UDim2.new(
			iconStartPos.X.Scale,
			iconStartPos.X.Offset + delta.X,
			iconStartPos.Y.Scale,
			iconStartPos.Y.Offset + delta.Y
		)
	end
end)

--------------------------------------------------
-- OPEN/CLOSE
--------------------------------------------------

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		if draggingIcon then
			draggingIcon = false

			if moved then
				return
			end

			if open then
				open = false
				frame.Visible = false
				return
			end

			open = true

			frame.Visible = true
			frame.Size = UDim2.new(0,0,0,0)

			frame.Position = UDim2.new(
				savedPosition.X.Scale,
				savedPosition.X.Offset,
				savedPosition.Y.Scale,
				savedPosition.Y.Offset + 30
			)

			TweenService:Create(
				frame,
				TweenInfo.new(
					0.25,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),
				{
					Size = savedSize,
					Position = savedPosition
				}
			):Play()
		end
	end
end)