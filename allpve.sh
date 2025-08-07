#!/bin/bash

# 适用于 PVE 9 / Debian 13 的国内源更换和常用工具安装脚本（带重启提示）

set -e

# 声明国内源列表
declare -A SOURCES
SOURCES=(
  [1]="清华大学|http://mirrors.tuna.tsinghua.edu.cn/debian"
  [2]="中科大|http://mirrors.ustc.edu.cn/debian"
  [3]="阿里云|http://mirrors.aliyun.com/debian"
  [4]="华为云|http://repo.huaweicloud.com/debian"
  [5]="网易|http://mirrors.163.com/debian"
)

echo "🔧 可用的 Debian 13 国内镜像源："
for i in "${!SOURCES[@]}"; do
  echo "  $i) ${SOURCES[$i]%%|*}"
done
echo "  0) 跳过更换镜像源"

read -p "请输入你想使用的镜像源编号（支持 0 跳过）： " CHOICE

if [[ "$CHOICE" =~ ^[1-5]$ ]]; then
  NAME="${SOURCES[$CHOICE]%%|*}"
  URL="${SOURCES[$CHOICE]##*|}"
  echo "✅ 你选择的是：$NAME - $URL"

  cat > /etc/apt/sources.list <<EOF
deb $URL bookworm main contrib non-free non-free-firmware
deb $URL bookworm-updates main contrib non-free non-free-firmware
deb $URL bookworm-backports main contrib non-free non-free-firmware
deb $URL bookworm-security main contrib non-free non-free-firmware
EOF

  echo "📦 已应用 $NAME 源。"

else
  echo "⚠️ 未选择有效镜像源，跳过源替换。"
fi

echo "⏳ 正在执行 apt update 和 dist-upgrade..."
apt update
apt dist-upgrade -y

TOOLS=(
  "htop"
  "curl"
  "vim"
  "net-tools"
  "lsof"
  "git"
  "unzip"
  "wget"
)

echo "🛠 请选择要安装的常用工具（空格分隔编号，直接回车跳过）："
for i in "${!TOOLS[@]}"; do
  echo "  $((i+1))) ${TOOLS[$i]}"
done

read -p "输入编号（如 1 2 3）： " TOOL_SELECTION

TO_INSTALL=()
for num in $TOOL_SELECTION; do
  if [[ "$num" =~ ^[1-9]$ ]] && (( num <= ${#TOOLS[@]} )); then
    TO_INSTALL+=("${TOOLS[$((num-1))]}")
  fi
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
  echo "🚀 正在安装：${TO_INSTALL[*]}"
  apt install -y "${TO_INSTALL[@]}"
else
  echo "📭 未选择任何工具包，跳过安装。"
fi

# ✅ 是否重启提示
echo ""
read -p "🔁 是否立即重启系统？(y/N): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" == "y" || "$REBOOT_CHOICE" == "Y" ]]; then
  echo "🌀 系统将在 5 秒后重启..."
  sleep 5
  reboot
else
  echo "✅ 脚本执行完毕，系统未重启。"
fi
