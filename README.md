# 8-node CCIE-SP XRd Playground

8 台未預先設定業務功能的 Cisco XRd Control Plane 節點。Topology 只建立
節點與資料 link，不載入 startup config。

```text
PE1 ── ABR1 ── P1 ── ABR3 ── PE3
  ╲      │       │       │      ╱
   ╲── ABR2 ── P2 ── ABR4 ──╱
```

使用的 image：

```text
docker.io/sbezverk/xrd-control-plane:26.2.1
```

## 啟動

```bash
make preflight
make deploy
make verify
```

XRd 首次開機約需一至數分鐘。`make verify` 會等待 8 台 XR CLI 就緒。

## 進入 XR CLI

```bash
make cli NODE=pe1
make cli NODE=abr1
```

也可以直接執行：

```bash
docker exec -it clab-xrd-playground-pe1 /pkg/bin/xr_cli.sh
```

## SSH 管理

| Node | Management IP | Username | Password |
| --- | --- | --- | --- |
| PE1 | `172.31.20.11` | `clab` | `clab@123` |
| ABR1 | `172.31.20.12` | `clab` | `clab@123` |
| P1 | `172.31.20.13` | `clab` | `clab@123` |
| ABR3 | `172.31.20.14` | `clab` | `clab@123` |
| PE3 | `172.31.20.15` | `clab` | `clab@123` |
| ABR2 | `172.31.20.16` | `clab` | `clab@123` |
| P2 | `172.31.20.17` | `clab` | `clab@123` |
| ABR4 | `172.31.20.18` | `clab` | `clab@123` |

```bash
ssh clab@172.31.20.11
ssh clab@172.31.20.12
```

資料介面一開始沒有 IP 或路由協定設定，請在 XR CLI 中自行設定。

## 儲存設定

在節點內完成設定並執行 `commit` 後，可匯出所有節點的 running-config：

```bash
make save-configs
git diff -- labs/xrd-playground/configs/
```

設定會儲存在 `labs/xrd-playground/configs/`，但不會由 topology 自動載入，
因此新的 lab 仍會以空白設定啟動。

## 停止與清除

```bash
make destroy
```

`destroy` 會保留 Containerlab lab directory。若要連持久化資料一起全部清除：

```bash
make clean
```

若要強制重建所有節點，請使用 `make redeploy`；這會中斷現有連線。

主機需要：

```text
fs.inotify.max_user_instances=64000
```
