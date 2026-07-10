# CCIE-SP Containerlab Labs

這個 repository 依 CCIE-SP v5.1 roadmap 將練習拆成可獨立部署、驗證與版本控制的
lab。每個主題放在自己的 `labs/<stage>-<topic>/` 資料夾，避免 topology、IP
規劃與設定互相覆寫。

完整的考綱對照請見 [docs/blueprint-map.md](docs/blueprint-map.md)。

## Lab 目錄

| 階段 | 資料夾 | 主題 | 狀態 |
| --- | --- | --- | --- |
| 00 | [00-xrd-playground](labs/00-xrd-playground/README.md) | 基礎 MPLS forwarding、IS-IS、LDP | 已實作 |
| 01 | [01-isis-ecmp](labs/01-isis-ecmp/README.md) | IS-IS dual stack、ECMP、收斂 | 規劃中 |
| 02 | [02-ospf-bfd-lfa](labs/02-ospf-bfd-lfa/README.md) | OSPFv2/v3、BFD、LFA | 規劃中 |
| 03 | [03-mpls-ldp-failover](labs/03-mpls-ldp-failover/README.md) | MPLS LDP 故障切換 | 規劃中 |
| 04 | [04-mpbgp-rr](labs/04-mpbgp-rr/README.md) | iBGP、RR、MP-BGP、policy | 規劃中 |
| 05 | [05-mpls-l3vpn](labs/05-mpls-l3vpn/README.md) | MPLS L3VPN、Inter-AS、CSC | 規劃中 |
| 06 | [06-evpn-vpls](labs/06-evpn-vpls/README.md) | VPWS、VPLS、EVPN | 規劃中 |
| 07 | [07-multicast](labs/07-multicast/README.md) | Multicast、PIM、Anycast RP、mLDP | 規劃中 |
| 08 | [08-sr-mpls-te](labs/08-sr-mpls-te/README.md) | SR-MPLS、SR-TE、TI-LFA、PCEP | 規劃中 |
| 09 | [09-srv6-usid](labs/09-srv6-usid/README.md) | SRv6、uSID、interworking | 規劃中 |
| 10 | [10-qos-security](labs/10-qos-security/README.md) | QoS、CoPP、uRPF、RPKI、FlowSpec | 規劃中 |
| 11 | [11-telemetry-automation](labs/11-telemetry-automation/README.md) | Telemetry、NETCONF/RESTCONF、Python | 規劃中 |
| 12 | [12-mixed-troubleshooting](labs/12-mixed-troubleshooting/README.md) | 混合式故障排除情境 | 規劃中 |

只有標示「已實作」的 lab 目前具備 topology、設定與驗證腳本；其餘資料夾先保留
README，作為後續實作的固定位置。

## 目前可用：00 XRd MPLS Playground

```text
CE-A -- PE-1 -- P-1 -- P-2 -- PE-2 -- CE-B
```

此 lab 使用 `docker.io/sbezverk/xrd-control-plane:26.2.1`。PE/P 的 core
使用 IS-IS 與 LDP；CE-A、CE-B 使用靜態預設路由，並以兩端 loopback 驗證 MPLS
轉送。完整 IP 規劃與驗證細節請見
[00-xrd-playground README](labs/00-xrd-playground/README.md)。

請明確指定 `LAB`，以對應資料夾名稱：

```bash
make LAB=00-xrd-playground preflight
make LAB=00-xrd-playground deploy
make LAB=00-xrd-playground verify
make LAB=00-xrd-playground cli NODE=pe-1
```

XRd 第一次開機約需一至數分鐘。`verify` 會檢查 XR CLI、IS-IS/LDP 鄰接、MPLS
forwarding entry，以及 CE-A 到 CE-B 的連通性。

## 建立下一個 Lab

每個 lab 都應維持下列結構；不要重用其他 lab 的 topology 或 configs：

```text
labs/<stage>-<topic>/
├── README.md
├── topology.clab.yml
├── configs/
└── scripts/
    └── verify.sh
```

共用的 `scripts/save-configs.sh` 由根目錄的 Makefile 呼叫，會從各 lab 的
`topology.clab.yml` 讀取 lab 名稱和節點清單，將 XRd running-config 匯出到該 lab 的
`snapshots/`。

在實作前，README 應先說明目標、拓撲、IP/ASN 規劃、預期驗證結果，以及刻意植入
的故障（若有）。`configs/` 放受版本控制的 deterministic startup config；實驗
中匯出的 running-config 應放在已忽略的 `snapshots/`。

## 主機準備

需要 Docker Engine、Containerlab、`make` 與可執行 Docker 的使用者帳號：

```bash
sudo apt update
sudo apt install -y ca-certificates curl git make
curl -sL https://get.containerlab.dev | sudo -E bash
sudo usermod -aG docker "$USER"
newgrp docker
docker info
containerlab version
```

XRd 需要較高的 inotify instance 上限：

```bash
echo 'fs.inotify.max_user_instances=64000' | \
  sudo tee /etc/sysctl.d/99-xrd.conf
sudo sysctl --system
```

## 常用操作

將以下命令中的 `<lab-name>` 換成實際已實作的資料夾名稱：

```bash
make LAB=<lab-name> inspect
make LAB=<lab-name> save-configs
make LAB=<lab-name> destroy
make LAB=<lab-name> clean
```

`destroy` 會停止並移除 lab 容器；`clean` 會連同 Containerlab lab state 一起清除。
