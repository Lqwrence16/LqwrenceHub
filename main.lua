local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "LRX_Hub_Config.json"

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
	Title = "LRX Premium Hub",
	Footer = "v2.5.0",
	Icon = "rbxassetid://18271336971",
	IconSize = UDim2.fromOffset(28, 28),
	Size = UDim2.fromOffset(740, 520),
	Position = UDim2.fromOffset(70, 80),
	Center = false,
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
local HomeTab = Window:AddTab("Home", "house")
local AutoFarmTab = Window:AddTab("Auto-Farm", "sword")
local AutoPlantTab = Window:AddTab("Auto-Plant", "flower-2")
local AutoCollectTab = Window:AddTab("Auto-Collect", "shopping-basket")
local AutoShovelTab = Window:AddTab("Auto-Shovel", "shovel")
local PlotScanTab = Window:AddTab("Plot Scan", "scan")
local TeleportTab = Window:AddTab("Teleports", "map-pin")
local SettingsTab = Window:AddTab("Settings", "settings")

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
-- AUTO-PLANT TAB
-- ==============================================================================
local PlantLeft = AutoPlantTab:AddLeftGroupbox("Seed Controls", "flower-2")
local PlantRight = AutoPlantTab:AddRightGroupbox("Plant Settings", "sliders-horizontal")

local AutoPlantToggle = PlantLeft:AddToggle("AutoPlant", {
	Text = "Enable Auto-Plant",
	Default = GetSaved("AutoPlant", false),
	Tooltip = "Automatically plants seeds in your plot",
	Callback = function(Value)
		SetSaved("AutoPlant", Value)
		_G.AutoPlantEnabled = Value
	end,
})

local AutoSeedToggle = PlantLeft:AddToggle("AutoSeed", {
	Text = "Auto-Buy Seeds",
	Default = GetSaved("AutoSeed", false),
	Tooltip = "Automatically buys seeds when low",
	Callback = function(Value)
		SetSaved("AutoSeed", Value)
		_G.AutoSeedEnabled = Value
	end,
})

PlantLeft:AddDropdown("SeedType", {
	Text = "Seed Type",
	Values = { "Wheat", "Corn", "Carrot", "Tomato", "Pumpkin", "Watermelon" },
	Default = GetSaved("SeedType", "Wheat"),
	Callback = function(Value)
		SetSaved("SeedType", Value)
	end,
})

PlantRight:AddSlider("PlantDelay", {
	Text = "Plant Delay",
	Default = GetSaved("PlantDelay", 0.2),
	Min = 0.05,
	Max = 2.0,
	Rounding = 2,
	Suffix = "s",
	Callback = function(Value)
		SetSaved("PlantDelay", Value)
	end,
})

PlantRight:AddToggle("SmartPlant", {
	Text = "Smart Planting",
	Default = GetSaved("SmartPlant", true),
	Tooltip = "Prioritizes empty plots first",
	Callback = function(Value)
		SetSaved("SmartPlant", Value)
	end,
})

-- ==============================================================================
-- AUTO-COLLECT TAB
-- ==============================================================================
local CollectLeft = AutoCollectTab:AddLeftGroupbox("Collection Controls", "shopping-basket")
local CollectRight = AutoCollectTab:AddRightGroupbox("Collection Settings", "sliders-horizontal")

local AutoCollectToggle = CollectLeft:AddToggle("AutoCollect", {
	Text = "Enable Auto-Collect",
	Default = GetSaved("AutoCollect", false),
	Tooltip = "Automatically collects grown crops",
	Callback = function(Value)
		SetSaved("AutoCollect", Value)
		_G.AutoCollectEnabled = Value
	end,
})

CollectLeft:AddToggle("CollectFruits", {
	Text = "Collect Fruits",
	Default = GetSaved("CollectFruits", true),
	Tooltip = "Collects fruit drops",
	Callback = function(Value)
		SetSaved("CollectFruits", Value)
	end,
})

CollectLeft:AddToggle("CollectSeeds", {
	Text = "Collect Seeds",
	Default = GetSaved("CollectSeeds", true),
	Tooltip = "Collects seed drops",
	Callback = function(Value)
		SetSaved("CollectSeeds", Value)
	end,
})

CollectRight:AddSlider("CollectRadius", {
	Text = "Collection Radius",
	Default = GetSaved("CollectRadius", 20),
	Min = 5,
	Max = 100,
	Rounding = 0,
	Suffix = " studs",
	Callback = function(Value)
		SetSaved("CollectRadius", Value)
	end,
})

-- ==============================================================================
-- AUTO-SHOVEL TAB
-- ==============================================================================
local ShovelLeft = AutoShovelTab:AddLeftGroupbox("Shovel Controls", "shovel")
local ShovelRight = AutoShovelTab:AddRightGroupbox("Shovel Settings", "sliders-horizontal")

