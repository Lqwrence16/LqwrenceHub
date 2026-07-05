-- ═══════════════════════════════════════════════════════════════════════
--  LRX_Hub v2.2.2
--  Fixed: Scroll, Modal height, Loop errors, Grid Dots toggle
-- ═══════════════════════════════════════════════════════════════════════

--══════════════════════════════════════════════════════--
-- SERVICES
--══════════════════════════════════════════════════════--
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--══════════════════════════════════════════════════════--
-- CONFIGURATION
--══════════════════════════════════════════════════════--
local Config = {
	WindowWidth = 600,
	WindowHeight = 400,
	MinWindowWidth = 320,
	MinWindowHeight = 240,
	SidebarWidth = 170,
	ToggleButtonText = "LRX",
	Theme = "Dark",
	AnimationSpeed = 0.2,
	DisableAnimations = false,
	NotificationDuration = 3,
	ModalDarkening = 0.5,
	UIScale = 1.0,
	WindowPosition = nil,
	WindowSize = nil,

	-- Shop
	SelectedSeeds = {},
	EnableSeedShop = false,

	-- Seed Placer
	SelectedPlaceSeeds = {},
	EnableSeedPlacer = false,
	PlaceAmount = 10,
	PlantingArea = "Default",
	PlantingPattern = "LeftToRight",
	PlantSpacing = 1,
	PlantDelay = 0.05,

	-- Plot Visualizer
	ShowGridDots = false,

	ReduceEffects = false,
	Keybinds = { ToggleUI = "F" },
}

--══════════════════════════════════════════════════════--
-- THEMES
--══════════════════════════════════════════════════════--
local Themes = {
	Dark = {
		Background = Color3.fromRGB(22, 22, 26),
		Sidebar = Color3.fromRGB(28, 28, 32),
		Content = Color3.fromRGB(18, 18, 22),
		Card = Color3.fromRGB(35, 35, 40),
		CardHover = Color3.fromRGB(45, 45, 50),
		DropdownBg = Color3.fromRGB(32, 32, 38),
		TextPrimary = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(160, 160, 160),
		TextMuted = Color3.fromRGB(100, 100, 100),
		Accent = Color3.fromRGB(147, 112, 219),
		AccentPink = Color3.fromRGB(255, 105, 180),
		AccentCyan = Color3.fromRGB(0, 255, 255),
		AccentGreen = Color3.fromRGB(50, 205, 50),
		AccentRed = Color3.fromRGB(255, 80, 80),
		AccentYellow = Color3.fromRGB(255, 215, 0),
		Border = Color3.fromRGB(50, 50, 55),
		ToggleBg = Color3.fromRGB(60, 60, 65),
		ToggleOn = Color3.fromRGB(147, 112, 219),
		ScrollBar = Color3.fromRGB(60, 60, 70),
		Overlay = Color3.fromRGB(0, 0, 0),
	},
}

local Theme = Themes[Config.Theme]

--══════════════════════════════════════════════════════--
-- LASER VISUAL EFFECT
--══════════════════════════════════════════════════════--
local LaserBeams = {}
local LaserFolder = nil

local function EnsureLaserFolder()
	if not LaserFolder or not LaserFolder.Parent then
		LaserFolder = Instance.new("Folder")
		LaserFolder.Name = "LRX_Lasers"
		LaserFolder.Parent = workspace
	end
	return LaserFolder
end

local function ClearLasers()
	for _, beam in ipairs(LaserBeams) do
		if beam then
			pcall(function()
				beam:Destroy()
			end)
		end
	end
	table.clear(LaserBeams)
end

local function CreateLaserBeam(startPos, endPos, color, duration)
	local folder = EnsureLaserFolder()

	local beamPart = Instance.new("Part")
	beamPart.Name = "LaserBeam"
	beamPart.Anchored = true
	beamPart.CanCollide = false
	beamPart.CanQuery = false
	beamPart.CanTouch = false
	beamPart.CastShadow = false
	beamPart.Material = Enum.Material.Neon
	beamPart.Color = color or Theme.Accent
	beamPart.Transparency = 0.3
	beamPart.Size = Vector3.new(0.05, 0.05, (endPos - startPos).Magnitude)
	beamPart.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -beamPart.Size.Z / 2)
	beamPart.Parent = folder

	local glow = Instance.new("PointLight")
	glow.Color = beamPart.Color
	glow.Brightness = 2
	glow.Range = 6
	glow.Parent = beamPart

	table.insert(LaserBeams, beamPart)

	if duration then
		task.delay(duration, function()
			if beamPart then
				local tween = TweenService:Create(beamPart, TweenInfo.new(0.3), { Transparency = 1 })
				tween.Completed:Connect(function()
					pcall(function()
						beamPart:Destroy()
					end)
				end)
				tween:Play()
			end
		end)
	end

	return beamPart
end

