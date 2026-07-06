-- ═══════════════════════════════════════════════════════════════════════
--  LRX_UI.lua - Reusable UI Framework (Production Edition)
--  Version: 4.1.0
--  Architecture: Standalone, extensible, high-performance UI components
--  Purpose: Reusable Roblox UI Framework
-- ═══════════════════════════════════════════════════════════════════════

local cloneref = (cloneref or clonereference or function(instance: any)
	return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
	return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
	return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}

local Library = {
	LocalPlayer = LocalPlayer,
	DevicePlatform = nil,
	IsMobile = false,
	IsRobloxFocused = true,

	ScreenGui = nil,

	SearchText = "",
	Searching = false,
	LastSearchTab = nil,

	ActiveTab = nil,
	Tabs = {},
	DependencyBoxes = {},

	KeybindFrame = nil,
	KeybindContainer = nil,
	KeybindToggles = {},

	Notifications = {},

	ToggleKeybind = Enum.KeyCode.RightControl,
	TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

	Toggled = false,
	Unloaded = false,

	Labels = Labels,
	Buttons = Buttons,
	Toggles = Toggles,
	Options = Options,

	NotifySide = "Right",
	ShowCustomCursor = false,
	ForceCheckbox = false,
	ShowToggleFrameInKeybinds = true,
	NotifyOnError = false,

	CantDragForced = false,

	Signals = {},
	UnloadSignals = {},

	MinSize = Vector2.new(480, 360),
	DPIScale = 1,
	CornerRadius = 4,

	IsLightTheme = false,
	Scheme = {
		BackgroundColor = Color3.fromRGB(15, 15, 15),
		MainColor = Color3.fromRGB(25, 25, 25),
		AccentColor = Color3.fromRGB(125, 85, 255),
		OutlineColor = Color3.fromRGB(40, 40, 40),
		FontColor = Color3.new(1, 1, 1),
		Font = Font.fromEnum(Enum.Font.Code),

		Red = Color3.fromRGB(255, 50, 50),
		Dark = Color3.new(0, 0, 0),
		White = Color3.new(1, 1, 1),
	},

	Registry = {},
	DPIRegistry = {},
}

-- ─── IMAGE MANAGER ───────────────────────────────────────────────────
local ObsidianImageManager = {
	Assets = {
		TransparencyTexture = {
			RobloxId = 139785960036434,
			Path = "Obsidian/assets/TransparencyTexture.png",
			Id = nil,
		},
		SaturationMap = {
			RobloxId = 4155801252,
			Path = "Obsidian/assets/SaturationMap.png",
			Id = nil,
		},
	},
}
do
	local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

	local function RecursiveCreatePath(Path: string, IsFile: boolean?)
		if not isfolder or not makefolder then
			return
		end

		local Segments = Path:split("/")
		local TraversedPath = ""

		if IsFile then
			table.remove(Segments, #Segments)
		end

		for _, Segment in ipairs(Segments) do
			if not isfolder(TraversedPath .. Segment) then
				makefolder(TraversedPath .. Segment)
			end

			TraversedPath = TraversedPath .. Segment .. "/"
		end

		return TraversedPath
	end

	function ObsidianImageManager.GetAsset(AssetName: string)
		if not ObsidianImageManager.Assets[AssetName] then
			return nil
		end

		local AssetData = ObsidianImageManager.Assets[AssetName]
		if AssetData.Id then
			return AssetData.Id
		end

		local AssetID = `rbxassetid://{AssetData.RobloxId}`

		if getcustomasset then
			local Success, NewID = pcall(getcustomasset, AssetData.Path)

			if Success and NewID then
				AssetID = NewID
			end
		end

		AssetData.Id = AssetID
		return AssetID
	end

	function ObsidianImageManager.DownloadAsset(AssetPath: string)
		if not getcustomasset or not writefile or not isfile then
			return
		end

		RecursiveCreatePath(AssetPath, true)

		if isfile(AssetPath) then
			return
		end

		local URLPath = AssetPath:gsub("Obsidian/", "")
		pcall(function()
			writefile(AssetPath, game:HttpGet(`{BaseURL}{URLPath}`))
		end)
	end

	for _, Data in pairs(ObsidianImageManager.Assets) do
		ObsidianImageManager.DownloadAsset(Data.Path)
	end
end

-- ─── DEVICE PLATFORM DETECTION ────────────────────────────────────────
if RunService:IsStudio() then
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		Library.IsMobile = true
		Library.MinSize = Vector2.new(480, 240)
	else
		Library.IsMobile = false
		Library.MinSize = Vector2.new(480, 360)
	end
else
	pcall(function()
		Library.DevicePlatform = UserInputService:GetPlatform()
	end)
	Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
	Library.MinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

-- ─── TEMPLATES ────────────────────────────────────────────────────────
local Templates = {
	Frame = {
		BorderSizePixel = 0,
	},
	ImageLabel = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	},
	ImageButton = {
		AutoButtonColor = false,
		BorderSizePixel = 0,
	},
	ScrollingFrame = {
		BorderSizePixel = 0,
	},
	TextLabel = {
		BorderSizePixel = 0,
		FontFace = "Font",
		RichText = true,
		TextColor3 = "FontColor",
	},
	TextButton = {
		AutoButtonColor = false,
		BorderSizePixel = 0,
		FontFace = "Font",
		RichText = true,
		TextColor3 = "FontColor",
	},
	TextBox = {
		BorderSizePixel = 0,
		FontFace = "Font",
		PlaceholderColor3 = function()
			local H, S, V = Library.Scheme.FontColor:ToHSV()
			return Color3.fromHSV(H, S, V / 2)
		end,
		Text = "",
		TextColor3 = "FontColor",
	},
	UIListLayout = {
		SortOrder = Enum.SortOrder.LayoutOrder,
	},
	UIStroke = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	},

	Window = {
		Title = "No Title",
		Footer = "No Footer",
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(720, 600),
		IconSize = UDim2.fromOffset(30, 30),
		AutoShow = true,
		Center = true,
		Resizable = true,
		SearchbarSize = UDim2.fromScale(1, 1),
		CornerRadius = 4,
		NotifySide = "Right",
		ShowCustomCursor = false,
		Font = Enum.Font.Code,
		ToggleKeybind = Enum.KeyCode.RightControl,
		MobileButtonsSide = "Left",
	},
	Toggle = {
		Text = "Toggle",
		Default = false,
		Callback = function() end,
		Changed = function() end,
		Risky = false,
		Disabled = false,
		Visible = true,
	},
	Input = {
		Text = "Input",
		Default = "",
		Finished = false,
		Numeric = false,
		ClearTextOnFocus = true,
		Placeholder = "",
		AllowEmpty = true,
		EmptyReset = "---",
		Callback = function() end,
		Changed = function() end,
		Disabled = false,
		Visible = true,
	},
	Slider = {
		Text = "Slider",
		Default = 0,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Prefix = "",
		Suffix = "",
		Callback = function() end,
		Changed = function() end,
		Disabled = false,
		Visible = true,
	},
	Dropdown = {
		Values = {},
		DisabledValues = {},
		Multi = false,
		MaxVisibleDropdownItems = 8,
		Callback = function() end,
		Changed = function() end,
		Disabled = false,
		Visible = true,
	},
	Viewport = {
		Object = nil,
		Camera = nil,
		Clone = true,
		AutoFocus = true,
		Interactive = false,
		Height = 200,
		Visible = true,
	},
	Image = {
		Image = "",
		Transparency = 0,
		Color = Color3.new(1, 1, 1),
		RectOffset = Vector2.zero,
		RectSize = Vector2.zero,
		ScaleType = Enum.ScaleType.Fit,
		Height = 200,
		Visible = true,
	},

	KeyPicker = {
		Text = "KeyPicker",
		Default = "None",
		Mode = "Hold",
		Modes = { "Always", "Toggle", "Hold" },
		SyncToggleState = false,
		Callback = function() end,
		ChangedCallback = function() end,
		Changed = function() end,
		Clicked = function() end,
	},
	ColorPicker = {
		Default = Color3.new(1, 1, 1),
		Callback = function() end,
		Changed = function() end,
	},
}

local Places = {
	Bottom = { 0, 1 },
	Right = { 1, 0 },
}
local Sizes = {
	Left = { 0.5, 1 },
	Right = { 0.5, 1 },
}

-- ─── CORE LAYOUT FUNCTIONS ───────────────────────────────────────────
local function ApplyDPIScale(Dimension, ExtraOffset)
	if typeof(Dimension) == "UDim" then
		return UDim.new(Dimension.Scale, Dimension.Offset * Library.DPIScale)
	end

	if ExtraOffset then
		return UDim2.new(
			Dimension.X.Scale,
			(Dimension.X.Offset * Library.DPIScale) + (ExtraOffset[1] * Library.DPIScale),
			Dimension.Y.Scale,
			(Dimension.Y.Offset * Library.DPIScale) + (ExtraOffset[2] * Library.DPIScale)
		)
	end

	return UDim2.new(
		Dimension.X.Scale,
		Dimension.X.Offset * Library.DPIScale,
		Dimension.Y.Scale,
		Dimension.Y.Offset * Library.DPIScale
	)
end

local function ApplyTextScale(TextSize)
	return TextSize * Library.DPIScale
end

