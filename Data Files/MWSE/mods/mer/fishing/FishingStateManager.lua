local common = require("mer.Fishing.common")
local logger = common.createLogger("FishingStateManager")
local config = require("mer.Fishing.config")

---@class Fishing.FishingStateManager
local FishingStateManager = {}

---@alias Fishing.FishingAction.type
---| "cast" #Cast the fishing rod
---| "castFinish" #Finish casting the fishing rod
---| "castCancel" #Cancel casting the fishing rod
---| "reel" #Reel in the fishing rod
---| "fishBite" #Fish bites
---| "biteFinish" #Finish fish bite
---| "fishEscape" #Fish escapes
---| "fishCaught" #Fish caught
---| "endFishing" #End fishing

---@alias Fishing.fishingState
---| "IDLE" #Idle state, not fishing
---| "CASTING" #Casting state
---| "WAITING" #Waiting state
---| "BITING" #Biting state
---| "REELING" #Reeling state

---@type table<Fishing.fishingState, table<Fishing.FishingAction.type, Fishing.fishingState>>
local STATES = {
    IDLE = {
        cast = "CASTING",
    },
    CASTING = {
        castFinish = "WAITING",
        castCancel = "IDLE",
    },
    WAITING = {
        reel = "IDLE",
        fishBite = "BITING",
    },
    BITING = {
        reel = "REELING",
        biteFinish = "WAITING",
    },
    REELING = {
        fishEscape = "IDLE",
        fishCaught = "IDLE",
    },
}

---Change state based on the current state
---@param action Fishing.FishingAction.type
function FishingStateManager.performAction(action)
    local currentState = config.persistent.fishingState or "IDLE"
    local nextState = STATES[currentState][action]
    if nextState then
        config.persistent.fishingState = nextState
        logger:debug("State changed from %s to %s", currentState, nextState)
    else
        logger:debug("No state change for action %s in state %s", action, currentState)
    end
end

--set state
---comment
---@param state Fishing.fishingState
function FishingStateManager.setState(state)
    config.persistent.fishingState = state
end

function FishingStateManager.resetState()
    config.persistent.fishingState = "IDLE"
end

function FishingStateManager.isState(state)
    return FishingStateManager.getCurrentState() == state
end

---@return Fishing.fishingState
function FishingStateManager.getCurrentState()
    return config.persistent.fishingState or "IDLE"
end

return FishingStateManager