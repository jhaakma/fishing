local common = require("mer.fishing.common")
local logger = common.createLogger("FightManager")
local SwimService = require("mer.fishing.Fish.SwimService")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

---@class Fishing.FightManager
---@field fish Fishing.FishType.instance The fish to fight
---@field callback fun(self: Fishing.FightManager, succeeded: boolean) The callback to run when the fight is over
local FightManager = {}

---@param e Fishing.FightManager
function FightManager.new(e)
    local self = setmetatable({}, { __index = FightManager })
    self.fish = e.fish
    self.callback = e.callback

    return self
end

local function simulateFight()
    local currentState = FishingStateManager.getCurrentState()
    if currentState ~= "REELING" then
        --cancel
        event.unregister("simulate", simulateFight)
    end


end


function FightManager:start()
    FishingStateManager.setState("REELING")
    tes3.messageBox("You've hooked something!")
    logger:debug([[
        Starting Fish Fight!
        The Challenger: %s
        The Defender: %s

        Player fatigue: %s
        Fish fatigue: %s
    ]],
        tes3.player.object.name,
        self.fish.fishType:getBaseObject().name,
        tes3.mobilePlayer.fatigue.current,
        self.fish.fatigue
    )
    self:callback(true)
    --event.register("simulate", simulateFight)
end

return FightManager