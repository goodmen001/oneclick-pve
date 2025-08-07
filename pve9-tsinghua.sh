#!/bin/bash

echo "🔧 正在备份原始 sources.list 和 pve 源文件..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak
cp /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak 2>/dev/null

echo "📝 更换 Debian 官方源为清华源..."
cat > /etc/apt/sources.list <<EOF
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

echo "🛠️ 禁用 PVE 企业源（非订阅用户不建议启用）..."
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null

echo "➕ 添加 PVE 社区源（清华镜像）..."
cat > /etc/apt/sources.list.d/pve-no-subscription.list <<EOF
deb http://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/pve bookworm pve-no-subscription
EOF

echo "🔄 正在更新软件包列表..."
apt update

echo "✅ 更换完成，可使用 apt upgrade 进行升级。"
