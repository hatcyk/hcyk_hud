local maxRpm = Config.maxRpm
local maxSpeed = Config.maxSpeed
local throttleControlEnabled = Config.defaultSmoothing  -- Set based on defaultSmoothing
local allowedClasses = Config.allowedClasses

-- Odeslání stavu smooth control do UI
local function updateSmoothUI(state)
    SendNUIMessage({
        name = "smoothControl",
        active = state
    })
end

local function TriggerThrottleControl()
    updateSmoothUI(throttleControlEnabled)
    
    if not throttleControlEnabled then
        return
    end
    
    CreateThread(function()
        while throttleControlEnabled do
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local sleepDuration = 50
            if vehicle and DoesEntityExist(vehicle) then
                local vehicleClass = GetVehicleClass(vehicle)
                if allowedClasses[vehicleClass] then
                    local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6
                    local throttleOffset = math.abs(GetVehicleThrottleOffset(vehicle))
                    if throttleOffset > 0.3 and vehicleSpeed <= maxSpeed then
                        sleepDuration = 1
                        local currentRpm = GetVehicleCurrentRpm(vehicle)
                        if currentRpm > maxRpm then
                            SetVehicleCurrentRpm(vehicle, maxRpm)
                        end
                    end
                end
            end
            Wait(sleepDuration)
        end
    end)
end

-- Ujistit se, že tato funkce je viditelná a exportována

-- Přidat funkci pro získání stavu smooth throttle
function IsThrottleControlActive()
    return throttleControlEnabled or false
end

-- Export pro přístup z jiných modulů
exports('IsThrottleControlActive', IsThrottleControlActive)
RegisterCommand('+throttlecontrol', function()
    throttleControlEnabled = not Config.defaultSmoothing
    TriggerThrottleControl()
end, false)

RegisterCommand('-throttlecontrol', function()
    throttleControlEnabled = Config.defaultSmoothing
    TriggerThrottleControl()
end, false)

exports['I']:RegisterKeyMap('+throttlecontrol','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Plynulý rozjezd', '')