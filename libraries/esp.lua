local ESP = {}
ESP.__index = ESP

if not workspace.CurrentCamera then
    repeat
        workspace.ChildAdded:Wait()
    until workspace.CurrentCamera
end

local Player = game:GetService("Players").LocalPlayer
local Camera = workspace.CurrentCamera

local function ToScreenPoint(DrawingObject, Position)
    local Vector = Camera:WorldToScreenPoint(Position)

    local CameraLookVector = Camera.CFrame.LookVector
    local CameraLookVectorToPoint = CFrame.new(Camera.CFrame.Position, Position).LookVector
    local InBounds = (getrawmetatable(DrawingObject).__type == "Text") and (
        Vector.X < (-DrawingObject.TextBounds.X / 2) or Vector.X > (Camera.ViewportSize.X + DrawingObject.TextBounds.X)
    ) or true

    return (
        CameraLookVectorToPoint:Dot(CameraLookVector) > 0 and InBounds and (
            Vector2.new(Vector.X, Vector.Y)
        ) or nil
    )
end

local Default = {
    Base = {
        MaxDistance = 5000;
        ShowHealth = true;
        ShowDistance = true;
        AutoRemove = true;
    };
    Text = {
        CustomName = nil;
        TextSize = 17;
        Color = Color3.fromRGB(255, 255, 255);
        Transparency = 0;
        Outline = false;
        OutlineColor = Color3.fromRGB(255, 255, 255);
        Font = "System";
        Offset = "Auto"
    };
    Highlight = {
        FillColor = Color3.fromRGB(255, 255, 255);
        FillTransparency = .5;
        OutlineColor = Color3.fromRGB(255, 255, 255);
        OutlineTransparency = 1;
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
    };
    Tracer = {
        From = "Auto";
        Color = Color3.fromRGB(255, 255, 255);
        Transparency = 0;
        Thickness = 1;
    };
}

local function SlotFinder(Table)
    local nextindex = 1
    for index, _ in pairs(Table) do
        if nextindex < index then
            return index - 1
        end
        
        nextindex = nextindex + 1
    end
    return #Table + 1
end

local function Constructor(Type)
    local Object
    if Type == "Text" then
        Object = Drawing.new("Text")
    elseif Type == "Tracer" then
        Object = Drawing.new("Line")
    else
        Object = Instance.new("Highlight")
    end
    return Object
end

local function SetProperties(Type, Object, Options)
    if Type == "Text" then
        Object.Size = Options.TextSize
        Object.Color = Options.Color
        Object.Transparency = 1 - Options.Transparency
        Object.Outline = Options.Outline
        Object.OutlineColor = Options.OutlineColor
        Object.Font = Drawing.Fonts[Options.Font]
        Object.Center = true
    elseif Type == "Tracer" then
        Object.Color = Options.Color
        Object.Transparency = 1 - Options.Transparency

        Object.From = (not Options.From or Options.From == "Auto") and (
            Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/5 * 4)
        ) or Options.From
    else
        Object.FillColor = Options.FillColor
        Object.FillTransparency = Options.FillTransparency
        Object.OutlineColor = Options.OutlineColor
        Object.OutlineTransparency = Options.OutlineTransparency
        Object.DepthMode = Options.DepthMode
    end
end

function ESP.Base(Settings)
    local self = setmetatable({}, ESP)

    self.BaseOptions = Settings and coroutine.wrap(function()
        local Temp = Settings
        for key, value in pairs(Default.Base) do
            if not Temp[key] then
                Temp[key] = value
            end
        end
        return Temp
    end)() or Default.Base

    local Folder = Instance.new("Folder")
    Folder.Name = syn.crypt.random(24)
    Folder.Parent = game:GetService("CoreGui")

    self.HighlightFolder = Folder
    self.HighlightCount = 0

    self.Proxy = {}
    self.RenderConnection = nil

    local function RenderText(Table)
        local Object = Table._Object
        local Text = Table._ESPObject
        local Options = Table._Options
        local SourceData = Table._SourceData

        local Offset = not Options.Offset and Vector3.zero or Options.Offset == "Auto" and (
            Vector3.new(0, SourceData.RefPart.Size.Y/2 + 1, 0)
        ) or Options.Offset
        
        local PositionVector = ToScreenPoint(Text, SourceData.RefPart.Position + Offset)
        local Distance = (Camera.CFrame.Position - SourceData.RefPart.Position).Magnitude

        if not PositionVector or (self.BaseOptions.MaxDistance and Distance >= self.BaseOptions.MaxDistance or false) then
            if Text.Visible then
                Text.Visible = false
            end

            return
        end
        
        if not Text.Visible then
            Text.Visible = true
        end

        local DisplayName = (Options.CustomName or Object.Name)
        local Display = DisplayName
        if self.BaseOptions.ShowDistance then
            Display = Display.."\n["..math.floor(Distance).."]"
        end
        if self.BaseOptions.ShowHealth and SourceData.Humanoid then
            Display = Display..(Display:len() == DisplayName:len() and "\n" or " ").."["..
            (math.floor(SourceData.Humanoid.Health).."/"..math.floor(SourceData.Humanoid.MaxHealth)).."]"
        end
        
        Text.Text = Display
        Text.Position = PositionVector
    end

    local function RenderTracer(Table)
        local Tracer = Table._ESPObject
        local SourceData = Table._SourceData
        
        local PositionVector = ToScreenPoint(Tracer, SourceData.RefPart.Position)
        local Distance = (Camera.CFrame.Position - SourceData.RefPart.Position).Magnitude

        if not PositionVector or (self.BaseOptions.MaxDistance and Distance >= self.BaseOptions.MaxDistance or false) then
            if Tracer.Visible then
                Tracer.Visible = false
            end

            return
        end
        
        if not Tracer.Visible then
            Tracer.Visible = true
        end
        
        Tracer.To = PositionVector + Vector2.new(0, game:GetService("GuiService"):GetGuiInset().Y)
    end

    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        for _, value in pairs(self.Proxy) do
            if value._Type == "Tracer" then
                local Object = value._ESPObject
                local Options = value._Options
                if not Options.From or Options.From == "Auto" then
                    Object.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/5 * 4)
                end
            end
        end
    end)

    local function RenderMaster()
        for _, value in pairs(self.Proxy) do
            if value._Type == "Text" then
                RenderText(value)
            elseif value._Type == "Tracer" then
                RenderTracer(value)
            end
        end
    end

    self.Highlights = {}
    self.Drawings = setmetatable({}, {
        __newindex = function(_, k, v)
            rawset(self.Proxy, k, v)

            if #self.Proxy > 0 and not self.RenderConnection then
                self.RenderConnection = game:GetService("RunService").RenderStepped:Connect(RenderMaster)
            elseif #self.Proxy == 0 and self.RenderConnection then
                self.RenderConnection:Disconnect()
            end
        end;
    })

    warn("Disclaimer: The MaxDistance property is not supported for Highlights, as it produces unnecessary lag")
    return self
