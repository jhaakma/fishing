---@class Fishing.config
local config = {}
config.configPath = "Fishing"
config.metadata = toml.loadFile("Data Files\\Fishing-metadata.toml")
config.fishingRods = {
    mer_fishing_pole_01 = {
        quality = 0.25
    }
}
---@type CraftingFramework.Recipe.data[]
config.bushcraftingRecipes = {
    {
        id = "Fishing:mer_fishing_pole_01",
        craftableId = "mer_fishing_pole_01",
        description = "A simple wooden fishing pole.",
        materials = {
            { material = "wood", count = 2 },
            { material = "fibre", count = 6 },
            { material = "resin", count = 1 }
        }
    }
}

---@class Fishing.config.persistent
local persistentDefault = {
    ---The total number of fish this character has ever caught
    ---@type number
    totalFishCaught = 0,
    ---@type Fishing.fishingState|nil
    fishingState = nil,
}

---@class Fishing.config.MCM
local mcmDefault = {
    enabled = true,
    logLevel = "INFO"
}
---@type Fishing.config.MCM
config.mcm = mwse.loadConfig(config.configPath, mcmDefault)
---Save the current config.mcm to the config file
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end
---@type Fishing.config.persistent
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        return tes3.player.data[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        tes3.player.data[config.configPath][key] = value
    end
})

return config