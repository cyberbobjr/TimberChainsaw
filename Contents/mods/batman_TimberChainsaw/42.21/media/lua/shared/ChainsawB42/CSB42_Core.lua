-- ============================================================================
-- Timber! Chainsaw — shared core
--
-- Rework of Chainsaw B42 by Likit (Workshop 3692027888). Same items, same
-- ModData keys (CurrentFuel, FuelCapacity): chainsaws from a save
-- made with the original mod keep their fuel.
--
-- The running state IS the item type:
--   ChainsawB42.ChainsawOff  engine stopped
--   ChainsawB42.Chainsaw     engine running (only while held in both hands)
-- The engine gives the vanilla chainsaw animations and attack to an item whose
-- type is exactly "Chainsaw", held in both hands (WeaponType.java:63, :100, 42.21).
-- The item type is saved and synchronised by the game itself, so client and
-- server always agree on the weapon stats (tree damage, damage, sounds).
--
-- Authority: the swap between the two items, the fuel and the wear happen where
-- the game is authoritative: in singleplayer, and on the server in multiplayer
-- (timed action complete(), server tick). A client never writes them.
-- ============================================================================

CSB42 = CSB42 or {}

CSB42.MODULE = "ChainsawB42"
CSB42.TYPE_OFF = "ChainsawOff"
CSB42.TYPE_RUNNING = "Chainsaw"
CSB42.FULLTYPE_OFF = "ChainsawB42.ChainsawOff"
CSB42.FULLTYPE_RUNNING = "ChainsawB42.Chainsaw"
CSB42.MAGAZINE = "ChainsawB42.ChainsawMaintenanceMagazine"

-- Optional compatibility mods register existing off/on pairs; no new item IDs.
CSB42.families = CSB42.families or {}
function CSB42.registerFamily(family)
    assert(family.off and family.running and family.off ~= family.running)
    CSB42.families[family.off] = family
    CSB42.families[family.running] = family
end
CSB42.registerFamily({ off = CSB42.FULLTYPE_OFF, running = CSB42.FULLTYPE_RUNNING })

function CSB42.getFamily(item)
    if not instanceof(item, "InventoryItem") then return nil end
    return CSB42.families[item:getFullType()]
end

function CSB42.isStoppedType(item)
    local family = CSB42.getFamily(item)
    return family ~= nil and item:getFullType() == family.off
end

function CSB42.stateType(item, running)
    local family = CSB42.getFamily(item)
    if not family then return nil end
    if running then return family.running end
    return family.off
end

local function fuelData(item, create)
    local data = item:getModData()
    local family = CSB42.getFamily(item)
    if not family or not family.dataKey then return data end
    if type(data[family.dataKey]) ~= "table" then
        if not create then return data end -- read legacy fuel without changing it
        data[family.dataKey] = {
            CurrentFuel = data.CurrentFuel, FuelCapacity = data.FuelCapacity,
        }
    end
    return data[family.dataKey]
end

-- Compatibility wear is proportional to Timber's 127-point maximum.
-- Fractional losses are retained so a 15-point saw does not lose 1 per tree hit.
function CSB42.applyWear(item, amount)
    local family = CSB42.getFamily(item)
    if family and family.dataKey then
        local data = fuelData(item, true)
        local remainder = type(data.wearRemainder) == "number" and data.wearRemainder or 0
        local total = remainder + amount * item:getConditionMax() / 127
        amount = math.floor(total)
        data.wearRemainder = total - amount
    end
    item:setCondition(math.max(0, item:getCondition() - amount))
end

CSB42.FUEL_CAPACITY = 4.0
--- Fuel burnt per second of real time at game speed x1, before the
--- FuelConsumption sandbox option: 4 L last ~16 min idle.
CSB42.FUEL_IDLE_PER_SECOND = 0.004
--- Extra fuel per tree point cut, from the menu or with held attacks: the
--- biggest tree (560 points) takes about 0.45 L on top of idling.
CSB42.FUEL_PER_TREE_POINT = 0.0008
--- Smallest amount taken from a petrol can (vanilla predicatePetrol uses 0.099).
CSB42.MIN_PETROL = 0.01

-- ----------------------------------------------------------------------------
-- Sandbox options (namespace ChainsawB42, same names as the original mod)
-- ----------------------------------------------------------------------------

local DEFAULTS = {
    FuelConsumption = 100,
    DamageMod = 100,
    ConditionLossCombat = 20,
    ConditionLossTree = 1,
    TreeCuttingSpeed = 100,
    NoiseMod = 50,
    JamFrequency = 25,
    LootChance = 3,
}

