-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local WallConstants = require(ReplicatedStorage.Shared.Constants.WallConstants)

local WallController = Knit.CreateController({
	Name = "WallController",
})

local HEALTH_BAR_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SHATTER_CONFIG = {
	DebrisCount = 40,
	SizeMin = 1.5,
	SizeMax = 5.0,
	DebrisThicknessMin = 2,
	DebrisThicknessMax = 3.5,
	ForwardForce = -40,
	DownwardForce = -10,
	Spread = 32,
	FadeTime = 1,
	DestroyTime = 1,
}

local brokenWalls = {}

local function randomFloat(minValue: number, maxValue: number): number
	return minValue + (math.random() * (maxValue - minValue))
end

local function findHealthUi(wallArea: Instance)
	local wallModel = wallArea:FindFirstChild("WallModel")
	if not wallModel or not wallModel:IsA("Model") then
		return nil, nil, nil
	end

	local bigWall = wallModel:FindFirstChild("BigWall")
	if not bigWall then
		return nil, nil, nil
	end

	local healthGui = bigWall:FindFirstChild("HealthGUI")
	if not healthGui or not healthGui:IsA("SurfaceGui") then
		return nil, nil, nil
	end

	local healthFrame = healthGui:FindFirstChild("Health")
	local barBg = healthFrame and healthFrame:FindFirstChild("BarBG")
	local bar = barBg and barBg:FindFirstChild("Bar")
	local textLabel = barBg and barBg:FindFirstChild("TextLabel")

	if not bar or not bar:IsA("Frame") then
		return nil, nil, healthGui
	end

	if textLabel and not textLabel:IsA("TextLabel") then
		textLabel = nil
	end

	return bar, textLabel, healthGui
end

local function setHealthGuiEnabled(wallArea: Instance, isEnabled: boolean)
	local _, _, healthGui = findHealthUi(wallArea)
	if healthGui then
		healthGui.Enabled = isEnabled
	end
end

local function applyWallModelState(wallArea: Instance, isVisible: boolean)
	local targetTransparency = isVisible and 0 or 1

	local legacyWall = wallArea:FindFirstChild("Wall")
	if legacyWall and legacyWall:IsA("BasePart") then
		legacyWall.CanCollide = isVisible
		legacyWall.Transparency = targetTransparency
	end

	local wallModel = wallArea:FindFirstChild("WallModel")
	if wallModel and wallModel:IsA("Model") then
		for _, descendant in ipairs(wallModel:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = isVisible
				descendant.Transparency = targetTransparency
			end
		end
	end
end

local function triggerShatter(wallArea: Instance)
	if brokenWalls[wallArea] then
		return
	end
	brokenWalls[wallArea] = true

	local wall = wallArea:FindFirstChild("Wall")
	if not wall or not wall:IsA("BasePart") then
		return
	end

	local attachment = wall:FindFirstChild("Attachment")
	if attachment and attachment:IsA("Attachment") then
		local emitter = attachment:FindFirstChild("Emitter") or attachment:FindFirstChildOfClass("ParticleEmitter")
		if emitter and emitter:IsA("ParticleEmitter") then
			emitter:Emit(1)
		end
	end

	local sound = wall:FindFirstChild("WallDestroy")
	if sound and sound:IsA("Sound") then
		sound:Play()

		local fallback = sound:Clone()
		fallback.Name = "WallDestroy_Local"
		fallback.RollOffMode = Enum.RollOffMode.Linear
		fallback.Parent = SoundService
		fallback:Play()
		Debris:AddItem(fallback, math.max(fallback.TimeLength, 1) + 0.25)
	end

	for _ = 1, SHATTER_CONFIG.DebrisCount do
		local piece = Instance.new("Part")
		local randY = randomFloat(SHATTER_CONFIG.SizeMin, SHATTER_CONFIG.SizeMax)
		local randX = randomFloat(SHATTER_CONFIG.DebrisThicknessMin, SHATTER_CONFIG.DebrisThicknessMax)
		local randZ = randomFloat(SHATTER_CONFIG.DebrisThicknessMin, SHATTER_CONFIG.DebrisThicknessMax)

		piece.Size = Vector3.new(randX, randY, randZ)
		piece.Color = wall.Color
		piece.Material = wall.Material
		piece.Anchored = false
		piece.CanCollide = true
		piece.Massless = true

		local offsetX = (math.random() - 0.5) * wall.Size.X
		local offsetY = (math.random() - 0.5) * wall.Size.Y
		local offsetZ = (math.random() - 0.5) * wall.Size.Z
		piece.CFrame = wall.CFrame * CFrame.new(offsetX, offsetY, offsetZ)
		piece.Parent = workspace

		local forwardDirection = wall.CFrame.LookVector
		local randomSpread = Vector3.new(
			randomFloat(-SHATTER_CONFIG.Spread, SHATTER_CONFIG.Spread),
			randomFloat(SHATTER_CONFIG.DownwardForce - 10, SHATTER_CONFIG.DownwardForce + 10),
			randomFloat(-SHATTER_CONFIG.Spread, SHATTER_CONFIG.Spread)
		)

		piece.AssemblyLinearVelocity = (forwardDirection * SHATTER_CONFIG.ForwardForce) + randomSpread
		piece.AssemblyAngularVelocity = Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))

		TweenService:Create(
			piece,
			TweenInfo.new(SHATTER_CONFIG.FadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.2),
			{ Transparency = 1 }
		):Play()

		Debris:AddItem(piece, SHATTER_CONFIG.DestroyTime)
	end
