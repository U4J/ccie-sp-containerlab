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

完成設定並在 XR CLI 執行 `commit` 後，可將兩台 running-config 匯出至 Git
追蹤的設定檔：

```bash
make save-configs
git diff -- labs/xrd-playground/configs/
```

Topology 會在全新部署或 `make redeploy` 時讀取這些設定檔。
