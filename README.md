# Two-node XRd Playground

兩台未預先設定業務功能的 Cisco XRd Control Plane 節點，透過一條資料 link
直接互連，適合登入後自行設定與測試 IOS XR 功能。

```text
xrd1 Gi0/0/0/0 ───────── Gi0/0/0/0 xrd2
     172.31.20.11         172.31.20.12
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

XRd 首次開機約需一至數分鐘。`make verify` 會等待兩台 XR CLI 就緒。

## 進入 XR CLI

```bash
make cli-xrd1
make cli-xrd2
```

也可以直接執行：

```bash
docker exec -it clab-xrd-playground-xrd1 /pkg/bin/xr_cli.sh
docker exec -it clab-xrd-playground-xrd2 /pkg/bin/xr_cli.sh
```

## SSH 管理

| Node | Management IP | Username | Password |
| --- | --- | --- | --- |
| xrd1 | `172.31.20.11` | `clab` | `clab@123` |
| xrd2 | `172.31.20.12` | `clab` | `clab@123` |

```bash
ssh clab@172.31.20.11
ssh clab@172.31.20.12
```

資料介面一開始沒有 IP，請在 XR CLI 中自行設定
`GigabitEthernet0/0/0/0`。

## 停止與清除

```bash
make destroy
```

`destroy` 會保留 Containerlab lab directory，因此在 XR CLI 中 commit 的設定可供
下次部署使用。若要連持久化設定一起全部清除：

```bash
make clean
```

主機需要：

```text
fs.inotify.max_user_instances=64000
```