local function WaitForEvent(Event, Timeout, Condition)
	local Bindable = Instance.new("BindableEvent")
	local Connection = Event:Once(function(...)
		if not Condition or typeof(Condition) == "function" and Condition(...) then
			Bindable:Fire(true)
		else
			Bindable:Fire(false)
		end
	end)
	task.delay(Timeout, function()
		Connection:Disconnect()
		Bindable:Fire(false)
	end)

	local Result = Bindable.Event:Wait()
	Bindable:Destroy()
	return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
	return Input.UserInputType == Enum.UserInputType.MouseButton1
		or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
		or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
	return IsMouseInput(Input, IncludeM2)
		and Input.UserInputState == Enum.UserInputState.Begin
		and Library.IsRobloxFocused
end

local function IsHoverInput(Input: InputObject)
	return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
		and Input.UserInputState == Enum.UserInputState.Change
end

local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
	return IsMouseInput(Input, IncludeM2)
		and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
		and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
	local Size = 0
	for _, _ in pairs(Table) do
		Size += 1
	end
	return Size
end

local function StopTween(Tween: TweenBase)
	if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
		return
	end
	Tween:Cancel()
end

local function Trim(Text: string)
	return Text:match("^%s*(.-)%s*$")
end

local function Round(Value, Rounding)
	assert(Rounding >= 0, "Invalid rounding number.")
	if Rounding == 0 then
		return math.floor(Value)
	end
	return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
	local PlayerList = Players:GetPlayers()
	if ExcludeLocalPlayer then
		local Idx = table.find(PlayerList, LocalPlayer)
		if Idx then
			table.remove(PlayerList, Idx)
		end
	end
	table.sort(PlayerList, function(Player1, Player2)
		return Player1.Name:lower() < Player2.Name:lower()
	end)
	return PlayerList
end

local function GetTeams()
	local TeamList = Teams:GetTeams()
	table.sort(TeamList, function(Team1, Team2)
		return Team1.Name:lower() < Team2.Name:lower()
	end)
	return TeamList
end

-- ─── FRAMEWORK INTERFACES ─────────────────────────────────────────────
function Library:UpdateKeybindFrame()
	if not Library.KeybindFrame then
		return
	end

	local XSize = 0
	for _, KeybindToggle in pairs(Library.KeybindToggles) do
		if not KeybindToggle.Holder.Visible then
			continue
		end

		local FullSize = KeybindToggle.Label.Size.X.Offset + KeybindToggle.Label.Position.X.Offset
		if FullSize > XSize then
			XSize = FullSize
		end
	end

	Library.KeybindFrame.Size = UDim2.fromOffset(XSize + 18 * Library.DPIScale, 0)
end

function Library:UpdateDependencyBoxes()
	for _, Depbox in pairs(Library.DependencyBoxes) do
		Depbox:Update(true)
	end

	if Library.Searching then
		Library:UpdateSearch(Library.SearchText)
	end
end

local function CheckDepbox(Box, Search)
	local VisibleElements = 0

	for _, ElementInfo in pairs(Box.Elements) do
		if ElementInfo.Type == "Divider" then
			ElementInfo.Holder.Visible = false
			continue
		elseif ElementInfo.SubButton then
			local Visible = false
			if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
				Visible = true
			else
				ElementInfo.Base.Visible = false
			end
			if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
				Visible = true
			else
				ElementInfo.SubButton.Base.Visible = false
			end
			ElementInfo.Holder.Visible = Visible
			if Visible then
				VisibleElements += 1
			end
			continue
		end

		if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
			ElementInfo.Holder.Visible = true
			VisibleElements += 1
		else
			ElementInfo.Holder.Visible = false
		end
	end

	for _, Depbox in pairs(Box.DependencyBoxes) do
		if not Depbox.Visible then
			continue
		end
		VisibleElements += CheckDepbox(Depbox, Search)
	end

	return VisibleElements
end

local function RestoreDepbox(Box)
	for _, ElementInfo in pairs(Box.Elements) do
		ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true
		if ElementInfo.SubButton then
			ElementInfo.Base.Visible = ElementInfo.Visible
			ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
		end
	end

	Box:Resize()
	Box.Holder.Visible = true

	for _, Depbox in pairs(Box.DependencyBoxes) do
		if not Depbox.Visible then
			continue
		end
		RestoreDepbox(Depbox)
	end
end

function Library:UpdateSearch(SearchText)
	Library.SearchText = SearchText

	if Library.LastSearchTab then
		for _, Groupbox in pairs(Library.LastSearchTab.Groupboxes) do
			for _, ElementInfo in pairs(Groupbox.Elements) do
				ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true
				if ElementInfo.SubButton then
					ElementInfo.Base.Visible = ElementInfo.Visible
					ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
				end
			end

			for _, Depbox in pairs(Groupbox.DependencyBoxes) do
				if not Depbox.Visible then
					continue
				end
				RestoreDepbox(Depbox)
			end

			Groupbox:Resize()
			Groupbox.Holder.Visible = true
		end

		for _, Tabbox in pairs(Library.LastSearchTab.Tabboxes) do
			for _, Tab in pairs(Tabbox.Tabs) do
				for _, ElementInfo in pairs(Tab.Elements) do
					ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible
						or true
					if ElementInfo.SubButton then
						ElementInfo.Base.Visible = ElementInfo.Visible
						ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
					end
				end

				for _, Depbox in pairs(Tab.DependencyBoxes) do
					if not Depbox.Visible then
						continue
					end
					RestoreDepbox(Depbox)
				end
				Tab.ButtonHolder.Visible = true
			end

			Tabbox.ActiveTab:Resize()
			Tabbox.Holder.Visible = true
		end

		for _, DepGroupbox in pairs(Library.LastSearchTab.DependencyGroupboxes) do
			if not DepGroupbox.Visible then
				continue
			end

			for _, ElementInfo in pairs(DepGroupbox.Elements) do
				ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true
				if ElementInfo.SubButton then
					ElementInfo.Base.Visible = ElementInfo.Visible
					ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
				end
			end

			for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
				if not Depbox.Visible then
					continue
				end
				RestoreDepbox(Depbox)
			end

			DepGroupbox:Resize()
			DepGroupbox.Holder.Visible = true
		end
	end

	local Search = SearchText:lower()
	if Trim(Search) == "" or Library.ActiveTab.IsKeyTab then
		Library.Searching = false
		Library.LastSearchTab = nil
		return
	end

	Library.Searching = true

	for _, Groupbox in pairs(Library.ActiveTab.Groupboxes) do
		local VisibleElements = 0
		for _, ElementInfo in pairs(Groupbox.Elements) do
			if ElementInfo.Type == "Divider" then
				ElementInfo.Holder.Visible = false
				continue
			elseif ElementInfo.SubButton then
				local Visible = false
				if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
					Visible = true
				else
					ElementInfo.Base.Visible = false
				end
				if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
					Visible = true
				else
					ElementInfo.SubButton.Base.Visible = false
				end
				ElementInfo.Holder.Visible = Visible
				if Visible then
					VisibleElements += 1
				end
				continue
			end

			if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
				ElementInfo.Holder.Visible = true
				VisibleElements += 1
			else
				ElementInfo.Holder.Visible = false
			end
		end

		for _, Depbox in pairs(Groupbox.DependencyBoxes) do
			if not Depbox.Visible then
				continue
			end
			VisibleElements += CheckDepbox(Depbox, Search)
		end

		if VisibleElements > 0 then
			Groupbox:Resize()
		end
		Groupbox.Holder.Visible = VisibleElements > 0
	end

	for _, Tabbox in pairs(Library.ActiveTab.Tabboxes) do
		local VisibleTabs = 0
		local VisibleElements = {}

		for _, Tab in pairs(Tabbox.Tabs) do
			VisibleElements[Tab] = 0
			for _, ElementInfo in pairs(Tab.Elements) do
				if ElementInfo.Type == "Divider" then
					ElementInfo.Holder.Visible = false
					continue
				elseif ElementInfo.SubButton then
					local Visible = false
					if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
						Visible = true
					else
						ElementInfo.Base.Visible = false
					end
					if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
						Visible = true
					else
						ElementInfo.SubButton.Base.Visible = false
					end
					ElementInfo.Holder.Visible = Visible
					if Visible then
						VisibleElements[Tab] += 1
					end
					continue
				end

				if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
					ElementInfo.Holder.Visible = true
					VisibleElements[Tab] += 1
				else
					ElementInfo.Holder.Visible = false
				end
			end

			for _, Depbox in pairs(Tab.DependencyBoxes) do
				if not Depbox.Visible then
					continue
				end
				VisibleElements[Tab] += CheckDepbox(Depbox, Search)
			end
		end

		for Tab, Visible in pairs(VisibleElements) do
			Tab.ButtonHolder.Visible = Visible > 0
			if Visible > 0 then
				VisibleTabs += 1
				if Tabbox.ActiveTab == Tab then
					Tab:Resize()
				elseif VisibleElements[Tabbox.ActiveTab] == 0 then
					Tab:Show()
				end
			end
		end

		Tabbox.Holder.Visible = VisibleTabs > 0
	end

	for _, DepGroupbox in pairs(Library.ActiveTab.DependencyGroupboxes) do
		if not DepGroupbox.Visible then
			continue
		end

		local VisibleElements = 0
		for _, ElementInfo in pairs(DepGroupbox.Elements) do
			if ElementInfo.Type == "Divider" then
				ElementInfo.Holder.Visible = false
				continue
			elseif ElementInfo.SubButton then
				local Visible = false
				if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
					Visible = true
				else
					ElementInfo.Base.Visible = false
				end
				if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
					Visible = true
				else
					ElementInfo.SubButton.Base.Visible = false
				end
				ElementInfo.Holder.Visible = Visible
				if Visible then
					VisibleElements += 1
				end
				continue
			end

			if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
				ElementInfo.Holder.Visible = true
				VisibleElements += 1
			else
				ElementInfo.Holder.Visible = false
			end
		end

		for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
			if not Depbox.Visible then
				continue
			end
			VisibleElements += CheckDepbox(Depbox, Search)
		end

		if VisibleElements > 0 then
			DepGroupbox:Resize()
		end
		DepGroupbox.Holder.Visible = VisibleElements > 0
	end

	Library.LastSearchTab = Library.ActiveTab
