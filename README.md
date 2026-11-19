# anne-local

L4D2 Anne 服务端的**本地化构建仓**（固定上游版本 + base/profile 叠加，不维护 fork）。
维护规则见 [AGENTS.md](AGENTS.md)；变更记录见 [CHANGELOG.md](CHANGELOG.md)。

## 结构

```text
VERSIONS.lock            # 上游 repo/tag/asset/sha256（升级只改这里）
base/                    # 与部署环境无关的修复
├── patches/             #   rcon 禁用（上游默认密码是公开的）
└── overlay/files/       #   l4d2_dirspawn 1.6.3（+ 源码）
profiles/
├── lan/                 # 局域网/离线：关 FastDL/更新/上报/MySQL
└── wan/                 # 广域网：目前只有 base，后续按需加
build.sh                 # 下载→解包→base→profile→覆盖→删除→断言→打包
tools/make-patches.sh    # 从现有游戏树重生成补丁
.github/workflows/build.yml
```

**默认构建不含任何部署配置**（`PROFILE=none`）：只有 base 的安全/修复项。LAN 与 WAN 的差异全部在 `profiles/` 里，不写进 base。

## 用法

```bash
# 只出 base（默认，不套任何部署配置）
VERSION=v2026.11.20 bash build.sh

# 局域网离线配置
PROFILE=lan VERSION=v2026.11.20 bash build.sh

# 广域网（当前等于 base）
PROFILE=wan VERSION=v2026.11.20 bash build.sh

ls dist/
```

要求：`bash`、`curl`、`tar`、`patch`、`sha256sum`（没有 `patch` 时回退 `git apply`）。

Windows 上用 Git Bash：

```powershell
& 'C:\Program Files\Git\bin\bash.exe' -lc 'cd /c/path/to/anne-local && PROFILE=lan VERSION=v2026.11.20 bash build.sh'
```

> WSL 访问 GitHub release 资产会超时；本地构建请在 Windows 或 CI 里跑。

## 命名与产物标准

| 项 | 规则 | 示例 |
|---|---|---|
| 版本号 | `vYYYY.MM.DD`，同日再构建用 `-rN` | `v2026.11.20` |
| 产物 | `L4D2-Anne-linux-[<profile>-]<version>.tar.gz`（**仅 Linux**，剔除 `.dll`/`.exe`） | `L4D2-Anne-linux-lan-v2026.11.20.tar.gz` |
| 校验 | 同名 `.sha256` | — |
| 元数据 | 同名 `.json`：版本/profile/构建时间/git commit/上游 tag+sha/插件数 | — |
| Release tag | 与版本号一致，资产含 tar.gz/sha256/json | `v2026.11.20` |
| CI artifact | 与产物同名（去扩展名） | `L4D2-Anne-linux-lan-v2026.11.20` |
| 包内结构 | 根目录即 `left4dead2/`（drop-in 覆盖） | — |

`build.sh` 会校验版本号与 profile 是否存在，不合法直接 exit 2。

## base 与 profile 的边界

| 内容 | 放哪 | 原因 |
|---|---|---|
| `rcon_password ""` | `base/` | 上游默认密码是公开字符串，任何部署都不该留 |
| `l4d2_dirspawn` 1.6.3 | `base/` | 定时器句柄 bug，与网络环境无关 |
| `sv_lan`、FastDL、`sv_allowdownload`、`join_autoupdate` | `profiles/lan` | LAN/WAN 取值相反 |
| MySQL 驱动/DB 插件移除 | `profiles/lan` | WAN 可能需要数据库 |
| 崩溃上报 / nqh / MOTD URL | `profiles/*/patches` | 各部署不同 |
| 广告文本（`advertisements*.txt`） | `profiles/*/overlay/` | 内容类整文件覆盖 |

> 如果某个改动"所有部署都要"且与网络无关，才放 `base/`；否则一律进 profile。

## 升级上游

1. 改 `VERSIONS.lock` 的 `UPSTREAM_TAG` / `UPSTREAM_ASSET` / `UPSTREAM_ASSET_SHA256`；
2. `PROFILE=lan bash build.sh`——补丁因上下文变化失败会停在对应 patch；
3. 用 `tools/make-patches.sh` 对新基线重生成补丁（或手工修）；
4. 断言全过 + 测试服覆盖验证后再上生产；
5. 提交 `VERSIONS.lock` 与新 `patches/`。

## 后期多包合并

新增来源时：`vendor/<pkg>/`（建议 `git subtree`）+ `VERSIONS.lock` 增一行来源 +
`build.sh` 组合顺序（vendor 先、base 后、profile 最后）；同名文件必须在 `overrides.txt` 登记。
