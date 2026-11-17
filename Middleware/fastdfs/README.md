#tsingyun-fastdfs


> 🚀目前仅提供docker 和 docker-compose 运行



| 名称           | 内容                                                       |
| -------------- | ---------------------------------------------------------- |
| 基础镜像:      | alpine:3.16                                                |
| AMD64镜像地址       | harbor.tsingyun.net/tsingyun-middleware/fastdfs:6.10.0       |
| ARM64镜像地址       | harbor.tsingyun.net/tsingyun-middleware/fastdfs:6.10.0-arm64       |
| Trivy漏洞情况: | 无，2025/03/31                                             |

| 软件名称      | 版本   | 备注 |
| ------------- | ------ | ---- |
| fastdfs       | 6.10.0   |      |
| libfastcommon | 1.0.70 | 依赖 |
| libserverframe| 1.2.0  | 依赖 |



> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Middleware/fastdfs/fastdfs_data

2、docker run 运行【(使用宿主机网络访问),注意修改FASTDFS_IPADDR地址】
docker run -d --name fastdfs --restart=always -v /home/application/Middleware/fastdfs/fastdfs_data:/home/dfs/data -e FASTDFS_IPADDR="172.16.10.37" --network=host harbor.tsingyun.net/tsingyun-middleware/fastdfs:6.10.0
```


> 🐋 docker-compose 指令运行：


```
1、创建目录
mkdir -p /home/application/Middleware/fastdfs/fastdfs_data

2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Middleware/fastdfs/docker-compose.yml

3、运行docker-compose创建容器
docker-compose up -d
```