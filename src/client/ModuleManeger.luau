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
	print("creatingplayer")
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

-- Instance type for the manager
type cls = {
	Id: number,
	guiServices: { [string]: any },
	services: { [string]: any },
	plr: Player?,
	Connections: { [number]: any },
	Initialized: boolean,
	Init: (self: any) -> boolean,
	GetGuiService: (self: any, Servicename: string) -> any?,
	GetService: (self: any, Servicename: string) -> any?,
	Remove: (self: any) -> (),
}

function InitModules.Init(self: cls)
	if self.Initialized then
		return true
	end

	self.Initialized = true

	local services = ModuleLoader.LoadPlayer(self)

	if type(services) ~= "table" then
		print("Failed To initialize local player services")
		return false
	end

	self.services = services

	local guis = ModuleLoader.LoadGui(self)

	if type(guis) ~= "table" then
		print("Failed To initialize gui services")
		return false
	end

	self.guiServices = guis

	return true
end

function InitModules.GetGuiService(self: cls, Servicename)
	local service = GetService(self.guiServices, Servicename)

	if not service then
		print(
			"Failed to get service because of invalid service or service does not exist inside guiservices"
				.. tostring(Servicename)
		)
	end

	return service
end

function InitModules.GetService(self: cls, Servicename)
	local service = GetService(self.services, Servicename)

	if not service then
		print(
			"Failed to get service because of invalid service or service does not exist inside services"
				.. tostring(Servicename)
		)
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
