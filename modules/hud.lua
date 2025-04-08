local ESX = exports['es_extended']:getSharedObject()

local uivisible = Config.hud.defaultVisible
local lastMinimap = { x = 0, y = 0, ar = 0 }
local displayStreetsOnFoot = Config.hud.showStreetsOnFoot
local streetInfo = {
    compass = "",
    street = "",
    postal = "",
    time = ""
}

local healthThreshold = 25
local hungerThreshold = 25
local thirstThreshold = 25
local staminaThreshold = 25
local oxygenThreshold = 25
local lastArmorNotify = 0
local lastHealthNotify = 0
local lastHungerNotify = 0
local lastThirstNotify = 0
local lastStaminaNotify = 0
local lastOxygenNotify = 0
local notifyCooldown = 60000

local oxygenEffectActive = false
local cinematicMode = false

function toggleCinematicMode()
    cinematicMode = not cinematicMode
    SendNUIMessage({
        name = "cinematicMode",
        enabled = cinematicMode
    })
    
    -- Hide radar in cinematic mode
    DisplayRadar(not cinematicMode)
    
    local notifyType = cinematicMode and "success" or "info"
    local message = cinematicMode and "Cinematic mode zapnut" or "Cinematic mode vypnut"
    exports['okokNotify']:Alert('Hud', message, 3500, notifyType)
    
    -- If mode is disabled, update HUD again
    if not cinematicMode then
        updateHud()
    end
end

RegisterCommand("cinmode", function()
    toggleCinematicMode()
end, false)

function updateStreetInfo()
    local player = PlayerPedId()
    local position = GetEntityCoords(player)
    local heading = GetEntityHeading(player)
    streetInfo.compass = degreesToCardinalDirection(heading)
    local streetHash = GetStreetNameAtCoord(position.x, position.y, position.z)
    streetInfo.street = GetStreetNameFromHashKey(streetHash) or "Unknown"
    local lastDistance = 1000
    local nearestPostalIndex = 1
    for i = 1, #PostalConfig.postalCodes do
        local distance = #(position.xy - vector2(PostalConfig.postalCodes[i].x, PostalConfig.postalCodes[i].y))
        if distance < lastDistance then
            lastDistance = distance
            nearestPostalIndex = i
        end
    end
    streetInfo.postal = PostalConfig.postalCodes[nearestPostalIndex].code
    local year, month, day, hour, minute = GetLocalTime()
    streetInfo.time = string.format("%02d:%02d", hour, minute)
    return streetInfo
end

