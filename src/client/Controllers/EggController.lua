local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local EggController = Knit.CreateController({
	Name = "EggController",
})

function EggController:KnitStart()
	local localPlayer = Players.LocalPlayer

	local function updateEggPrompts()
		local isHolding = localPlayer:GetAttribute("IsHoldingEgg") or false

		for _, prompt in ipairs(CollectionService:GetTagged("EggPickupPrompt")) do
			prompt.Enabled = not isHolding
		end
	end

	localPlayer:GetAttributeChangedSignal("IsHoldingEgg"):Connect(updateEggPrompts)

	CollectionService:GetInstanceAddedSignal("EggPickupPrompt"):Connect(function(newPrompt)
		local isHolding = localPlayer:GetAttribute("IsHoldingEgg") or false
		newPrompt.Enabled = not isHolding
	end)
end

return EggController
