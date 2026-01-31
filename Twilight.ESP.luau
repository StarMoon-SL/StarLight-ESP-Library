local TwilightESP = {}
local Cache = {}

local function GetServices()
    local Services = {}
    setmetatable(Services, {
        __index = function(self, ServiceName)
            local Service = game:GetService(ServiceName)
            if cloneref then
                Service = cloneref(Service)
            end
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
local GuiService = Services.GuiService

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local DrawingUtility = {
    new = function(Class, Properties)
        local Object = Drawing.new(Class)
        for Property, Value in pairs(Properties or {}) do
            Object[Property] = Value
        end
        return Object
    end
}

local function GetTracerOrigin(Library)
    local Origin = Library.Settings.Tracer.Origin
    if Origin == 2 then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    elseif Origin == 3 then
        return Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif Origin == 4 then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    elseif Origin == 5 then
        return UserInputService:GetMouseLocation()
    elseif Origin == 1 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local Position = Camera:WorldToViewportPoint(LocalPlayer.Character.HumanoidRootPart.Position)
        return Vector2.new(Position.X, Position.Y)
    else
        return Vector2.new(0, 0)
    end
end

local function GetPlayerType(Player)
    local PlayerType
    if Player.Neutral then
        PlayerType = "generic"
    else
        if Player.TeamColor == LocalPlayer.TeamColor then
            PlayerType = "friendly"
        else
            PlayerType = "enemy"
        end
    end
    if Player == LocalPlayer then
        PlayerType = "local"
    end
    return PlayerType
end

local function GetPlayerColor(Library, Player, IsVisible, Component, SubComponent)
    local PlayerType = GetPlayerType(Player)
    
    if Component == "HealthBar" and SubComponent == "Fill" then
        if not Player.Character then return end
        local Health = Library.Settings.HealthBar.Source(Player, "Health")
        local MaxHealth = Library.Settings.HealthBar.Source(Player, "MaxHealth")
        local HealthPercent = Health / MaxHealth
        local HealthLevel
        if HealthPercent > 0.65 then
            HealthLevel = "High"
        elseif HealthPercent > 0.2 then
            HealthLevel = "Medium"
        else
            HealthLevel = "Low"
        end
        return Library.Settings.currentColors[PlayerType].HealthBar.Fills[HealthLevel]
    elseif Component == "Text" then
        return Library.Settings.currentColors[PlayerType][Component]
    elseif Component == "HealthBar" and SubComponent == "Outline" then
        if not Player.Character then return end
        return Library.Settings.currentColors[PlayerType].HealthBar.Outline or Color3.new(0, 0, 0)
    end
    
    if Library.Settings.Checks.Visible.Enabled and not IsVisible then
        if SubComponent then
            return Library.Settings.currentColors[PlayerType][Component][SubComponent].Invisible
        else
            return Library.Settings.currentColors[PlayerType][Component].Invisible
        end
    else
        if SubComponent then
            return Library.Settings.currentColors[PlayerType][Component][SubComponent].Visible
        else
            return Library.Settings.currentColors[PlayerType][Component].Visible
        end
    end
end

local PlayerESP = {}
PlayerESP.__index = PlayerESP

function PlayerESP.CreateESP(Library, Player)
    local PlayerType = GetPlayerType(Player)
    
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
        Line.Color = Library.Settings.currentColors[PlayerType].Box.Outline.Visible
        Line.Thickness = Library.Settings.Box.Thickness
    end
    
    local Tracer = Drawing.new("Line")
    Tracer.Visible = false
    Tracer.Thickness = Library.Settings.Tracer.Thickness
    Tracer.From = GetTracerOrigin(Library)
    
    local HealthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    
    task.defer(function()
        for Key, Object in pairs(HealthBar) do
            Object.Visible = false
            repeat task.wait() until Player.Character
            local Health = Library.Settings.HealthBar.Source(Player, "Health")
            local MaxHealth = Library.Settings.HealthBar.Source(Player, "MaxHealth")
            local HealthLevel
            if Health / MaxHealth > 0.6 then
                HealthLevel = "High"
            elseif Health / MaxHealth > 0.2 then
                HealthLevel = "Medium"
            else
                HealthLevel = "Low"
            end
            if not Library.Settings.currentColors[PlayerType].HealthBar then continue end
            if Object == HealthBar.Fill then
                Object.Color = Library.Settings.currentColors[PlayerType].HealthBar.Fills[HealthLevel]
                Object.Filled = true
            elseif Object == HealthBar.Text then
                Object.Center = true
                Object.Size = Library.Settings.TextSize
                Object.Color = Library.Settings.currentColors[PlayerType].HealthBar.Fills[HealthLevel]
                Object.Font = 2
            else
                Object.Filled = false
            end
        end
    end)
    
    local Info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    for _, Text in pairs(Info) do
        Text.Visible = false
        Text.Center = true
        Text.Size = Library.Settings.TextSize
        Text.Color = Library.Settings.currentColors[PlayerType].Text
        Text.Font = 2
        Text.Outline = true
    end
    
    local Snapline = Drawing.new("Line")
    Snapline.Visible = false
    Snapline.Color = Library.Settings.currentColors[PlayerType].Box.Outline.Visible
    Snapline.Thickness = 1
    
    local Highlight = Instance.new("Highlight")
    Highlight.FillColor = Library.Settings.currentColors[PlayerType].Chams.Fill.Visible
    Highlight.OutlineColor = Library.Settings.currentColors[PlayerType].Chams.Outline.Visible
    Highlight.FillTransparency = Library.Settings.Chams.Fill.Transparency
    Highlight.OutlineTransparency = Library.Settings.Chams.Outline.Transparency
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Enabled = false
    Library.Highlights[Player] = Highlight
    
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
        Bone.Color = Library.Settings.currentColors[PlayerType].Skeleton.Visible
        Bone.Thickness = Library.Settings.Skeleton.Thickness
        Bone.Transparency = Library.Settings.Skeleton.Transparency
    end
    
    Library.Drawings.Skeleton[Player] = Skeleton
    Library.Drawings.ESP[Player] = {
        Box = Box,
        Tracer = Tracer,
        HealthBar = HealthBar,
        Info = Info,
        Snapline = Snapline,
        Fills = {}
    }
end

function PlayerESP.RemoveESP(Library, Player)
    local ESPData = Library.Drawings.ESP[Player]
    if ESPData then
        for _, Line in pairs(ESPData.Box) do
            pcall(Line.Remove, Line)
            pcall(Line.Destroy, Line)
        end
        pcall(ESPData.Tracer.Remove, ESPData.Tracer)
        pcall(ESPData.Tracer.Destroy, ESPData.Tracer)
        for _, Object in pairs(ESPData.HealthBar) do
            pcall(Object.Remove, Object)
            pcall(Object.Destroy, Object)
        end
        for _, Object in pairs(ESPData.Info) do
            pcall(Object.Remove, Object)
            pcall(Object.Destroy, Object)
        end
        for _, Object in pairs(ESPData.Fills) do
            pcall(Object.Remove, Object)
            pcall(Object.Destroy, Object)
        end
        pcall(ESPData.Snapline.Remove, ESPData.Snapline)
        pcall(ESPData.Snapline.Destroy, ESPData.Snapline)
        Library.Drawings.ESP[Player] = nil
    end
    
    local Highlight = Library.Highlights[Player]
    if Highlight then
        pcall(Highlight.Destroy, Highlight)
        Library.Highlights[Player] = nil
    end
    
    local SkeletonData = Library.Drawings.Skeleton[Player]
    if SkeletonData then
        for _, Bone in pairs(SkeletonData) do
            pcall(Bone.Remove, Bone)
            pcall(Bone.Destroy, Bone)
        end
        Library.Drawings.Skeleton[Player] = nil
    end
end

function PlayerESP.UpdateESP(Library, Player)
    if not Library.Settings.Enabled then return end
    
    local ESPData = Library.Drawings.ESP[Player]
    if not ESPData then return end
    
    local Character = Player.Character
    if not Character then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        
        local SkeletonData = Library.Drawings.Skeleton[Player]
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do
                Bone.Visible = false
            end
        end
        return
    end
    
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChild("Humanoid")
    
    if not HumanoidRootPart or not Humanoid then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        
        local SkeletonData = Library.Drawings.Skeleton[Player]
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do
                Bone.Visible = false
            end
        end
        return
    end
    
    local Position, OnScreen = Camera:WorldToViewportPoint(HumanoidRootPart.Position)
    if not OnScreen then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        
        local SkeletonData = Library.Drawings.Skeleton[Player]
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do
                Bone.Visible = false
            end
        end
        return
    end
    
    if not Humanoid or Humanoid.Health <= 0 then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        
        local SkeletonData = Library.Drawings.Skeleton[Player]
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do
                Bone.Visible = false
            end
        end
        return
    end
    
    local Distance = (HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
    local IsVisible = true
    
    if OnScreen then
        local ObscuringParts = Camera:GetPartsObscuringTarget({Camera.CFrame.Position, HumanoidRootPart.Position}, {HumanoidRootPart})
        if #ObscuringParts > 0 then
            IsVisible = false
            if Library.Settings.Checks.Visible.Enabled and Library.Settings.Checks.Visible.OnlyVisible then
                for _, Line in pairs(ESPData.Box) do
                    Line.Visible = false
                end
                ESPData.Tracer.Visible = false
                for _, Object in pairs(ESPData.HealthBar) do
                    Object.Visible = false
                end
                for _, Object in pairs(ESPData.Info) do
                    Object.Visible = false
                end
                for _, Object in pairs(ESPData.Fills) do
                    Object.Visible = false
                end
                ESPData.Snapline.Visible = false
                
                local SkeletonData = Library.Drawings.Skeleton[Player]
                if SkeletonData then
                    for _, Bone in pairs(SkeletonData) do
                        Bone.Visible = false
                    end
                end
                return
            end
        end
    end
    
    if not OnScreen or Distance > Library.Settings.MaxDistance then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        
        local SkeletonData = Library.Drawings.Skeleton[Player]
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do
                Bone.Visible = false
            end
        end
        return
    end
    
    local PlayerType = GetPlayerType(Player)
    
    if Library.Settings.Checks.Team.Enabled then
        if not Library.Settings.Checks.Team.SelectedTeams[PlayerType] then
            for _, Line in pairs(ESPData.Box) do
                Line.Visible = false
            end
            ESPData.Tracer.Visible = false
            for _, Object in pairs(ESPData.HealthBar) do
                Object.Visible = false
            end
            for _, Object in pairs(ESPData.Info) do
                Object.Visible = false
            end
            for _, Object in pairs(ESPData.Fills) do
                Object.Visible = false
            end
            ESPData.Snapline.Visible = false
            
            local SkeletonData = Library.Drawings.Skeleton[Player]
            if SkeletonData then
                for _, Bone in pairs(SkeletonData) do
                    Bone.Visible = false
                end
            end
            return
        end
    end
    
    local BoxOutlineColor = GetPlayerColor(Library, Player, IsVisible, "Box", "Outline")
    local BoxFillColor = GetPlayerColor(Library, Player, IsVisible, "Box", "Fill")
    local TracerColor = GetPlayerColor(Library, Player, IsVisible, "Tracer")
    local TextColor = GetPlayerColor(Library, Player, IsVisible, "Text")
    local SkeletonColor = GetPlayerColor(Library, Player, IsVisible, "Skeleton")
    local ChamsOutlineColor = GetPlayerColor(Library, Player, IsVisible, "Chams", "Outline")
    local ChamsFillColor = GetPlayerColor(Library, Player, IsVisible, "Chams", "Fill")
    local HealthBarFillColor = GetPlayerColor(Library, Player, IsVisible, "HealthBar", "Fill")
    local HealthBarOutlineColor = GetPlayerColor(Library, Player, IsVisible, "HealthBar", "Outline")
    
    local Size = Character:GetExtentsSize()
    local RootCFrame = HumanoidRootPart.CFrame
    
    local TopPosition, TopVisible = Camera:WorldToViewportPoint(RootCFrame * CFrame.new(0, Size.Y / 2, 0).Position)
    local BottomPosition, BottomVisible = Camera:WorldToViewportPoint(RootCFrame * CFrame.new(0, -Size.Y / 2, 0).Position)
    local RootPosition = Camera:WorldToViewportPoint(RootCFrame.Position)
    
    if not TopVisible or not BottomVisible then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        return
    end
    
    local Scale = 1 / (RootPosition.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
    local Width = math.floor(4.5 * Scale)
    local Height = math.floor(6 * Scale)
    local X = math.floor(RootPosition.X)
    local Y = math.floor(RootPosition.Y)
    
    local TopLeft = Vector2.new(math.floor(X - Width / 2), math.floor((Y - Height / 2) + (Scale / 2)))
    local BoxSize = Vector2.new(Width, Height)
    
    for _, Line in pairs(ESPData.Box) do
        Line.Visible = false
    end
    
    if Library.Settings.Box.Enabled then
        if Library.Settings.Box.Style == 3 then
            local Corners = {
                TL = Camera:WorldToViewportPoint((RootCFrame * CFrame.new(-Size.X / 2, Size.Y / 2, -Size.Z / 2)).Position),
                TR = Camera:WorldToViewportPoint((RootCFrame * CFrame.new(Size.X / 2, Size.Y / 2, -Size.Z / 2)).Position),
                BL = Camera:WorldToViewportPoint((RootCFrame * CFrame.new(-Size.X / 2, -Size.Y / 2, -Size.Z / 2)).Position),
                BR = Camera:WorldToViewportPoint((RootCFrame * CFrame.new(Size.X / 2, -Size.Y / 2, -Size.Z / 2)).Position)
            }
            
            local BackCorners = {
                TL = Camera:WorldToViewportPoint((RootCFrame * CFrame.new(-Size.X / 2, Size.Y / 2, Size.Z / 2)).Position),
                TR = Camera:WorldToViewportPoint((RootCFrame * CFrame.new(Size.X / 2, Size.Y / 2, Size.Z / 2)).Position),
                BL = Camera:WorldToViewportPoint((RootCFrame * CFrame.new(-Size.X / 2, -Size.Y / 2, Size.Z / 2)).Position),
                BR = Camera:WorldToViewportPoint((RootCFrame * CFrame.new(Size.X / 2, -Size.Y / 2, Size.Z / 2)).Position)
            }
            
            if not (Corners.TL.Z > 0 and Corners.TR.Z > 0 and Corners.BL.Z > 0 and Corners.BR.Z > 0 and 
                    BackCorners.TL.Z > 0 and BackCorners.TR.Z > 0 and BackCorners.BL.Z > 0 and BackCorners.BR.Z > 0) then
                for _, Line in pairs(ESPData.Box) do
                    Line.Visible = false
                end
                return
            end
            
            local function ToVector2(Vector)
                return Vector2.new(Vector.X, Vector.Y)
            end
            
            Corners.TL = ToVector2(Corners.TL)
            Corners.TR = ToVector2(Corners.TR)
            Corners.BL = ToVector2(Corners.BL)
            Corners.BR = ToVector2(Corners.BR)
            BackCorners.TL = ToVector2(BackCorners.TL)
            BackCorners.TR = ToVector2(BackCorners.TR)
            BackCorners.BL = ToVector2(BackCorners.BL)
            BackCorners.BR = ToVector2(BackCorners.BR)
            
            ESPData.Box.TopLeft.From = Corners.TL
            ESPData.Box.TopLeft.To = Corners.TR
            ESPData.Box.TopLeft.Visible = true
            
            ESPData.Box.TopRight.From = Corners.TR
            ESPData.Box.TopRight.To = Corners.BR
            ESPData.Box.TopRight.Visible = true
            
            ESPData.Box.BottomLeft.From = Corners.BL
            ESPData.Box.BottomLeft.To = Corners.BR
            ESPData.Box.BottomLeft.Visible = true
            
            ESPData.Box.BottomRight.From = Corners.TL
            ESPData.Box.BottomRight.To = Corners.BL
            ESPData.Box.BottomRight.Visible = true
            
            ESPData.Box.Left.From = BackCorners.TL
            ESPData.Box.Left.To = BackCorners.TR
            ESPData.Box.Left.Visible = true
            
            ESPData.Box.Right.From = BackCorners.TR
            ESPData.Box.Right.To = BackCorners.BR
            ESPData.Box.Right.Visible = true
            
            ESPData.Box.Top.From = BackCorners.BL
            ESPData.Box.Top.To = BackCorners.BR
            ESPData.Box.Top.Visible = true
            
            ESPData.Box.Bottom.From = BackCorners.TL
            ESPData.Box.Bottom.To = BackCorners.BL
            ESPData.Box.Bottom.Visible = true
            
            local function CreateTempLine(From, To, Visible)
                return Drawing.new("Line", {
                    Visible = Visible,
                    Color = BoxOutlineColor,
                    Thickness = Library.Settings.Box.Thickness,
                    From = From,
                    To = To
                })
            end
            
            local TempLines = {
                CreateTempLine(Corners.TL, BackCorners.TL, true),
                CreateTempLine(Corners.TR, BackCorners.TR, true),
                CreateTempLine(Corners.BL, BackCorners.BL, true),
                CreateTempLine(Corners.BR, BackCorners.BR, true)
            }
            
            task.defer(function()
                task.wait(Library.Settings.Framerate or 0.016666666666666666)
                for _, Line in ipairs(TempLines) do
                    pcall(Line.Remove, Line)
                    pcall(Line.Destroy, Line)
                end
            end)
        else
            local function UpdateFill()
                local Fill = ESPData.Fills[1]
                if not Fill then
                    Fill = Drawing.new("Square")
                    ESPData.Fills[1] = Fill
                end
                Fill.Visible = IsVisible and Library.Settings.Box.Filled.Enabled or false
                Fill.Color = BoxFillColor
                Fill.Transparency = Library.Settings.Box.Filled.Transparency
                Fill.Filled = true
                Fill.Position = TopLeft
                Fill.Size = BoxSize
                return Fill
            end
            
            UpdateFill()
            
            if Library.Settings.Box.Style == 1 then
                local CornerSize = Width * 0.2
                
                ESPData.Box.TopLeft.From = TopLeft
                ESPData.Box.TopLeft.To = TopLeft + Vector2.new(CornerSize, 0)
                ESPData.Box.TopLeft.Visible = true
                
                ESPData.Box.TopRight.From = TopLeft + Vector2.new(BoxSize.X, 0)
                ESPData.Box.TopRight.To = TopLeft + Vector2.new(BoxSize.X - CornerSize, 0)
                ESPData.Box.TopRight.Visible = true
                
                ESPData.Box.BottomLeft.From = TopLeft + Vector2.new(0, BoxSize.Y)
                ESPData.Box.BottomLeft.To = TopLeft + Vector2.new(CornerSize, BoxSize.Y)
                ESPData.Box.BottomLeft.Visible = true
                
                ESPData.Box.BottomRight.From = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
                ESPData.Box.BottomRight.To = TopLeft + Vector2.new(BoxSize.X - CornerSize, BoxSize.Y)
                ESPData.Box.BottomRight.Visible = true
                
                ESPData.Box.Left.From = TopLeft
                ESPData.Box.Left.To = TopLeft + Vector2.new(0, CornerSize)
                ESPData.Box.Left.Visible = true
                
                ESPData.Box.Right.From = TopLeft + Vector2.new(BoxSize.X, 0)
                ESPData.Box.Right.To = TopLeft + Vector2.new(BoxSize.X, CornerSize)
                ESPData.Box.Right.Visible = true
                
                ESPData.Box.Top.From = TopLeft + Vector2.new(0, BoxSize.Y)
                ESPData.Box.Top.To = TopLeft + Vector2.new(0, BoxSize.Y - CornerSize)
                ESPData.Box.Top.Visible = true
                
                ESPData.Box.Bottom.From = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
                ESPData.Box.Bottom.To = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y - CornerSize)
                ESPData.Box.Bottom.Visible = true
            else
                ESPData.Box.Left.From = TopLeft
                ESPData.Box.Left.To = TopLeft + Vector2.new(0, BoxSize.Y)
                ESPData.Box.Left.Visible = true
                
                ESPData.Box.Right.From = TopLeft + Vector2.new(BoxSize.X, 0)
                ESPData.Box.Right.To = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
                ESPData.Box.Right.Visible = true
                
                ESPData.Box.Top.From = TopLeft
                ESPData.Box.Top.To = TopLeft + Vector2.new(BoxSize.X, 0)
                ESPData.Box.Top.Visible = true
                
                ESPData.Box.Bottom.From = TopLeft + Vector2.new(0, BoxSize.Y)
                ESPData.Box.Bottom.To = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
                ESPData.Box.Bottom.Visible = true
                
                ESPData.Box.TopLeft.Visible = false
                ESPData.Box.TopRight.Visible = false
                ESPData.Box.BottomLeft.Visible = false
                ESPData.Box.BottomRight.Visible = false
            end
        end
        
        for _, Line in pairs(ESPData.Box) do
            if Line.Visible then
                Line.Color = BoxOutlineColor
                Line.Thickness = Library.Settings.Box.Thickness
            end
        end
    end
    
    if Library.Settings.Tracer.Enabled[PlayerType] then
        ESPData.Tracer.From = GetTracerOrigin(Library)
        ESPData.Tracer.To = Vector2.new(Position.X, Position.Y)
        ESPData.Tracer.Color = TracerColor
        ESPData.Tracer.Visible = true
    else
        ESPData.Tracer.Visible = false
    end
    
    if Library.Settings.HealthBar.Enabled[PlayerType] then
        local Health = Library.Settings.HealthBar.Source(Player, "Health")
        local MaxHealth = Library.Settings.HealthBar.Source(Player, "MaxHealth")
        local HealthPercent = Health / MaxHealth
        local BarHeight = Height
        local BarWidth = 4
        local BarX = Library.Settings.HealthBar.Position == 1 and (TopLeft.X - BarWidth - 4) or (TopLeft.X + BarWidth + 4 + BoxSize.X)
        local BarPosition = Vector2.new(BarX, TopLeft.Y)
        
        if Library.Settings.HealthBar.Bar then
            ESPData.HealthBar.Outline.Size = Vector2.new(BarWidth, BarHeight)
            ESPData.HealthBar.Outline.Position = BarPosition
            ESPData.HealthBar.Outline.Visible = true
            ESPData.HealthBar.Outline.Color = HealthBarOutlineColor
            
            ESPData.HealthBar.Fill.Size = Vector2.new(BarWidth - 2, (BarHeight - 2) * HealthPercent)
            ESPData.HealthBar.Fill.Position = Vector2.new(BarPosition.X + 1, BarPosition.Y + 1 + ((BarHeight - 2) * (1 - HealthPercent)))
            ESPData.HealthBar.Fill.Color = HealthBarFillColor
            ESPData.HealthBar.Fill.Visible = true
        else
            ESPData.HealthBar.Outline.Visible = false
            ESPData.HealthBar.Fill.Visible = false
        end
        
        if Library.Settings.HealthBar.Text then
            ESPData.HealthBar.Text.Text = math.floor(Health) .. Library.Settings.HealthBar.Suffix
            ESPData.HealthBar.Text.Position = Vector2.new(BarPosition.X + BarWidth + 2, BarPosition.Y + BarHeight)
            ESPData.HealthBar.Text.Visible = true
        else
            ESPData.HealthBar.Text.Visible = false
        end
    else
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
    end
    
    if Library.Settings.Name.Enabled[PlayerType] then
        ESPData.Info.Name.Text = Library.Settings.Name.Style == 2 and Player.Name or Player.DisplayName
        ESPData.Info.Name.Position = Vector2.new(TopLeft.X + Width / 2, TopLeft.Y - 20)
        ESPData.Info.Name.Color = TextColor
        ESPData.Info.Name.Visible = true
    else
        ESPData.Info.Name.Visible = false
    end
    
    if Library.Settings.Distance.Enabled[PlayerType] then
        local DisplayDistance = tonumber(Distance)
        if Library.Settings.Distance.DistanceUnit == 2 then
            DisplayDistance = Distance * 0.28
        end
        ESPData.Info.Name.Text = tostring(math.round(DisplayDistance * 10) / 10) .. " " .. (Library.Settings.Distance.DistanceUnit == 2 and "meters" or "studs")
        ESPData.Info.Name.Position = Vector2.new(TopLeft.X + Width / 2, TopLeft.Y + BoxSize.Y)
        ESPData.Info.Name.Color = TextColor
        ESPData.Info.Name.Visible = true
    else
        ESPData.Info.Name.Visible = false
    end
    
    if Library.Settings.Snaplines then
        ESPData.Snapline.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        ESPData.Snapline.To = Vector2.new(Position.X, Position.Y)
        ESPData.Snapline.Color = BoxOutlineColor
        ESPData.Snapline.Visible = false
    end
    
    local Highlight = Library.Highlights[Player]
    if Highlight then
        if Library.Settings.Chams.Enabled[PlayerType] and Character then
            Highlight.Parent = Character
            Highlight.FillColor = ChamsFillColor
            Highlight.OutlineColor = ChamsOutlineColor
            Highlight.FillTransparency = Library.Settings.Chams.Fill.Enabled and Library.Settings.Chams.Fill.Transparency or 1
            Highlight.OutlineTransparency = Library.Settings.Chams.Outline.Enabled and Library.Settings.Chams.Outline.Transparency or 1
            Highlight.Enabled = true
        else
            Highlight.Enabled = false
        end
        Highlight.DepthMode = Library.Settings.Chams.Occlusion and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
    end
    
    if Library.Settings.Skeleton.Enabled[PlayerType] then
        local function GetBodyParts()
            if not Character then return nil end
            local Parts = {
                Head = Character:FindFirstChild("Head"),
                UpperTorso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso"),
                LowerTorso = Character:FindFirstChild("LowerTorso") or Character:FindFirstChild("Torso"),
                RootPart = Character:FindFirstChild("HumanoidRootPart"),
                LeftUpperArm = Character:FindFirstChild("LeftUpperArm") or Character:FindFirstChild("Left Arm"),
                LeftLowerArm = Character:FindFirstChild("LeftLowerArm") or Character:FindFirstChild("Left Arm"),
                LeftHand = Character:FindFirstChild("LeftHand") or Character:FindFirstChild("Left Arm"),
                RightUpperArm = Character:FindFirstChild("RightUpperArm") or Character:FindFirstChild("Right Arm"),
                RightLowerArm = Character:FindFirstChild("RightLowerArm") or Character:FindFirstChild("Right Arm"),
                RightHand = Character:FindFirstChild("RightHand") or Character:FindFirstChild("Right Arm"),
                LeftUpperLeg = Character:FindFirstChild("LeftUpperLeg") or Character:FindFirstChild("Left Leg"),
                LeftLowerLeg = Character:FindFirstChild("LeftLowerLeg") or Character:FindFirstChild("Left Leg"),
                LeftFoot = Character:FindFirstChild("LeftFoot") or Character:FindFirstChild("Left Leg"),
                RightUpperLeg = Character:FindFirstChild("RightUpperLeg") or Character:FindFirstChild("Right Leg"),
                RightLowerLeg = Character:FindFirstChild("RightLowerLeg") or Character:FindFirstChild("Right Leg"),
                RightFoot = Character:FindFirstChild("RightFoot") or Character:FindFirstChild("Right Leg")
            }
            if not (Parts.Head and Parts.UpperTorso) then return nil end
            return Parts
        end
        
        local function DrawBone(Part1, Part2, Line)
            if not Part1 or not Part2 then
                Line.Visible = false
                return
            end
            local Pos1 = (Part1.CFrame * CFrame.new(0, 0, 0)).Position
            local Pos2 = (Part2.CFrame * CFrame.new(0, 0, 0)).Position
            local Screen1, Visible1 = Camera:WorldToViewportPoint(Pos1)
            local Screen2, Visible2 = Camera:WorldToViewportPoint(Pos2)
            
            if not (Visible1 and Visible2) or Screen1.Z < 0 or Screen2.Z < 0 then
                Line.Visible = false
                return
            end
            
            local ViewportSize = Camera.ViewportSize
            if Screen1.X < 0 or Screen1.X > ViewportSize.X or Screen1.Y < 0 or Screen1.Y > ViewportSize.Y or
               Screen2.X < 0 or Screen2.X > ViewportSize.X or Screen2.Y < 0 or Screen2.Y > ViewportSize.Y then
                Line.Visible = false
                return
            end
            
            Line.From = Vector2.new(Screen1.X, Screen1.Y)
            Line.To = Vector2.new(Screen2.X, Screen2.Y)
            Line.Color = SkeletonColor
            Line.Thickness = Library.Settings.Skeleton.Thickness
            Line.Transparency = Library.Settings.Skeleton.Transparency
            Line.Visible = true
        end
        
        local BodyParts = GetBodyParts()
        if BodyParts then
            local SkeletonData = Library.Drawings.Skeleton[Player]
            if SkeletonData then
                DrawBone(BodyParts.Head, BodyParts.UpperTorso, SkeletonData.Head)
                DrawBone(BodyParts.UpperTorso, BodyParts.LowerTorso, SkeletonData.UpperSpine)
                DrawBone(BodyParts.UpperTorso, BodyParts.LeftUpperArm, SkeletonData.LeftShoulder)
                DrawBone(BodyParts.LeftUpperArm, BodyParts.LeftLowerArm, SkeletonData.LeftUpperArm)
                DrawBone(BodyParts.LeftLowerArm, BodyParts.LeftHand, SkeletonData.LeftLowerArm)
                DrawBone(BodyParts.UpperTorso, BodyParts.RightUpperArm, SkeletonData.RightShoulder)
                DrawBone(BodyParts.RightUpperArm, BodyParts.RightLowerArm, SkeletonData.RightUpperArm)
                DrawBone(BodyParts.RightLowerArm, BodyParts.RightHand, SkeletonData.RightLowerArm)
                DrawBone(BodyParts.LowerTorso, BodyParts.LeftUpperLeg, SkeletonData.LeftHip)
                DrawBone(BodyParts.LeftUpperLeg, BodyParts.LeftLowerLeg, SkeletonData.LeftUpperLeg)
                DrawBone(BodyParts.LeftLowerLeg, BodyParts.LeftFoot, SkeletonData.LeftLowerLeg)
                DrawBone(BodyParts.LowerTorso, BodyParts.RightUpperLeg, SkeletonData.RightHip)
                DrawBone(BodyParts.RightUpperLeg, BodyParts.RightLowerLeg, SkeletonData.RightUpperLeg)
                DrawBone(BodyParts.RightLowerLeg, BodyParts.RightFoot, SkeletonData.RightLowerLeg)
            end
        end
    else
        local SkeletonData = Library.Drawings.Skeleton[Player]
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do
                Bone.Visible = false
            end
        end
    end
end

local RadarSystem = {}
RadarSystem.__index = RadarSystem

function RadarSystem.new()
    local self = setmetatable({}, RadarSystem)
    self.EspObjects = {}
    self.ExistingESPs = {}
    return self
end

function RadarSystem:Init(Library)
    self:UpdateObjectList(Library)
    self.Library = Library
end

function RadarSystem:UpdateObjectList(Library)
    self.EspObjects = {}
    for Object, _ in pairs(Library.ObjectESPs.ESPs) do
        table.insert(self.EspObjects, Object)
        if not table.find(self.ExistingESPs, Object) then
            self:PlaceObjectDot(Object)
        end
    end
end

function RadarSystem:PlaceObjectDot(Object)
    table.insert(self.ExistingESPs, Object)
    local CFramePosition = Object:IsA("Model") and Object:GetBoundingBox() or Object.Position
    local _, OnScreen = Camera:WorldToViewportPoint(CFramePosition)
    local NeutralData = {Neutral = true}
    
    local Dot = Drawing.new("Square")
    Dot.Transparency = 1
    Dot.Color = Color3.new(1, 1, 1)
    Dot.Visible = false
    Dot.Thickness = 1
    Dot.Position = Vector2.new(0, 0)
    Dot.Size = Vector2.new(6, 6)
    Dot.Filled = true
    Dot.ZIndex = 5
    
    local function Update()
        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            if Object then
                local Scale = self.Library.Settings.Radar.Scale
                local LocalCharacter = LocalPlayer.Character
                if LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") then
                    local Root = LocalCharacter.HumanoidRootPart
                    local CameraCFrame = Camera.CFrame
                    local FlattenedPosition = Vector3.new(CameraCFrame.Position.X, Root.Position.Y, CameraCFrame.Position.Z)
                    local RelativeCFrame = CFrame.new(Root.Position, FlattenedPosition)
                    local ObjectSpace = RelativeCFrame:PointToObjectSpace(CFramePosition)
                    local X, Z = ObjectSpace.X, ObjectSpace.Z
                    local RadarPosition = self.Library.Settings.Radar.Position - Vector2.new(X * Scale, Z * Scale)
                    
                    if (RadarPosition - self.Library.Settings.Radar.Position).Magnitude < self.Library.Settings.Radar.Radius - 2 then
                        Dot.Size = Vector2.new(6, 6)
                        Dot.Position = RadarPosition - Vector2.new(3, 3)
                        Dot.Visible = true
                    else
                        local Distance = (self.Library.Settings.Radar.Position - RadarPosition).Magnitude
                        local Direction = (self.Library.Settings.Radar.Position - RadarPosition).Unit * (Distance - self.Library.Settings.Radar.Radius)
                        local EdgePosition = Vector2.new(RadarPosition.X + Direction.X, RadarPosition.Y + Direction.Y)
                        Dot.Size = Vector2.new(4, 4)
                        Dot.Position = EdgePosition - Vector2.new(2, 2)
                        Dot.Visible = true
                    end
                    
                    Dot.Color = Color3.new(1, 1, 1)
                    Dot.Visible = true
                    if not self.Library.Settings.Radar.Enabled then
                        Dot.Visible = false
                    end
                end
            else
                Dot.Visible = false
                pcall(Dot.Destroy, Dot)
                pcall(Dot.Remove, Dot)
                table.remove(self.ExistingESPs, table.find(self.ExistingESPs, Object))
                Connection:Disconnect()
            end
        end)
        table.insert(self.Library._connections, Connection)
    end
    
    coroutine.wrap(Update)()
end

local ObjectESP = {}
ObjectESP.__index = ObjectESP

function ObjectESP.CreateESP(Library, Object, RootPart)
    local ObjectType = "generic"
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
        Line.Color = Color3.new(1, 1, 1)
        Line.Thickness = Library.Settings.Box.Thickness
    end
    
    local Tracer = Drawing.new("Line")
    Tracer.Visible = false
    Tracer.Thickness = Library.Settings.Tracer.Thickness
    Tracer.From = GetTracerOrigin(Library)
    
    local HealthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    
    task.defer(function()
        for Key, Object in pairs(HealthBar) do
            Object.Visible = false
            repeat task.wait() until RootPart
            local Health = Library.Settings.HealthBar.Source(LocalPlayer, "Health")
            local MaxHealth = Library.Settings.HealthBar.Source(LocalPlayer, "MaxHealth")
            local HealthLevel
            if Health / MaxHealth > 0.6 then
                HealthLevel = "High"
            elseif Health / MaxHealth > 0.2 then
                HealthLevel = "Medium"
            else
                HealthLevel = "Low"
            end
            if not Color3.new(1, 1, 1) then continue end
            if Object == HealthBar.Fill then
                Object.Color = Color3.new(1, 0, 0)
                Object.Filled = true
            elseif Object == HealthBar.Text then
                Object.Center = true
                Object.Size = Library.Settings.TextSize
                Object.Color = Color3.new(1, 0, 0)
                Object.Font = 2
            else
                Object.Filled = false
            end
        end
    end)
    
    local Info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    for _, Text in pairs(Info) do
        Text.Visible = false
        Text.Center = true
        Text.Size = Library.Settings.TextSize
        Text.Color = Color3.new(1, 1, 1)
        Text.Font = 2
        Text.Outline = true
    end
    
    local Snapline = Drawing.new("Line")
    Snapline.Visible = false
    Snapline.Color = Color3.new(1, 1, 1)
    Snapline.Thickness = 1
    
    local Highlight = Instance.new("Highlight")
    Highlight.FillColor = Color3.new(1, 1, 1)
    Highlight.OutlineColor = Color3.new(1, 1, 1)
    Highlight.FillTransparency = Library.Settings.Chams.Fill.Transparency
    Highlight.OutlineTransparency = Library.Settings.Chams.Outline.Transparency
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Enabled = false
    
    if not Library.ObjectESPs then
        Library.ObjectESPs = {Highlights = {}, ESPs = {}}
    end
    if Library.ObjectESPs.Highlights then
        Library.ObjectESPs.Highlights[Object] = Highlight
    end
    
    RootPart = Object:IsA("Part") and Object or RootPart or (Object:IsA("Model") and Object:FindFirstChildOfClass("Part"))
    
    local self = setmetatable({
        Box = Box,
        Tracer = Tracer,
        HealthBar = HealthBar,
        Info = Info,
        Snapline = Snapline,
        Fills = {},
        RootPart = RootPart,
        Highlight = Highlight,
        Object = Object
    }, ObjectESP)
    
    Library.ObjectESPs.ESPs[Object] = self
    return self
end

function ObjectESP:UpdateESP(Library)
    if not Library.Settings.ObjectsEnabled then
        return
    end
    
    local ESPData = self
    if not ESPData then
        return
    end
    
    local Object = self.Object
    if not Object then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        ESPData.Highlight.Enabled = false
        return
    end
    
    local RootPart = self.RootPart
    local Humanoid = Object:FindFirstChild("Humanoid")
    
    if not RootPart then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        ESPData.Highlight.Enabled = false
        return
    end
    
    local Position, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
    if not OnScreen then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        ESPData.Highlight.Enabled = false
        return
    end
    
    if Humanoid and Humanoid.Health <= 0 then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        ESPData.Highlight.Enabled = false
        return
    end
    
    local Distance = (RootPart.Position - Camera.CFrame.Position).Magnitude
    local IsVisible = true
    
    if OnScreen then
        local ObscuringParts = Camera:GetPartsObscuringTarget({Camera.CFrame.Position, RootPart.Position}, {RootPart})
        if #ObscuringParts > 0 then
            IsVisible = false
            if Library.Settings.Checks.Visible.Enabled and Library.Settings.Checks.Visible.OnlyVisible then
                for _, Line in pairs(ESPData.Box) do
                    Line.Visible = false
                end
                ESPData.Tracer.Visible = false
                for _, Object in pairs(ESPData.HealthBar) do
                    Object.Visible = false
                end
                for _, Object in pairs(ESPData.Info) do
                    Object.Visible = false
                end
                for _, Object in pairs(ESPData.Fills) do
                    Object.Visible = false
                end
                ESPData.Snapline.Visible = false
                ESPData.Highlight.Enabled = false
                return
            end
        end
    end
    
    if not OnScreen or Distance > Library.Settings.MaxDistance then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        ESPData.Tracer.Visible = false
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Info) do
            Object.Visible = false
        end
        for _, Object in pairs(ESPData.Fills) do
            Object.Visible = false
        end
        ESPData.Snapline.Visible = false
        ESPData.Highlight.Enabled = false
        return
    end
    
    local ObjectType = "generic"
    if Library.Settings.Checks.Team.Enabled then
        if not Library.Settings.Checks.Team.SelectedTeams[ObjectType] then
            for _, Line in pairs(ESPData.Box) do
                Line.Visible = false
            end
            ESPData.Tracer.Visible = false
            for _, Object in pairs(ESPData.HealthBar) do
                Object.Visible = false
            end
            for _, Object in pairs(ESPData.Info) do
                Object.Visible = false
            end
            for _, Object in pairs(ESPData.Fills) do
                Object.Visible = false
            end
            ESPData.Snapline.Visible = false
            ESPData.Highlight.Enabled = false
            return
        end
    end
    
    local NeutralData = {Neutral = true}
    local BoxOutlineColor = Color3.new(1, 1, 1)
    local BoxFillColor = Color3.new(1, 1, 1)
    local TracerColor = Color3.new(1, 1, 1)
    local TextColor = Color3.new(1, 1, 1)
    local ChamsOutlineColor = Color3.new(1, 1, 1)
    local ChamsFillColor = Color3.new(1, 1, 1)
    local HealthBarFillColor = Color3.new(1, 0, 0)
    local HealthBarOutlineColor = Color3.new(0, 0, 0)
    
    local Size = Object:IsA("Model") and Object:GetExtentsSize() or Object.Size
    local RootCFrame = RootPart.CFrame
    
    local TopPosition, TopVisible = Camera:WorldToViewportPoint(RootCFrame * CFrame.new(0, Size.Y / 2, 0).Position)
    local BottomPosition, BottomVisible = Camera:WorldToViewportPoint(RootCFrame * CFrame.new(0, -Size.Y / 2, 0).Position)
    local RootPosition = Camera:WorldToViewportPoint(RootCFrame.Position)
    
    if not TopVisible or not BottomVisible then
        for _, Line in pairs(ESPData.Box) do
            Line.Visible = false
        end
        return
    end
    
    local Scale = 1 / (RootPosition.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
    local Width = math.floor(4.5 * Scale)
    local Height = math.floor(6 * Scale)
    local X = math.floor(RootPosition.X)
    local Y = math.floor(RootPosition.Y)
    
    local TopLeft = Vector2.new(math.floor(X - Width / 2), math.floor((Y - Height / 2) + (Scale / 2)))
    local BoxSize = Vector2.new(Width, Height)
    
    for _, Line in pairs(ESPData.Box) do
        Line.Visible = false
    end
    
    if Library.Settings.Box.Enabled then
        local function UpdateFill()
            local Fill = ESPData.Fills[1]
            if not Fill then
                Fill = Drawing.new("Square")
                ESPData.Fills[1] = Fill
            end
            Fill.Visible = IsVisible and Library.Settings.Box.Filled.Enabled or false
            Fill.Color = BoxFillColor
            Fill.Transparency = Library.Settings.Box.Filled.Transparency
            Fill.Filled = true
            Fill.Position = TopLeft
            Fill.Size = BoxSize
        end
        
        UpdateFill()
        
        ESPData.Box.Left.From = TopLeft
        ESPData.Box.Left.To = TopLeft + Vector2.new(0, BoxSize.Y)
        ESPData.Box.Left.Visible = true
        
        ESPData.Box.Right.From = TopLeft + Vector2.new(BoxSize.X, 0)
        ESPData.Box.Right.To = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
        ESPData.Box.Right.Visible = true
        
        ESPData.Box.Top.From = TopLeft
        ESPData.Box.Top.To = TopLeft + Vector2.new(BoxSize.X, 0)
        ESPData.Box.Top.Visible = true
        
        ESPData.Box.Bottom.From = TopLeft + Vector2.new(0, BoxSize.Y)
        ESPData.Box.Bottom.To = TopLeft + Vector2.new(BoxSize.X, BoxSize.Y)
        ESPData.Box.Bottom.Visible = true
        
        for _, Line in pairs(ESPData.Box) do
            if Line.Visible then
                Line.Color = BoxOutlineColor
                Line.Thickness = Library.Settings.Box.Thickness
            end
        end
    end
    
    if Library.Settings.Tracer.Enabled[ObjectType] then
        ESPData.Tracer.From = GetTracerOrigin(Library)
        ESPData.Tracer.To = Vector2.new(Position.X, Position.Y)
        ESPData.Tracer.Color = TracerColor
        ESPData.Tracer.Visible = true
    else
        ESPData.Tracer.Visible = false
    end
    
    if Library.Settings.HealthBar.Enabled[ObjectType] and Humanoid then
        local Health = Humanoid.Health
        local MaxHealth = Humanoid.MaxHealth
        local HealthPercent = Health / MaxHealth
        local BarHeight = Height
        local BarWidth = 4
        local BarX = Library.Settings.HealthBar.Position == 1 and (TopLeft.X - BarWidth - 4) or (TopLeft.X + BarWidth + 4 + BoxSize.X)
        local BarPosition = Vector2.new(BarX, TopLeft.Y)
        
        if Library.Settings.HealthBar.Bar then
            ESPData.HealthBar.Outline.Size = Vector2.new(BarWidth, BarHeight)
            ESPData.HealthBar.Outline.Position = BarPosition
            ESPData.HealthBar.Outline.Visible = true
            ESPData.HealthBar.Outline.Color = HealthBarOutlineColor
            
            ESPData.HealthBar.Fill.Size = Vector2.new(BarWidth - 2, (BarHeight - 2) * HealthPercent)
            ESPData.HealthBar.Fill.Position = Vector2.new(BarPosition.X + 1, BarPosition.Y + 1 + ((BarHeight - 2) * (1 - HealthPercent)))
            ESPData.HealthBar.Fill.Color = HealthBarFillColor
            ESPData.HealthBar.Fill.Visible = true
        else
            ESPData.HealthBar.Outline.Visible = false
            ESPData.HealthBar.Fill.Visible = false
        end
        
        if Library.Settings.HealthBar.Text then
            ESPData.HealthBar.Text.Text = math.floor(Health) .. Library.Settings.HealthBar.Suffix
            ESPData.HealthBar.Text.Position = Vector2.new(BarPosition.X + BarWidth + 2, BarPosition.Y + BarHeight)
            ESPData.HealthBar.Text.Visible = true
        else
            ESPData.HealthBar.Text.Visible = false
        end
    else
        for _, Object in pairs(ESPData.HealthBar) do
            Object.Visible = false
        end
    end
    
    if Library.Settings.Name.Enabled[ObjectType] then
        ESPData.Info.Name.Text = Object.Name
        ESPData.Info.Name.Position = Vector2.new(TopLeft.X + Width / 2, TopLeft.Y - 20)
        ESPData.Info.Name.Color = TextColor
        ESPData.Info.Name.Visible = true
    else
        ESPData.Info.Name.Visible = false
    end
    
    if Library.Settings.Distance.Enabled[ObjectType] then
        local DisplayDistance = tonumber(Distance)
        if Library.Settings.Distance.DistanceUnit == 2 then
            DisplayDistance = Distance * 0.28
        end
        ESPData.Info.Name.Text = tostring(math.round(DisplayDistance * 10) / 10) .. " " .. (Library.Settings.Distance.DistanceUnit == 2 and "meters" or "studs")
        ESPData.Info.Name.Position = Vector2.new(TopLeft.X + Width / 2, TopLeft.Y + BoxSize.Y)
        ESPData.Info.Name.Color = TextColor
        ESPData.Info.Name.Visible = true
    else
        ESPData.Info.Name.Visible = false
    end
    
    if Library.Settings.Snaplines then
        ESPData.Snapline.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        ESPData.Snapline.To = Vector2.new(Position.X, Position.Y)
        ESPData.Snapline.Color = BoxOutlineColor
        ESPData.Snapline.Visible = false
    end
    
    local Highlight = ESPData.Highlight
    if Highlight then
        if Library.Settings.Chams.Enabled[ObjectType] and Object then
            Highlight.Parent = Object
            Highlight.FillColor = ChamsFillColor
            Highlight.OutlineColor = ChamsOutlineColor
            Highlight.FillTransparency = Library.Settings.Chams.Fill.Enabled and Library.Settings.Chams.Fill.Transparency or 1
            Highlight.OutlineTransparency = Library.Settings.Chams.Outline.Enabled and Library.Settings.Chams.Outline.Transparency or 1
            Highlight.Enabled = true
        else
            Highlight.Enabled = false
        end
        Highlight.DepthMode = Library.Settings.Chams.Occlusion and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
    end
end

function ObjectESP:RemoveESP()
    local ESPData = self
    if ESPData then
        for _, Line in pairs(ESPData.Box) do
            pcall(Line.Remove, Line)
            pcall(Line.Destroy, Line)
        end
        pcall(ESPData.Tracer.Remove, ESPData.Tracer)
        pcall(ESPData.Tracer.Destroy, ESPData.Tracer)
        for _, Object in pairs(ESPData.HealthBar) do
            pcall(Object.Remove, Object)
            pcall(Object.Destroy, Object)
        end
        for _, Object in pairs(ESPData.Info) do
            pcall(Object.Remove, Object)
            pcall(Object.Destroy, Object)
        end
        for _, Object in pairs(ESPData.Fills) do
            pcall(Object.Remove, Object)
            pcall(Object.Destroy, Object)
        end
        pcall(ESPData.Snapline.Remove, ESPData.Snapline)
        pcall(ESPData.Snapline.Destroy, ESPData.Snapline)
    end
    
    local Highlight = self.Highlight
    if Highlight then
        pcall(Highlight.Destroy, Highlight)
    end
end

local Radar = RadarSystem.new()

local Twilight = {
    Settings = {
        Enabled = false,
        ObjectsEnabled = false,
        Checks = {
            Visible = {
                Enabled = false,
                OnlyVisible = false,
                Recolor = false
            },
            Team = {
                Enabled = false,
                SelectedTeams = {
                    enemy = false,
                    friendly = false,
                    generic = false,
                    ["local"] = false
                }
            }
        },
        currentColors = {
            generic = {
                Box = {
                    Outline = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                    Fill = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
                },
                HealthBar = {
                    Outline = Color3.new(1, 1, 1),
                    Fills = {
                        Low = Color3.new(1, 0, 0),
                        Medium = Color3.new(1, 1, 0),
                        High = Color3.new(0, 1, 0)
                    }
                },
                Tracer = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                Text = Color3.new(1, 1, 1),
                Chams = {
                    Outline = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                    Fill = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
                },
                Skeleton = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
            },
            friendly = {
                Box = {
                    Outline = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                    Fill = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
                },
                HealthBar = {
                    Outline = Color3.new(1, 1, 1),
                    Fills = {
                        Low = Color3.new(1, 0, 0),
                        Medium = Color3.new(1, 1, 0),
                        High = Color3.new(0, 1, 0)
                    }
                },
                Tracer = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                Text = Color3.new(1, 1, 1),
                Chams = {
                    Outline = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                    Fill = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
                },
                Skeleton = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
            },
            enemy = {
                Box = {
                    Outline = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                    Fill = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
                },
                HealthBar = {
                    Outline = Color3.new(1, 1, 1),
                    Fills = {
                        Low = Color3.new(1, 0, 0),
                        Medium = Color3.new(1, 1, 0),
                        High = Color3.new(0, 1, 0)
                    }
                },
                Tracer = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                Text = Color3.new(1, 1, 1),
                Chams = {
                    Outline = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                    Fill = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
                },
                Skeleton = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
            },
            ["local"] = {
                Box = {
                    Outline = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                    Fill = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
                },
                HealthBar = {
                    Outline = Color3.new(1, 1, 1),
                    Fills = {
                        Low = Color3.new(1, 0, 0),
                        Medium = Color3.new(1, 1, 0),
                        High = Color3.new(0, 1, 0)
                    }
                },
                Tracer = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                Text = Color3.new(1, 1, 1),
                Chams = {
                    Outline = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)},
                    Fill = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
                },
                Skeleton = {Visible = Color3.new(1, 1, 1), Invisible = Color3.new(1, 1, 1)}
            },
            Radar = {
                Background = Color3.fromRGB(5, 5, 5),
                Border = Color3.fromRGB(35, 35, 35)
            }
        },
        HealthBar = {
            Enabled = {
                enemy = false,
                friendly = false,
                ["local"] = false,
                generic = false
            },
            Source = function(Player, Type)
                return Player.Character.Humanoid[Type]
            end,
            Bar = false,
            Text = false,
            Position = 1,
            Suffix = "HP"
        },
        Box = {
            Style = 1,
            Enabled = false,
            Filled = {
                Enabled = false,
                Transparency = 0.6
            },
            Thickness = 1
        },
        Tracer = {
            Enabled = {
                enemy = false,
                friendly = false,
                generic = false
            },
            Origin = 1,
            Style = 1,
            Thickness = 1
        },
        Name = {
            Enabled = {
                enemy = false,
                friendly = false,
                ["local"] = false,
                generic = false
            },
            Style = 1
        },
        Distance = {
            Enabled = {
                enemy = false,
                friendly = false,
                ["local"] = false,
                generic = false
            },
            DistanceUnit = 1
        },
        Chams = {
            Enabled = {
                enemy = false,
                friendly = false,
                ["local"] = false,
                generic = false
            },
            Outline = {
                Enabled = true,
                Thickness = 0.1,
                Transparency = 0
            },
            Fill = {
                Enabled = true,
                Transparency = 0.5
            },
            Occlusion = false
        },
        Skeleton = {
            Enabled = {
                enemy = false,
                friendly = false,
                ["local"] = false,
                generic = false
            },
            Thickness = 1,
            Transparency = 0
        },
        Radar = {
            Enabled = true,
            Position = Vector2.new(Camera.ViewportSize.X - 120, 120),
            Radius = 100,
            Scale = 1
        },
        TextSize = 14,
        MaxDistance = 2000,
        RefreshRate = 0.008333333333333333,
        Framerate = 0.016666666666666666,
        Snaplines = false
    },
    Drawings = {
        ESP = {},
        Tracers = {},
        Boxes = {},
        Healthbars = {},
        Names = {},
        Distances = {},
        Snaplines = {},
        Radar = {},
        Skeleton = {}
    },
    Highlights = {},
    ObjectESPs = {
        Highlights = {},
        ESPs = {}
    },
    Enums = {
        HealthBarPosition = {
            Left = 1,
            Right = 2
        },
        HealthSource = {
            NRPBS = function(Player, Type)
                return Player.NRPBS and Player.NRPBS[Type].Value
            end,
            Humanoid = function(Player, Type)
                return Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid[Type] or 100
            end
        },
        BoxStyle = {
            CornerBoxes = 1,
            Normal = 2,
            ["3D"] = 3,
            Quad = 4
        },
        TracerOrigin = {
            LocalHumanoid = 1,
            Mouse = 5,
            Viewports = {
                Bottom = 2,
                Top = 3,
                Center = 4
            }
        },
        TracerStyle = {
            Line = 1
        },
        NameStyle = {
            Username = 1,
            DisplayName = 2
        },
        DistanceUnit = {
            Studs = 1,
            Meters = 2
        },
        SkeletonBodyType = {
            Dynamic = nil,
            R6 = 1,
            R15 = 2
        }
    },
    _connections = {}
}