function updateHud()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    local vehicleInfo = {}
    local inVehicle = IsPedInAnyVehicle(player, false)
    if inVehicle then
        local vehicleState = exports["hcyk_hud"]:GetVehicleState()
        local vehicleClasses = exports["hcyk_hud"]:GetVehicleClasses()
        local seatbeltOn = exports["hcyk_hud"]:IsSeatbeltOn()
        local vehicleSpeed = math.ceil(GetEntitySpeed(vehicle) * 2.24)
        local rpm = GetVehicleCurrentRpm(vehicle)
        local vehicleGear = GetVehicleCurrentGear(vehicle)
        local vehicleFuel = Entity(vehicle).state.fuel or 100
        local vehicleDamage = GetVehicleEngineHealth(vehicle) / 10
        if (vehicleSpeed == 0 and vehicleGear == 0) or (vehicleSpeed == 0 and vehicleGear == 1) then
            vehicleGear = 'N'
        elseif vehicleSpeed > 0 and vehicleGear == 0 then
            vehicleGear = 'R'
        end
        local vehicleLightsState
        local _, vehicleLights, vehicleHighlights = GetVehicleLightsState(vehicle)
        if vehicleLights == 1 and vehicleHighlights == 0 then
            vehicleLightsState = 'normal'
        elseif (vehicleLights == 1 and vehicleHighlights == 1) or (vehicleLights == 0 and vehicleHighlights == 1) then
            vehicleLightsState = 'high'
        else
            vehicleLightsState = 'off'
        end
        if rpm >= 0.95 then
            rpm = math.random(105, 110) * 0.01
        end
        rpm = math.ceil(rpm * 10000)
        local streetInfoData = updateStreetInfo()
        local sirenState = 0
        local isEmergencyVehicle = false
        if vehicleClasses.isEmergency then
            isEmergencyVehicle = true
            local success, result = pcall(function()
                return exports["hcyk_hud"]:GetSirenState()
            end)
            if success and result then
                sirenState = result
            end
        end
        vehicleInfo = {
            updateVehicle = true,
            status = true,
            speed = vehicleSpeed,
            rpm = rpm,
            gear = vehicleGear,
            fuel = vehicleFuel,
            signals = vehicleState.signals,
            cruiser = vehicleState.cruiser,
            sirenState = sirenState,
            isEmergency = isEmergencyVehicle,
            skidding = vehicleState.skidding, -- Add skidding state
            time = streetInfoData.time,
            compass = streetInfoData.compass,
            dash = {
                seatbelt = seatbeltOn,
                haveBelt = vehicleClasses.isCar,
                lights = vehicleLightsState,
                damage = vehicleDamage,
            },
            location = streetInfoData.street,
            postal = streetInfoData.postal,
            config = {
                speedUnit = Config.vehicle.speedUnit,
                maxSpeed = Config.vehicle.maxSpeed
            }
        }
    else
        local streetInfoData = updateStreetInfo()
        vehicleInfo = {
            updateVehicle = true,
            status = false,
            seatbelt = { status = false },
            cruiser = 'off',
            signals = 'off',
            streets = displayStreetsOnFoot,
            location = displayStreetsOnFoot and streetInfoData.street or nil,
            compass = displayStreetsOnFoot and streetInfoData.compass or nil,
            postal = displayStreetsOnFoot and streetInfoData.postal or nil,
            time = displayStreetsOnFoot and streetInfoData.time or nil,
        }
    end
    SendNUIMessage({
        name = "updateCarhud",
        info = vehicleInfo,
    })
end

RegisterCommand("hud", function()
    uivisible = not uivisible
    SendNUIMessage({
        name = "hideHud",
        show = uivisible
    })
end)

RegisterCommand('streets', function()
    displayStreetsOnFoot = not displayStreetsOnFoot
    notify("info", (displayStreetsOnFoot and 'Enabled' or 'Disabled') .. ' street display')
end)

-- Using SetTimeout for minimap position instead of a continuous thread
function updateMinimapPosition()
    local x, y = GetActiveScreenResolution()
    local ar = GetAspectRatio(0)

    if lastMinimap.x ~= x or lastMinimap.y ~= y or lastMinimap.ar ~= ar then
        local minimap = GetMinimapAnchor()
        lastMinimap = {
            x = x,
            y = y,
            ar = ar
        }

        SendNUIMessage({
            name = "updatePosition",
            minimapX = minimap.x * x,
            minimapY = minimap.y * y,
            minimapWidth = minimap.width * x,
        })
    end
    
    SetTimeout(2000, updateMinimapPosition)
end

-- Start the minimap position updates
Citizen.CreateThread(function()
    Citizen.Wait(500)
    updateMinimapPosition()
end)

-- Main HUD update loop with dynamic wait times
Citizen.CreateThread(function()
    local baseInterval = Config.hud.updateInterval
    local longInterval = 1000
    
    while true do
        local waitTime = longInterval
        
        if uivisible then
            updateHud()
            waitTime = baseInterval
        end
        
        Citizen.Wait(waitTime)
    end
end)

-- Create variables to track damage timers
local lastHungerDamageTime = 0
local hungerDamageInterval = 30000 -- 30 seconds in milliseconds

