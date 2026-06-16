local F = {}
local BODY = script.Parent.Parent.Parent.Body.Lights
local VEHICLE = script.Parent.Parent.Parent
local MISC = VEHICLE.Misc
local TRUNK = MISC.Trunk

local DUSK = 17.58
local DAWN = 6.3

local BlinkersEnabled = true
local player = nil
local brake = false
local ts = game:GetService("TweenService")
local tunnel = false
local rain = false
local drl = false
local blinking = false
local b = nil

local night = game.Lighting.ClockTime >= DUSK or game.Lighting.ClockTime <= DAWN

-- helper functions to make my life easier

local function setEnabled(instances, bool)
	for i, inst in ipairs(instances) do
		if inst and inst:IsA("Light") then
			inst.Enabled = bool
		elseif inst and inst:FindFirstChild("Light") then
			inst.Light.Enabled = bool
		end
	end
end

local function setDescendantLights(parent, bool)
	for i, v in ipairs(parent:GetDescendants()) do
		if v:IsA("Light") then v.Enabled = bool end
	end
end

local function setTransparency(instances, val)
	for i, inst in ipairs(instances) do
		if inst:IsA("ParticleEmitter") then
			inst.Transparency = NumberSequence.new(val)
		else
			inst.Transparency = val
		end
	end
end

local function tweenLights(lights, brightness, tweenInfo)
	for i, light in ipairs(lights) do
		ts:Create(light, tweenInfo, {Brightness = brightness}):Play()
	end
end

local function setMatColor(instances, mat, color)
	for i, inst in ipairs(instances) do
		inst.Material = mat
		inst.Color = color
	end
end

local function setVertexColor(instances, color)
	for i, inst in ipairs(instances) do
		if inst:IsA("MeshPart") or inst:IsA("SpecialMesh") then
			inst.VertexColor = color
		elseif inst:FindFirstChild("Mesh") then
			inst.Mesh.VertexColor = color
		end
	end
end

-- end helper functs

-- main light functions

