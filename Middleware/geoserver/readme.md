

> 🚀目前仅提供docker 和 docker-compose 运行



| 名称             | 内容                                                         |
| ---------------- | ------------------------------------------------------------ |
| 版本：           | geoserver=2.27.1, tomcat:9.0.105,jdk: eclipse-temurin:17.0.15_6-jdk-jammy   |
| AMD64镜像镜像地址：       | dockerhub.qingcloud.com/tsingyun_middleware/geoserver:2.27.1  |
| ARM64镜像镜像地址：       | dockerhub.qingcloud.com/tsingyun_middleware/geoserver:2.27.1-arm64  |
| 官方Dockerfile   | https://github.com/geoserver/docker |





> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Middleware/geoserver/data

2、docker run 运行
 docker run -itd --name geoserver -e CORS_ENABLED=true -p 8080:8080 -v /home/application/Middleware/geoserver/data:/opt/geoserver_data/ -v /home/application/Middleware/geoserver/map-data:/map docker.cnb.cool/sre/custom-vscode/geoserver:2.27.1


> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Middleware/geoserver/

2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Middleware/geoserver/docker-compose.yml

3、运行docker-compose创建容器
docker-compose up -d


```