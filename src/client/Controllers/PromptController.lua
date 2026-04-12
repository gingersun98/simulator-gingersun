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

	ProximityPromptService.PromptTriggered:Connect(function()
		local soundClone = equipSoundTemplate:Clone()
		soundClone.Parent = SoundService
		soundClone:Play()
		Debris:AddItem(soundClone, math.max(soundClone.TimeLength, 1) + 0.25)
	end)
end

return PromptController
