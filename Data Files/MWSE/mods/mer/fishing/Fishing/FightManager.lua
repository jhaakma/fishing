local common = require("mer.fishing.common")
local logger = common.createLogger("FightManager")
local config = require("mer.fishing.config")
local SwimService = require("mer.fishing.Fishing.SwimService")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local Animations = require("mer.fishing.Fish.Animations")
local FightIndicator = require("mer.fishing.ui.FightIndicator")


---@class Fishing.FightManager
---@field fish Fishing.FishType.instance The fish to fight
---@field callback fun(self: Fishing.FightManager, succeeded: boolean, failMessage?: string) The callback to run when the fight is over
---@field targetPosition tes3vector3
---@field reeling boolean if the player is actively reeling in the fish
---@field lineLength number how mich fishing line is out
---@field fightIndicator Fishing.FightIndicator
---@field playerFatigue number accululation of fatigue drain, when it reaches one, subtract it from the player
local FightManager = {}
local simulateFight

---@param e Fishing.FightManager
function FightManager.new(e)
    local self = setmetatable({}, { __index = FightManager })
    self.fish = e.fish
    self.fightIndicator = FightIndicator:new{
        fightManager = self
    }
    self.callback = e.callback
    self.playerFatigue = 0
    return self
end

function FightManager:endFight()
    FishingRod.stopReelSound()
    event.unregister("simulate", simulateFight)
    self.reeling = nil
    self.fightIndicator:destroy()
    self.fightIndicator = nil
    common.enablePlayerControls()
end

function FightManager:fail(reason)
    logger:debug("Fight failed: %s", reason)
    self:endFight()
    self:callback(false, reason)
    self.reeling = nil
end

function FightManager:success()
    logger:debug("Fight succeeded")
    self:endFight()
    self:callback(true)
end

function FightManager:pickTargetPosition()
    logger:trace("Picking target position")
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:warn("Lure not found")
        return
    end
    local targetPosition = SwimService.findTargetPosition{
        origin = lure.position,
        minDistance = 50,
        maxDistance = 200,
    }
    if not targetPosition then
        logger:debug("No target position found")
        return
    end
    logger:debug("Target position: %s", targetPosition)
    self.targetPosition = targetPosition
end

function FightManager:setTension(newTension)
    local min = config.constants.TENSION_MINIMUM
    local max = config.constants.TENSION_MAXIMUM
    newTension = math.clamp(newTension, min, max)
    local fishingLine = FishingStateManager.getFishingLine()
    if not fishingLine then
        logger:warn("Fishing line not found")
        return
    end
    fishingLine:setTension(newTension)
end

function FightManager:getTension()
    local fishingLine = FishingStateManager.getFishingLine()
    if not fishingLine then
        logger:warn("Fishing line not found")
        return 0
    end
    return fishingLine:getTension()
end

function FightManager:increaseTension(delta)
    local increasePerSecond = 1.0
    local tension = self:getTension()
    local newTension = tension + (increasePerSecond * delta)
    self:setTension(newTension)
end

function FightManager:restoreNeutralTension(delta)
    local decreasePerSecond = 0.5
    local tension = self:getTension()
    local newTension = tension - (decreasePerSecond * delta)
    newTension = math.max(newTension, config.constants.TENSION_NEUTRAL)
    self:setTension(newTension)
end


--[[
    Get the distance between the lure and the target position
]]
function FightManager:getLineDistance()
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:warn("Lure not found")
        self:fail()
        return 0
    end
    local lurePosition = lure.position
    --local rodPosition = FishingRod.getPoleEndPosition()
    local rodPosition = tes3.player.position
    return lurePosition:distance(rodPosition)
end


--[[
    Compare the current Line length to the current distance,
    and set the tension accordingly
]]
function FightManager:updateTension()
    local lineLength = self.lineLength
    local actualLineLength = self:getLineDistance()
    local difference = actualLineLength - lineLength
    --At 500 units, tension is increased by 0.5

    local maxDistance = config.constants.FIGHT_MAX_DISTANCE
    local neutralMaxDiff = config.constants.FIGHT_TENSION_UPPER_LIMIT
        - config.constants.TENSION_NEUTRAL

    local effect = math.remap(difference, 0, maxDistance, 0, neutralMaxDiff)
    local tension = config.constants.TENSION_NEUTRAL + effect
    local fishingLine = FishingStateManager.getFishingLine()
    if fishingLine then
        fishingLine:setTension(tension)
    end
    logger:debug([[
        lineLength: %s
        actualLineLength: %s
        difference: %s
        effect: %s
        neutral: %s
        tension: %s
    ]], lineLength, actualLineLength, difference, effect, config.constants.TENSION_NEUTRAL, tension)

end


function FightManager:startSwim()
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:warn("Lure not found")
        self:fail()
        return
    end
    if not self.targetPosition then
        self:pickTargetPosition()
        SwimService.startSwimming{
            speed = self.fish:getReelSpeed(),
            from = lure.position,
            to = self.targetPosition,
            lure = lure,
            callback = function()
                self.targetPosition = nil
            end
        }
    end
end

function FightManager:changeLineLength(change)
    logger:trace("updating line length by %s", change)
    self.lineLength = math.max(self.lineLength + change, config.constants.TENSION_NEUTRAL)
end

