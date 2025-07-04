local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local processed = {}
local queue = {}

local function addESP(model, nameText, color)
	if not model or not model:IsA("Model") or processed[model] then return end
	local root = model:FindFirstChild("HumanoidRootPart")
	local head = model:FindFirstChild("Head") or root
	if not head then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = color
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = model

	table.insert(queue, function()
		local tag = Instance.new("BillboardGui")
		tag.Name = "ESP_Name"
		tag.Adornee = head
		tag.Size = UDim2.new(0, 80, 0, 20)
		tag.StudsOffset = Vector3.new(0, 2.5, 0)
		tag.AlwaysOnTop = true

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = nameText
		label.TextColor3 = color
		label.TextScaled = false
		label.Font = Enum.Font.Arial
		label.TextSize = 14
		label.Parent = tag

		tag.Parent = model
	end)

	processed[model] = true
end

task.spawn(function()
	while true do
		local myChar = LocalPlayer.Character
		if myChar and myChar:FindFirstChild("HumanoidRootPart") then
			local myPos = myChar.HumanoidRootPart.Position

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and not processed[player.Character] then
					addESP(player.Character, player.Name, Color3.fromRGB(255, 165, 0))
				end
			end

			for _, model in ipairs(workspace:GetDescendants()) do
				if model:IsA("Model") and not processed[model] and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
					if not Players:GetPlayerFromCharacter(model) then
						local dist = (myPos - model.HumanoidRootPart.Position).Magnitude
						if dist < 500 then
							addESP(model, model.Name, Color3.fromRGB(255, 0, 0))
						end
					end
				end
			end
		end
		task.wait(1)
	end
end)

RunService.RenderStepped:Connect(function()
	if #queue > 0 then
		local add = table.remove(queue, 1)
		pcall(add)
	end
end)
