-- WoodzHUB_Minimal_Farm_SimplifiedFull.lua
-- Simplified full Farm module to debug 'attempt to call a nil value' error

local function debugPrint(msg)
    print("[WoodzHUB Debug] " .. tostring(msg))
end

debugPrint("Script started")

-- Module store
local Modules = {}

-- Utils.lua (Full)
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
    function Utils.waitForCharacter(player)
        debugPrint("Utils.waitForCharacter called")
        if not player then return end
        while not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") do
            player.CharacterAdded:Wait()
            task.wait(0.1)
        end
        return player.Character
    end
    function Utils.isValidCFrame(cf)
        debugPrint("Utils.isValidCFrame called")
        if not cf then return false end
        local p = cf.Position
        return p.X == p.X and p.Y == p.Y and p.Z == p.Z
            and math.abs(p.X) < 10000 and math.abs(p.Y) < 10000 and math.abs(p.Z) < 10000
    end
    function Utils.findBasePart(model)
        debugPrint("Utils.findBasePart called for model: " .. tostring(model))
        if not model then return nil end
        local candidates = { "HumanoidRootPart", "PrimaryPart", "Body", "Hitbox", "Root", "Main" }
        for _, n in ipairs(candidates) do
            local part = model:FindFirstChild(n)
            if part and part:IsA("BasePart") then return part end
        end
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
        return nil
    end
    function Utils.searchFoldersList()
        debugPrint("Utils.searchFoldersList called")
        local Workspace = game:GetService("Workspace")
        local list = {
            Workspace:FindFirstChild("Monsters"),
            Workspace:FindFirstChild("MiniBosses"),
            Workspace:FindFirstChild("Enemies"),
            Workspace:FindFirstChild("HideDuringEvent"),
            Workspace:FindFirstChild("Titan"),
        }
        local world = Workspace:FindFirstChild("World")
        if world then
            local names = { "Nuclearo Core", "NuclearCore", "Core", "NuclearoCore", "nuclearo core" }
            for _, nm in ipairs(names) do
                local f = world:FindFirstChild(nm)
                if f and f:FindFirstChild("Eatables") then
                    table.insert(list, f.Eatables)
                    break
                end
            end
        end
        return list
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

-- Farm.lua (Simplified Full)
Modules.Farm = (function()
    debugPrint("Defining Farm module")
    local Farm = {}
    local running = false
    local function refreshEnemyList(ctx)
        debugPrint("Farm.refreshEnemyList called")
        local Players = ctx.services.Players
        local weatherEventModels = { "Chicleteira", "YONII", "GRAIPUS MEDUS", "Market Crate", "BOSS" }
        local function isIn(list, lname)
            for _, n in ipairs(list) do
                if lname == n:lower() then return true end
            end
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
        for _, folder in ipairs(Utils.searchFoldersList()) do
            if folder then classify(folder) end
        end
        local out = {}
        for _, e in ipairs(weather) do table.insert(out, e) end
        for _, e in ipairs(other) do table.insert(out, e) end
        return out
    end
    local function loop(ctx, ui, deps)
        debugPrint("Farm.loop started")
        local Utils, Remotes = deps.Utils, deps.Remotes
        Remotes.setAutoAttack(ctx, true)
        while running do
            local enemies = refreshEnemyList(ctx)
            if #enemies == 0 then
                debugPrint("No enemies found")
                Utils.notify("WoodzHUB", "No enemies found", 3)
            else
                debugPrint("Found " .. #enemies .. " enemies")
                local enemyNames = {}
                for _, enemy in ipairs(enemies) do
                    table.insert(enemyNames, enemy.Name)
                end
                Utils.notify("WoodzHUB", "Found " .. #enemies .. " enemies: " .. table.concat(enemyNames, ", "), 5)
            end
            task.wait(1)
        end
        Remotes.setAutoAttack(ctx, false)
        debugPrint("Farm.loop stopped")
    end
    function Farm.init(ctx, ui, deps)
        debugPrint("Farm.init called")
        Farm.ctx, Farm.ui, Farm.deps = ctx, ui, deps
    end
    function Farm.start()
        debugPrint("Farm.start called")
        if running then
            debugPrint("Farm already running")
            return
        end
        running = true
        local ctx, ui, deps = Farm.ctx, Farm.ui, Farm.deps
        if not ctx or not deps then
            debugPrint("Farm.start failed: ctx or deps nil")
            running = false
            return
        end
        ctx.state.autoFarmEnabled = true
        task.spawn(loop, ctx, ui, deps)
    end
    function Farm.stop()
        debugPrint("Farm.stop called")
        if not running then
            debugPrint("Farm not running")
            return
        end
        running = false
        if Farm.ctx then
            Farm.ctx.state.autoFarmEnabled = false
        else
            debugPrint("Farm.stop failed: ctx nil")
        end
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
                Workspace = game:GetService("Workspace"),
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
