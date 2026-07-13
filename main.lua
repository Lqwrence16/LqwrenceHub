--==============================================================================
--  LRX HUB  |  MAIN LOADER
--==============================================================================

--------------------------------------------------------------------------------
--  SERVICE CACHE
--------------------------------------------------------------------------------
local Services = {
	Http = game:GetService("HttpService"),
	Players = game:GetService("Players"),
	CoreGui = game:GetService("CoreGui"),
	Marketplace = game:GetService("MarketplaceService"),
	Tween = game:GetService("TweenService"),
	Input = game:GetService("UserInputService"),
	Stats = game:GetService("Stats"),
	RunService = game:GetService("RunService"),
	StarterGui = game:GetService("StarterGui"),
}
local LocalPlayer = Services.Players.LocalPlayer

--------------------------------------------------------------------------------
--  CONSTANTS
--------------------------------------------------------------------------------
local CONSTANTS = {
	-- Root of all backend API calls.
	API_BASE = "https://lrx-hub-backend.vercel.app",
	-- Version strings displayed in the UI and used to detect cache staleness.
	HUB_VERSION = "v0.0.05",
	UI_VERSION = "0.0.02",

	-- Remote URLs for the UI library source and its companion version file.
	URLs = {
		UI = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.lua",
		VERSION = "https://raw.githubusercontent.com/Lqwrence16/LqwrenceHub/refs/heads/main/LRXUI.version",
	},

	-- Local file-system paths.  All hub files live under LRXHUB69/.
	Paths = {
		ROOT = "LRXHUB69",
		CACHE_FOLDER = "LRXHUB69/cache",
		CACHE_FILE = "LRXHUB69/cache/LRXUI.lua",
		VERSION_FILE = "LRXHUB69/cache/LRXUI.version",
		KEY_FILE = "LRX_Hub_Key.txt",
		CONFIG_FILE = "LRX_Hub_Config.json",
	},

	-- UI element names destroyed on a clean startup to avoid duplicate windows.
	UI_TARGETS = { "Obsidian", "ObsidanModal", "LRXUI", "LRXUI_Modal" },

	-- Authentication: how many seconds the key UI is shown before timing out.
	AUTH_TIMEOUT = 120,

	-- Heartbeat: ping interval (seconds) and how many consecutive misses
	-- invalidate the session.
	HEARTBEAT_INTERVAL = 30,
	HEARTBEAT_MAX_FAILS = 5,

	-- Networking: max attempts per API call and the starting retry delay.
	-- Each retry doubles the delay (exponential back-off).
	NET_MAX_RETRIES = 3,
	NET_RETRY_DELAY = 1.5,

	-- XOR cipher byte used to obfuscate the saved licence key on disk.
	-- Every byte of the key is XORed against this value before hex-encoding.
	-- Change it freely — just keep it consistent across builds.
	XOR_KEY = 0x5A,
}

--------------------------------------------------------------------------------
--  DEV FLAGS
--  Flip these during local testing only.  Never ship with either set to true.
--------------------------------------------------------------------------------
local DEV_MODE = false -- true → load library from local cache, skip download.
local SKIP_KEYCHECK = false -- true → skip authentication entirely.

--------------------------------------------------------------------------------
--  DEFAULT CONFIG
--  Applied when no saved config exists or when a setting key is missing.
--------------------------------------------------------------------------------
local DEFAULT_CONFIG = {
	AutoSaveConfig = true,
	AutoFarm = false,
	AutoBuySeeds = false,
	ShowNotifications = true,
}

--------------------------------------------------------------------------------
--  RUNTIME STATE
--  Mutable values that describe the current session.
--  Never cache these at module level — always read from here.
--------------------------------------------------------------------------------
local Runtime = {
	HeartbeatActive = false, -- true while the background heartbeat loop is alive.
	HeartbeatFails = 0, -- consecutive heartbeat misses this session.
	PlaceInfo = nil, -- cached table from MarketplaceService:GetProductInfo.
	KeyVerifying = false, -- debounce flag for the login button.
	EnterConnection = nil, -- RBXScriptConnection for the keyboard-Enter shortcut.
	HWID = "", -- hardware identifier, resolved exactly once at startup.
}

--------------------------------------------------------------------------------
--  LOGGER
--  Thin wrapper around print / warn / error.
--  Debug output is gated behind DEV_MODE so prod runs stay clean.
--------------------------------------------------------------------------------
local Logger = {}

function Logger.Debug(tag, msg)
	if DEV_MODE then
		print(string.format("[LRX DEBUG | %s] %s", tag, tostring(msg)))
	end
end

function Logger.Info(tag, msg)
	print(string.format("[LRX | %s] %s", tag, tostring(msg)))
end

function Logger.Warn(tag, msg)
	warn(string.format("[LRX WARN | %s] %s", tag, tostring(msg)))
end

-- Raises a hard Lua error with a formatted prefix.
-- Only call this for truly unrecoverable situations.
function Logger.Error(msg)
	error(string.format("[LRX ERROR] %s", tostring(msg)), 2)
end

--------------------------------------------------------------------------------
--  HARDWARE ID RESOLVER
--  Tries executor-specific APIs in priority order, then falls back to a
--  deterministic hash derived from UserId + PlaceId.
--  The fallback is stable per player+game so downstream code can still rely
--  on the value, but it is prefixed "FB_" so you can detect it server-side.
--------------------------------------------------------------------------------
local function ResolveHWID()
	local hwid = ""

	-- Attempt 1 — generic gethwid() (most modern executors).
	pcall(function()
		if gethwid then
			hwid = gethwid()
		end
	end)
	if hwid ~= "" then
		return hwid
	end

	-- Attempt 2 — Synapse X.
	pcall(function()
		if syn and syn.get_hwid then
			hwid = syn.get_hwid()
		end
	end)
	if hwid ~= "" then
		return hwid
	end

	-- Attempt 3 — KRNL global.
	pcall(function()
		if KRNL_LOADED and KRNL_HWID then
			hwid = KRNL_HWID
		end
	end)
	if hwid ~= "" then
		return hwid
	end

	-- Fallback — polynomial rolling hash over "UserId_PlaceId".
	local seed = tostring(LocalPlayer.UserId) .. "_" .. tostring(game.PlaceId)
	local hash = 0
	for i = 1, #seed do
		-- Bernstein-style djb2: hash = hash * 31 + byte, bounded to int range.
		hash = ((hash * 31) + string.byte(seed, i)) % 2147483647
	end
	return "FB_" .. tostring(hash)
end

