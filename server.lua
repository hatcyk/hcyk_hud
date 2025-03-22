RegisterServerEvent('hcyk_hud:syncCarLights')
AddEventHandler('hcyk_hud:syncCarLights', function(status)
    TriggerClientEvent('hcyk_hud:syncCarLights', -1, source, status)
end)