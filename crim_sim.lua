-- ANTI-DETECT v5 — horizontal jitter only, no floor clip
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local SG = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local DETECT_RADIUS = 35
local JITTER_XZ     = 3       -- боковой разброс, безопасный
local SCAN_RATE     = 0.03

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="ANTI", Text=t, Duration=s or 5}) end)
end

local function findEnemyParts()
    local out = {}
    for _,m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Humanoid") then
            local model = m.Parent
            if model and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) and model ~= LP.Character then
                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model.PrimaryPart
                if root and root:IsA("BasePart") then table.insert(out, root) end
            end
        end
    end
    return out
end

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

-- JITTER только по XZ, Y не трогаем (чтобы не падать)
local active = false
task.spawn(function()
    while true do
        task.wait(SCAN_RATE)
        local c = LP.Character; if not c then continue end
        local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end

        local closest = math.huge
        for _,r in ipairs(findEnemyParts()) do
            local d = (r.Position - hrp.Position).Magnitude
            if d < closest then closest = d end
        end

        if closest < DETECT_RADIUS then
            active = true
            local dx = (math.random() - 0.5) * 2 * JITTER_XZ
            local dz = (math.random() - 0.5) * 2 * JITTER_XZ
            -- только XZ, Y оставляем как есть (не падаем)
            local pos = hrp.Position
            pcall(function()
                hrp.CFrame = CFrame.new(pos.X + dx, pos.Y, pos.Z + dz) * (hrp.CFrame - hrp.CFrame.Position)
            end)
        else
            active = false
        end
    end
end)

-- stun-ремоут блок
local STUN = {"stun","taser","tase","ragdoll","arrest","ko","knock","hospital","catch","capture","handcuff","detect","down"}
local function match(s,l) s=string.lower(tostring(s)); for _,w in ipairs(l) do if string.find(s,w,1,true) then return true end end return false end
pcall(function()
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
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

notify("v5 XZ-jitter ±"..JITTER_XZ.." при враге в "..DETECT_RADIUS, 10)
