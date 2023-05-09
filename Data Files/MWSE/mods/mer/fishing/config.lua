---@class Fishing.config
local config = {}
config.configPath = "Fishing"
config.metadata = toml.loadFile("Data Files\\Fishing-metadata.toml")
---@class Fishing.config.constants
config.constants = {
    --How many times to try to find a valid position for a fish startPosition
    FISH_POSITION_ATTEMPTS = 50,
    --Minimum distance from lure to fish start position
    FISH_POSITION_DISTANCE_MIN = 300,
    --Maximum distance from lure to fish start position
    FISH_POSITION_DISTANCE_MAX = 700,
    --The interval between ripples when a fish is moving
    FISH_RIPPLE_INTERVAL = 0.05,
    --Fish Speed
    FISH_SPEED = 75,

    --Fishing line
    MIN_CAST_SPEED = 100,
    MAX_CAST_SPEED = 450,

    --The max distance the lure can be from the player before the line breaks
    FISHING_LINE_MAX_DISTANCE = 5000,
    MIN_DEPTH = 40,

    TENSION_NEUTRAL = 0.7,

    TENSION_MINIMUM = -0.1,
    TENSION_MAXIMUM = 1.5,
    FIGHT_TENSION_UPPER_LIMIT = 1.2,
    FIGHT_TENSION_LOWER_LIMIT = 0.2,
    REEL_DISTANCE_PER_SECOND = 300,
    RELAX_DISTANCE_PER_SECOND = 200,
    --the distance at which tension will reach breaking point
    FIGHT_MAX_DISTANCE = 300,
    FIGHT_FATIGUE_DRAIN_PER_SECOND = 5,

    --player fatigue
    --the amount of fatigue drained per second when the player is reeling
    FIGHT_PLAYER_FATIGUE_REELING_DRAIN_PER_SECOND = 15,
    --the amount of fatigue drained per second when the player is relaxing
    FIGHT_PLAYER_FATIGUE_RELAX_DRAIN_PER_SECOND = 3,

    --The a multiplier on the distance towards the player the fish will pull based on tension
    FIGHT_TENSION_DISTANCE_EFFECT_MAXIMUM = 0.5,

    FIGHT_REELING_DISTANCE_EFFECT = 200,

    --Tooltips
    TOOLTIP_COLOR_BAIT = {
        147 / 255,
        181 / 255,
        189 / 255,
    },
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
    cheatMode = false,
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