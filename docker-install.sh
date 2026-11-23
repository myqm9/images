#!/bin/bash

# ========================================
# Docker 通用安装脚本
# 版本: v2.0
# 支持系统: CentOS/RHEL/OpenEuler (YUM) 和 Ubuntu/Debian (APT)
# 作者: srebro
# 更新日期: $(date '+%Y-%m-%d')
# ========================================

# ========================================
# 配置区域 - 统一管理下载地址和版本信息
# 说明: 修改此区域的配置可以快速更新版本和下载源
# ========================================

# Docker 相关配置
DOCKER_VERSION="20.10.24"
DOCKER_DOWNLOAD_URL="https://mirrors.nju.edu.cn/docker-ce/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"

# Docker Compose 相关配置
DOCKER_COMPOSE_VERSION="2.10.2"
DOCKER_COMPOSE_DOWNLOAD_URL="https://cnb.cool/srebro/docker-images/-/releases/download/V1.0.0/docker-compose-linux-x86_64_${DOCKER_COMPOSE_VERSION}"

# Docker 镜像加速相关配置
DEFAULT_REGISTRY_MIRROR="https://docker.xuanyuan.me"

# 默认工作目录
DEFAULT_DOCKER_WORKDIR="/home/application/docker"

# 脚本版本信息
SCRIPT_VERSION="v2.0"
SCRIPT_DATE="$(date '+%Y-%m-%d')"

# ========================================
# 配置验证函数
# ========================================

# 验证配置是否完整
validate_config() {
    local missing_vars=()
    
    # 检查必要的配置变量
    [ -z "$DOCKER_VERSION" ] && missing_vars+=("DOCKER_VERSION")
    [ -z "$DOCKER_DOWNLOAD_URL" ] && missing_vars+=("DOCKER_DOWNLOAD_URL")
    [ -z "$DOCKER_COMPOSE_VERSION" ] && missing_vars+=("DOCKER_COMPOSE_VERSION")
    [ -z "$DOCKER_COMPOSE_DOWNLOAD_URL" ] && missing_vars+=("DOCKER_COMPOSE_DOWNLOAD_URL")
    [ -z "$DEFAULT_REGISTRY_MIRROR" ] && missing_vars+=("DEFAULT_REGISTRY_MIRROR")
    [ -z "$DEFAULT_DOCKER_WORKDIR" ] && missing_vars+=("DEFAULT_DOCKER_WORKDIR")
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        color_echo $RED "错误: 以下配置变量未设置:"
        for var in "${missing_vars[@]}"; do
            color_echo $RED "  - $var"
        done
        exit 1
    fi
    
    color_echo $GREEN "配置验证通过 ✅"
}

# ========================================
# 颜色定义和基础函数
# ========================================

# 定义颜色代码
RED='\033[0;31m'    # 红色
GREEN='\033[0;32m'  # 绿色
YELLOW='\033[0;33m' # 黄色
NC='\033[0m'        # No Color (默认颜色，重置颜色)

# 颜色输出函数
color_echo() {
    COLOR=$1
    shift
    echo -e "${COLOR}$*${NC}"
}

# 通用确认对话框函数
confirm_action() {
    whiptail --title "确认" --yesno "是否继续？" 10 60
    return $?
}

# 进度条显示函数, 持续 0.5 秒
show_progress_bar() {
    if pgrep -x "whiptail" > /dev/null; then
        color_echo $YELLOW "一个进度条正在运行，请稍候..."
        return
    fi

    {
        for ((i = 0; i <= 100; i += 20)); do
            sleep 0.1
            echo $i
        done
    } | whiptail --gauge "请稍候, 正在执行操作..." 6 60 0
}

# 定义一个全局的备份时间
bak_date=$(date "+%Y%m%d%H%M")