local function LaserScanPlot(plot, scanDuration)
	ClearLasers()
	if not plot then
		return
	end

	local visual = plot:FindFirstChild("Visual")
	if not visual then
		return
	end

	local parts = {}
	for _, child in ipairs(visual:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^PlantAreaColumn") then
			table.insert(parts, child)
		end
	end
	if #parts == 0 then
		return
	end

	scanDuration = scanDuration or 1.5

	-- Find bounds
	local minY = math.huge
	local allCorners = {}
	for _, part in ipairs(parts) do
		minY = math.min(minY, part.Position.Y)
		local hs = part.Size / 2
		local cf = part.CFrame
		for dx = -1, 1, 2 do
			for dz = -1, 1, 2 do
				table.insert(allCorners, cf * Vector3.new(dx * hs.X, hs.Y, dz * hs.Z))
			end
		end
	end

	local center = Vector3.zero
	for _, c in ipairs(allCorners) do
		center = center + c
	end
	center = center / #allCorners

	-- Create sweeping horizontal lasers
	local sweepCount = 6
	local sweepHeight = minY + 2
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	for _, c in ipairs(allCorners) do
		minX = math.min(minX, c.X)
		maxX = math.max(maxX, c.X)
		minZ = math.min(minZ, c.Z)
		maxZ = math.max(maxZ, c.Z)
	end

	for i = 1, sweepCount do
		task.delay((i - 1) * (scanDuration / sweepCount), function()
			if not ScriptRunning then
				return
			end
			local t = (i - 1) / (sweepCount - 1)
			local z = minZ + (maxZ - minZ) * t
			local startPos = Vector3.new(minX, sweepHeight, z)
			local endPos = Vector3.new(maxX, sweepHeight, z)
			CreateLaserBeam(startPos, endPos, Color3.fromRGB(0, 255, 255), 0.4)

			-- Cross sweep
			local x = minX + (maxX - minX) * t
			local startPos2 = Vector3.new(x, sweepHeight + 0.5, minZ)
			local endPos2 = Vector3.new(x, sweepHeight + 0.5, maxZ)
			CreateLaserBeam(startPos2, endPos2, Color3.fromRGB(255, 0, 255), 0.4)
		end)
	end

	-- Corner-to-corner diagonal sweeps
	task.delay(0.1, function()
		CreateLaserBeam(
			Vector3.new(minX, sweepHeight, minZ),
			Vector3.new(maxX, sweepHeight, maxZ),
			Color3.fromRGB(50, 205, 50),
			0.6
		)
		CreateLaserBeam(
			Vector3.new(minX, sweepHeight, maxZ),
			Vector3.new(maxX, sweepHeight, minZ),
			Color3.fromRGB(50, 205, 50),
			0.6
		)
	end)

	-- Perimeter outline
	task.delay(scanDuration * 0.5, function()
		local h = sweepHeight
		local corners = {
			Vector3.new(minX, h, minZ),
			Vector3.new(maxX, h, minZ),
			Vector3.new(maxX, h, maxZ),
			Vector3.new(minX, h, maxZ),
		}
		for i = 1, 4 do
			local a = corners[i]
			local b = corners[i % 4 + 1]
			CreateLaserBeam(a, b, Color3.fromRGB(255, 215, 0), 0.8)
		end
	end)

	task.delay(scanDuration + 0.5, ClearLasers)
end

--══════════════════════════════════════════════════════--
-- GRID DOTS VISUAL
--══════════════════════════════════════════════════════--
local GridDots = {}
local DotsFolder = nil

local function EnsureDotsFolder()
	if not DotsFolder or not DotsFolder.Parent then
		DotsFolder = Instance.new("Folder")
		DotsFolder.Name = "LRX_GridDots"
		DotsFolder.Parent = workspace
	end
	return DotsFolder
end

local function ClearGridDots()
	for _, dot in ipairs(GridDots) do
		if dot then
			pcall(function()
				dot:Destroy()
			end)
		end
	end
	table.clear(GridDots)
end

local function ClearAllVisuals()
	ClearLasers()
	ClearGridDots()
end

-- Grid dot colors to match the image (green/yellow alternating)
local GridDotColors = {
	Color3.fromRGB(50, 205, 50), -- Green
	Color3.fromRGB(255, 215, 0), -- Yellow
	Color3.fromRGB(0, 255, 127), -- Spring Green
	Color3.fromRGB(255, 165, 0), -- Orange
}

local function RefreshGridDots()
	ClearGridDots()
	if not Config.ShowGridDots then
		return
	end

	local plot = SeedPlacer:FindPlayerPlot()
	if not plot then
		return
	end

	-- Ensure positions are generated
	SeedPlacer:ClearCache()
	local positions = SeedPlacer:GetPlantPositions()
	if not positions or #positions == 0 then
		return
	end

	local folder = EnsureDotsFolder()
	local maxDots = math.min(#positions, 800)
	local step = math.max(1, math.floor(#positions / maxDots))

	for i = 1, #positions, step do
		local posData = positions[i]
		local dot = Instance.new("Part")
		dot.Name = "GridDot"
		dot.Anchored = true
		dot.CanCollide = false
		dot.CanQuery = false
		dot.CanTouch = false
		dot.CastShadow = false
		dot.Material = Enum.Material.Neon
		-- Alternate colors for visual variety like the image
		dot.Color = GridDotColors[((i - 1) % #GridDotColors) + 1]
		dot.Shape = Enum.PartType.Ball
		dot.Size = Vector3.new(0.15, 0.15, 0.15)
		-- Slightly above ground so it doesn't z-fight
		dot.Position = posData.Pos + Vector3.new(0, 0.15, 0)
		dot.Parent = folder
		dot.Transparency = 0.2

		
		table.insert(GridDots, dot)
	end

	Notify("Plot Visualizer", string.format("Showing %d grid dots", #GridDots), "Success", 2)
end

--══════════════════════════════════════════════════════--
-- STATE
--══════════════════════════════════════════════════════--
local ScriptRunning = true
local Connections = {}
local Tasks = {}
local ActiveNotifs = 0
local CurrentPage = "Home"
local SidebarButtons = {}
local Pages = {}
local SearchableItems = {}

local ActiveDropdownCard = nil
local ActiveDropdownFrame = nil
local DropdownDebounce = false

local ModalOverlay = nil
local ActiveModal = nil
local ModalOpen = false

local CardOrder = 0
local AutoSaveDebounce = nil

--══════════════════════════════════════════════════════--
-- UTILITIES
--══════════════════════════════════════════════════════--
local function AddConnection(eventConnection)
	table.insert(Connections, eventConnection)
	return eventConnection
end

local function DisconnectAll()
	for _, connection in ipairs(Connections) do
		if connection and connection.Connected then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	table.clear(Connections)
end

local function Tween(instance, properties, duration, callback)
	if Config.DisableAnimations then
		for key, value in pairs(properties) do
			instance[key] = value
		end
		if callback then
			callback()
		end
		return
	end
	local activeTween = TweenService:Create(
		instance,
		TweenInfo.new(duration or Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		properties
	)
	if callback then
		activeTween.Completed:Connect(callback)
	end
	activeTween:Play()
end

local function Create(className, properties)
	local newInstance = Instance.new(className)
	for property, value in pairs(properties or {}) do
		newInstance[property] = value
	end
	return newInstance
end

local function Corner(instance, radius)
	local newCorner = Instance.new("UICorner")
	newCorner.CornerRadius = UDim.new(0, radius or 6)
	newCorner.Parent = instance
end

local function Stroke(instance, color, thickness)
	local newStroke = Instance.new("UIStroke")
	newStroke.Color = color or Theme.Border
	newStroke.Thickness = thickness or 1
	newStroke.Parent = instance
end

local function FormatSelectedSeeds(selectedTable, maxDisplay)
	local names = {}
	for seedName, selected in pairs(selectedTable) do
		if selected then
			table.insert(names, seedName)
		end
	end
	table.sort(names)

	local shown = {}
	local displayLimit = maxDisplay or 10
	for i = 1, math.min(#names, displayLimit) do
		table.insert(shown, names[i])
	end

	local text = table.concat(shown, ", ")
	if #names > displayLimit then
		text = text .. "..."
	end
	if text == "" then
		text = "None"
	end

	return string.format("Selected (%d): %s", #names, text)
end

--══════════════════════════════════════════════════════--
-- AUTO JSON FILTER
--══════════════════════════════════════════════════════--
local CONFIG_FILE = "LRX_Hub_Config.json"
local CONFIG_ATTRIBUTE = "LRX_Hub_Config"

local function IsBasicSerializable(value)
	local valueType = typeof(value)
	return valueType == "nil" or valueType == "boolean" or valueType == "number" or valueType == "string"
end

local function FilterSerializable(data)
	if typeof(data) ~= "table" then
		return IsBasicSerializable(data) and data or nil
	end
	local result = {}
	for key, value in pairs(data) do
		if typeof(key) == "string" or typeof(key) == "number" then
			if typeof(value) == "table" then
				result[key] = FilterSerializable(value)
			elseif IsBasicSerializable(value) then
				result[key] = value
			end
		end
	end
	return result
end

local function BuildSaveData()
	return FilterSerializable(Config)
end

local function ApplyLoadedData(data)
	if typeof(data) ~= "table" then
		return false
	end
	for key, value in pairs(data) do
		if typeof(key) == "string" then
			Config[key] = value
		end
	end
	return true
end

--══════════════════════════════════════════════════════--
-- SAVE SYSTEM
--══════════════════════════════════════════════════════--
function SaveConfig(silent)
	local saveTable = BuildSaveData()
	local jsonString
	local success, errorMessage = pcall(function()
		jsonString = HttpService:JSONEncode(saveTable)
	end)
	if not success then
		warn("[Config] JSON Encode failed:", errorMessage)
		return false, "encode_failed"
	end

	if writefile then
		local fileOk = pcall(function()
			writefile(CONFIG_FILE, jsonString)
		end)
		if fileOk then
			if not silent then
				Notify("Config", "Saved to file!", "Success", 2)
			end
			return true, "file"
		end
	end

	local attrOk = pcall(function()
		player:SetAttribute(CONFIG_ATTRIBUTE, jsonString)
	end)
	if attrOk then
		if not silent then
			Notify("Config", "Saved (attribute)", "Info", 2)
		end
		return true, "attribute"
	end

	local valOk = pcall(function()
		local existing = playerGui:FindFirstChild(CONFIG_ATTRIBUTE)
		if existing then
			existing:Destroy()
		end
		local val = Instance.new("StringValue")
		val.Name = CONFIG_ATTRIBUTE
		val.Value = jsonString
		val.Parent = playerGui
	end)
	if valOk then
		if not silent then
			Notify("Config", "Saved (StringValue)", "Info", 2)
		end
		return true, "stringvalue"
	end

	Notify("Config", "Failed to save", "Error", 3)
	return false, "none"
end

--══════════════════════════════════════════════════════--
-- LOAD SYSTEM
--══════════════════════════════════════════════════════--
function LoadConfig()
	local jsonString = nil
	local method = "none"

	if isfile and isfile(CONFIG_FILE) then
		local success, result = pcall(readfile, CONFIG_FILE)
		if success and result and #result > 0 then
			jsonString = result
			method = "file"
		end
	end

	if not jsonString then
		local success, result = pcall(function()
			return player:GetAttribute(CONFIG_ATTRIBUTE)
		end)
		if success and result and typeof(result) == "string" and #result > 0 then
			jsonString = result
			method = "attribute"
		end
	end

	if not jsonString then
		local success, result = pcall(function()
			local val = playerGui:FindFirstChild(CONFIG_ATTRIBUTE)
			return val and val.Value
		end)
		if success and result and typeof(result) == "string" and #result > 0 then
			jsonString = result
			method = "stringvalue"
		end
	end

	if jsonString then
		local success, data = pcall(function()
			return HttpService:JSONDecode(jsonString)
		end)
		if success and data and ApplyLoadedData(data) then
			if Config.Theme and Themes[Config.Theme] then
				Theme = Themes[Config.Theme]
			end
			Notify("Config", "Loaded from " .. method, "Success", 2)
			return true, method
		end
	end
	return false, "none"
end

function ResetConfig()
	if delfile then
		pcall(function()
			delfile(CONFIG_FILE)
		end)
	end
	pcall(function()
		player:SetAttribute(CONFIG_ATTRIBUTE, nil)
	end)
	pcall(function()
		local val = playerGui:FindFirstChild(CONFIG_ATTRIBUTE)
		if val then
			val:Destroy()
		end
	end)

	Config = {
		WindowWidth = 600,
		WindowHeight = 400,
		MinWindowWidth = 320,
		MinWindowHeight = 240,
		SidebarWidth = 170,
		ToggleButtonText = "LRX",
		Theme = "Dark",
		AnimationSpeed = 0.2,
		DisableAnimations = false,
		NotificationDuration = 3,
		ModalDarkening = 0.5,
		UIScale = 1.0,
		WindowPosition = nil,
		WindowSize = nil,
		SelectedSeeds = {},
		EnableSeedShop = false,
		SelectedPlaceSeeds = {},
		EnableSeedPlacer = false,
		PlaceAmount = 10,
		PlantingArea = "Default",
		PlantingPattern = "LeftToRight",
		PlantSpacing = 1,
		PlantDelay = 0.05,
		ShowGridDots = false,
		ReduceEffects = false,
		Keybinds = { ToggleUI = "F" },
	}

	Theme = Themes.Dark
	ClearGridDots()
	Notify("Config", "Reset to defaults", "Warning", 3)
end

function AutoSaveConfig()
	if AutoSaveDebounce then
		pcall(function()
			task.cancel(AutoSaveDebounce)
		end)
	end
	AutoSaveDebounce = task.delay(1, function()
		SaveConfig(true)
		AutoSaveDebounce = nil
	end)
end

--══════════════════════════════════════════════════════--
-- NOTIFICATIONS
--══════════════════════════════════════════════════════--
function Notify(title, message, notifType, duration)
	notifType = notifType or "Info"
	duration = duration or Config.NotificationDuration

	local colors = {
		Success = Color3.fromRGB(50, 205, 50),
		Warning = Color3.fromRGB(255, 165, 0),
		Error = Color3.fromRGB(255, 80, 80),
		Info = Color3.fromRGB(100, 150, 255),
	}
	local accent = colors[notifType] or colors.Info

	while ActiveNotifs >= 5 do
		task.wait(0.1)
	end
	ActiveNotifs = ActiveNotifs + 1

	local NotifFrame = Instance.new("Frame")
	NotifFrame.Parent = ScreenGui
	NotifFrame.BackgroundColor3 = Theme.Card
	NotifFrame.BorderSizePixel = 0
	NotifFrame.Position = UDim2.new(1, 20, 0, 20 + (ActiveNotifs - 1) * 70)
	NotifFrame.Size = UDim2.new(0, 280, 0, 60)
	NotifFrame.ZIndex = 700
	NotifFrame.Active = true

	local NotifCorner = Instance.new("UICorner")
	NotifCorner.CornerRadius = UDim.new(0, 8)
	NotifCorner.Parent = NotifFrame

	local NotifStroke = Instance.new("UIStroke")
	NotifStroke.Color = Theme.Border
	NotifStroke.Thickness = 1
	NotifStroke.Parent = NotifFrame

	local NotifBar = Instance.new("Frame")
	NotifBar.Parent = NotifFrame
	NotifBar.BackgroundColor3 = accent
	NotifBar.BorderSizePixel = 0
	NotifBar.Size = UDim2.new(0, 4, 1, 0)
	NotifBar.ZIndex = 701

	local NotifBarCorner = Instance.new("UICorner")
	NotifBarCorner.CornerRadius = UDim.new(0, 8)
	NotifBarCorner.Parent = NotifBar

	local NotifTitle = Instance.new("TextLabel")
	NotifTitle.Parent = NotifFrame
	NotifTitle.BackgroundTransparency = 1
	NotifTitle.Position = UDim2.new(0, 14, 0, 8)
	NotifTitle.Size = UDim2.new(1, -28, 0, 18)
	NotifTitle.Font = Enum.Font.GothamBold
	NotifTitle.Text = title
	NotifTitle.TextColor3 = Theme.TextPrimary
	NotifTitle.TextSize = 13
	NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
	NotifTitle.ZIndex = 701

	local NotifMessage = Instance.new("TextLabel")
	NotifMessage.Parent = NotifFrame
	NotifMessage.BackgroundTransparency = 1
	NotifMessage.Position = UDim2.new(0, 14, 0, 26)
	NotifMessage.Size = UDim2.new(1, -28, 0, 28)
	NotifMessage.Font = Enum.Font.Gotham
	NotifMessage.Text = message
	NotifMessage.TextColor3 = Theme.TextSecondary
	NotifMessage.TextSize = 11
	NotifMessage.TextWrapped = true
	NotifMessage.TextXAlignment = Enum.TextXAlignment.Left
	NotifMessage.ZIndex = 701

	TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -300, 0, NotifFrame.Position.Y.Offset),
	}):Play()

	task.delay(duration, function()
		local tween =
			TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, 20, 0, NotifFrame.Position.Y.Offset),
			})
		tween.Completed:Connect(function()
			NotifFrame:Destroy()
			ActiveNotifs = ActiveNotifs - 1
		end)
		tween:Play()
	end)
end

--══════════════════════════════════════════════════════--
-- UI: SCREEN GUI
--══════════════════════════════════════════════════════--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LRX_Hub"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

--══════════════════════════════════════════════════════--
-- UI: MAIN FRAME
--══════════════════════════════════════════════════════--
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -Config.WindowWidth / 2, 0.5, -Config.WindowHeight / 2)
MainFrame.Size = UDim2.new(0, Config.WindowWidth, 0, Config.WindowHeight)
MainFrame.ClipsDescendants = false
MainFrame.Active = true
MainFrame.ZIndex = 10

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Theme.Border
mainStroke.Thickness = 2
mainStroke.Parent = MainFrame

if Config.WindowPosition then
	MainFrame.Position = UDim2.new(
		Config.WindowPosition[1],
		Config.WindowPosition[2],
		Config.WindowPosition[3],
		Config.WindowPosition[4]
	)
end
if Config.WindowSize then
	MainFrame.Size = UDim2.new(Config.WindowSize[1], Config.WindowSize[2], Config.WindowSize[3], Config.WindowSize[4])
end

--══════════════════════════════════════════════════════--
-- UI: TOGGLE BUTTON
--══════════════════════════════════════════════════════--
local MainIcon = Create("TextButton", {
	Name = "MainIcon",
	Parent = ScreenGui,
	BackgroundColor3 = Color3.fromRGB(15, 15, 15),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 8, 0, 8),
	Size = UDim2.new(0, 60, 0, 32),
	Font = Enum.Font.GothamBold,
	Text = Config.ToggleButtonText,
	TextColor3 = Theme.AccentYellow,
	TextSize = 13,
	ZIndex = 10,
	Active = true,
	AutoButtonColor = false,
})
Corner(MainIcon, 6)
Stroke(MainIcon, Theme.Border, 1)

local toggleDragging = false
local toggleStartPos, toggleBtnStart

AddConnection(MainIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		toggleDragging = true
		toggleStartPos = input.Position
		toggleBtnStart = MainIcon.Position
	end
end))

AddConnection(UserInputService.InputChanged:Connect(function(input)
	if
		toggleDragging
		and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
	then
		local delta = input.Position - toggleStartPos
		MainIcon.Position = UDim2.new(
			toggleBtnStart.X.Scale,
			toggleBtnStart.X.Offset + delta.X,
			toggleBtnStart.Y.Scale,
			toggleBtnStart.Y.Offset + delta.Y
		)
	end
end))

AddConnection(UserInputService.InputEnded:Connect(function(input)
	if toggleDragging then
		local delta = input.Position - toggleStartPos
		toggleDragging = false
		if math.abs(delta.X) <= 8 and math.abs(delta.Y) <= 8 then
			MainFrame.Visible = not MainFrame.Visible
			Tween(
				MainIcon,
				{ BackgroundColor3 = MainFrame.Visible and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(30, 30, 30) },
				0.2
			)
		end
	end
end))

--══════════════════════════════════════════════════════--
-- UI: TOP BAR
--══════════════════════════════════════════════════════--
local TopBar = Create("Frame", {
	Name = "TopBar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Sidebar,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 44),
	ZIndex = 10,
})

Create("TextLabel", {
	Name = "Title",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 0, 0),
	Size = UDim2.new(0, 70, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = " LRX",
	TextColor3 = Theme.TextPrimary,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
})

local PageTitle = Create("TextLabel", {
	Name = "PageTitle",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 180, 0, 6),
	Size = UDim2.new(0, 140, 0, 20),
	Font = Enum.Font.GothamBold,
	Text = "Home",
	TextColor3 = Theme.TextPrimary,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
})

local PageSubtitle = Create("TextLabel", {
	Name = "PageSubtitle",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 180, 0, 26),
	Size = UDim2.new(0, 140, 0, 16),
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = Theme.TextMuted,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
})

