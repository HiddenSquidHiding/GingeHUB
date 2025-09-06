-- WoodzHUB_Minimal.lua
-- Minimal script to debug 'attempt to call a nil value' error

local function debugPrint(msg)
    print("[WoodzHUB Debug] " .. tostring(msg))
end

debugPrint("Script started")

-- Module store
local Modules = {}

-- Hub.lua
Modules.Hub = (function()
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
            debugPrint("Utils module missing")
            return
        end
        Utils.init(ctx)
        debugPrint("Hub initialized context with Utils")
        -- Same GUI code as before
        local PlayerGui = ctx.services.Players.LocalPlayer:WaitForChild("PlayerGui", 5)
        if PlayerGui then
            local ScreenGui = Instance.new("ScreenGui", PlayerGui)
            ScreenGui.ResetOnSpawn = false
            local Frame = Instance.new("Frame", ScreenGui)
            Frame.Size = UDim2.new(0, 200, 0, 50)
            Frame.Position = UDim2.new(0.5, -100, 0.5, -25)
            Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.Text = "WoodzHUB Loaded"
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Utils.notify("Test", "Utils loaded successfully", 5)
            debugPrint("Test GUI created")
        else
            debugPrint("PlayerGui not found")
        end
    end
    debugPrint("Hub module defined")
    return Hub
end)()

debugPrint("Modules table created")

-- Entry point
if Modules.Hub then
    debugPrint("Hub module exists")
    if Modules.Hub.start then
        debugPrint("Hub.start function exists")
        local success, err = pcall(function()
            Modules.Hub.start()
        end)
        if success then
            debugPrint("Hub.start executed successfully")
        else
            debugPrint("Error in Hub.start: " .. tostring(err))
        end
    else
        debugPrint("Hub.start is nil")
    end
else
    debugPrint("Hub module is nil")
end
