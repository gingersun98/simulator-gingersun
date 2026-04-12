local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyMath = require(ReplicatedStorage.Shared.Modules.EconomyMath)

local CurrencyController = Knit.CreateController({
	Name = "CurrencyController",
})

local PULSE_INTERVAL = 0.05
local PULSE_UP_DURATION = 0.05
local PULSE_DOWN_DURATION = 0.06
local PULSE_BUMP_SCALE = 1.2
local COLLECT_PARTICLE_COOLDOWN = 0.15
local BUMP_PARTICLE_EMIT_COUNT = 6
local MONEY_PARTICLE_EMIT_COUNT = 5
local CLAIM_LOCK_COLOR = Color3.fromRGB(172, 57, 57)

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

	local function createAnimatedCounter(textLabel, pulseScale, formatter)
		if not pulseScale then
			pulseScale = Instance.new("UIScale")
			pulseScale.Parent = textLabel.Parent
		end

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
						pulseScale,
						TweenInfo.new(PULSE_UP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Scale = PULSE_BUMP_SCALE }
					) :: Tween
					upTween:Play()
					upTween.Completed:Wait()

					if animationId ~= localAnimationId or pulseId ~= localPulseId then
						break
					end

					local downTween = TweenService:Create(
						pulseScale,
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
						pulseScale,
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

	local moneyFrame = currencyRoot:WaitForChild("Money")
	local powerFrame = currencyRoot:WaitForChild("Power")
	local mineFrame = currencyRoot:WaitForChild("Mine")

	local animateMoneyTo = createAnimatedCounter(moneyFrame:WaitForChild("TextLabel"), uiScale, function(value)
		return EconomyMath.FormatNumber(value)
	end)

	local animatePowerLevelTo = createAnimatedCounter(powerFrame:WaitForChild("TextLabel"), uiScale, function(value)
		return tostring(value)
	end)

	local animateMiningLevelTo = createAnimatedCounter(mineFrame:WaitForChild("TextLabel"), uiScale, function(value)
		return tostring(value)
	end)

	local pendingMoneyAnimator = nil
	local pendingMoneyLabel = nil
	local pendingBindConnection = nil
	local collectTouchConnection = nil
	local collectTouchPart = nil
	local lastCollectParticleAt = 0
	local latestPendingMoney = 0

	local function bindCollectParticles(collectPart: BasePart)
		if collectTouchPart == collectPart and collectTouchConnection then
			return
		end

		if collectTouchConnection then
			collectTouchConnection:Disconnect()
			collectTouchConnection = nil
		end

		collectTouchPart = collectPart

		collectTouchConnection = collectPart.Touched:Connect(function(hit)
			local character = player.Character
			if not character then
				return
			end

			if not hit or not hit:IsDescendantOf(character) then
				return
			end

			if latestPendingMoney <= 0 then
				return
			end

			if collectPart.Color == CLAIM_LOCK_COLOR then
				return
			end

			local now = tick()
			if now - lastCollectParticleAt < COLLECT_PARTICLE_COOLDOWN then
				return
			end
			lastCollectParticleAt = now

			local bump = collectPart:FindFirstChild("BumpParticle", true)
			if bump and bump:IsA("ParticleEmitter") then
				bump:Emit(BUMP_PARTICLE_EMIT_COUNT)
			end

			local money = collectPart:FindFirstChild("MoneyParticle", true)
			if money and money:IsA("ParticleEmitter") then
				money:Emit(MONEY_PARTICLE_EMIT_COUNT)
			end

			local claimSound = collectPart:FindFirstChild("CollectSound", true)
			if claimSound and claimSound:IsA("Sound") then
				claimSound:Play()
			end
		end)
	end

	local function tryBindPendingMoneyGui()
		if pendingMoneyLabel and pendingMoneyLabel.Parent and pendingMoneyAnimator then
			if pendingBindConnection then
				pendingBindConnection:Disconnect()
				pendingBindConnection = nil
			end
			return
		end

		pendingMoneyAnimator = nil
		pendingMoneyLabel = nil

		local safehouseFolder = Workspace:FindFirstChild("Safehouse_" .. player.Name, true)
		if not safehouseFolder then
			return
		end

		local collectPart = safehouseFolder:FindFirstChild("Green", true)
		if not collectPart or not collectPart:IsA("BasePart") then
			return
		end

		bindCollectParticles(collectPart)

		local upgradeGui = collectPart:FindFirstChild("UpgradeSafehouseGUI")
		if not upgradeGui or not upgradeGui:IsA("BillboardGui") then
			return
		end

		local mainFrame = upgradeGui:FindFirstChild("MainFrame")
		local contentFrame = mainFrame and mainFrame:FindFirstChild("Frame")
		local collectText = contentFrame and contentFrame:FindFirstChild("CollectText")
		if not mainFrame or not contentFrame or not collectText or not collectText:IsA("TextLabel") then
			return
		end

		mainFrame.Visible = true

		local pendingScale = contentFrame:FindFirstChild("UIScale")
		if not pendingScale then
			pendingScale = Instance.new("UIScale")
			pendingScale.Parent = contentFrame
		end

		pendingMoneyLabel = collectText
		pendingMoneyAnimator = createAnimatedCounter(collectText, pendingScale, function(value)
			return EconomyMath.FormatNumber(value)
		end)

		if pendingBindConnection then
			pendingBindConnection:Disconnect()
			pendingBindConnection = nil
		end
	end

	tryBindPendingMoneyGui()
	if not pendingMoneyAnimator then
		pendingBindConnection = Workspace.DescendantAdded:Connect(function(descendant)
			if pendingMoneyAnimator then
				if pendingBindConnection then
					pendingBindConnection:Disconnect()
					pendingBindConnection = nil
				end
				return
			end

			if
				descendant.Name == ("Safehouse_" .. player.Name)
				or descendant.Name == "Green"
				or descendant.Name == "UpgradeSafehouseGUI"
			then
				task.defer(tryBindPendingMoneyGui)
			end
		end)
	end

	local function animateCurrencyFields(data)
		if not data then
			return
		end

		latestPendingMoney = data.PendingMoney or 0

		animateMoneyTo(data.Money or 0)

		local upgrades = data.Upgrades or {}
		animatePowerLevelTo(upgrades.PowerLevel or 1)
		animateMiningLevelTo(upgrades.MiningLevel or 1)

		if not pendingMoneyAnimator then
			tryBindPendingMoneyGui()
		end

		if pendingMoneyAnimator then
			pendingMoneyAnimator(latestPendingMoney)
		end
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
