-- crim_sim.lua  v4 — folder-targeted scan + proper categories
-- loader:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/d32650131-jpg/crim_sim.lua/main/crim_sim.lua", true))()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local TweenService      = game:GetService("TweenService")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse  = LP:GetMouse()

local S = {
    PoliceESP=false, NpcESP=false, GuardESP=false, LootESP=false, CameraESP=false, TruckESP=false,
    RedViewCones=false, DetectionMeter=false, NoiseMeter=false,
    WindowsNoclip=false, AntiTaser=false, StealthMode=false,
    SpeedBoost=false, InfStamina=false, FallProtect=false,
    Fullbright=false, AntiAFK=true,
    GrabNearbyLoot=false, BringLoot=false,
}
local SPEED_VAL = 50
local SCAN_INTERVAL = 1.2

if getgenv().__CRIM_SIM_GUI then pcall(function() getgenv().__CRIM_SIM_GUI:Destroy() end) end
if getgenv().__CRIM_SIM_CONN then
    for _, c in ipairs(getgenv().__CRIM_SIM_CONN) do pcall(function() c:Disconnect() end) end
end
getgenv().__CRIM_SIM_CONN = {}
local CONN = getgenv().__CRIM_SIM_CONN
for _, c in ipairs(Workspace:GetChildren()) do if c.Name=="__CRIM_ESP" then c:Destroy() end end

----------------------------------------------------------------
-- gui (unchanged from v3)
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name="CrimSim"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent = gethui and gethui() or game:GetService("CoreGui")
getgenv().__CRIM_SIM_GUI = gui
local root = Instance.new("Frame", gui)
root.Size=UDim2.new(0,360,0,560); root.Position=UDim2.new(0,60,0.5,-280)
root.BackgroundColor3=Color3.fromRGB(14,16,22); root.BorderSizePixel=0
root.Active=true; root.Draggable=true
Instance.new("UICorner", root).CornerRadius=UDim.new(0,12)
Instance.new("UIStroke", root).Color=Color3.fromRGB(40,44,58)
local header=Instance.new("Frame", root)
header.Size=UDim2.new(1,0,0,44); header.BackgroundColor3=Color3.fromRGB(20,23,32); header.BorderSizePixel=0
Instance.new("UICorner", header).CornerRadius=UDim.new(0,12)
local title=Instance.new("TextLabel", header)
title.BackgroundTransparency=1; title.Size=UDim2.new(1,-20,1,0); title.Position=UDim2.new(0,14,0,0)
title.Font=Enum.Font.GothamBold; title.TextSize=15; title.TextColor3=Color3.fromRGB(235,235,245)
title.TextXAlignment=Enum.TextXAlignment.Left; title.Text="CRIM SIM v4   ·   [Insert] toggle"
local scroll=Instance.new("ScrollingFrame", root)
scroll.Size=UDim2.new(1,-16,1,-58); scroll.Position=UDim2.new(0,8,0,50)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=4
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
local layout=Instance.new("UIListLayout", scroll); layout.Padding=UDim.new(0,6); layout.SortOrder=Enum.SortOrder.LayoutOrder
local function makeToggle(labelText, key, cb)
    local row=Instance.new("Frame", scroll)
    row.Size=UDim2.new(1,-8,0,32); row.BackgroundColor3=Color3.fromRGB(22,25,34); row.BorderSizePixel=0
    Instance.new("UICorner", row).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel", row)
    lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-60,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=13; lbl.TextColor3=Color3.fromRGB(215,218,228)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=labelText
    local sw=Instance.new("TextButton", row)
    sw.Size=UDim2.new(0,40,0,20); sw.Position=UDim2.new(1,-52,0.5,-10)
    sw.BackgroundColor3=Color3.fromRGB(55,60,72); sw.AutoButtonColor=false; sw.Text=""
    Instance.new("UICorner", sw).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame", sw)
    knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(0,2,0.5,-8)
    knob.BackgroundColor3=Color3.fromRGB(230,230,240); knob.BorderSizePixel=0
    Instance.new("UICorner", knob).CornerRadius=UDim.new(1,0)
    local function render()
        local on=S[key]
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = on and Color3.fromRGB(70,150,255) or Color3.fromRGB(55,60,72)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
    end
    sw.MouseButton1Click:Connect(function() S[key]=not S[key]; render(); if cb then pcall(cb, S[key]) end end)
    render()