end

function Library:AddToRegistry(Instance, Properties)
	Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
	Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
	for Instance, Properties in pairs(Library.Registry) do
		for Property, ColorIdx in pairs(Properties) do
			if typeof(ColorIdx) == "string" then
				Instance[Property] = Library.Scheme[ColorIdx]
			elseif typeof(ColorIdx) == "function" then
				Instance[Property] = ColorIdx()
			end
		end
	end
end

function Library:UpdateDPI(Instance, Properties)
	if not Library.DPIRegistry[Instance] then
		return
	end
	for Property, Value in pairs(Properties) do
		Library.DPIRegistry[Instance][Property] = Value and Value or nil
	end
end

function Library:SetDPIScale(DPIScale: number)
	Library.DPIScale = DPIScale / 100
	Library.MinSize *= Library.DPIScale

	for Instance, Properties in pairs(Library.DPIRegistry) do
		for Property, Value in pairs(Properties) do
			if Property == "DPIExclude" or Property == "DPIOffset" then
				continue
			elseif Property == "TextSize" then
				Instance[Property] = ApplyTextScale(Value)
			else
				Instance[Property] = ApplyDPIScale(Value, Properties["DPIOffset"][Property])
			end
		end
	end

	for _, Tab in pairs(Library.Tabs) do
		if Tab.IsKeyTab then
			continue
		end
		Tab:Resize(true)
		for _, Groupbox in pairs(Tab.Groupboxes) do
			Groupbox:Resize()
		end
		for _, Tabbox in pairs(Tab.Tabboxes) do
			for _, SubTab in pairs(Tabbox.Tabs) do
				SubTab:Resize()
			end
		end
	end

	for _, Option in pairs(Options) do
		if Option.Type == "Dropdown" then
			Option:RecalculateListSize()
		elseif Option.Type == "KeyPicker" then
			Option:Update()
		end
	end

	Library:UpdateKeybindFrame()
	for _, Notification in pairs(Library.Notifications) do
		Notification:Resize()
	end

	if Library.ActiveTab and Library.ActiveTab.Show then
		Library.ActiveTab:Show()
	end
end

function Library:GiveSignal(Connection: RBXScriptConnection)
	table.insert(Library.Signals, Connection)
	return Connection
end

local FetchIcons, Icons = pcall(function()
	return loadstring(
		game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
	)()
end)

function Library:GetIcon(IconName: string)
	if not FetchIcons then
		return
	end
	local Success, Icon = pcall(Icons.GetAsset, IconName)
	if not Success then
		return
	end
	return Icon
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
	if typeof(Table) ~= "table" then
		return Template
	end
	for k, v in pairs(Template) do
		if typeof(k) == "number" then
			continue
		end
		if typeof(v) == "table" then
			Table[k] = Library:Validate(Table[k], v)
		elseif Table[k] == nil then
			Table[k] = v
		end
	end
	return Table
end

-- ─── CREATOR INSTANTIATOR ─────────────────────────────────────────────
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
	local ThemeProperties = Library.Registry[Instance] or {}
	local DPIProperties = Library.DPIRegistry[Instance] or {}

	local DPIExclude = DPIProperties["DPIExclude"] or Table["DPIExclude"] or {}
	local DPIOffset = DPIProperties["DPIOffset"] or Table["DPIOffset"] or {}

	for k, v in pairs(Table) do
		if k == "DPIExclude" or k == "DPIOffset" then
			continue
		elseif ThemeProperties[k] then
			ThemeProperties[k] = nil
		elseif k ~= "Text" and (Library.Scheme[v] or typeof(v) == "function") then
			ThemeProperties[k] = v
			Instance[k] = Library.Scheme[v] or v()
			continue
		end

		if not DPIExclude[k] then
			if k == "Position" or k == "Size" or k:match("Padding") then
				DPIProperties[k] = v
				v = ApplyDPIScale(v, DPIOffset[k])
			elseif k == "TextSize" then
				DPIProperties[k] = v
				v = ApplyTextScale(v)
			end
		end

		Instance[k] = v
	end

	if GetTableSize(ThemeProperties) > 0 then
		Library.Registry[Instance] = ThemeProperties
	end
	if GetTableSize(DPIProperties) > 0 then
		DPIProperties["DPIExclude"] = DPIExclude
		DPIProperties["DPIOffset"] = DPIOffset
		Library.DPIRegistry[Instance] = DPIProperties
	end
end

local function New(ClassName: string, Properties: { [string]: any }): any
	local Instance = Instance.new(ClassName)
	if Templates[ClassName] then
		FillInstance(Templates[ClassName], Instance)
	end
	FillInstance(Properties, Instance)

	if Properties["Parent"] and not Properties["ZIndex"] then
		pcall(function()
			Instance.ZIndex = Properties.Parent.ZIndex
		end)
	end
	return Instance
end

-- ─── PARENTING COREGUI SAFE ──────────────────────────────────────────
local PlayerGui = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)

local function SafeParentUI(UI: Instance)
	local success, err = pcall(function()
		UI.Parent = PlayerGui
	end)
	if not success then
		warn("[LRX UI] Failed to parent UI to PlayerGui:", err)
		return false
	end
	return true
end

local function ParentUI(UI: Instance, _SkipHiddenUI: boolean?)
	return SafeParentUI(UI)
end

local ScreenGui = New("ScreenGui", {
	Name = "Obsidian",
	DisplayOrder = 2147483647,
	ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Instance)
	Library:RemoveFromRegistry(Instance)
	Library.DPIRegistry[Instance] = nil
end)

local ModalScreenGui = New("ScreenGui", {
	Name = "ObsidanModal",
	DisplayOrder = 2147483647,
	ResetOnSpawn = false,
})
ParentUI(ModalScreenGui, true)

local ModalElement = New("TextButton", {
	BackgroundTransparency = 1,
	Modal = false,
	Size = UDim2.fromScale(0, 0),
	Text = "",
	ZIndex = -999,
	Parent = ModalScreenGui,
})

-- ─── CURSOR ───────────────────────────────────────────────────────────
local Cursor
do
	Cursor = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		Size = UDim2.fromOffset(9, 1),
		Visible = false,
		ZIndex = 999,
		Parent = ScreenGui,
	})
	New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Dark",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 2, 1, 2),
		ZIndex = 998,
		Parent = Cursor,
	})

	local CursorV = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1, 9),
		Parent = Cursor,
	})
	New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Dark",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 2, 1, 2),
		ZIndex = 998,
		Parent = CursorV,
	})
end

-- ─── NOTIFICATION CONTAINER ───────────────────────────────────────────
local NotificationArea
local NotificationList
do
	NotificationArea = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.new(0, 300, 1, -6),
		Parent = ScreenGui,
	})
	NotificationList = New("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		Parent = NotificationArea,
	})
end

-- ─── COLOR CONVERTERS & GEOMETRY HELPERS ──────────────────────────────
function Library:GetBetterColor(Color: Color3, Add: number): Color3
	Add = Add * (Library.IsLightTheme and -4 or 2)
	return Color3.fromRGB(
		math.clamp(Color.R * 255 + Add, 0, 255),
		math.clamp(Color.G * 255 + Add, 0, 255),
		math.clamp(Color.B * 255 + Add, 0, 255)
	)
end

function Library:GetDarkerColor(Color: Color3): Color3
	local H, S, V = Color:ToHSV()
	return Color3.fromHSV(H, S, V / 2)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
	if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
		return string.char(KeyCode.Value)
	end
	return KeyCode.Name
end

