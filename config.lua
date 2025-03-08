Config = {}

-- Vehicle configuration
Config.vehicle = {
    speedUnit = 'MPH', -- MPH or KMH
    maxSpeed = 200,    -- Maximum speed for the speedometer (visual only)

    seatbelt = {
        playBuckleSound = true,
        playUnbuckleSound = true,
        ejectSpeed = 45.0,       -- Speed threshold for ejection (in speedUnit)
        ejectAcceleration = 100.0 -- Acceleration threshold for ejection
    },

    fuel = {
        warningLevel = 20, -- Percentage at which to show low fuel warning
    },

    damage = {
        warningLevel = 35, -- Percentage at which to show vehicle damage warning
    }
}

-- HUD configuration
Config.hud = {
    defaultVisible = true,
    showStreetsOnFoot = false,
    updateInterval = 150, -- milliseconds between HUD updates
    colors = {
        health = {r = 200, g = 40, b = 40},
        armor = {r = 30, g = 100, b = 240},
        hunger = {r = 240, g = 140, b = 30},
        thirst = {r = 30, g = 145, b = 240},
        fuel = {r = 60, g = 180, b = 75},
        damage = {r = 180, g = 180, b = 180},
        speed = {r = 255, g = 255, b = 255},
        rpm = {r = 255, g = 70, b = 70}
    }
}

-- Notification system configuration
Config.notifications = {
    duration = 3500, -- Default notification duration in ms
    position = 'top-right', -- Options: 'top-right', 'top-left', 'bottom-right', 'bottom-left'
}

-- Blackout system configuration
Config.blackout = {
    enabled = false,
    duration = 2000, -- Duration of blackout effect in ms
    
    fromDamage = {
        enabled = true, 
        threshold = 46  -- Vehicle damage threshold to trigger blackout
    },

    fromSpeed = {
        enabled = true,
        threshold = 70  -- Speed threshold in KPH to trigger blackout when rapid deceleration occurs
    },
    
    disableControls = true -- Whether to disable controls during blackout
}

-- Cruise control configuration
Config.cruiseControl = {
    incrementStep = 5, -- Speed increment/decrement step for cruise control adjustments
    allowAdjustment = true, -- Allow adjusting cruise control speed up/down
}

-- Feature toggles
Config.features = {
    allowBoostGauge = false, -- Enable/disable boost gauge for turbo vehicles
    showDamageWarning = true, -- Show warning when vehicle is damaged
    showFuelWarning = true,   -- Show warning when fuel is low
    showSpeedLimiter = true,  -- Show speed limiter indicator
    dynamicCompass = true,    -- Enable dynamic compass (shows exact degrees)
}

-- Key bindings (names used in RegisterKeyMapping)
Config.keys = {
    seatbelt = "b",
    cruiseControl = "m",
    turnLeft = "LEFT",
    turnRight = "RIGHT",
    hazardLights = "DOWN",
    toggleHud = "F7",
    toggleStreets = "F6",
    toggleEngine = "Y"
}