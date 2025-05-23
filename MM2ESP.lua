local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local ROLE_COLORS = {
	Murderer = Color3.fromRGB(255, 0, 0),
	Sheriff = Color3.fromRGB(0, 170, 255),
	Innocent = Color3.fromRGB(150, 150, 150),
	Gun = Color3.fromRGB(0, 255, 0),
}

local HITBOX_SIZES = {
	Murderer = Vector3.new(15, 15, 15),
	Sheriff = Vector3.new(15, 15, 15),
	Innocent = Vector3.new(10, 10, 10),
}

local espObjects = {}
local appliedHitboxes = {}
local hitboxEnabled = false

local function getRole(player)
	if player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife")) then
		return "Murderer"
	elseif player.Backpack:FindFirstChild("Gun") or (player.Character and player.Character:FindFirstChild("Gun")) then
		return "Sheriff"
	else
		return "Innocent"
	end
end

local function getMyRole()
	if LocalPlayer.Backpack:FindFirstChild("Knife") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Knife")) then
		return "Murderer"
	elseif LocalPlayer.Backpack:FindFirstChild("Gun") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")) then
		return "Sheriff"
	else
		return "Innocent"
	end
end

local function addESP(player)
	if espObjects[player] or not player.Character or not player.Character:FindFirstChild("Head") then return end

	local char = player.Character
	local highlight = Instance.new("Highlight")
	highlight.Name = "MM2ESP"
	highlight.Adornee = char
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = CoreGui

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RoleLabel"
	billboard.Size = UDim2.new(0, 200, 0, 40)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = char.Head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = "Innocent"
	label.Parent = billboard

	espObjects[player] = {
		Highlight = highlight,
		Label = label,
	}
end

local function removeESP(player)
	if espObjects[player] then
		if espObjects[player].Highlight then espObjects[player].Highlight:Destroy() end
		espObjects[player] = nil
	end
	if player.Character and player.Character:FindFirstChild("Head") then
		local old = player.Character.Head:FindFirstChild("RoleLabel")
		if old then old:Destroy() end
	end
end

local function updateESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			addESP(player)
			local role = getRole(player)
			local data = espObjects[player]
			if data then
				data.Highlight.Adornee = player.Character
				data.Highlight.FillColor = ROLE_COLORS[role]
				data.Highlight.OutlineColor = ROLE_COLORS[role]
				data.Label.Text = role
				data.Label.TextColor3 = ROLE_COLORS[role]
			end
		else
			removeESP(player)
		end
	end
end

local function showDroppedGun()
	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("Tool") and item.Name == "GunDrop" and not item:FindFirstChild("ESP") then
			local part = item:FindFirstChildWhichIsA("BasePart")
			if part then
				local hl = Instance.new("Highlight")
				hl.Name = "ESP"
				hl.Adornee = part
				hl.FillColor = ROLE_COLORS.Gun
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = item

				local billboard = Instance.new("BillboardGui")
				billboard.Name = "GunLabel"
				billboard.Size = UDim2.new(0, 100, 0, 40)
				billboard.StudsOffset = Vector3.new(0, 2, 0)
				billboard.AlwaysOnTop = true
				billboard.Parent = part

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.TextColor3 = ROLE_COLORS.Gun
				label.TextStrokeTransparency = 0
				label.TextScaled = true
				label.Text = "Gun"
				label.Font = Enum.Font.SourceSansBold
				label.Parent = billboard
			end
		end
	end
end

local function applyHitbox(player, size)
	local char = player.Character
	if not char or appliedHitboxes[player] then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	hrp.Size = size
	hrp.CanCollide = false
	hrp.Transparency = 0.75
	hrp.Material = Enum.Material.ForceField

	local highlight = Instance.new("Highlight")
	highlight.Name = "HitboxESP"
	highlight.Adornee = hrp
	highlight.FillColor = Color3.fromRGB(0, 255, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = hrp

	appliedHitboxes[player] = true
end

local function updateHitboxes()
	if not hitboxEnabled then return end
	local myRole = getMyRole()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local role = getRole(player)
			if myRole == "Murderer" and (role == "Sheriff" or role == "Innocent") then
				applyHitbox(player, HITBOX_SIZES[role])
			elseif myRole == "Sheriff" and role == "Murderer" then
				applyHitbox(player, HITBOX_SIZES.Murderer)
			end
		end
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	for _, data in pairs(espObjects) do
		if data.Highlight then data.Highlight:Destroy() end
	end
	espObjects = {}
	appliedHitboxes = {}
end)

RunService.RenderStepped:Connect(function()
	updateESP()
	showDroppedGun()
	updateHitboxes()
end)

local toggleButton = Instance.new("ScreenGui", CoreGui)
toggleButton.Name = "HitboxToggleUI"

local frame = Instance.new("TextButton")
frame.Size = UDim2.new(0, 160, 0, 50)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.Text = "Hitbox Expander: OFF"
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.TextColor3 = Color3.fromRGB(255, 255, 255)
frame.BorderSizePixel = 0
frame.Font = Enum.Font.SourceSansBold
frame.TextSize = 18
frame.Draggable = true
frame.Active = true
frame.Parent = toggleButton

frame.MouseButton1Click:Connect(function()
	hitboxEnabled = not hitboxEnabled
	frame.Text = hitboxEnabled and "Hitbox Expander: ON" or "Hitbox Expander: OFF"
end)
