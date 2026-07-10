local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--==============================================================================
-- CONFIG & CONSTANTS
--==============================================================================

local DEV_MODE = false

local CONSTANTS = {
	Config = {
		FILE = "LRX_Hub_Config.json",
		AutoSaveDefault = true,
	},
	Paths = {
		CACHE_FOLDER = "LRXHUB69/cache",
		CACHE_FILE = "LRXHUB69/cache/LRXUI.lua",
		VERSION_FILE = "LRXHUB69/cache/LRXUI.version",
	},
	URLs = {
		UI = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua",
		VERSION = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.version",
	},
	Version = {
		HUB = "v1.0.0-DEMO",
		UI = "0.0.03",
	},
	UI = {
		Targets = { "Obsidian", "ObsidanModal", "LRXUI", "LRXUI_Modal" },
	},
}

--==============================================================================
-- LOGGER
--==============================================================================

local Logger = {
	Debug = function(tag, msg)
		if DEV_MODE then
			print("[LRX " .. tostring(tag) .. "] " .. tostring(msg))
		end
	end,
	Info = function(tag, msg)
		print("[LRX " .. tostring(tag) .. "] " .. tostring(msg))
	end,
	Warn = function(tag, msg)
		warn("[LRX " .. tostring(tag) .. "] " .. tostring(msg))
	end,
	Error = function(msg)
		error("[LRX Loader] " .. tostring(msg))
	end,
}

--==============================================================================
-- HELPER FUNCTIONS
--==============================================================================

local function ReadFile(path)
	if not isfile or not isfile(path) then
		return nil
	end
	local ok, data = pcall(readfile, path)
	if ok and data and #data > 0 then
		return data
	end
	return nil
end

local function WriteFile(path, data)
	if not writefile then
		return false
	end
	return pcall(writefile, path, data)
end

local function EnsureCacheFolders()
	if not makefolder then
		return
	end
	if not isfolder("LRXHUB69") then
		pcall(makefolder, "LRXHUB69")
	end
	if not isfolder(CONSTANTS.Paths.CACHE_FOLDER) then
		pcall(makefolder, CONSTANTS.Paths.CACHE_FOLDER)
	end
end

local function Download(url)
	if not url then
		return nil
	end
	local ok, data = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and data and #data > 0 then
		return data
	end
	return nil
end

local function IsValidVersion(str)
	if type(str) ~= "string" then return false end
	if #str == 0 then return false end
	if not str:match("%S") then return false end
	if str:find("<!DOCTYPE", 1, true) or str:find("<html", 1, true) then return false end
	local lower = str:lower()
	if lower:find("not found") or lower:find("404") then return false end
	if lower:find("error") and #str < 200 then return false end
	return true
end

local function IsValidLibrarySource(str)
	if type(str) ~= "string" then return false end
	if #str <= 100 then return false, "Source too short" end
	if str:find("<!DOCTYPE", 1, true) or str:find("<html", 1, true) then
		return false, "Download returned HTML"
	end
end

local function ReadCache()
	local ui = ReadFile(CONSTANTS.Paths.CACHE_FILE)
	if not ui or #ui < 100 then return nil end
	local version = ReadFile(CONSTANTS.Paths.VERSION_FILE)
	if not version or #version == 0 then return nil end
	return { UI = ui, Version = version }
end

local function WriteCache(ui, version)
	local ok1 = ui and WriteFile(CONSTANTS.Paths.CACHE_FILE, ui) or true
	local ok2 = version and WriteFile(CONSTANTS.Paths.VERSION_FILE, version) or true
	return ok1 and ok2
end

local function DownloadLatest()
	Logger.Info("Cache", "Downloading...")
	local ui = Download(CONSTANTS.URLs.UI)
	if not ui or #ui <= 100 then
		Logger.Warn("Cache", "Failed to download LRXUI.lua")
		return nil
	end
	local uiOk, uiErr = IsValidLibrarySource(ui)
	if not uiOk then
		Logger.Warn("Cache", "Invalid LRXUI.lua: " .. tostring(uiErr))
		return nil
	end
	local version = Download(CONSTANTS.URLs.VERSION)
	if not IsValidVersion(version) then version = "unknown" end
	Logger.Info("Cache", "Download complete.")
	return { UI = ui, Version = version }
