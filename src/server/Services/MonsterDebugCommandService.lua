local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MonsterConstants = require(ReplicatedStorage.Shared.Constants.MonsterConstants)

local MonsterAssets: Folder = ServerStorage:WaitForChild("Assets"):WaitForChild("Monsters")

local MonsterDebugCommandService = Knit.CreateService({
	Name = "MonsterDebugCommandService",
	Client = {},
	CycleTokens = {},
})

local function normalizeMessage(rawMessage: string): string?
	if not rawMessage then
		return nil
	end

	local payload = string.gsub(rawMessage, "^%s+", "")
	payload = string.gsub(payload, "%s+$", "")

	if payload == "" then
		return nil
	end

	return payload
end

local function parseUnequipCommand(message: string): string?
	local lower = string.lower(message)
	if string.sub(lower, 1, 3) ~= "un " then
		return nil
	end

	local monsterId = string.sub(message, 4)
	monsterId = string.gsub(monsterId, "^%s+", "")
	monsterId = string.gsub(monsterId, "%s+$", "")

	if monsterId == "" then
		return nil
	end

	return monsterId
end

local function isStartCommand(message: string): boolean
	local lower = string.lower(message)
	return lower == "!start"
end

local function getMonsterPreviewList(): { string }
	local ids = {}
	for _, child in ipairs(MonsterAssets:GetChildren()) do
		if child:IsA("Model") and MonsterConstants.Data[child.Name] then
			table.insert(ids, child.Name)
		end
	end

	table.sort(ids)
	return ids
end

function MonsterDebugCommandService:CleanupSpawnedMonster(player: Player, monsterGuid: string)
	local data = self.DataService:GetData(player)
	if not data then
		return
	end

	local activeMonsters = self.MonsterService:GetActiveMonsters(player)
	local activeModel = activeMonsters[monsterGuid]
	if activeModel then
		activeModel:SetAttribute("IsEquipped", false)
		activeModel:Destroy()
		activeMonsters[monsterGuid] = nil
	end

	if data.Monsters then
		data.Monsters[monsterGuid] = nil
	end
end

function MonsterDebugCommandService:RunStartCycle(player: Player)
	local token = (self.CycleTokens[player] or 0) + 1
	self.CycleTokens[player] = token

	task.spawn(function()
		local monsterIds = getMonsterPreviewList()
		for _, monsterId in ipairs(monsterIds) do
			if self.CycleTokens[player] ~= token then
				return
			end

			local monsterGuid = self.DataService:AddMonsterToInventory(player, monsterId)
			if monsterGuid then
				self.MonsterService:EquipMonster(player, monsterGuid)

				if self.DataService.NotifyDataChanged then
					self.DataService:NotifyDataChanged(player)
				end

				task.wait(3)

				if self.CycleTokens[player] ~= token then
					self:CleanupSpawnedMonster(player, monsterGuid)
					return
				end

				self:CleanupSpawnedMonster(player, monsterGuid)
			end
		end

		if self.CycleTokens[player] == token then
			self.CycleTokens[player] = nil
		end
	end)
end

function MonsterDebugCommandService:TryUnequipByMonsterId(player: Player, monsterId: string)
	local data = self.DataService:GetData(player)
	if not data or not data.Monsters then
		return false
	end

	local targetGuid = nil
	for monsterGuid, monsterData in pairs(data.Monsters) do
		if monsterData.monsterId == monsterId then
			targetGuid = monsterGuid
			break
		end
	end

	if not targetGuid then
		warn("[MonsterDebug] Monster id not found in inventory:", monsterId)
		return false
	end

	local activeMonsters = self.MonsterService:GetActiveMonsters(player)
	local activeModel = activeMonsters[targetGuid]
	if not activeModel then
		warn("[MonsterDebug] Monster not currently active:", monsterId)
		return false
	end

	activeModel:SetAttribute("IsEquipped", false)
	print(string.format("[MonsterDebug] Unequipped '%s' for %s", monsterId, player.Name))
	return true
end

function MonsterDebugCommandService:HandleChatCommand(player: Player, message: string)
	local normalized = normalizeMessage(message)
	if not normalized then
		return
	end

	if isStartCommand(normalized) then
		self:RunStartCycle(player)
		return
	end

	local unequipMonsterId = parseUnequipCommand(normalized)
	if unequipMonsterId then
		self:TryUnequipByMonsterId(player, unequipMonsterId)
		return
	end

	local monsterId = normalized

	local monsterConfig = MonsterConstants.Data[monsterId]
	if not monsterConfig then
		return
	end

	local asset = MonsterAssets:FindFirstChild(monsterId)
	if not asset then
		warn("[MonsterDebug] Missing monster asset:", monsterId)
		return
	end

	local monsterGuid = self.DataService:AddMonsterToInventory(player, monsterId)
	if not monsterGuid then
		warn("[MonsterDebug] Failed to add monster to inventory for:", player.Name)
		return
	end

	self.MonsterService:EquipMonster(player, monsterGuid)

	if self.DataService.NotifyDataChanged then
		self.DataService:NotifyDataChanged(player)
	end

	print(string.format("[MonsterDebug] Spawned + equipped '%s' for %s", monsterId, player.Name))
end

function MonsterDebugCommandService:BindPlayer(player: Player)
	player.Chatted:Connect(function(message)
		self:HandleChatCommand(player, message)
	end)
end

function MonsterDebugCommandService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.MonsterService = Knit.GetService("MonsterService")

	for _, player in ipairs(Players:GetPlayers()) do
		self:BindPlayer(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:BindPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.CycleTokens[player] = nil
	end)
end

return MonsterDebugCommandService
