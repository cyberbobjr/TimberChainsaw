-- Existing Authentic Z items use Timber's actions and authoritative engine.
-- No distribution changes, script replacements or compatibility-only item IDs.
require "ChainsawB42/CSB42_Core"

if not CSB42 or not CSB42.registerFamily then
    error("Timber Authentic Z Compatibility requires Timber! Chainsaw 1.1.0 or newer")
end

local function prepareRunning(item)
    -- These HandWeapon fields are NOT serialized in 42.21 (HandWeapon.save).
    -- Apply on server and clients when held; removal + restart restores scripts.
    -- MinDamage/MaxDamage ARE serialized, so keep Authentic Z's native values.
    item:setTreeDamage(67)
    item:setSwingSound("ChainsawB42_Attack")
    item:setZombieHitSound("ChainsawB42_ZombieHit")
    item:setDoorHitSound("ChainsawB42_ZombieHit")
    item:setHitFloorSound("ChainsawB42_Attack")
end

for _, module in ipairs({ "AuthenticZClothing", "AuthenticZLite" }) do
    CSB42.registerFamily({
        off = module .. ".ChainsawOff",
        running = module .. ".Chainsaw",
        dataKey = "batman_TimberAuthenticZCompatibility",
        keepDamage = true,
        prepareRunning = prepareRunning,
    })
end

-- Authentic Z 42 comments out the implementation but still declares this
-- OnCreate in the running script. Creation/load must succeed before Timber
-- can stop the unregistered running item when a player equips it.
AZ_ChainsawUtil = AZ_ChainsawUtil or {}
AZ_ChainsawUtil.OnCreate = AZ_ChainsawUtil.OnCreate or {}
if not AZ_ChainsawUtil.OnCreate.TurnOffChainsaw then
    AZ_ChainsawUtil.OnCreate.TurnOffChainsaw = function(item)
        -- During OnCreate the item has no container yet: never replace here.
    end
end
