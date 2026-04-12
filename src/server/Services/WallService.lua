-- Knit Packages
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local EggAssets: Folder = ServerStorage:WaitForChild("Assets"):WaitForChild("Eggs")
local EggTitleGuiTemplate = ServerStorage:WaitForChild("Assets"):WaitForChild("EggTitleGUI")

local Zone = require(ReplicatedStorage.Packages.zoneplus)
local MonsterConstants = require(ReplicatedStorage.Shared.Constants.MonsterConstants)
local EggConstants = require(ReplicatedStorage.Shared.Constants.EggConstants)

local WallConstants = require(ReplicatedStorage.Shared.Constants.WallConstants)

local WallService = Knit.CreateService({
	Name = "WallService",
	Client = {
		WallDestroyed = Knit.CreateSignal(),
		WallDamaged = Knit.CreateSignal(),
		WallReset = Knit.CreateSignal(),
	},
})

local function getMonsterControlRoot(monsterModel: Model): BasePart?
	for _, descendant in ipairs(monsterModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local hasAlignPos = descendant:FindFirstChild("AlignPosition")
			local hasAlignOri = descendant:FindFirstChild("AlignOrientation")
			if hasAlignPos and hasAlignOri then
				return descendant
			end
		end
	end

	if monsterModel.PrimaryPart then
		return monsterModel.PrimaryPart
	end

	local humanoidRoot = monsterModel:FindFirstChild("HumanoidRootPart")
	if humanoidRoot and humanoidRoot:IsA("BasePart") then
		return humanoidRoot
	end

	local anyPart = monsterModel:FindFirstChildWhichIsA("BasePart", true)
	if anyPart and anyPart:IsA("BasePart") then
		return anyPart
	end

	return nil
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

function WallService:KnitInit()
	self.ActiveBreakers = {}
	self.PlayerActiveDamage = {} -- { [player] = 150 }
	self.AreaZones = {} -- { ["Area1"] = Zone (reference) }
	self.ActiveEggs = {}
	self.ActiveAnimations = {} -- [monsterGuid] = { Thread = ..., Tween = ... }
	self.InBreakings = {} -- { [player] = true }
end

function WallService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.SafehouseService = Knit.GetService("SafehouseService")
	self.MonsterService = Knit.GetService("MonsterService")

	self:SetupZones()
	self:StartDamageLoop()
	self:InitResetArea()
	self:InitEggSpawnZones()
end

function WallService:SetupZones()
	local breakableFolder = workspace:WaitForChild("BreakableWalls")

	for _, wallArea in ipairs(breakableFolder:GetChildren()) do
		local zonePart = wallArea:FindFirstChild("Zone")
		local wallPart = wallArea:FindFirstChild("Wall")

		local wallId = wallArea.Name
		local config = WallConstants.Data[wallId]

		if zonePart and wallPart and config then
			local zone = Zone.new(zonePart)

			zone.playerEntered:Connect(function(player)
				print("masuk zone ", player.Name)
				self.InBreakings[player] = true
				self.ActiveBreakers[player] = wallId
				self:RecalculatePlayerDamage(player)
				self:SetMonsterBreakingVisual(player, wallPart, wallId)
			end)

			zone.playerExited:Connect(function(player)
				self:SetEquipMonster(player)

				if self.ActiveBreakers[player] == wallId then
					self.ActiveBreakers[player] = nil
				end
			end)
		end
	end
end

function WallService:SetMonsterBreakingVisual(player, wallPart: Part, wallId)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end
	local activeMonsters = self.MonsterService:GetActiveMonsters(player)

	print("WALL PROGRESS DATA", data.WallProgress)
	if not data.WallProgress[wallId] then
		local config = WallConstants.Data[wallId]
		data.WallProgress[wallId] = {
			HP = config.MaxHP,
			IsDestroyed = false,
		}
	end

	print(wallId)
	print(data.WallProgress)
	local wallData = data.WallProgress[wallId]

	if wallData.IsDestroyed then
		return
	end

	local rng = Random.new()
	local IDLE_BACK_OFFSET = 8
	local ATTACK_BACK_OFFSET = 2
	local SPREAD_X = 8

	local attackInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	local retreatInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	for monsterGuid, monsterPhysic in pairs(activeMonsters) do
		if data.Monsters[monsterGuid].Status == "Breaking" then
			local petRoot = getMonsterControlRoot(monsterPhysic)

			if petRoot then
				local alignPos = petRoot:FindFirstChild("AlignPosition")
				local alignOri = petRoot:FindFirstChild("AlignOrientation")

				if alignPos and alignOri and wallPart then
					petRoot:SetNetworkOwner(nil)

					local randomX = rng:NextNumber(-SPREAD_X, SPREAD_X)

					local currentY = petRoot.Position.Y

					local idleCFrameRel = wallPart.CFrame * CFrame.new(randomX, 0, -IDLE_BACK_OFFSET)
					local idleTargetPos = Vector3.new(idleCFrameRel.Position.X, currentY, idleCFrameRel.Position.Z)

					local attackCFrameRel = wallPart.CFrame * CFrame.new(randomX, 0, -ATTACK_BACK_OFFSET)
					local attackTargetPos =
						Vector3.new(attackCFrameRel.Position.X, currentY, attackCFrameRel.Position.Z)

					local lookAtWallFlat = Vector3.new(wallPart.Position.X, currentY, wallPart.Position.Z)

					alignOri.CFrame = CFrame.lookAt(idleTargetPos, lookAtWallFlat)

					alignPos.MaxVelocity = 100000

					self.ActiveAnimations[monsterGuid] = {
						Thread = nil,
						CurrentTween = nil,
					}

					local animationThread = task.spawn(function()
						while data.Monsters[monsterGuid].Status == "Breaking" and wallPart.Parent do
							local attackTween =
								TweenService:Create(alignPos, attackInfo, { Position = attackTargetPos })

							self.ActiveAnimations[monsterGuid].CurrentTween = attackTween
							attackTween:Play()
							attackTween.Completed:Wait()

							alignPos.MaxVelocity = 20000
							local retreatTween =
								TweenService:Create(alignPos, retreatInfo, { Position = idleTargetPos })

							self.ActiveAnimations[monsterGuid].CurrentTween = retreatTween
							retreatTween:Play()
							retreatTween.Completed:Wait()

							alignPos.MaxVelocity = 100000
							task.wait(rng:NextNumber(0.1, 0.3))
						end

						self.ActiveAnimations[monsterGuid] = nil
					end)

					self.ActiveAnimations[monsterGuid].Thread = animationThread
				end
			end
		end
	end
end

function WallService:StopMonsterAnimation(monsterGuid)
	local animData = self.ActiveAnimations[monsterGuid]

	if animData then
		if animData.CurrentTween then
			animData.CurrentTween:Cancel()
		end

		if animData.Thread then
			task.cancel(animData.Thread)
		end

		self.ActiveAnimations[monsterGuid] = nil
	end
end

function WallService:SetEquipMonster(player)
	local data = self.DataService:GetData(player)
	local activeMonsters = self.MonsterService:GetActiveMonsters(player)

	for monsterGuid, _ in pairs(activeMonsters) do
		if data.Monsters[monsterGuid].Status == "Breaking" then
			self:StopMonsterAnimation(monsterGuid)
			self.MonsterService:EquipMonster(player, monsterGuid)
		end
	end
end

function WallService:InitResetArea()
	print("in breakings ", self.InBreakings)

	local resetPart = workspace:FindFirstChild("BreakableWalls")
		and workspace.BreakableWalls:FindFirstChild("ResetPart")

	if resetPart then
		local playerDebounce = {}
		local DEBOUNCE_COOLDOWN = 2

		resetPart.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = game:GetService("Players"):GetPlayerFromCharacter(character)

			if player and not playerDebounce[player] then
				playerDebounce[player] = true

				self:ResetAllWalls(player)
				self.InBreakings[player] = nil

				task.delay(DEBOUNCE_COOLDOWN, function()
					playerDebounce[player] = nil
				end)

				if not self.InBreakings[player] then
					return
				end
			end
		end)
	else
		warn("ResetPart tidak ditemukan di workspace.BreakableWalls")
	end
