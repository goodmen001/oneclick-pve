#!/bin/bash

set -e

echo "🔧 正在准备国内源列表..."

# 镜像源列表定义
declare -A SOURCES
SOURCES["1"]="清华大学|http://mirrors.tuna.tsinghua.edu.cn"
SOURCES["2"]="中科大|http://mirrors.ustc.edu.cn"
SOURCES["3"]="阿里云|http://mirrors.aliyun.com"
SOURCES["4"]="华为云|http://repo.huaweicloud.com"
SOURCES["5"]="网易|http://mirrors.163.com"

# 显示选择菜单
echo "请选择你想使用的镜像源："
for i in "${!SOURCES[@]}"; do
    name=$(echo "${SOURCES[$i]}" | cut -d'|' -f1)
    echo "  $i) $name"
done

read -p "请输入对应的数字编号 [1-5]：" choice
if [[ -z "${SOURCES[$choice]}" ]]; then
    echo "❌ 无效选择，脚本终止。"
    exit 1
fi

MIRROR_NAME=$(echo "${SOURCES[$choice]}" | cut -d'|' -f1)
MIRROR_URL=$(echo "${SOURCES[$choice]}" | cut -d'|' -f2)
echo "✅ 你选择的是：$MIRROR_NAME"

# 备份源
echo "🔄 正在备份源配置..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak
cp /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak 2>/dev/null || true

# 写入 Debian 13 源
echo "📝 正在写入 Debian 13 (Trixie) 的镜像源..."
cat > /etc/apt/sources.list <<EOF
deb $MIRROR_URL/debian/ trixie main contrib non-free non-free-firmware
deb $MIRROR_URL/debian/ trixie-updates main contrib non-free non-free-firmware
deb $MIRROR_URL/debian/ trixie-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

# 注释企业源
echo "🛠️ 禁用企业源..."
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true

# 添加非订阅源
if [[ "$choice" == "1" || "$choice" == "2" ]]; then
    echo "➕ 添加 PVE 社区非订阅源..."
    cat > /etc/apt/sources.list.d/pve-no-subscription.list <<EOF
deb $MIRROR_URL/proxmox/debian/pve trixie pve-no-subscription
EOF
else
    echo "⚠️ 你选择的镜像站不提供 Proxmox 社区源，已跳过配置。"
fi

# 更新与升级
echo "📦 正在更新软件包列表..."
apt update
echo "⬆️ 正在升级系统..."
apt dist-upgrade -y

# 工具包选择
declare -A TOOLS
TOOLS["1"]="htop"
TOOLS["2"]="curl"
TOOLS["3"]="vim"
TOOLS["4"]="net-tools"
TOOLS["5"]="lsof"
TOOLS["6"]="git"
TOOLS["7"]="unzip"
TOOLS["8"]="wget"

echo ""
echo "🔧 请选择你想安装的工具（可多选，用空格分隔，如：1 3 5）"
for i in "${!TOOLS[@]}"; do
    echo "  $i) ${TOOLS[$i]}"
done
echo "  0) 不安装任何工具"
read -p "请输入选项编号：" -a selected

# 处理用户选择
install_list=()
for index in "${selected[@]}"; do
    if [[ "$index" == "0" ]]; then
        install_list=()
        break
    elif [[ -n "${TOOLS[$index]}" ]]; then
        install_list+=("${TOOLS[$index]}")
    fi
done

# 安装工具
if [[ ${#install_list[@]} -gt 0 ]]; then
    echo "🔧 正在安装工具包: ${install_list[*]}"
    apt install -y "${install_list[@]}"
else
    echo "✅ 未选择任何工具包，跳过安装。"
fi

echo "🎉 脚本执行完毕！系统已切换为 $MIRROR_NAME 镜像源，并完成更新。"
