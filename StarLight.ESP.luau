local StarLightESP = {}
local Cache = {}

local function GetServices()
    local Services = {}
    setmetatable(Services, {
        __index = function(self, ServiceName)
            local Service = game:GetService(ServiceName)
            if cloneref then Service = cloneref(Service) end
            return Service
        end
    })
    return Services
end

local Services = GetServices()
local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local CoreGui = Services.CoreGui

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function RandomString(length)
    length = length or math.random(10, 20)
    local array = {}
    for i = 1, length do
        array[i] = string.char(math.random(33, 126))
    end
    return table.concat(array)
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

local function FindPrimaryPart(Instance)
    if typeof(Instance) ~= "Instance" then return nil end
    return (Instance:IsA("Model") and Instance.PrimaryPart or nil)
        or Instance:FindFirstChildWhichIsA("BasePart")
        or Instance:FindFirstChildWhichIsA("UnionOperation")
        or Instance
end

local function GetTracerOrigin(OriginType)
    if OriginType == 2 then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    elseif OriginType == 3 then
        return Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif OriginType == 4 then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    elseif OriginType == 5 then
        return UserInputService:GetMouseLocation()
    elseif OriginType == 1 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local Position = Camera:WorldToViewportPoint(LocalPlayer.Character.HumanoidRootPart.Position)
        return Vector2.new(Position.X, Position.Y)
    else
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    end
end

local RainbowHue = 0
local RainbowColor = Color3.fromHSV(0, 0.8, 1)

