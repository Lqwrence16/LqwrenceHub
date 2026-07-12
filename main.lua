local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StatsService = game:GetService("Stats")

--==============================================================================
-- RUNTIME TABLE
--==============================================================================
local Runtime = {
	HeartbeatActive = false,
	HeartbeatRetries = 0,
	HeartbeatMaxRetries = 5,
	PlaceInfo = nil,
	AuthTimeout = 120,
	KeyVerifying = false,
	EnterConnection = nil,
}

--==============================================================================
-- BACKEND CONFIG
--==============================================================================
local API_BASE = "https://lrx-hub-backend.vercel.app"

--==============================================================================
-- DEV MODE
--==============================================================================
local DEV_MODE = false
local SKIP_KEYCHECK = false

--==============================================================================
-- DEFAULT CONFIGURATION
--==============================================================================
local DEFAULT_CONFIG = {
	AutoSaveConfig = true,
	AutoFarm = false,
	AutoBuySeeds = false,
	ShowNotifications = true,
}

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
		UI = "0.0.01",
	},
	UI = {
		Targets = { "Obsidian", "ObsidanModal", "LRXUI", "LRXUI_Modal" },
	},
}

--==============================================================================
-- LOGGER
--==============================================================================
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

--==============================================================================
-- BACKEND API FUNCTIONS
--==============================================================================
local Backend = {}

local function GenerateHWID()
	local hwid = ""
	pcall(function()
		if gethwid then
			hwid = gethwid()
		elseif syn and syn.get_hwid then
			hwid = syn.get_hwid()
		elseif KRNL_LOADED and KRNL_HWID then
			hwid = KRNL_HWID
		end
	end)
	if hwid == "" then
		local seed = tostring(Players.LocalPlayer.UserId) .. "_" .. tostring(game.PlaceId)
		local hash = 0
		for i = 1, #seed do
			hash = ((hash * 31) + string.byte(seed, i)) % 2147483647
		end
		hwid = "FALLBACK_" .. tostring(hash)
	end
	return hwid
end

local HWID = GenerateHWID()

local function UrlEncode(str)
	if not str then
		return ""
	end
	return str:gsub("([^%w _%%%-%.])", function(c)
		return string.format("%%%02X", string.byte(c))
	end):gsub(" ", "+")
end

--==============================================================================
-- NETWORKING HELPERS
--==============================================================================
local function ApiPost(endpoint, body)
	local url = API_BASE .. endpoint
	local jsonBody = HttpService:JSONEncode(body)
	local response = nil

	-- Use request() FIRST (proven working on your executor)
	local ok, result = pcall(function()
		return request({
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = jsonBody,
		})
	end)
	if ok and result then
		if type(result) == "table" and result.Body then
			response = result.Body
		elseif type(result) == "string" then
			response = result
		end
	end

	-- Fallback: game:HttpPost
	if not response then
		local ok2, result2 = pcall(function()
			return game:HttpPost(url, jsonBody, false, "Content-Type: application/json")
		end)
		if ok2 and result2 then
			response = result2
		end
	end

	-- Fallback: GET with encoded data
	if not response then
		local ok3, result3 = pcall(function()
			return game:HttpGet(url .. "?data=" .. UrlEncode(jsonBody), true)
		end)
		if ok3 and result3 then
			response = result3
		end
	end

	if response and response ~= "" then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)
		if ok then
			return data
		end
	end

	return { success = false, error = "Request failed" }
end

local function ApiGet(endpoint)
	local url = API_BASE .. endpoint
	local response = nil

	local ok, result = pcall(function()
		return request({
			Url = url,
			Method = "GET",
			Headers = {},
		})
	end)
	if ok and result then
		if type(result) == "table" and result.Body then
			response = result.Body
		elseif type(result) == "string" then
			response = result
		end
	end

	if not response then
		local ok2, result2 = pcall(function()
			return game:HttpGet(url, true)
		end)
		if ok2 and result2 then
			response = result2
		end
	end

	if response and response ~= "" then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)
		if ok then
			return data
		end
	end

	return nil
end

