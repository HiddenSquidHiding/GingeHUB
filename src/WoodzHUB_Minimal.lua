-- WoodzHUB_Minimal_Farm_Simple.lua
-- Simplified script to debug 'attempt to call a nil value' error with Farm module

local function debugPrint(msg)
    print("[WoodzHUB Debug] " .. tostring(msg))
end

debugPrint("Script started")

-- Module store
local Modules = {}

-- Utils.lua
Modules.Utils = (function()
    debugPrint("Defining Utils module")
    local Utils = {}
    function Utils.init(ctx)
        debugPrint("Utils.init called")
        ctx.constants = {
            COLOR_BG_DARK = Color3.fromRGB(30, 30, 30),
            COLOR_BG = Color3.fromRGB(40, 40, 40),
            COLOR_BTN = Color3.fromRGB(60, 60, 60),
            COLOR_BTN_ACTIVE = Color3.fromRGB(80, 80, 80),
            COLOR_WHITE = Color3.fromRGB(255, 255, 255),
            SIZE_MAIN = UDim2.new(0, 200, 0, 190),
        }
    end
    function Utils.new(t, props, parent)
        debugPrint("Utils.new called for type: " .. tostring(t))
        local i = Instance.new(t)
        if props then
            for k, v in pairs(props) do
                i[k] = v
            end
        end
        if parent then
            i.Parent = parent
        end
        return i
    end
    function Utils.notify(title, content, duration)
        debugPrint("Utils.notify called: " .. title)
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        if not player then
            debugPrint("No LocalPlayer for notify")
            return
        end
        local PlayerGui = player:WaitForChild("PlayerGui", 5)
        if not PlayerGui then
            debugPrint("PlayerGui not found")
            return
        end
        local gui = Utils.new("ScreenGui", {
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 2000000000
        }, PlayerGui)
        local frame = Utils.new("Frame", {
            Size = UDim2.new(0, 200, 0, 50),
            Position = UDim2.new(0.5, -100, 0.5, -25),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        }, gui)
        Utils.new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = title .. ": " .. content,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.SourceSans
        }, frame)
        task.spawn(function()
            task.wait(duration or 5)
            gui:Destroy()
        end)
        debugPrint("Notification GUI created")
    end
    debugPrint("Utils module defined")
    return Utils
end)()

-- Remotes.lua
Modules.Remotes = (function()
    debugPrint("Defining Remotes module")
    local Remotes = {}
    function Remotes.init(ctx)
        debugPrint("Remotes.init called")
        ctx.state.autoAttackRemote = nil
        ctx.state.rebirthRemote = nil
        for _, d in ipairs(ctx.services.ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteFunction") and d.Name:lower() == "autoattack" then
                ctx.state.autoAttackRemote = d
                debugPrint("Found autoAttackRemote: " .. d.Name)
                break
            end
        end
        for _, d in ipairs(ctx.services.ReplicatedStorage:GetDescendants()) do
            local n = d.Name:lower()
            if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and (n:find("rebirth") or n:find("servercontrol") or n:find("bosszoneremote")) then
                ctx.state.rebirthRemote = d
                debugPrint("Found rebirthRemote: " .. d.Name)
                break
            end
        end
        if not ctx.state.rebirthRemote then
            debugPrint("No rebirthRemote found")
        end
    end
    function Remotes.setAutoAttack(ctx, enabled)
        debugPrint("Remotes.setAutoAttack called: " .. tostring(enabled))
        local rf = ctx.state.autoAttackRemote
        if not rf then
            debugPrint("No autoAttackRemote found")
            return
        end
        pcall(function() rf:InvokeServer(enabled and true or false) end)
    end
    function Remotes.rebirth(ctx)
        debugPrint("Remotes.rebirth called")
        local r = ctx.state.rebirthRemote
        if not r then
            debugPrint("No rebirthRemote found for rebirth")
            return false
        end
        local success, err = pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer()
            else
                r:InvokeServer()
            end
        end)
        if success then
            debugPrint("Rebirth remote fired successfully")
            return true
        else
            debugPrint("Error firing rebirth remote: " .. tostring(err))
            return false
        end
    end
    debugPrint("Remotes module defined")
    return Remotes
end)()

