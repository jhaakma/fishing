--[[
    Event handler for equipping bait
]]

local common = require("mer.fishing.common")
local logger = common.createLogger("BaitEventHandler")
local Bait = require("mer.fishing.Bait.Bait")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")


local skipEquip = false
---comment
---@param e equipEventData
local function onEquip(e)
    if skipEquip then
        skipEquip = false
        return
    end

    if not e.reference == tes3.player then return end
    if not FishingStateManager.isState("IDLE") then return end
    local itemId = e.item.id:lower()
    local bait = Bait.get(itemId)
    if bait then
        local fishingRod = FishingRod.getEquipped()
        local baitObject = tes3.getObject(itemId)
        local message = string.format("%s - %s", bait:getName(), bait:getTypeName())
        local equipMessage = string.format("Attach %s", bait:getName())
        if fishingRod then
            local currentBait = fishingRod:getEquippedBait()
            if currentBait then
                equipMessage = string.format("Replace %s", currentBait:getName())
            end
        end
        tes3ui.showMessageMenu{
            message = message,
            buttons = {
                {
                    text = equipMessage,
                    callback = function()
                        logger:debug("Equipping bait %s", itemId)
                        if fishingRod then
                            fishingRod:equipBait(bait)
                        end
                    end,
                    enableRequirements = function()
                        return fishingRod ~= nil
                    end,
                    tooltipDisabled = function ()
                        return {
                            text = "Must have a fishing rod equipped."
                        }
                    end
                },
                {
                    text = "Eat",
                    showRequirements = function()
                        return baitObject.objectType == tes3.objectType.ingredient
                    end,
                    callback = function()
                        logger:debug("Eating bait %s", itemId)
                        skipEquip = true
                        mwscript.equip{
                            reference = tes3.player,
                            item = baitObject,
                        }
                    end
                },
            },
            cancels = true,
        }
        --block event
        return false
    end
end
event.register("equip", onEquip, { priority = 500})