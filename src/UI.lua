local UI = {}

function UI.mount(ctx, deps)
    local Utils = deps.Utils
    local Players = ctx.services.Players
    local player  = Players.LocalPlayer
    local PlayerGui = player:WaitForChild("PlayerGui")
    local C = ctx.constants

    local ScreenGui = Utils.new("ScreenGui", {
        Name="WoodzHUB",
        ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        DisplayOrder=2000000000,
        IgnoreGuiInset=false
    }, PlayerGui)

    local Main = Utils.new("Frame", { Size=C.SIZE_MAIN, Position=UDim2.new(0.5,-200,0.5,-270), BackgroundColor3=C.COLOR_BG_DARK, BorderSizePixel=0 }, ScreenGui)
    Utils.new("TextLabel", {
        Size=UDim2.new(1,-60,0,50), BackgroundColor3=C.COLOR_BG_MED, Text="🌲 WoodzHUB - Brainrot Evolution",
        TextColor3=C.COLOR_WHITE, TextSize=14, Font=Enum.Font.SourceSansBold
    }, Main)

    local Tabs = Utils.new("Frame", { Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,50), BackgroundColor3=C.COLOR_BG }, Main)
    local MainTabBtn  = Utils.new("TextButton", { Size=UDim2.new(0.5,0,1,0), Text="Main", TextColor3=C.COLOR_WHITE, BackgroundColor3=C.COLOR_BTN }, Tabs)
    local OptTabBtn   = Utils.new("TextButton", { Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0), Text="Options", TextColor3=C.COLOR_WHITE, BackgroundColor3=C.COLOR_BG }, Tabs)

    local MainTab = Utils.new("Frame", { Size=UDim2.new(1,0,1,-80), Position=UDim2.new(0,0,0,80), BackgroundTransparency=1 }, Main)
    local OptTab  = Utils.new("Frame", { Size=UDim2.new(1,0,1,-80), Position=UDim2.new(0,0,0,80), BackgroundTransparency=1, Visible=false }, Main)

    local function showMain()
        MainTab.Visible, OptTab.Visible = true, false
        MainTabBtn.BackgroundColor3, OptTabBtn.BackgroundColor3 = C.COLOR_BTN, C.COLOR_BG
    end
    local function showOpts()
        MainTab.Visible, OptTab.Visible = false, true
        MainTabBtn.BackgroundColor3, OptTabBtn.BackgroundColor3 = C.COLOR_BG, C.COLOR_BTN
    end
    MainTabBtn.MouseButton1Click:Connect(showMain)
    OptTabBtn.MouseButton1Click:Connect(showOpts)

    -- Main buttons
    local AutoFarmBtn   = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,10), BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto-Farm: OFF" }, MainTab)
    local RebirthBtn    = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,50), BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto-Rebirth" }, MainTab)
    local AutoLevelBtn  = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,90), BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto Farm - Auto Level: OFF" }, MainTab)

    local TargetLabel   = Utils.new("TextLabel", {
        Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,130), BackgroundColor3=C.COLOR_BG_MED,
        TextColor3=C.COLOR_WHITE, Text="Current Target: None", TextSize=14, Font=Enum.Font.SourceSans
    }, MainTab)
    ctx.state.currentTargetLabel = TargetLabel

    -- Options
    local AutoCratesBtn   = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,10),  BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto Open Crates: OFF" }, OptTab)
    local Merchant1Btn    = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,50),  BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto Buy Mythics (Chicleteiramania): OFF" }, OptTab)
    local Merchant2Btn    = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,90),  BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto Buy Mythics (Bombardino Sewer): OFF" }, OptTab)

    -- Signals
    local onAutoFarmToggle    = Instance.new("BindableEvent")
    local onAutoLevelToggle   = Instance.new("BindableEvent")
    local onRebirth           = Instance.new("BindableEvent")
    local onAutoCratesToggle  = Instance.new("BindableEvent")
    local onMerchant1Toggle   = Instance.new("BindableEvent")
    local onMerchant2Toggle   = Instance.new("BindableEvent")

    AutoFarmBtn.MouseButton1Click:Connect(function()
        ctx.state.autoFarmEnabled = not ctx.state.autoFarmEnabled
        AutoFarmBtn.Text = "Auto-Farm: " .. (ctx.state.autoFarmEnabled and "ON" or "OFF")
        AutoFarmBtn.BackgroundColor3 = ctx.state.autoFarmEnabled and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        onAutoFarmToggle:Fire(ctx.state.autoFarmEnabled)
    end)

    AutoLevelBtn.MouseButton1Click:Connect(function()
        ctx.state.autoLevelEnabled = not ctx.state.autoLevelEnabled
        AutoLevelBtn.Text = "Auto Farm - Auto Level: " .. (ctx.state.autoLevelEnabled and "ON" or "OFF")
        AutoLevelBtn.BackgroundColor3 = ctx.state.autoLevelEnabled and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        onAutoLevelToggle:Fire(ctx.state.autoLevelEnabled)
    end)

    RebirthBtn.MouseButton1Click:Connect(function()
        onRebirth:Fire()
    end)

    AutoCratesBtn.MouseButton1Click:Connect(function()
        local on = AutoCratesBtn.Text:find("OFF") ~= nil
        AutoCratesBtn.Text = "Auto Open Crates: " .. (on and "ON" or "OFF")
        AutoCratesBtn.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        onAutoCratesToggle:Fire(on)
    end)

    Merchant1Btn.MouseButton1Click:Connect(function()
        local on = Merchant1Btn.Text:find("OFF") ~= nil
        Merchant1Btn.Text = "Auto Buy Mythics (Chicleteiramania): " .. (on and "ON" or "OFF")
        Merchant1Btn.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        onMerchant1Toggle:Fire(on)
    end)

    Merchant2Btn.MouseButton1Click:Connect(function()
        local on = Merchant2Btn.Text:find("OFF") ~= nil
        Merchant2Btn.Text = "Auto Buy Mythics (Bombardino Sewer): " .. (on and "ON" or "OFF")
        Merchant2Btn.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        onMerchant2Toggle:Fire(on)
    end)

    return {
        refs = {
            TargetLabel   = TargetLabel,
            AutoCratesBtn = AutoCratesBtn,
            Merchant1Btn  = Merchant1Btn,
            Merchant2Btn  = Merchant2Btn,
        },
        onAutoFarmToggle   = onAutoFarmToggle,
        onAutoLevelToggle  = onAutoLevelToggle,
        onRebirth          = onRebirth,
        onAutoCratesToggle = onAutoCratesToggle,
        onMerchant1Toggle  = onMerchant1Toggle,
        onMerchant2Toggle  = onMerchant2Toggle,
        setAutoFarm = function(on)
            ctx.state.autoFarmEnabled = on
            AutoFarmBtn.Text = "Auto-Farm: " .. (on and "ON" or "OFF")
            AutoFarmBtn.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        end,
        setAutoLevel = function(on)
            ctx.state.autoLevelEnabled = on
            AutoLevelBtn.Text = "Auto Farm - Auto Level: " .. (on and "ON" or "OFF")
            AutoLevelBtn.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        end,
        setCrates = function(on)
            AutoCratesBtn.Text = "Auto Open Crates: " .. (on and "ON" or "OFF")
            AutoCratesBtn.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        end,
        setMerchant1 = function(on, suffix)
            Merchant1Btn.Text = "Auto Buy Mythics (Chicleteiramania): " .. (on and "ON" or "OFF") .. (suffix and (" " .. suffix) or "")
            Merchant1Btn.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        end,
        setMerchant2 = function(on, suffix)
            Merchant2Btn.Text = "Auto Buy Mythics (Bombardino Sewer): " .. (on and "ON" or "OFF") .. (suffix and (" " .. suffix) or "")
            Merchant2Btn.BackgroundColor3 = on and C.COLOR_BTN_ACTIVE or C.COLOR_BTN
        end,
    }
end

return UI
