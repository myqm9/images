MetalLB 配置说明
================

一、概述
--------
MetalLB 是一个为 Kubernetes 集群提供 LoadBalancer 类型服务的网络负载均衡器。
本目录包含 MetalLB 的部署清单和配置示例。

二、文件说明
-----------
1. metallb-native.yaml
   - MetalLB 官方原生部署清单（v0.13.x）
   - 包含完整的 CRD 定义和组件部署
   - 使用 kubectl apply -f metallb-native.yaml 部署

2. config.yaml
   - MetalLB 配置示例
   - 定义 IP 地址池和网络广播方式
   - 使用 kubectl apply -f config.yaml 部署

三、配置说明
-----------
config.yaml 中的配置包括：

1. IPAddressPool (first-pool)
   - 名称：first-pool
   - IP 范围：172.22.33.120-172.22.33.129
   - 用于为 LoadBalancer 类型 Service 分配外部 IP

2. L2Advertisement (example)
   - 模式：Layer 2 (ARP/NDP)
   - 关联 IPAddressPool：first-pool
   - 通过 ARP/NDP 广播实现负载均衡

四、部署步骤
-----------
1. 部署 MetalLB 组件：
   kubectl apply -f metallb-native.yaml

2. 部署 MetalLB 配置：
   kubectl apply -f config.yaml

3. 验证部署状态：
   kubectl get pods -n metallb-system

五、注意事项
-----------
- 确保节点网络可以访问分配的 IP 范围
- 如需修改 IP 地址池，请编辑 config.yaml 后重新应用
- Layer 2 模式下，所有流量会经过一个节点转发
