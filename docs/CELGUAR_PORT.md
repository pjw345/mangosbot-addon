# First compatible Celguar port

Version 1.1.0-turtle.14 adapts controls from Celguar's 1.12 branch at
6f7300b15c7897992ac78b7874c4f61963de7459. This is a selective adaptation,
not a replacement of the custom addon or a wholesale merge.

## Behaviour

- Parse Combat, Non Combat, Dead and Reaction strategy replies, retaining the
  original Strategies reply and both Vanilla and modern addon packet layouts.
- Recognise holy/discipline/restoration healers and protection/feral tanks.
  Off-healing alone does not turn a DPS bot's role indicator into a healer.
- Priest specialisation buttons set combat, noncombat, dead and reaction engines.
  The first button now selects discipline rather than the obsolete generic heal
  strategy. Holy and shadow keep their own buttons.
- Two explicit priest buttons select Holy healer only (remove offdps/offheal)
  or Holy healer with damage (add offdps, remove offheal). Off-healing and
  preventive-healing toggles are available separately. These controls do not
  promise a particular mana budget or healing priority; the server supplies AI.
- Tank assist and DPS assist remove the other assist strategy. Tank AoE remains
  a separate existing control. These buttons do not override the server's
  human-master target policy or require skull marks.
- Repair sends the native repair command to the selected bot, using an existing
  icon. An available repair vendor and ordinary server conditions still apply.
- Allocate one roster item per bot instead of wrapping at ten. Additional columns
  keep the roster to at most ten rows; toolbars and the custom quest panel remain
  below the actual roster. This fixes the original custom layout beyond Celguar's
  fixed-height adjustment. Very large rosters can exceed screen width.

Manual quest queries/actions, corpse loot controls, party guards and ordered
dispatch are preserved. No automatic looting, default strategy change, query
cache, pull timing or expansion-specific spell controls are introduced.

## Validation and installation

Run `python -m pip install lupa==2.8`, then
`python tests/test_controls.py .`. The test runs the actual addon in Lua 5.1 with
mocked Vanilla frame/chat APIs; it checks syntax, reply parsing and role state,
both event packet layouts, actual button routing and numeric command ordering,
and actual roster rendering at 20, 11 and 3 entries. This is not an in-game test.

After review, install the addon files into Interface/AddOns/MangosBot while the
client is closed. Keep the existing SavedVariables unless investigating a
specific issue. No server rebuild is needed. This PR does not install files.

In game, check selected-bot priest modes and returned strategies, role icons,
repair near a vendor, assist switching, reconnects and a roster above ten bots.
Also verify the existing quest action buttons and manual corpse-looting controls.
