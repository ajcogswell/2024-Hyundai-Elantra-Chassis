local f = {}
local ts = game:GetService("TweenService")
local car = script.Parent.Parent
local carSeat = car.DriveSeat
local misc = car.Misc
local values = carSeat.Values
local body = car.Body
local passengers = body.Passengers

local S_TWEEN = TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
local S_TWEEN_2 = TweenInfo.new(3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
local TWEEN_INFO_AMBIENT = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0.5, false)

local COLOR_BSM_ON = Color3.fromRGB(255, 127, 0)
local COLOR_BSM_OFF = Color3.fromRGB(0, 0, 0)
local COLOR_AMB_DEFAULT = Color3.fromRGB(0, 0, 255)

local sr = misc.Sunroof.SS:WaitForChild("Motor6D")
local shadeMotor = misc.SunShade.SS:WaitForChild("Motor6D")
local sh = misc.SunShade.Shade

local ORIG_C0 = sr.C0
local ORIG_C0_2 = shadeMotor.C0
local ORIG_Z = sh.Size.Z

local sunroofOpen = false
local sunshade = true
local busy = false
local tilt = false
local ambColor = COLOR_AMB_DEFAULT

local clickDetectors = {
    misc.FrontLeft.Door.H.ClickDetector,
    misc.FrontRight.Door.H.ClickDetector,
    misc.RearLeft.Door.H.ClickDetector,
    misc.RearRight.Door.H.ClickDetector,
    misc.Trunk.H.ClickDetector
}

-- Helpers
local function playTween(obj, info, props, waitToComplete)
    local t = ts:Create(obj, info, props)
    t:Play()
    if waitToComplete then t.Completed:Wait() end
    return t
end

local function setClickDistances(dist)
    for _, cd in ipairs(clickDetectors) do
        cd.MaxActivationDistance = dist
    end
end

local function updatePassengers(disabledState)
    for _, p in ipairs(passengers:GetChildren()) do
        if not p.Occupied.Value then
            p.Disabled = disabledState
        end
    end
end

-- Functions
f.updateWindows = function(window, toggle)
    local winVal = values.Windows:FindFirstChild(window)
    if winVal and carSeat.Power.Value then
        winVal.Value = toggle
    end
end

f.Trip = function(trip) carSeat.Trip.Value = trip end

f.valTog = function(value)
    for _, v in ipairs(carSeat:GetDescendants()) do
        if (v:IsA("BoolValue") or v:IsA("IntValue") or v:IsA("StringValue")) and v.Name == value then
            v.Value = not v.Value
        end
    end
end

f.driveMode = function(value) values.Drivemode.Value = value end
f.Trunk = function() misc.Trunk.Trunk.H.Trunk.Value = not misc.Trunk.Trunk.H.Trunk.Value end
f.BRAKEHOLD = function(bool) values.BrakeHeld.Value = bool end
f.BrakeHold = function() values.Brakehold.Value = not values.Brakehold.Value end

f.SunRoof = function(action)
    if busy then return end

    if action == 'Up' then
        if not sunroofOpen and not sunshade and not tilt then
            busy = true
            carSeat.Sunroof.Value = true
            task.wait(0.2)
            sr.DesiredAngle = -.073
            playTween(sr, S_TWEEN, { C0 = sr.C0 - Vector3.new(-1.61, 0, 0) }, true)
            sunroofOpen = true
            busy = false
        elseif sunshade and not sunroofOpen and not tilt then
            busy = true
            playTween(sh, S_TWEEN_2, { Size = Vector3.new(sh.Size.X, sh.Size.Y, 0.05) })
            playTween(shadeMotor, S_TWEEN_2, { C0 = shadeMotor.C0 - Vector3.new(0, -0.05, 2.3) }, true)
            sunshade = false
            busy = false
        end
    elseif action == 'Down' then
        if sunroofOpen then
            busy = true
            playTween(sr, S_TWEEN, { C0 = ORIG_C0 }, true)
            sr.DesiredAngle = 0
            sunroofOpen = false
            carSeat.Sunroof.Value = false
            busy = false
        elseif not sunshade and not sunroofOpen and not tilt then
            busy = true
            playTween(sh, S_TWEEN_2, { Size = Vector3.new(sh.Size.X, sh.Size.Y, ORIG_Z) })
            playTween(shadeMotor, S_TWEEN_2, { C0 = ORIG_C0_2 }, true)
            sunshade = true
            busy = false
        end
    elseif action == "Tilt" then
        if sunshade and not sunroofOpen and not tilt then
            busy = true
            playTween(sh, S_TWEEN_2, { Size = Vector3.new(sh.Size.X, sh.Size.Y, 0.05) })
            playTween(shadeMotor, S_TWEEN_2, { C0 = shadeMotor.C0 - Vector3.new(0, -0.05, 2.3) }, true)
            sr.DesiredAngle = -.09
            task.wait(1)
            tilt = true
            sunshade = false
            busy = false
        elseif not sunroofOpen and not sunshade and not tilt then
            busy = true
            sr.DesiredAngle = -.09
            task.wait(1)
            tilt = true
            busy = false
        elseif tilt and not sunroofOpen and not sunshade then
            busy = true
            sr.DesiredAngle = 0
            task.wait(1)
            tilt = false
            busy = false
        end
    end
