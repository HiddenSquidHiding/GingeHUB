local Utils = {}

function Utils.init(ctx)
    ctx.constants = {
        COLOR_BG_DARK     = Color3.fromRGB(30, 30, 30),
        COLOR_BG          = Color3.fromRGB(40, 40, 40),
        COLOR_BG_MED      = Color3.fromRGB(50, 50, 50),
        COLOR_BTN         = Color3.fromRGB(60, 60, 60),
        COLOR_BTN_ACTIVE  = Color3.fromRGB(80, 80, 80),
        COLOR_WHITE       = Color3.fromRGB(255, 255, 255),
        SIZE_MAIN         = UDim2.new(0, 400, 0, 540),
        SIZE_MIN          = UDim2.new(0, 400, 0, 50),
    }
end

function Utils.new(t, props, parent)
    local i = Instance.new(t)
    if props then for k,v in pairs(props) do i[k]=v end end
    if parent then i.Parent = parent end
    return i
end

function Utils.notify(title, content, duration)
    local Players = game:GetService("Players")
    local player  = Players.LocalPlayer
    local PlayerGui = player:WaitForChild("PlayerGui")

    local COLOR_BG_DARK = Color3.fromRGB(30, 30, 30)
    local COLOR_BG_MED  = Color3.fromRGB(50, 50, 50)
    local COLOR_WHITE   = Color3.fromRGB(255, 255, 255)

    local gui  = Utils.new("ScreenGui", { ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=2000000000 }, PlayerGui)
    local frame= Utils.new("Frame", { Size=UDim2.new(0,300,0,100), Position=UDim2.new(1,-310,0,10), BackgroundColor3=COLOR_BG_DARK }, gui)
    Utils.new("TextLabel", { Size=UDim2.new(1,0,0,30), BackgroundColor3=COLOR_BG_MED, TextColor3=COLOR_WHITE, Text=title, TextSize=14, Font=Enum.Font.SourceSansBold }, frame)
    Utils.new("TextLabel", { Size=UDim2.new(1,-10,0,60), Position=UDim2.new(0,5,0,35), BackgroundTransparency=1, TextColor3=COLOR_WHITE, Text=content, TextWrapped=true, TextSize=14, Font=Enum.Font.SourceSans }, frame)
    task.spawn(function() task.wait(duration or 5) gui:Destroy() end)
end

function Utils.waitForCharacter(player)
    while not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") do
        player.CharacterAdded:Wait()
        task.wait(0.1)
    end
    return player.Character
end

function Utils.isValidCFrame(cf)
    if not cf then return false end
    local p = cf.Position
    return p.X == p.X and p.Y == p.Y and p.Z == p.Z
       and math.abs(p.X) < 10000 and math.abs(p.Y) < 10000 and math.abs(p.Z) < 10000
end

function Utils.findBasePart(model)
    if not model then return nil end
    local candidates = { "HumanoidRootPart","PrimaryPart","Body","Hitbox","Root","Main" }
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
        local names = { "Nuclearo Core","NuclearCore","Core","NuclearoCore","nuclearo core" }
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

function Utils.preventAFK(ctx)
    local VirtualUser = ctx.services.VirtualUser
    task.spawn(function()
        while (ctx.state.autoFarmEnabled or ctx.state.autoLevelEnabled) do
            VirtualUser:CaptureController()
            VirtualUser:SetKeyDown(Enum.KeyCode.W); task.wait(0.1)
            VirtualUser:SetKeyUp(Enum.KeyCode.W);   task.wait(0.1)
            VirtualUser:MoveMouse(Vector2.new(10, 0))
            task.wait(60)
        end
    end)
end

return Utils
