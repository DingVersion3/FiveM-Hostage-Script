local R = GetCurrentResourceName()
local sessions, member, threats, limits, lastNotice = {}, {}, {}, {}, {}
local weapons = {}
for _, name in ipairs(Config.Weapons) do weapons[GetHashKey(name)] = true end
assert(Config.CooldownSeconds > 0 and Config.MaxCaptors >= 1, 'Invalid hostage configuration')
local function identity(src) return Bridge.identifier(src) end
local function key(id) return 'protection:' .. id end
local function protect(id)
    SetResourceKvpInt(key(id), os.time() + Config.CooldownSeconds)
    DeleteResourceKvp('active:' .. id)
end
-- Crash recovery: active markers never expire mid-session. Recovery grants a full cooldown.
local handle = StartFindKvp('active:')
while true do
    Wait(0)
    local k = FindKvp(handle)
    if not k then break end
    protect(k:sub(8))
end
EndFindKvp(handle)
local function remaining(src)
    local id = identity(src)
    if not id then return 0 end
    return math.max(0, GetResourceKvpInt(key(id)) - os.time())
end
local function notify(src, text)
    TriggerClientEvent('ding_hostage:notice', src, text)
end
local function audit(kind, s, actor)
    local entry = { event = kind, session = s and s.id, hostage = s and s.hostage, actor = actor, time = os.time() }
    print('[ding_hostage] ' .. json.encode(entry))
    TriggerEvent('ding_hostage:audit', entry) -- local server event only; no network registration
end
local function live(src)
    return type(src) == 'number' and src > 0 and src % 1 == 0 and GetPlayerName(src) ~= nil and GetPlayerPed(src) ~= 0
end
local function near(a, b, distance)
    return live(a) and live(b) and GetPlayerRoutingBucket(a) == GetPlayerRoutingBucket(b)
        and #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b))) <= distance
end
local function armed(src) return weapons[GetCurrentPedWeapon(GetPlayerPed(src))] == true end
local function safeDead(src)
    local ok, result = pcall(Bridge.isDead, src)
    if not ok then print('[ding_hostage] MEDICAL_ADAPTER_ERROR ' .. tostring(result)); return true end
    return result
end
local function police(src)
    local ok, result = pcall(Bridge.isPolice, src)
    if not ok then print('[ding_hostage] POLICE_ADAPTER_ERROR ' .. tostring(result)); return false end
    return result
