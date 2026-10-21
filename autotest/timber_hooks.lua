-- Timber! Chainsaw in-game nominal test (pz-autotest, single player and multiplayer).
--
-- The client drives the player's real gestures, step by step, from the polled done() hook:
--   prepare   the authority gives a stopped chainsaw (full tank) and finds or plants a tree nearby;
--   started   "Start" from the inventory context menu (equip + CSB42_StartAction): the authority
--             swaps ChainsawOff for a NEW Chainsaw item held in both hands;
--   fuel      the idle engine burns fuel (ModData CurrentFuel, synced every 0.05 L in MP);
--   tree      "Cut down the tree" from the world context menu: walk, cut, the tree falls;
--   combat    a zombie killed by the player with the running chainsaw (killed by the authority:
--             SP Kill(weapon, player), server setAttackedBy + die()): ConditionLossCombat wear;
--   stopped   "Stop" from the inventory context menu: back to ChainsawOff in both hands;
--   restarted started again;
--   attached  the running chainsaw is attached on the back through the vanilla hotbar action
--             (ISAttachItemHotbar): the engine stops and the attached item must be the NEW
--             ChainsawOff, still in the inventory, no running chainsaw left anywhere (C01).
-- Each check runs on the client copy and, in multiplayer, on the server copy of the player too
-- (client command "check"): the server reports its own PASS/FAIL lines.
--
-- Single player: python .claude/tools/pz-autotest/pz_autotest.py sp TimberChainsaw --wait-idle 3600
-- Multiplayer:   python .claude/tools/pz-autotest/pz_autotest.py mp TimberChainsaw --client-run --wait-idle 3600
local H = { client = {}, server = {} }

local MOD = "PZATTimber"
local TREE_SPRITE = "e_americanlinden_1_3"
local TREE_RADIUS = 12

-- ---------------------------------------------------------------------------
-- Shared helpers (client and server)
-- ---------------------------------------------------------------------------

local function newReport()
    return { lines = {}, ok = true, pass = 0, fail = 0 }
end

