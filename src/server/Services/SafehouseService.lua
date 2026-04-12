local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")
local BadgeService = game:GetService("BadgeService")

local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local SafehouseConstants = require(game.ReplicatedStorage.Shared.Constants.SafehouseConstants)
local EggConstants = require(game.ReplicatedStorage.Shared.Constants.EggConstants)
local MonsterConstants = require(game.ReplicatedStorage.Shared.Constants.MonsterConstants)

local UpgradeAssets = ServerStorage.Assets.SafehouseUpgrades
local EggAssets: Folder = ServerStorage:WaitForChild("Assets"):WaitForChild("Eggs")
local MonsterAssets: Folder = ServerStorage:WaitForChild("Assets"):WaitForChild("Monsters")
local EggTitleGuiTemplate = ServerStorage:WaitForChild("Assets"):WaitForChild("EggTitleGUI")
local EggChanceGuiTemplate = ServerStorage:WaitForChild("Assets"):WaitForChild("EggChanceGUI")
local MonsterTitleGuiTemplate = ServerStorage:WaitForChild("Assets"):WaitForChild("MonsterTitleGUI")
local SAFEHOUSE_LEVEL2_BADGE_ID = 889148243617553

local function tryAwardSafehouseLevel2Badge(player: Player)
	local hasBadge = false
	local hasBadgeOk, hasBadgeResult = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, SAFEHOUSE_LEVEL2_BADGE_ID)
	end)

	if hasBadgeOk then
		hasBadge = hasBadgeResult == true
	end

	if hasBadge then
		return
	end

	pcall(function()
		BadgeService:AwardBadge(player.UserId, SAFEHOUSE_LEVEL2_BADGE_ID)
	end)
end

local function attachEggTitleGui(eggModel: Model, eggId: string)
	local eggRoot = eggModel.PrimaryPart or eggModel:FindFirstChildWhichIsA("BasePart", true)
	if not eggRoot then
		return
	end

	local eggConfig = EggConstants.Eggs[eggId]
	local displayName = eggConfig and eggConfig.Name or eggId
	local uiLevel = eggConfig and eggConfig.UILevel or ""
	local uiRarity = eggConfig and eggConfig.UIRarity or ""
	local finalName = displayName
	if uiLevel ~= "" then
		finalName ..= " " .. uiLevel
	end

	local titleGui = EggTitleGuiTemplate:Clone()
	local mainFrame = titleGui:FindFirstChild("MainFrame", true)
	local eggNameText = mainFrame and mainFrame:FindFirstChild("EggNameText", true)
	local eggRarityText = mainFrame and mainFrame:FindFirstChild("EggRarityText", true)

	if eggNameText and eggNameText:IsA("TextLabel") then
		eggNameText.Text = finalName
	end

	if eggRarityText and eggRarityText:IsA("TextLabel") then
		eggRarityText.Text = uiRarity
	end

	titleGui.Parent = eggRoot
end

local function attachEggChanceGui(eggModel: Model, eggId: string)
	local eggRoot = eggModel.PrimaryPart or eggModel:FindFirstChildWhichIsA("BasePart", true)
	if not eggRoot then
		return
	end

	local eggConfig = EggConstants.Eggs[eggId]
	if not eggConfig or type(eggConfig.HatchRates) ~= "table" then
		return
	end

	local chanceGui = EggChanceGuiTemplate:Clone()
	local mainFrame = chanceGui:FindFirstChild("MainFrame", true)
	local scrollingFrame = mainFrame and mainFrame:FindFirstChild("ScrollingFrame", true)
	local template = scrollingFrame and scrollingFrame:FindFirstChild("MonsterCardTemplate")
	if not mainFrame or not scrollingFrame or not template or not template:IsA("GuiObject") then
		chanceGui:Destroy()
		return
	end

	template.Visible = false

	local entries = {}
	for monsterId, chance in pairs(eggConfig.HatchRates) do
		table.insert(entries, { MonsterId = monsterId, Chance = chance })
	end

	table.sort(entries, function(a, b)
		if a.Chance == b.Chance then
			return a.MonsterId < b.MonsterId
		end
		return a.Chance > b.Chance
	end)

	for _, entry in ipairs(entries) do
		local card = template:Clone()
		card.Name = "Card_" .. entry.MonsterId
		card.Visible = true

		local monsterData = MonsterConstants.Data[entry.MonsterId]
		local image = card:FindFirstChild("MonsterImage", true)
		if image and image:IsA("ImageLabel") then
			image.Image = (monsterData and monsterData.ImageId) or ""
		end

		local chanceText = card:FindFirstChild("ChanceText", true)
		if chanceText and chanceText:IsA("TextLabel") then
			chanceText.Text = tostring(entry.Chance) .. "%"
		end

		card.Parent = scrollingFrame
	end

	chanceGui.Parent = eggRoot
