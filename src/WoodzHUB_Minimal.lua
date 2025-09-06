-- BareBones.lua
print("[BareBones Debug] Script started")
local function test()
    print("[BareBones Debug] Test function called")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    if player then
        print("[BareBones Debug] LocalPlayer found")
        local PlayerGui = player:WaitForChild("PlayerGui", 5)
        if PlayerGui then
            local ScreenGui = Instance.new("ScreenGui", PlayerGui)
            ScreenGui.ResetOnSpawn = false
            local Frame = Instance.new("Frame", ScreenGui)
            Frame.Size = UDim2.new(0, 100, 0, 50)
            Frame.Position = UDim2.new(0.5, -50, 0.5, -25)
            Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.Text = "Test GUI"
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            print("[BareBones Debug] GUI created")
        else
            print("[BareBones Debug] PlayerGui not found")
        end
    else
        print("[BareBones Debug] No LocalPlayer")
    end
end
local success, err = pcall(test)
if success then
    print("[BareBones Debug] Test executed successfully")
else
    print("[BareBones Debug] Error: " .. tostring(err))
end
