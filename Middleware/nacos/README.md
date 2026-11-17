#tsingyun-nacos


> 🚀目前仅提供docker 和 docker-compose 运行

| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| 版本：               | 2.5.3                                                        |
| AMD64 镜像地址：           | harbor.tsingyun.net/tsingyun-middleware/tsingyun-nacos@2.5.3 |
| ARM64 镜像地址：           | harbor.tsingyun.net/tsingyun-middleware/tsingyun-nacos@2.5.3-arm64 |
| Trivy漏洞情况:       | Total: 78 (UNKNOWN: 0, LOW: 8, MEDIUM: 11, HIGH: 7, CRITICAL: 3) 2026/07/21 |
| 官网Dockerfile地址： | https://github.com/nacos-group/nacos-docker/blob/v2.5.3/build/Dockerfile |



> 🐋 docker 指令运行：


## 1、创建目录
mkdir -p /home/application/Middleware/nacos

## 2、初始化数据库
> 登录数据库，创建数据库，创建nacos 数据库用户，创建jdbc 数据库用户

init.sql 下载地址在:  https://download.tsingyun.link/docker/Middleware/nacos/2.2.0/init.sql

> 登录数据库，初始化 nacos 数据库

mysql-schema.sql 下载地址在:  https://download.tsingyun.link/docker/Middleware/nacos/2.2.0/mysql-schema.sql


## 3、docker run 运行
> ⚠️ 注意修改nacos 密码
```
docker run -d \
  --name nacos \
  --restart always \
  -p 8848:8848 \
  -p 9848:9848 \
  -e MODE=standalone \
  -e SPRING_DATASOURCE_PLATFORM=mysql \
  -e MYSQL_SERVICE_HOST=172.22.33.200 \
  -e MYSQL_SERVICE_PORT=3306 \
  -e MYSQL_SERVICE_DB_NAME=nacos \
  -e MYSQL_SERVICE_USER=nacos \
  -e MYSQL_SERVICE_PASSWORD=xxxx \
  -e MYSQL_DB_PARAM="characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&serverTimezone=Asia/Shanghai" \
  -v $(pwd)/logs:/home/nacos/logs \
  dockerhub.qingcloud.com/tsingyun_middleware/tsingyun-nacos:2.2.0
```







> 🐋 docker-compose 指令运行：


## 1、创建目录
mkdir -p /home/application/Middleware/nacos


## 2、初始化数据库
> 登录数据库，创建数据库，创建nacos 数据库用户，创建jdbc 数据库用户

init.sql 下载地址在:  https://download.tsingyun.link/docker/Middleware/nacos/2.2.0/init.sql

> 登录数据库，初始化 nacos 数据库

mysql-schema.sql 下载地址在:  https://download.tsingyun.link/docker/Middleware/nacos/2.2.0/mysql-schema.sql


## 3、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
> ⚠️ 注意修改nacos 密码

vim /home/application/Middleware/nacos/docker-compose.yml


## 4、运行docker-compose创建容器
docker-compose up -d