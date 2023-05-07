local fishingRods = {
    {
        id = "mer_fishing_pole_01",
        quality = 0.25
    }
}

local FishingRod = require("mer.fishing.FishingRod.FishingRod")
for _, data in ipairs(fishingRods) do
    FishingRod.register(data)
end