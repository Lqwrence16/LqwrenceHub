-- ═══════════════════════════════════════════════════════════════════════
--  EXOTIC HUB PRO v2.0.5
--  All undefined variables fixed, notifications working, dropdowns
--  positioned above cards, modal selections update instantly.
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

--══════════════════════════════════════════════════════--
-- THEME
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
-- STATE VARIABLES (must be defined before any function uses them)
--══════════════════════════════════════════════════════--

local ScriptRunning = true
local Connections = {}
local Tasks = {} -- FIXED: Was undefined before
local ActiveNotifs = 0
local CurrentPage = "Home"
local SidebarButtons = {}
local Pages = {}
local SearchableItems = {}

-- Dropdown state
local ActiveDropdownCard = nil
local ActiveDropdownFrame = nil
local DropdownDebounce = false
local StickyConnection = nil

-- Modal state
local ModalOverlay = nil
local ActiveModal = nil
local ModalOpen = false

-- Card order counter
local CardOrder = 0

-- Auto-save debounce handle
local AutoSaveDebounce = nil

--══════════════════════════════════════════════════════--
-- CONFIG SYSTEM
--══════════════════════════════════════════════════════--

local CONFIG_FILE = "ExoticHubPro_Config.json"
local CONFIG_ATTRIBUTE = "ExoticHubProConfig"
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

local function BuildSaveData()
	local data = {}
	for _, key in ipairs(SERIALIZABLE_KEYS) do
		if Config[key] ~= nil then
			data[key] = Config[key]
		end
	end
	return data
end

local function ApplyLoadedData(data)
	if typeof(data) ~= "table" then
		return false
	end
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
-- We create ScreenGui here so Notify() can use it safely.
-- This fixes the "ScreenGui is undefined" warning in Notify.

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExoticHubPro"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

--══════════════════════════════════════════════════════--
-- MAIN FRAME
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

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = MainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Theme.Border
stroke.Thickness = 2
stroke.Parent = MainFrame

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
-- NOTIFICATION SYSTEM (NOW ScreenGui EXISTS!)
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

	local bar = Instance.new("Frame")
	bar.Parent = frame
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(0, 4, 1, 0)
	bar.ZIndex = 701

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 8)
	bc.Parent = bar

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

	-- Animate in
	TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -300, 0, frame.Position.Y.Offset),
	}):Play()

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

function SaveConfig()
	local saveData = BuildSaveData()
	local encoded
	local ok, err = pcall(function()
		encoded = HttpService:JSONEncode(saveData)
	end)
	if not ok then
		warn("[Config] JSON Encode failed:", err)
		return false, "encode_failed"
	end

	-- writefile, isfile, readfile, delfile are EXECUTOR-ONLY functions.
	-- They will show as "undefined" in Roblox Studio. This is NORMAL.
	-- They work fine in Synapse X, KRNL, Fluxus, etc.

	if writefile then
		local fileOk = pcall(function()
			writefile(CONFIG_FILE, encoded)
		end)
		if fileOk then
			Notify("Config", "Saved to file!", "Success", 2)
			return true, "file"
		end
	end

	local attrOk = pcall(function()
		player:SetAttribute(CONFIG_ATTRIBUTE, encoded)
	end)
	if attrOk then
		Notify("Config", "Saved (attribute)", "Info", 2)
		return true, "attribute"
	end

	local valOk = pcall(function()
		local existing = playerGui:FindFirstChild(CONFIG_ATTRIBUTE)
		if existing then
			existing:Destroy()
		end
		local val = Instance.new("StringValue")
		val.Name = CONFIG_ATTRIBUTE
		val.Value = encoded
		val.Parent = playerGui
	end)
	if valOk then
		Notify("Config", "Saved (StringValue)", "Info", 2)
		return true, "stringvalue"
	end

	Notify("Config", "Failed to save", "Error", 3)
	return false, "none"
end

