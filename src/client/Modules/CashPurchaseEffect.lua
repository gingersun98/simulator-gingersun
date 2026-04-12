local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local CashPurchaseEffect = {}

local CONFIG = {
	TextureId = "rbxassetid://18885492705",
	ParticleCount = 35,
	MinSize = 25,
	MaxSize = 55,
	MinDuration = 1.5,
	MaxDuration = 3.5,
}

local localPlayer = Players.LocalPlayer
local containerFrame = nil

local function getContainer(): Frame?
	if not localPlayer then
		return nil
	end

	if containerFrame and containerFrame.Parent then
		return containerFrame
	end

	local playerGui = localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui")
	if not playerGui then
		return nil
	end

	local screenGui = playerGui:FindFirstChild("CashFXGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "CashFXGui"
		screenGui.IgnoreGuiInset = true
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
	end

	local frame = screenGui:FindFirstChild("Particles")
	if not frame then
		frame = Instance.new("Frame")
		frame.Name = "Particles"
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundTransparency = 1
		frame.Parent = screenGui
	end

	containerFrame = frame
	return containerFrame
end

function CashPurchaseEffect.Play()
	local container = getContainer()
	if not container then
		return
	end

	for _ = 1, CONFIG.ParticleCount do
		local cash = Instance.new("ImageLabel")
		cash.Image = CONFIG.TextureId
		cash.BackgroundTransparency = 1
		cash.ImageTransparency = 0
		cash.AnchorPoint = Vector2.new(0.5, 0.5)

		local size = math.random(CONFIG.MinSize, CONFIG.MaxSize)
		cash.Size = UDim2.fromOffset(size, size)

		local startX = math.random()
		cash.Position = UDim2.fromScale(startX, -0.1)
		cash.Rotation = math.random(0, 360)
		cash.Parent = container

		local duration = CONFIG.MinDuration + (math.random() * (CONFIG.MaxDuration - CONFIG.MinDuration))
		local endX = startX + ((math.random() - 0.5) * 0.2)
		local endPos = UDim2.fromScale(endX, 1.1)

		local spin = math.random(180, 540)
		if math.random() > 0.5 then
			spin = -spin
		end

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		local goal = {
			Position = endPos,
			Rotation = cash.Rotation + spin,
			ImageTransparency = 1,
		}

		TweenService:Create(cash, tweenInfo, goal):Play()
		Debris:AddItem(cash, duration + 0.5)
	end
end

return CashPurchaseEffect