-- Search Bar
local SearchFrame = Create("Frame", {
	Name = "SearchFrame",
	Parent = TopBar,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -230, 0.5, -14),
	Size = UDim2.new(0, 200, 0, 28),
	ZIndex = 12,
})
Corner(SearchFrame, 12)
Stroke(SearchFrame, Theme.Border, 1)

Create("TextLabel", {
	Name = "SearchIcon",
	Parent = SearchFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 8, 0, 0),
	Size = UDim2.new(0, 22, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "🔍",
	TextColor3 = Theme.TextMuted,
	TextSize = 12,
	ZIndex = 13,
})

local SearchBox = Create("TextBox", {
	Name = "SearchBox",
	Parent = SearchFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 32, 0, 0),
	Size = UDim2.new(1, -44, 1, 0),
	Font = Enum.Font.Gotham,
	Text = "Search",
	TextColor3 = Theme.TextMuted,
	TextSize = 12,
	ZIndex = 13,
	ClearTextOnFocus = true,
	Active = true,
})

local SuggestFrame = Create("Frame", {
	Name = "Suggestions",
	Parent = ScreenGui,
	BackgroundColor3 = Theme.DropdownBg,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 200, 0, 0),
	Visible = false,
	ZIndex = 200,
	ClipsDescendants = true,
	Active = true,
})
Corner(SuggestFrame, 6)
Stroke(SuggestFrame, Theme.Border, 1)

local SuggestScroll = Create("ScrollingFrame", {
	Name = "SuggestScroll",
	Parent = SuggestFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 5),
	Size = UDim2.new(1, 0, 1, -10),
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Theme.ScrollBar,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 201,
	ScrollingEnabled = true,
	Active = true,
})

Create("UIListLayout", {
	Parent = SuggestScroll,
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- Close Button
local CloseBtn = Create("TextButton", {
	Name = "CloseBtn",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -34, 0, 6),
	Size = UDim2.new(0, 28, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "×",
	TextColor3 = Theme.TextSecondary,
	TextSize = 24,
	ZIndex = 11,
	Active = true,
	AutoButtonColor = false,
})

AddConnection(CloseBtn.MouseEnter:Connect(function()
	Tween(CloseBtn, { TextColor3 = Theme.AccentRed }, 0.15)
end))
AddConnection(CloseBtn.MouseLeave:Connect(function()
	Tween(CloseBtn, { TextColor3 = Theme.TextSecondary }, 0.15)
end))

AddConnection(CloseBtn.Activated:Connect(function()
	Config.WindowPosition = {
		MainFrame.Position.X.Scale,
		MainFrame.Position.X.Offset,
		MainFrame.Position.Y.Scale,
		MainFrame.Position.Y.Offset,
	}
	Config.WindowSize = {
		MainFrame.Size.X.Scale,
		MainFrame.Size.X.Offset,
		MainFrame.Size.Y.Scale,
		MainFrame.Size.Y.Offset,
	}
	SaveConfig()
	ScriptRunning = false
	DisconnectAll()
	ClearGridDots()
	ScreenGui:Destroy()
end))

--══════════════════════════════════════════════════════--
-- UI: SIDEBAR
--══════════════════════════════════════════════════════--
local Sidebar = Create("Frame", {
	Name = "Sidebar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Sidebar,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 2, 0, 46),
	Size = UDim2.new(0, Config.SidebarWidth, 1, -48),
	ZIndex = 10,
})

local SidebarScroll = Create("ScrollingFrame", {
	Name = "SidebarScroll",
	Parent = Sidebar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 4),
	Size = UDim2.new(1, 0, 1, -8),
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Theme.ScrollBar,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 11,
	ScrollingEnabled = true,
	Active = true,
})

local SidebarLayout = Create("UIListLayout", {
	Parent = SidebarScroll,
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

--══════════════════════════════════════════════════════--
-- UI: CONTENT AREA
--══════════════════════════════════════════════════════--
local ContentFrame = Create("Frame", {
	Name = "ContentFrame",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(0, Config.SidebarWidth, 0, 46),
	Size = UDim2.new(1, -Config.SidebarWidth, 1, -48),
	ZIndex = 10,
	ClipsDescendants = true,
})

local ContentScroll = Create("ScrollingFrame", {
	Name = "ContentScroll",
	Parent = ContentFrame,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 12, 0, 12),
	Size = UDim2.new(1, -24, 1, -24),
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Theme.ScrollBar,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 11,
	ScrollingEnabled = true,
	Active = true,
	ClipsDescendants = true,
})

-- FIX: Create UIListLayout ONCE and keep it alive
local ContentList = Create("UIListLayout", {
	Parent = ContentScroll,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- FIX: Auto-update CanvasSize so content actually scrolls
AddConnection(ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 20)
end))
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 20)

--══════════════════════════════════════════════════════--
-- UI: RESIZE HANDLE
--══════════════════════════════════════════════════════--
local ResizeHandle = Create("Frame", {
	Name = "ResizeHandle",
	Parent = MainFrame,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 16, 0, 16),
	ZIndex = 15,
})

Create("TextLabel", {
	Parent = ResizeHandle,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "//",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 10,
	TextTransparency = 0.4,
	ZIndex = 16,
})

local ResizeBtn = Create("TextButton", {
	Parent = ResizeHandle,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Text = "",
	ZIndex = 16,
	Active = true,
	AutoButtonColor = false,
})

AddConnection(ResizeBtn.InputBegan:Connect(function(input)
	if ModalOpen then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local startSize = MainFrame.Size
		local startPos = input.Position
		local resizeConnection

		resizeConnection = AddConnection(RunService.RenderStepped:Connect(function()
			if not resizeConnection then
				return
			end
			local mouse = UserInputService:GetMouseLocation()
			local delta = mouse - Vector2.new(startPos.X, startPos.Y)
			MainFrame.Size = UDim2.new(
				0,
				math.max(Config.MinWindowWidth, startSize.X.Offset + delta.X),
				0,
				math.max(Config.MinWindowHeight, startSize.Y.Offset + delta.Y)
			)
		end))

		AddConnection(input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				if resizeConnection then
					resizeConnection:Disconnect()
				end
				resizeConnection = nil
			end
		end))
	end
end))

--══════════════════════════════════════════════════════--
-- COMPONENTS
--══════════════════════════════════════════════════════--
local function CreateCard(parent, title, icon, iconColor)
	local card = Create("TextButton", {
		Name = title,
		Parent = parent,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = CardOrder * 2,
		Font = Enum.Font.Gotham,
		Text = "",
		ZIndex = 50,
		Active = true,
		AutoButtonColor = false,
	})
	CardOrder = CardOrder + 1
	Corner(card, 6)
	Stroke(card, Theme.Border, 1)

	Create("TextLabel", {
		Name = "Icon",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 24, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = icon or "⚙",
		TextColor3 = iconColor or Theme.Accent,
		TextSize = 16,
		ZIndex = 51,
	})

	Create("TextLabel", {
		Name = "Title",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 40, 0, 0),
		Size = UDim2.new(1, -65, 1, 0),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 51,
	})

	Create("TextLabel", {
		Name = "Arrow",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -26, 0, 0),
		Size = UDim2.new(0, 22, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = ">",
		TextColor3 = Theme.TextSecondary,
		TextSize = 14,
		ZIndex = 51,
	})

	AddConnection(card.MouseEnter:Connect(function()
		Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)
	end))
	AddConnection(card.MouseLeave:Connect(function()
		Tween(card, { BackgroundColor3 = Theme.Card }, 0.15)
	end))

	return card
end

local function CreateInput(parent, title, defaultText, callback)
	local container = Create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 50),
	})

	Create("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local box = Create("TextBox", {
		Parent = container,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 0, 26),
		Font = Enum.Font.Gotham,
		Text = defaultText or "",
		PlaceholderText = "Enter value...",
		TextColor3 = Theme.TextPrimary,
		PlaceholderColor3 = Theme.TextMuted,
		TextSize = 12,
		ClearTextOnFocus = false,
	})

	Corner(box, 4)

	AddConnection(box.FocusLost:Connect(function()
		callback(box.Text)
	end))

	return container, box
end

local function CreateToggle(parent, text, defaultState, callback)
	local container = Create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 32),
		ZIndex = 120,
	})

	Create("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = Theme.TextPrimary,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 120,
	})

	local toggleBg = Create("TextButton", {
		Parent = container,
		BackgroundColor3 = defaultState and Theme.ToggleOn or Theme.ToggleBg,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -46, 0.5, -10),
		Size = UDim2.new(0, 40, 0, 20),
		ZIndex = 120,
		Active = true,
		AutoButtonColor = false,
		Text = "",
	})
	Corner(toggleBg, 10)

	local knob = Create("Frame", {
		Parent = toggleBg,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = defaultState and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 121,
	})
	Corner(knob, 8)

	local state = defaultState or false

	AddConnection(toggleBg.Activated:Connect(function()
		state = not state
		Tween(toggleBg, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleBg }, 0.2)
		Tween(knob, { Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2) }, 0.2)

		if callback then
			local ok, err = pcall(callback, state)
			if not ok then
				warn("[Toggle Error]", err)
			end
		end

		AutoSaveConfig()
	end))

	return container, function()
		return state
	end
end

local function CreateButton(parent, text, bgColor, width, height, callback)
	bgColor = bgColor or Theme.Card
	width = width or 70
	height = height or 28

	local btn = Create("TextButton", {
		Parent = parent,
		BackgroundColor3 = bgColor,
		BorderSizePixel = 0,
		Size = UDim2.new(0, width, 0, height),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = Theme.TextPrimary,
		TextSize = 11,
		ZIndex = 120,
		Active = true,
		AutoButtonColor = false,
	})
	Corner(btn, 5)
	Stroke(btn, Theme.Border, 1)

	AddConnection(btn.MouseEnter:Connect(function()
		Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
	end))
	AddConnection(btn.MouseLeave:Connect(function()
		Tween(btn, { BackgroundColor3 = bgColor }, 0.15)
	end))

	if callback then
		AddConnection(btn.Activated:Connect(function()
			local ok, err = pcall(callback)
			if not ok then
				warn("[Button Error]", err)
			end
		end))
	end

	return btn
