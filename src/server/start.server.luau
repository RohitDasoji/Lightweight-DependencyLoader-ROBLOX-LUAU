local Players = game:GetService("Players")
local InitModule = require(script.Parent.InitModule)
local SERVERMAXRETRYAMT = 3
local RETRYDELAY = 1

local ServerStarted = false

for i = 1, SERVERMAXRETRYAMT do
	local succ, result = pcall(function()
		return InitModule:InitServer()
	end)

	-- succ only tells us whether an error was thrown. InitServer() can also
	-- fail "quietly" by warning and returning false, so both have to be checked.
	if succ and result then
		ServerStarted = true
		break
	end

	if succ then
		warn("InitServer() returned false, Retrying " .. i .. "/" .. SERVERMAXRETRYAMT)
	else
		warn("Error With Server.init, Retrying " .. i .. "/" .. SERVERMAXRETRYAMT .. " " .. tostring(result))
	end

	task.wait(RETRYDELAY)
end

if not ServerStarted then
	warn("Server Failed To Initalize")
end

Players.PlayerAdded:Connect(function(plr: Player)
	if not ServerStarted then
		plr:Kick("Server Failed To Initalize")
		return
	end

	local Start = InitModule:AddPlayer(plr)
	
	if not Start then
		InitModule:RemovePlayer(plr)
		plr:Kick("Issues With Loading Player Please Try Again Later")
	end
end)

Players.PlayerRemoving:Connect(function(plr: Player)
	InitModule:RemovePlayer(plr)
end)

game:BindToClose(function()
	InitModule:RemoveAllPlayers()
end)
