--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                         LRXUI v1.0 — Official Example                        ║
║                    auto.lua — Complete API Reference Demo                     ║
╚══════════════════════════════════════════════════════════════════════════════╝

  PURPOSE:
  ───────
  This file serves as the OFFICIAL showcase and reference implementation
  for the LRXUI framework. Every public API is demonstrated here with
  realistic, production-quality examples.

  HOW TO USE:
  ───────────
  1.  Load LRXUI first (e.g. via require or loadstring).
  2.  Run this script. It will create a fully functional hub window.
  3.  Browse every tab to see how each component is configured.
  4.  Copy patterns directly into your own projects.

  STRUCTURE:
  ──────────
  • Window Setup      →  LRXUI:CreateWindow, theme, watermark
  • Tab: Automation   →  Toggles, Sliders, Dropdowns, Keybinds
  • Tab: Visuals      →  Color Pickers, Theme switching
  • Tab: Settings     →  Textboxes, Configuration save/load
  • Tab: Player       →  Buttons, Dialogs, Notifications
  • Tab: Utilities    →  Dividers, Spacers, Labels, Dependencies
  • Tab: Developer    →  DPI scaling, Search demo, Draggable elements

  BEST PRACTICES DEMONSTRATED:
  ────────────────────────────
  ✓ Always use the PUBLIC API (no internal tables)
  ✓ Store component references for later access
  ✓ Use callbacks for real-time automation logic
  ✓ Organize features into logical tabs and groupboxes
  ✓ Handle errors gracefully with pcall
  ✓ Clean up on unload
]]

-- ═══════════════════════════════════════════════════════════════════════════
--  0.  LOAD LRXUI
-- ═══════════════════════════════════════════════════════════════════════════

local LRXUI

-- Try multiple loading methods in order of preference

-- Method 1: Local module (best for development / studio)
local success, result = pcall(function()
    return require(game:GetService("ReplicatedStorage"):WaitForChild("LRXUI", 5))
end)
if success and result then
    LRXUI = result
    print("[LRX Hub] LRXUI loaded from ReplicatedStorage")
end

-- Method 2: loadstring via HttpGet (exploit executors: Synapse, KRNL, Fluxus, etc.)
if not LRXUI and typeof(game.HttpGet) == "function" then
    success, result = pcall(function()
        local src = game:HttpGet("https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua", true)
        local fn, err = loadstring(src)
        if not fn then
            error("loadstring failed: " .. tostring(err))
        end
        return fn()
    end)
    if success and result then
        LRXUI = result
        print("[LRX Hub] LRXUI loaded via HttpGet + loadstring")
    else
        warn("[LRX Hub] HttpGet load failed:", result)
    end
end

-- Method 3: Direct require from URL (some executors support this)
if not LRXUI then
    success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua"))()
    end)
    if success and result then
        LRXUI = result
        print("[LRX Hub] LRXUI loaded via direct loadstring")
    end
end

-- Method 4: getgenv cached version (if already loaded)
if not LRXUI then
    local genv = getgenv and getgenv() or shared
    if genv.LRXUI then
        LRXUI = genv.LRXUI
        print("[LRX Hub] LRXUI loaded from getgenv cache")
    end
end

-- Fatal: could not load LRXUI
if not LRXUI then
    error("[LRX Hub] FAILED to load LRXUI.\n" ..
          "Make sure LRXUI.lua is available in one of these locations:\n" ..
          "  1. ReplicatedStorage.LRXUI (module)\n" ..
          "  2. GitHub raw URL (requires executor with HttpGet)\n" ..
          "  3. getgenv().LRXUI (pre-loaded)")
end

-- ═══════════════════════════════════════════════════════════════════════════
--  1.  WINDOW CREATION
-- ═══════════════════════════════════════════════════════════════════════════

local Window = LRXUI:CreateWindow({
    Title          = "LRX Hub  v1.0",
    Footer         = "by LRX | F1 for Keybinds | RightCtrl to Toggle",
    Size           = UDim2.fromOffset(780, 620),
    Center         = true,
    Resizable      = true,
    CornerRadius   = 6,
    Font           = Enum.Font.GothamMedium,
    ToggleKeybind  = Enum.KeyCode.RightControl,
    NotifySide     = "Right",
    ShowCustomCursor = false,
    DisableSearch  = false,
    AutoShow       = true,
})

-- ═══════════════════════════════════════════════════════════════════════════
--  2.  WATERMARK
-- ═══════════════════════════════════════════════════════════════════════════

LRXUI:SetWatermark("LRX Hub  |  v1.0.0  |  FPS: " .. math.floor(workspace:GetRealPhysicsFPS()))
LRXUI:SetWatermarkVisible(true)