Runtime.HWID = ResolveHWID()
Logger.Debug("HWID", "Resolved: " .. Runtime.HWID)

--------------------------------------------------------------------------------
--  KEY ENCODING / DECODING
--  XOR cipher: each plaintext byte is XORed against CONSTANTS.XOR_KEY,
--  then represented as two lowercase hex digits.  The full encoded string is
--  what gets written to LRX_Hub_Key.txt.
--
--  This is lightweight obfuscation — not cryptography — but it stops the key
--  being visible to a casual glance at the file.
--------------------------------------------------------------------------------

-- Encodes a plaintext key string → hex-encoded XOR-ciphered string.
local function EncodeKey(key)
	if not key or key == "" then
		return ""
	end
	local parts = {}
	for i = 1, #key do
		-- XOR byte against the cipher key, then emit as two hex digits.
		parts[i] = string.format("%02x", bit32.bxor(string.byte(key, i), CONSTANTS.XOR_KEY))
	end
	return table.concat(parts)
end

-- Decodes a hex-encoded XOR-ciphered string → plaintext key.
-- If the string isn't valid encoded hex, it is returned unchanged (legacy
-- plain-text keys stored by older versions).
local function DecodeKey(str)
	if not str or str == "" then
		return ""
	end

	-- Must be an even-length string of hex characters.
	if not str:match("^%x+$") or #str % 2 ~= 0 then
		return str
	end

	local parts = {}
	for i = 1, #str, 2 do
		local byte = tonumber(str:sub(i, i + 1), 16)
		if not byte then
			return str
		end -- Bail on malformed data.
		-- Reverse the XOR to recover the original byte.
		parts[#parts + 1] = string.char(bit32.bxor(byte, CONSTANTS.XOR_KEY))
	end
	return table.concat(parts)
end

--------------------------------------------------------------------------------
--  URL ENCODER
--  Percent-encodes characters that are unsafe in query-string parameters.
--  Used as a last-resort fallback when POSTing through game:HttpGet.
--------------------------------------------------------------------------------
local function UrlEncode(str)
	if not str then
		return ""
	end
	return (
		str:gsub("([^%w _%%%-%.])", function(c)
			return string.format("%%%02X", string.byte(c))
		end):gsub(" ", "+")
	)
end

--------------------------------------------------------------------------------
--  HTTP LAYER
--  All outbound HTTP calls flow through ApiPost / ApiGet.
--
--  Three request mechanisms are tried in order:
--    A) request()          — standard executor global (fastest, most reliable).
--    B) game:HttpPost/Get  — Roblox built-in (limited CORS, good fallback).
--    C) GET with body as query param — absolute last resort for POST calls.
--
--  Failed attempts are retried with exponential back-off up to
--  CONSTANTS.NET_MAX_RETRIES times before giving up.
--------------------------------------------------------------------------------

-- Internal: fires a single HTTP attempt using the best available mechanism.
-- Returns the raw response body string, or nil on failure.
local function TryRequest(method, url, jsonBody)
	local response = nil

	-- A) request() — preferred for all executors that support it.
	local okA, resA = pcall(function()
		return request({
			Url = url,
			Method = method,
			Headers = { ["Content-Type"] = "application/json" },
			Body = jsonBody or "",
		})
	end)
	if okA and resA then
		response = type(resA) == "table" and resA.Body or resA
	end

	-- B) game:HttpPost for POST when request() failed.
	if not response and method == "POST" and jsonBody then
		local okB, resB = pcall(function()
			return game:HttpPost(url, jsonBody, false, "Content-Type: application/json")
		end)
		if okB and resB then
			response = resB
		end
	end

	-- C) Encode the body as a GET query string (last resort for any method).
	if not response then
		local fallbackUrl = url .. (jsonBody and ("?data=" .. UrlEncode(jsonBody)) or "")
		local okC, resC = pcall(function()
			return game:HttpGet(fallbackUrl, true)
		end)
		if okC and resC then
			response = resC
		end
	end

	return response
end

-- Sends a POST to `endpoint` with `body` (Lua table → JSON).
-- Returns a decoded Lua table on success, or { success=false, error=msg } on failure.
local function ApiPost(endpoint, body)
	local url = CONSTANTS.API_BASE .. endpoint
	local payload = Services.Http:JSONEncode(body)
	local delay = CONSTANTS.NET_RETRY_DELAY

	for attempt = 1, CONSTANTS.NET_MAX_RETRIES do
		local raw = TryRequest("POST", url, payload)

		if raw and raw ~= "" then
			local ok, data = pcall(function()
				return Services.Http:JSONDecode(raw)
			end)
			if ok and data then
				return data
			end -- Successful decode — return early.
		end

		-- Warn on non-final failures, then wait before retrying.
		if attempt < CONSTANTS.NET_MAX_RETRIES then
			Logger.Warn(
				"Net",
				string.format(
					"POST %s failed (attempt %d/%d). Retrying in %.1fs…",
					endpoint,
					attempt,
					CONSTANTS.NET_MAX_RETRIES,
					delay
				)
			)
			task.wait(delay)
			delay = delay * 2 -- Double the wait each time (exponential back-off).
		end
	end

	Logger.Warn("Net", "POST " .. endpoint .. " exhausted all retries.")
	return { success = false, error = "Request failed after " .. CONSTANTS.NET_MAX_RETRIES .. " retries" }
end

-- Sends a GET to `endpoint`.
-- Returns a decoded Lua table on success, or nil on failure.
local function ApiGet(endpoint)
	local url = CONSTANTS.API_BASE .. endpoint
	local delay = CONSTANTS.NET_RETRY_DELAY

	for attempt = 1, CONSTANTS.NET_MAX_RETRIES do
		local raw = TryRequest("GET", url, nil)

		if raw and raw ~= "" then
			local ok, data = pcall(function()
				return Services.Http:JSONDecode(raw)
			end)
			if ok and data then
				return data
			end
		end

		if attempt < CONSTANTS.NET_MAX_RETRIES then
			Logger.Warn(
				"Net",
				string.format(
					"GET %s failed (attempt %d/%d). Retrying in %.1fs…",
					endpoint,
					attempt,
					CONSTANTS.NET_MAX_RETRIES,
					delay
				)
			)
			task.wait(delay)
			delay = delay * 2
		end
	end

	Logger.Warn("Net", "GET " .. endpoint .. " exhausted all retries.")
	return nil
end

--------------------------------------------------------------------------------
--  BACKEND MODULE
--  Every call to the remote API is wrapped here.
--  Callers never touch ApiPost / ApiGet directly; they go through Backend.*.
--  This keeps the HTTP mechanics decoupled from business logic.
--------------------------------------------------------------------------------
local Backend = {}

