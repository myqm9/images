* 官方地址
```
https://github.com/projectcalico/calico/blob/v3.27.0/manifests/calico.yaml
```

* 版本：v3.27.0


* 使用方法:
    下载完后还需要修改里面定义Pod网络（CALICO_IPV4POOL_CIDR），与前面kubeadm init指定的  
`--pod-network-cidr=10.244.0.0/16`  保持一致； `默认是 192.168.0.0/16`

```
$ kubectl apply -f calico.yaml
$ kubectl get pods -n kube-system
```




