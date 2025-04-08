local ESX = exports['es_extended']:getSharedObject()

-- Vehicle state
local vehicleCruiser = 'off'
local vehicleSignalIndicator = 'off'
local lastVehEngine = false
local lastVehCache = nil
local isVehicleSkidding = false

-- Vehicle classification
local vehicleClasses = {
    isHeli = false,
    isPlane = false,
    isBoat = false,
    isBike = false,
    isCar = false,
    isMotorcycle = false
}

-- Check vehicle type
function IdentifyVehicleType(veh)
    if not veh or (lastVehCache and lastVehCache == veh) then
        return
    end

    lastVehCache = veh
    
    -- Reset vehicle class flags
    for k in pairs(vehicleClasses) do
        vehicleClasses[k] = false
    end
    
    local vc = GetVehicleClass(veh)
    
    -- Nejprve zkontrolovat emergency vozidla (třída 18)
    if vc == 18 then
        vehicleClasses.isEmergency = true
        vehicleClasses.isCar = true -- Emergency vozidla jsou také auta
    elseif (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20) then
        vehicleClasses.isCar = true
    elseif vc == 8 then
        vehicleClasses.isMotorcycle = true
    elseif vc == 13 then
        vehicleClasses.isBike = true
    elseif vc == 14 then
        vehicleClasses.isBoat = true
    elseif vc == 15 then
        vehicleClasses.isHeli = true
    elseif vc == 16 then
        vehicleClasses.isPlane = true
    end
end

-- Engine control function
function ToggleEngine()
    local plyPed = PlayerPedId()
    
    if not IsPedInAnyVehicle(plyPed, false) then
        exports['okokNotify']:Alert('Hud', 'Nejsi ve vozidle', 3500, 'error')
        return
    end
    
    local plyVehicle = GetVehiclePedIsIn(plyPed, false)
    local vehicleSpeed = math.ceil(GetEntitySpeed(plyVehicle) * 3.6)
    
    if vehicleSpeed > 5 then
        exports['okokNotify']:Alert('Hud', 'Musíš stát na místě, abys vypnul motor', 3500, 'error')
        return
    end
    
    if GetIsVehicleEngineRunning(plyVehicle) then
        SetVehicleEngineOn(plyVehicle, false, false, true)
        SetVehicleUndriveable(plyVehicle, true)
        lastVehEngine = false
    else
        SetVehicleEngineOn(plyVehicle, true, false, true)
        SetVehicleUndriveable(plyVehicle, false)
        lastVehEngine = true
    end
end

-- Register key bindings for turn signals
exports['I']:RegisterKeyMap('blinkr_levy','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Levý blinkr',Config.keys.turnLeft)
exports['I']:RegisterKeyMap('blinkr_pravy','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Pravý blinkr',Config.keys.turnRight)
exports['I']:RegisterKeyMap('blinkr_vystrazne','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Výstražné světla',Config.keys.hazardLights)

-- Turn signal commands with sound effects
RegisterCommand("blinkr_levy", function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    
    -- Check if player is in a vehicle and is the driver
    if not IsPedInAnyVehicle(player, false) or GetPedInVehicleSeat(vehicle, -1) ~= player then
        return
    end
    
    -- Toggle state and play appropriate sound
    if vehicleSignalIndicator == 'off' then
        vehicleSignalIndicator = 'left'
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    else
        vehicleSignalIndicator = 'off'
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    end
    TriggerEvent('hcyk_hud:setCarSignalLights', vehicleSignalIndicator)
end)

RegisterCommand("blinkr_pravy", function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    
    -- Check if player is in a vehicle and is the driver
    if not IsPedInAnyVehicle(player, false) or GetPedInVehicleSeat(vehicle, -1) ~= player then
        return
    end
    
    -- Toggle state and play appropriate sound
    if vehicleSignalIndicator == 'off' then
        vehicleSignalIndicator = 'right'
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    else
        vehicleSignalIndicator = 'off'
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    end
    TriggerEvent('hcyk_hud:setCarSignalLights', vehicleSignalIndicator)
end)

RegisterCommand("blinkr_vystrazne", function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    
    -- Check if player is in a vehicle and is the driver
    if not IsPedInAnyVehicle(player, false) or GetPedInVehicleSeat(vehicle, -1) ~= player then
        return
    end
    
    -- Toggle state and play appropriate sound
    if vehicleSignalIndicator == 'off' then
        vehicleSignalIndicator = 'both'
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    else
        vehicleSignalIndicator = 'off'
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    end
    TriggerEvent('hcyk_hud:setCarSignalLights', vehicleSignalIndicator)
end)

