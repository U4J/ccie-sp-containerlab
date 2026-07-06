# XRd Playground

8 台未套用 startup config 的 XRd Control Plane 節點，拓撲如下：

```text
PE1 ── ABR1 ── P1 ── ABR3 ── PE3
  ╲      │       │       │      ╱
   ╲── ABR2 ── P2 ── ABR4 ──╱
```

| Node | Container | Management IP |
| --- | --- | --- |
| PE1 | `clab-xrd-playground-pe1` | `172.31.20.11` |
| ABR1 | `clab-xrd-playground-abr1` | `172.31.20.12` |
| P1 | `clab-xrd-playground-p1` | `172.31.20.13` |
| ABR3 | `clab-xrd-playground-abr3` | `172.31.20.14` |
| PE3 | `clab-xrd-playground-pe3` | `172.31.20.15` |
| ABR2 | `clab-xrd-playground-abr2` | `172.31.20.16` |
| P2 | `clab-xrd-playground-p2` | `172.31.20.17` |
| ABR4 | `clab-xrd-playground-abr4` | `172.31.20.18` |

預設登入資訊為 `clab / clab@123`。

```bash
make deploy
make verify
make cli NODE=pe1
```

Topology 只定義 XRd image、管理 IP 與資料介面連線，不載入任何
`startup-config`。節點名稱在 containerlab 中使用小寫。

完成設定並在 XR CLI 執行 `commit` 後，可匯出 8 台節點的 running-config：

```bash
make save-configs
```

設定會儲存在 `labs/xrd-playground/configs/`。這些檔案不會由 topology
自動載入。
