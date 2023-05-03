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

return FishingRod