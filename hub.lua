local LRXUI =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua"))()

-- 2. Create main window container
local HubWindow = LRXUI.CreateWindow({
	Title = "LRX Premium Hub v2.5",
	SubTitle = "2.5.0",
	Footer = "v2.5.0",
	Size = UDim2.fromOffset(720, 480),
	Theme = "DarkSlate",
})

-- Override accent color for branding
LRXUI.Palette.Accent = Color3.fromRGB(88, 166, 255)
LRXUI.ApplyTheme()

-- 4. Establish Hub Navigation Pages
local HomePage = HubWindow:AddPage({ Name = "Home", Icon = "home" })
local FarmPage = HubWindow:AddPage({ Name = "Auto-Farm", Icon = "sword" })
local TeleportPage = HubWindow:AddPage({ Name = "Teleports", Icon = "map-pin" })
local SettingsPage = HubWindow:AddPage({ Name = "Settings", Icon = "settings" })

-- ==============================================================================
-- 1. HOME / DASHBOARD PAGE
-- ==============================================================================
local WelcomeCard = HomePage:AddCard({ Title = "Welcome" })
WelcomeCard:AddLabel({ Text = "Welcome to LRX Hub! Customize and configure your experience." })

local StatusCard = HomePage:AddCard({ Title = "Status & Telemetry" })
StatusCard:AddLabel({ Text = "Client Status: Active" })

WelcomeCard:AddButton({
	Text = "Test Notification",
	Callback = function()
		HubWindow:Notify({
			Title = "LRX Notification",
			Text = "Connection verified and handshakes are fully active!",
			Duration = 5,
		})
	end,
})

-- ==============================================================================
-- 2. AUTO-FARM PAGE
-- ==============================================================================
local FarmingCard = FarmPage:AddCard({ Title = "Automated Farmers" })

FarmingCard:AddToggle({
	Text = "Enable Auto-Farm",
	Default = false,
	Callback = function(state)
		if state then
			HubWindow:Notify({ Title = "Auto-Farm", Text = "Automated farming routines started.", Duration = 3 })
		else
			HubWindow:Notify({ Title = "Auto-Farm", Text = "Automated farming routines paused.", Duration = 3 })
		end
	end,
})

FarmingCard:AddToggle({
	Text = "Fast Attack Mode",
	Default = true,
	Callback = function(state)
		print("Fast Attack:", state)
	end,
})

FarmingCard:AddSlider({
	Text = "Attack Radius",
	Min = 5,
	Max = 50,
	Default = 15,
	Suffix = " studs",
	Callback = function(value)
		print("Attack radius set to: " .. tostring(value))
	end,
})

FarmingCard:AddDropdown({
	Text = "Farm Priority",
	Values = { "Highest Level", "Closest Mob", "Lowest Health" },
	Callback = function(selected)
		HubWindow:Notify({
			Title = "Farm Priority",
			Text = "Target priority changed to: " .. tostring(selected),
			Duration = 3,
		})
	end,
})

-- ==============================================================================
-- 3. TELEPORTS PAGE
-- ==============================================================================
local TpCard = TeleportPage:AddCard({ Title = "Quick Teleports" })

TpCard:AddButton({
	Text = "Teleport to Main City",
	Callback = function()
		HubWindow:Confirm({
			Title = "Confirm Teleport",
			Text = "Are you sure you want to teleport to Main City? (Will cancel active quest)",
			OnConfirm = function()
				HubWindow:Notify({ Title = "Teleport", Text = "Teleporting to Main City...", Duration = 3 })
			end,
		})
	end,
})

TpCard:AddButton({
	Text = "Teleport to Dungeon",
	Callback = function()
		HubWindow:Notify({ Title = "Teleport", Text = "Teleporting to Dungeon...", Duration = 3 })
	end,
})

-- ==============================================================================
-- 4. SETTINGS PAGE
-- ==============================================================================
local ConfigCard = SettingsPage:AddCard({ Title = "UI & Performance" })

ConfigCard:AddKeybind({
	Text = "Toggle UI Key",
	Default = "RightControl",
	Callback = function()
		HubWindow:Toggle()
	end,
})

ConfigCard:AddColorPicker({
	Title = "Custom Accent",
	Default = Color3.fromRGB(88, 166, 255),
	Callback = function(newColor)
		LRXUI.Palette.Accent = newColor
		LRXUI.ApplyTheme()
		HubWindow:Notify({ Title = "Theme Manager", Text = "Accent color successfully updated!", Duration = 2 })
	end,
})

ConfigCard:AddSeparator()

ConfigCard:AddButton({
	Text = "Unload Library & UI",
	Callback = function()
		HubWindow:Confirm({
			Title = "Confirm Unload",
			Text = "This will completely destroy all active frames, UI connections, and clean up the heap.",
			OnConfirm = function()
				LRXUI.Unload()
			end,
		})
	end,
})

-- Set initial status
HubWindow:SetStatus("LRX premium active and loaded successfully")
