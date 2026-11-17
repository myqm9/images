---
title: 系统初始化配置
draft: false
sidebar:
  order: 1
---

系统安装完成后，需执行以下基础初始化操作。

## 关闭防火墙与 SELinux

```bash
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 临时关闭 SELinux
setenforce 0
# 永久关闭 SELinux
sed -i "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
```

## 系统参数调优（文件描述符与进程数）

```bash
# 修改 /etc/security/limits.conf
cat >> /etc/security/limits.conf << eof
root soft nofile 65535
root hard nofile 65535
root soft nproc 65535
root hard nproc 65535
root soft core unlimited
root hard core unlimited
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
* soft core unlimited
* hard core unlimited
eof

# 清理旧的 nproc 限制
cd /etc/security/limits.d/
rm -rf  *-nproc.conf
```

## 时间与时区配置

```bash
# 设置时区为上海
timedatectl set-timezone Asia/Shanghai

# 设置 24 小时制显示
echo "export LC_TIME=zh_CN.UTF-8" >> /etc/profile

# 配置时间同步 (Crontab 方式)
# 注意：生产环境推荐配置 Chrony 服务指向内网 NTP 服务器地址
echo "0 */1 * * * /usr/sbin/ntpdate -u ntp.aliyun.com" >> /var/spool/cron/root
```

## 优化历史命令记录（审计需求）

```bash
# 在 /etc/profile 中追加以下内容，记录操作时间、用户和来源IP
cat >> /etc/profile << 'EOF'
HISTFILESIZE=4000
HISTSIZE=4000
USER_IP=`who -u am i 2>/dev/null| awk '{print $NF}'|sed -e 's/[()]//g'`
if [ -z $USER_IP ]
then
USER_IP=`hostname`
fi
HISTTIMEFORMAT="[%F %T] [`whoami`]      [${USER_IP}]    "
export HISTTIMEFORMAT
EOF

source /etc/profile
```

## 创建运维账号

创建 `tsingyun-ops` 运维用户，指定密码。并配置 sudo 权限，避免日常运维直接使用 root 远程登录。

```bash
# 1. 创建用户并设置密码
useradd -m -s /bin/bash tsingyun-ops && echo "xxxx" | passwd --stdin ops

# 2. 配置 sudo 权限 (将用户添加到whell用户组里)
usermod -G wheel tsingyun-ops

# 3. 查看 tsingyun-ops 用户
id tsingyun-ops
uid=1000(tsingyun-ops) gid=1000(tsingyun-ops) groups=1000(tsingyun-ops),10(wheel)
```

## 创建业务开发账号

创建 `tsingyun` 普通用户，指定密码。用于登陆服务器查看日志。

```bash
# 1. 创建用户并设置密码
useradd -m -s /bin/bash tsingyun && echo "xxxx" | passwd --stdin tsingyun

# 2. 查看用户
id tsingyun
# uid=1001(tsingyun) gid=1001(tsingyun) groups=1001(tsingyun)
```

## 初始化数据盘

格式化数据盘 `/dev/sdb` 并挂载至 `/home/application`。

```bash
# 1. 创建挂载目录
mkdir -p /home/application

# 2. 格式化磁盘 (XFS)
mkfs.xfs -f /dev/sdb

# 3. 挂载磁盘
mount /dev/sdb /home/application

# 4. 配置开机自启 (修改 /etc/fstab)
sed -i '$a /dev/sdb /home/application xfs defaults 0 0' /etc/fstab

# 5. 验证挂载
df -h /home/application
```

## 安装基础运维工具

> 原则：先全量挂载磁盘，后安装软件。如果有互联网可直接安装软件。

### 方式一：互联网环境（推荐）

如果服务器可访问互联网，直接执行以下命令安装：

```bash
yum install vim make zlib-devel nc wget psmisc gcc-c++ gcc lrzsz telnet net-tools cifs-utils ntpdate bash-completion sysstat iotop iftop htop unzip tar nmap bc bind-utils nethogs nfs-utils network-scripts -y
```

### 方式二：内网环境（挂载全量镜像源）

#### 准备镜像与目录

从 OpenEuler 官网下载完整镜像（见交付物清单）：

[openEuler-22.03-LTS-SP4-everything-x86_64-dvd.iso](https://dl-cdn.openeuler.openatom.cn/openEuler-22.03-LTS-SP4/ISO/x86_64/openEuler-22.03-LTS-SP4-everything-x86_64-dvd.iso)

上传该 ISO 到 `/home/application/` 目录下。

```plain
#校验md5地址
md5sum /home/application/openEuler-22.03-LTS-SP4-everything-x86_64-dvd.iso

4c8a84423e7a73aa20f792564921ae602b9c80a17342928adfcc8420a1aaf7a9
```

#### 挂载镜像并拷贝软件包

```bash
#创建临时挂载点
mkdir -p /media/iso

#挂载光盘
mount -o loop /home/application/openEuler-22.03-LTS-SP4-everything-x86_64-dvd.iso /media/iso

#创建软件目录
mkdir -p /home/application/all_packages_iso

#从光盘中拷贝所以内容到软件目录下
cp -rp /media/iso/* /home/application/all_packages_iso/

# 卸载光盘
umount /media/iso
```

#### 配置 Yum 源

```bash
# 备份原有源
cd /etc/yum.repos.d/
mkdir -p bak
mv *.repo ./bak/

# 创建本地源配置文件
cat > /etc/yum.repos.d/Local.repo << EOF
[Local]
name=Local Yum
baseurl=file:///home/application/all_packages_iso
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-openEuler
EOF
```

#### 更新缓存并安装

```bash
yum clean all
yum makecache

# 导入 GPG 公钥
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-openEuler

# 安装工具
yum install vim make zlib-devel nc wget psmisc gcc-c++ gcc lrzsz telnet net-tools cifs-utils ntpdate bash-completion sysstat iotop iftop htop unzip tar nmap bc bind-utils nethogs nfs-utils network-scripts -y
```
