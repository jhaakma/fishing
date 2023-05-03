--[[
    Register default fish types
]]
local common = require("mer.fishing.common")
local logger = common.createLogger("Integrations - fishTypes")

---@type Fishing.FishType[]
local fishTypes = {
    {
        baseId = "mer_fish_arowana",
        previewMesh = "mer_fishing\\f\\arowana.nif",
        description = "Arowana, also known as bony tongues, are found throughout the Southern coastal regions of Morrowind. They tend to feed at from dawn until dusk.",
        speed = 1,
        difficulty = 10,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_arowana",
                min = 1,
                max = 4,
            }
        }
    },
    {
        baseId = "mer_fish_ashclaw",
        previewMesh = "mer_fishing\\f\\ashclaw.nif",
        description = "The Ashclaw is a large, frightening fish with claw-like fins that it uses to cling to rocks and other underwater surfaces. It's meat is prized for its powerful alchemical properties.",
        speed = 1,
        difficulty = 80,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_ashclaw",
                min = 3,
                max = 4,
            }
        }
    },
    {
        baseId = "mer_fish_bass",
        previewMesh = "mer_fishing\\f\\bass.nif",
        description = "The largemouth bass is a carnivourous fish found in the rivers and lakes of Morrowind. They can put up a good fight when hooked, but are prized for their delicious meat.",
        speed = 1,
        difficulty = 40,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_bass",
                min = 1,
                max = 4,
            }
        }
    },
    {
        baseId = "mer_fish_copperscale",
        previewMesh = "mer_fishing\\f\\copper.nif",
        description = "The Copperscale is very rare, found only in the hottest regions of Vvardenfell. It's meat is tough and chewy, but its scales can be used to make a powerful potion of fire resistance.",
        speed = 1,
        difficulty = 70,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_copperscale",
                min = 1,
                max = 2,
            },
            {
                id = "mer_ignred_copperscales",
                min = 2,
                max = 4,
            }
        }
    },

    {
        baseId = "mer_fish_discus",
        previewMesh = "mer_fishing\\f\\discus.nif",
        description = "The Discus is a small, colorful fish found in the warmer regions of Morrowind.",
        speed = 1,
        difficulty = 10,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_discus",
                min = 1,
                max = 3,
            }
        }
    },
    {
        baseId = "mer_fish_goby",
        previewMesh = "mer_fishing\\f\\goby.nif",
        description = "The Goby is a small fish found all throughout Morrowind.",
        speed = 1,
        difficulty = 10,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_goby",
                min = 1,
                max = 3,
            }
        }
    },
    {
        baseId = "mer_fish_marrow",
        previewMesh = "mer_fishing\\f\\marrow.nif",
        description = "The Marrowfish is a strange creature with bulging eyes and an oily red body. This rare fish can only be found in caves, and it's meat has powerful alchemical properties.",
        speed = 1,
        difficulty = 65,
        niche = {
            interiors = true,
            exteriors = false,
        },
        harvestables = {
            {
                id = "mer_meat_marrow",
                min = 2,
                max = 4,
            },
        }
    },
    {
        baseId = "mer_fish_salmon",
        previewMesh = "mer_fishing\\f\\salmon.nif",
        description = "Salmon can be found all over Vvardenfell. Their meat is delicious eaten raw or cooked.",
        speed = 1,
        difficulty = 10,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_salmon",
                min = 1,
                max = 3,
            }
        }
    },
    {
        baseId = "mer_fish_slaughter_l",
        previewMesh = "mer_fishing\\f\\sfish_l.nif",
        description = "A large, aggressive fish with sharp teeth and a dorsal fin that runs the length of its body. The Slaughterfish is found throughout Tamriel and is known to attack anything that enters its territory. Slaughterfish meat tastes awful, but their scales are considered a delicacy.",
        speed = 1,
        difficulty = 40,
        niche = {},
        harvestables = {
            {
                id = "ab_ingcrea_sfmeat_01",
                min = 1,
                max = 3,
            },
            {
                id = "ingred_scales_01",
                min = 2,
                max = 4,
            }
        }
    },
    {
        baseId = "mer_fish_slaughter_sm",
        previewMesh = "mer_fishing\\f\\sfish_sm.nif",
        description = "Juvenile Slaughterfish may be small, but they can still put up a fight.",
        speed = 1,
        difficulty = 20,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_sfish_sm",
                min = 1,
                max = 2,
            },
            {
                id = "ingred_scales_01",
                min = 1,
                max = 2,
            }
        }
    },
    {
        baseId = "mer_fish_shadowfin",
        previewMesh = "mer_fishing\\f\\shadowfin.nif",
        description = "A dark, elusive fish with a translucent body that blends in with its surroundings. The Shadowfin is found throughout Tamriel and feeds only at night. It is said to be able to swim through solid rock and is prized for its rich, oily meat.",
        speed = 1,
        difficulty = 10,
        niche = {
            times = {
                "night"
            },
        },
        harvestables = {
            {
                id = "mer_meat_shadowfin",
                min = 1,
                max = 4,
            }
        }
    },
    {
        baseId = "mer_fish_swampmaw",
        previewMesh = "mer_fishing\\f\\swampmaw.nif",
        description = "An eel with sharp teeth and a voracious appetite. It is known to prey on smaller fish and unwary travelers who venture too close to the water's edge. The Swampmaw is found in the swamps of Morrowind.",
        speed = 1,
        difficulty = 75,
        niche = {
            regions = {
                "Bitter Coast Region",
            },
        },
        harvestables = {
            {
                id = "mer_meat_swampmaw",
                min = 1,
                max = 2,
            }
        }
    },
    {
        baseId = "mer_fish_tambaqui",
        previewMesh = "mer_fishing\\f\\tambaqui.nif",
        description = "The tambaqui is a large tropical fish found along the eastern coast of Vvardenfell.",
        speed = 1,
        difficulty = 10,
        niche = {},
        harvestables = {
            {
                id = "mer_meat_tambaqui",
                min = 2,
                max = 5,
            }
        }
    }
}

local FishType = require("mer.fishing.Fish.FishType")
for _, fish in ipairs(fishTypes) do
    logger:debug("Registering fish %s", fish.baseId)
    FishType.register(fish)
end