end

local function CreateLabel(parent, text, textColor, fontSize)
	return Create("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, fontSize or 20),
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = textColor or Theme.TextSecondary,
		TextSize = fontSize or 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 120,
	})
end

--══════════════════════════════════════════════════════--
-- DROPDOWN SYSTEM
--══════════════════════════════════════════════════════--
local function CloseDropdown()
	if not ActiveDropdownFrame then
		return
	end

	if ActiveDropdownCard then
		local arrow = ActiveDropdownCard:FindFirstChild("Arrow")
		if arrow then
			arrow.Text = ">"
		end
		Tween(ActiveDropdownCard, { BackgroundColor3 = Theme.Card }, 0.15)
		ActiveDropdownCard = nil
	end

	local DropdownFrame = ActiveDropdownFrame
	ActiveDropdownFrame = nil
	Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15, function()
		if DropdownFrame and DropdownFrame.Parent then
			DropdownFrame:Destroy()
		end
	end)
end

local function ToggleDropdown(card, buildFunc)
	if DropdownDebounce then
		return
	end

	if ActiveDropdownCard == card then
		CloseDropdown()
		return
	end
	DropdownDebounce = true

	CloseDropdown()

	ActiveDropdownCard = card
	Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)
	local arrow = card:FindFirstChild("Arrow")
	if arrow then
		arrow.Text = "v"
	end

	local DropdownFrame = Create("Frame", {
		Name = "Dropdown",
		Parent = ContentScroll,
		BackgroundColor3 = Theme.DropdownBg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = card.LayoutOrder + 1,
		ClipsDescendants = true,
		ZIndex = 50,
	})
	Corner(DropdownFrame, 6)
	Stroke(DropdownFrame, Theme.Border, 1)

	local DropdownScroll = Create("ScrollingFrame", {
		Parent = DropdownFrame,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 51,
		ClipsDescendants = true,
		Active = true,
		ScrollingEnabled = true,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})

	local DropdownList = Create("UIListLayout", {
		Parent = DropdownScroll,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})

	Create("UIPadding", {
		Parent = DropdownScroll,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local ok, err = pcall(buildFunc, DropdownScroll)
	if not ok then
		warn("[Dropdown Build Error]", err)
	end

	task.wait()

	local contentHeight = DropdownList.AbsoluteContentSize.Y + 16
	local maxHeight = math.min(contentHeight, 260)

	DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	ActiveDropdownFrame = DropdownFrame

	Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, maxHeight) }, 0.2)

	task.delay(0.25, function()
		DropdownDebounce = false
	end)
end

--══════════════════════════════════════════════════════--
-- MODAL SYSTEM
--══════════════════════════════════════════════════════--
local function SetModalState(isOpen)
	ModalOpen = isOpen
	MainFrame.Active = not isOpen
	SidebarScroll.ScrollingEnabled = not isOpen
	ContentScroll.ScrollingEnabled = not isOpen
end

function CloseModal()
	if ActiveModal then
		Tween(
			ActiveModal,
			{ Position = UDim2.new(0.5, -ActiveModal.Size.X.Offset / 2, 0.5, -ActiveModal.Size.Y.Offset / 2 + 20) },
			0.2,
			function()
				if ActiveModal then
					ActiveModal:Destroy()
				end
				ActiveModal = nil
			end
		)
	end

	if ModalOverlay then
		Tween(ModalOverlay, { BackgroundTransparency = 1 }, 0.2, function()
			ModalOverlay.Visible = false
			SetModalState(false)
		end)
	end
end

function ShowModal(title, buildFunc, width, height)
	width = width or 520
	height = height or 420

	if not ModalOverlay then
		ModalOverlay = Create("Frame", {
			Name = "ModalOverlay",
			Parent = ScreenGui,
			BackgroundColor3 = Theme.Overlay,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 500,
			Active = false,
			Visible = false,
		})

		local blocker = Create("TextButton", {
			Parent = ModalOverlay,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = 500,
			Active = true,
			AutoButtonColor = false,
		})
	end

	SetModalState(true)
	ModalOverlay.Visible = true
	Tween(ModalOverlay, { BackgroundTransparency = Config.ModalDarkening }, 0.2)

	if ActiveModal then
		ActiveModal:Destroy()
	end

	local ModalFrame = Create("Frame", {
		Name = "ModalFrame",
		Parent = ModalOverlay,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		Size = UDim2.new(0, width, 0, height),
		ZIndex = 600,
		Active = true,
	})
	Corner(ModalFrame, 8)
	Stroke(ModalFrame, Theme.Border, 1)

	local ModalTitleBar = Create("Frame", {
		Parent = ModalFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 12),
		Size = UDim2.new(1, -30, 0, 28),
		ZIndex = 620,
	})

	Create("TextLabel", {
		Parent = ModalTitleBar,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 620,
	})

	local ModalCloseBtn = Create("TextButton", {
		Parent = ModalTitleBar,
		BackgroundColor3 = Theme.AccentRed,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -28, 0, 0),
		Size = UDim2.new(0, 28, 0, 28),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		ZIndex = 620,
		Active = true,
		AutoButtonColor = false,
	})
	Corner(ModalCloseBtn, 6)
	AddConnection(ModalCloseBtn.Activated:Connect(CloseModal))

	local ModalContent = Create("Frame", {
		Parent = ModalFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 50),
		Size = UDim2.new(1, -30, 1, -65),
		ZIndex = 620,
		ClipsDescendants = true,
	})

	ActiveModal = ModalFrame
	Tween(ModalFrame, { Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2) }, 0.3)

	if buildFunc then
		local ok, err = pcall(buildFunc, ModalFrame, ModalContent)
		if not ok then
			warn("[Modal Build Error]", err)
		end
	end
end

--══════════════════════════════════════════════════════--
-- SEARCH SYSTEM
--══════════════════════════════════════════════════════--
local function RegisterSearch(itemName, targetPage, itemIcon, itemAction)
	table.insert(SearchableItems, {
		Name = itemName,
		Page = targetPage,
		Icon = itemIcon,
		Action = itemAction,
	})
end

local function Search(searchQuery)
	local searchResults = {}
	local lowerSearchQuery = searchQuery:lower()
	for _, item in ipairs(SearchableItems) do
		if item.Name:lower():find(lowerSearchQuery, 1, true) then
			table.insert(searchResults, item)
		end
	end
	return searchResults
end