end

function WallService:InitEggSpawnZones()
	local areasFolder = workspace:FindFirstChild("BreakableWalls")
	if not areasFolder then
		return
	end

	for _, areaModel in ipairs(areasFolder:GetChildren()) do
		local spawnZonePart = areaModel:FindFirstChild("SpawnZone")
		if spawnZonePart then
			local spawnZone = Zone.new(spawnZonePart)
			self.AreaZones[areaModel.Name] = spawnZone
			self.ActiveEggs[areaModel.Name] = {}

			self:SpawnEggInArea(areaModel.Name)
		end
	end
end

function WallService:GetSafeRandomPoint(areaName, padding)
	local zone = self.AreaZones[areaName]
	local activeEggs = self.ActiveEggs[areaName]
	local maxAttempts = 10

	for _ = 1, maxAttempts do
		local point = zone:getRandomPoint()
		local isSafe = true

		for _, existingEgg in ipairs(activeEggs) do
			local distance = (point - existingEgg.Position).Magnitude
			if distance < padding then
				isSafe = false
				break
			end
		end

		if isSafe then
			return point
		end
	end

	return nil
end

local function getAreaNumber(areaName: string)
	local digits = string.match(areaName, "%d+")
	if not digits then
		return nil
	end

	return tonumber(digits)
