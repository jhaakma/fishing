---Class for controlling the ripples of a fish moving towards a lure
---@class Fishing.SwimService
local SwimService = {}

local common = require("mer.fishing.common")
local logger = common.createLogger("SwimService")
local config = require("mer.fishing.config")
local RippleGenerator = require("mer.fishing.Fishing.RippleGenerator")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")

function SwimService.deepEnough(location)
    local ray = tes3.rayTest{
        position = location,
        direction = tes3vector3.new(0,0,-1),
        maxDistance = config.constants.MIN_DEPTH,
        ignore = FishingStateManager.getIgnoreRefs(),
    }
    if ray then
        logger:debug("Depth %s too shallow. Hit: %s", ray.distance, ray.reference)
        return false
    end
    return true
end

local function hasLineOfSight(startPosition, targetPosition)
    local direction = (targetPosition - startPosition):normalized()
    local maxDistance = startPosition:distance(targetPosition)
    logger:trace([[
        Class: SwimService
        Method: hasLineOfSight
        Params:
            startPosition: %s
            targetPosition: %s
            direction: %s
            maxDistance: %s
    ]], startPosition, targetPosition, direction, maxDistance)

    local ray = tes3.rayTest{
        position = startPosition,
        direction = direction,
        maxDistance = maxDistance,
        ignore = FishingStateManager.getIgnoreRefs()
    }
    if ray then
        logger:debug("Line of sight blocked by %s", ray.object)
        -- tes3.createReference{
        --     object = "gold_001",
        --     position = ray.intersection
        -- }
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
        --useBackTriangles = true,
        ignore = ignoreList,
    }
    local hitSomething = ray ~= nil
    if not hitSomething then
        local targetPosition = startPosition + (direction * distance)
        --local rodEnd = FishingRod.getPoleEndPosition()

        local rodEnd = tes3.getCameraPosition()
        if rodEnd and not hasLineOfSight(targetPosition, rodEnd) then
            logger:debug("Line of sight to rod is blocked")
            return nil
        end

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

---@param startPosition tes3vector3
---@param distance number
function SwimService.findPositionTowardsPlayer(startPosition, distance)
    --find the position along the water plane towards the player by given distance,
    -- or shorter if there is a collision
    local playerPos = tes3vector3.new(
        tes3.player.position.x,
        tes3.player.position.y,
        startPosition.z
    )
    local direction = (playerPos - startPosition):normalized()
    logger:debug("Direction: %s", direction)

    local targetPosition = getTargetPosition(startPosition, direction, distance)
    if targetPosition then
        return targetPosition
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
    local currentPosition = e.from:copy()
    local fishTimer
    local currentState = FishingStateManager.getCurrentState()
    local safeLure
    if e.lure then
        safeLure = tes3.makeSafeObjectHandle(e.lure)
    end

    local movementSimulate
    local timePassed = 0
    movementSimulate = function(e2)
        logger:trace("targetPosition: %s", e.to)
        if not FishingStateManager.isState(currentState) then
            logger:trace("State changed, cancelling")
            event.unregister("simulate", movementSimulate)
            return
        end
        local distance = currentPosition:distance(e.to)
        if distance < 20 then
            logger:trace("Reached target position")
            event.unregister("simulate", movementSimulate)
            e.callback()
            return
        end
        local direction = (e.to - currentPosition):normalized()
        ---@type tes3vector3
        local delta = direction *  e.speed * e2.delta
        logger:trace("delta: %s", delta)
        local distanceTravelled = delta:length()
        logger:trace("distanceTravelled: %s", distanceTravelled)
        local newPosition = currentPosition + delta
        logger:trace("new position: %s", newPosition, distanceTravelled)
        currentPosition = newPosition
        if safeLure and safeLure:valid() then
            logger:trace("Updating lure position")
            safeLure.position = newPosition
        end

        --check if rime to generate ripple
        timePassed = timePassed + e2.delta
        if timePassed > config.constants.FISH_RIPPLE_INTERVAL then
            RippleGenerator.generateRipple{
                position = newPosition,
                scale = SwimService.rippleScale(),
                -- duration = 1.0,
                -- amount = 20,
            }
            timePassed = 0
        end
    end
    event.register("simulate", movementSimulate)
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
