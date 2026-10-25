# Customisation provenance and upstream comparison

## Imported snapshot

The Turtle WoW snapshot was taken from an existing installed customised addon.
Its original baseline is ike3's 1.12 branch, commit
`be0e563e91321cf79136b9fbd3c223a3b6802c2f`.
Lua, XML, bindings and localisation were copied without functional changes.
The manifest uses interface 11200 and version `1.1.0-turtle.13`; documentation
has been expanded. This import does not install anything into a game client.

Custom behaviour includes manual party quest progress, quest actions, use-object,
sell-junk, equip and manual corpse-looting buttons. Quest queries remain manual;
automatic post-combat loot scans and loot-policy changes remain disabled.
Logging out bots clears their quest state and refreshes the roster. Party actions
avoid broadcasts when no online bots are present. Addon reply parsing supports
the Vanilla server packet layout as well as the modern layout fallback.

## Celguar comparison

Comparison baseline: Celguar's 1.12 branch at
`6f7300b15c7897992ac78b7874c4f61963de7459`.
It diverges from ike3's branch: a wholesale merge would change server commands,
strategy names and UI behaviour, and needs compatibility review.

Candidates for separate reviewed changes:

| Candidate | Upstream commit | Compatibility work |
| --- | --- | --- |
| Roster layout for more than ten bots | 386ecfa | Check against our additional quest-panel height and roster sizing. |
| Selected-bot query suppression | a2c4630 | Review final implementation and invalidate cached state on reconnect; the original commit has a malformed conditional. |
| Strategy response parsing | 574a749 | Match the server's actual response prefixes before porting offsets. |
| Priest controls | 6f7300b | Verify every strategy and command against the Turtle WoW server before exposing buttons. |
| Role and assist controls | 5eb5814 | Verify tank/heal/DPS switching does not replace existing custom strategies unexpectedly. |
| Repair and class controls | 28bf4a2, 605339b, b421157, 0591741 | Verify supported server command names and Vanilla APIs individually. |

No Celguar gameplay changes have been merged in this snapshot. Retain the
original authorship and upstream history; this fork does not introduce a new
licence grant for upstream code. Repository publication does not itself grant
additional rights to redistribute upstream material.

For future comparisons:

    git remote add upstream https://github.com/ike3/mangosbot-addon.git
    git remote add celguar https://github.com/celguar/mangosbot-addon.git
    git fetch upstream 1.12
    git fetch celguar 1.12
    git log --oneline upstream/1.12..celguar/1.12

Detailed server command checks are recorded in
[the compatibility review](docs/CELGUAR_COMPATIBILITY.md).

## Group resource minimap icons

ResourceMarkers.lua is a separate Turtle extension loaded after Mangosbot.lua.
It polls only when pfQuest minimap support is available. It uses that support's
dimensions/zoom APIs without modifying pfQuest nodes or the map selection. The
read-only RESBOT protocol requires matching server support; it does not scrape
chat or learn/grant tracking spells. Roster, zone and expiry cleanup fail closed.
Use `/botresources off` to disable. No installed client is modified by this PR.