end

function WallService:SpawnEggInArea(areaName, forcedEggName)
	local padding = 5

	if not self.AreaZones[areaName] then
		return
	end

	if not forcedEggName then
		local areaNumber = getAreaNumber(areaName)
		local areaConfig = areaNumber and EggConstants.AreaConfig[areaNumber]
		if not areaConfig then
			warn("Missing AreaConfig for " .. areaName)
			return
		end

		for _, eggName in ipairs(areaConfig.Eggs) do
			for _ = 1, 2 do
				self:SpawnEggInArea(areaName, eggName)
			end
		end

		return
	end

	local eggAsset = EggAssets:FindFirstChild(forcedEggName)
	if not eggAsset or not eggAsset:IsA("Model") then
		warn("Egg asset not found: " .. tostring(forcedEggName))
		return
	end

	local safePoint = self:GetSafeRandomPoint(areaName, padding)
	if not safePoint then
		warn("Could not find safe spawn point for Egg in " .. areaName)
		return
	end

	local newEgg = eggAsset:Clone()
	newEgg.Name = forcedEggName
	newEgg:PivotTo(CFrame.new(safePoint) * CFrame.new(0, 2, 0))
	newEgg.Parent = workspace.BreakableWalls[areaName]
	attachEggTitleGui(newEgg, forcedEggName)

	table.insert(self.ActiveEggs[areaName], {
		Instance = newEgg,
		Position = safePoint,
		EggName = forcedEggName,
	})

	local eggRoot = newEgg.PrimaryPart or newEgg:FindFirstChildWhichIsA("BasePart", true)
	if not eggRoot then
		warn("Egg model has no BasePart root: " .. forcedEggName)
		newEgg:Destroy()
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Take Egg"
	prompt.ObjectText = "Egg"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 8
	prompt.HoldDuration = 0.2
	prompt.Parent = eggRoot

	CollectionService:AddTag(prompt, "EggPickupPrompt")

	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("IsHoldingEgg") == true then
			return
		end

		self:HandleEggPickup(player, newEgg)
	end)

	newEgg.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:RemoveEggFromTracking(areaName, newEgg)
		end
	end)
end