end

f.ALARM = function()
    values.AlarmValues.Sound.Value = not values.AlarmValues.Sound.Value
    values.AlarmValues.Lights.Value = not values.AlarmValues.Lights.Value
end

f.Gear = function(t, gear, park)
    if gear >= 1 then
    elseif gear == 0 then
        if park then else end
    elseif gear == -1 then
    end
end

local function ambient(bool)
    local ambientFolder = body.Lights.Ambient

    for _, v in ipairs(ambientFolder:GetDescendants()) do
        if v.Name == "AMB" then
            playTween(v.Light, TWEEN_INFO_AMBIENT, { Brightness = bool and 1 or 0 })
        elseif v.Name == "AMB2" then
            playTween(v.Light, TWEEN_INFO_AMBIENT, { Brightness = bool and .3 or 0 })
        end
    end
    playTween(ambientFolder.AmbientStrip, TWEEN_INFO_AMBIENT, { Transparency = bool and 0 or 1 })
end

f.ambColor = function(color)
    if values.AmbCurrOn.Value then
        for _, v in ipairs(body.Lights.Ambient:GetDescendants()) do
            if v.Name == "Light" then v.Color = color end
        end
        local strip = body.Lights.Ambient.AmbientStrip
        if strip.Material == Enum.Material.Neon then
            strip.Color = color
            ambColor = color
        end
    end
end

f.updateGUI = function(place, bool)
    if (place == "FL" or place == "FR") and carSeat.Power.Value and carSeat.Values.Safety.BSM.Value then
        local targetDoor = (place == "FL") and misc.FrontLeft.Door or misc.FrontRight.Door
        targetDoor.BSM.Transparency = bool and 0 or 0.9
        targetDoor.BSM.Color = bool and COLOR_BSM_ON or COLOR_BSM_OFF
        targetDoor.BSM.Material = bool and Enum.Material.Neon or Enum.Material.SmoothPlastic
    elseif place == "AEB" then
        values.EB.Value = bool
    end
end

f.AEBoff = function() values.EB.Value = false end
f.Wipers = function() values.Wipers.Value = not values.Wipers.Value end

local function seatLocks(bool)
    values.Locks.Seats.Value = bool
    updatePassengers(bool)
    setClickDistances(bool and 0 or 16)
end

local function carLocked(bool)
    updatePassengers(bool)
    carSeat.Disabled = bool
    values.Locks.Doors.Value = bool
    setClickDistances(16)
end

f.carlocked = carLocked
f.seatlocks = seatLocks

values.Locks.Seats.Changed:Connect(seatLocks)
values.Locks.Doors.Changed:Connect(carLocked)

f.horn = function(v) carSeat.Horn.Playing = v end
values.Ambient.Changed:Connect(ambient)

f.Speed = function(speed)
    body.Dash.GaugeCluster.Cluster.G.Speedo.Rotation = -29 + ((speed / 160) * 244)
end

f.RPM = function(rpm)
    body.Dash.GaugeCluster.Cluster.G.Tach.Rotation = -29 + ((rpm / 8000) * 244)
end

f.carStarted = function(bool)
    body.Dash.GaugeCluster.Cluster.Enabled = bool
    body.Dash.Display.Infotainment.Enabled = bool
    body.Dash.GaugeCluster.Light.Enabled = bool
    body.Dash.Display.Light.Enabled = bool
    body["Dome Lights"].Script.Other.Value = false
    ambient(bool)
    carSeat.IsOn.Value = bool
    carSeat.Power.Value = bool
end

f.carStarting = function(bool) carSeat.Starting.Value = bool end

f.engineKill = function()
    carSeat.EngineStart:Stop()
    carSeat.EngineKill:Play()
    carSeat.Chime.Chime.ChimeStart.Value = false
    carSeat.IsOn.Value = false
    carSeat.Power.Value = false
end

f.updateValue = function(place, value) place.Value = value end

script.Parent.OnServerEvent:Connect(function(pl, fnc, ...)
    if f[fnc] then f[fnc](...) end
end)
