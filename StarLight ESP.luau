local StarLightESP = {}
getgenv().StarLightESP = StarLightESP
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Cache = {}
local Connection = nil
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local Color3New = Color3.new
local DrawingNew = Drawing and Drawing.new
local WorldToViewportPoint = Camera.WorldToViewportPoint
local RandomString = function(length)
 length = tonumber(length) or math.random(10, 20)
 local array = {}
 for i = 1, length do
 array[i] = string.char(math.random(32, 126))
 end
 return table.concat(array)
end
local SafeCallback = function(Func, ...)
 if not (Func and typeof(Func) == "function") then
 return
 end
 local Result = table.pack(xpcall(Func, function(Error)
 task.defer(error, debug.traceback(Error, 2))
 return Error
 end, ...))
 if not Result[1] then
 return nil
 end
 return table.unpack(Result, 2, Result.n)
end
local GetPivot = function(Instance)
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
local InstancesLib = {
 Create = function(instanceType, properties)
 local instance = Instance.new(instanceType)
 for name, val in pairs(properties) do
 if name == "Parent" then
 continue
 end
 instance[name] = val
 end
 if properties["Parent"] ~= nil then
 instance["Parent"] = properties["Parent"]
 end
 return instance
 end,
 FindPrimaryPart = function(instance)
 if typeof(instance) ~= "Instance" then
 return nil
 end
 return (instance:IsA("Model") and instance.PrimaryPart or nil)
 or instance:FindFirstChildWhichIsA("BasePart")
 or instance:FindFirstChildWhichIsA("UnionOperation")
 or instance
 end,
 DistanceFrom = function(inst, from)
 if not (inst and from) then
 return 9e9
 end
 local position = if typeof(inst) == "Instance" then GetPivot(inst).Position else inst
 local fromPosition = if typeof(from) == "Instance" then GetPivot(from).Position else from
 return (fromPosition - position).Magnitude
 end
}
local getui
do
 local testGui = Instance.new("ScreenGui")
 local successful = pcall(function()
 testGui.Parent = CoreGui
 end)
 if not successful then
 getui = function() return Players.LocalPlayer.PlayerGui end
 else
 getui = function() return CoreGui end
 end
 testGui:Destroy()
end
local ActiveFolder = InstancesLib.Create("Folder", { Parent = getui(), Name = RandomString() })
local StorageFolder = InstancesLib.Create("Folder", { Parent = if typeof(game) == "userdata" then Players.Parent else game, Name = RandomString() })
local MainGUI = InstancesLib.Create("ScreenGui", { Parent = getui(), Name = RandomString(), IgnoreGuiInset = true, ResetOnSpawn = false, ClipToDeviceSafeArea = false, DisplayOrder = 999999 })
local BillboardGUI = InstancesLib.Create("ScreenGui", { Parent = getui(), Name = RandomString(), IgnoreGuiInset = true, ResetOnSpawn = false, ClipToDeviceSafeArea = false, DisplayOrder = 999999 })
local Library = {
 GlobalConfig = {
 IgnoreCharacter = false,
 Rainbow = false,
 Billboards = true,
 Highlighters = true,
 Distance = true,
 Tracers = true,
 Arrows = true,
 Font = Enum.Font.GothamBold
 },
 RainbowHueSetup = 0,
 RainbowHue = 0,
 RainbowStep = 0,
 RainbowColor = Color3.new()
}
local character
local rootPart
local camera = Camera
local function UpdatePlayerVariables(newCharacter, force)
 if force ~= true and Library.GlobalConfig.IgnoreCharacter == true then
 return
 end
 character = newCharacter or LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
 rootPart = character:WaitForChild("HumanoidRootPart", 2.5) or character:WaitForChild("UpperTorso", 2.5) or character:WaitForChild("Torso", 2.5) or character.PrimaryPart or character:WaitForChild("Head", 2.5)
end
task.spawn(UpdatePlayerVariables, nil, true)
local function worldToViewport(...)
 camera = (camera or workspace.CurrentCamera)
 if camera == nil then
 return Vector2.new(0, 0), false
 end
 return camera:WorldToViewportPoint(...)