-- UI.lua
Modules.UI = (function()
    debugPrint("Defining UI module")
    local UI = {}
    function UI.mount(ctx, deps)
        debugPrint("UI.mount called")
        local Utils = deps.Utils
        if not Utils then
            debugPrint("Utils is nil in UI.mount")
            return nil
        end
        local Players = ctx.services.Players
        local player = Players.LocalPlayer
        if not player then
            debugPrint("No LocalPlayer for UI")
            return nil
        end
        local PlayerGui = player:WaitForChild("PlayerGui", 5)
        if not PlayerGui then
            debugPrint("PlayerGui not found for UI")
            return nil
        end
        local C = ctx.constants
        local ScreenGui = Utils.new("ScreenGui", {
            Name = "WoodzHUB",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 2000000000,
            IgnoreGuiInset = false
        }, PlayerGui)
        local Main = Utils.new("Frame", {
            Size = C.SIZE_MAIN,
            Position = UDim2.new(0.5, -100, 0.5, -95),
            BackgroundColor3 = C.COLOR_BG_DARK,
            BorderSizePixel = 0
        }, ScreenGui)
        Utils.new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = C.COLOR_BG,
            Text = "🌲 WoodzHUB Test",
            TextColor3 = C.COLOR_WHITE,
            TextSize = 14,
            Font = Enum.Font.SourceSansBold
        }, Main)
        local TestButton = Utils.new("TextButton", {
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 40),
            BackgroundColor3 = C.COLOR_BTN,
            TextColor3 = C.COLOR_WHITE,
            Text = "Test Button"
        }, Main)
        local RebirthButton = Utils.new("TextButton", {
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 80),
            BackgroundColor3 = C.COLOR_BTN,
            TextColor3 = C.COLOR_WHITE,
            Text = "Test Rebirth"
        }, Main)
        local AutoFarmButton = Utils.new("TextButton", {
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 120),
            BackgroundColor3 = C.COLOR_BTN,
            TextColor3 = C.COLOR_WHITE,
            Text = "Auto-Farm: OFF"
        }, Main)
        local onTestToggle = Instance.new("BindableEvent")
        local onRebirth = Instance.new("BindableEvent")
        local onAutoFarmToggle = Instance.new("BindableEvent")
        TestButton.MouseButton1Click:Connect(function()
            debugPrint("Test button clicked")
            onTestToggle:Fire()
        end)
        RebirthButton.MouseButton1Click:Connect(function()
            debugPrint("Rebirth button clicked")
            onRebirth:Fire()
        end)
        AutoFarmButton.MouseButton1Click:Connect(function()
            debugPrint("AutoFarm button clicked")
            ctx.state.autoFarmEnabled = not ctx.state.autoFarmEnabled
            AutoFarmButton.Text = "Auto-Farm: " .. (ctx.state.autoFarmEnabled and "ON" or "OFF")
            AutoFarmButton.BackgroundColor3 = ctx.state.autoFarmEnabled and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
            onAutoFarmToggle:Fire(ctx.state.autoFarmEnabled)
        end)
        debugPrint("UI mounted successfully")
        return {
            refs = { TestButton = TestButton, RebirthButton = RebirthButton, AutoFarmButton = AutoFarmButton },
            onTestToggle = onTestToggle,
            onRebirth = onRebirth,
            onAutoFarmToggle = onAutoFarmToggle,
            setAutoFarm = function(on)
                ctx.state.autoFarmEnabled = on
                AutoFarmButton.Text = "Auto-Farm: " .. (on and "ON" or "OFF")
                AutoFarmButton.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
            end
        }
    end
    debugPrint("UI module defined")
    return UI
end)()

