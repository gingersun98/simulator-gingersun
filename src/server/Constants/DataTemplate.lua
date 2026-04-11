return {
	Money = 0,
	PendingMoney = 0,

	CurrentLayer = 1,

	SafehouseLevel = 1,
	SafehouseSlots = {},

	Upgrades = {
		PowerLevel = 1,
		MiningLevel = 1,
		SafehouseLevel = 1,
	},

	NewPlayer = true,

	Monsters = {},
	MonstersIndex = {},

	WallProgress = {},
}

-- EXAMPLE
-- return {
-- 	Money = 10000,
-- 	PendingMoney = 500,
-- 	CurrentLayer = 2,

-- 	SafehouseLevel = 1,
-- 	SafehouseSlots = {
-- 		["1"] = { Type = "Egg", Id = "BasicEgg },
-- 		["2"] = { Type = "Monster", Id = "MonsterA },
-- 	},

-- 	Upgrades = {
-- 		PowerLevel = 1,
-- 		MiningLevel = 1,
-- 		SafehouseLevel = 1,
-- 	},

-- 	NewPlayer = true,

-- 	Monsters = {
-- 		["GUID"] = {}

-- 	MonstersIndex = {},

-- WallProgress = {
-- ["Wall1"] = { HP = 100, IsDestroyed = false },
-- }
-- }