end
local AllowedESPType = {
 text = true,
 sphereadornment = true,
 cylinderadornment = true,
 adornment = true,
 selectionbox = true,
 highlight = true
}
local AllowedTracerFrom = {
 top = true,
 bottom = true,
 center = true,
 mouse = true
}
local function TracerCreate(espSettings, instanceName)
 if not espSettings or espSettings.Enabled ~= true then
 return nil
 end
 espSettings.Color = typeof(espSettings.Color) == "Color3" and espSettings.Color or Color3.new()
 espSettings.Thickness = typeof(espSettings.Thickness) == "number" and espSettings.Thickness or 2
 espSettings.Transparency = typeof(espSettings.Transparency) == "number" and espSettings.Transparency or 0
 espSettings.From = string.lower(typeof(espSettings.From) == "string" and espSettings.From or "bottom")
 if not AllowedTracerFrom[espSettings.From] then
 espSettings.From = "bottom"
 end
 local Line = InstancesLib.Create("Frame", {
 Parent = MainGUI,
 Name = instanceName or "Tracer",
 BackgroundColor3 = espSettings.Color,
 BorderSizePixel = 0,
 Size = UDim2.new(0, 0, 0, 0),
 BackgroundTransparency = espSettings.Transparency,
 ZIndex = 10
 })
 local data = {
 From = Vector2.new(0, 0),
 To = Vector2.new(0, 0),
 Visible = true,
 Color3 = espSettings.Color,
 Thickness = espSettings.Thickness,
 Transparency = espSettings.Transparency
 }
 local function UpdateTracer(from, to)
 local distance = (to - from).Magnitude
 if distance > 0 then
 Line.Visible = data.Visible
 Line.Position = UDim2.fromOffset(from.X, from.Y)
 Line.Size = UDim2.new(0, distance, 0, data.Thickness)
 Line.Rotation = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))
 else
 Line.Visible = false
 end
 end
 UpdateTracer(data.From, data.To)
 local proxy = {}
 local Tracer = {
 __newindex = function(table, key, value)
 if not Line then return end
 if key == "From" then
 data.From = value
 UpdateTracer(data.From, data.To)
 elseif key == "To" then
 data.To = value
 UpdateTracer(data.From, data.To)
 elseif key == "Transparency" then
 Line.BackgroundTransparency = value
 data[key] = value
 elseif key == "Thickness" then
 data[key] = value
 UpdateTracer(data.From, data.To)
 elseif key == "Color3" then
 Line.BackgroundColor3 = value
 data[key] = value
 elseif key == "Visible" then
 Line.Parent = value and MainGUI or StorageFolder
 data[key] = value
 end
 end,
 __index = function(table, key)
 if not Line then return nil end
 if key == "Destroy" or key == "Delete" then
 return function()
 Line:Destroy()
 Line = nil
 end
 end
 return data[key]
 end
 }
 return setmetatable(proxy, Tracer)
end
function StarLightESP:SetGlobalConfig(config)
 for key, value in pairs(config) do
 Library.GlobalConfig[key] = value
 end
end
function StarLightESP:SetRainbow(enabled)
 Library.GlobalConfig.Rainbow = enabled
end
function StarLightESP:ToggleBillboards(enabled)
 Library.GlobalConfig.Billboards = enabled
end
function StarLightESP:ToggleHighlighters(enabled)
 Library.GlobalConfig.Highlighters = enabled
end
function StarLightESP:ToggleDistance(enabled)
 Library.GlobalConfig.Distance = enabled
end
function StarLightESP:ToggleTracers(enabled)
 Library.GlobalConfig.Tracers = enabled
end
function StarLightESP:ToggleArrows(enabled)
 Library.GlobalConfig.Arrows = enabled
end
function StarLightESP:SetFont(font)
 Library.GlobalConfig.Font = font
end
function StarLightESP:Clear()
 for _, ESP in pairs(Cache) do
 if ESP then
 ESP:Destroy()
 end
 end
 table.clear(Cache)
end
function StarLightESP:Unload()
 if Connection then
 Connection:Disconnect()
 end
 self:Clear()
 ActiveFolder:Destroy()
 StorageFolder:Destroy()
 MainGUI:Destroy()
 BillboardGUI:Destroy()
 getgenv().StarLightESP = nil
