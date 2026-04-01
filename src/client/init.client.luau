local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

GuiService.AutoSelectGuiEnabled = true
GuiService.GuiNavigationEnabled = true

if UserInputService.TouchEnabled then
	task.wait()
	local playerGUI = Players.LocalPlayer:WaitForChild("PlayerGui")
	playerGUI.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight
end

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllers(script.Controllers)

Knit.Start()
	:andThen(function()
		print("[CLIENT] Knit Client berhasil menyala! Semua Controllers siap.")
	end)
	:catch(warn)
