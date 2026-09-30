-- ============================================================================
-- Timber! Chainsaw — repair recipe code
--
-- The original RepairChainsaw recipe named no OnTest/OnCreate, and its Lua
-- called CraftRecipeData:getAllOutputItems(), which does not exist in 42.21:
-- a repair gave a new chainsaw with a full tank.
-- OnTest (called for each input item, CraftRecipe.java:1027) refuses a chainsaw
-- that is not damaged; repairs are unlimited. OnCreate (craftRecipeData,
-- character), called after the output is added (ISHandcraftAction:performRecipe)
-- copies the fuel, the ModData and the name.
-- Shared: OnTest also runs on the client to show the recipe.
-- ============================================================================

require "ChainsawB42/CSB42_Core"

CSB42_Recipes = CSB42_Recipes or {}

function CSB42_Recipes.canRepair(item, character)
    if not CSB42.isChainsaw(item) then
        return true
    end
    return item:getCondition() < item:getConditionMax()
end

local function findChainsaw(items)
    if not items then
        return nil
    end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if CSB42.isChainsaw(item) then
            return item
        end
    end
    return nil
end

function CSB42_Recipes.onRepair(craftRecipeData, character)
    local old = findChainsaw(craftRecipeData:getAllConsumedItems())
    local new = findChainsaw(craftRecipeData:getAllCreatedItems())
    if not old or not new then
        return
    end
    local oldData, newData = old:getModData(), new:getModData()
    for key, value in pairs(oldData) do
        newData[key] = value
    end
    CSB42.setFuel(new, CSB42.getFuel(old))
    new:setCondition(new:getConditionMax())
    new:setFavorite(old:isFavorite())
    if old:isCustomName() then
        new:setName(old:getName())
        new:setCustomName(true)
    end
    if isServer() then
        new:syncItemFields()
    end
    if character then
        CSB42.notify(character, "IGUI_CSB42_Repaired")
    end
end
