# MangosBot for Turtle WoW

This fork preserves a customised Vanilla client addon based on
[ike3/mangosbot-addon](https://github.com/ike3/mangosbot-addon/tree/1.12).
Use the **turtlewow-development** branch for these customisations. The imported
snapshot targets Turtle WoW 1.18.1, using the Vanilla interface identifier 11200.
Changing that identifier alone does not update addon behaviour.

The existing customisations are imported as one snapshot: their individual
development commits were not available. See [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md)
for provenance and the Celguar comparison.

Download this branch or clone it with:

    git clone --branch turtlewow-development https://github.com/pjw345/mangosbot-addon.git

Copy the addon files into `Interface/AddOns/MangosBot` in your client directory.
The `.toc` file must sit directly in that folder, without an extra repository
folder level. Back up your existing addon first, then restart the client.
This repository contains addon source, not client accounts or SavedVariables.

## Original addon instructions
## Installation
Checkout all files to your Interface/Addons/Mangosbot folder (Mangosbot needs to be created first).

## Bot Roster
Run `/bot` command in WoW to bring Bot Roster window. Click `Login` buttons on appropriate bot window to bring this bot online.

When at least one bot is in your party, the bottom of the roster includes these quest buttons:

- `Quests` lists every party bot's quests.
- `Accept` accepts available quests from your selected quest giver.
- `Turn In` hands completed quests to your selected quest giver.
- `Use Object` makes each party bot use its nearest game object.
- `Sell Junk` runs `s vendor` for every party bot at a nearby vendor.
- `Equip` makes every party bot equip the best upgrades currently in its bags.
- `Loot Nearby Corpses` immediately scans nearby corpses for quest items and
  other useful loot.

Below the buttons, **Party Quest Progress** records the PlayerBots replies when
you press `Quests`. For each quest in the player's quest tracker it shows:

- `Have`: how many party bots accepted the quest.
- `Core*`: how many party bots have PlayerBots' stored completed flag.

For objectives that consume ordinary inventory items rather than dedicated
quest items (for example, *Pie for Billy*), PlayerBots may be able to turn in
the quest before `quests all` updates that stored flag. The quest giver performs
the authoritative final check, so a successful `Turn In` is the reliable result
for this edge case.

Rows are green when the core reports every bot complete, yellow while the whole
party is progressing, and red when one or more bots did not accept the quest.
Hover a row to see the names in each state. Refreshing is deliberately manual:
silent group addon messages can be heard by every bot and cause cross-talk in
this PlayerBots build.

`Loot Nearby Corpses` performs one manual `do loot` action. MangosBot no longer
runs automatic post-combat scans or changes the party's loot policy.

Logging out one bot or all bots immediately removes them from quest polling and
refreshes the roster. Quest/action buttons do not broadcast when no online
PlayerBots remain in the party.

![Screenshot](screenshots/bot_roster.png)

## Bot Controls
Select your bot to bring Bot Controls window. Use numerous buttons to control your bot actions.

![Screenshot](screenshots/bot_controls.png)
