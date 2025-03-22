local ESX = exports['es_extended']:getSharedObject()

-- Seatbelt state
local seatbeltIsOn = false
local hasBeenEjected = false
local ejectCooldown = false

-- Velocity tracking for better crash detection
local lastSpeed = 0
local lastVelocity = vector3(0.0, 0.0, 0.0)

-- Pre-crash speed tracking
local precrashSpeedWindow = {}
local speedHistorySize = 10

-- Configure these values in Config if needed
local minEjectSpeed = 66.0 -- Min speed for ejection (MPH) - HARDCODED FOR TESTING
local decelThreshold = 8.0 -- Sudden deceleration threshold (higher = harder crash needed)
local ejectForceMultiplier = 1.33 -- How much force to apply during ejection

-- Debug function
function DebugPrint(label, ...)
    local args = {...}
    local text = label .. ": "
    
    for i, arg in ipairs(args) do
        if type(arg) == "table" then
            for k, v in pairs(arg) do
                text = text .. k .. "=" .. tostring(v) .. " "
            end
        else
            text = text .. tostring(arg) .. " "
        end
    end
    
    print("[SEATBELT-DEBUG] " .. text)
end

-- Register key binding
exports['I']:RegisterKeyMap('seatbelt','(~HUD_COLOUR_YELLOWLIGHT~HUD~w~) - Bezp. pás', Config.keys.seatbelt)

-- Toggle seatbelt command
RegisterCommand("seatbelt", function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if not IsPedInAnyVehicle(playerPed, false) then return end
    
    if vehicleHasSeatbelts(vehicle) then
        ToggleSeatbelt()
    end
end)

function ToggleSeatbelt()
    seatbeltIsOn = not seatbeltIsOn
    
    -- Play sound effects if enabled
    if seatbeltIsOn and Config.vehicle.seatbelt.playBuckleSound then
        TriggerEvent('InteractSound_CL:PlayOnOne', 'buckle', 0.5)
    elseif not seatbeltIsOn and Config.vehicle.seatbelt.playUnbuckleSound then
        TriggerEvent('InteractSound_CL:PlayOnOne', 'unbuckle', 0.6)
    end
    
    -- Update HUD with new seatbelt state
    TriggerEvent('hcyk_hud:updateSeatbelt', seatbeltIsOn)
    
    return seatbeltIsOn
end

-- Better crash detection using multiple methods
function DetectCrash(vehicle)
    local currentVelocity = GetEntityVelocity(vehicle)
    local currentSpeed = GetEntitySpeed(vehicle) * 2.236936 -- Convert to MPH
    
    -- Store speed in history window (keep track of last few speeds)
    table.insert(precrashSpeedWindow, currentSpeed)
    if #precrashSpeedWindow > speedHistorySize then
        table.remove(precrashSpeedWindow, 1)
    end
    
    -- Calculate max speed from recent history
    local recentMaxSpeed = 0
    for _, speed in ipairs(precrashSpeedWindow) do
        if speed > recentMaxSpeed then recentMaxSpeed = speed end
    end
    
    -- Method 1: Detect sudden deceleration
    local speedDiff = lastSpeed - currentSpeed
    local isSuddenDecel = speedDiff > decelThreshold
    
    -- Method 2: Check for collision force (velocity change)
    local velocityDiff = #(lastVelocity - currentVelocity)
    local isHighImpact = velocityDiff > 0.15
    
    -- Method 3: Use game's native has collision detection
    local hasCollided = HasEntityCollidedWithAnything(vehicle)
    
    -- Store values for next frame
    lastSpeed = currentSpeed
    lastVelocity = currentVelocity
    
    -- Return crash detection result and crash data
    local hasCrashed = (isSuddenDecel or isHighImpact) and hasCollided
    local crashData = {
        speed = currentSpeed,
        recentMaxSpeed = recentMaxSpeed, -- Store recent max speed
        velocity = currentVelocity,
        deceleration = speedDiff,
        impact = velocityDiff
    }
    
    return hasCrashed, crashData
end

-- Monitor seatbelt state and handle crash detection
function MonitorSeatbelt(vehicle)
    local ped = PlayerPedId()
    
    -- Reset detection variables when entering new vehicle
    lastSpeed = 0
    lastVelocity = vector3(0.0, 0.0, 0.0)
    precrashSpeedWindow = {}
    hasBeenEjected = false
    ejectCooldown = false
    
    
    Citizen.CreateThread(function()
        while IsPedInVehicle(ped, vehicle) do
            if seatbeltIsOn then 
                -- Prevent F from exiting when seatbelt is on
                DisableControlAction(0, 75, true)
                DisableControlAction(27, 75, true)
            else
                -- Enable exit controls when seatbelt is off
                EnableControlAction(0, 75, true)
                EnableControlAction(27, 75, true)
                
                -- Only check for crashes if vehicle has seatbelts and we're not on cooldown
                if vehicleHasSeatbelts(vehicle) and not ejectCooldown then
                    local hasCrashed, crashData = DetectCrash(vehicle)
                    
                    -- Check for either high recent speed or high impact regardless of current speed
                    if hasCrashed and (crashData.recentMaxSpeed > minEjectSpeed and crashData.impact > 18.5) then
                        DebugPrint("EJECTION TRIGGERED", 
                            "Current Speed:", crashData.speed, 
                            "Recent Max Speed:", crashData.recentMaxSpeed,
                            "Min Required:", minEjectSpeed,
                            "Impact:", crashData.impact)
                        EjectFromVehicle(ped, vehicle, crashData)
                    end
                end
            end
            
            Citizen.Wait(10) 
        end
        
        seatbeltIsOn = false
    end)
