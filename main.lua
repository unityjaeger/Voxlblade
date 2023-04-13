--//Libraries
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/Library.lua"))()
local FileModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/unityjaeger/Voxlblade/main/libraries/file.lua"))()
--//

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--//Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--//

--//Misc
local Player = game.Players.LocalPlayer
local PlayerScripts = Player:WaitForChild("PlayerScripts")
local Core = PlayerScripts:WaitForChild("Core")
local CharacterHandler = require(Core.Controllers:WaitForChild("CharHandler"))
local Holder = Instance.new("Folder", CoreGui)
--//

--//Character
local Character = Player.Character or Player.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")
local Torso = Character:WaitForChild("Torso")
local Humanoid = Character:WaitForChild("Humanoid")
--//

--//File
local File = FileModule("MephGui/Voxlblade")
--//

--//Game Objects
local Lighting = game.Lighting
local NPCS = workspace.NPCS
local SpawnZones = ReplicatedStorage.MusicZone

local EquipWeapon = ReplicatedStorage.Events.EquipWeapon
local SwingSword = ReplicatedStorage.Events.SwingSword
--//

--//Data
local DistanceConstant = 1/3
local DefaultGravity = workspace.Gravity
local Debounce, EquipDebounce = 0, 0
local CurrentCounter, SubCounter, Counter = 1, 1, 1
local CombinedAreas = {}
local SpawnAreas = {
    Buni = {"Frontier", "Plains"},
    DireBuni = {"Plains", "Forest"},
    PlainsWoof = {"Plains", "Forest"},
    Mageling = {"Forest", "Enchantville"},
    Bumblz = {"FloraFields"},
    Drone = {"FloraFields"},
    Budboy = {"FloraFields"},
    Sporeling = {"Enchantville"},
    SporebossMen = {"Enchantville"},
    Bulfrogg = {"Swamp", "Swamp2", "Swamp3"},
    Toadzerker = {"Swamp", "Swamp2", "Swamp3"},
    Dragigator = {"Swamp", "Swamp2", "Swamp3"},
    Caci = {"Desert"},
    Slizard = {"Desert"},
    Bowldur = {"Deadlands"},
    VoidRoot = {"Deadlands"},
    IronSlayer = {"Tundra", "Tundra2", "Tundra3", "Tundra4", "Tundra5"},
    Snoeman = {"Tundra", "Tundra2", "Tundra3", "Tundra4", "Tundra5"},
    Scow = {"Tundra", "Tundra2", "Tundra3", "Tundra4", "Tundra5"},
    WinterWoof = {"Tundra", "Tundra2", "Tundra3", "Tundra4", "Tundra5"},
    SteamGolem = {"Tundra", "Tundra2", "Tundra3", "Tundra4", "Tundra5"}
}
--//

--//Character Setup
local Limbs = {}

local function AntiAggro()
    if not Root then
        return
    end
    local Attachment = Root:FindFirstChild("RootAttachment")
    if Attachment then
        Attachment:Destroy()
    end
end

local WalkSpeedConnection
local function SetupSpeed()
    WalkSpeedConnection = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if CharacterHandler.Running then
            if Options.run_speed.Value > 16 then
                Humanoid.WalkSpeed = Options.run_speed.Value
            end
        else
            if Options.walk_speed.Value > 16 then
                Humanoid.WalkSpeed = Options.walk_speed.Value
            end
        end
    end)
end

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
    if WalkSpeedConnection then
        WalkSpeedConnection:Disconnect()
    end

    Character, Root, Torso, Humanoid = nil
    Character = Player.CharacterAdded:Wait()
    Root = Character:WaitForChild("HumanoidRootPart")
    Torso = Character:WaitForChild("Torso")
    Humanoid = Character:WaitForChild("Humanoid")
    Humanoid.Died:Connect(Setup)

    SetupNoclip()
    if Toggles.anti_aggro then
        AntiAggro()
    end
    SetupSpeed()
end

SetupSpeed()
SetupNoclip()
Humanoid.Died:Connect(Setup)
--//

--//UI Setup
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
local UIMainBox = Tabs['UI Settings']:AddLeftGroupbox('Menu')
--//

--//Common Functions
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
			NoclipConnection:Disconnect()
		end
	end
end

local FloatConnection
local function Float(bool)
    if bool then
        FloatConnection = RunService.Heartbeat:Connect(function()
            if Root then
                workspace.Gravity = 0
                Root.Velocity = Root.Velocity * Vector3.new(1, 0, 1)
            end
        end)
    else
        workspace.Gravity = DefaultGravity
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
    if Distance > 10 then
        local Tween = TweenService:Create(Root, TweenInfo.new(Distance / 50, Enum.EasingStyle.Linear), {CFrame = To})
        Tween:Play()
    else
        Root.CFrame = To
    end
end
--//