end

local function ValidateAndLoad(source)
	if not source or type(source) ~= "string" then
		return false, "Source is nil"
	end
	if #source <= 100 then
		return false, "Source too short"
	end
	local chunk, compileError = loadstring(source)
	if not chunk then
		return false, "Syntax error: " .. tostring(compileError)
	end
	local success, result = xpcall(chunk, debug.traceback)
	if not success then
		return false, "Runtime error: " .. tostring(result)
	end
	if type(result) ~= "table" then
		return false, "Did not return table, got: " .. type(result)
	end
	return true, result
end

--==============================================================================
-- CLEANUP
--==============================================================================

local function DestroyHubUI()
	local targets = CONSTANTS.UI.Targets
	local function DestroyIn(parent)
		if not parent then return end
		for _, child in ipairs(parent:GetChildren()) do
			if table.find(targets, child.Name) then
				pcall(function() child:Destroy() end)
			end
		end
	end
	local localPlayer = Players.LocalPlayer
	if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
		DestroyIn(localPlayer.PlayerGui)
	end
	DestroyIn(CoreGui)
end

local function Cleanup()
	Logger.Info("Loader", "Running cleanup...")
	pcall(function()
		if getgenv and getgenv().Library then
			pcall(function()
				if getgenv().Library.Unload then
					getgenv().Library:Unload()
				end
			end)
			getgenv().Library = nil
		end
		_G.LRX_Hub_UI = nil
		_G.LRX_Connections = {}
		_G.LRX_KillSwitch = false
		_G.AutoFarmEnabled = nil
		DestroyHubUI()
	end)
	task.wait(0.15)
	Logger.Info("Loader", "Cleanup complete.")
end
Cleanup()

--==============================================================================
-- CACHE SETUP & LIBRARY LOADING
--==============================================================================

EnsureCacheFolders()

local Library = nil

if DEV_MODE then
	Logger.Info("Loader", "DEV_MODE enabled.")
	local devSource = ReadFile(CONSTANTS.Paths.CACHE_FILE)
	if not devSource then
		Logger.Error("DEV_MODE requires LRXUI.lua at '" .. CONSTANTS.Paths.CACHE_FILE .. "'")
		return
	end
	local valid, result = ValidateAndLoad(devSource)
	if not valid then
		Logger.Error("DEV_MODE validation failed: " .. tostring(result))
		return
	end
	Library = result
	Logger.Info("Loader", "Local library loaded.")
else
	Logger.Info("Loader", "Release mode.")
	local cache = ReadCache()
	local librarySource = nil

	if not cache then
		Logger.Info("Cache", "Cache missing. Downloading...")
		local latest = DownloadLatest()
		if not latest then
			Logger.Error("Failed to download LRXUI. No cache available.")
			return
		end
		local valid, result = ValidateAndLoad(latest.UI)
		if not valid then
			Logger.Error("Validation failed: " .. tostring(result))
			return
		end
		WriteCache(latest.UI, latest.Version)
		Library = result
		librarySource = latest.UI
		Logger.Info("Cache", "Cache created.")
	else
		Logger.Info("Cache", "Cache found. Version: " .. tostring(cache.Version))
		if cache.Version == CONSTANTS.Version.UI then
			Logger.Info("Cache", "Cache is up to date.")
			librarySource = cache.UI
		else
			Logger.Info("Cache", "Version mismatch. Downloading...")
			local latest = DownloadLatest()
			if not latest then
				Logger.Warn("Cache", "Download failed. Using existing cache.")
				librarySource = cache.UI
			else
				local valid, result = ValidateAndLoad(latest.UI)
				if not valid then
					Logger.Warn("Cache", "Validation failed: " .. tostring(result) .. ". Using cache.")
					librarySource = cache.UI
				else
					WriteCache(latest.UI, latest.Version)
					Library = result
					librarySource = latest.UI
					Logger.Info("Cache", "Cache updated.")
				end
			end
		end
	end

	if not Library and librarySource then
		local valid, result = ValidateAndLoad(librarySource)
		if not valid then
			Logger.Error("Failed to load library: " .. tostring(result))
			return
		end
		Library = result
	end