function Backend.CheckVersion()
	local data = ApiGet("/api/version")
	if not data then
		return { update = false }
	end
	return {
		update = data.force_update or (CONSTANTS.Version.HUB ~= data.version),
		version = data.version,
		download = data.download,
		force = data.force_update,
		changelog = data.changelog or "",
	}
end

function Backend.VerifyKey(key)
	if not key or key == "" then
		return { success = false, error = "No key provided" }
	end

	local data = ApiPost("/api/verify", {
		key = key,
		userid = tostring(Players.LocalPlayer.UserId),
		username = Players.LocalPlayer.Name,
		executor = identifyexecutor and identifyexecutor() or "Unknown",
		hwid = HWID,
		version = CONSTANTS.Version.HUB,
	})

	if data and data.valid then
		return {
			success = true,
			plan = data.plan or "free",
			expires_at = data.expires_at,
			message = data.message,
		}
	end
	return { success = false, error = data and (data.reason or data.error) or "Invalid key" }
end

function Backend.TrackLaunch(key)
	local placeName = "Unknown"
	pcall(function()
		if Runtime.PlaceInfo then
			placeName = Runtime.PlaceInfo.Name
		else
			placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name
		end
	end)
	ApiPost("/api/launch", {
		key = key,
		hwid = HWID,
		username = Players.LocalPlayer.Name,
		user_id = Players.LocalPlayer.UserId,
		place_id = game.PlaceId,
		place_name = placeName,
		executor = identifyexecutor and identifyexecutor() or "Unknown",
	})
end

function Backend.StartHeartbeat(key)
	if Runtime.HeartbeatActive then
		Logger.Debug("Heartbeat", "Already active, skipping duplicate.")
		return
	end
	Runtime.HeartbeatActive = true
	Runtime.HeartbeatRetries = 0

	task.spawn(function()
		while _G.LRX_Authenticated do
			task.wait(30)
			if not _G.LRX_Authenticated then
				break
			end
			local ok = pcall(function()
				local result = ApiPost("/api/heartbeat", { key = key, hwid = HWID })
				if result and result.success then
					Runtime.HeartbeatRetries = 0
				else
					Runtime.HeartbeatRetries = Runtime.HeartbeatRetries + 1
				end
			end)
			if not ok then
				Runtime.HeartbeatRetries = Runtime.HeartbeatRetries + 1
			end
			if Runtime.HeartbeatRetries >= Runtime.HeartbeatMaxRetries then
				_G.LRX_Authenticated = false
				Logger.Warn("Heartbeat", "Max retries reached. Stopping heartbeat.")
				break
			end
		end
		Runtime.HeartbeatActive = false
	end)
end

function Backend.GetAnnouncements()
	local data = ApiGet("/api/announcement")
	if data and data.announcements then
		return data.announcements
	end
	return {}
end

function Backend.GetConfig()
	return ApiGet("/api/config")
end
function Backend.GetFeatures()
	return ApiGet("/api/features")
end
function Backend.GetNews()
	return ApiGet("/api/news")
end
function Backend.GetStatistics()
	return ApiGet("/api/statistics")
end
function Backend.GetBanStatus()
	return ApiGet("/api/banstatus")
end

--==============================================================================
-- KEY ENCODING HELPERS
--==============================================================================
local function EncodeKey(key)
	if not key or key == "" then
		return ""
	end
	local encoded = ""
	for i = 1, #key do
		encoded = encoded .. string.format("%02x", string.byte(key, i))
	end
	return encoded
end

local function DecodeKey(str)
	if not str or str == "" then
		return ""
	end
	if not str:match("^%x+$") or #str % 2 ~= 0 then
		return str
	end
	local decoded = ""
	for i = 1, #str, 2 do
		local byte = tonumber(str:sub(i, i + 1), 16)
		if not byte then
			return str
		end
		decoded = decoded .. string.char(byte)
	end
	return decoded
end

