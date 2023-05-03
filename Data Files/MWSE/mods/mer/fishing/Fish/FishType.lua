local FishInstance = require("mer.fishing.Fish.FishInstance")
local Niche = require("mer.fishing.Fish.Niche")
local common = require("mer.fishing.common")
local logger = common.createLogger("FishType")

---@class Fishing.FishType
---@field baseId string The id of the base object representation of the fish
---@field previewMesh? string The mesh to be displayed in the trophy menu
---@field description string The description to be displayed when the fish is caught
---@field speed number The base speed of the fish
---@field difficulty number The difficulty of catching the fish, out of 100. Default 10 (easy)
---@field niche? Fishing.FishType.Niche The niche where the fish can be found
---@field harvestables Fishing.FishType.Harvestable[] The harvestables that can be obtained from the fish
local FishType = {
    --- A list of all registered fish types
    ---@type table<string, Fishing.FishType>
    registeredFishTypes = {}
}

---@param e Fishing.FishType
function FishType.new(e)
    logger:assert(type(e.baseId) == "string", "FishType must have a baseId")
    logger:assert(type(e.description) == "string", "FishType must have a description")
    logger:assert(type(e.speed) == "number", "FishType must have a speed")
    logger:assert(type(e.harvestables) == "table", "FishType must have a harvestables table")
    if e.previewMesh then
        logger:assert(tes3.getFileExists(string.format("Meshes\\%s", e.previewMesh)), "Preview mesh does not exist")
    end

    local self = setmetatable({}, { __index = FishType })
    self.baseId = e.baseId:lower()
    self.previewMesh = e.previewMesh
    self.description = e.description
    self.speed = e.speed
    self.difficulty = e.difficulty or 10
    self.niche = Niche.new(e.niche)
    self.harvestables = e.harvestables
    return self
end

function FishType:getBaseObject()
    return tes3.getObject(self.baseId) --[[@as tes3misc]]
end

---Register a new type of fish
function FishType.register(e)
    local fish = FishType.new(e)
    FishType.registeredFishTypes[fish.baseId] = fish
    return fish
end

---Create an instance of a fish
---@return Fishing.FishType.instance|nil
function FishType:instance()
    return FishInstance.new(self)
end


return FishType