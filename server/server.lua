RegisterServerEvent('icemallow-drag-server:attach')
AddEventHandler('icemallow-drag-server:attach', function(Player)
	TriggerClientEvent('icemallow-drag:attach', Player, source)
end)

RegisterServerEvent('icemallow-drag-server:deattach')
AddEventHandler('icemallow-drag-server:deattach', function(Player)
	TriggerClientEvent('icemallow-drag:deattach', Player, source)
end)
