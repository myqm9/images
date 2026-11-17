# 基于 NFS 的 Kubernetes StorageClass 动态供给部署指南

# 一、StorageClass介绍
StorageClass 用于描述集群中的“存储类型”和动态供给策略。它把后端存储（如 NFS、Ceph、云盘）的供给逻辑抽象为一个“provisioner”，并通过 parameters 传递供给参数。应用只需在 PVC 中声明 storageClassName，即可按需创建 PV。

- provisioner：指定供给器的唯一名称，必须与供给器部署时的环境变量保持一致
- parameters：供给器的行为配置，例如是否在删除 PVC 时保留数据
- reclaimPolicy：PV 的回收策略，通常由系统默认或 StorageClass 设定

本实验使用 nfs-subdir-external-provisioner 作为动态供给器，它会在 NFS 后端的指定目录下为每个 PVC 创建一个子目录，实现按需供给。

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-dynamic
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
parameters:
  archiveOnDelete: "false"
```

# 二、NFS介绍
NFS（Network File System）是基于网络的文件系统协议，允许多个主机通过网络共享同一目录。其在 Kubernetes 中常用于共享型持久化存储场景，典型特征是支持 ReadWriteMany（RWX），适合多副本工作负载共享同一数据目录。

- 优点：简易、通用、支持 RWX、和现有基础设施容易集成
- 注意：网络和 NFS 服务器性能会影响 IO；生产环境应考虑权限隔离、备份与高可用
- 先决条件：K8s 节点需安装 NFS 客户端（如 nfs-utils / nfs-common），并能访问 NFS 服务器端口（一般为 2049 等）

# 三、实验介绍
本实验在现有 NFS 服务基础上，部署 nfs-subdir-external-provisioner，实现 PVC 的动态供给，并通过示例 Pod 验证挂载与读写。

## 3.1、环境介绍
- Kubernetes 集群已可用
- NFS 服务器：`172.22.33.100`
- NFS 共享路径：`/home/application/nfs/data`
- 供给器命名空间：`kube-nfs`

## 3.2、安装配置nfs服务
如果尚未配置 NFS 服务，需在服务器上完成以下步骤（示例）：

1. 安装 NFS 服务端（不同发行版命令略有差异）  
   - Debian/Ubuntu：`apt install -y nfs-kernel-server`  
   - CentOS/RHEL：`yum install -y nfs-utils`
2. 创建共享目录：`mkdir -p /home/application/nfs/data`
3. 配置导出（编辑 `/etc/exports`）：
   ```
   /home/application/nfs/data *(insecure,rw,sync,no_root_squash)
   ```
4. 启动并刷新导出：
   - `systemctl start nfs-server`
   - `exportfs -arv`
5. 验证：
   - `showmount -e 172.22.33.100` 应显示共享目录
   - 确保 K8s 节点能访问nfs 服务器

# 四、PersistenVolume动态供给部署
本节基于以下文件完成部署与验证：

步骤如下：

1. 创建命名空间
   ```bash
   kubectl create namespace kube-nfs
   ```

2. 配置 RBAC（见 [rbac.yaml]）
   该文件创建供给器使用的 ServiceAccount、ClusterRole/Binding，以及 leader 选举所需的 Role/Binding：
   
   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: kube-nfs
   ---
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: nfs-client-provisioner-runner
   rules:
     - apiGroups: [""]
       resources: ["nodes"]
       verbs: ["get", "list", "watch"]
     - apiGroups: [""]
       resources: ["persistentvolumes"]
       verbs: ["get", "list", "watch", "create", "delete"]
     - apiGroups: [""]
       resources: ["persistentvolumeclaims"]
       verbs: ["get", "list", "watch", "update"]
     - apiGroups: ["storage.k8s.io"]
       resources: ["storageclasses"]
       verbs: ["get", "list", "watch"]
     - apiGroups: [""]
       resources: ["events"]
       verbs: ["create", "update", "patch"]
   ---
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: run-nfs-client-provisioner
   subjects:
     - kind: ServiceAccount
       name: nfs-client-provisioner
       # replace with namespace where provisioner is deployed
       namespace: kube-nfs
   roleRef:
     kind: ClusterRole
     name: nfs-client-provisioner-runner
     apiGroup: rbac.authorization.k8s.io
   ---
   kind: Role
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: leader-locking-nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: kube-nfs
   rules:
     - apiGroups: [""]
       resources: ["endpoints"]
       verbs: ["get", "list", "watch", "create", "update", "patch"]
   ---
   kind: RoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: leader-locking-nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: kube-nfs
   subjects:
     - kind: ServiceAccount
       name: nfs-client-provisioner
       # replace with namespace where provisioner is deployed
       namespace: kube-nfs
   roleRef:
     kind: Role
     name: leader-locking-nfs-client-provisioner
     apiGroup: rbac.authorization.k8s.io
   ```
   应用：
   ```bash
   kubectl apply -f rbac.yaml
   ```
   
