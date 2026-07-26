# 00-xrd-playground Configuration Guide

This document preserves the original reference scenario for this topology, provided for you to manually configure step-by-step on blank XRd nodes[cite: 5]. The topology itself no longer references `startup-config`; after running `make LAB=00-xrd-playground deploy`, all protocol, data interface IP, loopback, and user account configurations are up to you[cite: 5].

The reference scenario consists of CE static routing + provider core IS-IS Level-2 + MPLS LDP[cite: 5]. It demonstrates label forwarding only and does not establish VRFs, MP-BGP, or L3VPNs[cite: 5].

## 1. Topology and Addressing Plan

```text
CE-A Gi0/0/0/0 -- PE-1 Gi0/0/0/0    PE-1 Gi0/0/0/1 -- P-1 Gi0/0/0/0
P-1  Gi0/0/0/1 -- P-2  Gi0/0/0/0    P-2  Gi0/0/0/1 -- PE-2 Gi0/0/0/0
PE-2 Gi0/0/0/1 -- CE-B Gi0/0/0/0

```

| Link / node | IPv4 address |
| --- | --- |
| CE-A Gi0/0/0/0 — PE-1 Gi0/0/0/0 | `192.0.2.0/31` — `192.0.2.1/31` |
| PE-1 Gi0/0/0/1 — P-1 Gi0/0/0/0 | `10.0.0.0/31` — `10.0.0.1/31` |
| P-1 Gi0/0/0/1 — P-2 Gi0/0/0/0 | `10.0.0.2/31` — `10.0.0.3/31` |
| P-2 Gi0/0/0/1 — PE-2 Gi0/0/0/0 | `10.0.0.4/31` — `10.0.0.5/31` |
| PE-2 Gi0/0/0/1 — CE-B Gi0/0/0/0 | `192.0.2.2/31` — `192.0.2.3/31` |
| PE-1 / P-1 / P-2 / PE-2 Loopback0 | `10.255.0.1` / `.2` / `.3` / `.4` `/32` |
| CE-A / CE-B Loopback0 | `198.51.100.1/32` / `198.51.100.2/32` |
|  |  |

The IS-IS instance name is `CORE`, the area is `49.0001`, and it uses Level-2 only. The NET for each node is as follows:

| Node | NET |
| --- | --- |
| PE-1 | `49.0001.0102.5500.0001.00` |
| P-1 | `49.0001.0102.5500.0002.00` |
| P-2 | `49.0001.0102.5500.0003.00` |
| PE-2 | `49.0001.0102.5500.0004.00` |
|  |  |

## 2. Launching and Operation

Start the lab in the project root directory:

```bash
make LAB=00-xrd-playground deploy
make LAB=00-xrd-playground cli NODE=pe-1

```

After entering the XR CLI, use `configure` to enter configuration mode, and use `commit` after completing a section to write to the running configuration. Each of the code blocks below can be pasted in configuration mode; please adjust node names according to the actual node. On first boot without custom management settings, the most direct way to operate is `make ... cli`.

## 3. Common Basic Configuration (Optional)

If local accounts and SSH are required, execute the following configurations on each device individually, changing the hostname to that node's name. This is not a prerequisite for topology operation; the management interface VRF, IP, and default route should also be configured separately according to your environment.

```xr
hostname pe-1
username clab
 group root-lr
 group cisco-support
 secret clab@123
!
line default
 transport input ssh
!
ssh server v2

```

To add the XR management interface to a management VRF, you can verify the VRF name created by the system first, then configure `MgmtEth0/RP0/CPU0/0` yourself. `mgmt-ipv4` in Containerlab YAML is container management network data, not an XR IPv4 configuration automatically acquired by this interface.

## 4. CE Configuration

### CE-A

```xr
hostname ce-a
!
interface GigabitEthernet0/0/0/0
 description CE-A-to-PE-1
 ipv4 address 192.0.2.0 255.255.255.254
!
interface Loopback0
 description CE-A-test-loopback
 ipv4 address 198.51.100.1 255.255.255.255
!
router static
 address-family ipv4 unicast
  0.0.0.0/0 GigabitEthernet0/0/0/0 192.0.2.1
 !
!
commit

```

### CE-B

```xr
hostname ce-b
!
interface GigabitEthernet0/0/0/0
 description CE-B-to-PE-2
 ipv4 address 192.0.2.3 255.255.255.254
!
interface Loopback0
 description CE-B-test-loopback
 ipv4 address 198.51.100.2 255.255.255.255
!
router static
 address-family ipv4 unicast
  0.0.0.0/0 GigabitEthernet0/0/0/0 192.0.2.2
 !
!
commit

```

## 5. Provider Core Configuration

PEs redistribute static routes connected to CE loopbacks into IS-IS; P routers only participate in IS-IS and LDP. All core links are point-to-point and have LDP/IGP synchronization enabled.

### PE-1

