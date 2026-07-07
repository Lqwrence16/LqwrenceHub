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
	Footer = "v2.5.0",
	Icon = "rbxassetid://18271336971", -- Replace with your hub icon
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

print("[LRX Hub] Main script loaded successfully!")
