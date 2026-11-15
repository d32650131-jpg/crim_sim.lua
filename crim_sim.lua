-- AUTO REDEEM GOD CODE | использует родной UI игры
local Players = game:GetService("Players")
local SG = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local function notify(t, s)
    pcall(function() SG:SetCore("SendNotification", {Title="REDEEM", Text=t, Duration=s or 6}) end)
end

local CODES_TO_TRY = {"ADMIN","GOD","PIGGY","30KLIKES","10MVISITS"}

-- 1) Найти в PlayerGui окно с кодами (ключи: code, promo, код)
local function findCodesUI()
    local pg = LP:WaitForChild("PlayerGui")
    local box, btn, container
    for _,d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextBox") then
            local pname = string.lower(d.Parent.Name or "")
            local n = string.lower(d.Name or "")
            local ph = string.lower(d.PlaceholderText or "")
            if string.find(n,"code") or string.find(pname,"code") or string.find(ph,"код") or string.find(ph,"code") then
                box = d
                container = d.Parent
                -- ищем кнопку рядом
                for _,sib in ipairs(container:GetDescendants()) do
                    if sib:IsA("TextButton") then
                        local t = string.lower(sib.Text or "")
                        if string.find(t,"redeem") or string.find(t,"активир") or string.find(t,"ввести") or string.find(t,"применить") then
                            btn = sib; break
                        end
                    end
                end
                if box and btn then break end
            end
        end
    end
    return box, btn
end

-- 2) Открыть меню кодов, если закрыто (ищем кнопку CODES/КОДЫ)
local function openCodesMenu()
    local pg = LP:WaitForChild("PlayerGui")
    for _,d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("ImageButton") then
            local n = string.lower(d.Name or "")
            local t = d:IsA("TextButton") and string.lower(d.Text or "") or ""
            if string.find(n,"code") or string.find(t,"codes") or string.find(t,"коды") or string.find(t,"код") then
                pcall(function()
                    if d:IsA("TextButton") then
                        for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
                    else
                        for _,s in ipairs(getconnections(d.MouseButton1Click)) do s:Fire() end
                    end
                end)
                task.wait(0.4)
                return true
            end
        end
    end
    return false
end

-- 3) Запустить ввод кода
local function redeem(code)
    openCodesMenu()
    task.wait(0.3)
    local box, btn = findCodesUI()
    if not box or not btn then return false, "UI not found" end
    box.Text = code
    task.wait(0.2)
    pcall(function()
        for _,s in ipairs(getconnections(btn.MouseButton1Click)) do s:Fire() end
    end)
    task.wait(0.5)
    return true
end

-- 4) Цикл редем всех кодов
notify("ищу меню кодов...", 4)
task.wait(1)

local results = {}
for _,c in ipairs(CODES_TO_TRY) do
    local ok, err = redeem(c)
    table.insert(results, c.."="..(ok and "sent" or err))
    task.wait(1)
    local gc = LP:GetAttribute("GodCharges")
    print("[REDEEM]", c, "->", ok, err, "| GodCharges=", gc)
    if type(gc) == "number" and gc > 0 then
        notify("GOT "..gc.." god charges from "..c, 10)
        break
    end
end

task.wait(1)
local finalGC = LP:GetAttribute("GodCharges")
notify("final GodCharges = "..tostring(finalGC)..(finalGC and finalGC>0 and " ✓ активируй God в меню!" or " — коды не дали"), 15)
print("[REDEEM] results:", table.concat(results, " | "), "| final GC=", finalGC)
