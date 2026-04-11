local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local MonsterService = Knit.CreateService({
	Name = "MonsterService",
	Client = {},
	ActiveMonsters = {},
})

function MonsterService:KnitStart()
	self.DataService = Knit.GetService("DataService")

	Players.PlayerRemoving:Connect(function(player)
		self:CleanupMonsters(player)
	end)
end

function MonsterService:KnitInit()
	self.CoinAnimations = {}
end

function MonsterService:CleanupMonsters(player)
	if self.ActiveMonsters[player] then
		local folder = workspace:FindFirstChild(player.Name .. "_Monsters")
		if folder then
			folder:Destroy()
		end
		self.ActiveMonsters[player] = nil
	end
end

function MonsterService:SpawnMonster(player, monsterGuid)
	local data = self.DataService:GetData(player)
	if not data or not data.Monsters[monsterGuid] then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if not self.ActiveMonsters[player] then
		self.ActiveMonsters[player] = {}
	end

	if self.ActiveMonsters[player][monsterGuid] then
		return
	end

	local monsterId = data.Monsters[monsterGuid].monsterId
	local monsterAsset = ServerStorage.Monsters:FindFirstChild("Cat")

	if monsterAsset then
		local clone = monsterAsset:Clone()
		local petRoot = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChildOfClass("MeshPart")
		if not petRoot then
			return
		end

		petRoot.CanCollide = false
		petRoot.Anchored = false
		petRoot.Massless = true

		local petAttachment = petRoot:FindFirstChild("PetAttachment")
		if not petAttachment then
			petAttachment = Instance.new("Attachment")
			petAttachment.Name = "PetAttachment"
			petAttachment.Orientation = Vector3.new(0, 180, 0)
			petAttachment.Parent = petRoot
		end

		local alignPos = Instance.new("AlignPosition")
		alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
		alignPos.Attachment0 = petAttachment
		alignPos.MaxForce = 100000
		alignPos.Responsiveness = 40
		alignPos.Parent = petRoot

		local alignOri = Instance.new("AlignOrientation")
		alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOri.Attachment0 = petAttachment
		alignOri.MaxTorque = 100000
		alignOri.Responsiveness = 30
		alignOri.Parent = petRoot

		local folderName = player.Name .. "_Monsters"
		local playerMonsterFolder = workspace:FindFirstChild(folderName)
		if not playerMonsterFolder then
			playerMonsterFolder = Instance.new("Folder")
			playerMonsterFolder.Name = folderName
			playerMonsterFolder.Parent = workspace
		end

		petRoot.CFrame = rootPart.CFrame * CFrame.new(0, 0, 3)

		clone:SetAttribute("IsEquipped", true)
		clone.Parent = playerMonsterFolder

		local walkAnimation = Instance.new("Animation")
		walkAnimation.AnimationId = "rbxassetid://72435867523649"

		local animController = clone:FindFirstChildOfClass("AnimationController")

		if animController then
			local animator = animController:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = animController
			end

			local walkTrack = animator:LoadAnimation(walkAnimation)

			walkTrack.Looped = true

			walkTrack:Play()
		else
			warn("Gagal memutar animasi: AnimationController tidak ditemukan pada model", clone.Name)
		end

		petRoot:SetNetworkOwner(player)

		self.ActiveMonsters[player][monsterGuid] = clone
		print("Monster " .. monsterId .. " di-spawn untuk " .. player.Name)
	end
end

