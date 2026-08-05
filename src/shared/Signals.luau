local ReplicatedStorage = game:GetService("ReplicatedStorage")
local goodsignal = require(ReplicatedStorage.Packages.goodsignal)

local Signals = {}

Signals.signals = {
	RestockSignal = goodsignal.new(),
}

return Signals