-- Checks whether a hub update is available (or forced).
-- Returns a table: { update, version, download, force, changelog }
function Backend.CheckVersion()
	local data = ApiGet("/api/version")
	if not data then
		return { update = false }
	end
	return {
		update = data.force_update or (CONSTANTS.HUB_VERSION ~= data.version),
		version = data.version,
		download = data.download,
		force = data.force_update,
		changelog = data.changelog or "",
	}
end

-- Submits a key for validation.
-- Returns { success=true, plan, expires_at, message }  on success.
-- Returns { success=false, error }                      on failure.
function Backend.VerifyKey(key)
	if not key or key == "" then
		return { success = false, error = "No key provided" }
	end

	local data = ApiPost("/api/verify", {
		key = key,
		userid = tostring(LocalPlayer.UserId),
		username = LocalPlayer.Name,
		executor = (identifyexecutor and identifyexecutor()) or "Unknown",
		hwid = Runtime.HWID,
		version = CONSTANTS.HUB_VERSION,
	})

	if data and data.valid then
		return {
			success = true,
			plan = data.plan or "free",
			expires_at = data.expires_at,
			message = data.message,
		}
	end
	return {
		success = false,
		error = (data and (data.reason or data.error)) or "Invalid key",
	}
end

-- Records a launch event for analytics.  Fire-and-forget; failure is non-fatal.
-- Runs in its own task so it never delays startup.
function Backend.TrackLaunch(key)
	local placeName = "Unknown"
	pcall(function()
		placeName = Runtime.PlaceInfo and Runtime.PlaceInfo.Name or "Unknown"
	end)

	task.spawn(function()
		ApiPost("/api/launch", {
			key = key,
			hwid = Runtime.HWID,
			username = LocalPlayer.Name,
			user_id = LocalPlayer.UserId,
			place_id = game.PlaceId,
			place_name = placeName,
			executor = (identifyexecutor and identifyexecutor()) or "Unknown",
		})
	end)
end

-- Starts a background heartbeat loop that pings the backend every
-- HEARTBEAT_INTERVAL seconds to prove the session is still alive.
-- If HEARTBEAT_MAX_FAILS consecutive pings fail, the session is invalidated.
function Backend.StartHeartbeat(key)
	-- Guard: only one heartbeat loop per session.
	if Runtime.HeartbeatActive then
		Logger.Debug("Heartbeat", "Already running — skipping duplicate start.")
		return
	end

	Runtime.HeartbeatActive = true
	Runtime.HeartbeatFails = 0

	task.spawn(function()
		while _G.LRX_Authenticated do
			task.wait(CONSTANTS.HEARTBEAT_INTERVAL)
			if not _G.LRX_Authenticated then
				break
			end -- Re-check after the wait.

			local ok, result = pcall(function()
				return ApiPost("/api/heartbeat", { key = key, hwid = Runtime.HWID })
			end)

			if ok and result and result.success then
				Runtime.HeartbeatFails = 0 -- Reset on a clean ping.
			else
				Runtime.HeartbeatFails = Runtime.HeartbeatFails + 1
				Logger.Warn(
					"Heartbeat",
					string.format("Missed ping %d/%d.", Runtime.HeartbeatFails, CONSTANTS.HEARTBEAT_MAX_FAILS)
				)
			end

			-- Too many misses in a row → invalidate the session and exit.
			if Runtime.HeartbeatFails >= CONSTANTS.HEARTBEAT_MAX_FAILS then
				_G.LRX_Authenticated = false
				Logger.Warn("Heartbeat", "Max failures reached — session invalidated.")
				break
			end
		end

		Runtime.HeartbeatActive = false
		Logger.Debug("Heartbeat", "Loop exited.")
	end)
end

-- Convenience wrappers for additional backend endpoints.
function Backend.GetAnnouncements()
	local d = ApiGet("/api/announcement")
	return (d and d.announcements) or {}
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

