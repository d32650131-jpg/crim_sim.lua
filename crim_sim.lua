-- ANTI-DETECT Criminal Simulator v2 — tuned, minimal rubberband
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local SG = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local DETECT_RADIUS = 25     -- NPC ближе этого → dip
local DIP_DEPTH     = 3      -- маленький сдвиг, не триггерит rubberband
local DIP_HOLD      = 0.06   -- 60мс — глаз не замечает
local SCAN_RATE     = 0.08   -- проверяем 12 раз в секунду

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="ANTI", Text=t, Duration=s or 5}) end)
end

-- 1) Поиск ВСЕХ враждебных NPC: через модели с Humanoid, не-игроков, в папках угроз или по тэгам
local ENEMY_FOLDERS = {"Guards","Cops","Police","Npcs","NPCs","Enemies","Security","Dogs"}
local function isEnemy(m)
    if not m:IsA("Model") then return false end
    if not m:FindFirstChildOfClass("Humanoid") then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    return true
end
local function findEnemyParts()
    local out = {}
    for _,fname in ipairs(ENEMY_FOLDERS) do
        local f = workspace:FindFirstChild(fname)
        if f then
            for _,m in ipairs(f:GetChildren()) do
                if isEnemy(m) then
                    local root = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m.PrimaryPart
                    if root then table.insert(out, root) end
                end
            end
        end
    end
    return out
end

-- 2) Защита Humanoid-состояния
local BAD = {
    [Enum.HumanoidStateType.Physics]=1,
    [Enum.HumanoidStateType.Ragdoll]=1,
    [Enum.HumanoidStateType.FallingDown]=1,
    [Enum.HumanoidStateType.PlatformStanding]=1,
    [Enum.HumanoidStateType.Seated]=1,
}
local function protect(char)
    local h = char:WaitForChild("Humanoid", 5); if not h then return end
    pcall(function() h.BreakJointsOnDeath = false; h.RequiresNeck = false end)
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

-- 3) Dip-цикл
local dipping = false
task.spawn(function()
    while true do
        task.wait(SCAN_RATE)
        local c = LP.Character; if not c then continue end
        local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end

        local closest = math.huge
        for _,root in ipairs(findEnemyParts()) do
            local d = (root.Position - hrp.Position).Magnitude
            if d < closest then closest = d end
        end

        if closest < DETECT_RADIUS and not dipping then
            dipping = true
            local orig = hrp.CFrame
            pcall(function() hrp.CFrame = orig - Vector3.new(0, DIP_DEPTH, 0) end)
            task.wait(DIP_HOLD)
            local nhrp = c:FindFirstChild("HumanoidRootPart")
            if nhrp then pcall(function() nhrp.CFrame = orig end) end
            dipping = false
        end
    end
end)

-- 4) Блок всех stun-related ремоутов (исходящих от нас)
local STUN = {"stun","taser","tase","ragdoll","arrest","ko","knock","hospital","catch","capture","handcuff","detect","down"}
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

-- 5) Автоклик "Продолжить" (бесплатное восстановление вместо R$39)
LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
    task.wait(0.05)
    if d:IsA("TextButton") and string.find(tostring(d.Text or ""), "родолжить") then
        pcall(function()
            if getconnections then
                for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
            end
        end)
    end
end)

-- 6) При появлении "заметила/услышал" — экстренный глубокий dip
LP.PlayerGui.DescendantAdded:Connect(function(d)
    if d:IsA("TextLabel") then
        local t = tostring(d.Text or "")
        if string.find(t, "заметил") or string.find(t, "услышал") then
            local c = LP.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local orig = hrp.CFrame
                pcall(function() hrp.CFrame = orig - Vector3.new(0, 10, 0) end)
                task.wait(0.4)
                local n = c and c:FindFirstChild("HumanoidRootPart")
                if n then pcall(function() n.CFrame = orig end) end
            end
        end
    end
end)

-- Диагностика: раз в 5 сек говорим сколько врагов нашли
task.spawn(function()
    task.wait(2)
    local enemies = findEnemyParts()
    notify("ANTI-DETECT active. Враги в сцене: "..#enemies, 8)
    print("[ANTI] enemies found:", #enemies)
    for i,e in ipairs(enemies) do
        if i<=5 then print("  enemy", i, e:GetFullName()) end
    end
end)
