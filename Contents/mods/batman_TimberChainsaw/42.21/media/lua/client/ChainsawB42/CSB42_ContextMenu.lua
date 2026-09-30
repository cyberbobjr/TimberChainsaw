-- ============================================================================
-- Timber! Chainsaw — context menus (client)
--
-- Start, stop, refuel (inventory and world menus) and "cut down the tree" on a
-- tree while holding a running chainsaw. Zombies: the running chainsaw is a
-- real weapon with the vanilla chainsaw animations (aim with right click,
-- attack with left click), damage and wear handled by the game in singleplayer
-- and multiplayer. The original "hold right click" loop (client-side damage,
-- ignored by a multiplayer server) is gone.
-- ============================================================================

require "ChainsawB42/CSB42_Core"
require "TimedActions/CSB42_StartAction"
require "TimedActions/CSB42_StopAction"
require "TimedActions/CSB42_RefuelAction"
require "TimedActions/CSB42_CutTreeAction"

local function disable(option, key)
    option.notAvailable = true
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = getText(key)
    option.toolTip = tooltip
end

local function doStart(player, chainsaw)
    ISWorldObjectContextMenu.transferIfNeeded(player, chainsaw)
    if player:getPrimaryHandItem() ~= chainsaw or player:getSecondaryHandItem() ~= chainsaw then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(player, chainsaw, 50, true, true))
    end
    ISTimedActionQueue.add(CSB42_StartAction:new(player, chainsaw))
end

local function doStop(player, chainsaw)
    ISTimedActionQueue.add(CSB42_StopAction:new(player, chainsaw))
end

local function doRefuel(player, chainsaw, petrol)
    ISWorldObjectContextMenu.transferIfNeeded(player, chainsaw)
    ISWorldObjectContextMenu.transferIfNeeded(player, petrol)
    ISTimedActionQueue.add(CSB42_RefuelAction:new(player, chainsaw, petrol))
end

local function doCutTree(player, tree)
    if not tree or tree:getObjectIndex() < 0 then
        return
    end
    if luautils.walkAdj(player, tree:getSquare(), true) then
        ISTimedActionQueue.add(CSB42_CutTreeAction:new(player, tree))
    end
end

--- Start/stop/refuel options for one chainsaw.
local function addChainsawOptions(player, context, chainsaw)
    if CSB42.isHeldRunning(player, chainsaw) then
        context:addOptionOnTop(getText("ContextMenu_CSB42_Stop"), player, doStop, chainsaw)
        return
    end
    if chainsaw:getFullType() ~= CSB42.FULLTYPE_OFF then
        return
    end

    local start = context:addOptionOnTop(getText("ContextMenu_CSB42_Start"), player, doStart, chainsaw)
    if chainsaw:isBroken() then
        disable(start, "Tooltip_CSB42_Broken")
    elseif not CSB42.hasFuel(chainsaw) then
        disable(start, "Tooltip_CSB42_NoFuel")
    elseif player:getVehicle() then
        disable(start, "Tooltip_CSB42_InVehicle")
    end

    if CSB42.freeCapacity(chainsaw) > 0 then
        local petrol = CSB42.findPetrolCan(player:getInventory())
        local refuel = context:addOptionOnTop(getText("ContextMenu_CSB42_Refuel"), player, doRefuel, chainsaw, petrol)
        if not petrol then
            disable(refuel, "Tooltip_CSB42_NoPetrol")
        end
    end
end

local function findTree(worldobjects)
    for i = 1, #worldobjects do
        local object = worldobjects[i]
        if instanceof(object, "IsoTree") then
            return object
        end
        local square = object and object:getSquare()
        if square and square:getTree() then
            return square:getTree()
        end
    end
    return nil
end

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player or player:getVehicle() then
        return
    end
    local held = player:getPrimaryHandItem()
    if not CSB42.isChainsaw(held) then
        return
    end
    if test then
        return ISWorldObjectContextMenu.setTest()
    end

    local running = CSB42.getHeldRunning(player)
    if running then
        local tree = findTree(worldobjects)
        if tree then
            local cut = context:addOptionOnTop(getText("ContextMenu_CSB42_CutTree"), player, doCutTree, tree)
            if not CSB42.hasFuel(running) then
                disable(cut, "Tooltip_CSB42_NoFuel")
            end
        end
    end
    addChainsawOptions(player, context, held)
end

local function onFillInventoryObjectContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then
        return
    end
    for _, entry in ipairs(items) do
        local item = entry
        if not instanceof(entry, "InventoryItem") and entry.items then
            item = entry.items[1]
        end
        if CSB42.isChainsaw(item) then
            addChainsawOptions(player, context, item)
            return
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