# 系统检测函数
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        OS=openSUSE
    elif [ -f /etc/redhat-release ]; then
        OS="Red Hat Enterprise Linux"
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    # 判断系统类型
    case "$OS" in
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*|*"openEuler"*|*"Fedora"*)
            SYSTEM_TYPE="rhel"
            PACKAGE_MANAGER="yum"
            ;;
        *"Ubuntu"*|*"Debian"*|*"Mint"*|*"Kali"*)
            SYSTEM_TYPE="debian"
            PACKAGE_MANAGER="apt"
            ;;
        *)
            color_echo $RED "不支持的系统类型: $OS"
            exit 1
            ;;
    esac

    color_echo $GREEN "检测到系统: $OS $VER"
    color_echo $GREEN "系统类型: $SYSTEM_TYPE"
    color_echo $GREEN "包管理器: $PACKAGE_MANAGER"
    color_echo $YELLOW "脚本版本: $SCRIPT_VERSION ($SCRIPT_DATE)"
}

# 系统信息查询函数
system_info_query() {
    local SYSTEM_INFO=$(cat <<EOF
========================================================系统信息查询===================================================================================
=======================================================================================================================================================
主机名：$(uname -n)
EOF
    )

    # 根据系统类型获取系统版本
    if [ "$SYSTEM_TYPE" = "rhel" ]; then
        SYSTEM_INFO+="\n系统版本：$(awk -F= 'NR==2 {gsub(/\"/, \"\", \$2); print \$2}' /etc/os-release 2>/dev/null || echo \"未知\")"
    else
        SYSTEM_INFO+="\n系统版本：$(lsb_release -d | awk -F'\\t' '{print \$2}' 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'\"' -f2)"
    fi

    SYSTEM_INFO+=$(cat <<EOF

内核版本：$(uname -r)
CPU 架构：$(uname -m)
CPU 型号:$(lscpu | grep 'Model name' | awk -F ':' '{print $2}' | sed 's/^[ \t]*//')
CPU 核心数：$(nproc)
CPU 占用：$(top -bn1 | grep 'Cpu(s)' | awk '{printf "%.2f%%", $2 + $4 + $6}' 2>/dev/null || echo "N/A")
系统负载1分钟:$(awk '{print $1}' /proc/loadavg) | 系统负载5分钟:$(awk '{print $2}' /proc/loadavg) | 系统负载15分钟:$(awk '{print $3}' /proc/loadavg)
物理内存：$(free -m | awk 'NR==2{printf "%.2fGB", $2 / 1024}')
内存使用率：$(free | awk 'NR==2{printf "%.2f%%", $3 / $2 * 100}')
虚拟内存：$(free -m | awk 'NR==3{printf "%.2fGB", $2 / 1024}' 2>/dev/null || echo "N/A")
EOF
    )

    # 磁盘信息根据系统类型过滤
    if [ "$SYSTEM_TYPE" = "debian" ]; then
        local DISK_INFO=$(df -h | awk '!/docker|containers|iso9660|kubelet|tmpfs|snap/ && NR>1 {printf "%s分区磁盘使用情况: %s / %s\n", $NF, $3, $2}')
    else
        local DISK_INFO=$(df -h | awk '!/docker|containers|iso9660|kubelet|tmpfs/ && NR>1 {printf "%s分区磁盘使用情况: %s / %s\n", $NF, $3, $2}')
    fi

    SYSTEM_INFO+=$(cat <<EOF

$DISK_INFO
内网 IPv4 地址：$(ip -4 route get 8.8.8.8 2>/dev/null | head -1 | awk '{print $7}' || hostname -I | awk '{print $1}' 2>/dev/null || echo "获取失败")
公网 IPv4 地址：$(curl -s ifconfig.me 2>/dev/null || echo "获取失败")
系统时区：$(timedatectl 2>/dev/null | grep 'Time zone' | awk '{print $3}' || date +%Z)
系统时间：$(date)
系统运行时长：$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
EOF
    )

    # docker版本
    if command -v docker &> /dev/null; then
        SYSTEM_INFO="$SYSTEM_INFO\nDocker 版本：$(docker --version)"
    else
        SYSTEM_INFO="$SYSTEM_INFO\n未安装 Docker"
    fi

    echo -e "$SYSTEM_INFO"
    
    # docker-compose版本
    if command -v docker-compose &> /dev/null; then
        SYSTEM_INFO="$SYSTEM_INFO\ndocker-compose 版本：$(docker-compose --version)"
    else
        SYSTEM_INFO="$SYSTEM_INFO\n未安装 docker-compose"
    fi

    echo -e "$SYSTEM_INFO"
}

