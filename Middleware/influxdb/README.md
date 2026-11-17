#tsingyun-influxdb


> 🚀目前仅提供docker 和 docker-compose 运行


| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| 版本:                | 3.9.0                                                        |
| AMD64镜像地址：           | dockerhub.qingcloud.com/tsingyun_middleware/influxdb:3.9.0   |
| ARM64镜像地址：           | dockerhub.qingcloud.com/tsingyun_middleware/influxdb:3.9.0-arm64   |
| 官网Dockerfile地址： | https://github.com/influxdata/influxdata-docker/blob/207532a59a09fc207edb19cd2187e7f33f4a474e/influxdb/3.9-core/Dockerfile|
| Trivy漏洞情况:       | 无，2026.04.09                                               |


> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/influxdb/data
mkdir -p /home/application/Database/influxdb/plugins

#授权目录
chmod -R 777 /home/application/Database/influxdb/data
chmod -R 777 /home/application/Database/influxdb/plugins



2、docker run 运行
docker run -d \
  --name influxdb \
  --restart always \
  --network tsingyun \
  -p 8181:8181 \
  -v /home/application/Database/influxdb/data:/var/lib/influxdb3/data \
  -v /home/application/Database/influxdb/plugins:/var/lib/influxdb3/plugins \
  -v /etc/localtime:/etc/localtime:ro \
  harbor.tsingyun.net/tsingyun-middleware/influxdb:3.9.0 \
  influxdb3 serve \
  --node-id=node0 \
  --object-store=file \
  --data-dir=/var/lib/influxdb3/data \
  --plugin-dir=/var/lib/influxdb3/plugins

```

> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/influxdb/data
mkdir -p /home/application/Database/influxdb/plugins

#授权目录
chmod -R 777 /home/application/Database/influxdb/data
chmod -R 777 /home/application/Database/influxdb/plugins


2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Database/influxdb/docker-compose.yml

3、运行docker-compose创建容器
docker-compose up -d


```

> 创建admin token
``` bash
docker exec -it influxdb bash
influxdb3 create token --admin
```
记录下admin token即可。


> 创建数据库
``` bash
docker exec -it influxdb bash

export INFLUXDB3_AUTH_TOKEN=your_admin_token
influxdb3 create database tsingyun

#查看数据库
influxdb3 show databases
```

> 访问influxdb-explorer，通过influxdb-proxy 转发访问
``` bash
http://xx.xx.xx.xx:3100
```

用户名: admin, 密码: xxxx
