# XRd MPLS Manual Configuration Playground

This lab uses Cisco XRd Control Plane to build a minimal MPLS provider core:

```text
CE-A -- PE-1 -- P-1 -- P-2 -- PE-2 -- CE-B
```

This lab **does not load a startup configuration**. After nodes boot up, please perform manual configuration based on your practice goals. The original complete reference configuration has been compiled into [CONFIGURATION.md](CONFIGURATION.md). That document uses CE static routes, provider core IS-IS, and LDP as an example, ultimately allowing CE-A's `198.51.100.1/32` to connect to CE-B's `198.51.100.2/32` through the MPLS core. The example does not use VRF, MP-BGP, or L3VPN.

| Node | Container | Container management IP | Example Loopback / test IP |
| --- | --- | --- | --- |
| CE-A | `clab-00-xrd-playground-ce-a` | `172.31.20.11` | `198.51.100.1/32` |
| PE-1 | `clab-00-xrd-playground-pe-1` | `172.31.20.12` | `10.255.0.1/32` |
| P-1 | `clab-00-xrd-playground-p-1` | `172.31.20.13` | `10.255.0.2/32` |
| P-2 | `clab-00-xrd-playground-p-2` | `172.31.20.14` | `10.255.0.3/32` |
| PE-2 | `clab-00-xrd-playground-pe-2` | `172.31.20.15` | `10.255.0.4/32` |
| CE-B | `clab-00-xrd-playground-ce-b` | `172.31.20.16` | `198.51.100.2/32` |

`mgmt-ipv4` only provides the address for the Containerlab container management network. Since XR configuration is no longer injected, it does not mean that XR's `MgmtEth0/RP0/CPU0/0` already has an IP address. It is recommended to enter the node via `make ... cli` or `docker exec` and configure it yourself. If you wish to use SSH, please create a user account, enable SSH, and configure the management interface first.

```bash
make LAB=00-xrd-playground deploy
make LAB=00-xrd-playground cli NODE=pe-1
```

After completing the reference scenario in the [configuration guide](CONFIGURATION.md), you can run:

```bash
make LAB=00-xrd-playground verify
```

The verification script will check the XR CLI, number of IS-IS/LDP neighbors, routes for both CE loopbacks, and pings from CE-A to CE-B. Verification failure is expected behavior if the corresponding configurations are incomplete. You can also inspect manually:

```bash
make LAB=00-xrd-playground cli NODE=pe-1
show isis adjacency
show mpls ldp neighbor
show mpls forwarding
show route 198.51.100.2/32
```

If you want to save the modified running config from your lab session:

```bash
make LAB=00-xrd-playground save-configs
```

Files will be written to the git-ignored `snapshots/` directory. To stop the lab, use `make destroy`; to also remove the Containerlab lab state, use `make clean`. Please stop and clean up the old lab before redeploying to avoid inheriting the configuration state of existing containers.
