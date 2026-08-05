--!strict
local Players = game:GetService("Players")
local ModuleLoader = require(script.Parent.ModuleLoader)


type service = {}



local InitModules = {}
local activeclasses = {}
InitModules.__index = InitModules


local function GetService(Table, Servicename)
    if type(Table) ~= "table" then
        print("Inside get service table is not a table")
        return false
    end

    local service = Table[Servicename]

    if not service then
        return false
    end

    return service
end



function InitModules.new()
    local self = setmetatable({}, InitModules)
    self.Id = 12238498234
    self.guiServices = {}
    self.services = {}
    self.plr = Players.LocalPlayer
    self.Connections = {}
    self.Initialized = false
    activeclasses[self.Id] = self


    return self
end

type Objects = typeof(InitModules.new())

type cls = Objects & {
    Init: (self: cls) -> (),
    GetGuiService: (self: cls) -> string
}

function InitModules.Init(self: cls)
    if self.Initialized then
        return true
    end

    self.Initialized = true
    local succ = ModuleLoader.LoadPlayer(self)
    
    if not succ then
        return false
    end

    local succ2 = ModuleLoader.LoadGui(self)

    if not succ2 then
        return false
    end

    return true
end

function InitModules.GetGuiService(self: cls,Servicename)
    local service = GetService(self.guiServices, Servicename)
    
    if not service then
        print("Failed to get service because of invalid service or service does not exist inside guiservices" .. tostring(Servicename))
    end

    return service
end

function InitModules.GetService(self: cls, Servicename)
    local service = GetService(self.services, Servicename)
    
    
    if not service then
        print("Failed to get service because of invalid service or service does not exist inside services" .. tostring(Servicename))
    end

    return service
end

function InitModules.Remove(self: cls)
    for _, Connection in ipairs(self.Connections) do
        if typeof(Connection) == "RBXScriptConnection" then
            Connection:Disconnect()
            Connection = nil
        end
    end
    activeclasses[self.Id] = nil
end



return InitModules