--This is a fill in script and is not meant to be here you can delete if needed and this is also how projects are meant to be created and initialized

local fill = {}
fill.__index = fill

function fill.new(ContextTable)
	local self = {}
	self.ContextTable = ContextTable
	self.Initialized = false
	return self
end
type Objects = typeof(fill.new({}))

type class = Objects & {
    Init: (self: class) -> boolean
}

function fill.Init(self: class): boolean
	if self.Initialized then
		return false
	end

	print("Initialized PlayerServices")
    
	return true
end