end

if not Library then
	Logger.Error("No library source available.")
	return
end

getgenv().Library = Library

--==============================================================================
-- CONFIG PERSISTENCE
--==============================================================================

local SavedConfig = {}
pcall(function()
	if readfile and isfile and isfile(CONSTANTS.Config.FILE) then
		SavedConfig = HttpService:JSONDecode(readfile(CONSTANTS.Config.FILE))
	end
end)

local function SaveConfig()
	pcall(function()
		if writefile then
			writefile(CONSTANTS.Config.FILE, HttpService:JSONEncode(SavedConfig))
		end
	end)
end

local function GetSaved(key, default)
	if SavedConfig[key] ~= nil then
		return SavedConfig[key]
	end
	return default
end

local function SetSaved(key, value)
	SavedConfig[key] = value
	if key == "AutoSaveConfig" or (SavedConfig["AutoSaveConfig"] ~= false) then
		SaveConfig()
	end
end

_G.LRX_Connections = _G.LRX_Connections or {}
_G.LRX_KillSwitch = false

--==============================================================================
-- #1 // WINDOW SETUP
--==============================================================================

local Window = Library:CreateWindow({
	Title = "LRX Hub - Complete Demo",
	Footer = CONSTANTS.Version.HUB,
	Icon = "layout-dashboard",
	IconSize = UDim2.fromOffset(28, 28),
	Size = UDim2.fromOffset(800, 600),
	Position = UDim2.fromOffset(80, 80),
	Center = true,
	AutoShow = true,
	Resizable = true,
	SearchbarSize = UDim2.fromScale(1, 1),
	CornerRadius = 10,
	NotifySide = "Right",
	ShowCustomCursor = false,
	Font = Enum.Font.BuilderSans,
	ToggleKeybind = Enum.KeyCode.RightControl,
	MobileButtonsSide = "Left",
})

--==============================================================================
-- #2 // TABS
--==============================================================================

local HomeTab       = Window:AddTab("Home", "house", "Welcome to the LRXUI demo!")
local ElementsTab   = Window:AddTab("Elements", "component", "All UI element types.")
local AdvancedTab   = Window:AddTab("Advanced", "cpu", "Advanced features.")
local VisualTab     = Window:AddTab("Visual", "palette", "Colors & visuals.")
local SettingsTab   = Window:AddTab("Settings", "settings", "Configure & manage.")

--==============================================================================
-- #3 // HOME TAB
--==============================================================================

local HomeLeft = HomeTab:AddLeftGroupbox("Welcome", "hand-metal")
local HomeRight = HomeTab:AddRightGroupbox("System Info", "monitor")

HomeLeft:AddLabel("Welcome to LRX Hub!")
HomeLeft:AddLabel("This demo shows every API feature.")
HomeLeft:AddDivider()

local StatusLabel = HomeLeft:AddLabel("Status: <font color=\"#4ade80\">Online</font>")
local PingLabel = HomeLeft:AddLabel("Ping: -- ms")

HomeLeft:AddButton("Show Notification", function()
	Library:Notify({
		Title = "Hello!",
		Description = "This is a notification toast.",
		Time = 5,
	})
end)

HomeLeft:AddButton({
	Text = "Show Confirm Dialog",
	Func = function()
		Library:Confirm({
			Title = "Confirm Action",
			Description = "Are you sure you want to proceed?",
			Callback = function(accepted)
				if accepted then
					Library:Notify({ Title = "Confirmed!", Description = "Action accepted.", Time = 3 })
				else
					Library:Notify({ Title = "Cancelled", Description = "Action cancelled.", Time = 3 })
				end
			end,
		})
	end,
})

