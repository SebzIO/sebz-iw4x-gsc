# Sebz IW4X GSC

Custom IW4X GSC scripts and the IW4MAdmin bridge plugin used to expose admin-only commands for those scripts.

## Contents

- `src/SebzGscBridge` - IW4MAdmin plugin DLL source.
- `gsc/esp/sebz_esp.gsc` - Senior Administrator+ ESP observer marker script.
- `gsc/spectator/sebz_spectator.gsc` - Senior Administrator+ spectator toolkit target panel script.
- `gsc/visibility/sebz_visibility.gsc` - public clear visibility mode script.
- `gsc/rust-snipers/rust_snipers.gsc` - Rust snipers-only rules script.
- `examples/` - example server config snippets.
- `docs/install.md` - install and update notes.

## Current Features

### ESP Observer

Adds `!esp` with alias `!wh` through IW4MAdmin.

The command is restricted to `SeniorAdmin` and above. It toggles a private target marker overlay for the command executor by setting a server dvar that `sebz_esp.gsc` watches.

Use `!whref <player>` or `!espref <player>` to color ESP markers from that player's team perspective. This is useful while using MW2's built-in spectator mode, because the followed spectator target is not exposed to server-side GSC. Use `!whclear` or `!espclear` to return to the default self/team perspective.

Known limitation: current server-side GSC rendering can reliably attach waypoint-style markers to players. True rectangular player boxes were tested and did not render through this GSC HUD path.

### Spectator Toolkit

Adds `!watch <player>` with alias `!obs <player>` through IW4MAdmin.

The command is restricted to `SeniorAdmin` and above. It toggles a private marker and live info panel for the selected player, showing their team, life state, current weapon, and health. This is the first slice of the spectator toolkit and intentionally avoids forcing camera state until that behavior is verified per-server.

### Rust Snipers Only

Enforces a sniper-only Rust ruleset, keeps pistols empty for knife use, disables deathstreaks, and preserves selected sniper variants when possible.

### Clear Visibility

Adds `!vis` with alias `!visibility` through IW4MAdmin, and also lets players toggle the same mode with the top-row `3` key.

The mode toggles client-side visual settings intended to reduce haze and increase map clarity:

- `r_fog`
- `r_fullbright`
- `r_glow`
- `r_distortion`

This is available to all players.

## Build

```bash
dotnet build SebzIw4xGsc.slnx -c Release
```

The bridge DLL is produced at:

```text
src/SebzGscBridge/bin/Release/net10.0/SebzGscBridge.dll
```

## Package A Release

```bash
scripts/package-release.sh
```

Release files are written to:

```text
artifacts/release/
```

## Quick Install

Copy the bridge DLL into IW4MAdmin:

```bash
cp src/SebzGscBridge/bin/Release/net10.0/SebzGscBridge.dll /path/to/iw4madmin/Plugins/
```

Copy GSC scripts into each IW4X server that should use them:

```bash
cp gsc/esp/sebz_esp.gsc /path/to/iw4x/userraw/scripts/
cp gsc/spectator/sebz_spectator.gsc /path/to/iw4x/userraw/scripts/
cp gsc/visibility/sebz_visibility.gsc /path/to/iw4x/userraw/scripts/
```

Restart IW4MAdmin after replacing the DLL. Restart or rotate maps on the IW4X server after replacing GSC scripts.

See [docs/install.md](docs/install.md) for more detail.