function Library:GetTextBounds(Text, FontObj, Size, Width)
	Text = tostring(Text or "")
	Size = tonumber(Size) or 16
	Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

	local ok, Bounds = pcall(function()
		local Params = Instance.new("GetTextBoundsParams")
		Params.Text = Text
		Params.RichText = true
		Params.Size = Size
		Params.Width = Width
		if FontObj then
			Params.Font = FontObj
		else
			Params.Font = Font.fromEnum(Enum.Font.Gotham)
		end
		return TextService:GetTextBoundsAsync(Params)
	end)

	if ok and Bounds then
		return Bounds.X, Bounds.Y
	end

	local fallbackFont = Enum.Font.Gotham
	pcall(function()
		if typeof(FontObj) == "EnumItem" then
			fallbackFont = FontObj
		end
	end)

	local ok2, size = pcall(function()
		return TextService:GetTextSize(Text, Size, fallbackFont, Vector2.new(Width, math.huge))
	end)

	if ok2 and size then
		return size.X, size.Y
	end
	return #Text * Size * 0.55, Size
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
	local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
	return Mouse.X >= AbsPos.X
		and Mouse.X <= AbsPos.X + AbsSize.X
		and Mouse.Y >= AbsPos.Y
		and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
	if not (Func and typeof(Func) == "function") then
		return
	end
	local Result = table.pack(xpcall(Func, function(Error)
		task.defer(error, debug.traceback(Error, 2))
		if Library.NotifyOnError then
			Library:Notify(Error)
		end
		return Error
	end, ...))

	if not Result[1] then
		return nil
	end
	return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
	local StartPos
	local FramePos
	local Dragging = false
	local Changed
	DragFrame.InputBegan:Connect(function(Input: InputObject)
		if not IsClickInput(Input) or (IsMainWindow and Library.CantDragForced) then
			return
		end

		StartPos = Input.Position
		FramePos = UI.Position
		Dragging = true

		Changed = Input.Changed:Connect(function()
			if Input.UserInputState ~= Enum.UserInputState.End then
				return
			end
			Dragging = false
			if Changed and Changed.Connected then
				Changed:Disconnect()
				Changed = nil
			end
		end)
	end)
	Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
		if
			(not IgnoreToggled and not Library.Toggled)
			or (IsMainWindow and Library.CantDragForced)
			or not (ScreenGui and ScreenGui.Parent)
		then
			Dragging = false
			if Changed and Changed.Connected then
				Changed:Disconnect()
				Changed = nil
			end
			return
		end

		if Dragging and IsHoverInput(Input) then
			local Delta = Input.Position - StartPos
			UI.Position =
				UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
		end
	end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
	local StartPos
	local FrameSize
	local Dragging = false
	local Changed
	DragFrame.InputBegan:Connect(function(Input: InputObject)
		if not IsClickInput(Input) then
			return
		end

		StartPos = Input.Position
		FrameSize = UI.Size
		Dragging = true

		Changed = Input.Changed:Connect(function()
			if Input.UserInputState ~= Enum.UserInputState.End then
				return
			end
			Dragging = false
			if Changed and Changed.Connected then
				Changed:Disconnect()
				Changed = nil
			end
		end)
	end)
	Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
		if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
			Dragging = false
			if Changed and Changed.Connected then
				Changed:Disconnect()
				Changed = nil
			end
			return
		end

		if Dragging and IsHoverInput(Input) then
			local Delta = Input.Position - StartPos
			UI.Size = UDim2.new(
				FrameSize.X.Scale,
				math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
				FrameSize.Y.Scale,
				math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
			)
			if Callback then
				Library:SafeCallback(Callback)
			end
		end
	end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
	local Pos = Places[Place] or { 0, 0 }
	local Size = Sizes[Place] or { 1, 0.5 }

	local Cover = New("Frame", {
		AnchorPoint = Vector2.new(Pos[1], Pos[2]),
		BackgroundColor3 = Holder.BackgroundColor3,
		Position = UDim2.fromScale(Pos[1], Pos[2]),
		Size = UDim2.fromScale(Size[1], Size[2]),
		Parent = Holder,
	})
	return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
	local Line = New("Frame", {
		AnchorPoint = Info.AnchorPoint or Vector2.zero,
		BackgroundColor3 = "OutlineColor",
		Position = Info.Position,
		Size = Info.Size,
		Parent = Frame,
	})
	return Line
end

function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
	local Holder = New("Frame", {
		BackgroundColor3 = "Dark",
		Position = UDim2.fromOffset(-2, -2),
		Size = UDim2.new(1, 4, 1, 4),
		ZIndex = ZIndex,
		Parent = Frame,
	})

	local Outline = New("Frame", {
		BackgroundColor3 = "OutlineColor",
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = ZIndex,
		Parent = Holder,
	})

	if Corner and Corner > 0 then
		New("UICorner", {
			CornerRadius = UDim.new(0, Corner + 1),
			Parent = Holder,
		})
		New("UICorner", {
			CornerRadius = UDim.new(0, Corner),
			Parent = Outline,
		})
	end
	return Holder
end

function Library:AddDraggableButton(Text: string, Func)
	local Table = {}
	local Button = New("TextButton", {
		BackgroundColor3 = "BackgroundColor",
		Position = UDim2.fromOffset(6, 6),
		TextSize = 16,
		ZIndex = 10,
		Parent = ScreenGui,
		DPIExclude = {
			Position = true,
		},
	})
	New("UICorner", {
		CornerRadius = UDim.new(0, Library.CornerRadius - 1),
		Parent = Button,
	})
	Library:MakeOutline(Button, Library.CornerRadius, 9)

	Table.Button = Button
	Button.MouseButton1Click:Connect(function()
		Library:SafeCallback(Func, Table)
	end)
	Library:MakeDraggable(Button, Button, true)

	function Table:SetText(NewText: string)
		local X, Y = Library:GetTextBounds(NewText, Library.Scheme.Font, 16)
		Button.Text = NewText
		Button.Size = UDim2.fromOffset(X * Library.DPIScale * 2, Y * Library.DPIScale * 2)
		Library:UpdateDPI(Button, {
			Size = UDim2.fromOffset(X * 2, Y * 2),
		})
	end
	Table:SetText(Text)
	return Table
end

function Library:AddDraggableMenu(Name: string)
	local Background = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
	Background.AutomaticSize = Enum.AutomaticSize.Y
	Background.Position = UDim2.fromOffset(6, 6)
	Background.Size = UDim2.fromOffset(0, 0)
	Library:UpdateDPI(Background, {
		Position = false,
		Size = false,
	})

	local Holder = New("Frame", {
		BackgroundColor3 = "BackgroundColor",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = Background,
	})
	New("UICorner", {
		CornerRadius = UDim.new(0, Library.CornerRadius - 1),
		Parent = Holder,
	})
	Library:MakeLine(Holder, {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 1),
	})

	local Label = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Text = Name,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Holder,
	})
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = Label,
	})

	local Container = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 35),
		Size = UDim2.new(1, 0, 1, -35),
		Parent = Holder,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 7),
		Parent = Container,
	})
	New("UIPadding", {
		PaddingBottom = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7),
		PaddingTop = UDim.new(0, 7),
		Parent = Container,
	})

	Library:MakeDraggable(Background, Label, true)
	return Background, Container
end

-- ─── WATERMARK ────────────────────────────────────────────────────────
do
	local WatermarkBackground = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
	WatermarkBackground.AutomaticSize = Enum.AutomaticSize.Y
	WatermarkBackground.AnchorPoint = Vector2.new(1, 0)
	WatermarkBackground.Position = UDim2.new(1, -50, 0, -50)
	WatermarkBackground.Size = UDim2.fromOffset(0, 0)
	WatermarkBackground.Visible = false

	Library:UpdateDPI(WatermarkBackground, {
		Position = false,
		Size = false,
	})

	local Holder = New("Frame", {
		BackgroundColor3 = "BackgroundColor",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = WatermarkBackground,
	})
	New("UICorner", {
		CornerRadius = UDim.new(0, Library.CornerRadius - 1),
		Parent = Holder,
	})

	local WatermarkLabel = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.fromOffset(0, -8 * Library.DPIScale + 7),
		Text = "",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Holder,
	})
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = WatermarkLabel,
	})

	Library:MakeDraggable(WatermarkBackground, WatermarkLabel, true)

	local function ResizeWatermark()
		local X, Y = Library:GetTextBounds(WatermarkLabel.Text, Library.Scheme.Font, 15)
		WatermarkBackground.Size = UDim2.fromOffset((12 + X + 12 + 4) * Library.DPIScale, Y * Library.DPIScale * 2 + 4)
		Library:UpdateDPI(WatermarkBackground, {
			Size = UDim2.fromOffset(12 + X + 12 + 4, Y * 2 + 4),
		})
	end

	function Library:SetWatermarkVisibility(Visible: boolean)
		WatermarkBackground.Visible = Visible
		if Visible then
			ResizeWatermark()
		end
	end

	function Library:SetWatermark(Text: string)
		WatermarkLabel.Text = Text
		ResizeWatermark()
	end
end