HomeLeft:AddButton({
	Text = "Show Info Dialog",
	Func = function()
		Library:InfoPopup({
			Title = "Information",
			Description = "This is an info popup with OK only.",
			Callback = function() print("Info popup closed") end,
		})
	end,
})

HomeLeft:AddButton({
	Text = "Danger Button",
	Risky = true,
	DoubleClick = true,
	Func = function()
		Library:Notify({ Title = "Danger!", Description = "Double-click confirmed!", Time = 3 })
	end,
})

local MultiBtn = HomeLeft:AddButton("Main Action", function()
	print("Main button clicked")
end)
MultiBtn:AddButton("Side A", function()
	print("Side A clicked")
end)
MultiBtn:AddButton("Side B", function()
	print("Side B clicked")
end)

HomeRight:AddLabel("Client Info:")
HomeRight:AddLabel("Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))
HomeRight:AddLabel("Place ID: " .. tostring(game.PlaceId))
HomeRight:AddDivider()

HomeRight:AddButton("Copy Place ID", function()
	if setclipboard then
		setclipboard(tostring(game.PlaceId))
		Library:Notify({ Title = "Copied!", Description = "Place ID copied.", Time = 3 })
	end
end)

HomeRight:AddButton("Unload UI", function()
	Library:Unload()
end)

--==============================================================================
-- #4 // ELEMENTS TAB - Toggles, Inputs, Sliders, Dropdowns
--==============================================================================

local ToggleBox = ElementsTab:AddLeftGroupbox("Toggles & Checkboxes", "toggle-left")
local InputBox = ElementsTab:AddRightGroupbox("Inputs & Sliders", "sliders")
local DropdownBox = ElementsTab:AddLeftGroupbox("Dropdowns", "list")
local MiscBox = ElementsTab:AddRightGroupbox("Misc Elements", "box")

-- Master Toggle with KeyPicker and ColorPicker
local MasterToggle = ToggleBox:AddToggle("MasterToggle", {
	Text = "Master Switch",
	Default = false,
	Tooltip = "Master toggle for all features",
	Callback = function(Value)
		print("MasterToggle:", Value)
		StatusLabel:SetText("Auto-Farm: " .. (Value and '<font color="#4ade80">ON</font>' or '<font color="#ef4444">OFF</font>'))
	end,
})

MasterToggle:AddKeyPicker("MasterKeybind", {
	Text = "Master Keybind",
	Default = "RightControl",
	Mode = "Toggle",
	SyncToggleState = true,
	Callback = function(Value)
		print("KeyPicker state:", Value)
	end,
})

MasterToggle:AddColorPicker("MasterColor", {
	Default = Color3.fromRGB(88, 166, 255),
	Callback = function(Value)
		print("Color:", Value)
	end,
})

-- Checkbox
ToggleBox:AddCheckbox("ClassicCheckbox", {
	Text = "Classic Checkbox",
	Default = true,
	Tooltip = "Traditional checkbox",
	Callback = function(Value)
		print("Checkbox:", Value)
	end,
})

-- Risky toggle
ToggleBox:AddToggle("RiskyToggle", {
	Text = "Risky Feature",
	Default = false,
	Risky = true,
	Tooltip = "Red text risky toggle",
	Callback = function(Value)
		print("Risky:", Value)
	end,
})

-- Disabled toggle
local DisabledToggle = ToggleBox:AddToggle("DisabledToggle", {
	Text = "Disabled Toggle",
	Default = false,
	Disabled = true,
	DisabledTooltip = "Currently disabled",
	Callback = function(Value)
		print("Disabled:", Value)
	end,
})

ToggleBox:AddButton("Enable Disabled Toggle", function()
	DisabledToggle:SetDisabled(false)
	Library:Notify({ Title = "Enabled", Description = "Toggle is now enabled!", Time = 3 })
end)

-- Inputs
local TextInput = InputBox:AddInput("TextInput", {
	Text = "Text Input",
	Default = "Hello World",
	Placeholder = "Type something...",
	Finished = true,
	ClearTextOnFocus = false,
	AllowEmpty = false,
	EmptyReset = "Default Text",
	Tooltip = "Text input field",
	Callback = function(Value)
		print("Input:", Value)
	end,
})

InputBox:AddInput("NumberInput", {
	Text = "Numeric Input",
	Default = "100",
	Numeric = true,
	Placeholder = "Enter number...",
	Finished = true,
	Callback = function(Value)
		print("Number:", Value)
	end,
})

-- Sliders
local SpeedSlider = InputBox:AddSlider("SpeedSlider", {
	Text = "Walk Speed",
	Default = 16,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = " studs/s",
	Tooltip = "Adjust walk speed",
	Callback = function(Value)
		print("Speed:", Value)
	end,
})

InputBox:AddSlider("CompactSlider", {
	Text = "Compact Slider",
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Compact = true,
	Callback = function(Value)
		print("Compact:", Value)
	end,
})

InputBox:AddSlider("HideMaxSlider", {
	Text = "Hidden Max",
	Default = 75,
	Min = 0,
	Max = 200,
	Rounding = 0,
	HideMax = true,
	Prefix = "Level ",
	Callback = function(Value)
		print("Level:", Value)
	end,
})

-- Dropdowns
local FruitDropdown = DropdownBox:AddDropdown("FruitDropdown", {
	Text = "Select Fruit",
	Values = { "Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew" },
	Default = "Apple",
	Tooltip = "Choose your favorite fruit",
	Callback = function(Value)
		print("Fruit:", Value)
	end,
})

DropdownBox:AddDropdown("MultiDropdown", {
	Text = "Multi-Select",
	Values = { "Option A", "Option B", "Option C", "Option D", "Option E" },
	Multi = true,
	Default = { "Option A", "Option C" },
	Tooltip = "Select multiple options",
	Callback = function(Value)
		print("Multi:", Value)
	end,
})

DropdownBox:AddDropdown("SearchDropdown", {
	Text = "Searchable Dropdown",
	Values = { "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta" },
	Searchable = true,
	Tooltip = "Type to search",
	Callback = function(Value)
		print("Search:", Value)
	end,
})

DropdownBox:AddDropdown("PlayerDropdown", {
	Text = "Select Player",
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Tooltip = "Auto-populates with players",
	Callback = function(Value)
		print("Player:", Value)
	end,
})

DropdownBox:AddValueDropdown("ValueDropdown", {
	Text = "Value Dropdown",
	Values = {
		{ Text = "<font color="#ffd166">Gold</font>", Value = "gold" },
		{ Text = "<b>Silver</b>", Value = "silver" },
		{ Text = "<font color="#ff66cc">Ruby</font>", Value = "ruby" },
	},
	Default = "gold",
	Tooltip = "Rich text labels",
	Callback = function(Value)
		print("Value:", Value)
	end,
})

-- Misc
MiscBox:AddLabel("Basic label")
MiscBox:AddLabel({ Text = "Wrapped label that can span multiple lines if the text is long enough", DoesWrap = true })
MiscBox:AddSpacer(20)
MiscBox:AddDivider()
MiscBox:AddLabel("Elements above/below divider")

MiscBox:AddButton("Add Dropdown Value", function()
	FruitDropdown:AddValues("New Fruit " .. math.random(1, 999))
	Library:Notify({ Title = "Added", Description = "New value added!", Time = 2 })
end)

MiscBox:AddButton("Set Slider to 50", function()
	SpeedSlider:SetValue(50)
end)

MiscBox:AddButton("Set Input Text", function()
	TextInput:SetValue("Changed via button!")
end)

--==============================================================================
-- #5 // ADVANCED TAB - Dependencies, Keybinds, Tabboxes
--==============================================================================

local DepBox = AdvancedTab:AddLeftGroupbox("Dependencies", "git-branch")
local KeybindBox = AdvancedTab:AddRightGroupbox("Keybinds", "keyboard")

-- Dependency toggle
local DepToggle = DepBox:AddToggle("DepToggle", {
	Text = "Show Advanced Options",
	Default = false,
	Callback = function(Value)
		print("DepToggle:", Value)
	end,
})

-- DependencyBox (shows when toggle is ON)
local DepContainer = DepBox:AddDependencyBox()
DepContainer:SetupDependencies({
	{ DepToggle, true }
})
DepContainer:AddLabel("These only appear when toggle is ON")
DepContainer:AddSlider("DepSlider", {
	Text = "Hidden Slider",
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
})
DepContainer:AddInput("DepInput", {
	Text = "Hidden Input",
	Default = "Secret",
})

-- DependencyGroupbox (full groupbox conditional)
local DepGroup = DepBox:AddDependencyGroupbox()
DepGroup:SetupDependencies({
	{ DepToggle, true }
})
DepGroup:AddLabel("This entire groupbox is conditional!")
DepGroup:AddButton("Conditional Button", function()
	print("Conditional button clicked!")
end)

-- Keybinds
KeybindBox:AddLabel("KeyPicker Modes:")

local ToggleKey = KeybindBox:AddToggle("KeybindToggle", {
	Text = "Toggle Mode",
	Default = false,
})
ToggleKey:AddKeyPicker("ToggleKP", {
	Text = "Toggle",
	Default = "None",
	Mode = "Toggle",
	Callback = function(Value)
		print("Toggle key:", Value)
	end,
})

local HoldKey = KeybindBox:AddToggle("KeybindHold", {
	Text = "Hold Mode",
	Default = false,
})
HoldKey:AddKeyPicker("HoldKP", {
	Text = "Hold",
	Default = "LeftShift",
	Mode = "Hold",
	Callback = function(Value)
		print("Hold key:", Value)
	end,
})

local AlwaysKey = KeybindBox:AddToggle("KeybindAlways", {
	Text = "Always Active",
	Default = false,
})
AlwaysKey:AddKeyPicker("AlwaysKP", {
	Text = "Always",
	Default = "None",
	Mode = "Always",
	Callback = function(Value)
		print("Always key:", Value)
	end,
})

-- Tabbox (sub-tabs)
local TabboxGroup = AdvancedTab:AddLeftTabbox("Sub Tabs")
local SubTab1 = TabboxGroup:AddTab("Tab 1")
local SubTab2 = TabboxGroup:AddTab("Tab 2")

SubTab1:AddLabel("Content for Sub-Tab 1")
SubTab1:AddToggle("SubToggle1", {
	Text = "Sub-Tab 1 Toggle",
	Default = false,
})
SubTab1:AddButton("Sub-Tab 1 Button", function()
	print("Sub-tab 1 button")
end)

SubTab2:AddLabel("Content for Sub-Tab 2")
SubTab2:AddToggle("SubToggle2", {
	Text = "Sub-Tab 2 Toggle",
	Default = true,
})
SubTab2:AddSlider("SubSlider", {
	Text = "Sub-Tab Slider",
	Default = 25,
	Min = 0,
	Max = 50,
	Rounding = 0,
})

--==============================================================================
-- #6 // VISUAL TAB - Colors, Images
--==============================================================================

local ColorBox = VisualTab:AddLeftGroupbox("Color Pickers", "palette")
local ImageBox = VisualTab:AddRightGroupbox("Images", "image")

ColorBox:AddColorPicker("Color1", {
	Default = Color3.fromRGB(255, 0, 0),
	Title = "Primary Color",
	Callback = function(Value)
		print("Primary:", Value)
	end,
})

ColorBox:AddColorPicker("Color2", {
	Default = Color3.fromRGB(0, 255, 0),
	Transparency = 0.5,
	Title = "Secondary (with transparency)",
	Callback = function(Value)
		print("Secondary:", Value)
	end,
})

ImageBox:AddImage("DemoImage", {
	Image = "rbxassetid://12345678",
	Height = 150,
	ScaleType = Enum.ScaleType.Fit,
})

--==============================================================================
-- #7 // SETTINGS TAB
--==============================================================================

local ConfigLeft = SettingsTab:AddLeftGroupbox("Configuration", "save")
local ConfigRight = SettingsTab:AddRightGroupbox("Danger Zone", "alert-triangle")

ConfigLeft:AddToggle("AutoSave", {
	Text = "Auto-Save Config",
	Default = GetSaved("AutoSaveConfig", true),
	Tooltip = "Auto-save settings on change",
	Callback = function(Value)
		SetSaved("AutoSaveConfig", Value)
	end,
})

ConfigLeft:AddToggle("ShowNotifs", {
	Text = "Show Notifications",
	Default = GetSaved("ShowNotifications", true),
	Tooltip = "Enable/disable notifications",
	Callback = function(Value)
		SetSaved("ShowNotifications", Value)
	end,
})

ConfigLeft:AddDivider()

ConfigLeft:AddButton("Export Config", function()
	pcall(function()
		local json = HttpService:JSONEncode(SavedConfig)
		if setclipboard then
			setclipboard(json)
			Library:Notify({ Title = "Config Exported", Description = "Copied to clipboard!", Time = 3 })
		end
	end)
end)

ConfigLeft:AddButton("Import Config", function()
	Library:Notify({ Title = "Import", Description = "Paste JSON into console or use loadstring", Time = 3 })
end)

ConfigRight:AddLabel("⚠️ These actions cannot be undone!")
ConfigRight:AddDivider()

ConfigRight:AddButton("Reset All Settings", function()
	Library:Dialog({
		Title = "Reset All Settings?",
		Description = "This will delete ALL saved config. Cannot be undone!",
		Type = "confirm",
		Risky = true,
		Callback = function(accepted)
			if accepted then
				pcall(function()
					if delfile then delfile(CONSTANTS.Config.FILE) end
				end)
				SavedConfig = {}
				Library:Notify({ Title = "Settings Reset", Description = "All config cleared.", Time = 4 })
				task.wait(1)
				if Library and Library.Unload then Library:Unload() end
			end
		end,
	})
end)

ConfigRight:AddButton("Close All / Unload", function()
	Library:Dialog({
		Title = "Unload LRX Hub?",
		Description = "Stop all automation and close the UI.",
		Type = "confirm",
		Callback = function(accepted)
			if accepted then
				Library:Notify({ Title = "Closing...", Description = "LRX Hub shutting down.", Time = 2 })
				task.wait(0.5)
				Library:Unload()
			end
		end,
	})
end)

--==============================================================================
-- #8 // WELCOME NOTIFICATION & DYNAMIC UPDATES
--==============================================================================

task.delay(1, function()
	Library:Notify({
		Title = "LRX Hub Loaded",
		Description = "Complete API demo is ready! Explore all tabs.",
		Time = 5,
	})
end)

-- Dynamic ping update
task.spawn(function()
	while task.wait(5) do
		if PingLabel and PingLabel.SetText then
			local ping = math.random(20, 150)
			local color = ping < 50 and "#4ade80" or ping < 100 and "#fbbf24" or "#ef4444"
			PingLabel:SetText('Ping: <font color="' .. color .. '">' .. ping .. " ms</font>")
		end
	end
end)

-- Dynamic footer
Window:SetFooterText(CONSTANTS.Version.HUB .. " | Players: " .. #Players:GetPlayers())

-- Watermark
Library:SetWatermark("LRX Hub | " .. os.date("%H:%M:%S"))
Library:SetWatermarkVisibility(true)

--==============================================================================
-- #9 // ACCESSING ELEMENTS VIA GLOBAL TABLES (examples)
--==============================================================================

-- Library.Toggles["MasterToggle"]:SetValue(true)
-- Library.Options["SpeedSlider"]:SetValue(50)
-- Library.Options["FruitDropdown"]:SetValue("Banana")
-- Library.Buttons["Copy Place ID"]:SetText("New Text")
-- Library.Labels[1]:SetText("Updated Label")

Logger.Info("Hub", "Complete demo loaded successfully!")