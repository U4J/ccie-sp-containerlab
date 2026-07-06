# CCIE-SP Containerlab

以 Containerlab 建立可重複部署、驗證與故障排除的 CCIE Service Provider
練習環境。內容依 CCIE Service Provider v5.1 lab exam topics 規劃，但不包含
Cisco 官方考題或受授權限制的映像檔。

## 起始 Lab

`01-isis-dual-stack` 是一個四節點的雙棧 Service Provider underlay：

```text
              ┌──── p1 ────┐
              │            │
             pe1          pe2
              │            │
              └──── p2 ────┘
```

- IS-IS Level 2
- IPv4 與 IPv6 point-to-point addressing
- 兩條等成本路徑
- Loopback reachability 驗證
- FRRouting 開源映像，不需 Cisco image 即可開始

## 需求

- Linux 或 WSL2
- Docker
- Containerlab
- GNU Make

```bash
docker version
containerlab version
make preflight
```

## 快速開始

```bash
make deploy
make verify
make inspect
make destroy
```

選擇其他 lab 時指定其目錄名稱：

```bash
make LAB=01-isis-dual-stack deploy
```

進入節點：

```bash
docker exec -it clab-ccie-sp-isis-pe1 vtysh
```

建議先執行 `make deploy && make verify` 建立 baseline，再停止一條 link 或修改
metric，觀察 IS-IS、RIB 與 FIB 的收斂結果。

## Repository 結構

```text
.
├── docs/
│   └── blueprint-map.md
├── labs/
│   └── 01-isis-dual-stack/
│       ├── configs/
│       ├── scripts/
│       └── topology.clab.yml
├── Makefile
└── README.md
```

每個 lab 都應包含：

1. 獨立的 Containerlab topology。
2. 可版本控制的 startup configs。
3. 自動化驗證腳本。
4. README 中的目標、故障情境與完成條件。

## 學習路線

後續 lab 的建議順序與 CCIE-SP v5.1 對照請見
[`docs/blueprint-map.md`](docs/blueprint-map.md)。

> 注意：Containerlab 與 FRR 適合練習協定行為、自動化與故障排除；部分
> IOS XR 特有功能仍需合法取得的 Cisco XRd、CML 或其他 Cisco lab 環境。

