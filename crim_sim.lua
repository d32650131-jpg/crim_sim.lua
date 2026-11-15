-- GHOST MODE Criminal Simulator (quiet) — CanQuery trick only, no physics fighting
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local SG = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="GHOST", Text=t, Duration=s or 5}) end)
end

-- 1) Призрак для raycast / .Touched — НЕ ТРОГАЕМ HumanoidRootPart и CollisionPart
local SKIP = { HumanoidRootPart = true, CollisionPart = true }

local function ghostify(char)
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and not SKIP[p.Name] then
            pcall(function()
                p.CanQuery = false   -- raycast пуль пройдёт сквозь
                p.CanTouch = false   -- .Touched не фаерится
                -- CanCollide НЕ трогаем, чтобы анти-чит не кикнул
            end)
        end
    end
end

-- 2) Анти-ragdoll: блокируем стан-состояния у Humanoid
local BAD = {
    [Enum.HumanoidStateType.Physics]=1,
    [Enum.HumanoidStateType.Ragdoll]=1,
    [Enum.HumanoidStateType.FallingDown]=1,
    [Enum.HumanoidStateType.PlatformStanding]=1,
    [Enum.HumanoidStateType.Seated]=1,
}
local function lockStates(h)
    for s in pairs(BAD) do pcall(function() h:SetStateEnabled(s, false) end) end
    h.StateChanged:Connect(function(_,n)
        if BAD[n] then pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end) end
    end)
end

-- 3) Motor6D не ломаем (ragdoll через разрыв)
local function lockMotors(char)
    for _,m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") then
            m:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not m.Enabled then m.Enabled = true end
            end)
        end
    end
end

-- 4) Защита персонажа
local function protect(char)
    local h = char:WaitForChild("Humanoid", 5); if not h then return end
    pcall(function()
        h.BreakJointsOnDeath = false
        h.RequiresNeck = false
    end)
    lockStates(h)
    ghostify(char)
    lockMotors(char)
    char.DescendantAdded:Connect(function(p)
        if p:IsA("BasePart") and not SKIP[p.Name] then
            pcall(function()
                p.CanQuery = false; p.CanTouch = false
            end)
        end
        if p:IsA("Motor6D") then
            p:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not p.Enabled then p.Enabled = true end
            end)
        end
    end)
end

if LP.Character then protect(LP.Character) end
LP.CharacterAdded:Connect(protect)

-- 5) Heartbeat подчищает
Run.Heartbeat:Connect(function()
    local c = LP.Character
    if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and not SKIP[p.Name] then
            if p.CanQuery or p.CanTouch then
                pcall(function() p.CanQuery = false; p.CanTouch = false end)
            end
        end
    end
end)

-- 6) Namecall-хук только на стан-ремоуты, без прочего мусора
local STUN = {"stun","taser","tase","ragdoll","arrest","ko","knock","hospital","catch","capture","handcuff"}
local function match(s, l)
    s = string.lower(tostring(s))
    for _,w in ipairs(l) do if string.find(s, w, 1, true) then return true end end
    return false
end
pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            if (m == "FireServer" or m == "InvokeServer") and match(self.Name, STUN) then
                for _,a in ipairs({...}) do
                    if a == LP or a == LP.Character then return end
                end
            end
        end
        return old(self, ...)
    end)
end)

-- 7) Автоклик "Продолжить" если даунед всё же вылез
LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    task.wait(0.05)
    if d:IsA("TextButton") and string.find(tostring(d.Text or ""), "родолжить") then
        pcall(function()
            for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
        end)
    end
end)

notify("GHOST MODE (quiet) — пули пролетают, физика не трогается", 10)
print("[GHOST] quiet mode active")
