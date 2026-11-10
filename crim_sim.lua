-- crim_sim.lua  v7 — __namecall anticheat silencer + anti-kick + rubberband-rollback + velocity speed
-- loader:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/d32650131-jpg/crim_sim.lua/main/crim_sim.lua", true))()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse  = LP:GetMouse()

local S = {
    PoliceESP=false, GuardESP=false, NpcESP=false, LootESP=false, CameraESP=false, TruckESP=false,
    RedViewCones=false, DetectionMeter=false, NoiseMeter=false,
    WindowsNoclip=false, AntiTaser=false, StealthMode=false,
    SpeedBoost=false, InfStamina=false, FallProtect=false,
    Fullbright=false, AntiAFK=true,
    GrabNearbyLoot=false, BringLoot=false,
    -- bypass defaults
    AntiCheatBlock=false, AntiKick=true, AntiRubberband=false, SilentWarnings=true,
}

local SPEED_VAL = 28
local SPEED_MIN, SPEED_MAX = 16, 100
local ESP_UPDATE_RATE = 0.5
local ESP_MAX_DIST    = 1500
local GRAB_RADIUS     = 22
local BRING_RADIUS    = 400

----------------------------------------------------------------
-- cleanup prior
----------------------------------------------------------------
if getgenv().__CRIM_SIM_GUI then pcall(function() getgenv().__CRIM_SIM_GUI:Destroy() end) end
if getgenv().__CRIM_SIM_CONN then
    for _, c in ipairs(getgenv().__CRIM_SIM_CONN) do pcall(function() c:Disconnect() end) end
end
if getgenv().__CRIM_SIM_RESTORE then pcall(getgenv().__CRIM_SIM_RESTORE) end
getgenv().__CRIM_SIM_CONN = {}
local CONN = getgenv().__CRIM_SIM_CONN
for _, c in ipairs(Workspace:GetChildren()) do if c.Name=="__CRIM_ESP" then c:Destroy() end end

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------
local function char() return LP.Character end
local function hrp() local c=char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c=char(); return c and c:FindFirstChildOfClass("Humanoid") end

local LOOT_NAMES   = {"cashbag","goldbar","safedialing","safe","cash","money","gold","diamond","jewel","bag","loot","bundle","stack","ingot"}
local GLASS_NAMES  = {"window","glass","pane"}
local CAMERA_NAMES = {"camera","cctv","securitycam"}
local TRUCK_NAMES  = {"truck","van","armored"}
local TASER_NAMES  = {"taser","stun","shock","tazed","ragdoll"}

-- narrow anticheat blocklist — only compound anticheat-specific tokens
-- won't catch Checkpoint, SprintCheck, TrustFund, BanAnna, AuditLog, etc.
local AC_BLOCK = {
    "anticheat","antiexploit","exploitdetect","exploitreport",
    "reportexploit","reportcheater","reportclient","reportplayer",
    "detectexploit","detectcheat","cheatdetect",
    "flagexploit","flagcheater",
    "antifly","antinoclip","antiteleport","antispeed",
    "walkspeedcheck","speedhackcheck","flycheck","noclipcheck","teleportcheck",
    "validateposition","validatespeed","positionvalidate","speedvalidate",
    "kickplayer","kickexploit","forcekick","banexploit","banplayer",
    "sendtelemetry","exploittelemetry","securityreport","securityevent",
    "gameguard","watchdogreport",
}

local function matchAny(nameLower, words)
    for _, w in ipairs(words) do if nameLower:find(w, 1, true) then return true end end
    return false
end

----------------------------------------------------------------
-- GUI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name="CrimSim"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent = gethui and gethui() or game:GetService("CoreGui")
getgenv().__CRIM_SIM_GUI = gui

