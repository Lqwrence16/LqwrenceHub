local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")

--==============================================================================
-- PHASE 1: CONSTANTS
--==============================================================================

local DEV_MODE = true

local CONFIG_FILE = "LRX_Hub_Config.json"

local CACHE_FOLDER = "LRXHUB69/cache"
local CACHE_FILE = CACHE_FOLDER .. "/LRXUI.lua"
local VERSION_FILE = CACHE_FOLDER .. "/LRXUI.version"

local UI_URL = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua"
local VERSION_URL = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.version"

--==============================================================================
-- PHASE 2: HELPER FUNCTIONS
--==============================================================================

local function ReadFile(path)
	if not isfile or not isfile(path) then
		return nil
	end
	local ok, data = pcall(readfile, path)
	if ok and data and #data > 0 then
		return data
	end
	return nil
end

local function WriteFile(path, data)
	if not writefile then
		return false
	end
	return pcall(writefile, path, data)
end

local function EnsureCacheFolders()
	if not makefolder then
		return
	end
	if not isfolder("LRXHUB69") then
		pcall(makefolder, "LRXHUB69")
	end
	if not isfolder(CACHE_FOLDER) then
		pcall(makefolder, CACHE_FOLDER)
	end
end

local function Download(url)
	if not url then
		return nil
	end
	local ok, data = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and data and #data > 0 then
		return data
	end
	return nil
end

-- Validates that a version string is not an error page, HTML, or garbage.
local function IsValidVersion(str)
	if type(str) ~= "string" then
		return false
	end
	if #str == 0 then
		return false
	end
	if not str:match("%S") then
		return false
	end
	-- Reject HTML responses
	if str:find("<!DOCTYPE", 1, true) or str:find("<html", 1, true) then
		return false
	end
	-- Reject common error pages
	local lower = str:lower()
	if lower:find("not found") or lower:find("404") then
		return false
	end
	if lower:find("error") and #str < 200 then
		return false
	end
	return true
end

