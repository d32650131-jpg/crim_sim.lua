-- GHOST MODE Criminal Simulator — CanQuery hitbox trick + noclip + anti-ragdoll + hover
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local HOVER_HEIGHT = 80         -- на сколько приподняться (вне LoS охраны)
local FLY_SPEED = 80
local DECOY_ENABLED = false     -- false = просто призрак; true = клонировать тело-обманку в сторону

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="GHOST", Text=t, Duration=s or 5}) end)
end

-- 1) GHOST — убираем хитбокс для raycast/touch
local function ghostify(char)
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.CanQuery = false
                p.CanTouch = false
                p.CanCollide = false
                p.Massless = true
            end)
        end
    end
end

-- 2) ANTI-RAGDOLL
local BAD = {
    [Enum.HumanoidStateType.Physics]=1,
    [Enum.HumanoidStateType.Ragdoll]=1,
    [Enum.HumanoidStateType.FallingDown]=1,
    [Enum.HumanoidStateType.Dead]=1,
    [Enum.HumanoidStateType.PlatformStanding]=1,
    [Enum.HumanoidStateType.Seated]=1,
}
local function lockStates(h)
    for s in pairs(BAD) do pcall(function() h:SetStateEnabled(s, false) end) end
    h.StateChanged:Connect(function(_,n)
        if BAD[n] then pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end) end
    end)
end

-- 3) NAMECALL-хук: режем входящие "подними в hospital" и исходящие "I got hit"
local STUN = {"stun","taser","tase","ragdoll","down","arrest","ko","knock","hospital","detect","catch","capture","handcuff","hurt","damage","teleport"}
local function match(s, l)
    s = string.lower(tostring(s))
    for _,w in ipairs(l) do if string.find(s, w, 1, true) then return true end end
    return false
end
pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if typeof(self) == "Instance" then
            if (self:IsA("RemoteEvent") or self:IsA("RemoteFunction"))
                and (m == "FireServer" or m == "InvokeServer")
                and match(self.Name, STUN) then
                for _,a in ipairs({...}) do
                    if a == LP or a == LP.Character then return end
                end
            end
            if m == "TakeDamage" or m == "BreakJoints" or m == "Kill" or m == "ChangeState" then
                local c = LP.Character
                if c and self == c:FindFirstChildOfClass("Humanoid") then
                    if m == "ChangeState" then
                        local st = ...
                        if BAD[st] then return end
                    else return end
                end
            end
        end
        return old(self, ...)
    end)
end)

-- 4) FLY — WASD в воздухе
local flyBV, flyBG
local function startFly(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 5); if not hrp then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if h then h.PlatformStand = false end

    if flyBV then pcall(function() flyBV:Destroy() end) end
    if flyBG then pcall(function() flyBG:Destroy() end) end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 9000
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp

    Run.RenderStepped:Connect(function()
        if not flyBV or not flyBV.Parent then return end
        local cam = workspace.CurrentCamera
        local move = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        flyBV.Velocity = move * FLY_SPEED
        flyBG.CFrame = cam.CFrame
    end)
end

-- 5) HOVER — поднять автоматом на HOVER_HEIGHT при появлении персонажа
local function hover(char)
    task.wait(0.5)
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    hrp.CFrame = hrp.CFrame + Vector3.new(0, HOVER_HEIGHT, 0)
end

-- 6) Полная защита персонажа
local function protect(char)
    local h = char:WaitForChild("Humanoid", 5); if not h then return end
    pcall(function() h.BreakJointsOnDeath = false; h.RequiresNeck = false end)
    lockStates(h)
    ghostify(char)
    char.DescendantAdded:Connect(function(p)
        if p:IsA("BasePart") then
            pcall(function()
                p.CanQuery = false; p.CanTouch = false; p.CanCollide = false; p.Massless = true
            end)
        end
    end)
    -- Motor6D держим целыми (анти-ragdoll через поломку)
    for _,m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") then
            m:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not m.Enabled then m.Enabled = true end
            end)
        end
    end
    startFly(char)
    hover(char)
end

if LP.Character then protect(LP.Character) end
LP.CharacterAdded:Connect(protect)

-- 7) GUI-watcher: если даунед всё же вылез — автоклик Продолжить
LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    task.wait(0.05)
    if d:IsA("TextButton") then
        local t = tostring(d.Text or "")
        if string.find(t, "родолжить") then
            pcall(function()
                for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
            end)
        end
    end
end)

-- 8) Heartbeat: чиним ghostify если сервер пересобирает персонажа
Run.Heartbeat:Connect(function()
    local c = LP.Character
    if c then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                if p.CanQuery or p.CanTouch or p.CanCollide then
                    pcall(function()
                        p.CanQuery = false; p.CanTouch = false; p.CanCollide = false
                    end)
                end
            end
        end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h and h:GetState() == Enum.HumanoidStateType.Ragdoll then
            pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end
end)

notify("GHOST MODE: пули/лучи не задевают | WASD+Space/Ctrl = fly", 12)
print("[GHOST] active")
