
---@class Fishing.common
local common = {}

local config = require("mer.Fishing.config")
local MWSELogger = require("logging.logger")

---@type table<string, mwseLogger>
common.loggers = {}
function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("Fishing - %s", serviceName),
        logLevel = config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

function common.getVersion()
    return config.metadata.package.version
end

function common.disablePlayerControls()
    logger:debug("Disabling player controls")
    --disable everything except vanity\
    tes3.setPlayerControlState{enabled = false }
end

function common.enablePlayerControls()
    logger:debug("Enabling player controls")
    tes3.setPlayerControlState{ enabled = true}
end

return common