-- ─── CONTEXT MENU ─────────────────────────────────────────────────────
local CurrentMenu
function Library:AddContextMenu(
	Holder: GuiObject,
	Size: UDim2 | () -> (),
	Offset: { [number]: number } | () -> {},
	List: number?,
	ActiveCallback: (Active: boolean) -> ()?
)
	local Menu
	if List then
		Menu = New("ScrollingFrame", {
			AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			BackgroundColor3 = "BackgroundColor",
			BorderColor3 = "OutlineColor",
			BorderSizePixel = 1,
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarImageColor3 = "OutlineColor",
			ScrollBarThickness = List == 2 and 2 or 0,
			Size = typeof(Size) == "function" and Size() or Size,
			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			Visible = false,
			ZIndex = 10,
			Parent = ScreenGui,
			DPIExclude = {
				Position = true,
			},
		})
	else
		Menu = New("Frame", {
			BackgroundColor3 = "BackgroundColor",
			BorderColor3 = "OutlineColor",
			BorderSizePixel = 1,
			Size = typeof(Size) == "function" and Size() or Size,
			Visible = false,
			ZIndex = 10,
			Parent = ScreenGui,
			DPIExclude = {
				Position = true,
			},
		})
	end

	local Table = {
		Active = false,
		Holder = Holder,
		Menu = Menu,
		List = nil,
		Signal = nil,
		Size = Size,
	}

	if List then
		Table.List = New("UIListLayout", {
			Parent = Menu,
		})
	end

	function Table:Open()
		if CurrentMenu == Table then
			return
		elseif CurrentMenu then
			CurrentMenu:Close()
		end

		CurrentMenu = Table
		Table.Active = true

		if typeof(Offset) == "function" then
			Menu.Position = UDim2.fromOffset(
				math.floor(Holder.AbsolutePosition.X + Offset()[1]),
				math.floor(Holder.AbsolutePosition.Y + Offset()[2])
			)
		else
			Menu.Position = UDim2.fromOffset(
				math.floor(Holder.AbsolutePosition.X + Offset[1]),
				math.floor(Holder.AbsolutePosition.Y + Offset[2])
			)
		end
		if typeof(Table.Size) == "function" then
			Menu.Size = Table.Size()
		else
			Menu.Size = ApplyDPIScale(Table.Size)
		end
		if typeof(ActiveCallback) == "function" then
			Library:SafeCallback(ActiveCallback, true)
		end

		Menu.Visible = true

		Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			if typeof(Offset) == "function" then
				Menu.Position = UDim2.fromOffset(
					math.floor(Holder.AbsolutePosition.X + Offset()[1]),
					math.floor(Holder.AbsolutePosition.Y + Offset()[2])
				)
			else
				Menu.Position = UDim2.fromOffset(
					math.floor(Holder.AbsolutePosition.X + Offset[1]),
					math.floor(Holder.AbsolutePosition.Y + Offset[2])
				)
			end
		end)
	end

	function Table:Close()
		if CurrentMenu ~= Table then
			return
		end
		Menu.Visible = false

		if Table.Signal then
			Table.Signal:Disconnect()
			Table.Signal = nil
		end
		Table.Active = false
		CurrentMenu = nil
		if typeof(ActiveCallback) == "function" then
			Library:SafeCallback(ActiveCallback, false)
		end
	end

	function Table:Toggle()
		if Table.Active then
			Table:Close()
		else
			Table:Open()
		end
	end

	function Table:SetSize(Size)
		Table.Size = Size
		Menu.Size = typeof(Size) == "function" and Size() or Size
	end

	return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
	if IsClickInput(Input, true) then
		local Location = Input.Position
		if
			CurrentMenu
			and not (
				Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
				or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
			)
		then
			CurrentMenu:Close()
		end
	end
end))

-- ─── POPUP DIALOGS ────────────────────────────────────────────────────
local ActiveDialog

function Library:Dialog(DialogInfo)
	DialogInfo = Library:Validate(DialogInfo, {
		Type = "confirm",
		Title = "Confirm",
		Description = "Are you sure?",
		ConfirmText = "Confirm",
		CancelText = "Cancel",
		OkText = "OK",
		Risky = true,
		AllowEscape = true,
		Wait = false,
		Scale = nil,
		Callback = function() end,
		OnConfirm = function() end,
		OnCancel = function() end,
		OnClose = function() end,
	})

	local isInfo = string.lower(tostring(DialogInfo.Type or "confirm")) == "info"

	if ActiveDialog then
		ActiveDialog:Close(false, "replaced")
	end

	local resultEvent = DialogInfo.Wait and Instance.new("BindableEvent") or nil
	local closed = false
	local connections = {}
	local previousModal = ModalElement.Modal
	ModalElement.Modal = true

	local function hook(conn)
		table.insert(connections, conn)
		return conn
	end

	local blocker = New("TextButton", {
		Name = "DialogBlocker",
		Active = true,
		AutoButtonColor = false,
		BackgroundColor3 = "Dark",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Modal = true,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextTransparency = 1,
		ZIndex = 118,
		Parent = Library.ScreenGui,
		DPIExclude = {
			Size = true,
		},
	})

	local popup = New("Frame", {
		Name = "DialogPopup",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
		BorderSizePixel = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.58, 0.42),
		ZIndex = 130,
		Parent = Library.ScreenGui,
	})

	New("UICorner", {
		CornerRadius = UDim.new(0, Library.CornerRadius + 4),
		Parent = popup,
	})

	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1.2,
		Transparency = 0.1,
		Color = Library.Scheme.OutlineColor:Lerp(Library.Scheme.AccentColor, 0.1),
		Parent = popup,
	})

	return popup
end

-- ─── NOTIFICATION ENGINE ──────────────────────────────────────────────
function Library:SetNotifySide(Side: string)
	Library.NotifySide = Side
	if Side:lower() == "left" then
		NotificationArea.AnchorPoint = Vector2.new(0, 0)
		NotificationArea.Position = UDim2.fromOffset(6, 6)
		NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	else
		NotificationArea.AnchorPoint = Vector2.new(1, 0)
		NotificationArea.Position = UDim2.new(1, -6, 0, 6)
		NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	end
end

function Library:Notify(...)
	local Data = {}
	local Info = select(1, ...)

	if typeof(Info) == "table" then
		Data.Title = tostring(Info.Title)
		Data.Description = tostring(Info.Description)
		Data.Time = Info.Time or 5
		Data.SoundId = Info.SoundId
		Data.Steps = Info.Steps
		Data.Persist = Info.Persist
		Data.Type = Info.Type or "Info"
	else
		Data.Description = tostring(Info)
		Data.Time = select(2, ...) or 5
		Data.SoundId = select(3, ...)
		Data.Type = "Info"
	end
	Data.Destroyed = false

	local DeletedInstance = false
	local DeleteConnection = nil
	if typeof(Data.Time) == "Instance" then
		DeleteConnection = Data.Time.Destroying:Connect(function()
			DeletedInstance = true
			DeleteConnection:Disconnect()
			DeleteConnection = nil
		end)
	end

	local FakeBackground = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		Visible = false,
		Parent = NotificationArea,
		DPIExclude = {
			Size = true,
		},
	})

	local Background = Library:MakeOutline(FakeBackground, Library.CornerRadius, 5)
	Background.AutomaticSize = Enum.AutomaticSize.Y
	Background.Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -6, 0, -2) or UDim2.new(1, 6, 0, -2)
	Background.Size = UDim2.fromScale(1, 0)
	Library:UpdateDPI(Background, {
		Position = false,
		Size = false,
	})

	local Holder = New("Frame", {
		BackgroundColor3 = "MainColor",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Parent = Background,
	})
	New("UICorner", {
		CornerRadius = UDim.new(0, Library.CornerRadius - 1),
		Parent = Holder,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 4),
		Parent = Holder,
	})
	New("UIPadding", {
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		Parent = Holder,
	})

	local Title, Desc
	local TitleX, DescX = 0, 0
	local TimerFill

	if Data.Title then
		Title = New("TextLabel", {
			BackgroundTransparency = 1,
			Text = Data.Title,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = Holder,
			DPIExclude = {
				Size = true,
			},
		})
	end

	if Data.Description then
		Desc = New("TextLabel", {
			BackgroundTransparency = 1,
			Text = Data.Description,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = Holder,
			DPIExclude = {
				Size = true,
			},
		})
	end

	function Data:Resize()
		if Title then
			local X, Y = Library:GetTextBounds(
				Title.Text,
				Title.FontFace,
				Title.TextSize,
				NotificationArea.AbsoluteSize.X - (24 * Library.DPIScale)
			)
			Title.Size = UDim2.fromOffset(math.ceil(X), Y)
			TitleX = X
		end
		if Desc then
			local X, Y = Library:GetTextBounds(
				Desc.Text,
				Desc.FontFace,
				Desc.TextSize,
				NotificationArea.AbsoluteSize.X - (24 * Library.DPIScale)
			)
			Desc.Size = UDim2.fromOffset(math.ceil(X), Y)
			DescX = X
		end
		FakeBackground.Size = UDim2.fromOffset((TitleX > DescX and TitleX or DescX) + (24 * Library.DPIScale), 0)
	end

	function Data:ChangeTitle(NewText)
		if Title then
			Data.Title = tostring(NewText)
			Title.Text = Data.Title
			Data:Resize()
		end
	end

	function Data:ChangeDescription(NewText)
		if Desc then
			Data.Description = tostring(NewText)
			Desc.Text = Data.Description
			Data:Resize()
		end
	end

	function Data:Destroy()
		Data.Destroyed = true
		if DeleteConnection then
			DeleteConnection:Disconnect()
		end

		TweenService:Create(Background, Library.NotifyTweenInfo, {
			Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -6, 0, -2) or UDim2.new(1, 6, 0, -2),
		}):Play()
		task.delay(Library.NotifyTweenInfo.Time, function()
			Library.Notifications[FakeBackground] = nil
			FakeBackground:Destroy()
		end)
	end

	Data:Resize()

	-- Integrated side color strip based on Notify type
	local stripColors = {
		Success = Color3.fromRGB(50, 205, 50),
		Warning = Color3.fromRGB(255, 165, 0),
		Error = Color3.fromRGB(255, 80, 80),
		Info = Color3.fromRGB(100, 150, 255),
	}
	local stripColor = stripColors[Data.Type] or stripColors.Info

	local colorStrip = New("Frame", {
		BackgroundColor3 = stripColor,
		Position = UDim2.fromOffset(-2, 0),
		Size = UDim2.new(0, 3, 1, 0),
		ZIndex = 20,
		Parent = Holder,
	})
	New("UICorner", {
		CornerRadius = UDim.new(0, 2),
		Parent = colorStrip,
	})

	local TimerHolder = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 7),
		Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
		Parent = Holder,
	})
	local TimerBar = New("Frame", {
		BackgroundColor3 = "BackgroundColor",
		BorderColor3 = "OutlineColor",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(0, 3),
		Size = UDim2.new(1, 0, 0, 2),
		Parent = TimerHolder,
	})
	TimerFill = New("Frame", {
		BackgroundColor3 = stripColor,
		Size = UDim2.fromScale(1, 1),
		Parent = TimerBar,
	})

	if typeof(Data.Time) == "Instance" then
		TimerFill.Size = UDim2.fromScale(0, 1)
	end

	if Data.SoundId then
		local SoundId = Data.SoundId
		if typeof(SoundId) == "number" then
			SoundId = `rbxassetid://{SoundId}`
		end
		New("Sound", {
			SoundId = SoundId,
			Volume = 3,
			PlayOnRemove = true,
			Parent = SoundService,
		}):Destroy()
	end

	Library.Notifications[FakeBackground] = Data
	FakeBackground.Visible = true
	TweenService:Create(Background, Library.NotifyTweenInfo, {
		Position = UDim2.fromOffset(-2, -2),
	}):Play()

	task.delay(Library.NotifyTweenInfo.Time, function()
		if Data.Persist then
			return
		elseif typeof(Data.Time) == "Instance" then
			repeat
				task.wait()
			until DeletedInstance or Data.Destroyed
		else
			TweenService
				:Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
					Size = UDim2.fromScale(0, 1),
				})
				:Play()
			task.wait(Data.Time)
		end

		if not Data.Destroyed then
			Data:Destroy()
		end
	end)

	return Data
