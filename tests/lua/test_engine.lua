-- Authority tick: fuel, noise, automatic stops, combat wear, multiplayer sync.
local T = {}

function T.setup()
    API = loadSupport("game_api.lua")
    loadMod("shared/ChainsawB42/CSB42_Core.lua")
    loadMod("shared/TimedActions/CSB42_StartAction.lua")
    loadMod("server/ChainsawB42/CSB42_Engine.lua")
    loadMod("client/ChainsawB42/CSB42_Sound.lua")
end

local function started(fields, online)
    local off = API.item(CSB42.FULLTYPE_OFF, fields)
    local p = API.holding(off)
    if online then
        API.setOnlinePlayers({ p })
    else
        API.setLocalPlayers({ p })
    end
    CSB42_StartAction:new(p, off):complete()
    return p, p:getPrimaryHandItem()
end

local function ticks(n)
    for _ = 1, n do
        triggerEvent("OnTick")
    end
end

function T.idle_consumption_follows_the_option()
    local _, saw = started()
    ticks(600) -- 10 s at x1, 60 FPS
    assertTrue(math.abs((4.0 - CSB42.getFuel(saw)) - 0.04) < 1e-6, "0.004 L/s at 100 %")
    SandboxVars.ChainsawB42.FuelConsumption = 0
    local before = CSB42.getFuel(saw)
    ticks(600)
    assertEq(CSB42.getFuel(saw), before, "0 % = no consumption (ignored by the original mod)")
    SandboxVars.ChainsawB42.FuelConsumption = 200
    ticks(600)
    assertTrue(math.abs((before - CSB42.getFuel(saw)) - 0.08) < 1e-6, "200 % = twice as fast")
end

function T.empty_tank_stops_the_engine()
    local p = started({ modData = { CurrentFuel = 0.001 } })
    ticks(60)
    assertEq(p:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_OFF, "stopped")
    assertEq(API.last("halo").text, "IGUI_CSB42_OutOfFuel", "message")
end

function T.noise_every_two_seconds_with_the_option_radius()
    SandboxVars.ChainsawB42.NoiseMod = 35
    started()
    ticks(1)
    assertEq(API.count("addSound"), 1, "noise as soon as the engine runs")
    ticks(118)
    assertEq(API.count("addSound"), 1, "less than 2 s later: no new noise")
    ticks(3)
    assertEq(API.count("addSound"), 2, "every 2 s")
    assertEq(API.last("addSound").radius, 35, "NoiseMod = radius (ignored by the original mod)")
    SandboxVars.ChainsawB42.NoiseMod = 0
    ticks(240)
    assertEq(API.count("addSound"), 2, "0 = silent")
end

function T.chainsaw_put_in_a_bag_is_stopped_there()
    local p, saw = started()
    p.primary, p.secondary = nil, nil
    ticks(1)
    local item = p.inventory.items[1]
    assertEq(item:getFullType(), CSB42.FULLTYPE_OFF, "stopped in the inventory")
    assertTrue(not p.inventory:contains(saw), "running item replaced")
end

function T.running_chainsaw_from_a_save_is_stopped()
    local running = API.item(CSB42.FULLTYPE_RUNNING)
    local p = API.holding(running)
    API.setLocalPlayers({ p })
    ticks(1)
    assertEq(p:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_OFF, "engines do not survive a reload")
    assertEq(p:getSecondaryHandItem(), p:getPrimaryHandItem(), "still in both hands")
end

function T.vehicle_and_death_stop_the_engine()
    local p = started()
    p.vehicle = {}
    ticks(1)
    assertEq(p:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_OFF, "vehicle")
    local q, saw = started()
    q.dead = true
    ticks(1)
    assertEq(q.inventory.items[1]:getFullType(), CSB42.FULLTYPE_OFF, "death")
    assertTrue(saw ~= nil, "unused")
end

function T.server_syncs_fuel_every_five_centilitres()
    API.server = true
    local _, saw = started(nil, true)
    ticks(600) -- 0.04 L
    assertEq(saw.syncs, 0, "below 0.05 L: no packet")
    ticks(160) -- a little over 0.05 L
    assertEq(saw.syncs, 1, "one syncItemFields")
end

function T.disconnected_owner_is_forgotten_without_touching_the_item()
    API.server = true
    local p, saw = started(nil, true)
    API.setOnlinePlayers({})
    ticks(1)
    assertEq(p:getPrimaryHandItem(), saw, "untouched: stopped at reconnection")
    API.setOnlinePlayers({ p })
    ticks(1)
    assertEq(p:getPrimaryHandItem(), saw, "client still loading: not replaced yet")
    API.now = 4000
    ticks(1)
    assertEq(p:getPrimaryHandItem(), saw, "4 s: still waiting")
    API.now = 5000
    ticks(1)
    assertEq(p:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_OFF, "stopped 5 s after the owner is back")
end

function T.chainsaw_put_in_a_crate_is_stopped_without_error()
    local p, saw = started()
    local crate = API.container({ __classes = { IsoObject = true } })
    p.inventory:Remove(saw)
    crate:AddItem(saw)
    p.primary, p.secondary = nil, nil
    ticks(1)
    assertEq(crate.items[1]:getFullType(), CSB42.FULLTYPE_OFF, "stopped in the crate, no ClassCastException")
end

function T.held_attack_on_a_tree_burns_cutting_fuel()
    local p, saw = started()
    triggerEvent("OnWeaponHitTree", p, saw)
    assertTrue(math.abs((4.0 - CSB42.getFuel(saw)) - 67 * 0.0008) < 1e-9, "TreeDamage 67 x 0.0008 L")
    local off = API.item(CSB42.FULLTYPE_OFF)
    local q = API.holding(off)
    triggerEvent("OnWeaponHitTree", q, off)
    assertEq(CSB42.getFuel(off), 4.0, "stopped chainsaw: no fuel")
end

function T.held_attack_on_a_tree_can_empty_the_tank()
    local p, saw = started({ modData = { CurrentFuel = 0.01 } })
    triggerEvent("OnWeaponHitTree", p, saw)
    assertEq(p:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_OFF, "engine stopped")
    assertEq(API.last("halo").text, "IGUI_CSB42_OutOfFuel", "message")
end

function T.combat_wear_per_zombie_killed()
    SandboxVars.ChainsawB42.ConditionLossCombat = 20
    local p, saw = started()
    local zombie = { getAttackedBy = function() return p end }
    triggerEvent("OnZombieDead", zombie)
    assertEq(saw:getCondition(), 180, "20 per kill")
    saw:setCondition(15)
    triggerEvent("OnZombieDead", zombie)
    assertEq(p:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_OFF, "broken: engine stopped")
    assertEq(p:getPrimaryHandItem():getCondition(), 0, "broken item kept")
end

return T
