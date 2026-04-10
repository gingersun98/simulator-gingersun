local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local UiModalEffects = require(script.Parent.Parent.Modules.UiModalEffects)

local IndexController = Knit.CreateController({
	Name = "IndexController",
})

function IndexController:KnitStart()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local mainUI = playerGui:WaitForChild("Main")
	local openIndexButton = mainUI:WaitForChild("Buttons"):WaitForChild("Index")

	local framesUI = playerGui:WaitForChild("Frames")
	local indexFrame = framesUI:WaitForChild("Index")
	local closeIndexButton = indexFrame:WaitForChild("Close")

	indexFrame.Visible = false
	UiModalEffects.SetupHoverEffect(openIndexButton)
	UiModalEffects.SetupHoverEffect(closeIndexButton)

	openIndexButton.MouseButton1Click:Connect(function()
		if indexFrame.Visible then
			return
		end

		indexFrame.Visible = true
		UiModalEffects.PlayOpenFrame(indexFrame)
		UiModalEffects.OpenModal()
	end)

	closeIndexButton.MouseButton1Click:Connect(function()
		if not indexFrame.Visible then
			return
		end

		indexFrame.Visible = false
		UiModalEffects.CloseModal()
	end)
end

return IndexController
