local Rs = game:GetService("RunService")

local ModuleLoader = {}

export type LoaderOptions = {
	Order: { string },
	Loading: { [string]: boolean },
	Ordered: { [string]: boolean },
	Initialized: { [string]: boolean },
	Created: { [string]: boolean },
}
export type HeartbeatKey = string | Player | number

export type HeartbeatEntry = {
	Class: any,
	Key: HeartbeatKey?,
}

local Connections: { [string]: RBXScriptConnection? } = {
	Heartbeat = nil,
	Stepped = nil,
	RenderStepped = nil,
	PreRender = nil,
}

local Containers: { [string]: { HeartbeatEntry } } = {
	Heartbeat = {},
	Stepped = {},
	RenderStepped = {},
	PreRender = {},
}

export type dependency = string | ModuleScript

export type dependencies = { dependency }

export type ModuleObject = {
	Init: ((self: any) -> ())?,
}

export type Classmodules = { [string]: ModuleObject }

export type ContextTable = { [string]: any }

export type Module = {
	new: (ContextTable: any) -> any,
	Init: ((self: any) -> ())?,
	Dependencies: { dependency }?,
}

export type requiredmodules = { [string]: Module }

function ModuleLoader.LoadModules(
	ContextTable: ContextTable,
	RequiredModules: requiredmodules,
	ContainerOfModules: Classmodules
)
	local LoaderOptions: LoaderOptions = {
		Order = {},
		Loading = {},
		Created = {},
		Initialized = {},
		Ordered = {},
	}

	for Modulename in pairs(RequiredModules) do
		local succ, err = pcall(ModuleLoader.SetOrder, LoaderOptions, Modulename, RequiredModules)

		if not succ then
			warn("Failed to set order: " .. tostring(err))
			return false
		end
	end

	local Createcls = ModuleLoader.CreateClasses(ContextTable, LoaderOptions, RequiredModules, ContainerOfModules)

	if not Createcls then
		warn("Could not create classes; try again")
		return false
	end

	local Initialized = ModuleLoader.InitializeModules(LoaderOptions, RequiredModules, ContainerOfModules)

	if not Initialized then
		warn("Could not initialize modules; please try again")
		return false
	end

	return true
end

local function Register(EventName: string, RunServiceEvent: RBXScriptSignal, Services, Key: HeartbeatKey?)
	local Container = Containers[EventName]

	for _, Class in pairs(Services) do
		local UpdateFn = Class.Update or Class.update
		if typeof(UpdateFn) == "function" then
			table.insert(Container, { Class = Class, Key = Key })
		end
	end

	if not Connections[EventName] then
		Connections[EventName] = RunServiceEvent:Connect(function(...)
			for _, Entry in ipairs(Container) do
				local UpdateFn = Entry.Class[EventName] or Entry.Class[EventName:lower()]
				if typeof(UpdateFn) == "function" then
					UpdateFn(...)
				end
			end
		end)
	end
end

function ModuleLoader.Heartbeat(Services, Key: HeartbeatKey?)
	Register("Heartbeat", Rs.Heartbeat, Services, Key)
end

function ModuleLoader.Stepped(Services, Key: HeartbeatKey?)
	Register("Stepped", Rs.Stepped, Services, Key)
end

function ModuleLoader.RenderStepped(Services, Key: HeartbeatKey?)
	Register("RenderStepped", Rs.RenderStepped, Services, Key)
end

function ModuleLoader.PreRender(Services, Key: HeartbeatKey?)
	Register("PreRender", Rs.PreRender, Services, Key)
end

function ModuleLoader.Remove(Key: HeartbeatKey)
	for _, Container in pairs(Containers) do
		for i = #Container, 1, -1 do
			if Container[i].Key == Key then
				table.remove(Container, i)
			end
		end
	end
end

function ModuleLoader.RequireServices(Container, FolderOfModules: Folder)
	local Modules = FolderOfModules:GetChildren()
	local success = true

	for _, Module in ipairs(Modules) do
		if Module:IsA("ModuleScript") then
			local succ, result = pcall(require, Module)

			if not succ then
				warn(string.format("Failed To Require %s Reason: %s", Module.Name, result))
				success = false
				continue
			end

			if type(result) ~= "table" then
				warn(string.format("%s did not return a table instead %s", Module.Name, result))
				success = false
				continue
			end

			if type(result.new) == "function" then
				Container[Module.Name] = result
			else
				warn(string.format("%s did not have a .new function", Module.Name))
				success = false
			end
		else
			warn(
				string.format(
					"Couldent require object because %s is not a modulescript but is a %s",
					tostring(Module.Name),
					tostring(Module.ClassName)
				)
			)
		end
	end

	return success
end

function ModuleLoader.SetOrder(LoaderOptions: LoaderOptions, ModuleName: string, Modulescripts: requiredmodules)
	if LoaderOptions.Ordered[ModuleName] then
		return
	end

	if LoaderOptions.Loading[ModuleName] then
		error("Circular dependency detected at " .. ModuleName)
	end

	LoaderOptions.Loading[ModuleName] = true

	local Module = Modulescripts[ModuleName]

	if not Module then
		error("Could not find module " .. ModuleName)
	end

	for _, Dependency: dependency in ipairs(Module.Dependencies or {}) do
		if typeof(Dependency) == "Instance" and Dependency:IsA("ModuleScript") then
			if Modulescripts[Dependency.Name] then
				ModuleLoader.SetOrder(LoaderOptions, Dependency.Name, Modulescripts)
			end
		elseif type(Dependency) == "string" then
			if Modulescripts[Dependency] then
				ModuleLoader.SetOrder(LoaderOptions, Dependency, Modulescripts)
			else
				warn(
					string.format(
						"Dependency Is Not Matching any modulescripts inside services given dependency = %s, the modulescript it is comming from  = %s",
						Dependency,
						ModuleName
					)
				)
			end
		else
			print("Invalid Argument Passed Ignoring")
		end
	end

	LoaderOptions.Loading[ModuleName] = nil
	LoaderOptions.Ordered[ModuleName] = true

	table.insert(LoaderOptions.Order, ModuleName)
