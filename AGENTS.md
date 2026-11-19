# AGENTS.md —— anne-local 维护须知

> 本仓是 **L4D2 Anne 服务端的本地构建仓**：固定上游 release + base/profile 叠加，构建出可部署的游戏树 overlay。
> 不是 fork：**不维护上游分支、不做 `git merge upstream`**；升级 = 改 `VERSIONS.lock` 一行 + 重放补丁。
> 回复语言：中文。

## 1. 目录职责

| 路径 | 作用 | 允许改 |
|---|---|---|
| `VERSIONS.lock` | 上游 repo/tag/asset/sha256 | ✅ 升级时只改这里 |
| `base/` | 与部署无关的修复（rcon 禁用、dirspawn 1.6.3） | ✅ 只放"所有部署都要"的改动 |
| `profiles/<name>/` | 按环境叠加：`patches/`、`overlay/`、`remove.txt` | ✅ 新增 profile 或改现有 |
| `patches/.patch` | 对上游 cfg/configs 的 unified diff（`-p1`，相对 `left4dead2/`） | ✅ 配置唯一改法 |
| `overlay/files/` | 整文件覆盖，结构镜像 `left4dead2/`（二进制/内容文件） | ✅ |
| `remove.txt` | 上游有、我们不要的文件（相对 `left4dead2/`） | ✅ |
| `overrides.txt` | 多包合并时的同名覆盖登记 | ✅ 预留 |
| `build.sh` | 下载→解包→base→profile→覆盖→删除→断言→打包 | ⚠️ 改动需同步 README/本文件 |
| `tools/make-patches.sh` | 从现有游戏树重生成补丁 | ✅ |
| `.github/workflows/build.yml` | 手动构建 + artifact（可选 draft release） | ✅ |
| `.cache/ build/ dist/` | 构建中间物 | ❌ 不提交（.gitignore） |

## 2. 构建与验证

```bash
# 只有 base
VERSION=v2026.11.20 bash build.sh
# 局域网离线
PROFILE=lan VERSION=v2026.11.20 bash build.sh
```

Windows（Git Bash）：

```powershell
& 'C:\Program Files\Git\bin\bash.exe' -lc 'cd /c/.../anne-local && PROFILE=lan VERSION=v2026.11.20 bash build.sh'
```

- 版本号格式：`vYYYY.MM.DD` 或 `vYYYY.MM.DD-rN`，不符合 `build.sh` 直接 exit 2。
- 产物：`dist/L4D2-Anne-linux-[<profile>-]<version>.tar.gz` + `.sha256` + `.json`（仅 Linux，剔除 `.dll`/`.exe`）。
- **断言必须全过**才能交付：
  - base：`rcon_password ""`、dirspawn 根/optional 副本 sha 一致；
  - lan：9 个模式 `join_autoupdate=0`、`anne_db`/`rpg`/`savechat`/`updater` 未加载、崩溃上报 URL 为空、MySQL 驱动不存在。
- 产物解包后应与线上树对比：`cfg/server.cfg`（同 profile）逐字节一致、自动加载插件数 147（lan）、dirspawn sha 以 `800d776d` 开头。
- 改动配置后，至少在一台测试服覆盖验证再上生产。

## 3. 修改纪律（重要）

1. **部署差异进 `profiles/`，不进 `base/`**：`sv_lan`、FastDL、`sv_allowdownload`、`join_autoupdate`、MySQL、上报、MOTD、广告都属于 profile。
2. **`base/` 只放所有部署都成立的修复**：rcon 禁用、dirspawn bugfix 这类。
3. **默认构建（`PROFILE=none`）不套任何部署配置**，避免把某台机器的配置提交成"默认"。
4. **只改源码树里的配置用 `patches/`**，不改 `build/`（每次重建清空）。
5. **补丁必须 LF + `-p1`**；`build.sh` 用 `patch -p1 -d build/left4dead2`，无 `patch` 时回退 `git apply`。
6. **cfg 注释只写 ASCII**（引擎会把非 ASCII 注释当命令执行）。
7. **整文件覆盖仅限二进制/内容文件**（插件 smx、广告 txt）；配置一律用补丁。
8. **上游升级后重放/重生成补丁**：`bash tools/make-patches.sh <live/left4dead2>`；改名/移动文件会让 `remove.txt` 静默失效，靠断言和日志发现。
9. **不要把上游整包、`.cache`、`dist` 提交进仓**；仓库只放 diff + 覆盖文件，保持 < 1 MB。
10. **不提交凭据/token/密钥**；公开仓前 `git grep -iE 'token|password|secret'`。
11. 文本一律 LF（`.gitattributes` 已强制）；Windows 上不要用 `core.autocrlf=true` 直接提交脚本。

## 4. 发布

- GitHub Actions → **Build Linux package** → Run workflow：
  - `profile`：`lan` / `wan` / `none`
  - `version`：`vYYYY.MM.DD`
  - `publish=true` 才创建 **draft** release；默认只上传 artifact。
- draft 不会自动打 tag，需在 Releases 页面点 Publish。

## 5. 后期多包合并（预留）

新增来源时：`vendor/<pkg>/`（建议 `git subtree`）+ `VERSIONS.lock` 增一行来源 +
`build.sh` 组合顺序（vendor 先、base 后、profile 最后）；同名文件必须在 `overrides.txt` 登记。
