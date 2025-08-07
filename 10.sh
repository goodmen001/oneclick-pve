#!/bin/bash

# 检查 lsb_release 是否存在
if ! command -v lsb_release >/dev/null 2>&1; then
  echo "🔧 安装 lsb-release ..."
  apt update && apt install -y lsb-release
fi

# 获取版本号
OS_VERSION=$(lsb_release -cs)
PVE_VERSION=$(pveversion | cut -d"/" -f2 | cut -d"-" -f1)

echo "🔧 可用的 Debian $OS_VERSION 国内镜像源："
echo "  5) 网易"
echo "  4) 华为云"
echo "  3) 阿里云"
echo "  2) 中科大"
echo "  1) 清华大学"
echo "  0) 跳过更换镜像源"

read -p "请输入你想使用的镜像源编号（支持 0 跳过）： " MIRROR_CHOICE

# 映射源地址
case "$MIRROR_CHOICE" in
  1) MIRROR_URL="http://mirrors.tuna.tsinghua.edu.cn" ;;
  2) MIRROR_URL="http://mirrors.ustc.edu.cn" ;;
  3) MIRROR_URL="http://mirrors.aliyun.com" ;;
  4) MIRROR_URL="http://mirrors.huaweicloud.com" ;;
  5) MIRROR_URL="http://mirrors.163.com" ;;
  0) echo "⚠️ 未选择镜像源，跳过源替换。" ;;
  *) echo "⚠️ 未选择有效镜像源，跳过源替换。" ;;
esac

# 替换 Debian 和 PVE 源
if [[ -n "$MIRROR_URL" ]]; then
  echo "✅ 使用镜像源: $MIRROR_URL"
  echo "🔁 正在备份并替换 apt 源列表..."

  cp /etc/apt/sources.list /etc/apt/sources.list.bak

  cat > /etc/apt/sources.list <<EOF
deb $MIRROR_URL/debian $OS_VERSION main contrib non-free non-free-firmware
deb $MIRROR_URL/debian $OS_VERSION-updates main contrib non-free non-free-firmware
deb $MIRROR_URL/debian $OS_VERSION-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $OS_VERSION-security main contrib non-free non-free-firmware
EOF

  echo "🔁 替换 PVE 源..."
  echo "deb $MIRROR_URL/proxmox/debian/pve $OS_VERSION pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
fi

# 注释掉 Proxmox 企业源
if grep -q "^deb https://enterprise.proxmox.com" /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null; then
  echo "🔒 正在注释掉 Proxmox Enterprise 源..."
  sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list
fi

# 更新并升级
echo "⏳ 正在执行 apt update 和 dist-upgrade..."
apt update
apt dist-upgrade -y

# 安装常用工具包
echo "🔧 安装常用工具包（htop curl vim git sudo net-tools iftop iperf3）..."
apt install -y htop curl vim git sudo net-tools iftop iperf3

# 是否重启
read -p "🔁 是否立即重启系统？(y/N): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" == "y" || "$REBOOT_CHOICE" == "Y" ]]; then
  echo "🔁 即将重启..."
  reboot
else
  echo "✅ 脚本执行完成，不重启。"
fi
