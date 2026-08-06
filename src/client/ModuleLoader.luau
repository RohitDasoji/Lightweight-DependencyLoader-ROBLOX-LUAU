local replicatedstorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ModuleLoader = {}
local Loader = require(replicatedstorage:WaitForChild("Shared"):WaitForChild("ModuleLoader"))

local function resolveGuiFolder()
	local root = script.Parent
	if root then
		local gui = root:FindFirstChild("Gui")
		if gui then
			local gs = gui:FindFirstChild("GuiServices")
			if gs then
				return gs
			end
		end
	end

	local clientRoot = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Client")
	return clientRoot:WaitForChild("Gui"):WaitForChild("GuiServices")
end

local function resolvePlayerFolder()
	local root = script.Parent
	if root then
		local clientFolder = root:FindFirstChild("Client")
		if clientFolder then
			local services = clientFolder:FindFirstChild("Services")
			if services then
				return services
			end
		end
		local servicesDirect = root:FindFirstChild("services")
		if servicesDirect then
			return servicesDirect
		end
	end

	local clientRoot = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Client")
	if clientRoot:FindFirstChild("client") and clientRoot.client:FindFirstChild("services") then
		return clientRoot.client:WaitForChild("services")
	end

	return clientRoot:FindFirstChild("services") and clientRoot:WaitForChild("services") or nil
end

ModuleLoader.LoadGui = function(ContextTable): { [string]: any } | boolean
	print("Loading Player")
	local folder: Folder = resolveGuiFolder()
	if not folder then
		warn("Could not resolve GuiServices folder")
		return false
	end
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
	local folder: Folder = resolvePlayerFolder()
	if not folder then
		warn("Could not resolve player services folder")
		return false
	end
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
