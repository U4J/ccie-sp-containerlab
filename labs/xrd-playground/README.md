# XRd Playground

兩台空白 XRd Control Plane 節點透過 `GigabitEthernet0/0/0/0` 直接互連。

| Node | Container | Management IP |
| --- | --- | --- |
| xrd1 | `clab-xrd-playground-xrd1` | `172.31.20.11` |
| xrd2 | `clab-xrd-playground-xrd2` | `172.31.20.12` |

預設登入資訊為 `clab / clab@123`。

```bash
make deploy
make verify
make cli-xrd1
make cli-xrd2
```

資料介面不含預設 IP 或 routing protocol 設定，可直接由 XR CLI 開始配置。