function CSB42.option(name)
    local vars = SandboxVars and SandboxVars.ChainsawB42
    local value = vars and vars[name]
    if type(value) ~= "number" then
        return DEFAULTS[name]
    end
    return value
end

-- ----------------------------------------------------------------------------
-- Item checks
-- ----------------------------------------------------------------------------

function CSB42.isChainsaw(item)
    return CSB42.getFamily(item) ~= nil
end

function CSB42.isRunningType(item)
    local family = CSB42.getFamily(item)
    return family ~= nil and item:getFullType() == family.running
end

--- The engine runs only while the running item is held in both hands.
function CSB42.isHeldRunning(character, item)
    if not character or not CSB42.isRunningType(item) then
        return false
    end
    local held = character:getPrimaryHandItem() == item and character:getSecondaryHandItem() == item
    local family = CSB42.getFamily(item)
    if held and family.prepareRunning then family.prepareRunning(item) end
    return held
end

--- The running chainsaw a character holds, or nil.
function CSB42.getHeldRunning(character)
    if not character then
        return nil
    end
    local item = character:getPrimaryHandItem()
    if CSB42.isHeldRunning(character, item) then
        return item
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- Fuel (ModData, same keys as the original mod)
-- A chainsaw that never stored its fuel is full, like in the original mod.
-- ----------------------------------------------------------------------------

function CSB42.getCapacity(item)
    local capacity = fuelData(item, false).FuelCapacity
    if type(capacity) ~= "number" or capacity <= 0 then
        return CSB42.FUEL_CAPACITY
    end
    return capacity
end

function CSB42.getFuel(item)
    local fuel = fuelData(item, false).CurrentFuel
    if type(fuel) ~= "number" then
        return CSB42.getCapacity(item)
    end
    return math.max(0, math.min(fuel, CSB42.getCapacity(item)))
end

--- Authority only: the value reaches clients with syncItemFields.
function CSB42.setFuel(item, amount)
    local modData = fuelData(item, true)
    modData.FuelCapacity = CSB42.getCapacity(item)
    modData.CurrentFuel = math.max(0, math.min(amount, modData.FuelCapacity))
end

function CSB42.hasFuel(item)
    return CSB42.getFuel(item) > 0
end

function CSB42.freeCapacity(item)
    return math.max(0, CSB42.getCapacity(item) - CSB42.getFuel(item))
end

--- Authority only: burns the extra fuel of `points` tree points cut, scaled
--- by the FuelConsumption option. Returns true while fuel is left.
function CSB42.burnCuttingFuel(item, points)
    local ratio = CSB42.option("FuelConsumption") / 100
    CSB42.setFuel(item, CSB42.getFuel(item) - points * CSB42.FUEL_PER_TREE_POINT * ratio)
    return CSB42.hasFuel(item)
end

-- ----------------------------------------------------------------------------
-- Petrol can: pure petrol only.
-- The original mod accepted any fluid (water, bleach...) and emptied the whole
-- can: FluidContainer:adjustAmount() SETS the amount (clamped to 0), it does not
-- add a delta (FluidContainer.java:647, 42.21; vanilla ISAddFuel:complete).
-- ----------------------------------------------------------------------------

function CSB42.isPetrolCan(item)
    if not instanceof(item, "InventoryItem") or CSB42.isChainsaw(item) then
        return false
    end
    local fluid = item:getFluidContainer()
    return fluid ~= nil and fluid:isPureFluid(Fluid.Petrol) and fluid:getAmount() >= CSB42.MIN_PETROL
end

--- Litres moved from the can to the chainsaw by a refuel.
function CSB42.refuelAmount(chainsaw, petrol)
    if not CSB42.isPetrolCan(petrol) then
        return 0
    end
    return math.min(CSB42.freeCapacity(chainsaw), petrol:getFluidContainer():getAmount())
end

--- Best petrol can of an inventory (most petrol), searched in bags too.
function CSB42.findPetrolCan(inventory)
    local cans = inventory:getAllEvalRecurse(CSB42.isPetrolCan)
    local best
    for i = 0, cans:size() - 1 do
        local can = cans:get(i)
        if not best or can:getFluidContainer():getAmount() > best:getFluidContainer():getAmount() then
            best = can
        end
    end
    return best
end

-- ----------------------------------------------------------------------------
-- Authority: replace a chainsaw by the other type, wherever it is.
-- Pattern of the vanilla ISClothingExtraAction:complete (42.21).
-- ----------------------------------------------------------------------------

