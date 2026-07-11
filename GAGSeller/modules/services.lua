--[[ services.lua — game services + require semua module game (deps).
     Mengisi: ctx.Services, ctx.LP, ctx.deps ]]
return function(ctx)
	local Players           = game:GetService("Players")
	local RS                = game:GetService("ReplicatedStorage")
	local HttpService       = game:GetService("HttpService")
	local UserInputService  = game:GetService("UserInputService")
	local CollectionService = game:GetService("CollectionService")

	if not game:IsLoaded() then game.Loaded:Wait() end
	repeat task.wait() until Players.LocalPlayer
	local LP = Players.LocalPlayer

	ctx.Services = {
		Players           = Players,
		RS                = RS,
		HttpService       = HttpService,
		UserInputService  = UserInputService,
		CollectionService = CollectionService,
	}
	ctx.LP = LP

	----------------------------------------------------------------- deps
	local RR              = require(RS.Modules.ReplicationReciever)
	local DataService     = require(RS.Modules.DataService)
	local TradeBoothsData = require(RS.Data.TradeBoothsData)
	local PU              = require(RS.Modules.PetServices.PetUtilities)
	local PetEggs         = require(RS.Data.PetRegistry.PetEggs)
	local MutReg          = require(RS.Data.PetRegistry.PetMutationRegistry)
	local SkinsReg        = require(RS.Data.TradeBoothSkinRegistry)

	local Booths = RS.GameEvents.TradeEvents.Booths

	ctx.deps = {
		RR              = RR,
		DataService     = DataService,
		TradeBoothsData = TradeBoothsData,
		PU              = PU,
		PetEggs         = PetEggs,
		MutReg          = MutReg,
		SkinsReg        = SkinsReg,
		EnumToMut       = MutReg.EnumToPetMutation,

		Booths          = Booths,
		ClaimBooth      = Booths.ClaimBooth,
		CreateListing   = Booths.CreateListing,
		RemoveBooth     = Booths.RemoveBooth,
		RemoveListing   = Booths.RemoveListing,
		AddToHistory    = Booths.AddToHistory,
		EquipSkin       = RS.GameEvents.TradeBoothSkinService.Equip,
	}
end
