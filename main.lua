local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")

--==============================================================================
--
--==============================================================================

local DEV_MODE = false

local CONSTANTS = {
	Config = {
		FILE = "LRX_Hub_Config.json",
		AutoSaveDefault = true,
	},
	Paths = {
		CACHE_FOLDER = "LRXHUB69/cache",
		CACHE_FILE = "LRXHUB69/cache/LRXUI.lua",
		VERSION_FILE = "LRXHUB69/cache/LRXUI.version",
	},
	URLs = {
		UI = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua",
		VERSION = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.version",
	},
	Version = {
		HUB = "v0.0.05",
		UI = "0.0.03",
	},
	UI = {
		Targets = { "Obsidian", "ObsidanModal", "LRXUI", "LRXUI_Modal" },
	},
}
-- PHASE 1b: PRODUCTION LOGGER
local Logger = {
	Debug = function(tag, msg)
		if DEV_MODE then
			print("[LRX " .. tostring(tag) .. "] " .. tostring(msg))
		end
	end,
	Info = function(tag, msg)
		print("[LRX " .. tostring(tag) .. "] " .. tostring(msg))
	end,
	Warn = function(tag, msg)
		warn("[LRX " .. tostring(tag) .. "] " .. tostring(msg))
	end,
	Error = function(msg)
		error("[LRX Loader] " .. tostring(msg))
	end,
}
-- PHASE 2: HELPER FUNCTIONS
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
	if not isfolder(CONSTANTS.Paths.CACHE_FOLDER) then
		pcall(makefolder, CONSTANTS.Paths.CACHE_FOLDER)
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
-- Validates that a downloaded library source is not an HTTP error page.
local function IsValidLibrarySource(str)
	if type(str) ~= "string" then
		return false
	end
	if #str <= 100 then
		return false, "Source is too short (" .. #str .. " chars)"
	end
	-- Reject HTML responses
	if str:find("<!DOCTYPE", 1, true) or str:find("<html", 1, true) then
		return false, "Download returned HTML instead of Lua (likely an error page)"
	end
	-- Reject HTTP error codes at start
	local firstLine = str:match("^([^\n]+)")
	if firstLine then
		if firstLine:find("^%d%d%d[%s:]") then
			return false, "Download returned HTTP error response: " .. firstLine
		end
		if firstLine:lower():find("error") and #firstLine < 100 then
			return false, "Download returned error page: " .. firstLine
		end
	end
	-- Must look like Lua code
	local start = str:match("^%s*([^\n]+)")
	if start then
		local lower = start:lower()
		-- Common Lua start patterns
		local validStarts = {
			"local ",
			"return",
			"function",
			"--",
			"[[",
			"(",
			"{",
			"do",
			"if ",
			"for ",
			"while ",
			"repeat",
		}
		local looksLikeLua = false
		for _, pattern in ipairs(validStarts) do
			if lower:find(pattern, 1, true) == 1 then
				looksLikeLua = true
				break
			end
		end
		if not looksLikeLua then
			return false, "Download does not look like Lua code. First line: " .. start
		end
	end
	return true
