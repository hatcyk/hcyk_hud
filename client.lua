local ESX = exports['es_extended']:getSharedObject()

-- Core HUD state
local uivisible = true
local lastMinimap = { x = 0, y = 0, ar = 0 }
local pedInVeh = false
local displayStreetsOnFoot = false
local checkIsInVehicle = false
local vehicleCruiser = 'off'
local vehicleSignalIndicator = 'off'
local streetInfo = {
    compass = "",
    street = "",
    postal = "",
    time = ""
}

-- Vehicle state
local seatbeltIsOn = false
local engineon = true
local lastVehEngine = false
local lastVehCache = nil

-- Vehicle classification
local vehicleClasses = {
    isHeli = false,
    isPlane = false,
    isBoat = false,
    isBike = false,
    isCar = false,
    isMotorcycle = false
}

-- Update minimap position when resolution changes
Citizen.CreateThread(function()
    Citizen.Wait(500)

    while true do
        local minimap = GetMinimapAnchor()
        local x, y = GetActiveScreenResolution()
        local ar = GetAspectRatio(0)

        if lastMinimap.x ~= x or lastMinimap.y ~= y or lastMinimap.ar ~= ar then
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

        Citizen.Wait(2000)
    end
end)

-- Player loaded event handler
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    uivisible = true
    SendNUIMessage({
        name = "hideHud",
        show = true
    })
end)

-- Check vehicle type
local function identifyVehicleType(veh)
    if not veh or (lastVehCache and lastVehCache == veh) then
        return
    end

    lastVehCache = veh
    
    -- Reset vehicle class flags
    for k in pairs(vehicleClasses) do
        vehicleClasses[k] = false
    end
    
    local vc = GetVehicleClass(veh)
    
    if (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20) then
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

-- Toggle HUD visibility
RegisterCommand("hud", function()
    uivisible = not uivisible
    SendNUIMessage({
        name = "hideHud",
        show = uivisible
    })
end)

-- Vehicle events
AddEventHandler("baseevents:enteredVehicle", function(veh) 
    DisplayRadar(true)
    pedInVeh = true

    if IsVehicleDriveable(veh) then
        lastVehEngine = true
    end

    monitorVehicleState()
end)

AddEventHandler("baseevents:leftVehicle", function(veh)
    DisplayRadar(false)
    pedInVeh = false
    checkIsInVehicle = false
    vehicleClasses = {isHeli = false, isPlane = false, isBoat = false, isBike = false, isCar = false, isMotorcycle = false}

    if not IsControlPressed(0, 75) and DoesEntityExist(veh) and lastVehEngine then
        SetVehicleEngineOn(veh, true, true, false)
    end
    lastVehEngine = false
    
    if vehicleCruiser == 'on' then
        limitVehicleSpeed(veh, nil)
    end
    vehicleCruiser = 'off'
end)

-- Key mapping for big map
RegisterKeyMapping('+tgr:bigmap', "Toggle big map view", 'KEYBOARD', 'LSHIFT')
RegisterCommand('+tgr:bigmap', function()
    if pedInVeh then
        SetBigmapActive(true, false)
        uivisible = false
        SendNUIMessage({
            name = "updateCarhud",
            info = {
                updateVehicle = true,
                status = false,
            },
        })
    end
end)
RegisterCommand('-tgr:bigmap', function()
    SetBigmapActive(false, false)
    uivisible = true
    if pedInVeh then
        updateHud()
    end
end)

-- Engine control function
function ToggleEngine()
    local plyPed = PlayerPedId()
    
    if not IsPedInAnyVehicle(plyPed, false) then
        exports['okokNotify']:Alert('Server', 'You are not in a vehicle', 3500, 'error')
        return
    end
    
    local plyVehicle = GetVehiclePedIsIn(plyPed, false)
    local vehicleSpeed = math.ceil(GetEntitySpeed(plyVehicle) * 3.6)
    
    if vehicleSpeed > 5 then
        exports['okokNotify']:Alert('Server', 'You must be stationary to turn off the engine', 3500, 'error')
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
exports('ToggleEngine', ToggleEngine)

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

-- Main HUD update loop
Citizen.CreateThread(function()
    while true do
        if uivisible then
            updateHud()
            Citizen.Wait(150)
        else
            Citizen.Wait(1000)
        end
    end
end)

