local EggConstants = {

	-- =========================================================
	-- RATE PRESETS
	-- =========================================================
	RateSets = {
		CommonLv1 = { Baby = 80, Juvenile = 20, Elder = 0 },
		CommonLv2 = { Baby = 72, Juvenile = 23, Elder = 5 },
		CommonLv3 = { Baby = 62, Juvenile = 23, Elder = 15 },

		RareLv1 = { Baby = 76, Juvenile = 19, Elder = 5 },
		RareLv2 = { Baby = 67, Juvenile = 23, Elder = 10 },
		RareLv3 = { Baby = 55, Juvenile = 30, Elder = 15 },

		EpicLv1 = { Baby = 72, Juvenile = 18, Elder = 10 },
		EpicLv2 = { Baby = 63, Juvenile = 22, Elder = 15 },
		EpicLv3 = { Baby = 50, Juvenile = 35, Elder = 15 },
	},

	-- =========================================================
	-- EGG DATA
	-- =========================================================
	Eggs = {
		-- ================= COMMON =================
		-- ["Lv1EggGoat"] = {
		-- 	Name = "Egg Goat",
		-- 	UILevel = "Lvl 1",
		-- 	UIRarity = "Common",
		-- 	EggFamily = "Goat",
		-- 	HatchRates = { ElderDoctorCrow = 100 },
		-- },
		["Lv1EggGoat"] = {
			Name = "Egg Goat",
			UILevel = "Lvl 1",
			UIRarity = "Common",
			EggFamily = "Goat",
			HatchRates = { BabyGoat = 80, JuvenileGoat = 20, ElderGoldGoat = 0 },
		},
		["Lv2EggGoat"] = {
			Name = "Egg Goat",
			UILevel = "Lvl 2",
			UIRarity = "Common",
			EggFamily = "Goat",
			HatchRates = { BabyGoat = 72, JuvenileGoat = 23, ElderGoldGoat = 5 },
		},
		["Lv3EggGoat"] = {
			Name = "Egg Goat",
			UILevel = "Lvl 3",
			UIRarity = "Common",
			EggFamily = "Goat",
			HatchRates = { BabyGoat = 62, JuvenileGoat = 23, ElderGoldGoat = 15 },
		},

		["Lv1EggTiger"] = {
			Name = "Egg Tiger",
			UILevel = "Lvl 1",
			UIRarity = "Common",
			EggFamily = "Tiger",
			HatchRates = { BabyTiger = 80, JuvenileTiger = 20, ElderWhiteTiger = 0 },
		},
		["Lv2EggTiger"] = {
			Name = "Egg Tiger",
			UILevel = "Lvl 2",
			UIRarity = "Common",
			EggFamily = "Tiger",
			HatchRates = { BabyTiger = 72, JuvenileTiger = 23, ElderWhiteTiger = 5 },
		},
		["Lv3EggTiger"] = {
			Name = "Egg Tiger",
			UILevel = "Lvl 3",
			UIRarity = "Common",
			EggFamily = "Tiger",
			HatchRates = { BabyTiger = 62, JuvenileTiger = 23, ElderWhiteTiger = 15 },
		},

		["Lv1EggDeer"] = {
			Name = "Egg Deer",
			UILevel = "Lvl 1",
			UIRarity = "Common",
			EggFamily = "Deer",
			HatchRates = { BabyDeer = 80, JuvenileDeer = 20, ElderSpiritDeer = 0 },
		},
		["Lv2EggDeer"] = {
			Name = "Egg Deer",
			UILevel = "Lvl 2",
			UIRarity = "Common",
			EggFamily = "Deer",
			HatchRates = { BabyDeer = 72, JuvenileDeer = 23, ElderSpiritDeer = 5 },
		},
		["Lv3EggDeer"] = {
			Name = "Egg Deer",
			UILevel = "Lvl 3",
			UIRarity = "Common",
			EggFamily = "Deer",
			HatchRates = { BabyDeer = 62, JuvenileDeer = 23, ElderSpiritDeer = 15 },
		},

		["Lv1EggMoth"] = {
			Name = "Egg Moth",
			UILevel = "Lvl 1",
			UIRarity = "Common",
			EggFamily = "Moth",
			HatchRates = { BabyMoth = 80, JuvenileMoth = 20, ElderLunarMoth = 0 },
		},
		["Lv2EggMoth"] = {
			Name = "Egg Moth",
			UILevel = "Lvl 2",
			UIRarity = "Common",
			EggFamily = "Moth",
			HatchRates = { BabyMoth = 72, JuvenileMoth = 23, ElderLunarMoth = 5 },
		},
		["Lv3EggMoth"] = {
			Name = "Egg Moth",
			UILevel = "Lvl 3",
			UIRarity = "Common",
			EggFamily = "Moth",
			HatchRates = { BabyMoth = 62, JuvenileMoth = 23, ElderLunarMoth = 15 },
		},

		-- ================= RARE =================
		["Lv1EggCrow"] = {
			Name = "Egg Crow",
			UILevel = "Lvl 1",
			UIRarity = "Rare",
			EggFamily = "Crow",
			HatchRates = { BabyCrow = 76, JuvenileCrow = 19, ElderDoctorCrow = 5 },
		},
		["Lv2EggCrow"] = {
			Name = "Egg Crow",
			UILevel = "Lvl 2",
			UIRarity = "Rare",
			EggFamily = "Crow",
			HatchRates = { BabyCrow = 67, JuvenileCrow = 23, ElderDoctorCrow = 10 },
		},
		["Lv3EggCrow"] = {
			Name = "Egg Crow",
			UILevel = "Lvl 3",
			UIRarity = "Rare",
			EggFamily = "Crow",
			HatchRates = { BabyCrow = 55, JuvenileCrow = 30, ElderDoctorCrow = 15 },
		},

		["Lv1EggBat"] = {
			Name = "Egg Bat",
			UILevel = "Lvl 1",
			UIRarity = "Rare",
			EggFamily = "Bat",
			HatchRates = { BabyBat = 76, JuvenileBat = 19, ElderDragonBat = 5 },
		},
		["Lv2EggBat"] = {
			Name = "Egg Bat",
			UILevel = "Lvl 2",
			UIRarity = "Rare",
			EggFamily = "Bat",
			HatchRates = { BabyBat = 67, JuvenileBat = 23, ElderDragonBat = 10 },
		},
		["Lv3EggBat"] = {
			Name = "Egg Bat",
			UILevel = "Lvl 3",
			UIRarity = "Rare",
			EggFamily = "Bat",
			HatchRates = { BabyBat = 55, JuvenileBat = 30, ElderDragonBat = 15 },
		},

		["Lv1EggPeacock"] = {
			Name = "Egg Peacock",
			UILevel = "Lvl 1",
			UIRarity = "Rare",
			EggFamily = "Peacock",
			HatchRates = { BabyPeacock = 76, JuvenilePeacock = 19, ElderDemonicPeacock = 5 },
		},
		["Lv2EggPeacock"] = {
			Name = "Egg Peacock",
			UILevel = "Lvl 2",
			UIRarity = "Rare",
			EggFamily = "Peacock",
			HatchRates = { BabyPeacock = 67, JuvenilePeacock = 23, ElderDemonicPeacock = 10 },
		},
		["Lv3EggPeacock"] = {
			Name = "Egg Peacock",
			UILevel = "Lvl 3",
			UIRarity = "Rare",
			EggFamily = "Peacock",
			HatchRates = { BabyPeacock = 55, JuvenilePeacock = 30, ElderDemonicPeacock = 15 },
		},

		["Lv1EggFox"] = {
			Name = "Egg Fox",
			UILevel = "Lvl 1",
			UIRarity = "Rare",
			EggFamily = "Fox",
			HatchRates = { BabyFox = 76, JuvenileFox = 19, ElderBlueFox = 5 },
		},
		["Lv2EggFox"] = {
			Name = "Egg Fox",
			UILevel = "Lvl 2",
			UIRarity = "Rare",
			EggFamily = "Fox",
			HatchRates = { BabyFox = 67, JuvenileFox = 23, ElderBlueFox = 10 },
		},
		["Lv3EggFox"] = {
			Name = "Egg Fox",
			UILevel = "Lvl 3",
			UIRarity = "Rare",
			EggFamily = "Fox",
			HatchRates = { BabyFox = 55, JuvenileFox = 30, ElderBlueFox = 15 },
		},

		-- ================= EPIC =================
		["Lv1EggDragon"] = {
			Name = "Egg Dragon",
			UILevel = "Lvl 1",
			UIRarity = "Epic",
			EggFamily = "Dragon",
			HatchRates = { BabyDragon = 72, JuvenileDragon = 18, ElderSunDragon = 10 },
		},
		["Lv2EggDragon"] = {
			Name = "Egg Dragon",
			UILevel = "Lvl 2",
			UIRarity = "Epic",
			EggFamily = "Dragon",
			HatchRates = { BabyDragon = 63, JuvenileDragon = 22, ElderSunDragon = 15 },
		},
		["Lv3EggDragon"] = {
			Name = "Egg Dragon",
			UILevel = "Lvl 3",
			UIRarity = "Epic",
			EggFamily = "Dragon",
			HatchRates = { BabyDragon = 50, JuvenileDragon = 35, ElderSunDragon = 15 },
		},

		["Lv1EggPhoenix"] = {
			Name = "Egg Phoenix",
			UILevel = "Lvl 1",
			UIRarity = "Epic",
			EggFamily = "Phoenix",
			HatchRates = { BabyPhoenix = 72, JuvenilePhoenix = 18, ElderMagicPhoenix = 10 },
		},
		["Lv2EggPhoenix"] = {
			Name = "Egg Phoenix",
			UILevel = "Lvl 2",
			UIRarity = "Epic",
			EggFamily = "Phoenix",
			HatchRates = { BabyPhoenix = 63, JuvenilePhoenix = 22, ElderMagicPhoenix = 15 },
		},
		["Lv3EggPhoenix"] = {
			Name = "Egg Phoenix",
			UILevel = "Lvl 3",
			UIRarity = "Epic",
			EggFamily = "Phoenix",
			HatchRates = { BabyPhoenix = 50, JuvenilePhoenix = 35, ElderMagicPhoenix = 15 },
		},

		["Lv1EggPony"] = {
			Name = "Egg Pony",
			UILevel = "Lvl 1",
			UIRarity = "Epic",
			EggFamily = "Pony",
			HatchRates = { BabyPony = 72, JuvenilePony = 18, ElderFirePony = 10 },
		},
		["Lv2EggPony"] = {
			Name = "Egg Pony",
			UILevel = "Lvl 2",
			UIRarity = "Epic",
			EggFamily = "Pony",
			HatchRates = { BabyPony = 63, JuvenilePony = 22, ElderFirePony = 15 },
		},
		["Lv3EggPony"] = {
			Name = "Egg Pony",
			UILevel = "Lvl 3",
			UIRarity = "Epic",
			EggFamily = "Pony",
			HatchRates = { BabyPony = 50, JuvenilePony = 35, ElderFirePony = 15 },
		},

		["Lv1EggWhale"] = {
			Name = "Egg Whale",
			UILevel = "Lvl 1",
			UIRarity = "Epic",
			EggFamily = "Whale",
			HatchRates = { BabyWhale = 72, JuvenileWhale = 18, ElderCloudWhale = 10 },
		},
		["Lv2EggWhale"] = {
			Name = "Egg Whale",
			UILevel = "Lvl 2",
			UIRarity = "Epic",
			EggFamily = "Whale",
			HatchRates = { BabyWhale = 63, JuvenileWhale = 22, ElderCloudWhale = 15 },
		},
		["Lv3EggWhale"] = {
			Name = "Egg Whale",
			UILevel = "Lvl 3",
			UIRarity = "Epic",
			EggFamily = "Whale",
			HatchRates = { BabyWhale = 50, JuvenileWhale = 35, ElderCloudWhale = 15 },
		},

		-- ================= LEGENDS =================
		["EggRadioactifBlob"] = {
			Name = "Egg RadioactifBlob",
			UILevel = "Lvl 5",
			UIRarity = "Legends",
			EggFamily = "RadioactifBlob",
			HatchRates = { RadioactifBlob = 100 },
		},
	},

	-- =========================================================
	-- AREA CONFIG (FINAL DESIGN)
	-- =========================================================
	AreaConfig = {
		[1] = { Eggs = { "Lv1EggGoat", "Lv1EggTiger", "Lv2EggGoat" } },
		[2] = { Eggs = { "Lv1EggDeer", "Lv2EggGoat", "Lv2EggTiger" } },
		[3] = { Eggs = { "Lv1EggMoth", "Lv2EggDeer", "Lv2EggTiger" } },
		[4] = { Eggs = { "Lv1EggCrow", "Lv2EggMoth", "Lv2EggDeer" } },
		[5] = { Eggs = { "Lv1EggBat", "Lv2EggCrow", "Lv2EggMoth" } },
		[6] = { Eggs = { "Lv1EggPeacock", "Lv2EggBat", "Lv2EggCrow" } },
		[7] = { Eggs = { "Lv1EggFox", "Lv2EggPeacock", "Lv2EggBat" } },
		[8] = { Eggs = { "Lv1EggDragon", "Lv2EggFox", "Lv2EggPeacock" } },
		[9] = { Eggs = { "Lv1EggPhoenix", "Lv2EggDragon", "Lv2EggFox" } },
		[10] = { Eggs = { "Lv1EggPony", "Lv2EggPhoenix", "Lv2EggDragon" } },
		[11] = { Eggs = { "Lv1EggWhale", "Lv2EggPony", "Lv2EggPhoenix" } },

		-- Endgame
		[12] = { Eggs = { "Lv3EggGoat", "Lv3EggTiger", "Lv3EggDeer" } },
		[13] = { Eggs = { "Lv3EggMoth", "Lv3EggCrow", "Lv3EggBat" } },
		[14] = { Eggs = { "Lv3EggPeacock", "Lv3EggFox", "Lv3EggDragon" } },
		[15] = { Eggs = { "Lv3EggPhoenix", "Lv3EggPony", "Lv3EggWhale" } },
	},
}

return EggConstants
