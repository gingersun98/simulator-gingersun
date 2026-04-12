local MonsterConstants = {}

MonsterConstants.Meta = {
	MultiplierRanges = {
		Common = {
			Baby = { Min = 0.10, Max = 0.13 },
			Juvenile = { Min = 0.30, Max = 0.33 },
			Elder = { Min = 0.60, Max = 0.63 },
			Legend = { Min = 1.00, Max = 1.00 },
		},
		Rare = {
			Baby = { Min = 0.14, Max = 0.16 },
			Juvenile = { Min = 0.34, Max = 0.37 },
			Elder = { Min = 0.64, Max = 0.67 },
			Legend = { Min = 1.00, Max = 1.00 },
		},
		Epic = {
			Baby = { Min = 0.17, Max = 0.20 },
			Juvenile = { Min = 0.38, Max = 0.40 },
			Elder = { Min = 0.68, Max = 0.70 },
			Legend = { Min = 1.00, Max = 1.00 },
		},
		Special = {
			Legend = { Min = 1.00, Max = 1.00 },
		},
	},

	StageChance = {
		Baby = 10,
		Juvenile = 8,
		Elder = 5,
		Legend = 1,
	},
}

MonsterConstants.Data = {
	["RadioactifBlob"] = {
		Name = "Radioactive Blob",
		Rarity = "RadioactifBlob",
		EggRarity = "Special",
		Stage = "Legend",
		Chance = 1,
		BaseMultiplier = 1.00,
		ImageId = "rbxassetid://84479504476061",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://79833653100873",
			Mining = "rbxassetid://79833653100873",
			Breaking = "rbxassetid://79833653100873",
		},
	},

	["BabyGoat"] = {
		Name = "Baby Goat",
		Rarity = "BabyGoat",
		EggRarity = "Common",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.11,
		ImageId = "rbxassetid://103045095966987",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},
	["JuvenileGoat"] = {
		Name = "Juvenile Goat",
		Rarity = "JuvenileGoat",
		EggRarity = "Common",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.31,
		ImageId = "rbxassetid://96753691824295",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://123593170280357",
			Mining = "rbxassetid://123593170280357",
			Breaking = "rbxassetid://123593170280357",
		},
	},
	["ElderGoldGoat"] = {
		Name = "Elder GoldGoat",
		Rarity = "ElderGoldGoat",
		EggRarity = "Common",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.61,
		ImageId = "rbxassetid://116142756179599",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://115927064419869",
			Mining = "rbxassetid://115927064419869",
			Breaking = "rbxassetid://115927064419869",
		},
	},

	["BabyTiger"] = {
		Name = "Baby Tiger",
		Rarity = "BabyTiger",
		EggRarity = "Common",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.12,
		ImageId = "rbxassetid://125605385325265",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://125285615176047",
			Mining = "rbxassetid://125285615176047",
			Breaking = "rbxassetid://125285615176047",
		},
	},
	["JuvenileTiger"] = {
		Name = "Juvenile Tiger",
		Rarity = "JuvenileTiger",
		EggRarity = "Common",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.32,
		ImageId = "rbxassetid://88077331871044",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://85745032629407",
			Mining = "rbxassetid://85745032629407",
			Breaking = "rbxassetid://85745032629407",
		},
	},
	["ElderWhiteTiger"] = {
		Name = "Elder White Tiger",
		Rarity = "ElderWhiteTiger",
		EggRarity = "Common",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.62,
		ImageId = "rbxassetid://83000052866191",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},

	["BabyDeer"] = {
		Name = "Baby Deer",
		Rarity = "BabyDeer",
		EggRarity = "Common",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.10,
		ImageId = "rbxassetid://124804031038560",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},
	["JuvenileDeer"] = {
		Name = "Juvenile Deer",
		Rarity = "JuvenileDeer",
		EggRarity = "Common",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.30,
		ImageId = "rbxassetid://122837926896910",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://76257607719732",
			Mining = "rbxassetid://76257607719732",
			Breaking = "rbxassetid://76257607719732",
		},
	},
	["ElderSpiritDeer"] = {
		Name = "Elder SpiritDeer",
		Rarity = "ElderSpiritDeer",
		EggRarity = "Common",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.60,
		ImageId = "rbxassetid://111905117829346",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},

	["BabyMoth"] = {
		Name = "Baby Moth",
		Rarity = "BabyMoth",
		EggRarity = "Common",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.13,
		ImageId = "rbxassetid://86976968542517",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://104761840969957",
			Mining = "rbxassetid://104761840969957",
			Breaking = "rbxassetid://104761840969957",
		},
	},
	["JuvenileMoth"] = {
		Name = "Juvenile Moth",
		Rarity = "JuvenileMoth",
		EggRarity = "Common",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.33,
		ImageId = "rbxassetid://126053574648383",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://128526584585580",
			Mining = "rbxassetid://128526584585580",
			Breaking = "rbxassetid://128526584585580",
		},
	},
	["ElderLunarMoth"] = {
		Name = "Elder LunarMoth",
		Rarity = "ElderLunarMoth",
		EggRarity = "Common",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.63,
		ImageId = "rbxassetid://117698981883579",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://71786098887575",
			Mining = "rbxassetid://71786098887575",
			Breaking = "rbxassetid://71786098887575",
		},
	},

	["BabyCrow"] = {
		Name = "Baby Crow",
		Rarity = "BabyCrow",
		EggRarity = "Rare",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.15,
		ImageId = "rbxassetid://137068940440477",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://135720997783113",
			Mining = "rbxassetid://135720997783113",
			Breaking = "rbxassetid://135720997783113",
		},
	},
	["JuvenileCrow"] = {
		Name = "Juvenile Crow",
		Rarity = "JuvenileCrow",
		EggRarity = "Rare",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.35,
		ImageId = "rbxassetid://123616940084989",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://116929728359809",
			Mining = "rbxassetid://116929728359809",
			Breaking = "rbxassetid://116929728359809",
		},
	},
	["ElderDoctorCrow"] = {
		Name = "Elder DoctorCrow",
		Rarity = "ElderDoctorCrow",
		EggRarity = "Rare",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.65,
		ImageId = "rbxassetid://114814175490802",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://87148504333330",
			Mining = "rbxassetid://87148504333330",
			Breaking = "rbxassetid://87148504333330",
		},
	},

	["BabyBat"] = {
		Name = "Baby Bat",
		Rarity = "BabyBat",
		EggRarity = "Rare",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.14,
		ImageId = "rbxassetid://130134118706822",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},
	["JuvenileBat"] = {
		Name = "Juvenile Bat",
		Rarity = "JuvenileBat",
		EggRarity = "Rare",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.34,
		ImageId = "rbxassetid://70622066805290",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},
	["ElderDragonBat"] = {
		Name = "Elder DragonBat",
		Rarity = "ElderDragonBat",
		EggRarity = "Rare",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.66,
		ImageId = "rbxassetid://113743393255000",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},

	["BabyPeacock"] = {
		Name = "Baby Peacock",
		Rarity = "BabyPeacock",
		EggRarity = "Rare",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.16,
		ImageId = "rbxassetid://76214368252816",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://71162974995772",
			Mining = "rbxassetid://71162974995772",
			Breaking = "rbxassetid://71162974995772",
		},
	},
	["JuvenilePeacock"] = {
		Name = "Juvenile Peacock",
		Rarity = "JuvenilePeacock",
		EggRarity = "Rare",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.36,
		ImageId = "rbxassetid://83577331383078",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://96639043048623",
			Mining = "rbxassetid://96639043048623",
			Breaking = "rbxassetid://96639043048623",
		},
	},
	["ElderDemonicPeacock"] = {
		Name = "Elder DemonicPeacock",
		Rarity = "ElderDemonicPeacock",
		EggRarity = "Rare",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.67,
		ImageId = "rbxassetid://128182040621857",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://72340756521356",
			Mining = "rbxassetid://72340756521356",
			Breaking = "rbxassetid://72340756521356",
		},
	},

	["BabyFox"] = {
		Name = "Baby Fox",
		Rarity = "BabyFox",
		EggRarity = "Rare",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.17,
		ImageId = "rbxassetid://132434187137653",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://131664003935006",
			Mining = "rbxassetid://131664003935006",
			Breaking = "rbxassetid://131664003935006",
		},
	},
	["JuvenileFox"] = {
		Name = "Juvenile Fox",
		Rarity = "JuvenileFox",
		EggRarity = "Rare",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.37,
		ImageId = "rbxassetid://136394129580722",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://135991355690038",
			Mining = "rbxassetid://135991355690038",
			Breaking = "rbxassetid://135991355690038",
		},
	},
	["ElderBlueFox"] = {
		Name = "Elder BlueFox",
		Rarity = "ElderBlueFox",
		EggRarity = "Rare",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.68,
		ImageId = "rbxassetid://86894519371376",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://124816071124626",
			Mining = "rbxassetid://124816071124626",
			Breaking = "rbxassetid://124816071124626",
		},
	},

	["BabyDragon"] = {
		Name = "Baby Dragon",
		Rarity = "BabyDragon",
		EggRarity = "Epic",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.18,
		ImageId = "rbxassetid://134330991123047",
		VisualConfiguration = {
			Width = 4,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://126401872645152",
			Mining = "rbxassetid://126401872645152",
			Breaking = "rbxassetid://126401872645152",
		},
	},
	["JuvenileDragon"] = {
		Name = "Juvenile Dragon",
		Rarity = "JuvenileDragon",
		EggRarity = "Epic",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.38,
		ImageId = "rbxassetid://133797246205881",
		VisualConfiguration = {
			Width = 4,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://89818144668123",
			Mining = "rbxassetid://89818144668123",
			Breaking = "rbxassetid://89818144668123",
		},
	},
	["ElderSunDragon"] = {
		Name = "Elder SunDragon",
		Rarity = "ElderSunDragon",
		EggRarity = "Epic",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.70,
		ImageId = "rbxassetid://81822399471386",
		VisualConfiguration = {
			Width = 4,
			State = "Flying",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},

	["BabyPhoenix"] = {
		Name = "Baby Phoenix",
		Rarity = "BabyPhoenix",
		EggRarity = "Epic",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.19,
		ImageId = "rbxassetid://127291671544711",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://110513627922498",
			Mining = "rbxassetid://110513627922498",
			Breaking = "rbxassetid://110513627922498",
		},
	},
	["JuvenilePhoenix"] = {
		Name = "Juvenile Phoenix",
		Rarity = "JuvenilePhoenix",
		EggRarity = "Epic",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.39,
		ImageId = "rbxassetid://97338318929633",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://126542593398834",
			Mining = "rbxassetid://126542593398834",
			Breaking = "rbxassetid://126542593398834",
		},
	},
	["ElderMagicPhoenix"] = {
		Name = "Elder MagicPhoenix",
		Rarity = "ElderMagicPhoenix",
		EggRarity = "Epic",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.69,
		ImageId = "rbxassetid://93044840723603",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://99366530972123",
			Mining = "rbxassetid://99366530972123",
			Breaking = "rbxassetid://99366530972123",
		},
	},

	["BabyPony"] = {
		Name = "Baby Pony",
		Rarity = "BabyPony",
		EggRarity = "Epic",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.17,
		ImageId = "rbxassetid://74507828017573",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "",
			Mining = "",
			Breaking = "",
		},
	},
	["JuvenilePony"] = {
		Name = "Juvenile Pony",
		Rarity = "JuvenilePony",
		EggRarity = "Epic",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.37,
		ImageId = "rbxassetid://91209672013698",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://133757064392537",
			Mining = "rbxassetid://133757064392537",
			Breaking = "rbxassetid://133757064392537",
		},
	},
	["ElderFirePony"] = {
		Name = "Elder FirePony",
		Rarity = "ElderFirePony",
		EggRarity = "Epic",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.68,
		ImageId = "rbxassetid://140075570698947",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
		AnimationId = {
			Walking = "rbxassetid://130920041652263",
			Mining = "rbxassetid://130920041652263",
			Breaking = "rbxassetid://130920041652263",
		},
	},

	["BabyWhale"] = {
		Name = "Baby Whale",
		Rarity = "BabyWhale",
		EggRarity = "Epic",
		Stage = "Baby",
		Chance = 10,
		BaseMultiplier = 0.18,
		ImageId = "rbxassetid://105752882856258",
		VisualConfiguration = {
			Width = 4,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://106488491494784",
			Mining = "rbxassetid://106488491494784",
			Breaking = "rbxassetid://106488491494784",
		},
	},
	["JuvenileWhale"] = {
		Name = "Juvenile Whale",
		Rarity = "JuvenileWhale",
		EggRarity = "Epic",
		Stage = "Juvenile",
		Chance = 8,
		BaseMultiplier = 0.40,
		ImageId = "rbxassetid://92038774348325",
		VisualConfiguration = {
			Width = 4,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://81351735222566",
			Mining = "rbxassetid://81351735222566",
			Breaking = "rbxassetid://81351735222566",
		},
	},
	["ElderCloudWhale"] = {
		Name = "Elder CloudWhale",
		Rarity = "ElderCloudWhale",
		EggRarity = "Epic",
		Stage = "Elder",
		Chance = 5,
		BaseMultiplier = 0.70,
		ImageId = "rbxassetid://97357956289882",
		VisualConfiguration = {
			Width = 4,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://112622353113606",
			Mining = "rbxassetid://112622353113606",
			Breaking = "rbxassetid://112622353113606",
		},
	},
}

MonsterConstants.Pools = {
	ByRarity = {},
	ByEggRarity = {},
	ByStage = {},
}

for monsterId, monsterData in pairs(MonsterConstants.Data) do
	local rarity = monsterData.Rarity
	local eggRarity = monsterData.EggRarity
	local stage = monsterData.Stage

	if not MonsterConstants.Pools.ByRarity[rarity] then
		MonsterConstants.Pools.ByRarity[rarity] = {}
	end
	table.insert(MonsterConstants.Pools.ByRarity[rarity], monsterId)

	if not MonsterConstants.Pools.ByEggRarity[eggRarity] then
		MonsterConstants.Pools.ByEggRarity[eggRarity] = {}
	end
	table.insert(MonsterConstants.Pools.ByEggRarity[eggRarity], monsterId)

	if not MonsterConstants.Pools.ByStage[stage] then
		MonsterConstants.Pools.ByStage[stage] = {}
	end
	table.insert(MonsterConstants.Pools.ByStage[stage], monsterId)
end

return MonsterConstants
