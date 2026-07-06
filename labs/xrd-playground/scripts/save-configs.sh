#!/usr/bin/env bash
set -euo pipefail

lab_name="xrd-playground"
nodes=(pe1 abr1 p1 abr3 pe3 abr2 p2 abr4)

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lab_dir="$(cd "$script_dir/.." && pwd)"
configs_dir="$lab_dir/configs"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/xrd-save-configs.XXXXXX")"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$configs_dir"

for node in "${nodes[@]}"; do
  container="clab-${lab_name}-${node}"
  raw_config="$tmp_dir/${node}.raw"
  saved_config="$tmp_dir/${node}.cfg"

  if [[ "$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)" != "true" ]]; then
    echo "FAIL: $container is not running" >&2
    exit 1
  fi

  docker exec "$container" \
    /pkg/bin/xr_cli -n "show running-config" >"$raw_config"

  awk '
    /^!! / { next }
    {
      sub(/\r$/, "")
      print
    }
  ' "$raw_config" >"$saved_config"

  if ! grep -qx "hostname $node" "$saved_config" ||
     ! grep -qx "end" "$saved_config"; then
    echo "FAIL: exported configuration for $node is incomplete" >&2
    exit 1
  fi
done

for node in "${nodes[@]}"; do
  install -m 0644 "$tmp_dir/${node}.cfg" "$configs_dir/${node}.cfg"
  echo "Saved $configs_dir/${node}.cfg"
done
