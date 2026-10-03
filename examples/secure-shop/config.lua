Config = {}

-- Server-side item catalogue: never send prices to the client
Config.Items = {
    burger      = { label = 'Burger',       price = 5,   maxStack = 10 },
    water       = { label = 'Water Bottle', price = 2,   maxStack = 20 },
    medkit      = { label = 'Med Kit',      price = 150, maxStack = 5  },
}

Config.ShopCoords   = vector3(25.7, -1344.9, 29.5)
Config.ShopRange    = 5.0    -- metres
Config.CooldownMs   = 2000   -- ms between purchases (anti-spam)
