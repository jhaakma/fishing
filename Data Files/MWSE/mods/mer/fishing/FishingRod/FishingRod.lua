local common = require("mer.fishing.common")
local logger = common.createLogger("FishingRod")
local config = require("mer.fishing.config")


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
    if not weaponStack then
        weaponStack = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.weapon
        }
    end
    local config = FishingRod.getConfig(weaponStack)
    if not config then return nil end
    local self = {}
    setmetatable(self, {__index = FishingRod})
    self.weaponStack = weaponStack
    self.config = config
    return self
end

function FishingRod.isEquipped()
    local weaponStack = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.weapon
    }
    return FishingRod.getConfig(weaponStack) ~= nil
end

function FishingRod.getPoleEndPosition()
    local ref = tes3.is3rdPerson() and tes3.player or tes3.player1stPerson
    local attachNode = ref.sceneNode:getObjectByName("AttachFishingLine")--[[@as niNode]]
    return attachNode.worldTransform.translation
end

function FishingRod.playCastSound(castStrength)
    local pitch = math.remap(castStrength, 0, 1, 2.0, 1.0)
    logger:debug("Playing cast sound with pitch %s", pitch)
    tes3.playSound{
        soundPath = "mer_fishing\\fishing line.wav",
        pitch = pitch
    }
end

return FishingRod