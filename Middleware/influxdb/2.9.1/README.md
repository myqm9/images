#tsingyun-influxdb


> 🚀目前仅提供docker 和 docker-compose 运行


| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| 版本:                | 2.9.1                                                        |
| 镜像地址：           | dockerhub.qingcloud.com/tsingyun_middleware/influxdb:2.9.1   |
| 官网Dockerfile地址： | https://github.com/influxdata/influxdata-docker/blob/master/influxdb/2.9/alpine/Dockerfile |
| Trivy漏洞情况:       | 待重新扫描                                                    |

> ⚠️ 从 2.7.x 升级到 2.9.x 的注意事项：
> - 2.9.0 起默认对磁盘上的 API token 做哈希存储，容器首次以新版本启动时会自动将现有明文 token 转为哈希形式，转换后**无法再恢复出明文**。升级前请先备份/记录好现有 token（如 `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN`）。
> - 基础镜像内的 dasel 由 v2 升级到 v3（CLI 参数不兼容），已同步更新 entrypoint.sh 中的调用方式；如果你有自定义配置解析逻辑，需要一并检查。
> - 容器内降权方式由 `su-exec` 改为 `setpriv`（对齐官方最新镜像），使用方式对外无感知。


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
  dockerhub.qingcloud.com/tsingyun_middleware/influxdb:2.9.1

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