-- Apply turn signals to vehicle
RegisterNetEvent('hcyk_hud:setCarSignalLights')
AddEventHandler('hcyk_hud:setCarSignalLights', function(status)
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    
    if not DoesEntityExist(vehicle) then return end
    
    -- Check if player is the driver
    if GetPedInVehicleSeat(vehicle, -1) ~= player then return end
    
    local hasTrailer, vehicleTrailer = GetVehicleTrailerVehicle(vehicle, vehicleTrailer)
    local targetVeh = hasTrailer and vehicleTrailer or vehicle
    local leftLight, rightLight
    
    if status == 'left' then
        leftLight = false
        rightLight = true
    elseif status == 'right' then
        leftLight = true
        rightLight = false
    elseif status == 'both' then
        leftLight = true
        rightLight = true
    else -- 'off'
        leftLight = false
        rightLight = false
    end
    
    SetVehicleIndicatorLights(targetVeh, 0, leftLight)
    SetVehicleIndicatorLights(targetVeh, 1, rightLight)
    
    -- Set vehicle state for all occupants
    local vehNetId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('hcyk_hud:syncCarLights', status, vehNetId)
end)

-- Receive synchronized turn signals
RegisterNetEvent('hcyk_hud:syncCarLights')
AddEventHandler('hcyk_hud:syncCarLights', function(driver, status)
    local target = GetPlayerFromServerId(driver)
    
    if not target or target == -1 or target == PlayerId() then
        return
    end
    
    local targetVehicle = GetVehiclePedIsIn(GetPlayerPed(target), false)
    if not DoesEntityExist(targetVehicle) then return end
    
    local leftLight, rightLight
    
    if status == 'left' then
        leftLight = false
        rightLight = true
    elseif status == 'right' then
        leftLight = true
        rightLight = false
    elseif status == 'both' then
        leftLight = true
        rightLight = true
    else -- 'off'
        leftLight = false
        rightLight = false
    end
    
    SetVehicleIndicatorLights(targetVehicle, 0, leftLight)
    SetVehicleIndicatorLights(targetVehicle, 1, rightLight)
end)

-- Handle vehicle damage events
AddEventHandler('gameEventTriggered', function(name, args)
    if name == "CEventNetworkEntityDamage" then
        local victim = args[1]
        local attacker = args[2]
        local weaponHash = args[7]
        local vehicleFlag = args[13]

        if GetEntityType(victim) == 2 and weaponHash == `WEAPON_STUNGUN` and vehicleFlag == 93 then
            if IsPedInAnyVehicle(attacker) then
                local coords = GetEntityCoords(attacker)
                SetEntityCoords(attacker, coords.x, coords.y, coords.z + 0.1)
            end
            SetPedToRagdollWithFall(attacker, 20000, 20000, 0, 1.0, 0.0, 0.0, 10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        end
    end

    if name == "CEventNetworkVehicleUndrivable" then
        local vehicle = args[1]
        local attacker = args[2]
        local weapon = args[3]

        if attacker == -1 and weapon == 0 then
            SetVehicleEngineHealth(vehicle, 1000)
            SetVehicleEngineOn(vehicle, true, true)
            SetVehicleFixed(vehicle)
        end
    end
end)

-- Handle vehicle state updates from server
RegisterNetEvent('hcyk_hud:syncVehicleState')
AddEventHandler('hcyk_hud:syncVehicleState', function(vehNetId, state)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    
    local player = PlayerPedId()
    if DoesEntityExist(vehicle) and IsPedInVehicle(player, vehicle, false) and GetPedInVehicleSeat(vehicle, -1) ~= player then
        if state.signals ~= nil then vehicleSignalIndicator = state.signals end
    end
end)

-- Add event handler
RegisterNetEvent('hcyk_hud:setSkiddingState')
AddEventHandler('hcyk_hud:setSkiddingState', function(skidding)
    isVehicleSkidding = skidding
    
    -- Send NUI message directly to update UI immediately
    SendNUIMessage({
        name = "skiddingState",
        isSkidding = skidding
    })
end)

-- Get vehicle state
function GetVehicleState()
    return {
        classes = vehicleClasses,
        cruiser = vehicleCruiser,
        signals = vehicleSignalIndicator,
        engine = lastVehEngine,
        skidding = isVehicleSkidding
    }
end

-- Set vehicle state
function SetVehicleState(state)
    if state.cruiser ~= nil then vehicleCruiser = state.cruiser end
    if state.signals ~= nil then vehicleSignalIndicator = state.signals end
    if state.engine ~= nil then lastVehEngine = state.engine end
end

-- Exports
exports('IdentifyVehicleType', IdentifyVehicleType)
exports('ToggleEngine', ToggleEngine)
exports('GetVehicleState', GetVehicleState)
exports('SetVehicleState', SetVehicleState)
exports('GetVehicleClasses', function() return vehicleClasses end)