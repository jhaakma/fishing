local common = require("mer.fishing.common")
local logger = common.createLogger("FishingStateManager")
local config = require("mer.fishing.config")

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
---| "CHASING" #Chasing state - Fish is spawned and moving towards the lure
---| "BITING" #Biting state - Fish is biting the lure
---| "REELING" #Reeling state
---| "CATCHING" #The interval between snagging and showing the caught fish
---| "BLOCKED" #Blocked state - No action can be taken

--set state
---comment
---@param state Fishing.fishingState
function FishingStateManager.setState(state)
    logger:debug("Setting state: %s", state)
    config.persistent.fishingState = state
end

function FishingStateManager.isState(state)
    return FishingStateManager.getCurrentState() == state
end

---@return Fishing.fishingState
function FishingStateManager.getCurrentState()
    return config.persistent.fishingState or "IDLE"
end

return FishingStateManager