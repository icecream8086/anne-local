# base —— 所有部署都成立的修复

只放"任何环境都该有"的改动；部署差异请放本地 `profiles/`（gitignored）。

| 路径 | 内容 | 原因 |
|---|---|---|
| `patches/cfg__server.cfg.patch` | `rcon_password` 清空 | 上游默认密码 `WowYouKnowThePasswordHere` 是公开字符串，绝不能带到线上；清空即关闭远程 rcon |

`build.sh` 对 base 的断言：`rcon_password ""` 存在。

> dirspawn 1.6.3、`sv_lan`、FastDL、MySQL、MOTD、广告等都不在 base：
> dirspawn 属于可选修复，其余属于部署 profile，放本地 `profiles/<name>/`。
