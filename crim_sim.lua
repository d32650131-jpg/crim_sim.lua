-- crim_sim.lua  v2 — Criminal Simulator menu, executor payload
-- loader:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/d32650131-jpg/fpv/main/crim_sim.lua", true))()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService      = game:GetService("TweenService")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse  = LP:GetMouse()

----------------------------------------------------------------
-- state
----------------------------------------------------------------
local S = {
    PoliceESP=false, NpcESP=false, LootESP=false, CameraESP=false, TruckESP=false,
    RedViewCones=false, DetectionMeter=false, NoiseMeter=false,
    WindowsNoclip=false, AntiTaser=false, StealthMode=false,
    SpeedBoost=false, InfStamina=false, FallProtect=false,
    Fullbright=false, AntiAFK=true,
    GrabNearbyLoot=false, BringLoot=false,
}
local SPEED_VAL = 50

----------------------------------------------------------------
-- cleanup previous session
----------------------------------------------------------------
if getgenv().__CRIM_SIM_GUI then pcall(function() getgenv().__CRIM_SIM_GUI:Destroy() end) end
if getgenv().__CRIM_SIM_CONN then
    for _, c in ipairs(getgenv().__CRIM_SIM_CONN) do pcall(function() c:Disconnect() end) end
end
getgenv().__CRIM_SIM_CONN = {}
local CONN = getgenv().__CRIM_SIM_CONN
for _, c in ipairs(Workspace:GetChildren()) do if c.Name=="__CRIM_ESP" then c:Destroy() end end

----------------------------------------------------------------
-- gui
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name="CrimSim"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent = gethui and gethui() or game:GetService("CoreGui")
getgenv().__CRIM_SIM_GUI = gui

local root = Instance.new("Frame", gui)
root.Size=UDim2.new(0,360,0,540); root.Position=UDim2.new(0,60,0.5,-270)
root.BackgroundColor3=Color3.fromRGB(14,16,22); root.BorderSizePixel=0
root.Active=true; root.Draggable=true
Instance.new("UICorner", root).CornerRadius=UDim.new(0,12)
local stroke=Instance.new("UIStroke", root); stroke.Color=Color3.fromRGB(40,44,58)

local header=Instance.new("Frame", root)
header.Size=UDim2.new(1,0,0,44); header.BackgroundColor3=Color3.fromRGB(20,23,32); header.BorderSizePixel=0
Instance.new("UICorner", header).CornerRadius=UDim.new(0,12)
local title=Instance.new("TextLabel", header)
title.BackgroundTransparency=1; title.Size=UDim2.new(1,-20,1,0); title.Position=UDim2.new(0,14,0,0)
title.Font=Enum.Font.GothamBold; title.TextSize=15; title.TextColor3=Color3.fromRGB(235,235,245)
title.TextXAlignment=Enum.TextXAlignment.Left; title.Text="CRIM SIM   ·   [Insert] toggle"

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
    sw.MouseButton1Click:Connect(function()
        S[key]=not S[key]; render(); if cb then pcall(cb, S[key]) end
    end)
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

----------------------------------------------------------------
-- cursor + Insert toggle
----------------------------------------------------------------
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
-- char helpers
----------------------------------------------------------------
local function char() return LP.Character end
local function hrp() local c=char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c=char(); return c and c:FindFirstChildOfClass("Humanoid") end

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------
local espFolder=Instance.new("Folder", Workspace); espFolder.Name="__CRIM_ESP"

local function clearESPFor(key)
    for _, m in ipairs(espFolder:GetChildren()) do if m.Name==key then m:Destroy() end end
end
local function makeHL(adornee, color, key)
    local h=Instance.new("Highlight")
    h.Name=key; h.Adornee=adornee; h.FillColor=color; h.OutlineColor=color
    h.FillTransparency=0.55; h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=espFolder
end
local function makeTag(adornee, text, color, key)
    local bb=Instance.new("BillboardGui")
    bb.Name=key; bb.Adornee=adornee; bb.Size=UDim2.new(0,120,0,22)
    bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
    local tl=Instance.new("TextLabel", bb)
    tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1
    tl.Font=Enum.Font.GothamBold; tl.TextSize=13; tl.TextColor3=color
    tl.TextStrokeTransparency=0.4; tl.Text=text
    bb.Parent=espFolder
