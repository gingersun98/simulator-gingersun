-- Knit Packages
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Zone = require(ReplicatedStorage.Packages.zoneplus)
local MonsterConstants = require(ReplicatedStorage.Shared.Constants.MonsterConstants)

local WallConstants = require(ReplicatedStorage.Shared.Constants.WallConstants)

local WallService = Knit.CreateService({
	Name = "WallService",
	Client = {
		WallDamaged = Knit.CreateSignal(),
		WallDestroyed = Knit.CreateSignal(),
		WallReset = Knit.CreateSignal(),
	},
})

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
	local IDLE_BACK_OFFSET = 8 -- Jarak monster standby mundur dari tembok
	local ATTACK_BACK_OFFSET = 2 -- Jarak monster attack menempel tembok
	local SPREAD_X = 8

	local attackInfo = TweenInfo.new(
		0.15, -- Waktu maju (cepat)
		Enum.EasingStyle.Sine, -- Gaya Easing
		Enum.EasingDirection.Out -- Arah Easing
	)

	local retreatInfo = TweenInfo.new(
		0.5, -- Waktu mundur (lebih lama)
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.In
	)

	for monsterGuid, monsterPhysic in pairs(activeMonsters) do
		-- Pastikan statusnya Breaking
		if data.Monsters[monsterGuid].Status == "Breaking" then
			local petRoot = monsterPhysic:FindFirstChildOfClass("MeshPart")
				or monsterPhysic:FindFirstChild("HumanoidRootPart")

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

					-- 2. Mulai Loop Animasi
					local animationThread = task.spawn(function()
						while data.Monsters[monsterGuid].Status == "Breaking" and wallPart.Parent do
							-- A. Tween Maju Cepat
							local attackTween =
								TweenService:Create(alignPos, attackInfo, { Position = attackTargetPos })

							-- SEKARANG INI AMAN (Tidak akan nil lagi)
							self.ActiveAnimations[monsterGuid].CurrentTween = attackTween
							attackTween:Play()
							attackTween.Completed:Wait()

							-- B. Tween Mundur Lambat
							alignPos.MaxVelocity = 20000
							local retreatTween =
								TweenService:Create(alignPos, retreatInfo, { Position = idleTargetPos })

							-- UPDATE TWEEN MUNDUR
							self.ActiveAnimations[monsterGuid].CurrentTween = retreatTween
							retreatTween:Play()
							retreatTween.Completed:Wait()

							alignPos.MaxVelocity = 100000
							task.wait(rng:NextNumber(0.1, 0.3))
						end

						-- Jika berhenti secara natural (status berubah / tembok hancur), bersihkan data
						self.ActiveAnimations[monsterGuid] = nil
					end)

					-- 3. SIMPAN THREAD NYA SETELAH task.spawn
					-- Masukkan referensi thread ke dalam tabel yang sudah kita buat tadi
					self.ActiveAnimations[monsterGuid].Thread = animationThread
				end
			end
		end
	end
end

function WallService:StopMonsterAnimation(monsterGuid)
	local animData = self.ActiveAnimations[monsterGuid]

	if animData then
		-- 1. Batalkan Tween yang sedang berjalan seketika
		-- (Ini mencegah monster terus meluncur meskipun loop dimatikan)
		if animData.CurrentTween then
			animData.CurrentTween:Cancel()
		end

		-- 2. Matikan paksa thread/loop dari task.spawn
		if animData.Thread then
			task.cancel(animData.Thread)
		end

		-- 3. Hapus dari memori
		self.ActiveAnimations[monsterGuid] = nil
	end
end

function WallService:SetEquipMonster(player)
	local data = self.DataService:GetData(player)
	local activeMonsters = self.MonsterService:GetActiveMonsters(player)

	for monsterGuid, monsterPhysic in pairs(activeMonsters) do
		if data.Monsters[monsterGuid].Status == "Breaking" then
			self:StopMonsterAnimation(monsterGuid)
			self.MonsterService:EquipMonster(player, monsterGuid)
		end
	end
end

function WallService:InitResetArea()
	local resetPart = workspace:FindFirstChild("BreakableWalls")
		and workspace.BreakableWalls:FindFirstChild("ResetPart")

	if resetPart then
		local playerDebounce = {}
		local DEBOUNCE_COOLDOWN = 2

		resetPart.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = game:GetService("Players"):GetPlayerFromCharacter(character)

			if not self.InBreakings[player] then
				return
			end

			if player and not playerDebounce[player] then
				playerDebounce[player] = true

				self:ResetAllWalls(player)
				self.InBreakings[player] = nil
				print(player.Name .. " me-reset semua tembok!")

				task.delay(DEBOUNCE_COOLDOWN, function()
					playerDebounce[player] = nil
				end)
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

			for i = 1, 2 do
				self:SpawnEggInArea(areaModel.Name)
			end
		end
	end
end

function WallService:GetSafeRandomPoint(areaName, padding)
	local zone = self.AreaZones[areaName]
	local activeEggs = self.ActiveEggs[areaName]
	local maxAttempts = 10 -- Batasi percobaan agar tidak infinite loop jika area penuh

	for i = 1, maxAttempts do
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

function WallService:SpawnEggInArea(areaName)
	local eggAsset: Model = game:GetService("ServerStorage").Eggs:FindFirstChild("BlueEggInSpawn")
	local padding = 5

	if self.AreaZones[areaName] and eggAsset then
		local safePoint = self:GetSafeRandomPoint(areaName, padding)

		if safePoint then
			local newEgg = eggAsset:Clone()
			newEgg:PivotTo(CFrame.new(safePoint) * CFrame.new(0, 2, 0))
			newEgg.Parent = workspace.BreakableWalls[areaName]

			table.insert(self.ActiveEggs[areaName], {
				Instance = newEgg,
				Position = safePoint,
			})

			local prompt = newEgg.BlueEgg:FindFirstChildOfClass("ProximityPrompt")
			prompt.ActionText = "Take Egg"
			prompt.ObjectText = "Egg"

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
		else
			warn("Could not find safe spawn point for Egg in " .. areaName)
		end
	end
end

function WallService:RemoveEggFromTracking(areaName, eggInstance)
	local eggs = self.ActiveEggs[areaName]
	if not eggs then
		return
	end

	for i, eggData in ipairs(eggs) do
		if eggData.Instance == eggInstance then
			table.remove(eggs, i)

			task.delay(5, function()
				self:SpawnEggInArea(areaName)
			end)

			break
		end
	end
end

function WallService:StartDamageLoop()
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
			local monsterMultiplier = MonsterConstants.Data[monsterId].BaseMultiplier * 10

			local individualDamage = playerPower * monsterMultiplier

			totalDamage += individualDamage
		end
	end

	self.PlayerActiveDamage[player] = totalDamage
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
