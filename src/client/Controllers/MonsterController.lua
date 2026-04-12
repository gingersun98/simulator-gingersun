local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local player = Players.LocalPlayer

local PET_HEIGHT = 5
local BASE_DISTANCE = 9.0
local ROW_SPACING = 4.5
local X_SPACING = 3

local FORMATIONS = {
	[1] = {
		CFrame.new(0, PET_HEIGHT, BASE_DISTANCE),
	},
	[2] = {
		CFrame.new(-X_SPACING, PET_HEIGHT, BASE_DISTANCE),
		CFrame.new(X_SPACING, PET_HEIGHT, BASE_DISTANCE),
	},
	[3] = {
		CFrame.new(0, PET_HEIGHT, BASE_DISTANCE),
		CFrame.new(-X_SPACING * 1.2, PET_HEIGHT, BASE_DISTANCE),
		CFrame.new(X_SPACING * 1.2, PET_HEIGHT, BASE_DISTANCE),
	},
	[4] = {
		CFrame.new(-X_SPACING * 0.8, PET_HEIGHT, BASE_DISTANCE),
		CFrame.new(X_SPACING * 0.8, PET_HEIGHT, BASE_DISTANCE),
		CFrame.new(-X_SPACING, PET_HEIGHT, BASE_DISTANCE + ROW_SPACING),
		CFrame.new(X_SPACING, PET_HEIGHT, BASE_DISTANCE + ROW_SPACING),
	},
	[5] = {
		CFrame.new(0, PET_HEIGHT, BASE_DISTANCE),
		CFrame.new(-X_SPACING * 1.2, PET_HEIGHT, BASE_DISTANCE),
		CFrame.new(X_SPACING * 1.2, PET_HEIGHT, BASE_DISTANCE),
		CFrame.new(-X_SPACING, PET_HEIGHT, BASE_DISTANCE + ROW_SPACING),
		CFrame.new(X_SPACING, PET_HEIGHT, BASE_DISTANCE + ROW_SPACING),
	},
}

local MonsterController = Knit.CreateController({
	Name = "MonsterController",
	TargetCFrames = {},
	LerpSpeed = 7,
})

local function getControlledRoot(monsterModel: Model): BasePart?
	for _, descendant in ipairs(monsterModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local hasAlignPos = descendant:FindFirstChild("AlignPosition")
			local hasAlignOri = descendant:FindFirstChild("AlignOrientation")
			if hasAlignPos and hasAlignOri then
				return descendant
			end
		end
	end

	local humanoidRoot = monsterModel:FindFirstChild("HumanoidRootPart")
	if humanoidRoot and humanoidRoot:IsA("BasePart") then
		return humanoidRoot
	end

	if monsterModel.PrimaryPart then
		return monsterModel.PrimaryPart
	end

	local anyPart = monsterModel:FindFirstChildWhichIsA("BasePart", true)
	if anyPart and anyPart:IsA("BasePart") then
		return anyPart
	end

	return nil
end

function MonsterController:KnitStart()
	RunService.RenderStepped:Connect(function(dt)
		self:UpdateMonsters(dt)
	end)

	workspace.DescendantRemoving:Connect(function(descendant)
		if self.TargetCFrames[descendant] then
			self.TargetCFrames[descendant] = nil
		end
	end)
end

function MonsterController:UpdateMonsters(dt)
	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local playerMonsterFolder = workspace:FindFirstChild(player.Name .. "_Monsters")
	if not playerMonsterFolder then
		return
	end

	local equippedMonsters = {}
	for _, monsterModel in ipairs(playerMonsterFolder:GetChildren()) do
		if monsterModel:GetAttribute("IsEquipped") == true then
			table.insert(equippedMonsters, monsterModel)
		end
	end

	local monsterCount = #equippedMonsters
	if monsterCount == 0 then
		return
	end

	local timeNow = tick()
	local smoothFactor = 1 - math.exp(-self.LerpSpeed * dt)
	local currentFormation = FORMATIONS[monsterCount] or FORMATIONS[5]

	for i, monsterModel in ipairs(equippedMonsters) do
		local petRoot = getControlledRoot(monsterModel)
		if not petRoot then
			continue
		end

		local alignPos = petRoot:FindFirstChild("AlignPosition")
		local alignOri = petRoot:FindFirstChild("AlignOrientation")
		if not (alignPos and alignOri) then
			continue
		end

		local hoverOffset = math.sin(timeNow * 3 + i) * 0.3
		local offsetCFrame = currentFormation[i] or CFrame.new(0, 0, 3)

		local goalCFrame = rootPart.CFrame * offsetCFrame * CFrame.new(0, -0.5 + hoverOffset, 0)

		if not self.TargetCFrames[monsterModel] then
			self.TargetCFrames[monsterModel] = goalCFrame
		end

		self.TargetCFrames[monsterModel] = self.TargetCFrames[monsterModel]:Lerp(goalCFrame, smoothFactor)

		alignPos.Position = self.TargetCFrames[monsterModel].Position
		alignOri.CFrame = self.TargetCFrames[monsterModel]
	end
end

return MonsterController
