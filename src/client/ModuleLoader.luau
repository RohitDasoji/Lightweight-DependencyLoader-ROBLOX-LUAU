local replicatedstorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ModuleLoader = {}
local Loader = require(replicatedstorage:WaitForChild("Shared"):WaitForChild("ModuleLoader"))

ModuleLoader.LoadGui = function(ContextTable): { [string]: any } | boolean
	print("Loading Player")
	local folder: Folder = StarterPlayer.StarterPlayerScripts.Client.Gui:WaitForChild("GuiServices")
	local requiredModules = Loader.Require(folder)

	if not requiredModules then
		print("Failed to require")
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

	print("succ loaded gui")
	return Container
end

ModuleLoader.LoadPlayer = function(ContextTable): { [string]: any } | boolean
	local folder: Folder = StarterPlayer.StarterPlayerScripts.Client.Gui:WaitForChild("GuiServices")
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
	print("Succesfull loaded plr")
	return Container
end

return ModuleLoader