```xr
hostname pe-1
!
interface GigabitEthernet0/0/0/0
 description PE-1-to-CE-A
 ipv4 address 192.0.2.1 255.255.255.254
!
interface GigabitEthernet0/0/0/1
 description PE-1-to-P-1
 ipv4 address 10.0.0.0 255.255.255.254
!
interface Loopback0
 ipv4 address 10.255.0.1 255.255.255.255
!
router static
 address-family ipv4 unicast
  198.51.100.1/32 GigabitEthernet0/0/0/0 192.0.2.0
 !
!
router isis CORE
 net 49.0001.0102.5500.0001.00
 is-type level-2-only
 log-adjacency-changes
 mpls ldp sync
 address-family ipv4 unicast
  metric-style wide
  redistribute static
 !
 interface Loopback0
  address-family ipv4 unicast
   passive
  !
 !
 interface GigabitEthernet0/0/0/1
  point-to-point
  address-family ipv4 unicast
  !
 !
!
mpls ldp
 router-id 10.255.0.1
 interface GigabitEthernet0/0/0/1
 !
!
commit

```

### P-1

```xr
hostname p-1
!
interface GigabitEthernet0/0/0/0
 description P-1-to-PE-1
 ipv4 address 10.0.0.1 255.255.255.254
!
interface GigabitEthernet0/0/0/1
 description P-1-to-P-2
 ipv4 address 10.0.0.2 255.255.255.254
!
interface Loopback0
 ipv4 address 10.255.0.2 255.255.255.255
!
router isis CORE
 net 49.0001.0102.5500.0002.00
 is-type level-2-only
 log-adjacency-changes
 address-family ipv4 unicast
  metric-style wide
  mpls ldp sync
 !
 interface Loopback0
  address-family ipv4 unicast
   passive
  !
 !
 interface GigabitEthernet0/0/0/0
  point-to-point
  address-family ipv4 unicast
  !
 !
 interface GigabitEthernet0/0/0/1
  point-to-point
  address-family ipv4 unicast
  !
 !
!
mpls ldp
 router-id 10.255.0.2
 interface GigabitEthernet0/0/0/0
 !
 interface GigabitEthernet0/0/0/1
 !
!
commit

```

### P-2

```xr
hostname p-2
!
interface GigabitEthernet0/0/0/0
 description P-2-to-P-1
 ipv4 address 10.0.0.3 255.255.255.254
!
interface GigabitEthernet0/0/0/1
 description P-2-to-PE-2
 ipv4 address 10.0.0.4 255.255.255.254
!
interface Loopback0
 ipv4 address 10.255.0.3 255.255.255.255
!
router isis CORE
 net 49.0001.0102.5500.0003.00
 is-type level-2-only
 log-adjacency-changes
 address-family ipv4 unicast
  metric-style wide
  mpls ldp sync
 !
 interface Loopback0
  address-family ipv4 unicast
   passive
  !
 !
 interface GigabitEthernet0/0/0/0
  point-to-point
  address-family ipv4 unicast
  !
 !
 interface GigabitEthernet0/0/0/1
  point-to-point
  address-family ipv4 unicast
  !
 !
!
mpls ldp
 router-id 10.255.0.3
 interface GigabitEthernet0/0/0/0
 !
 interface GigabitEthernet0/0/0/1
 !
!
commit

```

### PE-2

```xr
hostname pe-2
!
interface GigabitEthernet0/0/0/0
 description PE-2-to-P-2
 ipv4 address 10.0.0.5 255.255.255.254
!
interface GigabitEthernet0/0/0/1
 description PE-2-to-CE-B
 ipv4 address 192.0.2.2 255.255.255.254
!
interface Loopback0
 ipv4 address 10.255.0.4 255.255.255.255
!
router static
 address-family ipv4 unicast
  198.51.100.2/32 GigabitEthernet0/0/0/1 192.0.2.3
 !
!
router isis CORE
 net 49.0001.0102.5500.0004.00
 is-type level-2-only
 log-adjacency-changes
 mpls ldp sync
 address-family ipv4 unicast
  metric-style wide
  redistribute static
 !
 interface Loopback0
  address-family ipv4 unicast
   passive
  !
 !
 interface GigabitEthernet0/0/0/0
  point-to-point
  address-family ipv4 unicast
  !
 !
!
mpls ldp
 router-id 10.255.0.4
 interface GigabitEthernet0/0/0/0
 !
!
commit

```

## 6. Verification Sequence and Expected Results

First check IS-IS and LDP adjacencies on each core router: PEs have one neighbor each, and Ps have two neighbors each.

```xr
show isis adjacency
show mpls ldp neighbor
show route 198.51.100.1/32
show route 198.51.100.2/32
show mpls forwarding

```

Finally test from CE-A:

```xr
ping ipv4 198.51.100.2 source 198.51.100.1 count 5

```

After completing the reference scenario, you can also run `make LAB=00-xrd-playground verify` from the host. This verification script will check all expected adjacencies, PE routes, label forwarding table entries, and the ping above.

## 7. Saving Your Practice Results

To save the current configuration for future reference, run from the project root directory:

```bash
make LAB=00-xrd-playground save-configs

```

The output will be written to the unversioned `snapshots/` directory; it will not become the startup configuration for the next deployment.

```