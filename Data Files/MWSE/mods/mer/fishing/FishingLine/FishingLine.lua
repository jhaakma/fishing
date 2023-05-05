local MESH_PATH = "mer_fishing\\fishing_line.nif"

local MIN_TENSION = -1.0
local MAX_TENSION = 1.0

local MIN_DIST = 500
local MAX_DIST = 1000

---@class FishingLine
---@field sceneNode niNode
---@field curveData niKeyframeData
---@field tension number
local FishingLine = {}
FishingLine.__index = FishingLine

--- Create a new fishing line.
---
---@return FishingLine
function FishingLine.new()
    local self = setmetatable({}, FishingLine)
    self.sceneNode = assert(tes3.loadMesh(MESH_PATH, false)):clone() --[[@as niNode]]
    self.curveData = self.sceneNode.children[1].controller.data
    self.tension = 1.0
    return self
end

--- Attach the fishing line to a parent node.
---
---@param parent niNode
function FishingLine:attachTo(parent)
    parent:attachChild(self.sceneNode)
    parent:update()
    parent:updateEffects()
    parent:updateProperties()
end

function FishingLine:remove()
    self.sceneNode.parent:detachChild(self.sceneNode)
    self.sceneNode = nil
    self.curveData = nil
end

--[[
    Gradually change tension over a given duration
]]
function FishingLine:lerpTension(to, duration)
    local interval = 0.01
    local iterations = math.floor(duration / interval)

    local from = self.tension or 0
    local totalChange = to - from
    local delta = totalChange / iterations
    timer.start{
        duration = interval,
        iterations = iterations,
        callback = function(e)
            if self.sceneNode then
                self.tension = self.tension + delta
                self:updateEndPoint(self.sceneNode.children[1].worldTransform.translation)
            end
        end
    }
end

function FishingLine:setTension(tension)
    self.tension = tension
    self:updateEndPoint(self.sceneNode.children[1].worldTransform.translation)
end


--- Update the fishing line's end point and tension.
---
---@param position tes3vector3
function FishingLine:updateEndPoint(position)

    -- Recenter the fishing line to the parent position.
    local origin = self.sceneNode.parent.worldTransform.translation
    self.sceneNode.translation = origin

    -- Convert absolute position into relative position.
    position = (position - origin) / self.sceneNode.scale

    -- -- Calculate tension value as a function of distance.
    -- local distance = math.clamp(position:length(), MIN_DIST, MAX_DIST)
    -- local tension = math.remap(distance, MIN_DIST, MAX_DIST, MIN_TENSION, MAX_TENSION)

    -- Apply the calculated position and tension values.
    local keys = self.curveData.positionKeys
    local midp = keys[2]
    local endp = keys[3]
    midp.value = position
    midp.tension = self.tension
    endp.value = position * 2
    endp.value.z = 0
    self.curveData:updateDerivedValues()
    self.sceneNode.appCulled = false
end

return FishingLine