function LoadConfig()
	local encoded = nil
	local method = "none"

	if isfile and isfile(CONFIG_FILE) then
		local ok, result = pcall(readfile, CONFIG_FILE)
		if ok and result and #result > 0 then
			encoded = result
			method = "file"
		end
	end

	if not encoded then
		local ok, result = pcall(function()
			return player:GetAttribute(CONFIG_ATTRIBUTE)
		end)
		if ok and result and typeof(result) == "string" and #result > 0 then
			encoded = result
			method = "attribute"
		end
	end

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

	if encoded then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(encoded)
		end)
		if ok and data and ApplyLoadedData(data) then
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
	-- delfile is executor-only. Undefined in Studio = NORMAL.
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
	Theme = Themes.Dark
	Notify("Config", "Reset to defaults", "Warning", 3)
end

function AutoSaveConfig()
	if AutoSaveDebounce then
		pcall(function()
			task.cancel(AutoSaveDebounce)
		end)
	end
	AutoSaveDebounce = task.delay(1, function()
		SaveConfig()
		AutoSaveDebounce = nil
	end)
end

--══════════════════════════════════════════════════════--
-- UTILITY FUNCTIONS
--══════════════════════════════════════════════════════--

local function AddConnection(connection)
	table.insert(Connections, connection)
	return connection
end

local function DisconnectAll()
	for _, c in ipairs(Connections) do
		if c and c.Connected then
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	table.clear(Connections)
end

local function Tween(instance, props, duration, callback)
	if Config.DisableAnimations then
		for k, v in pairs(props) do
			instance[k] = v
		end
		if callback then
			callback()
		end
		return
	end
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration or Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	)
	if callback then
		tween.Completed:Connect(callback)
	end
	tween:Play()
end

local function Create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function Corner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = inst
end

local function Stroke(inst, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.Parent = inst
end

--══════════════════════════════════════════════════════--
-- TOGGLE BUTTON
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
			Tween(MainIcon, {
				BackgroundColor3 = MainFrame.Visible and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(30, 30, 30),
			}, 0.2)
		end
	end
end))

--══════════════════════════════════════════════════════--
-- TOP BAR
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
	Text = " _hub",
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

--══════════════════════════════════════════════════════--
-- SEARCH BAR
--══════════════════════════════════════════════════════--

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

--══════════════════════════════════════════════════════--
-- CLOSE BUTTON
--══════════════════════════════════════════════════════--

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
	ScreenGui:Destroy()
end))

--══════════════════════════════════════════════════════--
-- SIDEBAR
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
-- CONTENT AREA
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

