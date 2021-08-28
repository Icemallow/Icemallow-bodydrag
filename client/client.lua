local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function GetClosestPlayer()
    local players = GetPlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = PlayerPedId()
    local plyCoords = GetEntityCoords(ply)
	--
    for index,value in ipairs(players) do
        local target = GetPlayerPed(value)
        if(target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = GetDistanceBetweenCoords(targetCoords['x'], targetCoords['y'], targetCoords['z'], plyCoords['x'], plyCoords['y'], plyCoords['z'], true)
			print(target)
            if Config.ShowDistance > distance and IsPedDeadOrDying(target, 0) then
                closestPlayer = value
				break
            end
        end
    end
	--
    return closestPlayer
end

function GetPlayers()
    local players = {}
	--
    for i = 0, 1024 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end
	--
    return players
end

local drag = false
local draggingPed = nil
local animFinished = false
local draggingPlayer = nil
local Player = nil


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(7)
        local p1 = PlayerPedId()
		
		if not IsPedDeadOrDying(p1) and not drag then
			local p1pos	= GetEntityCoords(p1)
			--print(Player)
			local p2 = GetPlayerPed(Player)
			local p2pos = GetEntityCoords(p2)

			if GetDistanceBetweenCoords(p2pos, p1pos, true) <= Config.ShowDistance then
				if IsPedDeadOrDying(p2, 0) then
					if GetEntityHealth(p2) <= 6 then
						SetEntityInvincible(p2, true)
						if GetDistanceBetweenCoords(p2pos, p1pos, true) <= Config.InteractDistance then
						DrawText3D(p2pos.x, p2pos.y, p2pos.z, '~w~[~b~E~w~] Drag')

							if IsControlJustPressed(0, 206) then
								drag = true
								draggingPed = p2
								draggingPlayer = Player
								--
								while not HasAnimDictLoaded('combat@drag_ped@') do
									RequestAnimDict('combat@drag_ped@')
									Wait(0)
								end
								--
								local duration = 5700
								TaskPlayAnim(p1, 'combat@drag_ped@', 'injured_pickup_back_plyr', 2.0, 2.0, duration, 1, 0, false, false, false)
								TriggerServerEvent('icemallow-drag-server:attach', GetPlayerServerId(Player))
								Citizen.Wait(duration)
								animFinished = true
								TaskPlayAnim(p1, 'combat@drag_ped@', 'injured_drag_plyr', 2.0, 2.0, -1, 1, 0, false, false, false)
							end
						end
					end
				end
			end
		end
	end
end)


Citizen.CreateThread(function()
	local sleep = 500
	while true do
		if Player == nil then
			sleep = 500
			Player = GetClosestPlayer()
		else
			Player = GetClosestPlayer()
			sleep = 1000
		end
		Citizen.Wait(sleep)
	end
end)



Citizen.CreateThread(function()
	local sleep = 5000
	while true do
		if drag and animFinished then
			local playerPed = PlayerPedId()
			sleep = 7
			if IsControlPressed(0, 30) then
				SetEntityHeading(playerPed, GetEntityHeading(playerPed)+0.5)
			elseif IsControlPressed(0, 34) then
				SetEntityHeading(playerPed, GetEntityHeading(playerPed)-0.5)
			end
			if IsControlJustPressed(0, 47) then
				drag = false
				animFinished = false
				draggingPed = nil
				RequestAnimDict('combat@drag_ped@')
				TaskPlayAnim(playerPed, 'combat@drag_ped@', 'injured_putdown_plyr', 2.0, 2.0, 5500, 1, 0, false, false, false)
				TriggerServerEvent('icemallow-drag-server:deattach', GetPlayerServerId(draggingPlayer))
				draggingPlayer = nil
			end
		else
			sleep = 1000
		end
		Citizen.Wait(sleep)
	end
end)

RegisterNetEvent('icemallow-drag:attach')
AddEventHandler('icemallow-drag:attach', function(who)
	local p1 = PlayerPedId()
	local p2 = GetPlayerPed(GetPlayerFromServerId(who))
	local coords = GetEntityCoords(p1)
	local coords2 = GetEntityCoords(p2)
	SetEntityCoordsNoOffset(p1, coords.x, coords.y, coords.z, false, false, false, true)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(p2), true, false)
	SetEntityHeading(p1, GetEntityHeading(p2))
	SetEntityHealth(p1, GetPedMaxHealth(p1))
	
	AttachEntityToEntity(p1, p2, 11816, 0.0, 0.5, 0.0, GetEntityRotation(coords2), false, false, true, false, 2, false)
	
	while not HasAnimDictLoaded('combat@drag_ped@') do
		RequestAnimDict('combat@drag_ped@')
		Wait(0)
	end
	TaskPlayAnim(p1, 'combat@drag_ped@', 'injured_pickup_back_ped', 2.0, 2.0, -1, 1, 0, false, false, false)
	--TriggerEvent('playerSpawned', coords.x, coords.y, coords.z)
	Citizen.Wait(5700)
	TaskPlayAnim(p1, 'combat@drag_ped@', 'injured_drag_ped', 2.0, 2.0, -1, 1, 0, false, false, false)
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)
end)

RegisterNetEvent('icemallow-drag:deattach')
AddEventHandler('icemallow-drag:deattach', function(who)
	local p1 = PlayerPedId()
	local p2 = GetPlayerPed(GetPlayerFromServerId(who))
	
	RequestAnimDict('combat@drag_ped@')
	TaskPlayAnim(p1, 'combat@drag_ped@', 'injured_putdown_ped', 2.0, 2.0, 5700, 1, 0, false, false, false)

	Citizen.Wait(5700)
	
	DetachEntity(p1, true, true)
	SetEntityHealth(p1, 0)
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', true)
end)

function DrawText3D(x, y, z, text)
	SetTextScale(0.30, 0.30)
    SetTextFont(8)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 255, 51, 51, 80)
    ClearDrawOrigin()
end

