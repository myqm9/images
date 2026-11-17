#tsingyun-emqx


> 🚀目前仅提供docker 和 docker-compose 运行


| 名称                 | 内容                                                         |
| -------------------- | ------------------------------------------------------------ |
| 基础镜像:            | debian:13-slim                                                 |
| 版本：               | 5.8.9                                                        |
| AMD64镜像地址             | dockerhub.qingcloud.com/tsingyun_middleware/emqx:5.8.9       |
| ARM64镜像地址             | dockerhub.qingcloud.com/tsingyun_middleware/emqx:5.8.9-arm64       |
| Trivy漏洞情况:       | Total: 24 (UNKNOWN: 0, LOW: 11, MEDIUM: 13, HIGH: 0, CRITICAL: 0)   2025/03/31 |
| 操作系统设配：       | ⚠️ openeuler 22.03 LTS SP3 上可运行，emqx5.8版本需要openssl-1.1.1 以上 【centos7.9 不支持】 |
| 官网Dockerfile地址： | https://github.com/emqx/emqx-docker                          |



> 🐋 docker 指令运行：

```
1、创建目录
mkdir -p /home/application/Middleware/emqx/{log,data}

2、赋权【不然会提示mkdir: cannot create directory ‘/opt/emqx/data/configs’: Permission denied 】
chmod -Rf 777 /home/application/Middleware/emqx/{log,data}

2、docker run 运行
docker run -d --name emqx -p 18083:18083 -p 1883:1883 -p 18080:8081 -p 18883:8883 -v /home/application/Middleware/emqx/log:/opt/emqx/log -v /home/application/Middleware/emqx/data:/opt/emqx/data dockerhub.qingcloud.com/tsingyun_middleware/emqx:5.8.9

```

3、登录dashbord 修改密码，创建本地认证方式，并创建用户

* 控制台默认密码  admin/public
参考语雀： https://tsingyun.yuque.com/mgg7g9/doc/gwzgai5zrbvrb8dh#bhJCr

> 🐋 docker-compose 指令运行：

```
1、创建目录
mkdir -p /home/application/Middleware/emqx/{log,data}
chmod -Rf 777 /home/application/Middleware/emqx/{log,data}

2、创建docker-compose.yaml 文件，见 docker-compose.yaml 文件
vim /home/application/Middleware/emqx/docker-compose.yml

3、运行docker-compose创建容器
docker-compose up -d


```