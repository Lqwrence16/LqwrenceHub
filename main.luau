-- ═══════════════════════════════════════════════════════════════════════
--  LRX_Hub v3.1.0 - Global Namespace Refactor
--  Architecture: getgenv() namespace, modular, performant, memory-safe
--  Purpose: Development automation tool for personal Roblox game
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 0: GLOBAL NAMESPACE & LOAD PROTECTION
-- ═══════════════════════════════════════════════════════════════════════

local genv = (typeof(getgenv) == "function" and getgenv()) or _G

-- Initialize single global namespace (never pollute with multiple globals)
genv.LRX = genv.LRX
	or {
		Loaded = false,

		Config = {},
		State = {},
		Cache = {},
		UI = {},

		Connections = {},
		Threads = {},
		Objects = {},

		Debug = {},
		Functions = {},
	}

local LRX = genv.LRX

--[[
    Reload Protection & Cleanup
    On duplicate execution, gracefully teardown old instance before rebuilding.
--]]
if LRX.Loaded then
	-- 1. Execute structured cleanup if available
	if LRX.Functions and LRX.Functions.FullCleanup then
		pcall(LRX.Functions.FullCleanup)
	else
		-- Fallback: brute-force teardown
		for _, conn in pairs(LRX.Connections) do
			if typeof(conn) == "RBXScriptConnection" and conn.Connected then
				pcall(function()
					conn:Disconnect()
				end)
			end
		end
		for _, thr in pairs(LRX.Threads) do
			if type(thr) == "thread" then
				pcall(function()
					task.cancel(thr)
				end)
			end
		end
		if LRX.UI and LRX.UI.ScreenGui then
			pcall(function()
				LRX.UI.ScreenGui:Destroy()
			end)
		end
		for _, obj in pairs(LRX.Objects) do
			if typeof(obj) == "Instance" and obj.Parent then
				pcall(function()
					obj:Destroy()
				end)
			end
		end
	end

	-- 2. Purge all persistent tables (except Config, which we keep)
	local savedConfig = LRX.Config
	table.clear(LRX.State)
	table.clear(LRX.Cache)
	table.clear(LRX.UI)
	table.clear(LRX.Connections)
	table.clear(LRX.Threads)
	table.clear(LRX.Objects)
	table.clear(LRX.Debug)
	table.clear(LRX.Functions)
	LRX.Config = savedConfig
end

LRX.Loaded = true

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 1: CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════

local CONSTANTS = {
	CONFIG_FILE = "LRX_Hub_Config.json",
	CONFIG_ATTRIBUTE = "LRX_Hub_Config",

	DEFAULT_WINDOW_WIDTH = 600,
	DEFAULT_WINDOW_HEIGHT = 400,
	MIN_WINDOW_WIDTH = 320,
	MIN_WINDOW_HEIGHT = 240,
	SIDEBAR_WIDTH = 170,
	TOPBAR_HEIGHT = 44,

	DEFAULT_PLACE_AMOUNT = 10,
	DEFAULT_PLANT_SPACING = 1,
	DEFAULT_PLANT_DELAY = 0.05,

	MAX_NOTIFICATIONS = 5,
	NOTIFICATION_HEIGHT = 70,
	NOTIFICATION_WIDTH = 280,
	NOTIFICATION_DURATION = 3,
	MAX_DROPDOWN_HEIGHT = 260,
	DROPDOWN_ANIMATION_SPEED = 0.2,

	GRID_DOT_SIZE = 0.08,
	GRID_DOT_BATCH_SIZE = 500,
	GRID_DOT_BATCH_DELAY = 0.05,
	GRID_DOT_Y_OFFSET = 0.05,

	LASER_SCAN_DURATION = 1.5,
	LASER_SWEEP_COUNT = 6,
	LASER_BEAM_THICKNESS = 0.05,

	PLANT_CYCLE_INTERVAL = 0.2,
	AUTO_BUY_INTERVAL = 0.2,
	AUTO_SAVE_DEBOUNCE = 1,
	YIELD_INTERVAL = 200,

	Z_BASE = 10,
	Z_DROPDOWN = 50,
	Z_NOTIFICATION = 700,
	Z_MODAL_OVERLAY = 500,
	Z_MODAL = 600,

	MOBILE_PADDING_X = 20,
	MOBILE_PADDING_Y = 40,
	MOBILE_INIT_DELAY = 0.5,

	POSITION_PRECISION = 100,
	OCCUPIED_LOOKUP_PRECISION = 2,
	OCCUPANCY_TOLERANCE = 0.5,

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

local PlantRemote = Networking and Networking.Plant and Networking.Plant.PlantSeed

-- Performance: localize frequently used global functions
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
local pairs = pairs
local ipairs = ipairs

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 3: CONFIG (persistent user settings — never overwrite existing)
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
	ShowGridDots = { type = "boolean", default = false },
	ReduceEffects = { type = "boolean", default = false },
	Keybinds = { type = "table", default = { ToggleUI = "F" } },
}

-- Apply defaults without overwriting existing values
for key, schema in pairs(ConfigSchema) do
	if LRX.Config[key] == nil then
		if schema.type == "table" then
			LRX.Config[key] = table_clone(schema.default)
		else
			LRX.Config[key] = schema.default
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 4: STATE (runtime-only, reset on reload)
-- ═══════════════════════════════════════════════════════════════════════

LRX.State.ScriptRunning = true
LRX.State.ActiveNotifs = 0
LRX.State.CurrentPage = "Home"
LRX.State.ModalOpen = false
LRX.State.CardOrder = 0
LRX.State.ActiveDropdownCard = nil
LRX.State.ActiveDropdownFrame = nil
LRX.State.DropdownDebounce = false
LRX.State.ActiveModal = nil
LRX.State.ModalOverlay = nil
LRX.State.IsDraggingWindow = false
LRX.State.IsDraggingToggle = false
LRX.State.DragStartPos = nil
LRX.State.FrameStartPos = nil
LRX.State.ToggleStartPos = nil
LRX.State.ToggleBtnStart = nil
LRX.State.IsResizing = false
LRX.State.AutoSaveDebounce = nil
LRX.State.SidebarButtons = {}
LRX.State.SearchableItems = {}

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 5: CACHE (expensive computed data, invalidated when stale)
-- ═══════════════════════════════════════════════════════════════════════

LRX.Cache.CachedPlot = nil
LRX.Cache.CachedPlotParts = nil
LRX.Cache.CachedPartOptions = nil
LRX.Cache.PlantPositions = nil
LRX.Cache.CurrentPlantIndex = 1
LRX.Cache.LastConfigHash = nil
LRX.Cache.OccupiedLookup = nil
LRX.Cache.PlantsFolder = nil -- cached path to Plants folder
LRX.Cache.FakePlot = nil -- cached path to FakePlot

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