# 检查防火墙和 SELINUX 状态函数
check_firewall_selinux() {
    if [ "$SYSTEM_TYPE" = "rhel" ]; then
        # RHEL系列系统
        local FIREWALLD_STATE=$(systemctl is-active firewalld 2>/dev/null || echo "inactive")
        
        if [ "${FIREWALLD_STATE}" = "active" ]; then
            systemctl stop firewalld
            systemctl disable firewalld
            color_echo $GREEN "Firewalld 正在运行中, 已尝试停止并禁用."
        else
            color_echo $YELLOW "Firewalld 是已经停止的状态，无需再关闭."
        fi

        # 检查SELinux
        if command -v getenforce &> /dev/null; then
            local SELINUX_TEMP_STATE=$(getenforce)
            local SELINUX_PERM_STATE=$(sestatus 2>/dev/null | awk '/SELinux status:/ {print $3}' || echo "unknown")

            if [ "${SELINUX_TEMP_STATE}" != "Disabled" ]; then
                setenforce 0
                color_echo $GREEN "SELinux 已设置为宽容模式."
            else
                color_echo $YELLOW "SELinux 已经是宽容模式，无需再关闭."
            fi

            if [ "${SELINUX_PERM_STATE}" != "disabled" ] && [ -f /etc/selinux/config ]; then
                sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
                color_echo $GREEN "SELinux 永久模式正在运行, 已设置为禁用模式. 重启生效."
            else
                color_echo $YELLOW "SELinux 永久模式已经是禁用模式，无需再关闭."
            fi
        else
            color_echo $YELLOW "系统未安装SELinux."
        fi
    else
        # Debian系列系统
        if command -v ufw &> /dev/null; then
            local UFW_STATE=$(ufw status | grep -o "Status: .*" | awk '{print $2}')
            if [ "${UFW_STATE}" = "active" ]; then
                ufw disable
                color_echo $GREEN "UFW 防火墙正在运行中, 已尝试停止并禁用."
            else
                color_echo $YELLOW "UFW 防火墙已经是停止状态，无需再关闭."
            fi
        else
            color_echo $YELLOW "系统未安装UFW防火墙."
        fi

        # 检查iptables
        if command -v iptables &> /dev/null; then
            color_echo $YELLOW "检测到iptables，建议手动检查防火墙规则."
        fi
    fi
}

# 安装 Docker 必要工具, 依赖函数
install_docker_tools() {
    if [ "$SYSTEM_TYPE" = "rhel" ]; then
        # RHEL系列依赖
        declare -A TOOL_MAP
        TOOL_MAP=( ["curl"]="curl" ["wget"]="wget" ["device-mapper-persistent-data"]="dmsetup" ["tar"]="tar" ["lvm2"]="lvm" )

        for TOOL in "${!TOOL_MAP[@]}"; do
            BINARY=${TOOL_MAP[$TOOL]}
            if command -v $BINARY &> /dev/null; then
                color_echo $YELLOW "$TOOL 已安装，无需再次安装"
            else
                echo "安装 $TOOL ..."
                $PACKAGE_MANAGER install -y $TOOL || { color_echo $RED "安装 $TOOL 失败"; exit 1; }
            fi
        done
    else
        # Debian系列依赖
        declare -A TOOL_MAP
        TOOL_MAP=( ["curl"]="curl" ["wget"]="wget" ["ca-certificates"]="ca-certificates" ["gnupg"]="gnupg" ["lsb-release"]="lsb-release" )

        # 更新包索引
        color_echo $GREEN "更新包索引..."
        apt-get update

        for TOOL in "${!TOOL_MAP[@]}"; do
            BINARY=${TOOL_MAP[$TOOL]}
            if dpkg -l | grep -q "^ii  $TOOL "; then
                color_echo $YELLOW "$TOOL 已安装，无需再次安装"
            else
                echo "安装 $TOOL ..."
                apt-get install -y $TOOL || { color_echo $RED "安装 $TOOL 失败"; exit 1; }
            fi
        done
    fi
}



