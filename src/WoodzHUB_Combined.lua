-- WoodzHUB_Combined.lua
-- Combined script for Delta Executor to avoid HTTP restrictions

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create WoodzHUB folder
local WoodzHUB = ReplicatedStorage:FindFirstChild("WoodzHUB") or Instance.new("Folder")
WoodzHUB.Name = "WoodzHUB"
WoodzHUB.Parent = ReplicatedStorage

-- Module store
local Modules = {}

-- Utils.lua
Modules.Utils = (function()
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
end)()

-- Remotes.lua
Modules.Remotes = (function()
    local Remotes = {}
    function Remotes.init(ctx)
        ctx.state.autoAttackRemote = nil
        ctx.state.rebirthRemote    = nil
        for _, d in ipairs(ctx.services.ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteFunction") and d.Name:lower() == "autoattack" then
                ctx.state.autoAttackRemote = d
                break
            end
        end
        for _, d in ipairs(ctx.services.ReplicatedStorage:GetDescendants()) do
            local n = d.Name:lower()
            if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and (n:find("rebirth") or n:find("servercontrol") or n:find("bosszoneremote")) then
                ctx.state.rebirthRemote = d
                break
            end
        end
    end
    function Remotes.setAutoAttack(ctx, enabled)
        local rf = ctx.state.autoAttackRemote
        if not rf then return end
        pcall(function() rf:InvokeServer(enabled and true or false) end)
    end
    function Remotes.rebirth(ctx)
        local r = ctx.state.rebirthRemote
        if not r then return end
        pcall(function()
            if r:IsA("RemoteEvent") then r:FireServer() else r:InvokeServer() end
        end)
    end
    return Remotes
end)()

-- UI.lua
Modules.UI = (function()
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
        local AutoFarmBtn   = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,10), BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto-Farm: OFF" }, MainTab)
        local RebirthBtn    = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,50), BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto-Rebirth" }, MainTab)
        local AutoLevelBtn  = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,90), BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto Farm - Auto Level: OFF" }, MainTab)
        local TargetLabel   = Utils.new("TextLabel", {
            Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,130), BackgroundColor3=C.COLOR_BG_MED,
            TextColor3=C.COLOR_WHITE, Text="Current Target: None", TextSize=14, Font=Enum.Font.SourceSans
        }, MainTab)
        ctx.state.currentTargetLabel = TargetLabel
        local AutoCratesBtn   = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,10),  BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto Open Crates: OFF" }, OptTab)
        local Merchant1Btn    = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,50),  BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto Buy Mythics (Chicleteiramania): OFF" }, OptTab)
        local Merchant2Btn    = Utils.new("TextButton", { Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,90),  BackgroundColor3=C.COLOR_BTN, TextColor3=C.COLOR_WHITE, Text="Auto Buy Mythics (Bombardino Sewer): OFF" }, OptTab)
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
end)()

