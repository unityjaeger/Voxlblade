local Library = loadstring(game:HttpGet'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/Library.lua')()

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Player = game.Players.LocalPlayer

local Character = Player.Character or Player.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")
local Torso = Character:WaitForChild("Torso")
local Humanoid = Character:WaitForChild("Humanoid")

function Setup()
    Character, Root, Torso, Humanoid = nil
    Character = Player.CharacterAdded:Wait()
    Root = Character:WaitForChild("Root")
    Torso = Character:WaitForChild("Torso")
    Humanoid = Character:WaitForChild("Humanoid")
    Humanoid.Died:Connect(Setup)
end
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
