#!/usr/bin/env bash
set -euo pipefail

lab_name="01-isis-ecmp"
nodes=(r1 r2 r3 r4)
max_attempts=36
wait_seconds=5
mode="${1:-baseline}"

run_xr() {
  local node="$1"
  shift
  docker exec "clab-${lab_name}-${node}" /pkg/bin/xr_cli -n "$@"
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_contains() {
  local output="$1"
  local expected="$2"
  local message="$3"
  [[ "$output" == *"$expected"* ]] || fail "$message (missing: $expected)"
}

require_not_contains() {
  local output="$1"
  local unexpected="$2"
  local message="$3"
  [[ "$output" != *"$unexpected"* ]] || fail "$message (unexpected: $unexpected)"
}

adjacency_count() {
  local node="$1"
  run_xr "$node" "show isis adjacency" | grep -Eic '[[:space:]]up[[:space:]]' || true
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
    if run_xr "$node" "show version" 2>/dev/null | grep -q "Cisco IOS XR Software"; then
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

case "$mode" in
  baseline)
    for node in "${nodes[@]}"; do
      neighbors="$(adjacency_count "$node")"
      ((neighbors == 2)) || fail "$node has $neighbors IS-IS adjacencies; expected 2"
    done

    r1_ipv4_route="$(run_xr r1 "show route 10.255.1.4/32")"
    require_contains "$r1_ipv4_route" "10.1.12.1" "R1 IPv4 ECMP route does not use R2"
    require_contains "$r1_ipv4_route" "10.1.13.1" "R1 IPv4 ECMP route does not use R3"

    r1_ipv6_route="$(run_xr r1 "show route ipv6 2001:db8:255:4::4/128")"
    require_contains "$r1_ipv6_route" "2001:db8:12::2" "R1 IPv6 ECMP route does not use R2"
    require_contains "$r1_ipv6_route" "2001:db8:13::2" "R1 IPv6 ECMP route does not use R3"

    run_xr r1 "ping ipv4 10.255.1.4 source 10.255.1.1 count 5" |
      grep -q "Success rate is 100 percent" || fail "R1 cannot reach R4's IPv4 loopback"
    run_xr r1 "ping ipv6 2001:db8:255:4::4 source 2001:db8:255:1::1 count 5" |
      grep -q "Success rate is 100 percent" || fail "R1 cannot reach R4's IPv6 loopback"

    echo "PASS: dual-stack IS-IS has two adjacencies per node, ECMP via R2 and R3, and R1-to-R4 reachability"
    ;;

  r2-r4-down)
    declare -A expected_neighbors=(
      [r1]=2
      [r2]=1
      [r3]=2
      [r4]=1
    )
    for node in "${nodes[@]}"; do
      neighbors="$(adjacency_count "$node")"
      ((neighbors == expected_neighbors[$node])) ||
        fail "$node has $neighbors IS-IS adjacencies; expected ${expected_neighbors[$node]} for an R2--R4 failure"
    done

    r1_ipv4_route="$(run_xr r1 "show route 10.255.1.4/32")"
    require_contains "$r1_ipv4_route" "10.1.13.1" "R1 IPv4 route did not converge through R3"
    require_not_contains "$r1_ipv4_route" "10.1.12.1" "R1 IPv4 route still uses R2"

    r1_ipv6_route="$(run_xr r1 "show route ipv6 2001:db8:255:4::4/128")"
    require_contains "$r1_ipv6_route" "2001:db8:13::2" "R1 IPv6 route did not converge through R3"
    require_not_contains "$r1_ipv6_route" "2001:db8:12::2" "R1 IPv6 route still uses R2"

    run_xr r1 "ping ipv4 10.255.1.4 source 10.255.1.1 count 5" |
      grep -q "Success rate is 100 percent" || fail "R1 cannot reach R4's IPv4 loopback after the failure"
    run_xr r1 "ping ipv6 2001:db8:255:4::4 source 2001:db8:255:1::1 count 5" |
      grep -q "Success rate is 100 percent" || fail "R1 cannot reach R4's IPv6 loopback after the failure"

    echo "PASS: R2--R4 failure converged to the R3 path while dual-stack reachability remained intact"
    ;;

  *)
    fail "usage: $0 [baseline|r2-r4-down]"
    ;;
esac
