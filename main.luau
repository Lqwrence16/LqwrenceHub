-- ═══════════════════════════════════════════════════════════════════════
--  EXOTIC HUB PRO v2.0.7
--  Complete UI Framework with Full Documentation
--  Changes in v2.0.7:
--    • Silent auto-save (no spam notifications)
--    • 2-column grid layout for cards (side-by-side)
--    • Floating dropdowns that resize with window
--    • Detailed comments on every function
-- ═══════════════════════════════════════════════════════════════════════

--══════════════════════════════════════════════════════--
-- SERVICES
--══════════════════════════════════════════════════════--
-- Services are Roblox built-in systems that we need access to.
-- We get them once at the top so we can use them anywhere in the script.

local Players = game:GetService("Players") -- Access player data
local TweenService = game:GetService("TweenService") -- Smooth animations
local UserInputService = game:GetService("UserInputService") -- Detect clicks/touches
local RunService = game:GetService("RunService") -- Runs code every frame
local HttpService = game:GetService("HttpService") -- JSON encode/decode for saving

-- Get the local player (the person running this script)
local player = Players.LocalPlayer
-- PlayerGui is where all UI elements (buttons, text, frames) are stored
local playerGui = player:WaitForChild("PlayerGui")

--══════════════════════════════════════════════════════--
-- CONFIGURATION
--══════════════════════════════════════════════════════--
-- Config stores all user preferences and settings.
-- These values are saved to a file so they persist between sessions.
-- ONLY put simple values here (numbers, strings, booleans, tables of strings)
-- Do NOT put Color3, Instances, or Functions here or saving will break.

local Config = {
	-- Window settings
	WindowWidth = 720, -- How wide the main window is
	WindowHeight = 480, -- How tall the main window is
	MinWindowWidth = 580, -- Minimum width when resizing (enforced)
	MinWindowHeight = 360, -- Minimum height when resizing (enforced)
	SidebarWidth = 170, -- Width of the left sidebar

	-- Appearance
	ToggleButtonText = "_hub", -- Text on the floating toggle button
	Theme = "Dark", -- Which color theme to use
	AnimationSpeed = 0.2, -- How fast animations play (seconds)
	DisableAnimations = false, -- If true, animations are instant
	NotificationDuration = 3, -- How long notifications stay on screen
	ModalDarkening = 0.5, -- How dark the background gets behind modals
	UIScale = 1.0, -- Scale multiplier for UI size

	-- Saved window state
	WindowPosition = nil, -- Where the window was last placed
	WindowSize = nil, -- What size the window was last set to

	-- Feature settings
	SelectedSeeds = {}, -- Which seeds are selected for auto-buy
	EnableSeedShop = false, -- Whether auto-buy is turned on
	ReduceEffects = false, -- Whether to reduce visual effects

	-- Keybinds (stored as string names because JSON can't save Enum.KeyCode)
	Keybinds = { ToggleUI = "F" },
}

--══════════════════════════════════════════════════════--
-- THEMES
--══════════════════════════════════════════════════════--
-- Themes define the color palette for the entire UI.
-- Each theme is a table of Color3 values (RGB colors).
-- To add a new theme, copy the Dark theme and change the colors.

local Themes = {
	Dark = {
		Background = Color3.fromRGB(22, 22, 26), -- Main window background
		Sidebar = Color3.fromRGB(28, 28, 32), -- Left panel background
		Content = Color3.fromRGB(18, 18, 22), -- Right content area background
		Card = Color3.fromRGB(35, 35, 40), -- Card/button background
		CardHover = Color3.fromRGB(45, 45, 50), -- Card color when mouse hovers
		DropdownBg = Color3.fromRGB(32, 32, 38), -- Dropdown menu background
		TextPrimary = Color3.fromRGB(255, 255, 255), -- Main text (white)
		TextSecondary = Color3.fromRGB(160, 160, 160), -- Secondary text (gray)
		TextMuted = Color3.fromRGB(100, 100, 100), -- Dimmed text
		Accent = Color3.fromRGB(147, 112, 219), -- Purple accent
		AccentPink = Color3.fromRGB(255, 105, 180), -- Pink accent
		AccentCyan = Color3.fromRGB(0, 255, 255), -- Cyan accent
		AccentGreen = Color3.fromRGB(50, 205, 50), -- Green accent
		AccentRed = Color3.fromRGB(255, 80, 80), -- Red accent
		AccentYellow = Color3.fromRGB(255, 215, 0), -- Yellow accent
		Border = Color3.fromRGB(50, 50, 55), -- Border/stroke color
		ToggleBg = Color3.fromRGB(60, 60, 65), -- Toggle background (OFF)
		ToggleOn = Color3.fromRGB(147, 112, 219), -- Toggle background (ON)
		ScrollBar = Color3.fromRGB(60, 60, 70), -- Scrollbar color
		Overlay = Color3.fromRGB(0, 0, 0), -- Modal overlay color
	},
}

-- Set the current theme based on Config.Theme
-- This variable is used throughout the script to color UI elements
local Theme = Themes[Config.Theme]

--══════════════════════════════════════════════════════--
-- STATE VARIABLES
--══════════════════════════════════════════════════════--
-- These variables track the current state of the UI.
-- They MUST be defined before any function that uses them.

local ScriptRunning = true -- Controls whether background loops run
local Connections = {} -- Stores event connections for cleanup
local Tasks = {} -- Stores running threads
local ActiveNotifs = 0 -- Count of visible notifications
local CurrentPage = "Home" -- Which page is currently showing
local SidebarButtons = {} -- Table of sidebar click functions
local Pages = {} -- Table of all page functions
local SearchableItems = {} -- Items registered for search

-- Dropdown state tracking
local ActiveDropdownCard = nil -- Which card opened the dropdown
local ActiveDropdownFrame = nil -- The currently open dropdown frame
local DropdownDebounce = false -- Prevents rapid clicking while animating
local DropdownHeartbeat = nil -- Connection that updates dropdown position every frame

-- Modal state tracking
local ModalOverlay = nil -- The dark background behind modals
local ActiveModal = nil -- The currently open modal window
local ModalOpen = false -- Whether a modal is currently open

-- Card ordering counter
local CardOrder = 0 -- Increments for each card created

-- Auto-save debounce handle
local AutoSaveDebounce = nil -- Tracks pending auto-save

-- Grid layout reference (for updating cell size on resize)
local ContentGrid = nil -- The UIGridLayout for cards

-- Dropdown layer (floating above content)

--══════════════════════════════════════════════════════--
-- CONFIG SAVE/LOAD SYSTEM
--══════════════════════════════════════════════════════--
-- This system automatically saves your settings so you don't lose them.
-- It tries 3 different methods to save, in order of preference:
--   1. writefile() - Best method, only works on exploit executors
--   2. SetAttribute() - Fallback, stores on your player object
--   3. StringValue - Last resort, stores in PlayerGui

-- The filename used when saving to disk (executor method)
local CONFIG_FILE = "ExoticHubPro_Config.json"
-- The attribute name used when saving to player (fallback method)
local CONFIG_ATTRIBUTE = "ExoticHubProConfig"

-- These are the ONLY keys that will be saved.
-- We use a whitelist to prevent accidentally saving non-JSON data.
local SERIALIZABLE_KEYS = {
	"WindowWidth",
	"WindowHeight",
	"MinWindowWidth",
	"MinWindowHeight",
	"SidebarWidth",
	"ToggleButtonText",
	"Theme",
	"AnimationSpeed",
	"DisableAnimations",
	"NotificationDuration",
	"ModalDarkening",
	"UIScale",
	"SelectedSeeds",
	"EnableSeedShop",
	"Keybinds",
	"ReduceEffects",
	"WindowPosition",
	"WindowSize",
}

--[[
	BuildSaveData()
	----------------
	Purpose: Creates a clean table containing only the settings we want to save.
	Why: We can't save the entire Config table because it might contain
	     non-JSON values. This function extracts only safe values.
	Returns: table (the data to be saved)
--]]
local function BuildSaveData()
	local data = {}
	-- Loop through each allowed key and copy it from Config
	for _, key in ipairs(SERIALIZABLE_KEYS) do
		if Config[key] ~= nil then
			data[key] = Config[key]
		end
	end
	return data
end

--[[
	ApplyLoadedData(data)
	---------------------
	Purpose: Takes loaded data and applies it back to the Config table.
	Parameters:
		data - table: The data loaded from file/attribute/StringValue
	Returns: boolean (true if successful, false if data was invalid)
--]]
local function ApplyLoadedData(data)
	-- Safety check: make sure data is actually a table
	if typeof(data) ~= "table" then
		return false
	end

	-- Copy each loaded value back into Config
	for _, key in ipairs(SERIALIZABLE_KEYS) do
		if data[key] ~= nil then
			Config[key] = data[key]
		end
	end
	return true
end

--══════════════════════════════════════════════════════--
-- SCREENGUI (MUST BE CREATED BEFORE NOTIFY!)
--══════════════════════════════════════════════════════--
-- ScreenGui is the container that holds ALL UI elements.
-- We create it HERE (before Notify) so Notify can parent notifications to it.
-- This fixes the "ScreenGui is undefined" error in Notify.

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExoticHubPro"
ScreenGui.Parent = playerGui -- Parent to PlayerGui, NOT CoreGui
ScreenGui.ResetOnSpawn = false -- Don't destroy when player respawns
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999 -- Render above most other UIs

--══════════════════════════════════════════════════════--
-- MAIN FRAME
--══════════════════════════════════════════════════════--
-- MainFrame is the big window that contains everything.

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -Config.WindowWidth / 2, 0.5, -Config.WindowHeight / 2)
MainFrame.Size = UDim2.new(0, Config.WindowWidth, 0, Config.WindowHeight)
MainFrame.ClipsDescendants = false -- Allow elements to extend slightly outside
MainFrame.Active = true -- Enable interaction
MainFrame.ZIndex = 10

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Theme.Border
mainStroke.Thickness = 2
mainStroke.Parent = MainFrame

