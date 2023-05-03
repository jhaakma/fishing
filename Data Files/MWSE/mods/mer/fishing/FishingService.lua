local common = require("mer.fishing.common")
local logger = common.createLogger("FishingService")
local config = require("mer.fishing.config")
local FishingSpot = require("mer.fishing.FishingSpot")
local FishingStateManager = require("mer.fishing.FishingStateManager")
local FishingRod = require("mer.fishing.FishingRod")
local RippleGenerator = require("mer.fishing.RippleGenerator")
local SwimService = require("mer.fishing.SwimService")
local FishGenerator = require("mer.fishing.Fish.FishGenerator")
local TrophyMenu = require("mer.fishing.TrophyMenu")
local LineManager = require("mer.fishing.FishingLine.LineManager")

---@class Fishing.FishingService
local FishingService = {}

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

local function playSnapAnimation()
    logger:debug("Playing snap animation")

    --cancelling swing animation
    timer.start{
        duration = 0.2,
        callback = function()
            tes3.mobilePlayer.animationController.weaponSpeed = -tes3.mobilePlayer.animationController.weaponSpeed
            timer.start{duration = 0.2, callback = function()
                tes3.mobilePlayer.actionData.animationAttackState = tes3.animationState.idle
                tes3.mobilePlayer.animationController.weaponSpeed = 1
            end}
        end
    }
end

local function setCastStrength()
    tes3.player.tempData.fishingCastStrength = tes3.player.mobile.actionData.attackSwing
    logger:debug("Cast strength: %s", tes3.player.mobile.actionData.attackSwing)
end

local function getCastStrength()
    return tes3.player.tempData.fishingCastStrength
end

---@param fish Fishing.FishType.instance|nil
local function setActiveFish(fish)
    tes3.player.tempData.mer_activeFish = fish
end

---@return Fishing.FishType.instance
local function getActiveFish()
    return tes3.player.tempData.mer_activeFish
end

local function checkFishingSpot()
    if not checkPlayerSwing() then
        return false
    end
    local valid, invalidMessage = FishingSpot.check(getCastStrength())
    if not valid then
        logger:warn("Not a valid spot for fishing")
        if invalidMessage then
            tes3.messageBox(invalidMessage)
        end
        return false
    end
    return true
end

local function getEquippedFishingRod()
    local weaponStack = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.weapon
    }
    return FishingRod.new(weaponStack)
end


local function clampWaves()
    if tes3.player.tempData.mer_previousWaveHeight then return end
    if mge.render.dynamicRipples then
        tes3.player.tempData.mer_previousWaveHeight = mge.distantLandRenderConfig.waterWaveHeight
        local duration = 0.5
        local iterations = duration / 0.01

        local from = tes3.player.tempData.mer_previousWaveHeight
        local to = 0.0

        timer.start{
            iterations = iterations,
            duration = duration / iterations,
            callback = function(e)
                local newHeight = math.lerp(
                    to,
                    from,
                    e.timer.iterations / iterations
                )
                logger:trace("Setting wave height to %s", newHeight)
                mge.distantLandRenderConfig.waterWaveHeight = newHeight
            end
        }
    end
end

local function unclampWaves()
    if not tes3.player.tempData.mer_previousWaveHeight then return end
    local previousWaveHeight = tes3.player.tempData.mer_previousWaveHeight
    local currentWaveHeight = mge.distantLandRenderConfig.waterWaveHeight
    --smooth transition
    local duration = 0.5
    local iterations = duration / 0.01
    local from = currentWaveHeight
    local to = previousWaveHeight
    timer.start{
        iterations = iterations,
        duration = duration / iterations,
        callback = function(e)
            local newHeight = math.lerp(
                to,
                from,
                e.timer.iterations / iterations
            )
            logger:trace("Re-Setting wave height to %s", newHeight)
            mge.distantLandRenderConfig.waterWaveHeight = newHeight
        end
    }
    timer.start{
        duration = duration,
        callback = function()
            tes3.player.tempData.mer_previousWaveHeight = nil
        end
    }
end

local function getBiteDuration()
    local min = 0.1
    local max = 1.0
    return math.random(min*100, max*100)/100
end


local function getCastDuration()
    return (0.5 + getCastStrength()*2)
end


local function playCastSound()
    local pitch = math.remap(getCastStrength(), 0, 1, 2.0, 1.0)
    logger:debug("Playing cast sound with pitch %s", pitch)
    tes3.playSound{
        soundPath = "mer_fishing\\fishing line.wav",
        pitch = pitch
    }
end

local function playSplashSound()
    logger:debug("Playing splash sound")
    local sound = (math.random() < 0.5) and "Swim Left" or "Swim Right"
    tes3.playSound{ sound = sound }
end