local function copyState(old, new)
    local oldData, newData = old:getModData(), new:getModData()
    for key, value in pairs(oldData) do
        newData[key] = value
    end
    local family = CSB42.getFamily(old)
    if family and family.dataKey and type(oldData[family.dataKey]) == "table" then
        local copy = {}
        for key, value in pairs(oldData[family.dataKey]) do copy[key] = value end
        newData[family.dataKey] = copy
    end
    CSB42.setFuel(new, CSB42.getFuel(old))
    local condition = old:getCondition()
    local oldMax, newMax = old:getConditionMax(), new:getConditionMax()
    if condition > 0 and oldMax > 0 and oldMax ~= newMax then
        -- Preserve the percentage for a legacy item or a modified condition
        -- maximum. Do not round a usable item down to broken or repair a zero.
        condition = math.max(1, math.floor(condition * newMax / oldMax + 0.5))
    end
    new:setCondition(condition)
    new:setHaveBeenRepaired(old:getHaveBeenRepaired())
    new:setFavorite(old:isFavorite())
    new:setBloodLevel(old:getBloodLevel())
    if old:isCustomName() then
        new:setName(old:getName())
        new:setCustomName(true)
    end
end

--- Running item: MinDamage/MaxDamage scaled by the DamageMod option. Both are
--- saved and sent with the item (HandWeapon.save), so client and server agree.
local function applyDamageMod(item)
    local ratio = CSB42.option("DamageMod") / 100
    if ratio ~= 1 then
        local script = item:getScriptItem()
        item:setMinDamage(script:getMinDamage() * ratio)
        item:setMaxDamage(script:getMaxDamage() * ratio)
    end
end

local function replaceInContainer(container, old, new)
    container:Remove(old)
    sendRemoveItemFromContainer(container, old)
    container:AddItem(new)
    sendAddItemToContainer(container, new)
    -- Singleplayer: casts container:getParent() to IsoPlayer before testing it
    -- (LuaManager.java:9753): ClassCastException for a crate or a corpse.
    if instanceof(container:getParent(), "IsoPlayer") then
        replaceItemInContainer(container, old, new)
    end
end

local function replaceOnGround(worldItem, old, new)
    local square = worldItem:getSquare()
    if not square then
        return false
    end
    local x = worldItem:getWorldPosX() - square:getX()
    local y = worldItem:getWorldPosY() - square:getY()
    local z = worldItem:getWorldPosZ() - square:getZ()
    -- Vanilla pattern: ISTransferAction.lua:156-159 (42.21)
    square:transmitRemoveItemFromSquare(worldItem)
    square:removeWorldObject(worldItem)
    old:setWorldItem(nil)
    square:AddWorldInventoryItem(new, x, y, z)
    return true
end

--- Replaces `item` by a new item of `fullType`. `character` holds it or owns
--- it (may be nil for a chainsaw lying elsewhere). Returns the new item.
function CSB42.replace(item, fullType, character)
    if item:getFullType() == fullType then
        return item
    end
    local new = instanceItem(fullType)
    if not new then
        return nil
    end
    copyState(item, new)
    local family = CSB42.getFamily(new)
    if family and fullType == family.running then
        -- Compatibility families can keep native persistent damage values.
        if not family.keepDamage then applyDamageMod(new) end
        if family.prepareRunning then family.prepareRunning(new) end
    end

    local held = character and character:getPrimaryHandItem() == item
    local bothHands = held and character:getSecondaryHandItem() == item
    local worldItem = item:getWorldItem()
    local container = item:getContainer()
    if held then
        character:removeFromHands(item)
    end
    if worldItem then
        if not replaceOnGround(worldItem, item, new) then
            return nil
        end
    elseif container then
        replaceInContainer(container, item, new)
    else
        return nil
    end
    if held then
        character:setPrimaryHandItem(new)
        if bothHands then
            character:setSecondaryHandItem(new)
        end
        sendEquip(character)
    end
    return new
end

-- ----------------------------------------------------------------------------
-- Messages (halo text above the player). In multiplayer the server sends them
-- to the owner, who translates them in their own language.
-- ----------------------------------------------------------------------------

function CSB42.notify(character, key)
    if isServer() then
        sendServerCommand(character, CSB42.MODULE, "notify", { key = key })
    elseif CSB42.showNotice then
        CSB42.showNotice(character, key)
    end
end

return CSB42
