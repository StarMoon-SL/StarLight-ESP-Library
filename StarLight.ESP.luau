local StarLight_ESPLibrary = {
	ObjectsFolder = Instance.new("Folder"),
	ScreenGui = Instance.new("ScreenGui"),
	HighlightsFolder = Instance.new("Folder"),
	BillboardsFolder = Instance.new("Folder"),
	TracersFrame = Instance.new("Frame"),
	ArrowsFrame = Instance.new("Frame"),
	AdornmentsFolder = Instance.new("Folder"),
	Highlights = {},
	Labels = {},
	Elements = {},
	ElementsEnabled = {},
	Frames = {},
	TotalObjects = {},
	TransparencyEnabled = {},
	Connections = {},
	Billboards = {},
	ColorTable = {},
	TextTable = {},
	Lines = {},
	ArrowsTable = {},
	Font = Enum.Font.RobotoCondensed,
	ConnectionsTable = {},
	Objects = {},
	ConnectionsManager = {},
	TracerTable = {},
	HighlightedObjects = {},
	Adornments = {},
	Rainbow = false,
	Tracers = false,
	Unloaded = false,
	ShowDistance = false,
	MatchColors = true,
	Arrows = false,
	TextTransparency = 0,
	TracerOrigin = "Bottom",
	FillTransparency = 0.75,
	OutlineTransparency = 0,
	TextOffset = 0,
	TextOutlineTransparency = 0,
	FadeTime = 0,
	TracerSize = 0.5,
	ArrowRadius = 200,
	TextSize = 20,
	DistanceSizeRatio = 1,
	OutlineColor = Color3.fromRGB(255,255,255),
	RainbowColor = Color3.fromRGB(255,255,255),
	ESPType = "Highlight",
	Thickness = 0.1,
	Transparency = 0.65,
}
local RainbowTable = {
	HueSetup = 0,
	Hue = 0,
	Step = 0,
	Color = Color3.new(),
	Enabled = false,
}