local root = Instance.new("Frame", gui)
root.Size=UDim2.new(0,360,0,620); root.Position=UDim2.new(0,60,0.5,-310)
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
title.TextXAlignment=Enum.TextXAlignment.Left; title.Text="CRIM SIM v7   ·   [Insert] toggle"

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
local function makeSlider(labelText, minV, maxV, defV, onChange)
    local row=Instance.new("Frame", scroll)
    row.Size=UDim2.new(1,-8,0,46); row.BackgroundColor3=Color3.fromRGB(22,25,34); row.BorderSizePixel=0
    Instance.new("UICorner", row).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel", row)
    lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-20,0,20); lbl.Position=UDim2.new(0,12,0,2)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextColor3=Color3.fromRGB(215,218,228)
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text = string.format("%s: %d", labelText, defV)
    local track=Instance.new("Frame", row)
    track.Size=UDim2.new(1,-24,0,8); track.Position=UDim2.new(0,12,0,28)
    track.BackgroundColor3=Color3.fromRGB(45,50,62); track.BorderSizePixel=0
    Instance.new("UICorner", track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame", track)
    fill.BackgroundColor3=Color3.fromRGB(70,150,255); fill.BorderSizePixel=0
    fill.Size=UDim2.new((defV-minV)/(maxV-minV), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton", track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3=Color3.fromRGB(235,235,245); knob.AutoButtonColor=false; knob.Text=""
    Instance.new("UICorner", knob).CornerRadius=UDim.new(1,0)
    local dragging=false
    local function setFromX(x)
        local abs = track.AbsolutePosition.X
        local w   = track.AbsoluteSize.X
        local a   = math.clamp((x-abs)/w, 0, 1)
        local val = math.floor(minV + (maxV-minV)*a + 0.5)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        lbl.Text = string.format("%s: %d", labelText, val)
        if onChange then pcall(onChange, val) end
    end
    knob.MouseButton1Down:Connect(function() dragging=true end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
end

local function applyCursor()
    UserInputService.MouseIconEnabled = root.Visible
    UserInputService.ModalEnabled     = root.Visible
end
applyCursor()
table.insert(CONN, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.End then
        root.Visible = not root.Visible; applyCursor()
    end
end))

----------------------------------------------------------------
-- __namecall hook (only active when AntiCheatBlock/AntiKick on)
----------------------------------------------------------------
local _hookmm = hookmetamethod or (getgenv and getgenv().hookmetamethod)
local _getnc  = getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
local _check  = checkcaller or function() return false end

local origNamecall
if _hookmm then
    origNamecall = _hookmm(game, "__namecall", function(self, ...)
        local method = _getnc and _getnc() or ""
        if not _check() then
            if S.AntiCheatBlock and (method == "FireServer" or method == "InvokeServer") then
                local okN, n = pcall(function() return self.Name:lower() end)
                local okF, f = pcall(function() return self:GetFullName():lower() end)
                if okN then
                    for _, w in ipairs(AC_BLOCK) do
                        if n:find(w, 1, true) or (okF and f:find(w, 1, true)) then
                            if method == "InvokeServer" then return nil end
                            return
                        end
                    end
                end
            end
            if S.AntiKick and method == "Kick" then
                return
            end
        end
        return origNamecall(self, ...)
    end)
end

-- neuter LocalPlayer.Kick via raw metatable
pcall(function()
    local mt = getrawmetatable(LP)
    if mt then
        setreadonly(mt, false)
        local origIndex = mt.__index
        mt.__index = function(t, k)
            if k == "Kick" and S.AntiKick then
                return function() end
            end
            return origIndex(t, k)
        end
        setreadonly(mt, true)
    end
end)

-- silence server notification popups
pcall(function()
    local origSet
    origSet = hookfunction(StarterGui.SetCore, function(self, kind, ...)
        if S.SilentWarnings and (kind == "SendNotification" or kind == "ChatMakeSystemMessage") then
            return
        end
        return origSet(self, kind, ...)
    end)
end)

-- strip kick-popup GUIs the server pushes
local function nukeKickGuis()
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    for _, g in ipairs(pg:GetChildren()) do
        local n = g.Name:lower()
        if n:find("kick") or n:find("ban") or n:find("exploit") or n:find("anticheat") or n:find("detect") then
            if S.SilentWarnings then pcall(function() g:Destroy() end) end
        end
    end
end
table.insert(CONN, LP:WaitForChild("PlayerGui").ChildAdded:Connect(function(c)
    task.wait()
    if S.SilentWarnings then
        local n = c.Name:lower()
        if n:find("kick") or n:find("ban") or n:find("exploit") or n:find("anticheat") or n:find("detect") then
            pcall(function() c:Destroy() end)
        end
    end
end))

-- wipe client-side AC connections (on demand)
local function wipeACConnections()
    if not getconnections then return end
    local function scan(obj)
        for _, sig in ipairs({"DescendantAdded","ChildAdded","Heartbeat","Stepped","RenderStepped"}) do
            local ok, s = pcall(function() return obj[sig] end)
            if ok and typeof(s) == "RBXScriptSignal" then
                for _, con in ipairs(getconnections(s)) do
                    local f = con.Function or con.func
                    local name = ""
                    pcall(function() name = tostring(f):lower() end)
                    if name:find("anticheat") or name:find("detect") or name:find("exploit") or name:find("report") then
                        pcall(function() con:Disable() end)
                    end
                end
            end
        end
    end
    pcall(function() scan(RunService) end)
    pcall(function() scan(Workspace) end)
end

----------------------------------------------------------------
-- CACHE (event-driven)
----------------------------------------------------------------
local setPolice, setGuards, setNpcs = {}, {}, {}
local setLoot, setCamera, setTruck   = {}, {}, {}
local glassBackup                    = {}
local setPrompts                     = {}

local function inFolder(inst, folderName)
    local f = Workspace:FindFirstChild(folderName)
    if not f then return false end
    return inst:IsDescendantOf(f)
end
local function classify(inst)
    if inst:IsA("Model") then
        if inst:FindFirstChildOfClass("Humanoid") then
            if inFolder(inst, "Police") then setPolice[inst]=true; return end
            if inFolder(inst, "Guards") then setGuards[inst]=true; return end
            if inFolder(inst, "Npcs")   then setNpcs[inst]=true;  return end
        end
        local n = inst.Name:lower()
        if matchAny(n, LOOT_NAMES)       then setLoot[inst]=true
        elseif matchAny(n, CAMERA_NAMES) then setCamera[inst]=true
        elseif matchAny(n, TRUCK_NAMES)  then setTruck[inst]=true
        end
    elseif inst:IsA("BasePart") then
        local n = inst.Name:lower()
        if matchAny(n, LOOT_NAMES) then setLoot[inst]=true
        elseif matchAny(n, GLASS_NAMES) then
            if glassBackup[inst]==nil then glassBackup[inst] = inst.CanCollide end
        end
    elseif inst:IsA("ProximityPrompt") then
        local p = inst:FindFirstAncestorOfClass("Model") or inst.Parent
        if p and matchAny(p.Name:lower(), LOOT_NAMES) then setPrompts[inst]=true end
    end
end
local function unclassify(inst)
    setPolice[inst]=nil; setGuards[inst]=nil; setNpcs[inst]=nil
    setLoot[inst]=nil;   setCamera[inst]=nil; setTruck[inst]=nil
    setPrompts[inst]=nil
    if glassBackup[inst]~=nil then
        pcall(function() if inst and inst.Parent then inst.CanCollide = glassBackup[inst] end end)
        glassBackup[inst] = nil
    end
end
local function initialWalk()
    local i = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        classify(d); i = i + 1
        if i % 800 == 0 then task.wait() end
    end
end
table.insert(CONN, Workspace.DescendantAdded:Connect(function(d) classify(d) end))
table.insert(CONN, Workspace.DescendantRemoving:Connect(function(d) unclassify(d) end))

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------
local espFolder=Instance.new("Folder", Workspace); espFolder.Name="__CRIM_ESP"
local espByInst = {}
local function getPrimary(inst)
    if inst:IsA("Model") then return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart") end
    if inst:IsA("BasePart") then return inst end
end
local function addHL(inst, color, label)
    if espByInst[inst] and espByInst[inst].hl.Parent then return end
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
    espByInst[inst] = {hl=h, bb=bb}
end
local function removeHL(inst)
    local rec = espByInst[inst]
    if rec then
        if rec.hl then rec.hl:Destroy() end
        if rec.bb then rec.bb:Destroy() end
        espByInst[inst] = nil
    end
end
local function removeAllHL()
    for inst, _ in pairs(espByInst) do removeHL(inst) end
    for _, c in ipairs(espFolder:GetChildren()) do c:Destroy() end
end
local function syncESP()
    local wanted = {}
    local pos = (hrp() and hrp().Position) or Vector3.new()
    local function addSet(set, color, label, enabled)
        if not enabled then return end
        for inst, _ in pairs(set) do
            if inst and inst.Parent then
                local p = getPrimary(inst)
                if p and (p.Position - pos).Magnitude <= ESP_MAX_DIST then
                    wanted[inst] = true; addHL(inst, color, label)
                end
            end
        end
    end
    addSet(setPolice, Color3.fromRGB(60,140,255), "POLICE", S.PoliceESP)
    addSet(setGuards, Color3.fromRGB(255,120,80), "GUARD",  S.GuardESP)
    addSet(setNpcs,   Color3.fromRGB(255,200,80), "NPC",    S.NpcESP)
    addSet(setLoot,   Color3.fromRGB(255,220,70), "LOOT",   S.LootESP)
    addSet(setCamera, Color3.fromRGB(255,60,160), "CAM",    S.CameraESP)
    addSet(setTruck,  Color3.fromRGB(120,255,120),"TRUCK",  S.TruckESP)
    for inst, _ in pairs(espByInst) do
        if not wanted[inst] then removeHL(inst) end
    end
    for _, c in ipairs(espFolder:GetChildren()) do if c.Name=="cone" then c:Destroy() end end
    if S.RedViewCones then
        for m, _ in pairs(setPolice) do
            local hr=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if hr and (hr.Position - pos).Magnitude <= ESP_MAX_DIST then
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
    for m, _ in pairs(setPolice) do
        local hr=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
        if hr then local d=(hr.Position-pos).Magnitude; if d<copD then copD=d end end
    end
    detLbl.Text = string.format("DETECTION  %d%%", math.clamp(100 - (copD/80*100), 0, 100))
    noiseLbl.Text = string.format("NOISE      %d%%", math.clamp(r.AssemblyLinearVelocity.Magnitude/30*100, 0, 100))
end

----------------------------------------------------------------
-- windows noclip
----------------------------------------------------------------
local noclipOn = false
local function applyNoclip()
    if S.WindowsNoclip then
        for p, _ in pairs(glassBackup) do
            if p and p.Parent and p.CanCollide then p.CanCollide = false end
        end
        noclipOn = true
    elseif noclipOn then
        for p, orig in pairs(glassBackup) do
            if p and p.Parent then p.CanCollide = orig end
        end
        noclipOn = false
    end
end

----------------------------------------------------------------
-- anti-taser
----------------------------------------------------------------
local atTick = 0
local function tickAntiTaser(dt)
    if not S.AntiTaser then return end
    atTick = atTick + dt
    if atTick < 0.25 then return end
    atTick = 0
    local c = char(); local h = hum(); if not c or not h then return end
    if h.PlatformStand then h.PlatformStand=false end
    local st=h:GetState()
    if st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
       or st==Enum.HumanoidStateType.Physics then
        h:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    for _, v in ipairs(c:GetChildren()) do
        local n = v.Name:lower()
        if matchAny(n, TASER_NAMES) then
            if v:IsA("BoolValue") then v.Value=false
            elseif v:IsA("NumberValue") then v.Value=0
            else pcall(function() v:Destroy() end) end
        end
    end
end

----------------------------------------------------------------
-- stealth + fullbright
----------------------------------------------------------------
local stealthRestore = {}
local function setStealth(on)
    local c=char(); if not c then return end
    if on then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                if stealthRestore[p]==nil then stealthRestore[p]=p.Transparency end
                p.Transparency=1
            elseif p:IsA("Decal") then
                if stealthRestore[p]==nil then stealthRestore[p]=p.Transparency end
                p.Transparency=1
            end
        end
    else
        for inst, t in pairs(stealthRestore) do
            if inst and inst.Parent then inst.Transparency=t end
        end
        stealthRestore = {}
    end
end
local lightingBackup
local function setFullbright(on)
    if on then
        if not lightingBackup then
            lightingBackup = {
                Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
                Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
                FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart, GlobalShadows=Lighting.GlobalShadows,
            }
        end
        Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
        Lighting.Brightness=2; Lighting.ClockTime=14
        Lighting.FogEnd=1e6; Lighting.FogStart=1e6; Lighting.GlobalShadows=false
    elseif lightingBackup then
        for k,v in pairs(lightingBackup) do Lighting[k]=v end
        lightingBackup = nil
    end
end

----------------------------------------------------------------
-- velocity speed (walkspeed stays at base)
----------------------------------------------------------------
local baseSpeed = 16
local function applySpeedEveryFrame()
    if not S.SpeedBoost then return end
    local h = hum(); local r = hrp(); if not h or not r then return end
    local move = h.MoveDirection
    if move.Magnitude < 0.05 then return end
    local v = r.AssemblyLinearVelocity
    local horizontal = move * SPEED_VAL
    r.AssemblyLinearVelocity = Vector3.new(horizontal.X, v.Y, horizontal.Z)
end
local function tickMovement(dt)
    local h=hum(); local r=hrp(); if not h or not r then return end
    applySpeedEveryFrame()
    if S.FallProtect then
        local v=r.AssemblyLinearVelocity
        if v.Y < -60 then r.AssemblyLinearVelocity = Vector3.new(v.X, -5, v.Z) end
    end
end

----------------------------------------------------------------
-- anti-rubberband
----------------------------------------------------------------
local arHistory = {}
local function tickAntiRubberband(dt)
    if not S.AntiRubberband then return end
    local r=hrp(); if not r then return end
    local now = tick()
    table.insert(arHistory, {t=now, p=r.Position})
    while #arHistory > 0 and now - arHistory[1].t > 0.8 do
        table.remove(arHistory, 1)
    end
    if #arHistory >= 4 then
        local recent = arHistory[#arHistory - 1]
        local backShift = (recent.p - r.Position)
        if backShift.Magnitude > 12 then
            r.CFrame = CFrame.new(recent.p)
        end
    end
end

----------------------------------------------------------------
-- stamina
----------------------------------------------------------------
local staminaConns = {}
local function isStaminaName(n) n=n:lower(); return n:find("stam") or n:find("energy") end
local function hookStaminaValue(v)
    if staminaConns[v] then return end
    if not (v:IsA("NumberValue") or v:IsA("IntValue")) then return end
    if not isStaminaName(v.Name) then return end
    local max = (v.MaxValue and v.MaxValue > 0) and v.MaxValue or 100
    v.Value = max
    staminaConns[v] = v:GetPropertyChangedSignal("Value"):Connect(function()
        if S.InfStamina then v.Value = max end
    end)
end
local function unhookAllStamina()
    for v, c in pairs(staminaConns) do pcall(function() c:Disconnect() end); staminaConns[v]=nil end
end
local staminaTick = 0
local function tickStamina(dt)
    if not S.InfStamina then return end
    staminaTick = staminaTick + dt
    if staminaTick < 0.5 then return end
    staminaTick = 0
    for _, v in ipairs(LP:GetDescendants()) do hookStaminaValue(v) end
    local c = char()
    if c then
        for _, v in ipairs(c:GetDescendants()) do hookStaminaValue(v) end
        for k,_ in pairs(c:GetAttributes()) do
            local lk=k:lower()
            if lk:find("stam") or lk:find("energy") then c:SetAttribute(k, 100) end
        end
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then
            for k,_ in pairs(h:GetAttributes()) do
                local lk=k:lower()
                if lk:find("stam") or lk:find("energy") then h:SetAttribute(k, 100) end
            end
        end
    end
    for k,_ in pairs(LP:GetAttributes()) do
        local lk=k:lower()
        if lk:find("stam") or lk:find("energy") then LP:SetAttribute(k, 100) end
    end
end

----------------------------------------------------------------
-- loot ops
----------------------------------------------------------------
local function triggerOn(inst)
    if not inst then return end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ProximityPrompt") then pcall(fireproximityprompt, d, 1) end
        if d:IsA("ClickDetector") then
            pcall(fireclickdetector, d, 1, "MouseClick")
            pcall(fireclickdetector, d, 1)
        end
    end
    if inst:IsA("ProximityPrompt") then pcall(fireproximityprompt, inst, 1) end
    if inst:IsA("ClickDetector")  then pcall(fireclickdetector,  inst, 1, "MouseClick") end
end
local function grabNearbyLoot()
    local r=hrp(); if not r then return end
    local pos=r.Position
    for m, _ in pairs(setLoot) do
        if m and m.Parent then
            local p = getPrimary(m)
            if p and (p.Position - pos).Magnitude < GRAB_RADIUS then triggerOn(m) end
        end
    end
    for pp, _ in pairs(setPrompts) do
        if pp and pp.Parent then
            local pt = pp.Parent
            local part = (pt and pt:IsA("BasePart")) and pt or (pt and pt:FindFirstChildWhichIsA("BasePart"))
            if part and (part.Position - pos).Magnitude < GRAB_RADIUS then
                pcall(fireproximityprompt, pp, 1)
            end
        end
    end
end
local function bringLoot()
    local r=hrp(); if not r then return end
    local target = r.CFrame * CFrame.new(0, 2, -4)
    for m, _ in pairs(setLoot) do
        if m and m.Parent then
            local primary = getPrimary(m)
            if primary and (primary.Position - r.Position).Magnitude < BRING_RADIUS then
                pcall(function()
                    if primary:IsA("BasePart") and not primary.Anchored then
                        pcall(function() primary:SetNetworkOwner(LP) end)
                    end
                    if m:IsA("Model") then
                        if m.PrimaryPart then m:PivotTo(target)
                        else
                            local wasAnchored = primary.Anchored
                            primary.Anchored = true
                            primary.CFrame = target
                            primary.Anchored = wasAnchored
                        end
                    else
                        primary.CFrame = target
                    end
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

----------------------------------------------------------------
-- heartbeat
----------------------------------------------------------------
table.insert(CONN, RunService.Heartbeat:Connect(function(dt)
    tickMovement(dt); tickAntiTaser(dt); tickStamina(dt); tickAntiRubberband(dt)
end))

----------------------------------------------------------------
-- slow loop
----------------------------------------------------------------
task.spawn(function()
    while gui.Parent do
        local anyESP = S.PoliceESP or S.GuardESP or S.NpcESP or S.LootESP or S.CameraESP or S.TruckESP or S.RedViewCones
        if anyESP then syncESP() elseif next(espByInst) then removeAllHL() end
        updateMeters()
        applyNoclip()
        if S.SilentWarnings then nukeKickGuis() end
        if S.GrabNearbyLoot then grabNearbyLoot() end
        if S.BringLoot      then bringLoot()      end
        task.wait(ESP_UPDATE_RATE)
    end
end)

----------------------------------------------------------------
-- UI mount
----------------------------------------------------------------
makeToggle("AntiCheat Block",  "AntiCheatBlock")
makeToggle("Anti Kick",        "AntiKick")
makeToggle("Anti Rubberband",  "AntiRubberband")
makeToggle("Silent Warnings",  "SilentWarnings")
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
makeToggle("Speed Boost (velocity)", "SpeedBoost")
makeSlider("Speed", SPEED_MIN, SPEED_MAX, SPEED_VAL, function(val) SPEED_VAL = val end)
makeToggle("Inf Stamina",      "InfStamina", function(v) if not v then unhookAllStamina() end end)
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
    local best, bestD = nil, math.huge
    for m, _ in pairs(setLoot) do
        local p = getPrimary(m)
        if p then local d=(p.Position-r.Position).Magnitude; if d<bestD then bestD=d; best=p end end
    end
    if best and char() then char():PivotTo(best.CFrame * CFrame.new(0, 3, 2)) end
end)
makeAction("Wipe AC Connections", wipeACConnections)

----------------------------------------------------------------
-- respawn + restore
----------------------------------------------------------------
table.insert(CONN, LP.CharacterAdded:Connect(function(c)
    stealthRestore = {}
    local h=c:WaitForChild("Humanoid", 5)
    if h then baseSpeed = h.WalkSpeed end
    task.wait(1)
    if S.StealthMode then setStealth(true) end
    if S.Fullbright  then setFullbright(true) end
end))
if hum() then baseSpeed = hum().WalkSpeed end

getgenv().__CRIM_SIM_RESTORE = function()
    unhookAllStamina()
    setFullbright(false)
    setStealth(false)
    for p, orig in pairs(glassBackup) do if p and p.Parent then p.CanCollide = orig end end
    local h=hum()
    if h then
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    end
end

task.spawn(initialWalk)
print("[crim_sim v7] loaded — press Insert (or End)")