-- Update HUD with current state
function updateHud()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    local position = GetEntityCoords(player)
    local vehicleInfo = {}

    if IsPedInAnyVehicle(player, false) then
        identifyVehicleType(vehicle)

        -- Basic vehicle data
        local vehicleSpeed = math.ceil(GetEntitySpeed(vehicle) * 2.24) -- MPH
        local rpm = GetVehicleCurrentRpm(vehicle)
        local vehicleGear = GetVehicleCurrentGear(vehicle)
        local vehicleFuel = Entity(vehicle).state.fuel or 100
        
        -- Calculate damage
        local vehicleDamage = GetVehicleEngineHealth(vehicle) / 10

        -- Handle gear display
        if (vehicleSpeed == 0 and vehicleGear == 0) or (vehicleSpeed == 0 and vehicleGear == 1) then
            vehicleGear = 'N'
        elseif vehicleSpeed > 0 and vehicleGear == 0 then
            vehicleGear = 'R'
        end
        
        -- Get vehicle lights state
        local vehicleLightsState
        local _, vehicleLights, vehicleHighlights = GetVehicleLightsState(vehicle)
        
        if vehicleLights == 1 and vehicleHighlights == 0 then
            vehicleLightsState = 'normal'
        elseif (vehicleLights == 1 and vehicleHighlights == 1) or (vehicleLights == 0 and vehicleHighlights == 1) then
            vehicleLightsState = 'high'
        else
            vehicleLightsState = 'off'
        end
        
        -- Handle seatbelt logic for cars
        if vehicleClasses.isCar then
            local prevSpeed = currSpeed
            currSpeed = GetEntitySpeed(vehicle)

            SetPedConfigFlag(player, 32, true)

            if not seatbeltIsOn then
                -- Allow F to exit when seatbelt is off
                DisableControlAction(0, 75, false)
                
                -- Store velocity for potential ejection
                prevVelocity = GetEntityVelocity(vehicle)
            else
                -- Prevent F from exiting when seatbelt is on
                DisableControlAction(0, 75, true)
            end
        end
        
        -- Format RPM for display (0-10000 range)
        if rpm >= 0.95 then
            rpm = math.random(105, 110) * 0.01
        end
        rpm = math.ceil(rpm * 10000)

        -- Update location information
        updateStreetInfo()
        
        -- Prepare vehicle info for UI
        vehicleInfo = {
            updateVehicle = true,
            status = true,
            speed = vehicleSpeed,
            rpm = rpm,
            gear = vehicleGear,
            fuel = vehicleFuel,
            signals = vehicleSignalIndicator,
            cruiser = vehicleCruiser,
            time = streetInfo.time,
            compass = streetInfo.compass,
            dash = {
                seatbelt = seatbeltIsOn,
                haveBelt = vehicleClasses.isCar,
                lights = vehicleLightsState,
                damage = vehicleDamage,
            },
            location = streetInfo.street,
            postal = streetInfo.postal,
            config = {
                speedUnit = Config.vehicle.speedUnit,
                maxSpeed = Config.vehicle.maxSpeed
            }
        }
    else
        -- Reset vehicle states when out of vehicle
        vehicleCruiser = 'off'
        seatbeltIsOn = false
        
        -- Update location info if on foot display is enabled
        updateStreetInfo()
        
        vehicleInfo = {
            updateVehicle = true,
            status = false,
            seatbelt = { status = false },
            cruiser = 'off',
            signals = 'off',
            streets = displayStreetsOnFoot,
            location = displayStreetsOnFoot and streetInfo.street or nil,
            compass = displayStreetsOnFoot and streetInfo.compass or nil,
            postal = displayStreetsOnFoot and streetInfo.postal or nil,
            time = displayStreetsOnFoot and streetInfo.time or nil,
        }
        
        Citizen.Wait(1000) -- Reduce update frequency when not in vehicle
    end
    
    -- Send updated vehicle info to UI
    SendNUIMessage({
        name = "updateCarhud",
        info = vehicleInfo,
    })
end

-- Update street name, compass direction, postal code and time
function updateStreetInfo()
    local player = PlayerPedId()
    local position = GetEntityCoords(player)
    local heading = GetEntityHeading(player)
    
    streetInfo.compass = getCardinalDirection(heading)
    
    local streetHash = GetStreetNameAtCoord(position.x, position.y, position.z)
    streetInfo.street = GetStreetNameFromHashKey(streetHash) or "Unknown"
    
    local lastDistance = 1000
    for i = 1, #PostalConfig.postalCodes do
        local distance = #(position.xy - vector2(PostalConfig.postalCodes[i].x, PostalConfig.postalCodes[i].y))
        if distance < lastDistance then
            lastDistance = distance
            nearestPostalIndex = i
        end
    end
    
    streetInfo.postal = PostalConfig.postalCodes[nearestPostalIndex].code
