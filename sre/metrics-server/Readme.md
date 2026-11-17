# 一、Metrics-Server 介绍

​        Metrics-Server是k8s集群采集监控数据的聚合器，如采集node、pod的cpu、内存等数据，从 Kubernetes1.8 开始默认使用Metrics-Server采集数据，并通过Metrics API的形式提供查询，但是，kubeadm安装的k8s集群默认是没有安装Metrics-Server的。

![](https://s3.hi168.com:443/hi168-19497-0285lqya/images/202408231327969.png)

**⚠️ 注意：**

​      在 Kubernetes 1.7 版本引入了聚合层，允许第三方应用程序通过将自己注册到kube-apiserver上，仍然通过 API Server 的 HTTP URL 对新的 API 进行访问和操作。为了实现这个机制，Kubernetes 在 kube-apiserver 服务中引入了一个API 聚合层（API Aggregation Layer），用于将扩展 API 的访问请求转发到用户服务的功能。**如果你是kubadm 的部署方式，默认已开启Kubernetes API聚合层。**

* Metrics Server项目地址： https://github.com/kubernetes-sigs/metrics-server
* metrics-server版本与k8s版本对应关系:  https://github.com/kubernetes-sigs/metrics-server#compatibility-matrix
* 本次部署环境： K8S1.32 ，Metrics Server 0.8.0

![](https://s3.hi168.com:443/hi168-19497-0285lqya/images/20260126112717902.webp)

# 二、部署Metrics-Server

1. **下载 Metrics Server 的部署文件**:

   ```
   $ wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.0/components.yaml
   ```

2. **修改components.yaml 文件:**

   * 国内墙，需要替换 `registry.k8s.io/metrics-server/metrics-server:v0.8.0` 镜像地址为：`registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-server:v0.8.0`

   ```
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     labels:
       k8s-app: metrics-server
     name: metrics-server
     namespace: kube-system
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     labels:
       k8s-app: metrics-server
       rbac.authorization.k8s.io/aggregate-to-admin: "true"
       rbac.authorization.k8s.io/aggregate-to-edit: "true"
       rbac.authorization.k8s.io/aggregate-to-view: "true"
     name: system:aggregated-metrics-reader
   rules:
   - apiGroups:
     - metrics.k8s.io
     resources:
     - pods
     - nodes
     verbs:
     - get
     - list
     - watch
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     labels:
       k8s-app: metrics-server
     name: system:metrics-server
   rules:
   - apiGroups:
     - ""
     resources:
     - nodes/metrics
     verbs:
     - get
   - apiGroups:
     - ""
     resources:
     - pods
     - nodes
     verbs:
     - get
     - list
     - watch
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     labels:
       k8s-app: metrics-server
     name: metrics-server-auth-reader
     namespace: kube-system
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: Role
     name: extension-apiserver-authentication-reader
   subjects:
   - kind: ServiceAccount
     name: metrics-server
     namespace: kube-system
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     labels:
       k8s-app: metrics-server
     name: metrics-server:system:auth-delegator
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: system:auth-delegator
   subjects:
   - kind: ServiceAccount
     name: metrics-server
     namespace: kube-system
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     labels:
       k8s-app: metrics-server
     name: system:metrics-server
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: system:metrics-server
   subjects:
   - kind: ServiceAccount
     name: metrics-server
     namespace: kube-system
   ---
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       k8s-app: metrics-server
     name: metrics-server
     namespace: kube-system
   spec:
     ports:
     - appProtocol: https
       name: https
       port: 443
       protocol: TCP
       targetPort: https
     selector:
       k8s-app: metrics-server
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     labels:
       k8s-app: metrics-server
     name: metrics-server
     namespace: kube-system
   spec:
     selector:
       matchLabels:
         k8s-app: metrics-server
     strategy:
       rollingUpdate:
         maxUnavailable: 0
     template:
       metadata:
         labels:
           k8s-app: metrics-server
       spec:
         containers:
         - args:
           - --cert-dir=/tmp
           - --secure-port=10250
           - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
           - --kubelet-use-node-status-port
           - --metric-resolution=15s
           - --kubelet-insecure-tls
           #image: registry.k8s.io/metrics-server/metrics-server:v0.8.0
           image: registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-server:v0.8.0
           imagePullPolicy: IfNotPresent
           livenessProbe:
             failureThreshold: 3
             httpGet:
               path: /livez
               port: https
               scheme: HTTPS
             periodSeconds: 10
           name: metrics-server
           ports:
           - containerPort: 10250
             name: https
             protocol: TCP
           readinessProbe:
             failureThreshold: 3
             httpGet:
               path: /readyz
               port: https
               scheme: HTTPS
             initialDelaySeconds: 20
             periodSeconds: 10
           resources:
             requests:
               cpu: 100m
               memory: 200Mi
           securityContext:
             allowPrivilegeEscalation: false
             capabilities:
               drop:
               - ALL
             readOnlyRootFilesystem: true
             runAsNonRoot: true
             runAsUser: 1000
             seccompProfile:
               type: RuntimeDefault
           volumeMounts:
           - mountPath: /tmp
             name: tmp-dir
         nodeSelector:
           kubernetes.io/os: linux
         priorityClassName: system-cluster-critical
         serviceAccountName: metrics-server
         volumes:
         - emptyDir: {}
           name: tmp-dir
   ---
   apiVersion: apiregistration.k8s.io/v1
   kind: APIService
   metadata:
     labels:
       k8s-app: metrics-server
     name: v1beta1.metrics.k8s.io
   spec:
     group: metrics.k8s.io
     groupPriorityMinimum: 100
     insecureSkipTLSVerify: true
     service:
       name: metrics-server
       namespace: kube-system
     version: v1beta1
     versionPriority: 100
   ```

3.**部署 Metrics Server **: 

   ```
   $ kubectl apply -f components.yaml
   ```

4.**验证 Metrics Server 是否成功部署**:

   ```
   $ kubectl get pods -n kube-system -l k8s-app=metrics-server
   NAME                             READY   STATUS    RESTARTS   AGE
   metrics-server-74458669b-wvkkr   1/1     Running   0          130m
   ```

5. **使用 `kubectl top` 命令查看 Pods 和 Nodes 的资源使用情况**：

   ```
   $ kubectl top pods
   NAME                            CPU(cores)   MEMORY(bytes)   
   pig-auth-58f7855c76-cft8m       3m           523Mi           
   pig-codegen-7799896dd6-mzfhx    3m           633Mi           
   pig-gateway-65854c6b5c-l7rdc    2m           425Mi           
   pig-gateway-65854c6b5c-t64c9    2m           451Mi           
   pig-monitor-5b5c68bc4f-kt5hn    11m          457Mi           
   pig-mysql-c867c676f-6zs9z       7m           439Mi           
   pig-quartz-657d5c9f77-qx6q5     19m          509Mi           
   pig-quartz-657d5c9f77-sbszt     5m           484Mi           
   pig-redis-6dbccc7854-f786j      2m           8Mi             
   pig-register-798bc58678-rqrrn   7m           647Mi           
   pig-ui-5ff9bbdd7f-ld7mb         0m           3Mi             
   pig-upms-d9dcc697f-7cdhw        17m          575Mi           
   pig-upms-d9dcc697f-klx6z        17m          492Mi  
   
   
   $ kubectl top nodes
   NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
   k8s-master01   230m         5%     3026Mi          41%       
   k8s-master02   240m         6%     2399Mi          32%       
   k8s-master03   214m         5%     2221Mi          30%       
   k8s-node01     264m         6%     6663Mi          90%       
   ```

![](https://s3.hi168.com:443/hi168-19497-0285lqya/images/20260126124327525.webp)

