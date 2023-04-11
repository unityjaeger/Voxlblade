local Library = loadstring(game:HttpGet'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/Library.lua')()

local Player = game.Players.LocalPlayer

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
    Text = 'Anti Aggro',
    Func = function()
        local Character = Player.Character
        if not (Character and Character.HumanoidRootPart) then return end
        Character.HumanoidRootPart.RootAttachment:Destroy()
    end,
    DoubleClick = false,
    Tooltip = 'mobs dont aggro on u'
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
