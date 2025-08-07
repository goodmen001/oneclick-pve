#!/bin/bash
set -e

echo "🔧 修复 Proxmox 企业源和 Debian 安全源配置..."

# 修复安全源地址
sed -i 's|http://mirrors.tuna.tsinghua.edu.cn/debian bookworm-security|http://security.debian.org bookworm-security|' /etc/apt/sources.list

# 注释企业源，防止401错误
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
    sed -i 's|^deb https://enterprise.proxmox.com|# deb https://enterprise.proxmox.com|' /etc/apt/sources.list.d/pve-enterprise.list
fi

# 更新 apt 并安装必须工具
apt update
apt install -y lsb-release curl sudo

# 获取 Debian 代号
DEBIAN_CODENAME=$(lsb_release -cs)

# 定义国内镜像源
declare -A SOURCES=(
  [1]="清华|http://mirrors.tuna.tsinghua.edu.cn/debian"
  [2]="中科大|http://mirrors.ustc.edu.cn/debian"
  [3]="阿里云|http://mirrors.aliyun.com/debian"
  [4]="华为云|https://mirrors.huaweicloud.com/debian"
  [5]="网易|http://mirrors.163.com/debian"
)

echo "请选择你想使用的镜像源（0 跳过更换源）："
for i in "${!SOURCES[@]}"; do
  name=$(echo "${SOURCES[$i]}" | cut -d'|' -f1)
  echo "  $i) $name"
done
read -rp "输入编号 [0-5]: " CHOICE

MIRROR_URL=""
if [[ "$CHOICE" =~ ^[1-5]$ ]]; then
  MIRROR_URL=$(echo "${SOURCES[$CHOICE]}" | cut -d'|' -f2)
  echo "✅ 选择了 $MIRROR_URL"
else
  echo "⚠️ 跳过更换镜像源"
fi

# 替换 sources.list
if [[ -n "$MIRROR_URL" ]]; then
  echo "备份旧源..."
  cp /etc/apt/sources.list /etc/apt/sources.list.bak

  echo "写入新源..."
  cat >/etc/apt/sources.list <<EOF
deb $MIRROR_URL $DEBIAN_CODENAME main contrib non-free non-free-firmware
deb $MIRROR_URL $DEBIAN_CODENAME-updates main contrib non-free non-free-firmware
deb $MIRROR_URL $DEBIAN_CODENAME-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $DEBIAN_CODENAME-security main contrib non-free non-free-firmware
EOF

  echo "写入 PVE 社区非订阅源..."
  echo "deb $MIRROR_URL/proxmox/debian/pve $DEBIAN_CODENAME pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

  # 删除企业源防止冲突
  rm -f /etc/apt/sources.list.d/pve-enterprise.list
fi

echo "更新系统包列表并升级..."
apt update && apt dist-upgrade -y

# 常用工具选项
TOOLS=(
  htop
  curl
  vim
  net-tools
  lsof
  git
  unzip
  wget
)

echo -e "\n请选择要安装的常用工具（用空格分隔编号，0 跳过）："
for i in "${!TOOLS[@]}"; do
  echo "  $((i+1))) ${TOOLS[$i]}"
done

read -rp "输入编号（例如：1 3 5）： " TOOL_SELECTIONS

INSTALL_LIST=()
for idx in $TOOL_SELECTIONS; do
  if [[ "$idx" == "0" ]]; then
    INSTALL_LIST=()
    break
  elif [[ "$idx" =~ ^[1-9][0-9]*$ ]] && (( idx >= 1 && idx <= ${#TOOLS[@]} )); then
    INSTALL_LIST+=("${TOOLS[$((idx-1))]}")
  fi
done

if [[ ${#INSTALL_LIST[@]} -gt 0 ]]; then
  echo "安装工具：${INSTALL_LIST[*]}"
  apt install -y "${INSTALL_LIST[@]}"
else
  echo "跳过工具安装。"
fi

echo
read -rp "是否立即重启系统？(y/N): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
  echo "系统将在3秒后重启..."
  sleep 3
  reboot
else
  echo "操作完成，未重启。"
fi
