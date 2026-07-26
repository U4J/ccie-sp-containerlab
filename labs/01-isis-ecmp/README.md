# IS-IS Dual-Stack ECMP and Convergence

This lab is a four-router IS-IS Level-2 core. It starts every XRd router without a
startup configuration so that the complete exercise can be configured manually.

```text
                    R2
                  /    \
                R1      R4
                  \    /
                    R3
```

R1 reaches R4 through R2 and R3. Both paths have the same IGP metric, which
installs two equal-cost next hops for both IPv4 and IPv6. Shutting the R2--R4
link removes one path while retaining reachability through R3.

## Objectives

- Configure a Level-2-only IS-IS domain with IPv4 and IPv6 enabled.
- Use IS-IS IPv6 single-topology mode, so IPv4 and IPv6 share the same graph.
- Verify two ECMP next hops from R1 to R4 for IPv4 and IPv6 loopbacks.
- Inject an R2--R4 link failure and verify IS-IS convergence to the R3 path.
- Restore the link and verify that ECMP returns.

## Deployment

From the repository root:

```bash
make LAB=01-isis-ecmp preflight
make LAB=01-isis-ecmp deploy
make LAB=01-isis-ecmp cli NODE=r1
```

The topology deliberately contains no `startup-config` references. The
`mgmt-ipv4` values in the topology only assign Containerlab management-network
addresses to the containers; they do not configure XR management interfaces.
Use `make ... cli` to access a node on first boot.

Apply the per-router reference configurations in
[CONFIGURATION.md](CONFIGURATION.md). They are intended to be pasted from XR
configuration mode and committed on each router. The configurations do not
create local users, SSH access, or management-interface addressing because none
of those are required for this routing exercise.

## Addressing Summary

| Link or node | IPv4 | IPv6 |
| --- | --- | --- |
| R1--R2 | `10.1.12.0/31` | `2001:db8:12::/64` |
| R1--R3 | `10.1.13.0/31` | `2001:db8:13::/64` |
| R2--R4 | `10.1.24.0/31` | `2001:db8:24::/64` |
| R3--R4 | `10.1.34.0/31` | `2001:db8:34::/64` |
| R1 Loopback0 | `10.255.1.1/32` | `2001:db8:255:1::1/128` |
| R2 Loopback0 | `10.255.1.2/32` | `2001:db8:255:2::2/128` |
| R3 Loopback0 | `10.255.1.3/32` | `2001:db8:255:3::3/128` |
| R4 Loopback0 | `10.255.1.4/32` | `2001:db8:255:4::4/128` |

## Verification

After all four reference configurations are committed, run the baseline check:

```bash
make LAB=01-isis-ecmp verify
```

It checks that every router has two IS-IS adjacencies, R1 has both expected
next hops to R4 for IPv4 and IPv6, and that R1 can ping R4's two loopbacks.
For manual inspection, use:

```bash
make LAB=01-isis-ecmp cli NODE=r1
```

```xr
show isis adjacency
show route 10.255.1.4/32
show route ipv6 2001:db8:255:4::4/128
show cef 10.255.1.4/32 detail
show cef ipv6 2001:db8:255:4::4/128 detail
```

For the convergence exercise, follow the failure and restoration steps in
[CONFIGURATION.md](CONFIGURATION.md#5-failure-injection-and-convergence). Once
R2's interface to R4 is shut down, run:

```bash
bash labs/01-isis-ecmp/scripts/verify.sh r2-r4-down
```

This mode expects R1 to retain only the path through R3. Restore the link, wait
for the adjacency to return, and run the normal `make ... verify` command
again.

## Saving and Cleaning Up

```bash
make LAB=01-isis-ecmp save-configs
make LAB=01-isis-ecmp destroy
make LAB=01-isis-ecmp clean
```

`save-configs` exports the running configurations to the git-ignored
`snapshots/` directory. They are not used by a later deployment.