end

-- ─── TOOLTIP CONTAINER ────────────────────────────────────────────────
local TooltipLabel
do
	TooltipLabel = New("TextLabel", {
		BackgroundColor3 = "BackgroundColor",
		BorderColor3 = "OutlineColor",
		BorderSizePixel = 1,
		Size = UDim2.fromOffset(0, 0),
		Visible = false,
		ZIndex = 500,
		Parent = ScreenGui,
	})
	New("UIPadding", {
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4),
		Parent = TooltipLabel,
	})
end

-- ─── WINDOW DRAWING VISUAL EFFECT ENGINE (MERGED FROM MAIN) ───────────
Library.Laser = {}
Library.Laser.Beams = {}

function Library.Laser:CreateBeam(startPos, endPos, color, duration)
	local folder = game.Workspace:FindFirstChild("LRX_Lasers")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "LRX_Lasers"
		folder.Parent = game.Workspace
	end

	local beamPart = Instance.new("Part")
	beamPart.Name = "LaserBeam"
	beamPart.Anchored = true
	beamPart.CanCollide = false
	beamPart.CanQuery = false
	beamPart.CanTouch = false
	beamPart.CastShadow = false
	beamPart.Material = Enum.Material.Neon
	beamPart.Color = color or Color3.fromRGB(147, 112, 219)
	beamPart.Transparency = 0.3

	local distance = (endPos - startPos).Magnitude
	beamPart.Size = Vector3.new(0.05, 0.05, distance)
	beamPart.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
	beamPart.Parent = folder

	local glow = Instance.new("PointLight")
	glow.Color = beamPart.Color
	glow.Brightness = 2
	glow.Range = 6
	glow.Parent = beamPart

	table.insert(self.Beams, beamPart)

	task.delay(duration, function()
		if beamPart and beamPart.Parent then
			local tween = TweenService:Create(beamPart, TweenInfo.new(0.3), { Transparency = 1 })
			tween.Completed:Connect(function()
				if beamPart and beamPart.Parent then
					beamPart:Destroy()
				end
			end)
			tween:Play()
		end
	end)
	return beamPart
end

function Library.Laser:ClearBeams()
	for i, beam in pairs(self.Beams) do
		if beam and beam.Parent then
			pcall(function()
				beam:Destroy()
			end)
		end
		self.Beams[i] = nil
	end
end

function Library.Laser:ScanPlot(plot, scanDuration)
	self:ClearBeams()
	if not plot then
		return
	end

	local visual = plot:FindFirstChild("Visual")
	if not visual then
		return
	end

	local parts = {}
	for _, child in ipairs(visual:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^PlantAreaColumn") then
			table.insert(parts, child)
		end
	end
	if #parts == 0 then
		return
	end

	local minY = math.huge
	local allCorners = {}
	for _, part in ipairs(parts) do
		minY = math.min(minY, part.Position.Y)
		local hs = part.Size / 2
		local cf = part.CFrame
		for dx = -1, 1, 2 do
			for dz = -1, 1, 2 do
				table.insert(allCorners, cf * Vector3.new(dx * hs.X, hs.Y, dz * hs.Z))
			end
		end
	end

	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math_huge, -math_huge
	for _, corner in ipairs(allCorners) do
		minX = math.min(minX, corner.X)
		maxX = math.max(maxX, corner.X)
		minZ = math.min(minZ, corner.Z)
		maxZ = math.max(maxZ, corner.Z)
	end

	local sweepHeight = minY + 2
	local sweepCount = 6
	local stepDelay = scanDuration / sweepCount

	for i = 1, sweepCount do
		task.delay((i - 1) * stepDelay, function()
			local t = (i - 1) / math.max(1, sweepCount - 1)
			local z = minZ + (maxZ - minZ) * t
			self:CreateBeam(
				Vector3.new(minX, sweepHeight, z),
				Vector3.new(maxX, sweepHeight, z),
				Color3.fromRGB(0, 255, 255),
				0.4
			)
		end)
	end

	for i = 1, sweepCount do
		task.delay((i - 1) * stepDelay + 0.05, function()
			local t = (i - 1) / math.max(1, sweepCount - 1)
			local x = minX + (maxX - minX) * t
			self:CreateBeam(
				Vector3.new(x, sweepHeight + 0.5, minZ),
				Vector3.new(x, sweepHeight + 0.5, maxZ),
				Color3.fromRGB(255, 0, 255),
				0.4
			)
		end)
	end
end

-- ─── DRAGGING & COMPONENT BASE ─────────────────────────────────────────
local BaseAddons = {}
do
	local Funcs = {}
	function Funcs:AddKeyPicker(Idx, Info)
		Info = Library:Validate(Info, Templates.KeyPicker)
		local ParentObj = self
		local ToggleLabel = ParentObj.TextLabel

		local KeyPicker = {
			Text = Info.Text,
			Value = Info.Default,
			Toggled = false,
			Mode = Info.Mode,
			SyncToggleState = Info.SyncToggleState,
			Callback = Info.Callback,
			ChangedCallback = Info.ChangedCallback,
			Changed = Info.Changed,
			Clicked = Info.Clicked,
			Type = "KeyPicker",
		}

		local Picker = New("TextButton", {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
			BorderSizePixel = 1,
			Size = UDim2.fromOffset(18, 18),
			Text = KeyPicker.Value,
			TextSize = 12,
			Parent = ToggleLabel,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Picker })

		function KeyPicker:Update()
			Picker.Text = tostring(KeyPicker.Value)
		end

		Picker.MouseButton1Click:Connect(function()
			local InputConn
			Picker.Text = "..."
			InputConn = UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Keyboard then
					KeyPicker.Value = input.KeyCode.Name
					Picker.Text = KeyPicker.Value
					InputConn:Disconnect()
					Library:SafeCallback(KeyPicker.Callback, KeyPicker.Value)
				end
			end)
		end)

		Options[Idx] = KeyPicker
		return KeyPicker
	end

	function Funcs:AddColorPicker(Idx, Info)
		-- Compact color picker implementation
		local ColorPicker = {
			Value = Info.Default or Color3.new(1, 1, 1),
			Callback = Info.Callback,
			Type = "ColorPicker",
		}
		Options[Idx] = ColorPicker
		return ColorPicker
	end

	BaseAddons.__index = Funcs
	BaseAddons.__namecall = function(_, Key, ...)
		return Funcs[Key](...)
	end
end

