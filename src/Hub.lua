local Hub = {}

function Hub.start(config)
    local function req(name)
        return require(game:GetService("ReplicatedStorage").WoodzHUB:WaitForChild(name:gsub("%.lua","")))
    end

    local ctx = {
        services = {
            Players           = game:GetService("Players"),
            Workspace         = game:GetService("Workspace"),
            ReplicatedStorage = game:GetService("ReplicatedStorage"),
            UserInputService  = game:GetService("UserInputService"),
            VirtualUser       = game:GetService("VirtualUser"),
            StarterGui        = game:GetService("StarterGui"),
        },
        state = {
            autoFarmEnabled       = false,
            autoLevelEnabled      = false,
            useWorkspaceFallback  = true,
            currentTargetLabel    = nil,
        },
        constants = {},
    }

    local Utils     = req("Utils.lua")
    local Remotes   = req("Remotes.lua")
    local UI        = req("UI.lua")
    local Farm      = req("Farm.lua")
    local AutoLevel = req("AutoLevel.lua")
    local Crates    = req("Crates.lua")
    local Merchants = req("Merchants.lua")

    local deps = { Utils = Utils, Remotes = Remotes }

    Utils.init(ctx)
    local ui = UI.mount(ctx, deps)

    Remotes.init(ctx)
    Crates.init(ctx, ui, deps)
    Merchants.init(ctx, ui, deps)

    Farm.init(ctx, ui, deps)
    AutoLevel.init(ctx, ui, deps)

    ui.onAutoFarmToggle.Event:Connect(function(on)
        if on then
            ctx.state.autoLevelEnabled = false
            ui.setAutoLevel(false)
            Farm.start()
        else
            Farm.stop()
        end
    end)

    ui.onAutoLevelToggle.Event:Connect(function(on)
        if on then
            ctx.state.autoFarmEnabled = false
            ui.setAutoFarm(false)
            AutoLevel.start()
        else
            AutoLevel.stop()
        end
    end)

    ui.onRebirth.Event:Connect(function()
        Remotes.rebirth(ctx)
    end)

    ui.onAutoCratesToggle.Event:Connect(function(on)
        Crates.setEnabled(on)
    end)

    ui.onMerchant1Toggle.Event:Connect(function(on)
        Merchants.setM1Enabled(on, ui)
    end)
    ui.onMerchant2Toggle.Event:Connect(function(on)
        Merchants.setM2Enabled(on, ui)
    end)

    Utils.notify("🌲 WoodzHUB","Loaded modular build (Hub + modules).",6.5)
end

return Hub