function StarLight_ESPLibrary:GenerateRandomString()
	local FinishedString = {}
	local CharacterList = [==[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890]==]
	local function GenerateSegment()
		local RandomIndex = math.random(1,#CharacterList)
		local Character = CharacterList:sub(RandomIndex,RandomIndex)
		return Character
	end
	for i = 1,24,1 do
		local NewCharacter = GenerateSegment()
		table.insert(FinishedString, NewCharacter)
	end
	return table.concat(FinishedString)
end

local CloneReference = (cloneref and cloneref or function(Object) return Object end)
local Players = CloneReference(game:GetService("Players"))
local CoreGui = (getgenv and CloneReference(game:GetService("CoreGui")) or Players.LocalPlayer.PlayerGui)
local function GetHiddenUI()
	if gethui then
		return gethui()
	end
	local HiddenUI = Instance.new("Folder", CoreGui)
	HiddenUI.Name = StarLight_ESPLibrary:GenerateRandomString()
	return HiddenUI
end

local Workspace = CloneReference(workspace)
local HttpService = CloneReference(game:GetService("HttpService"))
local UserInputService = CloneReference(game:GetService("UserInputService"))
local RunService = CloneReference(game:GetService("RunService"))
local TweenService = CloneReference(game:GetService("TweenService"))
local Debris = CloneReference(game:GetService("Debris"))
local LocalPlayer = Players.LocalPlayer
local ObjectsFolder = StarLight_ESPLibrary.ObjectsFolder
local HighlightedObjects = StarLight_ESPLibrary.HighlightedObjects
local Highlights = StarLight_ESPLibrary.Highlights
local ConnectionsTable = StarLight_ESPLibrary.ConnectionsTable
local Objects = StarLight_ESPLibrary.Objects
local TotalObjects = StarLight_ESPLibrary.TotalObjects
local Billboards = StarLight_ESPLibrary.Billboards
local Frames = StarLight_ESPLibrary.Frames
local ScreenGui = StarLight_ESPLibrary.ScreenGui
local ArrowsTable = StarLight_ESPLibrary.ArrowsTable
local HighlightsFolder = StarLight_ESPLibrary.HighlightsFolder
local Labels = StarLight_ESPLibrary.Labels
local Connections = StarLight_ESPLibrary.Connections
local Elements = StarLight_ESPLibrary.Elements
local TextTable = StarLight_ESPLibrary.TextTable
local HiddenUI = GetHiddenUI()
local ColorTable = StarLight_ESPLibrary.ColorTable
local Camera = Workspace.CurrentCamera
local Mouse = CloneReference(LocalPlayer:GetMouse())
local TracersFrame = StarLight_ESPLibrary.TracersFrame
local ArrowsFrame = StarLight_ESPLibrary.ArrowsFrame
local AdornmentsFolder = StarLight_ESPLibrary.AdornmentsFolder

ScreenGui.Parent = HiddenUI
HighlightsFolder.Parent = ScreenGui
BillboardsFolder = StarLight_ESPLibrary.BillboardsFolder
BillboardsFolder.Parent = ScreenGui
AdornmentsFolder.Parent = ScreenGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
TracersFrame.Size = UDim2.new(1,0,1,0)
TracersFrame.BackgroundTransparency = 1
TracersFrame.Parent = ScreenGui
ArrowsFrame.Size = UDim2.new(1,0,1,0)
ArrowsFrame.BackgroundTransparency = 1
ArrowsFrame.Parent = ScreenGui
TracersFrame.Visible = false
ArrowsFrame.Visible = false
local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "http://www.roblox.com/asset/?id=16368985219"
ArrowTemplate.Size = UDim2.new(0, 50,0, 50)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowTemplate.BackgroundTransparency = 1
ArrowTemplate.ImageTransparency = 1
local Constraint = Instance.new("UIAspectRatioConstraint")
Constraint.Parent = ArrowTemplate
Constraint.AspectRatio = 1
Constraint.Name = "Constraint"

local function FindPrimaryPart(instance)
	if typeof(instance) ~= "Instance" then
		return nil
	end
	return (instance:IsA("Model") and instance.PrimaryPart or nil)
		or instance:FindFirstChildWhichIsA("BasePart")
		or instance:FindFirstChildWhichIsA("UnionOperation")
		or instance
end

local function TryGetProperty(instance, propertyName)
	local success, property = pcall(function()
		return instance[propertyName]
	end)
	return if success then property else nil
end

local function GetPivot(Instance)
	if Instance.ClassName == "Bone" then
		return Instance.TransformedWorldCFrame
	elseif Instance.ClassName == "Attachment" then
		return Instance.WorldCFrame
	elseif Instance.ClassName == "Camera" then
		return Instance.CFrame
	else
		return Instance:GetPivot()
	end
end

if StarLight_ESPLibrary.Unloaded == true then return end

function StarLight_ESPLibrary:AddESP(Parameters)
	local Object = Parameters.Object
	if StarLight_ESPLibrary.ElementsEnabled[Object] == true or StarLight_ESPLibrary.Unloaded == true then return end
	if not Object:IsA("BasePart") and not Object:IsA("Model") then
		return
	end

	local ESPType = Parameters.ESPType or "Highlight"
	local IsAdornment = ESPType == "SphereAdornment" or ESPType == "Adornment" or ESPType == "BoxHandleAdornment"

	StarLight_ESPLibrary.TransparencyEnabled[Object] = false

	if Highlights[Object] then
		Highlights[Object]:Destroy()
		Highlights[Object] = nil
	end

	if StarLight_ESPLibrary.Adornments[Object] then
		StarLight_ESPLibrary.Adornments[Object]:Destroy()
		StarLight_ESPLibrary.Adornments[Object] = nil
	end

	local MainPart = nil
	if Parameters.BasePart then
		MainPart = Parameters.BasePart
	end

	local Highlighter = nil
	local ModelSize = nil

	if IsAdornment then
		if Object:IsA("Model") then
			_, ModelSize = Object:GetBoundingBox()
		else
			if not TryGetProperty(Object, "Size") then
				local prim = FindPrimaryPart(Object)
				if not TryGetProperty(prim, "Size") then
					ESPType = "Highlight"
					IsAdornment = false
				else
					ModelSize = prim.Size
				end
			else
				ModelSize = Object.Size
			end
		end
	end

	if IsAdornment and ESPType == "SphereAdornment" then
		Highlighter = Instance.new("SphereHandleAdornment")
		Highlighter.Parent = AdornmentsFolder
		Highlighter.Name = StarLight_ESPLibrary:GenerateRandomString()
		Highlighter.Adornee = Object
		Highlighter.AlwaysOnTop = true
		Highlighter.ZIndex = 10
		Highlighter.Radius = ModelSize.X * 1.085
		Highlighter.CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
		Highlighter.Color3 = Parameters.Color or Color3.new()
		Highlighter.Transparency = Parameters.Transparency or StarLight_ESPLibrary.Transparency
		StarLight_ESPLibrary.Adornments[Object] = Highlighter
	elseif IsAdornment and (ESPType == "Adornment" or ESPType == "BoxHandleAdornment") then
		Highlighter = Instance.new("BoxHandleAdornment")
		Highlighter.Parent = AdornmentsFolder
		Highlighter.Name = StarLight_ESPLibrary:GenerateRandomString()
		Highlighter.Adornee = Object
		Highlighter.AlwaysOnTop = true
		Highlighter.ZIndex = 10
		Highlighter.Size = ModelSize or Vector3.new(5,5,5)
		Highlighter.Color3 = Parameters.Color or Color3.new()
		Highlighter.Transparency = Parameters.Transparency or StarLight_ESPLibrary.Transparency
		StarLight_ESPLibrary.Adornments[Object] = Highlighter
	else
		Highlighter = Instance.new("Highlight")
		Highlighter.FillTransparency = 1
		Highlighter.OutlineTransparency = 1
		Highlighter.Name = StarLight_ESPLibrary:GenerateRandomString()
		Highlighter.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		Highlighter.Parent = HighlightsFolder
		Highlighter.Adornee = Object
		Highlights[Object] = Highlighter
	end

	local ObjectTable = {Object}
	TextTable[Object] = Parameters.Text

	local TextFrame = Instance.new("Frame")
	TextFrame.Visible = false
	TextFrame.Name = StarLight_ESPLibrary:GenerateRandomString()
	TextFrame.Size = UDim2.fromScale(1,1)
	TextFrame.Parent = BillboardsFolder
	TextFrame.BackgroundTransparency = 1
	TextFrame.AnchorPoint = Vector2.new(0.5,0.5)

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Name = StarLight_ESPLibrary:GenerateRandomString()
	TextLabel.BackgroundTransparency = 1
	TextLabel.Text = Parameters.Text
	TextLabel.TextTransparency = 1
	TextLabel.TextStrokeTransparency = StarLight_ESPLibrary.TextOutlineTransparency
	TextLabel.Size = UDim2.new(1,0,1,0)
	TextLabel.Font = StarLight_ESPLibrary.Font
	TextLabel.TextSize = StarLight_ESPLibrary.TextSize
	TextLabel.RichText = true
	TextLabel.Parent = TextFrame
	TextLabel.TextColor3 = Parameters.Color
	Labels[Object] = TextLabel
	Objects[Object] = ObjectTable
	StarLight_ESPLibrary.ElementsEnabled[Object] = true
	Labels[Object] = TextLabel

	if Highlighter then
		if IsAdornment then
			TweenService:Create(Highlighter, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {Transparency = StarLight_ESPLibrary.Transparency}):Play()
		else
			TweenService:Create(Highlighter, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {FillTransparency = StarLight_ESPLibrary.FillTransparency}):Play()
			TweenService:Create(Highlighter, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {OutlineTransparency = StarLight_ESPLibrary.OutlineTransparency}):Play()
		end
	end

	Frames[Object] = TextFrame
	Labels[Object] = TextLabel
	Objects[Object] = Object
	ColorTable[Object] = Parameters.Color 

	local LineFrame = Instance.new("Frame")
	LineFrame.Size = UDim2.new(0,0,0,0)
	LineFrame.BackgroundTransparency = 1
	LineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	LineFrame.Parent = TracersFrame
	LineFrame.Name = StarLight_ESPLibrary:GenerateRandomString()

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = StarLight_ESPLibrary.TracerSize
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = LineFrame
	Stroke.Transparency = 1
	Stroke.Name = StarLight_ESPLibrary:GenerateRandomString()

	TweenService:Create(LineFrame, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Stroke, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {Transparency = 0}):Play()
	StarLight_ESPLibrary.Lines[Object] = {LineFrame, Stroke}

	if TextLabel then
		local Tween = TweenService:Create(TextLabel, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {TextTransparency = StarLight_ESPLibrary.TextTransparency})
		Tween:Play()
		TweenService:Create(TextLabel, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {TextStrokeTransparency = StarLight_ESPLibrary.TextOutlineTransparency}):Play()
		local TweenConnection = Tween.Completed:Once(function()
			StarLight_ESPLibrary.TransparencyEnabled[Object] = true
		end)
	end

	table.insert(Elements, TextFrame)
	table.insert(TotalObjects, Object)

	local Destroying1 = Object:GetPropertyChangedSignal("Parent"):Once(function()
		StarLight_ESPLibrary:RemoveESP(Object)
	end)
	if Object.Parent ~= nil then
		local Destroying2 = Object.Parent:GetPropertyChangedSignal("Parent"):Once(function()
			StarLight_ESPLibrary:RemoveESP(Object)
		end)
	end
	if Object:IsA("Model") and Object.PrimaryPart then
		local Destroying3 = Object.PrimaryPart:GetPropertyChangedSignal("Parent"):Once(function()
			StarLight_ESPLibrary:RemoveESP(Object)
		end)
	end

	task.spawn(function()
		local function Render()
			local Position
			Position = GetPivot(Object).Position
			if Position then
				local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(Position)
				local Frame = Frames[Object]
				local Label = Labels[Object]
				local HighlightInst = Highlights[Object]
				local AdornmentInst = StarLight_ESPLibrary.Adornments[Object]

				if StarLight_ESPLibrary.Lines[Object][1] then
					StarLight_ESPLibrary.Lines[Object][1].Visible = (OnScreen)
				end
				if Frame then Frame.Visible = OnScreen end

				if not OnScreen then
					if HighlightInst then 
						HighlightInst:Destroy() 
						Highlights[Object] = nil 
						HighlightInst = nil 
					end
					if AdornmentInst then
						AdornmentInst:Destroy()
						StarLight_ESPLibrary.Adornments[Object] = nil
						AdornmentInst = nil
					end
				elseif Frame then
					Frame.Position = UDim2.new(0, ScreenPoint.X, 0, ScreenPoint.Y)
				end

				if StarLight_ESPLibrary.ElementsEnabled[Object] == true and OnScreen then
					if not HighlightInst and not AdornmentInst and not IsAdornment then
						HighlightInst = Instance.new("Highlight")
						HighlightInst.FillTransparency = 1
						HighlightInst.OutlineTransparency = 1
						HighlightInst.Name = StarLight_ESPLibrary:GenerateRandomString()
						HighlightInst.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						HighlightInst.Parent = HighlightsFolder
						HighlightInst.Adornee = Object
						Highlights[Object] = HighlightInst
					elseif IsAdornment and not AdornmentInst and OnScreen then
						if ESPType == "SphereAdornment" then
							AdornmentInst = Instance.new("SphereHandleAdornment")
							AdornmentInst.Radius = ModelSize.X * 1.085
							AdornmentInst.CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
						else
							AdornmentInst = Instance.new("BoxHandleAdornment")
							AdornmentInst.Size = ModelSize or Vector3.new(5,5,5)
						end
						AdornmentInst.Parent = AdornmentsFolder
						AdornmentInst.Name = StarLight_ESPLibrary:GenerateRandomString()
						AdornmentInst.Adornee = Object
						AdornmentInst.AlwaysOnTop = true
						AdornmentInst.ZIndex = 10
						AdornmentInst.Color3 = ColorTable[Object] or Color3.new()
						AdornmentInst.Transparency = StarLight_ESPLibrary.Transparency
						StarLight_ESPLibrary.Adornments[Object] = AdornmentInst
					end
				end

				if Label then
					Label.TextColor3 = StarLight_ESPLibrary.Rainbow and RainbowTable.Color or ColorTable[Object] or Color3.fromRGB(255,255,255)
				end

				local distance = math.floor((Camera.CFrame.Position - Position).Magnitude)
				local distanceText = StarLight_ESPLibrary.ShowDistance and ("\n" .. '<font size="' .. math.round(StarLight_ESPLibrary.TextSize * StarLight_ESPLibrary.DistanceSizeRatio) .. '">[' .. distance .. ']</font>') or ""

				if Label then
					Label.Text = TextTable[Object] .. distanceText
				end

				if HighlightInst and not IsAdornment then
					HighlightInst.Enabled = true
					HighlightInst.FillColor = StarLight_ESPLibrary.Rainbow and RainbowTable.Color or ColorTable[Object] or Color3.fromRGB(255,255,255)
					HighlightInst.OutlineColor = StarLight_ESPLibrary.MatchColors and HighlightInst.FillColor or StarLight_ESPLibrary.OutlineColor
					if StarLight_ESPLibrary.TransparencyEnabled[Object] == true then
						HighlightInst.FillTransparency = StarLight_ESPLibrary.FillTransparency
						HighlightInst.OutlineTransparency = StarLight_ESPLibrary.OutlineTransparency
						Label.TextTransparency = StarLight_ESPLibrary.TextTransparency
						Label.TextStrokeTransparency = StarLight_ESPLibrary.TextOutlineTransparency
					end
				elseif AdornmentInst and IsAdornment then
					AdornmentInst.Color3 = StarLight_ESPLibrary.Rainbow and RainbowTable.Color or ColorTable[Object] or Color3.new()
					if StarLight_ESPLibrary.TransparencyEnabled[Object] == true then
						AdornmentInst.Transparency = StarLight_ESPLibrary.Transparency
						Label.TextTransparency = StarLight_ESPLibrary.TextTransparency
						Label.TextStrokeTransparency = StarLight_ESPLibrary.TextOutlineTransparency
					end
				end

				local LineFrame = StarLight_ESPLibrary.Lines[Object][1]
				local Stroke = StarLight_ESPLibrary.Lines[Object][2]
				local Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 1)

				if LineFrame and (HighlightInst or AdornmentInst) and StarLight_ESPLibrary.Tracers == true and OnScreen then
					if StarLight_ESPLibrary.TracerOrigin == "Center" then
						local MousePos = UserInputService:GetMouseLocation()
						Origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
					elseif StarLight_ESPLibrary.TracerOrigin == "Top" then
						Origin = Vector2.new(Camera.ViewportSize.X/2, 0)	
					elseif StarLight_ESPLibrary.TracerOrigin == "Mouse" then
						Origin = Vector2.new(LocalPlayer:GetMouse().X, UserInputService:GetMouseLocation().Y)
					end

					local Destination = Vector2.new(ScreenPoint.X, ScreenPoint.Y)
					local Position = (Origin + Destination) / 2
					local Rotation = math.deg(math.atan2(Destination.Y - Origin.Y, Destination.X - Origin.X))
					local Length = (Origin - Destination).Magnitude

					LineFrame.Position = UDim2.new(0, Position.X, 0, Position.Y)
					LineFrame.Size = UDim2.new(0, Length, 0, 1)
					LineFrame.Rotation = Rotation
					LineFrame.BorderSizePixel = 0

					if HighlightInst and not IsAdornment then
						LineFrame.BackgroundColor3 = HighlightInst.FillColor
						Stroke.Color = HighlightInst.FillColor
					elseif AdornmentInst and IsAdornment then
						LineFrame.BackgroundColor3 = AdornmentInst.Color3
						Stroke.Color = AdornmentInst.Color3
					end

					Stroke.Thickness = StarLight_ESPLibrary.TracerSize
					LineFrame.Visible = true
				end

				local function GetArrowData(objPos)
					local ScreenSize = Camera.ViewportSize
					local ScreenCenter = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
					local ToObj = (objPos - Camera.CFrame.Position).Unit
					local CamForward = Camera.CFrame.LookVector
					local Dir = Vector2.new(ScreenPoint.X, ScreenPoint.Y) - ScreenCenter
					local Dot = CamForward:Dot(ToObj)
					if Dot < 0 then
						Dir = -Dir
					end
					local Angle = math.atan2(Dir.Y, Dir.X)
					local radius = math.min(ScreenSize.X, ScreenSize.Y) / 2 - (400 - StarLight_ESPLibrary.ArrowRadius)
					local ArrowPos = ScreenCenter + Dir.Unit * radius
					return ArrowPos, math.deg(Angle)
				end

				if Object and StarLight_ESPLibrary.Arrows == true then
					local Arrow = ArrowsTable[Object] or nil
					if Arrow == nil and StarLight_ESPLibrary.ElementsEnabled[Object] == true then
						Arrow = ArrowTemplate:Clone()
						Arrow.Parent = ArrowsFrame
						Arrow.Name = StarLight_ESPLibrary:GenerateRandomString()
						Arrow:WaitForChild("Constraint").Name = StarLight_ESPLibrary:GenerateRandomString()
						ArrowsTable[Object] = Arrow
						TweenService:Create(Arrow, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()
					elseif StarLight_ESPLibrary.ElementsEnabled[Object] == true then
						if OnScreen and ScreenPoint.Z > 0 then
							ArrowsTable[Object].Visible = false
						else
							local arrowPos, angle = GetArrowData(GetPivot(Object).Position)
							ArrowsTable[Object].Position = UDim2.new(0, arrowPos.X, 0, arrowPos.Y)
							ArrowsTable[Object].Rotation = angle - 90
							ArrowsTable[Object].Visible = true
							ArrowsTable[Object].ImageColor3 = (StarLight_ESPLibrary.Rainbow == true and StarLight_ESPLibrary.RainbowColor or ColorTable[Object])
						end
					end
				end
			end
		end

		local Connection = RunService.PreRender:Connect(function()
			Render()
		end)
		ConnectionsTable[Object] = Connection
	end)
end

function StarLight_ESPLibrary:SetColorTable(Name, Color)
	ColorTable[Name] = Color
end

function StarLight_ESPLibrary:SetFadeTime(Number)
	StarLight_ESPLibrary.FadeTime = Number
end

function StarLight_ESPLibrary:SetTextTransparency(Number)
	StarLight_ESPLibrary.TextTransparency = Number
	for i, Label in pairs(Labels) do
		Label.TextTransparency = Number
	end
end

function StarLight_ESPLibrary:SetFillTransparency(Number)
	StarLight_ESPLibrary.FillTransparency = Number
	for i, Highlight in pairs(Highlights) do
		if Highlight:IsA("Highlight") then
			Highlight.FillTransparency = Number
		end
	end
end

function StarLight_ESPLibrary:SetOutlineTransparency(Number)
	StarLight_ESPLibrary.OutlineTransparency = Number
	for i, Highlight in pairs(Highlights) do
		if Highlight:IsA("Highlight") then
			Highlight.OutlineTransparency = Number
		end
	end
end

function StarLight_ESPLibrary:SetTextSize(Number)
	StarLight_ESPLibrary.TextSize = Number
	for i, Label in pairs(Labels) do
		Label.TextSize = Number
	end
end

function StarLight_ESPLibrary:SetTextOutlineTransparency(Number)
	StarLight_ESPLibrary.TextOutlineTransparency = Number
	for i, Label in pairs(Labels) do
		Label.TextStrokeTransparency = Number
	end
end

function StarLight_ESPLibrary:SetFont(Font)
	StarLight_ESPLibrary.Font = Font
	for i, Label in pairs(Labels) do
		Label.Font = Font
	end
end

function StarLight_ESPLibrary:UpdateObjectText(Object, Text)
	if Labels[Object] then
		TextTable[Object] = Text
	end
end

function StarLight_ESPLibrary:UpdateObjectColor(Object, Color)
	ColorTable[Object] = Color
	if Labels[Object] then
		Labels[Object].TextColor3 = Color
	end
	if StarLight_ESPLibrary.Adornments[Object] then
		StarLight_ESPLibrary.Adornments[Object].Color3 = Color
	end
end

function StarLight_ESPLibrary:SetOutlineColor(Color)
	StarLight_ESPLibrary.OutlineColor = Color
end

function StarLight_ESPLibrary:SetRainbow(Value)
	StarLight_ESPLibrary.Rainbow = Value
end

function StarLight_ESPLibrary:SetShowDistance(Value)
	StarLight_ESPLibrary.ShowDistance = Value
end

function StarLight_ESPLibrary:SetMatchColors(Value)
	StarLight_ESPLibrary.MatchColors = Value
end

function StarLight_ESPLibrary:SetTracers(Value)
	StarLight_ESPLibrary.Tracers = Value
	TracersFrame.Visible = Value
end

function StarLight_ESPLibrary:SetArrows(Value)
	StarLight_ESPLibrary.Arrows = Value
	ArrowsFrame.Visible = Value
end

function StarLight_ESPLibrary:SetArrowRadius(Value)
	StarLight_ESPLibrary.ArrowRadius = Value
end

function StarLight_ESPLibrary:SetTracerOrigin(Value)
	StarLight_ESPLibrary.TracerOrigin = Value
end

function StarLight_ESPLibrary:SetDistanceSizeRatio(Value)
	StarLight_ESPLibrary.DistanceSizeRatio = Value
end

function StarLight_ESPLibrary:SetTracerSize(Value)
	StarLight_ESPLibrary.TracerSize = 0.5 * Value
end

function StarLight_ESPLibrary:SetTransparency(Number)
	StarLight_ESPLibrary.Transparency = Number
	for i, Adornment in pairs(StarLight_ESPLibrary.Adornments) do
		if Adornment then
			Adornment.Transparency = Number
		end
	end
end

function StarLight_ESPLibrary:SetThickness(Number)
	StarLight_ESPLibrary.Thickness = Number
end

function RemoveObjectFromTables(Object)
	for index, obj in pairs(TotalObjects) do
		if obj == Object then
			table.remove(TotalObjects, index)
			break
		end
	end
end

function StarLight_ESPLibrary:RemoveESP(Object)
	if StarLight_ESPLibrary.Unloaded == true or StarLight_ESPLibrary.ElementsEnabled[Object] ~= true then return end
	StarLight_ESPLibrary.ElementsEnabled[Object] = false
	StarLight_ESPLibrary.TransparencyEnabled[Object] = false

	local Value = Instance.new("Frame", game.ReplicatedStorage)
	Value.BackgroundTransparency = 0
	Value.Name = StarLight_ESPLibrary:GenerateRandomString()
	Debris:AddItem(Value, StarLight_ESPLibrary.FadeTime + 0.5)

	local TextFrame = Frames[Object]
	local TextLabel = Labels[Object]

	if TextLabel then
		TweenService:Create(TextLabel, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
	end

	if StarLight_ESPLibrary.Lines[Object] ~= nil then
		if StarLight_ESPLibrary.Lines[Object][1] ~= nil then
			TweenService:Create(StarLight_ESPLibrary.Lines[Object][1], TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
		end
		if StarLight_ESPLibrary.Lines[Object][2] ~= nil then
			TweenService:Create(StarLight_ESPLibrary.Lines[Object][2], TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
		end
	end

	local Highlight
	if Highlights[Object] then
		TweenService:Create(Highlights[Object], TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {FillTransparency = 1}):Play()
		TweenService:Create(Highlights[Object], TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {OutlineTransparency = 1}):Play()
		Highlight = Highlights[Object]
	end

	local Adornment
	if StarLight_ESPLibrary.Adornments[Object] then
		TweenService:Create(StarLight_ESPLibrary.Adornments[Object], TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
		Adornment = StarLight_ESPLibrary.Adornments[Object]
	end

	if StarLight_ESPLibrary.Lines[Object][2] ~= nil then
		TweenService:Create(StarLight_ESPLibrary.Lines[Object][2], TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
	end

	if ArrowsTable[Object] ~= nil then
		TweenService:Create(ArrowsTable[Object], TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
	end

	if Object.Parent == nil then
		if StarLight_ESPLibrary.ElementsEnabled[Object] == false then
			if Frames[Object] then
				Frames[Object]:Destroy()
				Frames[Object] = nil
			end
			Objects[Object] = nil
			if Highlight then
				Highlight:Destroy()
				Highlights[Object] = nil
			end
			if Adornment then
				Adornment:Destroy()
				StarLight_ESPLibrary.Adornments[Object] = nil
			end
			RemoveObjectFromTables(Object)
			if ArrowsTable[Object] then
				ArrowsTable[Object]:Destroy()
				ArrowsTable[Object] = nil
			end
			if Connections[Object] then
				Connections[Object]:Disconnect()
			end
			if StarLight_ESPLibrary.Lines[Object] ~= nil then
				if StarLight_ESPLibrary.Lines[Object][1] ~= nil then
					StarLight_ESPLibrary.Lines[Object][1]:Destroy()
				end
				if StarLight_ESPLibrary.Lines[Object][2] ~= nil then
					StarLight_ESPLibrary.Lines[Object][2]:Destroy()
				end
				StarLight_ESPLibrary.Lines[Object] = {}
			end
			if StarLight_ESPLibrary.TracerTable[Object] ~= nil then
				StarLight_ESPLibrary.TracerTable[Object]:Destroy()
			end
			Value:Destroy()
		else
			if Highlight then
				TweenService:Create(Highlight, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {FillTransparency = StarLight_ESPLibrary.FillTransparency}):Play()
				TweenService:Create(Highlight, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {OutlineTransparency = StarLight_ESPLibrary.OutlineTransparency}):Play()
			end
			if Adornment then
				TweenService:Create(Adornment, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {Transparency = StarLight_ESPLibrary.Transparency}):Play()
			end
		end
	else
		local DestroyTween = TweenService:Create(Value, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
		DestroyTween:Play()
		local DestroyTween1 = DestroyTween.Completed:Once(function()
			if StarLight_ESPLibrary.ElementsEnabled[Object] == false then
				if Frames[Object] then
					Frames[Object]:Destroy()
					Frames[Object] = nil
				end
				RemoveObjectFromTables(Object)
				if Connections[Object] then
					Connections[Object]:Disconnect()
				end
				if ArrowsTable[Object] then
					ArrowsTable[Object]:Destroy()
					ArrowsTable[Object] = nil
				end
				if Highlight then
					Highlight:Destroy()
					Highlights[Object] = nil
				end
				if Adornment then
					Adornment:Destroy()
					StarLight_ESPLibrary.Adornments[Object] = nil
				end
				if StarLight_ESPLibrary.Lines[Object] ~= nil then
					if StarLight_ESPLibrary.Lines[Object][1] ~= nil then
						StarLight_ESPLibrary.Lines[Object][1]:Destroy()
					end
					if StarLight_ESPLibrary.Lines[Object][2] ~= nil then
						StarLight_ESPLibrary.Lines[Object][2]:Destroy()
					end
					StarLight_ESPLibrary.Lines[Object] = {}
				end
				if StarLight_ESPLibrary.TracerTable[Object] ~= nil then
					StarLight_ESPLibrary.TracerTable[Object]:Destroy()
				end
				Value:Destroy()
			else
				if Highlight then
					TweenService:Create(Highlight, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {FillTransparency = StarLight_ESPLibrary.FillTransparency}):Play()
					TweenService:Create(Highlight, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {OutlineTransparency = StarLight_ESPLibrary.OutlineTransparency}):Play()
				end
				if Adornment then
					TweenService:Create(Adornment, TweenInfo.new(StarLight_ESPLibrary.FadeTime, Enum.EasingStyle.Quad), {Transparency = StarLight_ESPLibrary.Transparency}):Play()
				end
			end
		end)
	end
end

local RainbowConnection = RunService.RenderStepped:Connect(function(Delta)
	RainbowTable.Step = RainbowTable.Step + Delta
	if RainbowTable.Step >= (1 / 60) then
		RainbowTable.Step = 0
		RainbowTable.HueSetup = RainbowTable.HueSetup + (1 / 400)
		if RainbowTable.HueSetup > 1 then RainbowTable.HueSetup = 0 end
		RainbowTable.Hue = RainbowTable.HueSetup
		RainbowTable.Color = Color3.fromHSV(RainbowTable.Hue, 0.8, 1)
		StarLight_ESPLibrary.RainbowColor = Color3.fromHSV(RainbowTable.Hue, 0.8, 1)
	end
end)

CameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

function StarLight_ESPLibrary:Unload()
	for i, Object in pairs(StarLight_ESPLibrary.Objects) do
		StarLight_ESPLibrary:RemoveESP(Object)
	end
	for i, Connection in pairs(ConnectionsTable) do
		Connection:Disconnect()
	end
	RainbowConnection:Disconnect()
	CameraConnection:Disconnect()
	ScreenGui.Enabled = false
	StarLight_ESPLibrary.Unloaded = true
end

ObjectsFolder.Name = StarLight_ESPLibrary:GenerateRandomString()
ScreenGui.Name = StarLight_ESPLibrary:GenerateRandomString()
HighlightsFolder.Name = StarLight_ESPLibrary:GenerateRandomString()
TracersFrame.Name = StarLight_ESPLibrary:GenerateRandomString()
ArrowsFrame.Name = StarLight_ESPLibrary:GenerateRandomString()
BillboardsFolder.Name = StarLight_ESPLibrary:GenerateRandomString()
AdornmentsFolder.Name = StarLight_ESPLibrary:GenerateRandomString()

if getgenv then
	getgenv().StarLight_ESPLibrary = StarLight_ESPLibrary
end

return StarLight_ESPLibrary
