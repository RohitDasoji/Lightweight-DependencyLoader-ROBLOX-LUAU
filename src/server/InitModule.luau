-- Services --
local ServerScriptService = game:GetService("ServerScriptService")
-- Server Modules --
local RemotesManager = require(ServerScriptService.Server.ModuleHelper.RemotesManeger)
local ModuleLoader = require(ServerScriptService.Server.Services.ModuleLoader)
local DataManager = require(ServerScriptService.Server.ModuleHelper.DataManager)

local RuntimeModule = {}

RuntimeModule.RuntimeData = {}

RuntimeModule.ServerData = {
	RequiredModules = {},
	Modules = {},

	Remotes = {
		"Restock",
		"Buy",
		"CurrencyUpdate",
	},

	IsModulesLoaded = false,
}

function RuntimeModule:InitServer()
	for _, RemoteString in ipairs(self.ServerData.Remotes) do
		RemotesManager:Create(RemoteString)
	end

	local Container, PlayerModules = ModuleLoader.LoadServer({})

	if not Container or not PlayerModules then
		warn("Server Services failed to initalize")
		return false
	end


	self.ServerData.RequiredModules = PlayerModules   -- ✅ was missing
	self.ServerData.Modules = Container

	self.ServerData.IsModulesLoaded = true
	return true
end

function RuntimeModule:GetPlayer(plr: Player)
	return self.RuntimeData[plr]
end

function RuntimeModule:AddPlayer(plr: Player): boolean
	local PlayerData = {
		DataLoaded = false,
		Data = nil,
		Modules = {},
		Player = plr,
	}

	self.RuntimeData[plr] = PlayerData

	-- Create Data Manager
	PlayerData.Data = DataManager.new(plr)

	-- Load Data
	local success = PlayerData.Data:Load()

	-- Data failed to load
	if not success then
		self:RemovePlayer(plr)
		return false
	end

	-- Player left while loading
	if not self.RuntimeData[plr] then
		PlayerData.Data:Release()
		return false
	end

	-- Finish setup
	PlayerData.DataLoaded = true

	if PlayerData.Data == nil then
		return false
	end

	PlayerData.GetData = function()
		if not PlayerData.DataLoaded then
			warn("Data Has not Been Loaded Could Not execute function .getdata")
			return
		end

		local Data = PlayerData.Data:GetData()

		if not Data then
			warn("Data could not be retrived BoolValue = " .. tostring(Data))
			return
		end

		return Data
	end

	PlayerData.GetModule = function(ModuleObject)
		local Module = PlayerData.Modules[ModuleObject.Name]

		if not Module then
			warn("Module Not Found Please Try Again")
			return
		end

		return Module
	end

	local Loaded = ModuleLoader.LoadPlayer(PlayerData, RuntimeModule.ServerData.RequiredModules)

	if not Loaded then
		warn("Failed to Load Services Kicking Player")
		return false
	end

	-- Loaded is the Container of live module instances returned by LoadPlayer.
	-- This was never being stored, so PlayerData.Modules (and GetModule) stayed empty.
	PlayerData.Modules = Loaded

	return true
end

function RuntimeModule:RemovePlayer(plr)
	local PlayerData = self.RuntimeData[plr]

	if not PlayerData then
		return
	end

	if PlayerData.Data then
		PlayerData.Data:Release()
		PlayerData.Data = nil
	end

	self.RuntimeData[plr] = nil
end

function RuntimeModule:RemoveAllPlayers()
	for plr, PlayerData in pairs(self.RuntimeData) do
		if PlayerData.Data then
			PlayerData.Data:Release()
		end

		self.RuntimeData[plr] = nil
	end

	self.RuntimeData = {}
end

return RuntimeModule
