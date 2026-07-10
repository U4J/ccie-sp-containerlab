#!/usr/bin/env bash
set -euo pipefail

lab_name="00-xrd-playground"
nodes=(ce-a pe-1 p-1 p-2 pe-2 ce-b)
core_nodes=(pe-1 p-1 p-2 pe-2)
declare -A mgmt_ips=(
  [ce-a]="172.31.20.11"
  [pe-1]="172.31.20.12"
  [p-1]="172.31.20.13"
  [p-2]="172.31.20.14"
  [pe-2]="172.31.20.15"
  [ce-b]="172.31.20.16"
)
declare -A expected_isis_neighbors=(
  [pe-1]=1
  [p-1]=2
  [p-2]=2
  [pe-2]=1
)
declare -A expected_ldp_neighbors=(
  [pe-1]=1
  [p-1]=2
  [p-2]=2
  [pe-2]=1
)
max_attempts=36
wait_seconds=5

run_xr() {
  local node="$1"
  shift
  docker exec "clab-${lab_name}-${node}" /pkg/bin/xr_cli -n "$@"
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for node in "${nodes[@]}"; do
  container="clab-${lab_name}-${node}"
  docker inspect "$container" >/dev/null 2>&1 || fail "$container does not exist"
  [[ "$(docker inspect -f '{{.State.Running}}' "$container")" == "true" ]] || \
    fail "$container is not running"
done

echo "Waiting for all XR CLI instances..."
for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  ready=0
  for node in "${nodes[@]}"; do
    if run_xr "$node" "show version" 2>/dev/null | grep -q "Cisco IOS XR Software" &&
       run_xr "$node" "show running-config interface MgmtEth0/RP0/CPU0/0" 2>/dev/null |
         grep -q "ipv4 address ${mgmt_ips[$node]} "; then
      ((ready += 1))
    fi
  done

  if ((ready == ${#nodes[@]})); then
    break
  fi
  ((attempt < max_attempts)) || fail "XR CLI was not ready after $((max_attempts * wait_seconds)) seconds"
  printf 'Attempt %d/%d: %d/%d ready\n' "$attempt" "$max_attempts" "$ready" "${#nodes[@]}"
  sleep "$wait_seconds"
done

for node in "${core_nodes[@]}"; do
  isis_neighbors=$(run_xr "$node" "show isis adjacency" | grep -c ' Up ' || true)
  ((isis_neighbors == expected_isis_neighbors[$node])) ||
    fail "$node has $isis_neighbors IS-IS neighbors; expected ${expected_isis_neighbors[$node]}"

  ldp_neighbors=$(run_xr "$node" "show mpls ldp neighbor" | grep -c 'State: Oper' || true)
  ((ldp_neighbors == expected_ldp_neighbors[$node])) ||
    fail "$node has $ldp_neighbors LDP neighbors; expected ${expected_ldp_neighbors[$node]}"
done

run_xr pe-1 "show route 198.51.100.2/32" | grep -q "198.51.100.2/32" ||
  fail "PE-1 has no route to CE-B loopback"
run_xr pe-2 "show route 198.51.100.1/32" | grep -q "198.51.100.1/32" ||
  fail "PE-2 has no route to CE-A loopback"
run_xr pe-1 "show mpls forwarding" | grep -q "198.51.100.2/32" ||
  fail "PE-1 has no MPLS forwarding entry for CE-B loopback"
run_xr ce-a "ping ipv4 198.51.100.2 source 198.51.100.1 count 5" |
  grep -q "Success rate is 100 percent" || fail "CE-A cannot reach CE-B loopback"

echo "PASS: IS-IS, LDP, labeled core forwarding, and CE-A-to-CE-B reachability are working"
