--[[
    Event handler for equipping bait
]]

local common = require("mer.fishing.common")
local logger = common.createLogger("BaitEventHandler")
local config = require("mer.fishing.config")
local Bait = require("mer.fishing.Bait.Bait")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local UI = require("mer.fishing.ui")
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
        local currentBait = fishingRod:getEquippedBait()
        local message = currentBait
            and string.format("Replace %s with %s?", currentBait:getName(), bait:getName())
            or string.format("Equip %s?", bait:getName())
        tes3ui.showMessageMenu{
            message = message,
            cancels = true,
            buttons = {
                {
                    text = "Yes",
                    callback = function()
                        logger:debug("Equipping bait %s", itemId)
                        fishingRod:equipBait(bait)
                    end
                },
            }
        }
        --block event
        return false
    end
end
event.register("equip", onEquip, { priority = 500})


---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    local bait = Bait.get(e.object.id:lower())
    if bait then
        UI.addLabelToTooltip(
            e.tooltip,
            bait:getTypeName(),
            config.constants.TOOLTIP_COLOR_BAIT
        )
        return
    end

    local fishingRod = FishingRod.new{
        item = e.object,
        itemData = e.itemData
    }
    if fishingRod then
        local equippedBait = fishingRod:getEquippedBait()
        if equippedBait then

            local labelText = string.format("%s - %s",
                equippedBait:getTypeName(),
                equippedBait:getName()
            )
            if equippedBait.uses then
                labelText = string.format("%s (%d uses)", labelText, equippedBait.uses)
            end
            UI.addLabelToTooltip( e.tooltip,  labelText, config.constants.TOOLTIP_COLOR_BAIT )
        end
    end
end)