--==============================================================================
-- KEY SYSTEM UI
--==============================================================================
local function CreateKeySystem()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LRX_KeySystem"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	pcall(function()
		screenGui.Parent = CoreGui
	end)
	if not screenGui.Parent then
		screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.fromOffset(360, 220)
	mainFrame.Position = UDim2.fromScale(0.5, 0.5)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 40, 40)
	stroke.Thickness = 1
	stroke.Parent = mainFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.fromOffset(0, 10)
	title.BackgroundTransparency = 1
	title.Text = "LRX Hub"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 22
	title.Font = Enum.Font.BuilderSansBold
	title.Parent = mainFrame

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 20)
	subtitle.Position = UDim2.fromOffset(0, 38)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Key Authentication"
	subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	subtitle.TextSize = 12
	subtitle.Font = Enum.Font.BuilderSans
	subtitle.Parent = mainFrame

	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.new(1, -40, 0, 36)
	inputFrame.Position = UDim2.fromOffset(20, 75)
	inputFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	inputFrame.BorderSizePixel = 0
	inputFrame.Parent = mainFrame

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = inputFrame

	local inputStroke = Instance.new("UIStroke")
	inputStroke.Color = Color3.fromRGB(50, 50, 50)
	inputStroke.Thickness = 1
	inputStroke.Parent = inputFrame

	local keyInput = Instance.new("TextBox")
	keyInput.Name = "KeyInput"
	keyInput.Size = UDim2.new(1, -40, 1, 0)
	keyInput.Position = UDim2.fromOffset(10, 0)
	keyInput.BackgroundTransparency = 1
	keyInput.Text = ""
	keyInput.PlaceholderText = "Enter LRX Key..."
	keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	keyInput.TextSize = 14
	keyInput.Font = Enum.Font.BuilderSans
	keyInput.ClearTextOnFocus = false
	keyInput.Parent = inputFrame

	local pasteBtn = Instance.new("TextButton")
	pasteBtn.Name = "PasteBtn"
	pasteBtn.Size = UDim2.fromOffset(30, 30)
	pasteBtn.Position = UDim2.new(1, -35, 0.5, 0)
	pasteBtn.AnchorPoint = Vector2.new(0, 0.5)
	pasteBtn.BackgroundTransparency = 1
	pasteBtn.Text = "[PASTE]"
	pasteBtn.TextSize = 14
	pasteBtn.Parent = inputFrame

	pasteBtn.MouseButton1Click:Connect(function()
		local clipboard = ""
		pcall(function()
			if getclipboard then
				clipboard = getclipboard()
			end
		end)
		if clipboard and clipboard ~= "" then
			keyInput.Text = clipboard
		end
	end)

	local errorLabel = Instance.new("TextLabel")
	errorLabel.Name = "ErrorLabel"
	errorLabel.Size = UDim2.new(1, -40, 0, 18)
	errorLabel.Position = UDim2.fromOffset(20, 115)
	errorLabel.BackgroundTransparency = 1
	errorLabel.Text = ""
	errorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	errorLabel.TextSize = 11
	errorLabel.Font = Enum.Font.BuilderSans
	errorLabel.TextWrapped = true
	errorLabel.Parent = mainFrame

	local loginBtn = Instance.new("TextButton")
	loginBtn.Name = "LoginBtn"
	loginBtn.Size = UDim2.new(1, -40, 0, 36)
	loginBtn.Position = UDim2.fromOffset(20, 145)
	loginBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
	loginBtn.BorderSizePixel = 0
	loginBtn.Text = "Login"
	loginBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	loginBtn.TextSize = 14
	loginBtn.Font = Enum.Font.BuilderSansBold
	loginBtn.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = loginBtn

	local getKeyBtn = Instance.new("TextButton")
	getKeyBtn.Name = "GetKeyBtn"
	getKeyBtn.Size = UDim2.new(1, -40, 0, 28)
	getKeyBtn.Position = UDim2.fromOffset(20, 188)
	getKeyBtn.BackgroundTransparency = 1
	getKeyBtn.Text = "Get Key  |  Discord"
	getKeyBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	getKeyBtn.TextSize = 11
	getKeyBtn.Font = Enum.Font.BuilderSans
	getKeyBtn.Parent = mainFrame

	local loadingFrame = Instance.new("Frame")
	loadingFrame.Name = "Loading"
	loadingFrame.Size = UDim2.fromScale(1, 1)
	loadingFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	loadingFrame.BackgroundTransparency = 0.3
	loadingFrame.Visible = false
	loadingFrame.Parent = mainFrame

	local loadingCorner = Instance.new("UICorner")
	loadingCorner.CornerRadius = UDim.new(0, 10)
	loadingCorner.Parent = loadingFrame

	local loadingText = Instance.new("TextLabel")
	loadingText.Size = UDim2.fromScale(1, 1)
	loadingText.BackgroundTransparency = 1
	loadingText.Text = "Verifying..."
	loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
	loadingText.TextSize = 14
	loadingText.Font = Enum.Font.BuilderSansBold
	loadingText.Parent = loadingFrame

	local dragging = false
	local dragStart, startPos

	mainFrame.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			mainFrame.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	local function btnHover(btn, normalColor, hoverColor)
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = hoverColor }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = normalColor }):Play()
		end)
	end

	btnHover(loginBtn, Color3.fromRGB(245, 158, 11), Color3.fromRGB(217, 119, 6))

	getKeyBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard("discord.gg/lrxhub")
		end
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Discord",
				Text = "discord.gg/lrxhub copied!",
				Duration = 3,
			})
		end)
	end)

	return {
		ScreenGui = screenGui,
		MainFrame = mainFrame,
		KeyInput = keyInput,
		LoginBtn = loginBtn,
		ErrorLabel = errorLabel,
		LoadingFrame = loadingFrame,
		Destroy = function()
			screenGui:Destroy()
		end,
	}
