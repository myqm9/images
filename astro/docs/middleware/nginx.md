---
title: Nginx
sidebar: { order: 15 }
---

TDP 提供 Nginx 容器镜像，采用 docker-compose 部署，用作静态资源、反向代理和 TLS 入口。手册示例以企业 HSE 基线为准；站点路由、后端地址按项目交付清单填写，不要把客户专属配置写入公共文档。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

## 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装。
- ARM64 主机请将下方 compose 中的 `image` 换成发布信息中的 ARM64 镜像。

## 创建工作目录

```bash
mkdir -p /home/application/Middleware/nginx/{conf.d,html,config}
mkdir -p /home/application/Middleware/nginx/conf.d/cert
```

将站点配置放到 `conf.d/`，静态资源放到 `html/`，主配置放到 `config/nginx.conf`。

## 签发证书（可选）

自签发证书不受浏览器信任，仅用于内网或联调。有几个访问 IP 就写几个 `IP.n`。

编辑 `/home/application/Middleware/nginx/conf.d/cert/ssl.sh`，将 `YOUR_SERVER_IP` 换成实际地址：

```bash
#!/bin/sh

cat > openssl.cnf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
countryName = Country Name (2 letter code)
countryName_default = CN
stateOrProvinceName = State or Province Name (full name)
stateOrProvinceName_default = HN
localityName = Locality Name (eg, city)
localityName_default = ZZ
organizationalUnitName  = Organizational Unit Name (eg, section)
organizationalUnitName_default  = baseline
commonName = commonName
commonName_default = baseline
commonName_max  = 64

[ v3_req ]
basicConstraints = CA:TRUE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
IP.1 = YOUR_SERVER_IP
EOF

cat > v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName=@alt_names

[alt_names]
IP.1 = YOUR_SERVER_IP
EOF

openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt
openssl genrsa -out server.key 2048
openssl req -new -days 3650 -key server.key -out server.csr -config openssl.cnf
openssl x509 -days 3650 -req -sha256 -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in server.csr -out server.crt
cat server.crt server.key > server.pem
openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12 -name "server"
```

执行：

```bash
cd /home/application/Middleware/nginx/conf.d/cert
bash ssl.sh
```

交互提示可直接回车。正式环境应使用项目签发的证书替换 `server.pem` / `server.key`。

## 编写 Nginx 配置

SSL 片段 `/home/application/Middleware/nginx/conf.d/admin.ssl`：

```nginx
http2 on;
ssl_certificate  /etc/nginx/conf.d/cert/server.pem;
ssl_certificate_key /etc/nginx/conf.d/cert/server.key;
ssl_session_timeout 1h;
ssl_session_cache shared:MozSSL:10m;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers on;
```

主配置 `/home/application/Middleware/nginx/config/nginx.conf`：

```nginx
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    map $http_upgrade $connection_upgrade {
      default upgrade;
      '' close;
    }

    access_log  /var/log/nginx/access.log  main;

    sendfile       on;
    tcp_nopush     on;
    tcp_nodelay    on;

    keepalive_timeout  65;
    server_tokens off;

    gzip on;
    gzip_http_version 1.1;
    gzip_min_length 1k;
    gzip_comp_level 4;
    gzip_types text/plain application/json application/javascript application/octet-stream application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/bmp application/x-bmp image/x-ms-bmp application/vnd.ms-fontobject font/ttf font/opentype font/x-woff;
    gzip_vary on;
    gzip_buffers 4 16k;

    include /etc/nginx/conf.d/*.conf;
}
```

站点子配置放到 `conf.d/*.conf`（手册示例文件名为 `admin-docker.conf`），定义监听端口、反向代理和跨域。该文件随项目交付，不要把客户专属路由写入公共文档。前端静态包解压到 `html/`。

## 编写 docker-compose.yml

编辑 `/home/application/Middleware/nginx/docker-compose.yml`。手册采用宿主机网络，便于直接占用 80 / 443。

```yaml
services:
  nginx:
    image: {{ image.amd64.reference }}
    container_name: nginx
    restart: unless-stopped
    network_mode: host
    volumes:
      - /home/application/Middleware/nginx/config/nginx.conf:/etc/nginx/nginx.conf:ro
      - /home/application/Middleware/nginx/conf.d:/etc/nginx/conf.d:ro
      - /home/application/Middleware/nginx/html:/usr/share/nginx/html:ro
```

使用 `network_mode: host` 时不要再配置 `ports` 或加入 `tsingyun` bridge 网络。

## 启动容器

```bash
cd /home/application/Middleware/nginx
docker-compose up -d
docker-compose ps
```

## 校验配置与平滑重载

```bash
docker exec nginx nginx -t
docker exec nginx nginx -s reload
```

更新证书后同样执行 `nginx -t` 再 reload。
