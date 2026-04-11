local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyMath = require(ReplicatedStorage.Shared.Modules.EconomyMath)

local CurrencyController = Knit.CreateController({
	Name = "CurrencyController",
})

local PULSE_INTERVAL = 0.05
local PULSE_UP_DURATION = 0.05
local PULSE_DOWN_DURATION = 0.06
local PULSE_BUMP_SCALE = 1.2

function CurrencyController:KnitStart()
	local DataService = Knit.GetService("DataService")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local mainUI = playerGui:WaitForChild("Main")
	local currencyRoot = mainUI:WaitForChild("Currency")
	local uiScale = currencyRoot:FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = currencyRoot
	end

	local function createAnimatedCounter(frameName, formatter)
		local frame = currencyRoot:WaitForChild(frameName)
		local textLabel = frame:WaitForChild("TextLabel")

		local displayedValue = 0
		local animationId = 0
		local pulseId = 0
		local currentTween = nil
		local currentValueObject = nil
		local currentValueConnection = nil

		local function setText(value)
			textLabel.Text = formatter(value)
		end

		local function stopCurrentAnimation()
			pulseId += 1

			if currentTween then
				currentTween:Cancel()
				currentTween = nil
			end

			if currentValueConnection then
				currentValueConnection:Disconnect()
				currentValueConnection = nil
			end

			if currentValueObject then
				currentValueObject:Destroy()
				currentValueObject = nil
			end
		end

		local function playPulseWhileIncreasing(localAnimationId)
			pulseId += 1
			local localPulseId = pulseId

			task.spawn(function()
				while animationId == localAnimationId and pulseId == localPulseId do
					task.wait(PULSE_INTERVAL)
					if animationId ~= localAnimationId or pulseId ~= localPulseId then
						break
					end

					local upTween = TweenService:Create(
						uiScale,
						TweenInfo.new(PULSE_UP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Scale = PULSE_BUMP_SCALE }
					) :: Tween
					upTween:Play()
					upTween.Completed:Wait()

					if animationId ~= localAnimationId or pulseId ~= localPulseId then
						break
					end

					local downTween = TweenService:Create(
						uiScale,
						TweenInfo.new(PULSE_DOWN_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Scale = 1 }
					) :: Tween
					downTween:Play()
					downTween.Completed:Wait()
				end
			end)
		end

		local function animateTo(targetValue: number)
			targetValue = math.max(0, math.floor(targetValue))
			if targetValue == displayedValue then
				return
			end

			animationId += 1
			local localAnimationId = animationId

			stopCurrentAnimation()

			local startValue = displayedValue
			local delta = math.abs(targetValue - startValue)
			local duration = math.clamp(delta / 1500, 0.12, 0.9)

			local valueObject = Instance.new("NumberValue")
			valueObject.Value = startValue
			currentValueObject = valueObject

			currentValueConnection = valueObject:GetPropertyChangedSignal("Value"):Connect(function()
				displayedValue = math.floor(valueObject.Value)
				setText(displayedValue)
			end)

			local tween = TweenService:Create(
				valueObject,
				TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Value = targetValue }
			) :: Tween
			currentTween = tween

			if targetValue > startValue then
				playPulseWhileIncreasing(localAnimationId)
			end

			tween:Play()
			tween.Completed:Connect(function()
				if animationId ~= localAnimationId then
					return
				end

				displayedValue = targetValue
				setText(displayedValue)
				TweenService
					:Create(
						uiScale,
						TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Scale = 1 }
					)
					:Play()
				stopCurrentAnimation()
			end)
		end

		setText(displayedValue)

		return animateTo
	end

	local animateMoneyTo = createAnimatedCounter("Money", function(value)
		return EconomyMath.FormatNumber(value)
	end)

	local animatePowerLevelTo = createAnimatedCounter("Power", function(value)
		return tostring(value)
	end)

	local animateMiningLevelTo = createAnimatedCounter("Mine", function(value)
		return tostring(value)
	end)

	local function animateCurrencyFields(data)
		if not data then
			return
		end

		animateMoneyTo(data.Money or 0)

		local upgrades = data.Upgrades or {}
		animatePowerLevelTo(upgrades.PowerLevel or 1)
		animateMiningLevelTo(upgrades.MiningLevel or 1)
	end

	DataService:GetData()
		:andThen(function(data)
			animateCurrencyFields(data)
		end)
		:catch(warn)

	DataService.DataChanged:Connect(function(newData)
		animateCurrencyFields(newData)
	end)
end

return CurrencyController
