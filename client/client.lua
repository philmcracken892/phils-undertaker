local RSGCore = exports['rsg-core']:GetCoreObject()
local huntingwagonspawned = false
local currentHuntingWagon = nil
local currentHuntingPlate = nil
local closestWagonStore = nil
local wagonBlip = nil
lib.locale()

-------------------------------------------------------------------------------------------
-- blips
-------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    for _, v in pairs(Config.HunterLocations) do
        if v.showblip == true then
            local HunterBlip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(HunterBlip, joaat(Config.Blip.blipSprite), true)
            SetBlipScale(HunterBlip, Config.Blip.blipScale)
            SetBlipName(HunterBlip, Config.Blip.blipName)
        end
    end
end)

-------------------------------------------------------------------------------------------
-- hunter camp main menu
-------------------------------------------------------------------------------------------
RegisterNetEvent('phils-bounty:client:openhuntermenu', function(location, wagonspawn)
    lib.registerContext({
        id = 'hunter_mainmenu',
        title = locale('cl_lang_2'),
        options = {
            {
                title = locale('cl_lang_3') .. Config.WagonPrice .. ')',
                description = locale('cl_lang_4'),
                icon = 'fa-solid fa-horse-head',
                serverEvent = 'phils-bounty:server:buyhuntingcart',
                args = { huntingcamp = location },
                arrow = true
            },
            {
                title = locale('cl_lang_5'),
                description = locale('cl_lang_6'),
                icon = 'fa-solid fa-eye',
                event = 'phils-bounty:client:spawnwagon',
                args = { huntingcamp = location, spawncoords = wagonspawn },
                arrow = true
            },
            {
                title = locale('cl_lang_39'),
                icon = 'fa-solid fa-basket-shopping',
                event = 'phils-bounty:client:openshop',
                arrow = true
            },
            {
                title = 'Sell Bodys',
                description = 'Sell all bodys stored in your wagon.',
                icon = 'fa-solid fa-dollar-sign',
                event = 'phils-bounty:client:sellnpcs',
                args = { plate = currentHuntingPlate, huntingcamp = location },
                arrow = true,
                disabled = not huntingwagonspawned or not currentHuntingPlate
            },
        }
    })
    lib.showContext('hunter_mainmenu')
end)

---------------------------------------------------------------------
-- sell bounties
---------------------------------------------------------------------
RegisterNetEvent('phils-bounty:client:sellnpcs', function(data)
    if not huntingwagonspawned or not data.plate then
        lib.notify({ title = locale('cl_lang_7'), description = locale('cl_lang_8'), type = 'error', duration = 5000 })
        return
    end

    RSGCore.Functions.TriggerCallback('phils-bounty:server:gettarpinfo', function(count)
        if count == 0 then
            lib.notify({ title = locale('sv_lang_31'), description = locale('sv_lang_32'), type = 'error', duration = 5000 })
            return
        end

        local input = lib.inputDialog('Sell Bodys', {
            {
                label = 'Confirm selling all bodys in wagon ' .. data.plate .. '?',
                type = 'select',
                options = {
                    { value = 'yes', label = locale('cl_lang_32') },
                    { value = 'no', label = locale('cl_lang_33') }
                },
                required = true,
                icon = 'fa-solid fa-circle-question'
            },
        })

        if not input or input[1] == 'no' then
            return
        end

        if input[1] == 'yes' then
            TriggerServerEvent('phils-bounty:server:sellnpcs', data.plate)
            RSGCore.Functions.TriggerCallback('phils-bounty:server:gettarpinfo', function(results)
                local percentage = results * Config.TotalPedsStored / 100 -- Changed from TotalAnimalsStored to TotalPedsStored
                Citizen.InvokeNative(0x31F343383F19C987, currentHuntingWagon, tonumber(percentage), 1)
            end, data.plate)
        end
    end, data.plate)
end)

---------------------------------------------------------------------
-- get wagon
---------------------------------------------------------------------
RegisterNetEvent('phils-bounty:client:spawnwagon', function(data)
    RSGCore.Functions.TriggerCallback('phils-bounty:server:getwagons', function(results)
        if not results or #results == 0 then
            return lib.notify({ title = locale('cl_lang_7'), description = locale('cl_lang_8'), type = 'inform', duration = 5000 })
        end
        if huntingwagonspawned then
            return lib.notify({ title = locale('cl_lang_9'), description = locale('cl_lang_10'), type = 'error', duration = 5000 })
        end

        local options = {}
        for i = 1, #results do
            local wagon = results[i]
            table.insert(options, {
                title = locale('cl_lang_42') .. wagon.plate,
                description = wagon.huntingcamp .. (wagon.damaged == 1 and locale('cl_lang_43') or ''),
                event = 'phils-bounty:client:spawnSelectedWagon',
                args = { wagon = wagon, spawncoords = data.spawncoords }
            })
        end

        lib.registerContext({
            id = 'wagon_selection_menu',
            title = locale('cl_lang_44'),
            options = options
        })
        lib.showContext('wagon_selection_menu')
    end)
end)

