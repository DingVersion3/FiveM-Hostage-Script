-- Only this server-side adapter needs editing for a custom framework.
Bridge = {}
function Bridge.identifier(src)
    return GetPlayerIdentifierByType(src, 'license') -- account-wide, not character/source ID
end
local function framework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    if GetResourceState('qb-core') == 'started' then return 'qbcore' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    return 'standalone'
end
function Bridge.player(src)
    local fw = framework()
    if fw == 'qbox' then return exports.qbx_core:GetPlayer(src) end
    if fw == 'qbcore' then return exports['qb-core']:GetCoreObject().Functions.GetPlayer(src) end
    if fw == 'esx' then return exports.es_extended:getSharedObject().GetPlayerFromId(src) end
end
function Bridge.isPolice(src)
    if IsPlayerAceAllowed(src, Config.PoliceAce) then return true end
    local fw = framework()
    if fw == 'custom' then return false end -- Replace with trusted server job/duty check.
    local p = Bridge.player(src)
    if not p then return false end
    local job = fw == 'esx' and p.getJob() or p.PlayerData.job
    if not job or not Config.PoliceJobs[job.name] then return false end
    -- ESX installations without a duty field normally encode off-duty as another job name.
    return not Config.RequirePoliceDuty or job.onduty ~= false
end
function Bridge.isDead(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    if GetEntityHealth(ped) <= 0 then return true end
    local p = Bridge.player(src)
    local m = p and p.PlayerData and p.PlayerData.metadata
    return m and (m.isdead == true or m.inlaststand == true) or false
    -- Custom/ESX medical systems can use the server-only EndHostage export on incapacitation.
end