local Theme = Themes[LRX.Config.Theme] or Themes.Dark

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 7: UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.Round(num, precision)
	precision = precision or CONSTANTS.POSITION_PRECISION
	return math_floor(num * precision + 0.5) / precision
end

function Utils.FormatPositionKey(pos, precision)
	precision = precision or CONSTANTS.OCCUPIED_LOOKUP_PRECISION
	local mult = precision * 10
	local x = math_floor(pos.X * mult + 0.5) / mult
	local z = math_floor(pos.Z * mult + 0.5) / mult
	return string_format("%.1f,%.1f", x, z)
end

function Utils.Clamp(value, min, max)
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
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
			return table_clone(schema.default)
		end
		return value
	end
	return schema.default
end

function Utils.FormatSelectedSeeds(selectedTable, maxDisplay)
	maxDisplay = maxDisplay or 10
	local names = {}
	for seedName, selected in pairs(selectedTable) do
		if selected then
			table_insert(names, seedName)
		end
	end
	table_sort(names)
	local count = #names
	if count == 0 then
		return "Selected (0): None"
	end
	local shown = {}
	for i = 1, math_min(count, maxDisplay) do
		table_insert(shown, names[i])
	end
	local text = table.concat(shown, ", ")
	if count > maxDisplay then
		text = text .. "..."
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

function Utils.IsPointInPart(point, part)
	local localPos = part.CFrame:PointToObjectSpace(point)
	local halfSize = part.Size / 2
	return math_abs(localPos.X) <= halfSize.X + 0.1
		and math_abs(localPos.Y) <= halfSize.Y + 0.1
		and math_abs(localPos.Z) <= halfSize.Z + 0.1
end

function Utils.GetWorldBoundsXZ(part)
	local cf = part.CFrame
	local hs = part.Size / 2
	local minX, maxX = math_huge, -math_huge
	local minZ, maxZ = math_huge, -math_huge
	for dx = -1, 1, 2 do
		for dz = -1, 1, 2 do
			local corner = cf * Vector3.new(dx * hs.X, 0, dz * hs.Z)
			minX = math_min(minX, corner.X)
			maxX = math_max(maxX, corner.X)
			minZ = math_min(minZ, corner.Z)
			maxZ = math_max(maxZ, corner.Z)
		end
	end
	return minX, maxX, minZ, maxZ
end

function Utils.GetPlayerPosition()
	local character = Player.Character
	if not character then
		return nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or nil
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 8: MEMORY MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════

local Memory = {}

function Memory.TrackConnection(connection)
	table_insert(LRX.Connections, connection)
	return connection
end

function Memory.DisconnectAll()
	for i = 1, #LRX.Connections do
		local c = LRX.Connections[i]
		if c and typeof(c) == "RBXScriptConnection" and c.Connected then
			pcall(function()
				c:Disconnect()
			end)
		end
		LRX.Connections[i] = nil
	end
end

function Memory.TrackThread(thread)
	table_insert(LRX.Threads, thread)
	return thread
end

function Memory.CancelAllThreads()
	for i = 1, #LRX.Threads do
		local t = LRX.Threads[i]
		if t and type(t) == "thread" then
			pcall(function()
				task_cancel(t)
			end)
		end
		LRX.Threads[i] = nil
	end
end

function Memory.DestroyTableInstances(instanceTable)
	for i = 1, #instanceTable do
		local inst = instanceTable[i]
		if inst then
			pcall(function()
				inst:Destroy()
			end)
		end
		instanceTable[i] = nil
	end
end

function Memory.EnsureWorkspaceFolder(folderName, cacheKey)
	local folder = LRX.Objects[cacheKey]
	if folder and folder.Parent then
		return folder
	end
	folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = Services.Workspace
	LRX.Objects[cacheKey] = folder
	return folder
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 9: TWEEN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local TweenSystem = {}
local TweenInfoCache = {}

function TweenSystem.GetTweenInfo(duration, style, direction)
	style = style or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	duration = duration or LRX.Config.AnimationSpeed
	local key = string_format("%.2f_%s_%s", duration, tostring(style), tostring(direction))
	if not TweenInfoCache[key] then
		TweenInfoCache[key] = TweenInfo.new(duration, style, direction)
	end
	return TweenInfoCache[key]
end

function TweenSystem.Tween(instance, properties, duration, callback)
	if LRX.Config.DisableAnimations then
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
-- SECTION 10: NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local NotificationSystem = {}

function NotificationSystem.Notify(title, message, notifType, duration)
	notifType = notifType or "Info"
	duration = duration or LRX.Config.NotificationDuration
	local accent = CONSTANTS.NOTIF_COLORS[notifType] or CONSTANTS.NOTIF_COLORS.Info

	while LRX.State.ActiveNotifs >= CONSTANTS.MAX_NOTIFICATIONS do
		task_wait(0.1)
	end

	LRX.State.ActiveNotifs += 1
	local notifIndex = LRX.State.ActiveNotifs

	local frame = Instance.new("Frame")
	frame.Name = "Notification_" .. notifIndex
	frame.Parent = LRX.UI.ScreenGui
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

	TweenSystem.Tween(frame, {
		Position = UDim2.new(1, -CONSTANTS.NOTIFICATION_WIDTH - 20, 0, frame.Position.Y.Offset),
	}, 0.3)

	task_delay(duration, function()
		if not frame or not frame.Parent then
			LRX.State.ActiveNotifs = math_max(0, LRX.State.ActiveNotifs - 1)
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
				LRX.State.ActiveNotifs = math_max(0, LRX.State.ActiveNotifs - 1)
			end
		)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 11: LASER VISUALIZATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local LaserSystem = {}

function LaserSystem.Clear()
	Memory.DestroyTableInstances(LRX.Objects.LaserBeams or {})
	LRX.Objects.LaserBeams = {}