-- Apply saved window position/size if available
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
-- NOTIFICATION SYSTEM
--══════════════════════════════════════════════════════--
-- Notifications are popup messages that appear in the top-right corner.
-- They auto-dismiss after a few seconds.

--[[
	Notify(title, message, notifType, duration)
	-------------------------------------------
	Purpose: Displays a popup notification message.
	Parameters:
		title     - string: The bold title at the top of the notification
		message   - string: The body text of the notification
		notifType - string: The type/color - "Success", "Warning", "Error", or "Info"
		duration  - number: How many seconds to show (default: Config.NotificationDuration)
	Example:
		Notify("Shop", "Auto-buy enabled!", "Success", 3)
--]]
function Notify(title, message, notifType, duration)
	-- Use defaults if not provided
	notifType = notifType or "Info"
	duration = duration or Config.NotificationDuration

	-- Define colors for each notification type
	local colors = {
		Success = Color3.fromRGB(50, 205, 50), -- Green
		Warning = Color3.fromRGB(255, 165, 0), -- Orange
		Error = Color3.fromRGB(255, 80, 80), -- Red
		Info = Color3.fromRGB(100, 150, 255), -- Blue
	}
	local accent = colors[notifType] or colors.Info

	-- Wait if too many notifications are showing (max 5)
	while ActiveNotifs >= 5 do
		task.wait(0.1)
	end
	ActiveNotifs = ActiveNotifs + 1

	-- Create the notification frame
	local frame = Instance.new("Frame")
	frame.Parent = ScreenGui
	frame.BackgroundColor3 = Theme.Card
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(1, 20, 0, 20 + (ActiveNotifs - 1) * 70)
	frame.Size = UDim2.new(0, 280, 0, 60)
	frame.ZIndex = 700
	frame.Active = true

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = frame

	local s = Instance.new("UIStroke")
	s.Color = Theme.Border
	s.Thickness = 1
	s.Parent = frame

	-- Colored accent bar on the left side
	local bar = Instance.new("Frame")
	bar.Parent = frame
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(0, 4, 1, 0)
	bar.ZIndex = 701

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 8)
	bc.Parent = bar

	-- Title label (bold, at the top)
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
	titleLabel.ZIndex = 701

	-- Message label (regular, below title)
	local msgLabel = Instance.new("TextLabel")
	msgLabel.Parent = frame
	msgLabel.BackgroundTransparency = 1
	msgLabel.Position = UDim2.new(0, 14, 0, 26)
	msgLabel.Size = UDim2.new(1, -28, 0, 28)
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.Text = message
	msgLabel.TextColor3 = Theme.TextSecondary
	msgLabel.TextSize = 11
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.ZIndex = 701

	-- Animate in: slide from off-screen right to visible position
	TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -300, 0, frame.Position.Y.Offset),
	}):Play()

	-- Auto-dismiss after duration
	task.delay(duration, function()
		local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, 20, 0, frame.Position.Y.Offset),
		})
		tween.Completed:Connect(function()
			frame:Destroy()
			ActiveNotifs = ActiveNotifs - 1
		end)
		tween:Play()
	end)
end

--══════════════════════════════════════════════════════--
-- SAVE/LOAD FUNCTIONS (now that Notify exists)
--══════════════════════════════════════════════════════--

--[[
	SaveConfig(silent)
	------------------
	Purpose: Saves the current configuration to disk or memory.
	How it works:
		1. Converts Config to JSON string
		2. Tries writefile() first (best, executor-only)
		3. Falls back to SetAttribute()
		4. Falls back to StringValue
	Parameters:
		silent - boolean: If true, does NOT show notification (used for auto-save)
	Returns: boolean (true if saved successfully), string (method used)

	NOTE: writefile, isfile, readfile, delfile are EXECUTOR-ONLY functions.
	They will show as "undefined" in Roblox Studio. This is NORMAL.
	They work fine in Synapse X, KRNL, Fluxus, etc.
--]]
function SaveConfig(silent)
	silent = silent or false

	-- Step 1: Build clean data and convert to JSON
	local saveData = BuildSaveData()
	local encoded
	local ok, err = pcall(function()
		encoded = HttpService:JSONEncode(saveData)
	end)

	-- If JSON encoding failed, show error and exit
	if not ok then
		warn("[Config] JSON Encode failed:", err)
		if not silent then
			Notify("Config", "Failed to encode settings", "Error", 3)
		end
		return false, "encode_failed"
	end

	-- Method 1: Save to file (BEST - requires executor like Synapse X, KRNL, etc.)
	-- writefile() creates a .json file in your executor's workspace folder
	if typeof(writefile) == "function" then
		local fileOk = pcall(function()
			writefile(CONFIG_FILE, encoded)
		end)
		if fileOk then
			if not silent then
				Notify("Config", "Saved to file!", "Success", 2)
			end
			return true, "file"
		end
	end

	-- Method 2: Save as player attribute (FALLBACK)
	-- Attributes are stored on your player object and persist in some executors
	local attrOk = pcall(function()
		player:SetAttribute(CONFIG_ATTRIBUTE, encoded)
	end)
	if attrOk then
		if not silent then
			Notify("Config", "Saved (attribute)", "Info", 2)
		end
		return true, "attribute"
	end

	-- Method 3: Save as StringValue (LAST RESORT)
	-- Creates a StringValue object in PlayerGui that holds the JSON string
	local valOk = pcall(function()
		-- Remove old value if it exists
		local existing = playerGui:FindFirstChild(CONFIG_ATTRIBUTE)
		if existing then
			existing:Destroy()
		end
		-- Create new StringValue
		local val = Instance.new("StringValue")
		val.Name = CONFIG_ATTRIBUTE
		val.Value = encoded
		val.Parent = playerGui
	end)
	if valOk then
		if not silent then
			Notify("Config", "Saved (StringValue)", "Info", 2)
		end
		return true, "stringvalue"
	end

	-- If all methods failed
	if not silent then
		Notify("Config", "Failed to save", "Error", 3)
	end
	return false, "none"
end

--[[
	LoadConfig()
	------------
	Purpose: Loads previously saved configuration.
	How it works:
		1. Tries to read from file first
		2. Falls back to player attribute
		3. Falls back to StringValue
		4. Parses JSON and applies to Config
		5. Updates the Theme variable if a theme was loaded
	Returns: boolean (true if loaded), string (method used)
--]]
function LoadConfig()
	local encoded = nil -- Will hold the raw JSON string
	local method = "none" -- Tracks which method succeeded

	-- Method 1: Load from file
	-- isfile() checks if the file exists, readfile() reads its contents
	if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(CONFIG_FILE) then
		local ok, result = pcall(readfile, CONFIG_FILE)

		if ok and result and #result > 0 then
			encoded = result
			method = "file"
		end
	end

	-- Method 2: Load from player attribute
	if not encoded then
		local ok, result = pcall(function()
			return player:GetAttribute(CONFIG_ATTRIBUTE)
		end)
		if ok and result and typeof(result) == "string" and #result > 0 then
			encoded = result
			method = "attribute"
		end
	end

	-- Method 3: Load from StringValue
	if not encoded then
		local ok, result = pcall(function()
			local val = playerGui:FindFirstChild(CONFIG_ATTRIBUTE)
			return val and val.Value
		end)
		if ok and result and typeof(result) == "string" and #result > 0 then
			encoded = result
			method = "stringvalue"
		end
	end

	-- If we found saved data, parse it
	if encoded then
		-- JSONDecode converts the string back into a Lua table
		local ok, data = pcall(function()
			return HttpService:JSONDecode(encoded)
		end)

		-- If parsing succeeded, apply the data
		if ok and data and ApplyLoadedData(data) then
			-- Update the Theme variable if a valid theme was loaded
			if Config.Theme and Themes[Config.Theme] then
				Theme = Themes[Config.Theme]
			end
			Notify("Config", "Loaded from " .. method, "Success", 2)
			return true, method
		end
	end

	-- No saved data found or failed to load
	return false, "none"
end

