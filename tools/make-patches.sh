#!/usr/bin/env bash
# make-patches.sh —— 从"当前游戏树"重新生成 cfg 补丁（升级上游后重放用）
#
# 用法:
#   bash tools/make-patches.sh /srv/l4d2/lab/game/left4dead2
#
# 做法:
#   1. 按 VERSIONS.lock 取上游包，解到 .cache/base；
#   2. 对 cfg/ 与 configs/core.cfg 逐文件 diff（只处理文本 cfg/txt）；
#   3. 写入 patches/，并列出"上游有、当前树没有"的文件（供 remove.txt 参考）。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source VERSIONS.lock

LIVE="${1:-}"
[ -n "$LIVE" ] && [ -d "$LIVE" ] || { echo "usage: $0 <live/left4dead2 dir>"; exit 1; }

CACHE=".cache"
BASE="$CACHE/base"
asset="$CACHE/$UPSTREAM_ASSET"
if [ ! -f "$asset" ]; then
  url="https://github.com/${UPSTREAM_REPO}/releases/download/${UPSTREAM_TAG}/${UPSTREAM_ASSET}"
  curl -fL --retry 3 -o "$asset.part" "$url" && mv "$asset.part" "$asset"
fi
if [ -n "${UPSTREAM_ASSET_SHA256:-}" ]; then
  echo "${UPSTREAM_ASSET_SHA256}  ${asset}" | sha256sum -c -
fi
rm -rf "$BASE"; mkdir -p "$BASE"
tar -xzf "$asset" -C "$BASE" --strip-components=1

rm -rf patches; mkdir -p patches
count=0
while IFS= read -r -d '' rel; do
  rel="${rel#./}"
  case "$rel" in
    cfg/*.cfg|cfg/*.txt|addons/sourcemod/configs/core.cfg) ;;
    *) continue ;;
  esac
  live_file="$LIVE/$rel"
  [ -f "$live_file" ] || continue
  if ! cmp -s "$BASE/left4dead2/$rel" "$live_file"; then
    out="patches/${rel//\//__}.patch"
    diff -u --label "a/$rel" --label "b/$rel" "$BASE/left4dead2/$rel" "$live_file" > "$out" || true
    echo "  patch $rel"
    count=$((count+1))
  fi
done < <(cd "$BASE/left4dead2" && find cfg addons/sourcemod/configs -type f -print0 2>/dev/null)

echo "==> $count patch(es) written to patches/"
echo "==> 上游有、当前树没有的 cfg 文件（如需删除，登记到 remove.txt）:"
while IFS= read -r -d '' rel; do
  rel="${rel#./}"
  case "$rel" in cfg/*|addons/sourcemod/configs/*) ;; *) continue ;; esac
  [ -e "$LIVE/$rel" ] || echo "    - $rel"
done < <(cd "$BASE/left4dead2" && find cfg addons/sourcemod/configs -type f -print0 2>/dev/null)
