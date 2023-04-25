local common = require("mer.Fishing.common")
local logger = common.createLogger("FishingRod")
local config = require("mer.Fishing.config")
local FishingSpot = require("mer.Fishing.FishingSpot")
local FishingStateManager = require("mer.Fishing.FishingStateManager")

---@class Fishing.FishingRod
local FishingRod = {}

---@param weaponStack tes3equipmentStack
function FishingRod.getConfig(weaponStack)
    if not weaponStack then return false end
    local weapon = weaponStack.object
    return config.fishingRods[weapon.id:lower()]
end

---@param weaponStack tes3equipmentStack|nil
---@return Fishing.FishingRod|nil
function FishingRod.new(weaponStack)
    if not weaponStack then return nil end
    local config = FishingRod.getConfig(weaponStack)
    if not config then return nil end
    local self = {}
    setmetatable(self, {__index = FishingRod})
    self.weaponStack = weaponStack
    self.config = config
    return self
end

local function checkPlayerSwing()
    ---@diagnostic disable-next-line: undefined-field
    local attackDirection = tes3.mobilePlayer.actionData.attackDirection
    local isChop = attackDirection == 2 -- chop
    if not isChop then
        logger:warn("Player is not chopping")
        return false, nil
    end
    return true
end

function FishingRod:checkFishingSpot()
    if not checkPlayerSwing() then
        return false
    end
    local valid, invalidMessage = FishingSpot.check(self.castStrength)
    if not valid then
        logger:warn("Not a valid spot for fishing")
        if invalidMessage then
            tes3.messageBox(invalidMessage)
        end
        return false
    end
    return true
end

function FishingRod:getBiteDuration()
    local min = 0.1
    local max = 1.0
    return math.random(min*100, max*100)/100
end

function FishingRod:setCastStrength()
    self.castStrength = tes3.player.mobile.actionData.attackSwing
    logger:debug("Cast strength: %s", tes3.player.mobile.actionData.attackSwing)
end

function FishingRod:playCastSound()
    local pitch = math.remap(self.castStrength, 0, 1, 2.0, 1.0)
    logger:debug("Playing cast sound with pitch %s", pitch)
    tes3.playSound{
        soundPath = "mer_fishing\\fishing line.wav",
        pitch = pitch
    }
end

function FishingRod:playSplashSound()
    logger:debug("Playing splash sound")
    local sound = (math.random() < 0.5) and "Swim Left" or "Swim Right"
    tes3.playSound{ sound = sound }
end

function FishingRod:spawnLure()
    logger:debug("Spawning lure")
    local lurePosition = FishingSpot.getLurePosition(self.castStrength)
    if not lurePosition then
        logger:error("Could not get lure position")
        return
    end
    local lure = tes3.createReference({
        object = "mer_lure_01",
        position = lurePosition,
        cell = tes3.player.cell,
    })
    tes3.playAnimation{
        reference = lure,
        group = tes3.animationGroup.idle,
        loopCount = -1,
    }
    config.persistent.lureSafeRef = tes3.makeSafeObjectHandle(lure)
    self:playSplashSound()
    return lure
end

function FishingRod:removeLure()
    logger:debug("Removing lure")
    local lure = self:getLure()
    if lure then
        lure:delete()
        config.persistent.lureSafeRef = nil
    else
        logger:warn("Lure not found")
    end
end

function FishingRod:getLure()
    if config.persistent.lureSafeRef and config.persistent.lureSafeRef:valid() then
        return config.persistent.lureSafeRef:getObject()
    end
    logger:warn("Lure not found")
    return nil
end

function FishingRod:getCastDuration()
    return (0.5 + self.castStrength*2)
end

---Cast a line if player attacks with a fishing rod
--- and there is valid water in front of them
function FishingRod:startCasting()
    logger:debug("Casting fishing rod")

    local state = FishingStateManager.getCurrentState()
    if not state == "IDLE" then
        logger:debug("Not Idle, can't cast")
        return
    end

    self:setCastStrength()
    local fishingSpot = self:checkFishingSpot()
    if not fishingSpot then
        return
    end
    self:playCastSound()
    timer.start{
        duration = self:getCastDuration(),
        callback = function()
            local lure = self:spawnLure()
            if lure then
                self:generateRipple(lure.position, 2.5)
                self:generateSplash(lure.position)
                logger:debug("Finished casting")
                FishingStateManager.setState("WAITING")
            end
        end
    }
    common.disablePlayerControls()
    FishingStateManager.setState("CASTING")
end

function FishingRod:endFishing()
    logger:debug("Cancelling fishing")
    self:removeLure()
    common.enablePlayerControls()
    FishingStateManager.setState("IDLE")
end

function FishingRod:catchFish()
    logger:debug("Catching fish")
    tes3.messageBox("You caught a fish!")
    self:endFishing()
