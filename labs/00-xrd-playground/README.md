# XRd MPLS 手動設定 Playground

這個 lab 以 Cisco XRd Control Plane 建立一條最小的 MPLS provider core：

```text
CE-A -- PE-1 -- P-1 -- P-2 -- PE-2 -- CE-B
```

此 lab **不會載入 startup configuration**。節點啟動後，請依自己的練習目標手動
設定；原本的完整參考設定已整理至 [CONFIGURATION.md](CONFIGURATION.md)。該文件
以 CE 靜態路由、provider core IS-IS 與 LDP 為範例，最終讓 CE-A 的
`198.51.100.1/32` 可透過 MPLS core 連到 CE-B 的 `198.51.100.2/32`。範例不使用
VRF、MP-BGP 或 L3VPN。

| Node | Container | Container management IP | 範例 Loopback / test IP |
| --- | --- | --- | --- |
| CE-A | `clab-00-xrd-playground-ce-a` | `172.31.20.11` | `198.51.100.1/32` |
| PE-1 | `clab-00-xrd-playground-pe-1` | `172.31.20.12` | `10.255.0.1/32` |
| P-1 | `clab-00-xrd-playground-p-1` | `172.31.20.13` | `10.255.0.2/32` |
| P-2 | `clab-00-xrd-playground-p-2` | `172.31.20.14` | `10.255.0.3/32` |
| PE-2 | `clab-00-xrd-playground-pe-2` | `172.31.20.15` | `10.255.0.4/32` |
| CE-B | `clab-00-xrd-playground-ce-b` | `172.31.20.16` | `198.51.100.2/32` |

`mgmt-ipv4` 僅提供 Containerlab 容器管理網路的位址；由於不再注入 XR 設定，
它不代表 XR 的 `MgmtEth0/RP0/CPU0/0` 已有 IP。建議透過 `make ... cli` 或
`docker exec` 進入節點並自行設定。若要使用 SSH，請先自行建立帳號、啟用 SSH，
並設定管理介面。

```bash
make LAB=00-xrd-playground deploy
make LAB=00-xrd-playground cli NODE=pe-1
```

完成 [設定說明](CONFIGURATION.md) 的參考情境後，可執行：

```bash
make LAB=00-xrd-playground verify
```

驗證腳本會檢查 XR CLI、IS-IS/LDP 鄰居數量、兩端 CE loopback 的路由，和
CE-A 到 CE-B 的 ping。未完成相應設定時，驗證失敗是預期行為。也可手動觀察：

```bash
make LAB=00-xrd-playground cli NODE=pe-1
show isis adjacency
show mpls ldp neighbor
show mpls forwarding
show route 198.51.100.2/32
```

若想保留實驗中修改後的 running config：

```bash
make LAB=00-xrd-playground save-configs
```

檔案會寫入不納入版本控制的 `snapshots/`。停止 lab 使用 `make destroy`；要同時
移除 Containerlab 的 lab state，使用 `make clean`。重新部署前請先停止並清除舊
lab，避免沿用既有容器的設定狀態。