--[[
	ResetConfig()
	-------------
	Purpose: Completely resets all settings to default values.
	What it does:
		1. Deletes the saved file (if it exists)
		2. Clears the player attribute
		3. Removes the StringValue
		4. Resets the Config table to factory defaults
		5. Resets the Theme to Dark
	Shows a notification when complete.
--]]
function ResetConfig()
	-- Try to delete the file (delfile is executor-only)
	if typeof(delfile) == "function" then
		pcall(function()
			delfile(CONFIG_FILE)
		end)
	end

	-- Clear the attribute
	pcall(function()
		player:SetAttribute(CONFIG_ATTRIBUTE, nil)
	end)

	-- Remove the StringValue
	pcall(function()
		local val = playerGui:FindFirstChild(CONFIG_ATTRIBUTE)
		if val then
			val:Destroy()
		end
	end)

	-- Reset Config to default values
	Config = {
		WindowWidth = 600,
		WindowHeight = 400,
		MinWindowWidth = 320,
		MinWindowHeight = 240,
		SidebarWidth = 170,
		ToggleButtonText = "_hub",
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
		ReduceEffects = false,
		Keybinds = { ToggleUI = "F" },
	}

	-- Reset theme
	Theme = Themes.Dark
	Notify("Config", "Reset to defaults", "Warning", 3)
end

--[[
	AutoSaveConfig()
	----------------
	Purpose: Automatically saves config after a short delay.
	Why: We don't want to save on EVERY single change (that would be slow).
	     Instead, we wait 1 second after the last change, then save once.
	How: Uses task.delay() to schedule a save. If another change happens
	     before the delay finishes, we cancel the old one and start a new one.
	This calls SaveConfig(true) so it is SILENT (no notification spam).
--]]
function AutoSaveConfig()
	-- If there's already a pending save, cancel it
	if AutoSaveDebounce then
		pcall(function()
			task.cancel(AutoSaveDebounce)
		end)
	end

	-- Schedule a new save in 1 second (silent = true)
	AutoSaveDebounce = task.delay(1, function()
		SaveConfig(true) -- true = silent, no notification
		AutoSaveDebounce = nil
	end)
end

--══════════════════════════════════════════════════════--
-- UTILITY FUNCTIONS
--══════════════════════════════════════════════════════--
-- These are helper functions used everywhere in the script.

--[[
	AddConnection(connection)
	-------------------------
	Purpose: Stores an event connection for later cleanup.
	Why: If we don't disconnect events when the UI closes, they keep running
	     in the background causing memory leaks.
	Parameters:
		connection - RBXScriptConnection: The connection to store
	Returns: RBXScriptConnection (same connection, for chaining)
	Example:
		AddConnection(button.Activated:Connect(function() ... end))
--]]
local function AddConnection(connection)
	table.insert(Connections, connection)
	return connection
end

--[[
	DisconnectAll()
	---------------
	Purpose: Disconnects every stored event connection.
	When to call: When closing the UI to prevent memory leaks.
--]]
local function DisconnectAll()
	for _, connection in ipairs(Connections) do
		if connection and connection.Connected then
			-- pcall prevents errors if the connection is already dead
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	-- Clear the table so we don't try to disconnect them again
	table.clear(Connections)
end

--[[
	Tween(instance, properties, duration, callback)
	------------------------------------------------
	Purpose: Smoothly animates properties of a UI element.
	What it does: Changes properties (like Position, Size, Color) gradually
	              over time instead of instantly.
	Parameters:
		instance   - Instance: The UI element to animate
		properties - table: What to change, e.g. {BackgroundColor3 = Color3.new(1,0,0)}
		duration   - number: How long the animation takes (seconds)
		callback   - function: Optional function to run when animation finishes
	Example:
		Tween(button, {BackgroundColor3 = Theme.CardHover}, 0.2)
--]]
local function Tween(instance, properties, duration, callback)
	-- If animations are disabled, apply changes instantly
	if Config.DisableAnimations then
		for key, value in pairs(properties) do
			instance[key] = value
		end
		if callback then
			callback()
		end
		return
	end

	-- Create the tween using TweenService
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(
			duration or Config.AnimationSpeed, -- How long
			Enum.EasingStyle.Quad, -- Easing style (smooth acceleration)
			Enum.EasingDirection.Out -- Easing direction (fast start, slow end)
		),
		properties
	)

	-- If a callback was provided, connect it to the Completed event
	if callback then
		tween.Completed:Connect(callback)
	end

	-- Start the animation
	tween:Play()
end

--[[
	Create(className, properties)
	-----------------------------
	Purpose: Creates a new Roblox Instance and sets its properties.
	Why: This is a shortcut so we don't have to write 5 lines for every UI element.
	Parameters:
		className  - string: What type of object to create (e.g. "Frame", "TextButton")
		properties - table: Property names and values, e.g. {Size = UDim2.new(...), Parent = ...}
	Returns: Instance (the newly created object)
	Example:
		local frame = Create("Frame", {Size = UDim2.new(0, 100, 0, 50), Parent = ScreenGui})
--]]
local function Create(className, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties or {}) do
		local ok = pcall(function()
			instance[property] = value
		end)
	end
	return instance
end

--[[
	Corner(instance, radius)
	------------------------
	Purpose: Adds rounded corners to a UI element.
	Parameters:
		instance - Instance: The UI element to round
		radius   - number: How round the corners should be (default 6)
--]]
local function Corner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = instance
end

--[[
	Stroke(instance, color, thickness)
	----------------------------------
	Purpose: Adds a colored border (outline) around a UI element.
	Parameters:
		instance  - Instance: The UI element to outline
		color     - Color3: The border color (default: Theme.Border)
		thickness - number: How thick the border is (default: 1)
--]]
local function Stroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Parent = instance
end

--══════════════════════════════════════════════════════--
-- TOGGLE BUTTON (Floating Icon)
--══════════════════════════════════════════════════════--
-- This is the small floating button that shows/hides the main UI.
-- You can also drag it around the screen.

local MainIcon = Create("TextButton", {
	Name = "MainIcon",
	Parent = ScreenGui,
	BackgroundColor3 = Color3.fromRGB(15, 15, 15),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 8, 0, 8), -- Top-left corner by default
	Size = UDim2.new(0, 60, 0, 32),
	Font = Enum.Font.GothamBold,
	Text = Config.ToggleButtonText,
	TextColor3 = Theme.AccentYellow,
	TextSize = 13,
	ZIndex = 10,
	Active = true,
	AutoButtonColor = false, -- We handle colors manually
})
Corner(MainIcon, 6)
Stroke(MainIcon, Theme.Border, 1)

-- Dragging variables for the toggle button
local toggleDragging = false
local toggleStartPos, toggleBtnStart

-- When user presses down on the toggle button
AddConnection(MainIcon.InputBegan:Connect(function(input)
	-- Only respond to mouse left click or touch
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		toggleDragging = true
		toggleStartPos = input.Position -- Remember where press started
		toggleBtnStart = MainIcon.Position -- Remember button's current position
	end
end))

-- While dragging, move the button with the mouse/finger
AddConnection(UserInputService.InputChanged:Connect(function(input)
	if
		toggleDragging
		and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
	then
		-- Calculate how far we've moved from the start position
		local delta = input.Position - toggleStartPos
		-- Update button position by that delta
		MainIcon.Position = UDim2.new(
			toggleBtnStart.X.Scale,
			toggleBtnStart.X.Offset + delta.X,
			toggleBtnStart.Y.Scale,
			toggleBtnStart.Y.Offset + delta.Y
		)
	end
end))

-- When user releases, check if it was a click or a drag
AddConnection(UserInputService.InputEnded:Connect(function(input)
	if toggleDragging then
		local delta = input.Position - toggleStartPos
		toggleDragging = false

		-- If moved less than 8 pixels, treat as a CLICK (toggle UI visibility)
		-- If moved more than 8 pixels, treat as a DRAG (do nothing)
		if math.abs(delta.X) <= 8 and math.abs(delta.Y) <= 8 then
			MainFrame.Visible = not MainFrame.Visible
			Tween(MainIcon, {
				BackgroundColor3 = MainFrame.Visible and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(30, 30, 30),
			}, 0.2)
		end
	end
end))

--══════════════════════════════════════════════════════--
-- TOP BAR
--══════════════════════════════════════════════════════--
-- The top bar contains the title, page title, search bar, and close button.

local TopBar = Create("Frame", {
	Name = "TopBar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Sidebar,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 44), -- Full width, 44 pixels tall
	ZIndex = 10,
})

-- "_hub" logo text on the left
Create("TextLabel", {
	Name = "Title",
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 0, 0),
	Size = UDim2.new(0, 70, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = " _hub",
	TextColor3 = Theme.TextPrimary,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
})

-- Page title (changes when you switch pages)
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

-- Page subtitle (smaller text under the page title)
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

--══════════════════════════════════════════════════════--
-- SEARCH BAR
--══════════════════════════════════════════════════════--
-- The search bar lets users quickly find features by typing.
-- It shows a dropdown of matching results below the search box.

local SearchFrame = Create("Frame", {
	Name = "SearchFrame",
	Parent = TopBar,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -230, 0.5, -14), -- Right side, vertically centered
	Size = UDim2.new(0, 200, 0, 28),
	ZIndex = 12,
})
Corner(SearchFrame, 12) -- Very rounded corners
Stroke(SearchFrame, Theme.Border, 1)

-- Magnifying glass icon inside the search bar
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

-- The actual text input field
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
	ClearTextOnFocus = true, -- Clears "Search" text when clicked
	Active = true,
})

