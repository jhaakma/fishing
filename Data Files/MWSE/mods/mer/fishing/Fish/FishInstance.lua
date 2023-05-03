local common = require("mer.fishing.common")
local logger = common.createLogger("FishInstance")

---@class Fishing.FishType.instance
---@field fishType Fishing.FishType
---@field weight number
---@field value number
---@field speed number
local FishInstance = {}

---@param fishType Fishing.FishType
---@return Fishing.FishType.instance | nil
function FishInstance.new(fishType)
    local self = setmetatable({}, { __index = FishInstance })
    local baseObject = fishType:getBaseObject()
    if not baseObject then
        logger:warn("Could not find base object for %s", fishType.baseId)
        return nil
    end
    self.fishType = fishType
    self.weight = baseObject.weight
    self.value = baseObject.value
    self.speed = fishType.speed or 1
    return self
end

function FishInstance:getInstanceObject()
    -- local baseObject = tes3.getObject(self.fishType.baseId) --[[@as tes3misc]]
    -- local instance = baseObject:createCopy{}
    -- instance.weight = self.weight
    -- instance.value = self.value
    -- return instance
    return tes3.getObject(self.fishType.baseId) --[[@as tes3misc]]
end

return FishInstance