local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local gauges = script.Parent
local ts = game:GetService("TweenService")
local carSeat = gauges.Parent.CarSeat.Value
local car = carSeat.Parent
car.DriveSeat.HeadsUpDisplay = false

local tune = require(car["A-Chassis Tune"])
local values = gauges.Parent.Parent["A-Chassis Interface"].Values
local park = values:WaitForChild("Park")
local handler = car:WaitForChild('Handler')

local TWEEN_INFO = TweenInfo.new(.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, .5, false)
local COLOR_ECO = Color3.fromRGB(166, 255, 161)
local COLOR_POWER = Color3.fromRGB(255, 255, 255)
local COLOR_STOPPED = Color3.fromRGB(140, 140, 140)
local COLOR_ACTIVE = Color3.fromRGB(255, 147, 0)
local COLOR_DISABLED = Color3.fromRGB(255, 0, 0)

local mode = "Stopped"

-- Helpers
local function getMph()
	return math.floor(car.DriveSeat.Velocity.Magnitude * ((10 / 12) * (60 / 88)))
end

local function updateTac(setting)
	if mode == setting then return end
	mode = setting

	local targetColor = (setting == "Eco") and COLOR_ECO or (setting == "Power") and COLOR_POWER or COLOR_STOPPED
	ts:Create(gauges.Tac.Power, TWEEN_INFO, {ImageColor3 = targetColor}):Play()
end

local function updateGear(letter, gearVal, isReverse)
	handler:FireServer('Gear', letter, gearVal, park.Value)
	gauges.Main.Gear.Text = (letter == "S") and ("D " .. gearVal) or letter

	if isReverse ~= nil then
		car.DriveSeat.Lights:FireServer('updateLights', 'reverse', isReverse)
	end
end

local function updateLightUI()
	local isOn = carSeat.IsOn.Value
	local lightMode = carSeat.Values.Lights.LightMode.Value
	local main = gauges.Main

	if not isOn then
		main.Low.Visible = false
		main.Fogs.Visible = false
		main.AutoLights.Visible = false
		main.Eco.Visible = false
		return
	end

	main.Fogs.Visible = (lightMode == 1)
	main.Low.Visible = (lightMode == 2 or (lightMode == 3 and isOn))
	main.AutoLights.Visible = (lightMode == 3)
end

local function updateIndicator(element, isVisible, color)
	element.Visible = isVisible
	if isVisible and color then
		element.TextColor3 = color
	end
end

-- Events
values.Gear.Changed:Connect(function()
	local gearVal = values.Gear.Value
	local isAuto = (values.TransmissionMode.Value == "Auto")

	if gearVal > 0 then
		if isAuto and gearVal == 1 then
			updateGear('D', gearVal)
		elseif not isAuto then
			updateGear('S', gearVal)
		end
	elseif gearVal == 0 then
		local letter = (isAuto and park.Value) and 'P' or 'N'
		updateGear(letter, gearVal, false)
	elseif gearVal == -1 then
		updateGear('R', gearVal, true)
		task.wait(0.1)
	end
end)

values.Throttle.Changed:Connect(function()
	local throttle = values.Throttle.Value
	local mph = getMph()

	if throttle > 0.5 then
		updateTac("Power")
	else
		updateTac(mph < 0.3 and "Stopped" or "Eco")
	end
end)

values.RPM.Changed:Connect(function()
	handler:FireServer('RPM', values.RPM.Value)
end)

values.Velocity.Changed:Connect(function()
	
	local mph = getMph()
	gauges.Main.Speed.Text = tostring(mph)
	handler:FireServer('Speed', mph)

	local isHeld = (mph == 0 and values.Gear.Value ~= 0 and carSeat.Values.Safety.Brakehold.Value)
	values.BrakeHeld.Value = isHeld
	handler:FireServer('BRAKEHOLD', isHeld)
end)

carSeat.Values.Lights.LeftIndicator.Changed:Connect(function()
	gauges.Main.Left.Visible = carSeat.Values.Lights.LeftIndicator.Value
end)

carSeat.Values.Lights.RightIndicator.Changed:Connect(function()
	gauges.Main.Right.Visible = carSeat.Values.Lights.RightIndicator.Value
end)

carSeat.Values.Lights.LightMode.Changed:Connect(updateLightUI)
carSeat.IsOn.Changed:Connect(updateLightUI)

values.TCSActive.Changed:Connect(function() updateIndicator(gauges.Main.TCS, values.TCSActive.Value, COLOR_ACTIVE) end)
values.ABSActive.Changed:Connect(function() updateIndicator(gauges.Main.ABS, values.ABSActive.Value, COLOR_ACTIVE) end)
values.TCS.Changed:Connect(function() updateIndicator(gauges.Main.TCS, not values.TCS.Value, COLOR_DISABLED) end)
values.ABS.Changed:Connect(function() updateIndicator(gauges.Main.ABS, not values.ABS.Value, COLOR_DISABLED) end)
