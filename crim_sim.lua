-- UNIVERSAL GODMODE | multi-vector | inject early
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer
local HUGE       = 1e9

-- ключевые слова, по которым ловим "здоровье" в атрибутах/объектах/ремоутах
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
    hum.MaxHealth = HUGE; hum.Health = HUGE
    hum.HealthChanged:Connect(function(h) if h < HUGE then hum.Health = HUGE end end)
    hum:GetPropertyChangedSignal("MaxHealth"):Connect(function() hum.MaxHealth = HUGE end)
    if not char:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField"); ff.Visible = false; ff.Parent = char
    end
end
if LP.Character then protectChar(LP.Character) end
LP.CharacterAdded:Connect(protectChar)

-- 2) Атрибуты игрока/персонажа по словам health/hp/...
local function pumpAttributes(inst)
    if not inst then return end
    for k,v in pairs(inst:GetAttributes()) do
        if type(v) == "number" and match(k, HP_WORDS) then
            pcall(function() inst:SetAttribute(k, HUGE) end)
        end
    end
end

-- 3) leaderstats / любые NumberValue/IntValue с health-именем
local function pumpValues(root)
    for _,d in ipairs(root:GetDescendants()) do
        if (d:IsA("NumberValue") or d:IsA("IntValue")) and match(d.Name, HP_WORDS) then
            pcall(function() d.Value = HUGE end)
        end
    end
end

-- 4) Namecall-хук: режем исходящие damage/down ремоуты, направленные на нас
local mt = getrawmetatable(game); setreadonly(mt, false)
local oldNamecall = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local m = getnamecallmethod()
    if (m == "FireServer" or m == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        if match(self.Name, DMG_WORDS) then
            local args = {...}
            for _,a in ipairs(args) do
                if a == LP or a == LP.Character then return end
            end
        end
    end
    if m == "TakeDamage" or m == "BreakJoints" or m == "Kill" then
        local c = LP.Character
        if c and (self == c:FindFirstChildOfClass("Humanoid") or self == c) then return end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- 5) Перехват ВХОДЯЩИХ ивентов "downed/damage" с сервера — глушим OnClientEvent
for _,r in ipairs(RS:GetDescendants()) do
    if r:IsA("RemoteEvent") and match(r.Name, DMG_WORDS) then
        pcall(function()
            local conns = getconnections and getconnections(r.OnClientEvent)
            if conns then for _,c in ipairs(conns) do pcall(function() c:Disable() end) end end
        end)
    end
end
RS.DescendantAdded:Connect(function(r)
    if r:IsA("RemoteEvent") and match(r.Name, DMG_WORDS) then
        task.wait(0.1)
        pcall(function()
            local conns = getconnections and getconnections(r.OnClientEvent)
            if conns then for _,c in ipairs(conns) do pcall(function() c:Disable() end) end end
        end)
    end
end)

-- 6) Тик: подкачка всего разом
RunService.Heartbeat:Connect(function()
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h and h.Health < HUGE then h.Health = HUGE end
    pumpAttributes(LP)
    if c then pumpAttributes(c) end
    local ls = LP:FindFirstChild("leaderstats"); if ls then pumpValues(ls) end
    local pd = RS:FindFirstChild("PlayerData") or RS:FindFirstChild("Data")
    if pd then
        local mine = pd:FindFirstChild(LP.Name) or pd:FindFirstChild(tostring(LP.UserId))
        if mine then pumpValues(mine) end
    end
end)

-- 7) Антидаунед GUI: если игра уже нарисовала "Вы спустились вниз" — убиваем экран локально
LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    if d:IsA("Frame") or d:IsA("ScreenGui") then
        local n = string.lower(d.Name)
        if string.find(n,"down") or string.find(n,"death") or string.find(n,"hospital") or string.find(n,"respawn") then
            pcall(function() d:Destroy() end)
        end
    end
end)

print("[GODMODE] active | vectors: humanoid, attrs, values, outgoing, incoming, autopump")
