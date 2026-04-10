local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local localPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local SafehouseController = Knit.CreateController({
	Name = "SafehouseController",
})

function SafehouseController:KnitStart()
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
