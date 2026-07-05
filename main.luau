-- ═══════════════════════════════════════════════════════════════════════
--  LRX_Hub v4.0.2 - Fixed Dropdown + Auto Farm
--  Architecture: Modular, memory-safe, performance-oriented
--  Purpose: Development automation tool for personal Roblox game
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 0: GLOBAL NAMESPACE & LOAD PROTECTION
-- ═══════════════════════════════════════════════════════════════════════

local genv = (typeof(getgenv) == "function" and getgenv()) or _G

-- Use a single global only for duplicate-load protection and persistent config.
-- Everything else is local to this script execution.
genv.LRX = genv.LRX or { Config = {} }
local Persist = genv.LRX

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 1: CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════

local CONSTANTS = {
	-- Files & Storage
	CONFIG_FILE = "LRX_Hub_Config.json",
	CONFIG_ATTRIBUTE = "LRX_Hub_Config",

	-- UI Dimensions
	DEFAULT_WINDOW_WIDTH = 600,
	DEFAULT_WINDOW_HEIGHT = 400,
	MIN_WINDOW_WIDTH = 320,
	MIN_WINDOW_HEIGHT = 240,
	SIDEBAR_WIDTH = 170,
	TOPBAR_HEIGHT = 44,

	-- Z-Index Layers
	Z_BASE = 10,
	Z_DROPDOWN = 50,
	Z_NOTIFICATION = 700,
	Z_MODAL_OVERLAY = 500,
	Z_MODAL = 600,

	-- Planting
	DEFAULT_PLACE_AMOUNT = 10,
	DEFAULT_PLANT_SPACING = 1,
	DEFAULT_PLANT_DELAY = 0.05,
	MAX_PLANT_AMOUNT = 1000,

	-- Timing & Intervals
	DROPDOWN_ANIMATION_SPEED = 0.2,
	PLANT_CYCLE_INTERVAL = 0.2,
	AUTO_BUY_INTERVAL = 0.2,
	AUTO_SAVE_DEBOUNCE = 1,
	YIELD_INTERVAL = 300,

	-- Dropdowns
	MAX_DROPDOWN_HEIGHT = 300,

	-- Grid Dots
	GRID_DOT_SIZE = 0.08,
	GRID_DOT_BATCH_SIZE = 400,
	GRID_DOT_BATCH_DELAY = 0.03,
	GRID_DOT_Y_OFFSET = 0.0,

	-- Laser
	LASER_SCAN_DURATION = 1.5,
	LASER_SWEEP_COUNT = 6,
	LASER_BEAM_THICKNESS = 0.05,

	-- Notifications
	MAX_NOTIFICATIONS = 5,
	NOTIFICATION_HEIGHT = 60,
	NOTIFICATION_WIDTH = 260,
	NOTIFICATION_DURATION = 3,

	-- Mobile
	MOBILE_PADDING_X = 20,
	MOBILE_PADDING_Y = 40,
	MOBILE_INIT_DELAY = 0.3,

	-- Math & Precision
	POSITION_PRECISION = 100,
	OCCUPIED_LOOKUP_PRECISION = 2,
	OCCUPANCY_TOLERANCE = 0.5,

	-- Colors
	RARITY_COLORS = {
		Common = Color3.fromRGB(169, 169, 169),
		Uncommon = Color3.fromRGB(50, 205, 50),
		Rare = Color3.fromRGB(30, 144, 255),
		Epic = Color3.fromRGB(147, 112, 219),
		Legendary = Color3.fromRGB(255, 215, 0),
		Mythic = Color3.fromRGB(255, 69, 0),
	},

	NOTIF_COLORS = {
		Success = Color3.fromRGB(50, 205, 50),
		Warning = Color3.fromRGB(255, 165, 0),
		Error = Color3.fromRGB(255, 80, 80),
		Info = Color3.fromRGB(100, 150, 255),
	},

	GRID_DOT_COLORS = {
		Color3.fromRGB(50, 205, 50),
		Color3.fromRGB(255, 215, 0),
		Color3.fromRGB(0, 255, 127),
		Color3.fromRGB(255, 165, 0),
	},
}

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 2: SERVICES
-- ═══════════════════════════════════════════════════════════════════════

