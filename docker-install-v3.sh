#!/usr/bin/env bash
# Docker 通用安装与管理脚本 v3.1.1 — 全新安装优先
# 支持：Ubuntu/Debian、RHEL/CentOS/Rocky/AlmaLinux/openEuler/麒麟等（需可用的软件包管理器）
# 架构：x86_64 / aarch64；要求 systemd；在线从官方稳定版源下载安装。
# 特别说明：发现已有 Docker/containerd 的程序、服务或数据时拒绝安装；不迁移、不删除旧数据。
# 防火墙/SELinux 菜单保留原脚本的“直接禁用”行为，只有主动选中该菜单才会操作。

set -o pipefail
SCRIPT_VERSION='v3.1.1'
SCRIPT_DATE="$(date '+%Y-%m-%d')"
DEFAULT_WORKDIR='/home/application/docker'
DEFAULT_REGISTRY_MIRROR='https://docker.xuanyuan.me'
DOCKER_RELEASE_BASE="${DOCKER_RELEASE_BASE:-https://download.docker.com/linux/static/stable}"
COMPOSE_RELEASE_API="${COMPOSE_RELEASE_API:-https://api.github.com/repos/docker/compose/releases/latest}"
COMPOSE_RELEASE_BASE="${COMPOSE_RELEASE_BASE:-https://github.com/docker/compose/releases/download}"
COMPOSE_PLUGIN='/usr/local/lib/docker/cli-plugins/docker-compose'
BACKUP_STAMP="$(date '+%Y%m%d-%H%M%S')"
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; NC=$'\033[0m'

say() { printf '%b%s%b\n' "$1" "$2" "$NC"; }
ok() { say "$GREEN" "$*"; }
warn() { say "$YELLOW" "警告：$*" >&2; }
error() { say "$RED" "错误：$*" >&2; }
confirm() { whiptail --title '操作确认' --yesno "$1" 12 82; }
pause_menu() { printf '\n按任意键返回菜单...'; read -r -n1 -s _; printf '\n'; }
TMP_ROOT=''
INSTALL_TRANSACTION_ACTIVE=0
cleanup_tmp() { [[ -z "$TMP_ROOT" ]] || rm -rf -- "$TMP_ROOT"; TMP_ROOT=''; }
finish_on_exit() {
    if [[ "$INSTALL_TRANSACTION_ACTIVE" == 1 ]]; then
        warn '检测到安装过程意外中断，启动安全回滚'
        rollback_new_install
    fi
    cleanup_tmp
}
trap finish_on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# 先识别系统和命令，以便在 main() 之前安装 whiptail。
detect_system() {
    [[ -r /etc/os-release ]] || { error '无法读取 /etc/os-release'; return 1; }
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_NAME="${PRETTY_NAME:-${NAME:-未知系统}}"
    local hints=" ${ID:-} ${ID_LIKE:-} "
    case "$hints" in
        *ubuntu*|*debian*|*linuxmint*|*kali*) SYSTEM_TYPE='debian'; PKG='apt-get' ;;
        *rhel*|*fedora*|*centos*|*rocky*|*almalinux*|*ol*|*openeuler*|*kylin*|*opencloudos*)
            SYSTEM_TYPE='rhel'
            if command -v dnf >/dev/null 2>&1; then PKG='dnf'
            elif command -v yum >/dev/null 2>&1; then PKG='yum'
            else error '缺少 yum/dnf 包管理器'; return 1; fi ;;
        *) error "暂不支持：$OS_NAME，ID=${ID:-unknown}，ID_LIKE=${ID_LIKE:-unknown}"; return 1 ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64) ARCH='x86_64' ;;
        aarch64|arm64) ARCH='aarch64' ;;
        *) error "暂不支持该架构：$(uname -m)"; return 1 ;;
    esac
    command -v systemctl >/dev/null 2>&1 || { error '本脚本需要 systemd'; return 1; }
    [[ -d /run/systemd/system ]] || { error '未检测到正常运行的 systemd'; return 1; }
    ok "系统：$OS_NAME | $ARCH | $PKG"
}

