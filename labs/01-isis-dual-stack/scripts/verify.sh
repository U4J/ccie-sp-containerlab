#!/usr/bin/env bash
set -euo pipefail

lab_name="ccie-sp-isis"
nodes=(pe1 p1 p2 pe2)
max_attempts=30

run_vtysh() {
  local node="$1"
  shift
  docker exec "clab-${lab_name}-${node}" vtysh "$@"
}

for node in "${nodes[@]}"; do
  if ! docker inspect "clab-${lab_name}-${node}" >/dev/null 2>&1; then
    echo "FAIL: clab-${lab_name}-${node} is not running" >&2
    exit 1
  fi
done

echo "Waiting for IS-IS and dual-stack reachability..."
for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  if run_vtysh pe1 -c "show isis neighbor" | grep -q "p1" &&
     run_vtysh pe1 -c "show isis neighbor" | grep -q "p2" &&
     docker exec "clab-${lab_name}-pe1" ping -c 1 -W 1 10.255.0.4 >/dev/null 2>&1 &&
     docker exec "clab-${lab_name}-pe1" ping -6 -c 1 -W 1 2001:db8:0:4::1 >/dev/null 2>&1; then
    break
  fi

  if ((attempt == max_attempts)); then
    echo "FAIL: topology did not converge within ${max_attempts} seconds" >&2
    run_vtysh pe1 -c "show isis neighbor" || true
    run_vtysh pe1 -c "show ip route isis" || true
    run_vtysh pe1 -c "show ipv6 route isis" || true
    exit 1
  fi
  sleep 1
done

ipv4_paths="$(
  run_vtysh pe1 -c "show ip route 10.255.0.4/32" |
    grep -c "weight 1" || true
)"
ipv6_paths="$(
  run_vtysh pe1 -c "show ipv6 route 2001:db8:0:4::1/128" |
    grep -c "weight 1" || true
)"

if ((ipv4_paths < 2)); then
  echo "FAIL: expected two IPv4 ECMP paths, found ${ipv4_paths}" >&2
  exit 1
fi

if ((ipv6_paths < 2)); then
  echo "FAIL: expected two IPv6 ECMP paths, found ${ipv6_paths}" >&2
  exit 1
fi

echo "PASS: all IS-IS adjacencies converged"
echo "PASS: pe1 reaches pe2 over IPv4 and IPv6"
echo "PASS: pe1 installed two IPv4 and two IPv6 ECMP paths"
