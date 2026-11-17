#minio

> 🚀目前仅提供docker 和 docker-compose 运行



| 名称             | 内容                                                         |
| ---------------- | ------------------------------------------------------------ |
| 版本：           | RELEASE.2025-10-15T17-29-55Z             |
| AMD64 镜像地址：       | harbor.tsingyun.net/tsingyun-middleware/minio:RELEASE.2025-10-15T17-29-55Z |
| ARM64 镜像地址：       | harbor.tsingyun.net/tsingyun-middleware/minio:RELEASE.2025-10-15T17-29-55Z-arm64 |





> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Middleware/minio/data

2、docker run 运行
docker run -d --name minio --network tsingyun -p 9000:9000 -p 9001:9001 -v /home/application/Middleware/minio-test/data:/data -v /etc/localtime:/etc/localtime -e MINIO_ROOT_USER=tsingyun -e MINIO_ROOT_PASSWORD='xxx' -e TZ=Asia/Shanghai --restart unless-stopped harbor.tsingyun.net/tsingyun-middleware/minio:RELEASE.2025-10-15T17-29-55Z server /data --console-address :9001

```


> 🐋 docker-compose 指令运行：

> 1、创建目录
mkdir -p /home/application/Middleware/minio/

> 2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Middleware/minio/docker-compose.yml

> 3、运行docker-compose创建容器
docker-compose up -d

> 4、登陆容器创建 key
```
docker exec -it minio bash

#创建key
mc admin user add minio LCfz7gXVnNjvjEDq2qez jj6r9Hu2gtueIQFSV35FzKcvGtK1G61d9ieNmKDg

#修改用户权限
mc admin policy attach minio readwrite --user LCfz7gXVnNjvjEDq2qez    
exit     #退出minio
```


