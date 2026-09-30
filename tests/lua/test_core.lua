-- Core: fuel, petrol cans, replacement of the item.
local T = {}

function T.setup()
    API = loadSupport("game_api.lua")
    loadMod("shared/ChainsawB42/CSB42_Core.lua")
end

function T.fuel_defaults_to_full_like_the_original()
    local saw = API.item(CSB42.FULLTYPE_OFF)
    assertEq(CSB42.getFuel(saw), 4.0, "never refuelled = full tank")
    CSB42.setFuel(saw, 9)
    assertEq(CSB42.getFuel(saw), 4.0, "clamped to the capacity")
    CSB42.setFuel(saw, -1)
    assertEq(CSB42.getFuel(saw), 0, "clamped to 0")
    assertTrue(not CSB42.hasFuel(saw), "empty")
end

function T.original_modData_is_kept()
    local saw = API.item(CSB42.FULLTYPE_OFF, { modData = { CurrentFuel = 1.25, FuelCapacity = 4.0, RepairCount = 2 } })
    assertEq(CSB42.getFuel(saw), 1.25, "fuel of a save made with the original mod")
end

function T.only_pure_petrol_is_accepted()
    local petrol = API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 5) })
    local water = API.item("Base.WaterBottle", { fluid = API.fluid(Fluid.Water, 1) })
    local mixed = API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 5, 10, true) })
    local drops = API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 0.005) })
    local saw = API.item(CSB42.FULLTYPE_OFF)
    assertTrue(CSB42.isPetrolCan(petrol), "petrol can")
    assertTrue(not CSB42.isPetrolCan(water), "water refused (the original took any fluid)")
    assertTrue(not CSB42.isPetrolCan(mixed), "mixture refused")
    assertTrue(not CSB42.isPetrolCan(drops), "a few drops refused")
    assertTrue(not CSB42.isPetrolCan(saw), "a chainsaw is not a can")
    assertTrue(not CSB42.isPetrolCan(API.fluid(Fluid.Petrol, 5)), "a bare FluidContainer is not an item")
end

function T.refuel_takes_only_what_the_tank_needs()
    local saw = API.item(CSB42.FULLTYPE_OFF, { modData = { CurrentFuel = 1.0 } })
    local can = API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 10) })
    assertEq(CSB42.refuelAmount(saw, can), 3.0, "4 - 1 litres")
    local small = API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 2) })
    assertEq(CSB42.refuelAmount(saw, small), 2, "limited by the can")
end

function T.best_petrol_can_is_the_fullest()
    local p = API.player()
    local a = p.inventory:AddItem(API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 2) }))
    local b = p.inventory:AddItem(API.item("Base.PetrolCan", { fluid = API.fluid(Fluid.Petrol, 7) }))
    p.inventory:AddItem(API.item("Base.WaterBottle", { fluid = API.fluid(Fluid.Water, 9) }))
    assertEq(CSB42.findPetrolCan(p.inventory), b, "fullest can")
    assertTrue(a ~= nil, "unused")
end

function T.start_replaces_the_held_item_and_keeps_its_state()
    SandboxVars.ChainsawB42.DamageMod = 150
    local off = API.item(CSB42.FULLTYPE_OFF, { condition = 120, favorite = true, customName = true, name = "Betty",
        modData = { CurrentFuel = 2.5, RepairCount = 1 } })
    local p = API.holding(off)
    local running = CSB42.replace(off, CSB42.FULLTYPE_RUNNING, p)
    assertEq(running:getFullType(), CSB42.FULLTYPE_RUNNING, "running type")
    assertEq(p:getPrimaryHandItem(), running, "primary hand")
    assertEq(p:getSecondaryHandItem(), running, "secondary hand")
    assertTrue(not p.inventory:contains(off) and p.inventory:contains(running), "inventory updated")
    assertEq(CSB42.getFuel(running), 2.5, "fuel copied")
    assertEq(running:getModData().RepairCount, 1, "ModData copied")
    assertEq(running:getCondition(), 120, "condition copied")
    assertTrue(running:isFavorite() and running:getName() == "Betty", "favorite and name copied")
    assertEq(API.count("sendEquip"), 1, "hands sent to clients")
    assertTrue(math.abs(running.minDamage - 0.9) < 1e-9 and math.abs(running.maxDamage - 1.65) < 1e-9, "DamageMod 150 %")
    assertTrue(CSB42.isHeldRunning(p, running), "held running")
end

function T.one_handed_holder_keeps_the_other_hand()
    local off = API.item(CSB42.FULLTYPE_OFF)
    local p = API.player()
    local torch = API.item("Base.HandTorch")
    p.inventory:AddItem(off)
    p.primary, p.secondary = off, torch
    local new = CSB42.replace(off, CSB42.FULLTYPE_RUNNING, p)
    assertEq(p:getPrimaryHandItem(), new, "primary replaced")
    assertEq(p:getSecondaryHandItem(), torch, "secondary hand untouched")
end

function T.stop_on_the_ground_replaces_the_world_item()
    local running = API.item(CSB42.FULLTYPE_RUNNING)
    local square = API.square(20, 30, 0)
    local world = API.worldItem(square, running, 0.2, 0.7, 0)
    local off = CSB42.replace(running, CSB42.FULLTYPE_OFF, nil)
    assertEq(off:getFullType(), CSB42.FULLTYPE_OFF, "stopped")
    assertTrue(world.removed, "old world item removed")
    assertEq(#square.ground, 1, "new item on the ground")
    assertTrue(math.abs(square.ground[1].dx - 0.2) < 1e-6 and math.abs(square.ground[1].dy - 0.7) < 1e-6, "same place")
end

function T.notify_goes_to_the_owner_in_multiplayer()
    API.server = true
    local p = API.player()
    CSB42.notify(p, "IGUI_CSB42_Jammed")
    local sent = API.last("serverCommand")
    assertTrue(sent and sent.player == p and sent.command == "notify" and sent.args.key == "IGUI_CSB42_Jammed", "server command")
end

return T
