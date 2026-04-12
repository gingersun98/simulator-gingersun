local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local UiModalEffects = require(script.Parent.Parent.Modules.UiModalEffects)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonsterConstants = require(ReplicatedStorage.Shared.Constants.MonsterConstants)
local CLICK_SOUND_TEMPLATE = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds"):WaitForChild("Click")

local IndexController = Knit.CreateController({
	Name = "IndexController",
})

function IndexController:KnitStart()
	local DataService = Knit.GetService("DataService")

	local function playClickSound()
		local soundClone = CLICK_SOUND_TEMPLATE:Clone()
		soundClone.Parent = SoundService
		soundClone:Play()
		Debris:AddItem(soundClone, math.max(soundClone.TimeLength, 1) + 0.25)
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local mainUI = playerGui:WaitForChild("Main")
	local openIndexButton = mainUI:WaitForChild("Buttons"):WaitForChild("Index")
	local newPetFrame = mainUI:WaitForChild("NewPet")
	local newPetViewport = newPetFrame:WaitForChild("Viewport")
	local newPetNameLabel = newPetViewport:WaitForChild("NewTextPet")

	local framesUI = playerGui:WaitForChild("Frames")
	local indexFrame = framesUI:WaitForChild("Index")
	local closeIndexButton = indexFrame:WaitForChild("Close")
	local scrollingFrame = indexFrame:WaitForChild("ScrollingFrame")
	local indexCardTemplate = scrollingFrame:WaitForChild("IndexCardTemplate")

	local cardsByMonsterId = {}
	local orderedMonsterIds = {}
	local knownUnlocked = {}
	local hasInitialData = false
	local notifyQueue = {}
	local isShowingNotification = false

	local shownPosition = newPetFrame.Position
	local hiddenPosition =
		UDim2.new(shownPosition.X.Scale, shownPosition.X.Offset, shownPosition.Y.Scale + 1, shownPosition.Y.Offset)

	newPetFrame.Position = hiddenPosition
	newPetFrame.Visible = false

	for monsterId in pairs(MonsterConstants.Data) do
		table.insert(orderedMonsterIds, monsterId)
	end

	table.sort(orderedMonsterIds, function(a, b)
		local aName = MonsterConstants.Data[a].Name or a
		local bName = MonsterConstants.Data[b].Name or b
		if aName == bName then
			return a < b
		end
		return aName < bName
	end)

	indexCardTemplate.Visible = false

	for _, monsterId in ipairs(orderedMonsterIds) do
		local card = indexCardTemplate:Clone()
		card.Name = "Card_" .. monsterId
		card.Visible = true
		card.Parent = scrollingFrame
		cardsByMonsterId[monsterId] = card
	end

	local function playNextNotification()
		if isShowingNotification then
			return
		end

		local nextMonsterId = table.remove(notifyQueue, 1)
		if not nextMonsterId then
			return
		end

		isShowingNotification = true

		local monsterData = MonsterConstants.Data[nextMonsterId]
		newPetNameLabel.Text = (monsterData and monsterData.Name) or nextMonsterId

		newPetFrame.Visible = true

		local tweenIn = TweenService:Create(
			newPetFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = shownPosition }
		)
		tweenIn:Play()
		tweenIn.Completed:Wait()

		task.wait(2.5)

		local tweenOut = TweenService:Create(
			newPetFrame,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = hiddenPosition }
		)
		tweenOut:Play()
		tweenOut.Completed:Wait()

		newPetFrame.Visible = false
		isShowingNotification = false

		if #notifyQueue > 0 then
			task.defer(playNextNotification)
		end
	end

	local function enqueueNewPetNotification(monsterId)
		table.insert(notifyQueue, monsterId)
		task.defer(playNextNotification)
	end

	local function seedKnownUnlocked(unlockedMap)
		table.clear(knownUnlocked)
		for monsterId, unlocked in pairs(unlockedMap) do
			if unlocked == true then
				knownUnlocked[monsterId] = true
			end
		end
	end

	local function renderIndex(data)
		local unlockedMap = (data and data.MonstersIndex) or {}

		for monsterId, card in pairs(cardsByMonsterId) do
			local indexImage = card:FindFirstChild("IndexImage")
			local indexText = card:FindFirstChild("IndexText")
			local monsterData = MonsterConstants.Data[monsterId]
			local isUnlocked = unlockedMap[monsterId] == true

			if indexImage and indexImage:IsA("ImageLabel") then
				if isUnlocked then
					indexImage.Image = monsterData.ImageId or ""
				else
					indexImage.Image = ""
				end
			end

			if indexText and indexText:IsA("TextLabel") then
				if isUnlocked then
					indexText.Text = monsterData.Name or monsterId
				else
					indexText.Text = "???"
				end
			end
		end
	end

	DataService:GetData()
		:andThen(function(data)
			renderIndex(data)
			seedKnownUnlocked((data and data.MonstersIndex) or {})
			hasInitialData = true
		end)
		:catch(warn)

	DataService.DataChanged:Connect(function(newData)
		renderIndex(newData)

		local unlockedMap = (newData and newData.MonstersIndex) or {}
		if not hasInitialData then
			seedKnownUnlocked(unlockedMap)
			hasInitialData = true
			return
		end

		for _, monsterId in ipairs(orderedMonsterIds) do
			if unlockedMap[monsterId] == true and not knownUnlocked[monsterId] then
				knownUnlocked[monsterId] = true
				enqueueNewPetNotification(monsterId)
			end
		end
	end)

	indexFrame.Visible = false
	UiModalEffects.SetupHoverEffect(openIndexButton)
	UiModalEffects.SetupHoverEffect(closeIndexButton)

	openIndexButton.MouseButton1Click:Connect(function()
		playClickSound()
		if indexFrame.Visible then
			return
		end

		indexFrame.Visible = true
		UiModalEffects.PlayOpenFrame(indexFrame)
		UiModalEffects.OpenModal()
	end)

	closeIndexButton.MouseButton1Click:Connect(function()
		playClickSound()
		if not indexFrame.Visible then
			return
		end

		indexFrame.Visible = false
		UiModalEffects.CloseModal()
	end)
end

return IndexController
