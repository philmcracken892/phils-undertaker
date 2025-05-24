Config = {}

-----------------------------------------------------------
-- debug
-----------------------------------------------------------
Config.Debug = false

-----------------------------------------------------------
-- npc settings
-----------------------------------------------------------
Config.DistanceSpawn = 20.0
Config.FadeIn = true
Config.PricePerNPC = 10
-----------------------------------------------------------
-- hunting wagon
-----------------------------------------------------------
Config.WagonPrice              = 1000    -- price set to buy a  wagon
Config.WagonSellRate           = 0.75    -- sell rate percentage for  wagon
Config.TotalPedsStored      = 10      -- total amount  you can store in the  cart
Config.StorageMaxWeight        = 400000  -- max inventory weight for  wagon
Config.StorageMaxSlots         = 20      -- amount of inventory slots
Config.WagonFixRate            = 0.10    -- cost to fix the wagon when broken
Config.TargetDistance          = 5.0     -- distance you can target (prompt distance is defined in rsg-core/config.lua)
Config.MaxCargo                = 10      -- max  stored in  cart
Config.StoreTime               = 10000   -- progress bar timer

Config.Blip = {
    blipName   = 'Undertaker', -- Config.Blip.blipName
    blipSprite = 'blip_ambient_bounty_hunter_wagon', -- Config.Blip.blipSprite
    blipScale  = 0.2 -- Config.Blip.blipScale
}

-- prompt locations
Config.HunterLocations = {
    {
        name       = 'undertakers',
        location   = 'undertakers1',
        coords     = vector3(1307.24, -1309.19, 76.79),
        npcmodel   = `u_m_m_rhdundertaker_01`,
        npccoords  = vector4(1307.24, -1309.19, 76.79, 337.83),
        wagonspawn = vector4(1310.62, -1302.96, 76.14, 252.58),
        showblip   = true
    },
    
}



