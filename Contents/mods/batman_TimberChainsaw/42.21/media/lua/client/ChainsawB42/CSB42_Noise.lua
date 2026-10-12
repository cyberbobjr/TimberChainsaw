-- ============================================================================
-- Timber! Chainsaw — working noise (client of the player holding the chainsaw)
--
-- The authority (CSB42_Engine.lua) emits the idle noise (NoiseIdle) every 2 s
-- while the engine runs. Attacking or cutting a tree is louder: the NoiseWorking
-- radius, emitted here every 2 s for the LOCAL players only, so each player's
-- noise is emitted once. Only the local player's machine knows its attack
-- (isAttacking is set for local players only, CombatManager.pressedAttack,
-- 42.21). On a multiplayer client, addSound sends the noise to the server
-- (LuaManager addSound -> WorldSoundManager.addSound with doSend), like the
-- vanilla ISBarricadeAction:start.
-- ============================================================================

if isServer() then
    return
end

require "ChainsawB42/CSB42_Core"

local NOISE_SECONDS = 2
--- Attacks follow each other every 0.67 s (ChainsawDefault.xml): the working
--- state is kept this long after the last attacking tick.
local HOLD_SECONDS = 1
local CUT_ACTION_ANIM = "CSB42CutTree"

--- [IsoPlayer] = { timer = seconds since the last noise, hold = seconds left }
local working = {}

local function isWorking(player)
    return player:isAttacking() or player:getVariableString("PerformingAction") == CUT_ACTION_ANIM
end

local function onTick()
    local seconds = getGameTime():getMultiplier() / 48
    local seen = {}
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player and not player:isDead() and CSB42.getHeldRunning(player) then
            local state = working[player]
            if isWorking(player) then
                if not state then
                    -- First noise as soon as the work starts.
                    state = { timer = NOISE_SECONDS }
                    working[player] = state
                end
                state.hold = HOLD_SECONDS
            elseif state then
                state.hold = state.hold - seconds
                if state.hold <= 0 then
                    state = nil
                    working[player] = nil
                end
            end
            if state then
                seen[player] = true
                state.timer = state.timer + seconds
                local radius = CSB42.option("NoiseWorking")
                if state.timer >= NOISE_SECONDS and radius > 0 then
                    state.timer = 0
                    addSound(player, player:getX(), player:getY(), player:getZ(), radius, radius)
                end
            end
        end
    end
    -- A Kahlua table must not change during pairs(): collect first.
    local gone = {}
    for player in pairs(working) do
        if not seen[player] then
            gone[#gone + 1] = player
        end
    end
    for i = 1, #gone do
        working[gone[i]] = nil
    end
end

Events.OnTick.Add(onTick)