--------------------------------------------------------------------------------
--  KEY SYSTEM UI  (BuildKeyUI)
--  Assembles the authentication card and returns a public interface table.
--  All UI concerns are isolated here — the auth flow above never touches
--  Instance constructors directly.
--------------------------------------------------------------------------------
local function BuildKeyUI()
	--------------------------------------------------------------------------
	--  Internal helpers to reduce repetition when building UI frames.
	--------------------------------------------------------------------------

	-- Attaches a UICorner with `radius` to `parent`.
	local function AddCorner(parent, radius)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius or 8)
		c.Parent = parent
	end

	-- Attaches a UIStroke to `parent`.
	local function AddStroke(parent, color, thickness)
		local s = Instance.new("UIStroke")
		s.Color = color or Color3.fromRGB(50, 50, 50)
		s.Thickness = thickness or 1
		s.Parent = parent
	end

	-- Creates a TextLabel with the most common defaults pre-filled.
	local function MakeLabel(parent, text, size, bold, color, pos, labelSize)
		local lbl = Instance.new("TextLabel")
		lbl.Size = labelSize or UDim2.new(1, 0, 0, 24)
		lbl.Position = pos or UDim2.fromOffset(0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
		lbl.TextSize = size or 13
		lbl.Font = bold and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans
		lbl.Parent = parent
		return lbl
	end

	--------------------------------------------------------------------------
	--  Root ScreenGui
	--  Attempt CoreGui first (more reliable), fall back to PlayerGui.
	--------------------------------------------------------------------------
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LRX_KeySystem"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 99 -- Render on top of everything else.

	local parentOk = pcall(function()
		screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		--screenGui.Parent = Services.CoreGui
	end)
	--if not parentOk or not screenGui.Parent then
	--	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	--end

	--------------------------------------------------------------------------
	--  Card (main container)
	--------------------------------------------------------------------------
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromOffset(390, 250)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
	card.BorderSizePixel = 0
	card.Parent = screenGui
	AddCorner(card, 12)
	AddStroke(card, Color3.fromRGB(32, 32, 32), 1)

	-- Amber accent bar at the very top of the card.
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(1, 0, 0, 3)
	accentBar.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 2
	accentBar.Parent = card
	AddCorner(accentBar, 3)

	--------------------------------------------------------------------------
	--  Header labels
	--------------------------------------------------------------------------
	MakeLabel(card, "LRX Hub", 22, true, nil, UDim2.fromOffset(0, 18), UDim2.new(1, 0, 0, 32))
	MakeLabel(
		card,
		"Key Authentication",
		12,
		false,
		Color3.fromRGB(120, 120, 120),
		UDim2.fromOffset(0, 50),
		UDim2.new(1, 0, 0, 18)
	)

	--------------------------------------------------------------------------
	--  Input row: text box + paste button
	--------------------------------------------------------------------------
	local inputFrame = Instance.new("Frame")
	inputFrame.Size = UDim2.new(1, -40, 0, 40)
	inputFrame.Position = UDim2.fromOffset(20, 82)
	inputFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	inputFrame.BorderSizePixel = 0
	inputFrame.Parent = card
	AddCorner(inputFrame, 7)
	AddStroke(inputFrame, Color3.fromRGB(42, 42, 42), 1)

	local keyInput = Instance.new("TextBox")
	keyInput.Name = "KeyInput"
	keyInput.Size = UDim2.new(1, -48, 1, 0)
	keyInput.Position = UDim2.fromOffset(12, 0)
	keyInput.BackgroundTransparency = 1
	keyInput.Text = ""
	keyInput.PlaceholderText = "Enter your LRX key…"
	keyInput.TextColor3 = Color3.fromRGB(235, 235, 235)
	keyInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
	keyInput.TextSize = 13
	keyInput.Font = Enum.Font.BuilderSans
	keyInput.ClearTextOnFocus = false
	keyInput.Parent = inputFrame

	-- Clipboard paste button (📋 emoji icon).
	local pasteBtn = Instance.new("TextButton")
	pasteBtn.Size = UDim2.fromOffset(40, 40)
	pasteBtn.Position = UDim2.new(1, -40, 0, 0)
	pasteBtn.BackgroundTransparency = 1
	pasteBtn.Text = "📋"
	pasteBtn.TextSize = 16
	pasteBtn.Parent = inputFrame

	pasteBtn.MouseButton1Click:Connect(function()
		local clip = ""
		pcall(function()
			if getclipboard then
				clip = getclipboard()
			end
		end)
		if clip ~= "" then
			keyInput.Text = clip
		end
	end)

	--------------------------------------------------------------------------
	--  Status / error label  (toggled between red and green by SetStatus)
	--------------------------------------------------------------------------
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -40, 0, 22)
	statusLabel.Position = UDim2.fromOffset(20, 130)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.BuilderSans
	statusLabel.TextWrapped = true
	statusLabel.Parent = card

	--------------------------------------------------------------------------
	--  Login button with hover tween
	--------------------------------------------------------------------------
	local loginBtn = Instance.new("TextButton")
	loginBtn.Name = "LoginBtn"
	loginBtn.Size = UDim2.new(1, -40, 0, 40)
	loginBtn.Position = UDim2.fromOffset(20, 158)
	loginBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11) -- Amber brand.
	loginBtn.BorderSizePixel = 0
	loginBtn.Text = "Authenticate"
	loginBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
	loginBtn.TextSize = 14
	loginBtn.Font = Enum.Font.BuilderSansBold
	loginBtn.Parent = card
	AddCorner(loginBtn, 7)

	-- Smooth colour tween on mouse enter / leave.
	local AMBER_NORMAL = Color3.fromRGB(245, 158, 11)
	local AMBER_HOVER = Color3.fromRGB(217, 119, 6)

	loginBtn.MouseEnter:Connect(function()
		Services.Tween:Create(loginBtn, TweenInfo.new(0.12), { BackgroundColor3 = AMBER_HOVER }):Play()
	end)
	loginBtn.MouseLeave:Connect(function()
		Services.Tween:Create(loginBtn, TweenInfo.new(0.12), { BackgroundColor3 = AMBER_NORMAL }):Play()
	end)

	--------------------------------------------------------------------------
	--  Discord / get-key link
	--------------------------------------------------------------------------
	local discordBtn = Instance.new("TextButton")
	discordBtn.Size = UDim2.new(1, -40, 0, 26)
	discordBtn.Position = UDim2.fromOffset(20, 212)
	discordBtn.BackgroundTransparency = 1
	discordBtn.Text = "Get a key  •  discord.gg/lrxhub"
	discordBtn.TextColor3 = Color3.fromRGB(110, 110, 110)
	discordBtn.TextSize = 11
	discordBtn.Font = Enum.Font.BuilderSans
	discordBtn.Parent = card

	discordBtn.MouseButton1Click:Connect(function()
		pcall(function()
			if setclipboard then
				setclipboard("discord.gg/lrxhub")
			end
		end)
		pcall(function()
			Services.StarterGui:SetCore(
				"SendNotification",
				{ Title = "Discord", Text = "Invite link copied!", Duration = 3 }
			)
		end)
	end)

	--------------------------------------------------------------------------
	--  Loading overlay  (shown while the API call is in-flight)
	--------------------------------------------------------------------------
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
	overlay.BackgroundTransparency = 0.2
	overlay.Visible = false
	overlay.ZIndex = 10
	overlay.Parent = card
	AddCorner(overlay, 12)

	local overlayLabel = Instance.new("TextLabel")
	overlayLabel.Size = UDim2.fromScale(1, 1)
	overlayLabel.BackgroundTransparency = 1
	overlayLabel.Text = "Contacting server…"
	overlayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	overlayLabel.TextSize = 14
	overlayLabel.Font = Enum.Font.BuilderSansBold
	overlayLabel.ZIndex = 11
	overlayLabel.Parent = overlay

	--------------------------------------------------------------------------
	--  Drag logic  — allows the card to be repositioned by click-dragging.
	--------------------------------------------------------------------------
	local dragging, dragOrigin, cardOrigin = false, nil, nil

	card.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragOrigin = input.Position
			cardOrigin = card.Position
		end
	end)

	Services.Input.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local d = input.Position - dragOrigin
			card.Position =
				UDim2.new(cardOrigin.X.Scale, cardOrigin.X.Offset + d.X, cardOrigin.Y.Scale, cardOrigin.Y.Offset + d.Y)
		end
	end)

	Services.Input.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	--------------------------------------------------------------------------
	--  Public interface returned to the auth flow.
	--------------------------------------------------------------------------
	return {
		ScreenGui = screenGui,
		Card = card,
		KeyInput = keyInput,
		LoginBtn = loginBtn,

		-- Updates the status label text and colour.
		-- Pass isError=true for red (failure), false for green (success).
		SetStatus = function(text, isError)
			statusLabel.TextColor3 = isError and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(80, 210, 95)
			statusLabel.Text = text or ""
		end,

		-- Shows or hides the blocking loading overlay.
		SetLoading = function(active, text)
			overlay.Visible = active
			if text then
				overlayLabel.Text = text
			end
		end,

		-- Safely destroys the entire ScreenGui.
		Destroy = function()
			pcall(function()
				screenGui:Destroy()
			end)
		end,
	}
