local LRXUI =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/main.lua"))()

-- 2. Create main window container
local HubWindow = LRXUI.CreateWindow({
	Title = "LRX Premium Hub v2.5",
	SubTitle = "2.5.0",
	Footer = "v2.5.0",
	Size = UDim2.fromOffset(720, 480),
	Theme = "DarkSlate", -- Choose from: "Dark", "Light", "DarkSlate", "NordicFrost", "AmberGold"
})

-- Override accent color for branding
LRXUI.Palette.Accent = Color3.fromRGB(88, 166, 255)
LRXUI.ApplyTheme()

-- 4. Establish Hub Navigation Pages
local HomePage = HubWindow:AddPage("Home")
local FarmPage = HubWindow:AddPage("Auto-Farm")
local TeleportPage = HubWindow:AddPage("Teleports")
local SettingsPage = HubWindow:AddPage("Settings")

-- ==============================================================================
-- 1. HOME / DASHBOARD PAGE
-- ==============================================================================
local WelcomeCard = HomePage:AddCard("Welcome")
WelcomeCard:AddLabel("Welcome to LRX Hub! Customize and configure your experience.")

local StatusCard = HomePage:AddCard("Status & Telemetry")
StatusCard:AddLabel("Client Status: Active")

WelcomeCard:AddButton("Test Notification", function()
	LRXUI.Notify({
		Title = "LRX Notification",
		Text = "Connection verified and handshakes are fully active!",
		Duration = 5,
	})
end)

-- ==============================================================================
-- 2. AUTO-FARM PAGE
-- ==============================================================================
local FarmingCard = FarmPage:AddCard("Automated Farmers")

FarmingCard:AddToggle("Enable Auto-Farm", false, function(state)
	if state then
		LRXUI.Notify({ Title = "Auto-Farm", Text = "Automated farming routines started.", Duration = 3 })
	else
		LRXUI.Notify({ Title = "Auto-Farm", Text = "Automated farming routines paused.", Duration = 3 })
	end
end)

FarmingCard:AddToggle("Fast Attack Mode", true, function(state)
	print("Fast Attack:", state)
end)

FarmingCard:AddSlider("Attack Radius", { Min = 5, Max = 50, Default = 15, Suffix = " studs" }, function(value)
	print("Attack radius set to: " .. tostring(value))
end)

FarmingCard:AddDropdown("Farm Priority", { "Highest Level", "Closest Mob", "Lowest Health" }, function(selected)
	LRXUI.Notify({ Title = "Farm Priority", Text = "Target priority changed to: " .. selected, Duration = 3 })
end)

-- ==============================================================================
-- 3. TELEPORTS PAGE
-- ==============================================================================
local TpCard = TeleportPage:AddCard("Quick Teleports")

TpCard:AddButton("Teleport to Main City", function()
	HubWindow:Confirm({
		Title = "Confirm Teleport",
		Text = "Are you sure you want to teleport to Main City? (Will cancel active quest)",
		OnConfirm = function()
			LRXUI.Notify({ Title = "Teleport", Text = "Teleporting to Main City...", Duration = 3 })
		end,
	})
end)

TpCard:AddButton("Teleport to Dungeon", function()
	LRXUI.Notify({ Title = "Teleport", Text = "Teleporting to Dungeon...", Duration = 3 })
end)

-- ==============================================================================
-- 4. SETTINGS PAGE
-- ==============================================================================
local ConfigCard = SettingsPage:AddCard("UI & Performance")

ConfigCard:AddKeybind("Toggle UI Key", Enum.KeyCode.RightControl, function()
	HubWindow:Toggle()
end)

ConfigCard:AddColorPicker("Custom Accent", Color3.fromRGB(88, 166, 255), function(newColor)
	LRXUI.Palette.Accent = newColor
	LRXUI.ApplyTheme()
	LRXUI.Notify({ Title = "Theme Manager", Text = "Accent color successfully updated!", Duration = 2 })
end)

ConfigCard:AddSeparator()

ConfigCard:AddButton("Unload Library & UI", function()
	HubWindow:Confirm({
		Title = "Confirm Unload",
		Text = "This will completely destroy all active frames, UI connections, and clean up the heap.",
		OnConfirm = function()
			LRXUI.Unload()
		end,
	})
end)

-- Set initial status
HubWindow:SetStatus("LRX premium active and loaded successfully")
