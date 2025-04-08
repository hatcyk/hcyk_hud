local ESX = exports['es_extended']:getSharedObject()
local pedInVeh = false
local checkIsInVehicle = false

AddEventHandler("baseevents:enteredVehicle", function(veh) 
    DisplayRadar(true)
    pedInVeh = true
    exports["hcyk_hud"]:IdentifyVehicleType(veh)
    local engineState = false
    if IsVehicleDriveable(veh) then
        engineState = true
    end
    exports["hcyk_hud"]:SetVehicleState({
        cruiser = 'off',
        engine = engineState
    })
    exports["hcyk_hud"]:MonitorSeatbelt(veh)
    checkIsInVehicle = true
end)

AddEventHandler("baseevents:leftVehicle", function(veh)
    DisplayRadar(false)
    pedInVeh = false
    checkIsInVehicle = false
    local vehicleState = exports["hcyk_hud"]:GetVehicleState()
    if not IsControlPressed(0, 75) and DoesEntityExist(veh) and vehicleState.engine then
        SetVehicleEngineOn(veh, true, true, false)
    end
    if vehicleState.cruiser == 'on' then
        exports["hcyk_hud"]:ResetVehicleMaxSpeed(veh)
    end
    exports["hcyk_hud"]:SetVehicleState({
        cruiser = 'off',
        engine = false,
        signals = 'off'
    })
end)

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

RegisterNUICallback('getUIData', function(data, cb)
    -- Time
    local year, month, day, hour, minute = GetLocalTime()
    local currentTime = string.format("%02d:%02d", hour, minute)
    
    -- Control states
    local smoothActive = false
    local cruiseActive = false
    if exports["hcyk_hud"].IsThrottleControlActive ~= nil then
        smoothActive = exports["hcyk_hud"]:IsThrottleControlActive()
    end
    if exports["hcyk_hud"].IsCruiseControlActive ~= nil then
        cruiseActive = exports["hcyk_hud"]:IsCruiseControlActive()
    end
    
    cb({
        time = currentTime,
        controls = {
            smoothActive = smoothActive,
            cruiseActive = cruiseActive
        }
    })
end)

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
    if vehicleClass == 13 or vehicleClass == 15 or vehicleClass == 16 then
        return
    end
    local vehicleState = exports["hcyk_hud"]:GetVehicleState()
    local vehicleSpeed = GetEntitySpeed(vehicle) * 2.26
    if vehicleState.cruiser == 'on' then
        exports["hcyk_hud"]:SetVehicleState({ cruiser = 'off' })
        exports["hcyk_hud"]:ResetVehicleMaxSpeed(vehicle)
    else
        exports["hcyk_hud"]:SetVehicleState({ cruiser = 'on' })
        exports["hcyk_hud"]:LimitVehicleSpeed(vehicle, vehicleSpeed)
    end
end)

Citizen.CreateThread(function()
    local wasPauseMenuActive = false
    local lastTalkingState = false
    local checkInterval = 200 -- ms
    
    while true do
        -- Voice state
        local isTalking = NetworkIsPlayerTalking(PlayerId())
        if isTalking ~= lastTalkingState then
            SendNUIMessage({
                name = "voiceState",
                isTalking = isTalking
            })
            lastTalkingState = isTalking
        end
        
        -- Pause menu
        local isPauseMenuActive = IsPauseMenuActive()
        if isPauseMenuActive ~= wasPauseMenuActive then
            toggleHud(not isPauseMenuActive)
            exports['hcyk_main']:ToggleLogo(not isPauseMenuActive)
            wasPauseMenuActive = isPauseMenuActive
        end
        
        Citizen.Wait(checkInterval)
    end
end)

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
    AddStateBagChangeHandler('radioChannel', 'player:'..GetPlayerServerId(PlayerId()), function(bagName, key, value, _unused, replicated)
        SendNUIMessage({
            name = "voiceState",
            radioChannel = value or 0
        })
    end)
end

function toggleHud(display)
    if display == '' then display = true end
    uivisible = display
    SendNUIMessage({
        name = "hideHud",
        show = display
    })
end

exports('togglehud', toggleHud)
