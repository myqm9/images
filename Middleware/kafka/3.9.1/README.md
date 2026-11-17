#tsingyun-kafka

> 🚀目前仅提供docker 和 docker-compose 运行



| 名称             | 内容                                                         |
| ---------------- | ------------------------------------------------------------ |
| ARM64 openjdk基础镜像: | dockerhub.qingcloud.com/tsingyun_middleware/tsingyun-openjdk:v11_0_23-jdk-ubi9-arm64 |
| X86-64 openjdk基础镜像: | dockerhub.qingcloud.com/tsingyun_middleware/tsingyun-openjdk:v11_0_23-jdk-ubi9-x86 |
| 版本：           | KAFKA_VERSION=3.9.1 , SCALA_VERSION=2.13                     |
| ARM64镜像地址： | dockerhub.qingcloud.com/tsingyun_middleware/kafka-kraft:3.9.1-arm64 |
| AMD64镜像地址： | dockerhub.qingcloud.com/tsingyun_middleware/kafka-kraft:3.9.1 |





> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Middleware/kafka/data

2、docker run 运行
docker run -d --name kafka -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://172.16.10.180:9092 -p 9092:9092 -v /home/application/Middleware/kafka/data:/var/lib/kafka/data --restart=always dockerhub.qingcloud.com/tsingyun_middleware/kafka-kraft:3.9.1



3、运行kafka-map 管理工具
docker run -d \
    -p 19006:8080 \
    -v /opt/kafka-map/data:/usr/local/kafka-map/data \
    -e DEFAULT_USERNAME=admin \
    -e DEFAULT_PASSWORD=xxxx \
    --name kafka-map \
    --restart always dockerhub.qingcloud.com/tsingyun_middleware/kafka-map:1.3.3
```


> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Middleware/kafka/

2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Middleware/kafka/docker-compose.yml

3、运行docker-compose创建容器
docker-compose up -d


```