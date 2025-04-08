Config = {}

Config.vehicle = {
    speedUnit = 'MPH', 
    maxSpeed = 200,    

    seatbelt = {
        playBuckleSound = true,
        playUnbuckleSound = true,
        ejectSpeed = 35.0,       -- Speed in MPH that would eject player when crashing
        ejectAcceleration = 1000.0 -- Acceleration threshold for detecting crashes
    },

    fuel = {
        warningLevel = 20,
    },

    damage = {
        warningLevel = 35,
    }
}

Config.hud = {
    defaultVisible = true,
    showStreetsOnFoot = false,
    updateInterval = 150 
}

Config.notifications = {
    duration = 3500,
    position = 'top' 
}

Config.cruiseControl = {
    incrementStep = 5,
    allowAdjustment = true 
}

Config.features = {
    showDamageWarning = true,
    showFuelWarning = true,  
    showSpeedLimiter = true, 
    dynamicCompass = true,   -- Set to true to show direction without degrees
    terrainEffects = true,
    -- Status thresholds for notifications and effects
    thresholds = {
        health = 25,
        hunger = 25,
        thirst = 25,
        stamina = 25,
        oxygen = 25
    },
    
    -- Notification cooldowns (in ms)
    notifyCooldown = 60000 -- 60 seconds between notifications for the same status
}

Config.keys = {
    seatbelt = "b",
    cruiseControl = "CAPITAL", 
    turnLeft = "LEFT",
    turnRight = "RIGHT",
    hazardLights = "DOWN",
    toggleHud = "F7",
    toggleStreets = "F6",
    toggleEngine = "Y",
    throttleControl = "LSHIFT", 
}

Config.maxRpm = 0.255                             
Config.maxSpeed = 50                              
Config.defaultSmoothing = false                   


Config.allowedClasses = {                         
    [0] = true,  -- Compacts
    [1] = true,  -- Sedans
    [2] = true,  -- SUVs
    [3] = true,  -- Coupes
    [4] = true,  -- Muscle
    [5] = true,  -- Sports Classics
    [6] = true,  -- Sports
    [7] = true,  -- Super
    [8] = true,  -- Motorcycles
    [9] = true,  -- Off-road
    [10] = false, -- Industrial
    [11] = false, -- Utility
    [12] = false, -- Vans
    [13] = false, -- Cycles
    [14] = false, -- Boats
    [15] = false, -- Helicopters
    [16] = false, -- Planes
    [17] = false, -- Service
    [18] = true, -- Emergency
    [19] = false, -- Military
    [20] = false, -- Commercial
    [21] = false, -- Trains
}
