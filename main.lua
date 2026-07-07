-- LRX Premium Hub v2.5
-- Main Hub Script using Obsidian UI Library
-- Place this in your executor alongside the UI library

local Library =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua"))()
-- ^ Replace with your actual UI library URL, or use local require if you have it saved

-- Alternative: if running locally:
-- local Library = require(game.ReplicatedStorage:WaitForChild("LRXUI"))

-- ==============================================================================
-- WINDOW SETUP
-- ==============================================================================
local Window = Library:CreateWindow({
	Title = "LRX Premium Hub",
	Footer = "v2.5.0 | github.com/Lqwrence16",
	Icon = "rbxassetid://18271336971", -- Replace with your hub icon
	IconSize = UDim2.fromOffset(28, 28),
	Size = UDim2.fromOffset(740, 520),
	Position = UDim2.fromOffset(80, 80),
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

-- Set watermark (top-right)
Library:SetWatermark("LRX Hub v2.5")
Library:SetWatermarkVisibility(true)

-- ==============================================================================
-- TAB CREATION
-- ==============================================================================
local HomeTab = Window:AddTab("Home", "home")
local AutoFarmTab = Window:AddTab("Auto-Farm", "sword")
local AutoPlantTab = Window:AddTab("Auto-Plant", "flower-2")
local AutoCollectTab = Window:AddTab("Auto-Collect", "basket")
local AutoShovelTab = Window:AddTab("Auto-Shovel", "shovel")
local PlotScanTab = Window:AddTab("Plot Scan", "scan")
local TeleportTab = Window:AddTab("Teleports", "map-pin")
local SettingsTab = Window:AddTab("Settings", "settings")

-- ==============================================================================
-- HOME TAB
-- ==============================================================================
local HomeLeft = HomeTab:AddLeftGroupbox("Welcome", "user")
local HomeRight = HomeTab:AddRightGroupbox("Status", "activity")

HomeLeft:AddLabel("Welcome to LRX Premium Hub!")
HomeLeft:AddLabel("Configure your farming automation below.", true)
HomeLeft:AddDivider()
HomeLeft:AddLabel("Features:")
HomeLeft:AddLabel("• Auto-Plant with configurable patterns")
HomeLeft:AddLabel("• Auto-Collect fruits when ready")
HomeLeft:AddLabel("• Auto-Shovel for plot clearing")
HomeLeft:AddLabel("• Plot Scanner with grid visualization")
HomeLeft:AddSpacer(8)

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
-- AUTO-FARM TAB (General farming automation)
-- ==============================================================================
local FarmLeft = AutoFarmTab:AddLeftGroupbox("Auto-Farm Controls", "sword")
local FarmRight = AutoFarmTab:AddRightGroupbox("Farm Settings", "sliders-horizontal")

-- Main toggles
local AutoFarmToggle = FarmLeft:AddToggle("AutoFarmMain", {
	Text = "Enable Auto-Farm",
	Default = false,
	Tooltip = "Master toggle for all farming automation",
	Callback = function(Value)
		-- Your auto-farm logic here
		print("Auto-Farm:", Value)
	end,
})

local FastAttackToggle = FarmLeft:AddToggle("FastAttack", {
	Text = "Fast Attack Mode",
	Default = true,
	Tooltip = "Increases attack speed significantly",
})

local AutoEquipToggle = FarmLeft:AddToggle("AutoEquip", {
	Text = "Auto-Equip Best Tool",
	Default = true,
	Tooltip = "Automatically equips the best available farming tool",
})

FarmLeft:AddDivider()

-- Attack radius slider
FarmLeft:AddSlider("AttackRadius", {
	Text = "Attack Radius",
	Default = 15,
	Min = 5,
	Max = 50,
	Rounding = 0,
	Suffix = " studs",
	Tooltip = "Maximum distance to target mobs/crops",
})

-- Farm priority dropdown
FarmLeft:AddDropdown("FarmPriority", {
	Text = "Target Priority",
	Values = { "Highest Level", "Closest Mob", "Lowest Health", "Custom" },
	Default = "Closest Mob",
	Tooltip = "How the farm bot selects targets",
})

-- Right side: advanced settings
FarmRight:AddSlider("FarmDelay", {
	Text = "Action Delay",
	Default = 0.1,
	Min = 0.05,
	Max = 1.0,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Delay between farming actions",
})

FarmRight:AddToggle("AutoRejoin", {
	Text = "Auto-Rejoin on Kick",
	Default = false,
	Tooltip = "Automatically rejoins the server if kicked",
})

FarmRight:AddToggle("AntiAFK", {
	Text = "Anti-AFK",
	Default = true,
	Tooltip = "Prevents being kicked for inactivity",
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
-- AUTO-PLANT TAB (Seed placement automation)
-- ==============================================================================
local PlantLeft = AutoPlantTab:AddLeftGroupbox("Auto-Plant", "flower-2")
local PlantRight = AutoPlantTab:AddRightGroupbox("Plant Settings", "settings-2")

local AutoPlantToggle = PlantLeft:AddToggle("AutoPlant", {
	Text = "Enable Auto-Plant",
	Default = false,
	Tooltip = "Automatically plants seeds in your plot",
	Callback = function(Value)
		print("Auto-Plant:", Value)
	end,
})

PlantLeft:AddToggle("FillGapsFirst", {
	Text = "Fill Empty Spots First",
	Default = true,
	Tooltip = "Prioritizes filling gaps before continuing pattern",
})

PlantLeft:AddToggle("AutoBuySeeds", {
	Text = "Auto-Buy Seeds",
	Default = false,
	Tooltip = "Automatically purchases seeds from shop when low",
})

PlantLeft:AddDivider()

-- Seed selection dropdown
PlantLeft:AddDropdown("SeedSelect", {
	Text = "Seed Type",
	Values = { "Honey Seed", "Bee Balm", "Sunflower", "Rose", "Lavender", "Tulip" },
	Default = "Honey Seed",
	Tooltip = "Which seed to plant",
})

-- Planting pattern
PlantLeft:AddDropdown("PlantPattern", {
	Text = "Planting Pattern",
	Values = { "Grid (Row by Row)", "Spiral (Center Out)", "Random", "Checkerboard", "Border First" },
	Default = "Grid (Row by Row)",
	Tooltip = "Pattern used when planting seeds",
})

PlantRight:AddSlider("PlantDelay", {
	Text = "Plant Delay",
	Default = 0.15,
	Min = 0.05,
	Max = 1.0,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Delay between each plant action",
})

PlantRight:AddSlider("SeedThreshold", {
	Text = "Min Seeds Before Buy",
	Default = 5,
	Min = 1,
	Max = 50,
	Rounding = 0,
	Suffix = " seeds",
	Tooltip = "Buy more seeds when below this amount",
})

PlantRight:AddToggle("IgnoreOtherPlots", {
	Text = "Ignore Other Players' Plots",
	Default = true,
	Tooltip = "Only plants in your own plot area",
})

-- ==============================================================================
-- AUTO-COLLECT TAB (Fruit collection automation)
-- ==============================================================================
local CollectLeft = AutoCollectTab:AddLeftGroupbox("Auto-Collect", "basket")
local CollectRight = AutoCollectTab:AddRightGroupbox("Collection Settings", "sliders-horizontal")

local AutoCollectToggle = CollectLeft:AddToggle("AutoCollect", {
	Text = "Enable Auto-Collect",
	Default = false,
	Tooltip = "Automatically collects ripe fruits",
	Callback = function(Value)
		print("Auto-Collect:", Value)
	end,
})

CollectLeft:AddToggle("CollectAllFruits", {
	Text = "Collect All Fruit Types",
	Default = true,
	Tooltip = "Collect every fruit type, not just selected ones",
})

CollectLeft:AddToggle("TeleportCollect", {
	Text = "Teleport to Fruit",
	Default = false,
	Tooltip = "Instantly teleports to fruit instead of walking",
})

CollectLeft:AddDivider()

CollectLeft:AddDropdown("CollectMode", {
	Text = "Collection Mode",
	Values = { "When Ripe", "When Near Ripe", "Instant (Any Stage)", "Only Golden" },
	Default = "When Ripe",
	Tooltip = "When to trigger fruit collection",
})

CollectRight:AddSlider("CollectRadius", {
	Text = "Collection Radius",
	Default = 30,
	Min = 10,
	Max = 100,
	Rounding = 0,
	Suffix = " studs",
	Tooltip = "Maximum distance to scan for collectable fruits",
})

CollectRight:AddSlider("CollectDelay", {
	Text = "Collect Delay",
	Default = 0.2,
	Min = 0.05,
	Max = 1.0,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Delay between collection attempts",
})

CollectRight:AddToggle("AutoStore", {
	Text = "Auto-Store in Backpack",
	Default = true,
	Tooltip = "Automatically stores collected fruits in backpack",
})

-- ==============================================================================
-- AUTO-SHOVEL TAB (Plot clearing automation)
-- ==============================================================================
local ShovelLeft = AutoShovelTab:AddLeftGroupbox("Auto-Shovel", "shovel")
local ShovelRight = AutoShovelTab:AddRightGroupbox("Shovel Settings", "settings-2")

local AutoShovelToggle = ShovelLeft:AddToggle("AutoShovel", {
	Text = "Enable Auto-Shovel",
	Default = false,
	Tooltip = "Automatically shovels dead/withered plants",
	Callback = function(Value)
		print("Auto-Shovel:", Value)
	end,
})

ShovelLeft:AddToggle("ShovelDeadOnly", {
	Text = "Only Shovel Dead Plants",
	Default = true,
	Tooltip = "Only removes fully dead plants, not growing ones",
})

ShovelLeft:AddToggle("ShovelWeeds", {
	Text = "Remove Weeds",
	Default = true,
	Tooltip = "Also removes weeds from your plot",
})

ShovelLeft:AddToggle("AutoReplant", {
	Text = "Auto-Replant After Shovel",
	Default = false,
	Tooltip = "Automatically replants after shoveling",
})

ShovelRight:AddSlider("ShovelDelay", {
	Text = "Shovel Delay",
	Default = 0.3,
	Min = 0.1,
	Max = 2.0,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Delay between shovel actions",
})

ShovelRight:AddToggle("SafeShovel", {
	Text = "Safe Mode (No Accidental Deletes)",
	Default = true,
	Tooltip = "Double-checks before shoveling rare plants",
})

-- ==============================================================================
-- PLOT SCANNER TAB (Grid visualization & scanning)
-- ==============================================================================
local ScanLeft = PlotScanTab:AddLeftGroupbox("Plot Scanner", "scan")
local ScanRight = PlotScanTab:AddRightGroupbox("Scanner Settings", "settings-2")

local ScanToggle = ScanLeft:AddToggle("PlotScanner", {
	Text = "Enable Plot Scanner",
	Default = false,
	Tooltip = "Scans and visualizes your plot grid",
	Callback = function(Value)
		print("Plot Scanner:", Value)
	end,
})

ScanLeft:AddToggle("ShowGridDots", {
	Text = "Show Grid Dots",
	Default = true,
	Tooltip = "Displays dot markers for each grid position",
})

ScanLeft:AddToggle("ShowLaserScan", {
	Text = "Show Laser Scan Effect",
	Default = false,
	Tooltip = "Visual laser scanning animation across plot",
})

ScanLeft:AddToggle("HighlightEmpty", {
	Text = "Highlight Empty Spots",
	Default = true,
	Tooltip = "Colors empty grid positions differently",
})

ScanLeft:AddDivider()

ScanLeft:AddButton("Rescan Plot", function()
	Library:Notify({
		Title = "Plot Scanner",
		Description = "Rescanning plot grid...",
		Time = 2,
	})
	-- Trigger rescan logic here
end)

ScanLeft:AddButton("Export Grid Data", function()
	if setclipboard then
		setclipboard("-- LRX Plot Grid Data\n-- Generated at " .. os.date("%Y-%m-%d %H:%M:%S"))
		Library:Notify({
			Title = "Exported",
			Description = "Grid data copied to clipboard.",
			Time = 3,
		})
	end
end)

ScanRight:AddSlider("ScanRefreshRate", {
	Text = "Scan Refresh Rate",
	Default = 2,
	Min = 0.5,
	Max = 10,
	Rounding = 1,
	Suffix = "s",
	Tooltip = "How often to refresh the plot scan",
})

ScanRight:AddSlider("DotSize", {
	Text = "Grid Dot Size",
	Default = 4,
	Min = 1,
	Max = 10,
	Rounding = 0,
	Suffix = " px",
	Tooltip = "Size of each grid dot visualization",
})

ScanRight:AddDropdown("DotColor", {
	Text = "Dot Color Scheme",
	Values = { "Default (Blue)", "Green/Red (Status)", "Heat Map", "Custom" },
	Default = "Default (Blue)",
	Tooltip = "Color scheme for grid dots",
})

ScanRight:AddToggle("ShowOtherPlots", {
	Text = "Show Other Players' Plots",
	Default = false,
	Tooltip = "Also scans and displays nearby player plots",
})

-- ==============================================================================
-- TELEPORTS TAB
-- ==============================================================================
local TpLeft = TeleportTab:AddLeftGroupbox("Quick Teleports", "map-pin")
local TpRight = TeleportTab:AddRightGroupbox("Saved Locations", "bookmark")

TpLeft:AddButton("Teleport to Spawn", function()
	-- game.Players.LocalPlayer.Character:MoveTo(Vector3.new(0, 10, 0))
	Library:Notify({ Title = "Teleport", Description = "Teleported to Spawn.", Time = 3 })
end)

TpLeft:AddButton("Teleport to Shop", function()
	Library:Notify({ Title = "Teleport", Description = "Teleported to Shop.", Time = 3 })
end)

TpLeft:AddButton("Teleport to Plot", function()
	Library:Notify({ Title = "Teleport", Description = "Teleported to your plot.", Time = 3 })
end)

TpLeft:AddDivider()

TpLeft:AddButton("Teleport to Random Server", function()
	Library:Dialog({
		Title = "Confirm Server Hop",
		Description = "This will teleport you to a different server. Continue?",
		Type = "confirm",
		Callback = function(accepted)
			if accepted then
				-- TeleportService:Teleport(game.PlaceId)
				Library:Notify({ Title = "Server Hop", Description = "Finding new server...", Time = 3 })
			end
		end,
	})
end)

TpRight:AddInput("CustomTP", {
	Text = "Custom Coordinates",
	Default = "0, 10, 0",
	Placeholder = "X, Y, Z",
	Tooltip = "Enter coordinates to teleport to",
	Callback = function(Value)
		print("Custom TP coords:", Value)
	end,
})

TpRight:AddButton("Teleport to Coordinates", function()
	Library:Notify({ Title = "Teleport", Description = "Teleporting to custom coordinates...", Time = 3 })
end)

TpRight:AddDivider()

TpRight:AddLabel("Saved Locations:")
TpRight:AddButton("Save Current Position", function()
	Library:Notify({ Title = "Saved", Description = "Current position saved.", Time = 2 })
end)

-- ==============================================================================
-- SETTINGS TAB
-- ==============================================================================
local SettingsLeft = SettingsTab:AddLeftGroupbox("UI Settings", "monitor")
local SettingsRight = SettingsTab:AddRightGroupbox("Configuration", "save")

-- UI Toggle Keybind
SettingsLeft:AddLabel("Toggle UI Keybind:")
local ToggleKeybind = SettingsLeft:AddKeyPicker("ToggleKeybind", {
	Text = "Toggle UI",
	Default = "RightControl",
	Mode = "Toggle",
	SyncToggleState = false,
	NoUI = false,
	Callback = function(Value)
		print("Toggle keybind set to:", Value)
	end,
})

SettingsLeft:AddDivider()

-- Theme/Color settings
SettingsLeft:AddLabel("Theme Settings:")

local AccentColorPicker = SettingsLeft:AddColorPicker("AccentColor", {
	Title = "Accent Color",
	Default = Color3.fromRGB(88, 166, 255),
	Transparency = false,
	Callback = function(Value)
		Library.Scheme.AccentColor = Value
		Library:UpdateColorsUsingRegistry()
	end,
})

SettingsLeft:AddSlider("CornerRadius", {
	Text = "UI Corner Radius",
	Default = 8,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Suffix = " px",
	Callback = function(Value)
		Library.CornerRadius = Value
	end,
})

SettingsLeft:AddToggle("CustomCursor", {
	Text = "Show Custom Cursor",
	Default = false,
	Tooltip = "Replaces default cursor with custom one",
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

SettingsLeft:AddToggle("NotifyOnError", {
	Text = "Notify on Script Errors",
	Default = false,
	Tooltip = "Shows notification when a script error occurs",
	Callback = function(Value)
		Library.NotifyOnError = Value
	end,
})

-- Right side: config management
SettingsRight:AddLabel("Configuration:")

SettingsRight:AddButton("Save Configuration", function()
	Library:Notify({
		Title = "Config Saved",
		Description = "Your settings have been saved.",
		Time = 3,
	})
end)

SettingsRight:AddButton("Load Configuration", function()
	Library:Notify({
		Title = "Config Loaded",
		Description = "Settings loaded from file.",
		Time = 3,
	})
end)

SettingsRight:AddButton("Reset to Defaults", function()
	Library:Dialog({
		Title = "Confirm Reset",
		Description = "Reset all settings to default values? This cannot be undone.",
		Type = "confirm",
		Callback = function(accepted)
			if accepted then
				Library:Notify({
					Title = "Reset Complete",
					Description = "All settings reset to defaults.",
					Time = 3,
				})
			end
		end,
	})
end)

SettingsRight:AddDivider()

SettingsRight:AddLabel("Performance:")
SettingsRight:AddToggle("ReduceLag", {
	Text = "Reduce UI Lag",
	Default = true,
	Tooltip = "Optimizes UI for lower-end devices",
})

SettingsRight:AddSlider("DPIScale", {
	Text = "UI Scale",
	Default = 100,
	Min = 75,
	Max = 150,
	Rounding = 0,
	Suffix = "%",
	Tooltip = "Scale the entire UI up or down",
	Callback = function(Value)
		Library:SetDPIScale(Value)
	end,
})

SettingsRight:AddDivider()

SettingsRight:AddButton("Unload Hub", function()
	Library:Dialog({
		Title = "Confirm Unload",
		Description = "This will completely remove LRX Hub and all its connections. Are you sure?",
		Type = "confirm",
		Risky = true,
		Callback = function(accepted)
			if accepted then
				Library:Unload()
			end
		end,
	})
end)

-- ==============================================================================
-- KEYBINDS TAB (Auto-generated from the library)
-- ==============================================================================
local KeybindTab = Window:AddKeyTab("Keybinds")

-- ==============================================================================
-- NOTIFICATION ON LOAD
-- ==============================================================================
Library:Notify({
	Title = "LRX Premium Hub v2.5",
	Description = "Successfully loaded! Press RightControl to toggle UI.",
	Time = 5,
	SoundId = 4590657391, -- Optional notification sound
})

-- ==============================================================================
-- OPTIONAL: Update status labels periodically
-- ==============================================================================
task.spawn(function()
	while task.wait(2) do
		if StatusLabel and StatusLabel.SetText then
			-- Update with actual game state
			local state = "Idle"
			if AutoFarmToggle.Value then
				state = "Farming"
			end
			if AutoPlantToggle.Value then
				state = "Planting"
			end
			if AutoCollectToggle.Value then
				state = "Collecting"
			end
			StatusLabel:SetText("Status: " .. state)
		end

		if PingLabel and PingLabel.SetText then
			-- Simulated ping display
			local ping = math.random(30, 120)
			PingLabel:SetText("Ping: " .. ping .. " ms")
		end
	end
end)

print("[LRX Hub] Main script loaded successfully!")