-- Suggestion dropdown (appears below search bar when typing)
local SuggestFrame = Create("Frame", {
	Name = "Suggestions",
	Parent = ScreenGui, -- Parent to ScreenGui so it can float above everything
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

-- Scrollable list inside the suggestion dropdown
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

--══════════════════════════════════════════════════════--
-- CLOSE BUTTON
--══════════════════════════════════════════════════════--
-- The X button in the top-right corner.
-- Completely destroys the UI and cleans up everything.

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

-- Hover effect: turn red when mouse is over the X button
AddConnection(CloseBtn.MouseEnter:Connect(function()
	Tween(CloseBtn, { TextColor3 = Theme.AccentRed }, 0.15)
end))

-- Hover end: return to normal color
AddConnection(CloseBtn.MouseLeave:Connect(function()
	Tween(CloseBtn, { TextColor3 = Theme.TextSecondary }, 0.15)
end))

-- Click: Save position, save config, then destroy everything
AddConnection(CloseBtn.Activated:Connect(function()
	-- Save current window position and size before closing
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

	-- Stop all background loops
	ScriptRunning = false
	-- Disconnect all events to prevent memory leaks
	DisconnectAll()
	-- Destroy the entire UI
	ScreenGui:Destroy()
end))

--══════════════════════════════════════════════════════--
-- SIDEBAR
--══════════════════════════════════════════════════════--
-- The sidebar is the left panel with navigation buttons.

local Sidebar = Create("Frame", {
	Name = "Sidebar",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Sidebar,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 2, 0, 46), -- 2px from left, below top bar
	Size = UDim2.new(0, Config.SidebarWidth, 1, -48),
	ZIndex = 10,
})

-- Scrollable container for sidebar buttons
local SidebarScroll = Create("ScrollingFrame", {
	Name = "SidebarScroll",
	Parent = Sidebar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 4),
	Size = UDim2.new(1, 0, 1, -8),
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Theme.ScrollBar,
	CanvasSize = UDim2.new(0, 0, 0, 0), -- Will be set dynamically
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
-- CONTENT AREA
--══════════════════════════════════════════════════════--
-- The content area is the right side where cards, toggles, and text appear.

local ContentFrame = Create("Frame", {
	Name = "ContentFrame",
	Parent = MainFrame,
	BackgroundColor3 = Theme.Content,
	BorderSizePixel = 0,
	Position = UDim2.new(0, Config.SidebarWidth, 0, 46),
	Size = UDim2.new(1, -Config.SidebarWidth, 1, -48),
	ZIndex = 10,
	ClipsDescendants = true, -- Prevent content from spilling out
})

-- Scrollable list that holds all the cards in a 2-column grid
-- UIGridLayout arranges cards side-by-side (2 columns) automatically
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

-- 2-column grid layout: cards appear side-by-side
-- CellSize updates automatically when window resizes (see UpdateGridCellSize)
ContentGrid = Create("UIGridLayout", {
	Parent = ContentScroll,
	CellPadding = UDim2.new(0, 6, 0, 6), -- 6px gap between cards
	CellSize = UDim2.new(0, 200, 0, 42), -- Default width, updated dynamically
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	FillDirectionMaxCells = 2, -- Max 2 columns per row
})

-- Dropdowns are parented directly to MainFrame for stable positioning during resize.

--══════════════════════════════════════════════════════--
-- COMPONENT BUILDERS
--══════════════════════════════════════════════════════--
-- These functions create reusable UI elements.
-- Instead of writing 20 lines every time we need a button,
-- we just call CreateButton(...) and it handles everything.

--[[
	CreateCard(parent, title, icon, iconColor)
	------------------------------------------
	Purpose: Creates a clickable card button for the content grid.
	What it looks like: A rounded rectangle with an icon, title text, and an arrow.
	Parameters:
		parent    - Instance: Where to put the card (usually ContentScroll)
		title     - string: The text displayed on the card
		icon      - string: An emoji or text icon (e.g. "🌱", "👤")
		iconColor - Color3: The color of the icon (default: Theme.Accent)
	Returns: TextButton (the created card)
	Example:
		local card = CreateCard(ContentScroll, "Seed Shop", "🌱", Theme.Accent)
--]]
local function CreateCard(parent, title, icon, iconColor)
	local card = Create("TextButton", {
		Name = title,
		Parent = parent,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = CardOrder, -- Order in the grid
		Font = Enum.Font.Gotham,
		Text = "", -- We use child labels for text
		ZIndex = 50,
		Active = true,
		AutoButtonColor = false, -- We handle colors manually
	})
	CardOrder = CardOrder + 1 -- Increment for next card
	Corner(card, 6)
	Stroke(card, Theme.Border, 1)

	-- Icon label (left side)
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

	-- Title label (middle)
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

	-- Arrow label (right side, shows ">" when closed)
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

	-- Hover effect: brighten card when mouse enters
	AddConnection(card.MouseEnter:Connect(function()
		Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)
	end))

	-- Hover end: return to normal color when mouse leaves
	AddConnection(card.MouseLeave:Connect(function()
		Tween(card, { BackgroundColor3 = Theme.Card }, 0.15)
	end))

	return card
end

--[[
	CreateToggle(parent, text, defaultState, callback)
	--------------------------------------------------
	Purpose: Creates an ON/OFF toggle switch with a sliding knob.
	Parameters:
		parent       - Instance: Where to put the toggle
		text         - string: Label text next to the toggle
		defaultState - boolean: Whether it starts ON (true) or OFF (false)
		callback     - function(state): Called when toggle is clicked
	Returns: Frame (the container), function() (getter for current state)
	Example:
		CreateToggle(scroll, "Auto Buy", false, function(state)
		    print("Auto buy is now:", state)
		end)
--]]
local function CreateToggle(parent, text, defaultState, callback)
	local container = Create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 32),
		ZIndex = 120,
	})

	-- Label text
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

	-- Toggle background (the track the knob slides on)
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
	Corner(toggleBg, 10) -- Fully rounded ends

	-- The sliding knob (white circle)
	local knob = Create("Frame", {
		Parent = toggleBg,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		-- Position depends on default state (left for OFF, right for ON)
		Position = defaultState and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 121,
	})
	Corner(knob, 8)

	-- Track the current state
	local state = defaultState or false

	-- When the toggle is clicked
	AddConnection(toggleBg.Activated:Connect(function()
		state = not state -- Flip the state

		-- Animate background color change
		Tween(toggleBg, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleBg }, 0.2)
		-- Animate knob sliding left/right
		Tween(knob, { Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2) }, 0.2)

		-- Call the user's callback function if provided
		if callback then
			local ok, err = pcall(callback, state)
			if not ok then
				warn("[Toggle Error]", err)
			end
		end

		-- Auto-save config after toggle changes (silent)
		AutoSaveConfig()
	end))

	return container, function()
		return state
	end
end

--[[
	CreateButton(parent, text, bgColor, width, height, callback)
	------------------------------------------------------------
	Purpose: Creates a clickable button with hover effects.
	Parameters:
		parent   - Instance: Where to put the button
		text     - string: The button text
		bgColor  - Color3: Background color (default: Theme.Card)
		width    - number: Button width in pixels (default: 70)
		height   - number: Button height in pixels (default: 28)
		callback - function: Called when button is clicked
	Returns: TextButton
	Example:
		CreateButton(frame, "Save", Theme.AccentGreen, 100, 32, function()
		    print("Saved!")
		end)
--]]
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

	-- Hover effects
	AddConnection(btn.MouseEnter:Connect(function()
		Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
	end))
	AddConnection(btn.MouseLeave:Connect(function()
		Tween(btn, { BackgroundColor3 = bgColor }, 0.15)
	end))

	-- Click handler
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

--[[
	CreateLabel(parent, text, textColor, fontSize)
	----------------------------------------------
	Purpose: Creates a text label for displaying information.
	Parameters:
		parent    - Instance: Where to put the label
		text      - string: The text to display
		textColor - Color3: Text color (default: Theme.TextSecondary)
		fontSize  - number: Text size (default: 11)
	Returns: TextLabel
	Example:
		CreateLabel(scroll, "Hello World", Theme.TextPrimary, 14)
--]]
local function CreateLabel(parent, text, textColor, fontSize)
	return Create("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, fontSize or 20),
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = textColor or Theme.TextSecondary,
		TextSize = fontSize or 11,
		TextWrapped = true, -- Wrap text if too long
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 120,
	})
end

--══════════════════════════════════════════════════════--
-- GRID CELL SIZE UPDATER
--══════════════════════════════════════════════════════--
-- Updates the 2-column grid cell size when the window is resized.
-- This ensures cards automatically resize to fit the window width.

--[[
	UpdateGridCellSize()
	--------------------
	Purpose: Recalculates the grid cell width based on ContentFrame width.
	How: ContentFrame width minus padding, divided by 2 columns, minus gap.
	Called automatically when ContentFrame.AbsoluteSize changes.
--]]
local function UpdateGridCellSize()
	if not ContentGrid then
		return
	end
	local availableWidth = ContentFrame.AbsoluteSize.X - 24 -- 12px padding each side
	local cellWidth = math.max(100, math.floor((availableWidth - 6) / 2)) -- 2 columns, 6px gap
	ContentGrid.CellSize = UDim2.new(0, cellWidth, 0, 42)
end

-- Listen for ContentFrame size changes to update grid
AddConnection(ContentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateGridCellSize))

