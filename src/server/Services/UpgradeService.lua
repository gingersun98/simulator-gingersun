local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EconomyMath = require(ReplicatedStorage.Shared.Modules.EconomyMath)

local UpgradeService = Knit.CreateService({
	Name = "UpgradeService",
	Client = {},
})

local DataService

local function validateAmount(amount: number): boolean
	return typeof(amount) == "number" and amount > 0
end

function UpgradeService:BuyPowerUpgrade(player: Player, amount: number): boolean
	if not validateAmount(amount) then
		return false
	end

	local data = DataService:GetData(player)
	if not data then
		return false
	end

	local currentLevel = data.Upgrades.PowerLevel or 1
	local totalCost = EconomyMath.GetPowerUpgradeCost(currentLevel, amount)

	if data.Money < totalCost then
		return false
	end

	data.Money -= totalCost
	data.Upgrades.PowerLevel = currentLevel + amount

	DataService:NotifyDataChanged(player)

	return true
end

function UpgradeService:BuyMiningUpgrade(player: Player, amount: number): boolean
	if not validateAmount(amount) then
		return false
	end

	local data = DataService:GetData(player)
	if not data then
		return false
	end

	local currentLevel = data.Upgrades.MiningLevel or 1
	local totalCost = EconomyMath.GetMineUpgradeCost(currentLevel, amount)

	if data.Money < totalCost then
		return false
	end

	data.Money -= totalCost
	data.Upgrades.MiningLevel = currentLevel + amount

	DataService:NotifyDataChanged(player)

	return true
end

function UpgradeService.Client:BuyPowerUpgrade(player: Player, amount: number): boolean
	return self.Server:BuyPowerUpgrade(player, amount)
end

function UpgradeService.Client:BuyMiningUpgrade(player: Player, amount: number): boolean
	return self.Server:BuyMiningUpgrade(player, amount)
end

function UpgradeService:KnitStart()
	DataService = Knit.GetService("DataService")
	print("UpgradeService is running!")
end

return UpgradeService
