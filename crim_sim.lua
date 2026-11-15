local function C_gm3()
    local script = G2L["gm3"]
    local button = script.Parent
    local tweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local HUGE = 1e9

    local isOn = false
    local conns = {}
    local hookInstalled = false
    local oldNamecall

    local function protect(char)
        local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
        hum.BreakJointsOnDeath = false
        hum.MaxHealth = HUGE; hum.Health = HUGE
        table.insert(conns, hum.HealthChanged:Connect(function(h)
            if isOn and h < HUGE then hum.Health = HUGE end
        end))
        table.insert(conns, hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
            if isOn then hum.MaxHealth = HUGE end
        end))
        if not char:FindFirstChildOfClass("ForceField") then
            local ff = Instance.new("ForceField"); ff.Visible = false; ff.Parent = char
        end
    end

    local function installHook()
        if hookInstalled then return end
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            if isOn then
                local m = getnamecallmethod()
                local c = LP.Character
                if c and (self == c:FindFirstChildOfClass("Humanoid") or self == c) then
                    if m == "TakeDamage" or m == "BreakJoints" or m == "Kill" or m == "Destroy" then
                        return
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        hookInstalled = true
    end

    local function enable()
        isOn = true
        installHook()
        if LP.Character then protect(LP.Character) end
        table.insert(conns, LP.CharacterAdded:Connect(protect))
        table.insert(conns, RunService.Heartbeat:Connect(function()
            if not isOn then return end
            local c = LP.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h and h.Health < HUGE then h.Health = HUGE end
        end))
    end

    local function disable()
        isOn = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        conns = {}
        local char = LP.Character
        if char then
            local ff = char:FindFirstChildOfClass("ForceField")
            if ff then ff:Destroy() end
        end
    end

    button.BackgroundColor3 = Color3.fromRGB(173, 41, 41)
    button.MouseButton1Click:Connect(function()
        isOn = not isOn
        tweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = isOn and Color3.fromRGB(64, 149, 33) or Color3.fromRGB(173, 41, 41)
        }):Play()
        if isOn then enable() else disable() end
    end)
end
task.spawn(C_gm3)
