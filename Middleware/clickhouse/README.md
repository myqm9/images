#tsingyun-clickhouse

> 🚀目前仅提供docker 和 docker-compose 运行


| 名称                | 内容                                                         |
| ------------------- | ------------------------------------------------------------ |
| 版本：              | 24.5.1                                                       |
| AMD64镜像地址：          | dockerhub.qingcloud.com/tsingyun_middleware/clickhouse:24.5.1 |
| ARM64镜像地址(鲲鹏 920 专属)：          | harbor.tsingyun.net/tsingyun-middleware/clickhouse:23.3.9.55-arm64 |
| 官网Dockerfile地址: | https://github.com/ClickHouse/ClickHouse/blob/master/docker/server/Dockerfile.alpine |




> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/clickhouse/{data,log}

2、docker run 运行
docker run -d \
  --name clickhouse \
  --restart=always \
  -e CLICKHOUSE_USER=default \
  -e CLICKHOUSE_PASSWORD=XXXXXXXX \
  -e CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
  -p 8123:8123 \
  -v /home/application/Database/clickhouse/log:/var/log/clickhouse-server \
  -v /home/application/Database/clickhouse/data:/var/lib/clickhouse \
   dockerhub.qingcloud.com/tsingyun_middleware/clickhouse:24.5.1

```


> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/clickhouse/{data,log}

2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Database/clickhouse/docker-compose.yml

3、运行docker-compose创建容器
docker-compose up -d


```