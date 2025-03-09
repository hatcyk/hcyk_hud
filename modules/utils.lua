-- Utility functions for the HUD system

-- Cardinal directions mapping
local directions = {
    [0] = "N",
    [45] = "NE",
    [90] = "E",
    [135] = "SE",
    [180] = "S",
    [225] = "SW",
    [270] = "W",
    [315] = "NW",
    [360] = "N"
}

-- Convert degrees to cardinal direction
function degreesToCardinalDirection(degrees)
    degrees = (degrees + 360) % 360 -- Normalize to 0-359
    
    if Config.features.dynamicCompass then
        -- Find the closest cardinal direction
        local closestDirection = 0
        local closestDistance = 360
        
        for direction, _ in pairs(directions) do
            local distance = math.abs(degrees - direction)
            if distance > 180 then
                distance = 360 - distance
            end
            
            if distance < closestDistance then
                closestDistance = distance
                closestDirection = direction
            end
        end
        
        -- Return cardinal direction with exact degrees
        return directions[closestDirection] .. " " .. math.floor(degrees) .. "°"
    else
        -- Standard 8-point direction
        if (degrees >= 337.5 or degrees < 22.5) then
            return "N"
        elseif (degrees >= 22.5 and degrees < 67.5) then
            return "NE"
        elseif (degrees >= 67.5 and degrees < 112.5) then
            return "E"
        elseif (degrees >= 112.5 and degrees < 157.5) then
            return "SE"
        elseif (degrees >= 157.5 and degrees < 202.5) then
            return "S"
        elseif (degrees >= 202.5 and degrees < 247.5) then
            return "SW"
        elseif (degrees >= 247.5 and degrees < 292.5) then
            return "W"
        elseif (degrees >= 292.5 and degrees < 337.5) then
            return "NW"
        end
    end
end

-- Round to nearest decimal place
function roundToDecimals(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Get forward vector
function getForwardVector(entity)
    local entityHeading = GetEntityHeading(entity) + 90.0
    if entityHeading < 0.0 then
        entityHeading = 360.0 + entityHeading
    end
    
    local heading = entityHeading * 0.0174533 -- Convert to radians
    return vector2(math.cos(heading), math.sin(heading))
end

-- Display notification
function notify(type, message, duration)
    if not duration then
        duration = Config.notifications.duration
    end
    
    exports['okokNotify']:Alert('Server', message, duration, type)
end

-- Convert speed between units
function convertSpeed(speed, fromUnit, toUnit)
    if fromUnit == toUnit then
        return speed
    end
    
    if fromUnit == "MPH" and toUnit == "KMH" then
        return speed * 1.60934
    elseif fromUnit == "KMH" and toUnit == "MPH" then
        return speed * 0.621371
    else
        return speed
    end
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
    
    return hasSeatbelt[vehicleClass] or false
end

-- Export functions for external use
exports('DegreesToCardinalDirection', degreesToCardinalDirection)
exports('RoundToDecimals', roundToDecimals)
exports('GetForwardVector', getForwardVector)
exports('Notify', notify)
exports('ConvertSpeed', convertSpeed)
exports('VehicleHasSeatbelts', vehicleHasSeatbelts)