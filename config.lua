Config = {}
Config.Debug = true
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
    toggleEngine = "Y"
}