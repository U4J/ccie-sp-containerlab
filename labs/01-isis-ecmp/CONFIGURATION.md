# 01-isis-ecmp Configuration Guide

This guide is the manual reference configuration for the IS-IS dual-stack,
ECMP, and convergence lab. Containerlab does **not** load any part of it at
boot. Deploy the topology first, open each XR CLI with `make ... cli`, enter
`configure`, paste the matching block, and commit it.

## 1. Topology and Design

```text
                         R2
                  Gi0/0/0/0  Gi0/0/0/1
                    /                 \
       Gi0/0/0/0  R1                   R4  Gi0/0/0/1
                    \                 /
                  Gi0/0/0/1  Gi0/0/0/0
                         R3
```

All routers participate in one IS-IS instance named `CORE`, use area
`49.0001`, form Level-2-only adjacencies, and enable both address families on
every IS-IS interface. The IPv6 address family uses `single-topology`; it
therefore follows the same equal-cost graph as IPv4.

The interface metrics are left at the identical default value for all four
GigabitEthernet links. R1-to-R4 consequently has two paths of equal total cost:
R1--R2--R4 and R1--R3--R4. `maximum-paths 2` explicitly limits installed ECMP
paths to the two routes used in this exercise.

## 2. Address Plan and NETs

| Link | Left endpoint | Right endpoint |
| --- | --- | --- |
| R1--R2 | R1 `Gi0/0/0/0`: `10.1.12.0/31`, `2001:db8:12::1/64` | R2 `Gi0/0/0/0`: `10.1.12.1/31`, `2001:db8:12::2/64` |
| R1--R3 | R1 `Gi0/0/0/1`: `10.1.13.0/31`, `2001:db8:13::1/64` | R3 `Gi0/0/0/0`: `10.1.13.1/31`, `2001:db8:13::2/64` |
| R2--R4 | R2 `Gi0/0/0/1`: `10.1.24.0/31`, `2001:db8:24::1/64` | R4 `Gi0/0/0/0`: `10.1.24.1/31`, `2001:db8:24::2/64` |
| R3--R4 | R3 `Gi0/0/0/1`: `10.1.34.0/31`, `2001:db8:34::1/64` | R4 `Gi0/0/0/1`: `10.1.34.1/31`, `2001:db8:34::2/64` |

| Router | Loopback0 IPv4 | Loopback0 IPv6 | IS-IS NET |
| --- | --- | --- | --- |
| R1 | `10.255.1.1/32` | `2001:db8:255:1::1/128` | `49.0001.0000.0000.0001.00` |
| R2 | `10.255.1.2/32` | `2001:db8:255:2::2/128` | `49.0001.0000.0000.0002.00` |
| R3 | `10.255.1.3/32` | `2001:db8:255:3::3/128` | `49.0001.0000.0000.0003.00` |
| R4 | `10.255.1.4/32` | `2001:db8:255:4::4/128` | `49.0001.0000.0000.0004.00` |

## 3. Deploy and Access the Nodes

```bash
make LAB=01-isis-ecmp deploy
make LAB=01-isis-ecmp cli NODE=r1
```

Repeat the CLI command with `r2`, `r3`, and `r4`. The configurations below
include `no shutdown` for every data interface. Do not configure the XR
management interface unless you separately need SSH access.

## 4. Reference Configuration

### R1

```xr
hostname r1
!
interface GigabitEthernet0/0/0/0
 description R1-to-R2
 ipv4 address 10.1.12.0 255.255.255.254
 ipv6 address 2001:db8:12::1/64
 no shutdown
!
interface GigabitEthernet0/0/0/1
 description R1-to-R3
 ipv4 address 10.1.13.0 255.255.255.254
 ipv6 address 2001:db8:13::1/64
 no shutdown
!
interface Loopback0
 description R1-stable-router-id
 ipv4 address 10.255.1.1 255.255.255.255
 ipv6 address 2001:db8:255:1::1/128
!
router isis CORE
 net 49.0001.0000.0000.0001.00
 is-type level-2-only
 log adjacency changes
 address-family ipv4 unicast
  metric-style wide
  maximum-paths 2
 !
 address-family ipv6 unicast
  single-topology
  maximum-paths 2
 !
 interface Loopback0
  address-family ipv4 unicast
   passive
  !
  address-family ipv6 unicast
   passive
  !
 !
 interface GigabitEthernet0/0/0/0
  point-to-point
  address-family ipv4 unicast
  !
  address-family ipv6 unicast
  !
 !
 interface GigabitEthernet0/0/0/1
  point-to-point
  address-family ipv4 unicast
  !
  address-family ipv6 unicast
  !
 !
!
commit
```

### R2