function updateLights2(lights, bool, tog)
	local BRAKEOFF = Color3.fromRGB(108, 21, 8)
	local BRAKEON = Color3.fromRGB(255, 0, 0)
	local RDRLOFF = Color3.fromRGB(117, 0, 0)
	local dsValues = VEHICLE.DriveSeat.Values.Lights

	if lights == 'brake' then
		brake = bool
		BODY.BrakeLight1.Color = bool and BRAKEON or BRAKEOFF
		BODY.BrakeLight2.Color = bool and BRAKEON or BRAKEOFF
		setTransparency({BODY.BrakeLight3, BODY.BrakeLight4}, bool and .3 or 1)

		for i, v in ipairs(BODY:GetChildren()) do
			if v.Name == "Brake" then v.Light.Enabled = bool end
		end

	elseif lights == 'beam' or lights == 'high' then
		local isHigh = (lights == 'high')
		local state = bool

		if isHigh then
			if not dsValues.Lights.Value then
				state = bool
			else
				state = not bool
			end
			setDescendantLights(BODY.HighBeam, bool)
			dsValues.Highbeams.Value = bool
		else
			dsValues.Lights.Value = bool
		end

		for i, v in ipairs(BODY.Headlights:GetChildren()) do
			if v.Name == "Light" then v.Light.Enabled = bool end
		end

		for i, v in ipairs(BODY.Headlights.HighBeamDetail:GetChildren()) do
			if v.Name == "Light" then v.Light.Enabled = isHigh and state or bool end
		end

		if not isHigh or (isHigh and not dsValues.Lights.Value) then
			for i, v in ipairs(BODY.Beam:GetChildren()) do
				if v.Name == "Beam1" or v.Name == "Beam2" then
					setEnabled({v.L1, v.L2, v.L3}, bool)
				elseif v.Name == "cutOff" then
					v.Transparency = bool and .746 or 1
				end
			end
			setTransparency({BODY.Beam.Particle.P1, BODY.Beam.Particle2.P1}, bool and 0 or 1)
		end

		local hbDetAlpha = (isHigh and state) and 0 or (bool and 0.7 or 1)
		if isHigh and dsValues.Lights.Value then
			hbDetAlpha = bool and 1 or 0.7
		end

		setTransparency({BODY.Beam.HBDet.Particle.P1, BODY.Beam.HBDet.Particle2.P1}, hbDetAlpha)

		if isHigh then
			setTransparency({BODY.HighBeam.Particle.P1, BODY.HighBeam.Particle2.P1}, bool and 0 or 1)
		end

	elseif lights == 'reverse' then
		local tweeninfo = TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, .5, false)
		local rev = TRUNK.Reverse

		tweenLights({rev.Main.Light, rev.Main2.Light}, bool and 60 or 0, tweeninfo)
		tweenLights({rev.RV1.Light, rev.RV2.Light, rev.RV3.Light, rev.RV4.Light}, bool and 35 or 0, tweeninfo)
		tweenLights({rev.Main.Light2, rev.Main2.Light2}, bool and 1.2 or 0, tweeninfo)

	elseif lights == 'parking' then
		setEnabled({
			BODY.RB1, BODY.RB1.Light2, BODY.RB2, BODY.RB2.Light2, BODY.FB, BODY.FB2, 
			TRUNK.RB1, TRUNK.RB1.Light2, TRUNK.RB2, TRUNK.RB2.Light2, BODY.PL1, BODY.PL2,
			MISC.FrontRight.Door.ButtonLight, MISC.RearRight.Door.ButtonLight, MISC.RearLeft.Door.ButtonLight
		}, bool)

		setMatColor({BODY.RearDRL, TRUNK.RearDRL, BODY.PLi}, bool and Enum.Material.Neon or Enum.Material.SmoothPlastic, bool and BRAKEON or RDRLOFF)

		setDescendantLights(BODY.intButtonLights, bool)
		setDescendantLights(MISC.FrontLeft.Door.IntLightup, bool)
		setDescendantLights(MISC.SteeringWheel.Lightups, bool)

		local vcOn = Vector3.new(4, 4, 10)
		local vcOff = Vector3.new(1, 1, 1)
		setVertexColor(BODY.Lightups:GetChildren(), bool and vcOn or vcOff)
		setVertexColor({MISC.FrontRight.Door.Lightup, MISC.RearLeft.Door.Lightup, MISC.RearRight.Door.Lightup, MISC.FrontLeft.Door.Lightup, MISC.SteeringWheel.Upper}, bool and vcOn or vcOff)
		MISC.SteeringWheel.Lower.Mesh.VertexColor = bool and vcOn or Vector3.new(0, 0, 0)

		dsValues.Parking.Value = bool
	end
end

F.updateLights = function(lights, bool, tog) 
	updateLights2(lights, bool, tog) 
end

-- blinkers

function toggle(dir, tog)
	local tweeninfo = TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, .5, false)
	local INDICATORON = Color3.fromRGB(255, 148, 26)
	local GREY = Color3.fromRGB(163, 162, 165)

	local function playIndicatorTweens(side)
		tweenLights({side.Main.Light}, tog and 45 or 0, tweeninfo)
		tweenLights({side.P1.Light, side.P2.Light}, tog and 14 or 0, tweeninfo)
		tweenLights({side.Main.Light2}, tog and 1.2 or 0, tweeninfo)
	end

	local function setDoorIndicator(door)
		door.Ind.Material = tog and Enum.Material.Neon or Enum.Material.SmoothPlastic
		door.Ind.Color = tog and INDICATORON or GREY
		door.INDL.Light.Enabled = tog
	end

	if dir == 'Left' or dir == 'Hazards' then
		playIndicatorTweens(BODY.RLeft)
		setDoorIndicator(MISC.FrontLeft.Door)
		VEHICLE.DriveSeat.Values.Lights.LeftIndicator.Value = tog
	end

	if dir == 'Right' or dir == 'Hazards' then
		playIndicatorTweens(BODY.RRight)
		setDoorIndicator(MISC.FrontRight.Door)
		VEHICLE.DriveSeat.Values.Lights.RightIndicator.Value = tog
	end

	if tog then
		if dir == 'Left' or dir == 'Hazards' then
			setMatColor({BODY.LDRL}, Enum.Material.Neon, INDICATORON)
			setDescendantLights(BODY.LDRLLight, true)
			for i, v in ipairs(BODY.LDRLLight:GetChildren()) do v.Light.Color = INDICATORON end
		end
		if dir == 'Right' or dir == 'Hazards' then
			setMatColor({BODY.RDRL}, Enum.Material.Neon, INDICATORON)
			setDescendantLights(BODY.RDRLLight, true)
			for i, v in ipairs(BODY.RDRLLight:GetChildren()) do v.Light.Color = INDICATORON end
		end
	else
		Runner(dir, VEHICLE.DriveSeat.Values.Lights.Parking.Value)
	end

	if dir == 'Hazards' then VEHICLE.DriveSeat.Values.Lights.Hazards.Value = tog end
