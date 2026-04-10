local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local UiModalEffects = {}

local HOVER_SCALE = 1.05
local HOVER_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local FRAME_OPEN_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local CAMERA_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TARGET_BLUR = 15
local TARGET_FOV_OFFSET = 15

local activeModalCount = 0
local baseFieldOfView = nil

local function getOrCreateBlurEffect(): BlurEffect
	local uiBlur = Lighting:FindFirstChild("MenuBlur")
	if uiBlur and uiBlur:IsA("BlurEffect") then
		return uiBlur
	end

	uiBlur = Instance.new("BlurEffect")
	uiBlur.Name = "MenuBlur"
	uiBlur.Size = 0
	uiBlur.Parent = Lighting

	return uiBlur
end

function UiModalEffects.SetupHoverEffect(button: TextButton | ImageButton, hoverScale: number?)
	local uiScale = button:FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = button
	end
	uiScale.Scale = 1

	local targetScale = hoverScale or HOVER_SCALE

	button.MouseEnter:Connect(function()
		TweenService:Create(uiScale, HOVER_TWEEN_INFO, { Scale = targetScale }):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(uiScale, HOVER_TWEEN_INFO, { Scale = 1 }):Play()
	end)
end

function UiModalEffects.PlayOpenFrame(frame: GuiObject)
	local frameScale = frame:FindFirstChild("UIScale")
	if not frameScale then
		frameScale = Instance.new("UIScale")
		frameScale.Parent = frame
	end

	frameScale.Scale = 0.8
	TweenService:Create(frameScale, FRAME_OPEN_TWEEN_INFO, { Scale = 1 }):Play()
end

function UiModalEffects.OpenModal()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	if activeModalCount == 0 then
		baseFieldOfView = camera.FieldOfView
		local uiBlur = getOrCreateBlurEffect()
		TweenService:Create(uiBlur, CAMERA_TWEEN_INFO, { Size = TARGET_BLUR }):Play()
		TweenService:Create(camera, CAMERA_TWEEN_INFO, { FieldOfView = baseFieldOfView + TARGET_FOV_OFFSET }):Play()
	end

	activeModalCount += 1
end

function UiModalEffects.CloseModal()
	if activeModalCount <= 0 then
		return
	end

	activeModalCount -= 1
	if activeModalCount > 0 then
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local uiBlur = getOrCreateBlurEffect()
	TweenService:Create(uiBlur, CAMERA_TWEEN_INFO, { Size = 0 }):Play()

	if baseFieldOfView then
		TweenService:Create(camera, CAMERA_TWEEN_INFO, { FieldOfView = baseFieldOfView }):Play()
	end
end

return UiModalEffects