end
local function makeAction(labelText, cb)
    local row=Instance.new("TextButton", scroll)
    row.Size=UDim2.new(1,-8,0,32); row.BackgroundColor3=Color3.fromRGB(32,95,200)
    row.Text=labelText; row.Font=Enum.Font.GothamBold; row.TextSize=13; row.TextColor3=Color3.new(1,1,1)
    row.AutoButtonColor=true
    Instance.new("UICorner", row).CornerRadius=UDim.new(0,8)
    row.MouseButton1Click:Connect(function() pcall(cb) end)
end
local function applyCursor()
    UserInputService.MouseIconEnabled = root.Visible
    UserInputService.ModalEnabled = root.Visible
end
applyCursor()
table.insert(CONN, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        root.Visible = not root.Visible; applyCursor()
    end
end))

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------
local function char() return LP.Character end
local function hrp() local c=char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c=char(); return c and c:FindFirstChildOfClass("Humanoid") end

local LOOT_NAMES = {"cashbag","goldbar","safedialing","safe","cash","money","gold","diamond","jewel","bag","loot","bundle","stack","ingot"}
local GLASS_NAMES = {"window","glass","pane"}
local CAMERA_NAMES = {"camera","cctv","securitycam"}
local TRUCK_NAMES  = {"truck","van","armored"}

local function matchAny(name, words)
    name=name:lower()
    for _, w in ipairs(words) do if name:find(w, 1, true) then return true end end
    return false
end

local function getFolder(name)
    return Workspace:FindFirstChild(name)
end

----------------------------------------------------------------
-- cache (sweeping only known folders now)
----------------------------------------------------------------
local cache = { police={}, guards={}, npcs={}, loot={}, camera={}, truck={}, glass={}, prompts={} }

local function listFromFolder(folder)
    local t={}
    if not folder then return t end
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then table.insert(t, m) end
    end
    return t
end

local function sweep()
    cache.police = listFromFolder(getFolder("Police"))
    cache.guards = listFromFolder(getFolder("Guards"))
    cache.npcs   = listFromFolder(getFolder("Npcs"))

    cache.loot   = {}
    cache.camera = {}
    cache.truck  = {}
    cache.prompts= {}
    for _, m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") then
            local n=m.Name:lower()
            if matchAny(n, LOOT_NAMES)   then table.insert(cache.loot, m)
            elseif matchAny(n, CAMERA_NAMES) then table.insert(cache.camera, m)
            elseif matchAny(n, TRUCK_NAMES)  then table.insert(cache.truck, m)
            end
        elseif m:IsA("BasePart") then
            local n=m.Name:lower()
            if matchAny(n, LOOT_NAMES) then table.insert(cache.loot, m)
            elseif matchAny(n, GLASS_NAMES) then
                if cache.glass[m] == nil then cache.glass[m] = m.CanCollide end
            end
        elseif m:IsA("ProximityPrompt") then
            local p = m:FindFirstAncestorOfClass("Model") or m.Parent
            if p and matchAny(p.Name, LOOT_NAMES) then
                table.insert(cache.prompts, m)
            end
        end
    end
end

----------------------------------------------------------------
-- ESP (cached)
----------------------------------------------------------------
local espFolder=Instance.new("Folder", Workspace); espFolder.Name="__CRIM_ESP"
local espByInst = {}
local function ensureESP(inst, color, label)
    local rec = espByInst[inst]
    if rec and rec.hl.Parent then return rec end
    local h=Instance.new("Highlight")
    h.Adornee=inst; h.FillColor=color; h.OutlineColor=color
    h.FillTransparency=0.55; h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=espFolder
    local bb=Instance.new("BillboardGui")
    bb.Adornee=inst; bb.Size=UDim2.new(0,120,0,22)
    bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
    local tl=Instance.new("TextLabel", bb)
    tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1
    tl.Font=Enum.Font.GothamBold; tl.TextSize=13; tl.TextColor3=color
    tl.TextStrokeTransparency=0.4; tl.Text=label
    bb.Parent=espFolder
    rec = {hl=h, bb=bb}; espByInst[inst] = rec
    return rec
