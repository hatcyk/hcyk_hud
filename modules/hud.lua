local ESX = exports['es_extended']:getSharedObject()

-- Core HUD state
local uivisible = Config.hud.defaultVisible
local lastMinimap = { x = 0, y = 0, ar = 0 }
local displayStreetsOnFoot = Config.hud.showStreetsOnFoot
local streetInfo = {
    compass = "",
    street = "",
    postal = "",
    time = ""
}

-- Status thresholds for low notifications
local healthThreshold = 25
local hungerThreshold = 25
local thirstThreshold = 25
local staminaThreshold = 25
local oxygenThreshold = 25

-- Status notification cooldowns
local lastHealthNotify = 0
local lastHungerNotify = 0
local lastThirstNotify = 0
local lastStaminaNotify = 0
local lastOxygenNotify = 0
local notifyCooldown = 60000 -- 60 seconds cooldown

-- Low oxygen screen effect state
local oxygenEffectActive = false

-- Add to your variables at the top
local drunkLevel = 0
local lastDrunkUpdate = 0
local drunkEffect = false
local healthEffect = false

-- Update street name, compass direction, postal code and time
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
    
    -- Get current time
    local year, month, day, hour, minute = GetLocalTime()
    streetInfo.time = string.format("%02d:%02d", hour, minute)
    
    return streetInfo
end

-- Update HUD with current state
function updateHud()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    local vehicleInfo = {}
    local inVehicle = IsPedInAnyVehicle(player, false)

    if inVehicle then
        -- Get vehicle state from modules
        local vehicleState = exports["hcyk_hud"]:GetVehicleState()
        local vehicleClasses = exports["hcyk_hud"]:GetVehicleClasses()
        local seatbeltOn = exports["hcyk_hud"]:IsSeatbeltOn()
        
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
        
        -- Format RPM for display (0-10000 range)
        if rpm >= 0.95 then
            rpm = math.random(105, 110) * 0.01
        end
        rpm = math.ceil(rpm * 10000)

        -- Update location information
        local streetInfoData = updateStreetInfo()
        
        -- Prepare vehicle info for UI
        vehicleInfo = {
            updateVehicle = true,
            status = true,
            speed = vehicleSpeed,
            rpm = rpm,
            gear = vehicleGear,
            fuel = vehicleFuel,
            signals = vehicleState.signals,
            cruiser = vehicleState.cruiser,
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
        -- Update street info when on foot
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

-- Toggle HUD visibility
RegisterCommand("hud", function()
    uivisible = not uivisible
    SendNUIMessage({
        name = "hideHud",
        show = uivisible
    })
end)

-- Toggle streets display on foot
RegisterCommand('streets', function()
    displayStreetsOnFoot = not displayStreetsOnFoot
    notify("info", (displayStreetsOnFoot and 'Enabled' or 'Disabled') .. ' street display')
end)

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

-- Main HUD update loop
Citizen.CreateThread(function()
    while true do
        if uivisible then
            updateHud()
            Citizen.Wait(Config.hud.updateInterval)
        else
            Citizen.Wait(1000)
        end
    end
end)

-- Update player stats regularly
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        
        TriggerEvent('esx_status:getStatus', 'hunger', function(hunger)
            TriggerEvent('esx_status:getStatus', 'thirst', function(thirst)
                local hungerPercent = hunger.getPercent()
                local thirstPercent = thirst.getPercent()
                local health = math.max(0, GetEntityHealth(PlayerPedId()) - 100)
                local armor = GetPedArmour(PlayerPedId())
                local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
                local oxygen = 100
                local isUnderwater = false

                if IsPedSwimmingUnderWater(PlayerPedId()) then
                    isUnderwater = true
                    local underwaterTime = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
                    oxygen = math.max(0, underwaterTime)
                    if oxygen > 100 then oxygen = 100 end
                    
                    -- Handle oxygen screen effect
                    if oxygen <= oxygenThreshold and not oxygenEffectActive then
                        oxygenEffectActive = true
                        StartScreenEffect("DeathFailOut", 0, false)
                        SetTimecycleModifier("damage")
                    elseif oxygen > oxygenThreshold and oxygenEffectActive then
                        oxygenEffectActive = false
                        StopScreenEffect("DeathFailOut")
                        ClearTimecycleModifier()
                    end
                elseif oxygenEffectActive then
                    oxygenEffectActive = false
                    StopScreenEffect("DeathFailOut")
                    ClearTimecycleModifier()
                end
                local currentTime = GetGameTimer()
                
                -- Health notification
                if health <= healthThreshold and currentTime - lastHealthNotify > notifyCooldown then
                    exports['okokNotify']:Alert('Hud', 'Máš málo zdraví, měl by jsi se léčit', 4500, 'error')
                    lastHealthNotify = currentTime
                end
                
                -- Hunger notification
                if hungerPercent <= hungerThreshold and currentTime - lastHungerNotify > notifyCooldown then
                    exports['okokNotify']:Alert('Hud', 'Máš málo jídla, měl by jsi se najíst', 4500, 'warning')
                    lastHungerNotify = currentTime
                    
                    -- Add hunger effect
                    if hungerPercent <= hungerThreshold / 2 then
                        ApplyDamageToPed(PlayerPedId(), 1, true)
                        ShakeGameplayCam("DRUNK_SHAKE", 0.3)
                        Citizen.Wait(500)
                        StopGameplayCamShaking(true)
                    end
                end
                
                -- Thirst notification
                if thirstPercent <= thirstThreshold and currentTime - lastThirstNotify > notifyCooldown then
                    exports['okokNotify']:Alert('Hud', 'Máš málo vody, měl by jsi se napít', 4500, 'warning')
                    lastThirstNotify = currentTime
                    
                    -- Add thirst effect
                    if thirstPercent <= thirstThreshold / 2 then
                        ApplyDamageToPed(PlayerPedId(), 1, true)
                        ShakeGameplayCam("DRUNK_SHAKE", 0.3)
                        Citizen.Wait(500)
                        StopGameplayCamShaking(true)
                    end
                end
                
                -- Oxygen notification
                if isUnderwater and oxygen <= oxygenThreshold and currentTime - lastOxygenNotify > notifyCooldown then
                    exports['okokNotify']:Alert('Hud', 'Docházi ti kyslík, vynoř se!', 4500, 'error')
                    lastOxygenNotify = currentTime
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
                    isUnderwater = isUnderwater,
                    drunk = drunkLevel -- Add this line
                })
            end)
        end)
    end
