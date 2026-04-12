local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local SafehouseController = Knit.CreateController({
	Name = "SafehouseController",
})

local LEVEL_MOVE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LEVEL_FADE_TWEEN_INFO = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LEVEL_RISE_OFFSET = Vector3.new(0, -6, 0)
local COIN_FX_MIN_INTERVAL = 0.7
local COIN_FX_MAX_INTERVAL = 1.8
local COIN_PARTICLE_MIN_EMIT = 2
local COIN_PARTICLE_MAX_EMIT = 5
local HATCH_PARTICLE_EMIT_COUNT = 5
local UPGRADE_HOME_SOUND_TEMPLATE =
	ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds"):WaitForChild("UpgradeHome")
local EGG_HATCH_SOUND_TEMPLATE =
	ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds"):WaitForChild("EggHatch")
local HATCH_PARTICLE_TEMPLATE =
	ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VFX"):WaitForChild("HatchParticle")

local function isLevelModel(instance: Instance): boolean
	return instance:IsA("Model") and string.match(instance.Name, "^Level%d+$") ~= nil
end

local function animateLevelAppear(levelModel: Model)
	local parts = {}
	for _, descendant in ipairs(levelModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, {
				part = descendant,
				cframe = descendant.CFrame,
				transparency = descendant.Transparency,
				canCollide = descendant.CanCollide,
			})
		end
	end

	for _, partData in ipairs(parts) do
		local part = partData.part
		part.CFrame = partData.cframe + LEVEL_RISE_OFFSET
		part.Transparency = 1
		part.CanCollide = false
	end

	for _, partData in ipairs(parts) do
		local part = partData.part
		TweenService:Create(part, LEVEL_MOVE_TWEEN_INFO, {
			CFrame = partData.cframe,
		}):Play()
		TweenService:Create(part, LEVEL_FADE_TWEEN_INFO, {
			Transparency = partData.transparency,
		}):Play()
	end

	task.delay(math.max(LEVEL_MOVE_TWEEN_INFO.Time, LEVEL_FADE_TWEEN_INFO.Time) + 0.05, function()
		for _, partData in ipairs(parts) do
			if partData.part.Parent then
				partData.part.CanCollide = partData.canCollide
			end
		end
	end)
end

