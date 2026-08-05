local leaderstat = {}
leaderstat.__index = leaderstat

function leaderstat.new(plr)
	local self = setmetatable({}, leaderstat)
	self.plr = plr
	self.leaderstat = Instance.new("Folder")
	self.leaderstat.Parent = self.plr
	self.leaderstat.Name = "leaderstats"
	return self
end

function leaderstat:Additem(name, value)
	print("Created")
	local IntValue = Instance.new("IntValue")
	IntValue.Name = name
	IntValue.Value = value
	IntValue.Parent = self.leaderstat
end

return leaderstat