Radar:Init(Twilight)

function Twilight:Unload()
    for _, Player in ipairs(Players:GetPlayers()) do
        PlayerESP.RemoveESP(self, Player)
    end
    for _, ESP in ipairs(self.Drawings.ObjectESPs) do
        ESP:RemoveESP()
    end
    self.Drawings.ESP = {}
    self.Drawings.Skeleton = {}
    self.Drawings.Radar = {}
    self.ObjectESPs.Highlights = {}
    self.ObjectESPs = {}
    self.Drawings = {}
    self.Highlights = {}
    for _, Connection in pairs(self._connections) do
        Connection:Disconnect()
        Connection = nil
    end
end

function Twilight:DisablePlayerESP()
    for _, Player in ipairs(Players:GetPlayers()) do
        local ESPData = self.Drawings.ESP[Player]
        if ESPData then
            for _, Line in pairs(ESPData.Box) do
                Line.Visible = false
            end
            ESPData.Tracer.Visible = false
            for _, Object in pairs(ESPData.HealthBar) do
                Object.Visible = false
            end
            for _, Object in pairs(ESPData.Info) do
                Object.Visible = false
            end
            ESPData.Snapline.Visible = false
        end
        local SkeletonData = self.Drawings.Skeleton[Player]
        if SkeletonData then
            for _, Bone in pairs(SkeletonData) do
                Bone.Visible = false
            end
        end
        local Highlight = self.Highlights[Player]
        if Highlight then
            Highlight.Enabled = false
        end
    end
