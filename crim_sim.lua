-- CRIM SIM FULL DUMP | run, get downed once, send me the file
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local LP      = Players.LocalPlayer

local LOG = {}
local function log(...)
    local parts = {}
    for i,v in ipairs({...}) do parts[i] = tostring(v) end
    local line = "["..os.date("%H:%M:%S").."] "..table.concat(parts, " | ")
    table.insert(LOG, line)
    print(line)
end

local function flush()
    if writefile then
        pcall(function()
            writefile("crim_sim_dump.txt", table.concat(LOG, "\n"))
        end)
    end
end

-- ========== 1) ДЕРЕВО ReplicatedStorage ==========
log("=== ReplicatedStorage tree ===")
for _,d in ipairs(RS:GetDescendants()) do
    if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") then
        log("  ", d.ClassName, d:GetFullName())
    end
end

-- ========== 2) АТРИБУТЫ игрока и персонажа ==========
log("=== LP attributes ===")
for k,v in pairs(LP:GetAttributes()) do log("  LP.attr", k, "=", v, "("..typeof(v)..")") end

local function dumpChar()
    local c = LP.Character; if not c then return end
    log("=== Character attributes ===")
    for k,v in pairs(c:GetAttributes()) do log("  char.attr", k, "=", v, "("..typeof(v)..")") end
    log("=== Character children ===")
    for _,ch in ipairs(c:GetChildren()) do
        log("  child", ch.ClassName, ch.Name)
    end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        log("=== Humanoid ===")
        log("  Health=", h.Health, "MaxHealth=", h.MaxHealth, "WalkSpeed=", h.WalkSpeed, "State=", h:GetState())
    end
end
dumpChar()

-- ========== 3) LEADERSTATS / PlayerData ==========
local function dumpVals(root, prefix)
    if not root then return end
    for _,d in ipairs(root:GetDescendants()) do
        if d:IsA("NumberValue") or d:IsA("IntValue") or d:IsA("StringValue") or d:IsA("BoolValue") then
            log(" ", prefix, d:GetFullName(), "=", d.Value)
        end
    end
end
log("=== leaderstats ===")
dumpVals(LP:FindFirstChild("leaderstats"), "ls")
for _,n in ipairs({"PlayerData","Data","PlayerStats","Stats"}) do
    local f = RS:FindFirstChild(n)
    if f then
        log("=== RS."..n.." ===")
        dumpVals(f, n)
    end
end

-- ========== 4) ХУК ВСЕХ РЕМОУТОВ ==========
local function safeStr(v)
    local ok, s = pcall(function()
        if typeof(v) == "Instance" then return v.ClassName..":"..v.Name
        elseif typeof(v) == "table" then
            local out = {}
            for k,vv in pairs(v) do table.insert(out, tostring(k).."="..tostring(vv)) end
            return "{"..table.concat(out,",").."}"
        else return tostring(v) end
    end)
    return ok and s or "?"
end

pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            if m == "FireServer" or m == "InvokeServer" then
                local args = {...}
                local strs = {}
                for i,a in ipairs(args) do strs[i] = safeStr(a) end
                log("OUT", m, self:GetFullName(), "args=", table.concat(strs, ","))
            end
        end
        return old(self, ...)
    end)
end)

-- входящие
for _,r in ipairs(RS:GetDescendants()) do
    if r:IsA("RemoteEvent") then
        pcall(function()
            r.OnClientEvent:Connect(function(...)
                local args = {...}
                local strs = {}
                for i,a in ipairs(args) do strs[i] = safeStr(a) end
                log("IN ", r:GetFullName(), "args=", table.concat(strs, ","))
            end)
        end)
    end
end

-- ========== 5) ЛОВИМ СОБЫТИЯ Humanoid'а ==========
local function watchChar(c)
    local h = c:WaitForChild("Humanoid", 5); if not h then return end
    h.HealthChanged:Connect(function(v) log("HP", v, "/", h.MaxHealth) end)
    h.StateChanged:Connect(function(_, new) log("STATE ->", new.Name) end)
    h.Died:Connect(function() log("DIED"); flush() end)

    -- слушаем смену ЛЮБЫХ атрибутов на игроке и персонаже
    LP.AttributeChanged:Connect(function(name)
        log("LP.attr changed", name, "=", LP:GetAttribute(name))
    end)
    c.AttributeChanged:Connect(function(name)
        log("char.attr changed", name, "=", c:GetAttribute(name))
    end)
end
if LP.Character then watchChar(LP.Character) end
LP.CharacterAdded:Connect(function(c) task.wait(0.5); dumpChar(); watchChar(c) end)

-- ========== 6) ЛОВИМ ПОЯВЛЕНИЕ GUI "Вы спустились" ==========
LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    if d:IsA("TextLabel") then
        local t = tostring(d.Text or "")
        if t ~= "" and (#t > 3) then
            log("GUI text:", d:GetFullName(), "=", t)
        end
    end
end)

-- ========== 7) АВТОСОХРАНЕНИЕ файла каждые 3 сек ==========
task.spawn(function()
    while true do task.wait(3); flush() end
end)

-- уведомление
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "DUMP ACTIVE",
    Text  = "иди поймай даунед, потом открой crim_sim_dump.txt",
    Duration = 8
})
log("=== dump started ===")
flush()
