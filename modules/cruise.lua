-- Modern implementation of the cruise control system
-- Based on: https://github.com/hojgr/teb_speed_control/blob/master/client/speed_limiter.lua
-- Optimized for better performance and responsiveness

local activeVehicle = nil
local targetSpeed = nil
local toleranceThreshold = 2/3.6 -- Speed difference tolerance (2 km/h)
local lastForcedRpm = nil
local cruiseThread = nil

-- Check if speed limiting is active
function IsCruiseControlActive()
    return activeVehicle ~= nil
end

-- Main cruise control function to limit vehicle speed
function limitVehicleSpeed(vehicle, speed)
    if not speed then
        resetVehicleMaxSpeed(vehicle)
        return
    end

    if not DoesEntityExist(vehicle) then return end
    
    -- Convert MPH to m/s for internal calculations
    local speedMS = (tonumber(speed) or 0) * 0.44704
    
    activeVehicle = vehicle
    targetSpeed = speedMS
    
    -- First slow down if we're going too fast
    slowToTargetSpeed(vehicle, speedMS)
    
    -- Set the hard max speed limit
    SetVehicleMaxSpeed(vehicle, speedMS)
    
    -- Start the control thread if not already running
    if not cruiseThread then
        startCruiseThread()
    end
end

-- Start thread to monitor and control cruise speed
function startCruiseThread()
    cruiseThread = Citizen.CreateThread(function()
        while activeVehicle do
            local player = PlayerPedId()
            local currentVehicle = GetVehiclePedIsIn(player, false)
            
            -- Check if player changed vehicles or exited
            if currentVehicle ~= activeVehicle or not IsPedInVehicle(player, activeVehicle) then
                resetVehicleMaxSpeed(activeVehicle)
                activeVehicle = nil
                break
            end
            
            local currentSpeed = GetEntitySpeed(activeVehicle)
            local speedDiff = targetSpeed - currentSpeed
            
            -- When at max speed, gradually reduce RPM to maintain speed
            if speedDiff < toleranceThreshold then
                local rpm = GetVehicleCurrentRpm(activeVehicle)
                local newRpm
                
                if lastForcedRpm then
                    newRpm = lastForcedRpm - 0.03
                else
                    newRpm = rpm - 0.03
                end
                
                lastForcedRpm = newRpm
                
                -- Don't let RPM get too low
                if newRpm > 0.35 then
                    SetVehicleCurrentRpm(activeVehicle, newRpm)
                end
            else
                lastForcedRpm = nil
            end
            
            Citizen.Wait(0)
        end
        
        cruiseThread = nil
    end)
end

-- Smoothly slow down to target speed
function slowToTargetSpeed(vehicle, targetSpeed)
    local timeout = 4.0 -- Maximum slow down time
    local startTime = GetGameTimer()
    
    Citizen.CreateThread(function()
        while (GetGameTimer() - startTime) / 1000.0 < timeout do
            local currentSpeed = GetEntitySpeed(vehicle)
            
            -- If we're slower than target, stop slowing down
            if targetSpeed >= currentSpeed then
                return
            end
            
            -- Apply brakes gently
            SetControlNormal(0, 72, 1.0) -- Brake
            SetControlNormal(0, 71, 0.0) -- Throttle
            
            Citizen.Wait(0)
        end
    end)
end

-- Adjust cruise speed up or down
function adjustCruiseSpeed(increment)
    if not activeVehicle or not targetSpeed then return end
    
    -- Adjust by increment (in m/s)
    local newTargetSpeed = targetSpeed + (increment * 0.44704)
    limitVehicleSpeed(activeVehicle, newTargetSpeed / 0.44704) -- Convert back to MPH
end

-- Reset vehicle max speed
function resetVehicleMaxSpeed(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    activeVehicle = nil
    targetSpeed = nil
    lastForcedRpm = nil
    
    Citizen.Wait(10)
    
    -- Reset to vehicle's natural maximum speed
    local maxSpeed = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
    SetVehicleMaxSpeed(vehicle, maxSpeed)
end

-- Get the handling maximum speed
function GetVehicleHandlingMaxSpeed(vehicle)
    return GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
end

-- Export functions for external use
exports('IsCruiseControlActive', IsCruiseControlActive)
exports('LimitVehicleSpeed', limitVehicleSpeed)
exports('AdjustCruiseSpeed', adjustCruiseSpeed)
exports('ResetVehicleMaxSpeed', resetVehicleMaxSpeed)