```xr
hostname r2
!
interface GigabitEthernet0/0/0/0
 description R2-to-R1
 ipv4 address 10.1.12.1 255.255.255.254
 ipv6 address 2001:db8:12::2/64
 no shutdown
!
interface GigabitEthernet0/0/0/1
 description R2-to-R4
 ipv4 address 10.1.24.0 255.255.255.254
 ipv6 address 2001:db8:24::1/64
 no shutdown
!
interface Loopback0
 description R2-stable-router-id
 ipv4 address 10.255.1.2 255.255.255.255
 ipv6 address 2001:db8:255:2::2/128
!
router isis CORE
 net 49.0001.0000.0000.0002.00
 is-type level-2-only
 log adjacency changes
 address-family ipv4 unicast
  metric-style wide
  maximum-paths 2
 !
 address-family ipv6 unicast
  single-topology
  maximum-paths 2
 !
 interface Loopback0
  address-family ipv4 unicast
   passive
  !
  address-family ipv6 unicast
   passive
  !
 !
 interface GigabitEthernet0/0/0/0
  point-to-point
  address-family ipv4 unicast
  !
  address-family ipv6 unicast
  !
 !
 interface GigabitEthernet0/0/0/1
  point-to-point
  address-family ipv4 unicast
  !
  address-family ipv6 unicast
  !
 !
!
commit
```

### R3

```xr
hostname r3
!
interface GigabitEthernet0/0/0/0
 description R3-to-R1
 ipv4 address 10.1.13.1 255.255.255.254
 ipv6 address 2001:db8:13::2/64
 no shutdown
!
interface GigabitEthernet0/0/0/1
 description R3-to-R4
 ipv4 address 10.1.34.0 255.255.255.254
 ipv6 address 2001:db8:34::1/64
 no shutdown
!
interface Loopback0
 description R3-stable-router-id
 ipv4 address 10.255.1.3 255.255.255.255
 ipv6 address 2001:db8:255:3::3/128
!
router isis CORE
 net 49.0001.0000.0000.0003.00
 is-type level-2-only
 log adjacency changes
 address-family ipv4 unicast
  metric-style wide
  maximum-paths 2
 !
 address-family ipv6 unicast
  single-topology
  maximum-paths 2
 !
 interface Loopback0
  address-family ipv4 unicast
   passive
  !
  address-family ipv6 unicast
   passive
  !
 !
 interface GigabitEthernet0/0/0/0
  point-to-point
  address-family ipv4 unicast
  !
  address-family ipv6 unicast
  !
 !
 interface GigabitEthernet0/0/0/1
  point-to-point
  address-family ipv4 unicast
  !
  address-family ipv6 unicast
  !
 !
!
commit
```

### R4

```xr
hostname r4
!
interface GigabitEthernet0/0/0/0
 description R4-to-R2
 ipv4 address 10.1.24.1 255.255.255.254
 ipv6 address 2001:db8:24::2/64
 no shutdown
!
interface GigabitEthernet0/0/0/1
 description R4-to-R3
 ipv4 address 10.1.34.1 255.255.255.254
 ipv6 address 2001:db8:34::2/64
 no shutdown
!
interface Loopback0
 description R4-stable-router-id
 ipv4 address 10.255.1.4 255.255.255.255
 ipv6 address 2001:db8:255:4::4/128
!
router isis CORE
 net 49.0001.0000.0000.0004.00
 is-type level-2-only
 log adjacency changes
 address-family ipv4 unicast
  metric-style wide
  maximum-paths 2
 !
 address-family ipv6 unicast
  single-topology
  maximum-paths 2
 !
 interface Loopback0
  address-family ipv4 unicast
   passive
  !
  address-family ipv6 unicast
   passive
  !
 !
 interface GigabitEthernet0/0/0/0
  point-to-point
  address-family ipv4 unicast
  !
  address-family ipv6 unicast
  !
 !
 interface GigabitEthernet0/0/0/1
  point-to-point
  address-family ipv4 unicast
  !
  address-family ipv6 unicast
  !
 !
!
commit
```

## 5. Failure Injection and Convergence

Start by confirming the normal state:

```bash
make LAB=01-isis-ecmp verify
```

On R2, shut its remote link to R4. R1 remains adjacent to both R2 and R3, but
IS-IS must recompute R1's route to R4 and retain only the R3 next hop.

```xr
configure
interface GigabitEthernet0/0/0/1
 shutdown
commit
```

After the adjacency and SPF update finish, verify the failure state:

```bash
bash labs/01-isis-ecmp/scripts/verify.sh r2-r4-down
```

On R1, the IPv4 route to `10.255.1.4/32` and IPv6 route to
`2001:db8:255:4::4/128` should now contain only the next hop through R3:
`10.1.13.1` and `2001:db8:13::2`, respectively. Pings from R1 to R4 must
continue to succeed.

Restore the topology on R2:

```xr
configure
interface GigabitEthernet0/0/0/1
 no shutdown
commit
```

Wait for the R2--R4 adjacency to become `Up`, then run the baseline verifier.
Both equal-cost next hops should return.

## 6. Focused Troubleshooting Prompts

Try these changes one at a time, then restore the reference configuration:

1. Remove `address-family ipv6 unicast` from one IS-IS interface and determine
   why it conflicts with the single-topology design.
2. Change the R1-to-R2 IPv4 IS-IS interface metric to make the R3 path preferred
   and compare RIB/FIB output before and after.
3. Configure `maximum-paths 1` under R1's IPv4 IS-IS address family, then
   confirm that the second equal route is no longer installed.
4. Shut R3's link to R4 instead, and compare the resulting route with the
   prescribed R2--R4 failure test.
