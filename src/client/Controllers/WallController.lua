-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local WallController = Knit.CreateController({
	Name = "WallController",
})

function WallController:KnitStart()
	local WallService = Knit.GetService("WallService")

	WallService.WallDestroyed:Connect(function(wallId)
		self:ProcessWallDestruction(wallId)
	end)

	WallService.WallReset:Connect(function(wallId)
		self:SetWallVisibility(wallId, true)
	end)
end

function WallController:ProcessWallDestruction(wallId)
	local wallFolder = workspace:FindFirstChild("BreakableWalls")
	local physicalWall: BasePart = wallFolder and wallFolder:FindFirstChild(wallId).Wall

	if physicalWall then
		physicalWall.CanCollide = false
		physicalWall.Transparency = 0.5

		-- physicalWall:Destroy()
	end
end

function WallController:SetWallVisibility(wallId, isVisible)
	local wallFolder = workspace:FindFirstChild("BreakableWalls")
	local physicalWall: BasePart = wallFolder and wallFolder:FindFirstChild(wallId).Wall

	if physicalWall then
		local targetTransparency = isVisible and 0 or 1
		physicalWall.CanCollide = isVisible
		physicalWall.Transparency = targetTransparency
	end
end

return WallController
