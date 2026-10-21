-- Attached chainsaw replaced by the engine (back, belt): the client drives the
-- attachment of its own players (vanilla ISAttachItemHotbar, ISUnequipAction),
-- so it attaches the replacement itself. In multiplayer the new item may
-- arrive a few ticks after the attachment: retry for a while, then give up.
require "ChainsawB42/CSB42_Core"

local RETRY_MS = 10000

--- [old item ID] = first time (ms) its replacement was searched in vain
local missingSince = {}
local now = 0

local function shouldSearch(oldId)
    local since = missingSince[oldId]
    return not since or now - since <= RETRY_MS
end

local function onTick()
    now = getTimestampMs()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player and not player:isDead() then
            local fixed, missing = CSB42.repairAttached(player, shouldSearch)
            for _, id in ipairs(missing) do
                missingSince[id] = missingSince[id] or now
            end
            if #fixed > 0 then
                local hotbar = getPlayerHotbar and getPlayerHotbar(player:getPlayerNum())
                if hotbar then
                    hotbar:reloadIcons()
                end
            end
        end
    end
end

Events.OnTick.Add(onTick)
