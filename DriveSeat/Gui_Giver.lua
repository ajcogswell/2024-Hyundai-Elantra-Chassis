GUI = script.Parent.ScreenContent
GUI2 = script.Parent.RainHandler
car = script.Parent.Parent

function roundVector(vector, unit)
	return vector - Vector3.new(vector.X%unit, vector.Y%unit, vector.Z%unit)
end

script.Parent.ProximityPrompt.Triggered:Connect(function(plr)
	plr.Character.Humanoid.Sit = false
	script.Parent:Sit(plr.Character.Humanoid)
	script.Parent.ProximityPrompt.Enabled = false	
end)

script.Parent.Changed:Connect(function()
	if script.Parent.Occupant == nil then
		if script.Parent.Parent.Misc.FrontLeft.Door.SS:WaitForChild("Motor6D").DesiredAngle ~= 0 then
		script.Parent.ProximityPrompt.Enabled = true
		end
	end
end)

script.Parent.Parent.Misc.FrontLeft.Door.SS:WaitForChild("Motor6D").Changed:Connect(function()
	if script.Parent.Parent.Misc.FrontLeft.Door.SS:WaitForChild("Motor6D").DesiredAngle ~= 0 then
		if script.Parent.Occupant == nil then
			script.Parent.ProximityPrompt.Enabled = true
		end
	else
		script.Parent.ProximityPrompt.Enabled = false
	end
end)

script.Parent.ChildAdded:connect(function(child)
	if child:IsA("Weld") then
		if child.Part1 ~= nil and child.Part1.Name == "HumanoidRootPart" then
			player = game.Players:GetPlayerFromCharacter(child.Part1.Parent)
			if player and (not player.PlayerGui:FindFirstChild("Screen")) then --// The part after the "and" prevents multiple GUI's to be copied over.
				local clonedGUI = GUI:Clone()
				local clonedGUI2 = GUI2:Clone()
				clonedGUI.CarSeat.Value = script.Parent
				clonedGUI.Parent = player.PlayerGui
				clonedGUI2.CarSeat.Value = script.Parent
				clonedGUI2.Parent = player.PlayerGui
				script.Parent.Occupied.Value = true
				script.Parent.Values.AlarmValues.Lights.Value = false
				script.Parent.Values.AlarmValues.Sound.Value = false
				while car.Misc.FrontLeft.Door.SS.Motor6D.CurrentAngle ~= 0 do wait() end
				if car.DriveSeat.Power.Value == false then
				script.Parent.Welcome:Play()
				end
			end
		end
	end
end)

script.Parent.ChildRemoved:connect(function(child)
	if child:IsA("Weld") then
		if child.Part1.Name == "HumanoidRootPart" then
			game.Workspace.CurrentCamera.FieldOfView = 70
			player = game.Players:GetPlayerFromCharacter(child.Part1.Parent)
			if player and player.PlayerGui:FindFirstChild("ScreenContent") then
				player.PlayerGui:FindFirstChild("ScreenContent"):Destroy()
				player.PlayerGui:FindFirstChild("rainHandler"):Destroy()
				script.Parent.Occupied.Value = false
			end
		end
	end	
end)

while wait() do
	if script.Parent.Values.Locks.Doors.Value == true and script.Parent.Values.AlarmValues.Sound.Value == false then
		local p = roundVector(script.Parent.Position,0.5)
		wait(2)
		if roundVector(script.Parent.Position,0.5) ~= p and script.Parent.Power.Value == false and  script.Parent.Values.Locks.Doors.Value == true and script.Parent.Values.AlarmValues.Sound.Value == false then
			script.Parent.Values.AlarmValues.Lights.Value = true
			script.Parent.Values.AlarmValues.Sound.Value = true
		end
	end
end
