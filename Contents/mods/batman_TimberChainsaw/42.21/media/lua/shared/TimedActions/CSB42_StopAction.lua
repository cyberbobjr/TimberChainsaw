-- ============================================================================
-- Timber! Chainsaw — stop the engine
-- complete() (singleplayer, server) replaces Chainsaw by ChainsawOff.
-- ============================================================================

require "TimedActions/ISBaseTimedAction"
require "ChainsawB42/CSB42_Core"

CSB42_StopAction = ISBaseTimedAction:derive("CSB42_StopAction")

function CSB42_StopAction:isValid()
    if isClient() and self.started then
        return true
    end
    return CSB42.isHeldRunning(self.character, self.chainsaw)
end

function CSB42_StopAction:start()
    self.started = true
    self:setOverrideHandModels(self.chainsaw, nil)
    local sound = self.character:playSound("ChainsawB42_Stop")
    if CSB42.adjustVolume then
        CSB42.adjustVolume(self.character, sound)
    end
end

function CSB42_StopAction:perform()
    ISBaseTimedAction.perform(self)
end

function CSB42_StopAction:complete()
    if CSB42.isHeldRunning(self.character, self.chainsaw) and CSB42.stopEngine then
        CSB42.stopEngine(self.character, self.chainsaw)
    end
    return true
end

function CSB42_StopAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 15
end

function CSB42_StopAction:new(character, chainsaw)
    local o = ISBaseTimedAction.new(self, character)
    o.chainsaw = chainsaw
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = o:getDuration()
    return o
end
