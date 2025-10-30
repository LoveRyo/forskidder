local P = game:GetService("Players")
local L = P.LocalPlayer
local R = game:GetService("ReplicatedStorage")
local W = workspace
local M = R:FindFirstChild("Modules")
if not M then return end
local CU = nil
pcall(function()
    CU = require(M:WaitForChild("CombatUtil"))
end)
if not CU then return end
local WD = nil
pcall(function()
    WD = require(M:FindFirstChild("WeaponData"))
end)
local Net = M:FindFirstChild("Net")
local RA = Net and (Net:FindFirstChild("RE/RegisterAttack") or Net:FindFirstChild("RegisterAttack"))
local RH = Net and (Net:FindFirstChild("RE/RegisterHit") or Net:FindFirstChild("RegisterHit"))
local IS = nil
pcall(function()
    for _, s in pairs(L:WaitForChild("PlayerScripts"):GetChildren()) do
        if s:IsA("LocalScript") then
            local ok, env = pcall(function()
                return getsenv(s)
            end)
            if ok and type(env) == "table" and env._G and type(env._G.SendHitsToServer) == "function" then
                IS = env._G.SendHitsToServer
                break
            end
        end
    end
end)
if not IS and _G and type(_G.SendHitsToServer) == "function" then
    IS = _G.SendHitsToServer
end
pcall(function()
    hookfunction(CU.GetComboPaddingTime, function() return 0 end)
    hookfunction(CU.GetAttackCancelMultiplier, function() return 0 end)
    hookfunction(CU.CanAttack, function() return true end)
end)
local HitPart = {
    "RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm",
    "RightHand","LeftHand","HumanoidRootPart","Head","UpperTorso","LowerTorso"
}

IsValid = function(m)
    return m and m:FindFirstChildWhichIsA("Humanoid") and m:FindFirstChild("HumanoidRootPart")
        and m:FindFirstChildWhichIsA("Humanoid").Health > 0
        and not m:FindFirstChild("VehicleSeat")
end

GetHitPart = function(m)
    for i = 1, 3 do
        local part = HitPart[math.random(1, #HitPart)]
        local p = m:FindFirstChild(part)
        if p then return p end
    end
    return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
end

GetNearTargets = function(rng, maxN)
    local out = {}
    pcall(function()
        local ch = L.Character
        if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pos = hrp.Position
        for _, folder in pairs({W:FindFirstChild("Enemies"), W:FindFirstChild("Characters")}) do
            if folder then
                for _, v in pairs(folder:GetChildren()) do
                    if #out >= (maxN or 20) then break end
                    if v ~= ch and IsValid(v) then
                        local h = v:FindFirstChild("HumanoidRootPart")
                        if h and (h.Position - pos).Magnitude <= rng then
                            table.insert(out, v)
                        end
                    end
                end
            end
        end
        for _, pl in pairs(P:GetPlayers()) do
            if #out >= (maxN or 20) then break end
            if pl ~= L and pl.Character and IsValid(pl.Character) then
                local hr = pl.Character:FindFirstChild("HumanoidRootPart")
                if hr and (hr.Position - pos).Magnitude <= rng then
                    table.insert(out, pl.Character)
                end
            end
        end
    end)
    return out
end

BuildHits = function(targets)
    local main, hits = nil, {}
    for _, v in pairs(targets) do
        if IsValid(v) then
            local part = GetHitPart(v)
            if part then
                if not main then main = part end
                table.insert(hits, {v, part})
            end
        end
    end
    if #hits > 0 and hits[#hits] then table.insert(hits, hits[#hits]) end
    return main, hits
end

FireHit = function(main, hits)
    if not main or not hits or #hits == 0 then return end
    pcall(function()
        if IS then
            IS(main, hits)
        elseif RH and RH.FireServer then
            RH:FireServer(main, hits)
        end
    end)
end

 Attack = function(tool)
    local combo = 4
    pcall(function()
        local name = CU:GetWeaponName(tool)
        local key = string.lower(name)
        local data = WD and (WD[key] or WD[name] or WD[CU:GetPureWeaponName(name)])
        if data and data.Moveset and data.Moveset.Basic then
            local c = 0
            for _ in pairs(data.Moveset.Basic) do c = c + 1 end
            combo = c >= 1 and c or 4
        end
    end)
    return combo
end

spawn(
    function()
        while wait(0.019) do
            pcall(function()
                local ch = L.Character
                if not ch then return end
                local tool = ch:FindFirstChildOfClass("Tool")
                if not tool then return end
                local targets = GetNearTargets(60, 20)
                if #targets == 0 then return end
                local main, hits = BuildHits(targets)
                if not main or not hits then return end
                if RA and RA.FireServer then pcall(function() RA:FireServer(0) end) end
                for i = 1, Attack(tool) do
                    coroutine.wrap(function()
                        pcall(function()
                            CU:AttackStart(main, i)
                            local obj = {_Object = {Length = 0.02, IsPlaying = true}}
                            CU:RunHitDetection(main.Parent or main, i, obj)
                        end)
                    end)()
                end
                FireHit(main, hits)
            end)
        end
    end
)