local Library = {
    Settings = {
        Enabled = true,
        Rainbow = false,
        MaxDistance = 2000,
        TextSize = 13,
        RefreshRate = 0.016,
        Box = {
            Enabled = true,
            Style = 1,
            Thickness = 1,
            Filled = {Enabled = false, Transparency = 0.5},
            Color = Color3.new(1, 1, 1)
        },
        Tracer = {
            Enabled = true,
            Thickness = 1,
            Origin = 2,
            Color = Color3.new(1, 1, 1)
        },
        Arrow = {
            Enabled = true,
            Color = Color3.new(1, 1, 1),
            CenterOffset = 300
        },
        Dot = {
            Enabled = true,
            Size = 4,
            Color = Color3.new(1, 1, 1),
            Filled = true
        },
        HealthBar = {
            Enabled = true,
            Position = 1,
            Color = Color3.new(0, 1, 0),
            OutlineColor = Color3.new(0, 0, 0)
        },
        Name = {
            Enabled = true,
            Color = Color3.new(1, 1, 1)
        },
        Distance = {
            Enabled = true,
            Color = Color3.new(0.8, 0.8, 0.8)
        },
        Skeleton = {
            Enabled = false,
            Thickness = 1,
            Color = Color3.new(1, 1, 1)
        },
        Chams = {
            Enabled = true,
            Type = "Highlight",
            FillColor = Color3.new(1, 0, 0),
            OutlineColor = Color3.new(1, 1, 1),
            FillTransparency = 0.65,
            OutlineTransparency = 0
        },
        Radar = {
            Enabled = true,
            Position = Vector2.new(150, 150),
            Radius = 100,
            Scale = 1,
            Color = Color3.new(1, 1, 1)
        }
    },
    Drawings = {ESP = {}, Skeleton = {}, RadarObjects = {}},
    Highlights = {},
    Arrows = {},
    ChamsObjects = {},
    _connections = {}
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = RandomString()
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999

local function GetColor(BaseColor)
    if Library.Settings.Rainbow then
        return RainbowColor
    end
    return BaseColor
end

local PlayerESP = {}
PlayerESP.__index = PlayerESP

function PlayerESP.CreateESP(Player)
    local Box = {
        TopLeft = Drawing.new("Line"),
        TopRight = Drawing.new("Line"),
        BottomLeft = Drawing.new("Line"),
        BottomRight = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line")
    }
    for _, Line in pairs(Box) do
        Line.Visible = false
        Line.Color = Library.Settings.Box.Color
        Line.Thickness = Library.Settings.Box.Thickness
    end
    
    local Tracer = Drawing.new("Line")
    Tracer.Visible = false
    Tracer.Thickness = Library.Settings.Tracer.Thickness
    Tracer.Color = Library.Settings.Tracer.Color
    
    local Dot = Drawing.new("Circle")
    Dot.Visible = false
    Dot.Radius = Library.Settings.Dot.Size
    Dot.Color = Library.Settings.Dot.Color
    Dot.Filled = Library.Settings.Dot.Filled
    Dot.Thickness = 1
    
    local Arrow = Instance.new("ImageLabel")
    Arrow.Name = RandomString()
    Arrow.Parent = ScreenGui
    Arrow.Size = UDim2.new(0, 48, 0, 48)
    Arrow.SizeConstraint = Enum.SizeConstraint.RelativeYY
    Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    Arrow.BackgroundTransparency = 1
    Arrow.BorderSizePixel = 0
    Arrow.Image = "http://www.roblox.com/asset/?id=16368985219"
    Arrow.ImageColor3 = Library.Settings.Arrow.Color
    Arrow.Visible = false
    
    local HealthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square")
    }
    HealthBar.Outline.Visible = false
    HealthBar.Outline.Filled = false
    HealthBar.Outline.Thickness = 1
    HealthBar.Outline.Color = Library.Settings.HealthBar.OutlineColor
    HealthBar.Fill.Visible = false
    HealthBar.Fill.Filled = true
    
    local Info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    for _, Text in pairs(Info) do
        Text.Visible = false
        Text.Center = true
        Text.Size = Library.Settings.TextSize
        Text.Color = Library.Settings.Name.Color
        Text.Font = 2
        Text.Outline = true
    end
    Info.Distance.Color = Library.Settings.Distance.Color
    
    local Skeleton = {
        Head = Drawing.new("Line"),
        Neck = Drawing.new("Line"),
        UpperSpine = Drawing.new("Line"),
        LowerSpine = Drawing.new("Line"),
        LeftShoulder = Drawing.new("Line"),
        LeftUpperArm = Drawing.new("Line"),
        LeftLowerArm = Drawing.new("Line"),
        LeftHand = Drawing.new("Line"),
        RightShoulder = Drawing.new("Line"),
        RightUpperArm = Drawing.new("Line"),
        RightLowerArm = Drawing.new("Line"),
        RightHand = Drawing.new("Line"),
        LeftHip = Drawing.new("Line"),
        LeftUpperLeg = Drawing.new("Line"),
        LeftLowerLeg = Drawing.new("Line"),
        LeftFoot = Drawing.new("Line"),
        RightHip = Drawing.new("Line"),
        RightUpperLeg = Drawing.new("Line"),
        RightLowerLeg = Drawing.new("Line"),
        RightFoot = Drawing.new("Line")
    }
    for _, Bone in pairs(Skeleton) do
        Bone.Visible = false
        Bone.Color = Library.Settings.Skeleton.Color
        Bone.Thickness = Library.Settings.Skeleton.Thickness
    end
    
    Library.Drawings.ESP[Player] = {
        Box = Box,
        Tracer = Tracer,
        Dot = Dot,
        HealthBar = HealthBar,
        Info = Info,
        Fills = {}
    }
    Library.Drawings.Skeleton[Player] = Skeleton
    Library.Arrows[Player] = Arrow
end

function PlayerESP.RemoveESP(Player)
    local ESPData = Library.Drawings.ESP[Player]
    if ESPData then
        for _, Line in pairs(ESPData.Box) do
            pcall(function() Line:Remove() end)
        end
        pcall(function() ESPData.Tracer:Remove() end)
        pcall(function() ESPData.Dot:Remove() end)
        for _, Object in pairs(ESPData.HealthBar) do
            pcall(function() Object:Remove() end)
        end
        for _, Object in pairs(ESPData.Info) do
            pcall(function() Object:Remove() end)
        end
        for _, Object in pairs(ESPData.Fills) do
            pcall(function() Object:Remove() end)
        end
        Library.Drawings.ESP[Player] = nil
    end
    
    local SkeletonData = Library.Drawings.Skeleton[Player]
    if SkeletonData then
        for _, Bone in pairs(SkeletonData) do
            pcall(function() Bone:Remove() end)
        end
        Library.Drawings.Skeleton[Player] = nil
    end
    
    local Arrow = Library.Arrows[Player]
    if Arrow then
        pcall(function() Arrow:Destroy() end)
        Library.Arrows[Player] = nil
    end
    
    local Chams = Library.ChamsObjects[Player]
    if Chams then
        pcall(function() Chams:Destroy() end)
        Library.ChamsObjects[Player] = nil
    end