function SafehouseController:KnitStart()
	local DataService = Knit.GetService("DataService")
	local watchedSafehouseFolder: Folder? = nil
	local slotFxTokens = {}
	local previousSlotState = {}

	local function snapshotSlotState(data)
		local snapshot = {}
		local safehouseSlots = (data and data.SafehouseSlots) or {}

		for slotIndex, slotObj in pairs(safehouseSlots) do
			snapshot[tostring(slotIndex)] = {
				Type = slotObj.Type,
				MonsterGuid = slotObj.MonsterGuid,
			}
		end

		return snapshot
	end

	local function getSafehouseFolder(): Folder?
		if watchedSafehouseFolder and watchedSafehouseFolder.Parent then
			return watchedSafehouseFolder
		end

		local found = Workspace:FindFirstChild("Safehouse_" .. localPlayer.Name, true)
		if found and found:IsA("Folder") then
			watchedSafehouseFolder = found
			return found
		end

		return nil
	end

	local function findYellowForSlot(slotName: string): BasePart?
		local safehouseFolder = getSafehouseFolder()
		if not safehouseFolder then
			return nil
		end

		for _, levelModel in ipairs(safehouseFolder:GetChildren()) do
			if levelModel:IsA("Model") then
				local coinPlaceFolder = levelModel:FindFirstChild("CoinPlace")
				if coinPlaceFolder then
					local slotFolder = coinPlaceFolder:FindFirstChild(slotName)
					local yellow = slotFolder and slotFolder:FindFirstChild("Yellow")
					if yellow and yellow:IsA("BasePart") then
						return yellow
					end
				end
			end
		end

		return nil
	end

	local function findPhysicalSlotForName(slotName: string): BasePart?
		local safehouseFolder = getSafehouseFolder()
		if not safehouseFolder then
			return nil
		end

		for _, levelModel in ipairs(safehouseFolder:GetChildren()) do
			if levelModel:IsA("Model") and isLevelModel(levelModel) then
				local targetSlot = levelModel:FindFirstChild(slotName, true)
				if targetSlot then
					local emissivePart = targetSlot:FindFirstChild("Emissive")
					if emissivePart and emissivePart:IsA("BasePart") then
						return emissivePart
					end
				end
			end
		end

		return nil
	end

	local function playYellowFx(yellowPart: BasePart)
		local coinSound = yellowPart:FindFirstChild("CoinSound", true)
		if coinSound and coinSound:IsA("Sound") then
			coinSound:Play()
		end

		local coinParticle = yellowPart:FindFirstChild("CoinParticle", true)
		if coinParticle and coinParticle:IsA("ParticleEmitter") then
			coinParticle:Emit(math.random(COIN_PARTICLE_MIN_EMIT, COIN_PARTICLE_MAX_EMIT))
		end
	end

	local function startSlotFx(slotName: string)
		if slotFxTokens[slotName] then
			return
		end

		local token = tostring(os.clock()) .. "_" .. slotName
		slotFxTokens[slotName] = token

		task.spawn(function()
			while slotFxTokens[slotName] == token do
				local yellowPart = findYellowForSlot(slotName)
				if yellowPart then
					playYellowFx(yellowPart)
				end

				task.wait(math.random() * (COIN_FX_MAX_INTERVAL - COIN_FX_MIN_INTERVAL) + COIN_FX_MIN_INTERVAL)
			end
		end)
	end

	local function stopSlotFx(slotName: string)
		slotFxTokens[slotName] = nil
	end

	local function refreshCoinFxFromData(data)
		local safehouseSlots = (data and data.SafehouseSlots) or {}
		local monsters = (data and data.Monsters) or {}
		local shouldRun = {}

		for slotIndex, slotObj in pairs(safehouseSlots) do
			if slotObj.Type == "Monster" and slotObj.MonsterGuid then
				local monsterData = monsters[slotObj.MonsterGuid]
				if monsterData and monsterData.Status == "Mining" then
					local slotName = "Slot" .. tostring(slotIndex)
					shouldRun[slotName] = true
				end
			end
		end

		for slotName, _ in pairs(shouldRun) do
			startSlotFx(slotName)
		end

		for slotName, _ in pairs(slotFxTokens) do
			if not shouldRun[slotName] then
				stopSlotFx(slotName)
			end
		end
	end

	local function playUpgradeHomeSound(safehouseFolder: Folder)
		local level1 = safehouseFolder:FindFirstChild("Level1")
		if not level1 or not level1:IsA("Model") then
			return
		end

		local upgradePart = level1:FindFirstChild("Upgrade", true)
		if not upgradePart then
			return
		end

		local meshPart = upgradePart:FindFirstChild("SafehouseUpgradeMesh", true)
		if not meshPart or not meshPart:IsA("BasePart") then
			return
		end

		local sound = meshPart:FindFirstChild("UpgradeHome_Local")
		if not sound then
			sound = UPGRADE_HOME_SOUND_TEMPLATE:Clone()
			sound.Name = "UpgradeHome_Local"
			sound.Parent = meshPart
		end

		if sound:IsA("Sound") then
			sound.TimePosition = 0
			sound:Play()
		end
	end

	local function playHatchFxOnSlot(slotName: string)
		local physicalSlot = findPhysicalSlotForName(slotName)
		if not physicalSlot then
			return
		end

		local hatchSound = physicalSlot:FindFirstChild("EggHatch_Local")
		if not hatchSound then
			hatchSound = EGG_HATCH_SOUND_TEMPLATE:Clone()
			hatchSound.Name = "EggHatch_Local"
			hatchSound.Parent = physicalSlot
		end

		if hatchSound:IsA("Sound") then
			hatchSound.TimePosition = 0
			hatchSound:Play()
		end

		local hatchParticle = physicalSlot:FindFirstChild("HatchParticle_Local")
		if not hatchParticle then
			hatchParticle = HATCH_PARTICLE_TEMPLATE:Clone()
			hatchParticle.Name = "HatchParticle_Local"
			hatchParticle.Parent = physicalSlot
		end

		if hatchParticle:IsA("ParticleEmitter") then
			-- Force one-shot hatch effect even if template uses continuous emission settings.
			hatchParticle.Enabled = false
			hatchParticle.Rate = 0
			hatchParticle:Clear()
			hatchParticle:Emit(HATCH_PARTICLE_EMIT_COUNT)
		end
	end

	local function handleHatchTransitions(newData)
		local newState = snapshotSlotState(newData)

		for slotIndex, nextSlot in pairs(newState) do
			local prevSlot = previousSlotState[slotIndex]
			if prevSlot and prevSlot.Type == "Egg" and nextSlot.Type == "Monster" then
				playHatchFxOnSlot("Slot" .. slotIndex)
			end
		end

		previousSlotState = newState
	end

	local function setupSafehouseFolderWatcher(safehouseFolder: Folder)
		if watchedSafehouseFolder == safehouseFolder then
			return
		end

		watchedSafehouseFolder = safehouseFolder

		local existingLevels = {}
		for _, child in ipairs(safehouseFolder:GetChildren()) do
			if isLevelModel(child) then
				existingLevels[child] = true
			end
		end

		safehouseFolder.ChildAdded:Connect(function(child)
			if not isLevelModel(child) then
				return
			end

			if existingLevels[child] then
				return
			end

			existingLevels[child] = true
			playUpgradeHomeSound(safehouseFolder)
			animateLevelAppear(child)
		end)
	end

	local safehouseFolderName = "Safehouse_" .. localPlayer.Name
	local existingSafehouse = Workspace:FindFirstChild(safehouseFolderName, true)
	if existingSafehouse and existingSafehouse:IsA("Folder") then
		setupSafehouseFolderWatcher(existingSafehouse)
	end

	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Folder") and descendant.Name == safehouseFolderName then
			setupSafehouseFolderWatcher(descendant)
		end
	end)

	local function handlePrompt(prompt)
		if prompt:IsA("ProximityPrompt") then
			local owner = prompt:GetAttribute("OwnerName")
			if owner and owner ~= localPlayer.Name then
				prompt.Enabled = false
			end
		end
	end

	local function handlePrivateButton(button)
		local owner = button:GetAttribute("OwnerName")

		if owner and owner ~= localPlayer.Name then
			button:Destroy()
		end
	end

	for _, prompt in ipairs(CollectionService:GetTagged("SafehousePrompt")) do
		handlePrompt(prompt)
	end

	CollectionService:GetInstanceAddedSignal("SafehousePrompt"):Connect(handlePrompt)

	for _, btn in ipairs(CollectionService:GetTagged("PrivateStatusButton")) do
		handlePrivateButton(btn)
	end

	CollectionService:GetInstanceAddedSignal("PrivateStatusButton"):Connect(function(btn)
		handlePrivateButton(btn)
	end)

	DataService:GetData()
		:andThen(function(data)
			previousSlotState = snapshotSlotState(data)
			refreshCoinFxFromData(data)
		end)
		:catch(warn)

	DataService.DataChanged:Connect(function(newData)
		handleHatchTransitions(newData)
		refreshCoinFxFromData(newData)
	end)
end

return SafehouseController
