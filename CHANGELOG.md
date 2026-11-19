# 变更记录（本地构建仓）

## 2026-11-20 初始化（基线 2026-10-25）

- 建立方案 C：`VERSIONS.lock` 锁上游 `CompetitiveWithAnne-stable-release-2026-10-25`（nomysql，sha256 `342d3b92…`）
- 27 个 cfg 补丁：
  - `cfg/server.cfg`：关 FastDL / 关 rcon / `sv_allowdownload 1` / 离线块（`join_autoupdate 0`、MOTD+新人指导保留、IP/赞助清空）
  - `cfg/generalfixes.cfg`：注释 `extend/anne_db.smx`
  - `cfg/sharedplugins.cfg`：注释 `extend/updater|savechat|rpg.smx`
  - `cfg/cfgogl/*/{confogl_plugins,shared_plugins}.cfg`：13 行 DB 插件加载注释
  - `cfg/cfgogl/*/shared_settings.cfg`：9 处 `join_autoupdate 1 → 0`
  - `addons/sourcemod/configs/core.cfg`：崩溃上报 URL 清空、`DisableAutoUpdate yes`
  - `cfg/sourcemod/network_quality_hint.cfg`：上报关闭、URL 清空
- 覆盖文件：`l4d2_dirspawn.smx` 1.6.3（+ 源码），修 `OnMapEnd` 定时器句柄
- 删除：MySQL 驱动、`anne_db`、`rpg`、`savechat`、`updater`、`l4d_random_beam_item`