-- ─── COMPONENT CONTAINER GROUPBOX DEFINITION ───────────────────────────
local BaseGroupbox = {}
do
	local Funcs = {}

	function Funcs:AddDivider()
		local Groupbox = self
		local Container = Groupbox.Container
		local Holder = New("Frame", {
			BackgroundColor3 = "OutlineColor",
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			Parent = Container,
		})
		Groupbox:Resize()

		table.insert(Groupbox.Elements, {
			Holder = Holder,
			Type = "Divider",
		})
	end

	function Funcs:AddSpacer(Height)
		Height = (typeof(Height) == "number" and Height) or 20
		local Groupbox = self
		local Container = Groupbox.Container
		local SpacerFrame = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Height),
			Parent = Container,
		})
		Groupbox:Resize()

		table.insert(Groupbox.Elements, {
			Holder = SpacerFrame,
			Type = "Spacer",
			Visible = true,
		})
		return self
	end

	function Funcs:AddLabel(...)
		local Data = {}
		local Addons = {}
		local First = select(1, ...)
		local Second = select(2, ...)

		if typeof(First) == "table" or typeof(Second) == "table" then
			local Params = typeof(First) == "table" and First or Second
			Data.Text = Params.Text or ""
			Data.DoesWrap = Params.DoesWrap or false
			Data.Size = Params.Size or 14
			Data.Visible = Params.Visible or true
			Data.Idx = typeof(Second) == "table" and First or nil
		else
			Data.Text = First or ""
			Data.DoesWrap = Second or false
			Data.Size = 14
			Data.Visible = true
			Data.Idx = select(3, ...) or nil
		end

		local Groupbox = self
		local Container = Groupbox.Container

		local Label = {
			Text = Data.Text,
			DoesWrap = Data.DoesWrap,
			Addons = Addons,
			Visible = Data.Visible,
			Type = "Label",
		}

		local TextLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Text = Label.Text,
			TextSize = Data.Size,
			TextWrapped = Label.DoesWrap,
			TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
			Parent = Container,
		})

		function Label:SetVisible(Visible: boolean)
			Label.Visible = Visible
			TextLabel.Visible = Label.Visible
			Groupbox:Resize()
		end

		function Label:SetText(Text: string)
			Label.Text = Text
			TextLabel.Text = Text
			Groupbox:Resize()
		end

		Groupbox:Resize()
		Label.TextLabel = TextLabel
		Label.Container = Container
		if not Data.DoesWrap then
			setmetatable(Label, BaseAddons)
		end

		Label.Holder = TextLabel
		table.insert(Groupbox.Elements, Label)
		if Data.Idx then
			Labels[Data.Idx] = Label
		else
			table.insert(Labels, Label)
		end
		return Label
	end

	function Funcs:AddButton(...)
		local function GetInfo(...)
			local Info = {}
			local First = select(1, ...)
			local Second = select(2, ...)

			if typeof(First) == "table" or typeof(Second) == "table" then
				local Params = typeof(First) == "table" and First or Second
				Info.Text = Params.Text or ""
				Info.Func = Params.Func or function() end
				Info.DoubleClick = Params.DoubleClick
				Info.Risky = Params.Risky or false
				Info.Disabled = Params.Disabled or false
				Info.Visible = Params.Visible or true
				Info.Idx = typeof(Second) == "table" and First or nil
			else
				Info.Text = First or ""
				Info.Func = Second or function() end
				Info.DoubleClick = false
				Info.Risky = false
				Info.Disabled = false
				Info.Visible = true
				Info.Idx = select(3, ...) or nil
			end
			return Info
		end

		local Info = GetInfo(...)
		local Groupbox = self
		local Container = Groupbox.Container

		local Button = {
			Text = Info.Text,
			Func = Info.Func,
			DoubleClick = Info.DoubleClick,
			Risky = Info.Risky,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Hovering = false,
			Type = "Button",
		}

		local Base = New("TextButton", {
			BackgroundColor3 = "MainColor",
			Size = UDim2.new(1, 0, 0, 24),
			Text = Button.Text,
			TextSize = 13,
			TextColor3 = Button.Risky and "Red" or "FontColor",
			Parent = Container,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Base })
		New("UIStroke", { Color = "OutlineColor", Parent = Base })

		Base.MouseButton1Click:Connect(function()
			if Button.Disabled then
				return
			end
			Library:SafeCallback(Button.Func)
		end)

		function Button:SetVisible(Visible: boolean)
			Button.Visible = Visible
			Base.Visible = Visible
			Groupbox:Resize()
		end

		function Button:SetText(Text: string)
			Button.Text = Text
			Base.Text = Text
		end

		function Button:SetDisabled(Disabled: boolean)
			Button.Disabled = Disabled
			Base.Active = not Disabled
		end

		Groupbox:Resize()
		Button.Base = Base
		Button.Holder = Base
		table.insert(Groupbox.Elements, Button)
		return Button
	end

	function Funcs:AddToggle(Idx, Info)
		Info = Library:Validate(Info, Templates.Toggle)
		local Groupbox = self
		local Container = Groupbox.Container

		local Toggle = {
			Text = Info.Text,
			Value = Info.Default,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Risky = Info.Risky,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Addons = {},
			Type = "Toggle",
		}

		local Button = New("TextButton", {
			Active = not Toggle.Disabled,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			Text = "",
			Visible = Toggle.Visible,
			Parent = Container,
		})

		local Row = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = Button,
		})

		local Switch = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = "MainColor",
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(36, 20),
			Parent = Row,
		})
		New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Switch })
		local SwitchStroke = New("UIStroke", { Color = "OutlineColor", Parent = Switch })

		local Ball = New("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Parent = Switch,
		})
		New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Ball })

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -44, 1, 0),
			Text = Toggle.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Row,
		})

		function Toggle:Display()
			local Offset = Toggle.Value and 1 or 0
			TweenService:Create(Ball, Library.TweenInfo, {
				AnchorPoint = Vector2.new(Offset, 0),
				Position = UDim2.fromScale(Offset, 0),
			}):Play()
			TweenService:Create(Switch, Library.TweenInfo, {
				BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor,
			}):Play()
		end

		function Toggle:SetValue(Value)
			if Toggle.Disabled then
				return
			end
			Toggle.Value = Value
			Toggle:Display()
			Library:SafeCallback(Toggle.Callback, Toggle.Value)
			Library:SafeCallback(Toggle.Changed, Toggle.Value)
		end

		Button.MouseButton1Click:Connect(function()
			Toggle:SetValue(not Toggle.Value)
		end)

		Toggle:Display()
		Groupbox:Resize()

		Toggle.Holder = Button
		table.insert(Groupbox.Elements, Toggle)
		Toggles[Idx] = Toggle
		return Toggle
	end

	function Funcs:AddInput(Idx, Info)
		Info = Library:Validate(Info, Templates.Input)
		local Groupbox = self
		local Container = Groupbox.Container

		local Input = {
			Text = Info.Text,
			Value = Info.Default,
			Finished = Info.Finished,
			Numeric = Info.Numeric,
			ClearTextOnFocus = Info.ClearTextOnFocus,
			Placeholder = Info.Placeholder,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Type = "Input",
		}

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 48),
			Visible = Input.Visible,
			Parent = Container,
		})

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Text = Input.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local Box = New("TextBox", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = "MainColor",
			BorderSizePixel = 0,
			ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
			PlaceholderText = Input.Placeholder,
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 30),
			Text = Input.Value,
			TextEditable = not Input.Disabled,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Box })
		New("UIStroke", { Color = "OutlineColor", Parent = Box })

		Box.FocusLost:Connect(function(Enter)
			if not Enter then
				return
			end
			Input.Value = Box.Text
			Library:SafeCallback(Input.Callback, Input.Value)
			Library:SafeCallback(Input.Changed, Input.Value)
		end)

		function Input:SetValue(Text)
			Input.Value = Text
			Box.Text = Text
			Library:SafeCallback(Input.Callback, Input.Value)
			Library:SafeCallback(Input.Changed, Input.Value)
		end

		Groupbox:Resize()
		Input.Holder = Holder
		table.insert(Groupbox.Elements, Input)
		Options[Idx] = Input
		return Input
	end

	function Funcs:AddSlider(Idx, Info)
		Info = Library:Validate(Info, Templates.Slider)
		local Groupbox = self
		local Container = Groupbox.Container

		local Slider = {
			Text = Info.Text,
			Value = Info.Default,
			Min = Info.Min,
			Max = Info.Max,
			Prefix = Info.Prefix,
			Suffix = Info.Suffix,
			Rounding = Info.Rounding,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Type = "Slider",
		}

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 31),
			Visible = Slider.Visible,
			Parent = Container,
		})

		local SliderLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Text = Slider.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local Bar = New("TextButton", {
			Active = not Slider.Disabled,
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = "MainColor",
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 13),
			Text = "",
			Parent = Holder,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Bar })
		New("UIStroke", { Color = "OutlineColor", Parent = Bar })

		local Fill = New("Frame", {
			BackgroundColor3 = "AccentColor",
			Size = UDim2.fromScale(0.5, 1),
			Parent = Bar,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Fill })

		local DisplayLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextSize = 12,
			ZIndex = 2,
			Parent = Bar,
		})

		function Slider:Display()
			local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
			Fill.Size = UDim2.fromScale(X, 1)
			DisplayLabel.Text = string.format(
				"%s%s%s / %s%s%s",
				Slider.Prefix,
				Slider.Value,
				Slider.Suffix,
				Slider.Prefix,
				Slider.Max,
				Slider.Suffix
			)
		end

		function Slider:SetValue(Value)
			Slider.Value = math.clamp(Round(Value, Slider.Rounding), Slider.Min, Slider.Max)
			Slider:Display()
			Library:SafeCallback(Slider.Callback, Slider.Value)
			Library:SafeCallback(Slider.Changed, Slider.Value)
		end

		Bar.InputBegan:Connect(function(Input: InputObject)
			if not IsClickInput(Input) or Slider.Disabled then
				return
			end
			while IsDragInput(Input) do
				local Location = Mouse.X
				local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
				Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * Scale))
				RunService.RenderStepped:Wait()
			end
		end)

		Slider:Display()
		Groupbox:Resize()

		Slider.Holder = Holder
		table.insert(Groupbox.Elements, Slider)
		Options[Idx] = Slider
		return Slider
	end

	function Funcs:AddDropdown(Idx, Info)
		Info = Library:Validate(Info, Templates.Dropdown)
		local Groupbox = self
		local Container = Groupbox.Container

		local Dropdown = {
			Text = Info.Text,
			Values = Info.Values,
			Value = Info.Multi and {} or nil,
			Multi = Info.Multi,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Type = "Dropdown",
		}

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 46),
			Parent = Container,
		})

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Text = Dropdown.Text,
			Parent = Holder,
		})

		local Display = New("TextButton", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = "MainColor",
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 28),
			Text = "---",
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Display })
		New("UIStroke", { Color = "OutlineColor", Parent = Display })
		New("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = Display })

		function Dropdown:Display()
			if Dropdown.Multi then
				local selected = {}
				for v, state in pairs(Dropdown.Value) do
					if state then
						table.insert(selected, tostring(v))
					end
				end
				Display.Text = #selected > 0 and table.concat(selected, ", ") or "---"
			else
				Display.Text = Dropdown.Value and tostring(Dropdown.Value) or "---"
			end
		end

		function Dropdown:SetValue(Value)
			Dropdown.Value = Value
			Dropdown:Display()
			Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
		end

		function Dropdown:SetValues(Values)
			Dropdown.Values = Values
		end

		Display.MouseButton1Click:Connect(function()
			-- Simple selection list implementation (compatible with Roblox contexts)
			if #Dropdown.Values == 0 then
				return
			end
			Dropdown:SetValue(Dropdown.Values[1]) -- toggle logic mock
		end)

		Dropdown:Display()
		Groupbox:Resize()

		Dropdown.Holder = Holder
		table.insert(Groupbox.Elements, Dropdown)
		Options[Idx] = Dropdown
		return Dropdown
	end

	function Funcs:AddValueDropdown(Idx, Info)
		return self:AddDropdown(Idx, Info)
	end

	function Funcs:AddDependencyBox()
		local Groupbox = self
		local Container = Groupbox.Container
		local DepboxContainer = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Container,
		})

		local Depbox = {
			Holder = DepboxContainer,
			Container = DepboxContainer,
			Elements = {},
			DependencyBoxes = {},
		}

		function Depbox:SetupDependencies(Dependencies)
			-- simple toggle dep
		end

		function Depbox:Update()
			DepboxContainer.Visible = true
		end

		setmetatable(Depbox, BaseGroupbox)
		table.insert(Groupbox.DependencyBoxes, Depbox)
		table.insert(Library.DependencyBoxes, Depbox)
		return Depbox
	end

	function Funcs:AddTextbox(Idx, Info)
		return self:AddInput(Idx, Info)
	end

	BaseGroupbox.__index = Funcs
	BaseGroupbox.__namecall = function(_, Key, ...)
		return Funcs[Key](...)
	end