end

--==============================================================================
-- KEY AUTHENTICATION FLOW
--==============================================================================
local function RunKeySystem()
	if SKIP_KEYCHECK then
		Logger.Info("KeySystem", "Key check skipped (SKIP_KEYCHECK = true)")
		_G.LRX_Authenticated = true
		return true, nil
	end

	local versionInfo = Backend.CheckVersion()
	if versionInfo and versionInfo.force then
		Logger.Error("FORCE UPDATE REQUIRED. Please download the latest version.")
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "LRX Hub",
				Text = "FORCE UPDATE REQUIRED!",
				Duration = 10,
			})
		end)
		return false, nil
	end

	local savedKey = ""
	pcall(function()
		if isfile and isfile("LRX_Hub_Key.txt") then
			savedKey = DecodeKey(readfile("LRX_Hub_Key.txt"))
		end
	end)

	if savedKey and savedKey ~= "" then
		Logger.Info("KeySystem", "Found saved key, verifying...")
		local result = Backend.VerifyKey(savedKey)
		if result.success then
			Logger.Info("KeySystem", "Auto-login successful!")
			_G.LRX_Key = savedKey
			_G.LRX_Authenticated = true
			_G.LRX_Plan = result.plan
			Backend.TrackLaunch(savedKey)
			Backend.StartHeartbeat(savedKey)
			return true, result
		end
	end

	local keyUI = CreateKeySystem()
	local authenticated = false
	local authResult = nil
	local authStartTime = tick()

	pcall(function()
		Runtime.EnterConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
				if keyUI.KeyInput and keyUI.KeyInput.IsFocused then
					keyUI.LoginBtn:Activate()
				end
			end
		end)
	end)

	keyUI.LoginBtn.MouseButton1Click:Connect(function()
		if Runtime.KeyVerifying then
			return
		end
		Runtime.KeyVerifying = true
		keyUI.LoginBtn.Active = false
		keyUI.LoginBtn.AutoButtonColor = false

		local key = keyUI.KeyInput.Text:match("^%s*(.-)%s*$")
		if key == "" then
			keyUI.ErrorLabel.Text = "Please enter a key"
			Runtime.KeyVerifying = false
			keyUI.LoginBtn.Active = true
			keyUI.LoginBtn.AutoButtonColor = true
			return
		end

		keyUI.ErrorLabel.Text = ""
		keyUI.LoadingFrame.Visible = true
		keyUI.LoginBtn.Text = "Verifying..."

		local result = Backend.VerifyKey(key)
		keyUI.LoadingFrame.Visible = false
		keyUI.LoginBtn.Text = "Login"

		if result.success then
			pcall(function()
				if writefile then
					writefile("LRX_Hub_Key.txt", EncodeKey(key))
				end
			end)

			_G.LRX_Key = key
			_G.LRX_Authenticated = true
			_G.LRX_Plan = result.plan

			Backend.TrackLaunch(key)
			Backend.StartHeartbeat(key)

			authenticated = true
			authResult = result

			keyUI.ErrorLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
			keyUI.ErrorLabel.Text = "Success! Loading..."

			task.wait(0.5)
			if keyUI and keyUI.Destroy then
				keyUI:Destroy()
			end
		else
			keyUI.ErrorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			keyUI.ErrorLabel.Text = result.error or "Invalid key"
		end

		Runtime.KeyVerifying = false
		keyUI.LoginBtn.Active = true
		keyUI.LoginBtn.AutoButtonColor = true
	end)

	while not authenticated do
		task.wait(0.1)
		if tick() - authStartTime > Runtime.AuthTimeout then
			keyUI.ErrorLabel.Text = "Authentication timed out. Please try again."
			Logger.Warn("KeySystem", "Authentication timed out.")
			break
		end
		if not keyUI.ScreenGui or not keyUI.ScreenGui.Parent then
			return false, nil
		end
	end

	if Runtime.EnterConnection then
		pcall(function()
			Runtime.EnterConnection:Disconnect()
		end)
		Runtime.EnterConnection = nil
	end

	return authenticated, authResult