end

--------------------------------------------------------------------------------
--  KEY AUTHENTICATION FLOW  (RunKeySystem)
--  Drives the full three-step auth sequence:
--    1. Dev / skip flags → immediate pass.
--    2. Force-update check → hard abort if server demands it.
--    3. Silent re-auth from saved key → skip the UI if the key is still valid.
--    4. Manual key entry → show UI and wait.
--
--  Returns: (authenticated: bool, authResult: table | nil)
--------------------------------------------------------------------------------
local function RunKeySystem()
	-- Step 1 — Dev override.
	if SKIP_KEYCHECK then
		Logger.Info("Auth", "Key check bypassed via SKIP_KEYCHECK flag.")
		_G.LRX_Authenticated = true
		return true, nil
	end

	-- Step 2 — Force-update guard.
	local versionInfo = Backend.CheckVersion()
	if versionInfo and versionInfo.force then
		pcall(function()
			Services.StarterGui:SetCore("SendNotification", {
				Title = "LRX Hub",
				Text = "FORCE UPDATE REQUIRED — please re-download.",
				Duration = 15,
			})
		end)
		Logger.Error("Force update required.  Aborting loader.")
	end

	-- Step 3 — Silent re-auth from disk.
	local savedKey = ""
	pcall(function()
		if isfile and isfile(CONSTANTS.Paths.KEY_FILE) then
			savedKey = DecodeKey(readfile(CONSTANTS.Paths.KEY_FILE))
		end
	end)

	if savedKey ~= "" then
		Logger.Info("Auth", "Saved key found — attempting silent login…")
		local result = Backend.VerifyKey(savedKey)
		if result.success then
			Logger.Info("Auth", "Silent login OK.  Plan: " .. tostring(result.plan))
			_G.LRX_Key = savedKey
			_G.LRX_Authenticated = true
			_G.LRX_Plan = result.plan
			Backend.TrackLaunch(savedKey)
			Backend.StartHeartbeat(savedKey)
			return true, result
		else
			Logger.Warn("Auth", "Saved key rejected: " .. tostring(result.error))
		end
	end

	-- Step 4 — Manual entry UI.
	local ui = BuildKeyUI()
	local authenticated = false
	local authResult = nil
	local startTime = tick()

	-- Allow the Enter key to trigger the login button while the TextBox is focused.
	Runtime.EnterConnection = Services.Input.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if
			(input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter)
			and ui.KeyInput:IsFocused()
		then
			ui.LoginBtn:Activate()
		end
	end)

	--  Login button handler.
	ui.LoginBtn.MouseButton1Click:Connect(function()
		if Runtime.KeyVerifying then
			return
		end -- Debounce — prevent double-submit.
		Runtime.KeyVerifying = true
		ui.LoginBtn.Active = false

		-- Strip surrounding whitespace the player may have accidentally pasted.
		local key = ui.KeyInput.Text:match("^%s*(.-)%s*$")
		if key == "" then
			ui.SetStatus("Please enter a key.", true)
			Runtime.KeyVerifying = false
			ui.LoginBtn.Active = true
			return
		end

		ui.SetStatus("")
		ui.SetLoading(true, "Contacting server…")
		ui.LoginBtn.Text = "Verifying…"

		local result = Backend.VerifyKey(key)

		ui.SetLoading(false)
		ui.LoginBtn.Text = "Authenticate"
		ui.LoginBtn.Active = true

		if result.success then
			-- Write the XOR-encoded key to disk for silent re-auth next launch.
			pcall(function()
				if writefile then
					writefile(CONSTANTS.Paths.KEY_FILE, EncodeKey(key))
				end
			end)

			_G.LRX_Key = key
			_G.LRX_Authenticated = true
			_G.LRX_Plan = result.plan

			Backend.TrackLaunch(key)
			Backend.StartHeartbeat(key)

			ui.SetStatus("Authenticated!  Loading hub…", false)
			authenticated = true
			authResult = result

			task.wait(0.6) -- Brief pause so the user can see the success message.
			ui.Destroy()
		else
			ui.SetStatus(result.error or "Invalid key — try again.", true)
		end

		Runtime.KeyVerifying = false
	end)

	-- Blocking wait: yield until the user authenticates, times out, or closes the UI.
	while not authenticated do
		task.wait(0.1)

		if tick() - startTime > CONSTANTS.AUTH_TIMEOUT then
			ui.SetStatus("Session timed out.  Please re-execute.", true)
			Logger.Warn("Auth", "Authentication timed out.")
			break
		end

		-- Safety: if the GUI was somehow destroyed externally, exit cleanly.
		if not ui.ScreenGui or not ui.ScreenGui.Parent then
			break
		end
	end

	-- Disconnect the Enter-key shortcut regardless of how we exited.
	pcall(function()
		if Runtime.EnterConnection then
			Runtime.EnterConnection:Disconnect()
			Runtime.EnterConnection = nil
		end
	end)

	return authenticated, authResult
end

--------------------------------------------------------------------------------
--  FILE-SYSTEM UTILITIES
--  Thin, pcall-guarded wrappers so callers never need to handle FS errors.
--------------------------------------------------------------------------------