RegisterNetEvent('phils-bounty:client:spawnSelectedWagon', function(data)
    local wagon = data.wagon
    if wagon.damaged == 1 then
        lib.notify({ title = locale('cl_lang_12'), description = locale('cl_lang_13'), type = 'error', duration = 5000 })
        TriggerEvent('phils-bounty:client:fixwagon', wagon.plate)
        return
    end

    local carthash = joaat('coach3_cutscene')
    if wagonBlip then
        RemoveBlip(wagonBlip)
    end

    if IsModelAVehicle(carthash) then
        Citizen.CreateThread(function()
            RequestModel(carthash)
            while not HasModelLoaded(carthash) do
                Citizen.Wait(0)
            end
            local huntingcart = CreateVehicle(carthash, data.spawncoords, true, false)
            Citizen.InvokeNative(0x06FAACD625D80CAA, huntingcart)
            SetVehicleOnGroundProperly(huntingcart)
            currentHuntingWagon = huntingcart
            currentHuntingPlate = wagon.plate
            Wait(200)
            Citizen.InvokeNative(0xF89D82A0582E46ED, huntingcart, 5)
            Citizen.InvokeNative(0x8268B098F6FCA4E2, huntingcart, 2)
            Citizen.InvokeNative(0x06FAACD625D80CAA, huntingcart)

            wagonBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1749618580, huntingcart)
            Citizen.InvokeNative(0x9CB1A1623062F402, wagonBlip, locale('cl_lang_45')..'('..wagon.plate..')')

            SetEntityVisible(huntingcart, true)
            SetModelAsNoLongerNeeded(carthash)

            Wait(1000)

            RSGCore.Functions.TriggerCallback('phils-bounty:server:gettarpinfo', function(results)
                local percentage = results * Config.TotalPedsStored / 100 -- Changed from TotalAnimalsStored to TotalPedsStored
                Citizen.InvokeNative(0x31F343383F19C987, currentHuntingWagon, tonumber(percentage), 1)
            end, wagon.plate)

            exports.ox_target:addLocalEntity(huntingcart, {
                {
                    name = 'hunting_wagon',
                    icon = 'far fa-eye',
                    label = locale('cl_lang_16'),
                    onSelect = function()
                        TriggerEvent('phils-bounty:client:openmenu', wagon.plate)
                    end,
                    distance = Config.TargetDistance
                }
            })

            lib.notify({ title = locale('cl_lang_46'), description = locale('cl_lang_11'), type = 'inform', duration = 5000 })
            huntingwagonspawned = true
        end)
    end
end)


local function SetClosestStoreLocation()
    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist = nil

    for k, v in pairs(Config.HunterLocations) do
        local dest = vector3(v.coords.x, v.coords.y, v.coords.z)
        local dist2 = #(pos - dest)

        if current then
            if dist2 < dist then
                current = v.location
                dist = dist2
            end
        else
            dist = dist2
            current = v.location
        end
    end

    if current ~= closestWagonStore then
        closestWagonStore = current
    end
end

---------------------------------------------------------------------
-- get wagon state
---------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if huntingwagonspawned then
            local drivable = Citizen.InvokeNative(0xB86D29B10F627379, currentHuntingWagon, false, false)
            if not drivable then
                lib.notify({ title = locale('cl_lang_17'), description = locale('cl_lang_18'), type = 'inform', duration = 10000 })
                DeleteVehicle(currentHuntingWagon)
                SetEntityAsNoLongerNeeded(currentHuntingWagon)
                huntingwagonspawned = false
                SetClosestStoreLocation()
                TriggerServerEvent('phils-bounty:server:damagedwagon', closestWagonStore, currentHuntingPlate)
                lib.hideTextUI()
            end
        end
    end
end)

---------------------------------------------------------------------
-- store wagon
---------------------------------------------------------------------
RegisterNetEvent('phils-bounty:client:storewagon', function(data)
    if huntingwagonspawned then
        DeleteVehicle(currentHuntingWagon)
        SetEntityAsNoLongerNeeded(currentHuntingWagon)
        huntingwagonspawned = false
        SetClosestStoreLocation()
        TriggerServerEvent('phils-bounty:server:updatewagonstore', closestWagonStore, currentHuntingPlate)
        if wagonBlip then
            RemoveBlip(wagonBlip)
        end
    end
end)

