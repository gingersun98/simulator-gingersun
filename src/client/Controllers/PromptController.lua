local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PromptController = Knit.CreateController({
	Name = "PromptController",
})

function PromptController:KnitStart()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local equipSoundTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds"):WaitForChild("EquipPet")
	local eggHatchSoundTemplate =
		ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds"):WaitForChild("EggHatch")
	local hatchParticleTemplate =
		ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VFX"):WaitForChild("HatchParticle")

	local defaultUI = playerGui:WaitForChild("CustomPromptUI")
	defaultUI.Enabled = false

	local sellUI = playerGui:WaitForChild("SellPromptUI")
	sellUI.Enabled = false

	local activeUIs = {}
	local activeTweens = {}
	local promptConnections = {}

	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			local uiClone

			if prompt.Name == "SellPrompt" then
				uiClone = sellUI:Clone()
			else
				uiClone = defaultUI:Clone()
			end

			uiClone.Enabled = true
			uiClone.Adornee = prompt.Parent
			uiClone.Parent = playerGui

			local mainFrame = uiClone:WaitForChild("MainFrame")
			local actionText = mainFrame:WaitForChild("ActionText")
			local keyText = mainFrame:WaitForChild("KeyText")
			mainFrame.Active = true

			local clickArea = Instance.new("TextButton")
			clickArea.Name = "ClickArea"
			clickArea.Size = UDim2.fromScale(1, 1)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.ZIndex = 10
			clickArea.Active = true
			clickArea.Modal = true
			clickArea.AutoButtonColor = false
			clickArea.Parent = mainFrame

			local isHolding = false

			local function beginHold()
				if isHolding then
					return
				end
				isHolding = true
				prompt:InputHoldBegin()
			end

			local function endHold()
				if not isHolding then
					return
				end
				isHolding = false
				prompt:InputHoldEnd()
			end

			clickArea.MouseButton1Down:Connect(beginHold)
			clickArea.MouseButton1Up:Connect(endHold)

			-- Fallback for tap/quick click prompts (especially HoldDuration = 0)
			clickArea.Activated:Connect(function()
				if isHolding then
					endHold()
					return
				end

				if prompt.HoldDuration <= 0 then
					prompt:InputHoldBegin()
					prompt:InputHoldEnd()
				end
			end)

			clickArea.MouseLeave:Connect(function()
				endHold()
			end)

			local function updateUI()
				actionText.Text = prompt.ActionText
				if inputType == Enum.ProximityPromptInputType.Gamepad then
					keyText.Text = prompt.GamepadKeyCode.Name
				else
					keyText.Text = prompt.KeyboardKeyCode.Name
				end
			end

			updateUI()

			local conn = prompt:GetPropertyChangedSignal("ActionText"):Connect(updateUI)
			promptConnections[prompt] = conn

			activeUIs[prompt] = uiClone
		end
	end)

	ProximityPromptService.PromptHidden:Connect(function(prompt)
		local ui = activeUIs[prompt]
		if ui then
			ui:Destroy()
			activeUIs[prompt] = nil

			if activeTweens[prompt] then
				activeTweens[prompt]:Cancel()
				activeTweens[prompt] = nil
			end

			if promptConnections[prompt] then
				promptConnections[prompt]:Disconnect()
				promptConnections[prompt] = nil
			end
		end
	end)

	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		local ui = activeUIs[prompt]
		if ui then
			local progressBar = ui:FindFirstChild("ProgressBG", true).Bar
			progressBar.Size = UDim2.fromScale(0, 1)

			local tweenInfo = TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear)
			local tween = TweenService:Create(progressBar, tweenInfo, { Size = UDim2.fromScale(1, 1) })
			tween:Play()

			activeTweens[prompt] = tween
		end
	end)

	ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
		local ui = activeUIs[prompt]
		if ui then
			local tween = activeTweens[prompt]
			if tween then
				tween:Cancel()
				local progressBar = ui:FindFirstChild("ProgressBG", true).Bar
				progressBar.Size = UDim2.fromScale(0, 1)
				activeTweens[prompt] = nil
			end
		end
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local soundClone = equipSoundTemplate:Clone()
		soundClone.Parent = SoundService
		soundClone:Play()
		Debris:AddItem(soundClone, math.max(soundClone.TimeLength, 1) + 0.25)

		if prompt and prompt.Name == "HatchPrompt" then
			local hatchSoundClone = eggHatchSoundTemplate:Clone()
			hatchSoundClone.Parent = SoundService
			hatchSoundClone:Play()
			Debris:AddItem(hatchSoundClone, math.max(hatchSoundClone.TimeLength, 1) + 0.25)

			local emitterParent = nil
			if prompt.Parent and (prompt.Parent:IsA("BasePart") or prompt.Parent:IsA("Attachment")) then
				emitterParent = prompt.Parent
			else
				emitterParent = prompt:FindFirstAncestorWhichIsA("BasePart")
			end

			if emitterParent then
				local hatchEmitter = hatchParticleTemplate:Clone()
				hatchEmitter.Name = "PromptHatchParticle"
				hatchEmitter.Parent = emitterParent

				if hatchEmitter:IsA("ParticleEmitter") then
					hatchEmitter.Enabled = false
					hatchEmitter.Rate = 0
					hatchEmitter:Clear()
					hatchEmitter:Emit(30)
				end

				Debris:AddItem(hatchEmitter, 2)
			end
		end
	end)
end

return PromptController