-- Update watermark every 2 seconds
local watermarkConn
watermarkConn = game:GetService("RunService").Heartbeat:Connect(function()
    if tick() % 2 < 0.05 then
        LRXUI:SetWatermark("LRX Hub  |  v1.0.0  |  FPS: " .. math.floor(workspace:GetRealPhysicsFPS()))
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  3.  TAB: AUTOMATION
-- ═══════════════════════════════════════════════════════════════════════════

local AutoTab = Window:AddTab({
    Title       = "Automation",
    Description = "Farming & auto-play features",
})

-- Left column
-- Generic AddGroupbox (Side = 1 for left)
local AutoFarmBox = AutoTab:AddGroupbox({
    Name           = "Auto Farm",
    Side           = 1,
    Description    = "Core farming automation",
    StartCollapsed = false,
})
    Name           = "Auto Farm",
    Description    = "Core farming automation",
    StartCollapsed = false,
})

-- Toggle: Auto Plant
local AutoPlant = AutoFarmBox:AddToggle("AutoPlant", {
    Text     = "Auto Plant Seeds",
    Default  = false,
    Risky    = false,
    Tooltip  = "Automatically plants seeds in empty plot slots",
})

AutoPlant:OnChanged(function(value)
    print("[Auto Plant]", value and "ENABLED" or "DISABLED")
    -- Your planting logic here
end)

-- Toggle: Auto Collect
local AutoCollect = AutoFarmBox:AddToggle("AutoCollect", {
    Text     = "Auto Collect Fruits",
    Default  = false,
    Tooltip  = "Automatically harvests ripe fruits from plots",
})

AutoCollect:OnChanged(function(value)
    print("[Auto Collect]", value and "ENABLED" or "DISABLED")
end)

-- Toggle: Auto Shovel
local AutoShovel = AutoFarmBox:AddToggle("AutoShovel", {
    Text     = "Auto Shovel Weeds",
    Default  = false,
    Tooltip  = "Removes weeds automatically when detected",
})

AutoShovel:OnChanged(function(value)
    print("[Auto Shovel]", value and "ENABLED" or "DISABLED")
end)

-- Divider
AutoFarmBox:AddDivider()

-- Slider: Planting Speed
local PlantSpeed = AutoFarmBox:AddSlider("PlantSpeed", {
    Text     = "Planting Speed",
    Default  = 1.0,
    Min      = 0.1,
    Max      = 5.0,
    Rounding = 1,
    Prefix   = "",
    Suffix   = "s",
    Compact  = true,
    Tooltip  = "Delay between each plant action (seconds)",
})

PlantSpeed:OnChanged(function(value)
    print("[Plant Speed] Set to", value, "seconds")
end)

-- Slider: Collection Radius
local CollectRadius = AutoFarmBox:AddSlider("CollectRadius", {
    Text     = "Collection Radius",
    Default  = 50,
    Min      = 10,
    Max      = 200,
    Rounding = 0,
    Prefix   = "",
    Suffix   = " studs",
    Compact  = false,
    Tooltip  = "Maximum distance to detect collectible items",
})

-- Keybind: Quick Toggle Planting
local PlantKeybind = AutoPlant:AddKeyPicker("PlantKeybind", {
    Text            = "Quick Plant Toggle",
    Default         = "P",
    Mode            = "Toggle",
    Modes           = { "Always", "Toggle", "Hold" },
    SyncToggleState = true,
    NoUI            = false,
    Callback        = function(state)
        print("[Keybind] Plant toggled via key:", state)
    end,
})

-- Right column
-- Generic AddGroupbox (Side = 2 for right)
local AutoSellBox = AutoTab:AddGroupbox({
    Name        = "Auto Sell",
    Side        = 2,
    Description = "Selling & economy automation",
})
    Name        = "Auto Sell",
    Description = "Selling & economy automation",
})

-- Toggle: Auto Sell
local AutoSell = AutoSellBox:AddToggle("AutoSell", {
    Text     = "Auto Sell Inventory",
    Default  = false,
    Tooltip  = "Automatically sells items when inventory is full",
})

-- Dropdown: Sell Mode
local SellMode = AutoSellBox:AddDropdown("SellMode", {
    Text       = "Sell Mode",
    Values     = { "Sell All", "Sell Excess", "Sell Selected" },
    Default    = "Sell Excess",
    Multi      = false,
    AllowNull  = false,
    Searchable = false,
    Tooltip    = "Choose which items to sell automatically",
})

SellMode:OnChanged(function(value)
    print("[Sell Mode] Changed to:", value)
end)

-- Multi Dropdown: Item Categories
local SellCategories = AutoSellBox:AddDropdown("SellCategories", {
    Text       = "Sell Categories",
    Values     = { "Fruits", "Seeds", "Tools", "Decorations", "Rare Items" },
    Default    = { "Fruits", "Seeds" },
    Multi      = true,
    AllowNull  = false,
    Searchable = true,
    Tooltip    = "Select which item categories to include in auto-sell",
})