local function getLure()
    if tes3.player.tempData.mer_lureSafeRef and tes3.player.tempData.mer_lureSafeRef:valid() then
        return tes3.player.tempData.mer_lureSafeRef:getObject()
    else
        local lure =  tes3.getReference("mer_lure_01")
        if lure then
            tes3.player.tempData.mer_lureSafeRef = tes3.makeSafeObjectHandle(lure)
            return lure
        end
    end
    logger:warn("Lure not found")
    return nil
end

local function removeLure()
    logger:debug("Removing lure")
    local lure = getLure()
    if lure then
        lure:delete()
        tes3.player.tempData.mer_lureSafeRef = nil
    else
        logger:warn("Lure not found")
    end
end


---@param lure tes3reference
---@param landCallback function
local function launchLure(lure, landCallback)
    local mesh = tes3.loadMesh("mer_fishing\\LureParticle.nif")
    local particles = mesh:getObjectByName("Particles")

    --update speed opn object (TODO: Fix this with praticle bindings later)
    local swingStrength = getCastStrength()
    particles.controller.speed = math.remap(swingStrength, 0, 1, 100, 700)

    local vfx = tes3.createVisualEffect{
        object = "mer_lure_particle",
        position = lure.position,
    }
    local effectNode = vfx.effectNode
    local particles = effectNode:getObjectByName("Particles") --[[@as niParticles]]
    local controller = particles.controller --[[@as niParticleSystemController]]

    effectNode.rotation:toRotationZ(tes3.player.orientation.z)

   --controller.speed = math.remap(swingStrength, 0, 1, 1000, 5000)
    --effectNode:update{ controller = true}
    --effectNode:updateEffects()
    --effectNode:updateProperties()

    logger:debug("Setting lure speed to %s", controller.speed)

    local safeLure = tes3.makeSafeObjectHandle(lure)
    local safeParticle = tes3.makeSafeObjectHandle(vfx)
    local updateLurePosition
    local function cancel()
        event.unregister("simulate", updateLurePosition)
        if safeLure and safeLure:valid() then
            lure:delete()
        end
    end
    updateLurePosition = function()
        if not (safeLure and safeLure:valid()) then
            logger:debug("Lure is not valid, stopping updateLurePosition")
            cancel()
            return
        end
        if not (safeParticle and safeParticle:valid()) then
            logger:debug("Particle is not valid, stopping updateLurePosition")
            cancel()
            return
        end
        local transform = vfx.effectNode.worldTransform
        local vertex = particles.data.vertices[1]
        lure.position = transform * vertex

        --check for collision with ground
        local result = tes3.rayTest{
            position = lure.position + tes3vector3.new(0, 0, 10),
            direction = tes3vector3.new(0, 0, -1),
            ignore = { lure },
        }
        if result then
            local hitGround =  result.intersection.z > lure.cell.waterLevel
                and result.distance < 10
            if hitGround then
                logger:debug("Lure hit ground, stopping updateLurePosition")
                FishingStateManager.setState("IDLE")
                cancel()
                return
            end
        end

        if lure.position.z < lure.cell.waterLevel then
            logger:debug("Lure is underwater, stopping updateLurePosition")
            event.unregister("simulate", updateLurePosition)
            landCallback()
            return
        end
    end
    event.register("simulate", updateLurePosition)
end



local function spawnLure(lurePosition)
    logger:debug("Spawning lure")
    if not lurePosition then
        logger:error("Could not get lure position")
        return
    end
    local lure = tes3.createReference({
        object = "mer_lure_01",
        position = lurePosition,
        cell = tes3.player.cell,
    })
    tes3.player.tempData.mer_lureSafeRef = tes3.makeSafeObjectHandle(lure)
    return lure
end


local function generateSplash(position)
    logger:debug("Generating Splash")
    --Create Splash
    local splash = tes3.getObject("mer_fish_splash") --[[@as tes3activator]]
    local vfx = tes3.createVisualEffect({
        object = splash,
        position = position,
        repeatCount = 1
    })
end

local function endBite()
    local state = FishingStateManager.getCurrentState()
    if state == "BITING" then
        logger:debug("Fish stopped biting")
        FishingStateManager.setState("WAITING")
    else
        logger:debug("Not biting, state is %s", state)
    end
end

local function getFishingPoleEndPosition()
    local ref = tes3.is3rdPerson() and tes3.player or tes3.player1stPerson
    local attachNode = ref.sceneNode:getObjectByName("AttachFishingLine")--[[@as niNode]]
    return attachNode.worldTransform.translation
end


