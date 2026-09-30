-- Client: engine loops and volume, tooltip provider (TooltipLib), messages.
local T = {}

function T.setup()
    API = loadSupport("game_api.lua")
    TooltipLib = { providers = {} }
    function TooltipLib.registerProvider(provider)
        TooltipLib.providers[#TooltipLib.providers + 1] = provider
    end
    loadMod("shared/ChainsawB42/CSB42_Core.lua")
    loadMod("client/ChainsawB42/CSB42_Sound.lua")
    loadMod("client/ChainsawB42/CSB42_Tooltip.lua")
end

local function ticks(n)
    for _ = 1, n do
        triggerEvent("OnTick")
    end
end

function T.engine_loop_follows_the_held_item_at_effects_volume()
    API.soundVolume = 4
    local p = API.holding(API.item(CSB42.FULLTYPE_RUNNING))
    API.setLocalPlayers({ p })
    ticks(15)
    local id, name
    for soundId, soundName in pairs(p.emitter.playing) do
        id, name = soundId, soundName
    end
    assertEq(name, "ChainsawB42_Idle", "loop playing")
    assertEq(p.emitter.volumes[id], 0.4, "Sound effects volume 4/10")
    ticks(15)
    local count = 0
    for _ in pairs(p.emitter.playing) do count = count + 1 end
    assertEq(count, 1, "not started twice")
    p.primary, p.secondary = nil, nil
    ticks(15)
    assertEq(API.count("stopLocal"), 1, "stopped locally, no network stop")
end

local function playingSound(p)
    local name
    for _, soundName in pairs(p.emitter.playing) do name = soundName end
    return name
end

function T.held_attack_plays_full_throttle_then_idle()
    local p = API.holding(API.item(CSB42.FULLTYPE_RUNNING))
    API.setLocalPlayers({ p })
    ticks(15)
    assertEq(playingSound(p), "ChainsawB42_Idle", "idle")
    p.attacking = true
    ticks(1)
    assertEq(playingSound(p), "ChainsawB42_Rev", "attack button held: full throttle loop")
    p.attacking = false
    ticks(10)
    assertEq(playingSound(p), "ChainsawB42_Rev", "between two attack cycles: loop kept")
    ticks(40)
    assertEq(playingSound(p), "ChainsawB42_Idle", "released: back to idle (0.75 s hold)")
    local count = 0
    for _ in pairs(p.emitter.playing) do count = count + 1 end
    assertEq(count, 1, "one loop at a time")
end

function T.remote_player_attack_is_heard()
    API.client = true
    local me = API.player()
    local other = API.holding(API.item(CSB42.FULLTYPE_RUNNING), { x = 15 })
    API.setLocalPlayers({ me })
    API.setOnlinePlayers({ me, other })
    ticks(15)
    assertEq(playingSound(other), "ChainsawB42_Idle", "idle")
    -- replayed hit packet: pressedAttack sets attackStarted only (remote player)
    other.attackStarted = true
    ticks(1)
    assertEq(playingSound(other), "ChainsawB42_Rev", "full throttle for a remote attack")
    other.attackStarted = false
    ticks(40)
    assertEq(playingSound(other), "ChainsawB42_Rev", "kept between two replayed attacks")
    ticks(10)
    assertEq(playingSound(other), "ChainsawB42_Idle", "idle again")
end

function T.held_attack_on_a_tree_plays_wood_cutting()
    local p = API.holding(API.item(CSB42.FULLTYPE_RUNNING), { x = 10.5, y = 10.5, forward = { x = 0.7, y = 0.7 } })
    API.trees["11,11,0"] = true
    API.setLocalPlayers({ p })
    ticks(15)
    p.attacking = true
    ticks(1)
    assertEq(playingSound(p), "ChainsawB42_WoodCut", "tree on the square ahead (south-east)")
end

function T.cut_tree_action_has_its_own_loop()
    local p = API.holding(API.item(CSB42.FULLTYPE_RUNNING), { vars = { PerformingAction = "CSB42CutTree" } })
    API.setLocalPlayers({ p })
    ticks(15)
    assertEq(playingSound(p), nil, "no engine loop while the action plays the wood loop")
end

function T.remote_players_heard_within_forty_tiles()
    API.client = true
    local me = API.player()
    local near = API.holding(API.item(CSB42.FULLTYPE_RUNNING), { x = 30 })
    local far = API.holding(API.item(CSB42.FULLTYPE_RUNNING), { x = 60 })
    API.setLocalPlayers({ me })
    API.setOnlinePlayers({ me, near, far })
    ticks(15)
    local function playing(p)
        local found = false
        for _ in pairs(p.emitter.playing) do found = true end
        return found
    end
    assertTrue(playing(near), "20 tiles away: heard")
    assertTrue(not playing(far), "50 tiles away: not played")
end

function T.tooltip_ignores_fluid_containers()
    local provider = TooltipLib.providers[1]
    assertTrue(provider ~= nil and provider.target == "item", "provider registered")
    assertTrue(not provider.enabled(API.fluid(Fluid.Petrol, 1)), "FluidContainer (ISFluidBar tooltip): no line, no error")
    assertTrue(not provider.enabled(API.item("Base.Axe")), "other item")
    assertTrue(provider.enabled(API.item(CSB42.FULLTYPE_OFF)), "chainsaw")
end

function T.tooltip_lines()
    local provider = TooltipLib.providers[1]
    local lines = {}
    local ctx = {}
    function ctx:addKeyValue(key, value) lines[#lines + 1] = key .. "=" .. value end
    function ctx:addProgress(label, fraction) lines[#lines + 1] = label .. "~" .. string.format("%.2f", fraction) end
    local saw = API.item(CSB42.FULLTYPE_RUNNING, { modData = { CurrentFuel = 1, RepairCount = 1 } })
    API.holding(saw)
    ctx.item = saw
    provider.callback(ctx)
    assertEq(lines[1], "IGUI_CSB42_Engine=IGUI_CSB42_Running", "running while held")
    assertEq(lines[2], "IGUI_CSB42_Fuel~0.25", "fuel bar")
    assertEq(lines[3], "=1.00 / 4.0 L", "litres")
    assertEq(#lines, 3, "no repair line: repairs are unlimited")
end

function T.server_message_only_for_this_mod()
    local p = API.player()
    API.setLocalPlayers({ p })
    triggerEvent("OnServerCommand", "ChainsawB42", "notify", { key = "IGUI_CSB42_Broken" })
    assertEq(API.last("halo").text, "IGUI_CSB42_Broken", "shown")
    triggerEvent("OnServerCommand", "ChainsawB42", "notify", { key = "UI_Something" })
    assertEq(API.count("halo"), 1, "foreign key ignored")
end

return T
