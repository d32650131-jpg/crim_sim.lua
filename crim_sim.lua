-- ANTI-DETECT v3 — continuous dip, universal NPC scan
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local SG = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local DETECT_RADIUS = 30
local DIP_DEPTH     = 4
local SCAN_RATE     = 0.05   -- 20Hz

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="ANTI", Text=t, Duration=s or 5}) end)
end

-- Один раз — диагностика: что лежит в workspace
task.spawn(function()
    task.wait(1)
    print("=== workspace top-level folders ===")
    for _,c in ipairs(workspace:GetChildren()) do
        if c:IsA("Folder") or c:IsA("Model") then
            local kids = #c:GetChildren()
            if kids > 0 and kids < 200 then
                print("  ", c.ClassName, c.Name, "("..kids..")")
            end
        end
    end
end)

-- Универсальный поиск врагов: все модели с Humanoid, кроме игроков, во ВСЁМ workspace
local function findEnemyParts()
    local out = {}
    for _,m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Humanoid") then
            local model = m.Parent
            if model and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
                if model ~= LP.Character then
                    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model.PrimaryPart
                    if root and root:IsA("BasePart") then
                        table.insert(out, root)
                    end
                end
            end
        end
    end
    return out
end

-- Защита Humanoid
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

-- НЕПРЕРЫВНЫЙ dip: пока враг близко, постоянно держим HRP ниже с восстановлением
local baseline = nil   -- "честная" позиция (без dip)
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

        if closest < DETECT_RADIUS then
            -- запомнить "честную" позицию если ещё не прячемся
            if not baseline then baseline = hrp.CFrame end
            -- опустить ниже
            pcall(function() hrp.CFrame = baseline - Vector3.new(0, DIP_DEPTH, 0) end)
        else
            -- враг далеко, вернуть в честную позицию, сбросить baseline
            if baseline then
                pcall(function() hrp.CFrame = baseline end)
                baseline = nil
            end
        end
    end
end)

-- Исправить baseline если игрок двигается (чтобы не телепортило назад)
task.spawn(function()
    while true do
        task.wait(0.3)
        if baseline then
            local c = LP.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- обновляем X/Z из текущего положения, Y оставляем "честный"
                local cur = hrp.Position
                baseline = CFrame.new(cur.X, baseline.Position.Y, cur.Z) * (baseline - baseline.Position)
            end
        end
    end
end)

-- Блок stun-ремоутов
local STUN = {"stun","taser","tase","ragdoll","arrest","ko","knock","hospital","catch","capture","handcuff","detect","down"}
local function match(s, l) s=string.lower(tostring(s)); for _,w in ipairs(l) do if string.find(s,w,1,true) then return true end end return false end
pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if typeof(self)=="Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            if (m=="FireServer" or m=="InvokeServer") and match(self.Name, STUN) then
                for _,a in ipairs({...}) do if a==LP or a==LP.Character then return end end
            end
        end
        return old(self, ...)
    end)
end)

-- Автоклик "Продолжить"
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

-- Старт-диагностика после 2 сек
task.spawn(function()
    task.wait(2)
    local e = findEnemyParts()
    notify("v3 active. Найдено врагов во всей сцене: "..#e, 8)
    print("[ANTI v3] enemies total:", #e)
end)
