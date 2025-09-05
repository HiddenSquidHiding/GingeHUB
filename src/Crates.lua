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