local function UpdateSuggestions()
	for _, child in pairs(SuggestScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local searchText = SearchBox.Text:lower()
	if searchText == "" or searchText == "search" then
		SuggestFrame.Visible = false
		return
	end

	local suggestionMatches = Search(searchText)
	if #suggestionMatches == 0 then
		SuggestFrame.Visible = false
		return
	end

	local searchAbsPos = SearchFrame.AbsolutePosition
	local searchAbsSize = SearchFrame.AbsoluteSize
	SuggestFrame.Position = UDim2.new(0, searchAbsPos.X, 0, searchAbsPos.Y + searchAbsSize.Y + 4)
	SuggestFrame.Size = UDim2.new(0, searchAbsSize.X, 0, math.min(#suggestionMatches * 34 + 10, 220))

	for _, item in ipairs(suggestionMatches) do
		local SuggestionBtn = Create("TextButton", {
			Parent = SuggestScroll,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, 32),
			Position = UDim2.new(0, 5, 0, 0),
			Font = Enum.Font.Gotham,
			Text = item.Icon .. "  " .. item.Name,
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 201,
			Active = true,
			AutoButtonColor = false,
		})
		Corner(SuggestionBtn, 4)

		AddConnection(SuggestionBtn.MouseEnter:Connect(function()
			Tween(SuggestionBtn, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end))
		AddConnection(SuggestionBtn.MouseLeave:Connect(function()
			Tween(SuggestionBtn, { BackgroundColor3 = Theme.Card }, 0.15)
		end))

		AddConnection(SuggestionBtn.Activated:Connect(function()
			SuggestFrame.Visible = false
			SearchBox.Text = "Search"
			if item.Action then
				local ok, err = pcall(item.Action)
				if not ok then
					warn("[Search Action Error]", err)
				end
			end
		end))
	end

	SuggestScroll.CanvasSize = UDim2.new(0, 0, 0, #suggestionMatches * 34)
	SuggestFrame.Visible = true
end

AddConnection(SearchBox:GetPropertyChangedSignal("Text"):Connect(UpdateSuggestions))
AddConnection(SearchBox.FocusLost:Connect(function()
	if SearchBox.Text == "" then
		SearchBox.Text = "Search"
	end
	task.wait(0.2)
	SuggestFrame.Visible = false
end))
AddConnection(SearchBox.Focused:Connect(function()
	if SearchBox.Text ~= "Search" and SearchBox.Text ~= "" then
		UpdateSuggestions()
	end
end))

--══════════════════════════════════════════════════════--
-- PAGE SYSTEM
--══════════════════════════════════════════════════════--
local function ClearContent()
	ContentScroll.CanvasPosition = Vector2.new(0, 0)
	CloseDropdown()
	-- FIX: Don't destroy UIListLayout - only destroy actual content
	for _, child in pairs(ContentScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	CardOrder = 0
	-- UIListLayout stays alive so CanvasSize connection keeps working
end

local function SwitchPage(targetPage, pageTitle, pageSubtitle, pageBuilder)
	CurrentPage = targetPage
	PageTitle.Text = pageTitle
	PageSubtitle.Text = pageSubtitle or ""
	ClearContent()
	local ok, err = pcall(pageBuilder)
	if not ok then
		warn("[Page Error]", err)
	end
end

--══════════════════════════════════════════════════════--
-- NETWORKING
--══════════════════════════════════════════════════════--
local Networking, SeedData
pcall(function()
	Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
	SeedData = require(game:GetService("ReplicatedStorage").SharedModules.SeedData)
end)
<<<<<<< HEAD
=======
print("===== WRITES =====")
for k, v in pairs(Networking.Plant.PlantSeed.Writes) do
	print(k, v)
end

print("===== READS =====")
for k, v in pairs(Networking.Plant.PlantSeed.Reads) do
	print(k, v)
end
>>>>>>> 216637e9ae000c73df9c61a24a463b0e0a2edce8

--══════════════════════════════════════════════════════--
-- MODULE: SEED PLACER
--══════════════════════════════════════════════════════--
local SeedPlacer = (function()
	local module = {}

	-- Private Variables
	local PlantPositions = nil
	local OwnedPlot = nil
	local CurrentPlantIndex = 1
	local LastConfigHash = nil

	-- Private Helper Functions
	local function GetWorldBounds(part)
		local partCFrame = part.CFrame
		local partHalfSize = part.Size / 2
		local worldCorners = {
			partCFrame * Vector3.new(-partHalfSize.X, -partHalfSize.Y, -partHalfSize.Z),
			partCFrame * Vector3.new(-partHalfSize.X, -partHalfSize.Y, partHalfSize.Z),
			partCFrame * Vector3.new(-partHalfSize.X, partHalfSize.Y, -partHalfSize.Z),
			partCFrame * Vector3.new(-partHalfSize.X, partHalfSize.Y, partHalfSize.Z),
			partCFrame * Vector3.new(partHalfSize.X, -partHalfSize.Y, -partHalfSize.Z),
			partCFrame * Vector3.new(partHalfSize.X, -partHalfSize.Y, partHalfSize.Z),
			partCFrame * Vector3.new(partHalfSize.X, partHalfSize.Y, -partHalfSize.Z),
			partCFrame * Vector3.new(partHalfSize.X, partHalfSize.Y, partHalfSize.Z),
		}

		local minX, maxX = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge

		for _, corner in ipairs(worldCorners) do
			minX = math.min(minX, corner.X)
			maxX = math.max(maxX, corner.X)
			minZ = math.min(minZ, corner.Z)
			maxZ = math.max(maxZ, corner.Z)
		end

		return minX, maxX, minZ, maxZ
	end

	local function IsPointInPart(point, part)
		local objectSpacePoint = part.CFrame:PointToObjectSpace(point)
		local partHalfSize = part.Size / 2
		return math.abs(objectSpacePoint.X) <= partHalfSize.X + 0.1
			and math.abs(objectSpacePoint.Y) <= partHalfSize.Y + 0.1
			and math.abs(objectSpacePoint.Z) <= partHalfSize.Z + 0.1
	end

	local function FindPlayerPlot()
		local GardensFolder = workspace:FindFirstChild("Gardens")
		if not GardensFolder then
			warn("[SeedPlacer] workspace.Gardens not found.")
			return nil
		end

		for _, plot in ipairs(GardensFolder:GetChildren()) do
			local ownerName = plot:GetAttribute("Owner")
			local ownerId = plot:GetAttribute("OwnerUserId")

			if ownerName == player.Name or ownerId == player.UserId then
				print(string.format("[SeedPlacer] Found by Owner attribute: %s", plot.Name))
				return plot
			end
		end

		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local playerPos = hrp and hrp.Position

		if playerPos then
			local candidates = {}
			for _, plot in ipairs(GardensFolder:GetChildren()) do
				local visual = plot:FindFirstChild("Visual")
				if not visual then
					continue
				end

				local plotColumns = {}
				for _, child in ipairs(visual:GetChildren()) do
					if child:IsA("BasePart") and child.Name:match("^PlantAreaColumn") then
						table.insert(plotColumns, child)
					end
				end
				if #plotColumns == 0 then
					continue
				end

				local inside = false
				for _, col in ipairs(plotColumns) do
					local localPos = col.CFrame:PointToObjectSpace(playerPos)
					local half = col.Size / 2
					if
						math.abs(localPos.X) <= half.X + 0.5
						and math.abs(localPos.Y) <= half.Y + 10
						and math.abs(localPos.Z) <= half.Z + 0.5
					then
						inside = true
						break
					end
				end

				if inside then
					local plotCenter = Vector3.zero
					for _, col in ipairs(plotColumns) do
						plotCenter = plotCenter + col.Position
					end
					plotCenter = plotCenter / #plotColumns
					table.insert(candidates, {
						Plot = plot,
						CenterDist = (plotCenter - playerPos).Magnitude,
					})
				end
			end

			if #candidates > 0 then
				table.sort(candidates, function(a, b)
					return a.CenterDist < b.CenterDist
				end)
				print(string.format("[SeedPlacer] Position fallback → %s", candidates[1].Plot.Name))
				return candidates[1].Plot
			end
		end

		warn("[SeedPlacer] Could not find plot for player:", player.Name)
		return nil
	end

	local function DetectPlotParts(plot)
		local visual = plot:FindFirstChild("Visual")
		if not visual then
			return {}
		end

		local parts = {}
		for _, child in ipairs(visual:GetChildren()) do
			if child:IsA("BasePart") and child.Name:match("^PlantAreaColumn") then
				table.insert(parts, child)
			end
		end
		return parts
	end

	local function BuildPartOptions(parts)
		local nameCounts = {}
		local options = {}
		for _, part in ipairs(parts) do
			local name = part.Name
			nameCounts[name] = (nameCounts[name] or 0) + 1
			local displayName = name
			local value = name
			if nameCounts[name] > 1 then
				displayName = name .. " #" .. nameCounts[name]
				value = name .. "_" .. nameCounts[name]
			end
			table.insert(options, {
				Label = displayName,
				Value = value,
				Part = part,
			})
		end
		return options
	end

	local function FindPartByValue(parts, value)
		if value == "All" or not value then
			return nil
		end
		local nameCounts = {}
		for _, part in ipairs(parts) do
			local name = part.Name
			nameCounts[name] = (nameCounts[name] or 0) + 1
			local checkValue = name
			if nameCounts[name] > 1 then
				checkValue = name .. "_" .. nameCounts[name]
			end
			if checkValue == value then
				return part
			end
		end
		return nil
	end

	local function GeneratePlantPositions(targetParts, spacing)
		if #targetParts == 0 then
			return {}
		end

		local ColumnData = {}
		local totalMinX, totalMaxX = math.huge, -math.huge
		local totalMinZ, totalMaxZ = math.huge, -math.huge
		local PlantYLevel = 142.505

		for _, part in ipairs(targetParts) do
			local minX, maxX, minZ, maxZ = GetWorldBounds(part)
			table.insert(ColumnData, {
				Part = part,
				MinX = minX,
				MaxX = maxX,
				MinZ = minZ,
				MaxZ = maxZ,
			})
			totalMinX = math.min(totalMinX, minX)
			totalMaxX = math.max(totalMaxX, maxX)
			totalMinZ = math.min(totalMinZ, minZ)
			totalMaxZ = math.max(totalMaxZ, maxZ)
			PlantYLevel = part.Position.Y
		end

		local positions = {}
		local step = math.max(0.1, spacing)
		local YieldInterval = 100
		local iterationCount = 0

		local startX = math.floor(totalMinX)
		local endX = math.ceil(totalMaxX)
		local startZ = math.floor(totalMinZ)
		local endZ = math.ceil(totalMaxZ)

		local x = startX
		while x <= endX + 0.001 do
			local z = startZ
			while z <= endZ + 0.001 do
				iterationCount = iterationCount + 1
				if iterationCount % YieldInterval == 0 then
					task.wait()
				end

				local gridX = math.floor(x * 100 + 0.5) / 100
				local gridZ = math.floor(z * 100 + 0.5) / 100
				local gridPosition = Vector3.new(gridX, PlantYLevel, gridZ)

				for _, columnInfo in ipairs(ColumnData) do
					if
						gridX >= columnInfo.MinX
						and gridX <= columnInfo.MaxX
						and gridZ >= columnInfo.MinZ
						and gridZ <= columnInfo.MaxZ
					then
						if IsPointInPart(gridPosition, columnInfo.Part) then
							table.insert(positions, { Pos = gridPosition, Part = columnInfo.Part })
							break
						end
					end
				end

				z = z + step
			end
			x = x + step
		end

		return positions
	end

	local function ApplyPattern(positions, pattern)
		if pattern == "LeftToRight" then
			return positions
		elseif pattern == "RightToLeft" then
			local result = {}
			for i = #positions, 1, -1 do
				table.insert(result, positions[i])
			end
			return result
		elseif pattern == "OutsideToCenter" then
			local result = {}
			local left = 1
			local right = #positions
			while left <= right do
				table.insert(result, positions[left])
				left = left + 1
				if left <= right then
					table.insert(result, positions[right])
					right = right - 1
				end
			end
			return result
		elseif pattern == "CenterToOutside" then
			local result = {}
			local n = #positions
			if n == 0 then
				return result
			end
			local mid = math.ceil(n / 2)
			table.insert(result, positions[mid])
			local offset = 1
			while true do
				local added = false
				if mid - offset >= 1 then
					table.insert(result, positions[mid - offset])
					added = true
				end
				if mid + offset <= n then
					table.insert(result, positions[mid + offset])
					added = true
				end
				if not added then
					break
				end
				offset = offset + 1
			end
			return result
		elseif pattern == "Middle" then
			if #positions == 0 then
				return {}
			end

			local grid = {}
			local minX, maxX = math.huge, -math.huge
			local minZ, maxZ = math.huge, -math.huge

			for _, posData in ipairs(positions) do
				local p = posData.Pos
				minX = math.min(minX, p.X)
				maxX = math.max(maxX, p.X)
				minZ = math.min(minZ, p.Z)
				maxZ = math.max(maxZ, p.Z)
			end

			local step = math.max(0.1, Config.PlantSpacing or 1)
			local cols = math.max(1, math.floor((maxX - minX) / step + 0.5) + 1)
			local rows = math.max(1, math.floor((maxZ - minZ) / step + 0.5) + 1)

			local cellMap = {}
			for r = 1, rows do
				cellMap[r] = {}
			end

			for _, posData in ipairs(positions) do
				local p = posData.Pos
				local c = math.floor((p.X - minX) / step + 0.5) + 1
				local r = math.floor((p.Z - minZ) / step + 0.5) + 1
				c = math.clamp(c, 1, cols)
				r = math.clamp(r, 1, rows)
				if not cellMap[r][c] then
					cellMap[r][c] = {}
				end
				table.insert(cellMap[r][c], posData)
			end

			local result = {}
			local centerR = math.ceil(rows / 2)
			local centerC = math.ceil(cols / 2)

			local dr = { 0, 1, 0, -1 }
			local dc = { 1, 0, -1, 0 }
			local dir = 0
			local steps = 1
			local r, c = centerR, centerC

			if cellMap[r] and cellMap[r][c] then
				for _, posData in ipairs(cellMap[r][c]) do
					table.insert(result, posData)
				end
			end

			while #result < #positions do
				for _ = 1, 2 do
					for _ = 1, steps do
						r = r + dr[dir + 1]
						c = c + dc[dir + 1]
						if r >= 1 and r <= rows and c >= 1 and c <= cols then
							if cellMap[r] and cellMap[r][c] then
								for _, posData in ipairs(cellMap[r][c]) do
									table.insert(result, posData)
								end
							end
						end
					end
					dir = (dir + 1) % 4
				end
				steps = steps + 1
			end

			return result
		elseif pattern == "Random" then
			local result = {}
			for i, pos in ipairs(positions) do
				result[i] = pos
			end
			for i = #result, 2, -1 do
				local j = math.random(1, i)
				result[i], result[j] = result[j], result[i]
			end
			return result
		else
			return positions
		end
	end

	local function BuildOccupiedLookup()
		local occupied = {}
		local controllers = player:FindFirstChild("PlayerScripts")
			and player.PlayerScripts:FindFirstChild("Controllers")
		local seedInspect = controllers and controllers:FindFirstChild("SeedInspectController")
		local fakePlot = seedInspect and seedInspect:FindFirstChild("FakePlot")

		if not fakePlot then
			return occupied
		end

		local plantsFolder = fakePlot:FindFirstChild("Plants")
		if not plantsFolder then
			if OwnedPlot then
				plantsFolder = OwnedPlot:FindFirstChild("Plants")
			end
		end

		if not plantsFolder then
			return occupied
		end

		for _, plant in ipairs(plantsFolder:GetChildren()) do
			local plantPos = nil

			if plant:IsA("BasePart") then
				plantPos = plant.Position
			elseif plant:IsA("Model") then
				if plant.PrimaryPart then
					plantPos = plant.PrimaryPart.Position
				else
					for _, child in ipairs(plant:GetDescendants()) do
						if child:IsA("BasePart") then
							plantPos = child.Position
							break
						end
					end
				end
			end

			if plantPos then
				local keyX = math.floor(plantPos.X * 2 + 0.5) / 2
				local keyZ = math.floor(plantPos.Z * 2 + 0.5) / 2
				local key = string.format("%.1f,%.1f", keyX, keyZ)
				occupied[key] = true
			end
		end

		return occupied
	end

	local function IsSpotEmpty(spotPosition, occupiedLookup)
		local keyX = math.floor(spotPosition.X * 2 + 0.5) / 2
		local keyZ = math.floor(spotPosition.Z * 2 + 0.5) / 2
		local key = string.format("%.1f,%.1f", keyX, keyZ)
		return not occupiedLookup[key]
	end

	local function GetConfigHash()
		return string.format(
			"%s|%s|%.2f",
			Config.PlantingArea or "All",
			Config.PlantingPattern or "LeftToRight",
			Config.PlantSpacing or 1
		)
	end

	function module:GetPlantPositions()
		local currentHash = GetConfigHash()
		if PlantPositions and LastConfigHash == currentHash then
			return PlantPositions
		end

		if not OwnedPlot then
			OwnedPlot = FindPlayerPlot()
		end

		if not OwnedPlot then
			return nil
		end

		local allParts = DetectPlotParts(OwnedPlot)
		local targetParts = {}

		if Config.PlantingArea == "All" or not Config.PlantingArea or Config.PlantingArea == "" then
			for _, part in ipairs(allParts) do
				table.insert(targetParts, part)
			end
		else
			local selectedPart = FindPartByValue(allParts, Config.PlantingArea)
			if selectedPart then
				table.insert(targetParts, selectedPart)
			else
				for _, part in ipairs(allParts) do
					table.insert(targetParts, part)
				end
			end
		end

		if #targetParts == 0 then
			warn("[SeedPlacer] No target parts found for area: " .. tostring(Config.PlantingArea))
			return nil
		end

		local positions = GeneratePlantPositions(targetParts, Config.PlantSpacing or 1)
		positions = ApplyPattern(positions, Config.PlantingPattern or "LeftToRight")

		PlantPositions = positions
		LastConfigHash = currentHash

		print(
			string.format(
				"[SeedPlacer] Generated %d positions in %s (Area: %s) across %d parts.",
				#positions,
				OwnedPlot.Name,
				Config.PlantingArea or "All",
				#targetParts
			)
		)

		return PlantPositions
	end

	function module:GetDetectionInfo()
		local plot = OwnedPlot or FindPlayerPlot()
		if not plot then
			return { Parts = {}, PartOptions = {}, PartNames = {}, PlotName = "None", PlotInstance = nil }
		end

		local parts = DetectPlotParts(plot)
		local options = BuildPartOptions(parts)
		local names = {}
		for _, opt in ipairs(options) do
			table.insert(names, opt.Label)
		end
		return {
			Parts = parts,
			PartOptions = options,
			PartNames = names,
			PlotName = plot.Name,
			PlotInstance = plot,
		}
	end

	function module:ClearCache()
		PlantPositions = nil
		OwnedPlot = nil
		CurrentPlantIndex = 1
		LastConfigHash = nil
	end

	function module:FindPlayerPlot()
		return FindPlayerPlot()
	end

	function module:RunCycle()
		local allSpots = self:GetPlantPositions()
		if not allSpots then
			return
		end

		local PlantRemote = Networking and Networking.Plant and Networking.Plant.PlantSeed
		if not PlantRemote then
			warn("[SeedPlacer] Networking.Plant.PlantSeed not found!")
			return
		end

		local EnabledSeedNames = {}
		for seedName, enabled in pairs(Config.SelectedPlaceSeeds or {}) do
			if enabled then
				table.insert(EnabledSeedNames, seedName)
			end
		end

		if #EnabledSeedNames == 0 then
			return
		end

		local occupiedLookup = BuildOccupiedLookup()
		local totalSpots = #allSpots
		local maxPlantAmount = Config.PlaceAmount or 10
		local plantedCount = 0
		local seedIndex = 1
		local checkedCount = 0
		local delay = math.max(0, Config.PlantDelay or 0.05)

		while plantedCount < maxPlantAmount and checkedCount < totalSpots do
			if not Config.EnableSeedPlacer then
				break
			end

			local spot = allSpots[CurrentPlantIndex]
			if not spot or not spot.Part then
				CurrentPlantIndex = 1
				break
			end

			checkedCount = checkedCount + 1

			if IsSpotEmpty(spot.Pos, occupiedLookup) then
				local seedName = EnabledSeedNames[seedIndex]
				seedIndex = seedIndex % #EnabledSeedNames + 1

				local success, err = pcall(function()
					PlantRemote:Fire(spot.Pos, seedName, spot.Part)
				end)

				if not success then
					warn("[SeedPlacer] PlantSeed failed at spot " .. tostring(CurrentPlantIndex) .. ":", err)
				end

				plantedCount = plantedCount + 1

				if plantedCount < maxPlantAmount then
					task.wait(delay)
				end
			end

			CurrentPlantIndex = CurrentPlantIndex + 1
			if CurrentPlantIndex > totalSpots then
				CurrentPlantIndex = 1
			end
		end

		if plantedCount > 0 then
			print(string.format("[SeedPlacer] Planted %d seeds this cycle.", plantedCount))
		end
	end

	return module
end)()

--══════════════════════════════════════════════════════--
-- SEED SELECTION MODAL
--══════════════════════════════════════════════════════--
local function ShowSeedSelectionModal(title, selectedTable, updateCallback)
	local seedItems = {}
	if SeedData then
		for _, seed in ipairs(SeedData) do
			if seed.SeedName then
				table.insert(seedItems, {
					Name = seed.SeedName,
					Price = seed.PurchasePrice,
					Rarity = seed.Rarity or "Common",
				})
			end
		end
	end

	ShowModal("Select Seeds", function(ModalFrame, ModalContent)
		local ModalSearchContainer = Create("Frame", {
			Parent = ModalContent,
			BackgroundColor3 = Theme.Content,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 32),
			Position = UDim2.new(0, 0, 0, 0),
			ZIndex = 620,
		})

		Create("TextLabel", {
			Parent = ModalSearchContainer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 0),
			Size = UDim2.new(0, 22, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = "🔍",
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			ZIndex = 621,
		})

		local ModalSearchBox = Create("TextBox", {
			Parent = ModalSearchContainer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 32, 0, 0),
			Size = UDim2.new(1, -44, 1, 0),
			Font = Enum.Font.Gotham,
			Text = "Search seeds...",
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			ZIndex = 621,
			ClearTextOnFocus = true,
			Active = true,
		})

		local ModalSeedScroll = Create("ScrollingFrame", {
			Parent = ModalContent,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 40),
			Size = UDim2.new(1, 0, 1, -80),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.ScrollBar,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ZIndex = 620,
			ClipsDescendants = true,
		})

		local ModalSeedList = Create("UIListLayout", {
			Parent = ModalSeedScroll,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		local RarityColors = {
			Common = Color3.fromRGB(169, 169, 169),
			Uncommon = Color3.fromRGB(50, 205, 50),
			Rare = Color3.fromRGB(30, 144, 255),
			Epic = Color3.fromRGB(147, 112, 219),
			Legendary = Color3.fromRGB(255, 215, 0),
			Mythic = Color3.fromRGB(255, 69, 0),
		}

		local function FormatPrice(price)
			if not price then
				return "$0"
			end
			if price >= 1000 then
				return string.format("$%.2fK", price / 1000)
			end
			return "$" .. tostring(price)
		end

		local function BuildModalRows(filterText)
			for _, child in pairs(ModalSeedScroll:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("TextLabel") then
					child:Destroy()
				end
			end

			local lowerFilter = filterText and filterText:lower() or ""
			local visibleCount = 0

			for i, seedItem in ipairs(seedItems) do
				if lowerFilter ~= "" and not seedItem.Name:lower():find(lowerFilter, 1, true) then
					continue
				end

				visibleCount = visibleCount + 1
				local isSelected = selectedTable[seedItem.Name] == true

				local SeedRow = Create("TextButton", {
					Parent = ModalSeedScroll,
					BackgroundColor3 = isSelected and Color3.fromRGB(55, 45, 75) or Theme.Card,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 34),
					LayoutOrder = i,
					Font = Enum.Font.Gotham,
					Text = "",
					ZIndex = 620,
					Active = true,
					AutoButtonColor = false,
				})
				Corner(SeedRow, 4)

				Create("TextLabel", {
					Parent = SeedRow,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(0.32, 0, 1, 0),
					Font = Enum.Font.Gotham,
					Text = seedItem.Name,
					TextColor3 = Theme.TextPrimary,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 621,
				})

				Create("TextLabel", {
					Parent = SeedRow,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.36, 0, 0, 0),
					Size = UDim2.new(0.24, 0, 1, 0),
					Font = Enum.Font.Gotham,
					Text = FormatPrice(seedItem.Price),
					TextColor3 = Theme.AccentYellow,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 621,
				})

				local rarityColor = RarityColors[seedItem.Rarity] or Theme.TextSecondary
				Create("TextLabel", {
					Parent = SeedRow,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.62, 0, 0, 0),
					Size = UDim2.new(0.18, 0, 1, 0),
					Font = Enum.Font.GothamBold,
					Text = seedItem.Rarity,
					TextColor3 = rarityColor,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 621,
				})

				if isSelected then
					Create("TextLabel", {
						Parent = SeedRow,
						BackgroundTransparency = 1,
						Position = UDim2.new(1, -30, 0, 0),
						Size = UDim2.new(0, 20, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = "✓",
						TextColor3 = Theme.Accent,
						TextSize = 14,
						ZIndex = 621,
					})
				end

				AddConnection(SeedRow.Activated:Connect(function()
					selectedTable[seedItem.Name] = not selectedTable[seedItem.Name]
					AutoSaveConfig()
					if updateCallback then
						updateCallback()
					end
					BuildModalRows(ModalSearchBox.Text ~= "Search seeds..." and ModalSearchBox.Text or "")
				end))
			end

			ModalSeedScroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 37)

			if visibleCount == 0 and lowerFilter ~= "" then
				Create("TextLabel", {
					Parent = ModalSeedScroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 60),
					Font = Enum.Font.Gotham,
					Text = 'No seeds found matching "' .. filterText .. '"',
					TextColor3 = Theme.TextMuted,
					TextSize = 12,
					TextWrapped = true,
					ZIndex = 620,
				})
				ModalSeedScroll.CanvasSize = UDim2.new(0, 0, 0, 70)
			end
		end

		BuildModalRows("")

		AddConnection(ModalSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local text = ModalSearchBox.Text
			if text == "Search seeds..." then
				text = ""
			end
			BuildModalRows(text)
		end))

		local doneBtn = CreateButton(ModalContent, "Done", Theme.Accent, 80, 32, function()
			CloseModal()
		end)
		doneBtn.Position = UDim2.new(1, -80, 1, -36)
	end, 480, 400)
