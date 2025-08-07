#!/bin/bash

set -e

# ========== Step 0: 检查并安装 lsb-release ==========
if ! command -v lsb_release &> /dev/null; then
  echo "正在安装 lsb-release 以检测系统版本..."
  apt update && apt install -y lsb-release
fi

codename=$(lsb_release -cs)

# ========== Step 1: 选择镜像源 ==========
echo "请选择你想使用的镜像源："
echo "  1) 清华大学"
echo "  2) 中科大"
echo "  3) 阿里云"
echo "  4) 华为云"
echo "  5) 网易"
echo "  0) 跳过更换源"

read -rp "请输入选项 [0-5]: " source_choice

case "$source_choice" in
  1)
    debian_url="http://mirrors.tuna.tsinghua.edu.cn/debian"
    pve_url="http://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/pve"
    ;;
  2)
    debian_url="http://mirrors.ustc.edu.cn/debian"
    pve_url="http://mirrors.ustc.edu.cn/proxmox/debian/pve"
    ;;
  3)
    debian_url="http://mirrors.aliyun.com/debian"
    pve_url="http://mirrors.aliyun.com/proxmox/debian/pve"
    ;;
  4)
    debian_url="https://mirrors.huaweicloud.com/debian"
    pve_url="https://mirrors.huaweicloud.com/proxmox/debian/pve"
    ;;
  5)
    debian_url="http://mirrors.163.com/debian"
    pve_url="http://mirrors.163.com/proxmox/debian/pve"
    ;;
  0)
    echo "跳过镜像源更换..."
    ;;
  *)
    echo "无效选择，跳过换源。"
    ;;
esac

# ========== Step 2: 替换源 ==========
if [[ "$source_choice" =~ ^[1-5]$ ]]; then
  echo "正在备份原有源..."
  cp /etc/apt/sources.list /etc/apt/sources.list.bak
  cp /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak 2>/dev/null || true

  echo "替换为选定的源..."
  cat > /etc/apt/sources.list <<EOF
deb ${debian_url} ${codename} main contrib non-free non-free-firmware
deb ${debian_url} ${codename}-updates main contrib non-free non-free-firmware
deb ${debian_url} ${codename}-backports main contrib non-free non-free-firmware
deb ${debian_url} ${codename}-security main contrib non-free non-free-firmware
EOF

  echo "deb ${pve_url} ${codename} pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
  rm -f /etc/apt/sources.list.d/pve-enterprise.list
fi

# ========== Step 3: 更新系统 ==========
echo "正在更新系统..."
apt update
apt dist-upgrade -y

# ========== Step 4: 选择安装常用工具 ==========
echo "请选择要安装的常用工具（用空格分隔多选，回车跳过）："
echo "  1) htop"
echo "  2) curl"
echo "  3) vim"
echo "  4) net-tools"
echo "  5) lsof"
echo "  6) git"
echo "  7) unzip"
echo "  8) wget"
read -rp "输入选项（例如：1 2 3）: " tool_choices

declare -A tools=(
  [1]="htop"
  [2]="curl"
  [3]="vim"
  [4]="net-tools"
  [5]="lsof"
  [6]="git"
  [7]="unzip"
  [8]="wget"
)

install_list=()

for choice in $tool_choices; do
  tool="${tools[$choice]}"
  if [[ -n "$tool" ]]; then
    install_list+=("$tool")
  fi
done

if [[ ${#install_list[@]} -gt 0 ]]; then
  echo "正在安装选定的工具包：${install_list[*]}"
  apt install -y "${install_list[@]}"
else
  echo "未选择任何工具包，跳过安装。"
fi

# ========== Step 5: 是否重启 ==========
echo ""
read -rp "是否立即重启系统？(y/N): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
  echo "系统将在 3 秒后重启..."
  sleep 3
  reboot
else
  echo "操作完成。系统未重启。"
fi
