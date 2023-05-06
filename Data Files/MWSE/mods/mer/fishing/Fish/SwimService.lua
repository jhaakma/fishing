---Class for controlling the ripples of a fish moving towards a lure
---@class Fishing.SwimService
local SwimService = {}

local common = require("mer.fishing.common")
local logger = common.createLogger("SwimService")
local config = require("mer.fishing.config")
local RippleGenerator = require("mer.fishing.Fish.RippleGenerator")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

function SwimService.deepEnough(location)
    local ray = tes3.rayTest{
        position = location,
        direction = tes3vector3.new(0,0,-1),
        maxDistance = config.constants.MIN_DEPTH,
        ignore = FishingStateManager.getIgnoreRefs()
    }
    if ray then
        logger:debug("Depth %s too shallow. Hit: %s", ray.distance, ray.reference)
        return false
    end
    return true
end

---@return tes3vector3|nil # The position if unimpeded, nil if something blocked its path
local function getTargetPosition(startPosition, direction, distance)
    local ignoreList = FishingStateManager.getIgnoreRefs()
    local ray = tes3.rayTest{
        position = startPosition,
        direction = direction,
        maxDistance = distance,
        useBackTriangles = true,
        ignore = ignoreList,
    }
    local hitSomething = ray ~= nil
    if not hitSomething then
        local targetPosition = startPosition + (direction * distance)
        if not SwimService.deepEnough(targetPosition) then
            logger:debug("Too shallow")
            return nil
        end
        return startPosition + (direction * distance)
    else
        logger:debug("Hit something: %s", ray and ray.reference)
        return nil
    end
end


local m1 = tes3matrix33.new()

---@class SwimService.findTargetPosition.params
---@field origin tes3vector3 where to start looking from
---@field minDistance number minimum distance to look. Defaults to config.constants.FISH_POSITION_DISTANCE_MIN
---@field maxDistance number maximum distance to look. Defaults to config.constants.FISH_POSITION_DISTANCE_MAX
---@field ignoreList table<tes3reference, boolean> references to ignore when raycasting
--[[
    Given a position, try and find a position in a random direction
    that is unimpeded
]]
---@param e SwimService.findTargetPosition.params
function SwimService.findTargetPosition(e)
    local origin = e.origin
    local minDistance = e.minDistance or config.constants.FISH_POSITION_DISTANCE_MIN
    local maxDistance = e.maxDistance or config.constants.FISH_POSITION_DISTANCE_MAX

    logger:debug("Target position: %s", origin)
    logger:debug("Finding start position")
    for i=1, config.constants.FISH_POSITION_ATTEMPTS do
        --Every failed attempts, reduce the distance, to a minimum of 50
        local ABSOLUTE_MIN = 50
        local distanceReductionPerAttempt = minDistance / config.constants.FISH_POSITION_ATTEMPTS
        local min = math.max(ABSOLUTE_MIN, minDistance - (distanceReductionPerAttempt * i))
        local max = math.max(ABSOLUTE_MIN, maxDistance - (distanceReductionPerAttempt * i))
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

        local targetPosition = getTargetPosition(origin, direction, distance)
        if targetPosition then
            return targetPosition
        end
    end
end

---@class Fishing.SwimService.startSwimming.params
---@field from tes3vector3
---@field to tes3vector3
---@field callback function
---@field lure? tes3reference
---@field speed number

--[[
    Beginning at start position, move towards target position,
    generating ripples along the way at a rate of 0.05 seconds
    until the fish reaches the target position, then execute
    fish caught logic
]]
---@param e Fishing.SwimService.startSwimming.params
function SwimService.startSwimming(e)
    logger:debug("Starting to swim")
    local currentPosition = e.from
    local fishTimer
    local currentState = FishingStateManager.getCurrentState()
    local safeLure
    if e.lure then
        safeLure = tes3.makeSafeObjectHandle(e.lure)
    end
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
            if distance < 20 then
                logger:trace("Reached target position")
                fishTimer:cancel()
                e.callback()
                return
            end
            local direction = (e.to - currentPosition):normalized()
            ---@type tes3vector3
            local delta = direction * (e.speed * config.constants.FISH_RIPPLE_INTERVAL)
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
            if safeLure and safeLure:valid() then
                logger:trace("Updating lure position")
                safeLure.position = newPosition
            end
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



return SwimService