3. 部署供给器（见 [deployment.yaml]）  
   关键点：
   
   - `serviceAccountName: nfs-client-provisioner` 与上一步创建的 SA 对应
   - `PROVISIONER_NAME` 必须与 StorageClass 的 `provisioner` 完全一致：`k8s-sigs.io/nfs-subdir-external-provisioner`
   - `NFS_SERVER` 与 `NFS_PATH` 指向实际 NFS 服务
   - `volumes.nfs.server/path` 与环境变量保持一致
   示例片段：
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nfs-client-provisioner
     labels:
       app: nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: kube-nfs
   spec:
     replicas: 2
     strategy:
       type: Recreate
     selector:
       matchLabels:
         app: nfs-client-provisioner
     template:
       metadata:
         labels:
           app: nfs-client-provisioner
       spec:
         serviceAccountName: nfs-client-provisioner
         containers:
           - name: nfs-client-provisioner
             #image: registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
             image: docker.cnb.cool/sre-demo/k8s-demo/registry.k8s.io-sig-storage-nfs-subdir-external-provisioner:v4.0.2_amd64
             volumeMounts:
               - name: nfs-client-root
                 mountPath: /persistentvolumes
             env:
               - name: PROVISIONER_NAME
                 value: k8s-sigs.io/nfs-subdir-external-provisioner
               - name: NFS_SERVER
                 value: 172.22.33.100
               - name: NFS_PATH
                 value: /home/application/nfs/data
         volumes:
           - name: nfs-client-root
             nfs:
               server: 172.22.33.100
               path: /home/application/nfs/data
   ```
   应用：
   ```bash
   kubectl apply -f deployment.yaml
   kubectl -n kube-nfs get pods
   ```
   Pod 应处于 Running 状态；若失败，检查镜像拉取、NFS 可达性、节点是否安装 NFS 客户端。
   
4. 创建 StorageClass（见 [class.yaml]）
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-dynamic
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  archiveOnDelete: "false"
```
   ```bash
   kubectl apply -f class.yaml
   kubectl get sc
   ```
   应看到 `nfs-dynamic` 已创建，且 `provisioner` 为 `k8s-sigs.io/nfs-subdir-external-provisioner`。

5. 测试 PVC 与挂载（见 [nfs-pvc-test.yaml]）
   该文件创建一个 `ReadWriteMany` 的 PVC，并启动一个 Pod 挂载到 `/mnt`，在容器中创建 `/mnt/SUCCESS` 文件以验证写入：
   
   ```yaml
   ---
   kind: PersistentVolumeClaim
   apiVersion: v1
   metadata:
     name: test-claim
   spec:
     storageClassName: nfs-dynamic
     accessModes:
       - ReadWriteMany
     resources:
       requests:
         storage: 1Mi
   
   ---
   kind: Pod
   apiVersion: v1
   metadata:
     name: test-pod
   spec:
     containers:
     - name: test-pod
       #image: busybox:stable
       image: docker.cnb.cool/sre-demo/k8s-demo/busybox:stable_amd64
       command:
         - "/bin/sh"
       args:
         - "-c"
         - "touch /mnt/SUCCESS && exit 0 || exit 1"
       volumeMounts:
         - name: nfs-pvc
           mountPath: "/mnt"
     restartPolicy: "Never"
     volumes:
       - name: nfs-pvc
         persistentVolumeClaim:
           claimName: test-claim
   ```
   应用并验证：
   ```bash
   kubectl apply -f nfs-pvc-test.yaml
   kubectl get pvc
   kubectl get pv
   kubectl get pod test-pod
   kubectl logs test-pod
   ```
   - PVC 状态应为 `Bound`，PV 自动创建并绑定
   - Pod 退出码为 0，日志为空或正常，NFS 目录下应出现对应子目录与 `SUCCESS` 文件

# 五、其他

* 本文所涉及的 yaml 文件， 见： https://cnb.cool/sre-demo/k8s-demo
