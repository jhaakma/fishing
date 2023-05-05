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

--Fish

---@param fish Fishing.FishType.instance?
function FishingStateManager.setActiveFish(fish)
    tes3.player.tempData.mer_activeFish = fish
end

---@return Fishing.FishType.instance?
function FishingStateManager.getCurrentFish()
    return tes3.player.tempData.mer_activeFish
end

--Lure

---@return tes3reference?
function FishingStateManager.getLure()
    local safeRef = tes3.player.tempData.mer_lureSafeRef
    if safeRef and safeRef:valid() then
        return safeRef:getObject()
    else
        local lure =  tes3.getReference("mer_lure_01")
        if lure then
            safeRef = tes3.makeSafeObjectHandle(lure)
            return lure
        end
    end
    logger:warn("Lure not found")
    return nil
end

---@param lure tes3reference
function FishingStateManager.setLure(lure)
    tes3.player.tempData.mer_lureSafeRef = tes3.makeSafeObjectHandle(lure)
end

---@return boolean did remove
function FishingStateManager.removeLure()
    logger:debug("Removing lure")
    local lure = FishingStateManager.getLure()
    if lure then
        lure:delete()
        tes3.player.tempData.mer_lureSafeRef = nil
        return true
    else
        logger:warn("Lure not found")
        return false
    end
end

--Cast
function FishingStateManager.setCastStrength()
    tes3.player.tempData.fishingCastStrength = tes3.player.mobile.actionData.attackSwing
    logger:debug("Cast strength: %s", tes3.player.mobile.actionData.attackSwing)
end

function FishingStateManager.getCastStrength()
    return tes3.player.tempData.fishingCastStrength
end


--Tension
function FishingStateManager.setTension(tension)
    tes3.player.tempData.mer_fishingTension = tension
end

function FishingStateManager.getTension()
    return tes3.player.tempData.mer_fishingTension or 0
end

--Clear all data
function FishingStateManager.clearData()
    logger:debug("Clearing fishing data")
    tes3.player.tempData.mer_activeFish = nil
    tes3.player.tempData.mer_lureSafeRef = nil
    tes3.player.tempData.fishingCastStrength = nil
    tes3.player.tempData.mer_fishingTension = nil
end



return FishingStateManager