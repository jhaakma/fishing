---Class for controlling the ripples of a fish moving towards a lure
---@class Fishing.SwimService
---@field targetLure tes3reference The lure the fish is moving towards
---@field targetPosition tes3vector3 The position of the lure
---@field startPosition tes3vector3 The position the fish starts at
---@field catchCallback function The function to call when the fish is caught
local SwimService = {}

local common = require("mer.fishing.common")
local logger = common.createLogger("SwimService")
local config = require("mer.fishing.config")
local RippleGenerator = require("mer.fishing.RippleGenerator")
local FishingStateManager = require("mer.fishing.FishingStateManager")

---@class Fishing.Fish.new.params
---@field lure tes3reference
---@field catchCallback function

---@param params Fishing.Fish.new.params
function SwimService.new(params)
    local self = {}
    setmetatable(self, {__index = SwimService})
    self.targetLure = params.lure
    self.targetPosition = params.lure.position
    self.catchCallback = params.catchCallback
    if not self:findStartPosition() then
        logger:error("Failed to find start position")
        return nil
    end
    return self --[[@as Fishing.SwimService]]
end


--[[
    Pick a direction and distance along XY
    Check if the path is clear
    If not, pick a new direction and distance
    If yes, set the start position
]]
local m1 = tes3matrix33.new()
function SwimService:findStartPosition()
    logger:debug("Target position: %s", self.targetPosition)
    logger:debug("Finding start position")
    for _=1, config.constants.FISH_POSITION_ATTEMPTS do
        local distance = math.random(
            config.constants.FISH_POSITION_DISTANCE_MIN,
            config.constants.FISH_POSITION_DISTANCE_MAX
        )
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
        local ray = tes3.rayTest{
            position = self.targetPosition,
            direction = direction,
            maxDistance = distance,
            ignore = {self.targetLure}
        }
        if not ray then
            self.startPosition = self.targetPosition + (direction * distance)
            logger:debug("-- Found start position: %s", self.startPosition)
            return true
        else
            if false and ray.reference == nil then
                local vfx = tes3.getObject("VFX_LightningHit") --[[@as tes3static]]
                tes3.createVisualEffect{
                    object = vfx,
                    position = ray.intersection,
                    repeatCount = 1
                }

            end
            logger:trace("-- Ray hit %s at %s", ray.reference, ray.intersection)
        end
    end
end

--[[
    Beginning at start position, move towards target position,
    generating ripples along the way at a rate of 0.05 seconds
    until the fish reaches the target position, then execute
    fish caught logic
]]
function SwimService:startSwimming()
    FishingStateManager.setState("CHASING")
    logger:debug("Starting to swim")
    local currentPosition = self.startPosition
    local fishTimer
    fishTimer = timer.start{
        duration = config.constants.FISH_RIPPLE_INTERVAL,
        type = timer.simulate,
        iterations = -1,
        callback = function()
            logger:trace("targetPosition: %s", self.targetPosition)
            if not FishingStateManager.isState("CHASING") then
                logger:trace("Fishing stopped, cancelling fish timer")
                fishTimer:cancel()
                return
            end
            local distance = currentPosition:distance(self.targetPosition)
            if distance < 10 then
                logger:trace("Reached target position")
                fishTimer:cancel()
                self:caught()
                return
            end
            local direction = (self.targetPosition - currentPosition):normalized()
            ---@type tes3vector3
            local delta = direction * (self:getSpeed() * config.constants.FISH_RIPPLE_INTERVAL)
            logger:trace("delta: %s", delta)
            local distanceTravelled = delta:length()
            logger:trace("distanceTravelled: %s", distanceTravelled)
            local newPosition = currentPosition + delta
            logger:trace("new position: %s", newPosition, distanceTravelled)
            RippleGenerator.generateRipple{
                position = newPosition,
                scale = self:rippleScale(),
                -- duration = 1.0,
                -- amount = 20,
            }
            currentPosition = newPosition
        end
    }
end

function SwimService:rippleScale()
    return math.remap(math.random(), 0, 1, 1.0, 1.5)
end

function SwimService:getSpeed()
    return math.random(75, 200)
end

function SwimService:caught()
    logger:debug("Caught fish")
    timer.start{
        duration = 0.3,
        callback = self.catchCallback
    }
end

return SwimService