end

function WallController:UpdateWallHealthUI(wallId: string, currentHp: number)
	local wallFolder = workspace:FindFirstChild("BreakableWalls")
	local wallArea = wallFolder and wallFolder:FindFirstChild(wallId)
	if not wallArea then
		return
	end

	local config = WallConstants.Data[wallId]
	if not config then
		return
	end

	local maxHp = config.MaxHP
	local clampedHp = math.clamp(currentHp, 0, maxHp)
	local ratio = if maxHp > 0 then clampedHp / maxHp else 0

	local bar, textLabel = findHealthUi(wallArea)
	if not bar then
		return
	end

	TweenService:Create(bar, HEALTH_BAR_TWEEN, { Size = UDim2.fromScale(ratio, bar.Size.Y.Scale) }):Play()

	if textLabel then
		textLabel.Text = string.format("%d/%d", math.floor(clampedHp), math.floor(maxHp))
	end
end

function WallController:SetInitialWallHealthUI()
	for wallId, config in pairs(WallConstants.Data) do
		self:UpdateWallHealthUI(wallId, config.MaxHP)
	end
end

function WallController:KnitStart()
	local WallService = Knit.GetService("WallService")

	self:SetInitialWallHealthUI()

	WallService.WallDamaged:Connect(function(wallId, currentHp)
		self:UpdateWallHealthUI(wallId, currentHp)
	end)

	WallService.WallDestroyed:Connect(function(wallId)
		self:ProcessWallDestruction(wallId)
		self:UpdateWallHealthUI(wallId, 0)
	end)

	WallService.WallReset:Connect(function(wallId)
		self:SetWallVisibility(wallId, true)
		local config = WallConstants.Data[wallId]
		if config then
			self:UpdateWallHealthUI(wallId, config.MaxHP)
		end
	end)
end

function WallController:ProcessWallDestruction(wallId)
	local wallFolder = workspace:FindFirstChild("BreakableWalls")
	local wallArea = wallFolder and wallFolder:FindFirstChild(wallId)
	if not wallArea then
		return
	end

	triggerShatter(wallArea)
	applyWallModelState(wallArea, false)
	setHealthGuiEnabled(wallArea, false)
end

function WallController:SetWallVisibility(wallId, isVisible)
	local wallFolder = workspace:FindFirstChild("BreakableWalls")
	local wallArea = wallFolder and wallFolder:FindFirstChild(wallId)
	if not wallArea then
		return
	end

	if isVisible then
		brokenWalls[wallArea] = nil
	end

	applyWallModelState(wallArea, isVisible)
	setHealthGuiEnabled(wallArea, isVisible)
end

return WallController
