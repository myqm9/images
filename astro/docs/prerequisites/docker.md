---
title: 容器环境部署
draft: false
sidebar:
  order: 2
---

采用二进制包安装 Docker `29.2.1` 与 Docker Compose `v2.40.3`，支持 AMD64 与 ARM64。请先完成 [系统初始化配置](/prerequisites/system-initialization/)，确认 `/home/application` 已挂载。安装完成后创建 `tsingyun` 网络并登录私有仓库，后续中间件页面都依赖这两步。

安装包见交付物清单；也可按架构从社区镜像或内网地址下载。

## 安装 Docker

### 下载二进制包

**AMD64**

```bash
# 社区
wget https://mirrors.nju.edu.cn/docker-ce/linux/static/stable/x86_64/docker-29.2.1.tgz

# 内网
wget https://file.tsingyun.link/linux-soft/docker/docker-29.2.1.tgz
```

**ARM64**

```bash
# 社区
wget https://mirrors.nju.edu.cn/docker-ce/linux/static/stable/aarch64/docker-29.2.1.tgz

# 内网
wget https://file.tsingyun.link/linux-soft/docker/arm/docker-29.2.1.tgz
```

### 解压并安装

```bash
tar -xf docker-29.2.1.tgz
cp docker/* /usr/bin/
which docker

mkdir -p /home/soft
mv docker/ /home/soft/
```

:::caution
解压后的 `docker/` 目录必须移走（例如 `/home/soft/docker`），避免与后面创建的数据目录冲突，导致 Docker 启动失败。
:::

### 编写 systemd 服务

创建 `/etc/systemd/system/docker.service`：

```bash
cat > /etc/systemd/system/docker.service <<'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=65535
LimitNPROC=65535
LimitCORE=65535
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
```

### 数据目录（可选）

Docker 默认数据目录是 `/var/lib/docker`。建议不改这个路径，把目录软链到大容量磁盘（如已挂载的 `/home/application`）。

若数据盘已在系统初始化中挂载，**不要再次格式化**，只做目录和软链接：

```bash
mkdir -p /home/application/docker
ln -s /home/application/docker /var/lib/docker
```

### 启动服务

```bash
chmod +x /etc/systemd/system/docker.service
systemctl daemon-reload
systemctl start docker.service
systemctl enable docker.service
docker --version
```

### 配置镜像加速与日志

```bash
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2",
  "min-api-version": "1.24",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl daemon-reload
systemctl restart docker
```

:::caution[HTTP 仓库]
仓库不是 HTTPS 时，在 `/etc/docker/daemon.json` 中增加：

```json
"insecure-registries": [
  "YOUR_INSECURE_REGISTRY"
]
```
:::

:::caution[网段冲突]
客户网络占用 `172.17.0.0/16` 到 `172.31.0.0/16` 时，必须改 Docker 默认网段。默认 `docker0` 使用 `172.17.0.0/16`，自定义 bridge / overlay 会从 `172.18.0.0/16` 起依次分配到 `172.31.0.0/16`。

把 `bip`（docker0）和 `default-address-pools`（其他网络）写进 `daemon.json` 后重启：

```bash
cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "storage-driver": "overlay2",
  "bip": "10.10.30.1/24",
  "default-address-pools": [
    {
      "base": "10.10.31.0/20",
      "size": 24
    }
  ],
  "log-driver": "json-file",
  "min-api-version": "1.24",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker
```
:::

## 安装 Docker Compose

二进制包版本为 `v2.40.3`。社区包安装到 `/usr/local/bin`，内网包安装到 `/usr/bin`。

### AMD64

```bash
# 社区
wget https://github.com/docker/compose/releases/download/v2.40.3/docker-compose-linux-x86_64 -O /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 内网
wget https://file.tsingyun.link/linux-soft/docker/docker-compose_v3/x86/docker-compose-linux-x86_64_2.40.3 -O /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose
```

### ARM64

```bash
# 社区
wget https://github.com/docker/compose/releases/download/v2.40.3/docker-compose-linux-aarch64 -O /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 内网
wget https://file.tsingyun.link/linux-soft/docker/docker-compose_v3/arm/docker-compose-linux-aarch64_2.40.3 -O /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose
```

验证：

```bash
docker-compose --version
```

## 创建容器网络并登录仓库

创建名为 `tsingyun` 的网桥，供本机容器互通。子网 `10.22.33.0/24`，网关 `10.22.33.1`。

:::caution
创建前确认该子网未被占用，其他网络也不要使用同一网段。
:::

```bash
docker network create -d bridge --subnet "10.22.33.0/24" --gateway "10.22.33.1" tsingyun
```

登录私有仓库：

```bash
docker login harbor.tsingyun.net
```

按提示输入用户名和密码。密码保存在密钥系统，不要写入文档或提交到仓库。