-- Farm.lua (Simplified)
Modules.Farm = (function()
    debugPrint("Defining Farm module")
    local Farm = {}
    local running = false
    local function loop(ctx, ui, deps)
        debugPrint("Farm.loop started")
        local Remotes = deps.Remotes
        Remotes.setAutoAttack(ctx, true)
        while running do
            debugPrint("Farm loop running")
            task.wait(1) -- Placeholder loop to test stability
        end
        Remotes.setAutoAttack(ctx, false)
        debugPrint("Farm.loop stopped")
    end
    function Farm.init(ctx, ui, deps)
        debugPrint("Farm.init called")
        Farm.ctx, Farm.ui, Farm.deps = ctx, ui, deps
    end
    function Farm.start()
        if running then return end
        debugPrint("Farm.start called")
        running = true
        local ctx, ui, deps = Farm.ctx, Farm.ui, Farm.deps
        ctx.state.autoFarmEnabled = true
        task.spawn(loop, ctx, ui, deps)
    end
    function Farm.stop()
        if not running then return end
        debugPrint("Farm.stop called")
        running = false
        Farm.ctx.state.autoFarmEnabled = false
    end
    debugPrint("Farm module defined")
    return Farm
end)()

-- Hub.lua
Modules.Hub = (function()
    debugPrint("Defining Hub module")
    local Hub = {}
    function Hub.start(config)
        debugPrint("Hub.start called")
        local ctx = {
            services = {
                Players = game:GetService("Players"),
                StarterGui = game:GetService("StarterGui"),
                ReplicatedStorage = game:GetService("ReplicatedStorage"),
            },
            state = {
                autoAttackRemote = nil,
                rebirthRemote = nil,
                autoFarmEnabled = false,
            },
            constants = {},
        }
        local Utils = Modules.Utils
        if not Utils then
            debugPrint("Utils module is nil in Hub.start")
            return
        end
        Utils.init(ctx)
        local deps = { Utils = Utils, Remotes = Modules.Remotes }
        local UI = Modules.UI
        if not UI then
            debugPrint("UI module is nil in Hub.start")
            return
        end
        local Remotes = Modules.Remotes
        if not Remotes then
            debugPrint("Remotes module is nil in Hub.start")
            return
        end
        local Farm = Modules.Farm
        if not Farm then
            debugPrint("Farm module is nil in Hub.start")
            return
        end
        Remotes.init(ctx)
        Farm.init(ctx, nil, deps)
        local ui = UI.mount(ctx, deps)
        if not ui then
            debugPrint("UI.mount failed")
            return
        end
        ui.onTestToggle.Event:Connect(function()
            debugPrint("Test toggle fired")
            Utils.notify("WoodzHUB", "Test button clicked!", 3)
        end)
        ui.onRebirth.Event:Connect(function()
            debugPrint("Rebirth toggle fired")
            local success = Remotes.rebirth(ctx)
            Utils.notify("WoodzHUB", success and "Rebirth fired successfully" or "Rebirth failed (no remote?)", 3)
        end)
        ui.onAutoFarmToggle.Event:Connect(function(on)
            debugPrint("AutoFarm toggle fired: " .. tostring(on))
            if on then
                Farm.start()
                Utils.notify("WoodzHUB", "Auto-Farm enabled", 3)
            else
                Farm.stop()
                Utils.notify("WoodzHUB", "Auto-Farm disabled", 3)
            end
        end)
        Utils.notify("WoodzHUB", "Hub, Utils, UI, Remotes, and Farm loaded successfully", 5)
        debugPrint("Hub initialized with Utils, UI, Remotes, and Farm")
    end
    debugPrint("Hub module defined")
    return Hub
end)()

debugPrint("Modules table created")

-- Entry point
if not Modules then
    debugPrint("Modules table is nil")
elseif not Modules.Hub then
    debugPrint("Hub module is nil")
elseif not Modules.Hub.start then
    debugPrint("Hub.start function is nil")
else
    debugPrint("Starting Hub")
    local success, err = pcall(function()
        Modules.Hub.start()
    end)
    if success then
        debugPrint("Hub.start