--══════════════════════════════════════════════════════--
-- DROPDOWN SYSTEM (Floating - does NOT push content)
--══════════════════════════════════════════════════════--
-- Dropdowns are now FLOATING above the content grid.
-- They appear below the card but do NOT push other cards down.
-- They automatically resize and reposition when the window resizes.

--[[
	UpdateDropdownPosition()
	------------------------
	Purpose: Keeps the floating dropdown positioned exactly below its parent card.
	How: Calculates the card's position relative to MainFrame and updates
	     the dropdown's Position and Size every frame.
	Also closes the dropdown if the card scrolls out of view.
--]]
--[[
	CloseDropdown()
	---------------
	Purpose: Closes the currently open floating dropdown menu.
	What it does:
		1. Stops the position-tracking heartbeat
		2. Resets the card arrow back to ">"
		3. Animates the dropdown shrinking to height 0
		4. Destroys the dropdown frame after animation
--]]
local function CloseDropdown()
	-- Stop the position tracker
	if DropdownHeartbeat then
		pcall(function()
			DropdownHeartbeat:Disconnect()
		end)
		DropdownHeartbeat = nil
	end

	-- Reset the parent card's appearance
	if ActiveDropdownCard then
		local arrow = ActiveDropdownCard:FindFirstChild("Arrow")
		if arrow then
			arrow.Text = ">"
		end
		Tween(ActiveDropdownCard, { BackgroundColor3 = Theme.Card }, 0.15)
		ActiveDropdownCard = nil
	end

	-- Animate dropdown closing (shrink height to 0)
	if ActiveDropdownFrame and ActiveDropdownFrame.Parent then
		local frame = ActiveDropdownFrame
		ActiveDropdownFrame = nil
		Tween(frame, { Size = UDim2.new(0, frame.Size.X.Offset, 0, 0) }, 0.15, function()
			if frame and frame.Parent then
				frame:Destroy()
			end
		end)
	else
		ActiveDropdownFrame = nil
	end
end

--[[
	ToggleDropdown(card, buildFunc)
	-----------------------------
	Purpose: Opens or closes a FLOATING dropdown menu below a card.
	Parameters:
		card      - TextButton: The card that was clicked
		buildFunc - function(scrollFrame): A function that adds content to the dropdown
	How it works:
		1. If clicking the same card, close the dropdown
		2. Otherwise, close any existing dropdown
		3. Create a new dropdown frame in MainFrame (floats above grid)
		4. Position it exactly below the card
		5. Start a heartbeat connection to keep it positioned during scroll/resize
		6. Call buildFunc to fill it with content (toggles, buttons, etc.)
		7. Animate it opening
		8. Other cards stay in place - nothing is pushed down!
--]]
local function UpdateDropdownPosition()
	--[[
		UpdateDropdownPosition()
		------------------------
		Purpose: Keeps the floating dropdown positioned exactly below its parent card.
		How: Calculates the card's screen position relative to MainFrame and updates
		     the dropdown's Position and Size every frame.
		Parenting to MainFrame ensures the dropdown stays locked to the card
		dropdown stays locked to the card even when the window is resized.
	--]]
	if not ActiveDropdownFrame or not ActiveDropdownCard then
		return
	end
	if not ActiveDropdownFrame.Parent then
		return
	end

	local card = ActiveDropdownCard
	local drop = ActiveDropdownFrame

	-- Get absolute screen positions
	local cardAbsPos = card.AbsolutePosition
	local cardAbsSize = card.AbsoluteSize
	local mainAbsPos = MainFrame.AbsolutePosition
	local mainAbsSize = MainFrame.AbsoluteSize

	-- If card is scrolled completely outside MainFrame vertically, close dropdown
	if cardAbsPos.Y + cardAbsSize.Y < mainAbsPos.Y or cardAbsPos.Y > mainAbsPos.Y + mainAbsSize.Y then
		CloseDropdown()
		return
	end

	-- Calculate position relative to MainFrame (our dropdown parent)
	-- This makes the dropdown stick to the card even during resize/drag
	local relX = cardAbsPos.X - mainAbsPos.X
	local relY = cardAbsPos.Y - mainAbsPos.Y + cardAbsSize.Y

	-- Update position and width to match card exactly
	drop.Position = UDim2.new(0, relX, 0, relY)
	drop.Size = UDim2.new(0, cardAbsSize.X, 0, drop.Size.Y.Offset)
end

