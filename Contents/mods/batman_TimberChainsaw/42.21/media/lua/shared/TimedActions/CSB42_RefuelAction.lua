-- ============================================================================
-- Timber! Chainsaw — refuel from a petrol can
-- Only pure petrol, and only the litres the tank can take. The original mod
-- accepted any fluid and emptied the whole can (adjustAmount(-x) sets the
-- amount to 0). complete() follows the vanilla ISAddFuel:complete (42.21).
-- ============================================================================

require "TimedActions/ISBaseTimedAction"
require "ChainsawB42/CSB42_Core"

CSB42_RefuelAction = ISBaseTimedAction:derive("CSB42_RefuelAction")

local function canRefuel(character, chainsaw, petrol)
    local inventory = character:getInventory()
    return chainsaw ~= nil and petrol ~= nil
        and chainsaw:getFullType() == CSB42.FULLTYPE_OFF
        and inventory:contains(chainsaw)
        and inventory:contains(petrol)
        and CSB42.refuelAmount(chainsaw, petrol) > 0
end

function CSB42_RefuelAction:isValid()
    if isClient() and self.started then
        return true
    end
    return canRefuel(self.character, self.chainsaw, self.petrol)
end

function CSB42_RefuelAction:start()
    self.started = true
    self.chainsaw:setJobType(getText("ContextMenu_CSB42_Refuel"))
    self.chainsaw:setJobDelta(0.0)
    self.petrol:setJobType(getText("ContextMenu_CSB42_Refuel"))
    self.petrol:setJobDelta(0.0)
    self:setActionAnim("Loot")
    self.sound = self.character:playSound("GeneratorAddFuel")
end

function CSB42_RefuelAction:update()
    local delta = self:getJobDelta()
    self.chainsaw:setJobDelta(delta)
    self.petrol:setJobDelta(delta)
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

local function endSound(self)
    if self.sound and self.sound ~= 0 then
        self.character:stopOrTriggerSound(self.sound)
    end
    self.chainsaw:setJobDelta(0.0)
    self.petrol:setJobDelta(0.0)
end

function CSB42_RefuelAction:stop()
    endSound(self)
    ISBaseTimedAction.stop(self)
end

function CSB42_RefuelAction:perform()
    endSound(self)
    ISBaseTimedAction.perform(self)
end

function CSB42_RefuelAction:complete()
    if not canRefuel(self.character, self.chainsaw, self.petrol) then
        return true
    end
    local amount = CSB42.refuelAmount(self.chainsaw, self.petrol)
    local fluid = self.petrol:getFluidContainer()
    fluid:adjustAmount(fluid:getAmount() - amount)
    CSB42.setFuel(self.chainsaw, CSB42.getFuel(self.chainsaw) + amount)
    self.petrol:syncItemFields()
    self.chainsaw:syncItemFields()
    return true
end

function CSB42_RefuelAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 40 + CSB42.refuelAmount(self.chainsaw, self.petrol) * 40
end

function CSB42_RefuelAction:new(character, chainsaw, petrol)
    local o = ISBaseTimedAction.new(self, character)
    o.chainsaw = chainsaw
    o.petrol = petrol
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