---------------------------------------------------------------------
-- hunting wagon menu
---------------------------------------------------------------------
RegisterNetEvent('phils-bounty:client:openmenu', function(wagonplate)
    local sellprice = (Config.WagonPrice * Config.WagonSellRate)
    lib.registerContext({
        id = 'hunterwagon_menu',
        title = locale('cl_lang_19'),
        options = {
            {
                title = locale('cl_lang_20'),
                description = locale('cl_lang_21'),
                icon = 'fa-solid fa-circle-down',
                event = 'phils-bounty:client:addnpc',
                args = { plate = wagonplate },
                arrow = true
            },
            {
                title = locale('cl_lang_22'),
                description = locale('cl_lang_23'),
                icon = 'fa-solid fa-circle-up',
                event = 'phils-bounty:client:getHuntingWagonStore',
                args = { plate = wagonplate },
                arrow = true
            },
            {
                title = locale('cl_lang_24'),
                description = locale('cl_lang_25'),
                icon = 'fa-solid fa-box',
                event = 'phils-bounty:client:getHuntingWagonInventory',
                args = { plate = wagonplate },
                arrow = true
            },
            {
                title = locale('cl_lang_26'),
                description = locale('cl_lang_27'),
                icon = 'fa-solid fa-circle-xmark',
                event = 'phils-bounty:client:storewagon',
                arrow = true
            },
            {
                title = locale('cl_lang_28') .. sellprice .. ')',
                description = locale('cl_lang_29'),
                icon = 'fa-solid fa-dollar-sign',
                event = 'phils-bounty:client:sellwagoncheck',
                args = { plate = wagonplate },
                arrow = true
            },
        }
    })
    lib.showContext('hunterwagon_menu')
end)


RegisterNetEvent('phils-bounty:client:sellwagoncheck', function(data)
    local input = lib.inputDialog(locale('cl_lang_30'), {
        {
            label = locale('cl_lang_31'),
            type = 'select',
            options = {
                { value = 'yes', label = locale('cl_lang_32') },
                { value = 'no', label = locale('cl_lang_33') }
            },
            required = true,
            icon = 'fa-solid fa-circle-question'
        },
    })

    if not input or input[1] == 'no' then
        return
    end

    if input[1] == 'yes' then
        TriggerServerEvent('phils-bounty:server:sellhuntingcart', data.plate)
        if huntingwagonspawned then
            DeleteVehicle(currentHuntingWagon)
            SetEntityAsNoLongerNeeded(currentHuntingWagon)
            huntingwagonspawned = false
            exports['rsg-core']:deletePrompt(string.lower(data.plate))
        end
    end
end)


RegisterNetEvent('phils-bounty:client:addnpc', function(data)
    local ped = PlayerPedId()
    local holding = Citizen.InvokeNative(0xD806CD2A4F2C2996, ped) 
    if not holding or holding == 0 then
       
        lib.notify({ title = locale('cl_lang_34'), description = "Not holding any NPC!", type = 'error', duration = 5000 })
        return
    end

    local holdinghash = GetEntityModel(holding)
    local holdinglooted = Citizen.InvokeNative(0x8DE41E9902E85756, holding) 
    local pedType = Citizen.InvokeNative(0xFF059E1E4C01E63C, holding) 
    
   
    local entityExists = DoesEntityExist(holding)
    local isAPed = IsEntityAPed(holding)
    local notPlayer = holding ~= ped
    local isHumanPed = pedType == 4 -- Human ped type
    local isValidPed = entityExists and isAPed and notPlayer and isHumanPed
    
    

    if isValidPed then
        local modelhash = holdinghash
        local modellabel = "Body"
        local modellooted = holdinglooted
        local deleted = DeleteThis(holding, modellabel)
        if deleted then
            TriggerServerEvent('phils-bounty:server:addnpc', modelhash, modellabel, modellooted, data.plate)
            RSGCore.Functions.TriggerCallback('phils-bounty:server:gettarpinfo', function(results)
                local change = (results + 1)
                local percentage = change * Config.TotalPedsStored / 100
                Citizen.InvokeNative(0x31F343383F19C987, currentHuntingWagon, tonumber(percentage), 1)
            end, data.plate)
            lib.notify({ title = locale('cl_lang_34'), description = "Body stored successfully!", type = 'success', duration = 5000 })
        else
            --lib.notify({ title = locale('cl_lang_34'), description = "good work", type = 'error', duration = 5000 })
        end
    else
        local errorMsg = "Held entity is not a valid human NPC! (Exists: " .. tostring(entityExists) .. ", IsPed: " .. tostring(isAPed) .. ", NotPlayer: " .. tostring(notPlayer) .. ", IsHuman: " .. tostring(isHumanPed) .. ")"
        if pedType == 28 then
            errorMsg = "You cannot store animals in the bounty wagon!"
        end
        
        ---lib.notify({ title = locale('cl_lang_34'), description = errorMsg, type = 'error', duration = 5000 })
    end
end)


