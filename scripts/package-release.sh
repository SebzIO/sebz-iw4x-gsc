#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
artifact_dir="$root_dir/artifacts/release"

rm -rf "$artifact_dir"
mkdir -p "$artifact_dir/Plugins" "$artifact_dir/scripts"

dotnet build "$root_dir/SebzIw4xGsc.slnx" -c Release

cp "$root_dir/src/SebzGscBridge/bin/Release/net10.0/SebzGscBridge.dll" "$artifact_dir/Plugins/"
cp "$root_dir/gsc/esp/sebz_esp.gsc" "$artifact_dir/scripts/"
cp "$root_dir/gsc/spectator/sebz_spectator.gsc" "$artifact_dir/scripts/"
cp "$root_dir/gsc/visibility/sebz_visibility.gsc" "$artifact_dir/scripts/"
cp "$root_dir/gsc/rust-snipers/rust_snipers.gsc" "$artifact_dir/scripts/"
cp "$root_dir/README.md" "$artifact_dir/"
cp "$root_dir/docs/install.md" "$artifact_dir/INSTALL.md"

echo "Packaged release files in $artifact_dir"
