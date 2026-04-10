local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")

local Players = game:GetService("Players")
local TouchInputService = game:GetService("TouchInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local SafehouseConstants = require(game.ReplicatedStorage.Shared.Constants.SafehouseConstants)

local UpgradeAssets = ServerStorage.Assets.SafehouseUpgrades

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
		if player.UserId ~= 703574111 then
			return
		end
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
				warn(player.Name .. " mencoba mengakses prompt milik " .. ownerName)
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
			self:SetupBaseTouch(player, plot)

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

function SafehouseService:SetupBaseTouch(player, plot)
	local basePart = plot:FindFirstChild("Base")
	if not basePart then
		return
	end

	local isDebouncing = false

	basePart.Touched:Connect(function(hit)
		if isDebouncing then
			return
		end

		-- local hitCharacter = hit.Parent
		-- local hitPlayer = game:GetService("Players"):GetPlayerFromCharacter(hitCharacter)

		-- if hitPlayer and hitPlayer == player then
		-- 	isDebouncing = true

		-- 	local hasDropped = self.EggService:ProcessDropoff(hitPlayer)
		-- 	if hasDropped then
		-- 		print(hitPlayer.Name .. " successfully dropped an egg at their base!")
		-- 	end

		-- 	task.wait(1)
		-- 	isDebouncing = false
		-- end
	end)
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
	self:RefreshSafehousePhysicalSlots(player)
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
	local physicalSlot = targetPlot:FindFirstChild(slotName, true)

	return physicalSlot
end

function SafehouseService:RefreshSafehousePhysicalSlots(player)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	for slot, slotObj in pairs(data.SafehouseSlots) do
		local physicalSlot = self:GetPhysicalSlot(player, slot)

		if slotObj.Type == "Egg" then
			local eggAsset: Model = game:GetService("ServerStorage").Eggs:FindFirstChild("BlueEgg")
			if eggAsset then
				local newEgg = eggAsset:Clone()
				newEgg.Name = "PhysicalEgg"

				newEgg:PivotTo(physicalSlot.CFrame * CFrame.new(0, 3.5, 0))
				newEgg.Parent = physicalSlot

				local hatchPrompt = Instance.new("ProximityPrompt")
				hatchPrompt.Name = "HatchPrompt"
				hatchPrompt.Style = Enum.ProximityPromptStyle.Custom

				hatchPrompt.ActionText = "Hatch"
				hatchPrompt.ObjectText = "Slot " .. tostring(slot)
				hatchPrompt.RequiresLineOfSight = false
				hatchPrompt.MaxActivationDistance = 6
				hatchPrompt.HoldDuration = 1

				CollectionService:AddTag(hatchPrompt, "SafehousePrompt")
				hatchPrompt:SetAttribute("OwnerName", player.Name)
				hatchPrompt:SetAttribute("SlotIndex", slot)
				hatchPrompt.Parent = physicalSlot
			end
		elseif slotObj.Type == "Monster" then
			self:ProcessMonsterSlot(player, physicalSlot, data, slotObj.MonsterGuid)
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

	local physicalSlot = self:GetPhysicalSlot(player, slotIndex)
	if not physicalSlot then
		return
	end

	physicalSlot:ClearAllChildren()

	self:ProcessMonsterSlot(player, physicalSlot, data, monsterGuid)
end

function SafehouseService:ProcessMonsterSlot(player, physicalSlot, data, monsterGuid)
	local monsterAsset = game:GetService("ServerStorage").Monsters:FindFirstChild("Cat")
	if monsterAsset then
		local newMonster = monsterAsset:Clone()
		newMonster.Name = "PhysicalMonster"
		newMonster:PivotTo(physicalSlot.CFrame * CFrame.new(0, 3.5, 0))
		newMonster.Parent = physicalSlot

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

						local coinSlot, coinSource = self:GetCoinPlaceName(playerTrigger, physicalSlot.Name)
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
		end
	end
end

function SafehouseService:GetCoinPlaceName(player, slotName)
	local data = self.DataService:GetData(player)
	if not data then
		return nil
	end

	local playerSafehouse = self.ActiveSafehouses[player]
	for _, coinPlace in pairs(playerSafehouse:GetDescendants()) do
		if coinPlace.Name == slotName and coinPlace:IsA("Model") then
			return coinPlace.Yellow, playerSafehouse.Level1.CoinSource
		end
	end

	return nil
end

function SafehouseService:CreateDropPrompt(player)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	local maxSlots = (data.SafehouseLevel or 1) * 4

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