end
-- Reads the cache once and validates both files before returning them.
local function ReadCache()
	local ui = ReadFile(CONSTANTS.Paths.CACHE_FILE)
	if not ui then
		return nil
	end
	if #ui < 100 then
		Logger.Warn("Cache", "Cached UI is too small (" .. #ui .. " bytes), treating as invalid")
		return nil
	end

	local version = ReadFile(CONSTANTS.Paths.VERSION_FILE)
	if not version then
		Logger.Warn("Cache", "Version file missing")
		return nil
	end
	if #version == 0 then
		Logger.Warn("Cache", "Version file is empty")
		return nil
	end
	if not version:match("%S") then
		Logger.Warn("Cache", "Version file contains only whitespace")
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
		ok1 = WriteFile(CONSTANTS.Paths.CACHE_FILE, ui)
		if not ok1 then
			Logger.Warn("Cache", "Failed to write LRXUI.lua")
		end
	end
	if version then
		ok2 = WriteFile(CONSTANTS.Paths.VERSION_FILE, version)
		if not ok2 then
			Logger.Warn("Cache", "Failed to write version file")
		end
	end
	return ok1 and ok2
end
-- Downloads the latest package.
local function DownloadLatest()
	Logger.Info("Cache", "Downloading latest package...")

	local ui = Download(CONSTANTS.URLs.UI)
	if not ui or #ui <= 100 then
		Logger.Warn("Cache", "Failed to download LRXUI.lua or file too short")
		return nil
	end

	local uiOk, uiErr = IsValidLibrarySource(ui)
	if not uiOk then
		Logger.Warn("Cache", "LRXUI.lua download invalid: " .. tostring(uiErr))
		return nil
	end

	local version = Download(CONSTANTS.URLs.VERSION)
	if not IsValidVersion(version) then
		Logger.Warn("Cache", "Version file invalid, using 'unknown'")
		version = "unknown"
	end

	Logger.Info("Cache", "Download complete.")
	return {
		UI = ui,
		Version = version,
	}
end
-- Validates and loads a library source in one step.
-- Returns (true, libraryTable) on success, (false, errorMessage) on failure.
-- This eliminates double compilation by producing the library table immediately.
local function ValidateAndLoad(source)
	Logger.Info("Cache", "Validating library...")
	if not source or type(source) ~= "string" then
		return false, "Source is nil or not a string"
	end
	if #source <= 100 then
		return false, "Source is too short (" .. #source .. " chars)"
	end

	Logger.Info("Cache", "Compiling...")
	local chunk, compileError = loadstring(source)
	if not chunk then
		return false, "Syntax error: " .. tostring(compileError)
	end

	Logger.Info("Cache", "Executing test run...")
	local success, result = xpcall(chunk, debug.traceback)
	if not success then
		return false, "Runtime error: " .. tostring(result)
	end

	if type(result) ~= "table" then
		return false, "Did not return a library table. Got: " .. type(result)
	end

	Logger.Info("Cache", "Validation passed. Library loaded.")
	return true, result
end
-- PHASE 3: CLEANUP
-- Shared UI destruction helper used by both Cleanup() and Close All.
local function DestroyHubUI()
	local targets = CONSTANTS.UI.Targets

	local function DestroyIn(parent)
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
		DestroyIn(localPlayer.PlayerGui)
	end
	DestroyIn(CoreGui)
end

local function Cleanup()
	Logger.Info("Loader", "Running cleanup...")

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

		DestroyHubUI()
	end)

	task.wait(0.15)
	Logger.Info("Loader", "Cleanup complete.")
end
Cleanup()
-- PHASE 4: CACHE SETUP
EnsureCacheFolders()
-- PHASE 5 & 6: DEV MODE / RELEASE MODE
local Library = nil

if DEV_MODE then
	Logger.Info("Loader", "DEV_MODE enabled.")
	Logger.Info("Loader", "Loading local LRXUI.lua...")

	local devSource = ReadFile(CONSTANTS.Paths.CACHE_FILE)
	if not devSource then
		Logger.Error(
			"DEV_MODE requires a local LRXUI.lua at '"
				.. CONSTANTS.Paths.CACHE_FILE
				.. "'. Please place your local file there and re-execute."
		)
	end

	local valid, result = ValidateAndLoad(devSource)
	if not valid then
		Logger.Error("DEV_MODE validation failed: " .. tostring(result))
		return
	end

	Library = result
	Logger.Info("Loader", "Local library validated and loaded. (GitHub ignored, cache untouched)")
else
	Logger.Info("Loader", "Release mode.")
	Logger.Info("Cache", "Checking cache...")

	local cache = ReadCache()
	local librarySource = nil

	if not cache then
		Logger.Info("Cache", "Cache missing or corrupted.")
		Logger.Info("Cache", "Downloading fresh package...")

		local latest = DownloadLatest()
		if not latest then
			Logger.Error("Failed to download LRXUI. No local cache available.")
			return
		end

		local valid, result = ValidateAndLoad(latest.UI)
		if not valid then
			Logger.Error("Validation failed: " .. tostring(result))
			return
		end

		Logger.Info("Cache", "Updating cache...")
		local writeOk = WriteCache(latest.UI, latest.Version)
		if not writeOk then
			Logger.Warn("Cache", "Cache write failed. Library loaded but cache may be stale on next run.")
		end

		Library = result
		librarySource = latest.UI

		Logger.Info("Cache", "Cache created successfully.")
	else
		Logger.Info("Cache", "Cache found.")
		Logger.Info("Cache", "Cached version: " .. tostring(cache.Version))
		Logger.Info("Cache", "Expected version: " .. CONSTANTS.Version.UI)

		if cache.Version == CONSTANTS.Version.UI then
			Logger.Info("Cache", "Cache is up to date.")
			librarySource = cache.UI
		else
			Logger.Info("Cache", "Version mismatch.")
			Logger.Info("Cache", "Downloading latest package...")

			local latest = DownloadLatest()
			if not latest then
				Logger.Warn("Cache", "Download failed. Falling back to existing cache.")
				librarySource = cache.UI
			else
				local valid, result = ValidateAndLoad(latest.UI)
				if not valid then
					Logger.Warn(
						"Cache",
						"Validation failed: " .. tostring(result) .. ". Falling back to existing cache."
					)
					librarySource = cache.UI
				else
					Logger.Info("Cache", "Updating cache...")
					local writeOk = WriteCache(latest.UI, latest.Version)
					if not writeOk then
						Logger.Warn("Cache", "Cache write failed. Library loaded but cache may be stale on next run.")
					end
					Library = result
					librarySource = latest.UI
					Logger.Info("Cache", "Cache updated successfully.")
				end
			end
		end
	end

	-- If we only have source (fallback cases), compile and load it now.
	if not Library and librarySource then
		local valid, result = ValidateAndLoad(librarySource)
		if not valid then
			Logger.Error("Failed to load cached library: " .. tostring(result))
			return
		end
		Library = result
	end
