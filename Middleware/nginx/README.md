#tsingyun-nginx


> 🚀目前仅提供docker 和 docker-compose 运行

| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| 版本：               | 1.28.3                                                     |
| AMD64镜像地址：           | harbor.tsingyun.net/tsingyun-middleware/nginx:1.28.3 |
| ARM64镜像地址：           | harbor.tsingyun.net/tsingyun-middleware/nginx:1.28.3-arm64 |
| Trivy漏洞情况:       |0 高危，0 中危，0 低危，0 无危 2025/11/19 |
| 官网Dockerfile地址： | https://github.com/nginx/docker-nginx/blob/9b549fdf936778810dbe95a4813899c60444ef1c/stable/alpine-slim/Dockerfile |




## 1、创建目录
``` bash
mkdir -p /home/application/Middleware/nginx/{conf.d,html}
mkdir -p /home/application/Middleware/nginx/conf.d/cert
``` 

## 2、签发证书
* ssl 证书 需要签发，使用脚本签发 IP 证书【自签发证书都是不受信任的】
* 有几个 ip 就写几个 ip，比如项目允许内外网同时访问。那就写私网 ip 和公网 ip

``` bash
vim  /home/application/Middleware/nginx/conf.d/cert/ssl.sh
```

``` bash
#!/bin/sh
 
# Generate the openssl configuration files.
echo "创建openssl.cnf------------------->"
 
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
# Extensions to add to a certificate request
basicConstraints = CA:TRUE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
IP.1 = 172.22.22.217
IP.2 = 114.114.114.114

EOF
 
echo "创建v3.ext------------------->"
cat > v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName=@alt_names

[alt_names]
IP.1 = 172.22.22.217
IP.2 = 114.114.114.114
EOF
 
echo "创建CA 根证书------------------------->"
echo "创建私钥 ca.key"
openssl genrsa -out ca.key 2048
 
echo "创建CA证书 ca.crt"
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt
 
echo "生成服务器证书----------------->"
echo "创建私钥 server.key"
openssl genrsa -out server.key 2048
 
echo "创建服务器证书请求文件 server.csr"
openssl req -new -days 3650 -key server.key -out server.csr -config openssl.cnf
 
echo "创建服务器证书 server.crt"
openssl x509 -days 3650 -req -sha256 -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in server.csr -out server.crt
 
echo "创建pem------------------------>"
cat server.crt server.key > server.pem
 
echo "创建p12----------------------->"
openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12 -name "server"
```

* 执行证书生成的脚本，每一步骤都直接回车，无需配置
``` bash
cd  /home/application/Middleware/nginx/conf.d/cert/
bash ssl.sh

建openssl.cnf------------------->
创建v3.ext------------------->
创建CA 根证书------------------------->
创建私钥 ca.key
Generating RSA private key, 2048 bit long modulus (2 primes)
.....................+++++
..+++++
e is 65537 (0x010001)
创建CA证书 ca.crt
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:
Email Address []:
生成服务器证书----------------->
创建私钥 server.key
Generating RSA private key, 2048 bit long modulus (2 primes)
........+++++
......................................+++++
e is 65537 (0x010001)
创建服务器证书请求文件 server.csr
Ignoring -days; not generating a certificate
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [CN]:
State or Province Name (full name) [HN]:
Locality Name (eg, city) [ZZ]:
Organizational Unit Name (eg, section) [baseline]:
commonName [baseline]:
创建服务器证书 server.crt
Signature ok
subject=C = CN, ST = HN, L = ZZ, OU = baseline, CN = baseline
Getting CA Private Key
创建pem------------------------>
创建p12----------------------->
Enter Export Password:
Verifying - Enter Export Password:
```



## 3、创建 nginx 相关配置文件
● admin.ssl 配置文件，提供ssl 证书相关配置
● ssl证书 的路径是定义死的，需要挂载证书进入容器中

``` bash
vim /home/application/Middleware/nginx/conf.d/admin.ssl
```

``` bash
http2 on;
ssl_certificate  /etc/nginx/conf.d/cert/server.pem;
ssl_certificate_key /etc/nginx/conf.d/cert/server.key;
ssl_session_timeout 1h;
ssl_session_cache shared:MozSSL:10m;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers on;
```

* nginx.conf 主 nginx 配置文件
* 主配置文件中定义了子配置文件的路径，写死的，注意挂载。
* 主配置配置了相关的 nginx 优化内容，如 websock，gzip，隐藏 nginx 版本号等等。

