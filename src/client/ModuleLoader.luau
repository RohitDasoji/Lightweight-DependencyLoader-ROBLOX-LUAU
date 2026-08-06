local replicatedstorage = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
local ModuleLoader = {}
local Loader = require(replicatedstorage.Shared.ModuleLoader)

ModuleLoader.LoadGui = function(ContextTable): { [string]: any } | boolean
	local folder: Folder = client.Gui.GuiServices
	local requiredModules = Loader.Require(folder)

	if not requiredModules then
		return false
	end

	local Container, succ = Loader.Load(ContextTable, requiredModules)

	if not succ then
		warn("Failed to load services inside GuiServices LOCALSCRIPT")
		return false
	end

	if type(Container) ~= "table" then
		warn("Returned value is not = to a table inside guiservices LOCALSCRIPT")
		return false
	end

	return Container
end

ModuleLoader.LoadPlayer = function(ContextTable): { [string]: any } | boolean
	local folder: Folder = client.client.services
	local requiredModules = Loader.Require(folder)

	if not requiredModules then
		return false
	end

	local Container, succ = Loader.Load(ContextTable, requiredModules)

	if not succ then
		warn("Failed to load services inside GuiServices LOCALSCRIPT")
		return false
	end

	if type(Container) ~= "table" then
		warn("Returned value is not = to a table inside playerservices LOCALSCRIPT")
		return false
	end

	return Container
end

return ModuleLoader
