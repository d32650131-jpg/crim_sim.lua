-- AUTO GOD MODE Criminal Simulator — lobby detect + teleport + auto redeem
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local TS = game:GetService("TeleportService")
local LP = Players.LocalPlayer

local SCRIPT_URL = "https://raw.githubusercontent.com/d32650131-jpg/crim_sim.lua/main/crim_sim.lua"

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="GOD", Text=t, Duration=s or 8}) end)
end

local function queueMe()
    local q = queue_on_teleport or queueonteleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    if q then
        pcall(q, 'loadstring(game:HttpGet("'..SCRIPT_URL..'?t="..tick()))()')
        return true
    end
    return false
end

-- Детект: в лобби ли мы (есть ли ремоут Codes)
local remotes = RS:FindFirstChild("Remotes")
local codes = remotes and remotes:FindFirstChild("Codes")

if codes and codes:IsA("RemoteFunction") then
    ------- ЛОББИ: активируем коды -------
    notify("Лобби найдено. Активирую коды...", 5)
    local CODES = {"ADMIN","GOD","PIGGY","30KLIKES","10MVISITS","CITY","POLICE"}
    local results = {}
    local gotGC = false

    local gcBefore = LP:GetAttribute("GodCharges") or 0

    for _,c in ipairs(CODES) do
        local ok, r = pcall(function() return codes:InvokeServer(c) end)
        table.insert(results, c.."="..tostring(r))
        task.wait(0.4)
    end

    task.wait(2)  -- даём серверу обновить атрибут

    local gcAfter = LP:GetAttribute("GodCharges") or 0
    local delta = gcAfter - gcBefore

    print("[CODES]", table.concat(results, " | "))
    print("[GC]", gcBefore, "->", gcAfter, "delta="..delta)

    if delta > 0 then
        notify("✓ Получил "..delta.." god зарядов! Всего: "..gcAfter..". Жми God в меню перед раундом", 20)
    elseif gcAfter > 0 then
        notify("Коды уже активированы раньше. У тебя "..gcAfter.." зарядов — активируй в меню", 20)
    else
        notify("Все коды уже погашены на твоём аккаунте. Только Forever God gamepass (1599R$) даст бессмертие", 20)
    end

    -- Ищем в UI лобби кнопку God Mode / Immunity и подсвечиваем её
    task.wait(1)
    local pg = LP:WaitForChild("PlayerGui")
    for _,d in ipairs(pg:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) then
            local n = string.lower(d.Name or "")
            local t = d:IsA("TextButton") and string.lower(d.Text or "") or ""
            if string.find(n,"god") or string.find(t,"god") or string.find(t,"бог") or string.find(t,"иммун") then
                print("[FOUND GOD BUTTON]", d:GetFullName(), "text:", d.Text)
                notify("Кнопка God: "..d:GetFullName(), 15)
            end
        end
    end

else
    ------- РАУНД: ставим очередь и телепортим в лобби -------
    notify("Не в лобби. Очередь поставлена, возвращаюсь в лобби...", 6)
    local queued = queueMe()
    if not queued then
        notify("Executor не поддерживает queue_on_teleport. Выйди в лобби вручную и запусти снова", 15)
        return
    end

    -- Пробуем Rejoin remote
    local rej = remotes and remotes:FindFirstChild("Rejoin")
    if rej and rej:IsA("RemoteEvent") then
        pcall(function() rej:FireServer() end)
        task.wait(2)
    end

    -- Ищем кнопку "В лобби" / "Выйти" / "Return to lobby" в UI
    local pg = LP:WaitForChild("PlayerGui")
    local found = false
    for _,d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextButton") then
            local t = string.lower(d.Text or "")
            local n = string.lower(d.Name or "")
            if string.find(t,"лобби") or string.find(t,"lobby") or string.find(t,"выйти") or string.find(t,"leave") or string.find(t,"menu") or string.find(n,"lobby") or string.find(n,"leave") then
                pcall(function()
                    for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
                end)
                found = true
                notify("Клик: "..d.Text, 5)
                break
            end
        end
    end

    -- Fallback: прямой телепорт в универс Criminal Simulator
    if not found then
        task.wait(2)
        pcall(function() TS:Teleport(10769851460, LP) end)
    end

    notify("Телепорт в лобби... скрипт продолжится там автоматически", 8)
end