function MonsterService:UnequipMonster(player, monsterGuid, physicalCoinSlot: Part, coinSource: Model)
	if self.ActiveMonsters[player] and self.ActiveMonsters[player][monsterGuid] then
		local monsterModel = self.ActiveMonsters[player][monsterGuid]

		monsterModel:SetAttribute("IsEquipped", false)

		local petRoot = monsterModel:FindFirstChildOfClass("MeshPart")
			or monsterModel:FindFirstChild("HumanoidRootPart")

		if petRoot then
			petRoot:SetNetworkOwner(nil)

			local alignPos = petRoot:FindFirstChild("AlignPosition")
			local alignOri = petRoot:FindFirstChild("AlignOrientation")

			if alignPos and alignOri and physicalCoinSlot and coinSource and coinSource.PrimaryPart then
				local basePosition = physicalCoinSlot.Position + Vector3.new(0, 3.5, 0)
				local jumpPosition = basePosition + Vector3.new(0, 2, 0) -- Angka 2 adalah tinggi loncatan

				local sourcePos = coinSource.PrimaryPart.Position
				local lookAtSourceFlat = Vector3.new(sourcePos.X, basePosition.Y, sourcePos.Z)

				alignPos.MaxVelocity = 100000
				alignOri.CFrame = CFrame.lookAt(basePosition, lookAtSourceFlat)

				-- ==========================================
				-- LOGIKA ANIMASI LONCAT
				-- ==========================================

				-- Konfigurasi Tween (Lompat = Sine Out agar melambat di atas, Jatuh = Sine In agar cepat ke bawah)
				local jumpUpInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				local dropDownInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

				-- 1. Inisialisasi wadah animasi agar tidak error "nil"
				if not self.CoinAnimations then
					self.CoinAnimations = {}
				end
				self.CoinAnimations[monsterGuid] = {
					Thread = nil,
					CurrentTween = nil,
				}

				-- 2. Mulai Loop Loncatan
				local animThread = task.spawn(function()
					-- Loop akan berjalan selama monster belum di-equip lagi
					while not monsterModel:GetAttribute("IsEquipped") and monsterModel.Parent do
						-- A. LOMPAT NAIK
						local jumpTween = TweenService:Create(alignPos, jumpUpInfo, { Position = jumpPosition })
						self.CoinAnimations[monsterGuid].CurrentTween = jumpTween
						jumpTween:Play()
						jumpTween.Completed:Wait()

						-- B. JATUH TURUN
						local dropTween = TweenService:Create(alignPos, dropDownInfo, { Position = basePosition })
						self.CoinAnimations[monsterGuid].CurrentTween = dropTween
						dropTween:Play()
						dropTween.Completed:Wait()

						-- Jeda sebentar di lantai sebelum loncat lagi (opsional)
						task.wait(0.1)
					end

					-- Bersihkan memori jika loop berhenti natural
					if self.CoinAnimations[monsterGuid] then
						self.CoinAnimations[monsterGuid] = nil
					end
				end)

				-- 3. Simpan Thread
				self.CoinAnimations[monsterGuid].Thread = animThread

				print("Monster " .. monsterGuid .. " sedang menuju ke slot dan mulai loncat-loncat!")
			end
		end
	end
end

function MonsterService:EquipMonster(player, monsterGuid)
	if self.ActiveMonsters[player] and self.ActiveMonsters[player][monsterGuid] then
		local monsterModel = self.ActiveMonsters[player][monsterGuid]

		monsterModel:SetAttribute("IsEquipped", true)
		self:StopCoinAnimation(monsterGuid)

		local petRoot = monsterModel:FindFirstChildOfClass("MeshPart")
			or monsterModel:FindFirstChild("HumanoidRootPart")
		if petRoot then
			petRoot:SetNetworkOwner(player)
		end
	else
		self:SpawnMonster(player, monsterGuid)
	end
end

function MonsterService:GetActiveMonsters(player)
	return self.ActiveMonsters[player] or {}
end

function MonsterService:StopCoinAnimation(monsterGuid)
	if self.CoinAnimations and self.CoinAnimations[monsterGuid] then
		local animData = self.CoinAnimations[monsterGuid]

		if animData.CurrentTween then
			animData.CurrentTween:Cancel()
		end

		if animData.Thread then
			task.cancel(animData.Thread)
		end

		self.CoinAnimations[monsterGuid] = nil
	end
end

function MonsterService:ProcessSell(player, monsterGuid)
	local data = self.DataService:GetData(player)
	if not data then
		return false
	end
	if self.ActiveMonsters[player] and self.ActiveMonsters[player][monsterGuid] then
		local monsterModel = self.ActiveMonsters[player][monsterGuid]

		monsterModel:Destroy()
		self.ActiveMonsters[player][monsterGuid] = nil
		data.Monsters[monsterGuid] = nil

		return true
	end

	return false
end

return MonsterService