end

--==============================================================================
-- HELPER FUNCTIONS
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
	if str:find("<!DOCTYPE", 1, true) or str:find("<html", 1, true) then
		return false
	end
	local lower = str:lower()
	if lower:find("not found") or lower:find("404") then
		return false
	end
	if lower:find("error") and #str < 200 then
		return false
	end
	return true
end

local function IsValidLibrarySource(str)
	if type(str) ~= "string" then
		return false
	end
	if #str <= 100 then
		return false, "Source too short"
	end
	if str:find("<!DOCTYPE", 1, true) or str:find("<html", 1, true) then
		return false, "Download returned HTML"
	end
	local newline = string.char(10)
	local nlPos = str:find(newline, 1, true)
	local firstLine = nlPos and str:sub(1, nlPos - 1) or str
	if firstLine then
		if firstLine:find("^%d%d%d[%s:]") then
			return false, "HTTP error: " .. firstLine
		end
	end
	return true
end

local function ReadCache()
	local ui = ReadFile(CONSTANTS.Paths.CACHE_FILE)
	if not ui or #ui < 100 then
		return nil
	end
	local version = ReadFile(CONSTANTS.Paths.VERSION_FILE)
	if not version or #version == 0 then
		return nil
	end
	return { UI = ui, Version = version }
end

local function WriteCache(ui, version)
	local ok1, ok2 = true, true
	if ui then
		ok1 = WriteFile(CONSTANTS.Paths.CACHE_FILE, ui)
	end
	if version then
		ok2 = WriteFile(CONSTANTS.Paths.VERSION_FILE, version)
	end
	return ok1 and ok2
end

local function DownloadLatest()
	Logger.Info("Cache", "Downloading latest package...")
	local ui = Download(CONSTANTS.URLs.UI)
	if not ui or #ui <= 100 then
		Logger.Warn("Cache", "Failed to download LRXUI.lua")
		return nil
	end
	local uiOk, uiErr = IsValidLibrarySource(ui)
	if not uiOk then
		Logger.Warn("Cache", "LRXUI.lua invalid: " .. tostring(uiErr))
		return nil
	end
	local version = Download(CONSTANTS.URLs.VERSION)
	if not IsValidVersion(version) then
		Logger.Warn("Cache", "Version download failed. Will keep existing cached version.")
		version = nil
	end
	Logger.Info("Cache", "Download complete.")
	return { UI = ui, Version = version }
end

