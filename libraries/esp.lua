local ESP = {}
ESP.__index = ESP
local ESPObject = {}
ESPObject.__index = ESPObject

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local Inset = game:GetService("GuiService"):GetGuiInset()

local Options = {
    MaxDistance = 5000,
    ShowDistance = true
}

local Properties = {
    Visible = true,
    Color = Color3.new(1, 1, 1),
    Transparency = 1,
    AutoRemove = true,
    Text = {
        Size = 18,
        Font = Drawing.Fonts.Monospace,
        Outline = false,
        OutlineColor = Color3.new(),
        Custom = {
            Offset = CFrame.new(),
            OffsetAuto = true,
            CustomText = nil
        }
    },
    Line = {
        Thickness = .5,
        From = Vector2.new(),
        Custom = {
            FromAuto = true
        }
    }
}

local function ToScreenPoint(Object, Position)
    local Vector = Camera:WorldToScreenPoint(Position)

    local InBounds = ((getrawmetatable(Object).__type == "Text") and (
        Vector.X < (-Object.TextBounds.X / 2) or Vector.X > (Camera.ViewportSize.X + Object.TextBounds.X/2)
    ) or true) and Vector.Z > 0

    return InBounds and Vector2.new(Vector.X, Vector.Y)
end

function DeepCopy(Table)
    local Copy = {}
    for key, value in pairs(Table) do
        Copy[key] = type(value) == "table" and DeepCopy(value) or value
    end
    return Copy
end

local function FillTable(Table, Default, Branch)
    for key, value in pairs(Branch and Default[Branch] or Default) do
        if not Table[key] then
            Table[key] = type(value) == "table" and DeepCopy(value) or value
        end
    end
    return Table
end

local function SetVisible(Object, bool)
    if Object.Visible ~= bool then
        Object.Visible = bool
    end
end

local Renderers = {
    Text = function(self, v)
        local Object = v.Object
        local MainPart = v.MainPart
        local Offset = v.Offset
        local DefaultText = v.DefaultText

        local Distance = (Camera.CFrame.Position - MainPart.Position).Magnitude
        if self.InputOptions.MaxDistance and Distance > self.InputOptions.MaxDistance then
            SetVisible(Object, false)
            return
        end

        local Vec2Position = ToScreenPoint(Object, MainPart.Position + Offset)
        if not Vec2Position then
            SetVisible(Object, false)
            return
        end

        SetVisible(Object, true)

        if self.InputOptions.ShowDistance then
            Object.Text = DefaultText.."\n["..math.floor(Distance).."]"
        end
    
        if Object.Position ~= Vec2Position then
            Object.Position = Vec2Position
        end
    end,
    Line = function(self, v)
        local Object = v.Object
        local MainPart = v.MainPart

        local Distance = (Camera.CFrame.Position - MainPart.Position).Magnitude
        if self.InputOptions.MaxDistance and Distance > self.InputOptions.MaxDistance then
            SetVisible(Object, false)
            return
        end

        local Vec2Position = ToScreenPoint(Object, MainPart.Position)
        if not Vec2Position then
            SetVisible(Object, false)
            return
        end

        SetVisible(Object, true)
        
        if Object.To ~= Vec2Position then
            Object.To = Vec2Position + Inset
        end
    end
}

function ESP.Base(InputOptions, InputProperties)
    local self = setmetatable({}, ESP)
    self.Holder = {}

    self.InputOptions = FillTable(InputOptions or {}, Options)
    self.InputProperties = FillTable(InputProperties or {}, Properties)

    local function Render()
        for _,v in pairs(self.Holder) do
            local Type = getrawmetatable(v.Object).__type
            Renderers[Type](self, v)
        end
    end

    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if self.InputProperties.Line.Custom.FromAuto then
            for _,v in pairs(self.Holder) do
                if getrawmetatable(v.Object).__type == "Line" then
                    v.Object.From = Vector2.new(Camera.ViewportSize.X * .5, Camera.ViewportSize.Y * .8)
                end
            end
        end
    end)

    self.RenderDrawings = RunService.RenderStepped:Connect(Render)

    return self
end

local function ConstructSettings(Object, self)
    for key, value in pairs(self.InputProperties) do
        if type(value) ~= "table" then
            Object[key] = value
        end
    end

    for key, value in pairs(self.InputProperties[getrawmetatable(Object).__type]) do
        if type(value) ~= "table" then
            Object[key] = value
        end
    end
end

local function UpdateSettings(Object, Properties)
    for key, value in pairs(Properties) do
        Object[key] = value
    end
end

function ESP:Add(Type, Part, Properties)
    local Object = Drawing.new(Type)
    ConstructSettings(Object, self)
    local MainPart = Part:IsA("Model") and Part.PrimaryPart or Part
    local Custom = self.InputProperties[Type].Custom
    
    if Properties then
        UpdateSettings(Object, Properties)
    end

    local Structure = {
        Object = Object,
        MainPart = MainPart,
    }

    if Type == "Text" then
        local Offset = Custom.Offset
        if Custom.OffsetAuto then
            if Part:IsA("Model") then
                local Size = Part:GetExtentsSize()
                Offset = Vector3.new(0, Size.Y/2 + 1, 0)
            else
                Offset = Vector3.new(0, Part.Size.Y/2 + 1, 0)
            end
        end
        
        Structure.Offset = Offset
        Structure.DefaultText = self.InputProperties.Text.Custom.CustomText or Part.Name
        
        Object.Text = Structure.DefaultText
        Object.Center = true
    else
        if self.InputProperties.Line.Custom.FromAuto then
            Object.From = Vector2.new(Camera.ViewportSize.X * .5, Camera.ViewportSize.Y * .8)
        end
    end

    local selfDrawing = setmetatable({
        Struct = Structure,
        Slot = #self.Holder + 1,
        Parent = self
    }, ESPObject)

    Structure.Reference = selfDrawing

    self.Holder[selfDrawing.Slot] = Structure

    if self.InputProperties.AutoRemove then
        MainPart.AncestryChanged:Connect(function(_, new)
            if not new then
                selfDrawing:Remove()
            end
        end)
    end

    return selfDrawing
end

function ESPObject:Remove()
    self.Parent.Holder[self.Slot] = nil
    self.Struct.Object:Remove()
    setmetatable(self, nil)
end

function ESPObject:Update(Properties)
    UpdateSettings(self.Struct.Object, Properties)
end

function ESP:UpdateAll(Type, Properties)
    for _,v in pairs(self.Holder) do
        if not Type or getrawmetatable(v.Reference.Struct.Object).__type == Type then
            v.Reference:Update(Properties)
        end
    end
end

function ESP:RemoveAll(Type)
    for _,v in pairs(self.Holder) do
        if not Type or getrawmetatable(v.Reference.Struct.Object).__type == Type then
            v.Reference:Remove()
        end
    end
end

return ESP
