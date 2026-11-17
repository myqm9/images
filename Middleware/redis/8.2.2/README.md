#tsingyun-redis



> 🚀目前仅提供docker 和 docker-compose 运行



| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| 版本                 | 8.2.2                                                        |
| 镜像地址：           | dockerhub.qingcloud.com/tsingyun_middleware/redis:8.2.2      |
| Trivy漏洞情况:       | 0   2025/10/24 |
| 官网Dockerfile地址： | https://github.com/redis/docker-library-redis/blob/c5846c13383c8b284897ff171e0c946868ed4c8c/alpine/Dockerfile |

> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/redis/{data,logs}


2、docker run 运行
docker run -d --name redis \
  -v /home/application/Database/redis/data:/data \
  -v /home/application/Database/redis/logs:/logs \
  -p 6379:6379 \
  dockerhub.qingcloud.com/tsingyun_middleware/redis:8.2.2 redis-server --requirepass xxxxx --port 6379 --appendonly yes --dbfilename dump.rd --dir /data --timeout 0 --save 900 1 --save 300 10 --save 60 10000

```


> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Database/redis/{data,logs}


2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Database/redis/docker-compose.yaml

3、运行docker-compose创建容器
docker-compose up -d


```