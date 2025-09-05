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