end
function StarLightESP:RemoveESP(model)
 local data = Cache[model]
 if data then
 data:Destroy()
 Cache[model] = nil
 end
end
function StarLightESP:AddESP(espSettings)
 local model = espSettings.Model
 if not model or Cache[model] then
 return
 end
 assert(typeof(espSettings) == "table", "espSettings must be a table")
 assert(typeof(model) == "Instance", "espSettings.Model must be an Instance")
 espSettings.ESPType = espSettings.ESPType or "highlight"
 espSettings.ESPType = string.lower(espSettings.ESPType)
 if not AllowedESPType[espSettings.ESPType] then
 error("Invalid ESP Type: " .. espSettings.ESPType)
 end
 espSettings.Name = typeof(espSettings.Name) == "string" and espSettings.Name or model.Name
 espSettings.TextModel = typeof(espSettings.TextModel) == "Instance" and espSettings.TextModel or model
 espSettings.Visible = typeof(espSettings.Visible) == "boolean" and espSettings.Visible or true
 espSettings.Color = typeof(espSettings.Color) == "Color3" and espSettings.Color or Color3.new(1, 1, 1)
 espSettings.MaxDistance = typeof(espSettings.MaxDistance) == "number" and espSettings.MaxDistance or 5000
 espSettings.StudsOffset = typeof(espSettings.StudsOffset) == "Vector3" and espSettings.StudsOffset or Vector3.new(0, 3, 0)
 espSettings.TextSize = typeof(espSettings.TextSize) == "number" and espSettings.TextSize or 23
 espSettings.Thickness = typeof(espSettings.Thickness) == "number" and espSettings.Thickness or 0.1
 espSettings.Transparency = typeof(espSettings.Transparency) == "number" and espSettings.Transparency or 0.65
 espSettings.SurfaceColor = typeof(espSettings.SurfaceColor) == "Color3" and espSettings.SurfaceColor or Color3.new()
 espSettings.FillColor = typeof(espSettings.FillColor) == "Color3" and espSettings.FillColor or espSettings.Color
 espSettings.OutlineColor = typeof(espSettings.OutlineColor) == "Color3" and espSettings.OutlineColor or Color3.new(1, 1, 1)
 espSettings.FillTransparency = typeof(espSettings.FillTransparency) == "number" and espSettings.FillTransparency or 0.5
 espSettings.OutlineTransparency = typeof(espSettings.OutlineTransparency) == "number" and espSettings.OutlineTransparency or 0
 espSettings.Tracer = typeof(espSettings.Tracer) == "table" and espSettings.Tracer or { Enabled = false }
 espSettings.Arrow = typeof(espSettings.Arrow) == "table" and espSettings.Arrow or { Enabled = false }
 local Index = RandomString()
 local Billboard = InstancesLib.Create("BillboardGui", {
 Parent = BillboardGUI,
 Name = Index,
 Enabled = true,
 ResetOnSpawn = false,
 AlwaysOnTop = true,
 Size = UDim2.new(0, 200, 0, 50),
 Adornee = espSettings.TextModel,
 StudsOffset = espSettings.StudsOffset
 })
 local BillboardText = InstancesLib.Create("TextLabel", {
 Parent = Billboard,
 Size = UDim2.new(1, 0, 1, 0),
 Font = Library.GlobalConfig.Font,
 TextWrap = true,
 TextWrapped = true,
 RichText = true,
 TextStrokeTransparency = 0,
 BackgroundTransparency = 1,
 Text = espSettings.Name,
 TextColor3 = espSettings.Color,
 TextSize = espSettings.TextSize
 })
 InstancesLib.Create("UIStroke", { Parent = BillboardText })
 local Highlighter = nil
 local IsAdornment = string.match(string.lower(espSettings.ESPType), "adornment")
 if IsAdornment then
 local ModelSize = nil
 if model:IsA("Model") then
 local _, size = model:GetBoundingBox()
 ModelSize = size
 else
 local prim = InstancesLib.FindPrimaryPart(model)
 ModelSize = prim and prim.Size or Vector3.new(4, 5, 2)
 end
 if espSettings.ESPType == "sphereadornment" then
 Highlighter = InstancesLib.Create("SphereHandleAdornment", {
 Parent = ActiveFolder,
 Name = Index,
 Adornee = model,
 AlwaysOnTop = true,
 ZIndex = 10,
 Radius = ModelSize.X * 1.085,
 CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),
 Color3 = espSettings.Color,
 Transparency = espSettings.Transparency
 })
 elseif espSettings.ESPType == "cylinderadornment" then
 Highlighter = InstancesLib.Create("CylinderHandleAdornment", {
 Parent = ActiveFolder,
 Name = Index,
 Adornee = model,
 AlwaysOnTop = true,
 ZIndex = 10,
 Height = ModelSize.Y * 2,
 Radius = ModelSize.X * 1.085,
 CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0),
 Color3 = espSettings.Color,
 Transparency = espSettings.Transparency
 })
 else
 Highlighter = InstancesLib.Create("BoxHandleAdornment", {
 Parent = ActiveFolder,
 Name = Index,
 Adornee = model,
 AlwaysOnTop = true,
 ZIndex = 10,
 Size = ModelSize,
 Color3 = espSettings.Color,
 Transparency = espSettings.Transparency
 })
 end
 elseif espSettings.ESPType == "selectionbox" then
 Highlighter = InstancesLib.Create("SelectionBox", {
 Parent = ActiveFolder,
 Name = Index,
 Adornee = model,
 Color3 = espSettings.Color,
 LineThickness = espSettings.Thickness,
 SurfaceColor3 = espSettings.SurfaceColor,
 SurfaceTransparency = espSettings.Transparency
 })
 elseif espSettings.ESPType == "highlight" then
 Highlighter = InstancesLib.Create("Highlight", {
 Parent = ActiveFolder,
 Name = Index,
 Adornee = model,
 FillColor = espSettings.FillColor,
 OutlineColor = espSettings.OutlineColor,
 FillTransparency = espSettings.FillTransparency,
 OutlineTransparency = espSettings.OutlineTransparency
 })
 end
 local Tracer = TracerCreate(espSettings.Tracer, Index)
 local Arrow = nil
 if espSettings.Arrow.Enabled then
 Arrow = InstancesLib.Create("ImageLabel", {
 Parent = MainGUI,
 Name = Index,
 Size = UDim2.new(0, 48, 0, 48),
 SizeConstraint = Enum.SizeConstraint.RelativeYY,
 AnchorPoint = Vector2.new(0.5, 0.5),
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 Image = "http://www.roblox.com/asset/?id=16368985219",
 ImageColor3 = espSettings.Color,
 Visible = false
 })
 espSettings.Arrow.CenterOffset = typeof(espSettings.Arrow.CenterOffset) == "number" and espSettings.Arrow.CenterOffset or 300
 end
 local ESPObject = {
 Index = Index,
 Model = model,
 Settings = espSettings,
 Highlight = Highlighter,
 Billboard = Billboard,
 Label = BillboardText,
 Tracer = Tracer,
 Arrow = Arrow,
 Hidden = not espSettings.Visible,
 ModelRoot = InstancesLib.FindPrimaryPart(model),
 LastDist = -1,
 Destroyed = false
 }
 local connection = model.AncestryChanged:Connect(function(_, parent)
 if not parent and not ESPObject.Destroyed then
 StarLightESP:RemoveESP(model)
 end
 end)
 function ESPObject:Destroy()
 if ESPObject.Destroyed then return end
 ESPObject.Destroyed = true
 if Billboard then Billboard:Destroy() end
 if Highlighter then Highlighter:Destroy() end
 if Tracer then Tracer:Destroy() end
 if Arrow then Arrow:Destroy() end
 if connection and connection.Connected then
 connection:Disconnect()
 end
 if espSettings.OnDestroy then
 SafeCallback(espSettings.OnDestroy.Fire, espSettings.OnDestroy)
 end
 if espSettings.OnDestroyFunc then
 SafeCallback(espSettings.OnDestroyFunc)
 end
 Cache[model] = nil
 end
 function ESPObject:Show()
 if ESPObject.Destroyed then return end
 ESPObject.Hidden = false
 if ESPObject.Billboard then ESPObject.Billboard.Enabled = true end
 if ESPObject.Highlight then
 ESPObject.Highlight.Parent = ActiveFolder
 ESPObject.Highlight.Adornee = ESPObject.Model
 end
 if ESPObject.Tracer then ESPObject.Tracer.Visible = true end
 if ESPObject.Arrow then ESPObject.Arrow.Visible = true end
 end
 function ESPObject:Hide()
 if ESPObject.Destroyed then return end
 ESPObject.Hidden = true
 if ESPObject.Billboard then ESPObject.Billboard.Enabled = false end
 if ESPObject.Highlight then
 ESPObject.Highlight.Parent = StorageFolder
 ESPObject.Highlight.Adornee = nil
 end
 if ESPObject.Tracer then ESPObject.Tracer.Visible = false end
 if ESPObject.Arrow then ESPObject.Arrow.Visible = false end
 end
 function ESPObject:ToggleVisibility()
 if ESPObject.Destroyed then return end
 if ESPObject.Hidden then
 ESPObject:Show()
 else
 ESPObject:Hide()
 end
 end
 Cache[model] = ESPObject
 return ESPObject
