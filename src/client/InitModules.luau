--!strict
local Players = game:GetService("Players")


type service = {}



local InitModules = {}
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
    self.guiServices = {}
    self.services = {}
    self.plr = Players.LocalPlayer
    self.Connections = {}
    self.Initialized = false


    return self
end

type Objects = typeof(InitModules.new())

type cls = Objects & {
    Init: (self: cls) -> (),
    GetGuiService: (self: cls) -> string
}

function InitModules.Init(self: cls)
    if self.Initialized then
        return
    end

    self.Initialized = true

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



return InitModules