end

local function matchAny(name, words)
    name=name:lower()
    for _, w in ipairs(words) do if name:find(w) then return true end end
    return false
end
local POLICE={"police","cop","officer","swat","guard","sheriff"}
local CAMERA={"camera","cctv","securitycam"}
local TRUCK ={"truck","van","armored","armoredtruck","moneytruck"}
local LOOT  ={"loot","cash","money","gold","jewel","diamond","safe","bag","dufflebag","ingot","stack","bundle"}

local function scanESP()
    clearESPFor("police"); clearESPFor("npc"); clearESPFor("camera")
    clearESPFor("truck");  clearESPFor("loot"); clearESPFor("cone")
    if not (S.PoliceESP or S.NpcESP or S.LootESP or S.CameraESP or S.TruckESP or S.RedViewCones) then return end

    for _, m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") and m~=char() then
            local h=m:FindFirstChildOfClass("Humanoid")
            if h then
                if S.PoliceESP and matchAny(m.Name, POLICE) then
                    makeHL(m, Color3.fromRGB(60,140,255), "police")
                    makeTag(m:FindFirstChild("Head") or m, "POLICE", Color3.fromRGB(60,140,255), "police")
                    if S.RedViewCones then
                        local hr=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
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
                elseif S.NpcESP and not Players:GetPlayerFromCharacter(m) then
                    makeHL(m, Color3.fromRGB(255,200,80), "npc")
                end
            end
            if S.CameraESP and matchAny(m.Name, CAMERA) then
                makeHL(m, Color3.fromRGB(255,60,160), "camera")
                makeTag(m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart") or m, "CAM", Color3.fromRGB(255,60,160), "camera")
            end
            if S.TruckESP and matchAny(m.Name, TRUCK) then
                makeHL(m, Color3.fromRGB(120,255,120), "truck")
                makeTag(m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart") or m, "TRUCK", Color3.fromRGB(120,255,120), "truck")
            end
            if S.LootESP and matchAny(m.Name, LOOT) then
                makeHL(m, Color3.fromRGB(255,220,70), "loot")
                makeTag(m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart") or m, "LOOT", Color3.fromRGB(255,220,70), "loot")
            end
        elseif m:IsA("BasePart") and matchAny(m.Name, LOOT) and S.LootESP then
            makeHL(m, Color3.fromRGB(255,220,70), "loot")
            makeTag(m, "LOOT", Color3.fromRGB(255,220,70), "loot")
        end
    end
end
task.spawn(function() while gui.Parent do scanESP(); task.wait(1.2) end end)

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
    for _, m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") and matchAny(m.Name, POLICE) then
            local hr=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if hr then local d=(hr.Position-pos).Magnitude; if d<copD then copD=d end end
        end
    end
    local detect = math.clamp(100 - (copD/80*100), 0, 100)
    detLbl.Text = string.format("DETECTION  %d%%", detect)
    local hv = r.AssemblyLinearVelocity.Magnitude
    noiseLbl.Text = string.format("NOISE      %d%%", math.clamp(hv/30*100, 0, 100))
end

----------------------------------------------------------------
-- noclip (windows/glass only)
----------------------------------------------------------------
local noclipRestore = {}
local function tickNoclip()
    if not S.WindowsNoclip then
        for p, v in pairs(noclipRestore) do if p and p.Parent then p.CanCollide = v end end
        noclipRestore = {}
        return
    end
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("BasePart") and matchAny(p.Name, {"window","glass","pane"}) then
            if noclipRestore[p]==nil then noclipRestore[p]=p.CanCollide end
            if p.CanCollide then p.CanCollide=false end
        end
    end
end

----------------------------------------------------------------
-- anti-taser (clears ragdoll/stun welds + forced state)
----------------------------------------------------------------
local function tickAntiTaser()
    if not S.AntiTaser then return end
    local c=char(); local h=hum(); if not c or not h then return end
    for _, v in ipairs(c:GetDescendants()) do
        local n=v.Name:lower()
        if n:find("taser") or n:find("stun") or n:find("shock") or n:find("ragdoll") or n:find("tazed") then
            if v:IsA("BoolValue") then v.Value=false
            elseif v:IsA("NumberValue") then v.Value=0
            elseif v:IsA("Weld") or v:IsA("Motor6D")==false and v:IsA("Attachment")==false then
                pcall(function() v:Destroy() end)
            end
        end
    end
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
-- stealth: invisibility + break cop line of sight
----------------------------------------------------------------
local stealthRestore = {}
local function setStealth(on)
    local c=char(); if not c then return end
    if on then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                stealthRestore[p]=p.Transparency; p.Transparency=1
            elseif p:IsA("Decal") then
                stealthRestore[p]=p.Transparency; p.Transparency=1
            end
        end
        local n = c:FindFirstChild("Name") or c:FindFirstChild("Overhead")
        if n and n:FindFirstChildWhichIsA("TextLabel") then n:FindFirstChildWhichIsA("TextLabel").TextTransparency=1 end
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
            FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart,
            GlobalShadows=Lighting.GlobalShadows,
        }
        Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
        Lighting.Brightness=2; Lighting.ClockTime=14
        Lighting.FogEnd=1e6; Lighting.FogStart=1e6; Lighting.GlobalShadows=false
    elseif lightingBackup then
        for k,v in pairs(lightingBackup) do Lighting[k]=v end
    end
end

----------------------------------------------------------------
-- speed + stamina + fall
----------------------------------------------------------------
local baseSpeed = 16
local function tickMovement()
    local h=hum(); local r=hrp(); if not h or not r then return end
    if S.SpeedBoost then
        h.WalkSpeed = SPEED_VAL
    else
        if h.WalkSpeed == SPEED_VAL then h.WalkSpeed = baseSpeed end
    end
    if S.InfStamina then
        for _, v in ipairs(LP:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stamina") then
                v.Value = v.MaxValue>0 and v.MaxValue or 100
            end
        end
        for _, v in ipairs((char() or Instance.new("Model")):GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stamina") then
                v.Value = v.MaxValue>0 and v.MaxValue or 100
            end
        end
        local att = char() and char():GetAttribute("Stamina")
        if att ~= nil then char():SetAttribute("Stamina", 100) end
    end
    if S.FallProtect then
        local v=r.AssemblyLinearVelocity
        if v.Y < -60 then
            r.AssemblyLinearVelocity = Vector3.new(v.X, -5, v.Z)
        end
    end
end

----------------------------------------------------------------
-- LOOT GRAB: ProximityPrompt + ClickDetector trigger
----------------------------------------------------------------
local function isLootThing(inst)
    local m = inst:IsA("Model") and inst or inst:FindFirstAncestorOfClass("Model")
    if m and matchAny(m.Name, LOOT) then return true end
    if inst:IsA("BasePart") and matchAny(inst.Name, LOOT) then return true end
    return false
end

local function triggerPromptsAndClicks(inst)
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(d, 1) end)
        elseif d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d, 1, "MouseClick") end)
            pcall(function() fireclickdetector(d) end)
        end
    end
end

local function grabTarget(target)
    if not target then return end
    local parent = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model") or target
    triggerPromptsAndClicks(parent)
end

----------------------------------------------------------------
-- BringLoot: teleport unanchored loot to player, claim net ownership
----------------------------------------------------------------
local function tryClaimOwnership(part)
    pcall(function()
        if part:IsA("BasePart") and not part.Anchored then
            part:SetNetworkOwner(LP)
        end
    end)
end

local function bringLootTick()
    if not S.BringLoot then return end
    local r=hrp(); if not r then return end
    for _, m in ipairs(Workspace:GetDescendants()) do
        local isLoot = (m:IsA("Model") and matchAny(m.Name, LOOT))
                    or (m:IsA("BasePart") and matchAny(m.Name, LOOT))
        if isLoot then
            local primary = m:IsA("Model")
                and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart"))
                or m
            if primary and (primary.Position - r.Position).Magnitude < 400 then
                tryClaimOwnership(primary)
                if m:IsA("Model") then
                    pcall(function() m:PivotTo(r.CFrame * CFrame.new(0, 2, -4)) end)
                else
                    pcall(function()
                        if primary.Anchored then
                            primary.CFrame = r.CFrame * CFrame.new(0,2,-4)
                        else
                            primary.CFrame = r.CFrame * CFrame.new(0,2,-4)
                            primary.AssemblyLinearVelocity = Vector3.new()
                        end
                    end)
                end
            end
        end
    end
end

local function grabNearbyTick()
    if not S.GrabNearbyLoot then return end
    local r=hrp(); if not r then return end
    local pos=r.Position
    for _, m in ipairs(Workspace:GetDescendants()) do
        if isLootThing(m) then
            local p = m:IsA("Model")
                and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart"))
                or m
            if p and (p.Position - pos).Magnitude < 22 then
                grabTarget(m)
            end
        end
    end
    for _, p in ipairs(ProximityPromptService:GetChildren()) do end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local parent = d.Parent
            if parent and isLootThing(parent) then
                local pp = parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart")
                if pp and (pp.Position - pos).Magnitude < 22 then
                    pcall(function() fireproximityprompt(d, 1) end)
                end
            end
        end
    end
end

----------------------------------------------------------------
-- drop held loot (keyboard G + triggers held tool drop)
----------------------------------------------------------------
local function dropHeldLoot()
    local c=char(); if not c then return end
    for _, tool in ipairs(c:GetChildren()) do
        if tool:IsA("Tool") then
            local h = hum(); if h then h:UnequipTools() end
            if LP.Backpack then tool.Parent = LP.Backpack end
            task.wait(0.05)
            tool.Parent = Workspace
            local part = tool:FindFirstChildWhichIsA("BasePart")
            if part and hrp() then part.CFrame = hrp().CFrame * CFrame.new(0, 0, -3) end
        end
    end
    pcall(function() VirtualUser:SetKeyDown("g") task.wait(0.05) VirtualUser:SetKeyUp("g") end)
end

----------------------------------------------------------------
-- anti-afk
----------------------------------------------------------------
table.insert(CONN, LP.Idled:Connect(function()
    if not S.AntiAFK then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))

----------------------------------------------------------------
-- main loop
----------------------------------------------------------------
table.insert(CONN, RunService.Heartbeat:Connect(function()
    updateMeters()
    tickNoclip()
    tickAntiTaser()
    tickMovement()
end))

task.spawn(function()
    while gui.Parent do
        grabNearbyTick()
        bringLootTick()
        task.wait(0.35)
    end
end)

----------------------------------------------------------------
-- mount toggles + actions
----------------------------------------------------------------
makeToggle("Police ESP",       "PoliceESP")
makeToggle("NPC ESP",          "NpcESP")
makeToggle("Loot ESP",         "LootESP")
makeToggle("Camera ESP",       "CameraESP")
makeToggle("Truck ESP",        "TruckESP")
makeToggle("Red View Cones",   "RedViewCones")
makeToggle("Detection Meter",  "DetectionMeter")
makeToggle("Noise Meter",      "NoiseMeter")

makeToggle("Windows Noclip",   "WindowsNoclip")
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
    if t then grabTarget(t) end
end)
makeAction("Teleport To Nearest Loot", function()
    local r=hrp(); if not r then return end
    local best, bestD = nil, math.huge
    for _, m in ipairs(Workspace:GetDescendants()) do
        if isLootThing(m) then
            local p = m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) or m
            if p then
                local d=(p.Position-r.Position).Magnitude
                if d<bestD then bestD=d; best=p end
            end
        end
    end
    if best then r.CFrame = best.CFrame * CFrame.new(0, 3, 2) end
end)

----------------------------------------------------------------
-- character respawn hooks
----------------------------------------------------------------
table.insert(CONN, LP.CharacterAdded:Connect(function(c)
    stealthRestore = {}; noclipRestore = {}
    local h=c:WaitForChild("Humanoid", 5); if h then baseSpeed = h.WalkSpeed end
    task.wait(1)
    if S.StealthMode then setStealth(true) end
    if S.Fullbright then setFullbright(true) end
end))

if hum() then baseSpeed = hum().WalkSpeed end
print("[crim_sim v2] loaded — press Insert")
