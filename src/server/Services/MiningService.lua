local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MonsterConstants = require(ReplicatedStorage.Shared.Constants.MonsterConstants)

local MiningService = Knit.CreateService({
	Name = "MiningService",
	Client = {},
})

function MiningService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.SafehouseService = Knit.GetService("SafehouseService")

	self.SafehouseService.SafehouseReady:Connect(function(player, physicalSafehouse)
		self:SetupCoinCollector(player, physicalSafehouse)
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			self:ProcessMining()
		end
	end)
end

function MiningService:SetupCoinCollector(player, physicalSafehouse)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	local collectPart: MeshPart =
		physicalSafehouse:WaitForChild("Level1"):WaitForChild("CollectCoin"):WaitForChild("Green")

	local isCollecting = false

	collectPart.Touched:Connect(function(hit)
		if isCollecting then
			return
		end

		local character = hit.Parent
		local hitPlayer = Players:GetPlayerFromCharacter(character)

		if hitPlayer and hitPlayer == player then
			if data.PendingMoney > 0 then
				isCollecting = true

				local amountCollected = data.PendingMoney

				data.Money += amountCollected
				data.PendingMoney = 0
				self.DataService:NotifyDataChanged(player)

				print("Total uang sekarang: " .. data.Money)

				task.wait(1)
				isCollecting = false
			end
		end
	end)
end

function MiningService:ProcessMining()
	for _, player in pairs(Players:GetPlayers()) do
		local profile = self.DataService:GetData(player)
		if not profile then
			continue
		end

		local playerMineLevel = profile.Upgrades.MiningLevel or 1
		local totalIncomeThisSecond = 0

		for _, monsterData in pairs(profile.Monsters) do
			if monsterData.Status == "Mining" then
				local monsterId = monsterData.monsterId
				local constantData = MonsterConstants.Data[monsterId]

				if constantData then
					local monsterPower = playerMineLevel * constantData.BaseMultiplier * 100
					totalIncomeThisSecond += monsterPower
				end
			end
		end

		if totalIncomeThisSecond > 0 then
			profile.PendingMoney += totalIncomeThisSecond
			-- print(player.Name .. " earned " .. totalIncomeThisSecond .. " money from mining! Total: " .. profile.Money)
		end
	end
end

return MiningService
