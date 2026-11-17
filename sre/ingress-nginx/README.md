
这是一个整合了 Ingress-NGINX v1.14.3 部署、配置修改以及外部 HAProxy 负载均衡器的完整部署文档。

😭 截止发文前，Ingress NGINX 宣布退役，官方宣布尽力维护将持续至2026年3月。

下面的内容只是为了纪念。🐶

该方案的架构目标是：**全节点覆盖（DaemonSet）** + **本地流量转发（Local）** + **真实 IP 透传（Proxy Protocol）**

---

![k8s3 主 3 从](https://s3.hi168.com:443/hi168-19497-0285lqya/images/20260203144755614.webp)

## 1. 架构与环境说明

*   **一个 3 主 3 从的 K8s 集群,k8s 版本: 1.32**
*   **Ingress 版本**: v1.14.3
*   **部署模式**: DaemonSet (覆盖所有 Node 节点)
*   **流量策略**: `externalTrafficPolicy: Local` (仅接收本机流量，防止 SNAT 丢失 IP)
*   **IP 透传技术**: Proxy Protocol (v2)
*   **节点规划**:
    *   **HAProxy (外部 LB)**: `172.22.33.100`  负责K8s API Server 转发 (6443)，负责Ingress HTTPS 流量转发 (443 -> NodePort 32443)
    *   **K8s master Nodes**：`172.22.33.101`, `172.22.33.102`, `172.22.33.103`
    *   **K8s Worker Nodes**: `172.22.33.110`, `172.22.33.111`, `172.22.33.112`

---

## 2. 第一步：部署外部负载均衡器 (HAProxy)

我们需要在 K8s 集群外部（或独立节点）部署 HAProxy，负责将流量分发到各个 Worker 节点的 NodePort 上，并封装 Proxy Protocol 包头。

### 2.1 安装 HAProxy
在节点 `172.22.33.100` 上执行：

```bash
# CentOS/OpenEuler/RHEL
yum -y install haproxy
```

### 2.2 配置 HAProxy
编辑 `/etc/haproxy/haproxy.cfg`

**关键配置点**：

*   后端 server 必须开启 `send-proxy-v2`，这是 Ingress 能获取真实 IP 的前提。
*   端口需与后续 Ingress Service 定义的 NodePort (`32443`) 对应，最外侧的 4 层负载均衡只做 443 端口的转发，整个 K8s ingress nginx 使用 https 方式访问。
*   这里 K8s API Server 转发 (6443) 的部署过程忽略，可以参考 k8s 的部署文档： https://blog.srebro.cn/archives/102

```haproxy
global
    log /dev/log  local0 warning
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats

defaults
    log global
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client 50000
    timeout server 50000

# K8s API Server 转发 (6443)
frontend kube-apiserver
    bind *:6443
    mode tcp
    option tcplog
    default_backend kube-apiserver

backend kube-apiserver
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server kube-apiserver-1 172.22.33.101:6443 check
    server kube-apiserver-2 172.22.33.102:6443 check
    server kube-apiserver-3 172.22.33.103:6443 check

# Ingress HTTPS 流量转发 (443 -> NodePort 32243)
frontend kube-https
    bind *:443
    mode tcp
    option tcplog
    default_backend kube-https

backend kube-https
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    # 关键点：端口 32243 对应 Ingress NodePort
    # 关键点：send-proxy-v2 启用 Proxy Protocol 协议
    server kube-node01 172.22.33.110:32243 send-proxy-v2 check
    server kube-node02 172.22.33.111:32243 send-proxy-v2 check
    server kube-node03 172.22.33.112:32243 send-proxy-v2 check
```

### 2.3 启动服务
```bash
systemctl enable haproxy
systemctl start haproxy
systemctl status haproxy
```

---

## 3. 第二步：部署 Ingress-NGINX (K8s侧)

在 Master 节点操作。首先下载 v1.14.3的官方 YAML：

```bash
wget https://github.com/kubernetes/ingress-nginx/blob/controller-v1.14.3/deploy/static/provider/cloud/deploy.yaml -O ingress-nginx.yaml
# 如果下载失败，可访问我的代理仓库
```

对 `ingress-nginx.yaml` 进行如下**三处关键修改**：

### 3.1 修改 ConfigMap (开启 Proxy Protocol)
找到 `kind: ConfigMap` 且 `name: ingress-nginx-controller` 的部分，修改 `data` 如下：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.14.3
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  # 开启 Proxy Protocol 接收，必须与 HAProxy 的 send-proxy-v2 配合
  use-proxy-protocol: "true"
  # 解析完整链路 IP
  compute-full-forwarded-for: "true"
  # 指定 Header 名称
  forwarded-for-header: "X-Forwarded-For"
```

### 3.2 修改 Controller (Deployment -> DaemonSet)
为了保证每个 Worker 节点都有 Ingress 实例（配合 Local 策略），需将控制器类型改为 DaemonSet。

找到 `kind: Deployment` 且 `name: ingress-nginx-controller` 的部分：
1.  修改 `kind: Deployment` 为 `kind: DaemonSet`。
1.  修改滚动更新策略： 由 `spec.strategy` 变成 `spec.updateStrategy`。
3.  修改镜像版本为国内镜像加速地址。`docker.cnb.cool/sre-demo/k8s-demo/registry.k8s.io-ingress-nginx-controller:v1.14.3_amd64` ,  `docker.cnb.cool/sre-demo/k8s-demo/registry.k8s.io-ingress-nginx-kube-webhook-certgen:v1.6.7_amd64`

``` yaml
---
apiVersion: apps/v1
kind: DaemonSet # 1. 修改这里
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.14.3
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  minReadySeconds: 0
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app.kubernetes.io/component: controller
      app.kubernetes.io/instance: ingress-nginx
      app.kubernetes.io/name: ingress-nginx
  updateStrategy:  # 2. 修改滚动更新策略
    rollingUpdate:
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app.kubernetes.io/component: controller
        app.kubernetes.io/instance: ingress-nginx
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
        app.kubernetes.io/version: 1.14.3
    spec:
      automountServiceAccountToken: true
      containers:
      - args:
        - /nginx-ingress-controller
        - --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
        - --election-id=ingress-nginx-leader
        - --controller-class=k8s.io/ingress-nginx
        - --ingress-class=nginx
        - --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
        - --validating-webhook=:8443
        - --validating-webhook-certificate=/usr/local/certificates/cert
        - --validating-webhook-key=/usr/local/certificates/key
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: LD_PRELOAD
          value: /usr/local/lib/libmimalloc.so
        image: docker.cnb.cool/sre-demo/k8s-demo/registry.k8s.io-ingress-nginx-controller:v1.14.3_amd64
        # 3.0 修改镜像加速地址
        #####需要修改3处镜像地址######
        imagePullPolicy: IfNotPresent
        lifecycle:
          preStop:
            exec:
              command:
              - /wait-shutdown
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        name: controller
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        - containerPort: 443
          name: https
          protocol: TCP
        - containerPort: 8443
          name: webhook
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        resources:
          requests:
            cpu: 100m
            memory: 90Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - ALL
          readOnlyRootFilesystem: false
          runAsGroup: 82
          runAsNonRoot: true
          runAsUser: 101
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - mountPath: /usr/local/certificates/
          name: webhook-cert
          readOnly: true
      dnsPolicy: ClusterFirst
      nodeSelector:
        kubernetes.io/os: linux
      serviceAccountName: ingress-nginx
      terminationGracePeriodSeconds: 300
      volumes:
      - name: webhook-cert
        secret:
          secretName: ingress-nginx-admission
```



### 3.3 修改 Service (NodePort + Local + 端口对齐)

确保 Service 暴露 NodePort，且端口与 HAProxy 配置的后端端口一致 (`32443`)。

找到 `kind: Service` 且 `name: ingress-nginx-controller` 的部分：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/version: 1.14.3
spec:
  type: NodePort                    # 1. 类型改为 NodePort
  externalTrafficPolicy: Local      # 2. 策略改为 Local (关键：保留源 IP)
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - appProtocol: http
    name: http
    port: 80
    protocol: TCP
    targetPort: http
    nodePort: 32280                 # 3. 固定 HTTP 端口
  - appProtocol: https
    name: https
    port: 443
    protocol: TCP
    targetPort: https
    nodePort: 32443                 # 4. (必须) 固定 HTTPS 端口，与 HAProxy 配置一致
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
```

### 3.4 执行部署
```bash
$ kubectl apply -f ingress-nginx.yaml
```

---

## 4. 验证部署结果

### 4.1 检查 Pod 状态
确保每个 Worker 节点上都运行了一个 Ingress Pod。
```bash
[root@k8s-master01 ingress-nginx-v1.14.3]# kubectl get pods -n ingress-nginx -o wide
NAME                             READY   STATUS    RESTARTS   AGE     IP               NODE         NOMINATED NODE   READINESS GATES
ingress-nginx-controller-jt9xc   1/1     Running   0          8m24s   10.244.58.236    k8s-node02   <none>           <none>
ingress-nginx-controller-pwvm5   1/1     Running   0          8m24s   10.244.135.163   k8s-node03   <none>           <none>
ingress-nginx-controller-rskkc   1/1     Running   0          8m24s   10.244.85.241    k8s-node01   <none>           <none>
```

### 4.2 检查 Service 策略
确认策略已生效。
```bash
$ kubectl get svc -n ingress-nginx ingress-nginx-controller -o yaml | grep externalTrafficPolicy
# 预期输出：externalTrafficPolicy: Local
```

### 4.3 真实 IP 验证
部署一个测试应用（Demo），并通过域名访问

* 指定「可信代理服务器的 IP 段」，10.244.0.0/16 是k8s 的子网地址，表示信任只信任这段ip的代理头，即任何代理传递的 X-Forwarded-For都被认为是合法的，一般我们会添加上游服务器的 IP 地址。 `set_real_ip_from 10.244.0.0/16`
* 指定「从哪个 HTTP 头中提取真实客户端 IP ,`real_ip_header X-Forwarded-For` 
* 递归跳过可信代理 IP，取第一个非可信 IP（真实客户端 IP）`real_ip_recursive on`

``` yaml
# main-app.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-main-conf
  namespace: default
data:
  nginx.conf: |
    user  nginx;
    worker_processes  auto;

    error_log  /var/log/nginx/error.log notice;
    pid        /run/nginx.pid;

    events {
        worker_connections  1024;
    }

    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        set_real_ip_from 10.244.0.0/16;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        keepalive_timeout  65;

        include /etc/nginx/conf.d/*.conf;
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: main-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: main-app
  template:
    metadata:
      labels:
        app: main-app
    spec:
      containers:
        - name: main-app
          image: nginx:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-main-conf
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
              readOnly: true
      volumes:
        - name: nginx-main-conf
          configMap:
            name: nginx-main-conf
---
apiVersion: v1
kind: Service
metadata:
  name: main-app-service
  namespace: default
spec:
  type: ClusterIP
  selector:
    app: main-app
  ports:
    - name: http
      port: 80
      targetPort: 80
```

查看服务状态：

```
#apply
$ kubectl apply -f main-app.yaml

#查看资源
$ kubectl get all -n default 
NAME                           READY   STATUS    RESTARTS   AGE
pod/main-app-895f5b55d-d6hlf   1/1     Running   0          9s

NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP   18d
service/main-app-service   ClusterIP   10.106.241.190   <none>        80/TCP    10d

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/main-app   1/1     1            1           9s

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/main-app-895f5b55d   1         1         1       9s
```

 配置 Ingress 域名

- 配置一个 TLS Secret 证书，将提前准备好的域名证书导入到 k8s 的 default 命名空间下的 secret 中

``` yaml
$ kubectl create secret tls srebro.cn-tls \
  --cert=srebro.cn.pem \
  --key=srebro.cn.key \
  --namespace=default
```

- 创建一个 ingress 规则指定到一个域名上，如 demo.srebro.cn

``` yaml
#ingress.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: baseline-sre-test-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    # 可选：强制 HTTPS 重定向
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - demo.srebro.cn
    secretName: srebro.cn-tls
  rules:
  - host: demo.srebro.cn
    http:
      paths:
      - path: /()(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: main-app-service
            port:
              number: 80
```

查看ingress资源：
```
#创建ingress
$ kubectl apply -f ingress.yaml 
ingress.networking.k8s.io/baseline-sre-test-ingress created

$ kubectl get ingress
NAME                        CLASS   HOSTS            ADDRESS          PORTS     AGE
baseline-sre-test-ingress   nginx   demo.srebro.cn   10.104.185.248   80, 443   45s
```

记得修改本地 hosts ， `demo.srebro.cn `指向 HAProxy IP `172.22.33.100`

![](https://s3.hi168.com:443/hi168-19497-0285lqya/images/20260203171314204.webp)

![image-20260203173842259](https://s3.hi168.com:443/hi168-19497-0285lqya/images/20260203173842493.webp)

查看测试应用的日志：

```bash
kubectl logs -f <业务Pod名称>
```
**成功标志**：日志中的 `$remote_addr` 或 `X-Forwarded-For` 显示的是你客户端的IP，而不是K8s 集群内部地址。

![image-20260203174000054](https://s3.hi168.com:443/hi168-19497-0285lqya/images/20260203174000509.webp)

---

## 5. 其他

* 本文所涉及的资源文件见： https://cnb.cool/sre-demo/k8s-demo/-/tree/main/yaml/v1.32/ingress-nginx
* ingress-nginx 生命周期截止2026.3，后续官方也不会再提供更新服务。https://github.com/kubernetes/ingress-nginx/tree/main 祝好！
* 大家可以切换到其他的 ingress 控制器上，比如traefik,higress,或者其他。