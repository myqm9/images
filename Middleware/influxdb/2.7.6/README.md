#tsingyun-influxdb


> 🚀目前仅提供docker 和 docker-compose 运行


| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| 版本:                | 2.7.6                                                        |
| 镜像地址：           | dockerhub.qingcloud.com/tsingyun_middleware/influxdb:2.7.6   |
| 官网Dockerfile地址： | https://github.com/influxdata/influxdata-docker/blob/aaea43796c7833895f32ecea4ff36048cc809786/influxdb/2.7/alpine/Dockerfile |
| Trivy漏洞情况:       | 无，2024.06.14                                               |


> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/influxdb/data


2、docker run 运行
docker run -d \
  --name influxdb \
  -p 8086:8086 \
  -v /home/application/Database/influxdb/data:/var/lib/influxdb2 \
  -e DOCKER_INFLUXDB_INIT_MODE=setup \
  -e DOCKER_INFLUXDB_INIT_USERNAME=tsingyun \
  -e DOCKER_INFLUXDB_INIT_PASSWORD=xxxxx \
  -e DOCKER_INFLUXDB_INIT_ORG=tsingyun \
  -e DOCKER_INFLUXDB_INIT_BUCKET=tsingyun \
  -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=1iSB6On81BBxZUB60opKnRmWZLynY4Zw0yr99XFL9_CUJgEz3xPWsX-J7OMAdhsvYhKBtBpSkaQF9nm-xvGWtQ== \
  dockerhub.qingcloud.com/tsingyun_middleware/influxdb:2.7.6

```


> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/influxdb/data

2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Database/influxdb/docker-compose.yml

3、运行docker-compose创建容器
docker-compose up -d


```