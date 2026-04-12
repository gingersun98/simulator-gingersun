local MonsterConstants = {}

MonsterConstants.Data = {
	["MonsterA"] = {
		Name = "Monster Aa",
		Rarity = "Common",
		Chance = 10,
		BaseMultiplier = 1,
		ImageId = "rbxassetid://12345678",
		VisualConfiguration = {
			Width = 3,
			State = "Flying",
		},
		AnimationId = {
			Walking = "rbxassetid://12345678",
			Mining = "rbxassetid://12345678",
			Breaking = "rbxassetid://12345678",
		},
	},
	["MonsterB"] = {
		Name = "Monster Bb",
		Rarity = "Common",
		Chance = 8,
		BaseMultiplier = 1.2,
		ImageId = "rbxassetid://12345678",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
	},
	["MonsterC"] = {
		Name = "Monster Cc",
		Rarity = "Rare",
		Chance = 10,
		BaseMultiplier = 2,
		ImageId = "rbxassetid://87654321",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
	},
	["MonsterD"] = {
		Name = "Monster Dd",
		Rarity = "Epic",
		Chance = 10,
		BaseMultiplier = 4,
		ImageId = "rbxassetid://11223344",
		VisualConfiguration = {
			Width = 3,
			State = "Walking",
		},
	},
}

MonsterConstants.Pools = {
	ByRarity = {},
}

for monsterId, monsterData in pairs(MonsterConstants.Data) do
	local rarity = monsterData.Rarity

	if not MonsterConstants.Pools.ByRarity[rarity] then
		MonsterConstants.Pools.ByRarity[rarity] = {}
	end
	table.insert(MonsterConstants.Pools.ByRarity[rarity], monsterId)
end

return MonsterConstants
