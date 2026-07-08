local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "LRX_Hub_Config.json"

--==============================================================================
-- CLEANUP FIRST (VERY IMPORTANT)
--==============================================================================

local function Cleanup()
	pcall(function()
		local Players = game:GetService("Players")
		local CoreGui = game:GetService("CoreGui")
		local LocalPlayer = Players.LocalPlayer

		-- Proper unload
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
		_G.FastAttackEnabled = nil
		_G.AutoEquipEnabled = nil
		_G.AutoRejoinEnabled = nil
		_G.AntiAFKEnabled = nil

		local Targets = {
			"Obsidian",
			"ObsidanModal",
			"LRXUI",
			"LRXUI_Modal",
		}

		local function DestroyFrom(parent)
			if not parent then
				return
			end

			for _, v in ipairs(parent:GetChildren()) do
				if table.find(Targets, v.Name) then
					pcall(function()
						v:Destroy()
					end)
				end
			end
		end

		if LocalPlayer then
			DestroyFrom(LocalPlayer:FindFirstChild("PlayerGui"))
		end

		DestroyFrom(CoreGui)

		task.wait(0.15)
	end)
end

Cleanup()

--==============================================================================
-- CACHE
--==============================================================================

local CACHE_FOLDER = "LRXHUB67/cache"
local CACHE_FILE = CACHE_FOLDER .. "/LRXUI.lua"
local VERSION_FILE = CACHE_FOLDER .. "/LRXUI.version"

local UI_URL = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua"

local VERSION_URL = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.version"

if makefolder and not isfolder(CACHE_FOLDER) then
	makefolder("LRXHUB67")
	makefolder(CACHE_FOLDER)
end

local function Read(path)
	if isfile and isfile(path) then
		local ok, data = pcall(readfile, path)
		if ok then
			return data
		end
	end
end

local function Write(path, data)
	if writefile then
		pcall(writefile, path, data)
	end
end

local function Download(url)
	local ok, data = pcall(function()
		return game:HttpGet(url, true)
	end)

	if ok then
		return data
	end
end

local CachedUI = Read(CACHE_FILE)
local CachedVersion = Read(VERSION_FILE)
local LatestVersion = Download(VERSION_URL)

local NeedDownload = not CachedUI or not CachedVersion or (LatestVersion and LatestVersion ~= CachedVersion)

if NeedDownload then
	print("[LRX Cache] Updating cache...")

	local NewUI = Download(UI_URL)

	if NewUI and #NewUI > 100 then
		CachedUI = NewUI

		Write(CACHE_FILE, NewUI)
		Write(VERSION_FILE, LatestVersion or "unknown")

		print("[LRX Cache] Cache updated.")
	elseif not CachedUI then
		error("Unable to download LRXUI.")
	else
		warn("[LRX Cache] Using previous cache.")
	end
else
	print("[LRX Cache] Using cached LRXUI (" .. CachedVersion .. ")")
end

--==============================================================================
-- LOAD LIBRARY
--==============================================================================

assert(CachedUI, "Missing cached UI")

local Chunk, CompileError = loadstring(CachedUI)

assert(Chunk, CompileError)

local Success, Result = xpcall(Chunk, debug.traceback)

if not Success then
	error(Result)
end

assert(type(Result) == "table", "LRXUI didn't return a library.")

local Library = Result

getgenv().Library = Library

print("[LRX Hub] Library loaded successfully.")

-- ==============================================================================
-- CONFIG PERSISTENCE
-- ==============================================================================
local SavedConfig = {}
pcall(function()
	if readfile and isfile and isfile(CONFIG_FILE) then
		SavedConfig = HttpService:JSONDecode(readfile(CONFIG_FILE))
	end
end)

local function SaveConfig()
	pcall(function()
		if writefile then
			writefile(CONFIG_FILE, HttpService:JSONEncode(SavedConfig))
		end
	end)
end

local function GetSaved(key, default)
	return SavedConfig[key] ~= nil and SavedConfig[key] or default
end

local function SetSaved(key, value)
	SavedConfig[key] = value
	SaveConfig()
end

_G.LRX_Connections = _G.LRX_Connections or {}
_G.LRX_KillSwitch = false