``` bash
vim /home/application/Middleware/nginx/nginx.conf
```
``` bash
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
* admin-docker.conf  子配置文件
* 子配置文件中定义了 nginx 端口，路由，后端代理配置，以及跨域相关内容。

``` bash
vim /home/application/Middleware/nginx/conf.d/admin-docker.conf
```

``` bash
server {
    listen 15099 ssl;
    include /etc/nginx/conf.d/admin.ssl;

    # 首页重定向到 /main-app/
    location = / {
        return 302 /main-app/;
    }

    # ======================
    # 主应用
    # ======================

    location /main-app/ {
        alias   /usr/share/nginx/html/main-app/;
        index  index.html index.htm;
        try_files $uri $uri/ /main-app/index.html;

        # 针对 HTML 文件禁用缓存
        location ~* \.html$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
    }

    # 原HSE中GIS3D大屏
    location /gis3d/ {
        alias   /usr/share/nginx/html/gis3d/;
        index  index.html index.htm;
        try_files $uri $uri/ /gis3d/index.html;
        #协商缓存
        add_header Cache-Control max-age=no-cache;
    }

    # ======================
    # 子应用
    # ======================

    # 子应用：/base/
    location /base/ {
        alias   /usr/share/nginx/html/base/;
        index  index.html index.htm;
        try_files $uri $uri/ /base/index.html;

        # 公共跨域头
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;

        # 手动处理 OPTIONS 请求
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*" always;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }

    # 子应用：/risk/
    location /risk/ {
        alias   /usr/share/nginx/html/risk/;
        index  index.html index.htm;
        try_files $uri $uri/ /risk/index.html;

        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;

        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*" always;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }

    # 子应用：/alarm/
    location /alarm/ {
        alias   /usr/share/nginx/html/alarm/;
        index  index.html index.htm;
        try_files $uri $uri/ /alarm/index.html;

        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;

        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*" always;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }

    # 子应用：/design/
    location /design/ {
        alias   /usr/share/nginx/html/design/;
        index  index.html index.htm;
        try_files $uri $uri/ /design/index.html;

        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;

        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*" always;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }

    # 子应用：/hse/
    location /hse/ {
        alias   /usr/share/nginx/html/hse/;
        index  index.html index.htm;
        try_files $uri $uri/ /hse/index.html;

        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;

        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*" always;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }

    # 子应用：/admin/
    location /admin/ {
        alias   /usr/share/nginx/html/admin/;
        index  index.html index.htm;
        try_files $uri $uri/ /admin/index.html;

        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;

        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*" always;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }

    # ======================
    # API 代理：/config
    # ======================
    location /config {
        proxy_pass http://172.24.0.46:8039/global-active-configs;
        client_max_body_size 200m;
        proxy_set_header Host $host;
        proxy_set_header X-real-ip $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_http_version 1.1;
        proxy_read_timeout 3600s;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # 隐藏后端自己的 CORS 头
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Credentials;

        # 跨域头
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
        add_header Access-Control-Max-Age 1728000;
    }

    # ======================
    # API 代理：/back/
    # ======================
    location /back/ {
        proxy_pass http://172.24.0.46:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-real-ip $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_http_version 1.1;
        proxy_read_timeout 3600s;

        # 隐藏后端自己的 CORS 头
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Credentials;

        # 跨域头
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
        add_header Access-Control-Max-Age 1728000;
    }

    error_page  404              /404.html;
    error_page   500 502 503 504  /50x.html;

    location = /50x.html {
        root   html;
    }
}
```

## 4、提供 html 代码文件
* 需要提供好 relase 版本 前端的所有代码合集包

``` bash
mkdir -p /home/application/Middleware/nginx/html
wget  xxxxx -O /home/application/Middleware/nginx/html/fe-baseline.tar.gz
```

## 5、🐋 docker  指令运行：
``` bash
 docker run -itd  --name nginx -v /home/application/Middleware/nginx/config/nginx.conf:/etc/nginx/nginx.conf:ro -v /home/application/Middleware/nginx/conf.d:/etc/nginx/conf.d:ro -v  /home/application/Middleware/nginx/html:/usr/share/nginx/html --network=host nginx:1.28.0-alpine-slim
```

## 6、🐋 docker-compose 指令运行：
* 创建docker-compose.yaml 文件
``` bash
vim /home/application/Middleware/nginx/docker-compose.yml
```
``` bash
version: "3.8"

services:
  nginx:
    image: dockerhub.qingcloud.com/tsingyun_middleware/nginx:1.28.0
    container_name: nginx
    restart: unless-stopped
    network_mode: host
    volumes:
      - /home/application/Middleware/nginx/config/nginx.conf:/etc/nginx/nginx.conf:ro
      - /home/application/Middleware/nginx/conf.d:/etc/nginx/conf.d:ro
      - /home/application/Middleware/nginx/html:/usr/share/nginx/html:ro
```

``` bash
docker-compose up -d
```