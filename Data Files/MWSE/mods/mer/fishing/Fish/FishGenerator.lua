--[[
    This class will create an instance of a fish.
    The type of fish is determined by the region and time of day
    the player is fishing. The quality of the fish determined
    by the player's attributes and fishing skill.
]]
local common = require("mer.fishing.common")
local logger = common.createLogger("FishGenerator")
local SkillService = require("mer.fishing.SkillsService")
local FishType = require("mer.fishing.Fish.FishType")

---@class Fishing.FishGenerator
local FishGenerator = {}

---@class Fishing.FishGenerator.Params
---@field depth number

---Generate a fish instance
---@param e Fishing.FishGenerator.Params
function FishGenerator.generate(e)
    ---@type Fishing.FishType[]
    local validFishTypes = {}
    logger:debug("Picking fish")
    for id, fish in pairs(FishType.registeredFishTypes) do
        logger:trace("Checking fish %s", id)
        if fish.niche:isActive(e.depth) then
            logger:debug("- %s is active", id)
            table.insert(validFishTypes, fish)
        end
    end
    logger:debug("%s fish types available", #validFishTypes)
    local instance
    while #validFishTypes > 0 and not instance do
        local pick = table.choice(validFishTypes) --[[@as Fishing.FishType]]
        logger:debug("Picked %s", pick.baseId)
        instance = pick:instance()
        if not instance then
            logger:debug("%s is not a valid pick, trying again", pick.baseId)
            table.removevalue(validFishTypes, pick)
        end
    end
    if not instance then
        logger:warn("No valid fish types available")
        return nil
    end

    logger:debug("Fish stats: \n- weight: %s\n- value: %s\n- speed: %s",
        instance.weight, instance.value, instance.speed)
    return instance
end

return FishGenerator