end
local function snapshot(s, src)
    local captors = {}
    for c in pairs(s.captors) do captors[#captors + 1] = { id = c, name = GetPlayerName(c) or 'Disconnected' } end
    table.sort(captors, function(a,b) return a.id < b.id end)
    return { id = s.id, hostage = s.hostage, name = GetPlayerName(s.hostage), captors = captors,
        role = src == s.hostage and 'hostage' or 'captor', started = s.started, hands = s.hands,
        offer = s.offer and { officer = s.offer.officer, expires = s.offer.expires } or false }
end
local function sync(s)
    TriggerClientEvent('ding_hostage:state', s.hostage, snapshot(s, s.hostage))
    for c in pairs(s.captors) do TriggerClientEvent('ding_hostage:state', c, snapshot(s, c)) end
end
local function finish(s, reason, actor)
    if not s or not sessions[s.hostage] then return false end
    protect(s.identity) -- persist BEFORE publishing release
    sessions[s.hostage], member[s.hostage] = nil, nil
    threats[s.hostage] = nil
    TriggerClientEvent('ding_hostage:ended', s.hostage, reason, Config.CooldownSeconds)
    for c in pairs(s.captors) do
        member[c] = nil
        TriggerClientEvent('ding_hostage:ended', c, reason, 0)
    end
    if s.offer then TriggerClientEvent('ding_hostage:offer', s.offer.officer, false) end
    audit(reason, s, actor)
    TriggerEvent('ding_hostage:released', s.hostage, reason, s.id)
    return true
end
local function validThreat(c, victim, at)
    return at > os.time() - Config.ThreatExpirySeconds and near(c, victim, Config.ThreatDistance)
        and armed(c) and not safeDead(c) and not safeDead(victim)
end
local function threatList(victim)
    local list = {}
    for c, at in pairs(threats[victim] or {}) do
        if validThreat(c, victim, at) then list[#list + 1] = c else threats[victim][c] = nil end
    end
    table.sort(list)
    return list
end
local function count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
local function on(name, interval, fn)
    RegisterNetEvent('ding_hostage:' .. name, function(...)
        local src = source
        if not live(src) then return end
        limits[src] = limits[src] or {}
        local now = GetGameTimer()
        if limits[src][name] and now - limits[src][name] < interval then return end
        limits[src][name] = now
        fn(src, ...)
    end)
end
on('aim', 400, function(src, target)
    if not live(target) or target == src or not near(src,target,Config.ThreatDistance) or not armed(src)
        or safeDead(src) or safeDead(target) then return end
    local s = sessions[target]
    if member[src] and (not s or member[src] ~= target or src == target) then return end
    if member[target] and not s then return end
    if remaining(target) > 0 then
        if not lastNotice[src] or os.time()-lastNotice[src] > 8 then
            lastNotice[src] = os.time(); notify(src, ('This player is protected for %d more minutes.'):format(math.ceil(remaining(target)/60)))
        end
        return
    end
    if s and not s.captors[src] then return end -- joining active sessions requires lead approval
    for v, list in pairs(threats) do if v ~= target then list[src] = nil end end
    threats[target] = threats[target] or {}; threats[target][src] = os.time()
    TriggerClientEvent('ding_hostage:threat', target, threatList(target))
end)
on('comply', 700, function(src)
    local s = sessions[src]
    if s then s.hands = not s.hands; sync(s); return end
    if member[src] or remaining(src) > 0 then return end
    local id = identity(src)
    if not id then notify(src, 'Unable to verify account identity. Contact staff.'); return end
    local list, captors = threatList(src), {}
    for _, c in ipairs(list) do if not member[c] and count(captors) < Config.MaxCaptors then captors[c] = true end end
    if next(captors) == nil then notify(src, 'No active gun threat nearby.'); return end
    s = { id = ('%d-%d-%d'):format(os.time(), src, GetGameTimer()), hostage = src, identity = id,
        captors = captors, started = os.time(), hands = true }
    SetResourceKvpInt('active:' .. id, os.time())
    sessions[src], member[src] = s, src
    for c in pairs(captors) do member[c] = src end
    audit('complied', s, src); sync(s)
    TriggerEvent('ding_hostage:started', src, s.id)
end)
on('action', 700, function(src, action, target)
    if type(action) ~= 'string' then return end
    local s = member[src] and sessions[member[src]]
    if action == 'accept' then
        if not live(target) then return end
        s = sessions[target]
        if not s or not s.offer or s.offer.officer ~= src or s.offer.expires < os.time()
            or not police(src) or safeDead(src) or not near(src,target,Config.InteractionDistance) then
            notify(src, 'Handover expired or you are no longer eligible/nearby.'); return
        end
        finish(s, 'police_custody', src); notify(src, 'Custody accepted. Hostage protection is now active.'); return
    end
    if not s or not s.captors[src] then return end
    if safeDead(src) then return end
    if action == 'release' then finish(s, 'released', src)
    elseif action == 'handover' then
        if not live(target) or member[target] or not police(target) or safeDead(target)
            or not near(src,s.hostage,Config.InteractionDistance) or not near(target,s.hostage,Config.InteractionDistance) then
            notify(src,'Choose an eligible nearby officer who is not part of this session.'); return
        end
        if s.offer then TriggerClientEvent('ding_hostage:offer',s.offer.officer,false) end
        s.offer = { officer = target, expires = os.time() + Config.HandoverSeconds }
        TriggerClientEvent('ding_hostage:offer',target,{ hostage=s.hostage, name=GetPlayerName(s.hostage), seconds=Config.HandoverSeconds })
        sync(s)
    elseif action == 'invite' then
        if not live(target) or member[target] or count(s.captors) >= Config.MaxCaptors
            or not near(target,s.hostage,Config.InteractionDistance) or not near(src,target,Config.InteractionDistance)
            or not armed(target) or safeDead(target) then notify(src,'Additional captor must be nearby, armed and available.'); return end
        s.captors[target] = true; member[target] = s.hostage; sync(s); audit('captor_added',s,src)
    end
end)
on('warning', 15000, function(src)
    local s = sessions[src]
    if #threatList(src) == 0 then return end
    audit('possible_failrp_client_report',s,src) -- evidence hint only; never automatically punish
end)
on('ready', 2000, function(src)
    local s = member[src] and sessions[member[src]]
    TriggerClientEvent('ding_hostage:state', src, s and snapshot(s,src) or false)
    TriggerClientEvent('ding_hostage:protection', src, remaining(src))
end)
AddEventHandler('playerDropped', function()
    local src = source
    local s = member[src] and sessions[member[src]]
    if s then
        if src == s.hostage then finish(s,'hostage_disconnected',src)
        else
            s.captors[src], member[src] = nil,nil
            if next(s.captors) == nil then finish(s,'captors_disconnected',src) else sync(s) end
        end
    end
    threats[src], limits[src], lastNotice[src] = nil,nil,nil
    for _, list in pairs(threats) do list[src] = nil end
end)
CreateThread(function()
    while true do
        Wait(1000)
        for victim,s in pairs(sessions) do
            if safeDead(victim) then finish(s,'deceased',victim)
            else
                local close = false
                for c in pairs(s.captors) do
                    if not safeDead(c) and near(c,victim,Config.AbandonedDistance) then close = true end
                end
                if close then s.abandoned = nil else s.abandoned = s.abandoned or os.time() end
                if s.abandoned and os.time()-s.abandoned >= Config.AbandonedSeconds then finish(s,'abandoned',0)
                elseif s.offer and s.offer.expires < os.time() then
                    TriggerClientEvent('ding_hostage:offer',s.offer.officer,false); s.offer=nil; sync(s)
                end
            end
        end
        for victim in pairs(threats) do
            if #threatList(victim) == 0 then threats[victim]=nil; TriggerClientEvent('ding_hostage:threat',victim,{}) end
        end
    end
end)
AddEventHandler('onResourceStop', function(name)
    if name ~= R then return end
    for _,s in pairs(sessions) do finish(s,'resource_stopped',0) end
end)
RegisterCommand('hostage_release', function(src,args)
    if src ~= 0 and not IsPlayerAceAllowed(src,Config.AdminAce) then return end
    local target=tonumber(args[1]); local s=target and sessions[target]
    if not s then if src~=0 then notify(src,'No active hostage with that server ID.') end; return end
    finish(s,'staff_released',src)
end,false)
exports('GetHostage', function(src)
    local s=sessions[tonumber(src)]; return s and snapshot(s,s.hostage) or nil
end)
exports('GetProtectionRemaining', function(src) return remaining(tonumber(src)) end)
exports('EndHostage', function(src,reason)
    -- Trusted server resources only. Not a network event.
    if reason ~= 'deceased' and reason ~= 'released' and reason ~= 'police_custody' then return false end
    return finish(sessions[tonumber(src)],reason,0)
end)