local function ToggleDropdown(card, buildFunc)
	-- Prevent rapid clicking while animating
	if DropdownDebounce then
		return
	end

	-- If clicking the same card that's already open, close it
	if ActiveDropdownCard == card then
		CloseDropdown()
		return
	end
	DropdownDebounce = true

	-- Close any existing dropdown first
	CloseDropdown()

	-- Mark this card as the active one
	ActiveDropdownCard = card
	Tween(card, { BackgroundColor3 = Theme.CardHover }, 0.15)
	local arrow = card:FindFirstChild("Arrow")
	if arrow then
		arrow.Text = "v"
	end -- Change arrow to point down

	-- Calculate initial position below the card (relative to MainFrame)
	local cardAbsPos = card.AbsolutePosition
	local cardAbsSize = card.AbsoluteSize
	local mainAbsPos = MainFrame.AbsolutePosition
	local relX = cardAbsPos.X - mainAbsPos.X
	local relY = cardAbsPos.Y - mainAbsPos.Y + cardAbsSize.Y

	-- Create the dropdown container parented to MainFrame (above grid)
	local drop = Create("Frame", {
		Name = "Dropdown",
		Parent = MainFrame,
		BackgroundColor3 = Theme.DropdownBg,
		BorderSizePixel = 0,
		Position = UDim2.new(0, relX, 0, relY),
		Size = UDim2.new(0, cardAbsSize.X, 0, 0), -- Start at height 0, width matches card
		ClipsDescendants = true,
		ZIndex = 55, -- Above cards (ZIndex 50)
	})
	Corner(drop, 6)
	Stroke(drop, Theme.Border, 1)

	-- Scrollable area inside the dropdown
	local scroll = Create("ScrollingFrame", {
		Parent = drop,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 56,
		ClipsDescendants = true,
		Active = true,
		ScrollingEnabled = true,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})

	local list = Create("UIListLayout", {
		Parent = scroll,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})

	Create("UIPadding", {
		Parent = scroll,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	-- Build the dropdown content using the provided function
	local ok, err = pcall(buildFunc, scroll)
	if not ok then
		warn("[Dropdown Build Error]", err)
	end

	task.wait() -- Wait one frame for layout to calculate

	-- Calculate height based on content, cap at 260 pixels max
	local contentHeight = list.AbsoluteContentSize.Y + 16
	local maxHeight = math.min(contentHeight, 260)

	scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	ActiveDropdownFrame = drop

	-- Animate opening (height expands)
	Tween(drop, { Size = UDim2.new(0, cardAbsSize.X, 0, maxHeight) }, 0.2)

	-- Start heartbeat to track card position during scroll/resize
	DropdownHeartbeat = AddConnection(RunService.Heartbeat:Connect(UpdateDropdownPosition))

	-- Allow clicking again after animation finishes
	task.delay(0.25, function()
		DropdownDebounce = false
	end)
end

--══════════════════════════════════════════════════════--
-- MODAL SYSTEM
--══════════════════════════════════════════════════════--
-- Modals are popup windows that appear above everything else.
-- When a modal is open, you cannot interact with anything behind it.

--[[
	SetModalState(isOpen)
	---------------------
	Purpose: Enables or disables interaction with the main UI.
	Why: When a modal is open, we don't want users accidentally clicking
	     buttons in the main window behind the modal.
	Parameters:
		isOpen - boolean: true = modal is open (disable background), false = closed
--]]
local function SetModalState(isOpen)
	ModalOpen = isOpen
	MainFrame.Active = not isOpen -- Disable/enable main window clicks
	SidebarScroll.ScrollingEnabled = not isOpen
	ContentScroll.ScrollingEnabled = not isOpen
end

--[[
	CloseModal()
	------------
	Purpose: Closes the currently open modal.
	What it does:
		1. Animates the modal sliding down and fading out
		2. Animates the overlay fading to transparent
		3. Re-enables background interaction
--]]
function CloseModal()
	if ActiveModal then
		-- Slide modal down slightly while fading
		Tween(
			ActiveModal,
			{
				Position = UDim2.new(0.5, -ActiveModal.Size.X.Offset / 2, 0.5, -ActiveModal.Size.Y.Offset / 2 + 20),
			},
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
		-- Fade overlay to fully transparent
		Tween(ModalOverlay, { BackgroundTransparency = 1 }, 0.2, function()
			ModalOverlay.Visible = false
			SetModalState(false)
		end)
	end
end

--[[
	ShowModal(title, buildFunc, width, height)
	------------------------------------------
	Purpose: Opens a modal popup window.
	Parameters:
		title     - string: The title shown at the top of the modal
		buildFunc - function(modalFrame, contentFrame): Builds the modal's content
		width     - number: Modal width in pixels (default: 520)
		height    - number: Modal height in pixels (default: 420)
	Example:
		ShowModal("Settings", function(modal, content)
		    CreateLabel(content, "Hello from modal!", Theme.TextPrimary, 14)
		end, 400, 300)
--]]
function ShowModal(title, buildFunc, width, height)
	width = width or 520
	height = height or 420

	-- Create the overlay if it doesn't exist yet
	if not ModalOverlay then
		ModalOverlay = Create("Frame", {
			Name = "ModalOverlay",
			Parent = ScreenGui,
			BackgroundColor3 = Theme.Overlay,
			BackgroundTransparency = 1, -- Start fully transparent
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), -- Full screen
			ZIndex = 500,
			Active = false,
			Visible = false,
		})

		-- Invisible button that blocks clicks on the background
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

	-- Disable background interaction
	SetModalState(true)
	ModalOverlay.Visible = true

	-- Fade in the dark overlay
	Tween(ModalOverlay, { BackgroundTransparency = Config.ModalDarkening }, 0.2)

	-- Remove old modal if one exists
	if ActiveModal then
		ActiveModal:Destroy()
	end

	-- Create the modal window frame
	local modal = Create("Frame", {
		Name = "ModalFrame",
		Parent = ModalOverlay,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		Size = UDim2.new(0, width, 0, height),
		ZIndex = 600,
		Active = true,
	})
	Corner(modal, 8)
	Stroke(modal, Theme.Border, 1)

	-- Title bar at the top
	local titleBar = Create("Frame", {
		Parent = modal,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 12),
		Size = UDim2.new(1, -30, 0, 28),
		ZIndex = 620,
	})

	-- Title text
	Create("TextLabel", {
		Parent = titleBar,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 620,
	})

	-- Close button (X) in the title bar
	local closeModalBtn = Create("TextButton", {
		Parent = titleBar,
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
	Corner(closeModalBtn, 6)
	AddConnection(closeModalBtn.Activated:Connect(CloseModal))

	-- Content area inside the modal
	local content = Create("Frame", {
		Parent = modal,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 50),
		Size = UDim2.new(1, -30, 1, -65),
		ZIndex = 620,
		ClipsDescendants = true,
	})

	ActiveModal = modal

	-- Animate modal appearing (slight slide up)
	Tween(modal, { Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2) }, 0.3)

	-- Build the modal content
	if buildFunc then
		local ok, err = pcall(buildFunc, modal, content)
		if not ok then
			warn("[Modal Build Error]", err)
		end
	end
end

--══════════════════════════════════════════════════════--
-- SEARCH SYSTEM
--══════════════════════════════════════════════════════--
-- The search system lets users find features by typing keywords.
-- Items must be registered with RegisterSearch() to appear in results.

--[[
	RegisterSearch(name, pageName, icon, action)
	--------------------------------------------
	Purpose: Adds an item to the search database.
	Parameters:
		name     - string: The display name of the item
		pageName - string: Which page it belongs to
		icon     - string: An emoji icon
		action   - function: What to do when the item is clicked
	Example:
		RegisterSearch("Seed Shop", "Shop", "🌱", function()
		    SidebarButtons["Shop"]()
		end)
--]]
local function RegisterSearch(name, pageName, icon, action)
	table.insert(SearchableItems, {
		Name = name,
		Page = pageName,
		Icon = icon,
		Action = action,
	})
end

--[[
	Search(query)
	-------------
	Purpose: Finds items matching a search query.
	Parameters:
		query - string: What the user typed
	Returns: table (array of matching items)
--]]
local function Search(query)
	local matches = {}
	local lowerQuery = query:lower() -- Convert to lowercase for case-insensitive search
	for _, item in ipairs(SearchableItems) do
		-- Check if the item name contains the query text
		if item.Name:lower():find(lowerQuery, 1, true) then
			table.insert(matches, item)
		end
	end
	return matches
end

--[[
	UpdateSuggestions()
	-------------------
	Purpose: Updates the search suggestion dropdown based on what the user typed.
	What it does:
		1. Reads the search box text
		2. Finds matching items
		3. Creates suggestion buttons for each match
		4. Positions the dropdown below the search bar
--]]
local function UpdateSuggestions()
	-- Clear previous suggestions
	for _, child in pairs(SuggestScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local text = SearchBox.Text:lower()
	-- Hide if empty or just the placeholder
	if text == "" or text == "search" then
		SuggestFrame.Visible = false
		return
	end

	-- Find matching items
	local matches = Search(text)
	if #matches == 0 then
		SuggestFrame.Visible = false
		return
	end

	-- Position dropdown below the search bar
	local absPos = SearchFrame.AbsolutePosition
	local absSize = SearchFrame.AbsoluteSize
	SuggestFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
	SuggestFrame.Size = UDim2.new(0, absSize.X, 0, math.min(#matches * 34 + 10, 220))

	-- Create a button for each match
	for _, item in ipairs(matches) do
		local btn = Create("TextButton", {
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
		Corner(btn, 4)

		-- Hover effect
		AddConnection(btn.MouseEnter:Connect(function()
			Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end))
		AddConnection(btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundColor3 = Theme.Card }, 0.15)
		end))

		-- Click: hide suggestions and run the action
		AddConnection(btn.Activated:Connect(function()
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

	-- Update scroll area size
	SuggestScroll.CanvasSize = UDim2.new(0, 0, 0, #matches * 34)
	SuggestFrame.Visible = true
end

-- When user types in the search box, update suggestions
AddConnection(SearchBox:GetPropertyChangedSignal("Text"):Connect(UpdateSuggestions))

-- When search box loses focus, hide suggestions after a short delay
AddConnection(SearchBox.FocusLost:Connect(function()
	if SearchBox.Text == "" then
		SearchBox.Text = "Search"
	end
	task.wait(0.2)
	SuggestFrame.Visible = false
end))

-- When search box gains focus, show suggestions if text exists
AddConnection(SearchBox.Focused:Connect(function()
	if SearchBox.Text ~= "Search" and SearchBox.Text ~= "" then
		UpdateSuggestions()
	end
end))

--══════════════════════════════════════════════════════--
-- PAGE SYSTEM
--══════════════════════════════════════════════════════--
-- Pages are different sections of the hub (Home, Shop, Settings, etc.)
-- Each page has its own content that appears in the right panel.

--[[
	ClearContent()
	--------------
	Purpose: Removes ALL content from the content area.
	Why: When switching pages, we need to delete the old page's content
	     before showing the new page's content. Otherwise they stack on top
	     of each other causing the "repeating text" bug.
	What it destroys: Cards, labels, and dropdowns from ContentScroll and MainFrame
--]]
local function ClearContent()
	-- Reset scroll position to top
	ContentScroll.CanvasPosition = Vector2.new(0, 0)

	-- Close any open dropdown
	CloseDropdown()

	-- Destroy all children of ContentScroll (cards, labels, etc.)
	for _, child in pairs(ContentScroll:GetChildren()) do
		if
			child:IsA("Frame")
			or child:IsA("TextButton")
			or child:IsA("TextLabel")
			or child:IsA("UIGridLayout")
			or child:IsA("UIPadding")
		then
			child:Destroy()
		end
	end

	-- Clear any leftover dropdowns in MainFrame
	for _, child in pairs(MainFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "Dropdown" then
			child:Destroy()
		end
	end

	-- Reset card order counter
	CardOrder = 0

	-- Recreate the grid layout since we destroyed it
	ContentGrid = Create("UIGridLayout", {
		Parent = ContentScroll,
		CellPadding = UDim2.new(0, 6, 0, 6),
		CellSize = UDim2.new(0, 200, 0, 42),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		FillDirectionMaxCells = 2,
	})

	-- Update grid cell size immediately for the new page
	UpdateGridCellSize()
end

--[[
	SwitchPage(pageName, title, subtitle, builder)
	----------------------------------------------
	Purpose: Switches to a different page.
	Parameters:
		pageName - string: Internal name of the page
		title    - string: Shown in the top bar as the page title
		subtitle - string: Shown below the page title (can be empty)
		builder  - function: Creates the page's content
	Example:
		SwitchPage("Shop", "Shop", "Seed Shop", function()
		    local card = CreateCard(ContentScroll, "Seeds", "🌱", Theme.Accent)
		end)
--]]
local function SwitchPage(pageName, title, subtitle, builder)
	CurrentPage = pageName
	PageTitle.Text = title
	PageSubtitle.Text = subtitle or ""
	ClearContent() -- Remove old content first!
	local ok, err = pcall(builder) -- Build new content
	if not ok then
		warn("[Page Error]", err)
	end
end

--══════════════════════════════════════════════════════--
-- PAGES
--══════════════════════════════════════════════════════--
-- Each page function defines what appears when you click a sidebar button.

--[[
	Pages.Home()
	------------
	Purpose: The Home page - shown when the script first loads.
	Content: Welcome message and statistics card.
--]]
function Pages.Home()
	SwitchPage("Home", "Home", "Game Version: v2.0.7", function()
		-- Welcome text (spans full width in grid)
		CreateLabel(ContentScroll, "Welcome to Exotic Hub Pro", Theme.Accent, 14)
		CreateLabel(ContentScroll, "Select a category from the sidebar to get started.", Theme.TextSecondary, 12)

		-- Statistics card
		local statsCard = CreateCard(ContentScroll, "Statistics", "📊", Theme.AccentCyan)
		AddConnection(statsCard.Activated:Connect(function()
			ToggleDropdown(statsCard, function(scroll)
				CreateLabel(scroll, "FPS: Monitoring...", Theme.TextPrimary, 12)
				CreateLabel(scroll, "Ping: Monitoring...", Theme.TextPrimary, 12)
				CreateLabel(scroll, "Memory: Monitoring...", Theme.TextPrimary, 12)
			end)
		end))
	end)
end

--[[
	Pages.Account()
	---------------
	Purpose: Shows user account information.
--]]
function Pages.Account()
	SwitchPage("Account", "Account", "User Profile", function()
		local card = CreateCard(ContentScroll, "Account Info", "👤", Theme.Accent)
		AddConnection(card.Activated:Connect(function()
			ToggleDropdown(card, function(scroll)
				CreateLabel(scroll, "Username: " .. player.Name, Theme.TextPrimary, 12)
				CreateLabel(scroll, "User ID: " .. player.UserId, Theme.TextSecondary, 11)
			end)
		end))
	end)
end

--[[
	Pages.Premium()
	---------------
	Purpose: Shows premium features and benefits.
--]]
function Pages.Premium()
	SwitchPage("Premium", "Premium", "Premium Features", function()
		CreateLabel(ContentScroll, "Premium Benefits", Theme.Accent, 14)
		CreateLabel(ContentScroll, "• Auto Farm", Theme.TextSecondary, 12)
		CreateLabel(ContentScroll, "• Multi-Select", Theme.TextSecondary, 12)
		CreateLabel(ContentScroll, "• Advanced Stats", Theme.TextSecondary, 12)
	end)
end

-- Try to load game modules for the Shop page
local Networking, SeedData
pcall(function()
	Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
	SeedData = require(game:GetService("ReplicatedStorage").SharedModules.SeedData)
end)

-- Local references to config values for the shop
local SelectedSeeds = Config.SelectedSeeds
local EnableSeedShop = Config.EnableSeedShop

--[[
	GetSelectedSeedNames()
	----------------------
	Purpose: Returns a comma-separated string of selected seed names.
	Returns: string (e.g. "Carrot, Strawberry" or "None")
--]]
local function GetSelectedSeedNames()
	local names = {}
	for name, selected in pairs(SelectedSeeds) do
		if selected then
			table.insert(names, name)
		end
	end
	if #names == 0 then
		return "None"
	end
	return table.concat(names, ", ")
end

--[[
	Pages.Shop()
	------------
	Purpose: The Shop page with seed auto-buy functionality.
	Features:
		- Seed Shop card with dropdown
		- Gear Shop card (side by side in 2-column grid!)
		- Select Seeds button (opens modal)
		- Enable Auto Buy toggle
--]]
function Pages.Shop()
	SwitchPage("Shop", "Shop", "Seed Shop & Gear", function()
		-- Seed Shop card (left column in 2-column grid)
		local seedCard = CreateCard(ContentScroll, "Seed Shop", "🌱", Theme.Accent)
		AddConnection(seedCard.Activated:Connect(function()
			ToggleDropdown(seedCard, function(scroll)
				CreateLabel(scroll, "Auto Buy Seeds", Theme.Accent, 12)

				-- Show currently selected seeds
				local selectedLabel = CreateLabel(scroll, "Selected: " .. GetSelectedSeedNames(), Theme.TextMuted, 10)
				selectedLabel.Name = "SelectedLabel"

				-- Button to open seed selection modal
				local selectBtn = CreateButton(
					scroll,
					"Select Seeds...",
					Theme.Card,
					scroll.AbsoluteSize.X - 16,
					30,
					function()
						-- Build list of available seeds from game data
						local items = {}
						if SeedData then
							-- Use pairs to handle both arrays and dictionaries
							for _, seed in pairs(SeedData) do
								if typeof(seed) == "table" and seed.SeedName then
									table.insert(items, {
										Name = seed.SeedName,
										Price = seed.PurchasePrice,
										Rarity = seed.Rarity or "Common",
									})
								end
							end
							-- Sort alphabetically for consistent display
							table.sort(items, function(a, b)
								return a.Name < b.Name
							end)
						end

						-- Open multi-select modal
						ShowModal("Select Seeds", function(modal, content)
							--[[
									Modal Search Bar
									----------------
									A search input at the top of the modal that filters
									seed rows in real-time as you type.
									--]]
							local searchBox = Create("TextBox", {
								Parent = content,
								BackgroundColor3 = Theme.Card,
								BorderSizePixel = 0,
								Position = UDim2.new(0, 0, 0, 0),
								Size = UDim2.new(1, 0, 0, 32),
								Font = Enum.Font.Gotham,
								Text = "Search seeds...",
								TextColor3 = Theme.TextSecondary,
								TextSize = 12,
								ZIndex = 620,
								ClearTextOnFocus = true,
								Active = true,
							})
							Corner(searchBox, 6)
							Stroke(searchBox, Theme.Border, 1)

							-- Search icon inside the search box
							Create("TextLabel", {
								Parent = searchBox,
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 8, 0, 0),
								Size = UDim2.new(0, 22, 1, 0),
								Font = Enum.Font.GothamBold,
								Text = "🔍",
								TextColor3 = Theme.TextMuted,
								TextSize = 12,
								ZIndex = 621,
							})

							-- Scrollable list of seeds (below search bar)
							local scroll2 = Create("ScrollingFrame", {
								Parent = content,
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 0, 0, 40),
								Size = UDim2.new(1, 0, 1, -80),
								ScrollBarThickness = 3,
								ScrollBarImageColor3 = Theme.ScrollBar,
								CanvasSize = UDim2.new(0, 0, 0, 0),
								ZIndex = 620,
								ClipsDescendants = true,
							})

							local list2 = Create("UIListLayout", {
								Parent = scroll2,
								Padding = UDim.new(0, 3),
								SortOrder = Enum.SortOrder.LayoutOrder,
							})

							--[[
										BuildModalRows(filterText)
										-------------------------
										Purpose: Creates or refreshes all seed rows in the modal.
										When a row is clicked, it toggles selection and immediately
										updates the visual appearance (color + checkmark).
										Parameters:
											filterText - string: Optional search text to filter seeds by name
										--]]
							local function BuildModalRows(filterText)
								-- Clear existing rows
								for _, child in pairs(scroll2:GetChildren()) do
									if child:IsA("TextButton") then
										child:Destroy()
									end
								end

								local filteredItems = {}
								local searchLower = filterText and filterText:lower() or ""

								-- Filter items based on search text
								for _, item in ipairs(items) do
									if searchLower == "" or item.Name:lower():find(searchLower, 1, true) then
										table.insert(filteredItems, item)
									end
								end

								-- Show message if nothing matches or no data available
								if #filteredItems == 0 then
									local msg = #items == 0
											and "No seed data available. Make sure the game modules are loaded."
										or "No seeds match your search."
									local noResults = Create("TextLabel", {
										Parent = scroll2,
										BackgroundTransparency = 1,
										Size = UDim2.new(1, 0, 0, 50),
										Font = Enum.Font.Gotham,
										Text = msg,
										TextColor3 = Theme.TextMuted,
										TextSize = 12,
										TextWrapped = true,
										ZIndex = 620,
									})
									scroll2.CanvasSize = UDim2.new(0, 0, 0, 50)
									return
								end

								for i, item in ipairs(filteredItems) do
									local isSelected = SelectedSeeds[item.Name] == true

									local row = Create("TextButton", {
										Parent = scroll2,
										BackgroundColor3 = isSelected and Color3.fromRGB(55, 45, 75) -- Selected: purple tint
											or Theme.Card, -- Not selected: normal
										BorderSizePixel = 0,
										Size = UDim2.new(1, 0, 0, 34),
										LayoutOrder = i,
										Font = Enum.Font.Gotham,
										Text = "",
										ZIndex = 620,
										Active = true,
										AutoButtonColor = false,
									})
									Corner(row, 4)

									-- Seed name
									Create("TextLabel", {
										Parent = row,
										BackgroundTransparency = 1,
										Position = UDim2.new(0, 10, 0, 0),
										Size = UDim2.new(0.6, 0, 1, 0),
										Font = Enum.Font.Gotham,
										Text = item.Name,
										TextColor3 = Theme.TextPrimary,
										TextSize = 12,
										TextXAlignment = Enum.TextXAlignment.Left,
										ZIndex = 621,
									})

									-- Checkmark if selected
									if isSelected then
										Create("TextLabel", {
											Parent = row,
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

									-- Click to toggle selection with INSTANT visual update
									AddConnection(row.Activated:Connect(function()
										SelectedSeeds[item.Name] = not SelectedSeeds[item.Name]
										Config.SelectedSeeds = SelectedSeeds
										AutoSaveConfig()

										-- INSTANTLY rebuild all rows to show new selection state
										BuildModalRows(searchBox.Text)
									end))
								end

								scroll2.CanvasSize = UDim2.new(0, 0, 0, #filteredItems * 37)
							end

							-- Build rows initially (no filter)
							BuildModalRows()

							-- Rebuild rows whenever search text changes
							AddConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
								local text = searchBox.Text
								if text == "Search seeds..." then
									text = ""
								end
								BuildModalRows(text)
							end))

							-- Done button to close modal
							local doneBtn = CreateButton(content, "Done", Theme.Accent, 80, 32, function()
								CloseModal()
							end)
							doneBtn.Position = UDim2.new(1, -80, 1, -36)
						end, 480, 400)
					end
				)
				selectBtn.Size = UDim2.new(1, -8, 0, 30)

				-- Toggle to enable/disable auto buying
				local _, getToggle = CreateToggle(scroll, "Enable Auto Buy", EnableSeedShop, function(state)
					EnableSeedShop = state
					Config.EnableSeedShop = state
					AutoSaveConfig()
				end)
			end)
		end))

		-- Gear Shop card (right column in 2-column grid!)
		local gearCard = CreateCard(ContentScroll, "Gear Shop", "⚔️", Theme.AccentYellow)
		AddConnection(gearCard.Activated:Connect(function()
			ToggleDropdown(gearCard, function(scroll)
				CreateLabel(scroll, "Gear Shop", Theme.AccentYellow, 12)
				CreateLabel(scroll, "Coming Soon!", Theme.TextMuted, 11)
				CreateButton(scroll, "Browse Gear", Theme.Card, 120, 30, function()
					Notify("Gear", "Gear shop is not available yet.", "Info", 3)
				end)
			end)
		end))
	end)
end

--[[
	Pages.Settings()
	----------------
	Purpose: Settings page for configuring the UI.
	Features:
		- Disable Animations toggle
		- Reduce Effects toggle
		- Save Now button (shows notification)
		- Load Config button (shows notification)
		- Reset Config button (shows notification)
--]]
function Pages.Settings()
	SwitchPage("Settings", "Settings", "Preferences", function()
		CreateLabel(ContentScroll, "UI Settings", Theme.Accent, 14)

		-- Toggle: Disable Animations
		local _, animToggle = CreateToggle(
			ContentScroll,
			"Disable Animations",
			Config.DisableAnimations,
			function(state)
				Config.DisableAnimations = state
				AutoSaveConfig()
			end
		)

		-- Toggle: Reduce Effects
		local _, effectToggle = CreateToggle(ContentScroll, "Reduce Effects", Config.ReduceEffects, function(state)
			Config.ReduceEffects = state
			AutoSaveConfig()
		end)

		-- Spacer
		CreateLabel(ContentScroll, " ", Theme.TextSecondary, 8)

		-- Save Now button (manual save - shows notification)
		local saveNowBtn = CreateButton(ContentScroll, "Save Now", Theme.AccentGreen, 120, 32, function()
			SaveConfig(false) -- false = NOT silent, show notification
		end)

		-- Load Config button (manual load - shows notification)
		local loadNowBtn = CreateButton(ContentScroll, "Load Config", Theme.Accent, 120, 32, function()
			LoadConfig() -- Always shows notification on success
		end)

		-- Spacer
		CreateLabel(ContentScroll, " ", Theme.TextSecondary, 8)

		-- Reset Config button (shows notification)
		local resetBtn = CreateButton(ContentScroll, "Reset Config", Theme.AccentRed, 120, 32, function()
			ResetConfig()
		end)
	end)
end

--══════════════════════════════════════════════════════--
-- SIDEBAR SETUP
--══════════════════════════════════════════════════════--
-- This creates the navigation buttons on the left side.

-- Define the sidebar items
local SidebarItems = {
	{ Name = "Account", Icon = "👤", Color = Theme.Accent, Page = Pages.Account },
	{ Name = "Home", Icon = "🏠", Color = Theme.Accent, Page = Pages.Home },
	{ Name = "Premium", Icon = "💎", Color = Theme.AccentPink, Page = Pages.Premium },
	{ Name = "Shop", Icon = "🏪", Color = Theme.Accent, Page = Pages.Shop },
	{ Name = "Settings", Icon = "⚙️", Color = Theme.AccentCyan, Page = Pages.Settings },
}

-- Create each sidebar button
for index, item in ipairs(SidebarItems) do
	local btn = Create("TextButton", {
		Name = item.Name,
		Parent = SidebarScroll,
		-- Highlight "Home" by default (index 2 in this list)
		BackgroundColor3 = (index == 2) and Theme.Card or Theme.Sidebar,
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
	Corner(btn, 4)

	-- Store the click function so we can call it from search
	SidebarButtons[item.Name] = function()
		CurrentPage = item.Name

		-- Update visual selection: highlight clicked button, dim others
		for _, child in pairs(SidebarScroll:GetChildren()) do
			if child:IsA("TextButton") then
				local isSelected = (child.Name == item.Name)
				Tween(child, { BackgroundColor3 = isSelected and Theme.Card or Theme.Sidebar }, 0.2)
			end
		end

		-- Load the page content
		item.Page()
	end

	-- Hover effect (only if not currently selected)
	AddConnection(btn.MouseEnter:Connect(function()
		if CurrentPage ~= item.Name then
			Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end
	end))

	AddConnection(btn.MouseLeave:Connect(function()
		if CurrentPage ~= item.Name then
			Tween(btn, { BackgroundColor3 = Theme.Sidebar }, 0.15)
		end
	end))

	-- Click handler
	AddConnection(btn.Activated:Connect(SidebarButtons[item.Name]))

	-- Register for search
	RegisterSearch(item.Name, item.Name, item.Icon, SidebarButtons[item.Name])
end

-- Update sidebar scroll area size when buttons are added/removed
AddConnection(SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 10)
end))
-- Set initial size
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, #SidebarItems * 39 + 10)

--══════════════════════════════════════════════════════--
-- GLOBAL CLICK HANDLER
--══════════════════════════════════════════════════════--
-- This handles clicks anywhere on the screen to close
-- dropdowns and search suggestions when clicking outside them.

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Ignore if the game already processed this input (e.g., typing in a TextBox)
	if gameProcessed then
		return
	end

	-- Only handle mouse clicks and touches
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local pos = input.Position

	-- Helper: check if a position is inside a GUI element
	local function isInside(gui)
		if not gui or not gui.Parent then
			return false
		end
		local ap = gui.AbsolutePosition
		local as = gui.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end

	-- Close search suggestions if clicking outside
	if SuggestFrame and SuggestFrame.Visible then
		if not isInside(SearchFrame) and not isInside(SuggestFrame) then
			SuggestFrame.Visible = false
		end
	end

	-- Close dropdown if clicking outside of it AND outside its parent card
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
-- RESIZING SYSTEM
--══════════════════════════════════════════════════════--
-- Allows users to resize the window by dragging the bottom-right corner.

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
	-- Don't resize while a modal is open
	if ModalOpen then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local startSize = MainFrame.Size
		local startPos = input.Position
		local conn

		-- Update size every frame while dragging
		conn = AddConnection(RunService.RenderStepped:Connect(function()
			if not conn then
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

		-- Stop resizing when user releases
		AddConnection(input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				if conn then
					conn:Disconnect()
				end
				conn = nil
			end
		end))
	end
end))

--══════════════════════════════════════════════════════--
-- WINDOW DRAG
--══════════════════════════════════════════════════════--
-- Allows users to drag the window by clicking and dragging the top bar.

local dragging = false
local dragStart, frameStart

AddConnection(MainFrame.InputBegan:Connect(function(input)
	-- Don't drag while modal is open
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
-- AUTO BUY LOOP
--══════════════════════════════════════════════════════--
-- This background loop automatically buys selected seeds
-- when EnableSeedShop is true and you have enough money.

table.insert(
	Tasks,
	task.spawn(function()
		while ScriptRunning do
			task.wait(0.2) -- Check every 0.2 seconds

			-- Only buy if enabled and game modules loaded
			if EnableSeedShop and Networking and SeedData then
				-- Get player's money
				local leaderstats = player:FindFirstChild("leaderstats")
				local sheckles = leaderstats and leaderstats:FindFirstChild("Sheckles")

				if sheckles then
					-- Try to buy each selected seed
					for _, seed in pairs(SeedData) do
						if
							typeof(seed) == "table"
							and SelectedSeeds[seed.SeedName]
							and sheckles.Value >= (seed.PurchasePrice or 0)
						then
							pcall(function()
								Networking.SeedShop.PurchaseSeed:Fire(seed.SeedName)
							end)
						end
					end
				end
			end
		end
	end)
)

--══════════════════════════════════════════════════════--
-- MOBILE SUPPORT
--══════════════════════════════════════════════════════--
-- If the device has a touchscreen, shrink the window to fit.

if UserInputService.TouchEnabled then
	local viewport = workspace.CurrentCamera.ViewportSize
	local w = math.max(Config.MinWindowWidth, math.min(Config.WindowWidth, viewport.X - 20))
	local h = math.max(Config.MinWindowHeight, math.min(Config.WindowHeight, viewport.Y - 40))
	MainFrame.Size = UDim2.new(0, w, 0, h)
	MainFrame.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
end

--══════════════════════════════════════════════════════--
-- STARTUP
--══════════════════════════════════════════════════════--
-- This code runs when the script first loads.

-- Try to load saved configuration (shows notification on success)
LoadConfig()

-- Show the Home page by default
Pages.Home()

-- Show a welcome notification
Notify("Exotic Hub Pro", "v2.0.7 Loaded! 2-column grid + floating dropdowns.", "Success", 4)
