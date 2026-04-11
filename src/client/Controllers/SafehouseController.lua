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
	local watchedSafehouseFolder: Folder? = nil

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
end

return SafehouseController