end

--══════════════════════════════════════════════════════--
-- REUSABLE SELECTION MODAL
--══════════════════════════════════════════════════════--
local function ShowSelectionModal(title, options, currentValue, onSelect)
	ShowModal(title, function(ModalFrame, ModalContent)
		local scroll = Create("ScrollingFrame", {
			Parent = ModalContent,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, -40),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.ScrollBar,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ZIndex = 620,
			ClipsDescendants = true,
		})

		local list = Create("UIListLayout", {
			Parent = scroll,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		for i, opt in ipairs(options) do
			local isSelected = currentValue == opt.Value
			local btn = Create("TextButton", {
				Parent = scroll,
				BackgroundColor3 = isSelected and Theme.Accent or Theme.Card,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -10, 0, 32),
				Position = UDim2.new(0, 5, 0, 0),
				LayoutOrder = i,
				Font = Enum.Font.Gotham,
				Text = (isSelected and "✓ " or "     ") .. opt.Label,
				TextColor3 = Theme.TextPrimary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 621,
				Active = true,
				AutoButtonColor = false,
			})
			Corner(btn, 4)
			Stroke(btn, Theme.Border, 1)

			AddConnection(btn.Activated:Connect(function()
				onSelect(opt.Value)
				CloseModal()
			end))
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 35)

		local doneBtn = CreateButton(ModalContent, "Done", Theme.Accent, 80, 32, function()
			CloseModal()
		end)
		doneBtn.Position = UDim2.new(1, -80, 1, -36)
	end, 400, 350)
end