-- Create notification cooldown timers
local lastHungerNotify = 0
local lastThirstNotify = 0
local lastHealthNotify = 0
local lastOxygenNotify = 0
local notifyCooldown = 60000 -- 60 seconds between notifications

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local player = PlayerPedId()
        local health = math.max(0, GetEntityHealth(player) - 100)
        local armor = GetPedArmour(player)
        if armor < 1 then armor = 0 end
        local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
        local oxygen = 100
        local isUnderwater = false
        
        if IsPedSwimmingUnderWater(player) then
            isUnderwater = true
            oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
            if oxygen < 0 then oxygen = 0 end
            
            if oxygen <= 15 and GetGameTimer() - lastOxygenNotify > notifyCooldown then
                exports['okokNotify']:Alert('Hud', 'Váš kyslík je kriticky nízký!', 4500, 'error')
                lastOxygenNotify = GetGameTimer()
            end
        end
        
        if health <= 20 and GetGameTimer() - lastHealthNotify > notifyCooldown then
            exports['okokNotify']:Alert('Hud', 'Jste vážně zraněn!', 4500, 'error')
            lastHealthNotify = GetGameTimer()
        end
        
        if ESX and ESX.GetPlayerData().job then
            TriggerEvent('esx_status:getStatus', 'hunger', function(hunger)
                local hungerPercent = hunger.getPercent()
                
                TriggerEvent('esx_status:getStatus', 'thirst', function(thirst)
                    local thirstPercent = thirst.getPercent()
                    local currentTime = GetGameTimer()
                    
                    if hungerPercent <= 5 then
                        if currentTime - lastHungerDamageTime >= hungerDamageInterval then
                            ApplyDamageToPed(player, 2, true)
                            lastHungerDamageTime = currentTime
                        end
                        
                        if currentTime - lastHungerNotify > notifyCooldown then
                            exports['okokNotify']:Alert('Hud', 'Hladovíte!', 4500, 'error')
                            lastHungerNotify = currentTime
                        end
                        
                        SetTimecycleModifier("drug_flying_base")
                        SendNUIMessage({
                            name = "statusEffect",
                            effect = "hunger",
                            level = "critical"
                        })
                    elseif hungerPercent <= 15 then
                        if currentTime - lastHungerDamageTime >= hungerDamageInterval then
                            ApplyDamageToPed(player, 1, true)
                            lastHungerDamageTime = currentTime
                        end
                        
                        if currentTime - lastHungerNotify > notifyCooldown * 1.5 then
                            exports['okokNotify']:Alert('Hud', 'Potřebujete se brzy najíst.', 4500, 'warning')
                            lastHungerNotify = currentTime
                        end
                        
                        SendNUIMessage({
                            name = "statusEffect",
                            effect = "hunger",
                            level = "severe"
                        })
                    elseif hungerPercent <= 25 and currentTime - lastHungerNotify > notifyCooldown * 2 then
                        exports['okokNotify']:Alert('Hud', 'Začínáte být hladový.', 4500, 'info')
                        lastHungerNotify = currentTime
                    end
                    
                    if thirstPercent <= 5 then
                        if currentTime - lastHungerDamageTime >= hungerDamageInterval then
                            ApplyDamageToPed(player, 2, true)
                        end
                        
                        if currentTime - lastThirstNotify > notifyCooldown then
                            exports['okokNotify']:Alert('Hud', 'Jste těžce dehydrovaní!', 4500, 'error')
                            lastThirstNotify = currentTime
                        end
                        
                        SendNUIMessage({
                            name = "statusEffect",
                            effect = "thirst",
                            level = "critical"
                        })
                    elseif thirstPercent <= 15 then
                        if currentTime - lastHungerDamageTime >= hungerDamageInterval then
                            ApplyDamageToPed(player, 1, true)
                        end
                        
                        if currentTime - lastThirstNotify > notifyCooldown * 1.5 then
                            exports['okokNotify']:Alert('Hud', 'Potřebujete si brzy něco napít.', 4500, 'warning')
                            lastThirstNotify = currentTime
                        end
                        
                        SendNUIMessage({
                            name = "statusEffect",
                            effect = "thirst",
                            level = "severe"
                        })
                    elseif thirstPercent <= 25 and currentTime - lastThirstNotify > notifyCooldown * 2 then
                        exports['okokNotify']:Alert('Hud', 'Začínáte být žízniví.', 4500, 'info')
                        lastThirstNotify = currentTime
                    end
                    
                    if hungerPercent > 15 and thirstPercent > 15 then
                        ClearTimecycleModifier()
                    end
                    
                    SendNUIMessage({
                        name = "hudTick",
                        show = not IsPauseMenuActive() and uivisible,
                        health = health,
                        armor = armor,
                        hunger = hungerPercent,
                        thirst = thirstPercent,
                        stamina = stamina,
                        oxygen = oxygen,
                        isUnderwater = isUnderwater
                    })
                end)
            end)
        end
    end
