local common = require("mer.fishing.common")
local logger = common.createLogger("MCM")
local config = require("mer.fishing.config")
local metadata = config.metadata --[[@as MWSE.Metadata]]
local LINKS_LIST = {
    -- {
    --     text = "Release history",
    --     url = "https://github.com/jhaakma/***/releases"
    -- },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/***/wiki"
    -- },
    -- {
    --     text = "Nexus",
    --     url = "https://www.nexusmods.com/morrowind/mods/*****"
    -- },
    {
        text = "Buy me a coffee",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Made by Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local function addSideBar(component)
    component.sidebar:createCategory(metadata.package.name)
    component.sidebar:createInfo{ text = metadata.package.description}

    local linksCategory = component.sidebar:createCategory("Links")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Credits")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = metadata.package.name }
    template.onClose = function()
        config.save()
        event.trigger("Fishing:McmUpdated")
    end
    template:register()

    local page = template:createSideBarPage{ label = "Settings"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Enable Mod",
        description = "Turn this mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config.mcm },
        callback = function(self)
            if self.variable.value == true then
                logger:info("Enabling mod")
                event.trigger("Fishing:ModEnabled")
                event.trigger("Fishing:McmUpdated")
            else
                logger:info("Disabling mod")
                event.trigger("Fishing:ModDisabled")
            end
        end
    }

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level for all Fishing Loggers.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm},
        callback = function(self)
            for _, logger in pairs(common.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }

end
event.register("modConfigReady", registerMCM)