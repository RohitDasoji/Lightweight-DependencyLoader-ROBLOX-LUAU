local ModuleManeger = require(script.Parent.ModuleManeger)

local Construct = ModuleManeger.new()

local succ = Construct:Init()

if not succ then
	warn("Failed to Initialize local modules")
end

-- On the client there's only ever one player (yourself), and by the time this
-- LocalScript runs, Players.PlayerAdded has already fired for you -- so that
-- connection pattern never actually runs its callback. Cleanup happens on
-- BindToClose instead, since there's no local equivalent of "PlayerRemoving".
game:BindToClose(function()
	Construct:Remove()
end)
