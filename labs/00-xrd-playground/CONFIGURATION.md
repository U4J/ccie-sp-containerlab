# 00-xrd-playground 設定說明

本文件保存此拓撲原先的參考情境，供你在空白的 XRd 節點上逐步手動設定。拓撲本身
不再引用 `startup-config`；`make LAB=00-xrd-playground deploy` 後，所有協定、資料
介面 IP、loopback 與帳號設定都由你決定。

參考情境是 CE 靜態路由 + provider core IS-IS Level-2 + MPLS LDP。它只示範標籤
轉送，不建立 VRF、MP-BGP 或 L3VPN。

## 1. 拓撲與位址規劃

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

IS-IS instance 名稱是 `CORE`，area 為 `49.0001`，並使用 Level-2 only。各節點的
NET 分別為：

| Node | NET |
| --- | --- |
| PE-1 | `49.0001.0102.5500.0001.00` |
| P-1 | `49.0001.0102.5500.0002.00` |
| P-2 | `49.0001.0102.5500.0003.00` |
| PE-2 | `49.0001.0102.5500.0004.00` |

## 2. 啟動與操作方式

在專案根目錄啟動 lab：

```bash
make LAB=00-xrd-playground deploy
make LAB=00-xrd-playground cli NODE=pe-1
```

進入 XR CLI 後，以 `configure` 進入設定模式，完成一個區塊後使用 `commit` 寫入
running configuration。下列每個程式區塊皆可在設定模式貼上；節點名稱請依實際節點
調整。首次開機且沒有自訂管理設定時，最直接的操作方式是 `make ... cli`。

## 3. 共通基本設定（選用）

若需要本機帳號與 SSH，請在每台設備各自執行以下設定，並將 hostname 改成該節點
名稱。這不是拓撲運作的必要條件；管理介面的 VRF、IP 與預設路由也應依你的環境另行
設定。

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

若要讓 XR 管理介面加入管理 VRF，可先確認系統建立的 VRF 名稱，再自行設定
`MgmtEth0/RP0/CPU0/0`。Containerlab YAML 中的 `mgmt-ipv4` 是容器管理網路資料，
不是此介面自動取得的 XR IPv4 設定。

## 4. CE 設定

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

## 5. Provider core 設定

PE 會將連到 CE loopback 的靜態路由重分配進 IS-IS；P 路由器只參與 IS-IS 與 LDP。
所有 core link 都是 point-to-point，並啟用 LDP/IGP synchronization。

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

## 6. 驗證順序與預期結果

先在每台 core router 確認 IS-IS 和 LDP 鄰接：PE 各一個鄰居，P 各兩個鄰居。

```xr
show isis adjacency
show mpls ldp neighbor
show route 198.51.100.1/32
show route 198.51.100.2/32
show mpls forwarding
```

最後從 CE-A 測試：

```xr
ping ipv4 198.51.100.2 source 198.51.100.1 count 5
```

完成參考情境後，也可從主機執行 `make LAB=00-xrd-playground verify`。此驗證腳本
會檢查所有預期鄰接、PE 路由與標籤轉送表項，以及上述 ping。

## 7. 保存你的練習結果

要保存目前的設定供日後參考，從專案根目錄執行：

```bash
make LAB=00-xrd-playground save-configs
```

輸出會寫入未納入版本控制的 `snapshots/` 目錄；它不會成為下一次部署的
startup configuration。
