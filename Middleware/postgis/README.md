#tsingyun-postgis


> 🚀目前仅提供docker 和 docker-compose 运行


| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| postgres+postgis版本：               | 15.18-3.5.7                                                 |
| pgrouting版本：               | 3.7.1                                                   |
| AMD64镜像地址：           | harbor.tsingyun.net/tsingyun-middleware/postgis:15.18-3.5.7 |
| ARM64镜像地址：           | harbor.tsingyun.net/tsingyun-middleware/postgis:15.18-3.5.7-arm64 |
| Trivy漏洞情况:       | 无，2026/07/16                                           |
| 官网Dockerfile地址： | https://github.com/postgis/docker-postgis/blob/master/15-3.5/alpine/Dockerfile |
| 其他内容： 关于pgrouting集成在postgis 中  |https://github.com/postgis/docker-postgis/issues/399 |


> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/postgis/{data,init}

2、下载gis.sql 到init 目录下
wget https://file.tsingyun.link/docker/Database/postgres/docker-compose/gis.sql -P /home/application/Database/postgis/init


3、docker run 运行
docker run --name postgis \
  -e POSTGRES_HOST_AUTH_METHOD=md5 \
  -e POSTGRES_PASSWORD=xxx \
  -v /home/application/Database/postgis/data:/var/lib/postgresql/data \
  -v /home/application/Database/postgis/init:/docker-entrypoint-initdb.d/ \
  -p 5432:5432 \
  -c max_connections=2000 \
  --restart=always \
  -d harbor.tsingyun.net/tsingyun-middleware/postgis:15.18-3.5.7

```


> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/postgis/{data,init}


2、下载gis.sql 到init 目录下

wget https://file.tsingyun.link/docker/Database/postgres/docker-compose/gis.sql -P /home/application/Database/postgis/init


3、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Database/postgis/docker-compose.yml


4、运行docker-compose创建容器
docker-compose up -d


```