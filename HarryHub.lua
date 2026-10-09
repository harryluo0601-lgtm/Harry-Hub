-- Harry Hub | Roblox Studio 自製遊戲版
-- 移動速度、鏡頭方向飛行、飛行速度、拖曳、最小化、關閉

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("HarryHub")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "HarryHub"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(360, 330)
main.Position = UDim2.new(0.5, -180, 0.5, -165)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(220, 35, 45)
stroke.Thickness = 1.5

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(125, 20, 30)
header.BorderSizePixel = 0
header.Active = true
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "Harry 介面"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local function makeButton(parent, name, text, pos, size, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 14
	b.Font = Enum.Font.GothamBold
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local minimize = makeButton(
	header, "最小化", "－",
	UDim2.new(1, -68, 0, 8),
	UDim2.fromOffset(28, 26),
	Color3.fromRGB(75, 25, 30)
)

local close = makeButton(
	header, "關閉", "✕",
	UDim2.new(1, -34, 0, 8),
	UDim2.fromOffset(28, 26),
	Color3.fromRGB(190, 35, 45)
)

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(12, 52)
content.Size = UDim2.new(1, -24, 1, -62)
content.BackgroundTransparency = 1
content.Parent = main

local function makeLabel(text, y)
	local l = Instance.new("TextLabel")
	l.Position = UDim2.fromOffset(0, y)
	l.Size = UDim2.new(1, 0, 0, 22)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(230, 230, 230)
	l.TextSize = 14
	l.Font = Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = content
	return l
end

local function makeInput(name, default, y)
	local box = Instance.new("TextBox")
	box.Name = name
	box.Position = UDim2.fromOffset(0, y)
	box.Size = UDim2.fromOffset(145, 34)
	box.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
	box.BorderSizePixel = 0
	box.Text = default
	box.PlaceholderText = "輸入 1～100000"
	box.TextColor3 = Color3.new(1, 1, 1)
	box.TextSize = 14
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.Parent = content
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	return box
end

makeLabel("移動速度（1～100000）", 0)
local walkBox = makeInput("移動速度輸入", "16", 24)
local walkApply = makeButton(
	content, "套用移動速度", "套用速度",
	UDim2.fromOffset(155, 24),
	UDim2.new(1, -155, 0, 34),
	Color3.fromRGB(180, 30, 42)
)
local walkStatus = makeLabel("目前移動速度：16", 60)

makeLabel("飛行速度（1～100000）", 87)
local flyBox = makeInput("飛行速度輸入", "50", 111)
local flyApply = makeButton(
	content, "套用飛行速度", "套用飛行速度",
	UDim2.fromOffset(155, 111),
	UDim2.new(1, -155, 0, 34),
	Color3.fromRGB(180, 30, 42)
)
local flyStatus = makeLabel("目前飛行速度：50", 147)

local flyToggle = makeButton(
	content, "飛行開關", "飛行：已關閉",
	UDim2.fromOffset(0, 176),
	UDim2.new(1, 0, 0, 36),
	Color3.fromRGB(42, 42, 46)
)
makeLabel("WASD 移動，鏡頭控制飛行方向", 218)

local walkSpeed = 16
local flySpeed = 50
local flying = false
local flightConnection
local oldAutoRotate
local oldPlatformStand
local oldRoot
local minimized = false

local function getCharacterParts()
	local character = player.Character
	if not character then return end
	return character,
		character:FindFirstChildOfClass("Humanoid"),
		character:FindFirstChild("HumanoidRootPart")
end

local function parseSpeed(box, status, label)
	local n = tonumber(box.Text)
	if not n or n < 1 or n > 100000 or n % 1 ~= 0 then
		status.Text = "請輸入 1～100000 的整數"
		return nil
	end
	status.Text = label .. "：" .. n
	return n
end

walkApply.Activated:Connect(function()
	local n = parseSpeed(walkBox, walkStatus, "目前移動速度")
	if not n then return end
	walkSpeed = n
	local _, h = getCharacterParts()
	if h then h.WalkSpeed = n end
end)

flyApply.Activated:Connect(function()
	local n = parseSpeed(flyBox, flyStatus, "目前飛行速度")
	if n then flySpeed = n end
end)

local function stopFlying()
	flying = false

	if flightConnection then
		flightConnection:Disconnect()
		flightConnection = nil
	end

	local _, h, root = getCharacterParts()
	if h then
		h.PlatformStand = oldPlatformStand or false
		h.AutoRotate = oldAutoRotate ~= false
	end

	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	oldRoot = nil
	flyToggle.Text = "飛行：已關閉"
	flyToggle.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
end

local function startFlying()
	local _, h, root = getCharacterParts()
	if not h or not root then
		flyStatus.Text = "找不到角色，請重新嘗試"
		return
	end

	oldAutoRotate = h.AutoRotate
	oldPlatformStand = h.PlatformStand
	oldRoot = root

	h.AutoRotate = false
	h.PlatformStand = true
	flying = true

	flyToggle.Text = "飛行：已開啟"
	flyToggle.BackgroundColor3 = Color3.fromRGB(150, 25, 35)

	flightConnection = RunService.Heartbeat:Connect(function()
		if not flying or not root.Parent then
			stopFlying()
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then return end

		local cf = camera.CFrame
		local direction = Vector3.zero

		if UIS:IsKeyDown(Enum.KeyCode.W) then
			direction += cf.LookVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then
			direction -= cf.LookVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) then
			direction += cf.RightVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then
			direction -= cf.RightVector
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit
		end

		root.AssemblyLinearVelocity = direction * flySpeed

		-- 角色水平面向鏡頭方向
		local look = Vector3.new(
			cf.LookVector.X,
			0,
			cf.LookVector.Z
		)

		if look.Magnitude > 0.001 then
			root.CFrame = CFrame.lookAt(
				root.Position,
				root.Position + look.Unit
			)
		end

		root.AssemblyAngularVelocity = Vector3.zero
	end)
end

flyToggle.Activated:Connect(function()
	if flying then
		stopFlying()
	else
		startFlying()
	end
end)

player.CharacterAdded:Connect(function(character)
	if flying then stopFlying() end
	local h = character:WaitForChild("Humanoid", 10)
	if h then h.WalkSpeed = walkSpeed end
end)

minimize.Activated:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	main.Size = minimized
		and UDim2.fromOffset(360, 42)
		or UDim2.fromOffset(360, 330)
	minimize.Text = minimized and "+" or "－"
end)

close.Activated:Connect(function()
	stopFlying()
	gui:Destroy()
end)

-- 拖曳視窗
local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

print("Harry Hub 已載入")