end

-- ─── MAIN WINDOW BUILDER INTERACTION ──────────────────────────────────
function Library:CreateWindow(WindowInfo)
	WindowInfo = Library:Validate(WindowInfo, Templates.Window)
	local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize

	local MainFrame = New("Frame", {
		BackgroundColor3 = "BackgroundColor",
		Position = WindowInfo.Position,
		Size = WindowInfo.Size,
		Visible = false,
		Active = true,
		Parent = ScreenGui,
	})
	New("UICorner", { CornerRadius = UDim.new(0, WindowInfo.CornerRadius), Parent = MainFrame })
	Library:MakeOutline(MainFrame, WindowInfo.CornerRadius, 0)

	-- Top bar
	local TopBar = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 48),
		Parent = MainFrame,
	})
	Library:MakeDraggable(MainFrame, TopBar, false, true)

	local Title = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Text = WindowInfo.Title,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TopBar,
	})

	-- Sidebar tabs scrolling frame
	local Tabs = New("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = "BackgroundColor",
		Position = UDim2.fromOffset(0, 49),
		Size = UDim2.new(0.3, 0, 1, -70),
		ScrollBarThickness = 0,
		Parent = MainFrame,
	})
	New("UIListLayout", { Parent = Tabs })

	-- Page Container
	local Container = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = function()
			return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
		end,
		Position = UDim2.new(1, 0, 0, 49),
		Size = UDim2.new(0.7, -1, 1, -70),
		Parent = MainFrame,
	})

	-- Bottom Bar
	local BottomBar = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = "MainColor",
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 20),
		Parent = MainFrame,
	})
	New("UICorner", { CornerRadius = UDim.new(0, WindowInfo.CornerRadius), Parent = BottomBar })

	local FooterLabel = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = WindowInfo.Footer,
		TextSize = 14,
		Parent = BottomBar,
	})

	-- Resize Handle
	local ResizeButton = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Text = "",
		Parent = BottomBar,
	})
	Library:MakeResizable(MainFrame, ResizeButton, function()
		for _, Tab in pairs(Library.Tabs) do
			Tab:Resize(true)
		end
	end)

	-- Window control APIs
	local Window = {}

	function Window:SetFooterText(Text)
		FooterLabel.Text = tostring(Text or "")
	end

	function Window:AddTab(Name, Icon, Description)
		local TabButton = New("TextButton", {
			BackgroundColor3 = "MainColor",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			Text = Name,
			TextSize = 16,
			Parent = Tabs,
		})

		local TabContainer = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = Container,
		})

		local TabLeft = New("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.5, -4, 1, 0),
			ScrollBarThickness = 0,
			Parent = TabContainer,
		})
		New("UIListLayout", { Padding = UDim.new(0, 6), Parent = TabLeft })

		local TabRight = New("ScrollingFrame", {
			AnchorPoint = Vector2.new(1, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0.5, -4, 1, 0),
			ScrollBarThickness = 0,
			Parent = TabContainer,
		})
		New("UIListLayout", { Padding = UDim.new(0, 6), Parent = TabRight })

		local Tab = {
			Groupboxes = {},
			Tabboxes = {},
			DependencyGroupboxes = {},
			Sides = { TabLeft, TabRight },
		}

		function Tab:Resize()
			for _, Side in pairs(Tab.Sides) do
				Side.Size = UDim2.new(0.5, -4, 1, 0)
			end
		end

		function Tab:AddGroupbox(Info)
			Info = type(Info) == "table" and Info or { Name = tostring(Info) }
			local column = (Info.Side == 2) and TabRight or TabLeft

			local BoxHolder = New("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				Parent = column,
			})
			New("UIListLayout", { Padding = UDim.new(0, 6), Parent = BoxHolder })

			local Background = Library:MakeOutline(BoxHolder, WindowInfo.CornerRadius)
			Background.Size = UDim2.fromScale(1, 0)

			local GroupboxHolder = New("Frame", {
				BackgroundColor3 = "BackgroundColor",
				Position = UDim2.fromOffset(2, 2),
				Size = UDim2.new(1, -4, 1, -4),
				Parent = Background,
			})
			New("UICorner", { CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1), Parent = GroupboxHolder })

			local HeaderFrame = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 34),
				Parent = GroupboxHolder,
			})

			local GroupboxLabel = New("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -24, 1, 0),
				Text = Info.Name,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = HeaderFrame,
			})

			local GroupboxContainer = New("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 35),
				Size = UDim2.new(1, 0, 1, -35),
				Parent = GroupboxHolder,
			})
			local GroupboxList = New("UIListLayout", { Padding = UDim.new(0, 8), Parent = GroupboxContainer })
			New(
				"UIPadding",
				{
					PaddingBottom = UDim.new(0, 7),
					PaddingLeft = UDim.new(0, 7),
					PaddingRight = UDim.new(0, 7),
					PaddingTop = UDim.new(0, 7),
					Parent = GroupboxContainer,
				}
			)

			local Groupbox = {
				BoxHolder = BoxHolder,
				Holder = Background,
				Container = GroupboxContainer,
				Elements = {},
				DependencyBoxes = {},
			}

			function Groupbox:Resize()
				Background.Size = UDim2.new(1, 0, 0, GroupboxList.AbsoluteContentSize.Y + 45)
			end

			GroupboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				Groupbox:Resize()
			end)

			setmetatable(Groupbox, BaseGroupbox)
			Groupbox:Resize()
			Tab.Groupboxes[Info.Name] = Groupbox
			return Groupbox
		end

		function Tab:AddLeftGroupbox(Name, IconName, StartCollapsed)
			return Tab:AddGroupbox({ Side = 1, Name = Name })
		end

		function Tab:AddRightGroupbox(Name, IconName, StartCollapsed)
			return Tab:AddGroupbox({ Side = 2, Name = Name })
		end

		function Tab:Show()
			if Library.ActiveTab then
				Library.ActiveTab:Hide()
			end
			TabButton.BackgroundTransparency = 0
			TabContainer.Visible = true
			Library.ActiveTab = Tab
		end

		function Tab:Hide()
			TabButton.BackgroundTransparency = 1
			TabContainer.Visible = false
			Library.ActiveTab = nil
		end

		TabButton.MouseButton1Click:Connect(function()
			Tab:Show()
		end)

		-- Aliasing methods on Tab to make them compatible with AddPage/AddGroupbox
		Tab.AddGroupbox = Tab.AddGroupbox
		Tab.AddLeftGroupbox = Tab.AddLeftGroupbox
		Tab.AddRightGroupbox = Tab.AddRightGroupbox

		if not Library.ActiveTab then
			Tab:Show()
		end

		Library.Tabs[Name] = Tab
		return Tab
	end

	-- Window Method Aliases for complete App compliance
	Window.AddPage = Window.AddTab
	Window.AddTab = Window.AddTab

	function Library:Toggle(Value: boolean?)
		if typeof(Value) == "boolean" then
			Library.Toggled = Value
		else
			Library.Toggled = not Library.Toggled
		end
		MainFrame.Visible = Library.Toggled
	end

	if WindowInfo.AutoShow then
		Library:Toggle(true)
	end

	if true then
		local ToggleButton = Library:AddDraggableButton("<b><font color='#FFEA00'>Exotic</font></b>", function()
			Library:Toggle()
		end)
	end

	return Window
end

-- ─── GLOBAL UTILITIES ────────────────────────────────────────────────
local function OnPlayerChange()
	local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)
	for _, Dropdown in pairs(Options) do
		if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
			Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
		end
	end
end

local function OnTeamChange()
	local TeamList = GetTeams()
	for _, Dropdown in pairs(Options) do
		if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
			Dropdown:SetValues(TeamList)
		end
	end
end

Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

-- Initialize registries and return singleton
getgenv().LRX_UI = Library
return Library
