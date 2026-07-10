# CCIE-SP Containerlab Labs

目前預設 lab 是以 Cisco XRd Control Plane 建立的基礎 MPLS LDP lab：

```text
CE-A -- PE-1 -- P-1 -- P-2 -- PE-2 -- CE-B
```

每個練習情境各自位於 `labs/<lab-name>/`，包含 topology、startup configs、
驗證腳本與該 lab 的說明。這讓不同協定、故障情境與 IP 規劃可獨立部署，不會互相
覆寫。

使用的 image：

```text
docker.io/sbezverk/xrd-control-plane:26.2.1
```

## 全新 Ubuntu 系統準備

以下步驟適用於 Ubuntu 22.04、24.04 與 26.04。先安裝必要工具並加入
Docker 官方 APT repository：

```bash
sudo apt update
sudo apt install -y ca-certificates curl git make
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

安裝並啟動 Docker Engine：

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```

讓目前使用者可以直接執行 `docker`。執行後需登出再登入，或用
`newgrp docker` 立即套用新的群組：

```bash
sudo usermod -aG docker "$USER"
newgrp docker
docker info
```

> `docker` 群組具有等同 root 的主機存取權限，只應加入可信任的使用者。

安裝 Containerlab：

```bash
bash -c "$(curl -sL https://get.containerlab.dev)"
containerlab version
```

XRd 需要較高的 inotify instance 上限。建立永久設定並立即套用：

```bash
echo 'fs.inotify.max_user_instances=64000' | \
  sudo tee /etc/sysctl.d/99-xrd.conf
sudo sysctl --system
sysctl fs.inotify.max_user_instances
```

若尚未下載此 repository：

```bash
git clone https://github.com/U4J/ccie-sp-containerlab.git
cd ccie-sp-containerlab
```

## 啟動

```bash
make preflight
make deploy
make verify
```

XRd 首次開機約需一至數分鐘。`make verify` 會等待 6 台 XR CLI 就緒，然後檢查
IS-IS、LDP 與 CE-A 到 CE-B 的連通性。

## 進入 XR CLI

```bash
make cli NODE=pe-1
make cli NODE=p-1
```

也可以直接執行：

```bash
docker exec -it clab-xrd-playground-pe-1 /pkg/bin/xr_cli.sh
```

## SSH 管理

| Node | Management IP | Username | Password |
| --- | --- | --- | --- |
| CE-A | `172.31.20.11` | `clab` | `clab@123` |
| PE-1 | `172.31.20.12` | `clab` | `clab@123` |
| P-1 | `172.31.20.13` | `clab` | `clab@123` |
| P-2 | `172.31.20.14` | `clab` | `clab@123` |
| PE-2 | `172.31.20.15` | `clab` | `clab@123` |
| CE-B | `172.31.20.16` | `clab` | `clab@123` |

```bash
ssh clab@172.31.20.11
ssh clab@172.31.20.12
```

這個 lab 的資料介面、IS-IS、LDP 與 CE 的靜態路由已由 startup config 設定。
詳細的 IP 規劃與驗證指令請見 [labs/xrd-playground/README.md](labs/xrd-playground/README.md)。

## 儲存設定

在節點內完成設定並執行 `commit` 後，可匯出所有節點的 running-config：

```bash
make save-configs
git diff --no-index labs/xrd-playground/configs/ labs/xrd-playground/snapshots/ || true
```

設定會儲存在 `labs/xrd-playground/snapshots/`，不會覆寫受版本控制的
`configs/` startup configs。

## 停止與清除

```bash
make destroy
```

`destroy` 會保留 Containerlab lab directory。若要連持久化資料一起全部清除：

```bash
make clean
```

若要強制重建所有節點，請使用 `make redeploy`；這會中斷現有連線。