local AutoShovelToggle = ShovelLeft:AddToggle("AutoShovel", {
	Text = "Enable Auto-Shovel",
	Default = GetSaved("AutoShovel", false),
	Tooltip = "Automatically shovels dead crops",
	Callback = function(Value)
		SetSaved("AutoShovel", Value)
		_G.AutoShovelEnabled = Value
	end,
})

ShovelLeft:AddToggle("ShovelDeadOnly", {
	Text = "Dead Crops Only",
	Default = GetSaved("ShovelDeadOnly", true),
	Tooltip = "Only shovels dead/withered crops",
	Callback = function(Value)
		SetSaved("ShovelDeadOnly", Value)
	end,
})

ShovelRight:AddSlider("ShovelDelay", {
	Text = "Shovel Delay",
	Default = GetSaved("ShovelDelay", 0.3),
	Min = 0.1,
	Max = 2.0,
	Rounding = 2,
	Suffix = "s",
	Callback = function(Value)
		SetSaved("ShovelDelay", Value)
	end,
})

-- ==============================================================================
-- PLOT SCAN TAB
-- ==============================================================================
local ScanLeft = PlotScanTab:AddLeftGroupbox("Scan Controls", "scan")
local ScanRight = PlotScanTab:AddRightGroupbox("Scan Settings", "sliders-horizontal")

local PlotScanToggle = ScanLeft:AddToggle("PlotScan", {
	Text = "Enable Plot Scan",
	Default = GetSaved("PlotScan", false),
	Tooltip = "Scans and visualizes your plot grid",
	Callback = function(Value)
		SetSaved("PlotScan", Value)
		_G.PlotScanEnabled = Value
	end,
})

ScanLeft:AddToggle("ShowGrid", {
	Text = "Show Grid Dots",
	Default = GetSaved("ShowGrid", true),
	Tooltip = "Visual grid overlay on plot",
	Callback = function(Value)
		SetSaved("ShowGrid", Value)
	end,
})

ScanLeft:AddToggle("ShowLaser", {
	Text = "Laser Scan Effect",
	Default = GetSaved("ShowLaser", false),
	Tooltip = "Animated laser scan effect",
	Callback = function(Value)
		SetSaved("ShowLaser", Value)
	end,
})

ScanRight:AddSlider("ScanInterval", {
	Text = "Scan Interval",
	Default = GetSaved("ScanInterval", 5),
	Min = 1,
	Max = 30,
	Rounding = 0,
	Suffix = "s",
	Callback = function(Value)
		SetSaved("ScanInterval", Value)
	end,
})

-- ==============================================================================
-- TELEPORT TAB
-- ==============================================================================
local TeleportLeft = TeleportTab:AddLeftGroupbox("Locations", "map-pin")
local TeleportRight = TeleportTab:AddRightGroupbox("Teleport Settings", "sliders-horizontal")

TeleportLeft:AddButton("Teleport to Spawn", function()
	-- Your teleport logic
	Library:Notify({ Title = "Teleported", Description = "Moved to spawn", Time = 2 })
end)

TeleportLeft:AddButton("Teleport to Plot", function()
	-- Your teleport logic
	Library:Notify({ Title = "Teleported", Description = "Moved to your plot", Time = 2 })
end)

TeleportLeft:AddButton("Teleport to Shop", function()
	-- Your teleport logic
	Library:Notify({ Title = "Teleported", Description = "Moved to shop", Time = 2 })
end)

TeleportRight:AddToggle("AutoTeleport", {
	Text = "Auto-Teleport",
	Default = GetSaved("AutoTeleport", false),
	Tooltip = "Auto-teleports to targets",
	Callback = function(Value)
		SetSaved("AutoTeleport", Value)
		_G.AutoTeleportEnabled = Value
	end,
})

TeleportRight:AddToggle("SafeTeleport", {
	Text = "Safe Teleport",
	Default = GetSaved("SafeTeleport", true),
	Tooltip = "Checks safety before teleporting",
	Callback = function(Value)
		SetSaved("SafeTeleport", Value)
	end,
})

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
	_G.FastAttackEnabled = false
	_G.AutoEquipEnabled = false
	_G.AutoPlantEnabled = false
	_G.AutoSeedEnabled = false
	_G.AutoCollectEnabled = false
	_G.AutoShovelEnabled = false
	_G.PlotScanEnabled = false
	_G.AutoTeleportEnabled = false
	_G.AntiAFKEnabled = false
	_G.AutoRejoinEnabled = false
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
	task.wait(0.5)

	if Library and Library.Unload then
		Library:Unload()
	else
		pcall(function()
			local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
			for _, gui in ipairs(pg:GetChildren()) do
				if gui.Name == "Obsidian" or gui.Name == "ObsidanModal" then
					gui:Destroy()
				end
			end
		end)
	end

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

print("[LRX Hub] Main script loaded successfully!")
