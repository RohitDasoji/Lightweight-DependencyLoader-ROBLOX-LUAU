local ReplicatedStorage = game:GetService("ReplicatedStorage")
local goodsignal = require(ReplicatedStorage.Packages.goodsignal)

export type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

export type SignalConstructor = {
	new: <T...>() -> Signal<T...>,
}

local Signals = {}

Signals.signals = {
	NewSignal = goodsignal.new(),
}

return Signals
