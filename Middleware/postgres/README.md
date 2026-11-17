#tsingyun-postgis


> 🚀目前仅提供docker 和 docker-compose 运行


| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| postgres版本：               | 15.18-alpine3.24                                  |
| AMD64镜像地址：           | harbor.tsingyun.net/tsingyun-middleware/postgres:15.18-alpine3.24  |
| ARM64镜像地址：           | harbor.tsingyun.net/tsingyun-middleware/postgres:15.18-alpine3.24-arm64 |
| Trivy漏洞情况:       | 无，2026/07/16                                        |
| 官网Dockerfile地址【未修复 gous 漏洞】： | https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/15/alpine3.24/Dockerfile |
| 社区Dockerfile地址【通过使用当前golang镜像构建gosu来去除基于CVE的gosu】： |https://github.com/nathanlaceyraft/postgres/blob/build_gosu/15/alpine3.20/Dockerfile |

* 关于通过使用当前golang镜像构建gosu来去除基于CVE的gosu的 issue： https://github.com/docker-library/postgres/pull/1323

> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/postgres/{data,init}


2、docker run 运行
docker run --name postgres \
  -e POSTGRES_HOST_AUTH_METHOD=md5 \
  -e POSTGRES_PASSWORD=xxx \
  -v /home/application/Database/postgres/data:/var/lib/postgresql/data \
  -v /home/application/Database/postgres/init:/docker-entrypoint-initdb.d/ \
  -p 5432:5432 \
  -c max_connections=2000 \
  --restart=always \
  -d harbor.tsingyun.net/tsingyun-middleware/postgres:15.18-alpine3.24

```


> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/postgres/{data,init}


2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Database/postgres/docker-compose.yml


3、运行docker-compose创建容器
docker-compose up -d


```