-- Crates.lua
Modules.Crates = (function()
    local Crates = {}
    local running = false
    local cratesRF_Use, cratesRE_UnlockFinish
    local crateOpenDelay = 1.0
    _G.unlockIdQueue = _G.unlockIdQueue or {}
    local seenUnlockIds = {}
    local crateCounts = {}
    local lastInvFetch, INV_REFRESH_COOLDOWN = 0, 5
    local crateNames = {
        "Bronze Crate","Silver Crate","Golden Crate","Demon Crate",
        "Sahur Crate","Void Crate","Vault Crate","Lime Crate","Chairchachi Crate",
        "To To To Crate","Market Crate","Gummy Crate","Yoni Crate","Grapefruit Crate",
        "Bus Crate","Cheese Crate","Graipus Crate","Pasta Crate","Te Te Te Te Crate",
    }
    local KNOWN_ID_KEYS = { "id","Id","ID","unlockId","unlock_id","UnlockId","ticket","Ticket","crateId","CrateId","resultId","ResultId","uid","UUID","Uuid" }
    local function looksLikeId(s)
        if typeof(s) ~= "string" then return false end
        if (#s >= 20 and #s <= 64) and s:match("^[0-9a-fA-F%-]+$") then return true end
        if s:match("^%d+$") and #s >= 6 then return true end
        return false
    end
    local function scanForIds(x, out)
        out = out or {}
        local t = typeof(x)
        if t == "string" and looksLikeId(x) then
            table.insert(out, x)
        elseif t == "table" then
            for k, v in pairs(x) do
                if type(k) == "string" then
                    for _, key in ipairs(KNOWN_ID_KEYS) do
                        if k == key and typeof(v) == "string" and looksLikeId(v) then
                            table.insert(out, v)
                        end
                    end
                end
                scanForIds(v, out)
            end
        end
        return out
    end
    local function dumpCrateEvent(_, ...)
        local args = { ... }
        local ids = {}
        for i = 1, #args do scanForIds(args[i], ids) end
        if #ids > 0 then
            for _, id in ipairs(ids) do
                table.insert(_G.unlockIdQueue, id)
            end
        end
    end
    local function sniffCrateEvents(ctx)
        local pkg  = ctx.services.ReplicatedStorage:WaitForChild("Packages")
        local knit = pkg:WaitForChild("Knit")
        local svcs = knit:WaitForChild("Services")
        local svc  = svcs:WaitForChild("CratesService")
        local RE   = svc:WaitForChild("RE")
        for _, ch in ipairs(RE:GetChildren()) do
            if ch:IsA("RemoteEvent") then
                ch.OnClientEvent:Connect(function(...) dumpCrateEvent(ch.Name, ...) end)
            end
        end
        RE.ChildAdded:Connect(function(ch)
            if ch:IsA("RemoteEvent") then
                ch.OnClientEvent:Connect(function(...) dumpCrateEvent(ch.Name, ...) end)
            end
        end)
        cratesRE_UnlockFinish = RE:FindFirstChild("UnlockCratesFinished")
    end
    local function getCratesUseRF(ctx)
        if cratesRF_Use and cratesRF_Use.Parent then return cratesRF_Use end
        local pkg  = ctx.services.ReplicatedStorage:FindFirstChild("Packages") or ctx.services.ReplicatedStorage:WaitForChild("Packages")
        local knit = pkg:FindFirstChild("Knit") or pkg:WaitForChild("Knit")
        local svcs = knit:FindFirstChild("Services") or knit:WaitForChild("Services")
        local svc  = svcs:FindFirstChild("CratesService") or svcs:WaitForChild("CratesService")
        local RF   = svc:FindFirstChild("RF") or svc:WaitForChild("RF")
        local rf   = RF:FindFirstChild("UseCrateItem") or RF:WaitForChild("UseCrateItem")
        if rf and rf:IsA("RemoteFunction") then
            cratesRF_Use = rf
            return rf
        end
        return nil
    end
    local function addCrateCount(map, name, count)
        if typeof(name) ~= "string" then return end
        if not name:lower():find("crate") then return end
        local n = tonumber(count) or 0
        if n <= 0 then return end
        map[name] = (map[name] or 0) + n
    end
    local function parseInventoryResult(res, out)
        out = out or {}
        if typeof(res) ~= "table" then return out end
        if #res > 0 then
            for i = 1, #res do
                local it = res[i]
                if typeof(it) == "table" then
                    local n = it.Name or it.name or it.DisplayName or it.ItemName or it.crateName or it.CrateName
                    local c = it.Count or it.count or it.Amount or it.amount or it.qty or it.Qty or it.quantity or it.Quantity or it.Owned or it.owned
                    if n and c then addCrateCount(out, n, c) end
                end
            end
        end
        for k, v in pairs(res) do
            if typeof(k) == "string" and (typeof(v) == "number" or typeof(v) == "string") then
                if k:lower():find("crate") then addCrateCount(out, k, v) end
            end
        end
        for _, v in pairs(res) do
            if typeof(v) == "table" then parseInventoryResult(v, out) end
        end
        return out
    end
    local candidateRFNames = { "GetOwnedCrates","GetCrateItems","GetCrates","GetInventory","GetItems","GetStorage","GetPlayerInventory","FetchInventory" }
    local candidateArgs = { {}, {"Crate"}, {"Crates"}, {["Type"]="Crate"}, {["Category"]="Crates"}, {"crate"}, {"crates"} }
    local function collectInventoryRFs(ctx)
        local rfs = {}
        local packages = ctx.services.ReplicatedStorage:FindFirstChild("Packages")
        if not packages then return rfs end
        local knit = packages:FindFirstChild("Knit"); if not knit then return rfs end
        local services = knit:FindFirstChild("Services"); if not services then return rfs end
        for _, svc in ipairs(services:GetChildren()) do
            local RF = svc:FindFirstChild("RF")
            if RF then
                for _, rf in ipairs(RF:GetChildren()) do
                    if rf:IsA("RemoteFunction") then
                        local lname = rf.Name:lower()
                        for _, nm in ipairs(candidateRFNames) do
                            if lname:find(nm:lower()) then
                                table.insert(rfs, rf)
                                break
                            end
                        end
                    end
                end
            end
        end
        return rfs
    end
    local function fetchCrateInventory(ctx)
        local counts = {}
        for _, rf in ipairs(collectInventoryRFs(ctx)) do
            for _, argpat in ipairs(candidateArgs) do
                local ok, res = pcall(function()
                    if #argpat == 0 then return rf:InvokeServer() else return rf:InvokeServer(table.unpack(argpat)) end
                end)
                if ok and res then parseInventoryResult(res, counts) end
            end
        end
        local csRF = getCratesUseRF(ctx)
        if csRF and csRF.Parent then
            local svcRF = csRF.Parent
            for _, nm in ipairs({"GetOwnedCrates","GetCrates","GetInventory"}) do
                local cand = svcRF:FindFirstChild(nm)
                if cand and cand:IsA("RemoteFunction") then
                    local ok, res = pcall(function() return cand:InvokeServer() end)
                    if ok and res then parseInventoryResult(res, counts) end
                end
            end
        end
        return counts
    end
    local function refreshCrateInventory(ctx, force)
        if not force and (tick() - (lastInvFetch or 0)) < INV_REFRESH_COOLDOWN then
            return crateCounts
        end
        local newCounts = fetchCrateInventory(ctx)
        if next(newCounts) ~= nil then
            crateCounts = newCounts
            lastInvFetch = tick()
        end
        return crateCounts
    end
    local function tryUnlockFromReturn(ret)
        if ret == nil then return end
        local ids = scanForIds(ret)
        for _, id in ipairs(ids) do
            table.insert(_G.unlockIdQueue, id)
        end
    end
    local function unlockWorker(ctx)
        while true do
            if cratesRE_UnlockFinish == nil or not cratesRE_UnlockFinish.Parent then
                local pkg  = ctx.services.ReplicatedStorage:FindFirstChild("Packages") or ctx.services.ReplicatedStorage:WaitForChild("Packages")
                local knit = pkg:FindFirstChild("Knit") or pkg:WaitForChild("Knit")
                local svcs = knit:FindFirstChild("Services") or knit:WaitForChild("Services")
                local svc  = svcs:FindFirstChild("CratesService") or svcs:WaitForChild("CratesService")
                local RE   = svc:FindFirstChild("RE") or svcs:WaitForChild("RE")
                cratesRE_UnlockFinish = RE and (RE:FindFirstChild("UnlockCratesFinished") or RE:WaitForChild("UnlockCratesFinished"))
            end
            local id = table.remove(_G.unlockIdQueue, 1)
            if id then
                if not seenUnlockIds[id] then
                    seenUnlockIds[id] = true
                    pcall(function()
                        if cratesRE_UnlockFinish and cratesRE_UnlockFinish:IsA("RemoteEvent") then
                            cratesRE_UnlockFinish:FireServer(id)
                        end
                    end)
                end
            else
                task.wait(0.05)
            end
        end
    end
    local function openLoop(ctx, ui, Utils)
        while running do
            local rf = getCratesUseRF(ctx)
            if not rf then
                Utils.notify("🎁 Crates","UseCrateItem RF not found, retrying...",3)
                task.wait(1)
            else
                refreshCrateInventory(ctx, false)
                for _, crate in ipairs(crateNames) do
                    if not running then break end
                    local have = crateCounts[crate] or 0
                    if have > 0 then
                        local ok, ret = pcall(function()
                            return rf:InvokeServer(crate, 1)
                        end)
                        if ok then
                            crateCounts[crate] = math.max(0, (crateCounts[crate] or 0) - 1)
                            tryUnlockFromReturn(ret)
                            if typeof(ret) == "string" then
                                local s = ret:lower()
                                if s:find("no") and s:find("crate") then refreshCrateInventory(ctx, true) end
                            end
                        else
                            refreshCrateInventory(ctx, true)
                        end
                        task.wait(crateOpenDelay)
                    end
                end
            end
        end
    end
    function Crates.init(ctx, ui, deps)
        Crates.ctx, Crates.ui, Crates.deps = ctx, ui, deps
        sniffCrateEvents(ctx)
        task.spawn(unlockWorker, ctx)
    end
    function Crates.setEnabled(on)
        local ctx, ui, Utils = Crates.ctx, Crates.ui, Crates.deps.Utils
        if on == running then return end
        running = on
        if ui and ui.setCrates then ui.setCrates(on) end
        if on then
            refreshCrateInventory(ctx, true)
            Utils.notify("🎁 Crates","Auto opening 1 of each crate you OWN.",4)
            task.spawn(openLoop, ctx, ui, Utils)
        else
            Utils.notify("🎁 Crates","Auto opening disabled.",3)
        end
    end
    return Crates
end)()

-- Merchants.lua
Modules.Merchants = (function()
    local Merchants = {}
    local mythicSkus       = { "Mythic1", "Mythic2", "Mythic3", "Mythic4" }
    local merchantCooldown = 0.1
    local M1_ON, M2_ON = false, false
    local function getMerchentBuyRemoteByService(ctx, serviceName)
        local RS = ctx.services.ReplicatedStorage
        local packages = RS:FindFirstChild("Packages") or RS:WaitForChild("Packages", 5)
        local knit     = packages and (packages:FindFirstChild("Knit") or packages:WaitForChild("Knit", 5))
        local services = knit and (knit:FindFirstChild("Services") or knit:WaitForChild("Services", 5))
        local svc      = services and (services:FindFirstChild(serviceName) or services:WaitForChild(serviceName, 5))
        local rf       = svc and (svc:FindFirstChild("RF") or svc:WaitForChild("RF", 5))
        local remote   = rf and (rf:FindFirstChild("MerchentBuy") or rf:WaitForChild("MerchentBuy", 5))
        if remote and remote:IsA("RemoteFunction") then return remote end
        return nil
    end
    local function merchantResultOK(res)
        local t = typeof(res)
        if t == "boolean" then return res end
        if t == "string" then
            local s = res:lower()
            return s:find("ok") or s:find("success") or s == "true"
        end
        if t == "table" then
            return (res.ok == true) or (res.success == true) or (res.Success == true) or (res[1] == true)
        end
        return false
    end
    local function autoBuyLoop(ctx, ui, Utils, serviceName, getEnabled, setBtnSuffix)
        local idx, consecutiveFails = 1, 0
        while getEnabled() do
            local sku = mythicSkus[idx]
            idx = (idx % #mythicSkus) + 1
            local remote = getMerchentBuyRemoteByService(ctx, serviceName)
            if not remote then
                setBtnSuffix("(remote?)")
                task.wait(1.0)
            else
                local ok, res = pcall(function()
                    return remote:InvokeServer(sku)
                end)
                if not ok then
                    consecutiveFails = math.min(consecutiveFails + 1, 5)
                    setBtnSuffix("(fail)")
                    task.wait(math.clamp(merchantCooldown * (1 + consecutiveFails * 0.5), 0.2, 3))
                else
                    local good = merchantResultOK(res)
                    if good then
                        consecutiveFails = 0
                        setBtnSuffix("(ok)")
                        task.wait(merchantCooldown)
                    else
                        consecutiveFails = math.min(consecutiveFails + 1, 5)
                        setBtnSuffix("(fail)")
                        local msg = typeof(res)=="table" and "table" or tostring(res or "")
                        msg = msg:lower()
                        local extra = (msg:find("cooldown") or msg:find("too fast")) and 0.4
                                   or (msg:find("insufficient") or msg:find("not enough")) and 0.6
                                   or 0
                        task.wait(merchantCooldown + extra)
                    end
                end
            end
        end
        setBtnSuffix("")
    end
    function Merchants.init(ctx, ui, deps)
        Merchants.ctx, Merchants.ui, Merchants.deps = ctx, ui, deps
    end
    function Merchants.setM1Enabled(on, ui)
        local ctx, Utils = Merchants.ctx, Merchants.deps.Utils
        M1_ON = on
        if ui and ui.setMerchant1 then ui.setMerchant1(on) end
        if on then
            Utils.notify("🌲 Merchant","Auto buy enabled for Chicleteiramania (SmelterMerchantService)",3)
            task.spawn(function()
                autoBuyLoop(ctx, ui, Utils, "SmelterMerchantService",
                    function() return M1_ON end,
                    function(suffix) if ui and ui.setMerchant1 then ui.setMerchant1(true, suffix) end end
                )
            end)
        else
            Utils.notify("🌲 Merchant","Auto buy disabled for Chicleteiramania",3)
        end
    end
    function Merchants.setM2Enabled(on, ui)
        local ctx, Utils = Merchants.ctx, Merchants.deps.Utils
        M2_ON = on
        if ui and ui.setMerchant2 then ui.setMerchant2(on) end
        if on then
            Utils.notify("🌲 Merchant","Auto buy enabled for Bombardino Sewer (SmelterMerchantService2)",3)
            task.spawn(function()
                autoBuyLoop(ctx, ui, Utils, "SmelterMerchantService2",
                    function() return M2_ON end,
                    function(suffix) if ui and ui.setMerchant2 then ui.setMerchant2(true, suffix) end end
                )
            end)
        else
            Utils.notify("🌲 Merchant","Auto buy disabled for Bombardino Sewer",3)
        end
    end
    return Merchants
end)()

-- Farm.lua
Modules.Farm = (function()
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
end)()

-- AutoLevel.lua
Modules.AutoLevel = (function()
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
end)()

-- Hub.lua
Modules.Hub = (function()
    local Hub = {}
    function Hub.start(config)
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
        local Utils     = Modules.Utils
        local Remotes   = Modules.Remotes
        local UI        = Modules.UI
        local Farm      = Modules.Farm
        local AutoLevel = Modules.AutoLevel
        local Crates    = Modules.Crates
        local Merchants = Modules.Merchants
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
end)()

-- Main.client.lua equivalent
Modules.Hub.start()