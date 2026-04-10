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
	local uiScale = currencyRoot:WaitForChild("Money"):FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = currencyRoot
	end

	local moneyTextLabel = currencyRoot:WaitForChild("Money"):WaitForChild("TextLabel")

	local displayedMoney = 0
	local animationId = 0
	local pulseId = 0
	local currentTween: Tween? = nil
	local currentValueObject: NumberValue? = nil
	local currentValueConnection: RBXScriptConnection? = nil

	local function setMoneyText(value: number)
		moneyTextLabel.Text = EconomyMath.FormatNumber(value)
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

	local function playPulseWhileIncreasing(localAnimationId: number)
		pulseId += 1
		local localPulseId = pulseId

		task.spawn(function()
			while animationId == localAnimationId and pulseId == localPulseId do
				task.wait(PULSE_INTERVAL)
				if animationId ~= localAnimationId or pulseId ~= localPulseId then
					break
				end

				local bumpScale = PULSE_BUMP_SCALE
				local upTween = TweenService:Create(
					uiScale,
					TweenInfo.new(PULSE_UP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Scale = bumpScale }
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

	local function animateMoneyTo(targetMoney: number)
		targetMoney = math.max(0, math.floor(targetMoney))
		if targetMoney == displayedMoney then
			return
		end

		animationId += 1
		local localAnimationId = animationId

		stopCurrentAnimation()

		local startMoney = displayedMoney
		local delta = math.abs(targetMoney - startMoney)
		local duration = math.clamp(delta / 1500, 0.12, 0.9)

		local valueObject = Instance.new("NumberValue")
		valueObject.Value = startMoney
		currentValueObject = valueObject

		currentValueConnection = valueObject:GetPropertyChangedSignal("Value"):Connect(function()
			displayedMoney = math.floor(valueObject.Value)
			setMoneyText(displayedMoney)
		end)

		local tween = TweenService:Create(
			valueObject,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = targetMoney }
		) :: Tween
		currentTween = tween

		if targetMoney > startMoney then
			playPulseWhileIncreasing(localAnimationId)
		end

		tween:Play()
		tween.Completed:Connect(function()
			if animationId ~= localAnimationId then
				return
			end

			displayedMoney = targetMoney
			setMoneyText(displayedMoney)
			TweenService
				:Create(uiScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
				:Play()
			stopCurrentAnimation()
		end)
	end

	DataService:GetData()
		:andThen(function(data)
			if data then
				animateMoneyTo(data.Money or 0)
			end
		end)
		:catch(warn)

	DataService.DataChanged:Connect(function(newData)
		if not newData then
			return
		end
		animateMoneyTo(newData.Money or 0)
	end)
end

return CurrencyController
