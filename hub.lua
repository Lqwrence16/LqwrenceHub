--[[
================================================================================
    __    ____  _  ___  _   _ _   _ ___  
   / /   / __ \ | |/ / | | | | | | |_ _| 
  / /   / /_/ / |   /  | |_| | | | || |  
 / /___/ _, _/ /   |   |  _  | |_| || |  
/_____/_/ |_| /_/|_|   |_| |_|\___/|___| 
                                         
    LRX_hub.lua - The Ultimate Interactive Roblox Hub UI
    Powered by the LRXUI Core Library (LRXUI.lua)
================================================================================
]]

-- 1. Load the LRXUI Core Library
-- Developers can host LRXUI.lua on their own GitHub or load it locally:
local LRXUI =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/main.lua"))()

-- 2. Configure Themes and Aesthetics
LRXUI:SetTheme("DarkSlate") -- Choose from: "DarkSlate", "NordicFrost", "AmberGold"

-- Retrieve color scheme for custom branding overrides if desired
local colors = LRXUI:GetThemeColors()
colors.Accent = Color3.fromRGB(88, 166, 255) -- Exquisite royal accent blue

-- 3. Create main window container
local HubWindow = LRXUI:CreateWindow({
	Title = "LRX Premium Hub v2.5",
	Version = "2.5.0",
	Size = UDim2.fromOffset(720, 480),
})

-- 4. Establish Hub Navigation Pages
local HomePage = HubWindow:AddPage("Home")
local FarmPage = HubWindow:AddPage("Auto-Farm")
local TeleportPage = HubWindow:AddPage("Teleports")
local SettingsPage = HubWindow:AddPage("Settings")

-- ==============================================================================
-- 1. HOME / DASHBOARD PAGE
-- ==============================================================================
local WelcomeCard = HomePage:AddCard("Welcome")
WelcomeCard:AddLabel("Welcome to LRX Hub! Customize and configure your experience.", Enum.TextXAlignment.Left)

local SystemStatusCard = HomePage:AddCard("Status & Telemetry")
local ClientStatusLabel = SystemStatusCard:AddLabel("Client Status: Active", Enum.TextXAlignment.Left)
local ProgressTracker = SystemStatusCard:AddProgressBar("Script Sync Progress", 100)

WelcomeCard:AddButton("Test Notification", function()
	LRXUI:Notify("LRX Notification", "Connection verified and handshakes are fully active!", 5, "Success")
end)

-- ==============================================================================
-- 2. AUTO-FARM PAGE
-- ==============================================================================
local FarmingCard = FarmPage:AddCard("Automated Farmers")

FarmingCard:AddToggle("Enable Auto-Farm", false, function(state)
	if state then
		LRXUI:Notify("Auto-Farm", "Automated farming routines started.", 3, "Success")
	else
		LRXUI:Notify("Auto-Farm", "Automated farming routines paused.", 3, "Warning")
	end
end)

FarmingCard:AddToggle("Fast Attack Mode", true, function(state)
	print("Fast Attack:", state)
end)

FarmingCard:AddSlider("Attack Radius", { Min = 5, Max = 50, Default = 15, Suffix = " studs" }, function(value)
	print("Attack radius set to: " .. tostring(value))
end)

FarmingCard:AddDropdown("Farm Priority", { "Highest Level", "Closest Mob", "Lowest Health" }, function(selected)
	LRXUI:Notify("Farm Priority", "Target priority changed to: " .. selected, 3, "Success")
end)

-- ==============================================================================
-- 3. TELEPORTS PAGE
-- ==============================================================================
local TpCard = TeleportPage:AddCard("Quick Teleports")

TpCard:AddButton("Teleport to Main City", function()
	LRXUI:Prompt(
		"Confirm Teleport",
		"Are you sure you want to teleport to Main City? (Will cancel active quest)",
		function()
			LRXUI:Notify("Teleport", "Teleporting to Main City...", 3, "Success")
		end
	)
end)

TpCard:AddButton("Teleport to Dungeon", function()
	LRXUI:Notify("Teleport", "Teleporting to Dungeon...", 3, "Success")
end)

-- ==============================================================================
-- 4. SETTINGS PAGE
-- ==============================================================================
local ConfigCard = SettingsPage:AddCard("UI & Performance")

ConfigCard:AddKeybind("Toggle UI Key", Enum.KeyCode.RightControl, function()
	HubWindow:ToggleVisibility()
end)

ConfigCard:AddColorPicker("Custom Accent", Color3.fromRGB(88, 166, 255), function(newColor)
	colors.Accent = newColor
	LRXUI:Notify("Theme Manager", "Accent color successfully updated!", 2, "Success")
end)

ConfigCard:AddSeparator()

ConfigCard:AddButton("Unload Library & UI", function()
	LRXUI:Prompt(
		"Confirm Unload",
		"This will completely destroy all active frames, UI connections, and clean up the heap.",
		function()
			LRXUI:Unload()
		end
	)
end)

-- Initialize status bar at footer
HubWindow:UpdateStatus("LRX premium active and loaded successfully")
