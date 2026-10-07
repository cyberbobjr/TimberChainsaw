local T = {}
local KEY = "batman_TimberAuthenticZCompatibility"

function T.setup()
    API = loadSupport("game_api.lua")
    loadMod("shared/ChainsawB42/CSB42_Core.lua")
    local source = readCompatibilityFile("shared/TimberAuthenticZ/TAC_Compatibility.lua")
    assert(loadstring(source))()
    loadMod("shared/TimedActions/CSB42_StartAction.lua")
    loadMod("shared/TimedActions/CSB42_RefuelAction.lua")
    loadMod("shared/TimedActions/CSB42_CutTreeAction.lua")
    loadMod("server/ChainsawB42/CSB42_Engine.lua")
end

function T.current_and_lite_keep_their_identity_and_native_damage()
    SandboxVars.ChainsawB42.DamageMod = 200
    for _, module in ipairs({ "AuthenticZClothing", "AuthenticZLite" }) do
        local off = API.item(module .. ".ChainsawOff", {
            condition = 9, favorite = true, customName = true, name = "Ash",
            repaired = 2, modData = { CurrentFuel = 1.2, FuelCapacity = 4, otherMod = "kept" },
        })
        local p = API.holding(off)
        assertTrue(CSB42_StartAction:new(p, off):isValid())
        CSB42_StartAction:new(p, off):complete()
        local running = p:getPrimaryHandItem()
        assertEq(running:getFullType(), module .. ".Chainsaw")
        assertEq(running:getCondition(), 9)
        assertEq(running:getConditionMax(), 15)
        assertEq(running:getActualWeight(), 3)
        assertEq(running.minDamage, 0.6, "no persistent damage override")
        assertEq(running:getTreeDamage(), 67)
        assertEq(running.swingSound, "ChainsawB42_Attack")
        local stopped = CSB42.stopEngine(p, running)
        assertEq(stopped:getFullType(), module .. ".ChainsawOff")
        assertEq(stopped:getCondition(), 9)
        assertEq(stopped:getHaveBeenRepaired(), 2)
        assertEq(stopped:getName(), "Ash")
        assertTrue(stopped:isFavorite())
        assertEq(stopped:getModData().otherMod, "kept")
        assertEq(CSB42.getFuel(stopped), 1.2)
    end
end

function T.compatibility_fuel_does_not_overwrite_authenticz_data()
    local saw = API.item("AuthenticZClothing.ChainsawOff", {
        modData = { CurrentFuel = 1, FuelCapacity = 4 },
    })
    CSB42.setFuel(saw, 2)
    assertEq(saw:getModData().CurrentFuel, 1, "legacy data untouched")
    assertEq(saw:getModData()[KEY].CurrentFuel, 2)
    assertEq(CSB42.getFuel(saw), 2)
    local p = API.player()
    p.inventory:AddItem(saw)
    local can = p.inventory:AddItem(API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 5) }))
    local action = CSB42_RefuelAction:new(p, saw, can)
    assertTrue(action:isValid())
    action:complete()
    assertEq(CSB42.getFuel(saw), 4)
    assertEq(can:getFluidContainer():getAmount(), 3)
end

function T.wear_is_scaled_and_fractional_losses_survive_state_changes()
    local saw = API.item("AuthenticZLite.ChainsawOff")
    for i = 1, 8 do CSB42.applyWear(saw, 1) end
    assertEq(saw:getCondition(), 15, "sub-point tree wear accumulated")
    local p = API.holding(saw)
    local running = CSB42.replace(saw, CSB42.stateType(saw, true), p)
    CSB42.applyWear(running, 1)
    assertEq(running:getCondition(), 14)
    CSB42.applyWear(running, 20)
    assertTrue(running:getCondition() >= 11, "one kill does not break the saw")
end

function T.existing_running_item_is_stopped_in_its_own_module()
    local p = API.holding(API.item("AuthenticZClothing.Chainsaw", { condition = 0 }))
    API.setLocalPlayers({ p })
    triggerEvent("OnTick")
    assertEq(p:getPrimaryHandItem():getFullType(), "AuthenticZClothing.ChainsawOff")
    assertEq(p:getPrimaryHandItem():getCondition(), 0, "broken stays broken")
end

function T.removing_registration_leaves_only_existing_authenticz_types()
    local off = API.item("AuthenticZLite.ChainsawOff")
    local p = API.holding(off)
    CSB42_StartAction:new(p, off):complete()
    local running = p:getPrimaryHandItem()
    CSB42.setFuel(running, 0.75)
    CSB42.families["AuthenticZLite.ChainsawOff"] = nil
    CSB42.families["AuthenticZLite.Chainsaw"] = nil
    assertTrue(not CSB42.isChainsaw(running))
    assertEq(running:getFullType(), "AuthenticZLite.Chainsaw")
    -- Simulate loading with the native script after compatibility removal.
    local reloaded = API.item(running:getFullType(), {
        condition = running:getCondition(), modData = running:getModData(),
    })
    assertEq(reloaded.minDamage, 0.6)
    assertEq(reloaded:getConditionMax(), 15)
    assert(loadstring(readCompatibilityFile("shared/TimberAuthenticZ/TAC_Compatibility.lua")))()
    assertEq(CSB42.getFuel(reloaded), 0.75, "fuel recovered on reactivation")
end

function T.server_cuts_trees_consumes_and_synchronizes_compatibility_fuel()
    API.server = true
    local p = API.holding(API.item("AuthenticZLite.ChainsawOff"))
    API.setOnlinePlayers({ p })
    CSB42_StartAction:new(p, p:getPrimaryHandItem()):complete()
    local saw = p:getPrimaryHandItem()
    local tree = API.tree(40)
    local action = CSB42_CutTreeAction:new(p, tree)
    action:serverStart()
    action:animEvent("CSB42Cut")
    assertEq(tree:getHealth(), 20)
    action:animEvent("CSB42Cut")
    assertEq(tree.toppledBy, p)
    assertTrue(CSB42.getFuel(saw) < 4)
    for i = 1, 600 do triggerEvent("OnTick") end
    assertTrue(saw.syncs > 0, "server fuel sent to owner")
    assertTrue(API.last("addSound") ~= nil, "noise attracts zombies")
    p:removeFromHands(saw)
    triggerEvent("OnTick")
    assertEq(p.inventory.items[1]:getFullType(), "AuthenticZLite.ChainsawOff")
end

function T.client_never_changes_tree_health_or_fuel()
    API.client = true
    local saw = API.item("AuthenticZClothing.Chainsaw")
    local p = API.holding(saw)
    local tree = API.tree(40)
    local action = CSB42_CutTreeAction:new(p, tree)
    action:start()
    local fuel = CSB42.getFuel(saw)
    for i = 1, 120 do action:update() end
    assertEq(tree:getHealth(), 40)
    assertEq(CSB42.getFuel(saw), fuel)
end

function T.oncreate_is_available_without_changing_existing_implementations()
    local saw = API.item("AuthenticZClothing.Chainsaw")
    AZ_ChainsawUtil.OnCreate.TurnOffChainsaw(saw)
    assertEq(saw:getFullType(), "AuthenticZClothing.Chainsaw")
    local original = function() end
    AZ_ChainsawUtil.OnCreate.TurnOffChainsaw = original
    assert(loadstring(readCompatibilityFile("shared/TimberAuthenticZ/TAC_Compatibility.lua")))()
    assertEq(AZ_ChainsawUtil.OnCreate.TurnOffChainsaw, original)
    assertEq(listenerCount("OnTick"), 1, "no extra engine registration")
end

return T