-- Reads the cache once and validates both files before returning them.
local function ReadCache()
	local ui = ReadFile(CACHE_FILE)
	if not ui then
		return nil
	end
	if #ui < 100 then
		warn("[LRX Cache] Cached UI is too small (" .. #ui .. " bytes), treating as invalid")
		return nil
	end

	local version = ReadFile(VERSION_FILE)
	if not version then
		warn("[LRX Cache] Version file missing")
		return nil
	end
	if #version == 0 then
		warn("[LRX Cache] Version file is empty")
		return nil
	end
	if not version:match("%S") then
		warn("[LRX Cache] Version file contains only whitespace")
		return nil
	end

	return {
		UI = ui,
		Version = version,
	}
end

local function WriteCache(ui, version)
	local ok1 = true
	local ok2 = true
	if ui then
		ok1 = WriteFile(CACHE_FILE, ui)
		if not ok1 then
			warn("[LRX Cache] Failed to write LRXUI.lua")
		end
	end
	if version then
		ok2 = WriteFile(VERSION_FILE, version)
		if not ok2 then
			warn("[LRX Cache] Failed to write version file")
		end
	end
	return ok1 and ok2
end

-- Downloads the latest package. Optionally reuses a pre-fetched version string.
local function DownloadLatest(preFetchedVersion)
	print("[LRX Cache] Downloading latest package...")

	local ui = Download(UI_URL)
	if not ui or #ui <= 100 then
		warn("[LRX Cache] Failed to download LRXUI.lua or file too short")
		return nil
	end

	local version = preFetchedVersion
	if not IsValidVersion(version) then
		version = Download(VERSION_URL)
	end
	if not IsValidVersion(version) then
		warn("[LRX Cache] Version file invalid, using 'unknown'")
		version = "unknown"
	end

	print("[LRX Cache] Download complete.")
	return {
		UI = ui,
		Version = version,
	}
end

-- Checks if the local version matches the remote version.
-- Reuses the downloaded version string for the package download if an update is needed.
local function CheckVersion(localVersion)
	print("[LRX Cache] Local version: " .. tostring(localVersion))

	local remoteVersion = Download(VERSION_URL)
	if not IsValidVersion(remoteVersion) then
		warn("[LRX Cache] Failed to download valid version file. Assuming cache is up to date.")
		return {
			Match = true,
			RemoteVersion = nil,
		}
	end

	print("[LRX Cache] Remote version: " .. remoteVersion)

	if localVersion == remoteVersion then
		return {
			Match = true,
			RemoteVersion = remoteVersion,
		}
	else
		return {
			Match = false,
			RemoteVersion = remoteVersion,
		}
	end
end

-- Validates a downloaded UI by compiling and executing it BEFORE the cache is touched.
local function ValidateLibrary(source)
	print("[LRX Cache] Validating download...")
	if not source or type(source) ~= "string" then
		return false, "Source is nil or not a string"
	end
	if #source <= 100 then
		return false, "Source is too short (" .. #source .. " chars)"
	end

	print("[LRX Cache] Compiling...")
	local chunk, compileError = loadstring(source)
	if not chunk then
		return false, "Syntax error: " .. tostring(compileError)
	end

	print("[LRX Cache] Executing test run...")
	local success, result = xpcall(chunk, debug.traceback)
	if not success then
		return false, "Runtime error: " .. tostring(result)
	end

	if type(result) ~= "table" then
		return false, "Did not return a library table. Got: " .. type(result)
	end

	print("[LRX Cache] Validation passed.")
	return true, nil
end

local function LoadLibrary(source)
	print("[LRX Loader] Loading library...")

	local chunk, compileError = loadstring(source)
	if not chunk then
		error("[LRX Loader] Syntax error in LRXUI.lua: " .. tostring(compileError))
	end

	local success, result = xpcall(chunk, debug.traceback)
	if not success then
		error("[LRX Loader] Runtime error loading library: " .. tostring(result))
	end

	if type(result) ~= "table" then
		error("[LRX Loader] LRXUI.lua did not return a library table. Got: " .. type(result))
	end

	print("[LRX Loader] Library loaded successfully.")
	return result
end

--==============================================================================
-- PHASE 3: CLEANUP
--==============================================================================

local function Cleanup()
	print("[LRX Loader] Running cleanup...")

	pcall(function()
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

		local targets = {
			"Obsidian",
			"ObsidanModal",
			"LRXUI",
			"LRXUI_Modal",
		}

		local function DestroyTargets(parent)
			if not parent then
				return
			end
			for _, child in ipairs(parent:GetChildren()) do
				if table.find(targets, child.Name) then
					pcall(function()
						child:Destroy()
					end)
				end
			end
		end

		local localPlayer = Players.LocalPlayer
		if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
			DestroyTargets(localPlayer.PlayerGui)
		end

		DestroyTargets(CoreGui)
	end)

	task.wait(0.15)
	print("[LRX Loader] Cleanup complete.")
end

Cleanup()

--==============================================================================
-- PHASE 4: CACHE SETUP
--==============================================================================

EnsureCacheFolders()

--==============================================================================
-- PHASE 5 & 6: DEV MODE / RELEASE MODE
--==============================================================================

local CachedUI = nil

if DEV_MODE then
	print("[LRX Loader] DEV_MODE enabled.")
	print("[LRX Loader] Loading local LRXUI.lua...")

	local devSource = ReadFile(CACHE_FILE)
	if not devSource then
		error(
			"[LRX Loader] DEV_MODE requires a local LRXUI.lua at '"
				.. CACHE_FILE
				.. "'. Please place your local file there and re-execute."
		)
	end

	CachedUI = devSource
	print("[LRX Loader] Local library loaded. (GitHub ignored, cache untouched)")
else
	print("[LRX Loader] Release mode.")
	print("[LRX Cache] Checking cache...")

	local cache = ReadCache()

	if not cache then
		print("[LRX Cache] Cache missing or corrupted.")
		print("[LRX Cache] Downloading fresh package...")

		local latest = DownloadLatest()
		if not latest then
			error("[LRX Cache] Failed to download LRXUI. No local cache available.")
		end

		local valid, err = ValidateLibrary(latest.UI)
		if not valid then
			error("[LRX Cache] Validation failed: " .. tostring(err))
		end

		print("[LRX Cache] Updating cache...")
		WriteCache(latest.UI, latest.Version)
		CachedUI = latest.UI

		print("[LRX Cache] Cache created successfully.")
	else
		print("[LRX Cache] Cache found.")
		print("[LRX Cache] Checking version...")

		local versionCheck = CheckVersion(cache.Version)

		if versionCheck.Match then
			print("[LRX Cache] Cache is up to date.")
			CachedUI = cache.UI
		else
			print("[LRX Cache] Update available.")
			print("[LRX Cache] Downloading latest package...")

			local latest = DownloadLatest(versionCheck.RemoteVersion)
			if not latest then
				warn("[LRX Cache] Download failed. Falling back to existing cache.")
				CachedUI = cache.UI
			else
				local valid, err = ValidateLibrary(latest.UI)
				if not valid then
					warn("[LRX Cache] Validation failed: " .. tostring(err) .. ". Falling back to existing cache.")
					CachedUI = cache.UI
				else
					print("[LRX Cache] Updating cache...")
					WriteCache(latest.UI, latest.Version)
					CachedUI = latest.UI
					print("[LRX Cache] Cache updated successfully.")
				end
			end
		end
	end
end

--==============================================================================
-- PHASE 7: LIBRARY LOADING
--==============================================================================

assert(CachedUI, "[LRX Loader] No library source available.")

local Library = LoadLibrary(CachedUI)
getgenv().Library = Library

--==============================================================================
-- PHASE 8: CONFIG PERSISTENCE
--==============================================================================

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

_G.LRX_Connections = _G.LRX_Connections or {}
_G.LRX_KillSwitch = false

--==============================================================================
-- PHASE 9: WINDOW SETUP
--==============================================================================

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

--==============================================================================
-- PHASE 10: UI
--==============================================================================

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
HomeRight:AddLabel("Game: " .. MarketplaceService:GetProductInfo(game.PlaceId).Name)
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
