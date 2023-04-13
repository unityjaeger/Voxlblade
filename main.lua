local Library = loadstring(game:HttpGet'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/Library.lua')()

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = game.Players.LocalPlayer

local Character = Player.Character or Player.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")
local Torso = Character:WaitForChild("Torso")
local Humanoid = Character:WaitForChild("Humanoid")

--for waiting for mobs to spawn: tween through the music zones until one spawns, if multiple zones then tween between them, if one zone then tween around the sides by size

local Limbs = {}

local function SetupNoclip()
	for _,v in ipairs(getconnections(Torso.ChildAdded)) do
		v:Disable()
	end
	for _,v in ipairs(Character:GetChildren()) do
		if v:IsA("BasePart") then
			table.insert(Limbs, v)
		end
	end
end

function Setup()
    table.clear(Limbs)
    Character, Root, Torso, Humanoid = nil
    Character = Player.CharacterAdded:Wait()
    Root = Character:WaitForChild("HumanoidRootPart")
    Torso = Character:WaitForChild("Torso")
    Humanoid = Character:WaitForChild("Humanoid")
    Humanoid.Died:Connect(Setup)
    SetupNoclip()
end

SetupNoclip()
Humanoid.Died:Connect(Setup)

local Lighting = game.Lighting
local NPCS = workspace.NPCS

local Holder = Instance.new("Folder", CoreGui)

local Window = Library:CreateWindow({
    Title = 'Voxlblade GUI',
    Center = true, 
    AutoShow = true
})

local Tabs = {
    Main = Window:AddTab("Main"),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local MainBox = Tabs.Main:AddLeftGroupbox("Main")
local MiscBox = Tabs.Main:AddRightGroupbox("Misc")

MiscBox:AddToggle('NoFog', {
    Text = 'No Fog',
    Default = false,
    Tooltip = 'removes fog and atmosphere'
})
MiscBox:AddToggle('NoShadows', {
    Text = 'No Shadows',
    Default = false,
    Tooltip = 'removes shadows'
})
MiscBox:AddToggle('Fullbright', {
    Text = 'Fullbright',
    Default = false,
    Tooltip = 'increases brightness'
})
MiscBox:AddButton({
    Text = 'Unlock Camera Zoom',
    Func = function()
        Player.CameraMaxZoomDistance = 9e9
    end,
    DoubleClick = false,
    Tooltip = 'makes it so u can zoom further'
})

MainBox:AddButton({
    Text = 'Disable Aggro',
    Func = function()
        if not Root then
            return
        end
        
        local Attachment = Root:FindFirstChild("RootAttachment")
        if Attachment then
            Attachment:Destroy()
        end
    end,
    DoubleClick = false,
    Tooltip = 'mobs dont aggro on u'
})

MainBox:AddButton({
    Text = 'Abandon your mortal shell.',
    Func = function()
        if not Root then
            return
        end
        
        local Joint = Root:FindFirstChild("RootJoint")
        if Joint then
            Joint:Destroy()
        end
    end,
    DoubleClick = false,
    Tooltip = '...'
})

local CharacterHandler = require(Player.PlayerScripts.Core.Controllers.CharHandler)

local DefaultSpeed, _ = CharacterHandler:GetSpeed()
local DefaultRunSpeed = DefaultSpeed * 1.6

MainBox:AddSlider('WalkSpeed', {
    Text = 'Walkspeed',
    Default = DefaultSpeed,
    Min = DefaultSpeed,
    Max = 60,
    Rounding = 2,
    Compact = false,
})

MainBox:AddSlider('RunSpeed', {
    Text = 'Run Speed',
    Default = DefaultRunSpeed,
    Min = DefaultRunSpeed,
    Max = 60,
    Rounding = 2,
    Compact = false,
})

Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
    if CharacterHandler.Running then
        if Options.RunSpeed.Value > DefaultRunSpeed then
            Humanoid.WalkSpeed = Options.RunSpeed.Value
        end
    else
        if Options.WalkSpeed.Value > DefaultSpeed then
            Humanoid.WalkSpeed = Options.WalkSpeed.Value
        end
    end
end)

Toggles.NoFog:OnChanged(function(bool)
    if bool then
        Lighting.FogEnd = 9e9
        Lighting.Atmosphere.Parent = Holder
    else
        if Holder:FindFirstChild("Atmosphere") then
            Holder.Atmosphere.Parent = Lighting
        end
    end
end)

Toggles.NoShadows:OnChanged(function(bool)
    Lighting.GlobalShadows = not bool
end)

Toggles.Fullbright:OnChanged(function(bool)
    while bool do
        Lighting.Brightness = 5
        task.wait()
    end
end)

Library:OnUnload(function()
    Library.Unloaded = true
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' }) 

Library.ToggleKeybind = Options.MenuKeybind

local NoclipConnection
local function Noclip(bool)
	if bool then
		NoclipConnection = RunService.Stepped:Connect(function()
			for _, Limb in ipairs(Limbs) do
				Limb.CanCollide = false
			end
		end)
	else
		if NoclipConnection then
			NoclipConnection:Diconnect()
		end
	end
end

local FloatingPart
local FloatConnection
local function Float(bool)
    if bool then
        FloatingPart = Instance.new("Part")
        FloatingPart.Size = Vector3.new(5, 1, 5)
        FloatingPart.Transparency = .5
        FloatingPart.Anchored = true
        FloatingPart.Parent = workspace.CurrentCamera
        
        local Offset = CFrame.new(0, -3.5, 0)
        FloatConnection = RunService.Heartbeat:Connect(function()
            if Root then
                FloatingPart.CFrame = Root.CFrame * Offset
            end
        end)
    else
        if FloatingPart then
            FloatingPart:Destroy()
        end
        if FloatConnection then
            FloatConnection:Disconnect()
        end
    end
end

local function Transport(To)
    if not Root then
        return
    end

    local Distance = (Root.Position - To.Position).Magnitude
    if Distance > 25 then
        local Tween = TweenService:Create(Root, TweenInfo.new(Distance / 100, Enum.EasingStyle.Linear), {CFrame = To})
    else
        Root.CFrame = To
    end
end
