local state, offer, panel, hands = false, false, false, false
local threatIds, threatUntil, warningUntil, protectionUntil = {},0,0,0
local allowed = {}
for _,name in ipairs(Config.Weapons) do allowed[GetHashKey(name)] = true end
local function ui(kind,data) SendNUIMessage({ type=kind, data=data }) end
local function showPanel(value)
    panel=value; SetNuiFocus(value,value); ui('panel',value)
end
local function stopHands()
    hands=false
    StopAnimTask(PlayerPedId(),'missminuteman_1ig_2','handsup_base',2.0)
end
RegisterNetEvent('ding_hostage:state',function(data)
    state=data; ui('state',data)
    if not data or data.role~='hostage' or not data.hands then stopHands() else hands=true end
end)
RegisterNetEvent('ding_hostage:threat',function(ids)
    threatIds=ids; threatUntil=GetGameTimer()+Config.ThreatExpirySeconds*1000
    ui('threat',#ids>0)
end)
RegisterNetEvent('ding_hostage:offer',function(data)
    offer=data; ui('offer',data)
    if data then ui('notice','Police handover requested. Open the hostage panel to accept.') end
end)
RegisterNetEvent('ding_hostage:notice',function(text) ui('notice',text) end)
RegisterNetEvent('ding_hostage:protection',function(seconds)
    protectionUntil=GetGameTimer()+seconds*1000; ui('protection',seconds)
end)
RegisterNetEvent('ding_hostage:ended',function(reason,seconds)
    state=false; stopHands(); ui('state',false); ui('threat',false)
    threatIds={}; warningUntil=0; ui('warning',false)
    if seconds>0 then protectionUntil=GetGameTimer()+seconds*1000; ui('protection',seconds) end
    ui('notice','Hostage session ended: '..reason:gsub('_',' ')..'.')
end)
RegisterCommand('hostage_comply',function() TriggerServerEvent('ding_hostage:comply') end,false)
RegisterKeyMapping('hostage_comply','Hostage: comply / raise or lower hands','keyboard',Config.Keys.Comply)
RegisterCommand('hostage',function() showPanel(not panel) end,false)
RegisterKeyMapping('hostage','Hostage: interaction panel','keyboard',Config.Keys.Panel)
RegisterNUICallback('close',function(_,cb) showPanel(false); cb({ok=true}) end)
RegisterNUICallback('ready',function(_,cb)
    ui('config',{warning=Config.Warning,comply=Config.Keys.Comply,panel=Config.Keys.Panel})
    ui('state',state); ui('panel',panel); ui('offer',offer)
    ui('protection',math.max(0,math.ceil((protectionUntil-GetGameTimer())/1000)))
    TriggerServerEvent('ding_hostage:ready'); cb({ok=true})
end)
RegisterNUICallback('action',function(data,cb)
    if type(data)=='table' and type(data.action)=='string' then
        if data.action=='comply' then TriggerServerEvent('ding_hostage:comply')
        else TriggerServerEvent('ding_hostage:action',data.action,tonumber(data.target)) end
    end
    cb({ok=true})
end)
CreateThread(function()
    local previous, since, lastSend = nil,0,0
    while true do
        Wait(200)
        local ped, now = PlayerPedId(),GetGameTimer()
        local aimed,target = GetEntityPlayerIsFreeAimingAt(PlayerId())
        local id=nil
        if aimed and target~=0 and IsEntityAPed(target) and IsPedAPlayer(target)
            and allowed[GetSelectedPedWeapon(ped)] and not IsEntityDead(ped)
            and HasEntityClearLosToEntity(ped,target,17) then
            local player=NetworkGetPlayerIndexFromPed(target)
            if player~=-1 and #(GetEntityCoords(ped)-GetEntityCoords(target))<=Config.ThreatDistance then id=GetPlayerServerId(player) end
        end
        if id~=previous then previous=id; since=now end
        if id and now-since>=Config.AimDwellMs and now-lastSend>=650 then
            lastSend=now; TriggerServerEvent('ding_hostage:aim',id)
        end
        if now>threatUntil and #threatIds>0 then threatIds={}; ui('threat',false) end
        local threatened=false
        for _,serverId in ipairs(threatIds) do
            local p=GetPlayerFromServerId(serverId)
            if p~=-1 then
                local other=GetPlayerPed(p)
                if not IsEntityDead(other) and #(GetEntityCoords(ped)-GetEntityCoords(other))<=Config.ThreatDistance
                    and HasEntityClearLosToEntity(other,ped,17) then threatened=true end
            end
        end
        if threatened and not IsPedInAnyVehicle(ped,false) and not IsPedRagdoll(ped) and not IsPedFalling(ped)
            and not IsEntityDead(ped) and (IsPedRunning(ped) or IsPedSprinting(ped)) then
            if now>warningUntil then TriggerServerEvent('ding_hostage:warning') end
            warningUntil=now+5000; ui('warning',true)
        elseif warningUntil>0 and now>warningUntil then warningUntil=0; ui('warning',false) end
    end
end)
CreateThread(function()
    local dict='missminuteman_1ig_2'
    while true do
        if hands and state and state.role=='hostage' then
            local ped=PlayerPedId()
            if IsEntityDead(ped) or IsPedInAnyVehicle(ped,false) or IsPedRagdoll(ped) then
                StopAnimTask(ped,dict,'handsup_base',2.0); Wait(200)
            else
                if not HasAnimDictLoaded(dict) then
                    RequestAnimDict(dict)
                    local deadline=GetGameTimer()+5000
                    while not HasAnimDictLoaded(dict) and GetGameTimer()<deadline do Wait(20) end
                    if not HasAnimDictLoaded(dict) then ui('notice','Hands-up animation failed to load. Contact staff.'); hands=false end
                end
                if hands and not IsEntityPlayingAnim(ped,dict,'handsup_base',3) then TaskPlayAnim(ped,dict,'handsup_base',3.0,3.0,-1,49,0,false,false,false) end
                DisablePlayerFiring(PlayerId(),true)
                DisableControlAction(0,24,true); DisableControlAction(0,25,true)
                DisableControlAction(0,37,true); DisableControlAction(0,140,true)
                DisableControlAction(0,141,true); DisableControlAction(0,142,true)
                Wait(0)
            end
        else Wait(250) end
    end
end)
AddEventHandler('onResourceStop',function(name)
    if name~=GetCurrentResourceName() then return end
    stopHands(); SetNuiFocus(false,false)
end)