end

function Runner(dir, tog)
	local DRLON = Color3.fromRGB(180, 201, 255)
	local DRLOFF = Color3.fromRGB(255, 255, 255)

	local function setDRL(drlBODY, drlLightsTable)
		if tog then
			setMatColor({drlBODY}, Enum.Material.Neon, DRLON)
			setDescendantLights(drlLightsTable, true)
			for i, v in ipairs(drlLightsTable:GetChildren()) do v.Light.Color = DRLON end
		else
			setDescendantLights(drlLightsTable, false)
			setMatColor({drlBODY}, Enum.Material.SmoothPlastic, DRLOFF)
		end
	end

	if dir == 'Left' or dir == 'Hazards' then setDRL(BODY.LDRL, BODY.LDRLLight) end
	if dir == 'Right' or dir == 'Hazards' then setDRL(BODY.RDRL, BODY.RDRLLight) end
end

function blink(typ)
	b = typ
	if blinking == true then
		blinking = false
	else
		blinking = true
		Runner(typ, false)
		while blinking do
			toggle(typ, true)
			script.Parent:FireClient(player, 'blink', .9, true)
			wait(1/4)
			toggle(typ, false)
			script.Parent:FireClient(player, 'blink', 0.8, true)
			wait(1/2)
		end
		toggle(typ, false)
		script.Parent:FireClient(player, 'blink', .9, false)
		if VEHICLE.DriveSeat.Power.Value then
			task.wait(1/9)
			Runner(typ, true)
		end
	end
end

F.blinkers = function(dir)
	blink(dir)
end

-- end blinkers

F.DRLs = function(bool)
	Runner('Hazards', bool)
end

-- headlight controls (with auto lowbeam setting)

F.lightMode = function()
	local lm = VEHICLE.DriveSeat.Values.Lights.LightMode
	lm.Value = (lm.Value + 1) % 4

	if lm.Value == 0 then
		updateLights2('beam', false)
		updateLights2('parking', false)
		updateLights2('high', false)
	elseif lm.Value == 1 then
		updateLights2('parking', true)
	elseif lm.Value == 2 then
		updateLights2('beam', true)
	elseif lm.Value == 3 and not tunnel and not VEHICLE.DriveSeat.Values.Rain.Value then
		nightLights(night and VEHICLE.DriveSeat.IsOn.Value)
	end
end

-- helper function

function nightLights(bool)
	if bool then
		updateLights2('beam', true)
		updateLights2('parking', true)
	else
		if VEHICLE.DriveSeat.Values.Lights.Lights.Value then
			updateLights2('high', false)
		end
		updateLights2('beam', false)
		updateLights2('parking', false)
	end
end