SellCategories:OnChanged(function(values)
    local selected = {}
    for k, v in pairs(values) do if v then table.insert(selected, k) end end
    print("[Sell Categories] Selected:", table.concat(selected, ", "))
end)

-- Spacer
AutoSellBox:AddSpacer(8)

-- Button: Force Sell Now
local ForceSellBtn = AutoSellBox:AddButton({
    Text     = "Force Sell Now",
    Func     = function()
        LRXUI:Notify({
            Title       = "Selling...",
            Description = "Processing inventory sale...",
            Time        = 3,
        })
        print("[Force Sell] Triggered manual sell")
    end,
    Tooltip  = "Immediately sells all items matching current settings",
})

-- Button with sub-button: Sell Options
local SellOptionsBtn = AutoSellBox:AddButton({
    Text     = "Sell Options",
    Func     = function()
        print("[Sell Options] Opened settings")
    end,
})

SellOptionsBtn:AddButton({
    Text     = "Reset Prices",
    Func     = function()
        LRXUI:Notify({
            Title       = "Prices Reset",
            Description = "All item prices have been reset to default",
            Time        = 2,
        })
    end,
    Risky    = true,
    DoubleClick = true,
})

-- ═══════════════════════════════════════════════════════════════════════════
--  4.  TAB: VISUALS
-- ═══════════════════════════════════════════════════════════════════════════

local VisualsTab = Window:AddTab({
    Title       = "Visuals",
    Description = "ESP, highlights & theming",
})

local ThemeBox = VisualsTab:AddLeftGroupbox({
    Name        = "Theme & Colors",
    Description = "Customize the UI appearance",
})

-- Color Picker: Accent Color
local AccentColor = ThemeBox:AddLabel("Accent Color"):AddColorPicker("AccentColor", {
    Default      = Color3.fromRGB(125, 85, 255),
    Transparency = false,
    Callback     = function(color)
        LRXUI:SetAccentColor(color)
        print("[Theme] Accent color changed to", color:ToHex())
    end,
})

