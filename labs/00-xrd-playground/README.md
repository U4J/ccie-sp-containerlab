# 基礎 MPLS LDP Lab

這個 lab 以 Cisco XRd Control Plane 建立一條最小的 MPLS provider core：

```text
CE-A -- PE-1 -- P-1 -- P-2 -- PE-2 -- CE-B
```

CE 端使用靜態預設路由；provider core 使用 IS-IS 建立 IPv4 reachability，並在
PE/P 之間啟用 LDP。PE 將各自連接的 CE loopback 靜態路由重分配到 IS-IS，因此
CE-A 的 `198.51.100.1/32` 可透過 MPLS core 連到 CE-B 的
`198.51.100.2/32`。這是 forwarding/LDP 基礎 lab，尚未使用 VRF、MP-BGP 或
L3VPN。

| Node | Container | Management IP | Loopback / test IP |
| --- | --- | --- | --- |
| CE-A | `clab-00-xrd-playground-ce-a` | `172.31.20.11` | `198.51.100.1/32` |
| PE-1 | `clab-00-xrd-playground-pe-1` | `172.31.20.12` | `10.255.0.1/32` |
| P-1 | `clab-00-xrd-playground-p-1` | `172.31.20.13` | `10.255.0.2/32` |
| P-2 | `clab-00-xrd-playground-p-2` | `172.31.20.14` | `10.255.0.3/32` |
| PE-2 | `clab-00-xrd-playground-pe-2` | `172.31.20.15` | `10.255.0.4/32` |
| CE-B | `clab-00-xrd-playground-ce-b` | `172.31.20.16` | `198.51.100.2/32` |

所有設定都在 `configs/`，並由 `startup-config` 載入。登入資訊為
`clab / clab@123`。

```bash
make LAB=00-xrd-playground deploy
make LAB=00-xrd-playground verify
make LAB=00-xrd-playground cli NODE=pe-1
```

驗證腳本會檢查 XR CLI 就緒、IS-IS/LDP 鄰居數量、兩端 CE loopback 的路由，和
CE-A 到 CE-B 的 ping。也可手動觀察：

```bash
make LAB=00-xrd-playground cli NODE=pe-1
show isis adjacency
show mpls ldp neighbor
show mpls forwarding
show route 198.51.100.2/32
```

若想保留實驗中修改後的 running config，而不覆寫版本控制的 startup config：

```bash
make save-configs
```

檔案會寫入不納入版本控制的 `snapshots/`。停止 lab 使用 `make destroy`；要同時
移除 Containerlab 的 lab state，使用 `make clean`。
