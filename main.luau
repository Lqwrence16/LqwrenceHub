-- ═══════════════════════════════════════════════════════════════════════
--  LRX_Hub v3.0.0 - Production Refactor
--  Architecture: Modular, Performance-Optimized, Memory-Safe
-- ═══════════════════════════════════════════════════════════════════════

--[[
    ARCHITECTURE OVERVIEW:

    1. CONSTANTS        - Immutable configuration values
    2. SERVICES         - Cached Roblox service references
    3. STATE            - Runtime mutable state (separated from Config)
    4. CONFIG           - User-persistent settings with validation
    5. THEMES           - Visual styling definitions
    6. UTILITIES        - Reusable helper functions
    7. MEMORY           - Connection & task lifecycle management
    8. NOTIFICATIONS    - Toast system with queue management
    9. LASER SYSTEM     - Visual plot scanning effects
    10. GRID SYSTEM     - Planting position visualization
    11. PLOT SYSTEM     - Plot detection & bed management
    12. SEED PLACER     - Plant placement automation
    13. CONFIG SYSTEM   - Save/load with serialization
    14. UI SYSTEM       - Component factory & page management
    15. INITIALIZATION  - Boot sequence & error recovery
--]]

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 1: CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════

local CONSTANTS = {
	-- File & attribute names
	CONFIG_FILE = "LRX_Hub_Config.json",
	CONFIG_ATTRIBUTE = "LRX_Hub_Config",

	-- UI dimensions
	DEFAULT_WINDOW_WIDTH = 600,
	DEFAULT_WINDOW_HEIGHT = 400,
	MIN_WINDOW_WIDTH = 320,
	MIN_WINDOW_HEIGHT = 240,
	SIDEBAR_WIDTH = 170,
	TOPBAR_HEIGHT = 44,

	-- Planting defaults
	DEFAULT_PLACE_AMOUNT = 10,
	DEFAULT_PLANT_SPACING = 1,
	DEFAULT_PLANT_DELAY = 0.05,

	-- Visual
	MAX_NOTIFICATIONS = 5,
	NOTIFICATION_HEIGHT = 70,
	NOTIFICATION_WIDTH = 280,
	NOTIFICATION_DURATION = 3,
	MAX_DROPDOWN_HEIGHT = 260,
	DROPDOWN_ANIMATION_SPEED = 0.2,

	-- Grid dots
	GRID_DOT_SIZE = 0.08,
	GRID_DOT_BATCH_SIZE = 500,
	GRID_DOT_BATCH_DELAY = 0.05,
	GRID_DOT_Y_OFFSET = 0.05,

	-- Laser scan
	LASER_SCAN_DURATION = 1.5,
	LASER_SWEEP_COUNT = 6,
	LASER_BEAM_THICKNESS = 0.05,

	-- Performance
	PLANT_CYCLE_INTERVAL = 0.2,
	AUTO_BUY_INTERVAL = 0.2,
	AUTO_SAVE_DEBOUNCE = 1,
	YIELD_INTERVAL = 200,

	-- Z-Index layers
	Z_BASE = 10,
	Z_DROPDOWN = 50,
	Z_NOTIFICATION = 700,
	Z_MODAL_OVERLAY = 500,
	Z_MODAL = 600,

	-- Mobile
	MOBILE_PADDING_X = 20,
	MOBILE_PADDING_Y = 40,
	MOBILE_INIT_DELAY = 0.5,

	-- Position rounding
	POSITION_PRECISION = 100,
	OCCUPIED_LOOKUP_PRECISION = 2,

	-- Occupancy
	OCCUPANCY_TOLERANCE = 0.5,

	-- Rarity colors
	RARITY_COLORS = {
		Common = Color3.fromRGB(169, 169, 169),
		Uncommon = Color3.fromRGB(50, 205, 50),
		Rare = Color3.fromRGB(30, 144, 255),
		Epic = Color3.fromRGB(147, 112, 219),
		Legendary = Color3.fromRGB(255, 215, 0),
		Mythic = Color3.fromRGB(255, 69, 0),
	},

	-- Notification type colors
	NOTIF_COLORS = {
		Success = Color3.fromRGB(50, 205, 50),
		Warning = Color3.fromRGB(255, 165, 0),
		Error = Color3.fromRGB(255, 80, 80),
		Info = Color3.fromRGB(100, 150, 255),
	},

	-- Grid dot colors
	GRID_DOT_COLORS = {
		Color3.fromRGB(50, 205, 50),
		Color3.fromRGB(255, 215, 0),
		Color3.fromRGB(0, 255, 127),
		Color3.fromRGB(255, 165, 0),
	},
}

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 2: SERVICES (cached once, never re-fetched)
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

