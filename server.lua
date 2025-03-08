RegisterServerEvent('tgr:syncCarLights')
AddEventHandler('tgr:syncCarLights', function(status)
    TriggerClientEvent('tgr:syncCarLights', -1, source, status)
end)