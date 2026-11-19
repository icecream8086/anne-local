# AGENTS.md —— anne-local 维护须知

> 本仓只做一件事：**固定上游 release，清空上游公开的 rcon 默认密码**，产出 Linux 包。
> 不是 fork：不维护上游分支、不做 `git merge upstream`；升级 = 改 `VERSIONS.lock` + 重生成补丁。
> 部署相关配置（LAN/WAN、MySQL、FastDL、MOTD、广告、dirspawn）**不进本仓**，放本地 `profiles/`（已 gitignore）。
> 回复语言：中文。

## 1. 目录职责

| 路径 | 作用 | 允许改 |
|---|---|---|
| `VERSIONS.lock` | 上游 repo/tag/asset/sha256 | ✅ 升级时只改这里 |
| `base/patches/` | 只放所有部署都成立的修复（当前只有 rcon 清空） | ✅ 谨慎新增 |
| `build.sh` | 下载→解包→base→打包（可选本地 profile） | ⚠️ 改动需同步 README/本文件 |
| `tools/make-patches.sh` | 从现有游戏树重生成补丁 | ✅ |
| `.github/workflows/build.yml` | 手动构建 + artifact（可选 draft release） | ✅ |
| `profiles/` | **本地部署配置，gitignored，不上传** | ✅ 本地 |
| `.cache/ build/ dist/` | 构建中间物 | ❌ 不提交（.gitignore） |

## 2. 构建与验证

```bash
VERSION=v2026.11.20 bash build.sh                 # base（默认）
PROFILE=lan VERSION=v2026.11.20 bash build.sh     # 本地有 profiles/lan 时才叠加
```

Windows（Git Bash）：

```powershell
& 'C:\Program Files\Git\bin\bash.exe' -lc 'cd /c/.../anne-local && VERSION=v2026.11.20 bash build.sh'
```

- 版本号：`vYYYY.MM.DD` / `vYYYY.MM.DD-rN`，不合法 exit 2。
- 产物：`dist/L4D2-Anne-linux-[<profile>-]<version>.tar.gz` + `.sha256` + `.json`（仅 Linux，剔除 `.dll`/`.exe`）。
- **断言必须过**：`rcon_password ""`；若 profile 带 dirspawn overlay，则根/optional 副本 sha 一致；`PROFILE=lan` 额外要求 9 个 `join_autoupdate=0`、DB 插件未加载、崩溃上报关闭、MySQL 驱动不存在。
- 部署前在测试服覆盖验证；包内 `cfg/server.cfg` 应与目标环境一致。

## 3. 修改纪律（重要）

1. **部署差异不进 `base/`，也不提交**：`sv_lan`、FastDL、`sv_allowdownload`、`join_autoupdate`、MySQL、上报、MOTD、广告、dirspawn 修复都属于本地 `profiles/`。
2. **`base/` 只放所有部署都成立的修复**：当前只有 rcon 清空；新增前先问"这真是所有环境都要吗"。
3. **默认构建不套任何部署配置**，避免把某台机器的配置写成仓库默认。
4. **不要 `git add profiles/`**：`.gitignore` 已忽略；提交前 `git status` 确认没有 profiles 文件。
5. **配置用 `patches/`**，不改 `build/`（每次重建清空）；补丁必须 LF + `-p1`。
6. **cfg 注释只写 ASCII**（引擎会把非 ASCII 注释当命令执行）。
7. **整文件覆盖仅限二进制/内容文件**（插件 smx、广告 txt）。
8. **上游升级后重放/重生成补丁**：`bash tools/make-patches.sh <live/left4dead2>`；改名/移动文件会让 `remove.txt` 静默失效。
9. **不提交上游整包、`.cache`、`dist`**；仓库保持 < 1 MB。
10. **不提交凭据/token/密钥**；公开前 `git grep -iE 'token|password|secret'`。
11. 文本一律 LF（`.gitattributes` 强制）。

## 4. 发布

- GitHub Actions → **Build Linux package** → Run workflow：
  - `version`：`vYYYY.MM.DD`
  - `publish=true` 才创建 **draft** release；默认只上传 artifact。
- draft 不会自动打 tag，需在 Releases 页面点 Publish。

## 5. 本地 profile 约定

`PROFILE=<name>` 时，`build.sh` 依次叠加：

```text
base/patches → profiles/<name>/patches → base/overlay → profiles/<name>/overlay → base/remove.txt + profiles/<name>/remove.txt
```

本地 profile 可以很复杂（离线化、dirspawn、广告），但它**不进入仓库**，也不参与 CI。
