-- CRIMINAL SIMULATOR | anti-downed / anti-stun / anti-detect
local Players = game:GetService("Players")
local RunSvc  = game:GetService("RunService")
local RS      = game:GetService("ReplicatedStorage")
local LP      = Players.LocalPlayer

local STUN_WORDS   = {"stun","taser","tase","ragdoll","down","arrest","ko","knock","sleep","hospital","detect","catch","capture","handcuff"}
local HEALTH_WORDS = {"health","hp","stamina","energy"}

local function match(s, list)
    s = string.lower(tostring(s))
    for _,w in ipairs(list) do if string.find(s, w, 1, true) then return true end end
    return false
end

-- 1) Блок перехода в стан-состояния Humanoid'а
local BAD_STATES = {
    [Enum.HumanoidStateType.Physics]  = true,
    [Enum.HumanoidStateType.Ragdoll]  = true,
    [Enum.HumanoidStateType.FallingDown]=true,
    [Enum.HumanoidStateType.Dead]     = true,
    [Enum.HumanoidStateType.Seated]   = true,
    [Enum.HumanoidStateType.PlatformStanding]=true,
}
local function lockStates(hum)
    for state,_ in pairs(BAD_STATES) do
        pcall(function() hum:SetStateEnabled(state, false) end)
    end
    hum.StateChanged:Connect(function(_, new)
        if BAD_STATES[new] then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end)
end

-- 2) Защита Motor6D (анти-ragdoll — стан рвёт суставы)
local function lockMotors(char)
    for _,m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") then
            m:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not m.Enabled then m.Enabled = true end
            end)
        end
    end
    char.DescendantAdded:Connect(function(m)
        if m:IsA("Motor6D") then
            m:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not m.Enabled then m.Enabled = true end
            end)
        end
    end)
end

-- 3) Автосброс атрибутов даунеда/стана/детекта
local function clearBadAttrs(inst)
    if not inst then return end
    for k,v in pairs(inst:GetAttributes()) do
        local lk = string.lower(k)
        if type(v) == "boolean" and v == true and match(lk, STUN_WORDS) then
            pcall(function() inst:SetAttribute(k, false) end)
        end
        if type(v) == "number" and match(lk, STUN_WORDS) then
            pcall(function() inst:SetAttribute(k, 0) end)
        end
        if type(v) == "number" and match(lk, HEALTH_WORDS) then
            pcall(function() inst:SetAttribute(k, 100) end)
        end
    end
end

-- 4) Walkspeed/Jump/Stamina держим максимальными
local SAFE_POS -- последняя безопасная позиция
local function protectChar(char)
    local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    pcall(function() hum.BreakJointsOnDeath = false end)
    pcall(function() hum.RequiresNeck = false end)
    lockStates(hum)
    task.spawn(function() task.wait(0.5); lockMotors(char) end)

    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
    end)
    hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if hum.JumpPower < 50 then hum.JumpPower = 50 end
    end)

    -- трекаем "безопасную" позицию каждые 2 сек, когда нас никто не детектит
    task.spawn(function()
        while char.Parent do
            task.wait(2)
            local detected = false
            for k,v in pairs(LP:GetAttributes()) do
                if type(v)=="boolean" and v and match(k, {"detect","wanted","chase"}) then detected=true end
            end
            if not detected and hrp then SAFE_POS = hrp.CFrame end
        end
    end)
end
if LP.Character then protectChar(LP.Character) end
LP.CharacterAdded:Connect(protectChar)

-- 5) Namecall-хук: блок исходящих stun/arrest/damage ремоутов, где аргумент = мы
pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            if (m == "FireServer" or m == "InvokeServer") and match(self.Name, STUN_WORDS) then
                for _,a in ipairs({...}) do
                    if a == LP or a == LP.Character then return end
                end
            end
        end
        return old(self, ...)
    end)
end)

-- 6) Глушим входящие события stun/downed
local function killIncoming(r)
    if not (r:IsA("RemoteEvent") and match(r.Name, STUN_WORDS)) then return end
    pcall(function()
        if getconnections then
            for _,c in ipairs(getconnections(r.OnClientEvent)) do
                pcall(function() c:Disable() end)
            end
        end
    end)
end
for _,r in ipairs(RS:GetDescendants()) do killIncoming(r) end
RS.DescendantAdded:Connect(function(r) task.wait(0.1) killIncoming(r) end)

-- 7) GUI-watcher: если показался экран "Вы спустились вниз" — TP на SAFE_POS
LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    task.wait(0.05)
    if d:IsA("TextLabel") or d:IsA("TextButton") then
        local t = tostring(d.Text or "")
        if string.find(t, "спустились") or string.find(t, "ольниц") or string.find(t, "ozрожден") then
            -- TP на последнюю безопасную позицию
            local c = LP.Character
            if c and c:FindFirstChild("HumanoidRootPart") and SAFE_POS then
                task.wait(0.1)
                c.HumanoidRootPart.CFrame = SAFE_POS
            end
            -- автоклик "Продолжить"
            if d:IsA("TextButton") and string.find(t, "родолжить") then
                pcall(function()
                    for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
                end)
            end
        end
    end
end)

-- 8) Heartbeat: чистим все дрянные атрибуты каждый кадр
RunSvc.Heartbeat:Connect(function()
    pcall(function()
        clearBadAttrs(LP)
        if LP.Character then clearBadAttrs(LP.Character) end
    end)
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "CRIM SIM BYPASS",
    Text  = "anti-stun / anti-downed / safe-TP active",
    Duration = 6
})
print("[CRIM SIM] bypass active")