end

-- Key bindings for vehicle functions
RegisterKeyMapping("seatbelt", "Toggle seatbelt", "KEYBOARD", "b")
RegisterKeyMapping("cruiser", "Toggle speed limiter", "KEYBOARD", "m")
RegisterKeyMapping("blinkr_levy", "Left turn signal", "KEYBOARD", "LEFT")
RegisterKeyMapping("blinkr_pravy", "Right turn signal", "KEYBOARD", "RIGHT")
RegisterKeyMapping("blinkr_vystrazne", "Hazard lights", "KEYBOARD", "DOWN")

-- Seatbelt toggle command
RegisterCommand("seatbelt", function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if not IsPedInAnyVehicle(playerPed, false) then return end
    
    identifyVehicleType(vehicle)

    if vehicleClasses.isCar or vehicleClasses.isPlane or vehicleClasses.isHeli then
        seatbeltIsOn = not seatbeltIsOn
        
        -- Play sound
        if seatbeltIsOn then
            if Config.vehicle.seatbelt.playBuckleSound then
                PlaySoundFrontend(-1, "Faster_Click", "RESPAWN_ONLINE_SOUNDSET", 1)
            end
        else
            if Config.vehicle.seatbelt.playUnbuckleSound then
                PlaySoundFrontend(-1, "Faster_Click", "RESPAWN_ONLINE_SOUNDSET", 1)
            end
        end
    end
end)

-- Cruise control toggle command
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

    local vehicleSpeed = GetEntitySpeed(vehicle) * 2.26 -- Convert to MPH
    
    if vehicleCruiser == 'on' then
        vehicleCruiser = 'off'
        limitVehicleSpeed(vehicle, nil)
    else
        vehicleCruiser = 'on'
        limitVehicleSpeed(vehicle, vehicleSpeed)
    end
end)

-- Turn signal commands
RegisterCommand("blinkr_levy", function()
    if vehicleSignalIndicator == 'off' then
        vehicleSignalIndicator = 'left'
    else
        vehicleSignalIndicator = 'off'
    end
    TriggerEvent('tgr:setCarSignalLights', vehicleSignalIndicator)
end)

RegisterCommand("blinkr_pravy", function()
    if vehicleSignalIndicator == 'off' then
        vehicleSignalIndicator = 'right'
    else
        vehicleSignalIndicator = 'off'
    end
    TriggerEvent('tgr:setCarSignalLights', vehicleSignalIndicator)
end)

RegisterCommand("blinkr_vystrazne", function()
    if vehicleSignalIndicator == 'off' then
        vehicleSignalIndicator = 'both'
    else
        vehicleSignalIndicator = 'off'
    end
    TriggerEvent('tgr:setCarSignalLights', vehicleSignalIndicator)
end)

-- Apply turn signals to vehicle
AddEventHandler('tgr:setCarSignalLights', function(status)
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
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
    
    -- Synchronize with other players
    TriggerServerEvent('tgr:syncCarLights', status)
end)

