#!/bin/bash

set -e

# 镜像源列表
declare -A SOURCES
SOURCES[1]="清华大学|http://mirrors.tuna.tsinghua.edu.cn"
SOURCES[2]="中科大|http://mirrors.ustc.edu.cn"
SOURCES[3]="阿里云|http://mirrors.aliyun.com"
SOURCES[4]="华为云|https://repo.huaweicloud.com"
SOURCES[5]="网易|http://mirrors.163.com"

# 工具包列表
TOOLS_LIST=("htop" "curl" "vim" "net-tools" "lsof" "git" "unzip" "wget")
TOOLS_NAMES=("系统监控 htop" "网络工具 curl" "编辑器 vim" "网卡工具 net-tools" "端口工具 lsof" "版本管理 git" "压缩工具 unzip" "下载工具 wget")
SELECTED_TOOLS=()

echo "🔧 可用的 Debian 13 国内镜像源："
for i in {5..1}; do
    IFS="|" read -r NAME _ <<< "${SOURCES[$i]}"
    echo "  $i) $NAME"
done
echo "  0) 跳过更换镜像源"

read -rp "请输入你想使用的镜像源编号（支持 0 跳过）： " SOURCE_CHOICE

# 镜像源设置
if [[ "$SOURCE_CHOICE" =~ ^[0-5]$ ]]; then
    if [[ "$SOURCE_CHOICE" == "0" ]]; then
        echo "⚠️ 未选择镜像源，跳过更换。"
    else
        IFS="|" read -r SOURCE_NAME SOURCE_URL <<< "${SOURCES[$SOURCE_CHOICE]}"
        echo "🔁 使用镜像源：$SOURCE_NAME ($SOURCE_URL)"

        # 替换 debian 源
        cat > /etc/apt/sources.list <<EOF
deb $SOURCE_URL/debian trixie main contrib non-free non-free-firmware
deb $SOURCE_URL/debian trixie-updates main contrib non-free non-free-firmware
deb $SOURCE_URL/debian trixie-backports main contrib non-free non-free-firmware
deb $SOURCE_URL/debian-security trixie-security main contrib non-free non-free-firmware
EOF

        # 替换 PVE 源（保留社区版）
        cat > /etc/apt/sources.list.d/pve-install-repo.list <<EOF
deb $SOURCE_URL/proxmox/debian/pve bookworm pve-no-subscription
deb $SOURCE_URL/proxmox/debian/pve trixie pve-no-subscription
EOF

        echo "✅ 镜像源已更新。"
    fi
else
    echo "❌ 无效选择，跳过镜像源更换。"
fi

echo "⏳ 正在执行 apt update 和 dist-upgrade..."
apt update
apt dist-upgrade -y

# 工具包选择
echo ""
echo "📦 请选择你想安装的常用工具（输入多个数字以空格分隔，直接回车跳过）："
for i in "${!TOOLS_LIST[@]}"; do
    printf "  %d) %s\n" $((i + 1)) "${TOOLS_NAMES[$i]}"
done
read -rp "你的选择（如 1 3 5）: " TOOL_SELECTION

for i in $TOOL_SELECTION; do
    if [[ "$i" =~ ^[1-9]$ ]] && [ "$i" -le "${#TOOLS_LIST[@]}" ]; then
        SELECTED_TOOLS+=("${TOOLS_LIST[$((i - 1))]}")
    fi
done

if [ "${#SELECTED_TOOLS[@]}" -gt 0 ]; then
    echo "📦 安装以下工具包：${SELECTED_TOOLS[*]}"
    apt install -y "${SELECTED_TOOLS[@]}"
else
    echo "⚠️ 未选择工具包，跳过安装。"
fi

# 重启选项
echo ""
read -rp "🔁 是否现在重启系统？[y/N] " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
    echo "♻️ 即将重启..."
    reboot
else
    echo "✅ 安装完成，未重启。你可以手动重启以应用更新。"
fi
