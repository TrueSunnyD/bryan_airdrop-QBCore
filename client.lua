QBCore = exports['qb-core']:GetCoreObject()
local airdrops = {}

Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent(Config.FrameworkObj, function(obj) QBCore = obj end)
        Wait(100)
    end

    while QBCore.Functions.GetPlayerData().job == nil do Wait(100) end

    Citizen.CreateThread(function() StartScript(); end)
    Citizen.CreateThread(function() ShowLocations(); end)
    if Config.Debug then print(string.format('%s Started Successfully | Client Side', GetCurrentResourceName())) end
end)

RegisterNetEvent('bryan_airdrops:syncAirdrops', function(airdropsSv)
    airdrops = airdropsSv
end)

RegisterNetEvent('bryan_airdrops:removeObject', function(id)
    RemoveObject(id)
end)

RegisterNetEvent('bryan_airdrops:removeAllObjects', function()
    for k, v in pairs(airdrops) do
        RemoveObject(v.id)
    end

    airdrops = {}
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k, v in pairs(airdrops) do
            if v.object then
                RemoveObject(v.id)
            end
        end
    end
end)

StartScript = function()
    while true do
        local wait = 1000

        if #airdrops > 0 then
            wait = 1

            for k, v in pairs(airdrops) do
                if not v.landed then
                    airdrops[k].coords = airdrops[k].coords - vector3(0.0, 0.0, 0.01 * Config.Airdrops.FallSpeed)
                end

                if v.object and DoesEntityExist(v.object) then
                    if GetEntityHeightAboveGround(v.object) > 0.2 then
                        SetEntityCoords(v.object, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, false)
                    elseif not v.landed then
                        airdrops[k].landed = true
                        TriggerServerEvent('bryan_airdrops:airdropLanded', v.id)
                    end
                elseif not v.spawning and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), v.coords, true) <= 50.0 then
                    SpawnObject(k, v.coords)
                end

                if not v.blip then
                    AddBlip(k, v.coords)
                end
            end
        end

        Wait(wait)
    end
end

ShowLocations = function()
    while true do
        local wait = 500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for k, v in pairs(airdrops) do
            if v.landed then
                local distance = GetDistanceBetweenCoords(coords, v.coords, true)

                if distance <= 3.0 then
                    wait = 2
                    DrawText3D(v.coords, _U('3d_press_to_pickup'), 0.8, 4)

                    if IsControlJustPressed(1, 51) then
                        Config.ProgressBar(_U('progress_bar_picking_up'), Config.Airdrops.CollectTime * 1000)

                        TriggerServerEvent('bryan_airdrops:pickupAirdrop', v.id)
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end

SpawnObject = function(id, coords)
    airdrops[id].spawning = true

    local model = GetHashKey(Config.Object)

    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(10) end

    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, true)

    if Config.Debug then print('Object Spawned') end
    FreezeEntityPosition(obj, true)
    airdrops[id].object = obj

    if Config.Airdrops.UseFlareParticles then
        RequestNamedPtfxAsset('core')
        while not HasNamedPtfxAssetLoaded('core') do Citizen.Wait(10) end

        if Config.Debug then print('Particles Loaded') end

        UseParticleFxAssetNextCall("core")
        SetParticleFxNonLoopedColour(1.0, 0.0, 0.0)
        StartParticleFxLoopedOnEntity('weap_heist_flare_trail', obj, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0)
    end
end

AddBlip = function(id, coords)
    if Config.Blip.Enabled then
        local blip = AddBlipForCoord(coords)
        SetBlipSprite(blip, Config.Blip.Sprite)
        SetBlipColour(blip, Config.Blip.Colour)
        SetBlipScale(blip, Config.Blip.Scale)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, Config.Blip.ShortRange)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(_U('blip_name')) 
        EndTextCommandSetBlipName(blip)

        airdrops[id].blip = blip
    end
end

RemoveObject = function(id)
    for k, v in pairs(airdrops) do
        if v.id == id then
            DeleteObject(v.object)
            if Config.Blip.Enabled then RemoveBlip(v.blip) end
        end
    end
end



local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end
