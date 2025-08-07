#!/bin/bash

set -e

# 可选的国内镜像源列表
declare -A mirrors=(
  [1]="https://mirrors.tuna.tsinghua.edu.cn/debian/"
  [2]="https://mirrors.ustc.edu.cn/debian/"
  [3]="https://mirrors.aliyun.com/debian/"
  [4]="https://mirrors.huaweicloud.com/debian/"
  [5]="https://mirrors.163.com/debian/"
)

# 删除 PVE enterprise 源，避免 401 错误
echo "🧹 清除 PVE Enterprise 仓库..."
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  rm -f /etc/apt/sources.list.d/pve-enterprise.list
  echo "✅ 已删除 /etc/apt/sources.list.d/pve-enterprise.list"
fi

# 替换镜像源
echo "🔧 可用的 Debian 13 国内镜像源："
echo "  5) 网易"
echo "  4) 华为云"
echo "  3) 阿里云"
echo "  2) 中科大"
echo "  1) 清华大学"
echo "  0) 跳过更换镜像源"
read -p "请输入你想使用的镜像源编号（支持 0 跳过）: " mirror_choice

if [[ -n "${mirrors[$mirror_choice]}" ]]; then
  echo "🔄 正在替换为 ${mirrors[$mirror_choice]} ..."
  sed -i.bak "s|http://.*.debian.org/debian|${mirrors[$mirror_choice]}|g" /etc/apt/sources.list
  sed -i "s|http://deb.debian.org/debian|${mirrors[$mirror_choice]}|g" /etc/apt/sources.list
  echo "✅ 镜像源替换完成"
else
  echo "⚠️ 未选择有效镜像源，跳过源替换。"
fi

# 更新并升级系统
echo "⏳ 正在执行 apt update 和 dist-upgrade..."
apt update && apt -y dist-upgrade || echo "⚠️ apt 更新出错，但继续执行..."

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

echo "🧰 可选安装的常用工具："
for i in "${!tools[@]}"; do
  printf "  %2s) %s\n" "$i" "${tools[$i]}"
done
echo "  0) 跳过工具安装"
read -p "请输入你要安装的工具编号（支持多个，以空格分隔）: " -a selected_tools

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

# 是否重启
read -p "🌀 是否立即重启系统？(y/n): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
  echo "🔁 即将重启系统..."
  reboot
else
  echo "✅ 所有任务完成，请手动重启以确保生效。"
fi
