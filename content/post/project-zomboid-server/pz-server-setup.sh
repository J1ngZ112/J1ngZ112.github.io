#!/bin/bash
###############################################################################
# Project Zomboid 服务器一键部署脚本（Ubuntu 22.04 / 阿里云 ECS 4核8G 验证通过）
#
# 用法：
#   1. 新实例创建后，先在控制台放行安全组 UDP 16261/16262（脚本管不了云防火墙）
#   2. scp 本脚本到服务器:  scp pz-server-setup.sh root@你的IP:/root/
#   3. SSH 登录后执行:      bash /root/pz-server-setup.sh
#   4. （可选）恢复存档:    bash /root/pz-server-setup.sh --restore /root/pzsave.tar.gz
#
# 脚本完成后还需手动做的两件事：
#   - 上传本地配置: scp ~/Zomboid/Server/servertest* root@IP:/home/pz/Zomboid/Server/
#     然后 chown pz:pz /home/pz/Zomboid/Server/servertest*
#   - 启动服务器:   su - pz; cd /home/pz/pzserver; screen -S pz; bash start-server.sh
###############################################################################

set -e

# ---------- 可配置项 ----------
PZ_USER=pz
PZ_DIR=/home/pz/pzserver
HEAP_SIZE=4g          # Java 堆内存，mod 多可改 6g
SWAP_SIZE=4G
BACKUP_KEEP=20        # 保留的备份份数
BACKUP_CRON="0 */6 * * *"   # 每 6 小时备份一次
# ------------------------------

if [ "$(id -u)" != "0" ]; then
    echo "请用 root 运行: bash $0"
    exit 1
fi

echo "==> [1/7] 安装依赖"
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y lib32gcc-s1 screen curl

echo "==> [2/7] 创建 ${PZ_USER} 用户"
if ! id "$PZ_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$PZ_USER"
fi

echo "==> [3/7] 配置 ${SWAP_SIZE} swap"
if ! swapon --show | grep -q swapfile; then
    fallocate -l "$SWAP_SIZE" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    grep -q swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "==> [4/7] 安装 SteamCMD 和 PZ 服务端（约几百MB，耐心等待）"
sudo -u "$PZ_USER" bash <<'EOF'
set -e
mkdir -p ~/steamcmd && cd ~/steamcmd
if [ ! -f steamcmd.sh ]; then
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
fi
# 匿名接口偶尔抽风，失败自动重试 3 次
for i in 1 2 3; do
    ./steamcmd.sh +force_install_dir /home/pz/pzserver +login anonymous \
        +app_update 380870 validate +quit && break
    echo "安装失败，第 $i 次重试..."
    sleep 5
done
EOF

echo "==> [5/7] 调整 Java 堆内存为 ${HEAP_SIZE}（防止 OOM 被杀）"
sed -i "s/\"-Xms[0-9]*[gG]\"/\"-Xms${HEAP_SIZE}\"/; s/\"-Xmx[0-9]*[gG]\"/\"-Xmx${HEAP_SIZE}\"/" \
    "$PZ_DIR/ProjectZomboid64.json"

echo "==> [6/7] 配置存档自动备份"
cat > /home/pz/backup.sh <<EOF
#!/bin/bash
BACKUP_DIR=/home/pz/backups
SAVE_DIR=/home/pz/Zomboid/Saves/Multiplayer
mkdir -p "\$BACKUP_DIR"
tar -czf "\$BACKUP_DIR/pzsave-\$(date +%Y%m%d-%H%M).tar.gz" -C "\$SAVE_DIR" servertest
ls -t "\$BACKUP_DIR"/pzsave-*.tar.gz | tail -n +$((BACKUP_KEEP+1)) | xargs -r rm
EOF
chmod +x /home/pz/backup.sh
chown "$PZ_USER:$PZ_USER" /home/pz/backup.sh
# 写入 pz 用户的 crontab（去重）
sudo -u "$PZ_USER" bash -c \
    "(crontab -l 2>/dev/null | grep -v backup.sh; echo '$BACKUP_CRON /home/pz/backup.sh') | crontab -"

echo "==> [7/7] 收尾"
chown -R "$PZ_USER:$PZ_USER" /home/pz

# 可选：恢复存档（tar 包内应包含 servertest/ 目录）
if [ "$1" = "--restore" ] && [ -n "$2" ]; then
    echo "==> 恢复存档: $2"
    sudo -u "$PZ_USER" mkdir -p /home/pz/Zomboid/Saves/Multiplayer
    tar -xzf "$2" -C /home/pz/Zomboid/Saves/Multiplayer
    chown -R "$PZ_USER:$PZ_USER" /home/pz/Zomboid
    echo "    存档已恢复"
fi

cat <<'DONE'

==========================================
  部署完成！接下来手动做这几件事：

  1. 【每次新实例必做】阿里云控制台放行安全组：
     入方向 自定义UDP 16261/16262 来源 0.0.0.0/0

  2. 上传本地配置（在你自己电脑终端执行）：
     scp ~/Zomboid/Server/servertest* root@本机IP:/home/pz/Zomboid/Server/
     然后在本服务器执行:
     chown pz:pz /home/pz/Zomboid/Server/servertest*

  3. 启动服务器：
     su - pz
     cd /home/pz/pzserver
     screen -S pz
     bash start-server.sh
     （首次启动会提示设置管理员密码）

  4. 退出 screen 保持后台: Ctrl+A 然后 D
==========================================
DONE
