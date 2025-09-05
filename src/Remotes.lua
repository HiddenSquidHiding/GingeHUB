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
