-- INVISIBLE TO NPC — CanQuery raycast ghost + name spoof
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local SG = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="INVIS", Text=t, Duration=s or 5}) end)
end

-- 1) GHOST RAYCAST — все части НЕ ловят raycast
-- HRP не трогаем (rubberband), но делаем его CanQuery false ТОЖЕ для NPC AI, просто не трогаем Collision
local function ghostify(char)
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.CanQuery = false   -- raycast сквозь — главное для AI
                p.CanTouch = false   -- .Touched не фаерится
                -- CanCollide НЕ трогаем = нет rubberband
            end)
        end
    end
end

-- 2) Скрыть имя над головой (многие AI ищут по Humanoid.DisplayName)
local function hideName(char)
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        pcall(function()
            h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            h.NameDisplayDistance = 0
            h.HealthDisplayDistance = 0
            h.DisplayName = ""
        end)
    end
end

-- 3) Анти-стан/ragdoll
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

-- 4) Защита персонажа
local function protect(char)
    local h = char:WaitForChild("Humanoid", 5); if not h then return end
    pcall(function() h.BreakJointsOnDeath = false; h.RequiresNeck = false end)
    lockStates(h)
    ghostify(char)
    hideName(char)
    for _,m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") then
            m:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not m.Enabled then m.Enabled = true end
            end)
        end
    end
    char.DescendantAdded:Connect(function(p)
        if p:IsA("BasePart") then
            pcall(function() p.CanQuery = false; p.CanTouch = false end)
        end
    end)
end
if LP.Character then protect(LP.Character) end
LP.CharacterAdded:Connect(protect)

-- 5) Heartbeat: сервер может пересобирать character — держим настройки
Run.Heartbeat:Connect(function()
    local c = LP.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.CanQuery or p.CanTouch then
                pcall(function() p.CanQuery = false; p.CanTouch = false end)
            end
        end
    end
end)

-- 6) Блок stun-ремоутов (вдруг AI детект послал напрямую)
local BLOCK = {"stun","taser","ragdoll","arrest","hospital","detect","down","catch","handcuff","notice","spot","alert","wanted"}
local function matches(s)
    s = string.lower(tostring(s or ""))
    for _,w in ipairs(BLOCK) do if string.find(s,w,1,true) then return true end end
    return false
end
pcall(function()
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if typeof(self) == "Instance" then
            if (self:IsA("RemoteEvent") or self:IsA("RemoteFunction"))
                and (m == "FireServer" or m == "InvokeServer")
                and matches(self.Name) then return end
            if (m == "TakeDamage" or m == "BreakJoints" or m == "Kill") then
                local c = LP.Character
                if c and (self == c:FindFirstChildOfClass("Humanoid") or self == c) then return end
            end
        end
        return old(self, ...)
    end)
end)

-- 7) Снос downed-GUI если что-то пробилось
LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    task.wait(0.03)
    if d:IsA("TextButton") and string.find(tostring(d.Text or ""), "родолжить") then
        pcall(function()
            if getconnections then
                for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
            end
        end)
    end
    local n = string.lower(d.Name or "")
    local t = d:IsA("TextLabel") and string.lower(d.Text or "") or ""
    if string.find(n,"down") or string.find(n,"hospital") or string.find(t,"спустились") or string.find(t,"ольниц") then
        pcall(function() d:Destroy() end)
    end
end)

notify("INVIS: NPC-raycast проходит сквозь. Если видят всё равно = сервер по дистанции", 10)
