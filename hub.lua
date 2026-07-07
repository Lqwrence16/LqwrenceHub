--[[
================================================================================
    __    ____  _  ___  _   _ _   _ ___  
   / /   / __ \ | |/ / | | | | | | |_ _| 
  / /   / /_/ / |   /  | |_| | | | || |  
 / /___/ _, _/ /   |   |  _  | |_| || |  
/_____/_/ |_| /_/|_|   |_| |_|\___/|___| 
                                         
    LRX_hub.lua - Recreated for the rewritten LRXUI core
================================================================================
]]

-- Load the rewritten UI library from the main script.
local LRXUI =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/main.lua"))()

-- Apply a theme and customize the accent color.
LRXUI:SetTheme("DarkSlate")
local colors = LRXUI:GetThemeColors()
colors.Accent = Color3.fromRGB(88, 166, 255)

-- Create the main window.
local HubWindow = LRXUI:CreateWindow({
	Title = "LRX Premium Hub",
})

-- Create the pages.
local HomePage = HubWindow:AddPage("Home")
local ToolsPage = HubWindow:AddPage("Tools")
local SettingsPage = HubWindow:AddPage("Settings")

-- Home page contents.
local WelcomeCard = HomePage:AddCard("Welcome")
WelcomeCard:AddLabel("Welcome to LRX Hub. This version uses the rewritten theme-driven UI.")
WelcomeCard:AddButton("Show notification", function()
	LRXUI:Notify("LRX Hub", "UI loaded successfully.", 3)
end)

-- Tools page contents.
local AutomationCard = ToolsPage:AddCard("Automation")
AutomationCard:AddLabel("Control the basic automation experience from this panel.")
AutomationCard:AddToggle("Enable automation", false, function(enabled)
	LRXUI:Notify("Automation", enabled and "Enabled" or "Disabled", 2)
end)
AutomationCard:AddSlider("Speed", 0, 100, 50, function(value)
	print("Speed:", value)
end)
AutomationCard:AddInput("Alias", "Type your name", function(value)
	print("Alias:", value)
end)
AutomationCard:AddDropdown("Mode", { "Auto", "Manual" }, function(value)
	print("Mode:", value)
end)

-- Settings page contents.
local ThemeCard = SettingsPage:AddCard("Theme")
ThemeCard:AddLabel("Switch themes to change the full UI palette.")
ThemeCard:AddButton("Cycle theme", function()
	local themes = { "DarkSlate", "NordicFrost", "AmberGold" }
	local currentIndex = table.find(themes, LRXUI.CurrentTheme) or 1
	local nextTheme = themes[(currentIndex % #themes) + 1]
	LRXUI:SetTheme(nextTheme)
end)
