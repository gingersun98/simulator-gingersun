local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local localPlayer = Players.LocalPlayer
if not localPlayer then
	return
end

local playerGui = localPlayer:WaitForChild("PlayerGui")
local loadingTemplate = script:FindFirstChild("LoadingGUI") or ReplicatedFirst:FindFirstChild("LoadingGUI")

if not loadingTemplate or not loadingTemplate:IsA("ScreenGui") then
	warn("LoadingGUI not found in ReplicatedFirst")
	return
end

local loadingGui = loadingTemplate
if loadingGui.Parent ~= playerGui then
	loadingGui = loadingTemplate:Clone()
	loadingGui.Parent = playerGui
end

local frame = loadingGui:FindFirstChild("Frame")
if not frame or not frame:IsA("Frame") then
	warn("LoadingGUI.Frame not found")
	loadingGui:Destroy()
	return
end

local skipButton = frame:FindFirstChild("SkipButton")
local imageLabel = frame:FindFirstChild("ImageLabel")
local loadingText = frame:FindFirstChild("LoadingText")

if skipButton and skipButton:IsA("GuiObject") then
	skipButton.Visible = false
end

local running = true
local closeRequested = false

local rotationTween
if imageLabel and imageLabel:IsA("ImageLabel") then
	local rotateInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	rotationTween = TweenService:Create(imageLabel, rotateInfo, { Rotation = 12 })
	rotationTween:Play()
end

if loadingText and loadingText:IsA("TextLabel") then
	local baseText = string.gsub(loadingText.Text, "%.+$", "")
	if baseText == "" then
		baseText = "Loading"
	end

	task.spawn(function()
		local dotSequence = { 3, 2, 1, 2 }
		local index = 1
		while running and loadingText.Parent do
			local dotCount = dotSequence[index]
			loadingText.Text = baseText .. string.rep(".", dotCount)
			index += 1
			if index > #dotSequence then
				index = 1
			end
			task.wait(0.3)
		end
	end)
end

if skipButton and (skipButton:IsA("TextButton") or skipButton:IsA("ImageButton")) then
	skipButton.Activated:Connect(function()
		closeRequested = true
	end)
end

task.delay(5, function()
	if not running then
		return
	end

	if skipButton and skipButton:IsA("GuiObject") then
		skipButton.Visible = true
	end

	task.delay(2, function()
		if running then
			closeRequested = true
		end
	end)
end)

while not closeRequested do
	task.wait(0.1)
	if not loadingGui.Parent then
		running = false
		return
	end
end

running = false
if rotationTween then
	rotationTween:Cancel()
end

local fadeTweens = {}
local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function queueFade(instance)
	local goals = {}

	if instance:IsA("GuiObject") then
		goals.BackgroundTransparency = 1
	end

	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		goals.TextTransparency = 1
		goals.TextStrokeTransparency = 1
	end

	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		goals.ImageTransparency = 1
	end

	if instance:IsA("UIStroke") then
		goals.Transparency = 1
	end

	if next(goals) ~= nil then
		table.insert(fadeTweens, TweenService:Create(instance, fadeInfo, goals))
	end
end

queueFade(frame)
for _, descendant in ipairs(frame:GetDescendants()) do
	queueFade(descendant)
end

for _, tween in ipairs(fadeTweens) do
	tween:Play()
end

task.wait(0.55)
loadingGui:Destroy()