end
local function clearESP()
    for inst, rec in pairs(espByInst) do
        if rec.hl then rec.hl:Destroy() end
        if rec.bb then rec.bb:Destroy() end
    end
    espByInst = {}
    for _, c in ipairs(espFolder:GetChildren()) do c:Destroy() end
end
local function syncESP()
    local wanted = {}
    local function addList(list, color, label)
        for _, inst in ipairs(list) do
            if inst and inst.Parent then
                wanted[inst] = true; ensureESP(inst, color, label)
            end
        end
    end
    if S.PoliceESP then addList(cache.police, Color3.fromRGB(60,140,255), "POLICE") end
    if S.GuardESP  then addList(cache.guards, Color3.fromRGB(255,120,80), "GUARD") end
    if S.NpcESP    then addList(cache.npcs,   Color3.fromRGB(255,200,80), "NPC") end
    if S.LootESP   then addList(cache.loot,   Color3.fromRGB(255,220,70), "LOOT") end
    if S.CameraESP then addList(cache.camera, Color3.fromRGB(255,60,160), "CAM") end
    if S.TruckESP  then addList(cache.truck,  Color3.fromRGB(120,255,120), "TRUCK") end
    for inst, rec in pairs(espByInst) do
        if not wanted[inst] then
            if rec.hl then rec.hl:Destroy() end
            if rec.bb then rec.bb:Destroy() end
            espByInst[inst] = nil
        end
    end
    for _, c in ipairs(espFolder:GetChildren()) do if c.Name=="cone" then c:Destroy() end end
    if S.RedViewCones then
        for _, m in ipairs(cache.police) do
            local hr = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if hr then
                local cone=Instance.new("Part"); cone.Name="cone"
                cone.Shape=Enum.PartType.Cylinder
                cone.Size=Vector3.new(60,30,30); cone.Color=Color3.fromRGB(255,40,40)
                cone.Material=Enum.Material.ForceField; cone.Transparency=0.72
                cone.CanCollide=false; cone.Anchored=true
                cone.CFrame = hr.CFrame * CFrame.new(30,0,0) * CFrame.Angles(0,0,math.rad(90))
                cone.Parent=espFolder
            end
        end
    end
end

----------------------------------------------------------------
-- meters
----------------------------------------------------------------
local meterGui=Instance.new("Frame", gui)
meterGui.Size=UDim2.new(0,220,0,64); meterGui.Position=UDim2.new(1,-240,0,20)
meterGui.BackgroundColor3=Color3.fromRGB(14,16,22); meterGui.BorderSizePixel=0; meterGui.Visible=false
Instance.new("UICorner", meterGui).CornerRadius=UDim.new(0,10)
local detLbl=Instance.new("TextLabel", meterGui)
detLbl.BackgroundTransparency=1; detLbl.Size=UDim2.new(1,-16,0,24); detLbl.Position=UDim2.new(0,8,0,4)
detLbl.Font=Enum.Font.GothamBold; detLbl.TextSize=12; detLbl.TextXAlignment=Enum.TextXAlignment.Left
detLbl.TextColor3=Color3.fromRGB(255,80,80); detLbl.Text="DETECTION  0%"
local noiseLbl=Instance.new("TextLabel", meterGui)
noiseLbl.BackgroundTransparency=1; noiseLbl.Size=UDim2.new(1,-16,0,24); noiseLbl.Position=UDim2.new(0,8,0,32)
noiseLbl.Font=Enum.Font.GothamBold; noiseLbl.TextSize=12; noiseLbl.TextXAlignment=Enum.TextXAlignment.Left
noiseLbl.TextColor3=Color3.fromRGB(255,180,60); noiseLbl.Text="NOISE      0%"
local function updateMeters()
    meterGui.Visible = S.DetectionMeter or S.NoiseMeter
    detLbl.Visible=S.DetectionMeter; noiseLbl.Visible=S.NoiseMeter
    local r=hrp(); if not r then return end
    local pos=r.Position; local copD=math.huge
    for _, m in ipairs(cache.police) do
        local hr=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
        if hr then local d=(hr.Position-pos).Magnitude; if d<copD then copD=d end end
    end
    detLbl.Text = string.format("DETECTION  %d%%", math.clamp(100 - (copD/80*100), 0, 100))
    noiseLbl.Text = string.format("NOISE      %d%%", math.clamp(r.AssemblyLinearVelocity.Magnitude/30*100, 0, 100))