function WallService:RemoveEggFromTracking(areaName, eggInstance)
	local eggs = self.ActiveEggs[areaName]
	if not eggs then
		return
	end

	for i, eggData in ipairs(eggs) do
		if eggData.Instance == eggInstance then
			local respawnEggName = eggData.EggName
			table.remove(eggs, i)

			task.delay(5, function()
				self:SpawnEggInArea(areaName, respawnEggName)
			end)

			break
		end
	end
end

function WallService:StartDamageLoop()
	print(self.ActiveBreakers)
	task.spawn(function()
		while true do
			for player, wallId in pairs(self.ActiveBreakers) do
				if not player.Parent then
					self.ActiveBreakers[player] = nil
					continue
				end

				local data = self.DataService:GetData(player)
				if not data then
					continue
				end

				if not data.WallProgress[wallId] then
					local config = WallConstants.Data[wallId]
					data.WallProgress[wallId] = {
						HP = config.MaxHP,
						IsDestroyed = false,
					}
				end

				local wallData = data.WallProgress[wallId]

				if wallData.IsDestroyed then
					self:SetEquipMonster(player)
					continue
				end

				local totalDamage = self.PlayerActiveDamage[player] or 0

				if totalDamage > 0 then
					wallData.HP -= totalDamage

					if wallData.HP <= 0 then
						wallData.HP = 0
						wallData.IsDestroyed = true
						self.ActiveBreakers[player] = nil

						self:SetEquipMonster(player)

						print(player.Name .. " menghancurkan " .. wallId)
						self.Client.WallDestroyed:Fire(player, wallId)
					else
						print(wallData.HP)
						self.Client.WallDamaged:Fire(player, wallId, wallData.HP)
					end
				end
			end

			task.wait(1)
		end
	end)
end

function WallService:RecalculatePlayerDamage(player)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	local playerPower = data.Upgrades.PowerLevel or 1
	local totalDamage = 0

	for _, monsterObj in pairs(data.Monsters or {}) do
		if monsterObj.Status == "Breaking" then
			local monsterId = monsterObj.monsterId
			local monsterMultiplier = MonsterConstants.Data[monsterId].BaseMultiplier

			local individualDamage = playerPower * monsterMultiplier

			totalDamage += individualDamage
		end
	end

	self.PlayerActiveDamage[player] = totalDamage + playerPower
end

function WallService:ResetAllWalls(player)
	local data = self.DataService:GetData(player)
	if not data.WallProgress then
		return
	end

	for wallId, wallData in pairs(data.WallProgress) do
		if wallData.IsDestroyed then
			wallData.HP = WallConstants.Data[wallId].MaxHP
			wallData.IsDestroyed = false

			self.Client.WallReset:Fire(player, wallId)
		else
			wallData.HP = WallConstants.Data[wallId].MaxHP
		end
	end
end

function WallService:HandleEggPickup(player, eggInstance)
	local EggService = Knit.GetService("EggService")
	local processPickup = EggService:ProcessPickup(player, eggInstance)

	print("INSTANSI", eggInstance)
	self.SafehouseService:CreateDropPrompt(player)

	if processPickup then
		local character = player.Character
		local head = character and character:FindFirstChild("Head")

		if head then
			local eggRoot = eggInstance.PrimaryPart
				or eggInstance:FindFirstChildOfClass("MeshPart")
				or eggInstance:FindFirstChild("BlueEgg")

			if eggRoot then
				for _, part in ipairs(eggInstance:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false
						part.Massless = true
					end
				end

				self.SafehouseService:PlayerHoldingEggAnimation(player)
				eggInstance:PivotTo(head.CFrame * CFrame.new(0, 2, 1.5))

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = head
				weld.Part1 = eggRoot
				weld.Parent = eggRoot

				local prompt = eggInstance:FindFirstChildOfClass("ProximityPrompt", true)
				if prompt then
					prompt.Enabled = false
				end
			end
		else
			eggInstance:Destroy()
		end
	end
end

return WallService
