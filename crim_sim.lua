-- GHOST v6 — block the downed sequence entirely, zero physics interference
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="GHOST", Text=t, Duration=s or 5}) end)
end

-- 1) Защита Humanoid от stun-состояний (не трогает физику, только блокирует переход в ragdoll)
local BAD = {
    [Enum.HumanoidStateType.Physics]=1,
    [Enum.HumanoidStateType.Ragdoll]=1,
    [Enum.HumanoidStateType.FallingDown]=1,
    [Enum.HumanoidStateType.PlatformStanding]=1,
    [Enum.HumanoidStateType.Seated]=1,
    [Enum.HumanoidStateType.Dead]=1,
}
local function protect(char)
    local h = char:WaitForChild("Humanoid", 5); if not h then return end
    pcall(function()
        h.BreakJointsOnDeath = false
        h.RequiresNeck = false
    end)
    for s in pairs(BAD) do pcall(function() h:SetStateEnabled(s, false) end) end
    h.StateChanged:Connect(function(_,n)
        if BAD[n] then pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end) end
    end)
    for _,m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") then
            m:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not m.Enabled then m.Enabled = true end
            end)
        end
    end
end
if LP.Character then protect(LP.Character) end
LP.CharacterAdded:Connect(protect)

-- 2) АГРЕССИВНЫЙ namecall-блок: режем ВСЁ что похоже на damage/stun/down к нам
local BLOCK_WORDS = {
    "stun","taser","tase","ragdoll","arrest","ko","knock","hospital","catch","capture",
    "handcuff","detect","down","damage","hurt","hit","wounded","injure","die","death",
    "takedamage","kill","notice","spot","alert","wanted"
}
local function matches(s)
    s = string.lower(tostring(s or ""))
    for _,w in ipairs(BLOCK_WORDS) do
        if string.find(s, w, 1, true) then return true end
    end
    return false
end

pcall(function()
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if typeof(self) == "Instance" then
            -- Режем ИСХОДЯЩИЕ
            if (self:IsA("RemoteEvent") or self:IsA("RemoteFunction"))
                and (m == "FireServer" or m == "InvokeServer")
                and matches(self.Name) then
                return
            end
            -- Режем наши Humanoid-методы
            if m == "TakeDamage" or m == "BreakJoints" or m == "Kill" then
                local c = LP.Character
                if c and (self == c:FindFirstChildOfClass("Humanoid") or self == c) then return end
            end
            -- Блок принудительной смены state
            if m == "ChangeState" then
                local c = LP.Character
                if c and self == c:FindFirstChildOfClass("Humanoid") then
                    local st = ...
                    if BAD[st] then return end
                end
            end
        end
        return old(self, ...)
    end)
end)

-- 3) Режем ВХОДЯЩИЕ OnClientEvent на damage/down ремоутах (getconnections disable)
local function killIncoming(r)
    if not (r:IsA("RemoteEvent") and matches(r.Name)) then return end
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

-- 4) ГЛАВНОЕ: сносить любой даунед-GUI сразу как появится
local function killDownedGui(d)
    local n = string.lower(d.Name or "")
    local t = d:IsA("TextLabel") and string.lower(d.Text or "") or ""
    if string.find(n,"down") or string.find(n,"hospital") or string.find(n,"death")
        or string.find(t,"спустились") or string.find(t,"ольниц") or string.find(t,"возрожден") then
        pcall(function() d:Destroy() end)
        return true
    end
    return false
end

LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    task.wait(0.03)
    -- приоритет 1: автоклик Продолжить до того как снесём экран
    if d:IsA("TextButton") and string.find(tostring(d.Text or ""), "родолжить") then
        pcall(function()
            if getconnections then
                for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
            end
        end)
    end
    -- приоритет 2: снести любой элемент даунед-экрана
    killDownedGui(d)
end)

-- 5) Heartbeat: чистим всё существующее PlayerGui от даунед-мусора
Run.Heartbeat:Connect(function()
    local pg = LP:FindFirstChild("PlayerGui"); if not pg then return end
    for _,d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("Frame") or d:IsA("ScreenGui") then
            killDownedGui(d)
        end
    end
end)

notify("GHOST v6: downed-GUI снесён, стан-ремоуты заблокированы", 8)
print("[GHOST v6] active — zero physics, pure event block")
