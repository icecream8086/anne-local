# AGENTS.md —— anne-local 维护须知

> 本仓是 **L4D2 Anne 服务端的本地构建仓**：固定上游 release + 我们的补丁/覆盖/删除清单，构建出可部署的游戏树 overlay。
> 不是 fork：**不维护上游分支、不做 `git merge upstream`**；升级 = 改 `VERSIONS.lock` 一行 + 重放补丁。
> 回复语言：中文。

## 1. 目录职责

| 路径 | 作用 | 允许改 |
|---|---|---|
| `VERSIONS.lock` | 上游 repo/tag/asset/sha256 | ✅ 升级时只改这里 |
| `patches/*.patch` | 对上游 **cfg/configs** 的 unified diff（`-p1`，相对 `left4dead2/`） | ✅ 唯一改配置的方式 |
| `overlay/files/` | 整文件覆盖，目录结构镜像 `left4dead2/`（二进制/自研插件） | ✅ 新增/替换文件 |
| `remove.txt` | 上游有、我们不要的文件（相对 `left4dead2/`） | ✅ 增删 |
| `overrides.txt` | 将来多包合并时的同名覆盖登记 | ✅ 预留 |
| `build.sh` | 下载→解包→补丁→覆盖→删除→断言→打包 | ⚠️ 改动需同步 README/本文件 |
| `tools/make-patches.sh` | 从现有游戏树重生成补丁 | ✅ |
| `.github/workflows/build.yml` | 手动构建 + artifact（可选 draft release） | ✅ |
| `.cache/ build/ dist/` | 构建中间物 | ❌ 不提交（.gitignore） |

## 2. 构建与验证

```bash
# Windows（Git Bash）——本机 WSL 访问 GitHub release 资产会超时
& 'C:\Program Files\Git\bin\bash.exe' -lc 'cd /c/.../anne-local && VERSION=v2026.11.20 bash build.sh'
# Linux / CI
VERSION=v2026.11.20 bash build.sh
```

- 版本号格式：`vYYYY.MM.DD` 或 `vYYYY.MM.DD-rN`，不符合 `build.sh` 直接 exit 2。
- 产物：`dist/L4D2-Anne-linux-<version>.tar.gz` + `.sha256` + `.json`（仅 Linux，剔除 `.dll`/`.exe`）。
- **断言必须全过**才能交付：dirspawn 存在且根/optional 副本 sha 一致、9 个模式 `join_autoupdate=0`、`anne_db`/`rpg`/`savechat`/`updater` 未加载、崩溃上报 URL 为空、MySQL 驱动不存在。
- 产物 `dist/L4D2-Anne-linux-<VERSION>.tar.gz` 解包后应与线上树对比：`cfg/server.cfg` 逐字节一致、自动加载插件数 147、`l4d2_dirspawn.smx` sha 以 `800d776d` 开头。
- 改动配置后，至少在一台测试服覆盖验证再上生产。

## 3. 修改纪律（重要）

1. **只改 `patches/`，不改 `build/`**：`build/` 是临时解包目录，每次重建都会清空。
2. **补丁必须 LF + `-p1`**：标签是 `a/<相对 left4dead2 的路径>`；`build.sh` 用 `patch -p1 -d build/left4dead2`，缺失 `patch` 时回退 `git apply`。
3. **cfg 注释只写 ASCII**：Source 引擎会把非 ASCII 注释当命令执行（历史坑）。
4. **整文件覆盖仅限二进制/自研插件**：配置一律用补丁，避免"上游改了同一文件但被整文件盖掉、且不报冲突"。
5. **上游升级后必须重放/重生成补丁**：`bash tools/make-patches.sh <live/left4dead2>`；若上游改名/移动文件（如 `savechat`→`chatlog`），`remove.txt` 会静默失效——靠断言和构建日志发现。
6. **不要把上游整包或 `.cache` 提交进仓**：仓库只放 diff + 覆盖文件，体积应保持在 < 1 MB。
7. **不提交任何凭据/token/密钥**；公开仓前检查 `git grep -iE 'token|password|secret'`。
8. 文本一律 LF（`.gitattributes` 已强制）；Windows 上不要开 `core.autocrlf=true` 直接提交脚本。

## 4. 发布

- GitHub Actions → **Build Linux package** → Run workflow：
  - `version`（必填，格式 `vYYYY.MM.DD`）
  - `publish=true` 才会创建 **draft** release；default 只上传 artifact。
- draft 不会自动打 tag，需在 Releases 页面点 Publish。

## 5. 后期多包合并（预留）

新增来源时：`vendor/<pkg>/`（建议 `git subtree`）+ `VERSIONS.lock` 增一行来源 +
`build.sh` 组合顺序（vendor 先、overlay 后）；同名文件必须在 `overrides.txt` 登记，否则视为错误。