end

---Calculate the chance a bite is real or just a nibble
function FishingRod:calculateRealBiteChance()
    --TODO: base on skill etc
    return math.random() < 0.40
end

function FishingRod:realBite()
    logger:debug("Fish is biting")
    FishingStateManager.setState("BITING")
    local lure = self:getLure()
    if lure then
        logger:debug("Playing bite animation")

        --Animate lure
        tes3.playAnimation{
            reference = lure,
            group = tes3.animationGroup.idle2,
            startFlag = tes3.animationStartFlag.immediate,
            loopCount = 0,
        }
        tes3.playAnimation{
            reference = lure,
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.normal,
            loopCount = -1,
        }
        self:generateSplash(lure.position)
        self:generateRipple(lure.position, 1.5)
        self:playSplashSound()
        timer.start{
            duration = self:getBiteDuration(),
            callback = function()
                self:endBite()
            end
        }
    end
end

function FishingRod:nibble()
    local lure = self:getLure()
    if lure then
        logger:debug("Playing nibble animation")
        tes3.playAnimation{
            reference = lure,
            group = tes3.animationGroup.idle3,
            startFlag = tes3.animationStartFlag.immediate,
            loopCount = 0,
        }
        tes3.playAnimation{
            reference = lure,
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.normal,
            loopCount = -1,
        }
        self:generateRipple(lure.position, 1.0)
        self:playSplashSound()
    end
end

function FishingRod:fishBite()
    local state = FishingStateManager.getCurrentState()
    if state == "WAITING" then
        if self:calculateRealBiteChance() then
            self:realBite()
        else
            self:nibble()
        end
    else
        logger:debug("Not biting, state is %s", state)
    end
end

function FishingRod:generateSplash(position)
    logger:debug("Generating Splash")
    --Create Splash
    local splash = tes3.getObject("mer_fish_splash") --[[@as tes3activator]]
    local vfx = tes3.createVisualEffect({
        object = splash,
        position = position,
        repeatCount = 1
    })
end

function FishingRod:generateRipple(position, scale)
    logger:debug("Generating Ripple")
    local ffi = require("ffi")

    local _dataHandler = ffi.cast("struct { char _[46313]; void* waterController; }**", 0x7C67E0)
    local _waterController = _dataHandler[0][0].waterController
    local _createRipple = ffi.cast("void (__thiscall*)(void*, float, float, float, float, char)", 0x51C1E0)

    local ripples = 10
    local duration = 1
    timer.start{
        duration = duration / ripples,
        iterations = ripples,
        callback = function()
            logger:trace("*ripple*")
            _createRipple(_waterController, position.x, position.y, scale, 1, 0)
        end
    }
end

function FishingRod:endBite()
    local state = FishingStateManager.getCurrentState()
    if state == "BITING" then
        logger:debug("Fish stopped biting")
        FishingStateManager.setState("WAITING")
    else
        logger:debug("Not biting, state is %s", state)
    end
end

function FishingRod:release()
    logger:debug("Releasing Swing")
    local state = FishingStateManager.getCurrentState()
    if state == "IDLE" then
        logger:debug("IDLE - start casting")
        self:startCasting()
        logger:debug("Activate blocked by state - %s", state)
    end
end

-- function FishingRod:cancelSwing()
--     logger:debug("Cancelling Swing")
--     tes3.mobilePlayer.animationController.weaponSpeed = -tes3.mobilePlayer.animationController.weaponSpeed
--     tes3.mobilePlayer.actionData.animationAttackState = tes3.animationState.idle
-- end

function FishingRod:playSnapAnimation()
    -- logger:debug("Playing snap animation")
    -- tes3.playAnimation{
    --     reference = tes3.player,
    --     group = tes3.animationGroup.hit1,
    --     startFlag = tes3.animationStartFlag.immediate,
    -- }
    -- timer.start{
    --     duration = 1,
    --     callback = function()
    --         tes3.playAnimation{
    --             reference = tes3.player,
    --             group = tes3.animationGroup.idle,
    --             startFlag = tes3.animationStartFlag.immediate,
    --         }
    --     end
    -- }
end


function FishingRod:startSwing()
    logger:debug("Activating fishing rod")
    local state = FishingStateManager.getCurrentState()
    if state == "WAITING" then
        logger:debug("WAITING - cancel fishing")
        --self:cancelSwing()
        tes3.messageBox("You fail to catch anything.")
        self:endFishing()
        self:playSnapAnimation()
    elseif state == "BITING" then
        logger:debug("BITING - catch a fish")
        --self:cancelSwing()
        self:catchFish()
        self:playSnapAnimation()
    else
        logger:debug("Activate blocked by state - %s", state)
    end
end

return FishingRod