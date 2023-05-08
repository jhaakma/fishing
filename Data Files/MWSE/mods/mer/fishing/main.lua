
require("mer.fishing.mcm")

event.register("initialized", function()
    local common = require("mer.fishing.common")
    local logger = common.createLogger("main")
    ---event handlers
    require("mer.fishing.PlayerAnimations")
    require("mer.fishing.Fishing")
    require("mer.fishing.Bait")

    --Integrations
    require("mer.fishing.integrations.bait")
    require("mer.fishing.integrations.bushcrafting")
    require("mer.fishing.integrations.fishTypes")
    require("mer.fishing.integrations.fishingRods")

    logger:info("initialized")
end)
