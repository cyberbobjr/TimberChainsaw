-- Simulated Project Zomboid 42.21 API for the Timber! Chainsaw tests.
-- Only what the mod calls, with the behaviour read in the decompiled game:
--   FluidContainer:adjustAmount(x) SETS the amount, clamped to [0, capacity]
--   (FluidContainer.java:647); IsoTree:toppleTree removes the tree
--   (getObjectIndex() == -1); instanceof() tests Java classes only.

local api = {
    client = false,
    server = false,
    multiplier = 0.8, -- GameTime:getMultiplier() at x1, 60 FPS
    rand = function(n) return n - 1 end, -- never 0: no jam, no wear
    log = {},
    nextId = 1000,
    soundVolume = 10,
}
GameAPI = api

local function record(kind, data)
    data = data or {}
    data.kind = kind
    api.log[#api.log + 1] = data
end

function api.count(kind)
    local n = 0
    for _, entry in ipairs(api.log) do
        if entry.kind == kind then
            n = n + 1
        end
    end
    return n
end

function api.last(kind)
    for i = #api.log, 1, -1 do
        if api.log[i].kind == kind then
            return api.log[i]
        end
    end
    return nil
end

-- ArrayList ------------------------------------------------------------------

function api.list(items)
    local list = { items = items or {} }
    function list:size() return #self.items end
    function list:get(i) return self.items[i + 1] end
    function list:add(v) self.items[#self.items + 1] = v end
    return list
end

-- Globals ----------------------------------------------------------------------

function instanceof(obj, class)
    return type(obj) == "table" and obj.__classes ~= nil and obj.__classes[class] == true
end

api.now = 0
function getTimestampMs() return api.now end
function isClient() return api.client end
function isServer() return api.server end
function ZombRand(n) return api.rand(n) end
function getText(key) return key end
function print() end

SandboxVars = { ChainsawB42 = {} }
Fluid = { Petrol = "Petrol", Water = "Water", Bleach = "Bleach" }
Metabolics = { ForestryAxe = "ForestryAxe", LightDomestic = "LightDomestic" }

local gameTime = {}
function gameTime:getMultiplier() return api.multiplier end
function getGameTime() return gameTime end

local core = {}
function core:getOptionSoundVolume() return api.soundVolume end
function getCore() return core end

function sendRemoveItemFromContainer(container, item) record("sendRemove", { item = item }) end
function sendAddItemToContainer(container, item)
    record("sendAdd", { item = item, receivedCondition = api.savedCondition(item) })
end
function replaceItemInContainer(container, old, new)
    -- LuaManager.java:9753: (IsoPlayer) cast of the parent in singleplayer
    if not api.server and not api.client and container:getParent() ~= nil
        and not instanceof(container:getParent(), "IsoPlayer") then
        error("ClassCastException: parent is not an IsoPlayer")
    end
    record("replaceQueued", { old = old, new = new })
end
function sendEquip(player) record("sendEquip", { player = player }) end
function sendServerCommand(player, module, command, args)
    record("serverCommand", { player = player, module = module, command = command, args = args })
end
function addSound(source, x, y, z, radius, volume)
    record("addSound", { radius = radius, volume = volume })
end
function emulateAnimEvent(netAction, ms, event, param)
    record("emulate", { ms = ms, event = event })
end

HaloTextHelper = {}
function HaloTextHelper.addBadText(player, text) record("halo", { player = player, text = text }) end

-- Fluid container -------------------------------------------------------------

function api.fluid(fluid, amount, capacity, mixed)
    local c = { fluid = fluid, amount = amount, capacity = capacity or 10, mixed = mixed }
    function c:getAmount() return self.amount end
    function c:getCapacity() return self.capacity end
    function c:isPureFluid(f) return not self.mixed and self.amount > 0 and self.fluid == f end
    function c:adjustAmount(newAmount)
        if self.amount <= 0 then return end
        self.amount = math.max(0, math.min(newAmount, self.capacity))
    end
    c.__classes = { FluidContainer = true }
    return c
end

-- Items -------------------------------------------------------------------------

local SCRIPTS = {
    ["ChainsawB42.ChainsawOff"] = { min = 0.1, max = 0.5 },
    ["ChainsawB42.Chainsaw"] = { min = 0.6, max = 1.1 },
}

-- Read condition maxima and weight from the actual item definitions: a mock
-- with an independent safe maximum would miss the signed-byte regression.
local itemDefinitions = readModFile("../scripts/ChainsawB42_Items.txt")
for name, definition in itemDefinitions:gmatch("item%s+(%w+)%s*{(.-)}") do
    local script = SCRIPTS["ChainsawB42." .. name]
    if script then
        script.conditionMax = tonumber(definition:match("ConditionMax%s*=%s*([%d.]+)"))
        script.weight = tonumber(definition:match("Weight%s*=%s*([%d.]+)"))
    end
end

-- InventoryItem.save omits condition when full, otherwise writes a SIGNED
-- byte. load reads that byte, clamping negative values to zero (42.21).
function api.savedCondition(item)
    local condition, maximum = item:getCondition(), item:getConditionMax()
    if condition == maximum then return maximum end
    local signed = (condition + 128) % 256 - 128
    return math.max(0, math.min(signed, maximum))
end

function api.item(fullType, fields)
    api.nextId = api.nextId + 1
    local script = SCRIPTS[fullType] or { min = 0, max = 0 }
    local item = {
        fullType = fullType, id = api.nextId, modData = {},
        condition = script.conditionMax or 100, conditionMax = script.conditionMax or 100,
        weight = script.weight or 1,
        favorite = false, name = fullType, customName = false, blood = 0, repaired = 0,
        minDamage = script.min, maxDamage = script.max, syncs = 0,
        __classes = { InventoryItem = true },
    }
    for k, v in pairs(fields or {}) do item[k] = v end
    function item:getFullType() return self.fullType end
    function item:getID() return self.id end
    function item:getModData() return self.modData end
    function item:getCondition() return self.condition end
    function item:setCondition(v) self.condition = math.max(0, math.min(v, self.conditionMax)) end
    function item:getConditionMax() return self.conditionMax end
    function item:getActualWeight() return self.weight end
    function item:isBroken() return self.condition <= 0 end
    function item:getContainer() return self.container end
    function item:getWorldItem() return self.worldItem end
    function item:setWorldItem(w) self.worldItem = w end
    function item:getFluidContainer() return self.fluid end
    function item:isFavorite() return self.favorite end
    function item:setFavorite(v) self.favorite = v end
    function item:isCustomName() return self.customName end
    function item:setCustomName(v) self.customName = v end
    function item:getName() return self.name end
    function item:setName(v) self.name = v end
    function item:getBloodLevel() return self.blood end
    function item:setBloodLevel(v) self.blood = v end
    function item:getHaveBeenRepaired() return self.repaired end
    function item:setHaveBeenRepaired(v) self.repaired = v end
    function item:getScriptItem()
        return { getMinDamage = function() return script.min end, getMaxDamage = function() return script.max end }
    end
    function item:setMinDamage(v) self.minDamage = v end
    function item:setMaxDamage(v) self.maxDamage = v end
    function item:syncItemFields() self.syncs = self.syncs + 1 end
    function item:getTreeDamage() return fullType == "ChainsawB42.Chainsaw" and 67 or 1 end
    function item:setJobType() end
    function item:setJobDelta(v) self.jobDelta = v end
    return item
end

function instanceItem(fullType)
    return api.item(fullType)
end

function api.container(parent)
    local c = { items = {}, parent = parent }
    function c:contains(item)
        for _, v in ipairs(self.items) do if v == item then return true end end
        return false
    end
    function c:AddItem(item)
        self.items[#self.items + 1] = item
        item.container = self
        return item
    end
    function c:Remove(item)
        for i, v in ipairs(self.items) do
            if v == item then
                table.remove(self.items, i)
                item.container = nil
                return
            end
        end
    end
    function c:getParent() return self.parent end
    function c:getAllEvalRecurse(predicate)
        local found = api.list()
        for _, v in ipairs(self.items) do
            if predicate(v) then found:add(v) end
        end
        return found
    end
    return c
end

-- World --------------------------------------------------------------------------

function api.square(x, y, z)
    local sq = { x = x or 10, y = y or 10, z = z or 0, ground = {} }
    function sq:getX() return self.x end
    function sq:getY() return self.y end
    function sq:getZ() return self.z end
    function sq:transmitRemoveItemFromSquare(obj) record("transmitRemove", { obj = obj }) end
    function sq:removeWorldObject(obj) obj.removed = true end
    function sq:AddWorldInventoryItem(item, dx, dy, dz)
        local world = api.worldItem(self, item, dx, dy, dz)
        self.ground[#self.ground + 1] = world
        return item
    end
    return sq
end

function api.worldItem(square, item, dx, dy, dz)
    local w = { square = square, item = item, dx = dx or 0.5, dy = dy or 0.5, dz = dz or 0 }
    function w:getSquare() return self.square end
    function w:getWorldPosX() return self.square.x + self.dx end
    function w:getWorldPosY() return self.square.y + self.dy end
    function w:getWorldPosZ() return self.square.z + self.dz end
    item.worldItem = w
    return w
end

function api.tree(health, maxHealth)
    local tree = { health = health, maxHealth = maxHealth or health, index = 3, __classes = { IsoTree = true } }
    function tree:getObjectIndex() return self.index end
    function tree:getHealth() return self.health end
    function tree:setHealth(v) self.health = math.max(v, 0) end
    function tree:getMaxHealth() return self.maxHealth end
    function tree:toppleTree(owner)
        if api.client then return end
        self.index = -1
        self.toppledBy = owner
    end
    function tree:getSquare() return api.square() end
    return tree
end

-- Players -------------------------------------------------------------------------

function api.player(fields)
    api.nextId = api.nextId + 1
    local p = { x = 10, y = 10, z = 0, dead = false, sounds = {}, nextSound = 1,
        __classes = { IsoPlayer = true, IsoGameCharacter = true, IsoObject = true } }
    for k, v in pairs(fields or {}) do p[k] = v end
    p.inventory = p.inventory or api.container(p)
    local emitter = { playing = {}, volumes = {} }
    function emitter:playSoundImpl(name) p.nextSound = p.nextSound + 1; self.playing[p.nextSound] = name; return p.nextSound end
    function emitter:isPlaying(id) return self.playing[id] ~= nil end
    function emitter:setVolume(id, v) self.volumes[id] = v end
    function emitter:stopSoundLocal(id) self.playing[id] = nil; record("stopLocal", { id = id }) end
    p.emitter = emitter
    function p:getEmitter() return self.emitter end
    function p:getInventory() return self.inventory end
    function p:getPrimaryHandItem() return self.primary end
    function p:getSecondaryHandItem() return self.secondary end
    function p:setPrimaryHandItem(v) self.primary = v end
    function p:setSecondaryHandItem(v) self.secondary = v end
    function p:removeFromHands(item)
        if self.primary == item then self.primary = nil end
        if self.secondary == item then self.secondary = nil end
    end
    function p:isDead() return self.dead end
    function p:getVehicle() return self.vehicle end
    function p:getX() return self.x end
    function p:getY() return self.y end
    function p:getZ() return self.z end
    function p:isTimedActionInstant() return false end
    function p:playSound(name) p.nextSound = p.nextSound + 1; self.emitter.playing[p.nextSound] = name; return p.nextSound end
    function p:stopOrTriggerSound(id) self.emitter.playing[id] = nil end
    function p:faceThisObject() end
    function p:shouldBeTurning() return false end
    function p:setMetabolicTarget() end
    p.forward = p.forward or { x = 1, y = 0 }
    function p.getForwardDirection(player)
        local f = player.forward
        return { getX = function() return f.x end, getY = function() return f.y end }
    end
    function p:getCurrentSquare() return api.square(math.floor(self.x), math.floor(self.y), self.z) end
    function p:isAttacking() return self.attacking == true end
    function p:isAttackStarted() return self.attackStarted == true end
    function p:getVariableString(name) return (self.vars or {})[name] end
    return p
end

--- A player holding `item` in both hands (item in the main inventory).
function api.holding(item, fields)
    local p = api.player(fields)
    p.inventory:AddItem(item)
    p.primary, p.secondary = item, item
    return p
end

-- Cell: squares with a tree, api.trees["x,y,z"] = true
api.trees = {}
local cell = {}
function cell:getGridSquare(x, y, z)
    local sq = api.square(x, y, z)
    sq.getTree = function()
        if api.trees[x .. "," .. y .. "," .. z] then return {} end
        return nil
    end
    return sq
end
function getCell() return cell end

function api.setLocalPlayers(players)
    function getNumActivePlayers() return #players end
    function getSpecificPlayer(i) return players[i + 1] end
end

function api.setOnlinePlayers(players)
    function getOnlinePlayers() return api.list(players) end
end

api.setLocalPlayers({})
api.setOnlinePlayers({})

-- Timed actions -------------------------------------------------------------------

ISBaseTimedAction = {}
ISBaseTimedAction.__index = ISBaseTimedAction
function ISBaseTimedAction:derive(name)
    local class = setmetatable({ Type = name }, { __index = self })
    class.__index = class
    return class
end
function ISBaseTimedAction.new(class, character)
    local o = setmetatable({}, class)
    o.character = character
    o.netAction = { forceComplete = function(n) n.completed = true end }
    return o
end
function ISBaseTimedAction:setActionAnim(anim) self.anim = anim end
function ISBaseTimedAction:setOverrideHandModels() end
function ISBaseTimedAction:getJobDelta() return 0 end
function ISBaseTimedAction:forceComplete() self.forceCompleted = true end
function ISBaseTimedAction:stop() end
function ISBaseTimedAction:perform() end

return api
