local common = require ("mer.Fishing.common")
local logger = common.createLogger("fishing")
local FishingStateManager = require("mer.Fishing.FishingStateManager")
local FishingRod = require("mer.Fishing.FishingRod")

local function getFishingRod()
    local weaponStack = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.weapon,
    }
    return FishingRod.new(weaponStack)
end

---Cast line if player attacks with a fishing rod
---@param e attackEventData
event.register("attack", function(e)
    if e.reference ~= tes3.player then return end
    logger:debug("Swing strength = %s",tes3.player.mobile.actionData.attackSwing)
    local fishingRod = getFishingRod()
    if fishingRod then
        logger:debug("Player released attack with fishing rod")
        fishingRod:release()
    end
end)

-- event.register("attackStart", function(e)
--     if e.reference ~= tes3.player then return end
--     local fishingRod = getFishingRod()
--     if fishingRod then
--         logger:debug("Player started attack with fishing rod")
--         fishingRod:startSwing()
--     end
-- end)

---Event if activate is mapped to mouse
---@param e mouseButtonUpEventData
event.register("mouseButtonUp", function(e)
    if not tes3.player then return end
    if e.button == 0 then
        local fishingRod = getFishingRod()
        if fishingRod then
            logger:debug("Player started attack with fishing rod")
            fishingRod:startSwing()
        end
    end
end)

local swishSounds = {
    ["swishl"] = true,
    ["swishm"] = true,
    ["swishs"] = true,
    ["weapon swish"] = true,
    ["miss"] = true,
}
---Block vanilla weapon swish sounds when casting fishing line
---@param e addSoundEventData
event.register("addSound", function(e)
    local doBlockSound = e.reference == tes3.player
        and FishingStateManager.isState("CASTING")
        and swishSounds[e.sound.id:lower()]
    if doBlockSound then
        logger:debug("Blocking vanilla weapon swish sound")
        return false
    end
end, { priority = 500})


local function generateBiteInterval()
    return math.random(4, 10)
end


event.register("loaded", function()
    --fish bite timer
    local startFishBiteTimer
    ---comment
    ---@param interval number #The number of seconds between bites
    startFishBiteTimer = function(interval)
        timer.start{
            duration = interval,
            iterations = 1,
            callback = function()
                logger:debug("Fish bite timer finished")
                local fishingRod = getFishingRod()
                if fishingRod then
                    fishingRod:fishBite()
                end
                startFishBiteTimer(generateBiteInterval())
            end
        }
    end
    startFishBiteTimer(generateBiteInterval())

    --Check any interim states and cancel
    local state = FishingStateManager.getCurrentState()

    if state ~= "IDLE" then
        logger:debug("Loaded while fishing - cancel")
        local fishingRod = getFishingRod()
        if fishingRod then
            fishingRod:endFishing()
        end
    end
end)


-- local function dontMove(e)
--     if e.reference == tes3.player then
--         if not FishingStateManager.isState("IDLE") then
--             e.speed = 1e-5
--         end
--     end
-- end
-- event.register(tes3.event.calcMoveSpeed, dontMove)