end)

-- Add health and drunk screen effects
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped) - 100
        
        -- Handle low health effects
        if health < 20 and not healthEffect then
            healthEffect = true
            -- Make player walk slower
            SetPedMoveRateOverride(ped, 0.7)
            RequestAnimSet("move_m@injured")
            while not HasAnimSetLoaded("move_m@injured") do
                Citizen.Wait(100)
            end
            SetPedMovementClipset(ped, "move_m@injured", 1.0)
        elseif health >= 20 and healthEffect then
            healthEffect = false
            SetPedMoveRateOverride(ped, 1.0)
            ResetPedMovementClipset(ped, 0)
        end
        
        -- Handle drunk effects
        if drunkLevel > 30 and not drunkEffect then
            drunkEffect = true
            -- Apply drunk walking style
            RequestAnimSet("move_m@drunk@verydrunk")
            while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
                Citizen.Wait(100)
            end
            SetPedMovementClipset(ped, "move_m@drunk@verydrunk", 1.0)
            
            -- Add screen shaking for drunk effect
            ShakeGameplayCam("DRUNK_SHAKE", 1.0)
        elseif drunkLevel <= 30 and drunkEffect then
            drunkEffect = false
            ResetPedMovementClipset(ped, 0)
            StopGameplayCamShaking(true)
        end
    end
end)

-- Add drunk level decay over time
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000) -- Check every 10 seconds
        if drunkLevel > 0 then
            drunkLevel = math.max(0, drunkLevel - 2) -- Reduce drunk level by 2 every 10 seconds
        end
    end
end)

-- Create blip-less minimap
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

-- Toggle HUD visibility
function toggleHud(display)
    if display == '' then display = true end
    uivisible = display
    SendNUIMessage({
        name = "hideHud",
        show = display
    })
end

-- Exports
exports('UpdateStreetInfo', updateStreetInfo)
exports('UpdateHud', updateHud)
exports('GetHudVisibility', function() return uivisible end)
exports('togglehud', toggleHud)
exports('DrinkAlcohol', DrinkAlcohol)

-- Register key bindings
exports['I']:RegisterKeyMap('hud','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Skrýt/zobrazit HUD', 'F11')
exports['I']:RegisterKeyMap('+hud:bigmap','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Velká mapa', 'LSHIFT')

-- Handle big map toggle
RegisterCommand('+hud:bigmap', function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        SetBigmapActive(true, false)
        toggleHud(false)
    end
end)

RegisterCommand('-hud:bigmap', function()
    SetBigmapActive(false, false)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        toggleHud(true)
        updateHud()
    end
end)

-- Add function to handle drinking alcohol
function DrinkAlcohol(amount)
    drunkLevel = math.min(100, drunkLevel + amount)
    lastDrunkUpdate = GetGameTimer()
    
    -- Notify the player they're getting drunk
    if drunkLevel > 70 then
        exports['okokNotify']:Alert('Hud', 'Jsi úplně opilý!', 4500, 'warning')
    elseif drunkLevel > 30 then
        exports['okokNotify']:Alert('Hud', 'Začínáš být opilý', 4500, 'info')
    end
end