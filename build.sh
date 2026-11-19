#!/usr/bin/env bash
# build.sh —— 拉取锁定的上游 Anne 包，叠加 base 与指定 profile，产出可部署的 Linux 包
#
# 用法:
#   VERSION=v2026.11.20 bash build.sh                 # 默认只有 base（安全修复）
#   PROFILE=lan VERSION=v2026.11.20 bash build.sh     # 局域网离线配置
#   PROFILE=wan VERSION=v2026.11.20 bash build.sh     # 广域网配置（当前=base）
#
# 产物: dist/L4D2-Anne-linux-[<profile>-]<VERSION>.tar.gz（根目录即 left4dead2/）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source VERSIONS.lock
: "${UPSTREAM_REPO:?}" "${UPSTREAM_TAG:?}" "${UPSTREAM_ASSET:?}"

VERSION="${VERSION:-v$(date +%Y.%m.%d)}"
if ! printf '%s' "$VERSION" | grep -Eq '^v[0-9]{4}\.[0-9]{2}\.[0-9]{2}(-r[0-9]+)?$'; then
  echo "ERROR: VERSION 必须形如 v2026.11.20 或 v2026.11.20-r2（当前: $VERSION）"
  exit 2
fi
PROFILE="${PROFILE:-none}"
if [ "$PROFILE" != "none" ]; then
  printf '%s' "$PROFILE" | grep -Eq '^[a-z0-9_-]+$' || { echo "ERROR: PROFILE 名称非法: $PROFILE"; exit 2; }
  [ -d "profiles/$PROFILE" ] || { echo "ERROR: 不存在 profiles/$PROFILE"; exit 2; }
fi

PKG="L4D2-Anne-linux"
[ "$PROFILE" != "none" ] && PKG="$PKG-$PROFILE"
PKG="$PKG-$VERSION"

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

# ---------- 3. 打补丁（base 先，profile 后） ----------
apply_patches() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  shopt -s nullglob
  for p in "$dir"/*.patch; do
    echo "  - ${p#./}"
    abs="$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
    if command -v patch >/dev/null 2>&1; then
      patch -p1 -d "$BUILD/left4dead2" --forward --no-backup-if-mismatch < "$abs"
    else
      ( cd "$BUILD/left4dead2" && git apply -p1 --whitespace=nowarn "$abs" )
    fi
  done
}
echo "==> base patches";    apply_patches base/patches
if [ "$PROFILE" != "none" ]; then
  echo "==> profile patches ($PROFILE)"; apply_patches "profiles/$PROFILE/patches"
fi

# ---------- 4. 覆盖文件 ----------
echo "==> overlay files"
for d in base/overlay/files "profiles/$PROFILE/overlay/files"; do
  [ -d "$d" ] || continue
  cp -a "$d/." "$BUILD/"
  find "$d" -type f | sed 's#^#    +#'
done

# ---------- 5. 删除清单 ----------
echo "==> removals"
for f in base/remove.txt "profiles/$PROFILE/remove.txt"; do
  [ -f "$f" ] || continue
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    case "$rel" in \#*) continue ;; esac
    if [ -e "$BUILD/left4dead2/$rel" ]; then
      rm -f "$BUILD/left4dead2/$rel"
      echo "    - $rel"
    else
      echo "    ! 已不存在: $rel"
    fi
  done < "$f"
done

# ---------- 6. 断言（base 必过；lan 额外） ----------
echo "==> assertions"
fail=0
ok()  { echo "    ok   $1"; }
bad() { echo "    FAIL $1"; fail=1; }

root_ds="$BUILD/left4dead2/addons/sourcemod/plugins/l4d2_dirspawn.smx"
opt_ds="$BUILD/left4dead2/addons/sourcemod/plugins/optional/AnneHappy/l4d2_dirspawn.smx"
[ -f "$root_ds" ] && ok "dirspawn 1.6.3 已覆盖" || bad "dirspawn smx 缺失"
if [ -f "$opt_ds" ]; then
  [ "$(sha256sum "$root_ds" | cut -d' ' -f1)" = "$(sha256sum "$opt_ds" | cut -d' ' -f1)" ] \
    && ok "dirspawn optional 副本与根副本一致" || bad "dirspawn optional 副本与根副本不一致"
fi
grep -qE '^rcon_password ""' "$BUILD/left4dead2/cfg/server.cfg" \
  && ok "rcon 已禁用（空密码）" || bad "rcon 密码未清空"

if [ "$PROFILE" = "lan" ]; then
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
fi

if [ "$fail" -ne 0 ]; then
  echo "==> assertions failed"
  exit 1
fi

# ---------- 7. 打包（仅 Linux：剔除 .dll/.exe） ----------
out="$DIST/$PKG.tar.gz"
tar -czf "$out" --exclude='*.dll' --exclude='*.exe' -C "$BUILD" .
plugins=$(find "$BUILD/left4dead2/addons/sourcemod/plugins" -name '*.smx' | wc -l)
sha256sum "$out" | awk '{print $1"  '$PKG'.tar.gz"}' > "$out.sha256"

commit="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
built_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$DIST/$PKG.json" <<EOF
{
  "package": "$PKG.tar.gz",
  "version": "$VERSION",
  "profile": "$PROFILE",
  "built_at": "$built_at",
  "git_commit": "$commit",
  "upstream_repo": "$UPSTREAM_REPO",
  "upstream_tag": "$UPSTREAM_TAG",
  "upstream_asset": "$UPSTREAM_ASSET",
  "upstream_asset_sha256": "${UPSTREAM_ASSET_SHA256:-}",
  "plugins": $plugins
}
EOF

echo "==> done: $out"
echo "    size=$(du -h "$out" | cut -f1)  plugins=$plugins  profile=$PROFILE"
echo "    sha256: $(cut -d' ' -f1 "$out.sha256")"
echo "    meta:   $DIST/$PKG.json"