end

function Twilight:DisableObjectESP()
    if not self.ObjectESPs then return end
    if not self.ObjectESPs.ESPs then return end
    for _, ESP in pairs(self.ObjectESPs.ESPs) do
        if ESP then
            for _, Line in pairs(ESP.Box) do
                Line.Visible = false
            end
            ESP.Tracer.Visible = false
            for _, Object in pairs(ESP.HealthBar) do
                Object.Visible = false
            end
            for _, Object in pairs(ESP.Info) do
                Object.Visible = false
            end
            ESP.Snapline.Visible = false
        end
    end
    for _, Highlight in pairs(self.ObjectESPs.Highlights) do
        if Highlight then
            Highlight.Enabled = false
        end
    end
end

function Twilight:BindESPToObject(Object, RootPart)
    task.defer(function()
        task.wait(1)
        Radar:UpdateObjectList(self)
    end)
    return ObjectESP.CreateESP(self, Object, RootPart)
end

local LastPlayerUpdate = 0
local LastObjectUpdate = 0

table.insert(Twilight._connections, RunService.RenderStepped:Connect(function()
    if not Twilight.Settings.Enabled then
        Twilight:DisablePlayerESP()
        return
    end
    local CurrentTime = tick()
    if CurrentTime - LastPlayerUpdate >= Twilight.Settings.RefreshRate then
        for _, Player in ipairs(Players:GetPlayers()) do
            if not Twilight.Drawings.ESP[Player] then
                PlayerESP.CreateESP(Twilight, Player)
            end
            PlayerESP.UpdateESP(Twilight, Player)
        end
        LastPlayerUpdate = CurrentTime
    end
end))