--══════════════════════════════════════════════════════--
-- SEED PLACER CONFIG MODAL
--══════════════════════════════════════════════════════--
local function ShowSeedPlacerConfigModal()
	local info = SeedPlacer:GetDetectionInfo()
	local partOptions = { { Label = "All (every detected column)", Value = "All" } }
	for _, opt in ipairs(info.PartOptions or {}) do
		table.insert(partOptions, { Label = opt.Label, Value = opt.Value })
	end

	local patternOptions = {
		{ Label = "Left to Right", Value = "LeftToRight" },
		{ Label = "Right to Left", Value = "RightToLeft" },
		{ Label = "Outside to Center", Value = "OutsideToCenter" },
		{ Label = "Center to Outside", Value = "CenterToOutside" },
		{ Label = "Middle (Spiral from Center)", Value = "Middle" },
		{ Label = "Random", Value = "Random" },
	}

	-- FIX: Increased height from 200 to 280 so Done button isn't clipped
	ShowModal("Planting Configuration", function(ModalFrame, ModalContent)
		local yOffset = 0
		local rowHeight = 34
		local labelHeight = 18
		local gap = 8

		local areaLabel = CreateLabel(ModalContent, "Planting Area", Theme.Accent, 13)
		areaLabel.Position = UDim2.new(0, 4, 0, yOffset)
		areaLabel.Size = UDim2.new(1, -8, 0, labelHeight)
		yOffset = yOffset + labelHeight + 2

		local areaRow = Create("TextButton", {
			Parent = ModalContent,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, rowHeight),
			Position = UDim2.new(0, 5, 0, yOffset),
			Font = Enum.Font.Gotham,
			Text = "  " .. (Config.PlantingArea or "All") .. "  >",
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 620,
			Active = true,
			AutoButtonColor = false,
		})
		Corner(areaRow, 4)
		Stroke(areaRow, Theme.Border, 1)
		AddConnection(areaRow.Activated:Connect(function()
			ShowSelectionModal("Select Planting Area", partOptions, Config.PlantingArea or "All", function(value)
				Config.PlantingArea = value
				SeedPlacer:ClearCache()
				-- Refresh grid dots if they're showing
				if Config.ShowGridDots then
					RefreshGridDots()
				end
				AutoSaveConfig()
			end)
		end))
		yOffset = yOffset + rowHeight + gap

		local patternLabel = CreateLabel(ModalContent, "Planting Pattern", Theme.Accent, 13)
		patternLabel.Position = UDim2.new(0, 4, 0, yOffset)
		patternLabel.Size = UDim2.new(1, -8, 0, labelHeight)
		yOffset = yOffset + labelHeight + 2

		local patternRow = Create("TextButton", {
			Parent = ModalContent,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, rowHeight),
			Position = UDim2.new(0, 5, 0, yOffset),
			Font = Enum.Font.Gotham,
			Text = "  " .. (Config.PlantingPattern or "LeftToRight") .. "  >",
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 620,
			Active = true,
			AutoButtonColor = false,
		})
		Corner(patternRow, 4)
		Stroke(patternRow, Theme.Border, 1)
		AddConnection(patternRow.Activated:Connect(function()
			ShowSelectionModal(
				"Select Pattern",
				patternOptions,
				Config.PlantingPattern or "LeftToRight",
				function(value)
					Config.PlantingPattern = value
					SeedPlacer:ClearCache()
					if Config.ShowGridDots then
						RefreshGridDots()
					end
					AutoSaveConfig()
				end
			)
		end))
		yOffset = yOffset + rowHeight + gap

		local doneBtn = CreateButton(ModalContent, "Done", Theme.Accent, 80, 32, function()
			CloseModal()
		end)
		doneBtn.Position = UDim2.new(1, -90, 0, yOffset)
	end, 480, 280)
end

