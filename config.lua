Config = {
    Framework = 'auto', -- auto | standalone | esx | qbcore | qbox | custom
    CooldownSeconds = 60 * 60,
    ThreatDistance = 15.0,
    InteractionDistance = 4.0,
    AimDwellMs = 900,
    ThreatExpirySeconds = 3,
    MaxCaptors = 6,
    AbandonedSeconds = 90, -- all captors >80m away: end with protection
    AbandonedDistance = 80.0,
    HandoverSeconds = 20,
    RequirePoliceDuty = true,
    PoliceJobs = { police = true, sheriff = true },
    PoliceAce = 'ding_hostage.police',
    AdminAce = 'ding_hostage.admin',
    Keys = { Comply = 'X', Panel = 'F6' },
    Warning = 'VALUE YOUR LIFE — Running while threatened may violate server rules and may result in a ban. Comply with reasonable demands. Staff review applies.',
    Weapons = { -- Explicit firearm allowlist; add custom firearm spawn names here.
        'WEAPON_PISTOL', 'WEAPON_PISTOL_MK2', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL',
        'WEAPON_PISTOL50', 'WEAPON_SNSPISTOL', 'WEAPON_SNSPISTOL_MK2', 'WEAPON_HEAVYPISTOL',
        'WEAPON_VINTAGEPISTOL', 'WEAPON_REVOLVER', 'WEAPON_REVOLVER_MK2', 'WEAPON_DOUBLEACTION',
        'WEAPON_CERAMICPISTOL', 'WEAPON_NAVYREVOLVER', 'WEAPON_GADGETPISTOL',
        'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_SMG_MK2', 'WEAPON_ASSAULTSMG',
        'WEAPON_COMBATPDW', 'WEAPON_MACHINEPISTOL', 'WEAPON_MINISMG',
        'WEAPON_PUMPSHOTGUN', 'WEAPON_PUMPSHOTGUN_MK2', 'WEAPON_SAWNOFFSHOTGUN',
        'WEAPON_ASSAULTSHOTGUN', 'WEAPON_BULLPUPSHOTGUN', 'WEAPON_HEAVYSHOTGUN',
        'WEAPON_DBSHOTGUN', 'WEAPON_AUTOSHOTGUN', 'WEAPON_COMBATSHOTGUN',
        'WEAPON_ASSAULTRIFLE', 'WEAPON_ASSAULTRIFLE_MK2', 'WEAPON_CARBINERIFLE',
        'WEAPON_CARBINERIFLE_MK2', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_SPECIALCARBINE',
        'WEAPON_SPECIALCARBINE_MK2', 'WEAPON_BULLPUPRIFLE', 'WEAPON_BULLPUPRIFLE_MK2',
        'WEAPON_COMPACTRIFLE', 'WEAPON_MILITARYRIFLE', 'WEAPON_HEAVYRIFLE', 'WEAPON_TACTICALRIFLE',
        'WEAPON_MG', 'WEAPON_COMBATMG', 'WEAPON_COMBATMG_MK2', 'WEAPON_GUSENBERG',
        'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER', 'WEAPON_HEAVYSNIPER_MK2', 'WEAPON_MARKSMANRIFLE'
    }
}