end
local function UpdateESP()
 if not LocalPlayer.Character then
 return
 end
 camera = Workspace.CurrentCamera
 local viewportSize = camera.ViewportSize
 local centerPos = Vector2.new(viewportSize.X / 2, viewportSize.Y)
 local mousePos = UserInputService:GetMouseLocation()
 local currentFOV = camera.FieldOfView
 for _, ESP in pairs(Cache) do
 if not ESP or ESP.Destroyed or not ESP.Model or not ESP.Model.Parent then
 if ESP and not ESP.Destroyed then
 ESP:Destroy()
 end
 if ESP and ESP.Model then
 Cache[ESP.Model] = nil
 end
 continue
 end
 if ESP.Hidden then
 continue
 end
 local modelRoot = ESP.ModelRoot or ESP.Model
 if not modelRoot then
 ESP:Hide()
 continue
 end
 local rootPosition = GetPivot(modelRoot).Position
 local vector, onScreen = worldToViewport(rootPosition)
 local distance = (camera.CFrame.Position - rootPosition).Magnitude
 if distance > ESP.Settings.MaxDistance then
 ESP:Hide()
 continue
 end
 if ESP.Settings.BeforeUpdate then
 SafeCallback(ESP.Settings.BeforeUpdate, ESP)
 end
 local color = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.Settings.Color
 local tracerColor = Library.GlobalConfig.Rainbow and Library.RainbowColor or (ESP.Settings.Tracer and ESP.Settings.Tracer.Color or color)
 local arrowColor = Library.GlobalConfig.Rainbow and Library.RainbowColor or (ESP.Settings.Arrow and ESP.Settings.Arrow.Color or color)
 if ESP.Arrow and Library.GlobalConfig.Arrows and ESP.Settings.Arrow.Enabled then
 ESP.Arrow.Visible = not onScreen
 if not onScreen then
 local screenSize = camera.ViewportSize
 local centerScreen = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
 local partPos = Vector2.new(vector.X, vector.Y)
 local IsInverted = vector.Z <= 0
 local invert = IsInverted and -1 or 1
 local direction = (partPos - centerScreen)
 local arctan = math.atan2(direction.Y, direction.X)
 local angle = math.deg(arctan) + 90
 local distanceArrow = (ESP.Settings.Arrow.CenterOffset * 0.001) * screenSize.Y
 ESP.Arrow.Rotation = angle + 180 * (IsInverted and 0 or 1)
 ESP.Arrow.Position = UDim2.new(
 0,
 centerScreen.X + (distanceArrow * math.cos(arctan) * invert),
 0,
 centerScreen.Y + (distanceArrow * math.sin(arctan) * invert)
 )
 ESP.Arrow.ImageColor3 = arrowColor
 end
 else
 if ESP.Arrow then ESP.Arrow.Visible = false end
 end
 if ESP.Tracer and Library.GlobalConfig.Tracers and ESP.Settings.Tracer.Enabled then
 ESP.Tracer.Visible = onScreen
 if onScreen then
 if ESP.Settings.Tracer.From == "mouse" then
 ESP.Tracer.From = Vector2.new(mousePos.X, mousePos.Y)
 elseif ESP.Settings.Tracer.From == "top" then
 ESP.Tracer.From = Vector2.new(viewportSize.X / 2, 0)
 elseif ESP.Settings.Tracer.From == "center" then
 ESP.Tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
 else
 ESP.Tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
 end
 ESP.Tracer.To = Vector2.new(vector.X, vector.Y)
 ESP.Tracer.Color3 = tracerColor
 ESP.Tracer.Thickness = ESP.Settings.Tracer.Thickness
 ESP.Tracer.Transparency = ESP.Settings.Tracer.Transparency
 end
 else
 if ESP.Tracer then ESP.Tracer.Visible = false end
 end
 if ESP.Billboard and Library.GlobalConfig.Billboards then
 ESP.Billboard.Enabled = onScreen
 if onScreen then
 if Library.GlobalConfig.Distance and ESP.Settings.Distance ~= false then
 local distMath = math.floor(distance)
 if ESP.LastDist ~= distMath then
 ESP.LastDist = distMath
 ESP.Label.Text = string.format("%s\n[%d]", ESP.Settings.Name, distMath)
 end
 else
 if ESP.Label.Text ~= ESP.Settings.Name then
 ESP.Label.Text = ESP.Settings.Name
 end
 end
 ESP.Label.Font = Library.GlobalConfig.Font
 ESP.Label.TextColor3 = color
 ESP.Label.TextSize = ESP.Settings.TextSize * (currentFOV / 70)
 end
 else
 if ESP.Billboard then ESP.Billboard.Enabled = false end
 end
 if ESP.Highlight and Library.GlobalConfig.Highlighters then
 local showHighlight = onScreen
 if ESP.Settings.ESPType == "highlight" then
 ESP.Highlight.Parent = showHighlight and ActiveFolder or StorageFolder
 ESP.Highlight.Adornee = showHighlight and ESP.Model or nil
 if showHighlight then
 ESP.Highlight.FillColor = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.Settings.FillColor
 ESP.Highlight.OutlineColor = Library.GlobalConfig.Rainbow and Library.RainbowColor or ESP.Settings.OutlineColor
 ESP.Highlight.FillTransparency = ESP.Settings.FillTransparency
 ESP.Highlight.OutlineTransparency = ESP.Settings.OutlineTransparency
 end
 elseif ESP.Settings.ESPType == "selectionbox" then
 ESP.Highlight.Parent = showHighlight and ActiveFolder or StorageFolder
 ESP.Highlight.Adornee = showHighlight and ESP.Model or nil
 if showHighlight then
 ESP.Highlight.Color3 = color
 ESP.Highlight.LineThickness = ESP.Settings.Thickness
 ESP.Highlight.SurfaceColor3 = ESP.Settings.SurfaceColor
 ESP.Highlight.SurfaceTransparency = ESP.Settings.Transparency
 end
 else
 ESP.Highlight.Parent = showHighlight and ActiveFolder or StorageFolder
 ESP.Highlight.Adornee = showHighlight and ESP.Model or nil
 if showHighlight then
 ESP.Highlight.Color3 = color
 ESP.Highlight.Transparency = ESP.Settings.Transparency
 end
 end
 else
 if ESP.Highlight then
 ESP.Highlight.Parent = StorageFolder
 ESP.Highlight.Adornee = nil
 end
 end
 if ESP.Settings.AfterUpdate then
 SafeCallback(ESP.Settings.AfterUpdate, ESP)
 end
 end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
 camera = workspace.CurrentCamera
end)
LocalPlayer.CharacterAdded:Connect(function(char)
 task.wait(0.1)
 UpdatePlayerVariables(char, false)
end)
RunService.RenderStepped:Connect(function(Delta)
 if not Library.GlobalConfig.Rainbow then
 return
 end
 Library.RainbowStep = Library.RainbowStep + Delta
 if Library.RainbowStep >= (1 / 60) then
 Library.RainbowStep = 0
 Library.RainbowHueSetup = Library.RainbowHueSetup + (1 / 400)
 if Library.RainbowHueSetup > 1 then
 Library.RainbowHueSetup = 0
 end
 Library.RainbowHue = Library.RainbowHueSetup
 Library.RainbowColor = Color3.fromHSV(Library.RainbowHue, 0.8, 1)
 end
end)
Connection = RunService.RenderStepped:Connect(UpdateESP)
getgenv().StarLightESP = StarLightESP
return StarLightESP
