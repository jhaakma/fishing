local config = require("mer.fishing.config")

local function registerAshfallRecipes(e)
    ---@type CraftingFramework.MenuActivator
    local bushcraftingActivator = e.menuActivator
    if bushcraftingActivator then
        for _, recipe in ipairs(config.bushcraftingRecipes) do
            bushcraftingActivator:registerRecipe(recipe)
        end
    end
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerAshfallRecipes)