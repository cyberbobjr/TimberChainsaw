-- ============================================================================
-- Timber! Chainsaw — cut down a tree with a running chainsaw
--
-- Why trees did not fall with the original mod: IsoTree:Damage(10) removes
-- 10 x 0.05 = 0.5 point, truncated to 1 (IsoTree.java:185-191, 42.21), while a
-- tree has 40 to 560 points: a tank ran dry before a big tree fell.
--
-- Here each hit removes HIT_DAMAGE x TreeCuttingSpeed% points directly
-- (IsoTree:setHealth), and the tree falls with IsoTree:toppleTree, which also
-- drops the logs and removes the tree for every client (server side in MP).
-- Hits happen where the game is authoritative, like the vanilla
-- ISChopTreeAction (42.21): update() timer in singleplayer, animation events
-- emulated by the server in multiplayer (emulateAnimEvent, update() is never
-- called on the server).
-- ============================================================================

require "TimedActions/ISBaseTimedAction"
require "ChainsawB42/CSB42_Core"

CSB42_CutTreeAction = ISBaseTimedAction:derive("CSB42_CutTreeAction")

CSB42.HIT_SECONDS = 0.4
--- Tree points per hit at TreeCuttingSpeed 100: 50 points per second, so a
--- small tree (40-160) falls in 1-3 s and the biggest (560) in about 11 s.
CSB42.HIT_DAMAGE = 20
--- Server check: the player must stand next to the tree (squared tiles).
local MAX_DISTANCE_SQ = 3 * 3
local HIT_EVENT = "CSB42Cut"

local function hitDamage()
    return math.max(1, math.floor(CSB42.HIT_DAMAGE * CSB42.option("TreeCuttingSpeed") / 100 + 0.5))
end

local function nearTree(character, tree)
    local square = tree:getSquare()
    if not square then
        return false
    end
    local dx = square:getX() + 0.5 - character:getX()
    local dy = square:getY() + 0.5 - character:getY()
    return dx * dx + dy * dy <= MAX_DISTANCE_SQ and math.floor(character:getZ()) == square:getZ()
end

local function treeStanding(tree)
    return tree ~= nil and tree:getObjectIndex() >= 0
end

function CSB42_CutTreeAction:isValid()
    local chainsaw = CSB42.getHeldRunning(self.character)
    return treeStanding(self.tree) and chainsaw ~= nil and CSB42.hasFuel(chainsaw)
end

function CSB42_CutTreeAction:waitToStart()
    self.character:faceThisObject(self.tree)
    return self.character:shouldBeTurning()
end

function CSB42_CutTreeAction:start()
    self.chainsaw = CSB42.getHeldRunning(self.character)
    self.hitTimer = 0
    if self.chainsaw then
        self.chainsaw:setJobType(getText("ContextMenu_CSB42_CutTree"))
        self.chainsaw:setJobDelta(0.0)
        self:setOverrideHandModels(self.chainsaw, nil)
    end
    if self.character:isTimedActionInstant() then
        self.tree:setHealth(1)
    end
    self:setActionAnim("CSB42CutTree")
    self.sound = self.character:playSound("ChainsawB42_WoodCut")
    if CSB42.adjustVolume then
        CSB42.adjustVolume(self.character, self.sound)
    end
end

function CSB42_CutTreeAction:serverStart()
    self.chainsaw = CSB42.getHeldRunning(self.character)
    emulateAnimEvent(self.netAction, CSB42.HIT_SECONDS * 1000, HIT_EVENT, nil)
end

function CSB42_CutTreeAction:update()
    self.character:faceThisObject(self.tree)
    self.character:setMetabolicTarget(Metabolics.ForestryAxe)
    -- getMultiplier() is about 48 per second at game speed x1 (0.8 per tick at 60 FPS)
    local seconds = getGameTime():getMultiplier() / 48
    if isClient() then
        -- The tree health only changes on the server (IsoTree.setHealth):
        -- the progress bar is estimated from the time spent cutting.
        self.elapsed = (self.elapsed or 0) + seconds
        if self.chainsaw and treeStanding(self.tree) then
            local left = self.tree:getHealth() - math.floor(self.elapsed / CSB42.HIT_SECONDS) * hitDamage()
            local total = self.tree:getMaxHealth()
            if total > 0 then
                self.chainsaw:setJobDelta(math.min(1, math.max(0, 1 - left / total)))
            end
        end
        return
    end
    if self.chainsaw and treeStanding(self.tree) then
        local total = self.tree:getMaxHealth()
        if total > 0 then
            self.chainsaw:setJobDelta(1 - self.tree:getHealth() / total)
        end
    end
    self.hitTimer = (self.hitTimer or 0) + seconds
    if self.hitTimer >= CSB42.HIT_SECONDS then
        self.hitTimer = self.hitTimer - CSB42.HIT_SECONDS
        self:hit()
    end
end

function CSB42_CutTreeAction:animEvent(event, parameter)
    if event == HIT_EVENT and isServer() then
        self:hit()
    end
end

function CSB42_CutTreeAction:finish()
    if self.finished then
        return
    end
    self.finished = true
    if isServer() then
        self.netAction:forceComplete()
    else
        self:forceComplete()
    end
end

--- Authority only (singleplayer, server).
function CSB42_CutTreeAction:hit()
    local chainsaw = CSB42.getHeldRunning(self.character)
    if not chainsaw or not treeStanding(self.tree) or not CSB42.hasFuel(chainsaw)
        or not nearTree(self.character, self.tree) then
        self:finish()
        return
    end

    local damage = hitDamage()
    local health = self.tree:getHealth() - damage
    if health <= 0 then
        self.tree:setHealth(0)
        self.tree:toppleTree(self.character)
    else
        self.tree:setHealth(health)
    end

    CSB42.burnCuttingFuel(chainsaw, damage)

    -- Wear, as in the original mod: 1 chance in 8 per hit.
    local wear = CSB42.option("ConditionLossTree")
    if wear > 0 and ZombRand(8) == 0 then
        chainsaw:setCondition(math.max(0, chainsaw:getCondition() - wear))
        if isServer() then
            chainsaw:syncItemFields()
        end
    end

    if chainsaw:isBroken() then
        if CSB42.stopEngine then
            CSB42.stopEngine(self.character, chainsaw, "IGUI_CSB42_Broken")
        end
        self:finish()
    elseif not CSB42.hasFuel(chainsaw) then
        if CSB42.stopEngine then
            CSB42.stopEngine(self.character, chainsaw, "IGUI_CSB42_OutOfFuel")
        end
        self:finish()
    elseif not treeStanding(self.tree) then
        self:finish()
    end
end

local function endSound(self)
    if self.sound and self.sound ~= 0 then
        self.character:stopOrTriggerSound(self.sound)
    end
    if self.chainsaw then
        self.chainsaw:setJobDelta(0.0)
    end
end

function CSB42_CutTreeAction:stop()
    endSound(self)
    ISBaseTimedAction.stop(self)
end

function CSB42_CutTreeAction:perform()
    endSound(self)
    ISBaseTimedAction.perform(self)
end

function CSB42_CutTreeAction:complete()
    return true
end

function CSB42_CutTreeAction:getDuration()
    return -1
end

function CSB42_CutTreeAction:new(character, tree)
    local o = ISBaseTimedAction.new(self, character)
    o.tree = tree
    o.stopOnWalk = true
    o.stopOnRun = true
    o.caloriesModifier = 8
    o.maxTime = o:getDuration()
    return o
end
