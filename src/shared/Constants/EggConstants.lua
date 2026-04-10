local EggConstants = {
	["BasicEgg"] = {
		Name = "Basic Egg",
		HatchRates = {
			Common = 100,
		},
	},

	-- Layer Eggs --

	["Layer1Egg"] = {
		Name = "Layer 1 Egg",
		HatchRates = {
			Common = 90,
			Uncommon = 10,
		},
	},
	["Layer2Egg"] = {
		Name = "Layer 2 Egg",
		HatchRates = {
			Common = 60,
			Uncommon = 40,
		},
	},
	["Layer3Egg"] = {
		Name = "Layer 3 Egg",
		HatchRates = {
			Uncommon = 80,
			Rare = 20,
		},
	},
	["Layer4Egg"] = {
		Name = "Layer 4 Egg",
		HatchRates = {
			Rare = 80,
			Epic = 20,
		},
	},
	["Layer5Egg"] = {
		Name = "Layer 5 Egg",
		HatchRates = {
			Epic = 80,
			Legendary = 20,
		},
	},
}

return EggConstants