end

function ModuleLoader.CreateClasses(
	ContextTable: ContextTable,
	LoaderOptions: LoaderOptions,
	RequiredModules: requiredmodules,
	Container: Classmodules
)
	local retries = 3
	local success = true

	if not RequiredModules then
		warn("Modules not found")
		return false
	end

	for _, ModuleName in ipairs(LoaderOptions.Order) do
		local Module = RequiredModules[ModuleName]

		if not Module then
			warn("Module not Found" .. tostring(ModuleName))
			success = false
			continue
		end

		for _, Dependency: dependency in ipairs(Module.Dependencies or {}) do
			if type(Dependency) == "string" then
				if not LoaderOptions.Created[Dependency] then
					warn(
						"Dependencies are not met with "
							.. ModuleName
							.. " Module Which Gave the Error = "
							.. tostring(Dependency)
					)
					return false
				end
			elseif typeof(Dependency) == "Instance" and Dependency:IsA("ModuleScript") then
				if not LoaderOptions.Created[Dependency.Name] then
					warn(
						"Dependencies are not met with "
							.. ModuleName
							.. " Module Which Gave the Error = "
							.. tostring(Dependency)
					)
					return false
				end
			else
				warn("Invalid Argument in Dependencys, You have to pass string or modulescript")
			end
		end

		if type(Module) == "table" and type(Module.new) == "function" then
			for i = 1, retries do
				local succ, fail = pcall(function()
					local newObject = Module.new(ContextTable)

					if newObject == nil then
						error(("Module %s returned nil from new()"):format(ModuleName))
					end

					Container[ModuleName] = newObject
				end)

				if succ then
					LoaderOptions.Created[ModuleName] = true
					break
				end

				if i == retries then
					warn("Failed to Create Module " .. tostring(ModuleName) .. " Setting Success to false")
					LoaderOptions.Created[ModuleName] = false
					success = false
					break
				end

				warn(string.format("Could not Initalize %s reason %s so resulted to retrying", ModuleName, fail))
				task.wait(i ^ 2)
			end
		else
			print("Module Does not include a.new function: " .. tostring(ModuleName))
			LoaderOptions.Created[ModuleName] = false
			return false
		end
	end

	return success
end

function ModuleLoader.InitializeModules(
	LoaderOptions: LoaderOptions,
	RequiredModules: requiredmodules,
	Container: Classmodules
)
	local amountofretries = 3
	local success = true
	if not Container then
		warn("Modules not found")
		return false
	end

	for _, ModuleName in ipairs(LoaderOptions.Order) do
		local Module = Container[ModuleName]

		if not Module then
			warn("Module Not Found inside profile/modules" .. tostring(ModuleName))
			success = false
			continue
		end

		if not RequiredModules[ModuleName] then
			warn("Couldent find module inside required modules" .. tostring(ModuleName))
			success = false
			continue
		end

		for _, Dependency: dependency in ipairs(RequiredModules[ModuleName].Dependencies or {}) do
			if type(Dependency) == "string" then
				if not LoaderOptions.Initialized[Dependency] then
					warn(
						"Dependencies are not met with "
							.. ModuleName
							.. " Module Which Gave the Error = "
							.. tostring(Dependency)
					)
					return false
				end
			elseif typeof(Dependency) == "Instance" and Dependency:IsA("ModuleScript") then
				if not LoaderOptions.Initialized[Dependency.Name] then
					warn(
						"Dependencies are not met with "
							.. ModuleName
							.. " Module Which Gave the Error = "
							.. tostring(Dependency)
					)
					return false
				end
			else
				warn(
					"Invalid Argument in Dpendencys, You have to pass string or modulescript given = "
						.. tostring(Dependency)
				)
			end
		end

		if type(Module.Init) == "function" then
			print("Has init")
		end

		if type(Module) == "table" and type(Module.Init) == "function" then
			local initialized = false
			for i = 1, amountofretries do
				local succ, err = pcall(function()
					Module:Init()
				end)

				if succ then
					initialized = true
					break
				end

				if i == amountofretries then
					warn("Failed to Initialize Module " .. tostring(ModuleName) .. " Setting Success to false")
					success = false
					break
				end

				warn(
					string.format(
						"Could not Initialize %s reason %s so resulted to retrying",
						ModuleName,
						tostring(err)
					)
				)
				task.wait(i ^ 2)
			end

			if initialized then
				LoaderOptions.Initialized[ModuleName] = true
			else
				LoaderOptions.Initialized[ModuleName] = false
			end
		else
			LoaderOptions.Initialized[ModuleName] = false
		end
	end
	return success
end

ModuleLoader.Require = function(folder: Folder)
	local Container = {}
	local Require = ModuleLoader.RequireServices(Container, folder)

	if not Require then
		warn("Failed To require Modules inside" .. folder.Name)
		return false
	end

	return Container
end

ModuleLoader.Load = function(ContextTable: ContextTable, RequiredModules: { [string]: any })
	local ContainerOfModules: Classmodules = {}
	local Succ = ModuleLoader.LoadModules(ContextTable, RequiredModules, ContainerOfModules)

	return ContainerOfModules, Succ
end

return ModuleLoader
