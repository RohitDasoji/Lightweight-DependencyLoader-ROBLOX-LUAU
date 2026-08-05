local Players = game:GetService("Players")
local ModuleManeger = require(script.Parent.ModuleManeger)
local Classes = {}


Players.PlayerAdded:Connect(function(plr: Player)
    local Construct = ModuleManeger.new()

    local succ = Construct.Init(Construct)

    if not succ then
        warn("Failed to Initialize modules kicking player")
        plr:Kick("Client initilaized disconnect: Reason Module Failed to load")
        return false
    end

    Classes[plr] = Construct

    return true
end)

Players.PlayerAdded:Connect(function(plr: Player)
    local ModuleManeger = Classes[plr]
    
    if not ModuleManeger then
        return false
    end

    ModuleManeger.Remove(ModuleManeger)

    return true
end)