end

function PlayerESP.UpdateChams(Player, Character, IsVisible)
    if not Library.Settings.Chams.Enabled then
        local Existing = Library.ChamsObjects[Player]
        if Existing then
            Existing:Destroy()
            Library.ChamsObjects[Player] = nil
        end
        return
    end
    
    if not Character then return end
    local Model = Character
    local Chams = Library.ChamsObjects[Player]
    local ChamType = Library.Settings.Chams.Type
    local Color = GetColor(Library.Settings.Chams.FillColor)
    
    if not Chams or Chams.ClassName:lower() ~= ChamType:lower() then
        if Chams then
            pcall(function() Chams:Destroy() end)
        end
        
        if ChamType == "Highlight" then
            Chams = Instance.new("Highlight")
            Chams.FillColor = Library.Settings.Chams.FillColor
            Chams.OutlineColor = Library.Settings.Chams.OutlineColor
            Chams.FillTransparency = Library.Settings.Chams.FillTransparency
            Chams.OutlineTransparency = Library.Settings.Chams.OutlineTransparency
            Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        elseif ChamType == "SelectionBox" then
            Chams = Instance.new("SelectionBox")
            Chams.Color3 = Library.Settings.Chams.FillColor
            Chams.SurfaceColor3 = Library.Settings.Chams.FillColor
            Chams.LineThickness = 0.01
        elseif ChamType == "BoxAdornment" then
            Chams = Instance.new("BoxHandleAdornment")
            Chams.Color3 = Library.Settings.Chams.FillColor
            Chams.Transparency = Library.Settings.Chams.FillTransparency
            Chams.AlwaysOnTop = true
            Chams.ZIndex = 10
            local Size = Vector3.new(5, 6, 2)
            if Model:IsA("Model") and Model.PrimaryPart then
                Size = Model.PrimaryPart.Size
            elseif Model:FindFirstChild("HumanoidRootPart") then
                Size = Model.HumanoidRootPart.Size
            end
            Chams.Size = Size
        elseif ChamType == "SphereAdornment" then
            Chams = Instance.new("SphereHandleAdornment")
            Chams.Color3 = Library.Settings.Chams.FillColor
            Chams.Transparency = Library.Settings.Chams.FillTransparency
            Chams.AlwaysOnTop = true
            Chams.ZIndex = 10
            Chams.Radius = 3
        else
            Chams = Instance.new("BoxHandleAdornment")
            Chams.Color3 = Library.Settings.Chams.FillColor
            Chams.Transparency = Library.Settings.Chams.FillTransparency
            Chams.AlwaysOnTop = true
            Chams.ZIndex = 10
            Chams.Size = Vector3.new(4, 6, 2)
        end
        
        Chams.Name = RandomString()
        Chams.Adornee = Model
        Chams.Parent = ScreenGui
        Library.ChamsObjects[Player] = Chams
    end
    
    if Chams then
        Chams.Adornee = Model
        if ChamType == "Highlight" then
            Chams.FillColor = GetColor(Library.Settings.Chams.FillColor)
            Chams.OutlineColor = GetColor(Library.Settings.Chams.OutlineColor)
            Chams.Enabled = IsVisible
        elseif ChamType == "SelectionBox" then
            Chams.Color3 = GetColor(Library.Settings.Chams.FillColor)
            Chams.SurfaceColor3 = GetColor(Library.Settings.Chams.FillColor)
        else
            Chams.Color3 = GetColor(Library.Settings.Chams.FillColor)
            Chams.Visible = IsVisible
        end
    end
end

