-- Debug test commands for HUD system
-- Only active when Config.Debug is true

local function IsDebugEnabled()
    return Config.Debug == true
end

-- Register debug commands only if debug is enabled
Citizen.CreateThread(function()
    if not IsDebugEnabled() then 
        return 
    end
    
    -- Test drunk effect
    RegisterCommand('testdrunk', function(source, args)
        local level = tonumber(args[1]) or 50
        level = math.min(100, math.max(0, level))
        TriggerEvent('hcyk_hud:setDrunkLevel', level)
        exports['okokNotify']:Alert('Debug', 'Opilost nastavena na: ' .. level, 3000, 'info')
    end, false)
    
    -- Test health effect
    RegisterCommand('testhealth', function(source, args)
        local level = tonumber(args[1]) or 15
        level = math.min(200, math.max(0, level))
        SetEntityHealth(PlayerPedId(), level + 100)  -- +100 because game health starts at 100
        exports['okokNotify']:Alert('Debug', 'Zdraví nastaveno na: ' .. level, 3000, 'info')
    end, false)
    
    -- Test hunger effect
    RegisterCommand('testhunger', function(source, args)
        local level = tonumber(args[1]) or 15
        level = math.min(100, math.max(0, level))
        TriggerEvent('esx_status:set', 'hunger', level * 10000)  -- ESX status uses 0-1000000
        exports['okokNotify']:Alert('Debug', 'Hlad nastaven na: ' .. level .. '%', 3000, 'info')
    end, false)
    
    -- Test thirst effect
    RegisterCommand('testthirst', function(source, args)
        local level = tonumber(args[1]) or 15
        level = math.min(100, math.max(0, level))
        TriggerEvent('esx_status:set', 'thirst', level * 10000)  -- ESX status uses 0-1000000
        exports['okokNotify']:Alert('Debug', 'Žízeň nastavena na: ' .. level .. '%', 3000, 'info')
    end, false)
    
    -- Test oxygen effect
    RegisterCommand('testoxygen', function(source, args)
        local level = tonumber(args[1]) or 15
        
        -- Create thread to simulate oxygen depletion
        Citizen.CreateThread(function()
            -- Store original oxygen
            local originalOxygen = GetPlayerUnderwaterTimeRemaining(PlayerId())
            
            -- Set underwater time (max is around 20.0 seconds)
            SetPlayerUnderwaterTime(PlayerId(), level / 10)
            
            -- Force underwater state using a ped flag
            local ped = PlayerPedId()
            SetPedConfigFlag(ped, 65, true)  -- Set underwater flag
            
            exports['okokNotify']:Alert('Debug', 'Kyslík nastaven na: ' .. level .. '%', 3000, 'info')
            exports['okokNotify']:Alert('Debug', 'Resetování za 10 sekund', 3000, 'warning')
            
            Citizen.Wait(10000)  -- Reset after 10 seconds
            
            -- Reset oxygen and ped config
            SetPlayerUnderwaterTime(PlayerId(), originalOxygen)
            SetPedConfigFlag(ped, 65, false)
            
            exports['okokNotify']:Alert('Debug', 'Test kyslíku dokončen', 3000, 'success')
        end)
    end, false)
    
    -- Test HUD toggle
    RegisterCommand('testhud', function(source, args)
        local state = args[1]
        if state == "show" then
            ExecuteCommand("hud")
            exports['okokNotify']:Alert('Debug', 'HUD zobrazen', 3000, 'info')
        elseif state == "hide" then
            ExecuteCommand("hud")
            exports['okokNotify']:Alert('Debug', 'HUD skryt', 3000, 'info')
        else
            ExecuteCommand("hud")
            exports['okokNotify']:Alert('Debug', 'HUD přepnut', 3000, 'info')
        end
    end, false)
    
    -- Reset all effects to normal
    RegisterCommand('testreset', function()
        -- Reset health
        SetEntityHealth(PlayerPedId(), 200)
        
        -- Reset hunger and thirst
        TriggerEvent('esx_status:set', 'hunger', 1000000)
        TriggerEvent('esx_status:set', 'thirst', 1000000)
        
        -- Reset drunk
        TriggerEvent('hcyk_hud:setDrunkLevel', 0)
        
        -- Reset oxygen
        SetPlayerUnderwaterTime(PlayerId(), 20.0)
        SetPedConfigFlag(PlayerPedId(), 65, false)
        
        -- Reset movement
        ResetPedMovementClipset(PlayerPedId(), 0)
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
        
        -- Stop screen effects
        StopGameplayCamShaking(true)
        StopScreenEffect("DeathFailOut")
        ClearTimecycleModifier()
        
        exports['okokNotify']:Alert('Debug', 'Všechny efekty byly resetovány', 3000, 'success')
    end, false)
    
    -- Add event handler for drunk level
    RegisterNetEvent('hcyk_hud:setDrunkLevel')
    AddEventHandler('hcyk_hud:setDrunkLevel', function(level)
        if type(level) ~= "number" then return end
        drunkLevel = math.min(100, math.max(0, level))
    end)
    
    -- Display help message for debug commands
    RegisterCommand('testhelp', function()
        TriggerEvent('chat:addMessage', {
            color = {255, 200, 0},
            multiline = true,
            args = {
                'HUD Debug Commands:',
                '/testdrunk [0-100] - Nastavit úroveň opilosti\n' ..
                '/testhealth [0-200] - Nastavit úroveň zdraví\n' ..
                '/testhunger [0-100] - Nastavit úroveň hladu\n' ..
                '/testthirst [0-100] - Nastavit úroveň žízně\n' ..
                '/testoxygen [0-100] - Test úbytku kyslíku\n' ..
                '/testhud [show/hide] - Přepnout viditelnost HUD\n' ..
                '/testreset - Resetovat všechny efekty'
            }
        })
    end, false)
    
    -- Notify that debug commands are available
    Citizen.Wait(5000) -- Wait for resources to load
    exports['okokNotify']:Alert('Debug', 'HUD debug příkazy jsou k dispozici. Napiš /testhelp pro seznam.', 5000, 'info')
end)

-- Add exports for other scripts to use
exports('SetDrunkLevel', function(level)
    if IsDebugEnabled() or level == nil then
        TriggerEvent('hcyk_hud:setDrunkLevel', level)
        return true
    end
    return false
end)