end

----------------------------------------------------------------
-- noclip glass
----------------------------------------------------------------
local function applyNoclip()
    if S.WindowsNoclip then
        for p, _ in pairs(cache.glass) do if p and p.Parent then p.CanCollide = false end end
    else
        for p, orig in pairs(cache.glass) do if p and p.Parent then p.CanCollide = orig end end
    end
end

----------------------------------------------------------------
-- anti-taser
----------------------------------------------------------------
local atTick = 0
local function tickAntiTaser(dt)
    if not S.AntiTaser then return end
    atTick = atTick + dt
    if atTick < 0.3 then return end
    atTick = 0
    local h=hum(); if not h then return end
    if h.PlatformStand then h.PlatformStand=false end
    local st=h:GetState()
    if st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
       or st==Enum.HumanoidStateType.Physics then
        h:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
end

----------------------------------------------------------------
-- stealth
----------------------------------------------------------------
local stealthRestore = {}
local function setStealth(on)
    local c=char(); if not c then return end
    if on then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then stealthRestore[p]=p.Transparency; p.Transparency=1
            elseif p:IsA("Decal") then stealthRestore[p]=p.Transparency; p.Transparency=1 end
        end
    else
        for inst, t in pairs(stealthRestore) do
            if inst and inst.Parent then inst.Transparency=t end
        end
        stealthRestore = {}
    end
end

----------------------------------------------------------------
-- fullbright
----------------------------------------------------------------
local lightingBackup
local function setFullbright(on)
    if on then
        lightingBackup = {
            Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
            Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
            FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart, GlobalShadows=Lighting.GlobalShadows,
        }
        Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
        Lighting.Brightness=2; Lighting.ClockTime=14
        Lighting.FogEnd=1e6; Lighting.FogStart=1e6; Lighting.GlobalShadows=false
    elseif lightingBackup then for k,v in pairs(lightingBackup) do Lighting[k]=v end end
end

----------------------------------------------------------------
-- movement
----------------------------------------------------------------
local baseSpeed = 16
local function tickMovement()
    local h=hum(); local r=hrp(); if not h or not r then return end
    if S.SpeedBoost then h.WalkSpeed = SPEED_VAL
    elseif h.WalkSpeed == SPEED_VAL then h.WalkSpeed = baseSpeed end
    if S.FallProtect then
        local v=r.AssemblyLinearVelocity
        if v.Y < -60 then r.AssemblyLinearVelocity = Vector3.new(v.X, -5, v.Z) end
    end
end

----------------------------------------------------------------
-- stamina (aggressive + disables draining scripts)
----------------------------------------------------------------
local function killStaminaScripts()
    local ps = LP:FindFirstChild("PlayerScripts")
    if not ps then return end
    for _, d in ipairs(ps:GetDescendants()) do
        if d:IsA("LocalScript") then
            local n = d.Name:lower()
            if n:find("stam") or n:find("sprint") or n:find("energy") then
                pcall(function() d.Disabled = true end)
            end
        end
    end