-- Returns the file contents at `path`, or nil if the file does not exist.
local function ReadFile(path)
	if not (isfile and isfile(path)) then
		return nil
	end
	local ok, data = pcall(readfile, path)
	return (ok and data and #data > 0) and data or nil
end

-- Writes `data` to `path`.  Returns true on success.
local function WriteFile(path, data)
	if not writefile then
		return false
	end
	return pcall(writefile, path, data)
end

-- Creates the required folder hierarchy under LRXHUB69/ if it does not exist.
local function EnsureCacheFolders()
	if not makefolder then
		return
	end
	if not isfolder(CONSTANTS.Paths.ROOT) then
		pcall(makefolder, CONSTANTS.Paths.ROOT)
	end
	if not isfolder(CONSTANTS.Paths.CACHE_FOLDER) then
		pcall(makefolder, CONSTANTS.Paths.CACHE_FOLDER)
	end
end

-- Downloads `url` and returns the raw string, or nil on failure.
local function FetchRaw(url)
	if not url then
		return nil
	end
	local ok, data = pcall(function()
		return game:HttpGet(url, true)
	end)
	return (ok and data and #data > 0) and data or nil
end

--------------------------------------------------------------------------------
--  VALIDATORS
--  Guard against accepting HTML error pages or tiny stub strings as valid
--  library source or version data.
--------------------------------------------------------------------------------

-- Returns true when `str` looks like a genuine version string (not a 404 page).
local function IsValidVersion(str)
	if type(str) ~= "string" or #str == 0 or not str:match("%S") then
		return false
	end
	local lo = str:lower()
	return not (
		str:find("<!DOCTYPE", 1, true)
		or str:find("<html", 1, true)
		or lo:find("not found")
		or lo:find("404")
		or (lo:find("error") and #str < 200)
	)
end

-- Returns true when `str` looks like valid Lua library source code.
local function IsValidLibSource(str)
	if type(str) ~= "string" or #str <= 100 then
		return false
	end
	if str:find("<!DOCTYPE", 1, true) or str:find("<html", 1, true) then
		return false
	end
	-- If the first line looks like "404 Not Found" etc., reject it.
	local firstLine = str:match("^([^\n]*)")
	return not (firstLine and firstLine:match("^%d%d%d[%s:]"))
end

--------------------------------------------------------------------------------
--  CACHE LAYER
--  Caches the UI library source locally so repeated executions skip the
--  GitHub download when the version has not changed.
--------------------------------------------------------------------------------

-- Reads the cached UI source and version.
-- Returns { UI, Version } if both files exist and are non-empty, else nil.
local function ReadCache()
	local ui = ReadFile(CONSTANTS.Paths.CACHE_FILE)
	local version = ReadFile(CONSTANTS.Paths.VERSION_FILE)
	if not ui or #ui < 100 or not version or #version == 0 then
		return nil
	end
	return { UI = ui, Version = version }
end

-- Writes UI source and version to the local cache.
local function WriteCache(uiSource, version)
	local ok1 = uiSource and WriteFile(CONSTANTS.Paths.CACHE_FILE, uiSource) or true
	local ok2 = version and WriteFile(CONSTANTS.Paths.VERSION_FILE, version) or true
	return ok1 and ok2
end

-- Downloads the latest UI library and version from the configured GitHub URLs.
-- Returns { UI, Version } on success, or nil on failure.
local function DownloadLatestLib()
	Logger.Info("Cache", "Fetching library from remote…")

	local uiSource = FetchRaw(CONSTANTS.URLs.UI)
	if not uiSource or not IsValidLibSource(uiSource) then
		Logger.Warn("Cache", "Library download returned invalid content.")
		return nil
	end

	local version = FetchRaw(CONSTANTS.URLs.VERSION)
	if not IsValidVersion(version) then
		Logger.Warn("Cache", "Version file invalid — will retain cached version string.")
		version = nil -- Non-fatal: caller falls back to the existing version tag.
	end

	Logger.Info("Cache", "Remote fetch complete.")
	return { UI = uiSource, Version = version }
end

--------------------------------------------------------------------------------
--  LIBRARY LOADER  (LoadLibSource)
--  Compiles and executes a Lua source string.
--  Returns (true, table)   on success.
--  Returns (false, string) on any compile or runtime error.
--------------------------------------------------------------------------------
local function LoadLibSource(source)
	if type(source) ~= "string" or #source <= 100 then
		return false, "Source is nil or suspiciously short"
	end

	-- Compile to a Lua function.
	local chunk, compileErr = loadstring(source)
	if not chunk then
		return false, "Compile error: " .. tostring(compileErr)
	end

	-- Execute with full traceback so we can surface runtime errors cleanly.
	local ok, result = xpcall(chunk, debug.traceback)
	if not ok then
		return false, "Runtime error: " .. tostring(result)
	end

	-- The library must return a table that exposes its API.
	if type(result) ~= "table" then
		return false, "Expected table return, got " .. type(result)
	end

	return true, result
end

--------------------------------------------------------------------------------
--  UI CLEANUP
--  Destroys any remnant hub windows from a previous script execution to
--  ensure a clean slate before building the new UI.
--------------------------------------------------------------------------------
local function DestroyHubUI()
	local function PurgeFrom(parent)
		if not parent then
			return
		end
		for _, child in ipairs(parent:GetChildren()) do
			if table.find(CONSTANTS.UI_TARGETS, child.Name) then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end

	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		PurgeFrom(pg)
	end
	PurgeFrom(Services.CoreGui)
end

-- Full teardown: unloads the library, disconnects all connections, resets
-- global flags, and destroys any hub GUI instances.
local function FullCleanup()
	Logger.Info("Cleanup", "Running full session teardown…")

	pcall(function()
		-- Ask the library to clean up its own internals if it supports it.
		if getgenv and getgenv().Library then
			if getgenv().Library.Unload then
				pcall(function()
					getgenv().Library:Unload()
				end)
			end
			getgenv().Library = nil
		end

		-- Disconnect every connection registered during this session.
		if _G.LRX_Connections then
			for _, conn in ipairs(_G.LRX_Connections) do
				pcall(function()
					if conn and conn.Connected then
						conn:Disconnect()
					end
				end)
			end
		end

		-- Reset all shared globals to a clean baseline.
		_G.LRX_Hub_UI = nil
		_G.LRX_Connections = {}
		_G.LRX_KillSwitch = false
		_G.LRX_Authenticated = false

		DestroyHubUI()
	end)

	task.wait(0.15)
	Logger.Info("Cleanup", "Teardown complete.")
end

--==============================================================================
--  ██████  ████████  █████  ██████  ████████
--  ██         ██    ██   ██ ██   ██    ██
--  ███████    ██    ███████ ██████     ██
--       ██    ██    ██   ██ ██   ██    ██
--  ███████    ██    ██   ██ ██   ██    ██
--
--  STARTUP SEQUENCE
--==============================================================================

-- 1. Clean up any artefacts left by a previous execution of this script.
FullCleanup()

-- 2. Cache place info once.  Used in launch tracking and the status panel.
local placeName = "Unknown"
pcall(function()
	Runtime.PlaceInfo = Services.Marketplace:GetProductInfo(game.PlaceId)
	placeName = Runtime.PlaceInfo and Runtime.PlaceInfo.Name or "Unknown"
end)

-- 3. Run key authentication.  Nothing below executes if this fails.
Logger.Info("Auth", "Starting authentication…")
local authOk, _ = RunKeySystem()

if not authOk then
	Logger.Warn("Auth", "Authentication failed or was cancelled — aborting.")
	return -- Hard stop.
end

Logger.Info("Auth", "Authenticated!  Plan: " .. tostring(_G.LRX_Plan or "free"))

-- 4. Ensure the on-disk cache directory tree exists.
EnsureCacheFolders()

--------------------------------------------------------------------------------
--  LIBRARY LOADING PIPELINE
--  Priority order:
--    DEV_MODE  → read from local cache file, no download.
--    Normal    → check cached version → download if stale or missing → load.
--
--  Every path that touches the network falls back to the local cache if the
--  download fails, so a bad connection never leaves the hub un-launchable.
--------------------------------------------------------------------------------
local Library = nil

if DEV_MODE then
	Logger.Info("Loader", "DEV_MODE: loading library from local cache file.")
	local src = ReadFile(CONSTANTS.Paths.CACHE_FILE)
	if not src then
		Logger.Error("DEV_MODE requires " .. CONSTANTS.Paths.CACHE_FILE .. " to exist locally.")
	end
	local ok, result = LoadLibSource(src)
	if not ok then
		Logger.Error("DEV_MODE load failed: " .. tostring(result))
	end
	Library = result
else
	local cache = ReadCache()

	if not cache then
		-- No local cache → must download.
		Logger.Info("Loader", "No local cache — fetching from remote.")
		local latest = DownloadLatestLib()
		if not latest then
			Logger.Error("Remote download failed and no local cache exists — cannot continue.")
		end
		local ok, result = LoadLibSource(latest.UI)
		if not ok then
			Logger.Error("Downloaded library failed validation: " .. tostring(result))
		end

		WriteCache(latest.UI, latest.Version or CONSTANTS.UI_VERSION)
		Library = result
		Logger.Info("Loader", "Library loaded from remote and cached.")
	elseif cache.Version == CONSTANTS.UI_VERSION then
		-- Cache is current — load directly without a network round-trip.
		Logger.Info("Loader", "Cache is up to date (v" .. cache.Version .. ").")
		local ok, result = LoadLibSource(cache.UI)
		if ok then
			Library = result
		else
			Logger.Warn("Loader", "Cached source failed: " .. tostring(result) .. " — re-downloading.")
		end
	else
		-- Version mismatch → attempt an update.
		Logger.Info(
			"Loader",
			string.format(
				"Cache version mismatch (cached: %s, expected: %s) — updating.",
				tostring(cache.Version),
				CONSTANTS.UI_VERSION
			)
		)

		local latest = DownloadLatestLib()
		if latest then
			local ok, result = LoadLibSource(latest.UI)
			if ok then
				WriteCache(latest.UI, latest.Version or cache.Version)
				Library = result
				Logger.Info("Loader", "Cache updated to latest version.")
			else
				Logger.Warn("Loader", "Updated lib failed validation — falling back to cache.")
			end
		else
			Logger.Warn("Loader", "Download failed — falling back to cached version.")
		end
	end

	-- Common fallback: if Library is still nil, try the local cache one last time.
	if not Library and cache then
		Logger.Warn("Loader", "Attempting final fallback load from cache.")
		local ok, result = LoadLibSource(cache.UI)
		if ok then
			Library = result
		else
			Logger.Error("All load paths exhausted — cannot continue: " .. tostring(result))
		end
	end
end

if not Library then
	Logger.Error("Library could not be loaded from any available source.")
end

-- Expose the library globally so game scripts and future modules can reach it.
getgenv().Library = Library
Logger.Info("Loader", "Library is ready.")

--------------------------------------------------------------------------------
--  CONFIG PERSISTENCE
--  Loads saved preferences from disk, merges with defaults, and exposes
--  GetSaved / SetSaved helpers used throughout the UI callbacks below.
--------------------------------------------------------------------------------
local SavedConfig = {}

-- Attempt to parse the on-disk config.  Silently ignore failures.
pcall(function()
	if isfile and isfile(CONSTANTS.Paths.CONFIG_FILE) then
		local raw = readfile(CONSTANTS.Paths.CONFIG_FILE)
		local ok, parsed = pcall(function()
			return Services.Http:JSONDecode(raw)
		end)
		if ok and type(parsed) == "table" then
			SavedConfig = parsed
		end
	end
end)

-- Back-fill any keys that are missing from the saved config.
for k, v in pairs(DEFAULT_CONFIG) do
	if SavedConfig[k] == nil then
		SavedConfig[k] = v
	end
end

-- Writes the current SavedConfig table to disk as JSON.
local function SaveConfig()
	pcall(function()
		if writefile then
			writefile(CONSTANTS.Paths.CONFIG_FILE, Services.Http:JSONEncode(SavedConfig))
		end
	end)
end

-- Returns the saved value for `key`, or `default` if absent.
local function GetSaved(key, default)
	local v = SavedConfig[key]
	return (v ~= nil) and v or default
end

-- Sets a config value and persists to disk if AutoSaveConfig is on.
local function SetSaved(key, value)
	SavedConfig[key] = value
	if SavedConfig.AutoSaveConfig ~= false then
		SaveConfig()
	end
end

-- Initialise shared global state used by feature modules.
_G.LRX_Connections = _G.LRX_Connections or {}
_G.LRX_KillSwitch = false

--==============================================================================
--  WINDOW
--==============================================================================
local Window = Library:CreateWindow({
	Title = "LRX Hub",
	Footer = CONSTANTS.HUB_VERSION,
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
--  HOME TAB
--  Live status display and quick-action buttons.
--==============================================================================
local HomeTab = Window:AddTab("Home", "house", "Welcome to LRX Hub!")
local HomeLeft = HomeTab:AddLeftGroupbox("Info", "user")
local HomeRight = HomeTab:AddRightGroupbox("Client", "activity")

-- Labels refreshed every 2 seconds by the background status loop below.
local statusLabel = HomeLeft:AddLabel("Status : idle")
local pingLabel = HomeLeft:AddLabel("Ping   : -- ms")

HomeRight:AddLabel("Version : " .. CONSTANTS.HUB_VERSION)
HomeRight:AddLabel("Plan    : " .. tostring(_G.LRX_Plan or "Free"))
HomeRight:AddLabel("Game    : " .. placeName)
HomeRight:AddDivider()

local discordBtn = HomeRight:AddButton("Copy Discord Invite", function()
	pcall(function()
		if setclipboard then
			setclipboard("discord.gg/lrxhub")
		end
	end)
	Library:Notify({ Title = "Copied!", Description = "discord.gg/lrxhub", Time = 3 })
end)

discordBtn:AddButton("Copy Place ID", function()
	pcall(function()
		if setclipboard then
			setclipboard(tostring(game.PlaceId))
		end
	end)
	Library:Notify({ Title = "Place ID", Description = tostring(game.PlaceId), Time = 2 })
end)

-- Background loop: refresh status and ping labels every 2 seconds.
-- Exits automatically when the session ends (_G.LRX_Authenticated becomes false).
task.spawn(function()
	while _G.LRX_Authenticated do
		task.wait(2)

		pcall(function()
			if statusLabel and statusLabel.SetText then
				statusLabel:SetText("Status : Running  |  Players: " .. #Services.Players:GetPlayers())
			end
		end)

		pcall(function()
			if pingLabel and pingLabel.SetText then
				local pingText = "N/A"
				local statItem = Services.Stats.Network.ServerStatsItem
				if statItem and statItem["Data Ping"] then
					pingText = math.floor(statItem["Data Ping"]:GetValue()) .. " ms"
				end
				pingLabel:SetText("Ping   : " .. pingText)
			end
		end)
	end
end)

--==============================================================================
--  AUTOMATION TAB
--  Master toggles for background farming routines.
--  Add individual feature toggles / sliders here as your game expands.
--==============================================================================
local AutoTab = Window:AddTab("Automation", "workflow", "Automated farming controls.")
local AutoLeft = AutoTab:AddLeftGroupbox("Auto Farm", "sprout")

AutoLeft:AddToggle("AutoFarmMain", {
	Text = "Enable Auto-Farm",
	Default = GetSaved("AutoFarm", false),
	Tooltip = "Master toggle — enables all farming automation.",
	Callback = function(value)
		SetSaved("AutoFarm", value)
		_G.AutoFarmEnabled = value
	end,
})

--==============================================================================
--  MISC TAB
--  Placeholder groupbox — add utilities and one-off tools here.
--==============================================================================
local MiscTab = Window:AddTab("Misc", "puzzle", "Miscellaneous utilities.")
local _MiscLeft = MiscTab:AddLeftGroupbox("Grid Scanner", "grid-3x3")
-- Insert misc controls here as the project grows.

--==============================================================================
--  SHOP TAB
--  Automated in-game purchasing toggles.
--==============================================================================
local ShopTab = Window:AddTab("Shop", "shopping-cart", "Auto-purchase controls.")
local SeedShop = ShopTab:AddLeftGroupbox("Seed Shop", "apple")

SeedShop:AddToggle("AutoSeedShop", {
	Text = "Auto Buy Seeds",
	Default = GetSaved("AutoBuySeeds", false),
	Tooltip = "Automatically purchases all selected seeds.",
	Callback = function(value)
		SetSaved("AutoBuySeeds", value)
		_G.AutoBuySeeds = value
	end,
})

--==============================================================================
--  SETTINGS TAB
--  Preferences, config management, and session control.
--==============================================================================
local SettingsTab = Window:AddTab("Settings", "settings", "Hub preferences and management.")
local SettingsLeft = SettingsTab:AddLeftGroupbox("General", "settings")
local SettingsRight = SettingsTab:AddRightGroupbox("Danger Zone", "alert-triangle")

--  General preference toggles.
SettingsLeft:AddToggle("ShowNotifications", {
	Text = "Show Notifications",
	Default = GetSaved("ShowNotifications", true),
	Tooltip = "Toggle notification toasts.",
	Callback = function(value)
		SetSaved("ShowNotifications", value)
	end,
})

SettingsLeft:AddToggle("AutoSaveConfig", {
	Text = "Auto-Save Config",
	Default = GetSaved("AutoSaveConfig", true),
	Tooltip = "Persist settings to disk on every change.",
	Callback = function(value)
		SetSaved("AutoSaveConfig", value)
	end,
})

SettingsLeft:AddDivider()

SettingsLeft:AddButton("Export Config to Clipboard", function()
	pcall(function()
		if setclipboard then
			setclipboard(Services.Http:JSONEncode(SavedConfig))
			Library:Notify({ Title = "Exported", Description = "Config JSON copied.", Time = 3 })
		end
	end)
end)

SettingsLeft:AddButton("Force Save Now", function()
	SaveConfig()
	Library:Notify({ Title = "Saved", Description = "Config written to disk.", Time = 2 })
end)

SettingsLeft:AddDivider()

-- Expose only the first 8 characters of the key — never display it in full.
SettingsLeft:AddLabel("Key  : " .. (_G.LRX_Key and (_G.LRX_Key:sub(1, 8) .. "••••") or "N/A"))
SettingsLeft:AddLabel("HWID : " .. Runtime.HWID:sub(1, 14) .. "…")

--  Danger zone — destructive actions.
SettingsRight:AddLabel("⚠  These actions cannot be undone in-session.")
SettingsRight:AddDivider()

-- Graceful shutdown: kills all automation, disconnects listeners, saves config,
-- then destroys the entire hub UI.
SettingsRight:AddButton("Close Hub & Stop All", function()
	_G.AutoFarmEnabled = false
	_G.AutoBuySeeds = false
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

	Library:Notify({ Title = "Closing…", Description = "All automation halted.", Time = 2 })

	task.wait(0.2)
	pcall(function()
		if Library and Library.Unload then
			Library:Unload()
		end
		DestroyHubUI()
	end)

	_G.LRX_Hub_UI = nil
	Logger.Info("Hub", "Closed by user.")
end)

SettingsRight:AddDivider()

-- Full reset: deletes the saved key file and config, then unloads the hub.
-- Wrapped in a confirmation dialog to prevent accidental execution.
SettingsRight:AddButton("Reset All Settings & Key", function()
	Library:Dialog({
		Title = "Reset Everything?",
		Description = "Deletes your saved key and ALL config.  Cannot be undone.",
		Type = "confirm",
		Callback = function(confirmed)
			if not confirmed then
				return
			end

			pcall(function()
				if delfile then
					delfile(CONSTANTS.Paths.CONFIG_FILE)
					delfile(CONSTANTS.Paths.KEY_FILE)
				end
			end)

			SavedConfig = {}

			Library:Notify({
				Title = "Reset Complete",
				Description = "Re-execute to load defaults and re-authenticate.",
				Time = 5,
			})

			task.wait(1)
			if Library and Library.Unload then
				Library:Unload()
			end
		end,
	})
end)

--==============================================================================
--  POST-INIT: ANNOUNCEMENTS
--  Fetched asynchronously after startup so they never delay the UI load.
--==============================================================================
task.delay(2, function()
	pcall(function()
		for _, ann in ipairs(Backend.GetAnnouncements()) do
			if ann.active then
				Library:Notify({
					Title = "[ANN] " .. (ann.title or "Announcement"),
					Description = ann.content or "",
					Time = 8,
				})
			end
		end
	end)
end)

Logger.Info("Hub", "LRX Hub fully loaded!  Plan: " .. tostring(_G.LRX_Plan or "free"))
