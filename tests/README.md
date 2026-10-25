# Resource marker addon tests

Run with Lua 5.0.3 from the repository root:

```
lua tests/resource-markers.lua ResourceMarkers.lua
```

The fake WoW UI exercises the production module. It validates bounded parsing,
transactional snapshots, missing/out-of-order chunks, roster filtering, duplicate
GUIDs without numeric conversion, TTL/depletion, filters, projection and wrong-map
isolation. Native packets, actual minimap artwork/zoom, map data and gameplay need
separate live acceptance. No test installs an addon or commands a running bot.