end
local staminaTick = 0
local function tickStamina(dt)
    if not S.InfStamina then return end
    staminaTick = staminaTick + dt
    if staminaTick < 0.1 then return end
    staminaTick = 0
    killStaminaScripts()
    local function pump(v)
        if (v:IsA("NumberValue") or v:IsA("IntValue")) then
            local n=v.Name:lower()
            if n:find("stam") or n:find("sprint") or n:find("energy") then
                v.Value = (v.MaxValue and v.MaxValue>0) and v.MaxValue or 100
            end
        end
    end
    for _, v in ipairs(LP:GetDescendants()) do pump(v) end
    local c=char()
    if c then
        for _, v in ipairs(c:GetDescendants()) do pump(v) end
        for k,_ in pairs(c:GetAttributes()) do
            local lk=k:lower()
            if lk:find("stam") or lk:find("sprint") or lk:find("energy") then c:SetAttribute(k, 100) end
        end
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then
            for k,_ in pairs(h:GetAttributes()) do
                local lk=k:lower()
                if lk:find("stam") or lk:find("sprint") or lk:find("energy") then h:SetAttribute(k, 100) end
            end
        end
    end
    for k,_ in pairs(LP:GetAttributes()) do
        local lk=k:lower()
        if lk:find("stam") or lk:find("sprint") or lk:find("energy") then LP:SetAttribute(k, 100) end
    end
end

----------------------------------------------------------------
-- loot ops
----------------------------------------------------------------
local function triggerOn(inst)
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ProximityPrompt") then pcall(fireproximityprompt, d, 1) end
        if d:IsA("ClickDetector") then pcall(fireclickdetector, d, 1, "MouseClick") end
    end
end
local function grabNearbyLoot()
    local r=hrp(); if not r then return end
    local pos=r.Position
    for _, m in ipairs(cache.loot) do
        if m and m.Parent then
            local p = m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) or m
            if p and (p.Position - pos).Magnitude < 22 then triggerOn(m) end
        end
    end
    for _, pp in ipairs(cache.prompts) do
        if pp and pp.Parent then
            local pt = pp.Parent
            local part = pt:IsA("BasePart") and pt or pt:FindFirstChildWhichIsA("BasePart")
            if part and (part.Position - pos).Magnitude < 22 then pcall(fireproximityprompt, pp, 1) end
        end
    end
end
local function bringLoot()
    local r=hrp(); if not r then return end
    local target = r.CFrame * CFrame.new(0, 2, -4)
    for _, m in ipairs(cache.loot) do
        if m and m.Parent then
            local primary = m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) or m
            if primary and (primary.Position - r.Position).Magnitude < 400 then
                pcall(function()
                    if not primary.Anchored then primary:SetNetworkOwner(LP) end
                    if m:IsA("Model") and m.PrimaryPart then m:PivotTo(target)
                    else primary.CFrame = target end
                    if primary:IsA("BasePart") then primary.AssemblyLinearVelocity = Vector3.new() end
                end)
            end
        end
    end
end
local function dropHeldLoot()
    local c=char(); if not c then return end
    local h=hum()
    for _, tool in ipairs(c:GetChildren()) do
        if tool:IsA("Tool") then
            if h then h:UnequipTools() end
            task.wait(0.05)
            tool.Parent = Workspace
            local part = tool:FindFirstChildWhichIsA("BasePart")
            if part and hrp() then part.CFrame = hrp().CFrame * CFrame.new(0, 0, -3) end
        end
    end
    pcall(function() VirtualUser:SetKeyDown("g"); task.wait(0.05); VirtualUser:SetKeyUp("g") end)
end

----------------------------------------------------------------
-- anti-afk
----------------------------------------------------------------
table.insert(CONN, LP.Idled:Connect(function()
    if not S.AntiAFK then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))

table.insert(CONN, RunService.Heartbeat:Connect(function(dt)
    tickMovement(); tickAntiTaser(dt); tickStamina(dt)
end))

task.spawn(function()
    while gui.Parent do
        local needScan =
            S.PoliceESP or S.GuardESP or S.NpcESP or S.LootESP or S.CameraESP or S.TruckESP
            or S.RedViewCones or S.DetectionMeter
            or S.WindowsNoclip or S.GrabNearbyLoot or S.BringLoot
        if needScan then
            sweep()
            syncESP()
            applyNoclip()
            if S.GrabNearbyLoot then grabNearbyLoot() end
            if S.BringLoot then bringLoot() end
        else
            clearESP()
        end
        updateMeters()
        task.wait(SCAN_INTERVAL)
    end
end)

