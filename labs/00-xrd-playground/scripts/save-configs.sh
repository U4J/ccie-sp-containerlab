#!/usr/bin/env bash
set -euo pipefail

lab_name="00-xrd-playground"
nodes=(ce-a pe-1 p-1 p-2 pe-2 ce-b)

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lab_dir="$(cd "$script_dir/.." && pwd)"
snapshots_dir="$lab_dir/snapshots"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/00-xrd-playground-save-configs.XXXXXX")"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$snapshots_dir"

for node in "${nodes[@]}"; do
  container="clab-${lab_name}-${node}"
  raw_config="$tmp_dir/${node}.raw"
  saved_config="$tmp_dir/${node}.cfg"

  [[ "$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)" == "true" ]] || {
    echo "FAIL: $container is not running" >&2
    exit 1
  }

  docker exec "$container" /pkg/bin/xr_cli -n "show running-config" >"$raw_config"
  awk '/^!! / { next } { sub(/\r$/, ""); print }' "$raw_config" >"$saved_config"

  grep -qx "hostname $node" "$saved_config" && grep -qx "end" "$saved_config" || {
    echo "FAIL: exported configuration for $node is incomplete" >&2
    exit 1
  }
done

for node in "${nodes[@]}"; do
  install -m 0644 "$tmp_dir/${node}.cfg" "$snapshots_dir/${node}.cfg"
  echo "Saved $snapshots_dir/${node}.cfg"
done
