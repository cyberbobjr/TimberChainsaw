-- Timed actions: start (jam), refuel, cut down a tree.
local T = {}

function T.setup()
    API = loadSupport("game_api.lua")
    loadMod("shared/ChainsawB42/CSB42_Core.lua")
    loadMod("shared/TimedActions/CSB42_StartAction.lua")
    loadMod("shared/TimedActions/CSB42_StopAction.lua")
    loadMod("shared/TimedActions/CSB42_RefuelAction.lua")
    loadMod("shared/TimedActions/CSB42_CutTreeAction.lua")
    loadMod("server/ChainsawB42/CSB42_Engine.lua")
    loadMod("client/ChainsawB42/CSB42_Sound.lua")
end

-- Refuel -------------------------------------------------------------------------

function T.original_bug_adjustAmount_minus_x_empties_the_can()
    -- What Chainsaw B42 did: petrolFC:adjustAmount(-transferAmount).
    local can = API.fluid(Fluid.Petrol, 10)
    can:adjustAmount(-3)
    assertEq(can:getAmount(), 0, "adjustAmount sets the amount: the whole can was lost")
end

function T.refuel_moves_only_the_missing_litres()
    local saw = API.item(CSB42.FULLTYPE_OFF, { modData = { CurrentFuel = 1.0 } })
    local can = API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 10) })
    local p = API.player()
    p.inventory:AddItem(saw)
    p.inventory:AddItem(can)
    local action = CSB42_RefuelAction:new(p, saw, can)
    assertTrue(action:isValid(), "valid")
    action:complete()
    assertEq(can:getFluidContainer():getAmount(), 7, "3 litres taken")
    assertEq(CSB42.getFuel(saw), 4.0, "tank full")
    assertTrue(saw.syncs == 1 and can.syncs == 1, "both items synchronised")
end

function T.refuel_refuses_water_and_a_running_chainsaw()
    local p = API.player()
    local saw = p.inventory:AddItem(API.item(CSB42.FULLTYPE_OFF, { modData = { CurrentFuel = 1.0 } }))
    local water = p.inventory:AddItem(API.item("Base.WaterBottle", { fluid = API.fluid(Fluid.Water, 1) }))
    assertTrue(not CSB42_RefuelAction:new(p, saw, water):isValid(), "water")
    local running = p.inventory:AddItem(API.item(CSB42.FULLTYPE_RUNNING, { modData = { CurrentFuel = 1.0 } }))
    local can = p.inventory:AddItem(API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 10) }))
    local action = CSB42_RefuelAction:new(p, running, can)
    assertTrue(not action:isValid(), "running chainsaw")
    action:complete()
    assertEq(can:getFluidContainer():getAmount(), 10, "complete() checks again (server)")
end

-- Start / stop ------------------------------------------------------------------------

function T.start_then_engine_registered()
    local off = API.item(CSB42.FULLTYPE_OFF)
    local p = API.holding(off)
    API.setLocalPlayers({ p })
    local action = CSB42_StartAction:new(p, off)
    assertTrue(action:isValid(), "valid")
    action:complete()
    local running = p:getPrimaryHandItem()
    assertEq(running:getFullType(), CSB42.FULLTYPE_RUNNING, "running")
    triggerEvent("OnTick")
    assertEq(p:getPrimaryHandItem(), running, "registered: not stopped by the tick")
end

function T.start_refused_without_fuel_or_both_hands()
    local empty = API.item(CSB42.FULLTYPE_OFF, { modData = { CurrentFuel = 0 } })
    local p = API.holding(empty)
    assertTrue(not CSB42_StartAction:new(p, empty):isValid(), "no fuel")
    local saw = API.item(CSB42.FULLTYPE_OFF)
    local q = API.player()
    q.inventory:AddItem(saw)
    q.primary = saw
    local action = CSB42_StartAction:new(q, saw)
    assertTrue(not action:isValid(), "one hand")
    action:complete()
    assertEq(q:getPrimaryHandItem(), saw, "complete() checks again")
end

function T.worn_chainsaw_may_jam()
    SandboxVars.ChainsawB42.JamFrequency = 25
    API.rand = function() return 10 end -- 10 < 25
    local worn = API.item(CSB42.FULLTYPE_OFF, { condition = 90 })
    local p = API.holding(worn)
    CSB42_StartAction:new(p, worn):complete()
    assertEq(p:getPrimaryHandItem(), worn, "did not start")
    assertEq(API.last("halo").text, "IGUI_CSB42_Jammed", "message")
    local good = API.item(CSB42.FULLTYPE_OFF, { condition = 150 })
    local q = API.holding(good)
    CSB42_StartAction:new(q, good):complete()
    assertEq(q:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_RUNNING, "above half condition: never jams")
end

function T.stop_action()
    local off = API.item(CSB42.FULLTYPE_OFF)
    local p = API.holding(off)
    API.setLocalPlayers({ p })
    CSB42_StartAction:new(p, off):complete()
    local running = p:getPrimaryHandItem()
    local action = CSB42_StopAction:new(p, running)
    assertTrue(action:isValid(), "valid")
    action:complete()
    assertEq(p:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_OFF, "stopped")
