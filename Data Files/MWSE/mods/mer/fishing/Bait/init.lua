--[[
    Event handler for equipping bait
]]

local common = require("mer.fishing.common")
local logger = common.createLogger("BaitEventHandler")
local Bait = require("mer.fishing.Bait.Bait")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

---comment
---@param e equipEventData
local function onEquip(e)
    local fishingRod = FishingRod.getEquipped()
    if not fishingRod then return end
    if not e.reference == tes3.player then return end
    if not FishingStateManager.isState("IDLE") then return end
    local itemId = e.item.id:lower()
    local bait = Bait.get(itemId)
    if bait then
        local baitObject = tes3.getObject(itemId)
        local currentBait = fishingRod:getEquippedBait()
        local message = string.format("%s - %s", bait:getName(), bait:getTypeName())
        local equipMessage = currentBait
            and string.format("Replace %s", currentBait:getName())
            or string.format("Attach %s", bait:getName())
        tes3ui.showMessageMenu{
            message = message,
            buttons = {
                {
                    text = equipMessage,
                    callback = function()
                        logger:debug("Equipping bait %s", itemId)
                        fishingRod:equipBait(bait)
                    end
                },
                {
                    text = "Eat",
                    showRequirements = function()
                        return baitObject.objectType == tes3.objectType.ingredient
                    end,
                    callback = function()
                        tes3.player.mobile:equip{ ---@diagnostic disable-line
                            item = e.item,--[[@as tes3ingredient]]
                            itemData = e.itemData,
                            playSound = false
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
