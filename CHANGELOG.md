# 变更记录（本地构建仓）

## 2026-11-20 拆分 base / profile

- 默认构建（`PROFILE=none`）不再套任何部署配置：只有 base 的 `rcon_password ""` 与 `l4d2_dirspawn` 1.6.3
- 原离线/局域网配置整体移入 `profiles/lan/`（FastDL 注释、`sv_lan 1`、`join_autoupdate 0`、关上报、移除 MySQL/DB 插件）
- 新增 `profiles/wan/` 占位（当前只有 base，后续按广域网需求加）
- 产物名带 profile：`L4D2-Anne-linux-lan-v2026.11.20.tar.gz`；CI 增加 `profile` 输入
- 理由：LAN 与 WAN 配置相反，部署差异不应写成仓库默认

## 2026-11-20 标准化命名

- 产物统一为 **`L4D2-Anne-linux-<version>.tar.gz`**（仅 Linux，打包剔除 `.dll`/`.exe`），附同名 `.sha256` 与 `.json` 元数据
- 版本号统一为 `vYYYY.MM.DD` / `vYYYY.MM.DD-rN`，`build.sh` 校验格式
- CI workflow 更名 **Build Linux package**，artifact 与产物同名；Release 资产含 tar.gz/sha256/json

## 2026-11-20 初始化（基线 2026-10-25）

- 建立构建仓（固定上游版本 + overlay）：`VERSIONS.lock` 锁上游 `CompetitiveWithAnne-stable-release-2026-10-25`（nomysql，sha256 `342d3b92…`）
- 27 个 cfg 补丁：
  - `cfg/server.cfg`：关 FastDL / 关 rcon / `sv_allowdownload 1` / 离线块（`join_autoupdate 0`、MOTD+新人指导保留、IP/赞助清空）
  - `cfg/generalfixes.cfg`：注释 `extend/anne_db.smx`
  - `cfg/sharedplugins.cfg`：注释 `extend/updater|savechat|rpg.smx`
  - `cfg/cfgogl/*/{confogl_plugins,shared_plugins}.cfg`：13 行 DB 插件加载注释
  - `cfg/cfgogl/*/shared_settings.cfg`：9 处 `join_autoupdate 1 → 0`
  - `addons/sourcemod/configs/core.cfg`：崩溃上报 URL 清空、`DisableAutoUpdate yes`
  - `cfg/sourcemod/network_quality_hint.cfg`：上报关闭、URL 清空
- 覆盖文件：`l4d2_dirspawn.smx` 1.6.3（+ 源码），修 `OnMapEnd` 定时器句柄
- 覆盖文件补充：`plugins/optional/AnneHappy/l4d2_dirspawn.smx` 同步为 1.6.3，`build.sh` 增加"根副本与 optional 副本 sha 一致"断言
- 仓库文档：新增 `AGENTS.md`（维护规则），README 增加链接
- 删除：MySQL 驱动、`anne_db`、`rpg`、`savechat`、`updater`、`l4d_random_beam_item`
