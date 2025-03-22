-- Test commands for debugging HUD effects
-- Add these at the end of your file

-- Add debug test commands
Citizen.CreateThread(function()
    if not Config.Debug then return end  -- Only register these if debug mode is enabled
    
    -- Test drunk effect
    RegisterCommand('test_drunk', function(source, args)
        local level = tonumber(args[1]) or 50
        drunkLevel = math.min(100, math.max(0, level))
        exports['okokNotify']:Alert('Debug', 'Drunk level set to: ' .. drunkLevel, 3000, 'info')
    end, false)
    
    -- Test health effect
    RegisterCommand('test_health', function(source, args)
        local level = tonumber(args[1]) or 15
        level = math.min(200, math.max(0, level))
        SetEntityHealth(PlayerPedId(), level + 100)  -- +100 because game health starts at 100
        exports['okokNotify']:Alert('Debug', 'Health set to: ' .. level, 3000, 'info')
    end, false)
    
    -- Test hunger effect
    RegisterCommand('test_hunger', function(source, args)
        local level = tonumber(args[1]) or 15
        level = math.min(100, math.max(0, level))
        TriggerEvent('esx_status:set', 'hunger', level * 10000)  -- ESX status uses 0-1000000
        exports['okokNotify']:Alert('Debug', 'Hunger set to: ' .. level .. '%', 3000, 'info')
    end, false)
    
    -- Test thirst effect
    RegisterCommand('test_thirst', function(source, args)
        local level = tonumber(args[1]) or 15
        level = math.min(100, math.max(0, level))
        TriggerEvent('esx_status:set', 'thirst', level * 10000)  -- ESX status uses 0-1000000
        exports['okokNotify']:Alert('Debug', 'Thirst set to: ' .. level .. '%', 3000, 'info')
    end, false)
    
    -- Test oxygen effect (simulates underwater)
    RegisterCommand('test_oxygen', function(source, args)
        local level = tonumber(args[1]) or 15
        
        -- Create temporary thread to simulate oxygen depletion
        Citizen.CreateThread(function()
            local originalOxygen = GetPlayerUnderwaterTimeRemaining(PlayerId())
            SetPlayerUnderwaterTime(PlayerId(), level / 10)  -- Convert percent to seconds (divided by 10)
            
            -- Force oxygen display by simulating underwater
            local originalCoords = GetEntityCoords(PlayerPedId())
            SetPedConfigFlag(PlayerPedId(), 65, true)  -- Set underwater flag
            
            exports['okokNotify']:Alert('Debug', 'Oxygen set to: ' .. level .. '%', 3000, 'info')
            exports['okokNotify']:Alert('Debug', 'Will reset in 10 seconds', 3000, 'warning')
            
            Citizen.Wait(10000)  -- Reset after 10 seconds
            
            -- Reset oxygen and ped config
            SetPlayerUnderwaterTime(PlayerId(), originalOxygen)
            SetPedConfigFlag(PlayerPedId(), 65, false)
            
            exports['okokNotify']:Alert('Debug', 'Oxygen test complete', 3000, 'success')
        end)
    end, false)
    
    -- Test HUD toggle
    RegisterCommand('test_hud', function(source, args)
        local state = args[1]
        if state == "show" then
            toggleHud(true)
            exports['okokNotify']:Alert('Debug', 'HUD shown', 3000, 'info')
        elseif state == "hide" then
            toggleHud(false)
            exports['okokNotify']:Alert('Debug', 'HUD hidden', 3000, 'info')
        else
            toggleHud(not uivisible)
            exports['okokNotify']:Alert('Debug', 'HUD toggled: ' .. (uivisible and 'visible' or 'hidden'), 3000, 'info')
        end
    end, false)
    
    -- Reset all effects to normal
    RegisterCommand('test_reset', function()
        -- Reset health
        SetEntityHealth(PlayerPedId(), 200)
        
        -- Reset hunger and thirst
        TriggerEvent('esx_status:set', 'hunger', 1000000)
        TriggerEvent('esx_status:set', 'thirst', 1000000)
        
        -- Reset drunk
        drunkLevel = 0
        
        -- Reset oxygen
        SetPlayerUnderwaterTime(PlayerId(), 20.0)
        
        -- Reset movement
        if healthEffect or drunkEffect then
            ResetPedMovementClipset(PlayerPedId(), 0)
            SetPedMoveRateOverride(PlayerPedId(), 1.0)
            healthEffect = false
            drunkEffect = false
        end
        
        -- Stop screen effects
        StopGameplayCamShaking(true)
        StopScreenEffect("DeathFailOut")
        ClearTimecycleModifier()
        
        exports['okokNotify']:Alert('Debug', 'All effects have been reset', 3000, 'success')
    end, false)
    
    -- Display help message for debug commands
    RegisterCommand('test_help', function()
        TriggerEvent('chat:addMessage', {
            color = {255, 200, 0},
            multiline = true,
            args = {
                'HUD Debug Commands:',
                '/test_drunk [0-100] - Set drunk level\n' ..
                '/test_health [0-200] - Set health level\n' ..
                '/test_hunger [0-100] - Set hunger level\n' ..
                '/test_thirst [0-100] - Set thirst level\n' ..
                '/test_oxygen [0-100] - Test oxygen depletion\n' ..
                '/test_hud [show/hide] - Toggle HUD visibility\n' ..
                '/test_reset - Reset all effects to normal'
            }
        })
    end, false)
    
    -- Notify that debug commands are available
    Citizen.Wait(5000) -- Wait for resources to load
    exports['okokNotify']:Alert('Debug', 'HUD debug commands available. Type /test_help for list.', 5000, 'info')
end)