function PlayerESP.UpdateESP(Player)
    if not Library.Settings.Enabled then 
        PlayerESP.RemoveESP(Player)
        return 
    end
    
    local ESPData = Library.Drawings.ESP[Player]
    if not ESPData then 
        PlayerESP.CreateESP(Player)
        ESPData = Library.Drawings.ESP[Player]
    end
    
    local Arrow = Library.Arrows[Player]
    local SkeletonData = Library.Drawings.Skeleton[Player]
    local Character = Player.Character
    
    if not Character then
        for _, Line in pairs(ESPData.Box) do Line.Visible = false end
        ESPData.Tracer.Visible = false
        ESPData.Dot.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do Object.Visible = false end
        for _, Object in pairs(ESPData.Info) do Object.Visible = false end
        if Arrow then Arrow.Visible = false end
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do Bone.Visible = false end
        end
        PlayerESP.UpdateChams(Player, nil, false)
        return
    end
    
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChild("Humanoid")
    
    if not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then
        for _, Line in pairs(ESPData.Box) do Line.Visible = false end
        ESPData.Tracer.Visible = false
        ESPData.Dot.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do Object.Visible = false end
        for _, Object in pairs(ESPData.Info) do Object.Visible = false end
        if Arrow then Arrow.Visible = false end
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do Bone.Visible = false end
        end
        PlayerESP.UpdateChams(Player, nil, false)
        return
    end
    
    local Position, OnScreen = Camera:WorldToViewportPoint(HumanoidRootPart.Position)
    local Distance = (HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not OnScreen or Distance > Library.Settings.MaxDistance then
        for _, Line in pairs(ESPData.Box) do Line.Visible = false end
        ESPData.Tracer.Visible = false
        ESPData.Dot.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do Object.Visible = false end
        for _, Object in pairs(ESPData.Info) do Object.Visible = false end
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do Bone.Visible = false end
        end
        PlayerESP.UpdateChams(Player, nil, false)
    end
    
    if not OnScreen then
        if Library.Settings.Arrow.Enabled and Arrow then
            local screenSize = Camera.ViewportSize
            local centerPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
            local partPos = Vector2.new(Position.X, Position.Y)
            local IsInverted = Position.Z <= 0
            local invert = IsInverted and -1 or 1
            local direction = (partPos - centerPos)
            local arctan = math.atan2(direction.Y, direction.X)
            local angle = math.deg(arctan) + 90
            local offset = (Library.Settings.Arrow.CenterOffset * 0.001) * screenSize.Y
            
            Arrow.Rotation = angle + 180 * (IsInverted and 0 or 1)
            Arrow.Position = UDim2.new(0, centerPos.X + (offset * math.cos(arctan) * invert), 0, centerPos.Y + (offset * math.sin(arctan) * invert))
            Arrow.ImageColor3 = GetColor(Library.Settings.Arrow.Color)
            Arrow.Visible = true
        end
        PlayerESP.UpdateChams(Player, Character, false)
        return
    else
        if Arrow then Arrow.Visible = false end
    end
    
    PlayerESP.UpdateChams(Player, Character, true)
    
    local Scale = 1 / (Position.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
    local Width = math.floor(4.5 * Scale)
    local Height = math.floor(6 * Scale)
    local X = math.floor(Position.X)
    local Y = math.floor(Position.Y)
    local TopLeft = Vector2.new(math.floor(X - Width / 2), math.floor((Y - Height / 2) + (Scale / 2)))
    local BoxSize = Vector2.new(Width, Height)
    
    local BoxColor = GetColor(Library.Settings.Box.Color)
    
    if Library.Settings.Box.Enabled then
        if Library.Settings.Box.Style == 1 then
            local CornerSize = math.min(Width, Height) * 0.2
            
            ESPData.Box.TopLeft.From = TopLeft
            ESPData.Box.TopLeft.To = TopLeft + Vector2.new(CornerSize, 0)
            ESPData.Box.TopLeft.Color = BoxColor
            ESPData.Box.TopLeft.Visible = true
            
            ESPData.Box.TopRight.From = TopLeft + Vector2.new(BoxSize.X, 0)
            ESPData.Box.TopRight.To = TopLeft + Vector2.new(BoxSize.X - CornerSize, 0)
            ESPData.Box.TopRight.Color = BoxColor
            ESPData.Box.TopRight.Visible = true
            
            ESPData.Box.BottomLeft.From = TopLeft + Vector2.new(0, BoxSize.Y)
            ESPData.Box.BottomLeft.To = TopLeft + Vector2.new(CornerSize, BoxSize.Y)
            ESPData.Box.BottomLeft.Color = BoxColor
            ESPData.Box.BottomLeft.Visible = true
            
            ESPData.Box.BottomRight.From = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
            ESPData.Box.BottomRight.To = TopLeft + Vector2.new(BoxSize.X - CornerSize, BoxSize.Y)
            ESPData.Box.BottomRight.Color = BoxColor
            ESPData.Box.BottomRight.Visible = true
            
            ESPData.Box.Left.From = TopLeft
            ESPData.Box.Left.To = TopLeft + Vector2.new(0, CornerSize)
            ESPData.Box.Left.Color = BoxColor
            ESPData.Box.Left.Visible = true
            
            ESPData.Box.Right.From = TopLeft + Vector2.new(BoxSize.X, 0)
            ESPData.Box.Right.To = TopLeft + Vector2.new(BoxSize.X, CornerSize)
            ESPData.Box.Right.Color = BoxColor
            ESPData.Box.Right.Visible = true
            
            ESPData.Box.Top.From = TopLeft + Vector2.new(0, BoxSize.Y)
            ESPData.Box.Top.To = TopLeft + Vector2.new(0, BoxSize.Y - CornerSize)
            ESPData.Box.Top.Color = BoxColor
            ESPData.Box.Top.Visible = true
            
            ESPData.Box.Bottom.From = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
            ESPData.Box.Bottom.To = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y - CornerSize)
            ESPData.Box.Bottom.Color = BoxColor
            ESPData.Box.Bottom.Visible = true
        else
            ESPData.Box.Left.From = TopLeft
            ESPData.Box.Left.To = TopLeft + Vector2.new(0, BoxSize.Y)
            ESPData.Box.Left.Color = BoxColor
            ESPData.Box.Left.Visible = true
            
            ESPData.Box.Right.From = TopLeft + Vector2.new(BoxSize.X, 0)
            ESPData.Box.Right.To = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
            ESPData.Box.Right.Color = BoxColor
            ESPData.Box.Right.Visible = true
            
            ESPData.Box.Top.From = TopLeft
            ESPData.Box.Top.To = TopLeft + Vector2.new(BoxSize.X, 0)
            ESPData.Box.Top.Color = BoxColor
            ESPData.Box.Top.Visible = true
            
            ESPData.Box.Bottom.From = TopLeft + Vector2.new(0, BoxSize.Y)
            ESPData.Box.Bottom.To = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
            ESPData.Box.Bottom.Color = BoxColor
            ESPData.Box.Bottom.Visible = true
            
            ESPData.Box.TopLeft.Visible = false
            ESPData.Box.TopRight.Visible = false
            ESPData.Box.BottomLeft.Visible = false
            ESPData.Box.BottomRight.Visible = false
        end
        
        if Library.Settings.Box.Filled.Enabled then
            local Fill = ESPData.Fills[1]
            if not Fill then
                Fill = Drawing.new("Square")
                ESPData.Fills[1] = Fill
            end
            Fill.Visible = true
            Fill.Color = BoxColor
            Fill.Transparency = Library.Settings.Box.Filled.Transparency
            Fill.Filled = true
            Fill.Position = TopLeft
            Fill.Size = BoxSize
        else
            for _, Fill in pairs(ESPData.Fills) do
                Fill.Visible = false
            end
        end
    else
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        for _, Fill in pairs(ESPData.Fills) do
            Fill.Visible = false
        end
    end
    
    if Library.Settings.Tracer.Enabled then
        ESPData.Tracer.From = GetTracerOrigin(Library.Settings.Tracer.Origin)
        ESPData.Tracer.To = Vector2.new(Position.X, Position.Y)
        ESPData.Tracer.Color = GetColor(Library.Settings.Tracer.Color)
        ESPData.Tracer.Visible = true
    else
        ESPData.Tracer.Visible = false
    end
    
    if Library.Settings.Dot.Enabled then
        ESPData.Dot.Position = Vector2.new(Position.X, Position.Y)
        ESPData.Dot.Color = GetColor(Library.Settings.Dot.Color)
        ESPData.Dot.Visible = true
    else
        ESPData.Dot.Visible = false
    end
    
    if Library.Settings.HealthBar.Enabled then
        local Health = Humanoid.Health
        local MaxHealth = Humanoid.MaxHealth
        local HealthPercent = Health / MaxHealth
        local BarHeight = Height
        local BarWidth = 4
        local BarX = Library.Settings.HealthBar.Position == 1 and (TopLeft.X - BarWidth - 4) or (TopLeft.X + BoxSize.X + 4)
        local BarPosition = Vector2.new(BarX, TopLeft.Y)
        
        ESPData.HealthBar.Outline.Size = Vector2.new(BarWidth, BarHeight)
        ESPData.HealthBar.Outline.Position = BarPosition
        ESPData.HealthBar.Outline.Visible = true
        
        ESPData.HealthBar.Fill.Size = Vector2.new(BarWidth - 2, (BarHeight - 2) * HealthPercent)
        ESPData.HealthBar.Fill.Position = Vector2.new(BarPosition.X + 1, BarPosition.Y + 1 + ((BarHeight - 2) * (1 - HealthPercent)))
        local HealthColor = Color3.new(1 - HealthPercent, HealthPercent, 0)
        ESPData.HealthBar.Fill.Color = HealthColor
        ESPData.HealthBar.Fill.Visible = true
    else
        ESPData.HealthBar.Outline.Visible = false
        ESPData.HealthBar.Fill.Visible = false
    end
    
    if Library.Settings.Name.Enabled then
        ESPData.Info.Name.Text = Player.Name
        ESPData.Info.Name.Position = Vector2.new(TopLeft.X + Width / 2, TopLeft.Y - 20)
        ESPData.Info.Name.Color = GetColor(Library.Settings.Name.Color)
        ESPData.Info.Name.Visible = true
    else
        ESPData.Info.Name.Visible = false
    end
    
    if Library.Settings.Distance.Enabled then
        ESPData.Info.Distance.Text = math.floor(Distance) .. " studs"
        ESPData.Info.Distance.Position = Vector2.new(TopLeft.X + Width / 2, TopLeft.Y + BoxSize.Y + 5)
        ESPData.Info.Distance.Color = GetColor(Library.Settings.Distance.Color)
        ESPData.Info.Distance.Visible = true
    else
        ESPData.Info.Distance.Visible = false
    end
    
    if Library.Settings.Skeleton.Enabled and SkeletonData then
        local function GetPart(name)
            return Character:FindFirstChild(name) or Character:FindFirstChild(name:gsub("Upper", ""):gsub("Lower", ""))
        end
        
        local function DrawBone(Part1, Part2, Line)
            if not Part1 or not Part2 then
                Line.Visible = false
                return
            end
            local Pos1 = Part1.Position
            local Pos2 = Part2.Position
            local Screen1, Vis1 = Camera:WorldToViewportPoint(Pos1)
            local Screen2, Vis2 = Camera:WorldToViewportPoint(Pos2)
            if Vis1 and Vis2 and Screen1.Z > 0 and Screen2.Z > 0 then
                Line.From = Vector2.new(Screen1.X, Screen1.Y)
                Line.To = Vector2.new(Screen2.X, Screen2.Y)
                Line.Color = GetColor(Library.Settings.Skeleton.Color)
                Line.Visible = true
            else
                Line.Visible = false
            end
        end
        
        local Head = GetPart("Head")
        local UpperTorso = GetPart("UpperTorso") or GetPart("Torso")
        local LowerTorso = GetPart("LowerTorso") or GetPart("Torso")
        local LeftUpperArm = GetPart("LeftUpperArm") or GetPart("Left Arm")
        local LeftLowerArm = GetPart("LeftLowerArm") or GetPart("Left Arm")
        local LeftHand = GetPart("LeftHand") or GetPart("Left Arm")
        local RightUpperArm = GetPart("RightUpperArm") or GetPart("Right Arm")
        local RightLowerArm = GetPart("RightLowerArm") or GetPart("Right Arm")
        local RightHand = GetPart("RightHand") or GetPart("Right Arm")
        local LeftUpperLeg = GetPart("LeftUpperLeg") or GetPart("Left Leg")
        local LeftLowerLeg = GetPart("LeftLowerLeg") or GetPart("Left Leg")
        local LeftFoot = GetPart("LeftFoot") or GetPart("Left Leg")
        local RightUpperLeg = GetPart("RightUpperLeg") or GetPart("Right Leg")
        local RightLowerLeg = GetPart("RightLowerLeg") or GetPart("Right Leg")
        local RightFoot = GetPart("RightFoot") or GetPart("Right Leg")
        
        DrawBone(Head, UpperTorso, SkeletonData.Head)
        DrawBone(UpperTorso, LowerTorso, SkeletonData.UpperSpine)
        DrawBone(UpperTorso, LeftUpperArm, SkeletonData.LeftShoulder)
        DrawBone(LeftUpperArm, LeftLowerArm, SkeletonData.LeftUpperArm)
        DrawBone(LeftLowerArm, LeftHand, SkeletonData.LeftLowerArm)
        DrawBone(UpperTorso, RightUpperArm, SkeletonData.RightShoulder)
        DrawBone(RightUpperArm, RightLowerArm, SkeletonData.RightUpperArm)
        DrawBone(RightLowerArm, RightHand, SkeletonData.RightLowerArm)
        DrawBone(LowerTorso, LeftUpperLeg, SkeletonData.LeftHip)
        DrawBone(LeftUpperLeg, LeftLowerLeg, SkeletonData.LeftUpperLeg)
        DrawBone(LeftLowerLeg, LeftFoot, SkeletonData.LeftLowerLeg)
        DrawBone(LowerTorso, RightUpperLeg, SkeletonData.RightHip)
        DrawBone(RightUpperLeg, RightLowerLeg, SkeletonData.RightUpperLeg)
        DrawBone(RightLowerLeg, RightFoot, SkeletonData.RightLowerLeg)
    elseif SkeletonData then
        for _, Bone in pairs(SkeletonData) do
            Bone.Visible = false
        end
    end
end

local RadarSystem = {}
RadarSystem.__index = RadarSystem

function RadarSystem.new()
    local self = setmetatable({}, RadarSystem)
    self.Frame = Instance.new("Frame")
    self.Frame.Name = RandomString()
    self.Frame.Parent = ScreenGui
    self.Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    self.Frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
    self.Frame.BorderSizePixel = 2
    self.Frame.BackgroundTransparency = 0.5
    self.Frame.Size = UDim2.new(0, 200, 0, 200)
    self.Frame.Position = UDim2.new(0, 150, 0, 150)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(1, 0)
    Corner.Parent = self.Frame
    
    local CenterDot = Drawing.new("Circle")
    CenterDot.Radius = 3
    CenterDot.Filled = true
    CenterDot.Color = Color3.new(1, 1, 1)
    CenterDot.Position = Vector2.new(0, 0)
    CenterDot.Visible = false
    self.CenterDot = CenterDot
    
    self.PlayerDots = {}
    return self
end

function RadarSystem:Update()
    if not Library.Settings.Radar.Enabled then
        self.Frame.Visible = false
        self.CenterDot.Visible = false
        for _, Dot in pairs(self.PlayerDots) do
            Dot.Visible = false
        end
        return
    end
    
    self.Frame.Visible = true
    local RadarPos = Library.Settings.Radar.Position
    local RadarRadius = Library.Settings.Radar.Radius
    self.Frame.Position = UDim2.new(0, RadarPos.X - RadarRadius, 0, RadarPos.Y - RadarRadius)
    self.Frame.Size = UDim2.new(0, RadarRadius * 2, 0, RadarRadius * 2)
    
    local CenterPos = Vector2.new(RadarPos.X, RadarPos.Y)
    self.CenterDot.Position = CenterPos
    self.CenterDot.Visible = true
    
    local LocalChar = LocalPlayer.Character
    if not LocalChar or not LocalChar:FindFirstChild("HumanoidRootPart") then return end
    local LocalRoot = LocalChar.HumanoidRootPart
    local LocalPos = LocalRoot.Position
    local LocalCF = LocalRoot.CFrame
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        
        local Dot = self.PlayerDots[Player]
        if not Dot then
            Dot = Drawing.new("Circle")
            Dot.Radius = 4
            Dot.Filled = true
            Dot.Color = Library.Settings.Radar.Color
            self.PlayerDots[Player] = Dot
        end
        
        local Char = Player.Character
        if Char and Char:FindFirstChild("HumanoidRootPart") then
            local Pos = Char.HumanoidRootPart.Position
            local RelativePos = Pos - LocalPos
            local ObjectSpace = LocalCF:PointToObjectSpace(Pos)
            local Scale = Library.Settings.Radar.Scale
            local X = -ObjectSpace.X * Scale
            local Y = -ObjectSpace.Z * Scale
            local DotPos = CenterPos + Vector2.new(X, Y)
            
            if (DotPos - CenterPos).Magnitude <= RadarRadius - 4 then
                Dot.Position = DotPos
                Dot.Visible = true
            else
                local Direction = (DotPos - CenterPos).Unit
                local EdgePos = CenterPos + Direction * (RadarRadius - 6)
                Dot.Position = EdgePos
                Dot.Visible = true
            end
        else
            Dot.Visible = false
        end
    end
end

local Radar = RadarSystem.new()

local function UpdateRainbow()
    if Library.Settings.Rainbow then
        RainbowHue = RainbowHue + 0.002
        if RainbowHue > 1 then RainbowHue = 0 end
        RainbowColor = Color3.fromHSV(RainbowHue, 0.8, 1)
    end
end

local function UpdateAll()
    UpdateRainbow()
    Radar:Update()
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            PlayerESP.UpdateESP(Player)
        end
    end
end

function Library:Toggle(state)
    Library.Settings.Enabled = state
    if not state then
        for Player, _ in pairs(Library.Drawings.ESP) do
            PlayerESP.RemoveESP(Player)
        end
    end
end

function Library:SetBox(state)
    Library.Settings.Box.Enabled = state
end

function Library:SetTracer(state)
    Library.Settings.Tracer.Enabled = state
end

function Library:SetArrow(state)
    Library.Settings.Arrow.Enabled = state
end

function Library:SetChams(state)
    Library.Settings.Chams.Enabled = state
end

function Library:SetSkeleton(state)
    Library.Settings.Skeleton.Enabled = state
end

function Library:SetDot(state)
    Library.Settings.Dot.Enabled = state
end

function Library:SetRadar(state)
    Library.Settings.Radar.Enabled = state
end

function Library:SetRainbow(state)
    Library.Settings.Rainbow = state
end

function Library:Unload()
    for _, Connection in pairs(Library._connections) do
        if Connection then Connection:Disconnect() end
    end
    for Player, _ in pairs(Library.Drawings.ESP) do
        PlayerESP.RemoveESP(Player)
    end
    for _, Dot in pairs(Radar.PlayerDots) do
        pcall(function() Dot:Remove() end)
    end
    pcall(function() Radar.CenterDot:Remove() end)
    pcall(function() ScreenGui:Destroy() end)
    Library.Drawings = {ESP = {}, Skeleton = {}, RadarObjects = {}}
    Library.Highlights = {}
    Library.Arrows = {}
    Library.ChamsObjects = {}
end

table.insert(Library._connections, RunService.RenderStepped:Connect(UpdateAll))

table.insert(Library._connections, Players.PlayerAdded:Connect(function(Player)
    PlayerESP.CreateESP(Player)
end))

table.insert(Library._connections, Players.PlayerRemoving:Connect(function(Player)
    PlayerESP.RemoveESP(Player)
    if Radar.PlayerDots[Player] then
        Radar.PlayerDots[Player]:Remove()
        Radar.PlayerDots[Player] = nil
    end
end))

table.insert(Library._connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end))

for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        PlayerESP.CreateESP(Player)
    end
end

getgenv().StarLightESP = Library
return Library