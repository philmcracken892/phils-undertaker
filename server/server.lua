local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

----------------------------------------------------
-- generate wagon plate
----------------------------------------------------
local function GeneratePlate()
    local UniqueFound = false
    local plate = nil
    while not UniqueFound do
        plate = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM `phils_bountywagon` WHERE plate = ?", { plate })
        if result == 0 then
            UniqueFound = true
        end
    end
    return plate
end
----------------------------------------------------
-- buy and add hunting cart
----------------------------------------------------
RegisterServerEvent('phils-bounty:server:buyhuntingcart', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local cashBalance = Player.PlayerData.money["cash"]
    
    if cashBalance >= Config.WagonPrice then
        -- Escape the table name with backticks
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM `phils_bountywagon` WHERE citizenid = ?", { citizenid })
        
        local plate = GeneratePlate()
        MySQL.insert('INSERT INTO `phils_bountywagon`(citizenid, plate, huntingcamp, damaged, active) VALUES(@citizenid, @plate, @huntingcamp, @damaged, @active)', {
            ['@citizenid'] = citizenid,
            ['@plate'] = plate,
            ['@huntingcamp'] = data.huntingcamp,
            ['@damaged'] = 0,
            ['@active'] = 1,
        })
        Player.Functions.RemoveMoney('cash', Config.WagonPrice)
        
        local newCount = result + 1
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_1'), description = locale('sv_lang_2') .. locale('sv_lang_29') .. newCount .. locale('sv_lang_30'), type = 'success', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_5'), description = '$'..Config.WagonPrice..locale('sv_lang_6'), type = 'error', duration = 7000 })
    end
end)

----------------------------------------------------
-- get wagons
----------------------------------------------------
RSGCore.Functions.CreateCallback('phils-bounty:server:getwagons', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local wagon = MySQL.query.await('SELECT * FROM `phils_bountywagon` WHERE citizenid=@citizenid', { ['@citizenid'] = citizenid })
    cb(wagon or {}) 
end)

----------------------------------------------------
-- get wagon store
----------------------------------------------------
RSGCore.Functions.CreateCallback('phils-bounty:server:getwagonstore', function(source, cb, plate)
    local wagonstore = MySQL.query.await('SELECT * FROM `phils_bountywagon_inventory` WHERE plate=@plate', { ['@plate'] = plate })
    cb(wagonstore or {}) 
end)

----------------------------------------------------
-- get tarp info
----------------------------------------------------
RSGCore.Functions.CreateCallback('phils-bounty:server:gettarpinfo', function(source, cb, plate)
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM `phils_bountywagon_inventory` WHERE plate = ?", { plate })
    cb(result or 0)
end)

----------------------------------------------------
-- store good hunting wagon
----------------------------------------------------
RegisterServerEvent('phils-bounty:server:updatewagonstore', function(location, plate)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local newLocation = MySQL.query.await('UPDATE `phils_bountywagon` SET huntingcamp = ? WHERE plate = ?', { location, plate })

    if newLocation == nil then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_7'), description = locale('sv_lang_8'), type = 'error', duration = 5000 })
        return
    end
    
    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_9'), description = locale('sv_lang_10')..location, type = 'success', duration = 5000 })
end)

----------------------------------------------------
-- store damaged hunting wagon
----------------------------------------------------
RegisterServerEvent('phils-bounty:server:damagedwagon', function(location, plate)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local newLocation = MySQL.query.await('UPDATE `phils_bountywagon` SET huntingcamp = ? WHERE plate = ?', { location, plate })
    local newDamage = MySQL.query.await('UPDATE `phils_bountywagon` SET damaged = ? WHERE plate = ?', { 1, plate })

    if (newLocation == nil) or (newDamage == nil) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_11'), description = locale('sv_lang_12'), type = 'error', duration = 5000 })
        return
    end
    
    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_13'), description = locale('sv_lang_14')..location, type = 'success', duration = 5000 })
end)

----------------------------------------------------
-- fix damaged hunting wagon
----------------------------------------------------
RegisterServerEvent('phils-bounty:server:fixhuntingwagon', function(plate, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local cashBalance = Player.PlayerData.money['cash']
    if cashBalance >= price then
        Player.Functions.RemoveMoney('cash', price)
        MySQL.update('UPDATE `phils_bountywagon` SET damaged = ? WHERE plate = ?', { 0, plate })
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_15'), description = locale('sv_lang_16'), type = 'success', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_17'), description = locale('sv_lang_18'), type = 'error', duration = 5000 })
    end
end)