local function ValidateAndLoad(source)
	if not source or type(source) ~= "string" then
		return false, "Source is nil"
	end
	if #source <= 100 then
		return false, "Source too short"
	end
	local chunk, compileError = loadstring(source)
	if not chunk then
		return false, "Syntax error: " .. tostring(compileError)
	end
	local success, result = xpcall(chunk, debug.traceback)
	if not success then
		return false, "Runtime error: " .. tostring(result)
	end
	if type(result) ~= "table" then
		return false, "Did not return table. Got: " .. type(result)
	end
	return true, result
end

--==============================================================================
-- CLEANUP
--==============================================================================
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
		_G.LRX_Authenticated = false
		DestroyHubUI()
	end)
	task.wait(0.15)
	Logger.Info("Loader", "Cleanup complete.")
end

Cleanup()

--==============================================================================
-- CACHE PLACE INFORMATION
--==============================================================================
local placeName = "Unknown"
pcall(function()
	Runtime.PlaceInfo = MarketplaceService:GetProductInfo(game.PlaceId)
	placeName = Runtime.PlaceInfo and Runtime.PlaceInfo.Name or "Unknown"
end)

--==============================================================================
-- KEY AUTHENTICATION
--==============================================================================
Logger.Info("KeySystem", "Starting key authentication...")
local authSuccess, authData = RunKeySystem()

if not authSuccess then
	Logger.Error("Authentication failed or cancelled.")
	return
end

Logger.Info("KeySystem", "Authenticated! Plan: " .. tostring(_G.LRX_Plan or "free"))

--==============================================================================
-- CACHE SETUP
--==============================================================================
EnsureCacheFolders()

--==============================================================================
-- LOAD LIBRARY
--==============================================================================
local Library = nil

if DEV_MODE then
	Logger.Info("Loader", "DEV_MODE enabled.")
	local devSource = ReadFile(CONSTANTS.Paths.CACHE_FILE)
	if not devSource then
		Logger.Error("DEV_MODE requires local LRXUI.lua at " .. CONSTANTS.Paths.CACHE_FILE)
	end
	local valid, result = ValidateAndLoad(devSource)
	if not valid then
		Logger.Error("DEV_MODE validation failed: " .. tostring(result))
		return
	end
	Library = result
	Logger.Info("Loader", "Local library loaded.")
else
	Logger.Info("Cache", "Checking cache...")
	local cache = ReadCache()
	local librarySource = nil

	if not cache then
		Logger.Info("Cache", "Cache missing. Downloading...")
		local latest = DownloadLatest()
		if not latest then
			Logger.Error("Failed to download LRXUI. No cache available.")
			return
		end
		local valid, result = ValidateAndLoad(latest.UI)
		if not valid then
			Logger.Error("Validation failed: " .. tostring(result))
			return
		end
		local versionToWrite = latest.Version or CONSTANTS.Version.UI
		WriteCache(latest.UI, versionToWrite)
		Library = result
		librarySource = latest.UI
		Logger.Info("Cache", "Cache created.")
	else
		Logger.Info("Cache", "Cache found. Version: " .. tostring(cache.Version))
		if cache.Version == CONSTANTS.Version.UI then
			Logger.Info("Cache", "Cache up to date.")
			librarySource = cache.UI
		else
			Logger.Info("Cache", "Version mismatch. Downloading...")
			local latest = DownloadLatest()
			if not latest then
				Logger.Warn("Cache", "Download failed. Using cache fallback.")
				librarySource = cache.UI
			else
				local valid, result = ValidateAndLoad(latest.UI)
				if not valid then
					Logger.Warn("Cache", "Validation failed. Using cache fallback.")
					librarySource = cache.UI
				else
					local versionToWrite = latest.Version or cache.Version
					WriteCache(latest.UI, versionToWrite)
					Library = result
					librarySource = latest.UI
					Logger.Info("Cache", "Cache updated.")
				end
			end
		end
	end

	if not Library and librarySource then
		local valid, result = ValidateAndLoad(librarySource)
		if not valid then
			Logger.Error("Failed to load cached library: " .. tostring(result))
			return
		end
		Library = result
	end
