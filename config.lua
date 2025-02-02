Config = {}

Config.FrameworkObj = 'QBCore:GetObject'
Config.PlayerLoaded = 'QBCore:OnPlayerLoaded' --untested

Config.Locale = 'en'

-- Default: false | This just prints things in console
Config.Debug = true

Config.Airdrops = {
    Command = { -- Command which spawns Airdrop | Command can be disabled: enable = false | You can configure the name of the command and also who can execute it
        enabled = true,
        name = 'airdrop',
        groups = {'admin', 'god'}
    },
    OnlyCommand = false, -- true = only admins with commands can spawn in airdrops | false = time interval between automatic spawn (command will also be active)
    CoordsOfCommand = true, -- Spawn Airdrop on command executor's location
    Cooldown = { min = 1, max = 2 }, -- Minutes | Cooldown time before next airdrop spawns in | Default: { min = 5, max = 15 }
    CommandRestart = false, -- Does Command (if enabled) restart Cooldown time of next airdrop | Default: false
    FallSpeed = 1, -- Try modifying this to see how fast You want the Airdrop to go down | Lowering number, means slowing down airdrop fall speed | Default: 1
    SpawnOffline = false, -- Will Airdrops spawn when there're no players online | Default: false
    CollectTime = 10, -- Time it takes to pickup airdrop | Seconds
    DeletePrevious = false, -- Deletes Previous Airdrop if new is spawned
    UseFlareParticles = true,
}

-- Locations of where the Airdrops can spawn
Config.Locations = {
    vector3(-55.02, -1764.84, 200.0),
    vector3(-93.91, -1749.73, 200.0),
    --vector3(-139.08, -1712.92, 200.0)
}

-- Loot Table is chosen randomly, unless admin spawns it with specific ID. If randomly chosen Loot Table doesn't meet chance %, the script will automatically try to select other Loot Table
Config.LootTables = {
    [1] = {
        Chance = 100, -- Chance that this Airdrop (If Selected) will spawn | If called by command, this Chance doesn't matter | Value in %
        Items = { -- Item you get list | Types: 'item', 'weapon', 'account'
            { name = 'water', count = 3, type = 'item' },
            { name = 'bread', count = 2, type = 'item' },
        }
    },
    [2] = {
        Chance = 10,
        Items = {
            { name = 'WEAPON_PISTOL', count = 2, type = 'weapon' },
            { name = 'WEAPON_APPISTOL', count = 1, type = 'weapon' },
            { name = 'money', count = 5000, type = 'account' },
        }
    },
}

Config.Object = 'prop_drop_armscrate_01'

Config.Blip = {
    Enabled = true,
    Sprite = 306,
    Colour = 28,
    Scale = 0.8,
    ShortRange = true,
}

QBCore = exports['qb-core']:GetCoreObject()
local src = source
-- Functions
Config.Notification = function(msg) -- Client Side | Custom Notification if You want | By Default: ESX Notification
    --TriggerEvent('esx:showNotification', msg)
    TriggerClientEvent('QBCore:Notify', src, msg)
    
end

Config.ProgressBar = function(msg, time) -- Client Side | Custom Progress Bar | This function can return true (Airdrop will be looted) or false (Airdrop won't be looted)
    Wait(1000)

    return true
end

Config.NotifyPlayers = function(msg, coords) -- Server Side | Should be perhaps some kind of email to the player's phone | For testing it is made as Default ESX Notification
    --TriggerClientEvent('esx:showNotification', -1, msg)
    TriggerClientEvent('QBCore:Notify', src, msg)
end

Config.NotifyExecute = function(playerId, xPlayer) -- Server Side | This function is triggered when someone spawn in airdrop through command | You can add logs for example here and get identifier, name from playerId or xPlayer

end

