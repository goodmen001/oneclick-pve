#!/bin/bash

set -e

# 检查是否已安装 lsb_release，没有就安装
if ! command -v lsb_release &> /dev/null; then
    echo "正在安装 lsb-release 以检测系统版本..."
    apt update && apt install -y lsb-release
fi

# 获取当前 Debian 版本和 PVE 版本
DEBIAN_CODENAME=$(lsb_release -c -s)
PVE_CODENAME="bookworm"
if [[ "$DEBIAN_CODENAME" == "trixie" ]]; then
    PVE_CODENAME="trixie"
fi

# 国内镜像源列表
declare -A SOURCES
SOURCES=(
    [1]="清华大学|http://mirrors.tuna.tsinghua.edu.cn"
    [2]="中科大|http://mirrors.ustc.edu.cn"
    [3]="阿里云|http://mirrors.aliyun.com"
    [4]="华为云|http://repo.huaweicloud.com"
    [5]="网易|http://mirrors.163.com"
)

echo "🔧 可用的 Debian 13 国内镜像源："
for i in "${!SOURCES[@]}"; do
    NAME=$(echo "${SOURCES[$i]}" | cut -d'|' -f1)
    echo "  $i) $NAME"
done
echo "  0) 跳过更换镜像源"

read -rp "请输入你想使用的镜像源编号（支持 0 跳过）： " SOURCE_CHOICE
MIRROR_URL=""
if [[ "${SOURCES[$SOURCE_CHOICE]}" != "" ]]; then
    MIRROR_URL=$(echo "${SOURCES[$SOURCE_CHOICE]}" | cut -d'|' -f2)
    echo "✅ 你选择了：${SOURCES[$SOURCE_CHOICE]}"
else
    echo "⚠️ 未选择有效镜像源，跳过源替换。"
fi

if [[ -n "$MIRROR_URL" ]]; then
    echo "📝 正在写入 sources.list..."
    cat > /etc/apt/sources.list <<EOF
deb ${MIRROR_URL}/debian ${DEBIAN_CODENAME} main contrib non-free non-free-firmware
deb ${MIRROR_URL}/debian ${DEBIAN_CODENAME}-updates main contrib non-free non-free-firmware
deb ${MIRROR_URL}/debian ${DEBIAN_CODENAME}-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${DEBIAN_CODENAME}-security main contrib non-free non-free-firmware
EOF

    # Proxmox 镜像替换
    echo "📝 正在写入 PVE 源..."
    echo "deb ${MIRROR_URL}/proxmox/debian/pve ${PVE_CODENAME} pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
    rm -f /etc/apt/sources.list.d/pve-enterprise.list
fi

echo "⏳ 正在执行 apt update 和 dist-upgrade..."
apt update && apt dist-upgrade -y

# 工具包选择安装
TOOLS=(
    "htop"
    "curl"
    "wget"
    "vim"
    "net-tools"
    "git"
    "zip"
    "unzip"
    "lsof"
    "tree"
    "screen"
)

echo ""
echo "🧰 可选常用工具包："
for i in "${!TOOLS[@]}"; do
    echo "  $((i+1))) ${TOOLS[$i]}"
done
echo "  0) 全部跳过安装"

read -rp "请输入要安装的工具包编号（可用空格分隔，例如：1 3 5）： " TOOL_SELECTION

TO_INSTALL=()
for index in $TOOL_SELECTION; do
    if [[ "$index" =~ ^[0-9]+$ && "$index" -gt 0 && "$index" -le ${#TOOLS[@]} ]]; then
        TO_INSTALL+=("${TOOLS[$((index-1))]}")
    fi
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    echo "📦 开始安装选择的工具包：${TO_INSTALL[*]}"
    apt install -y "${TO_INSTALL[@]}"
else
    echo "⚠️ 未选择工具包，跳过安装。"
fi

# 是否重启
echo ""
read -rp "🎯 是否立即重启系统？(y/n): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" == "y" || "$REBOOT_CHOICE" == "Y" ]]; then
    echo "♻️ 即将重启..."
    reboot
else
    echo "✅ 操作完成，系统未重启。"
fi