-- ==============================================================================
-- WINDOW SETUP
-- ==============================================================================
local Window = Library:CreateWindow({
	Title = "LRX_Hub",
	Footer = "v0.0.05",
	Icon = "fan",
	IconSize = UDim2.fromOffset(28, 28),
	Size = UDim2.fromOffset(740, 520),
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

print("Window:", Window)

print("Children:", #Library.ScreenGui:GetChildren())

for _, v in ipairs(Library.ScreenGui:GetChildren()) do
	print(v.Name, v.ClassName)
end

-- ==============================================================================
-- TABS
-- ==============================================================================
local HomeTab = Window:AddTab("Home", "house", "Welcome to LRX Hub!")
local AutoFarmTab = Window:AddTab("Auto-Farm", "sword", "Automation controls for farming.")
local SettingsTab = Window:AddTab("Settings", "settings", "Configure your preferences and manage the hub.")

-- ==============================================================================
-- HOME TAB
-- ==============================================================================
local HomeLeft = HomeTab:AddLeftGroupbox("Welcome", "user")
local HomeRight = HomeTab:AddRightGroupbox("Status", "activity")

HomeLeft:AddLabel("Status: Idle")
HomeLeft:AddLabel("Ping: -- ms")

HomeRight:AddLabel("Client Info:")
HomeRight:AddLabel("Version: v2.5.0")
HomeRight:AddLabel("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
HomeRight:AddDivider()

HomeRight:AddButton("Test Notification", function()
	Library:Notify({
		Title = "LRX Hub",
		Description = "Notifications are working correctly!",
		Time = 4,
	})
end)

HomeRight:AddButton("Copy Discord", function()
	if setclipboard then
		setclipboard("discord.gg/lrxhub")
		Library:Notify({
			Title = "Copied!",
			Description = "Discord invite copied to clipboard.",
			Time = 3,
		})
	end
end)

-- ==============================================================================
-- AUTO-FARM TAB
-- ==============================================================================
local FarmLeft = AutoFarmTab:AddLeftGroupbox("Auto-Farm Controls", "sword")
local FarmRight = AutoFarmTab:AddRightGroupbox("Farm Settings", "sliders-horizontal")

FarmLeft:AddToggle("AutoFarmMain", {
	Text = "Enable Auto-Farm",
	Default = GetSaved("AutoFarm", false),
	Tooltip = "Master toggle for all farming automation",
	Callback = function(Value)
		SetSaved("AutoFarm", Value)
		_G.AutoFarmEnabled = Value
		print("Auto-Farm:", Value)
	end,
})

FarmLeft:AddToggle("FastAttack", {
	Text = "Fast Attack Mode",
	Default = GetSaved("FastAttack", true),
	Tooltip = "Increases attack speed significantly",
	Callback = function(Value)
		SetSaved("FastAttack", Value)
		_G.FastAttackEnabled = Value
	end,
})

FarmLeft:AddToggle("AutoEquip", {
	Text = "Auto-Equip Best Tool",
	Default = GetSaved("AutoEquip", true),
	Tooltip = "Automatically equips the best available farming tool",
	Callback = function(Value)
		SetSaved("AutoEquip", Value)
		_G.AutoEquipEnabled = Value
	end,
})

FarmLeft:AddDivider()

FarmLeft:AddSlider("AttackRadius", {
	Text = "Attack Radius",
	Default = GetSaved("AttackRadius", 15),
	Min = 5,
	Max = 50,
	Rounding = 0,
	Suffix = " studs",
	Tooltip = "Maximum distance to target mobs/crops",
	Callback = function(Value)
		SetSaved("AttackRadius", Value)
	end,
})

FarmLeft:AddDropdown("FarmPriority", {
	Text = "Target Priority",
	Values = { "Highest Level", "Closest Mob", "Lowest Health", "Custom" },
	Default = GetSaved("FarmPriority", "Closest Mob"),
	Tooltip = "How the farm bot selects targets",
	Callback = function(Value)
		SetSaved("FarmPriority", Value)
	end,
})

FarmRight:AddSlider("FarmDelay", {
	Text = "Action Delay",
	Default = GetSaved("FarmDelay", 0.1),
	Min = 0.05,
	Max = 1.0,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Delay between farming actions",
	Callback = function(Value)
		SetSaved("FarmDelay", Value)
	end,
})

FarmRight:AddToggle("AutoRejoin", {
	Text = "Auto-Rejoin on Kick",
	Default = GetSaved("AutoRejoin", false),
	Tooltip = "Automatically rejoins the server if kicked",
	Callback = function(Value)
		SetSaved("AutoRejoin", Value)
		_G.AutoRejoinEnabled = Value
	end,
})

FarmRight:AddToggle("AntiAFK", {
	Text = "Anti-AFK",
	Default = GetSaved("AntiAFK", true),
	Tooltip = "Prevents being kicked for inactivity",
	Callback = function(Value)
		SetSaved("AntiAFK", Value)
		_G.AntiAFKEnabled = Value
	end,
})

FarmRight:AddDivider()

FarmRight:AddButton("Reset Farm Stats", function()
	Library:Dialog({
		Title = "Confirm Reset",
		Description = "Are you sure you want to reset all farm statistics?",
		Type = "confirm",
		Callback = function(accepted)
			if accepted then
				Library:Notify({
					Title = "Reset Complete",
					Description = "All farm statistics cleared.",
					Time = 3,
				})
			end
		end,
	})
end)

-- ==============================================================================
-- SETTINGS TAB
-- ==============================================================================
local SettingsLeft = SettingsTab:AddLeftGroupbox("General Settings", "settings")
local SettingsRight = SettingsTab:AddRightGroupbox("Danger Zone", "alert-triangle")

SettingsLeft:AddToggle("ShowNotifications", {
	Text = "Show Notifications",
	Default = GetSaved("ShowNotifications", true),
	Tooltip = "Enable/disable notification toasts",
	Callback = function(Value)
		SetSaved("ShowNotifications", Value)
	end,
})

SettingsLeft:AddToggle("AutoSaveConfig", {
	Text = "Auto-Save Config",
	Default = GetSaved("AutoSaveConfig", true),
	Tooltip = "Automatically saves settings on change",
	Callback = function(Value)
		SetSaved("AutoSaveConfig", Value)
	end,
})

SettingsLeft:AddDivider()

SettingsLeft:AddButton("Export Config", function()
	pcall(function()
		local json = HttpService:JSONEncode(SavedConfig)
		if setclipboard then
			setclipboard(json)
			Library:Notify({
				Title = "Config Exported",
				Description = "Config JSON copied to clipboard!",
				Time = 3,
			})
		end
	end)
end)

SettingsRight:AddLabel("⚠️ Close All stops automation & UI.")
SettingsRight:AddLabel("Your settings are saved automatically.")
SettingsRight:AddDivider()

SettingsRight:AddButton("Close All / Stop Everything", function()
	_G.AutoFarmEnabled = false
	_G.LRX_KillSwitch = true

	if _G.LRX_Connections then
		for _, conn in ipairs(_G.LRX_Connections) do
			pcall(function()
				if conn and conn.Connected then
					conn:Disconnect()
				end
			end)
		end
		_G.LRX_Connections = {}
	end

	SaveConfig()

	Library:Notify({
		Title = "Closing LRX Hub...",
		Description = "All automation stopped. Settings saved.",
		Time = 2,
	})

	task.wait(0.1)

	pcall(function()
		local Players = game:GetService("Players")
		local CoreGui = game:GetService("CoreGui")
		local lp = Players.LocalPlayer
		local targets = { "LRXUI", "LRXUI_Modal", "Obsidian", "ObsidanModal" }

		if Library and Library.Unload then
			Library:Unload()
		end

		if lp and lp:FindFirstChild("PlayerGui") then
			for _, gui in ipairs(lp.PlayerGui:GetChildren()) do
				if table.find(targets, gui.Name) then
					gui:Destroy()
				end
			end
		end
		for _, gui in ipairs(CoreGui:GetChildren()) do
			if table.find(targets, gui.Name) then
				gui:Destroy()
			end
		end
	end)

	_G.LRX_Hub_UI = nil
	print("[LRX Hub] Fully closed. Config saved.")
end)

SettingsRight:AddDivider()

SettingsRight:AddButton("Reset All Settings", function()
	Library:Dialog({
		Title = "Reset All Settings?",
		Description = "This will delete ALL saved config. Cannot be undone!",
		Type = "confirm",
		Callback = function(accepted)
			if accepted then
				pcall(function()
					if delfile then
						delfile(CONFIG_FILE)
					end
				end)
				SavedConfig = {}
				Library:Notify({
					Title = "Settings Reset",
					Description = "All config cleared. Re-execute to load defaults.",
					Time = 4,
				})
				task.wait(1)
				if Library and Library.Unload then
					Library:Unload()
				end
			end
		end,
	})
end)

print("[LRX Hub] Main script loaded successfully!")