end
-- PHASE 7: LIBRARY LOADING
if not Library then
	Logger.Error("No library source available.")
	return
end

getgenv().Library = Library
-- PHASE 8: CONFIG PERSISTENCE
local SavedConfig = {}
pcall(function()
	if readfile and isfile and isfile(CONSTANTS.Config.FILE) then
		SavedConfig = HttpService:JSONDecode(readfile(CONSTANTS.Config.FILE))
	end
end)

local function SaveConfig()
	pcall(function()
		if writefile then
			writefile(CONSTANTS.Config.FILE, HttpService:JSONEncode(SavedConfig))
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
	-- Always save when the AutoSaveConfig toggle itself changes so the preference persists.
	-- Otherwise respect the user's AutoSaveConfig setting.
	if key == "AutoSaveConfig" or (SavedConfig["AutoSaveConfig"] ~= false) then
		SaveConfig()
	end
end

_G.LRX_Connections = _G.LRX_Connections or {}
_G.LRX_KillSwitch = false
--==============================================================================
--
--==============================================================================

--
--
--
--

--==============================================================================
-- #1 //WindowSetup\
--==============================================================================
local Window = Library:CreateWindow({
	Title = "LRX_Hub",
	Footer = CONSTANTS.Version.HUB,
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
-- #2 //TABS\\
--==============================================================================

-- //HOME TAB\\
local HomeTab = Window:AddTab("Home", "house", "Welcome to LRX Hub!")
local HomeLeft = HomeTab:AddLeftGroupbox("Welcome", "user")
local HomeRight = HomeTab:AddRightGroupbox("Status", "activity")

HomeLeft:AddLabel("Status: idle")
HomeLeft:AddLabel("Ping: -- ms")

HomeRight:AddLabel("Client Info:")
HomeRight:AddLabel("Version: " .. CONSTANTS.Version.HUB)
HomeRight:AddLabel("Game: " .. MarketplaceService:GetProductInfo(game.PlaceId).Name)
HomeRight:AddDivider()

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

-- //AUTOMATION TAB\\
local AutomationTab = Window:AddTab("Automation", "workflow", "Automation controls for farming.")
local FarmLeft = AutomationTab:AddLeftGroupbox("Seed Placer", "sprout")

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

-- //Misc Tab\\
local MiscTab = Window:AddTab("Misc", "puzzle", "Miscellaneous features and utilities.")
local MiscLeft = MiscTab:AddLeftGroupbox("Grid Scanner", "grid-3x3")

local ShopTab = Window:AddTab("Shop", "shopping-cart", "Buy items for your farm.")
local SeedShop = ShopTab:AddLeftGroupbox("Seed Shop", "apple")
SeedShop:AddToggle("AutoSeedShop", {
	Text = "Auto Buy Seeds",
	Default = GetSaved("AutoBuySeeds", false),
	Tooltip = "Buy all selected seeds",
	Callback = function(Value)
		SetSaved("AutoSeedShop", Value)
		_G.AutoBuySeeds = Value
		print("AutoBuySeeds:", Value)
	end,
})

-- //SETTINGS TAB\\
local SettingsTab = Window:AddTab("Settings", "settings", "Configure your preferences and manage the hub.")
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
		if Library and Library.Unload then
			Library:Unload()
		end
		DestroyHubUI()
	end)

	_G.LRX_Hub_UI = nil
	Logger.Info("Hub", "Fully closed. Config saved.")
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
						delfile(CONSTANTS.Config.FILE)
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

Logger.Info("Hub", "Main script loaded successfully!")
