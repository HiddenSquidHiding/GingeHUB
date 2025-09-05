local AutoLevel = {}
local running = false

local function getPlayerHealth(player)
    local ch = player.Character
    if not ch then return 0,0 end
    local h = ch:FindFirstChildOfClass("Humanoid")
    if not h then return 0,0 end
    local max = (h.MaxHealth and h.MaxHealth>0) and h.MaxHealth or h.Health
    return h.Health, max
end

local function collectAllEnemies(ctx, Utils)
    local enemies = {}
    local Players = ctx.services.Players
    local function collect(node)
        if node:IsA("Model") and not Players:GetPlayerFromCharacter(node) then
            local h = node:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                local emax = (h.MaxHealth and h.MaxHealth>0) and h.MaxHealth or h.Health
                enemies[#enemies+1] = {model=node, hum=h, emax=emax}
            end
        end
        for _,c in ipairs(node:GetChildren()) do collect(c) end
    end
    for _, folder in ipairs(Utils.searchFoldersList()) do if folder then collect(folder) end end
    if #enemies==0 and ctx.state.useWorkspaceFallback then collect(workspace) end
    table.sort(enemies, function(a,b) return a.emax < b.emax end)
    return enemies
end

local RATIO, TIMEOUT = 1.25, 45

local function chooseTarget(ctx, Utils)
    local player = ctx.services.Players.LocalPlayer
    local _, pmax = getPlayerHealth(player)
    if pmax <= 0 then return nil end
    local enemies = collectAllEnemies(ctx, Utils)
    if #enemies==0 then return nil end
    local cap = pmax * RATIO
    local best = nil
    for _,e in ipairs(enemies) do
        if e.emax <= cap then best = e else break end
    end
    if best then return best.model, best.hum end
    return enemies[1].model, enemies[1].hum
end

local function loop(ctx, ui, deps)
    local Utils, Remotes = deps.Utils, deps.Remotes
    Remotes.setAutoAttack(ctx, true)

    while running do
        local player = ctx.services.Players.LocalPlayer
        local ch = player.Character
        if not ch or not ch:FindFirstChild("HumanoidRootPart") or not ch:FindFirstChild("Humanoid") or ch.Humanoid.Health <= 0 then
            Utils.waitForCharacter(player)
        end

        local target, hum = chooseTarget(ctx, Utils)
        if not target or not hum then task.wait(0.5) goto next end

        if ui and ui.refs and ui.refs.TargetLabel then
            ui.refs.TargetLabel.Text = ("Current Target: %s (Health: %d)"):format(target.Name, hum.Health)
        end

        local part = Utils.findBasePart(target)
        local targetCF = part and (part.CFrame * CFrame.new(0,0,5)) or (target:GetModelCFrame() * CFrame.new(0,0,5))
        if Utils.isValidCFrame(targetCF) then
            local okTeleport = pcall(function() player.Character.HumanoidRootPart.CFrame = targetCF end)
            if okTeleport then
                local hc = hum.HealthChanged:Connect(function(h)
                    if ui and ui.refs and ui.refs.TargetLabel then
                        ui.refs.TargetLabel.Text = "Current Target: " .. target.Name .. " (Health: " .. h .. ")"
                    end
                end)
                local start = tick()
                while running and target.Parent and hum and hum.Health > 0 and (tick()-start) < TIMEOUT do
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = targetCF end
                    task.wait(0.5)
                end
                if hc then hc:Disconnect() end
            end
        end

        if ui and ui.refs and ui.refs.TargetLabel then
            ui.refs.TargetLabel.Text = "Current Target: None"
        end
        task.wait(0.25)
        ::next::
    end

    Remotes.setAutoAttack(ctx, false)
end

function AutoLevel.init(ctx, ui, deps)
    AutoLevel.ctx, AutoLevel.ui, AutoLevel.deps = ctx, ui, deps
end

function AutoLevel.start()
    if running then return end
    running = true
    local ctx = AutoLevel.ctx
    ctx.state.autoLevelEnabled = true
    AutoLevel.deps.Utils.preventAFK(ctx)
    task.spawn(loop, ctx, AutoLevel.ui, AutoLevel.deps)
end

function AutoLevel.stop()
    if not running then return end
    running = false
    AutoLevel.ctx.state.autoLevelEnabled = false
    local ui = AutoLevel.ui
    if ui and ui.refs and ui.refs.TargetLabel then
        ui.refs.TargetLabel.Text = "Current Target: None"
    end
end

return AutoLevel
