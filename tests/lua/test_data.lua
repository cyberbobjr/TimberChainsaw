-- Repair recipe code and loot distribution.
local T = {}

function T.setup()
    API = loadSupport("game_api.lua")
    loadMod("shared/ChainsawB42/CSB42_Core.lua")
    loadMod("shared/ChainsawB42/CSB42_Recipes.lua")
    loadMod("client/ChainsawB42/CSB42_Sound.lua")
end

function T.both_script_variants_have_weight_seven_and_safe_condition()
    for _, fullType in ipairs({ CSB42.FULLTYPE_OFF, CSB42.FULLTYPE_RUNNING }) do
        local saw = API.item(fullType)
        assertEq(saw:getActualWeight(), 7, "weight read from the item script")
        assertEq(saw:getConditionMax(), 127, "maximum read from the item script")
        for condition = 0, saw:getConditionMax() do
            saw:setCondition(condition)
            assertEq(API.savedCondition(saw), condition, "every condition survives signed-byte save/load")
        end
    end
end

function T.old_maximum_caused_signed_byte_damage_to_become_broken()
    local old = API.item(CSB42.FULLTYPE_OFF, { condition = 200, conditionMax = 200 })
    assertEq(API.savedCondition(old), 200, "full condition is omitted from the save")
    old:setCondition(199)
    assertEq(API.savedCondition(old), 0, "199 becomes -57, then is clamped to zero on load")
end

function T.repair_test_per_input_item()
    assertTrue(CSB42_Recipes.canRepair(API.item("Base.Screws")), "other inputs accepted")
    assertTrue(CSB42_Recipes.canRepair(API.item(CSB42.FULLTYPE_OFF, { condition = 50 })), "damaged chainsaw")
    assertTrue(not CSB42_Recipes.canRepair(API.item(CSB42.FULLTYPE_OFF)), "not damaged")
    assertTrue(CSB42_Recipes.canRepair(API.item(CSB42.FULLTYPE_OFF,
        { condition = 50, modData = { RepairCount = 12 } })), "no repair limit")
end

function T.repair_keeps_fuel_and_counts()
    local old = API.item(CSB42.FULLTYPE_OFF, { condition = 10, modData = { CurrentFuel = 0.5, RepairCount = 1 } })
    local new = API.item(CSB42.FULLTYPE_OFF)
    local data = {
        getAllConsumedItems = function() return API.list({ API.item("Base.Screws"), old }) end,
        getAllCreatedItems = function() return API.list({ new }) end,
    }
    local p = API.player()
    CSB42_Recipes.onRepair(data, p)
    assertEq(CSB42.getFuel(new), 0.5, "fuel kept (the original gave a full tank)")
    assertEq(new:getCondition(), 127, "repaired to the byte-safe maximum")
    assertEq(API.last("halo").text, "IGUI_CSB42_Repaired", "message")
end

function T.repair_keeps_the_raw_custom_name()
    -- A chainsaw waiting for repair is worn: getName() = "Betty (Worn)".
    local old = API.item(CSB42.FULLTYPE_OFF, { condition = 10, customName = true, name = "Betty (Worn)" })
    local new = API.item(CSB42.FULLTYPE_OFF)
    local data = {
        getAllConsumedItems = function() return API.list({ old }) end,
        getAllCreatedItems = function() return API.list({ new }) end,
    }
    CSB42_Recipes.onRepair(data, API.player())
    assertEq(new:getDisplayName(), "Betty", "no frozen or accumulated prefix")
    assertTrue(new:isCustomName(), "custom name kept")
end

local function lists()
    ProceduralDistributions = { list = {} }
    for _, name in ipairs({ "LoggingFactoryTools", "GarageTools", "ToolStoreBooks" }) do
        ProceduralDistributions.list[name] = { items = { "Base.Axe", 4 } }
    end
    ItemPickerJava = { parses = 0 }
    function ItemPickerJava.Parse() ItemPickerJava.parses = ItemPickerJava.parses + 1 end
end

local function weight(listName, fullType)
    local items = ProceduralDistributions.list[listName].items
    for i = 1, #items - 1, 2 do
        if items[i] == fullType then
            return items[i + 1]
        end
    end
    return nil
end

function T.loot_weights_and_missing_lists()
    lists()
    loadMod("server/Items/CSB42_Distributions.lua")
    triggerEvent("OnPreDistributionMerge")
    assertEq(weight("LoggingFactoryTools", CSB42.FULLTYPE_OFF), 3, "chainsaw")
    assertEq(weight("LoggingFactoryTools", CSB42.MAGAZINE), 4, "magazine")
    assertEq(weight("ToolStoreBooks", CSB42.MAGAZINE), 6, "magazine in books")
    triggerEvent("OnInitGlobalModData")
    assertEq(ItemPickerJava.parses, 0, "same option: no reparse")
end

function T.loot_option_known_late_in_singleplayer()
    lists()
    loadMod("server/Items/CSB42_Distributions.lua")
    triggerEvent("OnPreDistributionMerge")
    SandboxVars.ChainsawB42.LootChance = 6
    triggerEvent("OnInitGlobalModData")
    assertEq(weight("LoggingFactoryTools", CSB42.FULLTYPE_OFF), 6, "doubled")
    assertEq(ItemPickerJava.parses, 1, "lists reparsed")
    SandboxVars.ChainsawB42.LootChance = 0
    triggerEvent("OnInitGlobalModData")
    assertEq(weight("GarageTools", CSB42.FULLTYPE_OFF), nil, "0 = no chainsaw")
    assertEq(weight("GarageTools", "Base.Axe"), 4, "other entries untouched")
end

return T
