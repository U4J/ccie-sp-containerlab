# CCIE-SP Containerlab Labs

This repository breaks exercises down into labs that can be independently deployed, verified, and version-controlled according to the CCIE-SP v5.1 roadmap. Each topic is placed in its own `labs/<stage>-<topic>/` directory to prevent topology, IP planning, and configurations from overwriting one another.

For the complete blueprint mapping, please see [docs/blueprint-map.md](docs/blueprint-map.md).

## Lab Index

| Stage | Directory | Topic | Status |
| --- | --- | --- | --- |
| 00 | [00-xrd-playground](labs/00-xrd-playground/README.md) | Basic MPLS forwarding, IS-IS, LDP | Implemented |
| 01 | [01-isis-ecmp](labs/01-isis-ecmp/README.md) | IS-IS dual-stack, ECMP, convergence | Planned |
| 02 | [02-ospf-bfd-lfa](labs/02-ospf-bfd-lfa/README.md) | OSPFv2/v3, BFD, LFA | Planned |
| 03 | [03-mpls-ldp-failover](labs/03-mpls-ldp-failover/README.md) | MPLS LDP failover | Planned |
| 04 | [04-mpbgp-rr](labs/04-mpbgp-rr/README.md) | iBGP, RR, MP-BGP, policy | Planned |
| 05 | [05-mpls-l3vpn](labs/05-mpls-l3vpn/README.md) | MPLS L3VPN, Inter-AS, CSC | Planned |
| 06 | [06-evpn-vpls](labs/06-evpn-vpls/README.md) | VPWS, VPLS, EVPN | Planned |
| 07 | [07-multicast](labs/07-multicast/README.md) | Multicast, PIM, Anycast RP, mLDP | Planned |
| 08 | [08-sr-mpls-te](labs/08-sr-mpls-te/README.md) | SR-MPLS, SR-TE, TI-LFA, PCEP | Planned |
| 09 | [09-srv6-usid](labs/09-srv6-usid/README.md) | SRv6, uSID, interworking | Planned |
| 10 | [10-qos-security](labs/10-qos-security/README.md) | QoS, CoPP, uRPF, RPKI, FlowSpec | Planned |
| 11 | [11-telemetry-automation](labs/11-telemetry-automation/README.md) | Telemetry, NETCONF/RESTCONF, Python | Planned |
| 12 | [12-mixed-troubleshooting](labs/12-mixed-troubleshooting/README.md) | Mixed troubleshooting scenarios | Planned |

Only labs marked as "Implemented" currently feature topology files, configuration, and verification scripts; the remaining directories only retain a placeholder README for future implementation.

## Currently Available: 00 XRd MPLS Playground

```text
CE-A -- PE-1 -- P-1 -- P-2 -- PE-2 -- CE-B
```

This lab uses `docker.io/sbezverk/xrd-control-plane:26.2.1`. The core PE/P routers use IS-IS and LDP; CE-A and CE-B use static default routes and verify MPLS forwarding via loopbacks on both ends. For complete IP planning and verification details, please refer to the [00-xrd-playground README](labs/00-xrd-playground/README.md).

Please explicitly specify the `LAB` variable to match the directory name:

```bash
make LAB=00-xrd-playground preflight
make LAB=00-xrd-playground deploy
make LAB=00-xrd-playground verify
make LAB=00-xrd-playground cli NODE=pe-1
```

The initial boot of XRd takes about one to several minutes. `verify` will check the XR CLI, IS-IS/LDP adjacencies, MPLS forwarding entries, and connectivity from CE-A to CE-B.

## Creating the Next Lab

Each lab should maintain the following directory structure; do not reuse topology or configuration files from other labs:

```text
labs/<stage>-<topic>/
├── README.md
├── topology.clab.yml
├── CONFIGURATION.md       # Optional: manual setup guide or reference config
├── configs/               # Optional: version-controlled startup config
└── scripts/
    └── verify.sh
```

The shared `scripts/save-configs.sh` script is called by the Makefile in the root directory. It reads the lab name and node list from each lab's `topology.clab.yml` and exports the XRd running-config to that lab's `snapshots/` folder.

Prior to implementation, the README should outline objectives, topology, IP/ASN planning, expected verification results, and intentionally injected faults (if any). If a lab is built automatically, a version-controlled deterministic startup config can be placed under `configs/`; if the objective is manual practice, do not reference a `startup-config` inside the topology file, and document reference configurations in `CONFIGURATION.md`. Running configs exported during practice should be placed in the git-ignored `snapshots/` folder.

## Host Preparation

Docker Engine, Containerlab, `make`, and a user account with Docker execution privileges are required:

```bash
sudo apt update
sudo apt install -y ca-certificates curl git make
curl -sL https://get.containerlab.dev | sudo -E bash
sudo usermod -aG docker "$USER"
newgrp docker
docker info
containerlab version
```

XRd requires a higher limit for inotify instances:

```bash
echo 'fs.inotify.max_user_instances=64000' | \
  sudo tee /etc/sysctl.d/99-xrd.conf
sudo sysctl --system
```

## Common Operations

Replace `<lab-name>` in the commands below with the actual name of an implemented lab directory:

```bash
make LAB=<lab-name> inspect
make LAB=<lab-name> save-configs
make LAB=<lab-name> destroy
make LAB=<lab-name> clean
```

`destroy` stops and removes the lab containers; `clean` removes them along with the Containerlab lab state.