local ContentGrid = Create("UIGridLayout", {
	Parent = ContentScroll,
	CellSize = UDim2.new(0.5, -6, 0, 42),
	CellPadding = UDim2.new(0, 6, 0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

--══════════════════════════════════════════════════════--
-- DROPDOWN LAYER (ClipsDescendants = false so dropdown can go upward)
--══════════════════════════════════════════════════════--

local DropdownLayer = Create("Frame", {
	Name = "DropdownLayer",
	Parent = ContentFrame,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 12, 0, 58),
	Size = UDim2.new(1, -24, 1, -70),
	ZIndex = 100,
	ClipsDescendants = false, -- FIXED: Allow dropdown to extend upward without clipping
	Active = false,
})

--══════════════════════════════════════════════════════--
-- COMPONENT BUILDERS
--══════════════════════════════════════════════════════--

local function CreateCard(parent, title, icon, iconColor)
	local card = Create("TextButton", {
		Name = title,
		Parent = parent,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = CardOrder,
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
-- DROPDOWN SYSTEM (FIXED: Opens above card)
--══════════════════════════════════════════════════════--

local function UpdateDropdownPos()
	if not ActiveDropdownFrame or not ActiveDropdownCard then
		return
	end
	if not ActiveDropdownCard.Parent then
		if ActiveDropdownFrame then
			ActiveDropdownFrame:Destroy()
		end
		ActiveDropdownFrame = nil
		ActiveDropdownCard = nil
		return
	end

	local cardAbs = ActiveDropdownCard.AbsolutePosition
	local layerAbs = DropdownLayer.AbsolutePosition
	local dropHeight = ActiveDropdownFrame.AbsoluteSize.Y

	-- FIXED: Position dropdown ABOVE the card (connected to top)
	ActiveDropdownFrame.Position = UDim2.new(0, cardAbs.X - layerAbs.X, 0, cardAbs.Y - layerAbs.Y - dropHeight - 2)
end

local function CloseDropdown()
	if not ActiveDropdownFrame then
		return
	end

	if StickyConnection then
		StickyConnection:Disconnect()
		StickyConnection = nil
	end

	if ActiveDropdownCard then
		local arrow = ActiveDropdownCard:FindFirstChild("Arrow")
		if arrow then
			arrow.Text = ">"
		end
		Tween(ActiveDropdownCard, { BackgroundColor3 = Theme.Card }, 0.15)
		ActiveDropdownCard = nil
	end

	local frame = ActiveDropdownFrame
	ActiveDropdownFrame = nil
	Tween(frame, { Size = UDim2.new(0, frame.Size.X.Offset, 0, 0) }, 0.15, function()
		if frame and frame.Parent then
			frame:Destroy()
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

	local cAbs = card.AbsolutePosition
	local lAbs = DropdownLayer.AbsolutePosition
	local relX = cAbs.X - lAbs.X

	local drop = Create("TextButton", {
		Name = "Dropdown",
		Parent = DropdownLayer,
		BackgroundColor3 = Theme.DropdownBg,
		BorderSizePixel = 0,
		Position = UDim2.new(0, relX, 0, cAbs.Y - lAbs.Y - 2),
		Size = UDim2.new(0, card.AbsoluteSize.X, 0, 0),
		ZIndex = 100,
		ClipsDescendants = true,
		Active = true,
		AutoButtonColor = false,
		Text = "",
	})
	Corner(drop, 6)
	Stroke(drop, Theme.Border, 1)

	local scroll = Create("ScrollingFrame", {
		Parent = drop,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 110,
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

	local ok, err = pcall(buildFunc, scroll)
	if not ok then
		warn("[Dropdown Build Error]", err)
	end

	task.wait()

	local contentHeight = list.AbsoluteContentSize.Y + 16
	local maxHeight = math.min(contentHeight, 260)
	local width = card.AbsoluteSize.X

	scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	ActiveDropdownFrame = drop
	Tween(drop, { Size = UDim2.new(0, width, 0, maxHeight) }, 0.2)

	-- After sizing, update position to be above the card
	task.delay(0.05, function()
		UpdateDropdownPos()
	end)

	StickyConnection = AddConnection(RunService.Heartbeat:Connect(UpdateDropdownPos))

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

	local titleBar = Create("Frame", {
		Parent = modal,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 12),
		Size = UDim2.new(1, -30, 0, 28),
		ZIndex = 620,
	})

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

	local content = Create("Frame", {
		Parent = modal,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 50),
		Size = UDim2.new(1, -30, 1, -65),
		ZIndex = 620,
		ClipsDescendants = true,
	})

	ActiveModal = modal
	Tween(modal, { Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2) }, 0.3)

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

local function RegisterSearch(name, pageName, icon, action)
	table.insert(SearchableItems, {
		Name = name,
		Page = pageName,
		Icon = icon,
		Action = action,
	})
end

local function Search(query)
	local matches = {}
	local lowerQuery = query:lower()
	for _, item in ipairs(SearchableItems) do
		if item.Name:lower():find(lowerQuery, 1, true) then
			table.insert(matches, item)
		end
	end
	return matches
end

local function UpdateSuggestions()
	for _, child in pairs(SuggestScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local text = SearchBox.Text:lower()
	if text == "" or text == "search" then
		SuggestFrame.Visible = false
		return
	end

	local matches = Search(text)
	if #matches == 0 then
		SuggestFrame.Visible = false
		return
	end

	local absPos = SearchFrame.AbsolutePosition
	local absSize = SearchFrame.AbsoluteSize
	SuggestFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
	SuggestFrame.Size = UDim2.new(0, absSize.X, 0, math.min(#matches * 34 + 10, 220))

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

		AddConnection(btn.MouseEnter:Connect(function()
			Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15)
		end))
		AddConnection(btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundColor3 = Theme.Card }, 0.15)
		end))

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

	SuggestScroll.CanvasSize = UDim2.new(0, 0, 0, #matches * 34)
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
	for _, child in pairs(ContentScroll:GetChildren()) do
		if
			child:IsA("Frame")
			or child:IsA("TextButton")
			or child:IsA("TextLabel")
			or child:IsA("UIListLayout")
			or child:IsA("UIGridLayout")
			or child:IsA("UIPadding")
		then
			child:Destroy()
		end
	end
	CardOrder = 0

	ContentGrid = Create("UIGridLayout", {
		Parent = ContentScroll,
		CellSize = UDim2.new(0.5, -6, 0, 42),
		CellPadding = UDim2.new(0, 6, 0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function SwitchPage(pageName, title, subtitle, builder)
	CurrentPage = pageName
	PageTitle.Text = title
	PageSubtitle.Text = subtitle or ""
	ClearContent()
	local ok, err = pcall(builder)
	if not ok then
		warn("[Page Error]", err)
	end
end

--══════════════════════════════════════════════════════--
-- PAGES
--══════════════════════════════════════════════════════--

function Pages.Home()
	SwitchPage("Home", "Home", "Game Version: v2.0.5", function()
		CreateLabel(ContentScroll, "Welcome to Exotic Hub Pro", Theme.Accent, 14)
		CreateLabel(ContentScroll, "Select a category from the sidebar to get started.", Theme.TextSecondary, 12)

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

function Pages.Premium()
	SwitchPage("Premium", "Premium", "Premium Features", function()
		CreateLabel(ContentScroll, "Premium Benefits", Theme.Accent, 14)
		CreateLabel(ContentScroll, "• Auto Farm\n• Multi-Select\n• Advanced Stats", Theme.TextSecondary, 12)
	end)
end

local Networking, SeedData
pcall(function()
	Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
	SeedData = require(game:GetService("ReplicatedStorage").SharedModules.SeedData)
end)

local SelectedSeeds = Config.SelectedSeeds
local EnableSeedShop = Config.EnableSeedShop

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

function Pages.Shop()
	SwitchPage("Shop", "Shop", "Seed Shop & Gear", function()
		local seedCard = CreateCard(ContentScroll, "Seed Shop", "🌱", Theme.Accent)

		AddConnection(seedCard.Activated:Connect(function()
			ToggleDropdown(seedCard, function(scroll)
				CreateLabel(scroll, "Auto Buy Seeds", Theme.Accent, 12)

				-- Show currently selected seeds
				local selectedLabel = CreateLabel(scroll, "Selected: " .. GetSelectedSeedNames(), Theme.TextMuted, 10)
				selectedLabel.Name = "SelectedLabel"

				local selectBtn = CreateButton(
					scroll,
					"Select Seeds...",
					Theme.Card,
					scroll.AbsoluteSize.X - 16,
					30,
					function()
						local items = {}
						if SeedData then
							for _, seed in ipairs(SeedData) do
								if seed.SeedName then
									table.insert(items, {
										Name = seed.SeedName,
										Price = seed.PurchasePrice,
										Rarity = seed.Rarity or "Common",
									})
								end
							end
						end

						ShowModal("Select Seeds", function(modal, content)
							local scroll2 = Create("ScrollingFrame", {
								Parent = content,
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 1, -40),
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

							-- FIXED: BuildModalRows is now a proper local function defined BEFORE use
							local function BuildModalRows()
								for _, child in pairs(scroll2:GetChildren()) do
									if child:IsA("TextButton") then
										child:Destroy()
									end
								end

								for i, item in ipairs(items) do
									local isSelected = SelectedSeeds[item.Name] == true

									local row = Create("TextButton", {
										Parent = scroll2,
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
									Corner(row, 4)

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

									-- FIXED: Instant visual update on click
									AddConnection(row.Activated:Connect(function()
										SelectedSeeds[item.Name] = not SelectedSeeds[item.Name]
										Config.SelectedSeeds = SelectedSeeds
										AutoSaveConfig()

										-- Rebuild all rows to show updated selection state
										BuildModalRows()
									end))
								end

								scroll2.CanvasSize = UDim2.new(0, 0, 0, #items * 37)
							end

							-- Build initially
							BuildModalRows()

							local doneBtn = CreateButton(content, "Done", Theme.Accent, 80, 32, function()
								CloseModal()
							end)
							doneBtn.Position = UDim2.new(1, -80, 1, -36)
						end, 480, 400)
					end
				)
				selectBtn.Size = UDim2.new(1, -8, 0, 30)

				local _, getToggle = CreateToggle(scroll, "Enable Auto Buy", EnableSeedShop, function(state)
					EnableSeedShop = state
					Config.EnableSeedShop = state
					AutoSaveConfig()
				end)
			end)
		end))
	end)
end

function Pages.Settings()
	SwitchPage("Settings", "Settings", "Preferences", function()
		CreateLabel(ContentScroll, "UI Settings", Theme.Accent, 14)

		local _, animToggle = CreateToggle(
			ContentScroll,
			"Disable Animations",
			Config.DisableAnimations,
			function(state)
				Config.DisableAnimations = state
				AutoSaveConfig()
			end
		)

		local _, effectToggle = CreateToggle(ContentScroll, "Reduce Effects", Config.ReduceEffects, function(state)
			Config.ReduceEffects = state
			AutoSaveConfig()
		end)

		CreateLabel(ContentScroll, " ", Theme.TextSecondary, 8)

		local saveNowBtn = CreateButton(ContentScroll, "Save Now", Theme.AccentGreen, 120, 32, function()
			SaveConfig()
		end)

		local loadNowBtn = CreateButton(ContentScroll, "Load Config", Theme.Accent, 120, 32, function()
			LoadConfig()
		end)

		CreateLabel(ContentScroll, " ", Theme.TextSecondary, 8)

		local resetBtn = CreateButton(ContentScroll, "Reset Config", Theme.AccentRed, 120, 32, function()
			ResetConfig()
		end)
	end)
end

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

for index, item in ipairs(SidebarItems) do
	local btn = Create("TextButton", {
		Name = item.Name,
		Parent = SidebarScroll,
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

	SidebarButtons[item.Name] = function()
		CurrentPage = item.Name
		for _, child in pairs(SidebarScroll:GetChildren()) do
			if child:IsA("TextButton") then
				local isSel = (child.Name == item.Name)
				Tween(child, { BackgroundColor3 = isSel and Theme.Card or Theme.Sidebar }, 0.2)
			end
		end
		item.Page()
	end

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
	AddConnection(btn.Activated:Connect(SidebarButtons[item.Name]))
	RegisterSearch(item.Name, item.Name, item.Icon, SidebarButtons[item.Name])
end

AddConnection(SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 10)
end))
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, #SidebarItems * 39 + 10)

--══════════════════════════════════════════════════════--
-- GLOBAL CLICK HANDLER
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
-- RESIZING
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
		local conn
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
-- AUTO BUY LOOP
--══════════════════════════════════════════════════════--

table.insert(
	Tasks,
	task.spawn(function()
		while ScriptRunning do
			task.wait(0.2)
			if EnableSeedShop and Networking and SeedData then
				local leaderstats = player:FindFirstChild("leaderstats")
				local sheckles = leaderstats and leaderstats:FindFirstChild("Sheckles")
				if sheckles then
					for _, seed in ipairs(SeedData) do
						if SelectedSeeds[seed.SeedName] and sheckles.Value >= (seed.PurchasePrice or 0) then
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

if UserInputService.TouchEnabled then
	local viewport = workspace.CurrentCamera.ViewportSize
	local w = math.min(Config.WindowWidth, viewport.X - 20)
	local h = math.min(Config.WindowHeight, viewport.Y - 40)
	MainFrame.Size = UDim2.new(0, w, 0, h)
	MainFrame.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
end

--══════════════════════════════════════════════════════--
-- STARTUP
--══════════════════════════════════════════════════════--

LoadConfig()
Pages.Home()
Notify("Exotic Hub Pro", "v2.0.5 Loaded! All fixes applied.", "Success", 4)