----------------------------------------------------------------
-- UI mount
----------------------------------------------------------------
makeToggle("Police ESP",       "PoliceESP")
makeToggle("Guard ESP",        "GuardESP")
makeToggle("NPC ESP",          "NpcESP")
makeToggle("Loot ESP",         "LootESP")
makeToggle("Camera ESP",       "CameraESP")
makeToggle("Truck ESP",        "TruckESP")
makeToggle("Red View Cones",   "RedViewCones")
makeToggle("Detection Meter",  "DetectionMeter")
makeToggle("Noise Meter",      "NoiseMeter")
makeToggle("Windows Noclip",   "WindowsNoclip", function(v) if not v then applyNoclip() end end)
makeToggle("Anti Taser",       "AntiTaser")
makeToggle("Stealth Mode",     "StealthMode", function(v) setStealth(v) end)
makeToggle("Speed Boost",      "SpeedBoost")
makeToggle("Inf Stamina",      "InfStamina")
makeToggle("Fall Protection",  "FallProtect")
makeToggle("Fullbright",       "Fullbright", function(v) setFullbright(v) end)
makeToggle("Anti AFK",         "AntiAFK")
makeToggle("Grab Nearby Loot", "GrabNearbyLoot")
makeToggle("Bring Loot",       "BringLoot")
makeAction("Drop Held Loot", dropHeldLoot)
makeAction("Grab Target Under Cursor", function()
    local t = Mouse.Target
    if t then triggerOn(t:FindFirstAncestorOfClass("Model") or t) end
end)
makeAction("Teleport To Nearest Loot", function()
    local r=hrp(); if not r then return end
    sweep()
    local best, bestD = nil, math.huge
    for _, m in ipairs(cache.loot) do
        local p = m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) or m
        if p then local d=(p.Position-r.Position).Magnitude; if d<bestD then bestD=d; best=p end end
    end
    if best then r.CFrame = best.CFrame * CFrame.new(0, 3, 2) end
end)
makeAction("Diagnose Stamina (printout)", function()
    print("--- Player children ---")
    for _,v in ipairs(LP:GetChildren()) do print(v.ClassName, v.Name) end
    print("--- Player attributes ---")
    for k,v in pairs(LP:GetAttributes()) do print("attr", k, v) end
    local c=char()
    if c then
        print("--- Char attributes ---")
        for k,v in pairs(c:GetAttributes()) do print("cattr", k, v) end
    end
    print("--- Stamina-like values ---")
    for _,d in ipairs(game:GetDescendants()) do
        if d:IsA("NumberValue") or d:IsA("IntValue") then
            local n=d.Name:lower()
            if n:find("stam") or n:find("sprint") or n:find("energy") then
                print("val", d:GetFullName(), "=", d.Value)
            end
        end
    end
    print("--- PlayerScripts stamina ---")
    local ps=LP:FindFirstChild("PlayerScripts")
    if ps then
        for _,d in ipairs(ps:GetDescendants()) do
            if d:IsA("LocalScript") or d:IsA("ModuleScript") then
                local n=d.Name:lower()
                if n:find("stam") or n:find("sprint") or n:find("energy") then print("script", d:GetFullName()) end
            end
        end
    end
    print("--- done ---")
end)

table.insert(CONN, LP.CharacterAdded:Connect(function(c)
    stealthRestore = {}
    for k in pairs(cache.glass) do cache.glass[k] = nil end
    local h=c:WaitForChild("Humanoid", 5); if h then baseSpeed = h.WalkSpeed end
    task.wait(1)
    if S.StealthMode then setStealth(true) end
    if S.Fullbright then setFullbright(true) end
end))

if hum() then baseSpeed = hum().WalkSpeed end
print("[crim_sim v4] loaded — press Insert")
