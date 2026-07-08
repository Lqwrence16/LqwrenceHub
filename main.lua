local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "LRX_Hub_Config.json"

-- ==============================================================================
-- HARD RESET / CLEANUP (run this first to clear any previous session)
-- ==============================================================================
pcall(function()
	-- Clear old Library from global environment
	if getgenv and getgenv().Library then
		-- Try to unload properly
		if getgenv().Library.Unload then
			getgenv().Library.Unload()
		end
		getgenv().Library = nil
	end

	-- Clear _G references
	_G.LRX_Hub_UI = nil
	_G.LRX_Connections = nil
	_G.LRX_KillSwitch = nil
	_G.AutoFarmEnabled = nil
	_G.FastAttackEnabled = nil
	_G.AutoEquipEnabled = nil
	_G.AutoRejoinEnabled = nil
	_G.AntiAFKEnabled = nil

	-- Destroy any existing UI instances
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")
	local lp = Players.LocalPlayer

	local targets = { "LRXUI", "LRXUI_Modal", "Obsidian", "ObsidanModal" }

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

	-- Small delay to let destruction propagate
	task.wait(0.1)
end)
-- ==============================================================================
-- CONFIG PERSISTENCE SYSTEM
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
	if SavedConfig[key] ~= nil then
		return SavedConfig[key]
	end
	return default
end

local function SetSaved(key, value)
	SavedConfig[key] = value
	SaveConfig()
end

-- Global connection storage for cleanup
_G.LRX_Connections = _G.LRX_Connections or {}
_G.LRX_KillSwitch = false

-- ==============================================================================
-- UI LIBRARY
-- ==============================================================================
local Library =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua"))()

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

-- ==============================================================================
-- TAB CREATION
-- ==============================================================================
local HomeTab = Window:AddTab("Home", "house", "Welcome to LRX Hub!")
local AutoFarmTab = Window:AddTab("Auto-Farm", "sword", "Automation controls for farming.")
local SettingsTab = Window:AddTab("Settings", "settings", "Configure your preferences and manage the hub.")
-- ==============================================================================
-- HOME TAB
-- ==============================================================================
local HomeLeft = HomeTab:AddLeftGroupbox("Welcome", "user")
local HomeRight = HomeTab:AddRightGroupbox("Status", "activity")

local StatusLabel = HomeLeft:AddLabel("Status: Idle")
local PingLabel = HomeLeft:AddLabel("Ping: -- ms")

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

local AutoFarmToggle = FarmLeft:AddToggle("AutoFarmMain", {
	Text = "Enable Auto-Farm",
	Default = GetSaved("AutoFarm", false),
	Tooltip = "Master toggle for all farming automation",
	Callback = function(Value)
		SetSaved("AutoFarm", Value)
		_G.AutoFarmEnabled = Value
		print("Auto-Farm:", Value)
	end,
})

local FastAttackToggle = FarmLeft:AddToggle("FastAttack", {
	Text = "Fast Attack Mode",
	Default = GetSaved("FastAttack", true),
	Tooltip = "Increases attack speed significantly",
	Callback = function(Value)
		SetSaved("FastAttack", Value)
		_G.FastAttackEnabled = Value
	end,
})

local AutoEquipToggle = FarmLeft:AddToggle("AutoEquip", {
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
		Description = "Are you sure you want to reset all farm statistics? This cannot be undone.",
		Type = "confirm",
		Callback = function(accepted)
			if accepted then
				Library:Notify({
					Title = "Reset Complete",
					Description = "All farm statistics have been cleared.",
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

-- -- -- DANGER ZONE -- -- --
SettingsRight:AddLabel("⚠️ Close All stops automation & UI.")
SettingsRight:AddLabel("Your settings are saved automatically.")
SettingsRight:AddDivider()

SettingsRight:AddButton("Close All / Stop Everything", function()
	-- 1. STOP ALL AUTOMATION FLAGS
	_G.AutoFarmEnabled = false
	_G.LRX_KillSwitch = true

	-- 2. DISCONNECT ALL CONNECTIONS
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

	-- 3. SAVE FINAL STATE
	SaveConfig()

	-- 4. NOTIFY
	Library:Notify({
		Title = "Closing LRX Hub...",
		Description = "All automation stopped. Settings saved.",
		Time = 2,
	})

	-- 5. DESTROY UI
	task.wait(0.1)

	-- NEW CODE: Destroy ALL possible UI instances
	pcall(function()
		local Players = game:GetService("Players")
		local CoreGui = game:GetService("CoreGui")
		local lp = Players.LocalPlayer

		-- Try proper unload first
		if Library and Library.Unload then
			Library:Unload()
		end

		-- Force destroy any leftover ScreenGuis
		local targets = { "LRXUI", "LRXUI_Modal", "Obsidian", "ObsidanModal" }

		-- Check PlayerGui
		if lp and lp:FindFirstChild("PlayerGui") then
			for _, gui in ipairs(lp.PlayerGui:GetChildren()) do
				if table.find(targets, gui.Name) then
					gui:Destroy()
				end
			end
		end

		-- Check CoreGui (some executors parent here)
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
		Description = "This will delete ALL saved config. Next launch will use defaults. This cannot be undone!",
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
-- ==============================================================================
-- SETTINGS TAB-end
-- ==============================================================================

print("[LRX Hub] Main script loaded successfully!")
