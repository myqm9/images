# vmware_exporter

> 🚀目前仅提供docker-compose 运行


| 名称             | 内容                                                         |
| ---------------- | ------------------------------------------------------------ |
| AMD64镜像镜像地址:        | harbor.tsingyun.net/tsingyun-middleware/vmware_exporter:0.18.4 |
| ARM64镜像镜像地址:        | harbor.tsingyun.net/tsingyun-middleware/vmware_exporter:0.18.4-arm64 |
| 版本：           | 0.18.4               |
| 项目地址:           | https://github.com/pryorda/vmware_exporter           |
| Trivy漏洞情况:   | Total: 0 2026-01-07 |


> 🐋 docker-compose 指令运行：


## 1、创建目录
```
mkdir -p /home/application/vmware_exporter
```

## 2、创建认证文件，env 环境配置文件
- vim /home/application/vmware_exporter/config.env
```
VSPHERE_USER=administrator@vsphere.local
VSPHERE_PASSWORD=xxxx
VSPHERE_HOST=xxx
VSPHERE_IGNORE_SSL=TRUE
VSPHERE_SPECS_SIZE=2000
```

- vim /home/application/vmware_exporter/web.config
> 使用 `htpasswd -nbBC 12 admin <password>` 获取 `$2b$...` 哈希

- 配置示例：
``` bash
basic_auth_users:
  prometheus: $2b$12$abcdefghijklmnopqrstuvwxYZ0123456789abcdefghijklmnopqrstuv
```


## 3、创建docker-compose.yaml 文件
- vim /home/application/vmware_exporter/docker-compose.yml
```
version: "3"
services:
  vmware_exporter:
    image: harbor.tsingyun.net/tsingyun-middleware/vmware_exporter:0.18.4
    container_name: vmware_exporter
    networks:
      - tsingyun
    restart: always
    ports:
      - "9272:9272"
    env_file:
      - ./config.env
    volumes:
      - ./web.config:/web.config:ro
    command:
      # 配置认证信息
      - '--web.config=/web.config'
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "9272"]
      interval: 30s      # 检测间隔
      timeout: 10s       # 单次检测超时时间
      retries: 3         # 连续失败3次后标记为不健康
      start_period: 60s  # 启动后60秒开始检测
networks:
  tsingyun:
    driver: bridge
```

## 4、运行docker-compose创建容器
docker-compose up -d

## 5、访问监控页面
http://xx:29116/metrics

![](https://s3.hi168.com:443/hi168-19497-0285lqya/images/20260107172858020.webp)

## 6、和prometheus集成
仅提供配置文件 prometheus.yaml
```
#vmware_exporter
  - job_name: 'vmware_vcenter'
    ## 认证信息
    basic_auth:
      username: prometheus
      password: xxxx
    metrics_path: '/metrics'
    static_configs:
    - targets: ['172.22.33.218:9272']
      labels:
        project_name: "Datacenter-srebro"
        nodename: "EXSI-172.1.5.17"
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - source_labels: [__address__]
        regex: '.*:9272$'
        target_label: datacenter
        replacement: 'Datacenter-srebro'
    ##用于标签值的自定义
    metric_relabel_configs:
      - action: replace
        target_label: host_name
        replacement: 'EXSI-172.1.5.17'  # 新值
      - action: replace
        target_label: dc_name
        replacement: 'EXSI-172.1.5.17'  # 新值
```