end

local function attachMonsterTitleGui(monsterModel: Model, monsterId: string)
	local root = monsterModel.PrimaryPart
	if not root then
		return
	end

	local monsterData = MonsterConstants.Data[monsterId]
	if not monsterData then
		return
	end

	local titleGui = MonsterTitleGuiTemplate:Clone()
	local mainFrame = titleGui:FindFirstChild("MainFrame", true)
	local nameText = mainFrame and mainFrame:FindFirstChild("MonsterNameText", true)
	local powerText = mainFrame and mainFrame:FindFirstChild("MonsterPowerText", true)

	if nameText and nameText:IsA("TextLabel") then
		nameText.Text = monsterData.Name or monsterId
	end

	if powerText and powerText:IsA("TextLabel") then
		powerText.Text = tostring(monsterData.BaseMultiplier or 0) .. "x Power"
	end

	titleGui.Parent = root
end

local SafehouseService = Knit.CreateService({
	Name = "SafehouseService",
	Client = {},
})

function SafehouseService:KnitInit()
	local safehouseFolder = workspace:WaitForChild("Safehouses")

	self.AllocatedPlots = {}
	self.ActiveSafehouses = {}
	self.SafehouseReady = Signal.new()
	self.ActiveAnimations = {}

	for _, plot in pairs(safehouseFolder:GetChildren()) do
		self.AllocatedPlots[plot] = false
	end
end

