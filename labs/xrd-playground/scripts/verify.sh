#!/usr/bin/env bash
set -euo pipefail

lab_name="xrd-playground"
nodes=(xrd1 xrd2)
declare -A mgmt_ips=(
  [xrd1]="172.31.20.11"
  [xrd2]="172.31.20.12"
)
max_attempts=36
wait_seconds=5

run_xr() {
  local node="$1"
  shift
  docker exec "clab-${lab_name}-${node}" /pkg/bin/xr_cli -n "$@"
}

for node in "${nodes[@]}"; do
  container="clab-${lab_name}-${node}"
  if ! docker inspect "$container" >/dev/null 2>&1; then
    echo "FAIL: $container does not exist" >&2
    exit 1
  fi
  if [[ "$(docker inspect -f '{{.State.Running}}' "$container")" != "true" ]]; then
    echo "FAIL: $container is not running" >&2
    docker logs --tail 100 "$container" >&2 || true
    exit 1
  fi
done

echo "Waiting for both XR CLI instances..."
for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  ready=0
  for node in "${nodes[@]}"; do
    if run_xr "$node" "show version" 2>/dev/null |
       grep -q "Cisco IOS XR Software, Version 26.2.1" &&
       run_xr "$node" "show running-config interface MgmtEth0/RP0/CPU0/0" \
         2>/dev/null |
       grep -q "ipv4 address ${mgmt_ips[$node]} "; then
      ((ready += 1))
    fi
  done

  if ((ready == ${#nodes[@]})); then
    break
  fi

  if ((attempt == max_attempts)); then
    echo "FAIL: XR CLI was not ready after $((max_attempts * wait_seconds)) seconds" >&2
    for node in "${nodes[@]}"; do
      docker logs --tail 100 "clab-${lab_name}-${node}" >&2 || true
    done
    exit 1
  fi

  printf 'Attempt %d/%d: %d/%d ready\n' \
    "$attempt" "$max_attempts" "$ready" "${#nodes[@]}"
  sleep "$wait_seconds"
done

for node in "${nodes[@]}"; do
  echo
  echo "=== $node ==="
  run_xr "$node" "show version" |
    grep -E "Cisco IOS XR Software|ios uptime|XRd Control Plane"
  run_xr "$node" "show ipv4 interface brief" |
    grep -E "${mgmt_ips[$node]}|GigabitEthernet0/0/0/0"
done

echo
echo "PASS: xrd1 and xrd2 are running and their XR CLI is ready"