local Services = {
	Players = game:GetService("Players"),
	TweenService = game:GetService("TweenService"),
	UserInputService = game:GetService("UserInputService"),
	RunService = game:GetService("RunService"),
	HttpService = game:GetService("HttpService"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	Workspace = game:GetService("Workspace"),
}

local Player = Services.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Networking modules (loaded once, nil if unavailable)
local Networking, SeedData
pcall(function()
	Networking = require(Services.ReplicatedStorage:WaitForChild("SharedModules", 5):WaitForChild("Networking", 5))
	SeedData = require(Services.ReplicatedStorage.SharedModules:WaitForChild("SeedData", 5))
end)

local CollectFruitRemote = Networking and Networking.Garden and Networking.Garden.CollectFruit
local UseShovelRemote = Networking and Networking.Shovel and Networking.Shovel.UseShovel

local PlantRemote = Networking and Networking.Plant and Networking.Plant.PlantSeed

-- Localize global functions for performance
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_random = math.random
local math_ceil = math.ceil
local math_huge = math.huge
local math_clamp = math.clamp
local typeof = typeof
local pcall = pcall
local tick = tick
local task_wait = task.wait
local task_delay = task.delay
local task_spawn = task.spawn
local task_cancel = task.cancel
local string_format = string.format
local table_insert = table.insert
local table_clear = table.clear
local table_create = table.create
local table_clone = table.clone
local table_sort = table.sort
local table_concat = table.concat
local pairs = pairs
local ipairs = ipairs

-- Forward declarations for systems defined later (fixes closure capture)
local PlotSystem, SeedPlacer

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 3: CONFIG SCHEMA
-- ═══════════════════════════════════════════════════════════════════════

local ConfigSchema = {
	WindowWidth = { type = "number", min = 320, max = 2000, default = CONSTANTS.DEFAULT_WINDOW_WIDTH },
	WindowHeight = { type = "number", min = 240, max = 1500, default = CONSTANTS.DEFAULT_WINDOW_HEIGHT },
	MinWindowWidth = { type = "number", min = 200, max = 800, default = CONSTANTS.MIN_WINDOW_WIDTH },
	MinWindowHeight = { type = "number", min = 150, max = 600, default = CONSTANTS.MIN_WINDOW_HEIGHT },
	SidebarWidth = { type = "number", min = 120, max = 300, default = CONSTANTS.SIDEBAR_WIDTH },
	ToggleButtonText = { type = "string", default = "LRX" },
	Theme = { type = "string", default = "Dark" },
	AnimationSpeed = { type = "number", min = 0, max = 2, default = 0.2 },
	DisableAnimations = { type = "boolean", default = false },
	NotificationDuration = { type = "number", min = 1, max = 10, default = CONSTANTS.NOTIFICATION_DURATION },
	ModalDarkening = { type = "number", min = 0, max = 1, default = 0.5 },
	UIScale = { type = "number", min = 0.5, max = 2, default = 1.0 },
	SelectedSeeds = { type = "table", default = {} },
	EnableSeedShop = { type = "boolean", default = false },
	SelectedPlaceSeeds = { type = "table", default = {} },
	EnableSeedPlacer = { type = "boolean", default = false },
	PlaceAmount = { type = "number", min = 1, max = 1000, default = CONSTANTS.DEFAULT_PLACE_AMOUNT },
	PlantingArea = { type = "string", default = "All" },
	PlantingPattern = { type = "string", default = "LeftToRight" },
	PlantSpacing = { type = "number", min = 0.1, max = 10, default = CONSTANTS.DEFAULT_PLANT_SPACING },
	PlantDelay = { type = "number", min = 0, max = 5, default = CONSTANTS.DEFAULT_PLANT_DELAY },
	SelectedCollectFruits = { type = "table", default = {} },
	EnableAutoShovel = { type = "boolean", default = false },
	ShowGridDots = { type = "boolean", default = false },
	ReduceEffects = { type = "boolean", default = false },
	Keybinds = { type = "table", default = { ToggleUI = "F" } },
}

-- Apply defaults without overwriting existing values
for key, schema in pairs(ConfigSchema) do
	if Persist.Config[key] == nil then
		if schema.type == "table" then
			Persist.Config[key] = table_clone(schema.default)
		else
			Persist.Config[key] = schema.default
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 4: RUNTIME STATE (reset on reload)
-- ═══════════════════════════════════════════════════════════════════════

local State = {
	ScriptRunning = true,
	ActiveNotifs = 0,
	CurrentPage = "Home",
	ModalOpen = false,
	CardOrder = 0,
	ActiveDropdownCard = nil,
	ActiveDropdownFrame = nil,
	DropdownDebounce = false,
	ActiveModal = nil,
	ModalOverlay = nil,
	IsDraggingWindow = false,
	IsDraggingToggle = false,
	IsResizing = false,
	DragStartPos = nil,
	FrameStartPos = nil,
	ToggleStartPos = nil,
	ToggleBtnStart = nil,
	ResizeStartSize = nil,
	ResizeStartPos = nil,
	AutoSaveDebounce = nil,
	SidebarButtons = {},
	SearchableItems = {},
	GridRefreshThread = nil,
	AutoCollectThread = nil,
	AutoShovelThread = nil,
}

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 5: CACHE (invalidated when stale)
-- ═══════════════════════════════════════════════════════════════════════

local Cache = {
	CachedPlot = nil,
	CachedPlotParts = nil,
	CachedPartOptions = nil,
	PlantPositions = nil,
	CurrentPlantIndex = 1,
	LastConfigHash = nil,
	FakePlot = nil,
	TweenInfo = {},
	PlantIdBySeedName = nil,
	FruitIdBySeedName = nil,
}

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 6: THEMES
-- ═══════════════════════════════════════════════════════════════════════

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

local Theme = Themes[Persist.Config.Theme] or Themes.Dark

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 7: MEMORY MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════

local Connections = {}
local Threads = {}
local Instances = {}

local function TrackConnection(connection)
	if typeof(connection) == "RBXScriptConnection" then
		Connections[#Connections + 1] = connection
	end
	return connection
end

local function DisconnectAll()
	for i = 1, #Connections do
		local c = Connections[i]
		if c and c.Connected then
			c:Disconnect()
		end
		Connections[i] = nil
	end
end

local function TrackThread(thread)
	if type(thread) == "thread" then
		Threads[#Threads + 1] = thread
	end
	return thread
end

local function CancelAllThreads()
	for i = 1, #Threads do
		local t = Threads[i]
		if t and type(t) == "thread" then
			pcall(function()
				task_cancel(t)
			end)
		end
		Threads[i] = nil
	end
end

local function TrackInstance(name, instance)
	if typeof(instance) == "Instance" then
		Instances[name] = instance
	end
	return instance
end

local function DestroyAllInstances()
	for name, inst in pairs(Instances) do
		if typeof(inst) == "Instance" and inst.Parent then
			inst:Destroy()
		end
		Instances[name] = nil
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 8: UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.Clamp(value, min, max)
	return value < min and min or (value > max and max or value)
end

function Utils.ValidateConfigValue(key, value)
	local schema = ConfigSchema[key]
	if not schema then
		return value
	end
	local valueType = typeof(value)

	if schema.type == "number" then
		if valueType ~= "number" then
			return schema.default
		end
		return Utils.Clamp(value, schema.min, schema.max)
	elseif schema.type == "string" then
		return valueType == "string" and value or schema.default
	elseif schema.type == "boolean" then
		return valueType == "boolean" and value or schema.default
	elseif schema.type == "table" then
		return valueType == "table" and value or table_clone(schema.default)
	end
	return schema.default
end

function Utils.FormatSelectedSeeds(selectedTable, maxDisplay)
	maxDisplay = maxDisplay or 10
	local names = {}
	for seedName, selected in pairs(selectedTable) do
		if selected then
			names[#names + 1] = seedName
		end
	end
	table_sort(names)
	local count = #names
	if count == 0 then
		return "Selected (0): None"
	end
	local shown = {}
	for i = 1, math_min(count, maxDisplay) do
		shown[i] = names[i]
	end
	local text = table_concat(shown, ", ")
	if count > maxDisplay then
		text = text .. " ..."
	end
	return string_format("Selected (%d): %s", count, text)
end

function Utils.FormatPrice(price)
	if not price or price <= 0 then
		return "$0"
	end
	if price >= 1000 then
		return string_format("$%.2fK", price / 1000)
	end
	return "$" .. tostring(price)
end

function Utils.FormatPositionKey(pos, precision)
	precision = precision or CONSTANTS.OCCUPIED_LOOKUP_PRECISION
	local mult = precision * 10
	local x = math_floor(pos.X * mult + 0.5) / mult
	local z = math_floor(pos.Z * mult + 0.5) / mult
	return string_format("%.1f,%.1f", x, z)
end

function Utils.GetPlayerPosition()
	local character = Player.Character
	if not character then
		return nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or nil
end

function Utils.IsPointInGui(screenPoint, guiObject)
	if not guiObject or not guiObject.Parent then
		return false
	end
	local ap = guiObject.AbsolutePosition
	local as = guiObject.AbsoluteSize
	return screenPoint.X >= ap.X
		and screenPoint.X <= ap.X + as.X
		and screenPoint.Y >= ap.Y
		and screenPoint.Y <= ap.Y + as.Y
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 9: TWEEN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local TweenSystem = {}

function TweenSystem.GetTweenInfo(duration, style, direction)
	style = style or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	duration = duration or Persist.Config.AnimationSpeed
	local key = string_format("%.2f_%s_%s", duration, tostring(style), tostring(direction))
	local cached = Cache.TweenInfo[key]
	if not cached then
		cached = TweenInfo.new(duration, style, direction)
		Cache.TweenInfo[key] = cached
	end
	return cached
end

function TweenSystem.Tween(instance, properties, duration, callback)
	if not instance or not instance.Parent then
		if callback then
			callback()
		end
		return nil
	end
	if Persist.Config.DisableAnimations then
		for key, value in pairs(properties) do
			instance[key] = value
		end
		if callback then
			callback()
		end
		return nil
	end
	local tweenInfo = TweenSystem.GetTweenInfo(duration)
	local tween = Services.TweenService:Create(instance, tweenInfo, properties)
	if callback then
		TrackConnection(tween.Completed:Connect(callback))
	end
	tween:Play()
	return tween
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 10: NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local NotificationSystem = {}

function NotificationSystem.Notify(title, message, notifType, duration)
	notifType = notifType or "Info"
	duration = duration or Persist.Config.NotificationDuration
	local accent = CONSTANTS.NOTIF_COLORS[notifType] or CONSTANTS.NOTIF_COLORS.Info

	while State.ActiveNotifs >= CONSTANTS.MAX_NOTIFICATIONS do
		task_wait(0.1)
	end

	State.ActiveNotifs += 1
	local notifIndex = State.ActiveNotifs

	local screenGui = Instances.ScreenGui
	if not screenGui then
		return
	end

	local frame = Instance.new("Frame")
	frame.Name = "Notification_" .. notifIndex
	frame.Parent = screenGui
	frame.BackgroundColor3 = Theme.Card
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(1, 20, 0, 20 + (notifIndex - 1) * CONSTANTS.NOTIFICATION_HEIGHT)
	frame.Size = UDim2.new(0, CONSTANTS.NOTIFICATION_WIDTH, 0, CONSTANTS.NOTIFICATION_HEIGHT)
	frame.ZIndex = CONSTANTS.Z_NOTIFICATION
	frame.Active = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = frame

	local bar = Instance.new("Frame")
	bar.Parent = frame
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(0, 4, 1, 0)
	bar.ZIndex = CONSTANTS.Z_NOTIFICATION + 1
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 8)
	barCorner.Parent = bar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Parent = frame
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 14, 0, 8)
	titleLabel.Size = UDim2.new(1, -28, 0, 18)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = title
	titleLabel.TextColor3 = Theme.TextPrimary
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = CONSTANTS.Z_NOTIFICATION + 1

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Parent = frame
	messageLabel.BackgroundTransparency = 1
	messageLabel.Position = UDim2.new(0, 14, 0, 26)
	messageLabel.Size = UDim2.new(1, -28, 0, 28)
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.Text = message
	messageLabel.TextColor3 = Theme.TextSecondary
	messageLabel.TextSize = 11
	messageLabel.TextWrapped = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.ZIndex = CONSTANTS.Z_NOTIFICATION + 1

	TweenSystem.Tween(frame, {
		Position = UDim2.new(1, -CONSTANTS.NOTIFICATION_WIDTH - 20, 0, frame.Position.Y.Offset),
	}, 0.3)

	task_delay(duration, function()
		if not frame or not frame.Parent then
			State.ActiveNotifs = math_max(0, State.ActiveNotifs - 1)
			return
		end
		TweenSystem.Tween(
			frame,
			{
				Position = UDim2.new(1, 20, 0, frame.Position.Y.Offset),
			},
			0.3,
			function()
				if frame and frame.Parent then
					frame:Destroy()
				end
				State.ActiveNotifs = math_max(0, State.ActiveNotifs - 1)
			end
		)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 11: LASER VISUALIZATION
-- ═══════════════════════════════════════════════════════════════════════

local LaserSystem = {}

function LaserSystem.Clear()
	local beams = Instances.LaserBeams
	if beams then
		for i = 1, #beams do
			local beam = beams[i]
			if beam then
				pcall(function()
					beam:Destroy()
				end)
			end
			beams[i] = nil
		end
	end
end

function LaserSystem.CreateBeam(startPos, endPos, color, duration)
	local folder = Instances.LaserFolder
	if not folder or not folder.Parent then
		folder = Instance.new("Folder")
		folder.Name = "LRX_Lasers"
		folder.Parent = Services.Workspace
		Instances.LaserFolder = folder
	end

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

	local distance = (endPos - startPos).Magnitude
	beamPart.Size = Vector3.new(CONSTANTS.LASER_BEAM_THICKNESS, CONSTANTS.LASER_BEAM_THICKNESS, distance)
	beamPart.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
	beamPart.Parent = folder

	local glow = Instance.new("PointLight")
	glow.Color = beamPart.Color
	glow.Brightness = 2
	glow.Range = 6
	glow.Parent = beamPart

	local beams = Instances.LaserBeams
	if not beams then
		beams = {}
		Instances.LaserBeams = beams
	end
	beams[#beams + 1] = beamPart

	if duration then
		task_delay(duration, function()
			if beamPart and beamPart.Parent then
				TweenSystem.Tween(beamPart, { Transparency = 1 }, 0.3, function()
					if beamPart and beamPart.Parent then
						beamPart:Destroy()
					end
				end)
			end
		end)
	end
	return beamPart
end

function LaserSystem.ScanPlot(plot, scanDuration)
	LaserSystem.Clear()
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
			parts[#parts + 1] = child
		end
	end
	if #parts == 0 then
		return
	end

	scanDuration = scanDuration or CONSTANTS.LASER_SCAN_DURATION

	local minY = math_huge
	local allCorners = {}
	for _, part in ipairs(parts) do
		minY = math_min(minY, part.Position.Y)
		local hs = part.Size / 2
		local cf = part.CFrame
		for dx = -1, 1, 2 do
			for dz = -1, 1, 2 do
				allCorners[#allCorners + 1] = cf * Vector3.new(dx * hs.X, hs.Y, dz * hs.Z)
			end
		end
	end

	local minX, maxX = math_huge, -math_huge
	local minZ, maxZ = math_huge, -math_huge
	for _, corner in ipairs(allCorners) do
		minX = math_min(minX, corner.X)
		maxX = math_max(maxX, corner.X)
		minZ = math_min(minZ, corner.Z)
		maxZ = math_max(maxZ, corner.Z)
	end

	local sweepHeight = minY + 2
	local sweepCount = CONSTANTS.LASER_SWEEP_COUNT
	local stepDelay = scanDuration / sweepCount

	for i = 1, sweepCount do
		task_delay((i - 1) * stepDelay, function()
			if not State.ScriptRunning then
				return
			end
			local t = (i - 1) / math_max(1, sweepCount - 1)
			local z = minZ + (maxZ - minZ) * t
			LaserSystem.CreateBeam(
				Vector3.new(minX, sweepHeight, z),
				Vector3.new(maxX, sweepHeight, z),
				Color3.fromRGB(0, 255, 255),
				0.4
			)
		end)
	end

	for i = 1, sweepCount do
		task_delay((i - 1) * stepDelay + 0.05, function()
			if not State.ScriptRunning then
				return
			end
			local t = (i - 1) / math_max(1, sweepCount - 1)
			local x = minX + (maxX - minX) * t
			LaserSystem.CreateBeam(
				Vector3.new(x, sweepHeight + 0.5, minZ),
				Vector3.new(x, sweepHeight + 0.5, maxZ),
				Color3.fromRGB(255, 0, 255),
				0.4
			)
		end)
	end

	task_delay(0.1, function()
		if not State.ScriptRunning then
			return
		end
		local h = sweepHeight
		LaserSystem.CreateBeam(Vector3.new(minX, h, minZ), Vector3.new(maxX, h, maxZ), Color3.fromRGB(50, 205, 50), 0.6)
		LaserSystem.CreateBeam(Vector3.new(minX, h, maxZ), Vector3.new(maxX, h, minZ), Color3.fromRGB(50, 205, 50), 0.6)
	end)

	task_delay(scanDuration * 0.5, function()
		if not State.ScriptRunning then
			return
		end
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
			LaserSystem.CreateBeam(a, b, Color3.fromRGB(255, 215, 0), 0.8)
		end
	end)

	task_delay(scanDuration + 0.5, LaserSystem.Clear)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 12: GRID DOTS VISUALIZATION
-- ═══════════════════════════════════════════════════════════════════════

local GridSystem = {}

function GridSystem.Clear()
	-- Cancel any in-progress refresh so old dots don't leak after clear
	if State.GridRefreshThread and type(State.GridRefreshThread) == "thread" then
		local t = State.GridRefreshThread
		State.GridRefreshThread = nil
		pcall(function()
			task_cancel(t)
		end)
	end
	local dots = Instances.GridDots
	if dots then
		for i = 1, #dots do
			local dot = dots[i]
			if dot then
				pcall(function()
					dot:Destroy()
				end)
			end
			dots[i] = nil
		end
	end
	local folder = Instances.DotsFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
		Instances.DotsFolder = nil
	end
end

function GridSystem.Refresh()
	GridSystem.Clear()
	if not Persist.Config.ShowGridDots then
		return
	end

	local plot = PlotSystem.FindPlayerPlot()
	if not plot then
		warn("[GridDots] Could not find player plot.")
		return
	end

	local positions = SeedPlacer.GetPlantPositions()
	if not positions or #positions == 0 then
		warn("[GridDots] No plant positions generated.")
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "LRX_GridDots"
	folder.Parent = Services.Workspace
	Instances.DotsFolder = folder

	local colors = CONSTANTS.GRID_DOT_COLORS
	local colorCount = #colors
	local dotSize = Vector3.new(CONSTANTS.GRID_DOT_SIZE, CONSTANTS.GRID_DOT_SIZE, CONSTANTS.GRID_DOT_SIZE)
	local yOffset = Vector3.new(0, CONSTANTS.GRID_DOT_Y_OFFSET, 0)
	local batchSize = CONSTANTS.GRID_DOT_BATCH_SIZE
	local batchDelay = CONSTANTS.GRID_DOT_BATCH_DELAY
	local total = #positions

	local dots = {}
	Instances.GridDots = dots

	-- Single tracked thread so it can be cancelled on cleanup/toggle-off
	local refreshThread = task_spawn(function()
		for batchStart = 1, total, batchSize do
			-- Abort if script stopped or user toggled off
			if not State.ScriptRunning or not Persist.Config.ShowGridDots then
				break
			end

			for i = batchStart, math_min(batchStart + batchSize - 1, total) do
				if not State.ScriptRunning or not Persist.Config.ShowGridDots then
					break
				end

				local posData = positions[i]
				local dot = Instance.new("Part")
				dot.Name = "GridDot"
				dot.Anchored = true
				dot.CanCollide = false
				dot.CanQuery = false
				dot.CanTouch = false
				dot.CastShadow = false
				dot.Material = Enum.Material.Neon
				dot.Color = colors[((i - 1) % colorCount) + 1]
				dot.Shape = Enum.PartType.Ball
				dot.Size = dotSize
				dot.Position = posData.Pos + yOffset
				dot.Parent = folder
				dot.Transparency = 0.15
				dots[#dots + 1] = dot
			end

			-- Yield between batches to keep frame rate stable
			if batchStart + batchSize - 1 < total then
				task_wait(batchDelay)
			end
		end

		-- Only notify if we actually finished while still enabled
		if Persist.Config.ShowGridDots and State.ScriptRunning then
			NotificationSystem.Notify(
				"Plot Visualizer",
				string_format("Showing %d grid dots (all spots)", #dots),
				"Success",
				2
			)
		end
	end)

	TrackThread(refreshThread)
	State.GridRefreshThread = refreshThread
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 13: PLOT DETECTION
-- ═══════════════════════════════════════════════════════════════════════

PlotSystem = {}

function PlotSystem.FindPlayerPlot()
	if Cache.CachedPlot and Cache.CachedPlot.Parent then
		return Cache.CachedPlot
	end

	local gardensFolder = Services.Workspace:FindFirstChild("Gardens")
	if not gardensFolder then
		warn("[PlotSystem] workspace.Gardens not found.")
		return nil
	end

	local plots = gardensFolder:GetChildren()

	-- Strategy 1: Owner attribute match
	for _, plot in ipairs(plots) do
		local ownerName = plot:GetAttribute("Owner")
		local ownerId = plot:GetAttribute("OwnerUserId")
		if ownerName == Player.Name or ownerId == Player.UserId then
			Cache.CachedPlot = plot
			Cache.CachedPlotParts = nil
			Cache.CachedPartOptions = nil
			return plot
		end
	end

	-- Strategy 2: Position-based detection
	local playerPos = Utils.GetPlayerPosition()
	if not playerPos then
		warn("[PlotSystem] Could not find plot for player:", Player.Name)
		return nil
	end

	local candidates = {}
	for _, plot in ipairs(plots) do
		local visual = plot:FindFirstChild("Visual")
		if not visual then
			continue
		end

		local columns = {}
		for _, child in ipairs(visual:GetChildren()) do
			if child:IsA("BasePart") and child.Name:match("^PlantAreaColumn") then
				columns[#columns + 1] = child
			end
		end
		if #columns == 0 then
			continue
		end

		local inside = false
		for _, col in ipairs(columns) do
			local localPos = col.CFrame:PointToObjectSpace(playerPos)
			local half = col.Size / 2
			if
				math_abs(localPos.X) <= half.X + CONSTANTS.OCCUPANCY_TOLERANCE
				and math_abs(localPos.Y) <= half.Y + 10
				and math_abs(localPos.Z) <= half.Z + CONSTANTS.OCCUPANCY_TOLERANCE
			then
				inside = true
				break
			end
		end

		if inside then
			local center = Vector3.zero
			for _, col in ipairs(columns) do
				center += col.Position
			end
			center /= #columns
			candidates[#candidates + 1] = { Plot = plot, Distance = (center - playerPos).Magnitude }
		end
	end

	if #candidates > 0 then
		table_sort(candidates, function(a, b)
			return a.Distance < b.Distance
		end)
		Cache.CachedPlot = candidates[1].Plot
		Cache.CachedPlotParts = nil
		Cache.CachedPartOptions = nil
		return candidates[1].Plot
	end

	warn("[PlotSystem] Could not find plot for player:", Player.Name)
	return nil
end

function PlotSystem.DetectPlotParts(plot)
	if not plot then
		return {}
	end
	if Cache.CachedPlotParts and Cache.CachedPlot == plot then
		return Cache.CachedPlotParts
	end

	local visual = plot:FindFirstChild("Visual")
	if not visual then
		return {}
	end

	local parts = {}
	for _, child in ipairs(visual:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^PlantAreaColumn") then
			parts[#parts + 1] = child
		end
	end

	Cache.CachedPlotParts = parts
	return parts
end

function PlotSystem.BuildPartOptions(parts)
	if Cache.CachedPartOptions then
		return Cache.CachedPartOptions
	end

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
		options[#options + 1] = { Label = displayName, Value = value, Part = part }
	end

	Cache.CachedPartOptions = options
	return options
end

function PlotSystem.FindPartByValue(parts, value)
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

function PlotSystem.ClearCache()
	Cache.CachedPlot = nil
	Cache.CachedPlotParts = nil
	Cache.CachedPartOptions = nil
end

function PlotSystem.GetDetectionInfo()
	local plot = PlotSystem.FindPlayerPlot()
	if not plot then
		return { Parts = {}, PartOptions = {}, PartNames = {}, PlotName = "None", PlotInstance = nil }
	end

	local parts = PlotSystem.DetectPlotParts(plot)
	local options = PlotSystem.BuildPartOptions(parts)
	local names = {}
	for _, opt in ipairs(options) do
		names[#names + 1] = opt.Label
	end

	return {
		Parts = parts,
		PartOptions = options,
		PartNames = names,
		PlotName = plot.Name,
		PlotInstance = plot,
	}
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 14: SEED PLACER
-- ═══════════════════════════════════════════════════════════════════════

SeedPlacer = {}

-- ─── Configuration Hashing ─────────────────────────────────────────────

local function GetConfigHash()
	return string_format(
		"%s|%s|%.2f",
		Persist.Config.PlantingArea or "All",
		Persist.Config.PlantingPattern or "LeftToRight",
		Persist.Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING
	)
end

-- ─── Position Generation ───────────────────────────────────────────────

local function GeneratePlantPositions(targetParts, spacing)
	if #targetParts == 0 then
		return {}
	end
	spacing = math_max(0.1, spacing)
	local positions = {}
	local seenKeys = {}
	local iterationCount = 0
	local yieldInterval = CONSTANTS.YIELD_INTERVAL

	for _, part in ipairs(targetParts) do
		local cf = part.CFrame
		local size = part.Size
		local hs = size / 2

		-- The TOP surface in local space is Y = +hs.Y
		local topSurfaceLocal = Vector3.new(0, hs.Y, 0)
		local topSurfaceWorld = cf * topSurfaceLocal

		-- Calculate grid dimensions in local space
		local cellsX = math_max(1, math_floor(size.X / spacing))
		local cellsZ = math_max(1, math_floor(size.Z / spacing))

		-- Center the grid within the part's local space
		local startX = -hs.X + spacing / 2
		local startZ = -hs.Z + spacing / 2
		local endX = hs.X - spacing / 2
		local endZ = hs.Z - spacing / 2

		-- Edge case: if part is smaller than spacing, place one dot in center
		if startX > endX then
			startX = 0
			endX = 0
		end
		if startZ > endZ then
			startZ = 0
			endZ = 0
		end

		local localX = startX
		while localX <= endX + 0.001 do
			local localZ = startZ
			while localZ <= endZ + 0.001 do
				iterationCount += 1
				if iterationCount % yieldInterval == 0 then
					task_wait()
				end

				-- Generate in local space then transform to world space via CFrame.
				-- This correctly handles rotated parts.
				local localPos = Vector3.new(localX, hs.Y, localZ)
				local worldPos = cf * localPos

				-- Round to match game's grid precision
				local finalPos =
					Vector3.new(math_floor(worldPos.X + 0.5), topSurfaceWorld.Y, math_floor(worldPos.Z + 0.5))

				local key = Utils.FormatPositionKey(finalPos)

				if not seenKeys[key] then
					seenKeys[key] = true
					positions[#positions + 1] = { Pos = finalPos, Part = part }
				end

				if localZ >= endZ - 0.001 then
					break
				end
				localZ = localZ + spacing
			end

			if localX >= endX - 0.001 then
				break
			end
			localX = localX + spacing
		end
	end

	return positions
end

-- ─── Pattern Application ───────────────────────────────────────────────

local function ApplyPattern(positions, pattern)
	local count = #positions
	if count == 0 then
		return positions
	end

	if pattern == "LeftToRight" then
		return positions
	elseif pattern == "RightToLeft" then
		local result = table_create(count)
		for i = count, 1, -1 do
			result[count - i + 1] = positions[i]
		end
		return result
	elseif pattern == "OutsideToCenter" then
		local result = table_create(count)
		local left = 1
		local right = count
		while left <= right do
			result[#result + 1] = positions[left]
			left += 1
			if left <= right then
				result[#result + 1] = positions[right]
				right -= 1
			end
		end
		return result
	elseif pattern == "CenterToOutside" then
		local result = table_create(count)
		local mid = math_ceil(count / 2)
		result[1] = positions[mid]
		local offset = 1
		while true do
			local added = false
			if mid - offset >= 1 then
				result[#result + 1] = positions[mid - offset]
				added = true
			end
			if mid + offset <= count then
				result[#result + 1] = positions[mid + offset]
				added = true
			end
			if not added then
				break
			end
			offset += 1
		end
		return result
	elseif pattern == "Middle" then
		local minX, maxX = math_huge, -math_huge
		local minZ, maxZ = math_huge, -math_huge
		for _, posData in ipairs(positions) do
			local p = posData.Pos
			minX = math_min(minX, p.X)
			maxX = math_max(maxX, p.X)
			minZ = math_min(minZ, p.Z)
			maxZ = math_max(maxZ, p.Z)
		end
		local step = math_max(0.1, Persist.Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING)
		local cols = math_max(1, math_floor((maxX - minX) / step + 0.5) + 1)
		local rows = math_max(1, math_floor((maxZ - minZ) / step + 0.5) + 1)

		local cellMap = table_create(rows)
		for r = 1, rows do
			cellMap[r] = table_create(cols)
		end

		for _, posData in ipairs(positions) do
			local p = posData.Pos
			local c = math_floor((p.X - minX) / step + 0.5) + 1
			local r = math_floor((p.Z - minZ) / step + 0.5) + 1
			c = math_clamp(c, 1, cols)
			r = math_clamp(r, 1, rows)
			if not cellMap[r][c] then
				cellMap[r][c] = {}
			end
			cellMap[r][c][#cellMap[r][c] + 1] = posData
		end

		local result = table_create(count)
		local centerR = math_ceil(rows / 2)
		local centerC = math_ceil(cols / 2)
		local dr = { 0, 1, 0, -1 }
		local dc = { 1, 0, -1, 0 }
		local dir = 0
		local steps = 1
		local r, c = centerR, centerC

		if cellMap[r] and cellMap[r][c] then
			for _, posData in ipairs(cellMap[r][c]) do
				result[#result + 1] = posData
			end
		end

		while #result < count do
			for _ = 1, 2 do
				for _ = 1, steps do
					r += dr[dir + 1]
					c += dc[dir + 1]
					if r >= 1 and r <= rows and c >= 1 and c <= cols then
						if cellMap[r] and cellMap[r][c] then
							for _, posData in ipairs(cellMap[r][c]) do
								result[#result + 1] = posData
							end
						end
					end
				end
				dir = (dir + 1) % 4
			end
			steps += 1
		end
		return result
	elseif pattern == "Random" then
		local result = table_create(count)
		for i = 1, count do
			result[i] = positions[i]
		end
		for i = count, 2, -1 do
			local j = math_random(1, i)
			result[i], result[j] = result[j], result[i]
		end
		return result
	end

	return positions
end

-- ─── Occupancy Lookup ──────────────────────────────────────────────────

local function BuildOccupiedLookup()
	local occupied = {}

	if not Cache.FakePlot or not Cache.FakePlot.Parent then
		local controllers = Player:FindFirstChild("PlayerScripts")
		local seedInspect = controllers and controllers:FindFirstChild("SeedInspectController")
		Cache.FakePlot = seedInspect and seedInspect:FindFirstChild("FakePlot")
	end

	local plantsFolder = Cache.FakePlot and Cache.FakePlot:FindFirstChild("Plants")
	if not plantsFolder then
		local plot = PlotSystem.FindPlayerPlot()
		plantsFolder = plot and plot:FindFirstChild("Plants")
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
			local key = Utils.FormatPositionKey(plantPos)
			occupied[key] = true
		end
	end

	return occupied
end

local function IsSpotEmpty(spotPosition, occupiedLookup)
	local key = Utils.FormatPositionKey(spotPosition)
	return not occupiedLookup[key]
end

-- ─── Public API ────────────────────────────────────────────────────────

function SeedPlacer.GetPlantPositions()
	local currentHash = GetConfigHash()
	if Cache.PlantPositions and Cache.LastConfigHash == currentHash then
		return Cache.PlantPositions
	end

	local plot = PlotSystem.FindPlayerPlot()
	if not plot then
		return nil
	end

	local allParts = PlotSystem.DetectPlotParts(plot)
	local targetParts = {}

	if Persist.Config.PlantingArea == "All" or not Persist.Config.PlantingArea or Persist.Config.PlantingArea == "" then
		for _, part in ipairs(allParts) do
			targetParts[#targetParts + 1] = part
		end
	else
		local selectedPart = PlotSystem.FindPartByValue(allParts, Persist.Config.PlantingArea)
		if selectedPart then
			targetParts[1] = selectedPart
		else
			for _, part in ipairs(allParts) do
				targetParts[#targetParts + 1] = part
			end
		end
	end

	if #targetParts == 0 then
		warn("[SeedPlacer] No target parts found for area: " .. tostring(Persist.Config.PlantingArea))
		return nil
	end

	local positions =
		GeneratePlantPositions(targetParts, Persist.Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING)
	positions = ApplyPattern(positions, Persist.Config.PlantingPattern or "LeftToRight")

	Cache.PlantPositions = positions
	Cache.LastConfigHash = currentHash
	return positions
end

function SeedPlacer.ClearCache()
	Cache.PlantPositions = nil
	Cache.CurrentPlantIndex = 1
	Cache.LastConfigHash = nil
end

function SeedPlacer.RunCycle()
	if not PlantRemote then
		warn("[SeedPlacer] PlantSeed remote not available.")
		return
	end

	local allSpots = SeedPlacer.GetPlantPositions()
	if not allSpots then
		return
	end

	local enabledSeeds = {}
	for seedName, enabled in pairs(Persist.Config.SelectedPlaceSeeds or {}) do
		if enabled then
			enabledSeeds[#enabledSeeds + 1] = seedName
		end
	end
	if #enabledSeeds == 0 then
		return
	end

	local occupiedLookup = BuildOccupiedLookup()
	local totalSpots = #allSpots
	local maxPlantAmount =
		math_min(Persist.Config.PlaceAmount or CONSTANTS.DEFAULT_PLACE_AMOUNT, CONSTANTS.MAX_PLANT_AMOUNT)
	local plantedCount = 0
	local seedIndex = 1
	local checkedCount = 0
	local delay = math_max(0, Persist.Config.PlantDelay or CONSTANTS.DEFAULT_PLANT_DELAY)
	local idx = Cache.CurrentPlantIndex or 1

	while plantedCount < maxPlantAmount and checkedCount < totalSpots do
		if not Persist.Config.EnableSeedPlacer then
			break
		end

		local spot = allSpots[idx]
		if not spot or not spot.Part then
			idx = 1
			break
		end

		checkedCount += 1
		if IsSpotEmpty(spot.Pos, occupiedLookup) then
			local seedName = enabledSeeds[seedIndex]
			seedIndex = seedIndex % #enabledSeeds + 1

			local success, err = pcall(function()
				PlantRemote:Fire(spot.Pos, seedName, spot.Part)
			end)
			if not success then
				warn("[SeedPlacer] PlantSeed failed at spot " .. tostring(idx) .. ":", err)
			end
			plantedCount += 1
			if plantedCount < maxPlantAmount then
				task_wait(delay)
			end
		end

		idx += 1
		if idx > totalSpots then
			idx = 1
		end
	end

	Cache.CurrentPlantIndex = idx

	if plantedCount > 0 then
		print(string_format("[SeedPlacer] Planted %d seeds this cycle.", plantedCount))
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 14.5: AUTO FARM SYSTEM (Collect & Shovel) - PATCHED v4
-- ═══════════════════════════════════════════════════════════════════════

local AutoFarmSystem = {}
AutoFarmSystem.DEBUG = true

local function DebugPrint(...)
	if AutoFarmSystem.DEBUG then
		warn("[LRX AutoFarm]", ...)
	end
end

-- ─── Helpers ───────────────────────────────────────────────────────────

local function FindPlantsFolder(plot)
	if not plot then
		return nil
	end
	local folder = plot:FindFirstChild("Plants")
	if folder then
		return folder
	end
	local alts = { "Plant", "plant", "plants", "Crops", "crops", "Crop", "CropFolder" }
	for _, name in ipairs(alts) do
		folder = plot:FindFirstChild(name)
		if folder then
			return folder
		end
	end
	return nil
end

local function GetPlantSeedName(plant)
	if not plant then
		return nil
	end
	local attrNames = { "SeedName", "Seed", "seedName", "CropName", "Crop", "PlantType", "Type" }
	for _, name in ipairs(attrNames) do
		local val = plant:GetAttribute(name)
		if val and typeof(val) == "string" and #val > 0 then
			return val
		end
	end
	for _, name in ipairs(attrNames) do
		local obj = plant:FindFirstChild(name)
		if obj and obj:IsA("StringValue") and obj.Value and #obj.Value > 0 then
			return obj.Value
		end
	end
	return plant.Name
end

local function GetPlantId(plant)
	if not plant then
		return nil
	end
	local attrNames = { "PlantId", "Id", "GUID", "ID", "PlantID", "UniqueId", "uniqueId" }
	for _, name in ipairs(attrNames) do
		local val = plant:GetAttribute(name)
		if val then
			return tostring(val)
		end
	end
	for _, name in ipairs(attrNames) do
		local obj = plant:FindFirstChild(name)
		if obj and obj:IsA("ValueBase") then
			return tostring(obj.Value)
		end
	end
	return plant.Name
end

local function IsPlantReady(plant)
	if not plant then
		return false
	end
	if plant:GetAttribute("PlantGrowthReady") == true then
		return true
	end
	if plant:GetAttribute("Ready") == true then
		return true
	end
	if plant:GetAttribute("HarvestReady") == true then
		return true
	end
	if plant:GetAttribute("Grown") == true then
		return true
	end
	if plant:GetAttribute("Mature") == true then
		return true
	end
	-- Any plant with Age >= MaxAge is ready
	local age = plant:GetAttribute("Age")
	local maxAge = plant:GetAttribute("MaxAge")
	if age and maxAge and age >= maxAge then
		return true
	end
	return false
end

-- ─── CRITICAL FIX: Get Fruit ID with fallback ──────────────────────────

local function GetFruitId(plant)
	if not plant then
		return nil
	end

	-- 1. Try Fruits folder children
	local fruits = plant:FindFirstChild("Fruits")
	if fruits then
		for _, fruit in ipairs(fruits:GetChildren()) do
			local fid = fruit:GetAttribute("FruitId")
				or fruit:GetAttribute("Id")
				or fruit:GetAttribute("ID")
				or fruit.Name
			if fid then
				return tostring(fid)
			end
		end
	end

	-- 2. Try FruitSpawnLocations children
	local fruitSpawns = plant:FindFirstChild("FruitSpawnLocations")
	if fruitSpawns then
		for _, fruit in ipairs(fruitSpawns:GetChildren()) do
			local fid = fruit:GetAttribute("FruitId")
				or fruit:GetAttribute("Id")
				or fruit:GetAttribute("ID")
				or fruit.Name
			if fid then
				return tostring(fid)
			end
		end
	end

	-- 3. CRITICAL: Fallback to PlantId for plants with empty fruit folders
	-- Carrot and Bamboo have PlantGrowthReady=true but empty Fruits folders
	local plantId = GetPlantId(plant)
	if plantId then
		DebugPrint("Using PlantId as FruitId fallback:", plantId)
		return plantId
	end

	return nil
end

local function SafeFireRemote(remote, ...)
	if not remote then
		DebugPrint("Remote is nil")
		return false, "nil"
	end
	local ok, err = pcall(function(...)
		if typeof(remote) == "table" and remote.Fire then
			remote:Fire(...)
		elseif typeof(remote) == "Instance" and remote:IsA("RemoteEvent") then
			remote:FireServer(...)
		elseif typeof(remote) == "Instance" and remote:IsA("RemoteFunction") then
			remote:InvokeServer(...)
		else
			error("Bad remote type: " .. typeof(remote))
		end
	end, ...)
	if not ok then
		DebugPrint("Remote fire failed:", err)
		return false, err
	end
	return true, nil
end

-- ─── Scan Plot ─────────────────────────────────────────────────────────

function AutoFarmSystem.ScanPlotData()
	local plot = PlotSystem.FindPlayerPlot()
	if not plot then
		return {}, {}
	end
	local plantsFolder = FindPlantsFolder(plot)
	if not plantsFolder then
		return {}, {}
	end

	local plantMap = {}
	local fruitMap = {}

	for _, plant in ipairs(plantsFolder:GetChildren()) do
		local seedName = GetPlantSeedName(plant)
		local plantId = GetPlantId(plant)
		if not plantId then
			continue
		end

		plantMap[seedName] = { PlantId = plantId, Instance = plant }

		local fruitId = GetFruitId(plant)
		if fruitId then
			local ready = IsPlantReady(plant)
			if not fruitMap[seedName] then
				fruitMap[seedName] = {}
			end
			table_insert(fruitMap[seedName], {
				FruitId = fruitId,
				PlantId = plantId,
				Instance = plant,
				Ready = ready,
			})
		end
	end

	Cache.PlantIdBySeedName = plantMap
	Cache.FruitIdBySeedName = fruitMap
	return plantMap, fruitMap
end

function AutoFarmSystem.GetAvailableCollectNames()
	local _, fruitMap = AutoFarmSystem.ScanPlotData()
	local names = {}
	for seedName, fruits in pairs(fruitMap) do
		for _, f in ipairs(fruits) do
			if f.Ready then
				names[#names + 1] = seedName
				break
			end
		end
	end
	table_sort(names)
	return names
end

function AutoFarmSystem.GetAvailableShovelNames()
	local plantMap = Cache.PlantIdBySeedName
	if not plantMap then
		plantMap = AutoFarmSystem.ScanPlotData()
	end
	local names = {}
	for seedName, _ in pairs(plantMap or {}) do
		names[#names + 1] = seedName
	end
	table_sort(names)
	return names
end

-- ─── Auto Collect ──────────────────────────────────────────────────────

function AutoFarmSystem.StartCollect()
	if State.AutoCollectThread then
		return
	end
	if not CollectFruitRemote then
		NotificationSystem.Notify("Auto Farm", "CollectFruit remote not found", "Error", 3)
		return
	end

	DebugPrint("Starting Auto Collect...")
	NotificationSystem.Notify("Auto Farm", "Auto Collect started", "Success", 2)

	State.AutoCollectThread = task_spawn(function()
		while Persist.Config.EnableAutoCollect and State.ScriptRunning do
			local plot = PlotSystem.FindPlayerPlot()
			if plot then
				local plantsFolder = FindPlantsFolder(plot)
				if plantsFolder then
					for _, plant in ipairs(plantsFolder:GetChildren()) do
						if not Persist.Config.EnableAutoCollect or not State.ScriptRunning then
							break
						end

						local seedName = GetPlantSeedName(plant)
						local selected = Persist.Config.SelectedCollectFruits
						local hasSelection = false
						for _, _ in pairs(selected) do
							hasSelection = true
							break
						end

						if hasSelection and not selected[seedName] then
							continue
						end

						if not IsPlantReady(plant) then
							continue
						end

						local plantId = GetPlantId(plant)
						local fruitId = GetFruitId(plant)

						-- CRITICAL: If no fruitId, use plantId as fallback
						if not fruitId then
							fruitId = plantId
							DebugPrint("Fallback: Using PlantId as FruitId for", seedName)
						end

						DebugPrint("COLLECTING:", seedName, "| plantId=", plantId, "| fruitId=", fruitId)

						-- Try signatures
						local ok = SafeFireRemote(CollectFruitRemote, plantId, fruitId)
						if not ok then
							ok = SafeFireRemote(CollectFruitRemote, plantId)
						end
						if ok then
							DebugPrint("  -> SUCCESS")
						else
							DebugPrint("  -> FAILED")
						end
						task_wait(0.12)
					end
				end
			end
			task_wait(0.4)
		end
		State.AutoCollectThread = nil
	end)

	TrackThread(State.AutoCollectThread)
end

function AutoFarmSystem.StopCollect()
	Persist.Config.EnableAutoCollect = false
	State.AutoCollectThread = nil
	NotificationSystem.Notify("Auto Farm", "Auto Collect stopped", "Info", 2)
end

-- ─── Auto Shovel ───────────────────────────────────────────────────────

function AutoFarmSystem.StartShovel()
	if State.AutoShovelThread then
		return
	end
	if not UseShovelRemote then
		NotificationSystem.Notify("Auto Farm", "UseShovel remote not found", "Error", 3)
		return
	end

	DebugPrint("Starting Auto Shovel...")
	NotificationSystem.Notify("Auto Farm", "Auto Shovel started", "Success", 2)

	State.AutoShovelThread = task_spawn(function()
		while Persist.Config.EnableAutoShovel and State.ScriptRunning do
			local plot = PlotSystem.FindPlayerPlot()
			if plot then
				local plantsFolder = FindPlantsFolder(plot)
				if plantsFolder then
					for _, plant in ipairs(plantsFolder:GetChildren()) do
						if not Persist.Config.EnableAutoShovel or not State.ScriptRunning then
							break
						end

						local seedName = GetPlantSeedName(plant)
						local selected = Persist.Config.SelectedShovelPlants
						local hasSelection = false
						for _, _ in pairs(selected) do
							hasSelection = true
							break
						end

						if hasSelection and not selected[seedName] then
							continue
						end

						local plantId = GetPlantId(plant)
						DebugPrint("SHOVELING:", seedName, "| plantId=", plantId)

						local ok = SafeFireRemote(UseShovelRemote, "Dig", plantId, "", nil)
						if not ok then
							ok = SafeFireRemote(UseShovelRemote, "Dig", plantId)
						end
						if not ok then
							ok = SafeFireRemote(UseShovelRemote, plantId)
						end
						if ok then
							DebugPrint("  -> SUCCESS")
						else
							DebugPrint("  -> FAILED")
						end
						task_wait(0.12)
					end
				end
			end
			task_wait(0.4)
		end
		State.AutoShovelThread = nil
	end)

	TrackThread(State.AutoShovelThread)
end

function AutoFarmSystem.StopShovel()
	Persist.Config.EnableAutoShovel = false
	State.AutoShovelThread = nil
	NotificationSystem.Notify("Auto Farm", "Auto Shovel stopped", "Info", 2)
end
-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 15: CONFIGURATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local ConfigSystem = {}

local function IsSerializable(value)
	local valueType = typeof(value)
	return valueType == "nil" or valueType == "boolean" or valueType == "number" or valueType == "string"
end

local function FilterSerializable(data)
	if typeof(data) ~= "table" then
		return IsSerializable(data) and data or nil
	end
	local result = {}
	for key, value in pairs(data) do
		if typeof(key) == "string" or typeof(key) == "number" then
			if typeof(value) == "table" then
				result[key] = FilterSerializable(value)
			elseif IsSerializable(value) then
				result[key] = value
			end
		end
	end
	return result
end

function ConfigSystem.BuildSaveData()
	return FilterSerializable(Persist.Config)
end

function ConfigSystem.ApplyLoadedData(data)
	if typeof(data) ~= "table" then
		return false
	end
	for key, value in pairs(data) do
		if typeof(key) == "string" and ConfigSchema[key] then
			Persist.Config[key] = Utils.ValidateConfigValue(key, value)
		end
	end
	return true
end

function ConfigSystem.Save(silent)
	local saveTable = ConfigSystem.BuildSaveData()
	local jsonString
	local success, errorMessage = pcall(function()
		jsonString = Services.HttpService:JSONEncode(saveTable)
	end)
	if not success then
		warn("[Config] JSON Encode failed:", errorMessage)
		return false, "encode_failed"
	end

	if writefile then
		local fileOk = pcall(function()
			writefile(CONSTANTS.CONFIG_FILE, jsonString)
		end)
		if fileOk then
			if not silent then
				NotificationSystem.Notify("Config", "Saved to file!", "Success", 2)
			end
			return true, "file"
		end
	end

	local attrOk = pcall(function()
		Player:SetAttribute(CONSTANTS.CONFIG_ATTRIBUTE, jsonString)
	end)
	if attrOk then
		if not silent then
			NotificationSystem.Notify("Config", "Saved (attribute)", "Info", 2)
		end
		return true, "attribute"
	end

	local valOk = pcall(function()
		local existing = PlayerGui:FindFirstChild(CONSTANTS.CONFIG_ATTRIBUTE)
		if existing then
			existing:Destroy()
		end
		local val = Instance.new("StringValue")
		val.Name = CONSTANTS.CONFIG_ATTRIBUTE
		val.Value = jsonString
		val.Parent = PlayerGui
	end)
	if valOk then
		if not silent then
			NotificationSystem.Notify("Config", "Saved (StringValue)", "Info", 2)
		end
		return true, "stringvalue"
	end

	NotificationSystem.Notify("Config", "Failed to save", "Error", 3)
	return false, "none"
end

function ConfigSystem.Load()
	local jsonString = nil
	local method = "none"

	if isfile and isfile(CONSTANTS.CONFIG_FILE) then
		local success, result = pcall(readfile, CONSTANTS.CONFIG_FILE)
		if success and result and #result > 0 then
			jsonString = result
			method = "file"
		end
	end

	if not jsonString then
		local success, result = pcall(function()
			return Player:GetAttribute(CONSTANTS.CONFIG_ATTRIBUTE)
		end)
		if success and result and typeof(result) == "string" and #result > 0 then
			jsonString = result
			method = "attribute"
		end
	end

	if not jsonString then
		local success, result = pcall(function()
			local val = PlayerGui:FindFirstChild(CONSTANTS.CONFIG_ATTRIBUTE)
			return val and val.Value
		end)
		if success and result and typeof(result) == "string" and #result > 0 then
			jsonString = result
			method = "stringvalue"
		end
	end

	if jsonString then
		local success, data = pcall(function()
			return Services.HttpService:JSONDecode(jsonString)
		end)
		if success and data and ConfigSystem.ApplyLoadedData(data) then
			if Persist.Config.Theme and Themes[Persist.Config.Theme] then
				Theme = Themes[Persist.Config.Theme]
			end
			NotificationSystem.Notify("Config", "Loaded from " .. method, "Success", 2)
			return true, method
		end
	end

	return false, "none"
end

function ConfigSystem.Reset()
	if delfile then
		pcall(function()
			delfile(CONSTANTS.CONFIG_FILE)
		end)
	end
	pcall(function()
		Player:SetAttribute(CONSTANTS.CONFIG_ATTRIBUTE, nil)
	end)
	pcall(function()
		local val = PlayerGui:FindFirstChild(CONSTANTS.CONFIG_ATTRIBUTE)
		if val then
			val:Destroy()
		end
	end)

	for key, schema in pairs(ConfigSchema) do
		if schema.type == "table" then
			Persist.Config[key] = table_clone(schema.default)
		else
			Persist.Config[key] = schema.default
		end
	end

	Theme = Themes.Dark
	SeedPlacer.ClearCache()
	PlotSystem.ClearCache()
	GridSystem.Refresh()
	NotificationSystem.Notify("Config", "Reset to defaults", "Warning", 3)
end

function ConfigSystem.AutoSave()
	if State.AutoSaveDebounce then
		pcall(function()
			task_cancel(State.AutoSaveDebounce)
		end)
	end
	State.AutoSaveDebounce = task_delay(CONSTANTS.AUTO_SAVE_DEBOUNCE, function()
		ConfigSystem.Save(true)
		State.AutoSaveDebounce = nil
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 16: UI COMPONENT FACTORY
-- ═══════════════════════════════════════════════════════════════════════

local UI = {}

-- ─── Core Helpers ──────────────────────────────────────────────────────

function UI.Create(className, properties)
	local instance = Instance.new(className)
	if properties then
		for property, value in pairs(properties) do
			instance[property] = value
		end
	end
	return instance
end

function UI.AddCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = instance
	return corner
end

function UI.AddStroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Parent = instance
	return stroke
end

-- ─── Cards ─────────────────────────────────────────────────────────────

function UI.CreateCard(parent, title, icon, iconColor)
	local card = UI.Create("TextButton", {
		Name = title,
		Parent = parent,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = State.CardOrder * 2,
		Font = Enum.Font.Gotham,
		Text = "",
		ZIndex = CONSTANTS.Z_DROPDOWN,
		Active = true,
		AutoButtonColor = false,
	})
	State.CardOrder += 1
	UI.AddCorner(card, 6)
	UI.AddStroke(card, Theme.Border, 1)

	UI.Create("TextLabel", {
		Name = "Icon",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 24, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = icon or "⚙",
		TextColor3 = iconColor or Theme.Accent,
		TextSize = 16,
		ZIndex = CONSTANTS.Z_DROPDOWN + 1,
	})

	UI.Create("TextLabel", {
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
		ZIndex = CONSTANTS.Z_DROPDOWN + 1,
	})

	UI.Create("TextLabel", {
		Name = "Arrow",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -26, 0, 0),
		Size = UDim2.new(0, 22, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = ">",
		TextColor3 = Theme.TextSecondary,
		TextSize = 14,
		ZIndex = CONSTANTS.Z_DROPDOWN + 1,
	})

	TrackConnection(card.MouseEnter:Connect(function()
		TweenSystem.Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)
	end))
	TrackConnection(card.MouseLeave:Connect(function()
		TweenSystem.Tween(card, { BackgroundColor3 = Theme.Card }, 0.15)
	end))

	return card
end

-- ─── Interactive Components ────────────────────────���───────────────────

function UI.CreateToggle(parent, text, defaultState, callback)
	local container = UI.Create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 32),
		ZIndex = 120,
	})

	UI.Create("TextLabel", {
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

	local toggleBg = UI.Create("TextButton", {
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
	UI.AddCorner(toggleBg, 10)

	local knob = UI.Create("Frame", {
		Parent = toggleBg,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = defaultState and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 121,
	})
	UI.AddCorner(knob, 8)

	local state = defaultState or false

	TrackConnection(toggleBg.Activated:Connect(function()
		state = not state
		TweenSystem.Tween(toggleBg, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleBg }, 0.2)
		TweenSystem.Tween(knob, { Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2) }, 0.2)
		if callback then
			local ok, err = pcall(callback, state)
			if not ok then
				warn("[Toggle Error]", err)
			end
		end
		ConfigSystem.AutoSave()
	end))

	return container, function()
		return state
	end
end

function UI.CreateButton(parent, text, bgColor, width, height, callback)
	bgColor = bgColor or Theme.Card
	width = width or 70
	height = height or 28

	local btn = UI.Create("TextButton", {
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
	UI.AddCorner(btn, 5)
	UI.AddStroke(btn, Theme.Border, 1)

	TrackConnection(btn.MouseEnter:Connect(function()
		TweenSystem.Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
	end))
	TrackConnection(btn.MouseLeave:Connect(function()
		TweenSystem.Tween(btn, { BackgroundColor3 = bgColor }, 0.15)
	end))

	if callback then
		TrackConnection(btn.Activated:Connect(function()
			local ok, err = pcall(callback)
			if not ok then
				warn("[Button Error]", err)
			end
		end))
	end

	return btn
end

-- ─── Labels ────────────────────────────────────────────────────────────

function UI.CreateLabel(parent, text, textColor, fontSize)
	return UI.Create("TextLabel", {
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

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 17: DROPDOWN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local DropdownSystem = {}

function DropdownSystem.Close()
	if not State.ActiveDropdownFrame then
		return
	end

	if State.ActiveDropdownCard then
		local arrow = State.ActiveDropdownCard:FindFirstChild("Arrow")
		if arrow then
			arrow.Text = ">"
		end
		TweenSystem.Tween(State.ActiveDropdownCard, { BackgroundColor3 = Theme.Card }, 0.15)
		State.ActiveDropdownCard = nil
	end

	local frame = State.ActiveDropdownFrame
	State.ActiveDropdownFrame = nil

	TweenSystem.Tween(frame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15, function()
		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

function DropdownSystem.Toggle(card, buildFunc)
	if State.DropdownDebounce then
		return
	end
	if State.ActiveDropdownCard == card then
		DropdownSystem.Close()
		return
	end

	State.DropdownDebounce = true
	DropdownSystem.Close()

	State.ActiveDropdownCard = card
	TweenSystem.Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)

	local arrow = card:FindFirstChild("Arrow")
	if arrow then
		arrow.Text = "v"
	end

	local contentScroll = Instances.ContentScroll
	if not contentScroll then
		State.DropdownDebounce = false
		return
	end

	local frame = UI.Create("Frame", {
		Name = "Dropdown",
		Parent = contentScroll,
		BackgroundColor3 = Theme.DropdownBg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = card.LayoutOrder + 1,
		ClipsDescendants = true,
		ZIndex = CONSTANTS.Z_DROPDOWN,
	})
	UI.AddCorner(frame, 6)
	UI.AddStroke(frame, Theme.Border, 1)

	local scroll = UI.Create("ScrollingFrame", {
		Parent = frame,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = CONSTANTS.Z_DROPDOWN + 1,
		ClipsDescendants = true,
		Active = true,
		ScrollingEnabled = true,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})

	local list = UI.Create("UIListLayout", {
		Parent = scroll,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})

	UI.Create("UIPadding", {
		Parent = scroll,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local ok, err = pcall(buildFunc, scroll)
	if not ok then
		warn("[Dropdown Build Error]", err)
	end

	task_wait()
	local contentHeight = list.AbsoluteContentSize.Y + 16
	local maxHeight = math_min(contentHeight, CONSTANTS.MAX_DROPDOWN_HEIGHT)
	scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	State.ActiveDropdownFrame = frame

	TweenSystem.Tween(frame, { Size = UDim2.new(1, 0, 0, maxHeight) }, CONSTANTS.DROPDOWN_ANIMATION_SPEED)

	task_delay(0.25, function()
		State.DropdownDebounce = false
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 18: MODAL SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local ModalSystem = {}

function ModalSystem.SetState(isOpen)
	State.ModalOpen = isOpen
	local mainFrame = Instances.MainFrame
	local sidebarScroll = Instances.SidebarScroll
	local contentScroll = Instances.ContentScroll
	if mainFrame then
		mainFrame.Active = not isOpen
	end
	if sidebarScroll then
		sidebarScroll.ScrollingEnabled = not isOpen
	end
	if contentScroll then
		contentScroll.ScrollingEnabled = not isOpen
	end
end

function ModalSystem.Close()
	if State.ActiveModal then
		TweenSystem.Tween(
			State.ActiveModal,
			{
				Position = UDim2.new(
					0.5,
					-State.ActiveModal.Size.X.Offset / 2,
					0.5,
					-State.ActiveModal.Size.Y.Offset / 2 + 20
				),
			},
			0.2,
			function()
				if State.ActiveModal then
					State.ActiveModal:Destroy()
					State.ActiveModal = nil
				end
			end
		)
	end

	if State.ModalOverlay then
		TweenSystem.Tween(State.ModalOverlay, { BackgroundTransparency = 1 }, 0.2, function()
			if State.ModalOverlay then
				State.ModalOverlay.Visible = false
				ModalSystem.SetState(false)
			end
		end)
	end
end

function ModalSystem.Show(title, buildFunc, width, height)
	width = width or 520
	height = height or 420

	if not State.ModalOverlay then
		local screenGui = Instances.ScreenGui
		if not screenGui then
			return
		end

		State.ModalOverlay = UI.Create("Frame", {
			Name = "ModalOverlay",
			Parent = screenGui,
			BackgroundColor3 = Theme.Overlay,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = CONSTANTS.Z_MODAL_OVERLAY,
			Active = false,
			Visible = false,
		})

		local blocker = UI.Create("TextButton", {
			Parent = State.ModalOverlay,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = CONSTANTS.Z_MODAL_OVERLAY,
			Active = true,
			AutoButtonColor = false,
		})
		TrackConnection(blocker.Activated:Connect(ModalSystem.Close))
	end

	ModalSystem.SetState(true)
	State.ModalOverlay.Visible = true
	TweenSystem.Tween(State.ModalOverlay, { BackgroundTransparency = Persist.Config.ModalDarkening }, 0.2)

	if State.ActiveModal then
		State.ActiveModal:Destroy()
	end

	local modalFrame = UI.Create("Frame", {
		Name = "ModalFrame",
		Parent = State.ModalOverlay,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		Size = UDim2.new(0, width, 0, height),
		ZIndex = CONSTANTS.Z_MODAL,
		Active = true,
	})
	UI.AddCorner(modalFrame, 8)
	UI.AddStroke(modalFrame, Theme.Border, 1)

	local titleBar = UI.Create("Frame", {
		Parent = modalFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 12),
		Size = UDim2.new(1, -30, 0, 28),
		ZIndex = CONSTANTS.Z_MODAL + 20,
	})

	UI.Create("TextLabel", {
		Parent = titleBar,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = CONSTANTS.Z_MODAL + 20,
	})

	local closeBtn = UI.Create("TextButton", {
		Parent = titleBar,
		BackgroundColor3 = Theme.AccentRed,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -28, 0, 0),
		Size = UDim2.new(0, 28, 0, 28),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		ZIndex = CONSTANTS.Z_MODAL + 20,
		Active = true,
		AutoButtonColor = false,
	})
	UI.AddCorner(closeBtn, 6)
	TrackConnection(closeBtn.Activated:Connect(ModalSystem.Close))

	local content = UI.Create("Frame", {
		Parent = modalFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 50),
		Size = UDim2.new(1, -30, 1, -65),
		ZIndex = CONSTANTS.Z_MODAL + 20,
		ClipsDescendants = true,
	})

	State.ActiveModal = modalFrame
	TweenSystem.Tween(modalFrame, { Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2) }, 0.3)

	if buildFunc then
		local ok, err = pcall(buildFunc, modalFrame, content)
		if not ok then
			warn("[Modal Build Error]", err)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 19: SEARCH SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local SearchSystem = {}

function SearchSystem.Register(itemName, targetPage, itemIcon, itemAction)
	State.SearchableItems[#State.SearchableItems + 1] = {
		Name = itemName,
		Page = targetPage,
		Icon = itemIcon,
		Action = itemAction,
	}
end

function SearchSystem.Query(searchQuery)
	local results = {}
	local lowerQuery = searchQuery:lower()
	for _, item in ipairs(State.SearchableItems) do
		if item.Name:lower():find(lowerQuery, 1, true) then
			results[#results + 1] = item
		end
	end
	return results
end

function SearchSystem.UpdateSuggestions()
	local suggestScroll = Instances.SuggestScroll
	local suggestFrame = Instances.SuggestFrame
	local searchBox = Instances.SearchBox
	local searchFrame = Instances.SearchFrame
	if not suggestScroll or not suggestFrame or not searchBox or not searchFrame then
		return
	end

	for _, child in pairs(suggestScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local searchText = searchBox.Text:lower()
	if searchText == "" or searchText == "search" then
		suggestFrame.Visible = false
		return
	end

	local matches = SearchSystem.Query(searchText)
	if #matches == 0 then
		suggestFrame.Visible = false
		return
	end

	local searchAbsPos = searchFrame.AbsolutePosition
	local searchAbsSize = searchFrame.AbsoluteSize
	suggestFrame.Position = UDim2.new(0, searchAbsPos.X, 0, searchAbsPos.Y + searchAbsSize.Y + 4)
	suggestFrame.Size = UDim2.new(0, searchAbsSize.X, 0, math_min(#matches * 34 + 10, 220))

	for _, item in ipairs(matches) do
		local btn = UI.Create("TextButton", {
			Parent = suggestScroll,
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
		UI.AddCorner(btn, 4)

		TrackConnection(btn.MouseEnter:Connect(function()
			TweenSystem.Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end))
		TrackConnection(btn.MouseLeave:Connect(function()
			TweenSystem.Tween(btn, { BackgroundColor3 = Theme.Card }, 0.15)
		end))

		TrackConnection(btn.Activated:Connect(function()
			suggestFrame.Visible = false
			searchBox.Text = "Search"
			if item.Action then
				local ok, err = pcall(item.Action)
				if not ok then
					warn("[Search Action Error]", err)
				end
			end
		end))
	end

	suggestScroll.CanvasSize = UDim2.new(0, 0, 0, #matches * 34)
	suggestFrame.Visible = true
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 20: PAGE SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local PageSystem = {}
local Pages = {}

function PageSystem.ClearContent()
	local contentScroll = Instances.ContentScroll
	if not contentScroll then
		return
	end

	contentScroll.CanvasPosition = Vector2.new(0, 0)
	DropdownSystem.Close()

	for _, child in pairs(contentScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	State.CardOrder = 0
end

function PageSystem.SwitchTo(targetPage, pageTitle, pageSubtitle, pageBuilder)
	State.CurrentPage = targetPage
	local pageTitleLabel = Instances.PageTitle
	local pageSubtitleLabel = Instances.PageSubtitle
	if pageTitleLabel then
		pageTitleLabel.Text = pageTitle
	end
	if pageSubtitleLabel then
		pageSubtitleLabel.Text = pageSubtitle or ""
	end
	PageSystem.ClearContent()

	local ok, err = pcall(pageBuilder)
	if not ok then
		warn("[Page Error]", err)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 21: SEED MODAL
-- ═══════════════════════════════════════════════════════════════════════

local SeedModalSystem = {}

-- ─── Generic Item Selection Modal (looks like Seed Placer) ─────────────

function SeedModalSystem.ShowItemSelection(title, itemNames, selectedTable, updateCallback)
	-- itemNames: array of strings, e.g. {"Carrot", "Tomato", ...}
	-- selectedTable: dictionary, e.g. {Carrot = true, Tomato = false}
	table_sort(itemNames)

	ModalSystem.Show(title, function(modalFrame, modalContent)
		-- Search bar
		local searchContainer = UI.Create("Frame", {
			Parent = modalContent,
			BackgroundColor3 = Theme.Content,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 32),
			Position = UDim2.new(0, 0, 0, 0),
			ZIndex = CONSTANTS.Z_MODAL + 20,
		})
		UI.AddCorner(searchContainer, 4)

		UI.Create("TextLabel", {
			Parent = searchContainer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 0),
			Size = UDim2.new(0, 22, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = "🔍",
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			ZIndex = CONSTANTS.Z_MODAL + 21,
		})

		local searchBox = UI.Create("TextBox", {
			Parent = searchContainer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 32, 0, 0),
			Size = UDim2.new(1, -44, 1, 0),
			Font = Enum.Font.Gotham,
			Text = "Search...",
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			ZIndex = CONSTANTS.Z_MODAL + 21,
			ClearTextOnFocus = true,
			Active = true,
		})

		-- Action buttons (Select All / Clear All)
		local actionFrame = UI.Create("Frame", {
			Parent = modalContent,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 38),
			ZIndex = CONSTANTS.Z_MODAL + 20,
		})

		local selectAllBtn = UI.CreateButton(actionFrame, "Select All", Theme.Accent, 100, 28, function()
			for _, name in ipairs(itemNames) do
				selectedTable[name] = true
			end
			ConfigSystem.AutoSave()
			if updateCallback then
				updateCallback()
			end
			-- Rebuild with current search
			local filter = searchBox.Text
			if filter == "Search..." then
				filter = ""
			end
			buildRows(filter)
		end)
		selectAllBtn.Size = UDim2.new(0.5, -4, 1, 0)

		local clearAllBtn = UI.CreateButton(actionFrame, "Clear All", Color3.fromRGB(185, 65, 65), 100, 28, function()
			for _, name in ipairs(itemNames) do
				selectedTable[name] = nil
			end
			ConfigSystem.AutoSave()
			if updateCallback then
				updateCallback()
			end
			local filter = searchBox.Text
			if filter == "Search..." then
				filter = ""
			end
			buildRows(filter)
		end)
		clearAllBtn.Position = UDim2.new(0.5, 4, 0, 0)
		clearAllBtn.Size = UDim2.new(0.5, -4, 1, 0)

		-- Scroll list
		local scroll = UI.Create("ScrollingFrame", {
			Parent = modalContent,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 74),
			Size = UDim2.new(1, 0, 1, -118),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.ScrollBar,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ZIndex = CONSTANTS.Z_MODAL + 20,
			ClipsDescendants = true,
		})

		local list = UI.Create("UIListLayout", {
			Parent = scroll,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		UI.Create("UIPadding", {
			Parent = scroll,
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		})

		local function buildRows(filterText)
			for _, child in pairs(scroll:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("TextLabel") then
					child:Destroy()
				end
			end

			local lowerFilter = (filterText or ""):lower()
			if lowerFilter == "search..." then
				lowerFilter = ""
			end
			local visibleCount = 0

			for i, name in ipairs(itemNames) do
				if lowerFilter ~= "" and not name:lower():find(lowerFilter, 1, true) then
					continue
				end

				visibleCount += 1
				local isSelected = selectedTable[name] == true

				local row = UI.Create("TextButton", {
					Parent = scroll,
					BackgroundColor3 = isSelected and Color3.fromRGB(55, 45, 75) or Theme.Card,
					BorderSizePixel = 0,
					Size = UDim2.new(1, -8, 0, 34),
					Position = UDim2.new(0, 4, 0, 0),
					LayoutOrder = i,
					Font = Enum.Font.Gotham,
					Text = "",
					ZIndex = CONSTANTS.Z_MODAL + 20,
					Active = true,
					AutoButtonColor = false,
				})
				UI.AddCorner(row, 4)

				-- Name
				UI.Create("TextLabel", {
					Parent = row,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -40, 1, 0),
					Font = Enum.Font.Gotham,
					Text = name,
					TextColor3 = Theme.TextPrimary,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = CONSTANTS.Z_MODAL + 21,
				})

				-- Checkmark
				if isSelected then
					UI.Create("TextLabel", {
						Parent = row,
						BackgroundTransparency = 1,
						Position = UDim2.new(1, -30, 0, 0),
						Size = UDim2.new(0, 20, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = "✓",
						TextColor3 = Theme.Accent,
						TextSize = 14,
						ZIndex = CONSTANTS.Z_MODAL + 21,
					})
				end

				TrackConnection(row.Activated:Connect(function()
					selectedTable[name] = not selectedTable[name]
					if not selectedTable[name] then
						selectedTable[name] = nil
					end
					ConfigSystem.AutoSave()
					if updateCallback then
						updateCallback()
					end
					buildRows(searchBox.Text ~= "Search..." and searchBox.Text or "")
				end))
			end

			scroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 37)

			if visibleCount == 0 and lowerFilter ~= "" then
				UI.Create("TextLabel", {
					Parent = scroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 60),
					Font = Enum.Font.Gotham,
					Text = 'No items found matching "' .. filterText .. '"',
					TextColor3 = Theme.TextMuted,
					TextSize = 12,
					TextWrapped = true,
					ZIndex = CONSTANTS.Z_MODAL + 20,
				})
				scroll.CanvasSize = UDim2.new(0, 0, 0, 70)
			end
		end

		buildRows("")

		TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local text = searchBox.Text
			if text == "Search..." then
				text = ""
			end
			buildRows(text)
		end))

		-- Done button
		local doneBtn = UI.CreateButton(modalContent, "Done", Theme.Accent, 80, 32, function()
			ModalSystem.Close()
		end)
		doneBtn.Position = UDim2.new(1, -85, 1, -38)
	end, 460, 380)
end

-- ─── Original Seed Modal (unchanged) ───────────────────────────────────

function SeedModalSystem.Show(title, selectedTable, updateCallback)
	local seedItems = {}
	if SeedData then
		for _, seed in ipairs(SeedData) do
			if seed.SeedName then
				seedItems[#seedItems + 1] = {
					Name = seed.SeedName,
					Price = seed.PurchasePrice,
					Rarity = seed.Rarity or "Common",
				}
			end
		end
	end

	ModalSystem.Show(title, function(modalFrame, modalContent)
		local searchContainer = UI.Create("Frame", {
			Parent = modalContent,
			BackgroundColor3 = Theme.Content,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 32),
			Position = UDim2.new(0, 0, 0, 0),
			ZIndex = CONSTANTS.Z_MODAL + 20,
		})
		UI.AddCorner(searchContainer, 4)

		UI.Create("TextLabel", {
			Parent = searchContainer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 0),
			Size = UDim2.new(0, 22, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = "🔍",
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			ZIndex = CONSTANTS.Z_MODAL + 21,
		})

		local searchBox = UI.Create("TextBox", {
			Parent = searchContainer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 32, 0, 0),
			Size = UDim2.new(1, -44, 1, 0),
			Font = Enum.Font.Gotham,
			Text = "Search seeds...",
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			ZIndex = CONSTANTS.Z_MODAL + 21,
			ClearTextOnFocus = true,
			Active = true,
		})

		local scroll = UI.Create("ScrollingFrame", {
			Parent = modalContent,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 40),
			Size = UDim2.new(1, 0, 1, -80),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.ScrollBar,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ZIndex = CONSTANTS.Z_MODAL + 20,
			ClipsDescendants = true,
		})

		local list = UI.Create("UIListLayout", {
			Parent = scroll,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		local function BuildRows(filterText)
			for _, child in pairs(scroll:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("TextLabel") then
					child:Destroy()
				end
			end

			local lowerFilter = filterText and filterText:lower() or ""
			if lowerFilter == "search seeds..." then
				lowerFilter = ""
			end
			local visibleCount = 0

			for i, seedItem in ipairs(seedItems) do
				if lowerFilter ~= "" and not seedItem.Name:lower():find(lowerFilter, 1, true) then
					continue
				end

				visibleCount += 1
				local isSelected = selectedTable[seedItem.Name] == true

				local row = UI.Create("TextButton", {
					Parent = scroll,
					BackgroundColor3 = isSelected and Color3.fromRGB(55, 45, 75) or Theme.Card,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 34),
					LayoutOrder = i,
					Font = Enum.Font.Gotham,
					Text = "",
					ZIndex = CONSTANTS.Z_MODAL + 20,
					Active = true,
					AutoButtonColor = false,
				})
				UI.AddCorner(row, 4)

				UI.Create("TextLabel", {
					Parent = row,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(0.32, 0, 1, 0),
					Font = Enum.Font.Gotham,
					Text = seedItem.Name,
					TextColor3 = Theme.TextPrimary,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = CONSTANTS.Z_MODAL + 21,
				})

				UI.Create("TextLabel", {
					Parent = row,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.36, 0, 0, 0),
					Size = UDim2.new(0.24, 0, 1, 0),
					Font = Enum.Font.Gotham,
					Text = Utils.FormatPrice(seedItem.Price),
					TextColor3 = Theme.AccentYellow,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = CONSTANTS.Z_MODAL + 21,
				})

				local rarityColor = CONSTANTS.RARITY_COLORS[seedItem.Rarity] or Theme.TextSecondary
				UI.Create("TextLabel", {
					Parent = row,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.62, 0, 0, 0),
					Size = UDim2.new(0.18, 0, 1, 0),
					Font = Enum.Font.GothamBold,
					Text = seedItem.Rarity,
					TextColor3 = rarityColor,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = CONSTANTS.Z_MODAL + 21,
				})

				if isSelected then
					UI.Create("TextLabel", {
						Parent = row,
						BackgroundTransparency = 1,
						Position = UDim2.new(1, -30, 0, 0),
						Size = UDim2.new(0, 20, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = "✓",
						TextColor3 = Theme.Accent,
						TextSize = 14,
						ZIndex = CONSTANTS.Z_MODAL + 21,
					})
				end

				TrackConnection(row.Activated:Connect(function()
					selectedTable[seedItem.Name] = not selectedTable[seedItem.Name]
					ConfigSystem.AutoSave()
					if updateCallback then
						updateCallback()
					end
					BuildRows(searchBox.Text ~= "Search seeds..." and searchBox.Text or "")
				end))
			end

			scroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 37)

			if visibleCount == 0 and lowerFilter ~= "" then
				UI.Create("TextLabel", {
					Parent = scroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 60),
					Font = Enum.Font.Gotham,
					Text = 'No seeds found matching "' .. filterText .. '"',
					TextColor3 = Theme.TextMuted,
					TextSize = 12,
					TextWrapped = true,
					ZIndex = CONSTANTS.Z_MODAL + 20,
				})
				scroll.CanvasSize = UDim2.new(0, 0, 0, 70)
			end
		end

		BuildRows("")

		TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local text = searchBox.Text
			if text == "Search seeds..." then
				text = ""
			end
			BuildRows(text)
		end))

		local doneBtn = UI.CreateButton(modalContent, "Done", Theme.Accent, 80, 32, function()
			ModalSystem.Close()
		end)
		doneBtn.Position = UDim2.new(1, -85, 1, -38)
	end, 480, 400)
end

-- ─── Simple Selection Modal (for dropdown-style choices) ───────────────

function SeedModalSystem.ShowSelection(title, options, currentValue, onSelect)
	ModalSystem.Show(title, function(modalFrame, modalContent)
		local scroll = UI.Create("ScrollingFrame", {
			Parent = modalContent,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, -40),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.ScrollBar,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ZIndex = CONSTANTS.Z_MODAL + 20,
			ClipsDescendants = true,
		})

		local list = UI.Create("UIListLayout", {
			Parent = scroll,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		for i, opt in ipairs(options) do
			local isSelected = currentValue == opt.Value
			local btn = UI.Create("TextButton", {
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
				ZIndex = CONSTANTS.Z_MODAL + 21,
				Active = true,
				AutoButtonColor = false,
			})
			UI.AddCorner(btn, 4)
			UI.AddStroke(btn, Theme.Border, 1)

			TrackConnection(btn.Activated:Connect(function()
				onSelect(opt.Value)
				ModalSystem.Close()
			end))
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 35)

		local doneBtn = UI.CreateButton(modalContent, "Done", Theme.Accent, 80, 32, function()
			ModalSystem.Close()
		end)
		doneBtn.Position = UDim2.new(1, -85, 1, -38)
	end, 400, 350)
end

function SeedModalSystem.ShowPlacerConfig()
	local info = PlotSystem.GetDetectionInfo()
	local partOptions = { { Label = "All (every detected column)", Value = "All" } }
	for _, opt in ipairs(info.PartOptions or {}) do
		partOptions[#partOptions + 1] = { Label = opt.Label, Value = opt.Value }
	end

	local patternOptions = {
		{ Label = "Left to Right", Value = "LeftToRight" },
		{ Label = "Right to Left", Value = "RightToLeft" },
		{ Label = "Outside to Center", Value = "OutsideToCenter" },
		{ Label = "Center to Outside", Value = "CenterToOutside" },
		{ Label = "Middle (Spiral from Center)", Value = "Middle" },
		{ Label = "Random", Value = "Random" },
	}

	ModalSystem.Show("Planting Configuration", function(modalFrame, modalContent)
		local yOffset = 0
		local rowHeight = 34
		local labelHeight = 18
		local gap = 8

		UI.CreateLabel(modalContent, "Planting Area", Theme.Accent, 13).Position = UDim2.new(0, 4, 0, yOffset)
		yOffset += labelHeight + 2

		local areaRow = UI.Create("TextButton", {
			Parent = modalContent,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, rowHeight),
			Position = UDim2.new(0, 5, 0, yOffset),
			Font = Enum.Font.Gotham,
			Text = "  " .. (Persist.Config.PlantingArea or "All") .. "  >",
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = CONSTANTS.Z_MODAL + 20,
			Active = true,
			AutoButtonColor = false,
		})
		UI.AddCorner(areaRow, 4)
		UI.AddStroke(areaRow, Theme.Border, 1)

		TrackConnection(areaRow.Activated:Connect(function()
			SeedModalSystem.ShowSelection(
				"Select Planting Area",
				partOptions,
				Persist.Config.PlantingArea or "All",
				function(value)
					Persist.Config.PlantingArea = value
					SeedPlacer.ClearCache()
					if Persist.Config.ShowGridDots then
						GridSystem.Refresh()
					end
					ConfigSystem.AutoSave()
				end
			)
		end))
		yOffset += rowHeight + gap

		UI.CreateLabel(modalContent, "Planting Pattern", Theme.Accent, 13).Position = UDim2.new(0, 4, 0, yOffset)
		yOffset += labelHeight + 2

		local patternRow = UI.Create("TextButton", {
			Parent = modalContent,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, rowHeight),
			Position = UDim2.new(0, 5, 0, yOffset),
			Font = Enum.Font.Gotham,
			Text = "  " .. (Persist.Config.PlantingPattern or "LeftToRight") .. "  >",
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = CONSTANTS.Z_MODAL + 20,
			Active = true,
			AutoButtonColor = false,
		})
		UI.AddCorner(patternRow, 4)
		UI.AddStroke(patternRow, Theme.Border, 1)

		TrackConnection(patternRow.Activated:Connect(function()
			SeedModalSystem.ShowSelection(
				"Select Pattern",
				patternOptions,
				Persist.Config.PlantingPattern or "LeftToRight",
				function(value)
					Persist.Config.PlantingPattern = value
					SeedPlacer.ClearCache()
					if Persist.Config.ShowGridDots then
						GridSystem.Refresh()
					end
					ConfigSystem.AutoSave()
				end
			)
		end))
		yOffset += rowHeight + gap

		local doneBtn = UI.CreateButton(modalContent, "Done", Theme.Accent, 80, 32, function()
			ModalSystem.Close()
		end)
		doneBtn.Position = UDim2.new(1, -90, 0, yOffset)
	end, 480, 280)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 22: PAGE DEFINITIONS
-- ═══════════════════════════════════════════════════════════════════════

-- ─── Home Page ─────────────────────────────────────────────────────────

function Pages.Home()
	PageSystem.SwitchTo("Home", "Home", "Game Version: ----", function()
		local seedPlacerCard = UI.CreateCard(Instances.ContentScroll, "Seed Placer", "🏠", Theme.Accent)
		TrackConnection(seedPlacerCard.Activated:Connect(function()
			DropdownSystem.Toggle(seedPlacerCard, function(dropdownScroll)
				Persist.Config.SelectedPlaceSeeds = Persist.Config.SelectedPlaceSeeds or {}
				Persist.Config.PlaceAmount = Persist.Config.PlaceAmount or CONSTANTS.DEFAULT_PLACE_AMOUNT
				Persist.Config.PlantingArea = Persist.Config.PlantingArea or "All"
				Persist.Config.PlantingPattern = Persist.Config.PlantingPattern or "LeftToRight"
				Persist.Config.PlantSpacing = Persist.Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING
				Persist.Config.PlantDelay = Persist.Config.PlantDelay or CONSTANTS.DEFAULT_PLANT_DELAY
				if Persist.Config.EnableSeedPlacer == nil then
					Persist.Config.EnableSeedPlacer = false
				end

				UI.CreateLabel(dropdownScroll, "Seed Placer", Theme.Accent, 12)
				local selectedLabel = UI.CreateLabel(dropdownScroll, "Selected: None", Theme.TextMuted, 10)
				local function UpdateSelectedLabel()
					selectedLabel.Text = Utils.FormatSelectedSeeds(Persist.Config.SelectedPlaceSeeds, 10)
				end
				UpdateSelectedLabel()

				local selectSeedsBtn = UI.CreateButton(
					dropdownScroll,
					"Select Seeds...",
					Theme.Card,
					100,
					30,
					function()
						SeedModalSystem.Show("Select Seeds", Persist.Config.SelectedPlaceSeeds, UpdateSelectedLabel)
					end
				)
				selectSeedsBtn.Size = UDim2.new(1, -8, 0, 30)

				local actionFrame = UI.Create("Frame", {
					Parent = dropdownScroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 30),
				})

				local selectAllBtn = UI.CreateButton(actionFrame, "Select All", Theme.Accent, 100, 30, function()
					for _, seed in ipairs(SeedData or {}) do
						if seed.SeedName then
							Persist.Config.SelectedPlaceSeeds[seed.SeedName] = true
						end
					end
					ConfigSystem.AutoSave()
					UpdateSelectedLabel()
				end)
				selectAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				local clearAllBtn = UI.CreateButton(
					actionFrame,
					"Clear All",
					Color3.fromRGB(185, 65, 65),
					100,
					30,
					function()
						table_clear(Persist.Config.SelectedPlaceSeeds)
						ConfigSystem.AutoSave()
						UpdateSelectedLabel()
					end
				)
				clearAllBtn.Position = UDim2.new(0.5, 3, 0, 0)
				clearAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				local info = PlotSystem.GetDetectionInfo()
				local totalPos = 0
				local cached = SeedPlacer.GetPlantPositions()
				if cached then
					totalPos = #cached
				end

				UI.CreateLabel(dropdownScroll, "Plot: " .. (info and info.PlotName or "None"), Theme.TextSecondary, 11)
				UI.CreateLabel(
					dropdownScroll,
					"Columns Detected: " .. (info and #info.PartNames or 0),
					Theme.TextSecondary,
					11
				)
				UI.CreateLabel(dropdownScroll, "Total Positions: " .. totalPos, Theme.TextSecondary, 11)

				UI.CreateLabel(dropdownScroll, "Detected Columns:", Theme.Accent, 12)
				local partNames = info and info.PartNames or {}
				if #partNames == 0 then
					UI.CreateLabel(dropdownScroll, "  (none)", Theme.TextMuted, 11)
				else
					for _, name in ipairs(partNames) do
						UI.CreateLabel(dropdownScroll, "  " .. name, Theme.TextSecondary, 11)
					end
				end

				UI.CreateLabel(dropdownScroll, "Current Settings:", Theme.Accent, 12)
				UI.CreateLabel(
					dropdownScroll,
					"  Area: " .. (Persist.Config.PlantingArea or "All"),
					Theme.TextSecondary,
					11
				)
				UI.CreateLabel(
					dropdownScroll,
					"  Pattern: " .. (Persist.Config.PlantingPattern or "LeftToRight"),
					Theme.TextSecondary,
					11
				)

				local configBtn = UI.CreateButton(
					dropdownScroll,
					"Configure Planting...",
					Theme.Accent,
					100,
					30,
					function()
						SeedModalSystem.ShowPlacerConfig()
					end
				)
				configBtn.Size = UDim2.new(1, -8, 0, 30)

				UI.CreateLabel(dropdownScroll, "Settings", Theme.Accent, 12)
				local settingsRow = UI.Create("Frame", {
					Parent = dropdownScroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 50),
				})

				local spacingContainer = UI.Create("Frame", {
					Parent = settingsRow,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.33, -4, 1, 0),
				})
				UI.Create("TextLabel", {
					Parent = spacingContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					Font = Enum.Font.Gotham,
					Text = "Spacing",
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local spacingBox = UI.Create("TextBox", {
					Parent = spacingContainer,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 18),
					Size = UDim2.new(1, 0, 0, 26),
					Font = Enum.Font.Gotham,
					Text = tostring(Persist.Config.PlantSpacing),
					PlaceholderText = "1",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				UI.AddCorner(spacingBox, 4)
				TrackConnection(spacingBox.FocusLost:Connect(function()
					local val = tonumber(spacingBox.Text)
					if val and val >= 0.1 then
						Persist.Config.PlantSpacing = val
						SeedPlacer.ClearCache()
						if Persist.Config.ShowGridDots then
							GridSystem.Refresh()
						end
						ConfigSystem.AutoSave()
					end
				end))

				local delayContainer = UI.Create("Frame", {
					Parent = settingsRow,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.33, -4, 1, 0),
					Position = UDim2.new(0.33, 2, 0, 0),
				})
				UI.Create("TextLabel", {
					Parent = delayContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					Font = Enum.Font.Gotham,
					Text = "Delay (s)",
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local delayBox = UI.Create("TextBox", {
					Parent = delayContainer,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 18),
					Size = UDim2.new(1, 0, 0, 26),
					Font = Enum.Font.Gotham,
					Text = tostring(Persist.Config.PlantDelay),
					PlaceholderText = "0.05",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				UI.AddCorner(delayBox, 4)
				TrackConnection(delayBox.FocusLost:Connect(function()
					local val = tonumber(delayBox.Text)
					if val and val >= 0 then
						Persist.Config.PlantDelay = val
						ConfigSystem.AutoSave()
					end
				end))

				local amountContainer = UI.Create("Frame", {
					Parent = settingsRow,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.33, -4, 1, 0),
					Position = UDim2.new(0.67, 4, 0, 0),
				})
				UI.Create("TextLabel", {
					Parent = amountContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					Font = Enum.Font.Gotham,
					Text = "Amount",
					TextColor3 = Theme.TextPrimary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local amountBox = UI.Create("TextBox", {
					Parent = amountContainer,
					BackgroundColor3 = Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 18),
					Size = UDim2.new(1, 0, 0, 26),
					Font = Enum.Font.Gotham,
					Text = tostring(Persist.Config.PlaceAmount),
					PlaceholderText = "10",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				UI.AddCorner(amountBox, 4)
				TrackConnection(amountBox.FocusLost:Connect(function()
					local val = tonumber(amountBox.Text)
					if val and val > 0 then
						Persist.Config.PlaceAmount = math_floor(val)
						ConfigSystem.AutoSave()
					end
				end))

				UI.CreateToggle(dropdownScroll, "Enable Seed Placer", Persist.Config.EnableSeedPlacer, function(state)
					Persist.Config.EnableSeedPlacer = state
					ConfigSystem.AutoSave()
				end)
			end)
		end))

		local plotVisualizerCard = UI.CreateCard(Instances.ContentScroll, "Plot Visualizer", "✨", Theme.AccentCyan)
		TrackConnection(plotVisualizerCard.Activated:Connect(function()
			DropdownSystem.Toggle(plotVisualizerCard, function(dropdownScroll)
				UI.CreateLabel(dropdownScroll, "Plot Visualizer", Theme.AccentCyan, 12)
				local info = PlotSystem.GetDetectionInfo()
				UI.CreateLabel(
					dropdownScroll,
					"Detected Plot: " .. (info and info.PlotName or "None"),
					Theme.TextSecondary,
					11
				)

				local laserBtn = UI.CreateButton(
					dropdownScroll,
					"🔦 Laser Scan",
					Theme.AccentCyan,
					100,
					32,
					function()
						local detectedPlot = PlotSystem.FindPlayerPlot()
						if detectedPlot then
							LaserSystem.ScanPlot(detectedPlot, 1.2)
							NotificationSystem.Notify(
								"Plot Visualizer",
								"Laser scan on " .. detectedPlot.Name,
								"Success",
								2
							)
						else
							NotificationSystem.Notify("Plot Visualizer", "Could not find your plot!", "Error", 3)
						end
					end
				)
				laserBtn.Size = UDim2.new(1, -8, 0, 32)

				UI.CreateToggle(dropdownScroll, "Show Grid Dots", Persist.Config.ShowGridDots, function(state)
					Persist.Config.ShowGridDots = state
					ConfigSystem.AutoSave()
					if state then
						GridSystem.Refresh()
					else
						GridSystem.Clear()
					end
				end)

				local clearBtn = UI.CreateButton(
					dropdownScroll,
					"🧹 Clear All Visuals",
					Color3.fromRGB(185, 65, 65),
					100,
					32,
					function()
						LaserSystem.Clear()
						GridSystem.Clear()
						Persist.Config.ShowGridDots = false
						ConfigSystem.AutoSave()
						NotificationSystem.Notify("Plot Visualizer", "All visuals cleared", "Info", 2)
					end
				)
				clearBtn.Size = UDim2.new(1, -8, 0, 32)
			end)
		end))

		local autoCollectCard = UI.CreateCard(Instances.ContentScroll, "Auto Collect Fruits", "🍎", Theme.Accent)
		TrackConnection(autoCollectCard.Activated:Connect(function()
			DropdownSystem.Toggle(autoCollectCard, function(dropdownScroll)
				Persist.Config.SelectedCollectFruits = Persist.Config.SelectedCollectFruits or {}

				UI.CreateLabel(dropdownScroll, "Auto Collect", Theme.Accent, 12)
				local selectedLabel = UI.CreateLabel(dropdownScroll, "Selected: None", Theme.TextMuted, 10)
				local function UpdateSelectedLabel()
					selectedLabel.Text = Utils.FormatSelectedSeeds(Persist.Config.SelectedCollectFruits, 10)
				end
				UpdateSelectedLabel()

				local selectBtn = UI.CreateButton(
					dropdownScroll,
					"Select Fruits to Collect...",
					Theme.Card,
					100,
					30,
					function()
						local seedNames = {}
						if SeedData then
							for _, seed in ipairs(SeedData) do
								if seed.SeedName then
									table.insert(seedNames, seed.SeedName)
								end
							end
						end
						table.sort(seedNames)
						if #seedNames == 0 then
							NotificationSystem.Notify("Auto Collect", "No seed data available!", "Error", 3)
							return
						end
						SeedModalSystem.ShowItemSelection(
							"Select Fruits to Collect",
							seedNames,
							Persist.Config.SelectedCollectFruits,
							UpdateSelectedLabel
						)
					end
				)
				selectBtn.Size = UDim2.new(1, -8, 0, 30)

				UI.CreateToggle(dropdownScroll, "Enable Auto Collect", Persist.Config.EnableAutoCollect, function(state)
					Persist.Config.EnableAutoCollect = state
					ConfigSystem.AutoSave()
					if state then
						AutoFarmSystem.StartCollect()
					else
						AutoFarmSystem.StopCollect()
					end
				end)
			end)
		end))

		local autoShovelCard =
			UI.CreateCard(Instances.ContentScroll, "Auto Shovel Plants", "🥄", Color3.fromRGB(200, 100, 100))
		TrackConnection(autoShovelCard.Activated:Connect(function()
			DropdownSystem.Toggle(autoShovelCard, function(dropdownScroll)
				Persist.Config.SelectedShovelPlants = Persist.Config.SelectedShovelPlants or {}

				UI.CreateLabel(dropdownScroll, "Auto Shovel", Color3.fromRGB(200, 100, 100), 12)
				local selectedLabel = UI.CreateLabel(dropdownScroll, "Selected: None", Theme.TextMuted, 10)
				local function UpdateSelectedLabel()
					selectedLabel.Text = Utils.FormatSelectedSeeds(Persist.Config.SelectedShovelPlants, 10)
				end
				UpdateSelectedLabel()

				local selectBtn = UI.CreateButton(
					dropdownScroll,
					"Select Plants to Shovel...",
					Theme.Card,
					100,
					30,
					function()
						local seedNames = {}
						if SeedData then
							for _, seed in ipairs(SeedData) do
								if seed.SeedName then
									table.insert(seedNames, seed.SeedName)
								end
							end
						end
						table.sort(seedNames)
						if #seedNames == 0 then
							NotificationSystem.Notify("Auto Shovel", "No seed data available!", "Error", 3)
							return
						end
						SeedModalSystem.ShowItemSelection(
							"Select Plants to Shovel",
							seedNames,
							Persist.Config.SelectedShovelPlants,
							UpdateSelectedLabel
						)
					end
				)
				selectBtn.Size = UDim2.new(1, -8, 0, 30)

				UI.CreateToggle(dropdownScroll, "Enable Auto Shovel", Persist.Config.EnableAutoShovel, function(state)
					Persist.Config.EnableAutoShovel = state
					ConfigSystem.AutoSave()
					if state then
						AutoFarmSystem.StartShovel()
					else
						AutoFarmSystem.StopShovel()
					end
				end)
			end)
		end))
	end)
end

-- ─── Shop Page ─────────────────────────────────────────────────────────

function Pages.Shop()
	PageSystem.SwitchTo("Shop", "Shop", "ShopFeatures", function()
		local seedShopCard = UI.CreateCard(Instances.ContentScroll, "Seed Shop", "🌱", Theme.Accent)
		TrackConnection(seedShopCard.Activated:Connect(function()
			DropdownSystem.Toggle(seedShopCard, function(dropdownScroll)
				UI.CreateLabel(dropdownScroll, "Auto Buy Seeds", Theme.Accent, 12)

				local selectedLabel = UI.CreateLabel(
					dropdownScroll,
					"Selected: " .. Utils.FormatSelectedSeeds(Persist.Config.SelectedSeeds, 10),
					Theme.TextMuted,
					10
				)
				selectedLabel.Name = "SelectedLabel"

				local function UpdateSelectedLabel()
					selectedLabel.Text = Utils.FormatSelectedSeeds(Persist.Config.SelectedSeeds, 10)
				end
				UpdateSelectedLabel()

				local selectSeedsBtn = UI.CreateButton(
					dropdownScroll,
					"Select Seeds...",
					Theme.Card,
					100,
					30,
					function()
						SeedModalSystem.Show("Select Seeds", Persist.Config.SelectedSeeds, UpdateSelectedLabel)
					end
				)
				selectSeedsBtn.Size = UDim2.new(1, -8, 0, 30)

				local actionFrame = UI.Create("Frame", {
					Parent = dropdownScroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 30),
				})

				local selectAllBtn = UI.CreateButton(actionFrame, "Select All", Theme.Accent, 100, 30, function()
					if SeedData then
						for _, seed in ipairs(SeedData) do
							if seed.SeedName then
								Persist.Config.SelectedSeeds[seed.SeedName] = true
							end
						end
					end
					ConfigSystem.AutoSave()
					UpdateSelectedLabel()
				end)
				selectAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				local clearAllBtn = UI.CreateButton(
					actionFrame,
					"Clear All",
					Color3.fromRGB(185, 65, 65),
					100,
					30,
					function()
						table_clear(Persist.Config.SelectedSeeds)
						ConfigSystem.AutoSave()
						UpdateSelectedLabel()
					end
				)
				clearAllBtn.Position = UDim2.new(0.5, 3, 0, 0)
				clearAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				UI.CreateToggle(dropdownScroll, "Enable Auto Buy", Persist.Config.EnableSeedShop, function(state)
					Persist.Config.EnableSeedShop = state
					ConfigSystem.AutoSave()
				end)
			end)
		end))
	end)
end

-- ─── Account Page ──────────────────────────────────────────────────────

function Pages.Account()
	PageSystem.SwitchTo("Account", "Account", "User Profile", function()
		local card = UI.CreateCard(Instances.ContentScroll, "Account Info", "👤", Theme.Accent)
		TrackConnection(card.Activated:Connect(function()
			DropdownSystem.Toggle(card, function(dropdownScroll)
				UI.CreateLabel(dropdownScroll, "Username: " .. Player.Name, Theme.TextPrimary, 12)
				UI.CreateLabel(dropdownScroll, "User ID: " .. Player.UserId, Theme.TextSecondary, 11)
			end)
		end))
	end)
end

-- ─── Premium Page ──────────────────────────────────────────────────────

function Pages.Premium()
	PageSystem.SwitchTo("Premium", "Premium", "Premium Features", function() end)
end

-- ─── Settings Page ─────────────────────────────────────────────────────

function Pages.Settings()
	PageSystem.SwitchTo("Settings", "Settings", "Preferences", function()
		UI.CreateLabel(Instances.ContentScroll, "UI Settings", Theme.Accent, 14)

		UI.CreateToggle(Instances.ContentScroll, "Disable Animations", Persist.Config.DisableAnimations, function(state)
			Persist.Config.DisableAnimations = state
			ConfigSystem.AutoSave()
		end)

		UI.CreateToggle(Instances.ContentScroll, "Reduce Effects", Persist.Config.ReduceEffects, function(state)
			Persist.Config.ReduceEffects = state
			ConfigSystem.AutoSave()
		end)

		UI.CreateLabel(Instances.ContentScroll, " ", Theme.TextSecondary, 8)

		UI.CreateButton(Instances.ContentScroll, "Save Now", Theme.AccentGreen, 120, 32, function()
			ConfigSystem.Save()
		end)

		UI.CreateButton(Instances.ContentScroll, "Load Config", Theme.Accent, 120, 32, function()
			ConfigSystem.Load()
		end)

		UI.CreateLabel(Instances.ContentScroll, " ", Theme.TextSecondary, 8)

		UI.CreateButton(Instances.ContentScroll, "Reset Config", Theme.AccentRed, 120, 32, function()
			ConfigSystem.Reset()
		end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 23: UI INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════

local UIInit = {}

-- ─── ScreenGui & Main Frame ────────────────────────────────────────────

function UIInit.CreateScreenGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LRX_Hub"
	screenGui.Parent = PlayerGui
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999
	TrackInstance("ScreenGui", screenGui)
	return screenGui
end

function UIInit.CreateMainFrame(screenGui)
	local mainFrame = UI.Create("Frame", {
		Name = "MainFrame",
		Parent = screenGui,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -Persist.Config.WindowWidth / 2, 0.5, -Persist.Config.WindowHeight / 2),
		Size = UDim2.new(0, Persist.Config.WindowWidth, 0, Persist.Config.WindowHeight),
		ClipsDescendants = false,
		Active = true,
		ZIndex = CONSTANTS.Z_BASE,
	})
	UI.AddCorner(mainFrame, 8)
	UI.AddStroke(mainFrame, Theme.Border, 2)

	if Persist.Config.WindowPosition then
		mainFrame.Position = UDim2.new(
			Persist.Config.WindowPosition[1],
			Persist.Config.WindowPosition[2],
			Persist.Config.WindowPosition[3],
			Persist.Config.WindowPosition[4]
		)
	end
	if Persist.Config.WindowSize then
		mainFrame.Size = UDim2.new(
			Persist.Config.WindowSize[1],
			Persist.Config.WindowSize[2],
			Persist.Config.WindowSize[3],
			Persist.Config.WindowSize[4]
		)
	end

	TrackInstance("MainFrame", mainFrame)
	return mainFrame
end

-- ─── Toggle Button ─────────────────────────────────────────────────────

function UIInit.CreateToggleButton(screenGui)
	local btn = UI.Create("TextButton", {
		Name = "MainIcon",
		Parent = screenGui,
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(0, 60, 0, 32),
		Font = Enum.Font.GothamBold,
		Text = Persist.Config.ToggleButtonText,
		TextColor3 = Theme.AccentYellow,
		TextSize = 13,
		ZIndex = CONSTANTS.Z_BASE,
		Active = true,
		AutoButtonColor = false,
	})
	UI.AddCorner(btn, 6)
	UI.AddStroke(btn, Theme.Border, 1)

	TrackConnection(btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			State.IsDraggingToggle = true
			State.ToggleStartPos = input.Position
			State.ToggleBtnStart = btn.Position
		end
	end))

	TrackConnection(Services.UserInputService.InputChanged:Connect(function(input)
		if
			State.IsDraggingToggle
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - State.ToggleStartPos
			btn.Position = UDim2.new(
				State.ToggleBtnStart.X.Scale,
				State.ToggleBtnStart.X.Offset + delta.X,
				State.ToggleBtnStart.Y.Scale,
				State.ToggleBtnStart.Y.Offset + delta.Y
			)
		end
	end))

	TrackConnection(Services.UserInputService.InputEnded:Connect(function(input)
		if State.IsDraggingToggle then
			local delta = input.Position - State.ToggleStartPos
			State.IsDraggingToggle = false
			if math_abs(delta.X) <= 8 and math_abs(delta.Y) <= 8 then
				local mainFrame = Instances.MainFrame
				if mainFrame then
					mainFrame.Visible = not mainFrame.Visible
					TweenSystem.Tween(btn, {
						BackgroundColor3 = mainFrame.Visible and Color3.fromRGB(15, 15, 15)
							or Color3.fromRGB(30, 30, 30),
					}, 0.2)
				end
			end
		end
	end))

	TrackInstance("MainIcon", btn)
	return btn
end

-- ─── Top Bar ───────────────────────────────────────────────────────────

function UIInit.CreateTopBar(mainFrame, screenGui)
	local topBar = UI.Create("Frame", {
		Name = "TopBar",
		Parent = mainFrame,
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, CONSTANTS.TOPBAR_HEIGHT),
		ZIndex = CONSTANTS.Z_BASE,
	})

	UI.Create("TextLabel", {
		Name = "Title",
		Parent = topBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0, 70, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = " LRX",
		TextColor3 = Theme.TextPrimary,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = CONSTANTS.Z_BASE + 1,
	})

	local pageTitle = UI.Create("TextLabel", {
		Name = "PageTitle",
		Parent = topBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 180, 0, 6),
		Size = UDim2.new(0, 140, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = "Home",
		TextColor3 = Theme.TextPrimary,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = CONSTANTS.Z_BASE + 1,
	})

	local pageSubtitle = UI.Create("TextLabel", {
		Name = "PageSubtitle",
		Parent = topBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 180, 0, 26),
		Size = UDim2.new(0, 140, 0, 16),
		Font = Enum.Font.Gotham,
		Text = "",
		TextColor3 = Theme.TextMuted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = CONSTANTS.Z_BASE + 1,
	})

	TrackInstance("PageTitle", pageTitle)
	TrackInstance("PageSubtitle", pageSubtitle)

	local searchFrame = UI.Create("Frame", {
		Name = "SearchFrame",
		Parent = topBar,
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -230, 0.5, -14),
		Size = UDim2.new(0, 200, 0, 28),
		ZIndex = CONSTANTS.Z_BASE + 2,
	})
	UI.AddCorner(searchFrame, 12)
	UI.AddStroke(searchFrame, Theme.Border, 1)

	UI.Create("TextLabel", {
		Name = "SearchIcon",
		Parent = searchFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0, 22, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "🔍",
		TextColor3 = Theme.TextMuted,
		TextSize = 12,
		ZIndex = CONSTANTS.Z_BASE + 3,
	})

	local searchBox = UI.Create("TextBox", {
		Name = "SearchBox",
		Parent = searchFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 32, 0, 0),
		Size = UDim2.new(1, -44, 1, 0),
		Font = Enum.Font.Gotham,
		Text = "Search",
		TextColor3 = Theme.TextMuted,
		TextSize = 12,
		ZIndex = CONSTANTS.Z_BASE + 3,
		ClearTextOnFocus = true,
		Active = true,
	})

	TrackInstance("SearchFrame", searchFrame)
	TrackInstance("SearchBox", searchBox)

	local suggestFrame = UI.Create("Frame", {
		Name = "Suggestions",
		Parent = screenGui,
		BackgroundColor3 = Theme.DropdownBg,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 200, 0, 0),
		Visible = false,
		ZIndex = 200,
		ClipsDescendants = true,
		Active = true,
	})
	UI.AddCorner(suggestFrame, 6)
	UI.AddStroke(suggestFrame, Theme.Border, 1)

	local suggestScroll = UI.Create("ScrollingFrame", {
		Name = "SuggestScroll",
		Parent = suggestFrame,
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

	UI.Create("UIListLayout", {
		Parent = suggestScroll,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	TrackInstance("SuggestFrame", suggestFrame)
	TrackInstance("SuggestScroll", suggestScroll)

	local searchDebounceThread
	TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if searchDebounceThread then
			task_cancel(searchDebounceThread)
		end
		searchDebounceThread = task_delay(0.12, function()
			searchDebounceThread = nil
			SearchSystem.UpdateSuggestions()
		end)
	end))
	TrackConnection(searchBox.FocusLost:Connect(function()
		if searchBox.Text == "" then
			searchBox.Text = "Search"
		end
		task_wait(0.2)
		suggestFrame.Visible = false
	end))
	TrackConnection(searchBox.Focused:Connect(function()
		if searchBox.Text ~= "Search" and searchBox.Text ~= "" then
			SearchSystem.UpdateSuggestions()
		end
	end))

	local closeBtn = UI.Create("TextButton", {
		Name = "CloseBtn",
		Parent = topBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -34, 0, 6),
		Size = UDim2.new(0, 28, 0, 28),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Theme.TextSecondary,
		TextSize = 24,
		ZIndex = CONSTANTS.Z_BASE + 1,
		Active = true,
		AutoButtonColor = false,
	})

	TrackConnection(closeBtn.MouseEnter:Connect(function()
		TweenSystem.Tween(closeBtn, { TextColor3 = Theme.AccentRed }, 0.15)
	end))
	TrackConnection(closeBtn.MouseLeave:Connect(function()
		TweenSystem.Tween(closeBtn, { TextColor3 = Theme.TextSecondary }, 0.15)
	end))

	TrackConnection(closeBtn.Activated:Connect(function()
		Persist.Config.WindowPosition = {
			mainFrame.Position.X.Scale,
			mainFrame.Position.X.Offset,
			mainFrame.Position.Y.Scale,
			mainFrame.Position.Y.Offset,
		}
		Persist.Config.WindowSize = {
			mainFrame.Size.X.Scale,
			mainFrame.Size.X.Offset,
			mainFrame.Size.Y.Scale,
			mainFrame.Size.Y.Offset,
		}
		ConfigSystem.Save()
		FullCleanup()
	end))

	return topBar
end

-- ─── Sidebar ─────────────────────────────────────────────────────────────

function UIInit.CreateSidebar(mainFrame)
	local sidebar = UI.Create("Frame", {
		Name = "Sidebar",
		Parent = mainFrame,
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 2, 0, CONSTANTS.TOPBAR_HEIGHT + 2),
		Size = UDim2.new(0, Persist.Config.SidebarWidth, 1, -CONSTANTS.TOPBAR_HEIGHT - 4),
		ZIndex = CONSTANTS.Z_BASE,
	})

	local sidebarScroll = UI.Create("ScrollingFrame", {
		Name = "SidebarScroll",
		Parent = sidebar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 1, -8),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = CONSTANTS.Z_BASE + 1,
		ScrollingEnabled = true,
		Active = true,
	})

	local sidebarLayout = UI.Create("UIListLayout", {
		Parent = sidebarScroll,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	TrackInstance("SidebarScroll", sidebarScroll)

	TrackConnection(sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 10)
	end))

	return sidebar, sidebarScroll, sidebarLayout
end

-- ─── Content Area ──────────────────────────────────────────────────────

function UIInit.CreateContent(mainFrame)
	local contentFrame = UI.Create("Frame", {
		Name = "ContentFrame",
		Parent = mainFrame,
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Position = UDim2.new(0, Persist.Config.SidebarWidth, 0, CONSTANTS.TOPBAR_HEIGHT + 2),
		Size = UDim2.new(1, -Persist.Config.SidebarWidth, 1, -CONSTANTS.TOPBAR_HEIGHT - 4),
		ZIndex = CONSTANTS.Z_BASE,
		ClipsDescendants = true,
	})

	local contentScroll = UI.Create("ScrollingFrame", {
		Name = "ContentScroll",
		Parent = contentFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 12),
		Size = UDim2.new(1, -24, 1, -24),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = CONSTANTS.Z_BASE + 1,
		ScrollingEnabled = true,
		Active = true,
		ClipsDescendants = true,
	})

	local contentList = UI.Create("UIListLayout", {
		Parent = contentScroll,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	TrackConnection(contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 20)
	end))
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 20)

	TrackInstance("ContentScroll", contentScroll)
	return contentFrame, contentScroll
end

-- ─── Resize Handle ─────────────────────────────────────────────────────

function UIInit.CreateResizeHandle(mainFrame)
	local resizeHandle = UI.Create("Frame", {
		Name = "ResizeHandle",
		Parent = mainFrame,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 15,
	})

	UI.Create("TextLabel", {
		Parent = resizeHandle,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "//",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 10,
		TextTransparency = 0.4,
		ZIndex = 16,
	})

	local resizeBtn = UI.Create("TextButton", {
		Parent = resizeHandle,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		ZIndex = 16,
		Active = true,
		AutoButtonColor = false,
	})

	TrackConnection(resizeBtn.InputBegan:Connect(function(input)
		if State.ModalOpen then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			State.IsResizing = true
			State.ResizeStartSize = mainFrame.Size
			State.ResizeStartPos = input.Position
		end
	end))

	TrackInstance("ResizeHandle", resizeHandle)
	return resizeHandle
end

-- ─── Sidebar Setup ─────────────────────────────────────────────────────

function UIInit.SetupSidebar(sidebarScroll)
	local sidebarItems = {
		{ Name = "Account", Icon = "👤", Color = Theme.Accent, Page = Pages.Account },
		{ Name = "Home", Icon = "🏠", Color = Theme.Accent, Page = Pages.Home },
		{ Name = "Premium", Icon = "💎", Color = Theme.AccentPink, Page = Pages.Premium },
		{ Name = "Shop", Icon = "🏪", Color = Theme.Accent, Page = Pages.Shop },
		{ Name = "Settings", Icon = "⚙️", Color = Theme.AccentCyan, Page = Pages.Settings },
	}

	for _, item in ipairs(sidebarItems) do
		local sidebarBtn = UI.Create("TextButton", {
			Name = item.Name,
			Parent = sidebarScroll,
			BackgroundColor3 = (item.Name == "Home") and Theme.Card or Theme.Sidebar,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, 36),
			Position = UDim2.new(0, 5, 0, 0),
			Font = Enum.Font.Gotham,
			Text = "  " .. item.Icon .. "  " .. item.Name,
			TextColor3 = item.Color,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			ZIndex = CONSTANTS.Z_BASE + 2,
			Active = true,
		})
		UI.AddCorner(sidebarBtn, 4)

		State.SidebarButtons[item.Name] = function()
			State.CurrentPage = item.Name
			for _, child in pairs(sidebarScroll:GetChildren()) do
				if child:IsA("TextButton") then
					local isSelected = (child.Name == item.Name)
					TweenSystem.Tween(child, { BackgroundColor3 = isSelected and Theme.Card or Theme.Sidebar }, 0.2)
				end
			end
			item.Page()
		end

		TrackConnection(sidebarBtn.MouseEnter:Connect(function()
			if State.CurrentPage ~= item.Name then
				TweenSystem.Tween(sidebarBtn, { BackgroundColor3 = Theme.CardHover }, 0.15)
			end
		end))
		TrackConnection(sidebarBtn.MouseLeave:Connect(function()
			if State.CurrentPage ~= item.Name then
				TweenSystem.Tween(sidebarBtn, { BackgroundColor3 = Theme.Sidebar }, 0.15)
			end
		end))

		TrackConnection(sidebarBtn.Activated:Connect(State.SidebarButtons[item.Name]))
		SearchSystem.Register(item.Name, item.Name, item.Icon, State.SidebarButtons[item.Name])
	end

	sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, #sidebarItems * 39 + 10)
end

-- ─── Window Drag ───────────────────────────────────────────────────────

function UIInit.SetupWindowDrag(mainFrame)
	TrackConnection(mainFrame.InputBegan:Connect(function(input)
		if State.ModalOpen then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			State.IsDraggingWindow = true
			State.DragStartPos = input.Position
			State.FrameStartPos = mainFrame.Position
		end
	end))

	TrackConnection(Services.UserInputService.InputChanged:Connect(function(input)
		if
			State.IsDraggingWindow
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - State.DragStartPos
			mainFrame.Position = UDim2.new(
				State.FrameStartPos.X.Scale,
				State.FrameStartPos.X.Offset + delta.X,
				State.FrameStartPos.Y.Scale,
				State.FrameStartPos.Y.Offset + delta.Y
			)
		end
		if
			State.IsResizing
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - State.ResizeStartPos
			mainFrame.Size = UDim2.new(
				0,
				math_max(Persist.Config.MinWindowWidth, State.ResizeStartSize.X.Offset + delta.X),
				0,
				math_max(Persist.Config.MinWindowHeight, State.ResizeStartSize.Y.Offset + delta.Y)
			)
		end
	end))

	TrackConnection(Services.UserInputService.InputEnded:Connect(function(input)
		if State.IsDraggingWindow then
			State.IsDraggingWindow = false
		end
		if State.IsResizing then
			State.IsResizing = false
		end
	end))
end

-- ─── Global Input ──────────────────────────────────────────────────────

function UIInit.SetupGlobalInput()
	TrackConnection(Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local pos = input.Position
		local suggestFrame = Instances.SuggestFrame
		local searchFrame = Instances.SearchFrame
		if suggestFrame and suggestFrame.Visible then
			if not Utils.IsPointInGui(pos, searchFrame) and not Utils.IsPointInGui(pos, suggestFrame) then
				suggestFrame.Visible = false
			end
		end

		if State.ActiveDropdownFrame and State.ActiveDropdownFrame.Parent then
			if Utils.IsPointInGui(pos, State.ActiveDropdownFrame) then
				return
			end
			if State.ActiveDropdownCard and Utils.IsPointInGui(pos, State.ActiveDropdownCard) then
				return
			end
			DropdownSystem.Close()
		end
	end))
end

-- ─── Mobile Sizing ─────────────────────────────────────────────────────

function UIInit.ApplyMobileSizing()
	local success, err = pcall(function()
		if not Services.UserInputService.TouchEnabled then
			return
		end
		local camera = Services.Workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize
		if not viewport or viewport.X < 100 or viewport.Y < 100 then
			viewport = Vector2.new(800, 600)
		end
		local w = math_min(Persist.Config.WindowWidth, viewport.X - CONSTANTS.MOBILE_PADDING_X)
		local h = math_min(Persist.Config.WindowHeight, viewport.Y - CONSTANTS.MOBILE_PADDING_Y)
		w = math_max(w, Persist.Config.MinWindowWidth)
		h = math_max(h, Persist.Config.MinWindowHeight)
		local mainFrame = Instances.MainFrame
		if mainFrame then
			mainFrame.Size = UDim2.new(0, w, 0, h)
			mainFrame.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
		end
		print(string_format("[LRX_Hub] Mobile sizing applied: %dx%d", w, h))
	end)
	if not success then
		warn("[LRX_Hub] Mobile sizing failed:", err)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 24: BACKGROUND TASKS
-- ═══════════════════════════════════════════════════════════════════════

local BackgroundTasks = {}

function BackgroundTasks.StartSeedPlacerLoop()
	TrackThread(task_spawn(function()
		while State.ScriptRunning do
			task_wait(CONSTANTS.PLANT_CYCLE_INTERVAL)
			if Persist.Config.EnableSeedPlacer then
				local ok, err = pcall(function()
					SeedPlacer.RunCycle()
				end)
				if not ok then
					warn("[SeedPlacer Loop Error]", err)
				end
			end
		end
	end))
end

function BackgroundTasks.StartAutoBuyLoop()
	local cachedSheckles = nil
	local lastCheck = 0

	TrackThread(task_spawn(function()
		while State.ScriptRunning do
			task_wait(CONSTANTS.AUTO_BUY_INTERVAL)
			if Persist.Config.EnableSeedShop and Networking and SeedData then
				if not cachedSheckles or tick() - lastCheck > 5 then
					local leaderstats = Player:FindFirstChild("leaderstats")
					cachedSheckles = leaderstats and leaderstats:FindFirstChild("Sheckles")
					lastCheck = tick()
				end

				if cachedSheckles then
					local ok, err = pcall(function()
						for _, seed in ipairs(SeedData) do
							if
								Persist.Config.SelectedSeeds[seed.SeedName]
								and cachedSheckles.Value >= (seed.PurchasePrice or 0)
							then
								Networking.SeedShop.PurchaseSeed:Fire(seed.SeedName)
							end
						end
					end)
					if not ok then
						warn("[AutoBuy Loop Error]", err)
					end
				end
			end
		end
	end))
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 25: CLEANUP
-- ═══════════════════════════════════════════════════════════════════════

function FullCleanup()
	State.ScriptRunning = false
	DisconnectAll()
	CancelAllThreads()
	DestroyAllInstances()

	-- Clear caches
	for key in pairs(Cache) do
		if key ~= "TweenInfo" then
			Cache[key] = nil
		end
	end
	Cache.TweenInfo = {}

	-- Clear state (keep minimal)
	for key in pairs(State) do
		if type(State[key]) == "table" then
			table_clear(State[key])
		else
			State[key] = nil
		end
	end
	-- Stop auto farm threads
	Persist.Config.EnableAutoCollect = false
	Persist.Config.EnableAutoShovel = false
	State.AutoCollectThread = nil
	State.AutoShovelThread = nil
	State.ScriptRunning = false
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 26: INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════

local function Initialize()
	local initSuccess, initError = pcall(function()
		local screenGui = UIInit.CreateScreenGui()
		local mainFrame = UIInit.CreateMainFrame(screenGui)
		UIInit.CreateToggleButton(screenGui)
		UIInit.CreateTopBar(mainFrame, screenGui)
		local sidebar, sidebarScroll = UIInit.CreateSidebar(mainFrame)
		UIInit.CreateContent(mainFrame)
		UIInit.CreateResizeHandle(mainFrame)
		UIInit.SetupSidebar(sidebarScroll)
		UIInit.SetupWindowDrag(mainFrame)
		UIInit.SetupGlobalInput()

		ConfigSystem.Load()
		-- Restore auto farm states
		if Persist.Config.EnableAutoCollect then
			task_delay(2, function()
				AutoFarmSystem.StartCollect()
			end)
		end
		if Persist.Config.EnableAutoShovel then
			task_delay(2, function()
				AutoFarmSystem.StartShovel()
			end)
		end
		if Persist.Config.ShowGridDots then
			task_delay(1.5, function()
				local ok, err = pcall(function()
					GridSystem.Refresh()
				end)
				if not ok then
					warn("[Init] Grid dots restore failed:", err)
				end
			end)
		end

		BackgroundTasks.StartSeedPlacerLoop()
		BackgroundTasks.StartAutoBuyLoop()

		Pages.Home()

		if Services.UserInputService.TouchEnabled then
			task_delay(CONSTANTS.MOBILE_INIT_DELAY, UIInit.ApplyMobileSizing)
		end
	end)

	if not initSuccess then
		warn("[LRX_Hub] CRITICAL INIT ERROR:", initError)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════════

Initialize()
