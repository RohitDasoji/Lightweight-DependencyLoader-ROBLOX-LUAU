
local replicatedstorage = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService").Server
local ModuleLoader = {}
local Loader = require(replicatedstorage.Shared.ModuleLoader)

type Container = {[string]: {[string]: any | any}}


ModuleLoader.LoadServer = function(ContextTable): Container | boolean | {[string]: any}
    local ServerFolder: Folder = Server.Services.ServerServices
    local PlayerFolder: Folder = Server.Services.Services

    local RequiredServer = Loader.Require(ServerFolder)
    local RequiredPlayer = Loader.Require(PlayerFolder)

    if not RequiredPlayer or not RequiredServer then
        return false, false
    end

    local Container, succ = Loader.Load(ContextTable, RequiredServer)

    if not succ then
        warn("Failed to load services inside ServerServices SERVER")
        return false, RequiredPlayer
    end

    if type(Container) ~= "table" then
        warn("Returned value is not = to a table inside ServerServices SERVER")
        return false, RequiredPlayer
    end

    return Container, RequiredPlayer
end


ModuleLoader.LoadPlayer = function(ContextTable, RequiredPlayer): Container | boolean

    local Container, succ = Loader.Load(ContextTable, RequiredPlayer)

    if not succ then
        warn("Failed to load services inside PlayerServices SERVER")
        return false
    end

    if type(Container) ~= "table" then
        warn("Returned value is not = to a table inside PlayerServices SERVER")
        return false
    end

    return Container
end

return ModuleLoader