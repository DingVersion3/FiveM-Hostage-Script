# Ding Hostage 1.0.0

A standalone player-hostage resource with ESX, QBCore, Qbox and custom framework adapters. Lua gameplay/server scripts; all UI is React + TypeScript. Compiled UI is included. No SQL, ox_lib, target or inventory dependency. Requires OneSync.

## Install

1. Place the `ding_hostage` folder in your server's resources. Keep this resource name stable because persistent protection uses resource-scoped KVP storage.
2. Start your framework before this resource. In server.cfg add `ensure ding_hostage` with OneSync enabled.
3. Review `config.lua`. `Framework = 'auto'` selects Qbox first, then QBCore, then ESX, otherwise standalone. Select `custom` and adapt `server/bridge.lua` for a custom server.
4. Optional ACE permissions:

```cfg
add_ace group.admin ding_hostage.admin allow
# Assign this only to your actual police group on standalone servers:
add_ace group.police ding_hostage.police allow
```

The police ACE overrides framework job/duty checks. Do not grant it to everyone. Built-in police jobs are `police` and `sheriff`; edit the config for your server. Qbox/QBCore use server player job data. ESX uses getJob(); if your ESX duty system is separate, integrate it in Bridge.isPolice. Admin command: `/hostage_release <hostage server ID>`; console can also use it.

## Player flow

- One or more players aim an allowed gun at another real player within 15m for about 0.9 seconds. NPCs cannot participate. Aim and line-of-sight are sampled on the client; player existence, weapon, range, routing bucket, eligibility and cooldown are checked on the server.
- The threatened player sees a prompt and presses **X** to put their hands up. That response confirms the tracked hostage session. Captors already aiming are included, up to six. **X** subsequently raises/lowers hands without ending the session.
- **F6** opens the interaction panel. Captors can add another nearby armed player, release the hostage, or offer custody to a nearby police officer by server ID. The officer opens F6 and accepts within 20 seconds while still nearby and eligible.
- Running/sprinting on foot during a current nearby gun threat shows a large red warning that not valuing their life may result in a ban. It records a *possible* rule violation for staff review. It never bans automatically, forces an execution, or treats every movement as misconduct. Vehicles, falls and ragdolls are excluded from that detector.
- Release, accepted police handover, or detected death starts **60 minutes of account-wide protection**. Protection blocks this resource from starting a new hostage session, not damage or other resources' arrest/kidnap actions. Character switching and reconnecting cannot clear it.
- A hostage disconnect, last captor disconnect, resource stop, or abandonment also ends the session with protection. A crash marker grants a fresh 60 minutes on recovery. All captors dead or beyond 80m for 90 seconds counts as abandonment. No fixed maximum duration ends a legitimate active scene.

Keys are rebindable in FiveM Settings → Key Bindings. Config values set defaults; prompts show configured defaults, so users who rebind should use their chosen keys. `/hostage` and `/hostage_comply` are fallback commands. If another hands-up resource uses X, remove its conflicting binding or rebind one resource.

## Scope and integration

This resource tracks consensual compliance and scene lifecycle. There is no physical attachment, forced drag, execution hotkey, job reward, GPS wall tracking, automatic dispatch, arrest, or handcuff implementation. Police acceptance ends hostage tracking and starts protection; your police resource owns the subsequent custody mechanics. It does not interpret voice demands. A player refusing to comply is still warned for running during an active threat, but is not silently forced into a confirmed session.

Only server-side scripts may call:

```lua
local session = exports.ding_hostage:GetHostage(hostageSource)
local seconds = exports.ding_hostage:GetProtectionRemaining(playerSource)
-- From your trusted medical resource when its server confirms death/incapacitation:
exports.ding_hostage:EndHostage(playerSource, 'deceased')
-- Also accepted: 'released', 'police_custody'. Never expose this through an unchecked network event.
```

Session return values contain id, hostage source/name, captors, role, started timestamp, hands and an optional custody offer. They are copies, not mutable internal objects. Server-local lifecycle events:

```lua
AddEventHandler('ding_hostage:started', function(hostageSource, sessionId) end)
AddEventHandler('ding_hostage:released', function(hostageSource, reason, sessionId) end)
AddEventHandler('ding_hostage:audit', function(entry) end)
```

Audit entries also print to FXServer console. Retain your server logs or consume this event for long-term review. Logs label warnings as client reports, not proven violations. No external webhook or telemetry is included. GetHostage lets a job resource verify a real, currently tracked hostage; rewards and mission policy belong to that resource.

## Medical compatibility

Native dead health is detected server-side. Qbox/QBCore `isdead` and `inlaststand` metadata also end the session. ESX/custom medical scripts that maintain positive health while downed must integrate the trusted EndHostage export or implement Bridge.isDead. Test this with your actual ambulance resource: frameworks alone do not standardize every medical implementation.

## Persistence and security

Protection and active recovery markers use FXServer resource KVP, keyed by license identifier. No database setup is needed. Preserve your server KVP data during migrations/backups. Cooldowns rely on the server wall clock. Protection remains active while the player is offline. Missing identity rejects capture visibly. Expired KVP entries are harmless and reused on future captures; storage is one protection record per account ever captured.

Network mutations are rate limited, role checked and validated server-side. Police status never comes from the UI. No client may directly end a session through a death event. Client aim/line-of-sight and animation cannot be proven by the server, so this is not an anticheat. A modified client may lie about aim, but cannot bypass server range/weapon/cooldown checks or manufacture another player's hands-up confirmation. Pair with normal server moderation and anticheat.

## UI development

Requires Node 20.19+ or 22.12+. In `web`: `npm ci` then `npm run build`. Production assets are under `web/dist`. No npm installation is required on the game server. All bundled assets are local; no CDN/fonts/web services are required.

## Validation status

Automated tests execute the real server Lua under a mocked Cfx runtime, covering capture, authority checks, handover, cooldown, distance/bucket/weapon validation, stale threats, death, disconnect, abandonment, restart and crash recovery. TypeScript and production build are checked. A browser test script is included for hidden transparent startup and cleanup, but could not run here because the Chromium download was unavailable. Visual/game verification remains outstanding.

**This build has not been run inside a live FiveM multiplayer server.** Use `docs/ACCEPTANCE.md` before production or selling it. Framework exports were checked against official documentation, but each framework/medical combination still needs an in-game test.

## Technical references

- https://docs.fivem.net/docs/developers/server-security/
- https://docs.fivem.net/docs/scripting-manual/nui-development/full-screen-nui/
- https://docs.qbox.re/resources/qbx_core/exports/server
- https://qbcore.org/docs/qb-core/server-function-reference
- https://docs.esx-framework.org/en/esx_core/es_extended/server/functions