--//MainBox
MainBox:AddButton({
    Text = 'Invisible',
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
    Tooltip = 'drops ur character model'
})

MainBox:AddToggle('anti_aggro', {
    Text = 'Anti Aggro',
    Default = File.anti_aggro or false,
})

MainBox:AddDivider()

MainBox:AddDropdown('mob_selection', {
    Values = {"Buni","DireBuni","PlainsWoof","Mageling","Bumblz","Drone","Budboy","Sporeling","SporebossMen","Bulfrogg","Toadzerker","Dragigator","Caci","Slizard","Bowldur","VoidRoot","IronSlayer","Snoeman","Scow","WinterWoof","SteamGolem"},
    Default = 1,
    Multi = true,
    Text = 'Mobs to Farm',
    Tooltip = 'u can also select multiple mobs'
})

--//mob_selection sometimes slow???
repeat task.wait()
until Options.mob_selection

if File.mob_selection then
    Options.mob_selection:SetValue(File.mob_selection)
end

local function CombineAreas()
    for i,_ in pairs(Options.mob_selection.Value) do
        for _,v in pairs(SpawnAreas[i]) do
            if not table.find(CombinedAreas, v) then
                table.insert(CombinedAreas, v)
            end
        end
    end
end

Options.mob_selection:OnChanged(function()
    File.mob_selection = Options.mob_selection.Value
    table.clear(CombinedAreas)
    CombineAreas()
end)
CombineAreas()

MainBox:AddToggle("mob_farm", {
    Text = "Mob Farm",
    Default = File.mob_farm or false,
})

MainBox:AddToggle("mob_farm_nearby", {
    Text = "Kill Nearby Mobs",
    Default = false
})

MainBox:AddDivider()

MainBox:AddSlider('walk_speed', {
    Text = 'Walkspeed',
    Default = File.walk_speed or 16,
    Min = 16,
    Max = 60,
    Rounding = 0,
    Compact = false
})

MainBox:AddSlider('run_speed', {
    Text = 'Run Speed',
    Default = File.run_speed or 16,
    Min = 16,
    Max = 60,
    Rounding = 0,
    Compact = false
})
--//

--//Functions for MainBox
local function MatchesSelected(v)
    for i,_ in pairs(Options.mob_selection.Value) do
        if v.Name:match("^C?"..i) then
            return true
        end
    end
    return false
end

local function GetList()
    local new = {}
    for i,v in ipairs(NPCS:GetChildren()) do
        if MatchesSelected(v) then
            table.insert(new, v)
        end
    end
    return new
end

local function GetNearestMob()
    local obj, dist = nil, 9e9
    for _,v in ipairs(GetList()) do
        local mag = (Root.Position - v.Position).Magnitude
        if mag < dist then
            dist = mag
            obj = v
        end
    end
    return obj, dist
end

local function ClosestActualMob()
    local obj, dist = nil, 9e9
    for _,v in ipairs(NPCS:GetChildren()) do
        local mag = (Root.Position - v.Position).Magnitude
        if mag < dist then
            dist = mag
            obj = v
        end
    end
    return obj, dist
end

