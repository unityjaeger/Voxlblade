local Client = {}

local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera

local Player = game.Players.LocalPlayer
local Character =  Player.Character or Player.CharacterAdded:Wait()

local Root = Character:WaitForChild("HumanoidRootPart")
local Torso = Character:WaitForChild("Torso")
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:FindFirstChildOfClass("Animator")

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
SetupNoclip()

Humanoid.Died:Connect(function()
	for i,_ in ipairs(Limbs) do
	    Limbs[i] = nil
	end
	Character = Player.CharacterAdded:Wait()
	Torso = Character:WaitForChild("Torso")
	Root = Character:WaitForChild("HumanoidRootPart")
	Humanoid = Character:WaitForChild("Humanoid")
	Animator = Humanoid:FindFirstChildOfClass("Animator")
	SetupNoclip()
end)

function Client.Root(func)
	if Root then
		func(Root)
	end
end

function Client.Humanoid(func)
	if Humanoid then
		func(Humanoid)
	end
end

function Client.Animator(func)
	if Animator then
		func(Animator)
	end
end

local NoclipConnection
function Client.Noclip(bool)
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
function Client.Float(bool)
    if bool then
        FloatingPart = Instance.new("Part")
        FloatingPart.Size = Vector3.new(5, 1, 5)
        FloatingPart.Transparency = .5
        FloatingPart.Anchored = true
        FloatingPart.Parent = workspace.CurrentCamera
        
        local Offset = CFrame.new(0, -3.5, 0)
        FloatConnection = RunService.Heartbeat:Connect(function()
            Client.Root(function(Root)
                FloatingPart.CFrame = Root.CFrame * Offset
            end)
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

return Client