----------------------------------------------------
-- add holding animal to database
----------------------------------------------------
RegisterServerEvent('phils-bounty:server:addnpc', function(npchash, npclabel, npclooted, plate)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then
        print("Debug: Player not found for source ", src)
        return
    end
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM `phils_bountywagon_inventory` WHERE plate = ?", { plate })
    if result < Config.TotalPedsStored then
        local success, err = MySQL.insert('INSERT INTO `phils_bountywagon_inventory`(animalhash, animallabel, animallooted, citizenid, plate) VALUES(@npchash, @npclabel, @npclooted, @citizenid, @plate)', {
            ['@npchash'] = npchash,
            ['@npclabel'] = npclabel,
            ['@npclooted'] = npclooted,
            ['@citizenid'] = citizenid,
            ['@plate'] = plate
        })
        if not success then
            
            --TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Failed to store NPC in database!", type = 'error', duration = 5000 })
            return
        end
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_lang_19'), description = npclabel .. locale('sv_lang_20'), type = 'success', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_lang_21'), description = locale('sv_lang_22') .. Config.TotalPedsStored .. locale('sv_lang_23'), type = 'error', duration = 5000 })
    end
end)

RegisterServerEvent('phils-bounty:server:removeanimal', function(data)
    local src = source
    MySQL.update('DELETE FROM `phils_bountywagon_inventory` WHERE id = ? AND plate = ?', { data.id, data.plate })
    TriggerClientEvent('phils-bounty:client:takeoutanimal', src, data.animalhash, data.animallooted)
end)

RegisterServerEvent('phils-bounty:server:sellnpcs', function(plate)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then
        
        return
    end
    local citizenid = Player.PlayerData.citizenid

    -- Verify wagon exists and belongs to player
    local wagon, err = MySQL.query.await("SELECT * FROM `phils_bountywagon` WHERE citizenid=@citizenid AND plate=@plate", {
        ['@citizenid'] = citizenid,
        ['@plate'] = plate
    })
    if err then
       
        TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Database error: Failed to fetch wagon", type = 'error', duration = 5000 })
        return
    end
    if not wagon[1] then
       
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_lang_26'), description = locale('sv_lang_27'), type = 'error', duration = 5000 })
        return
    end

    
    local npcs, err = MySQL.query.await('SELECT * FROM `phils_bountywagon_inventory` WHERE plate=@plate', { ['@plate'] = plate })
    if err then
       
        TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Database error: Failed to fetch NPCs", type = 'error', duration = 5000 })
        return
    end
    if not npcs or #npcs == 0 then
        
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_lang_31'), description = locale('sv_lang_32'), type = 'error', duration = 5000 })
        return
    end

    
    local pricePerNPC = Config.PricePerNPC or 50 
    local totalPrice = #npcs * pricePerNPC
   

    
    local success, err = MySQL.update('DELETE FROM `phils_bountywagon_inventory` WHERE plate = ?', { plate })
    if err then
       
        TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Database error: Failed to clear inventory", type = 'error', duration = 5000 })
        return
    end

  
    Player.Functions.AddMoney('cash', totalPrice)

   
    TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_lang_33'), description = locale('sv_lang_34') .. totalPrice, type = 'success', duration = 5000 })
end)
RegisterServerEvent('phils-bounty:server:removenpc', function(data)
    local src = source
    MySQL.update('DELETE FROM `phils_bountywagon_inventory` WHERE id = ? AND plate = ?', { data.id, data.plate })
    TriggerClientEvent('phils-bounty:client:takeoutnpc', src, data.animalhash, data.animallooted)
end)


RegisterServerEvent('phils-bounty:server:sellhuntingcart')
AddEventHandler('phils-bounty:server:sellhuntingcart', function(plate)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    local sellPrice = (Config.WagonPrice * Config.WagonSellRate)

    local wagon = MySQL.query.await("SELECT * FROM `phils_bountywagon` WHERE citizenid=@citizenid AND plate=@plate", {
        ['@citizenid'] = citizenid,
        ['@plate'] = plate
    })

    if wagon[1] then
        MySQL.update('DELETE FROM `phils_bountywagon` WHERE id = ?', { wagon[1].id })
        MySQL.update('DELETE FROM stashitems WHERE stash = ?', { wagon[1].plate })
        Player.Functions.AddMoney('cash', sellPrice)
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_lang_24'), description = locale('sv_lang_25') .. sellPrice, type = 'success', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_lang_26'), description = locale('sv_lang_27'), type = 'error', duration = 5000 })
    end
end)



RegisterServerEvent('phils-bounty:server:wagonstorage', function(plate)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local data = { label = locale('sv_lang_28'), maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots }
    local stashName = plate
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)