end

if not Library then
	Logger.Error("No library source available.")
	return
end

getgenv().Library = Library

--==============================================================================
-- CONFIG PERSISTENCE
--==============================================================================
local SavedConfig = {}
pcall(function()
	if readfile and isfile and isfile(CONSTANTS.Config.FILE) then
		local saved = HttpService:JSONDecode(readfile(CONSTANTS.Config.FILE))
		if type(saved) == "table" then
			SavedConfig = saved
		end
	end
end)

for k, v in pairs(DEFAULT_CONFIG) do
	if SavedConfig[k] == nil then
		SavedConfig[k] = v
	end
end

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
	if key == "AutoSaveConfig" or (SavedConfig["AutoSaveConfig"] ~= false) then
		SaveConfig()
	end
end

_G.LRX_Connections = _G.LRX_Connections or {}
_G.LRX_KillSwitch = false

--==============================================================================
-- BUILD UI
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

--==============================================================================
-- TABS
--==============================================================================

local HomeTab = Window:AddTab("Home", "house", "Welcome to LRX Hub!")
local HomeLeft = HomeTab:AddLeftGroupbox("Welcome", "user")
local HomeRight = HomeTab:AddRightGroupbox("Status", "activity")

local statusLabel = HomeLeft:AddLabel("Status: idle")
local pingLabel = HomeLeft:AddLabel("Ping: -- ms")

HomeRight:AddLabel("Client Info:")
HomeRight:AddLabel("Version: " .. CONSTANTS.Version.HUB)
HomeRight:AddLabel("Plan: " .. tostring(_G.LRX_Plan or "Free"))
HomeRight:AddLabel("Game: " .. placeName)
HomeRight:AddDivider()

local discordBtn = HomeRight:AddButton("Copy Discord", function()
	if setclipboard then
		setclipboard("discord.gg/lrxhub")
		Library:Notify({
			Title = "Copied!",
			Description = "Discord invite copied to clipboard.",
			Time = 3,
		})
	end
end)

discordBtn:AddButton("Copy Game ID", function()
	if setclipboard then
		setclipboard(tostring(game.PlaceId))
		Library:Notify({ Title = "Game ID Copied", Description = tostring(game.PlaceId), Time = 2 })
	end
end)

spawn(function()
	while wait(2) do
		if statusLabel and statusLabel.SetText then
			statusLabel:SetText("Status: Running | Players: " .. #Players:GetPlayers())
		end
		if pingLabel and pingLabel.SetText then
			local ping = "N/A"
			pcall(function()
				local stats = StatsService.Network.ServerStatsItem
				if stats and stats["Data Ping"] then
					ping = math.floor(stats["Data Ping"]:GetValue()) .. " ms"
				end
			end)
			pingLabel:SetText("Ping: " .. ping)
		end
	end
end)

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

SettingsLeft:AddDivider()
SettingsLeft:AddLabel("Key: " .. tostring(_G.LRX_Key and _G.LRX_Key:sub(1, 8) .. "****" or "N/A"))
SettingsLeft:AddLabel("HWID: " .. HWID:sub(1, 12) .. "...")

SettingsRight:AddLabel("(!) Close All stops automation & UI.")
SettingsRight:AddLabel("Your settings are saved automatically.")
SettingsRight:AddDivider()

SettingsRight:AddButton("Close All / Stop Everything", function()
	_G.AutoFarmEnabled = false
	_G.LRX_KillSwitch = true
	_G.LRX_Authenticated = false

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
						delfile("LRX_Hub_Key.txt")
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

task.delay(2, function()
	pcall(function()
		local announcements = Backend.GetAnnouncements()
		if announcements and #announcements > 0 then
			for _, ann in ipairs(announcements) do
				if ann.active then
					Library:Notify({
						Title = "[ANN] " .. (ann.title or "Announcement"),
						Description = ann.content or "",
						Time = 8,
					})
				end
			end
		end
	end)
end)

Logger.Info("Hub", "Main script loaded successfully!")
Logger.Info("Hub", "Plan: " .. tostring(_G.LRX_Plan or "Free"))