function FightManager:updateLineLength(delta)
    if self.reeling then
        local change = delta * -config.constants.REEL_DISTANCE_PER_SECOND
        logger:trace("Reeling: %s", change)
        self:changeLineLength(change)
    else
        local change = delta * config.constants.RELAX_DISTANCE_PER_SECOND
        logger:trace("Relaxing: %s", change)
        self:changeLineLength(change)
    end
end

--[[
    Fish loses fatigue faster when tension is high
    and when player strength is high
]]
function FightManager:tireFish(delta)
    local tension = self:getTension()
    local maxTension = config.constants.FIGHT_TENSION_UPPER_LIMIT
    local minTension = config.constants.FIGHT_TENSION_LOWER_LIMIT

    local tensionEffect = math.remap(tension, minTension, maxTension, 0.0, 2.0)

    local strength = tes3.player.mobile.strength.current
    local strengthEffect = math.remap(strength, 0, 100, 0.0, 1.5)

    local fatigueDrain = config.constants.FIGHT_FATIGUE_DRAIN_PER_SECOND

    local drain = fatigueDrain  * tensionEffect * strengthEffect * delta

    logger:trace("Draining fatigue by: %s", drain)
    self.fish.fatigue = self.fish.fatigue - drain
    logger:trace("Fish fatigue: %s", self.fish.fatigue)
end

function FightManager:tirePlayer(delta)
    local change = 0
    if not self.reeling then
        change = config.constants.FIGHT_PLAYER_FATIGUE_RELAX_DRAIN_PER_SECOND * delta
    else
        local fishStrength = self.fish.fishType.difficulty
        local fishStrengthEffect = math.remap(fishStrength, 0, 100, 0.5, 1.5)
        change = config.constants.FIGHT_PLAYER_FATIGUE_REELING_DRAIN_PER_SECOND
            * fishStrengthEffect * delta
        logger:trace([[
            Fish strength: %s
            Fish strength effect: %s
            Change: %s
            Player fatigue: %s
        ]], fishStrength,
            fishStrengthEffect,
            change,
            self.playerFatigue
        )
    end
    self.playerFatigue = self.playerFatigue + change
    if self.playerFatigue > 1 then
        logger:trace("Draining player fatigue by: %s", self.playerFatigue)
        tes3.modStatistic{
            reference = tes3.player,
            name = "fatigue",
            current = -self.playerFatigue
        }
        self.playerFatigue = 0
    end

end

---@param e simulateEventData
function FightManager:fightSimulate(e)
    self:startSwim()
    --keybind test for left click
    local inputController = tes3.worldController.inputController
    local leftMouseDown = inputController:isMouseButtonDown(0)
    local rightMouseDown = inputController:isMouseButtonDown(1)
    --local keyTest = inputController:keybindTest(tes3.keybind.activate)
    if rightMouseDown then
        --cancel
        logger:debug("Cancelling on right click")
        self:fail()
    elseif leftMouseDown and not self.reeling then
        logger:debug("Started Reeling")
        self.reeling = true
        FishingRod.playReelSound{
            doLoop = true,
            pitch = 1.5
        }
        Animations.reverseSwing()
    elseif self.reeling and not leftMouseDown then
        logger:debug("Stopped Reeling")
        self.reeling = false
        FishingRod.playReelSound{
            doLoop = true,
        }
    end

    self:tireFish(e.delta)
    self:tirePlayer(e.delta)
    self:updateLineLength(e.delta)
    self:updateTension()
    -- tes3.messageBox("Tension: %s\nFatigue: %s",
    --     FishingStateManager.getFishingLine():getTension(),
    --     self.fish.fatigue
    -- )

    local fishingLine = FishingStateManager.getFishingLine()
    if fishingLine and fishingLine:getTension() >= config.constants.FIGHT_TENSION_UPPER_LIMIT then
        self:fail("Line Snapped!")
        return
    end
    if fishingLine and fishingLine:getTension() <= config.constants.FIGHT_TENSION_LOWER_LIMIT then
        self:fail("Fish Escaped!")
        return
    end

    if self.fish.fatigue <= 0 then
        self:success()
        return
    end

    if tes3.player.mobile.fatigue.current <= 0 then
        --make sure the player falls over
        tes3.setStatistic{
            reference = tes3.player,
            name = "fatigue",
            current = -5
        }
        self:fail("You are exhausted!")
    end
end


function FightManager:start()
    FishingRod.playReelSound{ doLoop = true }
    FishingStateManager.setState("REELING")
    self:startSwim()
    local fishingLine = FishingStateManager.getFishingLine()
    self.lineLength = self:getLineDistance()

    if fishingLine then
        fishingLine:lerpTension(0.5, config.constants.TENSION_NEUTRAL)
    end

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

    simulateFight = function(e)
        local currentState = FishingStateManager.getCurrentState()
        if currentState ~= "REELING" then
            self:fail("No longer reeling")
            return
        end
        self:fightSimulate(e)
    end
    event.register("simulate", simulateFight)
    self.fightIndicator:createMenu()
    common.disablePlayerControls()

    local doCancel
    doCancel = function()
        self:fail("Cancelled")
        event.unregister("Fishing:Cancel", doCancel)
    end
    event.register("Fishing:Cancel", doCancel)
end


return FightManager