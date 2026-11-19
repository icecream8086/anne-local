# profile: wan（广域网）

当前**只有 base**（`base/patches` + `base/overlay`），没有额外补丁。

广域网部署通常需要与 LAN 相反的东西，后续按需在这里加：

| 项 | LAN（`profiles/lan`） | WAN（本目录，待定义） |
|---|---|---|
| `sv_lan` | `1` | `0`（或不设置） |
| `sv_downloadurl` | 注释（无 FastDL） | 指向自己的 FastDL |
| `sv_allowdownload` | `1`（本服直连） | 由 FastDL 策略决定 |
| `join_autoupdate` | `0` | 按需（`0` 更可控） |
| MySQL / DB 插件 | 移除 | 需保留（`dbi.mysql` + `anne_db/rpg/savechat` 等） |
| 崩溃上报 / nqh 上报 | 关闭 | 按需 |
| MOTD / 新人指导 | 保留公网页 | 换成自己的 |

> 不要把 `profiles/lan` 的离线删除清单套到 WAN：`profiles/lan/remove.txt` 删了 MySQL 驱动与 DB 插件。

新增 WAN 配置时，在本目录放 `patches/`、`overlay/`、`remove.txt` 即可，`build.sh` 会自动叠加。
