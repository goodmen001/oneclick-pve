#!/bin/bash

set -e

# 获取系统 codename（trixie, bookworm 等）
codename=$(lsb_release -sc)

# 可选的国内镜像源
declare -A mirrors=(
  [1]="http://mirrors.tuna.tsinghua.edu.cn/debian"
  [2]="http://mirrors.ustc.edu.cn/debian"
  [3]="http://mirrors.aliyun.com/debian"
  [4]="http://mirrors.huaweicloud.com/debian"
  [5]="http://mirrors.163.com/debian"
)

# 工具包列表
declare -A tools=(
  [1]="htop"
  [2]="vim"
  [3]="net-tools"
  [4]="curl"
  [5]="wget"
  [6]="git"
  [7]="lsb-release"
  [8]="nfs-common"
  [9]="sshpass"
  [10]="build-essential"
)

# 清除 PVE enterprise 仓库
echo "🧹 清除 PVE Enterprise 仓库..."
rm -f /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null
sed -i '/enterprise.proxmox.com/d' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null

# 选择镜像源
echo "🔧 可用的 Debian ${codename^^} 国内镜像源："
echo "  5) 网易"
echo "  4) 华为云"
echo "  3) 阿里云"
echo "  2) 中科大"
echo "  1) 清华大学"
echo "  0) 跳过更换镜像源"
read -p "请输入你想使用的镜像源编号（支持 0 跳过）： " mirror_choice

if [[ -n "${mirrors[$mirror_choice]}" ]]; then
  new_mirror="${mirrors[$mirror_choice]}"
  echo "✅ 你选择的是：${new_mirror}"
  cat > /etc/apt/sources.list <<EOF
deb ${new_mirror} ${codename} main contrib non-free non-free-firmware
deb ${new_mirror} ${codename}-updates main contrib non-free non-free-firmware
deb ${new_mirror} ${codename}-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${codename}-security main contrib non-free non-free-firmware
EOF
  echo "📦 已应用 ${new_mirror} 源。"
else
  echo "⚠️ 未选择有效镜像源，跳过源替换。"
fi

# 更新并升级
echo "⏳ 正在执行 apt update 和 dist-upgrade..."
apt update || echo "⚠️ apt update 可能部分失败，但继续执行..."
apt -y dist-upgrade

# 工具安装选项
echo "🧰 可选安装的常用工具："
for i in "${!tools[@]}"; do
  printf "  %2s) %s\n" "$i" "${tools[$i]}"
done
echo "  0) 跳过工具安装"
read -p "请输入要安装的工具编号（支持多个，以空格分隔）: " -a selected_tools

install_list=""
for i in "${selected_tools[@]}"; do
  if [[ "${tools[$i]}" != "" ]]; then
    install_list+=" ${tools[$i]}"
  fi
done

if [[ -n "$install_list" ]]; then
  echo "📦 正在安装: $install_list"
  apt install -y $install_list
  echo "✅ 工具安装完成"
else
  echo "⏩ 跳过工具安装"
fi

# 重启选项
read -p "🔁 是否立即重启系统？(y/n): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
  echo "🔄 正在重启..."
  reboot
else
  echo "✅ 所有任务完成，请根据需要手动重启。"
fi