end

-- Cut down a tree ------------------------------------------------------------------------

local function startedSaw(fields)
    local off = API.item(CSB42.FULLTYPE_OFF, fields)
    local p = API.holding(off)
    API.setLocalPlayers({ p })
    CSB42_StartAction:new(p, off):complete()
    return p, p:getPrimaryHandItem()
end

local function ticksToFell(action, limit)
    for tick = 1, limit do
        action:update()
        if action.forceCompleted then
            return tick
        end
    end
    return nil
end

function T.original_bug_IsoTree_Damage_removes_one_point()
    -- IsoTree.Damage(float amount): damage = (int)(damage - amount * 0.05)
    local health = 560
    health = math.floor(health - 10 * 0.05)
    assertEq(health, 559, "Damage(10) of the original mod removes 1 point per hit")
end

function T.biggest_tree_falls_in_about_eleven_seconds()
    local p = startedSaw()
    local tree = API.tree(560)
    local action = CSB42_CutTreeAction:new(p, tree)
    assertTrue(action:isValid(), "valid")
    action:start()
    assertEq(action.anim, "CSB42CutTree", "vanilla Bob_ChainsawCutTree_Loop animation")
    local ticks = ticksToFell(action, 5000)
    assertTrue(ticks ~= nil, "the tree falls")
    local seconds = ticks / 60
    assertTrue(seconds > 10 and seconds < 12.5, "about 11 s at 60 FPS, got " .. seconds)
    assertEq(tree.toppledBy, p, "IsoTree:toppleTree(player): logs and removal by the game")
end

function T.cutting_speed_option()
    SandboxVars.ChainsawB42.TreeCuttingSpeed = 200
    local p = startedSaw()
    local action = CSB42_CutTreeAction:new(p, API.tree(560))
    action:start()
    local seconds = ticksToFell(action, 5000) / 60
    assertTrue(seconds > 5 and seconds < 6.5, "twice as fast, got " .. seconds)
end

function T.cutting_burns_fuel()
    local p, saw = startedSaw()
    local action = CSB42_CutTreeAction:new(p, API.tree(560))
    action:start()
    ticksToFell(action, 5000)
    local used = 4.0 - CSB42.getFuel(saw)
    assertTrue(used > 0.4 and used < 0.5, "about 0.45 L for the biggest tree, got " .. used)
end

function T.multiplayer_hits_come_from_the_server()
    API.server = true
    local p, saw = startedSaw()
    local tree = API.tree(40)
    local action = CSB42_CutTreeAction:new(p, tree)
    action:serverStart()
    local emulated = API.last("emulate")
    assertTrue(emulated and emulated.event == "CSB42Cut" and emulated.ms == 400, "emulated hit every 400 ms")
    action:animEvent("CSB42Cut")
    action:animEvent("CSB42Cut")
    assertEq(tree:getObjectIndex(), -1, "two hits of 20 fell a 40-point tree")
    assertTrue(action.netAction.completed, "server action completed")
    assertTrue(saw ~= nil, "unused")
end

function T.server_refuses_a_distant_tree()
    API.server = true
    local p = startedSaw()
    p.x = 30
    local tree = API.tree(40)
    local action = CSB42_CutTreeAction:new(p, tree)
    action:animEvent("CSB42Cut")
    assertEq(tree:getHealth(), 40, "20 tiles away: no damage")
    assertTrue(action.netAction.completed, "action ended")
end

function T.client_progress_bar_is_estimated()
    local p, saw = startedSaw()
    API.client = true
    local tree = API.tree(560)
    local action = CSB42_CutTreeAction:new(p, tree)
    action:start()
    for _ = 1, 336 do action:update() end -- 5.6 s: 14 hits of 20 = 280 points
    assertTrue(math.abs(saw.jobDelta - 0.5) < 0.05, "about half, got " .. tostring(saw.jobDelta))
end

function T.client_does_not_hit_in_multiplayer()
    local p = startedSaw()
    API.client = true
    local tree = API.tree(40)
    local action = CSB42_CutTreeAction:new(p, tree)
    action:start()
    for _ = 1, 600 do action:update() end
    action:animEvent("CSB42Cut")
    assertEq(tree:getHealth(), 40, "only the server damages the tree")
end

function T.empty_tank_stops_cutting_and_engine()
    local p, saw = startedSaw({ modData = { CurrentFuel = 0.01 } })
    local action = CSB42_CutTreeAction:new(p, API.tree(560))
    action:start()
    ticksToFell(action, 5000)
    assertTrue(action.forceCompleted, "action ended")
    assertEq(p:getPrimaryHandItem():getFullType(), CSB42.FULLTYPE_OFF, "engine stopped")
    assertEq(API.last("halo").text, "IGUI_CSB42_OutOfFuel", "message")
    assertTrue(saw ~= nil, "unused")
end

return T
