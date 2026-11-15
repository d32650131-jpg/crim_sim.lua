-- UNIVERSAL GODMODE v2 | Xeno-friendly
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer
local HUGE       = 1e9

local HP_WORDS  = {"health","hp","hitpoint","vitality","stamina","life"}
local DMG_WORDS = {"damage","hurt","hit","takedamage","shot","bullet","downed","down","kill","death","die"}

local function match(s, list)
    s = string.lower(tostring(s))
    for _,w in ipairs(list) do if string.find(s, w, 1, true) then return true end end
    return false
end

-- 1) Humanoid + ForceField
local function protectChar(char)
    local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
    pcall(function() hum.BreakJointsOnDeath = false end)
    pcall(function() hum.MaxHealth = HUGE; hum.Health = HUGE end)
    pcall(function()
        hum.HealthChanged:Connect(function(h) if h < HUGE then hum.Health = HUGE end end)
        hum:GetPropertyChangedSignal("MaxHealth"):Connect(function() hum.MaxHealth = HUGE end)
    end)
    if not char:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField"); ff.Visible = false; ff.Parent = char
    end
end
pcall(function() if LP.Character then protectChar(LP.Character) end end)
LP.CharacterAdded:Connect(protectChar)

-- 2/3) Автоподкачка атрибутов и values
local function pumpAttributes(inst)
    if not inst then return end
    for k,v in pairs(inst:GetAttributes()) do
        if type(v) == "number" and match(k, HP_WORDS) then
            pcall(function() inst:SetAttribute(k, HUGE) end)
        end
    end
end
local function pumpValues(root)
    if not root then return end
    for _,d in ipairs(root:GetDescendants()) do
        if (d:IsA("NumberValue") or d:IsA("IntValue")) and match(d.Name, HP_WORDS) then
            pcall(function() d.Value = HUGE end)
        end
    end
end

-- 4) Namecall-хук через hookmetamethod (Xeno OK)
pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local args = {...}
        if typeof(self) == "Instance" then
            if (m == "FireServer" or m == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                if match(self.Name, DMG_WORDS) then
                    for _,a in ipairs(args) do
                        if a == LP or a == LP.Character then return end
                    end
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

-- 5) Глушим входящие damage/down ивенты (если executor умеет getconnections)
local function killIncoming(r)
    if not (r:IsA("RemoteEvent") and match(r.Name, DMG_WORDS)) then return end
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

-- 6) Heartbeat пушит значения
RunService.Heartbeat:Connect(function()
    pcall(function()
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and h.Health < HUGE then h.Health = HUGE end
        pumpAttributes(LP)
        if c then pumpAttributes(c) end
        pumpValues(LP:FindFirstChild("leaderstats"))
        local pd = RS:FindFirstChild("PlayerData") or RS:FindFirstChild("Data")
        if pd then
            pumpValues(pd:FindFirstChild(LP.Name) or pd:FindFirstChild(tostring(LP.UserId)))
        end
    end)
end)

-- 7) Снос downed-GUI
pcall(function()
    LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
        if d:IsA("Frame") or d:IsA("ScreenGui") then
            local n = string.lower(d.Name)
            if string.find(n,"down") or string.find(n,"death") or string.find(n,"hospital") or string.find(n,"respawn") then
                pcall(function() d:Destroy() end)
            end
        end
    end)
end)

-- Статус-тост (виден без F9)
pcall(function()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "GODMODE",
        Text  = "active | MaxHP="..tostring(h and h.MaxHealth or "?"),
        Duration = 6
    })
end)
print("[GODMODE v2] active")