end

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

	table_insert(LRX.Objects.LaserBeams, beamPart)

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
			table_insert(parts, child)
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
				table_insert(allCorners, cf * Vector3.new(dx * hs.X, hs.Y, dz * hs.Z))
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
			if not LRX.State.ScriptRunning then
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
			if not LRX.State.ScriptRunning then
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
		if not LRX.State.ScriptRunning then
			return
		end
		local h = sweepHeight
		LaserSystem.CreateBeam(Vector3.new(minX, h, minZ), Vector3.new(maxX, h, maxZ), Color3.fromRGB(50, 205, 50), 0.6)
		LaserSystem.CreateBeam(Vector3.new(minX, h, maxZ), Vector3.new(maxX, h, minZ), Color3.fromRGB(50, 205, 50), 0.6)
	end)

	task_delay(scanDuration * 0.5, function()
		if not LRX.State.ScriptRunning then
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
-- SECTION 12: GRID DOTS VISUALIZATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local GridSystem = {}

function GridSystem.Clear()
	-- Cancel any in-progress refresh so old dots don't leak after clear
	if LRX.State.GridRefreshThread and type(LRX.State.GridRefreshThread) == "thread" then
		local t = LRX.State.GridRefreshThread
		LRX.State.GridRefreshThread = nil
		pcall(function()
			task_cancel(t)
		end)
	end

	Memory.DestroyTableInstances(LRX.Objects.GridDots or {})
	LRX.Objects.GridDots = {}
end

function GridSystem.Refresh()
	GridSystem.Clear()
	if not LRX.Config.ShowGridDots then
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

	-- Spawn ONE tracked thread so it can be cancelled on cleanup / toggle-off
	LRX.State.GridRefreshThread = task_spawn(function()
		for batchStart = 1, total, batchSize do
			-- Abort if script stopped or user toggled off
			if not LRX.State.ScriptRunning or not LRX.Config.ShowGridDots then
				break
			end

			local batchEnd = math_min(batchStart + batchSize - 1, total)
			for i = batchStart, batchEnd do
				if not LRX.State.ScriptRunning or not LRX.Config.ShowGridDots then
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

				table_insert(LRX.Objects.GridDots, dot)
			end

			-- Yield between batches to keep frame rate stable
			if batchEnd < total then
				task_wait(batchDelay)
			end
		end

		-- Only notify if we actually finished while still enabled
		if LRX.Config.ShowGridDots and LRX.State.ScriptRunning then
			NotificationSystem.Notify(
				"Plot Visualizer",
				string_format("Showing %d grid dots (all spots)", #LRX.Objects.GridDots),
				"Success",
				2
			)
		end
	end)

	Memory.TrackThread(LRX.State.GridRefreshThread)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 13: PLOT DETECTION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local PlotSystem = {}

function PlotSystem.FindPlayerPlot()
	if LRX.Cache.CachedPlot and LRX.Cache.CachedPlot.Parent then
		return LRX.Cache.CachedPlot
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
			LRX.Cache.CachedPlot = plot
			LRX.Cache.CachedPlotParts = nil
			LRX.Cache.CachedPartOptions = nil
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
				table_insert(columns, child)
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
			table_insert(candidates, { Plot = plot, Distance = (center - playerPos).Magnitude })
		end
	end

	if #candidates > 0 then
		table_sort(candidates, function(a, b)
			return a.Distance < b.Distance
		end)
		LRX.Cache.CachedPlot = candidates[1].Plot
		LRX.Cache.CachedPlotParts = nil
		LRX.Cache.CachedPartOptions = nil
		return candidates[1].Plot
	end

	warn("[PlotSystem] Could not find plot for player:", Player.Name)
	return nil
end

function PlotSystem.DetectPlotParts(plot)
	if not plot then
		return {}
	end
	if LRX.Cache.CachedPlotParts and LRX.Cache.CachedPlot and LRX.Cache.CachedPlot == plot then
		return LRX.Cache.CachedPlotParts
	end

	local visual = plot:FindFirstChild("Visual")
	if not visual then
		return {}
	end

	local parts = {}
	for _, child in ipairs(visual:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^PlantAreaColumn") then
			table_insert(parts, child)
		end
	end

	LRX.Cache.CachedPlotParts = parts
	return parts
end

function PlotSystem.BuildPartOptions(parts)
	if LRX.Cache.CachedPartOptions then
		return LRX.Cache.CachedPartOptions
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
		table_insert(options, { Label = displayName, Value = value, Part = part })
	end

	LRX.Cache.CachedPartOptions = options
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
	LRX.Cache.CachedPlot = nil
	LRX.Cache.CachedPlotParts = nil
	LRX.Cache.CachedPartOptions = nil
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
		table_insert(names, opt.Label)
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
-- SECTION 14: SEED PLACER SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local SeedPlacer = {}

local function GetConfigHash()
	return string_format(
		"%s|%s|%.2f",
		LRX.Config.PlantingArea or "All",
		LRX.Config.PlantingPattern or "LeftToRight",
		LRX.Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING
	)
end

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
		local halfSize = part.Size / 2
		local cf = part.CFrame
		local plantY = part.Position.Y
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
					task_wait()
				end

				local worldPos = cf * Vector3.new(localX, 0, localZ)
				local finalPos = Vector3.new(Utils.Round(worldPos.X), plantY, Utils.Round(worldPos.Z))
				local key = Utils.FormatPositionKey(finalPos)
				if not seenKeys[key] then
					seenKeys[key] = true
					table_insert(positions, { Pos = finalPos, Part = part })
				end
				localZ += spacing
			end
			localX += spacing
		end
	end

	return positions
end

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
			table_insert(result, positions[left])
			left += 1
			if left <= right then
				table_insert(result, positions[right])
				right -= 1
			end
		end
		return result
	elseif pattern == "CenterToOutside" then
		local result = table_create(count)
		local mid = math_ceil(count / 2)
		table_insert(result, positions[mid])
		local offset = 1
		while true do
			local added = false
			if mid - offset >= 1 then
				table_insert(result, positions[mid - offset])
				added = true
			end
			if mid + offset <= count then
				table_insert(result, positions[mid + offset])
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
		local step = math_max(0.1, LRX.Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING)
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
			table_insert(cellMap[r][c], posData)
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
				table_insert(result, posData)
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
								table_insert(result, posData)
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

local function BuildOccupiedLookup()
	local occupied = {}

	-- Cache FakePlot path once
	if not LRX.Cache.FakePlot or not LRX.Cache.FakePlot.Parent then
		local controllers = Player:FindFirstChild("PlayerScripts")
		local seedInspect = controllers and controllers:FindFirstChild("SeedInspectController")
		LRX.Cache.FakePlot = seedInspect and seedInspect:FindFirstChild("FakePlot")
	end

	local plantsFolder = LRX.Cache.FakePlot and LRX.Cache.FakePlot:FindFirstChild("Plants")
	if not plantsFolder then
		local plot = PlotSystem.FindPlayerPlot()
		plantsFolder = plot and plot:FindFirstChild("Plants")
	end

	if not plantsFolder then
		return occupied
	end

	LRX.Cache.PlantsFolder = plantsFolder

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

function SeedPlacer.GetPlantPositions()
	local currentHash = GetConfigHash()
	if LRX.Cache.PlantPositions and LRX.Cache.LastConfigHash == currentHash then
		return LRX.Cache.PlantPositions
	end

	local plot = PlotSystem.FindPlayerPlot()
	if not plot then
		return nil
	end

	local allParts = PlotSystem.DetectPlotParts(plot)
	local targetParts = {}

	if LRX.Config.PlantingArea == "All" or not LRX.Config.PlantingArea or LRX.Config.PlantingArea == "" then
		for _, part in ipairs(allParts) do
			table_insert(targetParts, part)
		end
	else
		local selectedPart = PlotSystem.FindPartByValue(allParts, LRX.Config.PlantingArea)
		if selectedPart then
			table_insert(targetParts, selectedPart)
		else
			for _, part in ipairs(allParts) do
				table_insert(targetParts, part)
			end
		end
	end

	if #targetParts == 0 then
		warn("[SeedPlacer] No target parts found for area: " .. tostring(LRX.Config.PlantingArea))
		return nil
	end

	local positions = GeneratePlantPositions(targetParts, LRX.Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING)
	positions = ApplyPattern(positions, LRX.Config.PlantingPattern or "LeftToRight")

	LRX.Cache.PlantPositions = positions
	LRX.Cache.LastConfigHash = currentHash
	return positions
end

function SeedPlacer.ClearCache()
	LRX.Cache.PlantPositions = nil
	LRX.Cache.CurrentPlantIndex = 1
	LRX.Cache.LastConfigHash = nil
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
	for seedName, enabled in pairs(LRX.Config.SelectedPlaceSeeds or {}) do
		if enabled then
			table_insert(enabledSeeds, seedName)
		end
	end
	if #enabledSeeds == 0 then
		return
	end

	local occupiedLookup = BuildOccupiedLookup()
	local totalSpots = #allSpots
	local maxPlantAmount = LRX.Config.PlaceAmount or CONSTANTS.DEFAULT_PLACE_AMOUNT
	local plantedCount = 0
	local seedIndex = 1
	local checkedCount = 0
	local delay = math_max(0, LRX.Config.PlantDelay or CONSTANTS.DEFAULT_PLANT_DELAY)
	local idx = LRX.Cache.CurrentPlantIndex or 1

	while plantedCount < maxPlantAmount and checkedCount < totalSpots do
		if not LRX.Config.EnableSeedPlacer then
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

	LRX.Cache.CurrentPlantIndex = idx

	if plantedCount > 0 then
		print(string_format("[SeedPlacer] Planted %d seeds this cycle.", plantedCount))
	end
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
	return FilterSerializable(LRX.Config)
end

function ConfigSystem.ApplyLoadedData(data)
	if typeof(data) ~= "table" then
		return false
	end
	for key, value in pairs(data) do
		if typeof(key) == "string" and ConfigSchema[key] then
			LRX.Config[key] = Utils.ValidateConfigValue(key, value)
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
			if LRX.Config.Theme and Themes[LRX.Config.Theme] then
				Theme = Themes[LRX.Config.Theme]
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
			LRX.Config[key] = table_clone(schema.default)
		else
			LRX.Config[key] = schema.default
		end
	end

	Theme = Themes.Dark
	SeedPlacer.ClearCache()
	PlotSystem.ClearCache()
	GridSystem.Refresh()
	NotificationSystem.Notify("Config", "Reset to defaults", "Warning", 3)
end

function ConfigSystem.AutoSave()
	if LRX.State.AutoSaveDebounce then
		pcall(function()
			task_cancel(LRX.State.AutoSaveDebounce)
		end)
	end
	LRX.State.AutoSaveDebounce = task_delay(CONSTANTS.AUTO_SAVE_DEBOUNCE, function()
		ConfigSystem.Save(true)
		LRX.State.AutoSaveDebounce = nil
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 16: UI COMPONENT FACTORY
-- ═══════════════════════════════════════════════════════════════════════

local UI = {}

function UI.Create(className, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties or {}) do
		instance[property] = value
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

function UI.CreateCard(parent, title, icon, iconColor)
	local card = UI.Create("TextButton", {
		Name = title,
		Parent = parent,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = LRX.State.CardOrder * 2,
		Font = Enum.Font.Gotham,
		Text = "",
		ZIndex = CONSTANTS.Z_DROPDOWN,
		Active = true,
		AutoButtonColor = false,
	})
	LRX.State.CardOrder += 1
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
-- SECTION 17: DROPDOWN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local DropdownSystem = {}

function DropdownSystem.Close()
	if not LRX.State.ActiveDropdownFrame then
		return
	end

	if LRX.State.ActiveDropdownCard then
		local arrow = LRX.State.ActiveDropdownCard:FindFirstChild("Arrow")
		if arrow then
			arrow.Text = ">"
		end
		TweenSystem.Tween(LRX.State.ActiveDropdownCard, { BackgroundColor3 = Theme.Card }, 0.15)
		LRX.State.ActiveDropdownCard = nil
	end

	local frame = LRX.State.ActiveDropdownFrame
	LRX.State.ActiveDropdownFrame = nil

	TweenSystem.Tween(frame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15, function()
		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

function DropdownSystem.Toggle(card, buildFunc)
	if LRX.State.DropdownDebounce then
		return
	end
	if LRX.State.ActiveDropdownCard == card then
		DropdownSystem.Close()
		return
	end

	LRX.State.DropdownDebounce = true
	DropdownSystem.Close()

	LRX.State.ActiveDropdownCard = card
	TweenSystem.Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)

	local arrow = card:FindFirstChild("Arrow")
	if arrow then
		arrow.Text = "v"
	end

	local frame = UI.Create("Frame", {
		Name = "Dropdown",
		Parent = LRX.UI.ContentScroll,
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
	LRX.State.ActiveDropdownFrame = frame

	TweenSystem.Tween(frame, { Size = UDim2.new(1, 0, 0, maxHeight) }, CONSTANTS.DROPDOWN_ANIMATION_SPEED)

	task_delay(0.25, function()
		LRX.State.DropdownDebounce = false
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 18: MODAL SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local ModalSystem = {}

function ModalSystem.SetState(isOpen)
	LRX.State.ModalOpen = isOpen
	LRX.UI.MainFrame.Active = not isOpen
	LRX.UI.SidebarScroll.ScrollingEnabled = not isOpen
	LRX.UI.ContentScroll.ScrollingEnabled = not isOpen
end

function ModalSystem.Close()
	if LRX.State.ActiveModal then
		TweenSystem.Tween(
			LRX.State.ActiveModal,
			{
				Position = UDim2.new(
					0.5,
					-LRX.State.ActiveModal.Size.X.Offset / 2,
					0.5,
					-LRX.State.ActiveModal.Size.Y.Offset / 2 + 20
				),
			},
			0.2,
			function()
				if LRX.State.ActiveModal then
					LRX.State.ActiveModal:Destroy()
					LRX.State.ActiveModal = nil
				end
			end
		)
	end

	if LRX.State.ModalOverlay then
		TweenSystem.Tween(LRX.State.ModalOverlay, { BackgroundTransparency = 1 }, 0.2, function()
			LRX.State.ModalOverlay.Visible = false
			ModalSystem.SetState(false)
		end)
	end
end

function ModalSystem.Show(title, buildFunc, width, height)
	width = width or 520
	height = height or 420

	if not LRX.State.ModalOverlay then
		LRX.State.ModalOverlay = UI.Create("Frame", {
			Name = "ModalOverlay",
			Parent = LRX.UI.ScreenGui,
			BackgroundColor3 = Theme.Overlay,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = CONSTANTS.Z_MODAL_OVERLAY,
			Active = false,
			Visible = false,
		})

		local blocker = UI.Create("TextButton", {
			Parent = LRX.State.ModalOverlay,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = CONSTANTS.Z_MODAL_OVERLAY,
			Active = true,
			AutoButtonColor = false,
		})
	end

	ModalSystem.SetState(true)
	LRX.State.ModalOverlay.Visible = true
	TweenSystem.Tween(LRX.State.ModalOverlay, { BackgroundTransparency = LRX.Config.ModalDarkening }, 0.2)

	if LRX.State.ActiveModal then
		LRX.State.ActiveModal:Destroy()
	end

	local modalFrame = UI.Create("Frame", {
		Name = "ModalFrame",
		Parent = LRX.State.ModalOverlay,
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

	LRX.State.ActiveModal = modalFrame
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
	table_insert(LRX.State.SearchableItems, {
		Name = itemName,
		Page = targetPage,
		Icon = itemIcon,
		Action = itemAction,
	})
end

function SearchSystem.Query(searchQuery)
	local results = {}
	local lowerQuery = searchQuery:lower()
	for _, item in ipairs(LRX.State.SearchableItems) do
		if item.Name:lower():find(lowerQuery, 1, true) then
			table_insert(results, item)
		end
	end
	return results
end

function SearchSystem.UpdateSuggestions()
	for _, child in pairs(LRX.UI.SuggestScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local searchText = LRX.UI.SearchBox.Text:lower()
	if searchText == "" or searchText == "search" then
		LRX.UI.SuggestFrame.Visible = false
		return
	end

	local matches = SearchSystem.Query(searchText)
	if #matches == 0 then
		LRX.UI.SuggestFrame.Visible = false
		return
	end

	local searchAbsPos = LRX.UI.SearchFrame.AbsolutePosition
	local searchAbsSize = LRX.UI.SearchFrame.AbsoluteSize
	LRX.UI.SuggestFrame.Position = UDim2.new(0, searchAbsPos.X, 0, searchAbsPos.Y + searchAbsSize.Y + 4)
	LRX.UI.SuggestFrame.Size = UDim2.new(0, searchAbsSize.X, 0, math_min(#matches * 34 + 10, 220))

	for _, item in ipairs(matches) do
		local btn = UI.Create("TextButton", {
			Parent = LRX.UI.SuggestScroll,
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
			LRX.UI.SuggestFrame.Visible = false
			LRX.UI.SearchBox.Text = "Search"
			if item.Action then
				local ok, err = pcall(item.Action)
				if not ok then
					warn("[Search Action Error]", err)
				end
			end
		end))
	end

	LRX.UI.SuggestScroll.CanvasSize = UDim2.new(0, 0, 0, #matches * 34)
	LRX.UI.SuggestFrame.Visible = true
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 20: PAGE SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local PageSystem = {}
local Pages = {}

function PageSystem.ClearContent()
	LRX.UI.ContentScroll.CanvasPosition = Vector2.new(0, 0)
	DropdownSystem.Close()

	for _, child in pairs(LRX.UI.ContentScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	LRX.State.CardOrder = 0
end

function PageSystem.SwitchTo(targetPage, pageTitle, pageSubtitle, pageBuilder)
	LRX.State.CurrentPage = targetPage
	LRX.UI.PageTitle.Text = pageTitle
	LRX.UI.PageSubtitle.Text = pageSubtitle or ""
	PageSystem.ClearContent()

	local ok, err = pcall(pageBuilder)
	if not ok then
		warn("[Page Error]", err)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 21: SEED SELECTION MODAL
-- ═══════════════════════════════════════════════════════════════════════

local SeedModalSystem = {}

function SeedModalSystem.Show(title, selectedTable, updateCallback)
	local seedItems = {}
	if SeedData then
		for _, seed in ipairs(SeedData) do
			if seed.SeedName then
				table_insert(seedItems, {
					Name = seed.SeedName,
					Price = seed.PurchasePrice,
					Rarity = seed.Rarity or "Common",
				})
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

function SeedModalSystem.ShowPlacerConfig()
	local info = PlotSystem.GetDetectionInfo()
	local partOptions = { { Label = "All (every detected column)", Value = "All" } }
	for _, opt in ipairs(info.PartOptions or {}) do
		table_insert(partOptions, { Label = opt.Label, Value = opt.Value })
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
			Text = "  " .. (LRX.Config.PlantingArea or "All") .. "  >",
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
				LRX.Config.PlantingArea or "All",
				function(value)
					LRX.Config.PlantingArea = value
					SeedPlacer.ClearCache()
					if LRX.Config.ShowGridDots then
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
			Text = "  " .. (LRX.Config.PlantingPattern or "LeftToRight") .. "  >",
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
				LRX.Config.PlantingPattern or "LeftToRight",
				function(value)
					LRX.Config.PlantingPattern = value
					SeedPlacer.ClearCache()
					if LRX.Config.ShowGridDots then
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

function Pages.Home()
	PageSystem.SwitchTo("Home", "Home", "Game Version: ----", function()
		local seedPlacerCard = UI.CreateCard(LRX.UI.ContentScroll, "Seed Placer", "🏠", Theme.Accent)
		Memory.TrackConnection(seedPlacerCard.Activated:Connect(function()
			DropdownSystem.Toggle(seedPlacerCard, function(dropdownScroll)
				LRX.Config.SelectedPlaceSeeds = LRX.Config.SelectedPlaceSeeds or {}
				LRX.Config.PlaceAmount = LRX.Config.PlaceAmount or CONSTANTS.DEFAULT_PLACE_AMOUNT
				LRX.Config.PlantingArea = LRX.Config.PlantingArea or "All"
				LRX.Config.PlantingPattern = LRX.Config.PlantingPattern or "LeftToRight"
				LRX.Config.PlantSpacing = LRX.Config.PlantSpacing or CONSTANTS.DEFAULT_PLANT_SPACING
				LRX.Config.PlantDelay = LRX.Config.PlantDelay or CONSTANTS.DEFAULT_PLANT_DELAY
				if LRX.Config.EnableSeedPlacer == nil then
					LRX.Config.EnableSeedPlacer = false
				end

				UI.CreateLabel(dropdownScroll, "Seed Placer", Theme.Accent, 12)
				local selectedLabel = UI.CreateLabel(dropdownScroll, "Selected: None", Theme.TextMuted, 10)
				local function UpdateSelectedLabel()
					selectedLabel.Text = Utils.FormatSelectedSeeds(LRX.Config.SelectedPlaceSeeds, 10)
				end
				UpdateSelectedLabel()

				local selectSeedsBtn = UI.CreateButton(
					dropdownScroll,
					"Select Seeds...",
					Theme.Card,
					100,
					30,
					function()
						SeedModalSystem.Show("Select Seeds", LRX.Config.SelectedPlaceSeeds, UpdateSelectedLabel)
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
							LRX.Config.SelectedPlaceSeeds[seed.SeedName] = true
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
						table_clear(LRX.Config.SelectedPlaceSeeds)
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
					"  Area: " .. (LRX.Config.PlantingArea or "All"),
					Theme.TextSecondary,
					11
				)
				UI.CreateLabel(
					dropdownScroll,
					"  Pattern: " .. (LRX.Config.PlantingPattern or "LeftToRight"),
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
					Text = tostring(LRX.Config.PlantSpacing),
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
						LRX.Config.PlantSpacing = val
						SeedPlacer.ClearCache()
						if LRX.Config.ShowGridDots then
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
					Text = tostring(LRX.Config.PlantDelay),
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
						LRX.Config.PlantDelay = val
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
					Text = tostring(LRX.Config.PlaceAmount),
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
						LRX.Config.PlaceAmount = math_floor(val)
						ConfigSystem.AutoSave()
					end
				end))

				UI.CreateToggle(dropdownScroll, "Enable Seed Placer", LRX.Config.EnableSeedPlacer, function(state)
					LRX.Config.EnableSeedPlacer = state
					ConfigSystem.AutoSave()
				end)
			end)
		end))

		local plotVisualizerCard = UI.CreateCard(LRX.UI.ContentScroll, "Plot Visualizer", "✨", Theme.AccentCyan)
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

				UI.CreateToggle(dropdownScroll, "Show Grid Dots", LRX.Config.ShowGridDots, function(state)
					LRX.Config.ShowGridDots = state
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
						LRX.Config.ShowGridDots = false
						ConfigSystem.AutoSave()
						NotificationSystem.Notify("Plot Visualizer", "All visuals cleared", "Info", 2)
					end
				)
				clearBtn.Size = UDim2.new(1, -8, 0, 32)
			end)
		end))

		local autoCollectCard = UI.CreateCard(LRX.UI.ContentScroll, "Auto Collect Fruits", "🍎", Theme.Accent)
		Memory.TrackConnection(autoCollectCard.Activated:Connect(function()
			-- Placeholder for future implementation
		end))
	end)
end

function Pages.Shop()
	PageSystem.SwitchTo("Shop", "Shop", "ShopFeatures", function()
		local seedShopCard = UI.CreateCard(LRX.UI.ContentScroll, "Seed Shop", "🌱", Theme.Accent)
		Memory.TrackConnection(seedShopCard.Activated:Connect(function()
			DropdownSystem.Toggle(seedShopCard, function(dropdownScroll)
				UI.CreateLabel(dropdownScroll, "Auto Buy Seeds", Theme.Accent, 12)

				local selectedLabel = UI.CreateLabel(
					dropdownScroll,
					"Selected: " .. Utils.FormatSelectedSeeds(LRX.Config.SelectedSeeds, 10),
					Theme.TextMuted,
					10
				)
				selectedLabel.Name = "SelectedLabel"

				local function UpdateSelectedLabel()
					selectedLabel.Text = Utils.FormatSelectedSeeds(LRX.Config.SelectedSeeds, 10)
				end
				UpdateSelectedLabel()

				local selectSeedsBtn = UI.CreateButton(
					dropdownScroll,
					"Select Seeds...",
					Theme.Card,
					100,
					30,
					function()
						SeedModalSystem.Show("Select Seeds", LRX.Config.SelectedSeeds, UpdateSelectedLabel)
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
								LRX.Config.SelectedSeeds[seed.SeedName] = true
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
						table_clear(LRX.Config.SelectedSeeds)
						ConfigSystem.AutoSave()
						UpdateSelectedLabel()
					end
				)
				clearAllBtn.Position = UDim2.new(0.5, 3, 0, 0)
				clearAllBtn.Size = UDim2.new(0.5, -3, 1, 0)

				UI.CreateToggle(dropdownScroll, "Enable Auto Buy", LRX.Config.EnableSeedShop, function(state)
					LRX.Config.EnableSeedShop = state
					ConfigSystem.AutoSave()
				end)
			end)
		end))
	end)
end

function Pages.Account()
	PageSystem.SwitchTo("Account", "Account", "User Profile", function()
		local card = UI.CreateCard(LRX.UI.ContentScroll, "Account Info", "👤", Theme.Accent)
		Memory.TrackConnection(card.Activated:Connect(function()
			DropdownSystem.Toggle(card, function(dropdownScroll)
				UI.CreateLabel(dropdownScroll, "Username: " .. Player.Name, Theme.TextPrimary, 12)
				UI.CreateLabel(dropdownScroll, "User ID: " .. Player.UserId, Theme.TextSecondary, 11)
			end)
		end))
	end)
end

function Pages.Premium()
	PageSystem.SwitchTo("Premium", "Premium", "Premium Features", function() end)
end

function Pages.Settings()
	PageSystem.SwitchTo("Settings", "Settings", "Preferences", function()
		UI.CreateLabel(LRX.UI.ContentScroll, "UI Settings", Theme.Accent, 14)

		UI.CreateToggle(LRX.UI.ContentScroll, "Disable Animations", LRX.Config.DisableAnimations, function(state)
			LRX.Config.DisableAnimations = state
			ConfigSystem.AutoSave()
		end)

		UI.CreateToggle(LRX.UI.ContentScroll, "Reduce Effects", LRX.Config.ReduceEffects, function(state)
			LRX.Config.ReduceEffects = state
			ConfigSystem.AutoSave()
		end)

		UI.CreateLabel(LRX.UI.ContentScroll, " ", Theme.TextSecondary, 8)

		UI.CreateButton(LRX.UI.ContentScroll, "Save Now", Theme.AccentGreen, 120, 32, function()
			ConfigSystem.Save()
		end)

		UI.CreateButton(LRX.UI.ContentScroll, "Load Config", Theme.Accent, 120, 32, function()
			ConfigSystem.Load()
		end)

		UI.CreateLabel(LRX.UI.ContentScroll, " ", Theme.TextSecondary, 8)

		UI.CreateButton(LRX.UI.ContentScroll, "Reset Config", Theme.AccentRed, 120, 32, function()
			ConfigSystem.Reset()
		end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SECTION 23: UI INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════

local UIInit = {}

function UIInit.CreateScreenGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LRX_Hub"
	screenGui.Parent = PlayerGui
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999
	LRX.UI.ScreenGui = screenGui
	return screenGui
end

function UIInit.CreateMainFrame(screenGui)
	local mainFrame = UI.Create("Frame", {
		Name = "MainFrame",
		Parent = screenGui,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -LRX.Config.WindowWidth / 2, 0.5, -LRX.Config.WindowHeight / 2),
		Size = UDim2.new(0, LRX.Config.WindowWidth, 0, LRX.Config.WindowHeight),
		ClipsDescendants = false,
		Active = true,
		ZIndex = CONSTANTS.Z_BASE,
	})
	UI.AddCorner(mainFrame, 8)
	UI.AddStroke(mainFrame, Theme.Border, 2)

	if LRX.Config.WindowPosition then
		mainFrame.Position = UDim2.new(
			LRX.Config.WindowPosition[1],
			LRX.Config.WindowPosition[2],
			LRX.Config.WindowPosition[3],
			LRX.Config.WindowPosition[4]
		)
	end
	if LRX.Config.WindowSize then
		mainFrame.Size = UDim2.new(
			LRX.Config.WindowSize[1],
			LRX.Config.WindowSize[2],
			LRX.Config.WindowSize[3],
			LRX.Config.WindowSize[4]
		)
	end

	LRX.UI.MainFrame = mainFrame
	return mainFrame
end

function UIInit.CreateToggleButton(screenGui)
	local btn = UI.Create("TextButton", {
		Name = "MainIcon",
		Parent = screenGui,
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(0, 60, 0, 32),
		Font = Enum.Font.GothamBold,
		Text = LRX.Config.ToggleButtonText,
		TextColor3 = Theme.AccentYellow,
		TextSize = 13,
		ZIndex = CONSTANTS.Z_BASE,
		Active = true,
		AutoButtonColor = false,
	})
	UI.AddCorner(btn, 6)
	UI.AddStroke(btn, Theme.Border, 1)

	Memory.TrackConnection(btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			LRX.State.IsDraggingToggle = true
			LRX.State.ToggleStartPos = input.Position
			LRX.State.ToggleBtnStart = btn.Position
		end
	end))

	Memory.TrackConnection(Services.UserInputService.InputChanged:Connect(function(input)
		if
			LRX.State.IsDraggingToggle
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - LRX.State.ToggleStartPos
			btn.Position = UDim2.new(
				LRX.State.ToggleBtnStart.X.Scale,
				LRX.State.ToggleBtnStart.X.Offset + delta.X,
				LRX.State.ToggleBtnStart.Y.Scale,
				LRX.State.ToggleBtnStart.Y.Offset + delta.Y
			)
		end
	end))

	Memory.TrackConnection(Services.UserInputService.InputEnded:Connect(function(input)
		if LRX.State.IsDraggingToggle then
			local delta = input.Position - LRX.State.ToggleStartPos
			LRX.State.IsDraggingToggle = false
			if math_abs(delta.X) <= 8 and math_abs(delta.Y) <= 8 then
				LRX.UI.MainFrame.Visible = not LRX.UI.MainFrame.Visible
				TweenSystem.Tween(btn, {
					BackgroundColor3 = LRX.UI.MainFrame.Visible and Color3.fromRGB(15, 15, 15)
						or Color3.fromRGB(30, 30, 30),
				}, 0.2)
			end
		end
	end))

	LRX.UI.MainIcon = btn
	return btn
end

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

	LRX.UI.PageTitle = pageTitle
	LRX.UI.PageSubtitle = pageSubtitle

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

	LRX.UI.SearchFrame = searchFrame
	LRX.UI.SearchBox = searchBox

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

	LRX.UI.SuggestFrame = suggestFrame
	LRX.UI.SuggestScroll = suggestScroll

	Memory.TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(SearchSystem.UpdateSuggestions))
	Memory.TrackConnection(searchBox.FocusLost:Connect(function()
		if searchBox.Text == "" then
			searchBox.Text = "Search"
		end
		task_wait(0.2)
		suggestFrame.Visible = false
	end))
	Memory.TrackConnection(searchBox.Focused:Connect(function()
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

	Memory.TrackConnection(closeBtn.MouseEnter:Connect(function()
		TweenSystem.Tween(closeBtn, { TextColor3 = Theme.AccentRed }, 0.15)
	end))
	Memory.TrackConnection(closeBtn.MouseLeave:Connect(function()
		TweenSystem.Tween(closeBtn, { TextColor3 = Theme.TextSecondary }, 0.15)
	end))

	Memory.TrackConnection(closeBtn.Activated:Connect(function()
		LRX.Config.WindowPosition = {
			mainFrame.Position.X.Scale,
			mainFrame.Position.X.Offset,
			mainFrame.Position.Y.Scale,
			mainFrame.Position.Y.Offset,
		}
		LRX.Config.WindowSize = {
			mainFrame.Size.X.Scale,
			mainFrame.Size.X.Offset,
			mainFrame.Size.Y.Scale,
			mainFrame.Size.Y.Offset,
		}
		ConfigSystem.Save()
		LRX.Functions.FullCleanup()
	end))

	return topBar
end

function UIInit.CreateSidebar(mainFrame)
	local sidebar = UI.Create("Frame", {
		Name = "Sidebar",
		Parent = mainFrame,
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 2, 0, CONSTANTS.TOPBAR_HEIGHT + 2),
		Size = UDim2.new(0, LRX.Config.SidebarWidth, 1, -CONSTANTS.TOPBAR_HEIGHT - 4),
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

	LRX.UI.SidebarScroll = sidebarScroll

	Memory.TrackConnection(sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 10)
	end))

	return sidebar, sidebarScroll, sidebarLayout
end

function UIInit.CreateContent(mainFrame)
	local contentFrame = UI.Create("Frame", {
		Name = "ContentFrame",
		Parent = mainFrame,
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Position = UDim2.new(0, LRX.Config.SidebarWidth, 0, CONSTANTS.TOPBAR_HEIGHT + 2),
		Size = UDim2.new(1, -LRX.Config.SidebarWidth, 1, -CONSTANTS.TOPBAR_HEIGHT - 4),
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

	Memory.TrackConnection(contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 20)
	end))
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 20)

	LRX.UI.ContentScroll = contentScroll
	return contentFrame, contentScroll
end

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
		if LRX.State.ModalOpen then
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
					math_max(LRX.Config.MinWindowWidth, startSize.X.Offset + delta.X),
					0,
					math_max(LRX.Config.MinWindowHeight, startSize.Y.Offset + delta.Y)
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

	LRX.UI.ResizeHandle = resizeHandle
	return resizeHandle
end

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

		LRX.State.SidebarButtons[item.Name] = function()
			LRX.State.CurrentPage = item.Name
			for _, child in pairs(sidebarScroll:GetChildren()) do
				if child:IsA("TextButton") then
					local isSelected = (child.Name == item.Name)
					TweenSystem.Tween(child, { BackgroundColor3 = isSelected and Theme.Card or Theme.Sidebar }, 0.2)
				end
			end
			item.Page()
		end

		Memory.TrackConnection(sidebarBtn.MouseEnter:Connect(function()
			if LRX.State.CurrentPage ~= item.Name then
				TweenSystem.Tween(sidebarBtn, { BackgroundColor3 = Theme.CardHover }, 0.15)
			end
		end))
		Memory.TrackConnection(sidebarBtn.MouseLeave:Connect(function()
			if LRX.State.CurrentPage ~= item.Name then
				TweenSystem.Tween(sidebarBtn, { BackgroundColor3 = Theme.Sidebar }, 0.15)
			end
		end))

		Memory.TrackConnection(sidebarBtn.Activated:Connect(LRX.State.SidebarButtons[item.Name]))
		SearchSystem.Register(item.Name, item.Name, item.Icon, LRX.State.SidebarButtons[item.Name])
	end

	sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, #sidebarItems * 39 + 10)
end

function UIInit.SetupWindowDrag(mainFrame)
	Memory.TrackConnection(mainFrame.InputBegan:Connect(function(input)
		if LRX.State.ModalOpen then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			LRX.State.IsDraggingWindow = true
			LRX.State.DragStartPos = input.Position
			LRX.State.FrameStartPos = mainFrame.Position
		end
	end))

	Memory.TrackConnection(Services.UserInputService.InputChanged:Connect(function(input)
		if
			LRX.State.IsDraggingWindow
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - LRX.State.DragStartPos
			mainFrame.Position = UDim2.new(
				LRX.State.FrameStartPos.X.Scale,
				LRX.State.FrameStartPos.X.Offset + delta.X,
				LRX.State.FrameStartPos.Y.Scale,
				LRX.State.FrameStartPos.Y.Offset + delta.Y
			)
		end
	end))

	Memory.TrackConnection(Services.UserInputService.InputEnded:Connect(function(input)
		if LRX.State.IsDraggingWindow then
			LRX.State.IsDraggingWindow = false
		end
	end))
end

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

		if LRX.UI.SuggestFrame and LRX.UI.SuggestFrame.Visible then
			if not isInside(LRX.UI.SearchFrame) and not isInside(LRX.UI.SuggestFrame) then
				LRX.UI.SuggestFrame.Visible = false
			end
		end

		if LRX.State.ActiveDropdownFrame and LRX.State.ActiveDropdownFrame.Parent then
			if isInside(LRX.State.ActiveDropdownFrame) then
				return
			end
			if LRX.State.ActiveDropdownCard and isInside(LRX.State.ActiveDropdownCard) then
				return
			end
			DropdownSystem.Close()
		end
	end))
end

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
		local w = math_min(LRX.Config.WindowWidth, viewport.X - CONSTANTS.MOBILE_PADDING_X)
		local h = math_min(LRX.Config.WindowHeight, viewport.Y - CONSTANTS.MOBILE_PADDING_Y)
		w = math_max(w, LRX.Config.MinWindowWidth)
		h = math_max(h, LRX.Config.MinWindowHeight)
		LRX.UI.MainFrame.Size = UDim2.new(0, w, 0, h)
		LRX.UI.MainFrame.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
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
	Memory.TrackThread(task_spawn(function()
		while LRX.State.ScriptRunning do
			task_wait(CONSTANTS.PLANT_CYCLE_INTERVAL)
			if LRX.Config.EnableSeedPlacer then
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
	-- Cache leaderstats reference to avoid repeated FindFirstChild
	local cachedSheckles = nil
	local lastCheck = 0

	Memory.TrackThread(task_spawn(function()
		while LRX.State.ScriptRunning do
			task_wait(CONSTANTS.AUTO_BUY_INTERVAL)
			if LRX.Config.EnableSeedShop and Networking and SeedData then
				-- Refresh cached sheckles reference every 5 seconds or if nil
				if not cachedSheckles or tick() - lastCheck > 5 then
					local leaderstats = Player:FindFirstChild("leaderstats")
					cachedSheckles = leaderstats and leaderstats:FindFirstChild("Sheckles")
					lastCheck = tick()
				end

				if cachedSheckles then
					local ok, err = pcall(function()
						for _, seed in ipairs(SeedData) do
							if
								LRX.Config.SelectedSeeds[seed.SeedName]
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

local function FullCleanup()
	LRX.State.ScriptRunning = false
	Memory.DisconnectAll()
	Memory.CancelAllThreads()
	-- Explicitly nuke any dangling grid refresh (safety net)
	if LRX.State.GridRefreshThread and type(LRX.State.GridRefreshThread) == "thread" then
		pcall(function()
			task_cancel(LRX.State.GridRefreshThread)
		end)
		LRX.State.GridRefreshThread = nil
	end

	for name, obj in pairs(LRX.Objects) do
		if typeof(obj) == "Instance" and obj.Parent then
			pcall(function()
				obj:Destroy()
			end)
		end
		LRX.Objects[name] = nil
	end

	if LRX.UI.ScreenGui then
		pcall(function()
			LRX.UI.ScreenGui:Destroy()
		end)
		LRX.UI.ScreenGui = nil
	end

	table_clear(LRX.Cache)
	table_clear(LRX.State)
	table_clear(LRX.UI)
end

LRX.Functions.FullCleanup = FullCleanup

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

		if LRX.Config.ShowGridDots then
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
		pcall(function()
			Pages.Home()
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════════

Initialize()
