local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}
RemoteService._cache = {}

local root = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")

-- GET (safe, expects it to exist or creates if missing via Create)
function RemoteService:Get(name)
	if self._cache[name] then
		return self._cache[name]
	end

	local remote = root:FindFirstChild(name)

	if not remote then
		-- fallback to create so it never breaks
		remote = self:Create(name)
	end

	self._cache[name] = remote
	return remote
end

-- CREATE (only one place that makes instances)
function RemoteService:Create(name, className)
	local existing = root:FindFirstChild(name)
	if existing then
		self._cache[name] = existing
		return existing
	end

	local remote = Instance.new(className or "RemoteEvent")
	remote.Name = name
	remote.Parent = root

	self._cache[name] = remote
	return remote
end

return RemoteService
