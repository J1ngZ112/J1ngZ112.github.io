#!/usr/bin/env bash
# Ubuntu 22.04 x86_64：安装公开分支 PZ 服务端，不启动、不恢复或覆盖游戏数据。
# 用法：以 root 执行 bash pz-server-setup.sh
# 可选：PZ_HEAP_MAX=6g bash pz-server-setup.sh
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    echo '请以 root 运行此脚本。' >&2
    exit 1
fi
if [[ $(uname -m) != x86_64 ]]; then
    echo '此脚本仅面向 x86_64 实例。' >&2
    exit 1
fi

PZ_HEAP_MAX=${PZ_HEAP_MAX:-4g}
if [[ ! $PZ_HEAP_MAX =~ ^[1-9][0-9]*[gG]$ ]]; then
    echo 'PZ_HEAP_MAX 需要是 4g、6g 等格式。' >&2
    exit 1
fi
if [[ ${PZ_HEAP_MAX%[gG]} -lt 2 ]]; then
    echo '此脚本的初始堆为 2g，最大堆不能小于 2g。' >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y lib32gcc-s1 lib32stdc++6 screen curl ca-certificates python3
if ! id pz >/dev/null 2>&1; then
    useradd -m -s /bin/bash pz
fi

runuser -l pz -c 'bash -s' <<'INSTALL'
set -euo pipefail
# 重复运行可能更新程序或重置启动配置，请先关闭游戏进程。
if pgrep -u "$(id -u)" -f 'zombie.network.GameServer' >/dev/null; then
    echo '检测到游戏服务端进程，请先用 quit 正常关服。' >&2
    exit 1
fi
mkdir -p /home/pz/steamcmd
cd /home/pz/steamcmd
if [[ ! -f steamcmd.sh ]]; then
    curl -fSL --retry 3 \
        https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        -o steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
fi
installed=0
for attempt in 1 2 3; do
    log=$(mktemp)
    if ./steamcmd.sh +force_install_dir /home/pz/pzserver \
        +login anonymous +app_update 380870 validate +quit >"$log" 2>&1; then
        if grep -Eq "Success! App '380870' (fully installed|already up to date)" "$log"; then
            installed=1
        fi
    fi
    cat "$log"
    rm -f "$log"
    if [[ $installed -eq 1 ]]; then
        break
    fi
    echo "第 ${attempt}/3 次安装未确认成功。" >&2
    if [[ $attempt -lt 3 ]]; then sleep 5; fi
done
if [[ $installed -ne 1 ]]; then
    echo '安装失败，请检查上方日志、网络和 Steam 分支。' >&2
    exit 1
fi
INSTALL

# 只替换存在的 JVM 参数；格式变化时停止，不假装调整成功。
python3 - "$PZ_HEAP_MAX" <<'PY'
import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

config = Path('/home/pz/pzserver/ProjectZomboid64.json')
data = json.loads(config.read_text())
args = data['vmArgs']
if not isinstance(args, list):
    raise SystemExit('vmArgs 格式不符合预期，请手动检查启动配置。')
for flag, size in (('Xms', '2g'), ('Xmx', sys.argv[1])):
    matches = [i for i, arg in enumerate(args) if re.fullmatch(rf'-{flag}\d+[kKmMgG]?', arg)]
    if len(matches) != 1:
        raise SystemExit(f'未找到唯一的 {flag} 参数，请手动检查启动配置。')
    args[matches[0]] = f'-{flag}{size}'
backup = config.with_name(config.name + '.before-' + datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
shutil.copy2(config, backup)
config.write_text(json.dumps(data, indent=4) + '\n')
PY

echo '基础安装完成。请确认内存参数、安全组和游戏版本，再恢复数据或手动首次启动。'
echo '启动方法：su - pz，然后进入 screen，执行：'
echo 'cd /home/pz/pzserver && bash start-server.sh -servername servertest'
