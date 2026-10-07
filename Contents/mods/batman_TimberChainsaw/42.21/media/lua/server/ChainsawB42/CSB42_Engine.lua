-- ============================================================================
-- Timber! Chainsaw — running engines (authority: singleplayer or server)
--
-- Each tick, for every chainsaw started with CSB42_StartAction:
--   * fuel burns in game time (FuelConsumption sandbox option, which the
--     original mod never read), so fast-forward burns faster, like any engine;
--   * noise attracts zombies every 2 s (NoiseMod option = radius in tiles);
--   * the engine stops when the chainsaw leaves both hands, breaks, runs dry,
--     when its owner dies, disconnects or gets in a vehicle.
-- A running chainsaw held without having been started here (save reloaded,
-- reconnection, taken from a bag) is stopped: engines do not survive a reload.
-- On a server this waits RECONNECT_GRACE_MS: the item packets are not handled
-- while a client is still loading (AddInventoryItemToContainerPacket,
-- handlingType 2, PacketSetting.java:30-35). In multiplayer the fuel reaches the owner with syncItemFields every
-- 0.05 L (SyncItemFieldsPacket carries the ModData).
-- ============================================================================

if isClient() then
    return
end

require "ChainsawB42/CSB42_Core"

local NOISE_SECONDS = 2
local SYNC_STEP = 0.05
local RECONNECT_GRACE_MS = 5000

--- [item ID] = first time (ms) a server saw this unregistered running chainsaw held
local unregisteredSince = {}

--- [item ID] = { item = , player = , noiseTimer = , syncedFuel = }
local running = {}

function CSB42.onStarted(player, item)
    running[item:getID()] = {
        item = item,
        player = player,
        noiseTimer = NOISE_SECONDS,
        syncedFuel = CSB42.getFuel(item),
    }
end

--- Stops the engine: back to ChainsawOff wherever the chainsaw is now.
function CSB42.stopEngine(player, item, noticeKey)
    running[item:getID()] = nil
    if not CSB42.isRunningType(item) then
        return item
    end
    local holder = nil
    if player and player:getPrimaryHandItem() == item then
        holder = player
    end
    local stopped = CSB42.replace(item, CSB42.stateType(item, false), holder)
    if player and noticeKey then
        CSB42.notify(player, noticeKey)
    end
    return stopped
end

local function currentPlayers()
    local list = {}
    if isServer() then
        local online = getOnlinePlayers()
        for i = 0, online:size() - 1 do
            list[#list + 1] = online:get(i)
        end
    else
        for i = 0, getNumActivePlayers() - 1 do
            local player = getSpecificPlayer(i)
            if player then
                list[#list + 1] = player
            end
        end
    end
    return list
end

local function makeNoise(player)
    local radius = CSB42.option("NoiseMod")
    if radius > 0 then
        addSound(player, player:getX(), player:getY(), player:getZ(), radius, radius)
    end
end

local function stopReason(entry, present)
    local player, item = entry.player, entry.item
    if not present[player] then
        return "gone"
    end
    if player:isDead() then
        return "dead"
    end
    if not CSB42.isHeldRunning(player, item) then
        return "unequipped"
    end
    if player:getVehicle() then
        return "vehicle"
    end
    if item:isBroken() then
        return "IGUI_CSB42_Broken"
    end
    if not CSB42.hasFuel(item) then
        return "IGUI_CSB42_OutOfFuel"
    end
    return nil
end

local function onTick()
    local players = currentPlayers()
    local present = {}
    local seenUnregistered = {}
    for i = 1, #players do
        local player = players[i]
        present[player] = true
        -- Running chainsaw in hand that no start action registered.
        local held = player:getPrimaryHandItem()
        if CSB42.isRunningType(held) and not running[held:getID()] and not player:isDead() then
            local id = held:getID()
            if not isServer() then
                CSB42.stopEngine(player, held)
            else
                local now = getTimestampMs()
                unregisteredSince[id] = unregisteredSince[id] or now
                seenUnregistered[id] = true
                if now - unregisteredSince[id] >= RECONNECT_GRACE_MS then
                    unregisteredSince[id] = nil
                    CSB42.stopEngine(player, held)
                end
            end
        end
    end
    local forgotten = {}
    for id in pairs(unregisteredSince) do
        if not seenUnregistered[id] then
            forgotten[#forgotten + 1] = id
        end
    end
    for i = 1, #forgotten do
        unregisteredSince[forgotten[i]] = nil
    end

    -- A Kahlua table must not change during pairs(): collect first.
    local stops = {}
    local seconds = getGameTime():getMultiplier() / 48
    local fuelRatio = CSB42.option("FuelConsumption") / 100
    for _, entry in pairs(running) do
        local reason = stopReason(entry, present)
        if reason then
            stops[#stops + 1] = { entry = entry, reason = reason }
        else
            local item, player = entry.item, entry.player
            CSB42.setFuel(item, CSB42.getFuel(item) - CSB42.FUEL_IDLE_PER_SECOND * seconds * fuelRatio)
            if not CSB42.hasFuel(item) then
                stops[#stops + 1] = { entry = entry, reason = "IGUI_CSB42_OutOfFuel" }
            else
                entry.noiseTimer = entry.noiseTimer + seconds
                if entry.noiseTimer >= NOISE_SECONDS then
                    entry.noiseTimer = 0
                    makeNoise(player)
                end
                local fuel = CSB42.getFuel(item)
                if isServer() and math.abs(entry.syncedFuel - fuel) >= SYNC_STEP then
                    entry.syncedFuel = fuel
                    item:syncItemFields()
                end
            end
        end
    end

    for i = 1, #stops do
        local entry, reason = stops[i].entry, stops[i].reason
        if reason == "gone" then
            -- Disconnected: the save keeps a Chainsaw, stopped at reconnection.
            running[entry.item:getID()] = nil
        elseif reason == "dead" then
            CSB42.stopEngine(nil, entry.item)
        elseif string.sub(reason, 1, 5) == "IGUI_" then
            CSB42.stopEngine(entry.player, entry.item, reason)
        else
            CSB42.stopEngine(entry.player, entry.item)
        end
    end
end

--- Combat wear, as in the original mod: ConditionLossCombat per zombie killed.
local function onZombieDead(zombie)
    local attacker = zombie:getAttackedBy()
    if not instanceof(attacker, "IsoPlayer") then
        return
    end
    local item = CSB42.getHeldRunning(attacker)
    if not item then
        return
    end
    local wear = CSB42.option("ConditionLossCombat")
    if wear <= 0 then
        return
    end
    CSB42.applyWear(item, wear)
    if item:isBroken() then
        CSB42.stopEngine(attacker, item, "IGUI_CSB42_Broken")
    elseif isServer() then
        item:syncItemFields()
    end
end

--- Held attacks on a tree burn cutting fuel too. OnWeaponHitTree is fired on
--- the authority only, for each melee hit on a tree, before IsoTree.WeaponHit
--- (CombatManager.processMaintenanceCheck:488-495; on a server from
--- PlayerHitObjectPacket.process:70-75, once per hit).
local function onWeaponHitTree(owner, weapon)
    if not instanceof(owner, "IsoPlayer") or not CSB42.isHeldRunning(owner, weapon) then
        return
    end
    if not CSB42.burnCuttingFuel(weapon, weapon:getTreeDamage()) then
        CSB42.stopEngine(owner, weapon, "IGUI_CSB42_OutOfFuel")
    end
end

Events.OnTick.Add(onTick)
Events.OnZombieDead.Add(onZombieDead)
Events.OnWeaponHitTree.Add(onWeaponHitTree)
