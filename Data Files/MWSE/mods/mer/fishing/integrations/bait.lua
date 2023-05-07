local common = require("mer.fishing.common")
local logger = common.createLogger("Interop - Bait")

---@alias Fishing.Bait.type
---| '"lure"'            # Default lure.
---| '"spinner"'         # Used for catching small baitfish.
---| '"bait"'            # Used for catching medium sized fish.
---| '"baitfish"'        # Used for catching large fish.
---| '"shiny"'           # More effective during the daytime.
---| '"glowing"'         # More effective at nighttime.
---| '"sinker"'          # Increases chance of catching random loot.

---@type Fishing.BaitType[]
local BaitTypes = {
    {
        id = "lure",
        name = "Lure",
    },
    {
        id = "glowing",
        name = "Glowing Lure",
        description = "More effective at nighttime.",
        getHookChance = function(self)
            local time = tes3.worldController.hour.value
            if time >= 6 and time <= 18 then
                return 1.5
            end
            return 0.5
        end
    },
    {
        id = "shiny",
        name = "Shiny Lure",
        description = "More effective during the daytime.",
        getHookChance = function(self)
            local time = tes3.worldController.hour.value
            if time >= 6 and time <= 18 then
                return 1.5
            end
            return 0.5
        end
    },
    {
        id = "spinner",
        name = "Spinner",
        description = "Most effective at catching small baitfish.",
        getFishEffect = function(self, fish)
            local classes = {
                small = 1.0,
                medium = 0.4,
                large = 0,
            }
            return classes[fish.class] or 0.1
        end
    },
    {
        id = "bait",
        name = "Bait",
        description = "Most effective at catching medium sized fish.",
        getFishEffect = function(self, fish)
            local classes = {
                small = 0.2,
                medium = 1.0,
                large = 0.1,
            }
            return classes[fish.class] or 0.1
        end
    },
    {
        id = "baitfish",
        name = "Baitfish",
        description = "Most effective at catching large fish.",
        getFishEffect = function(self, fish)
            local classes = {
                small = 0,
                medium = 0.2,
                large = 1.0,
            }
            return classes[fish.class] or 0.1
        end
    },
    {
        id = "sinker",
        name = "Sinker",
        description = "Increases chance of catching random loot.",
        getFishEffect = function(self, fish)
            local classes = {
                small = 0.5,
                medium = 0.5,
                large = 0.5,
                loot = 1.5,
            }
            return classes[fish.class] or 0.5
        end
    },
}
local BaitType = require("mer.fishing.Bait.BaitType")
for _, baitType in ipairs(BaitTypes) do
    logger:debug("Registering bait type %s", baitType.id)
    BaitType.register(baitType)
end

---@type Fishing.Bait[]
local baits = {
    {
        id = "mer_lure_01",
        type = "lure",
    },
    {
        id = "ingred_racer_plumes_01",
        type = "spinner",
        uses = 10,
    },
    {
        id = "ingred_crab_meat_01",
        type = "bait",
        uses = 10,
    },

    {
        id = "ingred_pearl_01",
        type = "shiny",
        uses = 10,
    },
    {
        id = "ab_ingcrea_glowbugthorax",
        type = "glowing",
        uses = 10,
    }

}

local Bait = require("mer.fishing.Bait.Bait")
for _, bait in ipairs(baits) do
    logger:debug("Registering bait %s", bait.id)
    Bait.register(bait)
end