-- Receive synchronized turn signals
RegisterNetEvent('tgr:syncCarLights')
AddEventHandler('tgr:syncCarLights', function(driver, status)
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

-- Monitor vehicle state
function monitorVehicleState()
    checkIsInVehicle = true

    Citizen.CreateThread(function()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        while checkIsInVehicle do
            -- Handle engine state
            if not engineon then
                SetVehicleEngineOn(veh, false, false, false)
                SetVehicleUndriveable(veh, false, false, false)
            end

            -- Disable exit controls when seatbelt is on
            if seatbeltIsOn then 
                DisableControlAction(0, 75, true)  -- Disable F
                DisableControlAction(27, 75, true) -- Disable F while driving
            end

            Citizen.Wait(0)
        end
    end)
end

-- Postal code command
RegisterCommand("pc", function(source, args)
    local postalCode = args[1]

    if postalCode then
        setWaypointToPostal(postalCode)
    else
        notifyPlayer("error", "Invalid postal code")
    end
end, false)

-- Set waypoint to postal code
function setWaypointToPostal(postalCode)
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
        notifyPlayer("info", "Postal code set to " .. postalCode)
    else
        notifyPlayer("error", "Postal code not found")
    end
end

-- Toggle street names display
RegisterCommand('streets', function()
    displayStreetsOnFoot = not displayStreetsOnFoot
    notifyPlayer("info", (displayStreetsOnFoot and 'Enabled' or 'Disabled') .. ' street display')
end)

-- Toggle HUD visibility
RegisterCommand('toggleui', function()
    uivisible = not uivisible
    notifyPlayer("info", "HUD visibility toggled")
    
    -- Send to UI
    SendNUIMessage({
        name = "hideHud",
        show = uivisible
    })
end, false)

-- Status updates thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        TriggerEvent('esx_status:getStatus', 'hunger', function(hunger)
            TriggerEvent('esx_status:getStatus', 'thirst', function(thirst)
                local hungerPercent = hunger.getPercent()
                local thirstPercent = thirst.getPercent()
                local health = GetEntityHealth(PlayerPedId()) - 100
                local armor = GetPedArmour(PlayerPedId())

                -- Send status update to UI
                SendNUIMessage({
                    name = "hudTick",
                    show = not IsPauseMenuActive() and uivisible,
                    health = health,
                    armor = armor,
                    hunger = hungerPercent,
                    thirst = thirstPercent,
                })
            end)
        end)
    end
end)

-- Utility functions
function notifyPlayer(type, message)
    exports['okokNotify']:Alert('Server', message, 3500, type)
end

function getCardinalDirection(heading)
    if heading >= 337.5 or heading < 22.5 then
        return "N"
    elseif heading >= 22.5 and heading < 67.5 then
        return "NE"
    elseif heading >= 67.5 and heading < 112.5 then
        return "E"
    elseif heading >= 112.5 and heading < 157.5 then
        return "SE"
    elseif heading >= 157.5 and heading < 202.5 then
        return "S"
    elseif heading >= 202.5 and heading < 247.5 then
        return "SW"
    elseif heading >= 247.5 and heading < 292.5 then
        return "W"
    elseif heading >= 292.5 and heading < 337.5 then
        return "NW"
    end
end

-- Get minimap anchor position
function GetMinimapAnchor()
    local safezone = GetSafeZoneSize()
    local safezone_x = 1.0 / 20.0
    local safezone_y = 1.0 / 20.0
    local aspect_ratio = GetAspectRatio(0)
    if aspect_ratio > 2 then aspect_ratio = 16/9 end
    
    local res_x, res_y = GetActiveScreenResolution()
    local xscale = 1.0 / res_x
    local yscale = 1.0 / res_y
    
    local Minimap = {}
    Minimap.width = xscale * (res_x / (4 * aspect_ratio))
    Minimap.height = yscale * (res_y / 5.674)
    Minimap.left_x = xscale * (res_x * (safezone_x * ((math.abs(safezone - 1.0)) * 10)))

    if aspect_ratio > 2 then
        Minimap.left_x = Minimap.left_x + Minimap.width * 0.845
        Minimap.width = Minimap.width * 0.76
    elseif aspect_ratio > 1.8 then
        Minimap.left_x = Minimap.left_x + Minimap.width * 0.2225
        Minimap.width = Minimap.width * 0.995
    end
    
    Minimap.bottom_y = 1.0 - yscale * (res_y * (safezone_y * ((math.abs(safezone - 1.0)) * 10)))
    Minimap.right_x = Minimap.left_x + Minimap.width
    Minimap.top_y = Minimap.bottom_y - Minimap.height
    Minimap.x = Minimap.left_x
    Minimap.y = Minimap.top_y
    Minimap.xunit = xscale
    Minimap.yunit = yscale
    
    return Minimap
end

local hideDefaultHUD = true
local radarDisplayed = false

RegisterNUICallback('hideRadar', function(data, cb)
    DisplayRadar(false)
    radarDisplayed = false
    
    if hideDefaultHUD then
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
    end
    
    cb({})
end)

RegisterNUICallback('getGameTime', function(data, cb)
    local year, month, day, hour, minute = GetLocalTime(x,x,x,x,hodiny,minuty)
    local currentTime = string.format("%02d:%02d", hour, minute)

    cb({
        time = currentTime
    })
end)

AddEventHandler("baseevents:enteredVehicle", function(veh) 
    DisplayRadar(true)
    radarDisplayed = false
    pedInVeh = true

    if IsVehicleDriveable(veh) then
        lastVehEngine = true
    end

    monitorVehicleState()
end)