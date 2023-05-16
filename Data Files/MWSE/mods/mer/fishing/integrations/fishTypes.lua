--[[
    Register default fish types
]]
local common = require("mer.fishing.common")
local logger = common.createLogger("Integrations - fishTypes")
local Interop = require("mer.fishing")

---@type Fishing.FishType.new.params[]
local commonFish = {
    {
        baseId = "mer_fish_bass",
        previewMesh = "mer_fishing\\f\\bass.nif",
        description = "The largemouth bass is a medium-sized, carnivorous fish known for its widespread presence in Morrowind. Anglers are drawn to its impressive fighting spirit when hooked, but it is their succulent flesh that truly makes them a prized catch.",
        speed = 170,
        size = 2.0,
        difficulty = 30,
        class = "medium",
        niche = {},
        harvestables = {
            {
                id = "mer_meat_bass",
                min = 1,
                max = 4,
                isMeat = true,
            }
        }
    },
    {
        baseId = "mer_fish_goby",
        previewMesh = "mer_fishing\\f\\goby.nif",
        description = "The goby is a small fish that can be found throughout Morrowind. While its size may be modest, it serves as excellent bait for luring in larger prey, making it a favorite among seasoned anglers.",
        speed = 150,
        size = 1.1,
        difficulty = 20,
        class = "small",
        isBaitFish = true,
        niche = {},
    },
    {
        baseId = "mer_fish_salmon",
        previewMesh = "mer_fishing\\f\\salmon.nif",
        description = "Salmon are versatile fish that inhabit the oceans, lakes, and rivers of the Ascadian Isles. With their remarkable ability to navigate various water bodies, they provide an exciting challenge for anglers seeking a rewarding catch.",
        speed = 180,
        size = 1.4,
        difficulty = 40,
        class = "medium",
        niche = {
            regions = {
                "Ascadian Isles Region",
            },
        },
        harvestables = {
            {
                id = "mer_meat_salmon",
                min = 1,
                max = 3,
                isMeat = true,
            }
        }
    },
    {
        baseId = "mer_fish_slaughter_l",
        previewMesh = "mer_fishing\\f\\sfish_l.nif",
        description = "The large slaughterfish is a formidable aquatic predator found across the expansive realm of Tamriel. Armed with sharp teeth and a dorsal fin that spans its entire body, this aggressive fish strikes fear into the hearts of those who enter its territory. Although its meat may be unappetizing, its scales are considered a delicacy.",
        speed = 180,
        size = 3.0,
        difficulty = 50,
        class = "large",
        niche = {
            minDepth = 250,
        },
        harvestables = {
            {
                id = "ab_ingcrea_sfmeat_01",
                min = 1,
                max = 3,
                isMeat = true,
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
        description = "Juvenile slaughterfish may be diminutive in size, but they possess a surprising resilience and tenacity. Even in their smaller form, they can put up a spirited fight when encountered by anglers.",
        speed = 170,
        size = 1.1,
        difficulty = 25,
        class = "small",
        isBaitFish = true,
        niche = {},
    },
    {
        baseId = "mer_fish_trigger",
        previewMesh = "mer_fishing\\f\\trigger.nif",
        description = "The triggerfish is a small tropical species commonly encountered in the azure waters of Azura's Coast. Known for their aggressive behavior and sharp teeth, these fish exhibit a captivating blend of beauty and ferocity that captures the attention of anglers.",
        speed = 230,
        size = 1.0,
        difficulty = 15,
        class = "small",
        isBaitFish = true,
        niche = {
            regions = {
                "Azura's Coast Region",
            }
        },
    },
    {
        baseId = "mer_fish_catfish",
        previewMesh = "mer_fishing\\f\\catfish.nif",
        description = "The catfish is a small, bottom-feeding fish found in the swamps of the Bitter Coast. With its distinctive barbels resembling a cat's whiskers, this species navigates its murky habitat in search of sustenance. While not known for its size or aggression, the catfish's adaptability and ability to thrive in challenging environments make it an intriguing target for anglers seeking a unique and flavorful catch.",
        speed = 160,
        size = 1.0,
        difficulty = 54,
        class = "small",
        isBaitFish = true,
        niche = {
            regions = {
                "Bitter Coast Region",
            }
        },
    },
    {
        baseId = "mer_fish_sculpin",
        previewMesh = "mer_fishing\\f\\sculpin.nif",
        description = "The sculpin is a small fish that inhabits both freshwater and saltwater environments. With its unassuming size, the sculpin serves as excellent bait for targeting larger prey. Anglers appreciate its versatility and ability to attract a variety of game fish.",
        speed = 165,
        size = 1.0,
        difficulty = 22,
        class = "small",
        isBaitFish = true,
        niche = {},
    },
    {
        baseId = "mer_fish_cod",
        previewMesh = "mer_fishing\\f\\cod.nif",
        description = "The cod is a medium-sized fish found in the deeper waters of the Inner Sea. Renowned for its delectable meat, the cod is a prized catch among anglers and culinary enthusiasts alike. Its firm, white flesh and mild flavor make it a versatile ingredient in various dishes. The pursuit of cod offers anglers a rewarding challenge and the promise of a satisfying meal, making it a beloved target in fishing expeditions.",
        speed = 150,
        size = 1.5,
        difficulty = 33,
        class = "medium",
        harvestables = {
            {
                id = "mer_meat_cod",
                min = 1,
                max = 3,
                isMeat = true,
            }
        },
        niche = {
            minDepth = 200,
        },
    },
}

---@type Fishing.FishType[]
local uncommonFish = {

    {
        baseId = "mer_fish_tambaqui",
        previewMesh = "mer_fishing\\f\\tambaqui.nif",
        description = "The tambaqui is a large tropical fish that thrives along the eastern coast of Vvardenfell. With its impressive size and striking appearance, this species captivates the imaginations of anglers seeking a thrilling challenge in their pursuit.",
        speed = 170,
        size = 2.0,
        difficulty = 43,
        class = "medium",
        niche = {
            regions = {
                "Grazelands Region",
                "Azura's Coast Region",
                "Molag Mar Region",
            }
        },
        harvestables = {
            {
                id = "mer_meat_tambaqui",
                min = 2,
                max = 5,
                isMeat = true,
            }
        }
    },
    {
        baseId = "mer_fish_arowana",
        previewMesh = "mer_fishing\\f\\arowana.nif",
        description = "Also known as bony tongues, arowanas are uncommon fish found along the coast of the West Gash. These elusive creatures exhibit a peculiar feeding pattern, predominantly active during daylight hours. Their rarity and enigmatic behavior make them a highly sought-after target among dedicated anglers.",
        speed = 175,
        size = 1.1,
        difficulty = 35,
        class = "small",
        isBaitFish = true,
        niche = {
            regions = {
                "West Gash Region",
            },
            times = {
                "day"
            }
        },
    },
    {
        baseId = "mer_fish_angelshark",
        previewMesh = "mer_fishing\\f\\angel.nif",
        description = "The Angelshark is a small yet formidable species of shark that can be found throughout the waters of Vvardenfell. Despite its size, it possesses a striking presence and an impressive set of skills. The Angelshark combines stealth and strength, making it a skilled predator capable of capturing its prey swiftly and efficiently.",
        speed = 180,
        size = 1.3,
        class = "large",
        difficulty = 55,
        niche = {
            minDepth = 200,
        },
        harvestables = {
            {
                id = "mer_meat_angelshark",
                min = 1,
                max = 1,
                isMeat = true,
            }
        }
    }
}
---@type Fishing.FishType[]
local rareFish = {
    {
        baseId = "mer_fish_sturgeon",
        previewMesh = "mer_fishing\\f\\sturgeon.nif",
        description = "The sturgeon is a massive, formidable fish boasting a long, sleek body and a distinctive row of bony plates along its back. These ancient creatures can be found in both freshwater and saltwater habitats, impressing anglers with their sheer size and strength. While their meat is highly prized, it is their caviar, with its delicate and luxurious flavor, that truly elevates them to a prized delicacy. Catching and conquering a sturgeon is a testament to an angler's skill and perseverance.",
        speed = 200,
        size = 2.0,
        difficulty = 68,
        class = "large",
        niche = {
            minDepth = 400,
        },
        harvestables = {
            {
                id = "ab_ingcrea_sturgeonmeat01",
                min = 3,
                max = 6,
                isMeat = true,
            },
            {
                id = "ab_ingcrea_sturgeonroe01",
                min = 0,
                max = 1,
                isMeat = false,
            }
        },
    },
    {
        baseId = "mer_fish_discus",
        previewMesh = "mer_fishing\\f\\discus.nif",
        description = "The discus is a visually captivating fish with vibrant colors, inhabiting the warmer regions of Morrowind. This uncommon species adds a touch of exotic beauty to the waters it calls home, making it a desirable catch for anglers seeking unique and eye-catching specimens.",
        speed = 200,
        size = 1.0,
        difficulty = 47,
        class = "small",
        isBaitFish = true,
        niche = {
            regions = {
                "Ascadian Isles Region",
                "Azura's Coast Region",
            }
        },
    },
    {
        baseId = "mer_fish_jelly",
        previewMesh = "mer_fishing\\f\\jellyfish.nif",
        description = "The jelly netch represents the larval form of the larger netch creature. These intriguing organisms dwell in the deep waters and emerge during the night. Their presence provides a captivating encounter for anglers who appreciate the wonders of Morrowind's aquatic ecosystems.",
        speed = 100,
        size = 1.2,
        difficulty = 18,
        class = "medium",
        niche = {
            minDepth = 400,
            times = {
                "night"
            }
        },
    },

    {
        baseId = "mer_fish_copperscale",
        previewMesh = "mer_fishing\\f\\copper.nif",
        description = "Exclusive to the Ascadian Isles, the copperscale is a fish highly coveted scales, sought after by artisans and collectors for their ornamental value.",
        speed = 200,
        size = 2.2,
        difficulty = 65,
        class = "medium",
        niche = {
            interiors = true,
            exterios = true,
            regions = {
                "Ascadian Isles Region",
            }
        },
        harvestables = {
            {
                id = "mer_ingred_copperscales",
                min = 2,
                max = 4,
            },
            {
                id = "mer_meat_copper",
                min = 1,
                max = 2,
                isMeat = true,
            }
        }
    },
    {
        baseId = "mer_fish_marrow",
        previewMesh = "mer_fishing\\f\\marrow.nif",
        description = "The marrowfish is a peculiar creature with bulging eyes and an oily red body. Its rarity and unique habitat within caves make it a true discovery for adventurous anglers. Beyond its captivating appearance, the marrowfish possesses powerful alchemical properties, making it a sought-after specimen among practitioners of the arcane arts.",
        speed = 180,
        size = 1.8,
        difficulty = 70,
        class = "medium",
        niche = {
            interiors = true,
            exteriors = false,
        },
        harvestables = {
            {
                id = "mer_meat_marrow",
                min = 2,
                max = 4,
                isMeat = true,
            },
        }
    },
    {
        baseId = "mer_fish_marlin",
        previewMesh = "mer_fishing\\f\\marlin.nif",
        description = "To engage in a battle of wills with a blue marlin is a testament to one's angling prowess. These powerful and determined creatures, found in the deep seawaters surrounding Vvardenfell, exhibit strength, speed, and an indomitable spirit. Catching a blue marlin requires both skill and physical fortitude, with live baitfish serving as the key to success.",
        niche = {
            minDepth = 500,
        },
        speed = 230,
        size = 4.4,
        difficulty = 75,
        class = "large",
        harvestables = {
            {
                id = "mer_trophy_marlin",
                min = 1,
                max = 1,
                isTrophy = true,
            }
        }
    }
}
---@type Fishing.FishType[]
local legendaryFish = {
    {
        baseId = "mer_fish_shadowfin",
        previewMesh = "mer_fishing\\f\\shadowfin.nif",
        description = "The shadowfin is a mysterious and elusive fish with a translucent body that effortlessly blends into its surroundings. Found in the enigmatic waters of the West Gash, this species ventures out exclusively under the cover of darkness, providing an alluring challenge for nocturnal anglers.",
        speed = 210,
        size = 1.8,
        difficulty = 77,
        class = "large",
        niche = {
            times = {
                "night"
            },
            regions = {
                "West Gash Region"
            },
        },
        harvestables = {
            {
                id = "mer_meat_shadowfin",
                min = 2,
                max = 3,
                isMeat = true,
            },
            {
                id = "mer_trophy_shadowfin",
                min = 1,
                max = 1,
                isTrophy = true,
            }
        }
    },
    {
        baseId = "mer_fish_ashclaw",
        previewMesh = "mer_fishing\\f\\ashclaw.nif",
        description = "The ashclaw is a large and intimidating fish with claw-like fins, residing in Lake Nabia within the Molag Amur Region. Its formidable appearance and predatory nature create an aura of fear, intriguing those who dare to seek it within its inhospitable habitat.",
        speed = 200,
        size = 3.4,
        difficulty = 80,
        class = "large",
        niche = {
            regions = {
                "Molag Mar Region",
            },
        },
        harvestables = {
            {
                id = "mer_meat_ashclaw",
                min = 2,
                max = 3,
                isMeat = true,
            },
            {
                id = "mer_ingred_ashlegs",
                min = 1,
                max = 2,
            },
            {
                id = "mer_trophy_ashclaw",
                min = 1,
                max = 1,
                isTrophy = true,
            }
        }
    },
    {
        baseId = "mer_fish_iskal",
        previewMesh = "mer_fishing\\f\\iskal.nif",
        description = "Iskal, a majestic fish adorned with icy blue scales and razor-sharp spines, calls the frigid waters of Sheogorad its home. Surviving in these harsh conditions showcases the Iskal's resilience, capturing the attention of anglers seeking a unique and chilling adventure.",
        speed = 230,
        size = 2.8,
        difficulty = 75,
        class = "large",
        niche = {
            regions = {
                "Sheogorad",
            },
        },
        harvestables = {
            {
                id = "mer_trophy_iskal",
                min = 1,
                max = 1,
                isTrophy = true,
            }
        }
    },
    {
        baseId = "mer_fish_swampmaw",
        previewMesh = "mer_fishing\\f\\swampmaw.nif",
        description = "The swampmaw is a colossal eel lurking within the murky swamps of the Bitter Coast. Armed with sharp teeth and an insatiable appetite, this predatory fish preys upon smaller fish and unwary travelers venturing too close to the water's edge at night. Its sheer size and fearsome reputation make it a formidable adversary for daring anglers.",
        speed = 200,
        size = 3.7,
        difficulty = 90,
        class = "large",
        niche = {
            times = {
                "night"
            },
            regions = {
                "Bitter Coast Region",
            },
            lures = {
                glowing = 100,
                iridescent = 80
            },
        },
        harvestables = {
            {
                id = "mer_meat_swampmaw",
                min = 3,
                max = 6,
                isMeat = true,
            },
            {
                id = "mer_trophy_swampmaw",
                min = 1,
                max = 1,
                isTrophy = true,
            }
        }
    },
    {
        baseId = "mer_fish_mega",
        previewMesh = "mer_fishing\\f\\megamax.nif",
        description = "The megamaxilla, known colloquially as the \"Mega Jaw,\" is a fearsome oceanic beast that instills awe in all who witness it. Possessing an enormous, hinge-like jaw, this formidable predator is capable of hunting down even large predator fish. It prefers to feed during the twilight hours of dawn and dusk in Azura's Coast, where its scarlet glow provides a striking camouflage. The pursuit of a megamaxilla demands the utmost strength and skill from anglers, as they strive to conquer one of the ocean's most formidable creatures.",
        speed = 210,
        size = 4.5,
        difficulty = 95,
        class = "large",
        niche = {
            regions = {
                "Azura's Coast Region",
            },
            times = {
                "dawn",
                "dusk",
            },
        },
        harvestables = {
            {
                id = "mer_trophy_megamax",
                min = 1,
                max = 1,
                isTrophy = true,
            }
        }
    }
}

local loot = {
    {
        baseId = "misc_com_bottle_10",
        description = "It's a bottle.",
        speed = 30,
        size = 0.5,
        difficulty = 5,
        class = "loot",
        niche = {},
        rarity = "common",
    },
    {
        baseId = "mer_fishing_pole_01",
        description = "Somewhere out there is a very sad fisherman.",
        speed = 30,
        size = 1.0,
        difficulty = 10,
        class = "loot",
        niche = {},
        rarity = "uncommon",
    },

}

local Ashfall = include("mer.ashfall.interop")
event.register("initialized", function (e)
    ---@param fish Fishing.FishType
    local function registerFood(fish)
        if Ashfall then
            local obj = fish:getBaseObject()
            if obj.objectType == tes3.objectType.ingredient then
                    logger:debug("Registering %s as meat", obj.id)
                    Ashfall.registerFoods{
                        [obj.id] = "meat"
                    }
            end
        end
    end
    for _, fish in ipairs(commonFish) do
        fish.rarity = "common"
        logger:debug("Registering common fish %s", fish.baseId)
        fish = Interop.registerFishType(fish)
        registerFood(fish)
    end
    for _, fish in ipairs(uncommonFish) do
        fish.rarity = "uncommon"
        logger:debug("Registering uncommon fish %s", fish.baseId)
        fish = Interop.registerFishType(fish)
        registerFood(fish)
    end
    for _, fish in ipairs(rareFish) do
        fish.rarity = "rare"
        logger:debug("Registering rare fish %s", fish.baseId)
        fish = Interop.registerFishType(fish)
        registerFood(fish)
    end
    for _, fish in ipairs(legendaryFish) do
        fish.rarity = "legendary"
        logger:debug("Registering legendary fish %s", fish.baseId)
        fish = Interop.registerFishType(fish)
        registerFood(fish)
    end
    for _, fish in ipairs(loot) do
        logger:debug("Registering loot %s", fish.baseId)
        fish = Interop.registerFishType(fish)
    end
end)
