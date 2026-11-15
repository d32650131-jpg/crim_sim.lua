-- GOD MODE Criminal Simulator — legit codes + attribute injection + fallback
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local LP = Players.LocalPlayer
local SG = game:GetService("StarterGui")

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="GOD", Text=t, Duration=s or 5}) end)
end

-- 1) Активировать все известные god-mode коды через Remotes.Codes
local CODES = {"ADMIN","GOD","PIGGY","30KLIKES","10MVISITS","POLICE","CITY"}
local codesRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Codes")
local redeemed = {}
if codesRemote and codesRemote:IsA("RemoteFunction") then
    for _,c in ipairs(CODES) do
        pcall(function()
            local r = codesRemote:InvokeServer(c)
            table.insert(redeemed, c.."="..tostring(r))
        end)
    end
end
notify("codes: "..(#redeemed > 0 and table.concat(redeemed, " | ") or "none"), 8)
print("[GOD] codes result:", table.concat(redeemed, " | "))

-- 2) Прямая запись GodCharges через SetAttribute
local HUGE = 999999
pcall(function() LP:SetAttribute("GodCharges", HUGE) end)

-- 3) Watcher: восстанавливать GodCharges если сервер списывает
pcall(function()
    LP:GetAttributeChangedSignal("GodCharges"):Connect(function()
        local v = LP:GetAttribute("GodCharges")
        if type(v) == "number" and v < HUGE then
            pcall(function() LP:SetAttribute("GodCharges", HUGE) end)
        end
    end)
end)

Run.Heartbeat:Connect(function()
    local v = LP:GetAttribute("GodCharges")
    if type(v) == "number" and v < HUGE then
        pcall(function() LP:SetAttribute("GodCharges", HUGE) end)
    end
end)

-- 4) Попытка активировать god через QueueAction
local qa = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("QueueAction")
if qa and qa:IsA("RemoteEvent") then
    for _,action in ipairs({"UseGod","ActivateGod","GodMode","God","Immunity","UseImmunity","EnableGod"}) do
        pcall(function() qa:FireServer(action) end)
    end
end

-- 5) Fallback: Humanoid lock + state block + Motor6D + ForceField
local BAD = {
    [Enum.HumanoidStateType.Physics]=1,
    [Enum.HumanoidStateType.Ragdoll]=1,
    [Enum.HumanoidStateType.FallingDown]=1,
    [Enum.HumanoidStateType.Dead]=1,
    [Enum.HumanoidStateType.PlatformStanding]=1,
}

local function prot(c)
    local h = c:WaitForChild("Humanoid", 5); if not h then return end
    pcall(function()
        h.BreakJointsOnDeath = false
        h.RequiresNeck = false
        h.MaxHealth = 1e9
        h.Health = 1e9
    end)
    for s in pairs(BAD) do pcall(function() h:SetStateEnabled(s, false) end) end
    h.StateChanged:Connect(function(_, n)
        if BAD[n] then pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end) end
    end)
    h.HealthChanged:Connect(function(v) if v < 1e9 then h.Health = 1e9 end end)
    for _,m in ipairs(c:GetDescendants()) do
        if m:IsA("Motor6D") then
            m:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not m.Enabled then m.Enabled = true end
            end)
        end
    end
    c.DescendantAdded:Connect(function(m)
        if m:IsA("Motor6D") then
            m:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not m.Enabled then m.Enabled = true end
            end)
        end
    end)
    if not c:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = c
    end
end
if LP.Character then prot(LP.Character) end
LP.CharacterAdded:Connect(prot)

-- 6) Namecall-хук на TakeDamage/BreakJoints + исходящие stun-ремоуты
pcall(function()
    local STUN = {"stun","taser","tase","ragdoll","down","arrest","ko","knock","sleep","hospital","detect","catch","capture","handcuff","hurt","damage"}
    local function match(s, l)
        s = string.lower(tostring(s))
        for _,w in ipairs(l) do if string.find(s, w, 1, true) then return true end end
        return false
    end
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
            if m == "TakeDamage" or m == "BreakJoints" or m == "Kill" then
                local c = LP.Character
                if c and (self == c:FindFirstChildOfClass("Humanoid") or self == c) then return end
            end
        end
        return old(self, ...)
    end)
end)

-- 7) GUI-watcher: даунед → автоклик "Продолжить"
LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    task.wait(0.05)
    if d:IsA("TextButton") then
        local t = tostring(d.Text or "")
        if string.find(t, "родолжить") or string.find(t, "ontinue") then
            pcall(function()
                if getconnections then
                    for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
                end
            end)
        end
    end
end)

-- 8) Финальный статус
task.wait(1.5)
local gc = LP:GetAttribute("GodCharges")
notify("GodCharges = "..tostring(gc), 10)
print("[GOD] final GodCharges =", gc)