end

function ESP:Add(Type, Object, Settings)
    if not Default[Type] or Type == "Base" then
        error(("ESP Element of type %s does not exist"):format(Type))
    end

    if Type == "Highlight" and self.HighlightCount >= 31 then
        error("Cannot exceed a maximum of 31 Highlights, this is a roblox issue")
    end

    local Options = Settings and coroutine.wrap(function()
        local Temp = Settings
        for key, value in pairs(Default[Type]) do
            if not Temp[key] then
                Temp[key] = value
            end
        end
        return Temp
    end)() or Default[Type]

    local Slot = SlotFinder(self.Proxy)
    local CreatedInstance = Constructor(Type, Options)
    SetProperties(Type, CreatedInstance, Options)

    local SourceData = {}
    if Type == "Highlight" then
        CreatedInstance.Adornee = Object
        CreatedInstance.Parent = self.HighlightFolder
        self.HighlightCount = self.HighlightCount + 1
    else
        SourceData.Humanoid = (Object.Parent:FindFirstChild("Humanoid") or Object:FindFirstChild("Humanoid"))
        SourceData.RefPart = (Object:IsA"Model" and Object.PrimaryPart or Object)
    end

    local function Void()
        if Type ~= "Highlight" then
            self.Proxy[Slot] = nil
            CreatedInstance:Remove()
        else
            CreatedInstance:Destroy()
            self.HighlightCount = self.HighlightCount - 1
        end
    end

    local function Update(_, NewSettings)
        if not NewSettings then
            error("Settings not found")
            return
        end
        
        local NewOptions = coroutine.wrap(function()
            local Temp = NewSettings
            for key, value in pairs(Default[Type]) do
                if not Temp[key] then
                    Temp[key] = value
                end
            end
            return Temp
        end)()

        SetProperties(Type, CreatedInstance, NewOptions)
        if Type ~= "Highlight" then
            self.Proxy[Slot]._Options = NewOptions
        end
    end

    local Holder = {
        _Type = Type;
        _Object = Object;
        _ESPObject = CreatedInstance;
        _Options = Options;
        _SourceData = SourceData;
    }

    local Proxy = setmetatable({}, {})
    rawset(Proxy, "Remove", Void)
    rawset(Proxy, "Update", Update)

    if self.BaseOptions.AutoRemove then
        local Connection
        Connection = Object.AncestryChanged:Connect(function(_, new)
            if not new then
                Proxy:Remove()
                Connection:Disconnect()
            end
        end)
    end

    if Type ~= "Highlight" then 
        self.Drawings[Slot] = Holder
    end

    return Proxy
end

function ESP:Purge(Type)
    if Type == "Highlight" then
        for _, value in ipairs(self.HighlightFolder:GetChildren()) do
            value:Destroy()
            self.HighlightCount = self.HighlightCount - 1
        end
        return
    end

    for index, value in pairs(self.Proxy) do
        if not Type or value._Type == Type then
            self.Proxy[index] = nil
            value._ESPObject:Remove()
        end
    end
end

function ESP:Update(Settings)
    if not Settings then
        error("Settings not found")
        return
    end

    self.BaseOptions = Settings and coroutine.wrap(function()
        local Temp = Settings
        for key, value in pairs(Default.Base) do
            if not Temp[key] then
                Temp[key] = value
            end
        end
        return Temp
    end)() or Default.Base
end

return ESP
