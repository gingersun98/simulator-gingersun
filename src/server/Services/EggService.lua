local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafehouseService = require(script.Parent.SafehouseService)
local Knit = require(ReplicatedStorage.Packages.Knit)
local MonsterConstants = require(ReplicatedStorage.Shared.Constants.MonsterConstants)
local EggConstants = require(ReplicatedStorage.Shared.Constants.EggConstants)

local EggService = Knit.CreateService({
	Name = "EggService",
	Client = {
		ShowStarterEgg = Knit.CreateSignal(),
	},
	PlayerHoldingStates = {},
})

function EggService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.SafehouseService = Knit.GetService("SafehouseService")

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		self.PlayerHoldingStates[player] = nil
	end)
end

local function rollRarityFromEgg(eggId)
	local eggData = EggConstants[eggId]
	if not eggData then
		return nil
	end

	local totalWeight = 0
	for rarity, chance in pairs(eggData.HatchRates) do
		totalWeight += chance
	end

	local rng = math.random(1, totalWeight)
	local currentWeight = 0

	for rarity, chance in pairs(eggData.HatchRates) do
		currentWeight += chance
		if rng <= currentWeight then
			print("[PRINT!] Rolled rarity: " .. rarity)
			return rarity
		end
	end
end

local function rollMonsterFromRarity(targetRarity)
	local pool = MonsterConstants.Pools.ByRarity[targetRarity]
	if not pool or #pool == 0 then
		return nil
	end

	local totalWeight = 0
	local rollTable = {}

	for _, monsterId in ipairs(pool) do
		local chance = MonsterConstants.Data[monsterId].Chance
		totalWeight += chance
		table.insert(rollTable, { id = monsterId, chance = chance })
	end

	local rng = math.random(1, totalWeight)
	local currentWeight = 0

	for _, data in ipairs(rollTable) do
		currentWeight += data.chance
		if rng <= currentWeight then
			print("[PRINT!] Rolled monster: " .. data.id)
			return data.id
		end
	end
end

function EggService:CheckStarterEgg(player)
	local profile = self.DataService:GetData(player)

	if not profile or not profile.NewPlayer then
		return
	end

	SafehouseService:GiveEggToSafehouse(player, "BasicEgg", nil)
	profile.NewPlayer = false
end

function EggService:HatchEgg(player, slotIndex)
	local profile = self.DataService:GetData(player)
	if not profile then
		return
	end

	local slotData = profile.SafehouseSlots[slotIndex]
	if not slotData or slotData.Type ~= "Egg" then
		return
	end

	local eggId = slotData.Id
	local rolledRarity = rollRarityFromEgg(eggId)
	if not rolledRarity then
		return
	end

	local rolledMonsterId = rollMonsterFromRarity(rolledRarity)
	if not rolledMonsterId then
		return
	end

	local monsterGuid = self.DataService:AddMonsterToInventory(player, rolledMonsterId)

	return rolledMonsterId, monsterGuid
end

function EggService:ProcessPickup(player, eggInstance)
	if self.PlayerHoldingStates[player] and self.PlayerHoldingStates[player].State == "Holding" then
		return false
	end

	self.PlayerHoldingStates[player] = { State = "Holding", EggInstance = eggInstance }
	player:SetAttribute("IsHoldingEgg", true)

	return true
end

function EggService:ProcessDropoff(player, slot)
	local stateData = self.PlayerHoldingStates[player]

	if stateData and stateData.State == "Holding" then
		local eggInstance = stateData.EggInstance
		eggInstance:Destroy()

		self.PlayerHoldingStates[player] = { State = "Idle", EggInstance = nil }
		self.SafehouseService:GiveEggToSafehouse(player, "BasicEgg", slot)
		self.SafehouseService:RefreshSafehousePhysicalSlots(player)

		player:SetAttribute("IsHoldingEgg", false)

		return true
	end

	return false
end

return EggService
