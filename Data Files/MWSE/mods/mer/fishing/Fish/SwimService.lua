---Class for controlling the ripples of a fish moving towards a lure
---@class Fishing.SwimService
local SwimService = {}

local common = require("mer.fishing.common")
local logger = common.createLogger("SwimService")
local config = require("mer.fishing.config")
local RippleGenerator = require("mer.fishing.Fish.RippleGenerator")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

---@return tes3vector3|nil # The position if unimpeded, nil if something blocked its path
function SwimService.getTargetPosition(startPosition, direction, distance)
    local ray = tes3.rayTest{
        position = startPosition,
        direction = direction,
        maxDistance = distance,
    }
    local hitSomething = ray and ray.reference ~= nil
    if not hitSomething then
        return startPosition + (direction * distance)
    end
end


local m1 = tes3matrix33.new()
--[[
    Given a position, try and find a position in a random direction
    that is unimpeded
]]
---@param origin tes3vector3
function SwimService.findTargetPosition(origin)
    logger:debug("Target position: %s", origin)
    logger:debug("Finding start position")
    for i=1, config.constants.FISH_POSITION_ATTEMPTS do
        --Every failed attempts, reduce the distance, to a minimum of 50
        local ABSOLUTE_MIN = 50
        local distanceReductionPerAttempt = config.constants.FISH_POSITION_DISTANCE_MIN / config.constants.FISH_POSITION_ATTEMPTS
        local min = math.max(ABSOLUTE_MIN, config.constants.FISH_POSITION_DISTANCE_MIN - (distanceReductionPerAttempt * i))
        local max = math.max(ABSOLUTE_MIN, config.constants.FISH_POSITION_DISTANCE_MAX - (distanceReductionPerAttempt * i))
        local distance = math.random(min, max)

        logger:trace("Distance: %s", distance)
        local zDir = math.random(0, 360)
        --use trig to create vector with XY values representing
        -- the direction
        local direction = tes3vector3.new(
            math.cos(zDir),
            math.sin(zDir),
            0
        )

        logger:debug("- Direction: %s", direction)
        if direction.z > 0 then
            logger:error("Bad direction")
            return
        end

        local targetPosition = SwimService.getTargetPosition(origin, direction, distance)
        if targetPosition then
            return targetPosition
        end
    end
end

---@class Fishing.SwimService.startSwimming.params
---@field from tes3vector3
---@field to tes3vector3
---@field callback function

--[[
    Beginning at start position, move towards target position,
    generating ripples along the way at a rate of 0.05 seconds
    until the fish reaches the target position, then execute
    fish caught logic
]]
---@param e Fishing.SwimService.startSwimming.params
function SwimService.startSwimming(e)
    FishingStateManager.setState("CHASING")
    logger:debug("Starting to swim")
    local currentPosition = e.from
    local fishTimer
    local currentState = FishingStateManager.getCurrentState()
    fishTimer = timer.start{
        duration = config.constants.FISH_RIPPLE_INTERVAL,
        type = timer.simulate,
        iterations = -1,
        callback = function()
            logger:trace("targetPosition: %s", e.to)
            if not FishingStateManager.isState(currentState) then
                logger:trace("State changed, cancelling fish timer")
                fishTimer:cancel()
                return
            end
            local distance = currentPosition:distance(e.to)
            if distance < 10 then
                logger:trace("Reached target position")
                fishTimer:cancel()
                e.callback()
                return
            end
            local direction = (e.to - currentPosition):normalized()
            ---@type tes3vector3
            local delta = direction * (SwimService.getSpeed() * config.constants.FISH_RIPPLE_INTERVAL)
            logger:trace("delta: %s", delta)
            local distanceTravelled = delta:length()
            logger:trace("distanceTravelled: %s", distanceTravelled)
            local newPosition = currentPosition + delta
            logger:trace("new position: %s", newPosition, distanceTravelled)
            RippleGenerator.generateRipple{
                position = newPosition,
                scale = SwimService.rippleScale(),
                -- duration = 1.0,
                -- amount = 20,
            }
            currentPosition = newPosition
        end
    }
end

function SwimService.rippleScale()
    local fish = FishingStateManager.getCurrentFish()
    if not fish then
        logger:error("rippleScale() No fish found")
        return 1.0
    end
    local variance = math.random(90, 110) / 100
    local scale = fish.fishType.size * variance
    logger:debug("rippleScale() scale: %s", scale)
    return scale
end

function SwimService.getSpeed()
    local fish = FishingStateManager.getCurrentFish()
    if not fish then
        logger:error("getSpeed() No fish found")
        return 100
    end
    local variance = math.random(80, 120) / 100
    local speed =  fish.fishType.speed * variance
    logger:debug("getSpeed() speed: %s", speed)
    return speed
end

return SwimService