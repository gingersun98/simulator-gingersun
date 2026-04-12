local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local UiModalEffects = require(script.Parent.Parent.Modules.UiModalEffects)
local CashPurchaseEffect = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("CashPurchaseEffect"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Zone = require(ReplicatedStorage.Packages.zoneplus)
local EconomyMath = require(ReplicatedStorage.Shared.Modules.EconomyMath)

local CLICK_SOUND_TEMPLATE = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds"):WaitForChild("Click")

local UpgradeController = Knit.CreateController({
	Name = "UpgradeController",
})

local ROBUX_PRICES = {
	[1] = 5,
	[5] = 23,
	[10] = 38,
}

local ROBUX_PRODUCT_IDS = {
	Power = {
		[1] = 3574575697,
		[5] = 3574576195,
		[10] = 3574576644,
	},
	Mining = {
		[1] = 3574577388,
		[5] = 3574577673,
		[10] = 3574577826,
	},
}

function UpgradeController:KnitStart()
	local DataService = Knit.GetService("DataService")
	local UpgradeService = Knit.GetService("UpgradeService")

	local function playClickSound()
		local soundClone = CLICK_SOUND_TEMPLATE:Clone()
		soundClone.Parent = SoundService
		soundClone:Play()
		Debris:AddItem(soundClone, math.max(soundClone.TimeLength, 1) + 0.25)
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local framesUI = playerGui:WaitForChild("Frames")
	local function bindUpgradeFrame(config)
		local frame = framesUI:WaitForChild(config.frameName)
		local scrollingFrame = frame:WaitForChild("ScrollingFrame")
		local closeButton = frame:WaitForChild("Close")
		local zonePart = Workspace:WaitForChild(config.zoneName):WaitForChild("Zone")
		local zone = Zone.new(zonePart)

		local optionFrames = {
			[1] = scrollingFrame:WaitForChild("Frame1"),
			[5] = scrollingFrame:WaitForChild("Frame5"),
			[10] = scrollingFrame:WaitForChild("Frame10"),
		}

		frame.Visible = false
		UiModalEffects.SetupHoverEffect(closeButton)

		local function updateFrameUI(data)
			if not data or not data.Upgrades then
				return
			end

			local currentLevel = data.Upgrades[config.levelKey] or 1

			for amount, optionFrame in pairs(optionFrames) do
				local cost = config.getCost(currentLevel, amount)

				optionFrame.PowerTotal.Text = currentLevel .. " >> " .. (currentLevel + amount)
				optionFrame.ButtonFrame.MoneyButton.TextLabel.Text = EconomyMath.FormatNumber(cost)
				optionFrame.ButtonFrame.RobuxButton.TextLabel.Text = tostring(ROBUX_PRICES[amount])
			end
		end

		local function openFrame()
			if frame.Visible then
				return
			end

			frame.Visible = true
			UiModalEffects.PlayOpenFrame(frame)
			UiModalEffects.OpenModal()
		end

		local function closeFrame()
			if not frame.Visible then
				return
			end

			frame.Visible = false
			UiModalEffects.CloseModal()
		end

		for amount, optionFrame in pairs(optionFrames) do
			local moneyBtn = optionFrame.ButtonFrame.MoneyButton
			local robuxBtn = optionFrame.ButtonFrame.RobuxButton

			UiModalEffects.SetupHoverEffect(moneyBtn)
			UiModalEffects.SetupHoverEffect(robuxBtn)

			moneyBtn.MouseButton1Click:Connect(function()
				playClickSound()
				config
					.buyWithMoney(amount)
					:andThen(function()
						CashPurchaseEffect.Play()
					end)
					:catch(warn)
			end)

			robuxBtn.MouseButton1Click:Connect(function()
				playClickSound()
				local productId = config.robuxProductIds and config.robuxProductIds[amount]
				if not productId then
					warn("Missing Robux product id for " .. config.frameName .. " amount: " .. tostring(amount))
					return
				end

				MarketplaceService:PromptProductPurchase(player, productId)
			end)
		end

		zone.localPlayerEntered:Connect(openFrame)
		zone.localPlayerExited:Connect(closeFrame)
		closeButton.MouseButton1Click:Connect(function()
			playClickSound()
			closeFrame()
		end)

		return updateFrameUI
	end

	local updatePowerFrame = bindUpgradeFrame({
		frameName = "Upgrades",
		zoneName = "UpgradeZonePower",
		levelKey = "PowerLevel",
		getCost = EconomyMath.GetPowerUpgradeCost,
		robuxProductIds = ROBUX_PRODUCT_IDS.Power,
		buyWithMoney = function(amount)
			return UpgradeService:BuyPowerUpgrade(amount)
		end,
	})

	local updateMineFrame = bindUpgradeFrame({
		frameName = "MineUpgrades",
		zoneName = "UpgradeZoneMine",
		levelKey = "MiningLevel",
		getCost = EconomyMath.GetMineUpgradeCost,
		robuxProductIds = ROBUX_PRODUCT_IDS.Mining,
		buyWithMoney = function(amount)
			return UpgradeService:BuyMiningUpgrade(amount)
		end,
	})

	local function UpdateUI(data)
		updatePowerFrame(data)
		updateMineFrame(data)
	end

	DataService:GetData()
		:andThen(function(data)
			UpdateUI(data)
		end)
		:catch(warn)

	DataService.DataChanged:Connect(function(newData)
		UpdateUI(newData)
	end)
end

function UpgradeController:KnitInit()
	print("UpgradeController is running!")
end

return UpgradeController
