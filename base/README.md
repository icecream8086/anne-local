# base —— 与部署环境无关的修复

这里的改动对任何部署（LAN / WAN / 离线 / 在线）都成立，所以不进 `profiles/`。

| 路径 | 内容 | 原因 |
|---|---|---|
| `patches/cfg__server.cfg.patch` | `rcon_password` 清空 | 上游默认密码 `WowYouKnowThePasswordHere` 是公开字符串，绝不能带到线上 |
| `overlay/files/.../l4d2_dirspawn.smx` | `l4d2_dirspawn` 1.6.3 | 上游包源码已是 1.6.3，但 `optional/*.smx` 仍是 1.6.2；1.6.2 在 `OnMapEnd` 只清 1 个定时器句柄，换图后报 `Invalid timer handle` |
| `overlay/files/.../l4d2_dirspawn.sp` | 同上源码 | 与 smx 保持一致，便于重编译/审计 |

`build.sh` 对 base 的断言：

- `rcon_password ""` 存在；
- 根目录与 `optional/AnneHappy/` 的 `l4d2_dirspawn.smx` sha 一致。

> 注意：base **不**修改 `sv_lan`、FastDL、`join_autoupdate`、MOTD、MySQL；这些属于 `profiles/`。