function DeleteThis(holding, modellabel)
    local attempts = 0
    while not NetworkRequestControlOfEntity(holding) and attempts < 5 do
        Wait(100)
        attempts = attempts + 1
    end
    if attempts >= 5 then
       
        return false
    end
    SetEntityAsMissionEntity(holding, true, true)
    Wait(100)
    lib.progressBar({
        duration = Config.StoreTime,
        label = locale('cl_lang_47') .. modellabel,
        useWhileDead = false,
        canCancel = false
    })
    DeleteEntity(holding)
    Wait(500)
    local entitycheck = Citizen.InvokeNative(0xD806CD2A4F2C2996, cache.ped)
    local holdingcheck = GetPedType(entitycheck)
    if holdingcheck == 0 then
        return true
    else
       
        return false
    end
end


---------------------------------------------------------------------
RegisterNetEvent('phils-bounty:client:getHuntingWagonStore', function(data)
    RSGCore.Functions.TriggerCallback('phils-bounty:server:getwagonstore', function(results)
        local options = {}
        for k, v in ipairs(results) do
            options[#options + 1] = {
                title = v.animallabel, 
                description = '',
                icon = 'fa-solid fa-box',
                serverEvent = 'phils-bounty:server:removenpc',
                args = {
                    id = v.id,
                    plate = v.plate,
                    animallooted = v.animallooted,
                    animalhash = v.animalhash,
                },
                arrow = true,
            }
        end
        lib.registerContext({
            id = 'hunting_inv_menu',
            title = locale('cl_lang_36'),
            position = 'top-right',
            options = options
        })
        lib.showContext('hunting_inv_menu')
    end, data.plate)
end)


RegisterNetEvent('phils-bounty:client:takeoutnpc', function(npchash, npclooted)
    local pos = GetOffsetFromEntityInWorldCoords(currentHuntingWagon, 0.0, -3.0, 0.0)
    
    modelHash = tonumber(npchash)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(1)
        end
    end

    local npc = CreatePed(modelHash, pos.x, pos.y, pos.z, true, true, true)
    Citizen.InvokeNative(0x77FF8D35EEC6BBC4, npc, 0, false)

    if npclooted == 1 then
        Citizen.InvokeNative(0x6BCF5F3D8FFE988D, npc, npclooted)
        SetEntityHealth(npc, 0, 0)
        SetEntityAsMissionEntity(npc, true, true)
    else
        SetEntityHealth(npc, 0, 0)
        SetEntityAsMissionEntity(npc, true, true)
    end
    
    RSGCore.Functions.TriggerCallback('phils-bounty:server:gettarpinfo', function(results)
        local change = (results - 1)
        local percentage = change * Config.TotalPedsStored / 100 
        Citizen.InvokeNative(0x31F343383F19C987, currentHuntingWagon, tonumber(percentage), 1)
    end, currentHuntingPlate)
end)


RegisterNetEvent('phils-bounty:client:fixwagon', function(plate)
    local fixprice = (Config.WagonPrice * Config.WagonFixRate)
    local input = lib.inputDialog(locale('cl_lang_37'), {
        {
            label = locale('cl_lang_38') .. fixprice,
            type = 'select',
            options = {
                { value = 'yes', label = locale('cl_lang_32') },
                { value = 'no', label = locale('cl_lang_33') }
            },
            required = true,
            icon = 'fa-solid fa-circle-question'
        },
    })

    if not input or input[1] == 'no' then
        return
    end

    if input[1] == 'yes' then
        TriggerServerEvent('phils-bounty:server:fixhuntingwagon', plate, fixprice)
    end
end)


RegisterNetEvent('phils-bounty:client:getHuntingWagonInventory', function(data)
    TriggerServerEvent('phils-bounty:server:wagonstorage', data.plate)
end)


RegisterNetEvent('phils-bounty:client:openshop', function()
    TriggerServerEvent('rsg-shops:server:openstore', 'undertaker', 'undertaker', 'Undertaker')
end)