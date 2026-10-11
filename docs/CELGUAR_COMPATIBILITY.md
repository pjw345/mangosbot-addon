# Celguar command compatibility review

Reviewed 2026-10-11. This is a source review, not a gameplay certification.

- Server: `pjw345/tortoise-wow`, playerbots-development at
  `50abfec774a800680d2337110ee72df5b61062c3`.
- Celguar addon: 1.12 at `6f7300b15c7897992ac78b7874c4f61963de7459`.
- Custom addon baseline: `365907b0d261be16933318a1995ad233c03d768a`.

The review used an isolated archive of the server revision. It did not change
the build checkout, game client, configuration, database or running services.

## Command inventory

[Machine-readable inventory](celguar-command-inventory.json) records 446 literal
toolbar command entries, including repeated commands and their addon line
numbers. All have a corresponding source dispatch path or strategy registration:
382 strategy commands, 57 chat/shortcut commands, five direct action commands,
one reset and one queued command. This is a name/dispatch check only. Registrations
across classes and build variants do not prove that every command works for every
bot. Dynamic query calls and parameters were separately sampled below; they are
not included in the 446 count.

Source references in the inventory are relative to the pinned server revision.
Relevant execution path: `PlayerbotMgr::HandleCommand` ->
`PlayerbotAI::HandleCommand` -> `ExternalEventHelper::ParseChatCommand` ->
chat triggers/actions or `ChangeStrategyAction` -> `Engine::addStrategy`.

## Findings and port decisions

| Area | Source finding | Decision |
| --- | --- | --- |
| Transport | PlayerbotAI.cpp accepts the `BOT\t` prefix, strips `#a`, and splits the configured command separator. The default separator agrees with the addon. Security and group ownership checks still apply. | Command transport has a source match; retain our party/raid and empty-party guards. |
| Reply parsing | Celguar assigns addon replies from arg2/arg4 unconditionally (Lua 3088-3091). Our server builds CHAT_MSG_ADDON chat packets with message and bot identity; our imported addon already accepts the Vanilla arg1/arg2 layout plus the modern fallback. | Do not overwrite our reply parser. This can break controls despite accepted commands. |
| Button sequence order | Celguar combines indexed command tables using `pairs` (Lua 183 and 195). Lua does not promise numeric order for pairs. Some buttons remove/add assist strategies then queue an attack. | Preserve ordered dispatch from the ike3 baseline; port button definitions individually. |
| Strategy query parser | Combat, Non Combat and Reaction prefixes emitted by Engine::PrintStrategies match Celguar's 19/23/21 character offsets. | Prefix parsing is a compatible candidate; preserve our quest-response handling. |
| Priest controls | PriestAiObjectContext registers offheal/offdps and the class strategies; generic preheal is also registered. Celguar's priest buttons add holy/discipline/shadow to combat, noncombat, dead and reaction engines. Engine removes registered sibling strategies on add. | Candidate port with explicit healer-only vs healer-plus-DPS semantics and checks of returned strategy lists. Registration alone is not proof that healing priority/mana behaviour is correct. |
| Assist / attack | ChatCommandHandlerStrategy routes attack to attack-my-target; queue is handled by PlayerbotAI. tank assist and dps assist are registered. | Candidate port, retaining numeric command order and testing tank/DPS filters and selected target. |
| Pull / delay | pull, pull back and wait for attack strategies are registered; wait for attack time has a chat trigger and action. | Candidate port; test timing and target selection without silently changing current defaults. |
| Repair | repair has a chat registration and RepairAllAction. | Candidate port; still requires an available repair vendor and applicable game conditions. |
| Expansion spell controls | The 1.12 addon includes aspect viper/dragonhawk, pet felguard, anesthetic poison and wrath totems. Server contexts contain their names too. | Require spell-data/learned-spell checks for Turtle WoW. Do not expose a button merely because a cross-expansion registration exists. |
| Role indicator | Celguar's strategy parser infers heal only from literal heal, and tank from tank/bear (Lua 3334-3335); its role buttons use holy/discipline/protection/tank feral. | Review role display against actual server responses; button labels and display inference are not equivalent contracts. |
| More than ten bots | Roster layout change 386ecfa changes its height decision to botCount rather than raid size. | UI candidate; adapt around our extra quest/action panels. This is independent of the server's roaming-bot population setting. |

## Validation and remaining work

The inventory check found no missing names or unresolved toolbar dispatchers.
The strategy-prefix offsets were checked against the actual server strings.
Aliases such as follow, stay, flee, guard, accept, revive, talk, c/e/s and d actions
were traced through chat trigger/action registrations or the direct dispatcher.
The queue attack payload resolves to the attack trigger; class filters are still
handled by the native chat filter and must be exercised in a client test.

No bot commands were sent during this review. No server build is required for
the eventual client-addon ports. Remaining gates before calling a port validated:

1. Apply a small addon-only change while keeping custom quest/loot behaviour.
2. Check Lua syntax and client APIs for the supported Vanilla client.
3. Check spell-specific buttons against the actual Turtle spell/learned-spell data.
4. Test selected-bot and party controls, reconnects, role switches, replies and
   disabled/unsupported states in-game, with gameplay changes made deliberately.

These results support selective ports, not replacing the addon with Celguar's
complete file or declaring all of its commands gameplay-compatible.