--══════════════════════════════════════════════════════--
-- PAGE: HOME
--══════════════════════════════════════════════════════--
function Pages.Home()
	SwitchPage("Home", "Home", "Game Version: ----", function()
		-- Seed Placer Card
		local SeedPlacerCard = CreateCard(ContentScroll, "Seed Placer", "🏠", Theme.Accent)

		AddConnection(SeedPlacerCard.Activated:Connect(function()
			ToggleDropdown(SeedPlacerCard, function(DropdownScroll)
				Config.SelectedPlaceSeeds = Config.SelectedPlaceSeeds or {}
				Config.PlaceAmount = Config.PlaceAmount or 10
				Config.PlantingArea = Config.PlantingArea or "All"
				Config.PlantingPattern = Config.PlantingPattern or "LeftToRight"
				Config.PlantSpacing = Config.PlantSpacing or 1
				Config.PlantDelay = Config.PlantDelay or 0.05
				if Config.EnableSeedPlacer == nil then
					Config.EnableSeedPlacer = false
				end

				CreateLabel(DropdownScroll, "Seed Placer", Theme.Accent, 12)

				local SelectedSeedsLabel = CreateLabel(DropdownScroll, "Selected: None", Theme.TextMuted, 10)

				local function UpdateSelectedLabel()
					SelectedSeedsLabel.Text = FormatSelectedSeeds(Config.SelectedPlaceSeeds, 10)
				end

				UpdateSelectedLabel()

				local SelectSeedsBtn = CreateButton(DropdownScroll, "Select Seeds...", Theme.Card, 100, 30, function()
					ShowSeedSelectionModal("Select Seeds", Config.SelectedPlaceSeeds, UpdateSelectedLabel)
				end)
				SelectSeedsBtn.Size = UDim2.new(1, -8, 0, 30)

				local SeedActionFrame = Create("Frame", {
					Parent = DropdownScroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 30),
				})

				local SelectAllBtn = CreateButton(SeedActionFrame, "Select All", Theme.Accent, 100, 30, function()
					for _, seed in ipairs(SeedData or {}) do
						if seed.SeedName then
							Config.SelectedPlaceSeeds[seed.SeedName] = true
						end
					end
					AutoSaveConfig()
					UpdateSelectedLabel()
				end)
				SelectAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				local ClearAllBtn = CreateButton(
					SeedActionFrame,
					"Clear All",
					Color3.fromRGB(185, 65, 65),
					100,
					30,
					function()
						table.clear(Config.SelectedPlaceSeeds)
						AutoSaveConfig()
						UpdateSelectedLabel()
					end
				)
				ClearAllBtn.Position = UDim2.new(0.5, 3, 0, 0)
				ClearAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				local info = SeedPlacer:GetDetectionInfo()
				local totalPos = 0
				local cached = SeedPlacer:GetPlantPositions()
				if cached then
					totalPos = #cached
				end

				CreateLabel(DropdownScroll, "Plot: " .. (info and info.PlotName or "None"), Theme.TextSecondary, 11)
				CreateLabel(
					DropdownScroll,
					"Columns Detected: " .. (info and #info.PartNames or 0),
					Theme.TextSecondary,
					11
				)
				CreateLabel(DropdownScroll, "Total Positions: " .. totalPos, Theme.TextSecondary, 11)

				CreateLabel(DropdownScroll, "Detected Columns:", Theme.Accent, 12)
				local partNames = info and info.PartNames or {}
				if #partNames == 0 then
					CreateLabel(DropdownScroll, "  (none)", Theme.TextMuted, 11)
				else
					for i, name in ipairs(partNames) do
						CreateLabel(DropdownScroll, "  " .. name, Theme.TextSecondary, 11)
					end
				end

				CreateLabel(DropdownScroll, "Current Settings:", Theme.Accent, 12)
				CreateLabel(DropdownScroll, "  Area: " .. (Config.PlantingArea or "All"), Theme.TextSecondary, 11)
				CreateLabel(
					DropdownScroll,
					"  Pattern: " .. (Config.PlantingPattern or "LeftToRight"),
					Theme.TextSecondary,
					11
				)

				local ConfigBtn = CreateButton(
					DropdownScroll,
					"Configure Planting...",
					Theme.Accent,
					100,
					30,
					function()
						ShowSeedPlacerConfigModal()
					end
				)
				ConfigBtn.Size = UDim2.new(1, -8, 0, 30)

				CreateLabel(DropdownScroll, "Settings", Theme.Accent, 12)
				local SettingsRow = Create("Frame", {
					Parent = DropdownScroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 50),
				})

				local SpacingContainer = Create("Frame", {
					Parent = SettingsRow,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.33, -4, 1, 0),
				})
				Create("TextLabel", {
					Parent = SpacingContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					Font = Enum.Font.Gotham,
					Text = "Spacing",
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local SpacingBox = Create("TextBox", {
					Parent = SpacingContainer,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 18),
					Size = UDim2.new(1, 0, 0, 26),
					Font = Enum.Font.Gotham,
					Text = tostring(Config.PlantSpacing),
					PlaceholderText = "1",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				Corner(SpacingBox, 4)
				AddConnection(SpacingBox.FocusLost:Connect(function()
					local val = tonumber(SpacingBox.Text)
					if val and val >= 0.1 then
						Config.PlantSpacing = val
						SeedPlacer:ClearCache()
						if Config.ShowGridDots then
							RefreshGridDots()
						end
						AutoSaveConfig()
					end
				end))

				local DelayContainer = Create("Frame", {
					Parent = SettingsRow,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.33, -4, 1, 0),
					Position = UDim2.new(0.33, 2, 0, 0),
				})
				Create("TextLabel", {
					Parent = DelayContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					Font = Enum.Font.Gotham,
					Text = "Delay (s)",
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local DelayBox = Create("TextBox", {
					Parent = DelayContainer,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 18),
					Size = UDim2.new(1, 0, 0, 26),
					Font = Enum.Font.Gotham,
					Text = tostring(Config.PlantDelay),
					PlaceholderText = "0.05",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				Corner(DelayBox, 4)
				AddConnection(DelayBox.FocusLost:Connect(function()
					local val = tonumber(DelayBox.Text)
					if val and val >= 0 then
						Config.PlantDelay = val
						AutoSaveConfig()
					end
				end))

				local AmountContainer = Create("Frame", {
					Parent = SettingsRow,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.33, -4, 1, 0),
					Position = UDim2.new(0.67, 4, 0, 0),
				})
				Create("TextLabel", {
					Parent = AmountContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					Font = Enum.Font.Gotham,
					Text = "Amount",
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local AmountBox = Create("TextBox", {
					Parent = AmountContainer,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 18),
					Size = UDim2.new(1, 0, 0, 26),
					Font = Enum.Font.Gotham,
					Text = tostring(Config.PlaceAmount),
					PlaceholderText = "10",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				Corner(AmountBox, 4)
				AddConnection(AmountBox.FocusLost:Connect(function()
					local val = tonumber(AmountBox.Text)
					if val and val > 0 then
						Config.PlaceAmount = math.floor(val)
						AutoSaveConfig()
					end
				end))

				CreateToggle(DropdownScroll, "Enable Seed Placer", Config.EnableSeedPlacer, function(state)
					Config.EnableSeedPlacer = state
					AutoSaveConfig()
					print("[SeedPlacer] Toggle set to:", state)
				end)
			end)
		end))

		-- Plot Visualizer Card
		local PlotVisualizerCard = CreateCard(ContentScroll, "Plot Visualizer", "✨", Theme.AccentCyan)

		AddConnection(PlotVisualizerCard.Activated:Connect(function()
			ToggleDropdown(PlotVisualizerCard, function(DropdownScroll)
				CreateLabel(DropdownScroll, "Plot Visualizer", Theme.AccentCyan, 12)

				local info = SeedPlacer:GetDetectionInfo()
				local plotName = info and info.PlotName or "None"
				CreateLabel(DropdownScroll, "Detected Plot: " .. plotName, Theme.TextSecondary, 11)

				-- Laser Scan Button (one-time effect)
				local LaserBtn = CreateButton(DropdownScroll, "🔦 Laser Scan", Theme.AccentCyan, 100, 32, function()
					local detectedPlot = SeedPlacer:FindPlayerPlot()
					if detectedPlot then
						LaserScanPlot(detectedPlot, 1.2)
						Notify("Plot Visualizer", "Laser scan on " .. detectedPlot.Name, "Success", 2)
					else
						Notify("Plot Visualizer", "Could not find your plot!", "Error", 3)
					end
				end)
				LaserBtn.Size = UDim2.new(1, -8, 0, 32)

				-- FIX: Grid Dots is now a persistent toggle
				CreateToggle(DropdownScroll, "Show Grid Dots", Config.ShowGridDots, function(state)
					Config.ShowGridDots = state
					AutoSaveConfig()
					if state then
						RefreshGridDots()
					else
						ClearGridDots()
					end
				end)

				-- Clear Visuals Button
				local ClearBtn = CreateButton(
					DropdownScroll,
					"🧹 Clear All Visuals",
					Color3.fromRGB(185, 65, 65),
					100,
					32,
					function()
						ClearAllVisuals()
						Config.ShowGridDots = false
						AutoSaveConfig()
						Notify("Plot Visualizer", "All visuals cleared", "Info", 2)
					end
				)
				ClearBtn.Size = UDim2.new(1, -8, 0, 32)
			end)
		end))

		-- Auto Collect Fruits Card (placeholder)
		local autoCollectFruitsCard = CreateCard(ContentScroll, "Auto Collect Fruits", "🍎", Theme.Accent)
		AddConnection(autoCollectFruitsCard.Activated:Connect(function()
			-- Placeholder for future implementation
		end))
	end)
end

--══════════════════════════════════════════════════════--
-- PAGE: SHOP
--══════════════════════════════════════════════════════--
local function GetSelectedSeedNames()
	local names = {}
	for name, selected in pairs(Config.SelectedSeeds) do
		if selected then
			table.insert(names, name)
		end
	end
	if #names == 0 then
		return "None"
	end
	return table.concat(names, ", ")
end

function Pages.Shop()
	SwitchPage("Shop", "Shop", "ShopFeatures", function()
		local SeedShopCard = CreateCard(ContentScroll, "Seed Shop", "🌱", Theme.Accent)

		AddConnection(SeedShopCard.Activated:Connect(function()
			ToggleDropdown(SeedShopCard, function(DropdownScroll)
				CreateLabel(DropdownScroll, "Auto Buy Seeds", Theme.Accent, 12)

				local SelectedSeedsLabel =
					CreateLabel(DropdownScroll, "Selected: " .. GetSelectedSeedNames(), Theme.TextMuted, 10)
				SelectedSeedsLabel.Name = "SelectedLabel"

				local function UpdateSelectedLabel()
					SelectedSeedsLabel.Text = FormatSelectedSeeds(Config.SelectedSeeds, 10)
				end

				UpdateSelectedLabel()

				local SelectSeedsBtn = CreateButton(DropdownScroll, "Select Seeds...", Theme.Card, 100, 30, function()
					ShowSeedSelectionModal("Select Seeds", Config.SelectedSeeds, UpdateSelectedLabel)
				end)
				SelectSeedsBtn.Size = UDim2.new(1, -8, 0, 30)

				local SeedActionFrame = Create("Frame", {
					Parent = DropdownScroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 30),
				})

				local SelectAllBtn = CreateButton(SeedActionFrame, "Select All", Theme.Accent, 100, 30, function()
					if SeedData then
						for _, seed in ipairs(SeedData) do
							if seed.SeedName then
								Config.SelectedSeeds[seed.SeedName] = true
							end
						end
					end
					AutoSaveConfig()
					UpdateSelectedLabel()
				end)
				SelectAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				local ClearAllBtn = CreateButton(
					SeedActionFrame,
					"Clear All",
					Color3.fromRGB(185, 65, 65),
					100,
					30,
					function()
						table.clear(Config.SelectedSeeds)
						AutoSaveConfig()
						UpdateSelectedLabel()
					end
				)
				ClearAllBtn.Position = UDim2.new(0.5, 3, 0, 0)
				ClearAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				CreateToggle(DropdownScroll, "Enable Auto Buy", Config.EnableSeedShop, function(state)
					Config.EnableSeedShop = state
					AutoSaveConfig()
				end)
			end)
		end))
	end)
end

--══════════════════════════════════════════════════════--
-- PAGE: ACCOUNT
--══════════════════════════════════════════════════════--
function Pages.Account()
	SwitchPage("Account", "Account", "User Profile", function()
		local card = CreateCard(ContentScroll, "Account Info", "👤", Theme.Accent)
		AddConnection(card.Activated:Connect(function()
			ToggleDropdown(card, function(DropdownScroll)
				CreateLabel(DropdownScroll, "Username: " .. player.Name, Theme.TextPrimary, 12)
				CreateLabel(DropdownScroll, "User ID: " .. player.UserId, Theme.TextSecondary, 11)
			end)
		end))
	end)
end

--══════════════════════════════════════════════════════--
-- PAGE: PREMIUM
--══════════════════════════════════════════════════════--
function Pages.Premium()
	SwitchPage("Premium", "Premium", "Premium Features", function() end)
end

--══════════════════════════════════════════════════════--
-- PAGE: SETTINGS
--══════════════════════════════════════════════════════--
function Pages.Settings()
	SwitchPage("Settings", "Settings", "Preferences", function()
		CreateLabel(ContentScroll, "UI Settings", Theme.Accent, 14)

		CreateToggle(ContentScroll, "Disable Animations", Config.DisableAnimations, function(state)
			Config.DisableAnimations = state
			AutoSaveConfig()
		end)

		CreateToggle(ContentScroll, "Reduce Effects", Config.ReduceEffects, function(state)
			Config.ReduceEffects = state
			AutoSaveConfig()
		end)

		CreateLabel(ContentScroll, " ", Theme.TextSecondary, 8)

		CreateButton(ContentScroll, "Save Now", Theme.AccentGreen, 120, 32, function()
			SaveConfig()
		end)

		CreateButton(ContentScroll, "Load Config", Theme.Accent, 120, 32, function()
			LoadConfig()
		end)

		CreateLabel(ContentScroll, " ", Theme.TextSecondary, 8)

		CreateButton(ContentScroll, "Reset Config", Theme.AccentRed, 120, 32, function()
			ResetConfig()
		end)
	end)
end

--══════════════════════════════════════════════════════--
-- BACKGROUND TASKS
--══════════════════════════════════════════════════════--
-- FIX: Seed Placer Loop with pcall so one error doesn't kill the loop forever
table.insert(
	Tasks,
	task.spawn(function()
		while ScriptRunning do
			task.wait(0.2)
			if Config.EnableSeedPlacer then
				local ok, err = pcall(function()
					SeedPlacer:RunCycle()
				end)
				if not ok then
					warn("[SeedPlacer Loop Error]", err)
				end
			end
		end
	end)
)

-- FIX: Auto Buy Loop with pcall
table.insert(
	Tasks,
	task.spawn(function()
		while ScriptRunning do
			task.wait(0.2)
			if Config.EnableSeedShop and Networking and SeedData then
				local ok, err = pcall(function()
					local leaderstats = player:FindFirstChild("leaderstats")
					local sheckles = leaderstats and leaderstats:FindFirstChild("Sheckles")
					if sheckles then
						for _, seed in ipairs(SeedData) do
							if Config.SelectedSeeds[seed.SeedName] and sheckles.Value >= (seed.PurchasePrice or 0) then
								Networking.SeedShop.PurchaseSeed:Fire(seed.SeedName)
							end
						end
					end
				end)
				if not ok then
					warn("[AutoBuy Loop Error]", err)
				end
			end
		end
	end)
)

--══════════════════════════════════════════════════════--
-- SIDEBAR SETUP
--══════════════════════════════════════════════════════--
local SidebarItems = {
	{ Name = "Account", Icon = "👤", Color = Theme.Accent, Page = Pages.Account },
	{ Name = "Home", Icon = "🏠", Color = Theme.Accent, Page = Pages.Home },
	{ Name = "Premium", Icon = "💎", Color = Theme.AccentPink, Page = Pages.Premium },
	{ Name = "Shop", Icon = "🏪", Color = Theme.Accent, Page = Pages.Shop },
	{ Name = "Settings", Icon = "⚙️", Color = Theme.AccentCyan, Page = Pages.Settings },
}

for itemIndex, item in ipairs(SidebarItems) do
	local SidebarBtn = Create("TextButton", {
		Name = item.Name,
		Parent = SidebarScroll,
		BackgroundColor3 = (itemIndex == 2) and Theme.Card or Theme.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -10, 0, 36),
		Position = UDim2.new(0, 5, 0, 0),
		Font = Enum.Font.Gotham,
		Text = "  " .. item.Icon .. "  " .. item.Name,
		TextColor3 = item.Color,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		ZIndex = 12,
		Active = true,
	})
	Corner(SidebarBtn, 4)

	SidebarButtons[item.Name] = function()
		CurrentPage = item.Name
		for _, child in pairs(SidebarScroll:GetChildren()) do
			if child:IsA("TextButton") then
				local isSelected = (child.Name == item.Name)
				Tween(child, { BackgroundColor3 = isSelected and Theme.Card or Theme.Sidebar }, 0.2)
			end
		end
		item.Page()
	end

	AddConnection(SidebarBtn.MouseEnter:Connect(function()
		if CurrentPage ~= item.Name then
			Tween(SidebarBtn, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end
	end))
	AddConnection(SidebarBtn.MouseLeave:Connect(function()
		if CurrentPage ~= item.Name then
			Tween(SidebarBtn, { BackgroundColor3 = Theme.Sidebar }, 0.15)
		end
	end))

	AddConnection(SidebarBtn.Activated:Connect(SidebarButtons[item.Name]))
	RegisterSearch(item.Name, item.Name, item.Icon, SidebarButtons[item.Name])
end

AddConnection(SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 10)
end))
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, #SidebarItems * 39 + 10)

--══════════════════════════════════════════════════════--
-- GLOBAL INPUT HANDLER
--══════════════════════════════════════════════════════--
AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local pos = input.Position
	local function isInside(gui)
		if not gui or not gui.Parent then
			return false
		end
		local ap = gui.AbsolutePosition
		local as = gui.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end

	if SuggestFrame and SuggestFrame.Visible then
		if not isInside(SearchFrame) and not isInside(SuggestFrame) then
			SuggestFrame.Visible = false
		end
	end

	if ActiveDropdownFrame and ActiveDropdownFrame.Parent then
		if isInside(ActiveDropdownFrame) then
			return
		end
		if ActiveDropdownCard and isInside(ActiveDropdownCard) then
			return
		end
		CloseDropdown()
	end
end))

--══════════════════════════════════════════════════════--
-- WINDOW DRAG
--══════════════════════════════════════════════════════--
local dragging = false
local dragStart, frameStart

AddConnection(MainFrame.InputBegan:Connect(function(input)
	if ModalOpen then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		frameStart = MainFrame.Position
	end
end))

AddConnection(UserInputService.InputChanged:Connect(function(input)
	if
		dragging
		and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
	then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			frameStart.X.Scale,
			frameStart.X.Offset + delta.X,
			frameStart.Y.Scale,
			frameStart.Y.Offset + delta.Y
		)
	end
end))

AddConnection(UserInputService.InputEnded:Connect(function(input)
	if dragging then
		dragging = false
	end
end))

--══════════════════════════════════════════════════════--
-- MOBILE SUPPORT
--══════════════════════════════════════════════════════--
if UserInputService.TouchEnabled then
	local viewport = workspace.CurrentCamera.ViewportSize
	local w = math.min(Config.WindowWidth, viewport.X - 20)
	local h = math.min(Config.WindowHeight, viewport.Y - 40)
	MainFrame.Size = UDim2.new(0, w, 0, h)
	MainFrame.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
end

--══════════════════════════════════════════════════════--
-- INITIALIZATION
--══════════════════════════════════════════════════════--
LoadConfig()

-- If grid dots were saved as enabled, show them on load
if Config.ShowGridDots then
	task.delay(1, function()
		RefreshGridDots()
	end)
end

Pages.Home()
