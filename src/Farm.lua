local Farm = {}
local running = false

local function refreshEnemyList(ctx)
    local Players = ctx.services.Players
    local weatherEventModels = { "Chicleteira","YONII","GRAIPUS MEDUS","Market Crate","BOSS" }
    local function isIn(list, lname)
        for _, n in ipairs(list) do if lname == n:lower() then return true end end
        return false
    end

    local weather, other = {}, {}
    local function classify(node)
        if node:IsA("Model") and not Players:GetPlayerFromCharacter(node) then
            local h = node:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                local lname = node.Name:lower()
                if isIn(weatherEventModels, lname) then
                    table.insert(weather, node)
                else
                    table.insert(other, node)
                end
            end
        end
        for _, c in ipairs(node:GetChildren()) do classify(c) end
    end
    local Utils = Farm.deps.Utils
    for _, folder in ipairs(Utils.searchFoldersList()) do if folder then classify(folder) end end
    local out = {}
    for _, e in ipairs(weather) do table.insert(out, e) end
    for _, e in ipairs(other) do table.insert(out, e) end
    return out
end

local function loop(ctx, ui, deps)
    local Utils, Remotes = deps.Utils, deps.Remotes
    Remotes.setAutoAttack(ctx, true)

    while running do
        local player = ctx.services.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart")
           or not player.Character:FindFirstChild("Humanoid")
           or player.Character.Humanoid.Health <= 0 then
            Utils.waitForCharacter(player)
        end

        local enemies = refreshEnemyList(ctx)
        if #enemies == 0 then task.wait(0.5) goto continue end

        for _, enemy in ipairs(enemies) do
            if not running then break end
            if not enemy or not enemy.Parent then goto continue end
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then goto continue end

            if ui and ui.refs and ui.refs.TargetLabel then
                ui.refs.TargetLabel.Text = "Current Target: " .. enemy.Name .. " (Health: " .. hum.Health .. ")"
            end

            local part = Utils.findBasePart(enemy)
            local targetCF = part and (part.CFrame * CFrame.new(0,0,5)) or (enemy:GetModelCFrame() * CFrame.new(0,0,5))
            if not Utils.isValidCFrame(targetCF) then goto continue end

            local okTeleport = pcall(function() player.Character.HumanoidRootPart.CFrame = targetCF end)
            if okTeleport then
                local hc = hum.HealthChanged:Connect(function(h)
                    if ui and ui.refs and ui.refs.TargetLabel then
                        ui.refs.TargetLabel.Text = "Current Target: " .. enemy.Name .. " (Health: " .. h .. ")"
                    end
                end)
                local start = tick()
                while running and enemy.Parent and hum and hum.Health > 0 and (tick()-start) < 30 do
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = targetCF end
                    task.wait(0.6)
                end
                if hc then hc:Disconnect() end
            end

            if ui and ui.refs and ui.refs.TargetLabel then
                ui.refs.TargetLabel.Text = "Current Target: None"
            end
            task.wait(0.25)
            ::continue::
        end
        ::continue::
        task.wait(0.5)
    end

    Remotes.setAutoAttack(ctx, false)
end

function Farm.init(ctx, ui, deps)
    Farm.ctx, Farm.ui, Farm.deps = ctx, ui, deps
end

function Farm.start()
    if running then return end
    local ctx, ui, deps = Farm.ctx, Farm.ui, Farm.deps
    running = true
    ctx.state.autoFarmEnabled = true
    deps.Utils.preventAFK(ctx)
    task.spawn(loop, ctx, ui, deps)
end

function Farm.stop()
    if not running then return end
    running = false
    Farm.ctx.state.autoFarmEnabled = false
    local ui = Farm.ui
    if ui and ui.refs and ui.refs.TargetLabel then
        ui.refs.TargetLabel.Text = "Current Target: None"
    end
end

return Farm
