# Install

## Requirements

- IW4X dedicated server.
- IW4MAdmin installed and monitoring the server.
- .NET SDK capable of building the IW4MAdmin plugin target framework.

## Build The Bridge

From the repository root:

```bash
dotnet build SebzIw4xGsc.slnx -c Release
```

## Install The IW4MAdmin Plugin

Copy the built DLL into the IW4MAdmin plugin directory:

```bash
cp src/SebzGscBridge/bin/Release/net10.0/SebzGscBridge.dll /path/to/iw4madmin/Plugins/
```

Restart IW4MAdmin after installing or updating the DLL.

## Install ESP

Copy the ESP GSC onto any IW4X server where `!esp` should work:

```bash
cp gsc/esp/sebz_esp.gsc /path/to/iw4x/userraw/scripts/
```

Restart the IW4X server or wait for a map reload so the script compiles and runs.

The command is:

```text
!esp
```

Alias:

```text
!wh
```

Minimum IW4MAdmin permission:

```text
SeniorAdmin
```

Owners are above `SeniorAdmin` and are allowed.

## Install Clear Visibility

Copy the visibility GSC onto any IW4X server where clear visibility should work:

```bash
cp gsc/visibility/sebz_visibility.gsc /path/to/iw4x/userraw/scripts/
```

Restart the IW4X server or wait for a map reload so the script compiles and runs.

Players can toggle clear visibility with:

```text
!vis
```

Alias:

```text
!visibility
```

They can also press top-row `3`, which is `+actionslot 3` in IW4X.

Minimum IW4MAdmin permission:

```text
User
```

The script toggles `r_fog`, `r_fullbright`, `r_glow`, and `r_distortion`.

## ESP Dvars

```text
sebz_esp_request
```

Bridge-to-GSC request dvar. The plugin writes to it; the GSC consumes and clears it.

```text
sebz_esp_debug
```

Set to `1` to print debug messages and show enable/disable text. Defaults to `0` in the public script.

## Install Rust Snipers Only

Copy:

```bash
cp gsc/rust-snipers/rust_snipers.gsc /path/to/iw4x/userraw/scripts/
```

Use `examples/rust-snipers.server.cfg` as a starting point. Replace all server identity, password, logging, and bot settings with values appropriate for the target server.

## Updating

1. Build the bridge.
2. Replace `SebzGscBridge.dll` in IW4MAdmin.
3. Replace changed GSC files on the relevant IW4X servers.
4. Restart IW4MAdmin if the DLL changed.
5. Restart the IW4X server or rotate maps if GSC files changed.