local function info(report, text)
    report.lines[#report.lines + 1] = "INFO " .. tostring(text)
end

local function rec(report, ok, name, detail)
    if ok then
        report.pass = report.pass + 1
    else
        report.ok = false
        report.fail = report.fail + 1
    end
    report.lines[#report.lines + 1] = (ok and "PASS " or "FAIL ") .. name
        .. (detail and (" - " .. tostring(detail)) or "")
end

local function chainsaws(player, pred)
    local found = player:getInventory():getAllEvalRecurse(function(item)
        return CSB42.isChainsaw(item) and (pred == nil or pred(item))
    end)
    local list = {}
    for i = 0, found:size() - 1 do list[#list + 1] = found:get(i) end
    return list
end

local function attachedChainsaws(player)
    local list = {}
    local attached = player:getAttachedItems()
    for i = 0, attached:size() - 1 do
        local item = attached:get(i):getItem()
        if CSB42.isChainsaw(item) then list[#list + 1] = item end
    end
    return list
end

local function describe(item)
    if not item then return "nil" end
    return item:getFullType() .. "#" .. tostring(item:getID())
end

local function heldBoth(player)
    local held = player:getPrimaryHandItem()
    return held, held ~= nil and player:getSecondaryHandItem() == held
end

--- Checks one step on `player` (client copy or server copy). `mem` keeps values between steps.
local function inspect(player, step, mem, args)
    local held, both = heldBoth(player)
    if step == "started" or step == "restarted" then
        local running = CSB42.isRunningType(held) and both
        local stopped = #chainsaws(player, CSB42.isStoppedType)
        mem.fuelStart = running and CSB42.getFuel(held) or nil
        mem.runningId = running and held:getID() or nil
        local fresh = step ~= "started" or mem.offId == nil or held == nil or held:getID() ~= mem.offId
        return running and stopped == 0 and fresh and player:getInventory():containsRecursive(held),
            string.format("held=%s both=%s stoppedInInventory=%d fuel=%.3f", describe(held), tostring(both),
                stopped, held and CSB42.isChainsaw(held) and CSB42.getFuel(held) or -1)
    elseif step == "fuel" then
        local fuel = CSB42.isRunningType(held) and CSB42.getFuel(held) or nil
        return fuel ~= nil and mem.fuelStart ~= nil and fuel < mem.fuelStart,
            string.format("start=%s now=%s", tostring(mem.fuelStart), tostring(fuel))
    elseif step == "tree" then
        local sq = getCell():getGridSquare(args.x, args.y, args.z)
        local tree = sq and sq:getTree()
        local fuel = CSB42.isRunningType(held) and CSB42.getFuel(held) or nil
        return sq ~= nil and tree == nil, string.format("square=%s tree=%s fuel=%s", tostring(sq ~= nil),
            tostring(tree ~= nil), tostring(fuel))
    elseif step == "combat" then
        local cond = held and CSB42.isChainsaw(held) and held:getCondition() or nil
        local expected = CSB42.option("ConditionLossCombat")
        local before = args.before or mem.condBefore
        return cond ~= nil and before ~= nil and (cond == before - expected or (cond == 0 and before <= expected)),
            string.format("before=%s now=%s expectedLoss=%d max=%d", tostring(before), tostring(cond), expected,
                held and held:getConditionMax() or -1)
    elseif step == "stopped" then
        local running = #chainsaws(player, CSB42.isRunningType)
        return CSB42.isStoppedType(held) and both and running == 0,
            string.format("held=%s both=%s runningInInventory=%d", describe(held), tostring(both), running)
    elseif step == "attached" then
        local list = attachedChainsaws(player)
        local item = list[1]
        local running = #chainsaws(player, CSB42.isRunningType)
        local inInventory = item ~= nil and player:getInventory():containsRecursive(item)
        local inHands = CSB42.isChainsaw(player:getPrimaryHandItem()) or CSB42.isChainsaw(player:getSecondaryHandItem())
        local newItem = item ~= nil and item:getID() ~= mem.runningId
        return #list == 1 and CSB42.isStoppedType(item) and inInventory and running == 0 and not inHands
                and newItem and item:getAttachedSlot() >= 0,
            string.format("attached=%s count=%d inInventory=%s slot=%s runningInInventory=%d inHands=%s newItem=%s",
                describe(item), #list, tostring(inInventory), item and tostring(item:getAttachedSlot()) or "-",
                running, tostring(inHands), tostring(newItem))
    end
    return false, "unknown step " .. tostring(step)
end

-- ---------------------------------------------------------------------------
-- Authority actions (single player: called directly; server: client commands)
-- ---------------------------------------------------------------------------

local function freeOutdoorSquare(cell, px, py, pz)
    for r = 2, 6 do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local sq = cell:getGridSquare(px + dx, py + dy, pz)
                    if sq and sq:isOutside() and sq:isFree(false) and not sq:getTree()
                            and sq:getObjects():size() == 1 and sq:getWorldObjects():size() == 0 then
                        return sq
                    end
                end
            end
        end
    end
    return nil
end

local function prepare(player)
    local inventory = player:getInventory()
    local saw = inventory:AddItem(CSB42.FULLTYPE_OFF)
    if not saw then return { ok = false, error = "AddItem " .. CSB42.FULLTYPE_OFF .. " failed" } end
    sendAddItemToContainer(inventory, saw)

    local cell = getCell()
    local px, py, pz = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    local best, bestD
    for dx = -TREE_RADIUS, TREE_RADIUS do
        for dy = -TREE_RADIUS, TREE_RADIUS do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq and sq:getTree() then
                local d = dx * dx + dy * dy
                if not bestD or d < bestD then best, bestD = sq, d end
            end
        end
    end
    local planted = false
    if not best then
        best = freeOutdoorSquare(cell, px, py, pz)
        if not best then return { ok = false, error = "no tree and no free outdoor square near the player" } end
        local tree = IsoTree.new(best, TREE_SPRITE)
        if isServer() then
            best:transmitAddObjectToSquare(tree, -1)
        else
            best:AddTileObject(tree)
        end
        planted = true
    end
    return { ok = true, id = saw:getID(), x = best:getX(), y = best:getY(), z = best:getZ(),
        planted = planted }
end

local function killZombie(player)
    local held = player:getPrimaryHandItem()
    if not CSB42.isRunningType(held) then return { ok = false, error = "no running chainsaw held" } end
    local before = held:getCondition()
    local zombies = addZombiesInOutfit(math.floor(player:getX()) + 2, math.floor(player:getY()),
        math.floor(player:getZ()), 1, nil, 50)
    local zombie = zombies and zombies:size() > 0 and zombies:get(0)
    if not zombie then return { ok = false, error = "addZombiesInOutfit returned no zombie" } end
    zombie:setAttackedBy(player)
    if isServer() then
        zombie:die()
    else
        zombie:Kill(held, player)
    end
    -- The engine may have replaced a broken chainsaw: read the hands again.
    local now = player:getPrimaryHandItem()
    return { ok = true, before = before,
        after = CSB42.isChainsaw(now) and now:getCondition() or -1 }
end

-- ---------------------------------------------------------------------------
-- Server hooks (multiplayer)
-- ---------------------------------------------------------------------------

local S = { report = newReport(), mem = {}, finished = false }

local function reply(player, command, args)
    args = args or {}
    args.command = command
    sendServerCommand(player, MOD, "reply", args)
end

local function onClientCommand(module, command, player, args)
    if module ~= MOD then return end
    args = args or {}
    if command == "prepare" then
        local res = prepare(player)
        S.mem.offId = res.id
        rec(S.report, res.ok, "server prepare", res.error or string.format("tree=%d,%d,%d planted=%s",
            res.x, res.y, res.z, tostring(res.planted)))
        reply(player, "prepare", res)
    elseif command == "kill" then
        local res = killZombie(player)
        S.mem.condBefore = res.before
        if not res.ok then rec(S.report, false, "server combat", res.error) end
        reply(player, "kill", res)
    elseif command == "check" then
        local ok, detail = inspect(player, args.step, S.mem, args)
        rec(S.report, ok, "server " .. tostring(args.step), detail)
        reply(player, "check", { step = args.step, ok = ok })
    elseif command == "finished" then
        S.finished = true
    end
end

function H.server.start(ctx)
    S.report, S.mem, S.finished = newReport(), {}, false
    if not S.subscribed then
        S.subscribed = true
        Events.OnClientCommand.Add(onClientCommand)
    end
    ctx.log("Timber server hooks ready, " .. tostring(#ctx.players()) .. " player(s) online")
    return true
end

function H.server.done()
    return S.finished
end

function H.server.result()
    local r = S.report
    local ok = r.ok and r.pass >= 8 -- prepare + 7 checks
    return { ok = ok, summary = string.format("server %d PASS, %d FAIL", r.pass, r.fail), lines = r.lines }
end

-- ---------------------------------------------------------------------------
-- Client hooks (single player, and client 1 in multiplayer with --client-run)
-- ---------------------------------------------------------------------------

local C = { report = newReport(), mem = {}, replies = {} }

local function now() return getTimestampMs() end

local function request(command, args)
    C.replies[command] = nil
    if isClient() then
        sendClientCommand(C.player, MOD, command, args or {})
        return
    end
    local res
    if command == "prepare" then
        res = prepare(C.player)
    elseif command == "kill" then
        res = killZombie(C.player)
    else
        res = {}
    end
    C.replies[command] = res
end

local function onServerCommand(module, command, args)
    if module ~= MOD or command ~= "reply" or not args then return end
    C.replies[args.command] = args
end

--- Builds a context menu with the mod's own fill event, then selects the option `key`.
local function selectMenuOption(fill, key)
    local context = ISContextMenu.get(0, 100, 100)
    fill(context)
    local option = context:getOptionFromName(getText(key))
    local usable = option ~= nil and not option.notAvailable
    if usable then
        option.onSelect(option.target, option.param1, option.param2, option.param3, option.param4)
    end
    context:hideAndChildren()
    return usable, option == nil and "option missing" or (option.notAvailable and "option disabled" or nil)
end

local function inventoryMenu(item, key)
    return selectMenuOption(function(context)
        triggerEvent("OnFillInventoryObjectContextMenu", 0, context, { item })
    end, key)
end

local function stepCheck(step, args)
    local side = isClient() and "client " or "sp "
    local ok, detail = inspect(C.player, step, C.mem, args or {})
    rec(C.report, ok, side .. step, detail)
    if isClient() then
        local sent = {}
        for k, v in pairs(args or {}) do sent[k] = v end
        sent.step = step
        sendClientCommand(C.player, MOD, "check", sent)
    end
    return ok
end

local function startFromMenu()
    local saw = C.player:getPrimaryHandItem()
    if not CSB42.isStoppedType(saw) then
        saw = chainsaws(C.player, CSB42.isStoppedType)[1]
    end
    if not saw then return false, "no stopped chainsaw in the inventory" end
    return inventoryMenu(saw, "ContextMenu_CSB42_Start")
end

--- Current timed action of the local player, or "none".
local function currentAction()
    local queue = ISTimedActionQueue.queues and ISTimedActionQueue.queues[C.player]
    local action = queue and queue.queue and queue.queue[1]
    return action and tostring(action.Type) or "none"
end

--- One-line state of the cut: player, position, held item, current action, tree.
local function treeState()
    local p = C.player
    local a = C.treeArgs or {}
    local sq = a.x and getCell():getGridSquare(a.x, a.y, a.z)
    local tree = sq and sq:getTree()
    return string.format("dead=%s pos=%.1f,%.1f,%d held=%s action=%s tree=%s health=%s/%s",
        tostring(p:isDead()), p:getX(), p:getY(), math.floor(p:getZ()), describe(p:getPrimaryHandItem()),
        currentAction(), tostring(tree ~= nil), tree and tostring(tree:getHealth()) or "-",
        tree and tostring(tree:getMaxHealth()) or "-")
end

local function runningHeld()
    local held, both = heldBoth(C.player)
    return CSB42.isRunningType(held) and both and held or nil
end

local function stoppedHeld()
    local held, both = heldBoth(C.player)
    return CSB42.isStoppedType(held) and both and held or nil
end

-- Steps: enter() starts the gesture (false, reason = failure), ready() is polled, check() records.
local STEPS = {
    { name = "prepare", critical = true, timeout = 30,
        enter = function() request("prepare") return true end,
        ready = function()
            local res = C.replies.prepare
            if not res then return false end
            if not res.ok then return true end
            if #chainsaws(C.player, CSB42.isStoppedType) == 0 then return false end
            local sq = getCell():getGridSquare(res.x, res.y, res.z)
            C.tree = sq and sq:getTree()
            return C.tree ~= nil
        end,
        check = function()
            local res = C.replies.prepare
            C.mem.offId = res.id
            C.treeArgs = { x = res.x, y = res.y, z = res.z }
            rec(C.report, res.ok, (isClient() and "client " or "sp ") .. "prepare",
                res.error or string.format("tree=%d,%d,%d planted=%s", res.x, res.y, res.z, tostring(res.planted)))
            return res.ok
        end },
    { name = "started", critical = true, timeout = 40, enter = startFromMenu,
        ready = function() return runningHeld() ~= nil end,
        check = function() return stepCheck("started") end },
    { name = "fuel", timeout = 40, enter = function() return true end,
        ready = function()
            local held = runningHeld()
            return held ~= nil and C.mem.fuelStart ~= nil and CSB42.getFuel(held) < C.mem.fuelStart
        end,
        check = function() return stepCheck("fuel") end },
    { name = "tree", timeout = 150,
        enter = function()
            if not C.tree or C.tree:getObjectIndex() < 0 then return false, "tree gone before the cut" end
            local tree = C.tree
            C.cutSeen = false
            info(C.report, "tree before the cut: " .. treeState())
            local ok, reason = selectMenuOption(function(context)
                triggerEvent("OnFillWorldObjectContextMenu", 0, context, { tree }, false)
            end, "ContextMenu_CSB42_CutTree")
            info(C.report, "tree option selected=" .. tostring(ok) .. " action=" .. currentAction())
            return ok, reason
        end,
        ready = function()
            if not C.cutSeen and currentAction() == "CSB42_CutTreeAction" then
                C.cutSeen = true
                info(C.report, string.format("tree cut action started after %.1f s: %s",
                    (now() - C.stepAt) / 1000, treeState()))
            end
            local sq = getCell():getGridSquare(C.treeArgs.x, C.treeArgs.y, C.treeArgs.z)
            return sq ~= nil and sq:getTree() == nil and ISTimedActionQueue.isPlayerDoingAction(C.player) == false
        end,
        diagnose = function() return "cutActionSeen=" .. tostring(C.cutSeen) .. " " .. treeState() end,
        check = function() return stepCheck("tree", C.treeArgs) end },
    { name = "combat", timeout = 30,
        enter = function()
            local held = runningHeld()
            if not held then return false, "no running chainsaw held" end
            C.mem.condBefore = held:getCondition()
            request("kill")
            return true
        end,
        ready = function()
            local res = C.replies.kill
            if not res then return false end
            if not res.ok then return true end
            local held = C.player:getPrimaryHandItem()
            return CSB42.isChainsaw(held) and held:getCondition() < C.mem.condBefore
        end,
        check = function()
            local res = C.replies.kill
            if not res.ok then
                rec(C.report, false, "combat", res.error)
                return false
            end
            return stepCheck("combat", { before = C.mem.condBefore })
        end },
    { name = "stopped", critical = true, timeout = 30,
        enter = function()
            local held = runningHeld()
            if not held then return false, "no running chainsaw held" end
            return inventoryMenu(held, "ContextMenu_CSB42_Stop")
        end,
        ready = function() return stoppedHeld() ~= nil end,
        check = function() return stepCheck("stopped") end },
    { name = "restarted", critical = true, timeout = 40, enter = startFromMenu,
        ready = function() return runningHeld() ~= nil end,
        check = function() return stepCheck("restarted") end },
    { name = "attached", timeout = 40,
        enter = function()
            local held = runningHeld()
            local hotbar = getPlayerHotbar(0)
            if not held or not hotbar then return false, "no running chainsaw or no hotbar" end
            local slot = hotbar.availableSlot and hotbar.availableSlot[1]
            local slotName = slot and slot.def.attachments[held:getAttachmentType()]
            if not slotName then return false, "no back slot for " .. tostring(held:getAttachmentType()) end
            hotbar:attachItem(held, slotName, 1, slot.def, true)
            return true
        end,
        ready = function()
            -- Leave the engine (authority tick) and, in MP, the item packets time to settle.
            if now() - C.stepAt < 5000 then return false end
            local p = C.player
            return not CSB42.isChainsaw(p:getPrimaryHandItem()) and #attachedChainsaws(p) > 0
                and #chainsaws(p, CSB42.isRunningType) == 0
        end,
        check = function() return stepCheck("attached") end },
}

local function nextStep()
    C.index = C.index + 1
    local step = STEPS[C.index]
    if not step then
        C.finished = true
        if isClient() then sendClientCommand(C.player, MOD, "finished", {}) end
        return
    end
    C.stepAt = now()
    local ok, reason = step.enter()
    if not ok then
        rec(C.report, false, step.name, "could not start: " .. tostring(reason))
        if step.critical then C.index = #STEPS end
        C.waiting = false
        return nextStep()
    end
    C.waiting = true
end

function H.client.start(ctx)
    if not CSB42 or not CSB42.replace then return false, "CSB42 (Timber! Chainsaw) not loaded" end
    C.player = getSpecificPlayer(0)
    if not C.player then return false, "no local player" end
    C.report, C.mem, C.replies, C.index, C.finished, C.tree = newReport(), {}, {}, 0, false, nil
    -- The multiplayer spawn (Muldraugh) has ambient zombies, drawn by the engine noise: run
    -- 20261021-160907 died at the tree (Logs/pvp.txt: 14 zombie hits, user.txt "died") and every
    -- later step failed. Same switch as the admin power "Zombies don't attack" (ISAdminPowerUI),
    -- read by the zombie owner (IsoZombie target test) and sent to the server in MP.
    C.player:setZombiesDontAttack(true)
    if isClient() then sendPlayerExtraInfo(C.player) end
    info(C.report, "zombiesDontAttack=" .. tostring(C.player:isZombiesDontAttack()))
    if not C.subscribed then
        C.subscribed = true
        Events.OnServerCommand.Add(onServerCommand)
    end
    nextStep()
    return true
end

function H.client.done()
    if C.finished then return true end
    local step = STEPS[C.index]
    if C.waiting then
        if C.player:isDead() then
            -- A dead player drops everything: every later step would fail for this reason only.
            rec(C.report, false, step.name, "player died during the step (zombies?)")
            C.index = #STEPS
            C.waiting = false
            nextStep()
            return C.finished
        end
        local ok, ready = pcall(step.ready)
        if not ok then
            rec(C.report, false, step.name, "error: " .. tostring(ready))
            if step.critical then C.index = #STEPS end
        elseif ready then
            local okCheck, passed = pcall(step.check)
            if not okCheck then
                rec(C.report, false, step.name, "error: " .. tostring(passed))
                passed = false
            end
            if not passed and step.critical then C.index = #STEPS end
        elseif now() - C.stepAt > step.timeout * 1000 then
            local detail = "timeout after " .. tostring(step.timeout) .. " s"
            if step.diagnose then
                local _, text = pcall(step.diagnose)
                detail = detail .. " - " .. tostring(text)
            end
            rec(C.report, false, step.name, detail)
            if step.critical then C.index = #STEPS end
        else
            return false
        end
        C.waiting = false
        nextStep()
    end
    return C.finished
end

function H.client.result()
    local r = C.report
    local ok = r.ok and r.pass >= #STEPS
    return { ok = ok, summary = string.format("%s %d PASS, %d FAIL", isClient() and "client" or "sp", r.pass,
        r.fail), lines = r.lines }
end

return H
