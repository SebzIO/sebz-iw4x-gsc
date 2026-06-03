# Development Notes

## Bridge Pattern

IW4MAdmin commands cannot directly run GSC functions. The bridge sends small command requests into the game server with dvars. GSC scripts watch those dvars, match the requesting player, and execute the local script behavior.

For ESP, the bridge writes:

```text
sebz_esp_request=<timestamp>:<network-guid-hex>:<client-slot>
```

The GSC first tries to match by client slot, then falls back to GUID.

For clear visibility, the bridge writes:

```text
sebz_visibility_request=<timestamp>:<network-guid-hex>:<client-slot>
```

The GSC also registers `+actionslot 3` with `notifyOnPlayerCommand`, so players can toggle it without IW4MAdmin chat commands.

## Adding A New Command

1. Add a new command class under `src/SebzGscBridge/Commands`.
2. Register it in `Plugin.RegisterDependencies`.
3. Pick a script-specific request dvar.
4. Add a GSC monitor loop that consumes that dvar and clears it.
5. Keep command permissions conservative by default.

## HUD Limitation

`createIcon(...); setTargetEnt(player);` works for target-attached waypoint-style markers.

Using arbitrary shader rectangles as target-attached HUD elements was tested for box ESP and did not render in-game. A true rectangular box likely needs an IW4X client-side rendering hook or a server-side world-to-screen primitive that is not currently used here.
