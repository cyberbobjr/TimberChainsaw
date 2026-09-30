-- ============================================================================
-- Timber! Chainsaw — start the engine
-- complete() runs where the game is authoritative (singleplayer, server): it
-- replaces ChainsawOff by Chainsaw in both hands. The server never calls the
-- Lua isValid() (NetTimedAction.java:119-122, 42.21): complete() checks again.
-- ============================================================================

require "TimedActions/ISBaseTimedAction"
require "ChainsawB42/CSB42_Core"

CSB42_StartAction = ISBaseTimedAction:derive("CSB42_StartAction")

local function canStart(character, chainsaw)
    return chainsaw ~= nil
        and chainsaw:getFullType() == CSB42.FULLTYPE_OFF
        and not chainsaw:isBroken()
        and CSB42.hasFuel(chainsaw)
        and character:getPrimaryHandItem() == chainsaw
        and character:getSecondaryHandItem() == chainsaw
        and character:getVehicle() == nil
end

function CSB42_StartAction:isValid()
    if isClient() and self.started then
        return true
    end
    return canStart(self.character, self.chainsaw)
end

function CSB42_StartAction:start()
    self.started = true
    self.chainsaw:setJobType(getText("ContextMenu_CSB42_Start"))
    self.chainsaw:setJobDelta(0.0)
    self:setActionAnim("CSB42Start")
    self:setOverrideHandModels(self.chainsaw, nil)
    self.sound = self.character:playSound("ChainsawB42_Start")
    if CSB42.adjustVolume then
        CSB42.adjustVolume(self.character, self.sound)
    end
end

function CSB42_StartAction:update()
    self.chainsaw:setJobDelta(self:getJobDelta())
end

function CSB42_StartAction:stop()
    if self.sound and self.sound ~= 0 then
        self.character:stopOrTriggerSound(self.sound)
    end
    self.chainsaw:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function CSB42_StartAction:perform()
    self.chainsaw:setJobDelta(0.0)
    ISBaseTimedAction.perform(self)
end

--- A worn chainsaw (below half condition) may refuse to start.
local function jams(chainsaw)
    local chance = CSB42.option("JamFrequency")
    if chance <= 0 then
        return false
    end
    if chainsaw:getCondition() * 2 >= chainsaw:getConditionMax() then
        return false
    end
    return ZombRand(100) < chance
end

function CSB42_StartAction:complete()
    if not canStart(self.character, self.chainsaw) then
        return true
    end
    if jams(self.chainsaw) then
        CSB42.notify(self.character, "IGUI_CSB42_Jammed")
        return true
    end
    local running = CSB42.replace(self.chainsaw, CSB42.FULLTYPE_RUNNING, self.character)
    if running and CSB42.onStarted then
        CSB42.onStarted(self.character, running)
    end
    return true
end

function CSB42_StartAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 60
end

function CSB42_StartAction:new(character, chainsaw)
    local o = ISBaseTimedAction.new(self, character)
    o.chainsaw = chainsaw
    o.stopOnWalk = false
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