---Cast a line if player attacks with a fishing rod
--- and there is valid water in front of them
local function startCasting()

    logger:debug("Casting fishing rod")

    local state = FishingStateManager.getCurrentState()
    if not state == "IDLE" then
        logger:debug("Not Idle, can't cast")
        return
    end
    setCastStrength()
    local fishingSpot = checkFishingSpot()
    if not fishingSpot then
        logger:debug("No fishing spot found")
        --No need to return with new fishing line animation
        --return
    end
    --local lurePosition = FishingSpot.getLurePosition(getCastStrength())
    local lurePosition = getFishingPoleEndPosition()
    playCastSound()
    clampWaves()

    local lure = spawnLure(lurePosition)
    if lure then
        -- common.disablePlayerControls()
        FishingStateManager.setState("CASTING")
        LineManager.attachLines(lure)
        launchLure(lure, function()
            tes3.playAnimation{
                reference = lure,
                group = tes3.animationGroup.idle,
                loopCount = -1,
            }

            playSplashSound()
            generateSplash(lure.position)
            RippleGenerator.generateRipple{
                position = lure.position,
                scale = 2.5,
                -- duration = 1.0,
                -- amount = 20,
            }
            logger:debug("Finished casting")
            FishingStateManager.setState("WAITING")

        end)
    else
        logger:error("Could not spawn lure")
        FishingService.endFishing()
    end
end



local function catchFish()
    logger:debug("Catching fish")
    FishingStateManager.setState("CATCHING")
    local fish = getActiveFish()
    local fishObj = fish:getInstanceObject()
    timer.start{
        duration = 0.75,
        callback = function()
            TrophyMenu.createMenu(fish.fishType, function()
                tes3.addItem{
                    reference = tes3.player,
                    item = fishObj,
                    count = 1,
                }
                FishingService.endFishing()
            end)
            -- tes3.messageBox{
            --     message = string.format("You caught %s!", addAOrAnPrefix(fishObj.name)),
            --     buttons = {
            --         "Okay"
            --     },
            -- }

        end
    }
end

---Calculate the chance a bite is real or just a nibble
local function calculateRealBiteChance()
    --TODO: base on skill etc
    return math.random() < 0.50
end

local function realBite()
    logger:debug("Fish is biting")
    FishingStateManager.setState("BITING")
    local lure = getLure()
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
        generateSplash(lure.position)
        RippleGenerator.generateRipple{
            position = lure.position,
            scale = 1.5,
            -- duration = 1.0,
            -- amount = 20,
        }
        playSplashSound()
        timer.start{
            duration = getBiteDuration(),
            callback = function()
                endBite()
            end
        }
    end
end

local function nibble()
    local lure = getLure()
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
        RippleGenerator.generateRipple{
            position = lure.position,
            scale = 1,
            -- duration = 1.0,
            -- amount = 20,
        }
        playSplashSound()
    end
end

local function startFish()
    logger:debug("Starting fish")
    local lure = getLure()
    if not lure then
        logger:warn("No lure found")
        return
    end
    local depth = FishingSpot.getDepth(lure.position)
    local fish = FishGenerator.generate{ depth = depth }
    if not fish then
        logger:warn("Unable to generate fish")
        return
    end
    setActiveFish(fish)
    local swimService = SwimService.new{
        lure = lure,
        fish = fish,
        catchCallback = function()
            realBite()
        end,
    }
    if not swimService then
        logger:warn("Unable to generate swimService")
        return
    end
    swimService:startSwimming()
end

function FishingService.triggerFish()
    local state = FishingStateManager.getCurrentState()
    if state == "WAITING" then
        if calculateRealBiteChance() then
            logger:debug("SwimService is biting")
            startFish()
        else
            logger:debug("SwimService is nibbling")
            nibble()
        end
    end
end

function FishingService.endFishing()
    logger:debug("Cancelling fishing")
    removeLure()
    -- common.enablePlayerControls()
    unclampWaves()
    setActiveFish(nil)
    --give time for waves to settle
    FishingStateManager.setState("BLOCKED")
    timer.start{
        duration = 0.5,
        callback = function()
            FishingStateManager.setState("IDLE")
        end
    }
end

function FishingService.release()
    logger:debug("Releasing Swing")
    local state = FishingStateManager.getCurrentState()
    if state == "IDLE" then
        logger:debug("IDLE - start casting")
        startCasting()
        logger:debug("Activate blocked by state - %s", state)
    end
end

function FishingService.startSwing()
    local state = FishingStateManager.getCurrentState()
    if (state == "WAITING") or (state == "CHASING") then
        logger:debug("CHASING - cancel fishing")
        tes3.messageBox("You fail to catch anything.")
        FishingService.endFishing()
        playSnapAnimation()
    elseif state == "BITING" then
        logger:debug("BITING - catch a fish")
        catchFish()
        playSnapAnimation()
    else
        logger:debug("Activate blocked by state - %s", state)
    end
end

return FishingService