local Interop = require("mer.fishing")

---@type Fishing.Location.Category.config[]
local categories = {
    {
        id = "water",
        defaultType = "saltwater",
        locationTypes = {
            {
                id = "saltwater",
                name = "Saltwater"
            },
            {
                id = "freshwater",
                name = "Freshwater"
            }
        }
    },
    {
        id = "climate",
        defaultType = "temperate",
        locationTypes = {
            {
                id = "arctic",
                name = "Arctic"
            },
            {
                id = "swamp",
                name = "Swamp"
            },
            {
                id = "tropical",
                name = "Tropical"
            },
            {
                id = "temperate",
                name = "Temperate"
            }
        }
    },
    {
        id = "location",
    }
}

local solstheimLocations = {
    vanilla = {
        cellX = -22,
        cellY = 23,
        radius = 4,
    },
    modded = {
        cellX = -15,
        cellY = 29,
        radius = 4
    }
}


event.register("initialized", function()
    --Register categories
    for _, category in ipairs(categories) do
        Interop.registerLocationCategory(category)
    end

    --Register Solestheim location
    local thirsk = tes3.getCell{ id = "Thirsk" }
    local inVanillaPosition = thirsk.gridX == -19
    local solstheimLocation = solstheimLocations[inVanillaPosition and "vanilla" or "modded"]
    Interop.registerLocation("water", solstheimLocation)

    --Register from JSON config
    local locationConfig = mwse.loadConfig("UltimateFishing_regions")
    for category, locationTypes in pairs(locationConfig) do
        ---@param locationType string
        ---@param locations Fishing.Location.config[]
        for locationType, locations in pairs(locationTypes) do
            for _, location in ipairs(locations) do
                location.locationType = locationType
                Interop.registerLocation(category, location)
            end
        end
    end
end)