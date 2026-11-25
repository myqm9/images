# MySQL 8.4

此目录可独立构建 MySQL 8.4.13.1 镜像。基础镜像为 Oracle Linux 9 Slim，支持 `linux/amd64` 和 `linux/arm64`。

在仓库根目录运行以下命令构建镜像：

```bash
docker build -t local/mysql:8.4.13.1 Middleware/mysql_8.4
```

首次启动时，使用 `MYSQL_ROOT_PASSWORD` 设置 root 密码，并将数据卷挂载到 `/var/lib/mysql`。初始化脚本可挂载到 `/docker-entrypoint-initdb.d`，只在首次初始化时执行。镜像使用说明见 [Docker Hub](https://hub.docker.com/_/mysql/)。

Dockerfile 和入口脚本来自 [docker-library/mysql 的固定提交](https://github.com/docker-library/mysql/tree/b5f66ae30918ed92c170f6c9ba5dd662fccbe66c/8.4)，上游许可证见 [LICENSE](LICENSE)。