Toggles.mob_farm_nearby:OnChanged(function(bool)
    if not bool then
        Noclip(false)
        Float(false)
    else
        Noclip(true)
        Float(true)
    end

    task.spawn(function()
        while Toggles.mob_farm_nearby.Value and task.wait() do
            local Mob, Distance = ClosestActualMob()
            if Mob then
                if not Character:FindFirstChild("Sword") then
                    if EquipDebounce < os.clock() then
                        EquipWeapon:InvokeServer()
                    else
                        EquipDebounce = os.clock() + 1
                    end
                end
                
                if Mob:FindFirstChild("LinkedModel") then
                    Transport(Mob.LinkedModel.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
                    if Distance <= 15 then
                        SwingSword:FireServer("L")
                    end
                else
                    Transport(Mob.CFrame)
                end
            end
        end
    end)
end)

Toggles.anti_aggro:OnChanged(function(bool)
    File.anti_aggro = bool
    if bool then
        AntiAggro()
    end
end)

Options.walk_speed:OnChanged(function()
    File.walk_speed = Options.walk_speed.Value
end)

Options.run_speed:OnChanged(function()
    File.run_speed = Options.run_speed.Value
end)

local function XZDistance(a, b)
    return (Vector2.new(a.X,a.Z) - Vector2.new(b.X,b.Z)).Magnitude
end

Toggles.mob_farm:OnChanged(function(bool)
    File.mob_farm = bool

    if not bool then
        Noclip(false)
        Float(false)
    else
        Noclip(true)
        Float(true)
    end

    task.spawn(function()
        while Toggles.mob_farm.Value and task.wait() do
            if not Root then
                continue
            end

            local Mob, Distance = GetNearestMob()
            if not Mob then
                if Debounce > os.clock() then
                    continue
                end

                if Counter > #CombinedAreas then
                    Counter = 1
                    CurrentCounter = 1
                end

                local Goal = SpawnZones:FindFirstChild(CombinedAreas[CurrentCounter])
                if Counter > CurrentCounter then
                    if SubCounter > 8 then
                        CurrentCounter = CurrentCounter + 1
                        SubCounter = 1
                        continue
                    end

                    local Corners = {
                        Goal.Position + Vector3.new(Goal.Size.X * DistanceConstant, 0, -Goal.Size.Z * DistanceConstant),
                        Goal.Position + Vector3.new(Goal.Size.X * DistanceConstant, 0, 0),
                        Goal.Position + Vector3.new(Goal.Size.X * DistanceConstant, 0, Goal.Size.Z * DistanceConstant),
                        Goal.Position + Vector3.new(0, 0, Goal.Size.Z * DistanceConstant),
                        Goal.Position + Vector3.new(-Goal.Size.X * DistanceConstant, 0, Goal.Size.Z * DistanceConstant),
                        Goal.Position + Vector3.new(-Goal.Size.X * DistanceConstant, 0, 0),
                        Goal.Position + Vector3.new(-Goal.Size.X * DistanceConstant, 0, -Goal.Size.Z * DistanceConstant),
                        Goal.Position + Vector3.new(0, 0, -Goal.Size.Z * DistanceConstant)
                    }

                    Transport(CFrame.new(Corners[SubCounter]))
                    if (Root.Position - Corners[SubCounter]).Magnitude < 10 then
                        SubCounter = SubCounter + 1
                        Debounce = os.clock() + 5
                    end
                else
                    if XZDistance(Root.Position, Goal.Position) > 10 then
                        if Root.CFrame.Y < 100 then
                            Transport(CFrame.new(Root.CFrame.X, 150, Root.CFrame.Z))
                            continue
                        end
                        Transport(CFrame.new(Goal.CFrame.X, 150, Goal.CFrame.Z))
                    else
                        Transport(Goal.CFrame)
                        if (Root.Position - Goal.Position).Magnitude < 10 then
                            Counter = Counter + 1
                            Debounce = os.clock() + 15
                        end
                    end
                end
            else
                if not Character:FindFirstChild("Sword") then
                    if EquipDebounce < os.clock() then
                        EquipWeapon:InvokeServer()
                    else
                        EquipDebounce = os.clock() + 1
                    end
                end
                
                if Mob:FindFirstChild("LinkedModel") then
                    Transport(Mob.LinkedModel.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
                    if Distance < 10 then
                        SwingSword:FireServer("L")
                    end
                else
                    Transport(Mob.CFrame)
                end
            end
        end
    end)
end)
--//

--//MiscBox
MiscBox:AddToggle('no_fog', {
    Text = 'No Fog',
    Default = File.no_fog or false,
    Tooltip = 'removes fog and atmosphere'
})
MiscBox:AddToggle('no_shadows', {
    Text = 'No Shadows',
    Default = File.no_shadows or false,
})
MiscBox:AddToggle('full_bright', {
    Text = 'Fullbright',
    Default = File.full_bright or false,
})
MiscBox:AddToggle("unlock_zoom", {
    Text = 'Unlock Camera Zoom',
    Default = File.unlock_zoom or false
})
--//

--//Functions for MiscBox
Toggles.no_fog:OnChanged(function(bool)
    File.no_fog = bool
    if bool then
        Lighting.FogEnd = 9e9
        Lighting.Atmosphere.Parent = Holder
    else
        if Holder:FindFirstChild("Atmosphere") then
            Holder.Atmosphere.Parent = Lighting
        end
    end
end)

Toggles.no_shadows:OnChanged(function(bool)
    File.no_shadows = bool
    Lighting.GlobalShadows = not bool
end)

Toggles.full_bright:OnChanged(function(bool)
    File.full_bright = bool
    task.spawn(function()
        while Toggles.full_bright.Value and task.wait() do
            Lighting.Brightness = 5
        end
    end)
end)

Toggles.unlock_zoom:OnChanged(function(bool)
    File.unlock_zoom = bool
    if bool then
        Player.CameraMaxZoomDistance = 9e9
    else
        Player.CameraMaxZoomDistance = 35
    end
end)
--//

--//UIMainBox
Library:OnUnload(function()
    Library.Unloaded = true
end)

UIMainBox:AddButton('Unload', function() Library:Unload() end)
UIMainBox:AddLabel('Menu Bind'):AddKeyPicker('MenuKeybind', {Default = File.menu_keybind or 'End', NoUI = true, Text = 'Menu Keybind'})
UIMainBox:AddButton("Save Keybind", function() File.menu_keybind = Options.MenuKeybind.Value end)

Library.ToggleKeybind = Options.MenuKeybind
--//
