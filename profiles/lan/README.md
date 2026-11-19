# profile: lan（局域网 / 离线）

在 base 之上叠加的局域网离线配置：

| 文件 | 改动 |
|---|---|
| `patches/cfg__server.cfg.patch` | 注释 `sv_downloadurl`；`sv_allowdownload 1`；末尾离线块：`sv_lan 1`、`join_autoupdate 0`、MOTD/新人指导保留、`sm_cfgip_url`/`sm_donate_url` 清空 |
| `patches/addons__sourcemod__configs__core.cfg.patch` | 崩溃上报 URL 清空、`DisableAutoUpdate yes` |
| `patches/cfg__sourcemod__network_quality_hint.cfg.patch` | 网络质量上报关闭 |
| `patches/cfg__generalfixes.cfg.patch` | 注释 `anne_db` 加载 |
| `patches/cfg__sharedplugins.cfg.patch` | 注释 `updater/savechat/rpg` 加载（**advertisements 未动**） |
| `patches/cfg__cfgogl/*/confogl_plugins.cfg`、`shared_plugins.cfg` | 注释 13 处 DB 插件加载 |
| `patches/cfg__cfgogl/*/shared_settings.cfg` | 9 处 `join_autoupdate 1 → 0` |
| `remove.txt` | MySQL 驱动 `.so/.dll`、`anne_db/rpg/savechat/updater/l4d_random_beam_item` |

> `rcon_password ""` 与 `l4d2_dirspawn` 1.6.3 属于 base（任何部署都该有），不在本 profile。
> 广告文本（`configs/advertisements*.txt`）目前未改，替换时放本 profile 的 `overlay/`。
