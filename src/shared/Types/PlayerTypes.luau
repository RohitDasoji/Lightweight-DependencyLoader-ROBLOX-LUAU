
local PlayerTypes = {}

export type Data = {
    Cash: number,
    Stones: number,

    Backpack: {[string]: {}},

    Hotbar: {boolean | string}
    --Write More Data if you add more in template.luau
}

export type DataProfile = {
    Data: Data
}

export type Profile = {
    DataLoaded: boolean,
    Data: {Data: Data, Profile: DataProfile} | nil,
    Modules: {[string]: any},
    plr: Player
}

export type Dependency = string | ModuleScript

export type Module = {
	new: (Context: Profile) -> any,
	Init: ((self: any) -> ())?,
	Dependencies: {Dependency}?,
}

export type class = {
    Init: ((self: any) -> ())
}

export type Services = {
    --Write Your Services Here If You Have Any Common ones
}

return PlayerTypes