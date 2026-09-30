-- ============================================================================
-- Timber! Chainsaw — loot
--
-- The original mod inserted into 21 procedural lists; 10 of them do not exist
-- in 42.21 (ForestryTools, FarmingTools, ToolStoreShelves, PickUpTruckBed,
-- PickUpTruckTrunk, ToolStoreMagazines, BookstoreMagazines, GarageMagazines,
-- ShedShelf, WarehouseShelves) and it never read the LootChance option.
--
-- A weight of 3 is about 3 % per roll (ItemPickerJava, 42.21). Chainsaw
-- weights are multiplied by LootChance / 3 (default 3 = weights below).
-- In singleplayer the sandbox options of the save are only loaded after the
-- distribution merge (IsoWorld.init, 42.21): OnInitGlobalModData fixes the
-- weights and reparses the lists (ItemPickerJava.Parse is idempotent).
-- Modules other than Base need the full type in a list.
-- ============================================================================

require "Items/ProceduralDistributions"
require "ChainsawB42/CSB42_Core"

local CHAINSAW_SPAWNS = {
    { list = "LoggingFactoryTools", weight = 3 },
    { list = "RangerTools", weight = 2 },
    { list = "ForestFireTools", weight = 2 },
    { list = "FireStorageTools", weight = 2 },
    { list = "BarnTools", weight = 2 },
    { list = "GarageTools", weight = 2 },
    { list = "FarmerTools", weight = 1.5 },
    { list = "MechanicTools", weight = 1.5 },
    { list = "ToolStoreTools", weight = 1 },
    { list = "GardenStoreTools", weight = 1 },
    { list = "CrateTools", weight = 1 },
}

local MAGAZINE_SPAWNS = {
    { list = "LoggingFactoryTools", weight = 4 },
    { list = "RangerMagazines", weight = 4 },
    { list = "CarSupplyMagazines", weight = 6 },
    { list = "ToolStoreBooks", weight = 6 },
    { list = "MechanicShelfBooks", weight = 6 },
    { list = "BookstoreMisc", weight = 4 },
    { list = "MagazineRackMixed", weight = 4 },
    { list = "LibraryMagazines", weight = 3 },
    { list = "LibraryBooks", weight = 3 },
}

local DEFAULT_LOOT_CHANCE = 3
local appliedRatio = nil

local function chainsawRatio()
    return CSB42.option("LootChance") / DEFAULT_LOOT_CHANCE
end

--- Sets (or updates) the weight of `fullType` in a list; weight 0 removes it.
local function setWeight(items, fullType, weight)
    for i = 1, #items - 1, 2 do
        if items[i] == fullType then
            if weight > 0 then
                items[i + 1] = weight
            else
                table.remove(items, i + 1)
                table.remove(items, i)
            end
            return
        end
    end
    if weight > 0 then
        table.insert(items, fullType)
        table.insert(items, weight)
    end
end

local function apply(ratio)
    local lists = ProceduralDistributions and ProceduralDistributions.list
    if not lists then
        return
    end
    for _, spawn in ipairs(CHAINSAW_SPAWNS) do
        local list = lists[spawn.list]
        if list and list.items then
            setWeight(list.items, CSB42.FULLTYPE_OFF, spawn.weight * ratio)
        end
    end
    for _, spawn in ipairs(MAGAZINE_SPAWNS) do
        local list = lists[spawn.list]
        if list and list.items then
            setWeight(list.items, CSB42.MAGAZINE, spawn.weight)
        end
    end
    appliedRatio = ratio
end

local function onPreDistributionMerge()
    apply(chainsawRatio())
end

local function onInitGlobalModData()
    local ratio = chainsawRatio()
    if appliedRatio ~= ratio then
        apply(ratio)
        ItemPickerJava.Parse()
    end
end

Events.OnPreDistributionMerge.Add(onPreDistributionMerge)
Events.OnInitGlobalModData.Add(onInitGlobalModData)
