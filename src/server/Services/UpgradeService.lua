local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EconomyMath = require(ReplicatedStorage.Shared.Modules.EconomyMath)

local UpgradeService = Knit.CreateService({
	Name = "UpgradeService",
	Client = {},
})

local DataService

local PRODUCT_REWARDS = {
	[3574575697] = { UpgradeKey = "PowerLevel", Amount = 1 },
	[3574576195] = { UpgradeKey = "PowerLevel", Amount = 5 },
	[3574576644] = { UpgradeKey = "PowerLevel", Amount = 10 },
	[3574577388] = { UpgradeKey = "MiningLevel", Amount = 1 },
	[3574577673] = { UpgradeKey = "MiningLevel", Amount = 5 },
	[3574577826] = { UpgradeKey = "MiningLevel", Amount = 10 },
}

local function applyRobuxUpgrade(player: Player, reward): boolean
	if not reward then
		return false
	end

	local data = DataService:GetData(player)
	if not data or not data.Upgrades then
		return false
	end

	local currentLevel = data.Upgrades[reward.UpgradeKey] or 1
	data.Upgrades[reward.UpgradeKey] = currentLevel + reward.Amount
	DataService:NotifyDataChanged(player)

	return true
end

function UpgradeService:HandleProductReceipt(receiptInfo)
	local reward = PRODUCT_REWARDS[receiptInfo.ProductId]
	if not reward then
		return nil
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = applyRobuxUpgrade(player, reward)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

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

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local decision = self:HandleProductReceipt(receiptInfo)
		if decision then
			return decision
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("UpgradeService is running!")
end

return UpgradeService
