local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UiModalEffects = require(script.Parent.Parent.Modules.UiModalEffects)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Zone = require(ReplicatedStorage.Packages.zoneplus)
local EconomyMath = require(ReplicatedStorage.Shared.Modules.EconomyMath)

local UpgradeController = Knit.CreateController({
	Name = "UpgradeController",
})

local ROBUX_PRICES = {
	[1] = 5,
	[5] = 23,
	[10] = 38,
}

function UpgradeController:KnitStart()
	local DataService = Knit.GetService("DataService")
	local UpgradeService = Knit.GetService("UpgradeService")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local framesUI = playerGui:WaitForChild("Frames")
	local upgradeFrame = framesUI:WaitForChild("Upgrades")
	local scrollingFrame = upgradeFrame:WaitForChild("ScrollingFrame")
	local closeButton = upgradeFrame:WaitForChild("Close")
	local frames = {
		[1] = scrollingFrame:WaitForChild("Frame1"),
		[5] = scrollingFrame:WaitForChild("Frame5"),
		[10] = scrollingFrame:WaitForChild("Frame10"),
	}

	upgradeFrame.Visible = false
	UiModalEffects.SetupHoverEffect(closeButton)

	local function UpdateUI(data)
		if not data or not data.Upgrades then
			return
		end

		local currentLevel = data.Upgrades.PowerLevel or 1

		for amount, frame in pairs(frames) do
			local cost = EconomyMath.GetCumulativeUpgradeCost(
				EconomyMath.POWER_BASE_PRICE,
				EconomyMath.POWER_MULTIPLIER,
				currentLevel,
				amount
			)

			frame.PowerTotal.Text = currentLevel .. " >> " .. (currentLevel + amount)
			frame.ButtonFrame.MoneyButton.TextLabel.Text = EconomyMath.FormatNumber(cost)
			frame.ButtonFrame.RobuxButton.TextLabel.Text = tostring(ROBUX_PRICES[amount])
		end
	end

	DataService:GetData()
		:andThen(function(data)
			UpdateUI(data)
		end)
		:catch(warn)

	DataService.DataChanged:Connect(function(newData)
		UpdateUI(newData)
	end)

	for amount, frame in pairs(frames) do
		local moneyBtn = frame.ButtonFrame.MoneyButton
		local robuxBtn = frame.ButtonFrame.RobuxButton

		moneyBtn.MouseButton1Click:Connect(function()
			UpgradeService:BuyPowerUpgrade(amount):catch(warn)
		end)

		robuxBtn.MouseButton1Click:Connect(function()
			print("Prompting Robux Purchase for amount: " .. amount)
		end)
	end

	local function openUpgradeUI()
		if upgradeFrame.Visible then
			return
		end

		upgradeFrame.Visible = true
		UiModalEffects.PlayOpenFrame(upgradeFrame)
		UiModalEffects.OpenModal()
	end

	local function closeUpgradeUI()
		if not upgradeFrame.Visible then
			return
		end

		upgradeFrame.Visible = false
		UiModalEffects.CloseModal()
	end

	local zonePart = Workspace:WaitForChild("UpgradeZonePower"):WaitForChild("Zone")
	local upgradeZone = Zone.new(zonePart)

	upgradeZone.localPlayerEntered:Connect(function()
		openUpgradeUI()
	end)

	upgradeZone.localPlayerExited:Connect(function()
		closeUpgradeUI()
	end)

	closeButton.MouseButton1Click:Connect(closeUpgradeUI)
end

function UpgradeController:KnitInit()
	print("UpgradeController is running!")
end

return UpgradeController