-- door lock lighting
VEHICLE.DriveSeat.Values.Locks.Doors.Changed:Connect(function()
	local locksOn = VEHICLE.DriveSeat.Values.Locks.Doors.Value
	local domeLights = VEHICLE.BODY["Dome Lights"].Script.Other

	if locksOn then
		domeLights.Value = true
		toggle('Hazards', true)
		task.wait(0.25)
		toggle('Hazards', false)

		if not VEHICLE.DriveSeat.IsOn.Value then
			task.wait(20)
			nightLights(false)
			Runner('Hazards', false)
		end
		task.wait(15)
		domeLights.Value = false
	else
		for i = 1, 2 do
			toggle('Hazards', true)
			task.wait(0.25)
			toggle('Hazards', false)
			if i == 1 then task.wait(0.25) end
		end
		task.wait(1/9)

		if night then nightLights(true) end

		domeLights.Value = true
		Runner('Hazards', true)
		task.wait(15)

		if not VEHICLE.DriveSeat.Power.Value then
			domeLights.Value = false
			Runner('Hazards', false)
			nightLights(false)
		end
	end
end)

script.Parent.Parent.ChildRemoved:Connect(function(child)
	if child:IsA("Weld") then
		if child.Part1 and child.Part1.Name == "HumanoidRootPart" then
			updateLights2('brake', false)
		end
		if BlinkersEnabled then
			if blinking and b == 'Hazards' then return end
			blinking = true
		end
	end
end)

-- automatic headlight events

F.tunnel = function(bool)
	tunnel = bool
	if tunnel then
		nightLights(true)
	elseif not night and VEHICLE.DriveSeat.IsOn.Value and not VEHICLE.DriveSeat.Values.Rain.Value then
		nightLights(false)
	end
end

F.rain = function(bool)
	VEHICLE.DriveSeat.Values.Rain.Value = bool
	VEHICLE.DriveSeat.Values.Wipers.Value = bool

	if VEHICLE.DriveSeat.Values.Lights.LightMode.Value == 3 and VEHICLE.DriveSeat.IsOn.Value and not tunnel then
		nightLights(bool or night)
	end
end

VEHICLE.DriveSeat.IsOn.Changed:Connect(function()
	local isOn = VEHICLE.DriveSeat.IsOn.Value
	if not isOn then VEHICLE.DriveSeat.Values.Wipers.Value = false end
	Runner('Hazards', isOn)

	if isOn then
		nightLights((night or VEHICLE.DriveSeat.Values.Rain.Value) and VEHICLE.DriveSeat.Values.Lights.LightMode.Value == 3)
	else
		nightLights(false)
		while VEHICLE.MISC.FrontLeft.Door.SS:WaitForChild("Motor6D").DesiredAngle == 0 do
			task.wait()
		end

		if night and VEHICLE.DriveSeat.Values.Lights.LightMode.Value == 3 then
			nightLights(true)
			Runner('Hazards', true)
			task.wait(20)

			if not VEHICLE.DriveSeat.IsOn.Value then
				Runner('Hazards', false)
				nightLights(false)
			end
		end
	end
end)

game.Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	night = game.Lighting.ClockTime >= DUSK or game.Lighting.ClockTime <= DAWN
	if VEHICLE.DriveSeat.Values.Lights.LightMode.Value == 3 and not tunnel and not VEHICLE.DriveSeat.Values.Rain.Value then
		nightLights(night and VEHICLE.DriveSeat.IsOn.Value)
	end
end)

VEHICLE.DriveSeat.Values.AlarmValues.Sound.Changed:Connect(function()
	local alarmOn = VEHICLE.DriveSeat.Values.AlarmValues.Sound.Value
	VEHICLE.DriveSeat.Horn.Alarm.Disabled = not alarmOn
	if not alarmOn then VEHICLE.DriveSeat.Horn:Stop() end
end)

VEHICLE.DriveSeat.Values.AlarmValues.Lights.Changed:Connect(function()
	if VEHICLE.DriveSeat.Values.AlarmValues.Lights.Value and not VEHICLE.DriveSeat.IsOn.Value then
		repeat
			toggle('Hazards', true)
			nightLights(true)
			task.wait(0.5)
			toggle('Hazards', false)
			nightLights(false)
			task.wait(0.5)
		until not VEHICLE.DriveSeat.Values.AlarmValues.Lights.Value
	end
end)

script.Parent.OnServerEvent:Connect(function(pl, Fnc, ...)
	player = pl
	if F[Fnc] then F[Fnc](...) end
end)
