local player = game.Players.LocalPlayer
function AttackNoCoolDown()
    local character = player.Character
    if not character then return end
    local equippedWeapon = nil
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            equippedWeapon = item
            break
        end
    end
    if not equippedWeapon then return end
    local function IsEntityAlive(entity)
        return entity and entity:FindFirstChild("Humanoid") and entity.Humanoid.Health > 0
    end
    local function GetEnemiesInRange(range)
        local enemies = game:GetService("Workspace").Enemies:GetChildren()
        local targets = {}
        local playerPos = character:GetPivot().Position
        for _, enemy in ipairs(enemies) do
            local primaryPart = enemy:FindFirstChild("HumanoidRootPart")
            if primaryPart and IsEntityAlive(enemy) and (primaryPart.Position - playerPos).Magnitude <= range then
                table.insert(targets, enemy)
            end
        end
        return targets
    end
    if equippedWeapon:FindFirstChild("LeftClickRemote") then
        local attackCount = 1  
        local enemiesInRange = GetEnemiesInRange(60)
        for _, enemy in ipairs(enemiesInRange) do
            local direction = (enemy.HumanoidRootPart.Position - character:GetPivot().Position).Unit
            pcall(function()
                equippedWeapon.LeftClickRemote:FireServer(direction, attackCount)
            end)
            attackCount = attackCount + 1
            if attackCount > 1000000000 then attackCount = 1 end
        end
    else
        local targets = {}
        local enemies = game:GetService("Workspace").Enemies:GetChildren()
        local playerPos = character:GetPivot().Position
        local mainTarget = nil
        for _, enemy in ipairs(enemies) do
            if not enemy:GetAttribute("IsBoat") and IsEntityAlive(enemy) then
                local head = enemy:FindFirstChild("Head")
                if head and (playerPos - head.Position).Magnitude <= 60 then
                    table.insert(targets, { enemy, head })
                    mainTarget = head
                end
            end
        end
        if not mainTarget then return end
        pcall(function()
            local storage = game:GetService("ReplicatedStorage")
            local attackEvent = storage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterAttack")
            local hitEvent = storage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterHit")
            if #targets > 0 then
                attackEvent:FireServer(0.000000001)
                hitEvent:FireServer(mainTarget, targets)
            else
                task.wait(0.000000001)
            end
        end)
    end
end

spawn(function()
    while wait(.1) do
        if _G.FastAttack then
            pcall(function()
                repeat task.wait(0.0000001)
                    AttackNoCoolDown()
                until not _G.FastAttack
            end)
        end
    end
end)

_G.FastAttack = true