-- Cache networking modules (loaded once, nil if unavailable)
local Networking, SeedData
pcall(function()
	Networking = require(Services.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
	SeedData = require(Services.ReplicatedStorage.SharedModules:WaitForChild("SeedData"))
end)

-- Cache PlantRemote reference
local PlantRemote = Networking and Networking.Plant and Networking.Plant.PlantSeed

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 3: STATE (runtime-only, not persisted)
-- ═══════════════════════════════════════════════════════════════════════

local State = {
	ScriptRunning = true,
	ActiveNotifs = 0,
	CurrentPage = "Home",
	ModalOpen = false,
	CardOrder = 0,

	-- Dropdown state
	ActiveDropdownCard = nil,
	ActiveDropdownFrame = nil,
	DropdownDebounce = false,

	-- Modal state
	ActiveModal = nil,
	ModalOverlay = nil,

	-- Drag state
	IsDraggingWindow = false,
	IsDraggingToggle = false,
	DragStartPos = nil,
	FrameStartPos = nil,
	ToggleStartPos = nil,
	ToggleBtnStart = nil,

	-- Resize state
	IsResizing = false,

	-- Auto-save debounce handle
	AutoSaveDebounce = nil,

	-- Cached plot reference
	CachedPlot = nil,
	CachedPlotParts = nil,
	CachedPartOptions = nil,

	-- UI references (populated during init)
	ScreenGui = nil,
	MainFrame = nil,
	ContentScroll = nil,
	SidebarScroll = nil,
	SearchFrame = nil,
	SuggestFrame = nil,
	SuggestScroll = nil,
	SearchBox = nil,
	PageTitle = nil,
	PageSubtitle = nil,
	MainIcon = nil,
	ResizeHandle = nil,

	-- Collections
	Connections = {},
	Tasks = {},
	SidebarButtons = {},
	SearchableItems = {},
	GridDots = {},
	LaserBeams = {},

	-- Folders
	DotsFolder = nil,
	LaserFolder = nil,
}

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 4: CONFIG (user-persistent settings)
-- ═══════════════════════════════════════════════════════════════════════

local Config = {
	-- Window
	WindowWidth = CONSTANTS.DEFAULT_WINDOW_WIDTH,
	WindowHeight = CONSTANTS.DEFAULT_WINDOW_HEIGHT,
	MinWindowWidth = CONSTANTS.MIN_WINDOW_WIDTH,
	MinWindowHeight = CONSTANTS.MIN_WINDOW_HEIGHT,
	SidebarWidth = CONSTANTS.SIDEBAR_WIDTH,
	WindowPosition = nil,
	WindowSize = nil,

	-- Appearance
	ToggleButtonText = "LRX",
	Theme = "Dark",
	AnimationSpeed = 0.2,
	DisableAnimations = false,
	NotificationDuration = CONSTANTS.NOTIFICATION_DURATION,
	ModalDarkening = 0.5,
	UIScale = 1.0,

	-- Shop
	SelectedSeeds = {},
	EnableSeedShop = false,

	-- Seed Placer
	SelectedPlaceSeeds = {},
	EnableSeedPlacer = false,
	PlaceAmount = CONSTANTS.DEFAULT_PLACE_AMOUNT,
	PlantingArea = "All",
	PlantingPattern = "LeftToRight",
	PlantSpacing = CONSTANTS.DEFAULT_PLANT_SPACING,
	PlantDelay = CONSTANTS.DEFAULT_PLANT_DELAY,

	-- Visualizer
	ShowGridDots = false,

	-- Performance
	ReduceEffects = false,

	-- Input
	Keybinds = { ToggleUI = "F" },
}

-- Config validation & defaults
local ConfigSchema = {
	WindowWidth = {
		type = "number",
		min = CONSTANTS.MIN_WINDOW_WIDTH,
		max = 2000,
		default = CONSTANTS.DEFAULT_WINDOW_WIDTH,
	},
	WindowHeight = {
		type = "number",
		min = CONSTANTS.MIN_WINDOW_HEIGHT,
		max = 1500,
		default = CONSTANTS.DEFAULT_WINDOW_HEIGHT,
	},
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
	ShowGridDots = { type = "boolean", default = false },
	ReduceEffects = { type = "boolean", default = false },
	Keybinds = { type = "table", default = { ToggleUI = "F" } },
}

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 5: THEMES
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

local Theme = Themes[Config.Theme] or Themes.Dark

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 6: UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

local Utils = {}

--[[
    Rounds a number to specified decimal places.
    More efficient than string formatting for position calculations.
--]]
function Utils.Round(num, precision)
	precision = precision or CONSTANTS.POSITION_PRECISION
	return math.floor(num * precision + 0.5) / precision
end

--[[
    Formats a position vector for deduplication keys.
    Uses cached precision for consistent occupancy lookups.
--]]
function Utils.FormatPositionKey(pos, precision)
	precision = precision or CONSTANTS.OCCUPIED_LOOKUP_PRECISION
	local mult = precision * 10
	local x = math.floor(pos.X * mult + 0.5) / mult
	local z = math.floor(pos.Z * mult + 0.5) / mult
	return string.format("%.1f,%.1f", x, z)
end

--[[
    Clamps a value between min and max.
--]]
function Utils.Clamp(value, min, max)
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
end

--[[
    Validates and coerces a config value against its schema.
    Returns the validated value (or default if invalid).
--]]
function Utils.ValidateConfigValue(key, value)
	local schema = ConfigSchema[key]
	if not schema then
		return value -- Unknown key, pass through
	end

	local valueType = typeof(value)

	if schema.type == "number" then
		if valueType ~= "number" then
			return schema.default
		end
		return Utils.Clamp(value, schema.min, schema.max)
	elseif schema.type == "string" then
		if valueType ~= "string" then
			return schema.default
		end
		return value
	elseif schema.type == "boolean" then
		if valueType ~= "boolean" then
			return schema.default
		end
		return value
	elseif schema.type == "table" then
		if valueType ~= "table" then
			return table.clone(schema.default)
		end
		return value
	end

	return schema.default
end

--[[
    Formats selected seeds for display with truncation.
--]]
function Utils.FormatSelectedSeeds(selectedTable, maxDisplay)
	maxDisplay = maxDisplay or 10
	local names = {}

	for seedName, selected in pairs(selectedTable) do
		if selected then
			table.insert(names, seedName)
		end
	end

	table.sort(names)

	local count = #names
	if count == 0 then
		return "Selected (0): None"
	end

	local shown = {}
	for i = 1, math.min(count, maxDisplay) do
		table.insert(shown, names[i])
	end

	local text = table.concat(shown, ", ")
	if count > maxDisplay then
		text = text .. "..."
	end

	return string.format("Selected (%d): %s", count, text)
end

--[[
    Formats price with K suffix for large values.
--]]
function Utils.FormatPrice(price)
	if not price or price <= 0 then
		return "$0"
	end
	if price >= 1000 then
		return string.format("$%.2fK", price / 1000)
	end
	return "$" .. tostring(price)
end

--[[
    Checks if a point is inside a BasePart using object-space coordinates.
    More efficient than world-space distance checks.
--]]
function Utils.IsPointInPart(point, part)
	local localPos = part.CFrame:PointToObjectSpace(point)
	local halfSize = part.Size / 2
	return math.abs(localPos.X) <= halfSize.X + 0.1
		and math.abs(localPos.Y) <= halfSize.Y + 0.1
		and math.abs(localPos.Z) <= halfSize.Z + 0.1
end

--[[
    Gets the world-space bounds of a part.
    Returns minX, maxX, minZ, maxZ.
--]]
function Utils.GetWorldBoundsXZ(part)
	local cf = part.CFrame
	local hs = part.Size / 2

	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge

	-- Only check the 4 corners on the XZ plane (Y doesn't matter for planting)
	for dx = -1, 1, 2 do
		for dz = -1, 1, 2 do
			local corner = cf * Vector3.new(dx * hs.X, 0, dz * hs.Z)
			minX = math.min(minX, corner.X)
			maxX = math.max(maxX, corner.X)
			minZ = math.min(minZ, corner.Z)
			maxZ = math.max(maxZ, corner.Z)
		end
	end

	return minX, maxX, minZ, maxZ
end

--[[
    Gets player position from HumanoidRootPart.
    Returns nil if character not ready.
--]]
function Utils.GetPlayerPosition()
	local character = Player.Character
	if not character then
		return nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or nil
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 7: MEMORY MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════

local Memory = {}

--[[
    Tracks a connection for automatic cleanup.
    Returns the connection for chaining.
--]]
function Memory.TrackConnection(connection)
	table.insert(State.Connections, connection)
	return connection
end

--[[
    Disconnects all tracked connections and clears the table.
    Safe to call multiple times.
--]]
function Memory.DisconnectAll()
	for _, connection in ipairs(State.Connections) do
		if connection and connection.Connected then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	table.clear(State.Connections)
end

--[[
    Cancels all tracked tasks.
--]]
function Memory.CancelAllTasks()
	for _, taskHandle in ipairs(State.Tasks) do
		if taskHandle then
			pcall(function()
				task.cancel(taskHandle)
			end)
		end
	end
	table.clear(State.Tasks)
end

--[[
    Destroys all instances in a table and clears it.
--]]
function Memory.DestroyTableInstances(instanceTable)
	for _, instance in ipairs(instanceTable) do
		if instance then
			pcall(function()
				instance:Destroy()
			end)
		end
	end
	table.clear(instanceTable)
end

--[[
    Ensures a folder exists in workspace, creating if necessary.
    Returns the folder.
--]]
function Memory.EnsureWorkspaceFolder(folderName, stateKey)
	local folder = State[stateKey]
	if folder and folder.Parent then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = Services.Workspace
	State[stateKey] = folder
	return folder
end

--[[
    Full cleanup on script shutdown.
--]]
function Memory.FullCleanup()
	State.ScriptRunning = false
	Memory.DisconnectAll()
	Memory.CancelAllTasks()
	Memory.DestroyTableInstances(State.GridDots)
	Memory.DestroyTableInstances(State.LaserBeams)

	if State.DotsFolder then
		pcall(function()
			State.DotsFolder:Destroy()
		end)
		State.DotsFolder = nil
	end

	if State.LaserFolder then
		pcall(function()
			State.LaserFolder:Destroy()
		end)
		State.LaserFolder = nil
	end

	if State.ScreenGui then
		pcall(function()
			State.ScreenGui:Destroy()
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 8: TWEEN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local TweenSystem = {}

--[[
    Cached TweenInfo for common animation patterns.
    Reduces GC pressure from creating many TweenInfo objects.
--]]
local TweenInfoCache = {}

function TweenSystem.GetTweenInfo(duration, style, direction)
	style = style or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	duration = duration or Config.AnimationSpeed

	local key = string.format("%.2f_%s_%s", duration, tostring(style), tostring(direction))

	if not TweenInfoCache[key] then
		TweenInfoCache[key] = TweenInfo.new(duration, style, direction)
	end

	return TweenInfoCache[key]
end

--[[
    Applies a tween to an instance.
    If animations are disabled, applies properties instantly.
--]]
function TweenSystem.Tween(instance, properties, duration, callback)
	if Config.DisableAnimations then
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
		Memory.TrackConnection(tween.Completed:Connect(callback))
	end

	tween:Play()
	return tween
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 9: NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local NotificationSystem = {}

--[[
    Shows a notification toast.
    Manages a queue to prevent overflow.
--]]
function NotificationSystem.Notify(title, message, notifType, duration)
	notifType = notifType or "Info"
	duration = duration or Config.NotificationDuration
	local accent = CONSTANTS.NOTIF_COLORS[notifType] or CONSTANTS.NOTIF_COLORS.Info

	-- Wait if queue is full
	while State.ActiveNotifs >= CONSTANTS.MAX_NOTIFICATIONS do
		task.wait(0.1)
	end

	State.ActiveNotifs += 1
	local notifIndex = State.ActiveNotifs

	local frame = Instance.new("Frame")
	frame.Name = "Notification_" .. notifIndex
	frame.Parent = State.ScreenGui
	frame.BackgroundColor3 = Theme.Card
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(1, 20, 0, 20 + (notifIndex - 1) * CONSTANTS.NOTIFICATION_HEIGHT)
	frame.Size = UDim2.new(0, CONSTANTS.NOTIFICATION_WIDTH, 0, 60)
	frame.ZIndex = CONSTANTS.Z_NOTIFICATION
	frame.Active = true

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

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
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

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

	-- Slide in
	TweenSystem.Tween(frame, {
		Position = UDim2.new(1, -CONSTANTS.NOTIFICATION_WIDTH - 20, 0, frame.Position.Y.Offset),
	}, 0.3)

	-- Auto-dismiss
	task.delay(duration, function()
		if not frame or not frame.Parent then
			State.ActiveNotifs = math.max(0, State.ActiveNotifs - 1)
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
				State.ActiveNotifs = math.max(0, State.ActiveNotifs - 1)
			end
		)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 10: LASER VISUALIZATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local LaserSystem = {}

--[[
    Clears all active laser beams.
--]]
function LaserSystem.Clear()
	Memory.DestroyTableInstances(State.LaserBeams)
end

--[[
    Creates a single laser beam between two points.
--]]
function LaserSystem.CreateBeam(startPos, endPos, color, duration)
	local folder = Memory.EnsureWorkspaceFolder("LRX_Lasers", "LaserFolder")

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

	table.insert(State.LaserBeams, beamPart)

	if duration then
		task.delay(duration, function()
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

--[[
    Performs a laser scan animation on a plot.
    Uses task.delay for non-blocking sequential effects.
--]]
function LaserSystem.ScanPlot(plot, scanDuration)
	LaserSystem.Clear()

	if not plot then
		return
	end

	local visual = plot:FindFirstChild("Visual")
	if not visual then
		return
	end

	-- Collect PlantAreaColumn parts
	local parts = {}
	for _, child in ipairs(visual:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^PlantAreaColumn") then
			table.insert(parts, child)
		end
	end

	if #parts == 0 then
		return
	end

	scanDuration = scanDuration or CONSTANTS.LASER_SCAN_DURATION

	-- Calculate bounds
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

	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge

	for _, corner in ipairs(allCorners) do
		minX = math.min(minX, corner.X)
		maxX = math.max(maxX, corner.X)
		minZ = math.min(minZ, corner.Z)
		maxZ = math.max(maxZ, corner.Z)
	end

	local sweepHeight = minY + 2
	local sweepCount = CONSTANTS.LASER_SWEEP_COUNT
	local stepDelay = scanDuration / sweepCount

	-- Horizontal sweeps
	for i = 1, sweepCount do
		task.delay((i - 1) * stepDelay, function()
			if not State.ScriptRunning then
				return
			end
			local t = (i - 1) / math.max(1, sweepCount - 1)
			local z = minZ + (maxZ - minZ) * t
			LaserSystem.CreateBeam(
				Vector3.new(minX, sweepHeight, z),
				Vector3.new(maxX, sweepHeight, z),
				Color3.fromRGB(0, 255, 255),
				0.4
			)
		end)
	end

	-- Vertical sweeps
	for i = 1, sweepCount do
		task.delay((i - 1) * stepDelay + 0.05, function()
			if not State.ScriptRunning then
				return
			end
			local t = (i - 1) / math.max(1, sweepCount - 1)
			local x = minX + (maxX - minX) * t
			LaserSystem.CreateBeam(
				Vector3.new(x, sweepHeight + 0.5, minZ),
				Vector3.new(x, sweepHeight + 0.5, maxZ),
				Color3.fromRGB(255, 0, 255),
				0.4
			)
		end)
	end

	-- Diagonal beams
	task.delay(0.1, function()
		if not State.ScriptRunning then
			return
		end
		local h = sweepHeight
		LaserSystem.CreateBeam(Vector3.new(minX, h, minZ), Vector3.new(maxX, h, maxZ), Color3.fromRGB(50, 205, 50), 0.6)
		LaserSystem.CreateBeam(Vector3.new(minX, h, maxZ), Vector3.new(maxX, h, minZ), Color3.fromRGB(50, 205, 50), 0.6)
	end)

	-- Corner outline
	task.delay(scanDuration * 0.5, function()
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

	-- Auto-cleanup
	task.delay(scanDuration + 0.5, LaserSystem.Clear)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 11: GRID DOTS VISUALIZATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local GridSystem = {}

--[[
    Clears all grid dots.
--]]
function GridSystem.Clear()
	Memory.DestroyTableInstances(State.GridDots)
end

--[[
    Refreshes grid dots based on current planting positions.
    Uses batched creation to prevent frame drops.
--]]
function GridSystem.Refresh()
	GridSystem.Clear()

	if not Config.ShowGridDots then
		return
	end

	local plot = PlotSystem.FindPlayerPlot()
	if not plot then
		warn("[GridDots] Could not find player plot.")
		return
	end

	SeedPlacer.ClearCache()
	local positions = SeedPlacer.GetPlantPositions()

	if not positions or #positions == 0 then
		warn("[GridDots] No plant positions generated.")
		return
	end

	local folder = Memory.EnsureWorkspaceFolder("LRX_GridDots", "DotsFolder")
	local colors = CONSTANTS.GRID_DOT_COLORS
	local colorCount = #colors
	local dotSize = Vector3.new(CONSTANTS.GRID_DOT_SIZE, CONSTANTS.GRID_DOT_SIZE, CONSTANTS.GRID_DOT_SIZE)
	local yOffset = Vector3.new(0, CONSTANTS.GRID_DOT_Y_OFFSET, 0)
	local batchSize = CONSTANTS.GRID_DOT_BATCH_SIZE
	local batchDelay = CONSTANTS.GRID_DOT_BATCH_DELAY
	local total = #positions

	-- Create dots in batches
	for batchStart = 1, total, batchSize do
		task.delay(math.floor((batchStart - 1) / batchSize) * batchDelay, function()
			if not State.ScriptRunning or not Config.ShowGridDots then
				return
			end

			local batchEnd = math.min(batchStart + batchSize - 1, total)

			for i = batchStart, batchEnd do
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

				table.insert(State.GridDots, dot)
			end
		end)
	end

	NotificationSystem.Notify("Plot Visualizer", string.format("Showing %d grid dots", total), "Success", 2)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 12: PLOT DETECTION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local PlotSystem = {}

--[[
    Finds the player's plot using multiple strategies:
    1. Owner attribute match (fastest)
    2. OwnerUserId attribute match
    3. Position-based detection (fallback)

    Results are cached until explicitly cleared.
--]]
function PlotSystem.FindPlayerPlot()
	-- Return cached plot if still valid
	if State.CachedPlot and State.CachedPlot.Parent then
		return State.CachedPlot
	end

	local gardensFolder = Services.Workspace:FindFirstChild("Gardens")
	if not gardensFolder then
		warn("[PlotSystem] workspace.Gardens not found.")
		return nil
	end

	local plots = gardensFolder:GetChildren()

	-- Strategy 1 & 2: Owner attribute match
	for _, plot in ipairs(plots) do
		local ownerName = plot:GetAttribute("Owner")
		local ownerId = plot:GetAttribute("OwnerUserId")

		if ownerName == Player.Name or ownerId == Player.UserId then
			State.CachedPlot = plot
			State.CachedPlotParts = nil -- Invalidate parts cache
			State.CachedPartOptions = nil -- Invalidate options cache
			return plot
		end
	end

	-- Strategy 3: Position-based detection
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
				table.insert(columns, child)
			end
		end

		if #columns == 0 then
			continue
		end

		-- Check if player is inside any column
		local inside = false
		for _, col in ipairs(columns) do
			local localPos = col.CFrame:PointToObjectSpace(playerPos)
			local half = col.Size / 2
			if
				math.abs(localPos.X) <= half.X + CONSTANTS.OCCUPANCY_TOLERANCE
				and math.abs(localPos.Y) <= half.Y + 10
				and math.abs(localPos.Z) <= half.Z + CONSTANTS.OCCUPANCY_TOLERANCE
			then
				inside = true
				break
			end
		end

		if inside then
			-- Calculate center distance for ranking
			local center = Vector3.zero
			for _, col in ipairs(columns) do
				center += col.Position
			end
			center /= #columns

			table.insert(candidates, {
				Plot = plot,
				Distance = (center - playerPos).Magnitude,
			})
		end
	end

	if #candidates > 0 then
		table.sort(candidates, function(a, b)
			return a.Distance < b.Distance
		end)

		State.CachedPlot = candidates[1].Plot
		State.CachedPlotParts = nil
		State.CachedPartOptions = nil
		return candidates[1].Plot
	end

	warn("[PlotSystem] Could not find plot for player:", Player.Name)
	return nil
end

--[[
    Detects PlantAreaColumn parts within a plot's Visual folder.
    Results are cached per-plot.
--]]
function PlotSystem.DetectPlotParts(plot)
	if not plot then
		return {}
	end

	-- Return cached parts if available
	if State.CachedPlotParts and State.CachedPlot and State.CachedPlot == plot then
		return State.CachedPlotParts
	end

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

	State.CachedPlotParts = parts
	return parts
end

--[[
    Builds display options for plot parts with deduplication labels.
--]]
function PlotSystem.BuildPartOptions(parts)
	if State.CachedPartOptions then
		return State.CachedPartOptions
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

		table.insert(options, {
			Label = displayName,
			Value = value,
			Part = part,
		})
	end

	State.CachedPartOptions = options
	return options
end

--[[
    Finds a specific part by its option value.
--]]
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

--[[
    Clears all plot caches. Call when plot changes or config changes.
--]]
function PlotSystem.ClearCache()
	State.CachedPlot = nil
	State.CachedPlotParts = nil
	State.CachedPartOptions = nil
end

--[[
    Gets comprehensive detection info for UI display.
--]]
function PlotSystem.GetDetectionInfo()
	local plot = PlotSystem.FindPlayerPlot()
	if not plot then
		return {
			Parts = {},
			PartOptions = {},
			PartNames = {},
			PlotName = "None",
			PlotInstance = nil,
		}
	end

	local parts = PlotSystem.DetectPlotParts(plot)
	local options = PlotSystem.BuildPartOptions(parts)
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

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 13: SEED PLACER SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local SeedPlacer = {}

-- Private state
local PlantPositions = nil
local CurrentPlantIndex = 1
local LastConfigHash = nil

--[[
    Generates a hash of current planting configuration.
    Used to invalidate cached positions when settings change.
--]]
local function GetConfigHash()
	return string.format(
		"%s|%s|%.2f",
		Config.PlantingArea or "All",
		Config.PlantingPattern or "LeftToRight",
		Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING
	)
end

--[[
    Generates planting positions within target parts.
    Uses local-space iteration for accurate corner coverage.
    Optimized with deduplication and yielding for large counts.
--]]
local function GeneratePlantPositions(targetParts, spacing)
	if #targetParts == 0 then
		return {}
	end

	spacing = math.max(0.1, spacing)
	local positions = {}
	local seenKeys = {}
	local iterationCount = 0
	local yieldInterval = CONSTANTS.YIELD_INTERVAL

	for _, part in ipairs(targetParts) do
		local halfSize = part.Size / 2
		local cf = part.CFrame
		local plantY = part.Position.Y

		-- Iterate in local XZ space from edge to edge
		local startX = -halfSize.X
		local endX = halfSize.X
		local startZ = -halfSize.Z
		local endZ = halfSize.Z

		local localX = startX
		while localX <= endX + 0.001 do
			local localZ = startZ
			while localZ <= endZ + 0.001 do
				iterationCount += 1
				if iterationCount % yieldInterval == 0 then
					task.wait()
				end

				-- Transform to world space
				local worldPos = cf * Vector3.new(localX, 0, localZ)

				-- Round to reduce floating-point jitter
				local finalPos = Vector3.new(Utils.Round(worldPos.X), plantY, Utils.Round(worldPos.Z))

				-- Deduplicate across adjacent columns
				local key = Utils.FormatPositionKey(finalPos)
				if not seenKeys[key] then
					seenKeys[key] = true
					table.insert(positions, { Pos = finalPos, Part = part })
				end

				localZ += spacing
			end
			localX += spacing
		end
	end

	return positions
end

--[[
    Applies planting pattern to position array.
    Patterns: LeftToRight, RightToLeft, OutsideToCenter, CenterToOutside, Middle, Random
--]]
local function ApplyPattern(positions, pattern)
	local count = #positions
	if count == 0 then
		return positions
	end

	if pattern == "LeftToRight" then
		return positions
	elseif pattern == "RightToLeft" then
		local result = table.create(count)
		for i = count, 1, -1 do
			result[count - i + 1] = positions[i]
		end
		return result
	elseif pattern == "OutsideToCenter" then
		local result = table.create(count)
		local left = 1
		local right = count
		while left <= right do
			table.insert(result, positions[left])
			left += 1
			if left <= right then
				table.insert(result, positions[right])
				right -= 1
			end
		end
		return result
	elseif pattern == "CenterToOutside" then
		local result = table.create(count)
		local mid = math.ceil(count / 2)
		table.insert(result, positions[mid])

		local offset = 1
		while true do
			local added = false
			if mid - offset >= 1 then
				table.insert(result, positions[mid - offset])
				added = true
			end
			if mid + offset <= count then
				table.insert(result, positions[mid + offset])
				added = true
			end
			if not added then
				break
			end
			offset += 1
		end
		return result
	elseif pattern == "Middle" then
		-- Build a grid map for spiral ordering
		local minX, maxX = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge

		for _, posData in ipairs(positions) do
			local p = posData.Pos
			minX = math.min(minX, p.X)
			maxX = math.max(maxX, p.X)
			minZ = math.min(minZ, p.Z)
			maxZ = math.max(maxZ, p.Z)
		end

		local step = math.max(0.1, Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING)
		local cols = math.max(1, math.floor((maxX - minX) / step + 0.5) + 1)
		local rows = math.max(1, math.floor((maxZ - minZ) / step + 0.5) + 1)

		-- Map positions to grid cells
		local cellMap = table.create(rows)
		for r = 1, rows do
			cellMap[r] = table.create(cols)
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

		-- Spiral from center
		local result = table.create(count)
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

		while #result < count do
			for _ = 1, 2 do
				for _ = 1, steps do
					r += dr[dir + 1]
					c += dc[dir + 1]
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
			steps += 1
		end

		return result
	elseif pattern == "Random" then
		local result = table.create(count)
		for i = 1, count do
			result[i] = positions[i]
		end
		for i = count, 2, -1 do
			local j = math.random(1, i)
			result[i], result[j] = result[j], result[i]
		end
		return result
	end

	return positions
end

--[[
    Builds an occupancy lookup table from existing plants.
    Checks FakePlot first, then falls back to plot's Plants folder.
--]]
local function BuildOccupiedLookup()
	local occupied = {}

	local controllers = Player:FindFirstChild("PlayerScripts")
	local seedInspect = controllers and controllers:FindFirstChild("SeedInspectController")
	local fakePlot = seedInspect and seedInspect:FindFirstChild("FakePlot")

	local plantsFolder = fakePlot and fakePlot:FindFirstChild("Plants")

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

--[[
    Checks if a planting spot is empty.
--]]
local function IsSpotEmpty(spotPosition, occupiedLookup)
	local key = Utils.FormatPositionKey(spotPosition)
	return not occupiedLookup[key]
end

--[[
    Gets all plant positions for the current configuration.
    Uses caching to avoid regenerating positions unnecessarily.
--]]
function SeedPlacer.GetPlantPositions()
	local currentHash = GetConfigHash()
	if PlantPositions and LastConfigHash == currentHash then
		return PlantPositions
	end

	local plot = PlotSystem.FindPlayerPlot()
	if not plot then
		return nil
	end

	local allParts = PlotSystem.DetectPlotParts(plot)
	local targetParts = {}

	if Config.PlantingArea == "All" or not Config.PlantingArea or Config.PlantingArea == "" then
		for _, part in ipairs(allParts) do
			table.insert(targetParts, part)
		end
	else
		local selectedPart = PlotSystem.FindPartByValue(allParts, Config.PlantingArea)
		if selectedPart then
			table.insert(targetParts, selectedPart)
		else
			-- Fallback to all parts if specific part not found
			for _, part in ipairs(allParts) do
				table.insert(targetParts, part)
			end
		end
	end

	if #targetParts == 0 then
		warn("[SeedPlacer] No target parts found for area: " .. tostring(Config.PlantingArea))
		return nil
	end

	local positions = GeneratePlantPositions(targetParts, Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING)
	positions = ApplyPattern(positions, Config.PlantingPattern or "LeftToRight")

	PlantPositions = positions
	LastConfigHash = currentHash

	return positions
end

--[[
    Clears cached plant positions. Call when config changes.
--]]
function SeedPlacer.ClearCache()
	PlantPositions = nil
	CurrentPlantIndex = 1
	LastConfigHash = nil
end

--[[
    Runs a single planting cycle.
    Plants up to Config.PlaceAmount seeds in empty spots.
--]]
function SeedPlacer.RunCycle()
	if not PlantRemote then
		warn("[SeedPlacer] PlantSeed remote not available.")
		return
	end

	local allSpots = SeedPlacer.GetPlantPositions()
	if not allSpots then
		return
	end

	-- Collect enabled seed names
	local enabledSeeds = {}
	for seedName, enabled in pairs(Config.SelectedPlaceSeeds or {}) do
		if enabled then
			table.insert(enabledSeeds, seedName)
		end
	end

	if #enabledSeeds == 0 then
		return
	end

	local occupiedLookup = BuildOccupiedLookup()
	local totalSpots = #allSpots
	local maxPlantAmount = Config.PlaceAmount or CONSTANTS.DEFAULT_PLACE_AMOUNT
	local plantedCount = 0
	local seedIndex = 1
	local checkedCount = 0
	local delay = math.max(0, Config.PlantDelay or CONSTANTS.DEFAULT_PLANT_DELAY)

	while plantedCount < maxPlantAmount and checkedCount < totalSpots do
		if not Config.EnableSeedPlacer then
			break
		end

		local spot = allSpots[CurrentPlantIndex]
		if not spot or not spot.Part then
			CurrentPlantIndex = 1
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
				warn("[SeedPlacer] PlantSeed failed at spot " .. tostring(CurrentPlantIndex) .. ":", err)
			end

			plantedCount += 1

			if plantedCount < maxPlantAmount then
				task.wait(delay)
			end
		end

		CurrentPlantIndex += 1
		if CurrentPlantIndex > totalSpots then
			CurrentPlantIndex = 1
		end
	end

	if plantedCount > 0 then
		print(string.format("[SeedPlacer] Planted %d seeds this cycle.", plantedCount))
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 14: CONFIGURATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local ConfigSystem = {}

--[[
    Checks if a value is JSON-serializable.
--]]
local function IsSerializable(value)
	local valueType = typeof(value)
	return valueType == "nil" or valueType == "boolean" or valueType == "number" or valueType == "string"
end

--[[
    Recursively filters a table to only serializable values.
--]]
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

--[[
    Builds save data from current config.
--]]
function ConfigSystem.BuildSaveData()
	return FilterSerializable(Config)
end

--[[
    Validates and applies loaded data to Config.
--]]
function ConfigSystem.ApplyLoadedData(data)
	if typeof(data) ~= "table" then
		return false
	end

	for key, value in pairs(data) do
		if typeof(key) == "string" and ConfigSchema[key] then
			Config[key] = Utils.ValidateConfigValue(key, value)
		end
	end

	return true
end

--[[
    Saves configuration to file, attribute, or StringValue.
    Tries methods in order of preference.
--]]
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

	-- Method 1: File
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

	-- Method 2: Player attribute
	local attrOk = pcall(function()
		Player:SetAttribute(CONSTANTS.CONFIG_ATTRIBUTE, jsonString)
	end)
	if attrOk then
		if not silent then
			NotificationSystem.Notify("Config", "Saved (attribute)", "Info", 2)
		end
		return true, "attribute"
	end

	-- Method 3: StringValue
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

--[[
    Loads configuration from file, attribute, or StringValue.
--]]
function ConfigSystem.Load()
	local jsonString = nil
	local method = "none"

	-- Method 1: File
	if isfile and isfile(CONSTANTS.CONFIG_FILE) then
		local success, result = pcall(readfile, CONSTANTS.CONFIG_FILE)
		if success and result and #result > 0 then
			jsonString = result
			method = "file"
		end
	end

	-- Method 2: Player attribute
	if not jsonString then
		local success, result = pcall(function()
			return Player:GetAttribute(CONSTANTS.CONFIG_ATTRIBUTE)
		end)
		if success and result and typeof(result) == "string" and #result > 0 then
			jsonString = result
			method = "attribute"
		end
	end

	-- Method 3: StringValue
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
			if Config.Theme and Themes[Config.Theme] then
				Theme = Themes[Config.Theme]
			end
			NotificationSystem.Notify("Config", "Loaded from " .. method, "Success", 2)
			return true, method
		end
	end

	return false, "none"
end

--[[
    Resets configuration to defaults.
--]]
function ConfigSystem.Reset()
	-- Delete saved data
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

	-- Reset to defaults
	for key, schema in pairs(ConfigSchema) do
		Config[key] = schema.default
	end

	Theme = Themes.Dark
	SeedPlacer.ClearCache()
	PlotSystem.ClearCache()
	GridSystem.Refresh()

	NotificationSystem.Notify("Config", "Reset to defaults", "Warning", 3)
end

--[[
    Debounced auto-save. Only saves after changes stop for 1 second.
--]]
function ConfigSystem.AutoSave()
	if State.AutoSaveDebounce then
		pcall(function()
			task.cancel(State.AutoSaveDebounce)
		end)
	end

	State.AutoSaveDebounce = task.delay(CONSTANTS.AUTO_SAVE_DEBOUNCE, function()
		ConfigSystem.Save(true)
		State.AutoSaveDebounce = nil
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 15: UI COMPONENT FACTORY
-- ═══════════════════════════════════════════════════════════════════════

local UI = {}

--[[
    Creates a base instance with properties.
--]]
function UI.Create(className, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties or {}) do
		instance[property] = value
	end
	return instance
end

--[[
    Adds a UICorner to an instance.
--]]
function UI.AddCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = instance
	return corner
end

--[[
    Adds a UIStroke to an instance.
--]]
function UI.AddStroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Parent = instance
	return stroke
end

--[[
    Creates a card component.
--]]
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

	Memory.TrackConnection(card.MouseEnter:Connect(function()
		TweenSystem.Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)
	end))
	Memory.TrackConnection(card.MouseLeave:Connect(function()
		TweenSystem.Tween(card, { BackgroundColor3 = Theme.Card }, 0.15)
	end))

	return card
end

--[[
    Creates a toggle component.
--]]
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

	Memory.TrackConnection(toggleBg.Activated:Connect(function()
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

--[[
    Creates a button component.
--]]
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

	Memory.TrackConnection(btn.MouseEnter:Connect(function()
		TweenSystem.Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
	end))
	Memory.TrackConnection(btn.MouseLeave:Connect(function()
		TweenSystem.Tween(btn, { BackgroundColor3 = bgColor }, 0.15)
	end))

	if callback then
		Memory.TrackConnection(btn.Activated:Connect(function()
			local ok, err = pcall(callback)
			if not ok then
				warn("[Button Error]", err)
			end
		end))
	end

	return btn
end

--[[
    Creates a label component.
--]]
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

--[[
    Creates an input component.
--]]
function UI.CreateInput(parent, title, defaultText, callback)
	local container = UI.Create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 50),
	})

	UI.Create("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local box = UI.Create("TextBox", {
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
	UI.AddCorner(box, 4)

	Memory.TrackConnection(box.FocusLost:Connect(function()
		callback(box.Text)
	end))

	return container, box
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 16: DROPDOWN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local DropdownSystem = {}

--[[
    Closes the active dropdown.
--]]
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

--[[
    Toggles a dropdown for a card.
--]]
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

	local frame = UI.Create("Frame", {
		Name = "Dropdown",
		Parent = State.ContentScroll,
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

	task.wait()

	local contentHeight = list.AbsoluteContentSize.Y + 16
	local maxHeight = math.min(contentHeight, CONSTANTS.MAX_DROPDOWN_HEIGHT)

	scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	State.ActiveDropdownFrame = frame

	TweenSystem.Tween(frame, { Size = UDim2.new(1, 0, 0, maxHeight) }, CONSTANTS.DROPDOWN_ANIMATION_SPEED)

	task.delay(0.25, function()
		State.DropdownDebounce = false
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 17: MODAL SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local ModalSystem = {}

--[[
    Sets modal interaction state (disables background UI).
--]]
function ModalSystem.SetState(isOpen)
	State.ModalOpen = isOpen
	State.MainFrame.Active = not isOpen
	State.SidebarScroll.ScrollingEnabled = not isOpen
	State.ContentScroll.ScrollingEnabled = not isOpen
end

--[[
    Closes the active modal.
--]]
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
			State.ModalOverlay.Visible = false
			ModalSystem.SetState(false)
		end)
	end
end

--[[
    Shows a modal with the given title and content builder.
--]]
function ModalSystem.Show(title, buildFunc, width, height)
	width = width or 520
	height = height or 420

	-- Create overlay if needed
	if not State.ModalOverlay then
		State.ModalOverlay = UI.Create("Frame", {
			Name = "ModalOverlay",
			Parent = State.ScreenGui,
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
	end

	ModalSystem.SetState(true)
	State.ModalOverlay.Visible = true
	TweenSystem.Tween(State.ModalOverlay, { BackgroundTransparency = Config.ModalDarkening }, 0.2)

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
	Memory.TrackConnection(closeBtn.Activated:Connect(ModalSystem.Close))

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
-- SECTION 18: SEARCH SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local SearchSystem = {}

--[[
    Registers an item for search.
--]]
function SearchSystem.Register(itemName, targetPage, itemIcon, itemAction)
	table.insert(State.SearchableItems, {
		Name = itemName,
		Page = targetPage,
		Icon = itemIcon,
		Action = itemAction,
	})
end

--[[
    Performs a search query.
--]]
function SearchSystem.Query(searchQuery)
	local results = {}
	local lowerQuery = searchQuery:lower()

	for _, item in ipairs(State.SearchableItems) do
		if item.Name:lower():find(lowerQuery, 1, true) then
			table.insert(results, item)
		end
	end

	return results
end

--[[
    Updates search suggestions UI.
--]]
function SearchSystem.UpdateSuggestions()
	-- Clear existing suggestions
	for _, child in pairs(State.SuggestScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local searchText = State.SearchBox.Text:lower()
	if searchText == "" or searchText == "search" then
		State.SuggestFrame.Visible = false
		return
	end

	local matches = SearchSystem.Query(searchText)
	if #matches == 0 then
		State.SuggestFrame.Visible = false
		return
	end

	-- Position suggestion frame below search box
	local searchAbsPos = State.SearchFrame.AbsolutePosition
	local searchAbsSize = State.SearchFrame.AbsoluteSize
	State.SuggestFrame.Position = UDim2.new(0, searchAbsPos.X, 0, searchAbsPos.Y + searchAbsSize.Y + 4)
	State.SuggestFrame.Size = UDim2.new(0, searchAbsSize.X, 0, math.min(#matches * 34 + 10, 220))

	for _, item in ipairs(matches) do
		local btn = UI.Create("TextButton", {
			Parent = State.SuggestScroll,
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

		Memory.TrackConnection(btn.MouseEnter:Connect(function()
			TweenSystem.Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end))
		Memory.TrackConnection(btn.MouseLeave:Connect(function()
			TweenSystem.Tween(btn, { BackgroundColor3 = Theme.Card }, 0.15)
		end))

		Memory.TrackConnection(btn.Activated:Connect(function()
			State.SuggestFrame.Visible = false
			State.SearchBox.Text = "Search"
			if item.Action then
				local ok, err = pcall(item.Action)
				if not ok then
					warn("[Search Action Error]", err)
				end
			end
		end))
	end

	State.SuggestScroll.CanvasSize = UDim2.new(0, 0, 0, #matches * 34)
	State.SuggestFrame.Visible = true
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 19: PAGE SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local PageSystem = {}
local Pages = {}

--[[
    Clears the content area.
--]]
function PageSystem.ClearContent()
	State.ContentScroll.CanvasPosition = Vector2.new(0, 0)
	DropdownSystem.Close()

	for _, child in pairs(State.ContentScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	State.CardOrder = 0
end

--[[
    Switches to a page.
--]]
function PageSystem.SwitchTo(targetPage, pageTitle, pageSubtitle, pageBuilder)
	State.CurrentPage = targetPage
	State.PageTitle.Text = pageTitle
	State.PageSubtitle.Text = pageSubtitle or ""
	PageSystem.ClearContent()

	local ok, err = pcall(pageBuilder)
	if not ok then
		warn("[Page Error]", err)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 20: SEED SELECTION MODAL
-- ═══════════════════════════════════════════════════════════════════════

local SeedModalSystem = {}

--[[
    Shows a seed selection modal.
--]]
function SeedModalSystem.Show(title, selectedTable, updateCallback)
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

		-- Scroll area
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

				Memory.TrackConnection(row.Activated:Connect(function()
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

		Memory.TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local text = searchBox.Text
			if text == "Search seeds..." then
				text = ""
			end
			BuildRows(text)
		end))

		local doneBtn = UI.CreateButton(modalContent, "Done", Theme.Accent, 80, 32, function()
			ModalSystem.Close()
		end)
		doneBtn.Position = UDim2.new(1, -80, 1, -36)
	end, 480, 400)
end

--[[
    Shows a generic selection modal.
--]]
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

			Memory.TrackConnection(btn.Activated:Connect(function()
				onSelect(opt.Value)
				ModalSystem.Close()
			end))
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 35)

		local doneBtn = UI.CreateButton(modalContent, "Done", Theme.Accent, 80, 32, function()
			ModalSystem.Close()
		end)
		doneBtn.Position = UDim2.new(1, -80, 1, -36)
	end, 400, 350)
end

--[[
    Shows the seed placer configuration modal.
--]]
function SeedModalSystem.ShowPlacerConfig()
	local info = PlotSystem.GetDetectionInfo()
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

	ModalSystem.Show("Planting Configuration", function(modalFrame, modalContent)
		local yOffset = 0
		local rowHeight = 34
		local labelHeight = 18
		local gap = 8

		-- Area selection
		UI.CreateLabel(modalContent, "Planting Area", Theme.Accent, 13).Position = UDim2.new(0, 4, 0, yOffset)
		yOffset += labelHeight + 2

		local areaRow = UI.Create("TextButton", {
			Parent = modalContent,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, rowHeight),
			Position = UDim2.new(0, 5, 0, yOffset),
			Font = Enum.Font.Gotham,
			Text = "  " .. (Config.PlantingArea or "All") .. "  >",
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = CONSTANTS.Z_MODAL + 20,
			Active = true,
			AutoButtonColor = false,
		})
		UI.AddCorner(areaRow, 4)
		UI.AddStroke(areaRow, Theme.Border, 1)

		Memory.TrackConnection(areaRow.Activated:Connect(function()
			SeedModalSystem.ShowSelection(
				"Select Planting Area",
				partOptions,
				Config.PlantingArea or "All",
				function(value)
					Config.PlantingArea = value
					SeedPlacer.ClearCache()
					if Config.ShowGridDots then
						GridSystem.Refresh()
					end
					ConfigSystem.AutoSave()
				end
			)
		end))
		yOffset += rowHeight + gap

		-- Pattern selection
		UI.CreateLabel(modalContent, "Planting Pattern", Theme.Accent, 13).Position = UDim2.new(0, 4, 0, yOffset)
		yOffset += labelHeight + 2

		local patternRow = UI.Create("TextButton", {
			Parent = modalContent,
			BackgroundColor3 = Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, rowHeight),
			Position = UDim2.new(0, 5, 0, yOffset),
			Font = Enum.Font.Gotham,
			Text = "  " .. (Config.PlantingPattern or "LeftToRight") .. "  >",
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = CONSTANTS.Z_MODAL + 20,
			Active = true,
			AutoButtonColor = false,
		})
		UI.AddCorner(patternRow, 4)
		UI.AddStroke(patternRow, Theme.Border, 1)

		Memory.TrackConnection(patternRow.Activated:Connect(function()
			SeedModalSystem.ShowSelection(
				"Select Pattern",
				patternOptions,
				Config.PlantingPattern or "LeftToRight",
				function(value)
					Config.PlantingPattern = value
					SeedPlacer.ClearCache()
					if Config.ShowGridDots then
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
-- SECTION 21: PAGE DEFINITIONS
-- ═══════════════════════════════════════════════════════════════════════

--[[
    Home page - Seed Placer, Plot Visualizer, Auto Collect
--]]
function Pages.Home()
	PageSystem.SwitchTo("Home", "Home", "Game Version: ----", function()
		-- Seed Placer Card
		local seedPlacerCard = UI.CreateCard(State.ContentScroll, "Seed Placer", "🏠", Theme.Accent)

		Memory.TrackConnection(seedPlacerCard.Activated:Connect(function()
			DropdownSystem.Toggle(seedPlacerCard, function(dropdownScroll)
				Config.SelectedPlaceSeeds = Config.SelectedPlaceSeeds or {}
				Config.PlaceAmount = Config.PlaceAmount or CONSTANTS.DEFAULT_PLACE_AMOUNT
				Config.PlantingArea = Config.PlantingArea or "All"
				Config.PlantingPattern = Config.PlantingPattern or "LeftToRight"
				Config.PlantSpacing = Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING
				Config.PlantDelay = Config.PlantDelay or CONSTANTS.DEFAULT_PLANT_DELAY
				if Config.EnableSeedPlacer == nil then
					Config.EnableSeedPlacer = false
				end

				UI.CreateLabel(dropdownScroll, "Seed Placer", Theme.Accent, 12)

				local selectedLabel = UI.CreateLabel(dropdownScroll, "Selected: None", Theme.TextMuted, 10)

				local function UpdateSelectedLabel()
					selectedLabel.Text = Utils.FormatSelectedSeeds(Config.SelectedPlaceSeeds, 10)
				end

				UpdateSelectedLabel()

				local selectSeedsBtn = UI.CreateButton(
					dropdownScroll,
					"Select Seeds...",
					Theme.Card,
					100,
					30,
					function()
						SeedModalSystem.Show("Select Seeds", Config.SelectedPlaceSeeds, UpdateSelectedLabel)
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
							Config.SelectedPlaceSeeds[seed.SeedName] = true
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
						table.clear(Config.SelectedPlaceSeeds)
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
				UI.CreateLabel(dropdownScroll, "  Area: " .. (Config.PlantingArea or "All"), Theme.TextSecondary, 11)
				UI.CreateLabel(
					dropdownScroll,
					"  Pattern: " .. (Config.PlantingPattern or "LeftToRight"),
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

				-- Spacing input
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
					Text = tostring(Config.PlantSpacing),
					PlaceholderText = "1",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				UI.AddCorner(spacingBox, 4)
				Memory.TrackConnection(spacingBox.FocusLost:Connect(function()
					local val = tonumber(spacingBox.Text)
					if val and val >= 0.1 then
						Config.PlantSpacing = val
						SeedPlacer.ClearCache()
						if Config.ShowGridDots then
							GridSystem.Refresh()
						end
						ConfigSystem.AutoSave()
					end
				end))

				-- Delay input
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
					Text = tostring(Config.PlantDelay),
					PlaceholderText = "0.05",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				UI.AddCorner(delayBox, 4)
				Memory.TrackConnection(delayBox.FocusLost:Connect(function()
					local val = tonumber(delayBox.Text)
					if val and val >= 0 then
						Config.PlantDelay = val
						ConfigSystem.AutoSave()
					end
				end))

				-- Amount input
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
					Text = tostring(Config.PlaceAmount),
					PlaceholderText = "10",
					TextColor3 = Theme.TextPrimary,
					PlaceholderColor3 = Theme.TextMuted,
					TextSize = 12,
					ClearTextOnFocus = false,
				})
				UI.AddCorner(amountBox, 4)
				Memory.TrackConnection(amountBox.FocusLost:Connect(function()
					local val = tonumber(amountBox.Text)
					if val and val > 0 then
						Config.PlaceAmount = math.floor(val)
						ConfigSystem.AutoSave()
					end
				end))

				UI.CreateToggle(dropdownScroll, "Enable Seed Placer", Config.EnableSeedPlacer, function(state)
					Config.EnableSeedPlacer = state
					ConfigSystem.AutoSave()
				end)
			end)
		end))

		-- Plot Visualizer Card
		local plotVisualizerCard = UI.CreateCard(State.ContentScroll, "Plot Visualizer", "✨", Theme.AccentCyan)

		Memory.TrackConnection(plotVisualizerCard.Activated:Connect(function()
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

				UI.CreateToggle(dropdownScroll, "Show Grid Dots", Config.ShowGridDots, function(state)
					Config.ShowGridDots = state
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
						Config.ShowGridDots = false
						ConfigSystem.AutoSave()
						NotificationSystem.Notify("Plot Visualizer", "All visuals cleared", "Info", 2)
					end
				)
				clearBtn.Size = UDim2.new(1, -8, 0, 32)
			end)
		end))

		-- Auto Collect Fruits Card (placeholder)
		local autoCollectCard = UI.CreateCard(State.ContentScroll, "Auto Collect Fruits", "🍎", Theme.Accent)
		Memory.TrackConnection(autoCollectCard.Activated:Connect(function()
			-- Placeholder for future implementation
		end))
	end)
end

--[[
    Shop page - Auto Buy Seeds
--]]
function Pages.Shop()
	PageSystem.SwitchTo("Shop", "Shop", "ShopFeatures", function()
		local seedShopCard = UI.CreateCard(State.ContentScroll, "Seed Shop", "🌱", Theme.Accent)

		Memory.TrackConnection(seedShopCard.Activated:Connect(function()
			DropdownSystem.Toggle(seedShopCard, function(dropdownScroll)
				UI.CreateLabel(dropdownScroll, "Auto Buy Seeds", Theme.Accent, 12)

				local selectedLabel = UI.CreateLabel(
					dropdownScroll,
					"Selected: " .. Utils.FormatSelectedSeeds(Config.SelectedSeeds, 10),
					Theme.TextMuted,
					10
				)
				selectedLabel.Name = "SelectedLabel"

				local function UpdateSelectedLabel()
					selectedLabel.Text = Utils.FormatSelectedSeeds(Config.SelectedSeeds, 10)
				end

				UpdateSelectedLabel()

				local selectSeedsBtn = UI.CreateButton(
					dropdownScroll,
					"Select Seeds...",
					Theme.Card,
					100,
					30,
					function()
						SeedModalSystem.Show("Select Seeds", Config.SelectedSeeds, UpdateSelectedLabel)
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
								Config.SelectedSeeds[seed.SeedName] = true
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
						table.clear(Config.SelectedSeeds)
						ConfigSystem.AutoSave()
						UpdateSelectedLabel()
					end
				)
				clearAllBtn.Position = UDim2.new(0.5, 3, 0, 0)
				clearAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				UI.CreateToggle(dropdownScroll, "Enable Auto Buy", Config.EnableSeedShop, function(state)
					Config.EnableSeedShop = state
					ConfigSystem.AutoSave()
				end)
			end)
		end))
	end)
end

--[[
    Account page - User Profile
--]]
function Pages.Account()
	PageSystem.SwitchTo("Account", "Account", "User Profile", function()
		local card = UI.CreateCard(State.ContentScroll, "Account Info", "👤", Theme.Accent)
		Memory.TrackConnection(card.Activated:Connect(function()
			DropdownSystem.Toggle(card, function(dropdownScroll)
				UI.CreateLabel(dropdownScroll, "Username: " .. Player.Name, Theme.TextPrimary, 12)
				UI.CreateLabel(dropdownScroll, "User ID: " .. Player.UserId, Theme.TextSecondary, 11)
			end)
		end))
	end)
end

--[[
    Premium page - Placeholder
--]]
function Pages.Premium()
	PageSystem.SwitchTo("Premium", "Premium", "Premium Features", function() end)
end

--[[
    Settings page - Preferences
--]]
function Pages.Settings()
	PageSystem.SwitchTo("Settings", "Settings", "Preferences", function()
		UI.CreateLabel(State.ContentScroll, "UI Settings", Theme.Accent, 14)

		UI.CreateToggle(State.ContentScroll, "Disable Animations", Config.DisableAnimations, function(state)
			Config.DisableAnimations = state
			ConfigSystem.AutoSave()
		end)

		UI.CreateToggle(State.ContentScroll, "Reduce Effects", Config.ReduceEffects, function(state)
			Config.ReduceEffects = state
			ConfigSystem.AutoSave()
		end)

		UI.CreateLabel(State.ContentScroll, " ", Theme.TextSecondary, 8)

		UI.CreateButton(State.ContentScroll, "Save Now", Theme.AccentGreen, 120, 32, function()
			ConfigSystem.Save()
		end)

		UI.CreateButton(State.ContentScroll, "Load Config", Theme.Accent, 120, 32, function()
			ConfigSystem.Load()
		end)

		UI.CreateLabel(State.ContentScroll, " ", Theme.TextSecondary, 8)

		UI.CreateButton(State.ContentScroll, "Reset Config", Theme.AccentRed, 120, 32, function()
			ConfigSystem.Reset()
		end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 22: UI INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════

local UIInit = {}

--[[
    Creates the ScreenGui.
--]]
function UIInit.CreateScreenGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LRX_Hub"
	screenGui.Parent = PlayerGui
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999

	State.ScreenGui = screenGui
	return screenGui
end

--[[
    Creates the main frame.
--]]
function UIInit.CreateMainFrame(screenGui)
	local mainFrame = UI.Create("Frame", {
		Name = "MainFrame",
		Parent = screenGui,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -Config.WindowWidth / 2, 0.5, -Config.WindowHeight / 2),
		Size = UDim2.new(0, Config.WindowWidth, 0, Config.WindowHeight),
		ClipsDescendants = false,
		Active = true,
		ZIndex = CONSTANTS.Z_BASE,
	})
	UI.AddCorner(mainFrame, 8)
	UI.AddStroke(mainFrame, Theme.Border, 2)

	-- Restore saved position/size
	if Config.WindowPosition then
		mainFrame.Position = UDim2.new(
			Config.WindowPosition[1],
			Config.WindowPosition[2],
			Config.WindowPosition[3],
			Config.WindowPosition[4]
		)
	end
	if Config.WindowSize then
		mainFrame.Size =
			UDim2.new(Config.WindowSize[1], Config.WindowSize[2], Config.WindowSize[3], Config.WindowSize[4])
	end

	State.MainFrame = mainFrame
	return mainFrame
end

--[[
    Creates the toggle button.
--]]
function UIInit.CreateToggleButton(screenGui)
	local btn = UI.Create("TextButton", {
		Name = "MainIcon",
		Parent = screenGui,
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(0, 60, 0, 32),
		Font = Enum.Font.GothamBold,
		Text = Config.ToggleButtonText,
		TextColor3 = Theme.AccentYellow,
		TextSize = 13,
		ZIndex = CONSTANTS.Z_BASE,
		Active = true,
		AutoButtonColor = false,
	})
	UI.AddCorner(btn, 6)
	UI.AddStroke(btn, Theme.Border, 1)

	-- Dragging
	Memory.TrackConnection(btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			State.IsDraggingToggle = true
			State.ToggleStartPos = input.Position
			State.ToggleBtnStart = btn.Position
		end
	end))

	Memory.TrackConnection(Services.UserInputService.InputChanged:Connect(function(input)
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

	Memory.TrackConnection(Services.UserInputService.InputEnded:Connect(function(input)
		if State.IsDraggingToggle then
			local delta = input.Position - State.ToggleStartPos
			State.IsDraggingToggle = false
			if math.abs(delta.X) <= 8 and math.abs(delta.Y) <= 8 then
				State.MainFrame.Visible = not State.MainFrame.Visible
				TweenSystem.Tween(btn, {
					BackgroundColor3 = State.MainFrame.Visible and Color3.fromRGB(15, 15, 15)
						or Color3.fromRGB(30, 30, 30),
				}, 0.2)
			end
		end
	end))

	State.MainIcon = btn
	return btn
end

--[[
    Creates the top bar.
--]]
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

	State.PageTitle = pageTitle
	State.PageSubtitle = pageSubtitle

	-- Search bar
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

	State.SearchFrame = searchFrame
	State.SearchBox = searchBox

	-- Suggestions frame
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

	State.SuggestFrame = suggestFrame
	State.SuggestScroll = suggestScroll

	-- Search events
	Memory.TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(SearchSystem.UpdateSuggestions))
	Memory.TrackConnection(searchBox.FocusLost:Connect(function()
		if searchBox.Text == "" then
			searchBox.Text = "Search"
		end
		task.wait(0.2)
		suggestFrame.Visible = false
	end))
	Memory.TrackConnection(searchBox.Focused:Connect(function()
		if searchBox.Text ~= "Search" and searchBox.Text ~= "" then
			SearchSystem.UpdateSuggestions()
		end
	end))

	-- Close button
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

	Memory.TrackConnection(closeBtn.MouseEnter:Connect(function()
		TweenSystem.Tween(closeBtn, { TextColor3 = Theme.AccentRed }, 0.15)
	end))
	Memory.TrackConnection(closeBtn.MouseLeave:Connect(function()
		TweenSystem.Tween(closeBtn, { TextColor3 = Theme.TextSecondary }, 0.15)
	end))

	Memory.TrackConnection(closeBtn.Activated:Connect(function()
		Config.WindowPosition = {
			mainFrame.Position.X.Scale,
			mainFrame.Position.X.Offset,
			mainFrame.Position.Y.Scale,
			mainFrame.Position.Y.Offset,
		}
		Config.WindowSize = {
			mainFrame.Size.X.Scale,
			mainFrame.Size.X.Offset,
			mainFrame.Size.Y.Scale,
			mainFrame.Size.Y.Offset,
		}
		ConfigSystem.Save()
		Memory.FullCleanup()
	end))

	return topBar
end

--[[
    Creates the sidebar.
--]]
function UIInit.CreateSidebar(mainFrame)
	local sidebar = UI.Create("Frame", {
		Name = "Sidebar",
		Parent = mainFrame,
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 2, 0, CONSTANTS.TOPBAR_HEIGHT + 2),
		Size = UDim2.new(0, Config.SidebarWidth, 1, -CONSTANTS.TOPBAR_HEIGHT - 4),
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

	State.SidebarScroll = sidebarScroll

	-- Auto-update canvas size
	Memory.TrackConnection(sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 10)
	end))

	return sidebar, sidebarScroll, sidebarLayout
end

--[[
    Creates the content area.
--]]
function UIInit.CreateContent(mainFrame)
	local contentFrame = UI.Create("Frame", {
		Name = "ContentFrame",
		Parent = mainFrame,
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Position = UDim2.new(0, Config.SidebarWidth, 0, CONSTANTS.TOPBAR_HEIGHT + 2),
		Size = UDim2.new(1, -Config.SidebarWidth, 1, -CONSTANTS.TOPBAR_HEIGHT - 4),
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

	-- Auto-update canvas size
	Memory.TrackConnection(contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 20)
	end))
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 20)

	State.ContentScroll = contentScroll
	return contentFrame, contentScroll
end

--[[
    Creates the resize handle.
--]]
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

	Memory.TrackConnection(resizeBtn.InputBegan:Connect(function(input)
		if State.ModalOpen then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local startSize = mainFrame.Size
			local startPos = input.Position
			local resizeConnection

			resizeConnection = Memory.TrackConnection(Services.RunService.RenderStepped:Connect(function()
				if not resizeConnection then
					return
				end
				local mouse = Services.UserInputService:GetMouseLocation()
				local delta = mouse - Vector2.new(startPos.X, startPos.Y)
				mainFrame.Size = UDim2.new(
					0,
					math.max(Config.MinWindowWidth, startSize.X.Offset + delta.X),
					0,
					math.max(Config.MinWindowHeight, startSize.Y.Offset + delta.Y)
				)
			end))

			Memory.TrackConnection(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if resizeConnection then
						resizeConnection:Disconnect()
					end
					resizeConnection = nil
				end
			end))
		end
	end))

	State.ResizeHandle = resizeHandle
	return resizeHandle
end

--[[
    Sets up sidebar buttons.
--]]
function UIInit.SetupSidebar(sidebarScroll)
	local sidebarItems = {
		{ Name = "Account", Icon = "👤", Color = Theme.Accent, Page = Pages.Account },
		{ Name = "Home", Icon = "🏠", Color = Theme.Accent, Page = Pages.Home },
		{ Name = "Premium", Icon = "💎", Color = Theme.AccentPink, Page = Pages.Premium },
		{ Name = "Shop", Icon = "🏪", Color = Theme.Accent, Page = Pages.Shop },
		{ Name = "Settings", Icon = "⚙️", Color = Theme.AccentCyan, Page = Pages.Settings },
	}

	for itemIndex, item in ipairs(sidebarItems) do
		local sidebarBtn = UI.Create("TextButton", {
			Name = item.Name,
			Parent = sidebarScroll,
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

		Memory.TrackConnection(sidebarBtn.MouseEnter:Connect(function()
			if State.CurrentPage ~= item.Name then
				TweenSystem.Tween(sidebarBtn, { BackgroundColor3 = Theme.CardHover }, 0.15)
			end
		end))
		Memory.TrackConnection(sidebarBtn.MouseLeave:Connect(function()
			if State.CurrentPage ~= item.Name then
				TweenSystem.Tween(sidebarBtn, { BackgroundColor3 = Theme.Sidebar }, 0.15)
			end
		end))

		Memory.TrackConnection(sidebarBtn.Activated:Connect(State.SidebarButtons[item.Name]))
		SearchSystem.Register(item.Name, item.Name, item.Icon, State.SidebarButtons[item.Name])
	end

	sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, #sidebarItems * 39 + 10)
end

--[[
    Sets up window dragging.
--]]
function UIInit.SetupWindowDrag(mainFrame)
	Memory.TrackConnection(mainFrame.InputBegan:Connect(function(input)
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

	Memory.TrackConnection(Services.UserInputService.InputChanged:Connect(function(input)
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
	end))

	Memory.TrackConnection(Services.UserInputService.InputEnded:Connect(function(input)
		if State.IsDraggingWindow then
			State.IsDraggingWindow = false
		end
	end))
end

--[[
    Sets up global input handler for dropdown/suggestion closing.
--]]
function UIInit.SetupGlobalInput()
	Memory.TrackConnection(Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
		local function isInside(gui)
			if not gui or not gui.Parent then
				return false
			end
			local ap = gui.AbsolutePosition
			local as = gui.AbsoluteSize
			return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
		end

		if State.SuggestFrame and State.SuggestFrame.Visible then
			if not isInside(State.SearchFrame) and not isInside(State.SuggestFrame) then
				State.SuggestFrame.Visible = false
			end
		end

		if State.ActiveDropdownFrame and State.ActiveDropdownFrame.Parent then
			if isInside(State.ActiveDropdownFrame) then
				return
			end
			if State.ActiveDropdownCard and isInside(State.ActiveDropdownCard) then
				return
			end
			DropdownSystem.Close()
		end
	end))
end

--[[
    Applies mobile sizing if on a touch device.
--]]
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

		local w = math.min(Config.WindowWidth, viewport.X - CONSTANTS.MOBILE_PADDING_X)
		local h = math.min(Config.WindowHeight, viewport.Y - CONSTANTS.MOBILE_PADDING_Y)

		w = math.max(w, Config.MinWindowWidth)
		h = math.max(h, Config.MinWindowHeight)

		State.MainFrame.Size = UDim2.new(0, w, 0, h)
		State.MainFrame.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)

		print(string.format("[LRX_Hub] Mobile sizing applied: %dx%d", w, h))
	end)

	if not success then
		warn("[LRX_Hub] Mobile sizing failed:", err)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 23: BACKGROUND TASKS
-- ═══════════════════════════════════════════════════════════════════════

local BackgroundTasks = {}

--[[
    Starts the seed placer background loop.
--]]
function BackgroundTasks.StartSeedPlacerLoop()
	table.insert(
		State.Tasks,
		task.spawn(function()
			while State.ScriptRunning do
				task.wait(CONSTANTS.PLANT_CYCLE_INTERVAL)
				if Config.EnableSeedPlacer then
					local ok, err = pcall(function()
						SeedPlacer.RunCycle()
					end)
					if not ok then
						warn("[SeedPlacer Loop Error]", err)
					end
				end
			end
		end)
	)
end

--[[
    Starts the auto-buy background loop.
--]]
function BackgroundTasks.StartAutoBuyLoop()
	table.insert(
		State.Tasks,
		task.spawn(function()
			while State.ScriptRunning do
				task.wait(CONSTANTS.AUTO_BUY_INTERVAL)
				if Config.EnableSeedShop and Networking and SeedData then
					local ok, err = pcall(function()
						local leaderstats = Player:FindFirstChild("leaderstats")
						local sheckles = leaderstats and leaderstats:FindFirstChild("Sheckles")
						if sheckles then
							for _, seed in ipairs(SeedData) do
								if
									Config.SelectedSeeds[seed.SeedName]
									and sheckles.Value >= (seed.PurchasePrice or 0)
								then
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
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 24: INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════

local function Initialize()
	local initSuccess, initError = pcall(function()
		-- Create UI hierarchy
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

		-- Load config
		ConfigSystem.Load()

		-- Restore grid dots if enabled
		if Config.ShowGridDots then
			task.delay(1.5, function()
				local ok, err = pcall(function()
					GridSystem.Refresh()
				end)
				if not ok then
					warn("[Init] Grid dots restore failed:", err)
				end
			end)
		end

		-- Start background tasks
		BackgroundTasks.StartSeedPlacerLoop()
		BackgroundTasks.StartAutoBuyLoop()

		-- Show home page
		Pages.Home()

		-- Mobile sizing
		if Services.UserInputService.TouchEnabled then
			task.delay(CONSTANTS.MOBILE_INIT_DELAY, UIInit.ApplyMobileSizing)
		end
	end)

	if not initSuccess then
		warn("[LRX_Hub] CRITICAL INIT ERROR:", initError)
		pcall(function()
			Pages.Home()
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════════

Initialize()
