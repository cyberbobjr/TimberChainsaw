-- ============================================================================
-- Timber! Chainsaw — engine sound and messages (client)
--
-- Each client plays, by itself, the engine loop of every nearby player holding
-- a running chainsaw (the held item is synchronised by the game). No network
-- message: the loop starts and stops with the item, even after a
-- disconnection, a death or a reload, which the original mod did not handle.
-- One loop per player, chosen from its state:
--   idle                         ChainsawB42_Idle
--   attacking (button held)      ChainsawB42_Rev, or ChainsawB42_WoodCut when a
--                                tree stands on the square ahead (the melee hit
--                                also cuts it: CombatManager.CheckObjectHit)
--   cutting a tree (our action)  nothing here: the action plays the wood loop
-- Attacks follow each other (0.67 s cycle, ChainsawDefault.xml): the attack
-- state is kept ATTACK_HOLD_TICKS after the last attacking tick so the loop
-- does not stop between two cycles.
-- Multiplayer: another player's attack reaches this client as a hit packet
-- (PlayerHitSquare for a miss, relayed by GameServer.sendHitCharacter), replayed
-- with pressedAttack(). For a remote player it only sets attackStarted: the
-- attack type (isAttacking) is set for local players only
-- (CombatManager.pressedAttack, 42.21). Both flags are read here.
--
-- Volume: audio-file sounds do not follow the "Sound effects" slider (it drives
-- the FMOD VCA Settings_Sfx, bank events only: SoundManager.setSoundVolume,
-- FMODSoundEmitter file sounds in channel group InGameNonBank, 42.21). The
-- loops and the sounds started by this mod's actions get that volume here.
-- ============================================================================

require "ChainsawB42/CSB42_Core"

local SOUND_IDLE = "ChainsawB42_Idle"
local SOUND_REV = "ChainsawB42_Rev"
local SOUND_WOOD = "ChainsawB42_WoodCut"
local CUT_ACTION_ANIM = "CSB42CutTree"
local HEAR_DISTANCE = 40
local CHECK_TICKS = 15
local ATTACK_HOLD_TICKS = 45
--- sin(22.5 degrees): forward vector to one of the 8 neighbouring squares
local DIAGONAL = 0.38

--- [IsoPlayer] = { emitter = , id = , sound = , attackTicks = }
local loops = {}
local tickCount = 0

function CSB42.effectsVolume()
    return getCore():getOptionSoundVolume() / 10
end

function CSB42.adjustVolume(character, soundId)
    if soundId and soundId ~= 0 then
        character:getEmitter():setVolume(soundId, CSB42.effectsVolume())
    end
end

local function candidates()
    local list = {}
    local seen = {}
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player and not seen[player] then
            seen[player] = true
            list[#list + 1] = player
        end
    end
    if isClient() then
        local online = getOnlinePlayers()
        for i = 0, online:size() - 1 do
            local player = online:get(i)
            if player and not seen[player] then
                seen[player] = true
                list[#list + 1] = player
            end
        end
    end
    return list
end

local function nearListener(player)
    local listener = getSpecificPlayer(0)
    if not listener or listener == player then
        return true
    end
    local dx, dy = listener:getX() - player:getX(), listener:getY() - player:getY()
    return dx * dx + dy * dy <= HEAR_DISTANCE * HEAR_DISTANCE
end

local function step(value)
    if value > DIAGONAL then
        return 1
    elseif value < -DIAGONAL then
        return -1
    end
    return 0
end

--- Tree on the square the player faces (the square a melee hit checks).
function CSB42.treeAhead(player)
    local square = player:getCurrentSquare()
    if not square then
        return false
    end
    local forward = player:getForwardDirection()
    local dx, dy = step(forward:getX()), step(forward:getY())
    if dx == 0 and dy == 0 then
        return false
    end
    local ahead = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
    return ahead ~= nil and ahead:getTree() ~= nil
end

local function wantedSound(player, loop)
    if player:getVariableString("PerformingAction") == CUT_ACTION_ANIM then
        return nil
    end
    if loop.attackTicks > 0 then
        if CSB42.treeAhead(player) then
            return SOUND_WOOD
        end
        return SOUND_REV
    end
    return SOUND_IDLE
end

local function stopLoop(loop)
    if loop.id and loop.id ~= 0 then
        loop.emitter:stopSoundLocal(loop.id)
    end
    loop.id, loop.sound = 0, nil
end

--- Plays the wanted loop, restarting it if FMOD ended it.
local function refresh(player, loop, volume)
    local wanted = wantedSound(player, loop)
    local playing = loop.id ~= 0 and loop.emitter:isPlaying(loop.id)
    if wanted == loop.sound and (playing or wanted == nil) then
        return
    end
    stopLoop(loop)
    if wanted then
        loop.id = loop.emitter:playSoundImpl(wanted, nil)
        loop.sound = wanted
        if loop.id ~= 0 then
            loop.emitter:setVolume(loop.id, volume)
        end
    end
end

--- Every tick: attack state of the players already heard (cheap).
local function followAttacks(volume)
    for player, loop in pairs(loops) do
        if player:isAttacking() or player:isAttackStarted() then
            loop.attackTicks = ATTACK_HOLD_TICKS
        elseif loop.attackTicks > 0 then
            loop.attackTicks = loop.attackTicks - 1
        end
        refresh(player, loop, volume)
    end
end

--- Every CHECK_TICKS: who holds a running chainsaw nearby, volume changes.
local function update(volume)
    local active = {}
    local players = candidates()
    for i = 1, #players do
        local player = players[i]
        if not player:isDead() and CSB42.getHeldRunning(player) and nearListener(player) then
            active[player] = true
            local loop = loops[player]
            if not loop then
                loop = { emitter = player:getEmitter(), id = 0, sound = nil, attackTicks = 0 }
                loops[player] = loop
            end
            refresh(player, loop, volume)
            if loop.id ~= 0 then
                loop.emitter:setVolume(loop.id, volume)
            end
        end
    end
    local ended = {}
    for player, loop in pairs(loops) do
        if not active[player] then
            ended[#ended + 1] = player
            stopLoop(loop)
        end
    end
    for i = 1, #ended do
        loops[ended[i]] = nil
    end
end

local function onTick()
    local volume = CSB42.effectsVolume()
    tickCount = tickCount + 1
    if tickCount >= CHECK_TICKS then
        tickCount = 0
        update(volume)
    else
        followAttacks(volume)
    end
end

-- ----------------------------------------------------------------------------
-- Messages above the player (jam, empty tank, broken, repairs)
-- ----------------------------------------------------------------------------

function CSB42.showNotice(character, key)
    if character and HaloTextHelper then
        HaloTextHelper.addBadText(character, getText(key))
    end
end

--- Local player named by the server (split screen); player 0 when the
--- server sent no ID (older version) or no local player has it.
local function noticeTarget(onlineId)
    if type(onlineId) == "number" then
        for i = 0, getNumActivePlayers() - 1 do
            local player = getSpecificPlayer(i)
            if player and player:getOnlineID() == onlineId then
                return player
            end
        end
    end
    return getSpecificPlayer(0)
end

local function onServerCommand(module, command, args)
    if module ~= CSB42.MODULE or command ~= "notify" or type(args) ~= "table" then
        return
    end
    if type(args.key) ~= "string" or string.sub(args.key, 1, 11) ~= "IGUI_CSB42_" then
        return
    end
    -- sendServerCommand(player, ...) only reaches that player's client.
    CSB42.showNotice(noticeTarget(args.playerOnlineId), args.key)
end

Events.OnTick.Add(onTick)
Events.OnServerCommand.Add(onServerCommand)
