task.wait(0.1)

local openControls = Enum.KeyCode.G
local car = script.Parent.Parent:WaitForChild("CarSeat").Value.Parent
local UserInputService = game:GetService("UserInputService")

local isOpen = false

local function onInput(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.KeyCode == openControls then
		isOpen = not isOpen
		local targetX = isOpen and 0.023 or -0.2
		script.Parent:TweenPosition(UDim2.new(targetX, 0, 0.558, 0), "InOut", "Quint", 1, true)
	end
end

local colorKeypointsOn = {
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.652, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.747, Color3.fromRGB(213, 255, 213)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(213, 255, 213))
}

local colorKeypointsOff = {
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.652, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.747, Color3.fromRGB(255, 213, 213)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 213, 213))
}

for i, v in ipairs(script.Parent.Main.DrivemodeFrame.DM:GetDescendants()) do
	if v:IsA("TextButton") then
		local settingName = v.Name
		v.MouseButton1Click:Connect(function()
			car.Handler:FireServer("driveMode", settingName)
		end)
	end
end

for i, v in ipairs(script.Parent.Main.SafetyFrame.Frame:GetDescendants()) do
	if v:IsA("TextButton") then
		local settingName = v.Parent.Name
		local safetyValue = car.DriveSeat.Values.Safety:FindFirstChild(settingName)
		local uiGradient = v.Parent:FindFirstChild("UIGradient")

		if safetyValue and uiGradient then

			local function updateGradientColor(isOn)
				if isOn then
					uiGradient.Color = ColorSequence.new(colorKeypointsOn)
					v.Text = "On"
				else
					uiGradient.Color = ColorSequence.new(colorKeypointsOff)
					v.Text = "Off"
				end
			end

			updateGradientColor(safetyValue.Value)

			v.MouseButton1Click:Connect(function()
				car.Handler:FireServer("valTog", settingName)
			end)

			safetyValue.Changed:Connect(function(newValue)
				updateGradientColor(newValue)
			end)
		end
	end
end

script.Parent.Main.WindowFrame.Center.Tilt.MouseButton1Click:Connect(function()
	car.Handler:FireServer("SunRoof", "Tilt")
end)

script.Parent.Main.WindowFrame.Center.Open.MouseButton1Click:Connect(function()
	car.Handler:FireServer("SunRoof", "Up")
end)

script.Parent.Main.WindowFrame.Center.Close.MouseButton1Click:Connect(function()
	car.Handler:FireServer("SunRoof", "Down")
end)

UserInputService.InputBegan:Connect(onInput)
