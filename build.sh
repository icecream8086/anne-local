#!/usr/bin/env bash
# build.sh —— 拉取锁定的上游 Anne 包，叠加我们的补丁/文件/删除清单，产出可部署的 tar.gz
#
# 用法:
#   bash build.sh                 # 默认版本号 = 当前日期时间
#   VERSION=v1.0.0 bash build.sh  # 指定版本号
#
# 产物: dist/anne-local-<VERSION>.tar.gz（游戏树 overlay，根目录即 left4dead2/）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source VERSIONS.lock
: "${UPSTREAM_REPO:?}" "${UPSTREAM_TAG:?}" "${UPSTREAM_ASSET:?}"

VERSION="${VERSION:-$(date +%Y%m%d-%H%M)}"
CACHE=".cache"
BUILD="build"
DIST="dist"
mkdir -p "$CACHE" "$DIST"

# ---------- 1. 取上游包（有缓存则复用，并按锁校验） ----------
asset="$CACHE/$UPSTREAM_ASSET"
if [ ! -f "$asset" ]; then
  url="https://github.com/${UPSTREAM_REPO}/releases/download/${UPSTREAM_TAG}/${UPSTREAM_ASSET}"
  echo "==> download: $url"
  curl -fL --retry 3 --retry-delay 2 -o "$asset.part" "$url"
  mv "$asset.part" "$asset"
else
  echo "==> cache hit: $asset"
fi
if [ -n "${UPSTREAM_ASSET_SHA256:-}" ]; then
  echo "${UPSTREAM_ASSET_SHA256}  ${asset}" | sha256sum -c -
fi

# ---------- 2. 解包 ----------
rm -rf "$BUILD"; mkdir -p "$BUILD"
tar -xzf "$asset" -C "$BUILD" --strip-components=1
[ -d "$BUILD/left4dead2" ] || { echo "ERROR: 包结构不是 <顶层>/left4dead2/"; exit 1; }

# ---------- 3. 打补丁 ----------
echo "==> patches"
shopt -s nullglob
n=0
for p in patches/*.patch; do
  echo "  - $(basename "$p")"
  abs="$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
  if command -v patch >/dev/null 2>&1; then
    patch -p1 -d "$BUILD/left4dead2" --forward --no-backup-if-mismatch < "$abs"
  else
    ( cd "$BUILD/left4dead2" && git apply -p1 --whitespace=nowarn "$abs" )
  fi
  n=$((n+1))
done
echo "    applied $n patch(es)"

# ---------- 4. 覆盖文件 ----------
echo "==> overlay files"
if [ -d overlay/files ]; then
  cp -a overlay/files/. "$BUILD/"
  find overlay/files -type f | sed 's#^overlay/files/#    +#'
fi

# ---------- 5. 删除清单 ----------
echo "==> removals"
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  case "$rel" in \#*) continue ;; esac
  if [ -e "$BUILD/left4dead2/$rel" ]; then
    rm -f "$BUILD/left4dead2/$rel"
    echo "    - $rel"
  else
    echo "    ! 已不存在: $rel"
  fi
done < remove.txt

# ---------- 6. 断言（防上游漂移） ----------
echo "==> assertions"
fail=0
ok()  { echo "    ok   $1"; }
bad() { echo "    FAIL $1"; fail=1; }

[ -f "$BUILD/left4dead2/addons/sourcemod/plugins/l4d2_dirspawn.smx" ] \
  && ok "dirspawn 1.6.3 已覆盖" || bad "dirspawn smx 缺失"

cnt=$(grep -rl 'confogl_addcvar join_autoupdate 0' "$BUILD/left4dead2/cfg/cfgogl" 2>/dev/null | wc -l)
[ "$cnt" -ge 9 ] && ok "join_autoupdate=0 覆盖 $cnt 个模式" || bad "join_autoupdate=0 只覆盖 $cnt 个模式"

grep -qE '^sm plugins load extend/anne_db' "$BUILD/left4dead2/cfg/generalfixes.cfg" \
  && bad "anne_db 仍在加载" || ok "anne_db 未加载"

grep -qE '^sm plugins load extend/(rpg|savechat|updater)\.smx' "$BUILD/left4dead2/cfg/sharedplugins.cfg" \
  && bad "rpg/savechat/updater 仍在加载" || ok "rpg/savechat/updater 未加载"

grep -q 'anne.trygek.com/accelerator' "$BUILD/left4dead2/addons/sourcemod/configs/core.cfg" \
  && bad "崩溃上报 URL 未清空" || ok "崩溃上报已关闭"

[ -f "$BUILD/left4dead2/addons/sourcemod/extensions/dbi.mysql.ext.so" ] \
  && bad "mysql 驱动仍在" || ok "mysql 驱动已移除"

if [ "$fail" -ne 0 ]; then
  echo "==> assertions failed"
  exit 1
fi

# ---------- 7. 打包 ----------
out="$DIST/anne-local-${VERSION}.tar.gz"
tar -czf "$out" -C "$BUILD" .
plugins=$(find "$BUILD/left4dead2/addons/sourcemod/plugins" -name '*.smx' | wc -l)
echo "==> done: $out"
echo "    size=$(du -h "$out" | cut -f1)  plugins=$plugins"
