-- GOD MODE for Criminal Simulator (via RVC Hub autoload + killaura preempt)
-- one-shot, no key prompt, uses saved free key from Xeno workspace

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local function notify(t, s)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="GODMODE", Text=t, Duration=s or 5})
    end)
end

-- 1) Ключ из файла Xeno, с запасом хардкода
local KEY = "free-864ba927-6dc1-40af-b77b-d47ed451e2b1"
pcall(function()
    if readfile then
        local saved = readfile("RVCHub_key.txt")
        if saved and #saved > 10 then KEY = saved:gsub("%s+","") end
    end
end)

-- 2) RVC Hub ids
local UI_URL     = "https://raw.githubusercontent.com/heyitsmehowareyou11/rvchub/main/ui/dist/ui.lua"
local SERVICE    = "hub"
local IDENTIFIER = "1229300"
local SCRIPT_ID  = "128eaa492d8d16bf83c056eab88bf0a183f4c80c755b213d2112d0af8989209b"

-- 3) Автозагрузка RVC Hub с пропуском keygate
local function loadRVC()
    local okUI, Library = pcall(function()
        return loadstring(game:HttpGet(UI_URL))()
    end)
    if not okUI or type(Library) ~= "table" then return false, "UI fetch failed" end

    local okP, provider = pcall(function()
        return Library.Providers.Jnkie({
            Service = SERVICE, Identifier = IDENTIFIER, ScriptId = SCRIPT_ID
        })
    end)
    if not okP or type(provider) ~= "table" then return false, "provider failed" end

    local okL, result = pcall(provider.LoadScript, KEY)
    if not okL or result == false then return false, "key invalid or expired" end
    return true
end

-- 4) Fallback shotgun god-mode если RVC не взлетел
local function fallback()
    local RS = game:GetService("ReplicatedStorage")
    local Run = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local HUGE = 1e9
    local STUN = {"stun","taser","tase","ragdoll","down","arrest","ko","knock","sleep","hospital","detect","catch","capture","handcuff"}
    local HP   = {"health","hp","stamina","energy","life"}
    local function match(s,l) s=string.lower(tostring(s)); for _,w in ipairs(l) do if string.find(s,w,1,true) then return true end end return false end

    local BAD = {
        [Enum.HumanoidStateType.Physics]=1,[Enum.HumanoidStateType.Ragdoll]=1,
        [Enum.HumanoidStateType.FallingDown]=1,[Enum.HumanoidStateType.Dead]=1,
        [Enum.HumanoidStateType.Seated]=1,[Enum.HumanoidStateType.PlatformStanding]=1,
    }
    local SAFE
    local function prot(c)
        local h = c:WaitForChild("Humanoid",5); if not h then return end
        pcall(function() h.BreakJointsOnDeath=false; h.RequiresNeck=false end)
        pcall(function() h.MaxHealth=HUGE; h.Health=HUGE end)
        for s in pairs(BAD) do pcall(function() h:SetStateEnabled(s,false) end) end
        h.StateChanged:Connect(function(_,n) if BAD[n] then pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end) end end)
        h.HealthChanged:Connect(function(v) if v<HUGE then h.Health=HUGE end end)
        for _,m in ipairs(c:GetDescendants()) do if m:IsA("Motor6D") then m:GetPropertyChangedSignal("Enabled"):Connect(function() if not m.Enabled then m.Enabled=true end end) end end
        if not c:FindFirstChildOfClass("ForceField") then local ff=Instance.new("ForceField"); ff.Visible=false; ff.Parent=c end
        task.spawn(function()
            while c.Parent do task.wait(2)
                local hrp=c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local det=false
                    for k,v in pairs(LP:GetAttributes()) do if type(v)=="boolean" and v and match(k,{"detect","wanted","chase"}) then det=true end end
                    if not det then SAFE=hrp.CFrame end
                end
            end
        end)
    end
    if LP.Character then prot(LP.Character) end
    LP.CharacterAdded:Connect(prot)

    pcall(function()
        local old
        old = hookmetamethod(game,"__namecall",function(self,...)
            local m=getnamecallmethod()
            if typeof(self)=="Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                if (m=="FireServer" or m=="InvokeServer") and match(self.Name,STUN) then
                    for _,a in ipairs({...}) do if a==LP or a==LP.Character then return end end
                end
            end
            if m=="TakeDamage" or m=="BreakJoints" or m=="Kill" then
                local c=LP.Character
                if c and (self==c:FindFirstChildOfClass("Humanoid") or self==c) then return end
            end
            return old(self,...)
        end)
    end)

    for _,r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") and match(r.Name,STUN) then
            pcall(function() if getconnections then for _,c in ipairs(getconnections(r.OnClientEvent)) do pcall(function() c:Disable() end) end end end)
        end
    end

    LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
        task.wait(0.05)
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local t=tostring(d.Text or "")
            if string.find(t,"спустились") or string.find(t,"ольниц") then
                local c=LP.Character
                if c and c:FindFirstChild("HumanoidRootPart") and SAFE then
                    task.wait(0.1); c.HumanoidRootPart.CFrame=SAFE
                end
                if d:IsA("TextButton") and string.find(t,"родолжить") then
                    pcall(function() for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end end)
                end
            end
        end
    end)

    Run.Heartbeat:Connect(function()
        pcall(function()
            local c=LP.Character; local h=c and c:FindFirstChildOfClass("Humanoid")
            if h and h.Health<HUGE then h.Health=HUGE end
            for k,v in pairs(LP:GetAttributes()) do
                local lk=string.lower(k)
                if type(v)=="boolean" and v and match(lk,STUN) then pcall(function() LP:SetAttribute(k,false) end) end
                if type(v)=="number" and match(lk,HP) then pcall(function() LP:SetAttribute(k,HUGE) end) end
            end
            if c then
                for k,v in pairs(c:GetAttributes()) do
                    local lk=string.lower(k)
                    if type(v)=="boolean" and v and match(lk,STUN) then pcall(function() c:SetAttribute(k,false) end) end
                end
            end
        end)
    end)
end

-- 5) Погнали
notify("loading RVC Hub...", 3)
local ok, err = loadRVC()
if ok then
    notify("RVC Hub loaded. Enable Kill Aura in menu = god mode", 8)
else
    notify("RVC failed ("..tostring(err).."), fallback shotgun active", 6)
    fallback()
end
