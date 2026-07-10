#!/usr/bin/env bash
set -euo pipefail

topology_file="${1:-}"

if [[ -z "$topology_file" || ! -f "$topology_file" ]]; then
  echo "Usage: $0 <topology.clab.yml>" >&2
  exit 2
fi

topology_file="$(cd "$(dirname "$topology_file")" && pwd)/$(basename "$topology_file")"
lab_dir="$(dirname "$topology_file")"

# Containerlab uses the topology's `name` in container names.  Node entries are
# intentionally read from the topology so this one script works for every XRd lab.
lab_name="$(awk -F: '/^name:[[:space:]]*/ { value=$2; sub(/^[[:space:]]*/, "", value); sub(/[[:space:]]*$/, "", value); print value; exit }' "$topology_file")"
mapfile -t nodes < <(
  awk '
    /^  nodes:[[:space:]]*$/ { in_nodes=1; next }
    in_nodes && /^  (defaults|links):/ { exit }
    in_nodes && /^    [[:alnum:]_.-]+:[[:space:]]*$/ {
      node=$1
      sub(/:$/, "", node)
      print node
    }
  ' "$topology_file"
)

if [[ -z "$lab_name" || ${#nodes[@]} -eq 0 ]]; then
  echo "FAIL: could not read a lab name and nodes from $topology_file" >&2
  exit 1
fi

snapshots_dir="$lab_dir/snapshots"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/${lab_name}-save-configs.XXXXXX")"

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
