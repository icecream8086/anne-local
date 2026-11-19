# anne-local

L4D2 Anne 服务端的**构建仓**：固定上游 release，只加一个必须的修复——**清空上游公开的 rcon 默认密码**。

- 上游：`fantasylidong/CompetitiveWithAnne`（Anne 包，已含 SirPlease 上游）
- 基线：`VERSIONS.lock` 锁定的 release tag + sha256
- 产物：`dist/L4D2-Anne-linux-<version>.tar.gz`（根目录即 `left4dead2/`，drop-in 覆盖）

## 结构

```text
VERSIONS.lock           # 上游 tag / 资产名 / sha256
base/                   # 所有部署都成立的修复
└── patches/            #   rcon_password ""（上游默认密码是公开字符串）
build.sh                # 拉包 → base 补丁 → 打包（仅 Linux）
tools/make-patches.sh   # 从现有游戏树重生成补丁
.github/workflows/build.yml
```

> **部署配置不进仓**：`sv_lan`、FastDL、`join_autoupdate`、MySQL、MOTD、广告、dirspawn 修复等
> 都属于"看情况"的本地配置，放在 `profiles/<name>/`（已 gitignore，不上传），需要时本地叠加即可。

## 用法

```bash
VERSION=v2026.11.20 bash build.sh     # 默认只出 base（rcon 已清空）
PROFILE=lan VERSION=v2026.11.20 bash build.sh   # 本地有 profiles/lan 时才会叠加
```

要求：`bash`、`curl`、`tar`、`patch`、`sha256sum`（没有 `patch` 时回退 `git apply`）。

Windows 上用 Git Bash：

```powershell
& 'C:\Program Files\Git\bin\bash.exe' -lc 'cd /c/path/to/anne-local && VERSION=v2026.11.20 bash build.sh'
```

> WSL 访问 GitHub release 资产会超时；本地构建请在 Windows 或 CI 里跑。

## 命名标准

| 项 | 规则 | 示例 |
|---|---|---|
| 版本号 | `vYYYY.MM.DD`，同日再构建用 `-rN` | `v2026.11.20` |
| 产物 | `L4D2-Anne-linux-[<profile>-]<version>.tar.gz`（**仅 Linux**，剔除 `.dll`/`.exe`） | `L4D2-Anne-linux-v2026.11.20.tar.gz` |
| 校验 | 同名 `.sha256` | — |
| 元数据 | 同名 `.json`：版本/profile/构建时间/git commit/上游 tag+sha/插件数 | — |
| Release tag | 与版本号一致 | `v2026.11.20` |
| CI artifact | 与产物同名（去扩展名） | `L4D2-Anne-linux-v2026.11.20` |

`build.sh` 会校验版本号格式，不合法直接 exit 2。

## base 里有什么

只有一条补丁：`rcon_password "WowYouKnowThePasswordHere"` → `rcon_password ""`。

上游把默认密码写死在公开仓库里，任何部署都不该保留；清空即关闭远程 rcon（需要时在部署侧运行时设置）。

其余一切（离线化、MySQL、FastDL、MOTD、广告、dirspawn）都不属于本仓默认产物。

## 升级上游

1. 改 `VERSIONS.lock` 的 `UPSTREAM_TAG` / `UPSTREAM_ASSET` / `UPSTREAM_ASSET_SHA256`；
2. `bash build.sh`；
3. 断言通过后，拿 `dist/` 包在测试服验一遍再上生产；
4. 提交 `VERSIONS.lock` 与新 `patches/`。

## 本地部署配置（不上传）

`profiles/` 已被 `.gitignore` 忽略。需要离线/局域网配置时，本地建 `profiles/<name>/`：

```text
profiles/lan/
├── patches/      # 对上游 cfg 的补丁（如 sv_lan、FastDL 注释、join_autoupdate）
├── overlay/files/# 整文件覆盖（如 l4d2_dirspawn 1.6.3、广告 txt）
└── remove.txt    # 要删的文件（如 MySQL 驱动、DB 插件）
```

`PROFILE=<name> bash build.sh` 会自动按 base → profile 的顺序叠加。
