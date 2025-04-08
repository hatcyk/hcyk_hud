local ESX = exports['es_extended']:getSharedObject()

-- Core state
local pedInVeh = false
local checkIsInVehicle = false

-- Initialize application
Citizen.CreateThread(function()
    -- Wait for resources to load
    Citizen.Wait(1000)
    
    -- Initial HUD state setup
    exports["hcyk_hud"]:togglehud(true)
    
    -- Display radar only in vehicles
    DisplayRadar(false)
end)

-- Player loaded event
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    local streetInfo = exports["hcyk_hud"]:UpdateStreetInfo()
    
    SendNUIMessage({
        name = "hideHud",
        show = true
    })
    
    SendNUIMessage({
        name = "updateCarhud",
        info = {
            updateVehicle = true,
            status = false,
            streets = true,
            location = streetInfo.street,
            compass = streetInfo.compass,
            postal = streetInfo.postal,
            time = streetInfo.time
        }
    })
end)

-- Vehicle entry event
AddEventHandler("baseevents:enteredVehicle", function(veh) 
    DisplayRadar(true)
    pedInVeh = true

    -- Identify vehicle type
    exports["hcyk_hud"]:IdentifyVehicleType(veh)

    -- Set default engine state
    local engineState = false
    if IsVehicleDriveable(veh) then
        engineState = true
    end
    
    -- Update vehicle state
    exports["hcyk_hud"]:SetVehicleState({
        cruiser = 'off',
        engine = engineState
    })
    
    -- Start seatbelt monitoring
    exports["hcyk_hud"]:MonitorSeatbelt(veh)
    
    -- Set vehicle in use state
    checkIsInVehicle = true
end)

-- Vehicle exit event
AddEventHandler("baseevents:leftVehicle", function(veh)
    DisplayRadar(false)
    pedInVeh = false
    checkIsInVehicle = false
    
    -- Get vehicle state before exiting
    local vehicleState = exports["hcyk_hud"]:GetVehicleState()
    
    -- Keep engine running if not turning off with F
    if not IsControlPressed(0, 75) and DoesEntityExist(veh) and vehicleState.engine then
        SetVehicleEngineOn(veh, true, true, false)
    end
    
    -- Reset cruise control
    if vehicleState.cruiser == 'on' then
        exports["hcyk_hud"]:ResetVehicleMaxSpeed(veh)
    end
    
    -- Reset signals when exiting vehicle
    exports["hcyk_hud"]:SetVehicleState({
        cruiser = 'off',
        engine = false,
        signals = 'off'
    })
end)

-- Postal code command
RegisterCommand("pc", function(source, args)
    local postalCode = args[1]

    if postalCode then
        local found = false
        local targetCoords
        
        for i = 1, #PostalConfig.postalCodes do
            if PostalConfig.postalCodes[i].code == postalCode then
                targetCoords = vector2(PostalConfig.postalCodes[i].x, PostalConfig.postalCodes[i].y)
                found = true
                break
            end
        end

        if found then
            SetNewWaypoint(targetCoords.x, targetCoords.y)
            notify("info", "Postal code set to " .. postalCode)
        else
            notify("error", "Postal code not found")
        end
    else
        notify("error", "Invalid postal code")
    end
end, false)

RegisterNUICallback('hideRadar', function(data, cb)
    DisplayRadar(false)
    
    HideHudComponentThisFrame(1)
    HideHudComponentThisFrame(2)
    HideHudComponentThisFrame(3)
    HideHudComponentThisFrame(4)
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(13)
    HideHudComponentThisFrame(17)
    HideHudComponentThisFrame(20)
    
    cb({})
end)

RegisterNUICallback('getGameTime', function(data, cb)
    local year, month, day, hour, minute = GetLocalTime()
    local currentTime = string.format("%02d:%02d", hour, minute)

    cb({
        time = currentTime
    })
end)

function notify(type, message, duration)
    if not duration then
        duration = Config.notifications.duration
    end
    
    exports['okokNotify']:Alert('Hud', message, 4500, type)
end

RegisterCommand("cruiser", function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if not IsPedInAnyVehicle(playerPed, false) or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        return
    end

    local vehicleClass = GetVehicleClass(vehicle)
    
    -- Don't enable cruise for certain vehicle types
    if vehicleClass == 13 or vehicleClass == 15 or vehicleClass == 16 then
        return
    end

    local vehicleState = exports["hcyk_hud"]:GetVehicleState()
    local vehicleSpeed = GetEntitySpeed(vehicle) * 2.26 -- Convert to MPH
    
    if vehicleState.cruiser == 'on' then
        -- Turn off cruise control
        exports["hcyk_hud"]:SetVehicleState({ cruiser = 'off' })
        exports["hcyk_hud"]:ResetVehicleMaxSpeed(vehicle)
    else
        -- Turn on cruise control
        exports["hcyk_hud"]:SetVehicleState({ cruiser = 'on' })
        exports["hcyk_hud"]:LimitVehicleSpeed(vehicle, vehicleSpeed)
    end
end)

Citizen.CreateThread(function()
    while true do
        local isTalking = NetworkIsPlayerTalking(PlayerId())
        SendNUIMessage({
            name = "voiceState",
            isTalking = isTalking
        })
        Citizen.Wait(200) -- Check every 200ms
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        -- Check if cinematic mode is active
        local isCinematicMode = IsCinematicModeActive()

        -- Hide carhud if in cinematic mode
        SendNUIMessage({
            name = "hideHud",
            show = not isCinematicMode
        })
    end
end)

-- PMA-Voice integration
if GetResourceState("pma-voice") == "started" then
    AddEventHandler("pma-voice:setTalkingMode", function(mode)
        local voiceRange = 33
        if mode == 2 then
            voiceRange = 66
        elseif mode == 3 then
            voiceRange = 100
        end
        
        SendNUIMessage({
            name = "voiceState",
            voiceRange = voiceRange
        })
    end)
    
    AddEventHandler("pma-voice:radioActive", function(radioTalking)
        SendNUIMessage({
            name = "voiceState",
            isTalkingOnRadio = radioTalking
        })
    end)
    
    AddEventHandler("onResourceStart", function(resourceName)
        if resourceName ~= "pma-voice" then
            return
        end
        Wait(1000)
        
        local voiceRange = 33
        local mode = LocalPlayer.state.proximity.index
        if mode == 2 then
            voiceRange = 66
        elseif mode == 3 then
            voiceRange = 100
        end
        
        SendNUIMessage({
            name = "voiceState",
            voiceRange = voiceRange
        })
    end)
end