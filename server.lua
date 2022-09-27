local QBCore = exports['qb-core']:GetCoreObject()
local airdrops = {}
local tryCount = 0
local cooldown = math.random(Config.Airdrops.Cooldown.min, Config.Airdrops.Cooldown.max)

TriggerEvent(Config.FrameworkObj, function(obj) QBCore = obj end)

--Functions

local function RestartCooldown()
    cooldown = math.random(Config.Airdrops.Cooldown.min, Config.Airdrops.Cooldown.max)
end


local function IsLocationTaken(location)
    for k, v in pairs(airdrops) do
        if v.coords == location then
            return true
        end
    end

    return false
end

local function SelectLoottable(lootTable)
    if lootTable ~= nil then
        return Config.LootTables[lootTable].Items
    else
        local randomLootTable = Config.LootTables[math.random(1, #Config.LootTables)]
        local chance = math.random(1, 100)

        while randomLootTable.Chance < chance do
            Wait(10)
            
            randomLootTable = Config.LootTables[math.random(1, #Config.LootTables)]
            chance = math.random(1, 100)

            if Config.Debug then print('searching ' .. randomLootTable.Chance < chance) end
        end

        return randomLootTable.Items
    end
end


local function RemoveAirdrop(id)
    for k, v in pairs(airdrops) do
        if v.id == id then
            airdrops[k] = nil
            break
        end
    end
end


local function RewardPlayer(source, items)             --Still need to convert to qb-core
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)

    for k, v in pairs(items) do
        if v.type == 'item' then
            xPlayer.Functions.AddItem(v.name, v.count)
        elseif v.type == 'weapon' then
            xPlayer.Functions.AddItem(v.name, v.count)
        elseif v.type == 'account' then
            --xPlayer.addAccountMoney(v.name, v.count) --Still need to convert to qb-core
            xPlayer.Functions.AddMoney('cash', tonumber(v.count))
        end
    end
end


local function GetAirdrop(id)
    for k, v in pairs(airdrops) do
        if v.id == id then
            return v
        end
    end

    return nil
end


local function GetAirdropIndex(id)
    for k, v in pairs(airdrops) do
        if v.id == id then
            return k
        end
    end

    return nil
end


local function SpawnAirdrop(lootTable, customCoords)
    local randomLocation = Config.Locations[math.random(1, #Config.Locations)]
    local isLocationTaken = IsLocationTaken(randomLocation)
    
    if Config.Debug then print(tryCount > 10, not isLocationTaken) end
    if tryCount > 10 or not isLocationTaken or customCoords then
        tryCount = 0
        
        local airdropId = math.random(10000, 99999)
        local airdropItems = SelectLoottable(lootTable)

        local coords = randomLocation

        if customCoords then coords = customCoords
        elseif coords.z < 150.0 then coords = vector3(randomLocation.x, randomLocation.y, 200.0) end

        if Config.Airdrops.DeletePrevious then
            TriggerClientEvent('bryan_airdrops:removeAllObjects', -1)
            airdrops = {}
        end

        table.insert(airdrops, {
            id = airdropId,
            items = airdropItems,
            coords = coords
        })

        if Config.Debug then print('Airdrop Spawned') end
        TriggerClientEvent('bryan_airdrops:syncAirdrops', -1, airdrops)
        Config.NotifyPlayers('Airdrop has been Called In!') --Need to look into a global alert event converting to QBCore


        Citizen.CreateThread(function()
            local airdropIndex = GetAirdropIndex(airdropId)

            while not airdrops[airdropIndex].landed do
                airdrops[airdropIndex].coords = airdrops[airdropIndex].coords - vector3(0.0, 0.0, 0.01 * Config.Airdrops.FallSpeed)
                Wait(1)
            end

            if Config.Debug then print(string.format('Airdrop (ID: %s) Landed', airdrops[airdropIndex].id)) end
        end)
    elseif isLocationTaken then 
        tryCount = tryCount + 1
        SpawnAirdrop(lootTable)
    end
end


local function StartAirdropLoop()
    while true do
        while cooldown > 0 do
            if Config.Debug then print(string.format('%s Minutes Till Next Airdrop Spawn', cooldown)) end
            Wait(60 * 1000)
            cooldown = cooldown - 1
        end

        RestartCooldown()
        if Config.Airdrops.SpawnOffline or (not Config.Airdrops.SpawnOffline and #QBCore.Functions.GetPlayers() > 0) then
            SpawnAirdrop()
        end

        Wait(10)
    end
end




--Events


AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.Debug then print(string.format('%s Started Successfully | Server Side', GetCurrentResourceName())) end

        if not Config.Airdrops.OnlyCommand then
            Citizen.CreateThread(function() StartAirdropLoop(); end)
        end
    end
end)

RegisterNetEvent('QBCore:playerLoaded', function(playerId, xPlayer)
    TriggerClientEvent('bryan_airdrops:syncAirdrops', playerId, airdrops)
end)

RegisterNetEvent('bryan_airdrops:pickupAirdrop', function(id)
    local airdrop = GetAirdrop(id)

    if airdrop then
        RewardPlayer(source, airdrop.items)
        RemoveAirdrop(id)
        TriggerClientEvent('bryan_airdrops:removeObject', -1, id)
        TriggerClientEvent('bryan_airdrops:syncAirdrops', -1, airdrops)
    else
        if Config.Debug then
            print('Could not find airdrop by it\'s ID')
        end
    end
end)

RegisterNetEvent('bryan_airdrops:airdropLanded', function(id)
    local airdropIndex = GetAirdropIndex(id)

    airdrops[airdropIndex].landed = true
end)



if Config.Airdrops.Command.enabled then
    QBCore.Commands.Add(Config.Airdrops.Command.name,"Create an airdrop manually", {}, false, function(xPlayer, args, showError)
        local src = source
        local xPlayer = QBCore.Functions.GetPlayer(src)
        if Config.Debug then print(args.lootTable == nil, Config.LootTables[args.lootTable] ~= nil) end
            if args.lootTable == nil or Config.LootTables[args.lootTable] ~= nil then
                if Config.Airdrops.Command.CommandRestart then RestartCooldown() end

                if Config.Airdrops.CoordsOfCommand and (xPlayer and xPlayer.src) then
                    SpawnAirdrop(args.lootTable, GetEntityCoords(GetPlayerPed(xPlayer.src)) + vector3(0.0, 0.0, 150.0))
                else
                    SpawnAirdrop(args.lootTable)
                end

            if xPlayer and xPlayer.source then
                Config.NotifyExecute(xPlayer.source, xPlayer)
            end
        else
            --showError(_U('command_error_loottable_not_found', args.lootTable))
            TriggerClientEvent("QBCore:Notify", src "Loot Table (ID: %s) Not Found", args.lootTable, 'error')
        end
    end, true, {help = 'Spawn An Airdrop', validate = false, arguments = {
        { name = 'lootTable', help = "Loot Table ID | Not Necessary", type = 'number' },
    }})
end
