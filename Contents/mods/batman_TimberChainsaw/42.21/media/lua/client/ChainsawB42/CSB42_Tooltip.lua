-- ============================================================================
-- Timber! Chainsaw — tooltip lines through TooltipLib (required mod)
--
-- The original mod replaced ISToolTipInv.render and called self.item:IsWeapon()
-- on every tooltip. The game also opens ISToolTipInv for a FluidContainer
-- (ISFluidBar.lua:220) and an entity resource (ISEnergyBar.lua:90), which have
-- no IsWeapon: "Tried to call nil" on each frame, and the Lua debugger stopped
-- on it in debug mode although it ran under pcall.
-- TooltipLib calls providers for inventory items only and lays the lines out
-- with the vanilla tooltip.
-- ============================================================================

require "ChainsawB42/CSB42_Core"
require "TooltipLib/Core"

if not TooltipLib or type(TooltipLib.registerProvider) ~= "function" then
    print("[CSB42] TooltipLib missing: no chainsaw lines in tooltips")
    return
end

local LABEL = { 0.9, 0.9, 0.9, 1 }
local RUNNING = { 0.3, 0.9, 0.3, 1 }
local STOPPED = { 0.65, 0.65, 0.65, 1 }
local FUEL_BAR = { 1, 0.55, 0.1, 1 }

TooltipLib.registerProvider({
    id = "batman_TimberChainsaw",
    target = "item",
    description = "IGUI_CSB42_TooltipProvider",
    enabled = function(item)
        return CSB42.isChainsaw(item)
    end,
    callback = function(ctx)
        local item = ctx.item
        local holder = item:getContainer() and item:getContainer():getParent()
        local running = instanceof(holder, "IsoGameCharacter") and CSB42.isHeldRunning(holder, item)
        if running then
            ctx:addKeyValue(getText("IGUI_CSB42_Engine"), getText("IGUI_CSB42_Running"), LABEL, RUNNING)
        else
            ctx:addKeyValue(getText("IGUI_CSB42_Engine"), getText("IGUI_CSB42_Stopped"), LABEL, STOPPED)
        end
        local fuel, capacity = CSB42.getFuel(item), CSB42.getCapacity(item)
        ctx:addProgress(getText("IGUI_CSB42_Fuel"), fuel / capacity, LABEL, FUEL_BAR)
        ctx:addKeyValue("", string.format("%.2f / %.1f L", fuel, capacity), LABEL, LABEL)
    end,
})