function SafehouseService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.EggService = Knit.GetService("EggService")
	self.MonsterService = Knit.GetService("MonsterService")

	Players.PlayerAdded:Connect(function(player)
		-- if player.UserId ~= 703574111 then
		-- 	return
		-- end
		self:AssignPlot(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:ReleasePlot(player)
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local ownerName = prompt:GetAttribute("OwnerName")
		local slotIndex = prompt:GetAttribute("SlotIndex")
		-- local isEggReady = prompt:GetAttribute("ReadyState")

		if ownerName and slotIndex then
			if player.Name ~= ownerName then
				return
			end

			self:ProcessHatch(player, slotIndex)
		end
	end)
end

function SafehouseService:AssignPlot(player)
	for plot, owner in pairs(self.AllocatedPlots) do
		if owner == false then
			self.AllocatedPlots[plot] = player

			local character = player.Character or player.CharacterAdded:Wait()
			local spawnPoint = plot:FindFirstChild("SpawnPoint")
			if spawnPoint then
				character:PivotTo(spawnPoint.CFrame + Vector3.new(0, 3, 0))
			end

			self:SpawnInitialSafehouse(player, plot)

			return
		end
	end
end

function SafehouseService:ReleasePlot(player)
	for plot, owner in pairs(self.AllocatedPlots) do
		if owner == player then
			self.AllocatedPlots[plot] = false

			if self.ActiveSafehouses[player] then
				self.ActiveSafehouses[player]:Destroy()
				self.ActiveSafehouses[player] = nil
			end

			break
		end
	end
end

function SafehouseService:SpawnInitialSafehouse(player, assignedPlot)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	print(data)
	local currentLevel = data.SafehouseLevel or 1

	local playerSafehouseFolder = Instance.new("Folder")
	playerSafehouseFolder.Name = "Safehouse_" .. player.Name
	playerSafehouseFolder.Parent = assignedPlot

	self.ActiveSafehouses[player] = playerSafehouseFolder

	for i = 1, currentLevel do
		local levelName = "Level" .. tostring(i)

		local assetModel = UpgradeAssets:FindFirstChild(levelName)
		local targetBase = assignedPlot:FindFirstChild(levelName .. "Base")

		if assetModel and targetBase then
			local newModel = assetModel:Clone()

			newModel:PivotTo(targetBase.CFrame)

			newModel.Parent = playerSafehouseFolder
		else
			warn("Missing asset or target for safehouse level: " .. levelName)
		end
	end

	self.SafehouseReady:Fire(player, playerSafehouseFolder)

	self:InitUpgradeSafehouse(player)
	self:RefreshSafehousePhysicalSlots(player)
end

function SafehouseService:InitUpgradeSafehouse(player)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	local playerSafehouse = self.ActiveSafehouses[player]
	if not playerSafehouse then
		return
	end

	local upgradeSafehousePrompt = playerSafehouse.Level1.Upgrade.SafehouseUpgradeMesh.SafehouseUpgradePrompt
	if not upgradeSafehousePrompt then
		return
	end

	local currentLevel = data.SafehouseLevel or 1
	local nextLevel = currentLevel + 1
	local nextLevelConfig = SafehouseConstants.Levels[nextLevel]

	CollectionService:AddTag(upgradeSafehousePrompt, "SafehousePrompt")
	upgradeSafehousePrompt:SetAttribute("OwnerName", player.Name)
	upgradeSafehousePrompt.ObjectText = "Safehouse"

	if nextLevelConfig then
		upgradeSafehousePrompt.ActionText = "Upgrade ($" .. tostring(nextLevelConfig.UpgradeCost) .. ")"
		upgradeSafehousePrompt.Enabled = true
	else
		upgradeSafehousePrompt.ActionText = "Max Level"
		upgradeSafehousePrompt.Enabled = false
	end

	if upgradeSafehousePrompt:GetAttribute("UpgradeBound") then
		return
	end

	upgradeSafehousePrompt:SetAttribute("UpgradeBound", true)

	upgradeSafehousePrompt.Triggered:Connect(function(playerTrigger)
		if playerTrigger ~= player then
			return
		end

		local freshData = self.DataService:GetData(playerTrigger)
		if not freshData then
			return
		end

		local freshCurrentLevel = freshData.SafehouseLevel or 1
		local freshNextLevel = freshCurrentLevel + 1
		local freshNextLevelConfig = SafehouseConstants.Levels[freshNextLevel]
		if not freshNextLevelConfig then
			self:InitUpgradeSafehouse(playerTrigger)
			return
		end

		if (freshData.Money or 0) < freshNextLevelConfig.UpgradeCost then
			return
		end

		local addedLevel = self:AddLevelToSafehouse(playerTrigger)
		if not addedLevel then
			return
		end

		freshData.Money -= freshNextLevelConfig.UpgradeCost
		freshData.SafehouseLevel = freshNextLevel

		if freshNextLevel == 2 then
			tryAwardSafehouseLevel2Badge(playerTrigger)
		end

		if self.DataService.NotifyDataChanged then
			self.DataService:NotifyDataChanged(playerTrigger)
		end

		self:InitUpgradeSafehouse(playerTrigger)
	end)
end

function SafehouseService:AddLevelToSafehouse(player)
	local data = self.DataService:GetData(player)
	if not data then
		return false
	end

	local playerSafehouse = self.ActiveSafehouses[player]
	if not playerSafehouse then
		return false
	end

	local currentLevel = data.SafehouseLevel or 1
	local nextLevel = currentLevel + 1
	local levelName = "Level" .. tostring(nextLevel)

	local assignedPlot = nil
	for plot, owner in pairs(self.AllocatedPlots) do
		if owner == player then
			assignedPlot = plot
			break
		end
	end

	if not assignedPlot then
		return false
	end

	local assetModel = UpgradeAssets:FindFirstChild(levelName)
	local targetBase = assignedPlot:FindFirstChild(levelName .. "Base")
	if not assetModel or not targetBase then
		warn("Missing asset or target for safehouse level: " .. levelName)
		return false
	end

	local newModel = assetModel:Clone()
	newModel:PivotTo(targetBase.CFrame)
	newModel.Parent = playerSafehouse

	return true
end

function SafehouseService:GiveEggToSafehouse(player, eggId, slot)
	local data = self.DataService:GetData(player)
	if not data then
		return false
	end

	local level = data.SafehouseLevel or 1
	local maxSlots = SafehouseConstants.Levels[level].MaxSlots

	local foundSlot = nil

	if not slot then
		for i = 1, maxSlots do
			if data.SafehouseSlots[tostring(i)] == nil then
				foundSlot = tostring(i)
				break
			end
		end
	else
		foundSlot = tostring(slot)
	end

	if not foundSlot then
		-- safehouse is full
		return false
	end

	data.SafehouseSlots[foundSlot] = { Type = "Egg", Id = eggId }

	-- If use time!!!! (later)
	-- if isReady == true then
	-- 	data.SafehouseSlots[foundSlot] = { Type = "Egg", Id = eggId, isReady = true, readyAt = nil }
	-- else
	-- 	data.SafehouseSlots[foundSlot] =
	-- 		{ Type = "Egg", Id = eggId, isReady = false, readyAt = EggConstants[eggId].HatchTime + os.time() }
	-- end

	return true
end

function SafehouseService:GetPhysicalSlot(player, slotIndex)
	local targetPlot = self.ActiveSafehouses[player]
	if not targetPlot then
		return nil
	end

	local slotName = "Slot" .. tostring(slotIndex)

	for _, levelModel in ipairs(targetPlot:GetChildren()) do
		if levelModel:IsA("Model") and string.find(levelModel.Name, "Level") then
			local targetSlot = levelModel:FindFirstChild(slotName, true)

			if targetSlot then
				local emissivePart = targetSlot:FindFirstChild("Emissive")
				if emissivePart then
					return emissivePart
				else
					return nil
				end
			end
		end
	end

	return nil
end

function SafehouseService:RefreshSafehousePhysicalSlots(player)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	for slot, slotObj in pairs(data.SafehouseSlots) do
		local physicalSlot = self:GetPhysicalSlot(player, slot)

		if slotObj.Type == "Egg" then
			local eggAsset = EggAssets:FindFirstChild(slotObj.Id)
			if eggAsset then
				local newEgg = eggAsset:Clone()
				newEgg.Name = slotObj.Id

				newEgg:PivotTo(physicalSlot.CFrame * CFrame.new(0, 3.5, 0))
				newEgg.Parent = physicalSlot
				attachEggTitleGui(newEgg, slotObj.Id)
				attachEggChanceGui(newEgg, slotObj.Id)

				local hatchPrompt = Instance.new("ProximityPrompt")
				hatchPrompt.Name = "HatchPrompt"
				hatchPrompt.Style = Enum.ProximityPromptStyle.Custom

				hatchPrompt.ActionText = "Hatch"
				hatchPrompt.ObjectText = "Slot " .. tostring(slot)
				hatchPrompt.RequiresLineOfSight = false
				hatchPrompt.MaxActivationDistance = 8
				hatchPrompt.HoldDuration = 2

				CollectionService:AddTag(hatchPrompt, "SafehousePrompt")
				hatchPrompt:SetAttribute("OwnerName", player.Name)
				hatchPrompt:SetAttribute("SlotIndex", slot)
				hatchPrompt.Parent = physicalSlot
			end
		elseif slotObj.Type == "Monster" then
			print("semua slot1 ", data.SafehouseSlots)

			self:ProcessMonsterSlot(player, physicalSlot, data, slotObj.MonsterGuid, slot)
		end
	end
end

function SafehouseService:ProcessHatch(player, slotIndex)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	local monsterHatched, monsterGuid = self.EggService:HatchEgg(player, slotIndex)
	if not monsterHatched then
		return
	end

	data.SafehouseSlots[slotIndex] = { Type = "Monster", Id = monsterHatched, MonsterGuid = monsterGuid }
	self.DataService:NotifyDataChanged(player)

	local physicalSlot = self:GetPhysicalSlot(player, slotIndex)
	print(physicalSlot)
	if not physicalSlot then
		return
	end

	physicalSlot:ClearAllChildren()

	self:ProcessMonsterSlot(player, physicalSlot, data, monsterGuid, slotIndex)
end

function SafehouseService:ProcessMonsterSlot(player, physicalSlot, data, monsterGuid, slotIndex)
	if not data.Monsters[monsterGuid] then
		print("masuk sini guys (gagal deh)")
		return
	end

	local monsterAsset = MonsterAssets:FindFirstChild(data.Monsters[monsterGuid].monsterId)
	if monsterAsset then
		local newMonster = monsterAsset:Clone()
		newMonster.Name = data.Monsters[monsterGuid].monsterId

		for _, descendant in ipairs(newMonster:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
			end
		end

		local targetPosition = (physicalSlot.CFrame * CFrame.new(0, 3.5, 0)).Position
		local facingPart = physicalSlot.Parent and physicalSlot.Parent:FindFirstChild("Facing")
		if facingPart and facingPart:IsA("BasePart") then
			local lookFlat =
				Vector3.new(facingPart.Position.X - targetPosition.X, 0, facingPart.Position.Z - targetPosition.Z)

			if lookFlat.Magnitude > 0.001 then
				newMonster:PivotTo(CFrame.lookAt(targetPosition, targetPosition + lookFlat.Unit))
			else
				newMonster:PivotTo(CFrame.new(targetPosition))
			end
		else
			newMonster:PivotTo(physicalSlot.CFrame * CFrame.new(0, 3.5, 0))
		end

		newMonster.Parent = physicalSlot
		attachMonsterTitleGui(newMonster, newMonster.Name)

		local promptAsset = game:GetService("ServerStorage").Assets:FindFirstChild("SlotPrompt")
		if promptAsset then
			local prompt: ProximityPrompt = promptAsset:Clone()
			prompt.Name = "StatusPrompt"

			prompt:SetAttribute("OwnerName", player.Name)
			CollectionService:AddTag(prompt, "SafehousePrompt")

			local promptStatus = "Mining"
			local monsterStatus = "Breaking"

			prompt.ActionText = "Set " .. promptStatus
			prompt.ObjectText = "Monster"
			data.Monsters[monsterGuid].Status = monsterStatus

			self.MonsterService:SpawnMonster(player, monsterGuid)

			prompt.Parent = physicalSlot

			prompt.Triggered:Connect(function(playerTrigger)
				if playerTrigger.Name == player.Name then
					if promptStatus == "Mining" then
						promptStatus = "Breaking"
						monsterStatus = "Mining"

						local coinSlot, coinSource = self:GetCoinPlaceName(playerTrigger, physicalSlot.Parent.Name)
						if coinSlot then
							self.MonsterService:UnequipMonster(player, monsterGuid, coinSlot, coinSource)
						end
					else
						promptStatus = "Mining"
						monsterStatus = "Breaking"

						self.MonsterService:EquipMonster(player, monsterGuid)
					end

					prompt.ActionText = "Set " .. promptStatus

					data.Monsters[monsterGuid].Status = monsterStatus
				else
					warn(playerTrigger.Name .. " mencoba mengakses monster milik " .. player.Name)
				end
			end)

			local sellPart = ServerStorage.Assets:FindFirstChild("SellPromptPart"):Clone()
			sellPart.Parent = physicalSlot
			sellPart:PivotTo(physicalSlot.CFrame * CFrame.new(0, 0, 0))

			local sellPrompt = sellPart:FindFirstChild("SellPrompt")

			if sellPrompt then
				sellPrompt:SetAttribute("OwnerName", player.Name)
				CollectionService:AddTag(sellPrompt, "SafehousePrompt")

				sellPrompt.Triggered:Connect(function(playerTrigger)
					if playerTrigger.Name == player.Name then
						local hasSold = self.MonsterService:ProcessSell(playerTrigger, monsterGuid)
						if hasSold then
							data.SafehouseSlots[tostring(slotIndex)] = nil

							physicalSlot:ClearAllChildren()

							local isPlayerHoldingEgg = self.EggService:IsPlayerHoldingEgg(playerTrigger)
							if isPlayerHoldingEgg then
								self:CreateDropPrompt(playerTrigger)
							end

							self:RefreshSafehousePhysicalSlots(playerTrigger)
						end
					end
				end)
			end
		end
	end
end

function SafehouseService:GetCoinPlaceName(player, slotName)
	local data = self.DataService:GetData(player)
	if not data then
		return nil
	end

	local playerSafehouse = self.ActiveSafehouses[player]
	if not playerSafehouse then
		return nil
	end

	for _, levelModel in ipairs(playerSafehouse:GetChildren()) do
		if levelModel:IsA("Model") then
			local coinPlaceFolder = levelModel:FindFirstChild("CoinPlace")

			if coinPlaceFolder then
				local targetSlot = coinPlaceFolder:FindFirstChild(slotName)
				if targetSlot and targetSlot:FindFirstChild("Yellow") then
					return targetSlot.Yellow, playerSafehouse.Level1.CoinSource
				end
			end
		end
	end

	return nil
end

function SafehouseService:CreateDropPrompt(player)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	local slotProgression = {
		[1] = 2,
		[2] = 4,
		[3] = 4,
		[4] = 5,
		[5] = 6,
		[6] = 7,
		[7] = 8,
	}

	local currentLevel = data.SafehouseLevel
	local maxSlots = slotProgression[currentLevel]

	print("current level adalah ", currentLevel)
	print("dan punya jumlah slot ", maxSlots)

	local activePrompts = {}

	for i = 1, maxSlots do
		local slotKey = tostring(i)
		if not data.SafehouseSlots[slotKey] then
			local physicalSlot = self:GetPhysicalSlot(player, slotKey)
			if not physicalSlot then
				continue
			end

			local prompt = Instance.new("ProximityPrompt")
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt.Name = "DropPrompt"
			prompt.ActionText = "Drop Egg"
			prompt.ObjectText = "Slot " .. tostring(slotKey)
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 6
			prompt.HoldDuration = 1

			CollectionService:AddTag(prompt, "SafehousePrompt")

			prompt:SetAttribute("OwnerName", player.Name)
			prompt:SetAttribute("SlotIndex", i)

			prompt.Parent = physicalSlot

			table.insert(activePrompts, prompt)

			prompt.Triggered:Connect(function(playerTrigger)
				if playerTrigger.Name == player.Name then
					local hasDropped = self.EggService:ProcessDropoff(playerTrigger, i)
					if hasDropped then
						print(playerTrigger.Name .. " successfully dropped an egg at their base!")

						for _, p in ipairs(activePrompts) do
							if p and p.Parent then
								p:Destroy()
							end
						end

						table.clear(activePrompts)

						self.ActiveAnimations[playerTrigger]:Stop()
						self.ActiveAnimations[playerTrigger] = nil
					end
				else
					return
				end
			end)
		end
	end
end

function SafehouseService:GetPlayerSafehouse(player)
	return self.ActiveSafehouses[player]
end

function SafehouseService:PlayerHoldingEggAnimation(player)
	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local holdAnimation = Instance.new("Animation")
			holdAnimation.AnimationId = "rbxassetid://80824979073835"

			local holdTrack = animator:LoadAnimation(holdAnimation)
			self.ActiveAnimations[player] = holdTrack
			holdTrack:Play()
		end
	end
end

return SafehouseService