end)

CreateThread(function()
    Wait(1000)
    local minimap = RequestScaleformMovie("minimap")
    while not HasScaleformMovieLoaded(minimap) do
        Wait(0)
    end
    SetRadarBigmapEnabled(true, false)
    Wait(500)
    SetRadarBigmapEnabled(false, false)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    while true do
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
        Wait(500)
    end
end)

-- Apply screen shake effect with variable intensity
function applyScreenShake(intensity)
    local shakeIntensity = math.min(1.0, math.max(0.1, intensity))
    ShakeGameplayCam("DRUNK_SHAKE", shakeIntensity)
    SetTimecycleModifierStrength(shakeIntensity * 0.5)
    
    Citizen.CreateThread(function()
        local decayRate = 0.1
        while shakeIntensity > 0.05 do
            Citizen.Wait(500)
            shakeIntensity = shakeIntensity - decayRate
            ShakeGameplayCam("DRUNK_SHAKE", shakeIntensity)
            SetTimecycleModifierStrength(shakeIntensity * 0.5)
        end
        StopGameplayCamShaking(true)
    end)
end

exports('UpdateStreetInfo', updateStreetInfo)
exports('UpdateHud', updateHud)
exports('GetHudVisibility', function() return uivisible end)
exports('IsCinematicModeEnabled', function() return cinematicMode end)

exports['I']:RegisterKeyMap('hud','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Skrýt/zobrazit HUD', 'F11')
exports['I']:RegisterKeyMap('+hud:bigmap','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Velká mapa', 'LSHIFT')

RegisterCommand('+hud:bigmap', function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        SetBigmapActive(true, false)
        toggleHud(true)
        SendNUIMessage({
            name = "bigmap",
            active = true
        })
    end
end)

RegisterCommand('-hud:bigmap', function()
    SetBigmapActive(false, false)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        SendNUIMessage({
            name = "bigmap",
            active = false
        })
        updateHud()
    end
end)

RegisterCommand('sethunger', function(source, args, rawCommand)
    local hungerValue = tonumber(args[1])
    if hungerValue and hungerValue >= 0 and hungerValue <= 100 then
        TriggerEvent('esx_status:set', 'hunger', hungerValue * 10000)
        notify("success", "Hunger set to " .. hungerValue .. "%")
    else
        notify("error", "Invalid hunger value. Must be between 0 and 100.")
    end
end, false)

RegisterCommand('SetThirst', function(source, args, rawCommand)
    local thirstValue = tonumber(args[1])
    if thirstValue and thirstValue >= 0 and thirstValue <= 100 then
        TriggerEvent('esx_status:set', 'thirst', thirstValue * 10000)
        notify("success", "Thirst set to " .. thirstValue .. "%")
    else
        notify("error", "Invalid thirst value. Must be between 0 and 100.")
    end
end, false)

RegisterCommand('SetHealth', function(source, args, rawCommand)
    local healthValue = tonumber(args[1])
    if healthValue and healthValue >= 0 and healthValue <= 100 then
        SetEntityHealth(PlayerPedId(), healthValue + 100)
        notify("success", "Health set to " .. healthValue .. "%")
    else
        notify("error", "Invalid health value. Must be between 0 and 100.")
    end
end, false)

RegisterCommand('SetArmor', function(source, args, rawCommand)
    local armorValue = tonumber(args[1])
    if armorValue and armorValue >= 0 and armorValue <= 100 then
        SetPedArmour(PlayerPedId(), armorValue)
        notify("success", "Armor set to " .. armorValue .. "%")
    else
        notify("error", "Invalid armor value. Must be between 0 and 100.")
    end
end, false)