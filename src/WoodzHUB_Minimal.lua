-- WoodzHUB_Minimal_Utils.lua
-- Minimal script to debug 'Utils module missing' and 'attempt to call a nil value' errors

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
            COLOR_WHITE = Color3.fromRGB(255, 255, 255),
            SIZE_MAIN = UDim2.new(0, 200, 0, 50),
        }
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
        local gui = Instance.new("ScreenGui", PlayerGui)
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 2000000000
        local frame = Instance.new("Frame", gui)
        frame.Size = UDim2.new(0, 200, 0, 50)
        frame.Position = UDim2.new(0.5, -100, 0.5, -25)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = title .. ": " .. content
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.SourceSans
        task.spawn(function()
            task.wait(duration or 5)
            gui:Destroy()
        end)
        debugPrint("Notification GUI created")
    end
    debugPrint("Utils module defined")
    return Utils
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
            },
            state = {},
            constants = {},
        }
        local Utils = Modules.Utils
        if not Utils then
            debugPrint("Utils module is nil in Hub.start")
            return
        end
        Utils.init(ctx)
        Utils.notify("WoodzHUB", "Hub and Utils loaded successfully", 5)
        debugPrint("Hub initialized with Utils")
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
        debugPrint("Hub.start executed successfully")
    else
        debugPrint("Error in Hub.start: " .. tostring(err))
    end
end
