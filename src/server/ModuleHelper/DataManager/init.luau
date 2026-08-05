--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TemplateModule = require(script.Template)
local ProfileService = require(ReplicatedStorage.Packages.profileservice)

local DataStore = ProfileService.GetProfileStore(
	"PlayerData",
	TemplateModule.Template
)

local DataProfile = {}
DataProfile.__index = DataProfile


type Objects = {
	Player: Player,

	Profile: any?,
	Data: any?,

	Conditions: {
		DataLoaded: boolean,
	},
}


type Class = Objects & {
	Load: (self: Objects) -> boolean,
	GetData: (self: Objects) -> any?,
	Release: (self: Objects) -> (),
}


function DataProfile.new(plr: Player)
	local self = setmetatable({}, DataProfile)

	self.Player = plr

	self.Profile = nil
	self.Data = nil

	self.Conditions = {
		DataLoaded = false,
	}

	return self
end


function DataProfile.Load(self: Objects): boolean
	local plr = self.Player

	local Profile = DataStore:LoadProfileAsync(
		"Player_" .. plr.UserId
	)

	if not Profile then
		return false
	end

	Profile:AddUserId(plr.UserId)

	Profile:Reconcile()

	Profile:ListenToRelease(function()
		self.Profile = nil
		self.Data = nil
		self.Conditions.DataLoaded = false

		if plr.Parent then
			plr:Kick("Your data was loaded on another server.")
		end
	end)

	if not plr.Parent then
		Profile:Release()
		return false
	end

	self.Profile = Profile
	self.Data = Profile.Data

	self.Conditions.DataLoaded = true

	print("💾 DataProfile: Successfully loaded data for " .. plr.Name)

	return true
end


function DataProfile.GetData(self: Objects): any?
	if not self.Profile then
		return nil
	end

	return self.Data
end


function DataProfile.IsLoaded(self: Objects): boolean
	return self.Conditions.DataLoaded
end


function DataProfile.Release(self: Objects)
	if self.Profile then
		self.Profile:Release()
	end

	self.Profile = nil
	self.Data = nil

	self.Conditions.DataLoaded = false
end


return DataProfile