table.insert(Twilight._connections, RunService.RenderStepped:Connect(function()
    if not Twilight.Settings.ObjectsEnabled then
        Twilight:DisableObjectESP()
        return
    end
    local CurrentTime = tick()
    if CurrentTime - LastObjectUpdate >= Twilight.Settings.RefreshRate then
        if not Twilight.ObjectESPs then return end
        for _, ESP in pairs(Twilight.ObjectESPs.ESPs) do
            if ESP then
                ESP:UpdateESP(Twilight)
            end
        end
        LastObjectUpdate = CurrentTime
    end
end))

table.insert(Twilight._connections, Players.PlayerAdded:Connect(function(Player)
    PlayerESP.CreateESP(Twilight, Player)
end))

table.insert(Twilight._connections, Players.PlayerRemoving:Connect(function(Player)
    PlayerESP.RemoveESP(Twilight, Player)
end))

for _, Player in ipairs(Players:GetPlayers()) do
    PlayerESP.CreateESP(Twilight, Player)
end

local function MergeDefaults(Source, Destination)
    Source = Source or {}
    Destination = Destination or {}
    for Key, Value in pairs(Source) do
        if type(Value) == "table" then
            Destination[Key] = MergeDefaults(Value, Destination[Key] or {})
        else
            if Destination[Key] == nil then
                Destination[Key] = Value
            end
        end
    end
    return Destination
end

function Twilight:SetOptions(Options)
    Options = Options or {}
    local Defaults = self.Settings
    self.Settings = MergeDefaults(Defaults, Options)
end

return Twilight