# Docker 安装函数
install_docker() {
    # 调用通用确认对话框
    if ! confirm_action; then
        color_echo $RED "用户取消安装 Docker。"
        return
    fi
    
    # 判断 docker 是否存在
    if command -v docker &> /dev/null; then
        color_echo $RED "Docker 已存在, 无需部署"
        color_echo $GREEN "版本为：$(docker --version)"
        return
    fi

    # 设置 Docker 工作目录
    DOCKER_WORKDIR=$(whiptail --title "设置 Docker 工作目录" --inputbox "请输入 Docker 工作目录【默认为 ${DEFAULT_DOCKER_WORKDIR}】\n\n说明：此目录将通过软链接方式链接到 /var/lib/docker" 12 80 "${DEFAULT_DOCKER_WORKDIR}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    
    if [ $exitstatus != 0 ]; then
        color_echo $RED "您取消了输入操作。"
        return
    fi

    # 检查工作目录是否单独挂载
    color_echo $GREEN "检查 $DOCKER_WORKDIR 目录是否单独挂载......"

    # 获取所有挂载点信息，除去根目录 /
    MOUNT_POINTS=$(df -h --output=target | tail -n +2 | grep -v "^/$")

    # 初始化标志位
    DIRECTORY_MOUNTED=false

    # 遍历挂载点，检查 DOCKER_WORKDIR 是否位于这些挂载点范围内
    for MOUNT_POINT in $MOUNT_POINTS; do
        if [[ "$DOCKER_WORKDIR" == "$MOUNT_POINT"* ]]; then
            color_echo $GREEN "$MOUNT_POINT 目录已挂载，且 $DOCKER_WORKDIR 在该目录下......ok"
            DIRECTORY_MOUNTED=true
            break
        fi
    done

    # 如果没有找到任何匹配的挂载点
    if [ "$DIRECTORY_MOUNTED" = false ]; then
        if ! (whiptail --title "确认" --yesno "$DOCKER_WORKDIR 不在挂载分区上是否继续？" 10 60); then
            color_echo $RED "用户取消安装 Docker。"
            return
        fi
    fi

    # 显示Docker版本信息
    whiptail --title "Docker 安装确认" --msgbox "即将安装 Docker\n\n版本: ${DOCKER_VERSION}\n下载地址: ${DOCKER_DOWNLOAD_URL}\n\n点击确定继续安装" 12 80
    
    color_echo $GREEN "安装依赖及必要工具......ok"
    # 安装必要工具
    install_docker_tools

    if [ "$SYSTEM_TYPE" = "rhel" ]; then
        # RHEL系列：二进制安装
        color_echo $GREEN "正在下载 docker-${DOCKER_VERSION}.tgz 二进制包......"
        # 下载二进制包
        if ! curl -Ifs "${DOCKER_DOWNLOAD_URL}" > /dev/null; then
            color_echo $RED "网络不通, 无法下载 Docker 二进制包."
            exit 1
        fi

        wget "${DOCKER_DOWNLOAD_URL}"

        color_echo $GREEN "解压并拷贝文件......ok"
        # 解压并拷贝文件
        tar -xf "docker-${DOCKER_VERSION}.tgz"
        cp docker/* /usr/bin/
        which docker

        color_echo $GREEN "清理二进制包, 软件包......ok"
        # 清理二进制包, 软件包
        rm -rf "docker-${DOCKER_VERSION}.tgz" docker

        color_echo $GREEN "编写 docker.service 文件......ok"
        # 编写 docker.service 文件
        cat > /etc/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP \$MAINPID
LimitNOFILE=65535
LimitNPROC=65535
LimitCORE=65535
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

        color_echo $GREEN "给 docker.service 添加可执行权限......ok"
        # 添加可执行权限
        chmod +x /etc/systemd/system/docker.service
    else
        # Debian系列：二进制安装
        color_echo $GREEN "正在下载 docker-${DOCKER_VERSION}.tgz 二进制包......"
        # 下载二进制包
        if ! curl -Ifs "${DOCKER_DOWNLOAD_URL}" > /dev/null; then
            color_echo $RED "网络不通, 无法下载 Docker 二进制包."
            exit 1
        fi

        wget "${DOCKER_DOWNLOAD_URL}"

        color_echo $GREEN "解压并拷贝文件......ok"
        # 解压并拷贝文件
        tar -xf "docker-${DOCKER_VERSION}.tgz"
        cp docker/* /usr/bin/
        which docker

        color_echo $GREEN "清理二进制包, 软件包......ok"
        # 清理二进制包, 软件包
        rm -rf "docker-${DOCKER_VERSION}.tgz" docker

        color_echo $GREEN "编写 docker.service 文件......ok"
        # 编写 docker.service 文件
        cat > /etc/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP \$MAINPID
LimitNOFILE=65535
LimitNPROC=65535
LimitCORE=65535
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

        color_echo $GREEN "给 docker.service 添加可执行权限......ok"
        # 添加可执行权限
        chmod +x /etc/systemd/system/docker.service
    fi

    # 创建工作目录
    color_echo $GREEN "创建工作目录为 $DOCKER_WORKDIR ......ok"
    mkdir -p "$DOCKER_WORKDIR"

    # 判断工作目录的符号链接状态
    if [ -d /var/lib/docker ]; then
        if [ -L /var/lib/docker ]; then
            LINK_TARGET=$(readlink /var/lib/docker)
            if [ "$LINK_TARGET" == "$DOCKER_WORKDIR" ]; then
                color_echo $GREEN "/var/lib/docker 已经是符号链接并且指向 $DOCKER_WORKDIR，不做更改"
            else
                color_echo $YELLOW "/var/lib/docker 是符号链接，但指向不同的目录，迁移数据到 $DOCKER_WORKDIR 并创建新的符号链接"
                systemctl stop docker
                mv /var/lib/docker/* "$DOCKER_WORKDIR" 2>/dev/null || true
                rm /var/lib/docker
                ln -s "$DOCKER_WORKDIR" /var/lib/docker
                systemctl start docker
            fi
        else
            color_echo $YELLOW "/var/lib/docker 是实际目录，迁移数据到 $DOCKER_WORKDIR 并创建符号链接"
            systemctl stop docker
            mv /var/lib/docker/* "$DOCKER_WORKDIR" 2>/dev/null || true
            rm -rf /var/lib/docker
            ln -s "$DOCKER_WORKDIR" /var/lib/docker
            systemctl start docker
        fi
    else
        # 如果 /var/lib/docker 不存在，直接创建符号链接
        color_echo $YELLOW "创建软连接指向/var/lib/docker"
        ln -s "$DOCKER_WORKDIR" /var/lib/docker
    fi

    color_echo $GREEN "启动 Docker 并设为开机自启动......ok"
    # 启动并设为开机自启动
    systemctl daemon-reload
    systemctl start docker
    systemctl enable docker

    # 配置镜像加速器
    color_echo $GREEN "配置 Docker 镜像加速地址【加速地址可能随时失效】......ok"
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["${DEFAULT_REGISTRY_MIRROR}"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

    systemctl daemon-reload
    systemctl restart docker

    # 输出 Docker 版本和部署完成信息
    color_echo $GREEN "$(docker --version)"
    color_echo $GREEN "Docker 已经部署完成✅"
}

# 卸载 Docker 函数
uninstall_docker() {
    # 调用通用确认对话框
    if ! confirm_action; then
        color_echo $RED "用户取消卸载 Docker。"
        return
    fi

    # 检查 Docker 是否存在
    if ! command -v docker &> /dev/null; then
        color_echo $RED "Docker 不存在, 无需卸载"
        return
    fi

    color_echo $GREEN "Docker 服务正在停止中......"
    # 停止 Docker 服务
    systemctl stop docker
    systemctl disable docker
    color_echo $GREEN "Docker 已停止......ok"

    while systemctl is-active --quiet docker; do
        sleep 1
    done

    # 备份 Docker 配置文件目录
    color_echo $GREEN "备份 /etc/docker 配置文件目录为 /etc/docker-bak$bak_date......ok"
    if [ -d /etc/docker ]; then
        mv /etc/docker /etc/docker-bak$bak_date
        color_echo $GREEN "备份文件如下: $(ls -l /etc/docker-bak$bak_date)"
    fi

    if [ "$SYSTEM_TYPE" = "rhel" ]; then
        # RHEL系列：删除二进制文件
        color_echo $GREEN "备份 Docker 二进制文件/usr/bin/docker* 至 /usr/bin/docker-bak$bak_date 目录下......ok"
        mkdir -p /usr/bin/docker-bak$bak_date
        # 备份 Docker 二进制文件
        mv /usr/bin/{docker,dockerd,docker-init,docker-proxy} /usr/bin/docker-bak$bak_date/ 2>/dev/null || true
        color_echo $GREEN "备份文件如下: $(ls -l /usr/bin/docker-bak$bak_date/)"

        # 备份 Docker systemd 文件
        color_echo $GREEN "备份 /etc/systemd/system/docker.service 文件至 /etc/systemd/system/docker.service-bak$bak_date......ok"
        mv /etc/systemd/system/docker.service /etc/systemd/system/docker.service-bak$bak_date 2>/dev/null || true
        color_echo $GREEN "备份文件如下: $(ls -l /etc/systemd/system/docker.service-bak$bak_date)"
        # 重新加载 systemd
        systemctl daemon-reload
    else
        # Debian系列：删除二进制文件
        color_echo $GREEN "备份 Docker 二进制文件/usr/bin/docker* 至 /usr/bin/docker-bak$bak_date 目录下......ok"
        mkdir -p /usr/bin/docker-bak$bak_date
        # 备份 Docker 二进制文件
        mv /usr/bin/{docker,dockerd,docker-init,docker-proxy} /usr/bin/docker-bak$bak_date/ 2>/dev/null || true
        color_echo $GREEN "备份文件如下: $(ls -l /usr/bin/docker-bak$bak_date/)"

        # 备份 Docker systemd 文件
        color_echo $GREEN "备份 /etc/systemd/system/docker.service 文件至 /etc/systemd/system/docker.service-bak$bak_date......ok"
        mv /etc/systemd/system/docker.service /etc/systemd/system/docker.service-bak$bak_date 2>/dev/null || true
        color_echo $GREEN "备份文件如下: $(ls -l /etc/systemd/system/docker.service-bak$bak_date)"
        # 重新加载 systemd
        systemctl daemon-reload
    fi

    color_echo $GREEN "保留现有的符号链接和工作目录"

    # 检查 Docker 是否已成功卸载
    if command -v docker &> /dev/null; then
        color_echo $RED "Docker 卸载异常, 请手动检查"
    else
        color_echo $GREEN "Docker 已成功卸载✅"
    fi
}

# Docker-Compose 安装函数
install_docker_compose() {
    # 调用通用确认对话框
    if ! confirm_action; then
        color_echo $RED "用户取消安装 Docker-Compose。"
        return
    fi
 
    # 判断 Docker-Compose 是否存在
    if command -v docker-compose &> /dev/null; then
        color_echo $RED "Docker-Compose 已存在, 无需部署"
        color_echo $GREEN "版本为：$(docker-compose --version)"
        return
    fi

    # 显示Docker-Compose版本信息
    whiptail --title "Docker-Compose 安装确认" --msgbox "即将安装 Docker-Compose\n\n版本: ${DOCKER_COMPOSE_VERSION}\n下载地址: ${DOCKER_COMPOSE_DOWNLOAD_URL}\n\n点击确定继续安装" 12 80
    
    color_echo $GREEN "安装依赖及必要工具......ok"
    # 安装必要工具
    install_docker_tools

    color_echo $GREEN "下载docker-compose-linux-x86_64_${DOCKER_COMPOSE_VERSION}二进制文件......ok"
    # 下载二进制文件
    if ! wget "${DOCKER_COMPOSE_DOWNLOAD_URL}" -O /usr/bin/docker-compose; then
        color_echo $RED "下载 Docker-Compose 二进制文件失败，请检查网络连接或下载地址."
        exit 1
    fi
    # 添加可执行权限
    chmod +x /usr/bin/docker-compose
    which docker-compose

    # 输出 Docker-Compose 版本和部署完成信息
    color_echo $GREEN "$(docker-compose --version)"
    color_echo $GREEN "docker-compose 已经部署完成✅"
}

# 卸载Docker-Compose
uninstall_docker_compose() {
    # 调用通用确认对话框
    if ! confirm_action; then
        color_echo $RED "用户取消卸载 Docker-Compose。"
        return
    fi

    # 检查 Docker-Compose 是否存在
    if ! command -v docker-compose &> /dev/null; then
        color_echo $RED "Docker-Compose 不存在, 无需卸载"
        return
    fi

    color_echo $GREEN "备份 Docker-Compose 二进制文件/usr/bin/docker-compose 至 /usr/bin/docker-compose-bak$bak_date 目录下......ok"
    mkdir -p /usr/bin/docker-compose-bak$bak_date
    # 备份 docker-compose 二进制文件
    mv /usr/bin/docker-compose /usr/bin/docker-compose-bak$bak_date
    color_echo $GREEN "备份文件如下: $(ls -l /usr/bin/docker-compose-bak$bak_date/)"

    # 检查 Docker-Compose 是否已成功卸载
    if command -v docker-compose &> /dev/null; then
        color_echo $RED "Docker-Compose 卸载异常, 请手动检查"
    else
        color_echo $GREEN "Docker-Compose 已成功卸载✅"
    fi
}



# 显示 Docker 信息函数
check_docker_info() {
    docker info
}

# 显示 Docker 正在运行的容器函数
check_docker_ps() {
    docker ps --no-trunc | column -t
}

# 返回菜单提示函数
prompt_to_return() {
    color_echo $GREEN "按任意键返回菜单..."
    read -n 1 -s
}

# Docker 环境检查菜单函数
docker_environment_check_menu() {
    while true; do
        if [ "$SYSTEM_TYPE" = "rhel" ]; then
            MENU_TITLE="Docker 环境检查 (RHEL系列)"
            INSTALL_OPTION="在线二进制安装Docker"
            FIREWALL_OPTION="禁用防火墙和SELINUX"
        else
            MENU_TITLE="Docker 环境检查 (Debian系列)"
            INSTALL_OPTION="在线二进制安装Docker"
            FIREWALL_OPTION="禁用防火墙"
        fi

        CHECK_OPTION=$(whiptail --title "$MENU_TITLE" --menu "选择您的选项" 18 70 10 \
        "1" "$FIREWALL_OPTION" \
        "2" "$INSTALL_OPTION" \
        "3" "卸载 Docker" \
        "4" "在线二进制安装Docker-Compose" \
        "5" "卸载 Docker-Compose" \
        "6" "返回" 3>&1 1>&2 2>&3)

        case $CHECK_OPTION in
            1)
                clear
                show_progress_bar
                check_firewall_selinux
                prompt_to_return
                ;;
            2)
                clear
                show_progress_bar
                install_docker
                prompt_to_return
                ;;
            3)
                clear
                show_progress_bar
                uninstall_docker
                prompt_to_return
                ;;
            4)
                clear
                show_progress_bar
                install_docker_compose
                prompt_to_return
                ;;
            5)
                clear
                show_progress_bar
                uninstall_docker_compose
                prompt_to_return
                ;;
            6) return ;;
        esac
    done
}

# 主程序入口
main() {
    # 验证配置
    validate_config
    
    # 检测系统类型
    detect_system
    
    # 主菜单
    while true; do
        OPTION=$(whiptail --title "Docker 通用安装菜单 ($SYSTEM_TYPE系列)" --menu "选择您的选项" 15 60 3 \
        "1" "系统信息查询" \
        "2" "Docker部署" \
        "3" "退出" 3>&1 1>&2 2>&3)

        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            case $OPTION in
                1)
                    clear
                    # 预处理系统信息查询
                    SYSTEM_INFO_OUTPUT=$(system_info_query)
                    # 显示进度条
                    show_progress_bar
                    clear
                    echo -e "$SYSTEM_INFO_OUTPUT"
                    prompt_to_return
                    ;;
                2)
                    docker_environment_check_menu
                    ;;
                3)
                    echo "再见"
                    break
                    ;;
            esac
        else
            echo "您选择了取消."
            exit 1
        fi
    done
}

# 运行主程序
main