prepare_prerequisites() {
    [[ "$EUID" -eq 0 ]] || { error '请使用 sudo 或 root 执行'; return 1; }
    local packages=() c
    if [[ "$SYSTEM_TYPE" == 'debian' ]]; then
        command -v whiptail >/dev/null 2>&1 || packages+=(whiptail)
        command -v curl >/dev/null 2>&1 || packages+=(curl)
        command -v python3 >/dev/null 2>&1 || packages+=(python3)
        command -v tar >/dev/null 2>&1 || packages+=(tar)
        command -v sha256sum >/dev/null 2>&1 || packages+=(coreutils)
        command -v findmnt >/dev/null 2>&1 || packages+=(util-linux)
        command -v iptables >/dev/null 2>&1 || packages+=(iptables)
        command -v ip >/dev/null 2>&1 || packages+=(iproute2)
        command -v modprobe >/dev/null 2>&1 || packages+=(kmod)
        command -v pgrep >/dev/null 2>&1 || packages+=(procps)
        command -v sort >/dev/null 2>&1 || packages+=(coreutils)
        command -v find >/dev/null 2>&1 || packages+=(findutils)
        if ((${#packages[@]})); then
            warn "需要安装依赖：${packages[*]}"
            DEBIAN_FRONTEND=noninteractive apt-get update || return 1
            DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates "${packages[@]}" || return 1
        fi
    else
        command -v whiptail >/dev/null 2>&1 || packages+=(newt)
        command -v curl >/dev/null 2>&1 || packages+=(curl)
        command -v python3 >/dev/null 2>&1 || packages+=(python3)
        command -v tar >/dev/null 2>&1 || packages+=(tar)
        command -v sha256sum >/dev/null 2>&1 || packages+=(coreutils)
        command -v findmnt >/dev/null 2>&1 || packages+=(util-linux)
        command -v iptables >/dev/null 2>&1 || packages+=(iptables)
        command -v ip >/dev/null 2>&1 || packages+=(iproute)
        command -v modprobe >/dev/null 2>&1 || packages+=(kmod)
        command -v pgrep >/dev/null 2>&1 || packages+=(procps-ng)
        command -v find >/dev/null 2>&1 || packages+=(findutils)
        if ((${#packages[@]})); then
            warn "需要安装依赖：${packages[*]}"
            "$PKG" install -y ca-certificates "${packages[@]}" || return 1
        fi
    fi
    for c in whiptail curl python3 tar sha256sum sort awk grep sed find findmnt realpath mktemp install pgrep systemctl; do
        command -v "$c" >/dev/null 2>&1 || { error "缺少必要命令：$c"; return 1; }
    done
    if ! curl --version | grep -q 'https'; then
        error 'curl 没有 HTTPS 支持'; return 1
    fi
}

show_system_info() {
    printf '\n==================== 系统信息 ====================\n'
    printf '主机名：%s\n系统：%s\n内核：%s\n架构：%s\nCPU 核数：%s\n' \
        "$(hostname)" "$OS_NAME" "$(uname -r)" "$(uname -m)" "$(nproc)"
    printf '系统负载：%s\n' "$(cat /proc/loadavg 2>/dev/null)"
    free -h 2>/dev/null || true
    df -hT 2>/dev/null | awk 'NR==1 || ($2 !~ /tmpfs|overlay|squashfs/ && $1 !~ /docker/)' || true
    printf 'IPv4 地址：%s\n时区：%s\n时间：%s\n' \
        "$(hostname -I 2>/dev/null || echo 未知)" "$(date +%Z)" "$(date)"
    if command -v docker >/dev/null 2>&1; then
        docker version --format 'Docker Client: {{.Client.Version}}' 2>/dev/null || docker --version
        docker info --format 'Docker 数据目录：{{.DockerRootDir}}' 2>/dev/null || true
        docker compose version 2>/dev/null || true
    else
        printf 'Docker：未安装\n'
    fi
    if command -v containerd >/dev/null 2>&1; then containerd --version; fi
    printf 'Docker 服务：%s\ncontainerd 服务：%s\n' \
        "$(systemctl is-active docker 2>/dev/null || true)" \
        "$(systemctl is-active containerd 2>/dev/null || true)"
}

# 按用户要求，保留 v2.0 的原有禁用功能；仅主动选择此菜单时执行。
disable_firewall_selinux() {
    if [[ "$SYSTEM_TYPE" == 'rhel' ]]; then
        if systemctl is-active --quiet firewalld; then
            systemctl stop firewalld && systemctl disable firewalld \
                && ok 'firewalld 已停止并禁用' || error '无法完全禁用 firewalld'
        else warn 'firewalld 当前未运行'; fi
        if command -v getenforce >/dev/null 2>&1; then
            if [[ "$(getenforce)" != 'Disabled' ]]; then
                setenforce 0 || warn 'setenforce 0 执行失败'
            fi
            if [[ -f /etc/selinux/config ]]; then
                sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config \
                    || warn '修改 /etc/selinux/config 失败'
            fi
            ok '已按原脚本要求尝试禁用 SELinux（永久配置重启生效）'
        else warn '系统缺少 SELinux 管理工具'; fi
    else
        if command -v ufw >/dev/null 2>&1 && ufw status | grep -q '^Status: active'; then
            ufw disable && ok 'UFW 已禁用' || error 'UFW 禁用失败'
        else warn 'UFW 当前未运行或未安装'; fi
        command -v iptables >/dev/null 2>&1 && warn '检测到 iptables，原脚本不自动修改其规则'
    fi
}

http_get() {
    curl --fail --location --silent --show-error --retry 3 --retry-delay 2 \
        --connect-timeout 15 --max-time 900 "$1" -o "$2"
}

resolve_docker_version() {
    local index="$TMP_ROOT/docker-index.html" version
    http_get "${DOCKER_RELEASE_BASE}/${ARCH}/" "$index" || { error '获取 Docker 官方稳定版目录失败'; return 1; }
    version="$(grep -oE 'docker-[0-9]+\.[0-9]+\.[0-9]+\.tgz' "$index" \
        | sed -E 's/^docker-//;s/\.tgz$//' | sort -Vu | tail -n 1)"
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { error '无法解析最新 Docker 稳定版'; return 1; }
    DOCKER_VERSION="$version"
    DOCKER_URL="${DOCKER_RELEASE_BASE}/${ARCH}/docker-${version}.tgz"
}

resolve_compose_version() {
    local response="$TMP_ROOT/compose-release.json" tag
    http_get "$COMPOSE_RELEASE_API" "$response" || { error '查询 Compose 最新 Release 失败'; return 1; }
    tag="$(python3 - "$response" <<'PY'
import json,sys
try:
    with open(sys.argv[1],encoding='utf-8') as f: j=json.load(f)
    if not j.get('draft', True) and not j.get('prerelease',True):
        print(j.get('tag_name',''))
except (ValueError,OSError) as e:
    print('JSON error:',e,file=sys.stderr)
PY
)"
    [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { error "Compose Release 标签无效：$tag"; return 1; }
    COMPOSE_VERSION="$tag"
    COMPOSE_ASSET="docker-compose-linux-${ARCH}"
    COMPOSE_URL="${COMPOSE_RELEASE_BASE}/${tag}/${COMPOSE_ASSET}"
}

# 从发布方下载配套 .sha256 文件，验证本体；失败时绝不安装。
download_verified() {
    local url="$1" dest="$2" check_file="${2}.sha256" expected actual
    ok "开始下载：$url"
    http_get "$url" "$dest" || { error "下载失败：$url"; return 1; }
    http_get "${url}.sha256" "$check_file" || { error '未取到 SHA256 文件，拒绝安装'; return 1; }
    expected="$(grep -Eo '[a-fA-F0-9]{64}' "$check_file" | head -n 1)"
    [[ "$expected" =~ ^[a-fA-F0-9]{64}$ ]] || { error 'SHA256 文件格式无法识别'; return 1; }
    actual="$(sha256sum "$dest" | awk '{print $1}')"
    if [[ "${expected,,}" != "${actual,,}" ]]; then
        error "SHA256 不匹配：$(basename "$dest")"; return 1
    fi
    ok "SHA256 校验通过：$(basename "$dest")"
}

not_empty_dir() {
    [[ -d "$1" && -n "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]
}

# 强制新装：对任何旧存储、服务或二进制冲突，直接终止，而不是迁移数据。
preflight_new_install() {
    local cmd file
    for cmd in docker dockerd containerd ctr runc; do
        if command -v "$cmd" >/dev/null 2>&1; then
            error "检测到已有程序：$(command -v "$cmd")；本功能只负责全新安装，不覆盖旧环境"
            return 1
        fi
    done
    for file in /etc/systemd/system/docker.service /etc/systemd/system/containerd.service \
                /usr/lib/systemd/system/docker.service /usr/lib/systemd/system/containerd.service \
                /lib/systemd/system/docker.service /lib/systemd/system/containerd.service \
                /etc/systemd/system/docker.socket /run/containerd/containerd.sock /run/docker.sock; do
        if [[ -e "$file" || -L "$file" ]]; then
            error "检测到已有服务文件或运行时套接字：$file；拒绝覆盖"; return 1
        fi
    done
    if systemctl is-active --quiet docker || systemctl is-active --quiet containerd \
        || pgrep -x dockerd >/dev/null 2>&1 || pgrep -x containerd >/dev/null 2>&1; then
        error '检测到 Docker/containerd 进程正在运行，拒绝安装'; return 1
    fi
    for file in /var/lib/docker /var/lib/containerd "$DOCKER_DATA_ROOT" "$CONTAINERD_DATA_ROOT"; do
        if [[ -L "$file" ]]; then
            error "数据目录是软链接：$file；拒绝处理"; return 1
        fi
        if not_empty_dir "$file"; then
            error "发现非空数据目录：$file。请先确认数据归属；本脚本不会迁移或删除"; return 1
        fi
        if [[ -e "$file" && ! -d "$file" ]]; then
            error "存在同名非目录文件：$file"; return 1
        fi
    done
}

validate_base_path() {
    DOCKER_BASE="$(realpath -m -- "$DOCKER_BASE")" || return 1
    [[ "$DOCKER_BASE" == /* && "$DOCKER_BASE" != '/' ]] || { error '存储目录必须是绝对路径'; return 1; }
    case "$DOCKER_BASE" in
        /var|/var/*|/etc|/etc/*|/usr|/usr/*|/run|/run/*|/tmp|/tmp/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*|/boot|/boot/*)
            error "拒绝使用系统目录：$DOCKER_BASE"; return 1 ;;
    esac
    if [[ -e "$DOCKER_BASE" && ! -d "$DOCKER_BASE" ]] || [[ -L "$DOCKER_BASE" ]]; then
        error "目录不存在有效的真实目录形式：$DOCKER_BASE"; return 1
    fi
    DOCKER_DATA_ROOT="$DOCKER_BASE/docker"
    CONTAINERD_DATA_ROOT="$DOCKER_BASE/containerd"
}

# 合并 Docker JSON：保留用户已有配置，不覆盖未知字段。
build_docker_candidate() {
    local src='/etc/docker/daemon.json' out="$1"
    python3 - "$src" "$out" "$DOCKER_DATA_ROOT" "$DEFAULT_REGISTRY_MIRROR" <<'PY'
import json,os,sys
src,dst,root,mirror=sys.argv[1:]
try:
    if os.path.isfile(src):
        with open(src,encoding='utf-8') as f: data=json.load(f)
    else: data={}
    if not isinstance(data,dict): raise ValueError('daemon.json 顶层必须为 JSON 对象')
    existing=data.get('data-root')
    if existing and os.path.realpath(existing)!=os.path.realpath(root):
        raise ValueError('已有 data-root 与目标不同：%s；需人工确认' % existing)
    data['data-root']=root
    mirrors=data.setdefault('registry-mirrors',[])
    if not isinstance(mirrors,list): raise ValueError('registry-mirrors 必须为数组')
    if mirror and mirror not in mirrors: mirrors.append(mirror)
    data.setdefault('exec-opts',['native.cgroupdriver=systemd'])
    data.setdefault('log-driver','json-file')
    if data['log-driver']=='json-file':
        opts=data.setdefault('log-opts',{})
        if not isinstance(opts,dict): raise ValueError('log-opts 必须为对象')
        opts.setdefault('max-size','10m')
        opts.setdefault('max-file','3')
    features=data.setdefault('features',{})
    if not isinstance(features,dict): raise ValueError('features 必须为对象')
    if features.get('containerd-snapshotter') is False:
        raise ValueError('当前配置禁用了 containerd-snapshotter；为保留既有设置，不自动改写')
    features['containerd-snapshotter']=True
    with open(dst,'w',encoding='utf-8') as f:
        json.dump(data,f,ensure_ascii=False,indent=2); f.write('\n')
except (OSError,ValueError,TypeError) as e:
    print('合并 Docker JSON 失败：',e,file=sys.stderr); sys.exit(1)
PY
}

# 合并 containerd TOML，仅修改顶层 root；既有其他字段、插件设置保持不变。
# 不依赖第三方 TOML 库；由实际 containerd 二进制解析并校验候选文件。
build_containerd_candidate() {
    local src='/etc/containerd/config.toml' out="$1"
    python3 - "$src" "$out" "$CONTAINERD_DATA_ROOT" <<'PY'
import json,os,re,sys
src,dst,root=sys.argv[1:]
try:
    content=open(src,encoding='utf-8').read() if os.path.isfile(src) else ''
    lines=content.splitlines(keepends=True)
    head_end=next((i for i,line in enumerate(lines) if re.match(r'^\s*\[',line)),len(lines))
    header=lines[:head_end]
    root_matches=[i for i,line in enumerate(header) if re.match(r'^\s*root\s*=',line)]
    if len(root_matches)>1: raise ValueError('存在多个顶层 root 项')
    root_line='root = '+json.dumps(root,ensure_ascii=False)+'\n'
    if root_matches: header[root_matches[0]]=root_line
    else: header.append(root_line)
    if not any(re.match(r'^\s*version\s*=',line) for line in header):
        header.insert(0,'version = 3\n')
    if not any(re.match(r'^\s*state\s*=',line) for line in header):
        header.append('state = "/run/containerd"\n')
    with open(dst,'w',encoding='utf-8') as f: f.writelines(header+lines[head_end:])
except (OSError,ValueError) as e:
    print('合并 containerd TOML 失败：',e,file=sys.stderr); sys.exit(1)
PY
}

# 配置文件落盘前先在临时目录校验，并备份原文件；发生故障可回滚。
# 返回的全局数组只保存本次修改的路径及其备份，不操作用户数据目录。
CONFIG_NEW=(); CONFIG_BACKUPS=()
commit_config_file() {
    local candidate="$1" target="$2" backup=''
    mkdir -p -- "$(dirname "$target")" || return 1
    if [[ -f "$target" ]]; then
        backup="${target}.bak-${BACKUP_STAMP}"
        cp -a -- "$target" "$backup" || { error "备份配置失败：$target"; return 1; }
        ok "配置备份：$backup"
    elif [[ -e "$target" || -L "$target" ]]; then
        error "不是普通配置文件：$target"; return 1
    fi
    if ! install -m 0644 -- "$candidate" "${target}.tmp-${BACKUP_STAMP}"; then
        rm -f -- "${target}.tmp-${BACKUP_STAMP}"; return 1
    fi
    if ! mv -f -- "${target}.tmp-${BACKUP_STAMP}" "$target"; then
        rm -f -- "${target}.tmp-${BACKUP_STAMP}"; return 1
    fi
    CONFIG_NEW+=("$target")
    CONFIG_BACKUPS+=("$backup")
}

INSTALLED_BINS=(); INSTALLED_UNITS=()
rollback_new_install() {
    INSTALL_TRANSACTION_ACTIVE=0
    local i
    warn '安装未成功：尝试回滚本次新增的服务、配置和二进制文件；保留所有数据目录'
    systemctl stop docker >/dev/null 2>&1 || true
    systemctl stop containerd >/dev/null 2>&1 || true
    systemctl disable docker containerd >/dev/null 2>&1 || true
    for i in "${INSTALLED_UNITS[@]}"; do rm -f -- "$i" || warn "清理服务文件失败：$i"; done
    for i in "${INSTALLED_BINS[@]}"; do rm -f -- "$i" || warn "清理可执行文件失败：$i"; done
    for ((i=${#CONFIG_NEW[@]}-1;i>=0;i--)); do
        if [[ -n "${CONFIG_BACKUPS[$i]}" ]]; then
            cp -a -- "${CONFIG_BACKUPS[$i]}" "${CONFIG_NEW[$i]}" || warn "恢复配置失败：${CONFIG_NEW[$i]}"
        else rm -f -- "${CONFIG_NEW[$i]}" || warn "清理新配置失败：${CONFIG_NEW[$i]}"; fi
    done
    systemctl daemon-reload >/dev/null 2>&1 || true
}

write_units() {
    local cdservice='/etc/systemd/system/containerd.service'
    local docker_service='/etc/systemd/system/docker.service'
    # preflight 已保证两个文件均不存在。
    INSTALLED_UNITS+=("$cdservice")
    cat > "$cdservice" <<'EOF'
# Managed by docker-manager-v3.1.sh
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/containerd --config /etc/containerd/config.toml
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
    [[ $? -eq 0 ]] || return 1
    INSTALLED_UNITS+=("$docker_service")
    cat > "$docker_service" <<'EOF'
# Managed by docker-manager-v3.1.sh
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
Requires=containerd.service
After=network-online.target containerd.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure
RestartSec=3
TimeoutStartSec=0
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
    [[ $? -eq 0 ]] || return 1
}

install_docker() {
    if ! confirm '此操作仅适用于全新安装，若发现旧 Docker/containerd 程序、服务或数据会直接终止。继续吗？'; then return 0; fi
    local status name file docker_candidate cd_candidate bin mountpoint
    DOCKER_BASE="$(whiptail --title 'Docker 存储目录' --inputbox \
        '请选择统一数据目录。程序将在该目录下创建 docker/ 和 containerd/ 两个子目录：' \
        13 88 "$DEFAULT_WORKDIR" 3>&1 1>&2 2>&3)"
    status=$?
    ((status==0)) || return 0
    [[ -n "$DOCKER_BASE" ]] || { error '存储目录不能为空'; return 1; }
    validate_base_path || return 1
    preflight_new_install || return 1
    # 判断根盘：不存在时 findmnt -T 最近现存父目录。
    local parent="$DOCKER_BASE"
    while [[ ! -e "$parent" && "$parent" != '/' ]]; do parent="$(dirname "$parent")"; done
    mountpoint="$(findmnt -T "$parent" -no TARGET 2>/dev/null || echo /)"
    if [[ "$mountpoint" == '/' ]]; then
        warn "目标路径位于根分区：$DOCKER_BASE"
        confirm '所选存储目录位于根分区，仍要继续吗？' || return 0
    fi
    TMP_ROOT="$(mktemp -d /tmp/docker-install.XXXXXXXX)" || return 1
    resolve_docker_version || return 1
    if ! whiptail --title '安装确认' --yesno \
        "Docker Engine 最新稳定版：$DOCKER_VERSION\nCPU 架构：$ARCH\nDocker 存储：$DOCKER_DATA_ROOT\ncontainerd 存储：$CONTAINERD_DATA_ROOT\n\n将安装独立 containerd.service 和 docker.service，不创建软链接、不迁移旧数据。\n确认下载并安装？" \
        17 92; then cleanup_tmp; return 0; fi
    download_verified "$DOCKER_URL" "$TMP_ROOT/docker-${DOCKER_VERSION}.tgz" || return 1
    mkdir -p "$TMP_ROOT/extract" || return 1
    tar -xzf "$TMP_ROOT/docker-${DOCKER_VERSION}.tgz" -C "$TMP_ROOT/extract" || { error '解压 Docker 包失败'; return 1; }
    for name in docker dockerd containerd ctr runc containerd-shim-runc-v2; do
        [[ -x "$TMP_ROOT/extract/docker/$name" ]] || { error "Docker 安装包中缺少 $name"; return 1; }
    done
    # 不覆盖来自 RPM/DEB、第三方软件或其他安装程序的任何二进制。
    for bin in "$TMP_ROOT"/extract/docker/*; do
        [[ -f "$bin" ]] || continue
        name="$(basename "$bin")"
        [[ ! -e "/usr/bin/$name" && ! -L "/usr/bin/$name" ]] || {
            error "文件冲突：/usr/bin/$name；不会覆盖"; return 1; }
    done
    docker_candidate="$TMP_ROOT/daemon.json"
    cd_candidate="$TMP_ROOT/containerd-config.toml"
    build_docker_candidate "$docker_candidate" || return 1
    build_containerd_candidate "$cd_candidate" || return 1
    # 首次安装尚未把 docker-proxy 复制到 /usr/bin。
    # Docker 默认启用 userland-proxy，dockerd --validate 必须能够找到它；
    # 仅对本次校验进程临时扩展 PATH，不修改系统 PATH、不提前安装文件。
    [[ -x "$TMP_ROOT/extract/docker/docker-proxy" ]] \
        || { error '安装包中缺少可执行的 docker-proxy，拒绝继续'; return 1; }
    PATH="$TMP_ROOT/extract/docker:$PATH" \
        "$TMP_ROOT/extract/docker/dockerd" --validate --config-file "$docker_candidate" \
        || { error 'daemon.json 校验失败，未修改系统'; return 1; }
    "$TMP_ROOT/extract/docker/containerd" --config "$cd_candidate" config dump >"$TMP_ROOT/containerd-dump.toml" \
        || { error 'containerd config.toml 校验失败，未修改系统'; return 1; }
    ok 'Docker 和 containerd 配置预校验通过'
    # 所有耗时下载、配置检查已结束；从这里开始出现错误时回滚本次写入。
    INSTALLED_BINS=(); INSTALLED_UNITS=(); CONFIG_NEW=(); CONFIG_BACKUPS=()
    INSTALL_TRANSACTION_ACTIVE=1
    for bin in "$TMP_ROOT"/extract/docker/*; do
        [[ -f "$bin" ]] || continue
        name="$(basename "$bin")"
        if ! install -m 0755 -- "$bin" "/usr/bin/$name"; then
            error "安装二进制失败：$name"; rollback_new_install; return 1
        fi
        INSTALLED_BINS+=("/usr/bin/$name")
    done
    if ! commit_config_file "$docker_candidate" /etc/docker/daemon.json \
        || ! commit_config_file "$cd_candidate" /etc/containerd/config.toml; then
        error '写入配置文件失败'; rollback_new_install; return 1
    fi
    if ! mkdir -p -- "$DOCKER_DATA_ROOT" "$CONTAINERD_DATA_ROOT"; then
        error '创建数据目录失败'; rollback_new_install; return 1
    fi
    if ! write_units; then error '写入 systemd 服务文件失败'; rollback_new_install; return 1; fi
    if ! systemctl daemon-reload \
        || ! systemctl start containerd \
        || ! systemctl is-active --quiet containerd \
        || ! systemctl start docker \
        || ! systemctl is-active --quiet docker \
        || ! docker info >/dev/null 2>&1; then
        error 'Docker/containerd 启动失败；日志：journalctl -u docker -u containerd -n 100 --no-pager'
        rollback_new_install; return 1
    fi
    local actual_root
    actual_root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)"
    if [[ "$actual_root" != "$DOCKER_DATA_ROOT" ]]; then
        error "Docker 数据目录不匹配：$actual_root"; rollback_new_install; return 1
    fi
    if ! docker info --format '{{json .DriverStatus}}' 2>/dev/null | grep -q 'io.containerd.snapshotter.v1'; then
        error '没有检测到 containerd image store，拒绝报告安装成功'
        rollback_new_install; return 1
    fi
    systemctl enable containerd docker || warn '启动成功，但设置开机自启动失败，请检查'
    INSTALL_TRANSACTION_ACTIVE=0
    cleanup_tmp
    ok "Docker 安装成功：$(docker --version)"
    ok "Docker data-root：$DOCKER_DATA_ROOT"
    ok "containerd root：$CONTAINERD_DATA_ROOT"
    ok '存储后端：containerd image store'
    ok 'docker/containerd 服务已启动，健康检查通过'
    if confirm 'Docker 安装成功。是否继续安装最新稳定版 Docker Compose 插件？'; then
        install_compose_core || warn 'Docker 已安装成功，但 Compose 安装失败，可在菜单中单独重试'
    fi
}

install_compose_core() {
    command -v docker >/dev/null 2>&1 || { error '请先安装 Docker Engine'; return 1; }
    if docker compose version >/dev/null 2>&1; then
        warn "Compose 已安装：$(docker compose version)"; return 0
    fi
    if [[ -e "$COMPOSE_PLUGIN" || -L "$COMPOSE_PLUGIN" ]]; then
        error "Compose 目标文件已存在：$COMPOSE_PLUGIN；拒绝覆盖"; return 1
    fi
    TMP_ROOT="$(mktemp -d /tmp/compose-install.XXXXXXXX)" || return 1
    resolve_compose_version || return 1
    ok "Compose 最新稳定版：$COMPOSE_VERSION"
    download_verified "$COMPOSE_URL" "$TMP_ROOT/$COMPOSE_ASSET" || return 1
    mkdir -p -- "$(dirname "$COMPOSE_PLUGIN")" || return 1
    if ! install -m 0755 "$TMP_ROOT/$COMPOSE_ASSET" "$COMPOSE_PLUGIN"; then
        error 'Compose 插件文件安装失败'; rm -f -- "$COMPOSE_PLUGIN"; return 1
    fi
    if ! docker compose version; then
        error 'Compose 插件测试失败，本次新增插件已删除'
        rm -f -- "$COMPOSE_PLUGIN"; return 1
    fi
    cleanup_tmp
    ok 'Compose 已成功安装，使用方式：docker compose'
}

install_compose() {
    if confirm '是否在线安装最新稳定版 Docker Compose CLI 插件？'; then
        install_compose_core
    fi
}

uninstall_compose() {
    confirm '将备份并移走由本脚本安装位置的 Compose 插件，不删除任何容器数据。继续吗？' || return 0
    if [[ ! -f "$COMPOSE_PLUGIN" ]]; then warn '脚本管理位置没有 Compose 插件'; return 0; fi
    local backup_dir="/usr/local/lib/docker/compose-backup-${BACKUP_STAMP}"
    mkdir -p "$backup_dir" || return 1
    mv -- "$COMPOSE_PLUGIN" "$backup_dir/" || { error 'Compose 备份失败'; return 1; }
    ok "Compose 备份完成：$backup_dir"
}

uninstall_docker() {
    if ! confirm '卸载本脚本安装的 Docker + containerd（将停止现有容器）。只备份程序和配置，不删除任何镜像、容器或卷数据。继续吗？'; then return 0; fi
    local unit='/etc/systemd/system/docker.service' ctrunit='/etc/systemd/system/containerd.service'
    [[ -f "$unit" && -f "$ctrunit" ]] || { error '本脚本服务文件不存在，拒绝执行卸载'; return 1; }
    grep -q 'Managed by docker-manager-v3.1.sh' "$unit" \
        && grep -q 'Managed by docker-manager-v3.1.sh' "$ctrunit" \
        || { error '现有服务非本脚本管理，拒绝卸载'; return 1; }
    systemctl stop docker || { error 'Docker 停止失败，取消卸载'; return 1; }
    systemctl stop containerd || { error 'containerd 停止失败，取消卸载'; return 1; }
    systemctl disable docker containerd || warn '取消开机启动有部分失败'
    local backup_dir="/usr/local/docker-manager-backup-${BACKUP_STAMP}" name path
    mkdir -p "$backup_dir/bin" "$backup_dir/config" "$backup_dir/systemd" || return 1
    for name in docker dockerd docker-init docker-proxy containerd containerd-shim-runc-v2 ctr runc \
                containerd-shim containerd-shim-runc-v1; do
        path="/usr/bin/$name"
        if [[ -f "$path" ]]; then
            mv -- "$path" "$backup_dir/bin/" || { error "备份 $path 失败，已停止后续卸载"; return 1; }
        fi
    done
    for path in /etc/docker/daemon.json /etc/containerd/config.toml; do
        if [[ -f "$path" ]]; then
            local prefix
            case "$path" in /etc/docker/*) prefix='docker' ;; *) prefix='containerd' ;; esac
            mv -- "$path" "$backup_dir/config/${prefix}-$(basename "$path")" || return 1
        fi
    done
    mv -- "$unit" "$backup_dir/systemd/docker.service" || return 1
    mv -- "$ctrunit" "$backup_dir/systemd/containerd.service" || return 1
    systemctl daemon-reload || return 1
    ok "已备份 Docker/containerd 可执行文件、配置和服务：$backup_dir"
    ok "未删除存储数据：/var/lib/docker、/var/lib/containerd 及自定义 data-root 均被保留"
}

show_docker_info() { docker info || error '无法获取 Docker 信息，请检查服务'; }
show_docker_ps() { docker ps --no-trunc || error '无法列出容器，请检查服务'; }

manage_menu() {
    local choice
    while true; do
        choice="$(whiptail --title "Docker 管理菜单（${SYSTEM_TYPE}）" --menu '请选择操作' 19 84 10 \
            '1' '禁用防火墙和 SELinux / UFW（保留原功能）' \
            '2' '全新安装最新 Docker Engine（安装后可安装 Compose）' \
            '3' '卸载/备份本脚本安装的 Docker（不删除数据）' \
            '4' '安装最新 Docker Compose 插件' \
            '5' '卸载/备份 Docker Compose 插件' \
            '6' '查看 Docker 信息' \
            '7' '查看运行中的容器' \
            '8' '返回主菜单' 3>&1 1>&2 2>&3)" || return 0
        clear
        case "$choice" in
            1) disable_firewall_selinux ;;
            2) install_docker ;;
            3) uninstall_docker ;;
            4) install_compose ;;
            5) uninstall_compose ;;
            6) show_docker_info ;;
            7) show_docker_ps ;;
            8) return 0 ;;
        esac
        cleanup_tmp
        pause_menu
    done
}

main() {
    local choice
    ok "Docker 通用安装脚本 $SCRIPT_VERSION（$SCRIPT_DATE）"
    while true; do
        choice="$(whiptail --title 'Docker 通用管理主菜单' --menu '请选择操作' 15 74 5 \
            '1' '系统信息查询' \
            '2' 'Docker 部署与管理' \
            '3' '退出' 3>&1 1>&2 2>&3)" || break
        clear
        case "$choice" in
            1) show_system_info; pause_menu ;;
            2) manage_menu ;;
            3) break ;;
        esac
    done
    printf '再见\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    [[ "$EUID" -eq 0 ]] || { error '必须使用 root 权限执行'; exit 1; }
    detect_system || exit 1
    prepare_prerequisites || exit 1
    main "$@"
fi