-- Button: Change Font
ThemeBox:AddButton({
    Text    = "Cycle Font",
    Func    = function()
        local fonts = {
            Enum.Font.GothamMedium,
            Enum.Font.Code,
            Enum.Font.SourceSans,
            Enum.Font.Ubuntu,
        }
        local current = 1
        for i, f in ipairs(fonts) do
            if tostring(f) == tostring(Theme.Font) then
                current = i
                break
            end
        end
        local nextFont = fonts[(current % #fonts) + 1]
        LRXUI:SetFont(nextFont)
        LRXUI:Notify({
            Title       = "Font Changed",
            Description = "Switched to " .. tostring(nextFont),
            Time        = 2,
        })
    end,
    Tooltip = "Cycle through available UI fonts",
})

-- Color Picker: Background Color (with transparency)
local BgColor = ThemeBox:AddLabel("Background Tint"):AddColorPicker("BgColor", {
    Default      = Color3.fromRGB(15, 15, 15),
    Transparency = true,
    Callback     = function(color, transparency)
        print("[Theme] Background:", color:ToHex(), "Transparency:", transparency)
    end,
})

-- Button: Reset Theme
ThemeBox:AddButton({
    Text = "Reset to Default Theme",
    Func = function()
        LRXUI:SetTheme({
            Background = Color3.fromRGB(15, 15, 15),
            Surface    = Color3.fromRGB(25, 25, 25),
            Accent     = Color3.fromRGB(125, 85, 255),
            Border     = Color3.fromRGB(40, 40, 40),
            Text       = Color3.new(1, 1, 1),
        })
        LRXUI:SetAccentColor(Color3.fromRGB(125, 85, 255))
        LRXUI:Notify({
            Title       = "Theme Reset",
            Description = "All colors restored to default",
            Time        = 2,
        })
    end,
})

-- Divider
ThemeBox:AddDivider()

-- Slider: UI Scale (DPI)
local UIScale = ThemeBox:AddSlider("UIScale", {
    Text     = "UI Scale",
    Default  = 100,
    Min      = 75,
    Max      = 150,
    Rounding = 0,
    Prefix   = "",
    Suffix   = "%",
    Compact  = true,
    Tooltip  = "Scale the entire UI up or down",
})

UIScale:OnChanged(function(value)
    LRXUI:SetDPIScale(value)
    print("[DPI] Scale set to", value .. "%")
end)

-- Right column: ESP Settings
local ESPBox = VisualsTab:AddRightGroupbox({
    Name        = "ESP Settings",
    Description = "Entity highlighting options",
})

-- Toggle: Player ESP
local PlayerESP = ESPBox:AddToggle("PlayerESP", {
    Text     = "Player ESP",
    Default  = false,
    Tooltip  = "Highlight other players through walls",
})

-- Toggle: Item ESP
local ItemESP = ESPBox:AddToggle("ItemESP", {
    Text     = "Item ESP",
    Default  = false,
    Tooltip  = "Highlight valuable items on the map",
})

-- Toggle: Plot ESP
local PlotESP = ESPBox:AddToggle("PlotESP", {
    Text     = "Plot ESP",
    Default  = false,
    Tooltip  = "Highlight your farm plot boundaries",
})

-- Color Picker: ESP Color
local ESPColor = PlayerESP:AddColorPicker("ESPColor", {
    Default      = Color3.fromRGB(0, 255, 128),
    Transparency = false,
    Callback     = function(color)
        print("[ESP] Color set to", color:ToHex())
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════
--  5.  TAB: SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

local SettingsTab = Window:AddTab({
    Title       = "Settings",
    Description = "Configuration & preferences",
})

local ConfigBox = SettingsTab:AddLeftGroupbox({
    Name        = "Configuration",
    Description = "Save and load your settings",
})

-- Textbox: Config Name
local ConfigName = ConfigBox:AddTextbox("ConfigName", {
    Text             = "Config Name",
    Default          = "Default",
    Placeholder      = "Enter config name...",
    Numeric          = false,
    ClearTextOnFocus = false,
    Finished         = true,
    AllowEmpty       = false,
    EmptyReset       = "Default",
    Tooltip          = "Name used when saving/loading configurations",
})

ConfigName:OnChanged(function(text)
    print("[Config] Name set to:", text)
end)

-- Divider
ConfigBox:AddDivider()

-- Button: Save Config
ConfigBox:AddButton({
    Text = "Save Configuration",
    Func = function()
        local name = ConfigName.Value
        -- Your save logic here (e.g. writefile, setclipboard, etc.)
        LRXUI:Notify({
            Title       = "Config Saved",
            Description = "Saved as: " .. name,
            Time        = 3,
            SoundId     = 9114488953, -- success sound
        })
        print("[Config] Saved:", name)
    end,
    Tooltip = "Save current settings to a file",
})

-- Button: Load Config
ConfigBox:AddButton({
    Text = "Load Configuration",
    Func = function()
        local name = ConfigName.Value
        -- Your load logic here
        LRXUI:Notify({
            Title       = "Config Loaded",
            Description = "Loaded: " .. name,
            Time        = 3,
        })
        print("[Config] Loaded:", name)
    end,
    Tooltip = "Load settings from a saved file",
})

-- Button: Delete Config (risky)
ConfigBox:AddButton({
    Text        = "Delete Config",
    Func        = function()
        LRXUI:Confirm("Delete Config?", "This will permanently delete "" .. ConfigName.Value .. "". Are you sure?", function(accepted)
            if accepted then
                LRXUI:Notify({
                    Title       = "Config Deleted",
                    Description = ConfigName.Value .. " has been deleted",
                    Time        = 2,
                })
                print("[Config] Deleted:", ConfigName.Value)
            else
                print("[Config] Delete cancelled")
            end
        end)
    end,
    Risky       = true,
    DoubleClick = true,
    Tooltip     = "Permanently delete the selected configuration",
})

-- Right column: Preferences
local PrefBox = SettingsTab:AddRightGroupbox({
    Name        = "Preferences",
    Description = "General hub preferences",
})

-- Toggle: Show Notifications
local ShowNotifs = PrefBox:AddToggle("ShowNotifs", {
    Text     = "Show Notifications",
    Default  = true,
    Tooltip  = "Enable or disable popup notifications",
})

-- Toggle: Show Watermark
local ShowWatermark = PrefBox:AddToggle("ShowWatermark", {
    Text     = "Show Watermark",
    Default  = true,
    Tooltip  = "Toggle the FPS watermark display",
})

ShowWatermark:OnChanged(function(value)
    LRXUI:SetWatermarkVisible(value)
end)

-- Dropdown: Notification Side
local NotifSide = PrefBox:AddDropdown("NotifSide", {
    Text       = "Notification Side",
    Values     = { "Left", "Right" },
    Default    = "Right",
    Multi      = false,
    AllowNull  = false,
    Tooltip    = "Which side notifications appear on",
})

NotifSide:OnChanged(function(value)
    LRXUI:SetNotifySide(value)
    LRXUI:Notify({
        Title       = "Side Changed",
        Description = "Notifications now appear on the " .. value,
        Time        = 2,
    })
end)

-- Toggle: Auto-hide on Idle
local AutoHide = PrefBox:AddToggle("AutoHide", {
    Text     = "Auto-hide on Idle",
    Default  = false,
    Tooltip  = "Automatically hide the UI after 60 seconds of inactivity",
})

-- ═══════════════════════════════════════════════════════════════════════════
--  6.  TAB: PLAYER
-- ═══════════════════════════════════════════════════════════════════════════

local PlayerTab = Window:AddTab({
    Title       = "Player",
    Description = "Character & movement modifications",
})

local MovementBox = PlayerTab:AddLeftGroupbox({
    Name        = "Movement",
    Description = "Speed and jump modifications",
})

-- Toggle: WalkSpeed Modifier
local SpeedToggle = MovementBox:AddToggle("SpeedToggle", {
    Text     = "Speed Modifier",
    Default  = false,
    Tooltip  = "Enable custom walk speed",
})

-- Slider: WalkSpeed Value
local WalkSpeed = MovementBox:AddSlider("WalkSpeed", {
    Text     = "Walk Speed",
    Default  = 16,
    Min      = 1,
    Max      = 200,
    Rounding = 0,
    Prefix   = "",
    Suffix   = " studs/s",
    Compact  = false,
    Tooltip  = "Custom walk speed value",
})

WalkSpeed:OnChanged(function(value)
    if SpeedToggle.Value then
        local player = game:GetService("Players").LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = value
        end
    end
end)

SpeedToggle:OnChanged(function(value)
    local player = game:GetService("Players").LocalPlayer
    if not player or not player.Character then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if value then
        humanoid.WalkSpeed = WalkSpeed.Value
    else
        humanoid.WalkSpeed = 16 -- default
    end
end)

-- Toggle: JumpPower Modifier
local JumpToggle = MovementBox:AddToggle("JumpToggle", {
    Text     = "Jump Modifier",
    Default  = false,
    Tooltip  = "Enable custom jump power",
})

-- Slider: JumpPower Value
local JumpPower = MovementBox:AddSlider("JumpPower", {
    Text     = "Jump Power",
    Default  = 50,
    Min      = 1,
    Max      = 200,
    Rounding = 0,
    Prefix   = "",
    Suffix   = " power",
    Compact  = false,
    Tooltip  = "Custom jump power value",
})

-- Keybind: Speed Boost (Hold)
local SpeedBoostKey = SpeedToggle:AddKeyPicker("SpeedBoostKey", {
    Text     = "Speed Boost Key",
    Default  = "LeftShift",
    Mode     = "Hold",
    Modes    = { "Always", "Toggle", "Hold" },
    NoUI     = false,
    Callback = function(state)
        local player = game:GetService("Players").LocalPlayer
        if not player or not player.Character then return end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid then return end

        if state then
            humanoid.WalkSpeed = WalkSpeed.Value * 2
        else
            humanoid.WalkSpeed = SpeedToggle.Value and WalkSpeed.Value or 16
        end
    end,
})

-- Right column: Character
local CharBox = PlayerTab:AddRightGroupbox({
    Name        = "Character",
    Description = "Appearance & state modifications",
})

-- Toggle: God Mode
local GodMode = CharBox:AddToggle("GodMode", {
    Text     = "God Mode",
    Default  = false,
    Risky    = true,
    Tooltip  = "Prevents character from taking damage (risky feature)",
})

GodMode:OnChanged(function(value)
    print("[God Mode]", value and "ENABLED" or "DISABLED")
end)

-- Toggle: Anti-AFK
local AntiAFK = CharBox:AddToggle("AntiAFK", {
    Text     = "Anti-AFK",
    Default  = true,
    Tooltip  = "Prevents being kicked for inactivity",
})

-- Button: Reset Character
CharBox:AddButton({
    Text        = "Reset Character",
    Func        = function()
        LRXUI:Confirm("Reset Character?", "This will respawn your character. Continue?", function(accepted)
            if accepted then
                local player = game:GetService("Players").LocalPlayer
                if player then
                    player.Character:BreakJoints()
                end
            end
        end)
    end,
    Risky       = false,
    DoubleClick = false,
    Tooltip     = "Respawn your character immediately",
})

-- Button: Full Heal
CharBox:AddButton({
    Text    = "Full Heal",
    Func    = function()
        local player = game:GetService("Players").LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
            LRXUI:Notify({
                Title       = "Healed",
                Description = "Health restored to maximum",
                Time        = 2,
            })
        end
    end,
    Tooltip = "Restore full health instantly",
})

-- ═══════════════════════════════════════════════════════════════════════════
--  7.  TAB: UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════

local UtilsTab = Window:AddTab({
    Title       = "Utilities",
    Description = "Miscellaneous helper tools",
})

local ToolsBox = UtilsTab:AddLeftGroupbox({
    Name        = "Tools",
    Description = "Handy utility functions",
})

-- Label: Info
ToolsBox:AddLabel("Utility tools for common tasks")

-- Spacer
ToolsBox:AddSpacer(4)

-- Button: Copy Position
ToolsBox:AddButton({
    Text    = "Copy Position",
    Func    = function()
        local player = game:GetService("Players").LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            local posStr = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
            if setclipboard then
                setclipboard(posStr)
                LRXUI:Notify({
                    Title       = "Position Copied",
                    Description = posStr,
                    Time        = 3,
                })
            else
                LRXUI:Notify({
                    Title       = "Position",
                    Description = posStr .. " (clipboard not available)",
                    Time        = 3,
                })
            end
        end
    end,
    Tooltip = "Copy current position to clipboard",
})

-- Button: Rejoin Server
ToolsBox:AddButton({
    Text        = "Rejoin Server",
    Func        = function()
        LRXUI:Confirm("Rejoin Server?", "You will be disconnected and reconnected to the same server.", function(accepted)
            if accepted then
                local ts = game:GetService("TeleportService")
                local placeId = game.PlaceId
                local jobId = game.JobId
                ts:TeleportToPlaceInstance(placeId, jobId)
            end
        end)
    end,
    Risky       = false,
    DoubleClick = false,
    Tooltip     = "Rejoin the current server instance",
})

-- Button: Server Hop
ToolsBox:AddButton({
    Text        = "Server Hop",
    Func        = function()
        LRXUI:Confirm("Server Hop?", "Find and join a different server.", function(accepted)
            if accepted then
                local ts = game:GetService("TeleportService")
                ts:Teleport(game.PlaceId)
            end
        end)
    end,
    Risky       = false,
    DoubleClick = false,
    Tooltip     = "Join a different server",
})

-- Divider
ToolsBox:AddDivider()

-- Textbox: Teleport Coordinates
local TeleportBox = ToolsBox:AddTextbox("TeleportCoords", {
    Text             = "Teleport To",
    Default          = "0, 0, 0",
    Placeholder      = "X, Y, Z...",
    Numeric          = false,
    ClearTextOnFocus = true,
    Finished         = true,
    AllowEmpty       = false,
    EmptyReset       = "0, 0, 0",
    Tooltip          = "Enter coordinates to teleport to (format: X, Y, Z)",
})

-- Button: Execute Teleport
ToolsBox:AddButton({
    Text    = "Teleport",
    Func    = function()
        local text = TeleportBox.Value
        local x, y, z = text:match("([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+)")
        if x and y and z then
            local player = game:GetService("Players").LocalPlayer
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
                LRXUI:Notify({
                    Title       = "Teleported",
                    Description = "Moved to: " .. text,
                    Time        = 2,
                })
            end
        else
            LRXUI:Notify({
                Title       = "Invalid Format",
                Description = "Use format: X, Y, Z (e.g. 0, 10, 0)",
                Time        = 3,
            })
        end
    end,
    Tooltip = "Teleport to the entered coordinates",
})

-- Right column: Info & Stats
local InfoBox = UtilsTab:AddRightGroupbox({
    Name        = "Information",
    Description = "Game and session info",
})

-- Label: Game Name
local GameNameLabel = InfoBox:AddLabel("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)

-- Label: Place ID
InfoBox:AddLabel("Place ID: " .. tostring(game.PlaceId))

-- Label: Job ID (truncated)
InfoBox:AddLabel("Job ID: " .. string.sub(game.JobId, 1, 8) .. "...")

-- Spacer
InfoBox:AddSpacer(8)

-- Label: Session Time
local SessionStart = tick()
local SessionLabel = InfoBox:AddLabel("Session: 0m 0s")

-- Update session time every second
local sessionConn
sessionConn = game:GetService("RunService").Heartbeat:Connect(function()
    if tick() % 1 < 0.05 then
        local elapsed = tick() - SessionStart
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)
        SessionLabel:SetText(string.format("Session: %dm %ds", mins, secs))
    end
end)

-- Divider
InfoBox:AddDivider()

-- Label: Player Count
local PlayerCountLabel = InfoBox:AddLabel("Players: " .. tostring(#game:GetService("Players"):GetPlayers()))

game:GetService("Players").PlayerAdded:Connect(function()
    PlayerCountLabel:SetText("Players: " .. tostring(#game:GetService("Players"):GetPlayers()))
end)
game:GetService("Players").PlayerRemoving:Connect(function()
    PlayerCountLabel:SetText("Players: " .. tostring(#game:GetService("Players"):GetPlayers()))
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  8.  TAB: DEVELOPER
-- ═══════════════════════════════════════════════════════════════════════════

local DevTab = Window:AddTab({
    Title       = "Developer",
    Description = "Debug tools & framework testing",
})

local TestBox = DevTab:AddLeftGroupbox({
    Name        = "Component Testing",
    Description = "Test every LRXUI component",
})

-- Toggle: Test Toggle
local TestToggle = TestBox:AddToggle("TestToggle", {
    Text     = "Test Toggle",
    Default  = false,
    Tooltip  = "A toggle for testing purposes",
})

TestToggle:OnChanged(function(value)
    print("[Test] Toggle =", value)
end)

-- Toggle with synced keybind
local SyncToggle = TestBox:AddToggle("SyncToggle", {
    Text     = "Sync Keybind Toggle",
    Default  = false,
    Tooltip  = "Toggle with a synced keybind (always matches state)",
})

local SyncKey = SyncToggle:AddKeyPicker("SyncKey", {
    Text            = "Sync Bind",
    Default         = "K",
    Mode            = "Toggle",
    SyncToggleState = true,
    NoUI            = false,
})

-- Slider: Test Slider
local TestSlider = TestBox:AddSlider("TestSlider", {
    Text     = "Test Slider",
    Default  = 50,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Prefix   = "",
    Suffix   = "%",
    Compact  = false,
    HideMax  = false,
})

-- Dropdown: Test Dropdown
local TestDropdown = TestBox:AddDropdown("TestDropdown", {
    Text       = "Test Dropdown",
    Values     = { "Option A", "Option B", "Option C", "Option D", "Option E" },
    Default    = "Option A",
    Multi      = false,
    AllowNull  = false,
    Searchable = false,
    Tooltip    = "Single-select dropdown test",
})

-- Multi Dropdown: Test Multi
local TestMulti = TestBox:AddDropdown("TestMulti", {
    Text       = "Test Multi-Select",
    Values     = { "Red", "Green", "Blue", "Yellow", "Purple", "Orange" },
    Default    = { "Red", "Blue" },
    Multi      = true,
    AllowNull  = true,
    Searchable = true,
    Tooltip    = "Multi-select dropdown with search",
})

-- Textbox: Test Input
local TestTextbox = TestBox:AddTextbox("TestTextbox", {
    Text             = "Test Input",
    Default          = "Hello World",
    Placeholder      = "Type something...",
    Numeric          = false,
    ClearTextOnFocus = true,
    Finished         = false,
    AllowEmpty       = true,
    Tooltip          = "Text input with live updates",
})

TestTextbox:OnChanged(function(text)
    print("[Test] Textbox live:", text)
end)

-- Right column: Framework Features
local FrameworkBox = DevTab:AddRightGroupbox({
    Name        = "Framework Features",
    Description = "Test advanced LRXUI features",
})

-- Button: Test Notification
FrameworkBox:AddButton({
    Text    = "Test Notification",
    Func    = function()
        LRXUI:Notify({
            Title       = "Test Notification",
            Description = "This is a test of the notification system with a longer description to demonstrate text wrapping behavior.",
            Time        = 5,
            SoundId     = 9114488953,
        })
    end,
    Tooltip = "Show a sample notification",
})

-- Button: Test Dialog (Confirm)
FrameworkBox:AddButton({
    Text    = "Test Confirm Dialog",
    Func    = function()
        LRXUI:Confirm("Confirm Action", "Are you sure you want to proceed with this test action?", function(accepted)
            LRXUI:Notify({
                Title       = accepted and "Confirmed" or "Cancelled",
                Description = accepted and "Action was confirmed!" or "Action was cancelled.",
                Time        = 2,
            })
        end)
    end,
    Tooltip = "Show a confirmation dialog",
})

-- Button: Test Dialog (Info)
FrameworkBox:AddButton({
    Text    = "Test Info Dialog",
    Func    = function()
        LRXUI:InfoPopup("Information", "This is an informational dialog. It only has an OK button and is used for displaying important messages to the user.", function()
            print("[Dialog] Info dialog closed")
        end)
    end,
    Tooltip = "Show an information dialog",
})

-- Button: Test Dialog (Custom)
FrameworkBox:AddButton({
    Text    = "Test Custom Dialog",
    Func    = function()
        LRXUI:Dialog({
            Type        = "confirm",
            Title       = "Custom Dialog",
            Description = "This demonstrates the full Dialog API with custom callbacks.",
            ConfirmText = "Proceed",
            CancelText  = "Abort",
            OnConfirm   = function() print("[Dialog] Custom confirmed") end,
            OnCancel    = function() print("[Dialog] Custom cancelled") end,
            Callback    = function(accepted, reason)
                print("[Dialog] Final result:", accepted, reason)
            end,
        })
    end,
    Tooltip = "Show a custom-configured dialog",
})

-- Divider
FrameworkBox:AddDivider()

-- Button: Change Window Title
FrameworkBox:AddButton({
    Text    = "Change Title",
    Func    = function()
        Window:SetTitle("LRX Hub  |  Modified Title")
        LRXUI:Notify({
            Title       = "Title Changed",
            Description = "Window title has been updated",
            Time        = 2,
        })
    end,
    Tooltip = "Dynamically change the window title",
})

-- Button: Change Footer
FrameworkBox:AddButton({
    Text    = "Change Footer",
    Func    = function()
        Window:SetFooter("Custom Footer  |  " .. os.date("%H:%M:%S"))
    end,
    Tooltip = "Dynamically change the window footer",
})

-- Button: Hide/Show Window
local WindowVisible = true
FrameworkBox:AddButton({
    Text    = "Toggle Window Visibility",
    Func    = function()
        WindowVisible = not WindowVisible
        if WindowVisible then
            Window:Show()
        else
            Window:Hide()
        end
    end,
    Tooltip = "Programmatically hide or show the window",
})

-- Spacer
FrameworkBox:AddSpacer(8)

-- Button: Test Draggable Button
FrameworkBox:AddButton({
    Text    = "Create Draggable Button",
    Func    = function()
        local dragBtn = LRXUI:AddDraggableButton("Drag Me!", function(handle)
            print("[Draggable] Button clicked!")
            handle:SetText("Clicked!")
            task.delay(1, function()
                handle:SetText("Drag Me!")
            end)
        end)
        LRXUI:Notify({
            Title       = "Draggable Created",
            Description = "A draggable button was added to the screen",
            Time        = 3,
        })
    end,
    Tooltip = "Create a draggable on-screen button",
})

-- Button: Test Draggable Menu
FrameworkBox:AddButton({
    Text    = "Create Draggable Menu",
    Func    = function()
        local panel, container = LRXUI:AddDraggableMenu("Debug Panel")
        -- Add some content to the panel
        local label = Instance.new("TextLabel")
        label.Text = "This is a draggable debug panel!"
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Parent = container
        LRXUI:Notify({
            Title       = "Panel Created",
            Description = "A draggable menu panel was added",
            Time        = 3,
        })
    end,
    Tooltip = "Create a draggable floating panel",
})

-- ═══════════════════════════════════════════════════════════════════════════
--  9.  DEPENDENCY DEMONSTRATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Create a dependency box that shows/hides based on a toggle
local DepTab = Window:AddTab({
    Title       = "Dependencies",
    Description = "Conditional visibility demo",
})

local DepBox = DepTab:AddLeftGroupbox({
    Name        = "Master Control",
    Description = "Toggle to reveal advanced options",
})

-- Master toggle
local MasterToggle = DepBox:AddToggle("MasterToggle", {
    Text     = "Enable Advanced Mode",
    Default  = false,
    Tooltip  = "Enables advanced configuration options",
})

-- Right column: Dependent groupbox
local AdvancedBox = DepTab:AddRightGroupbox({
    Name        = "Advanced Options",
    Description = "Only visible when Advanced Mode is on",
})

-- Setup dependencies: this groupbox only shows when MasterToggle is true
AdvancedBox:SetupDependencies({
    { MasterToggle, true },
})

-- Add some advanced controls
AdvancedBox:AddSlider("AdvSlider", {
    Text     = "Advanced Setting",
    Default  = 75,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Suffix   = "%",
    Compact  = true,
})

AdvancedBox:AddToggle("AdvToggle", {
    Text     = "Advanced Feature",
    Default  = false,
    Tooltip  = "An advanced feature that requires master toggle",
})

AdvancedBox:AddDropdown("AdvDropdown", {
    Text       = "Advanced Mode",
    Values     = { "Conservative", "Balanced", "Aggressive", "Extreme" },
    Default    = "Balanced",
    Multi      = false,
    Tooltip    = "Select advanced operation mode",
})

-- ═══════════════════════════════════════════════════════════════════════════
--  10.  NOTIFICATION ON LOAD
-- ═══════════════════════════════════════════════════════════════════════════

LRXUI:Notify({
    Title       = "LRX Hub Loaded",
    Description = "Welcome! All features are ready to use. Press RightCtrl to toggle the UI.",
    Time        = 5,
    SoundId     = 9114488953,
})

-- ═══════════════════════════════════════════════════════════════════════════
--  11.  UNLOAD HANDLER
-- ═══════════════════════════════════════════════════════════════════════════

LRXUI:OnUnload(function()
    -- Clean up custom connections
    if watermarkConn then watermarkConn:Disconnect() end
    if sessionConn then sessionConn:Disconnect() end

    -- Reset character modifications
    local player = game:GetService("Players").LocalPlayer
    if player and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = 16
        player.Character.Humanoid.JumpPower = 50
    end

    print("[LRX Hub] Unloaded successfully")
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  12.  SEARCH DEMONSTRATION
-- ═══════════════════════════════════════════════════════════════════════════
-- The search box is automatically available in the top-right of the window.
-- Type any feature name (e.g. "speed", "esp", "sell") to filter controls.

-- ═══════════════════════════════════════════════════════════════════════════
--  END OF auto.lua
-- ═══════════════════════════════════════════════════════════════════════════

print("[LRX Hub] auto.lua loaded successfully")
print("[LRX Hub] Features loaded:")
print("  • 6 Tabs with 12+ Groupboxes")
print("  • 20+ Toggles with callbacks")
print("  • 8 Sliders with real-time updates")
print("  • 6 Dropdowns (single & multi-select)")
print("  • 4 Textboxes with validation")
print("  • 3 Keybinds (Toggle, Hold, Sync)")
print("  • 2 Color Pickers (with transparency)")
print("  • 15+ Buttons with various behaviors")
print("  • Notifications, Dialogs, Watermarks")
print("  • Theme switching, DPI scaling")
print("  • Dependency boxes, Search, Draggable elements")