end

function EjectFromVehicle(ped, vehicle, crashData)
    ejectCooldown = true
    
    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleForward = GetEntityForwardVector(vehicle)
    local vehicleRight = vector3(-vehicleForward.y, vehicleForward.x, 0)
    local vehicleSpeed = math.max(crashData.speed, crashData.recentMaxSpeed) -- Use the higher speed
    local vehicleVelocity = crashData.velocity

    -- Calculate ragdoll duration based on crash intensity
    local baseRagdollTime = 4000 -- Base time in ms
    local impactFactor = math.min(1.0, crashData.impact / 30.0) -- Normalized impact
    local speedFactor = math.min(1.0, vehicleSpeed / 100.0) -- Normalized speed

    -- Exponential relationship for more dramatic difference in severe crashes
    local crashSeverity = (impactFactor * 0.7) + (speedFactor * 0.3) -- 70% impact, 30% speed
    local severityExponent = crashSeverity * crashSeverity * 1.5 -- Square the severity for exponential effect

    -- Calculate ragdoll duration range
    local minRagdollTime = baseRagdollTime + (severityExponent * 6000) -- 4000-10000ms 
    local maxRagdollTime = minRagdollTime + (2000 + (severityExponent * 3000)) -- Variable gap between min/max

    -- Add random factor to make crashes feel less predictable
    local randomFactor = 0.85 + (math.random() * 0.3) -- 0.85-1.15 multiplier
    minRagdollTime = math.floor(minRagdollTime * randomFactor)
    maxRagdollTime = math.floor(maxRagdollTime * randomFactor)
    
    SetPedCanRagdoll(ped, true)
    
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.0, 1.0))
    
    Citizen.CreateThread(function()
        SetPedToRagdoll(ped, minRagdollTime, maxRagdollTime, 0, true, true, false)
        
        -- Randomize direction slightly
        local randomAngle = math.random() * 0.5 - 0.25 -- -0.25 to 0.25
        local randomHeight = math.random() * 0.5 + 0.5 -- 0.5 to 1.0
        
        -- Calculate ejection velocity (use restored pre-crash speed)
        local forwardFactor = 0.2 + (vehicleSpeed / 50)
        local upwardFactor = 0.5 + (vehicleSpeed / 80)
        
        local ejectVelocity = {
            x = vehicleVelocity.x + (vehicleForward.x * forwardFactor) + (vehicleRight.x * randomAngle),
            y = vehicleVelocity.y + (vehicleForward.y * forwardFactor) + (vehicleRight.y * randomAngle),
            z = vehicleVelocity.z + upwardFactor * randomHeight
        }
        
        SetEntityVelocity(ped, ejectVelocity.x, ejectVelocity.y, ejectVelocity.z)
        
        Citizen.Wait(0)
        
        SetPedToRagdoll(ped, minRagdollTime, maxRagdollTime, 0, true, true, false)
        
        Citizen.Wait(100)
        
        if not IsPedRagdoll(ped) then
            SetPedToRagdollWithFall(ped, minRagdollTime, maxRagdollTime, 1, vehicleForward, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        end
        
        local baseDamage = 10 -- Reduced from 20
        local speedDamage = math.min(30, vehicleSpeed / 4) -- Reduced from 60, divided by 4 instead of 2
        local impactDamage = math.min(10, crashData.impact * 50) -- Reduced from 20, multiplied by 50 instead of 100
        local totalDamage = math.floor((baseDamage + speedDamage + impactDamage) * 0.7) -- Added 30% overall reduction
        
        local currentHealth = GetEntityHealth(ped)
        local newHealth = math.max(1, currentHealth - totalDamage)
        SetEntityHealth(ped, newHealth)
        SetTimecycleModifier("damage")
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 1.0)
        
        Citizen.SetTimeout(5000, function()
            ClearTimecycleModifier()
            StopGameplayCamShaking(true)
        end)
        
        Citizen.SetTimeout(3000, function()
            ejectCooldown = false
        end)
    end)
end

-- Helper function for vector length
function vector3GetLength(vector)
    return math.sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
end

-- Check if a vehicle has seatbelts
function vehicleHasSeatbelts(vehicle)
    if not DoesEntityExist(vehicle) then
        return false
    end
    
    local vehicleClass = GetVehicleClass(vehicle)
    
    -- Classes that typically have seatbelts
    local hasSeatbelt = {
        [0] = true,  -- Compacts
        [1] = true,  -- Sedans
        [2] = true,  -- SUVs
        [3] = true,  -- Coupes
        [4] = true,  -- Muscle
        [5] = true,  -- Sports Classics
        [6] = true,  -- Sports
        [7] = true,  -- Super
        [9] = true,  -- Off-road
        [10] = true, -- Industrial
        [11] = true, -- Utility
        [12] = true, -- Vans
        [17] = true, -- Service
        [18] = true, -- Emergency
        [19] = true, -- Military
        [20] = true  -- Commercial
    }
    
    local hasBelt = hasSeatbelt[vehicleClass] or false
    return hasBelt
end

-- Get current seatbelt state
function IsSeatbeltOn()
    return seatbeltIsOn
end

-- Exports
exports('IsSeatbeltOn', IsSeatbeltOn)
exports('ToggleSeatbelt', ToggleSeatbelt)
exports('MonitorSeatbelt', MonitorSeatbelt)