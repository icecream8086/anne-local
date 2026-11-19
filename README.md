# anne-local

L4D2 Anne 服务端的**本地化构建仓**（方案 C：固定上游版本 + overlay，不维护 fork）。
维护规则见 [AGENTS.md](AGENTS.md)；变更记录见 [CHANGELOG.md](CHANGELOG.md)。

- 上游：`fantasylidong/CompetitiveWithAnne`（Anne 包，已含 SirPlease 上游）
- 基线：`VERSIONS.lock` 里锁定的 release tag + sha256
- 产物：`dist/anne-local-<VERSION>.tar.gz`，根目录即 `left4dead2/`，可直接覆盖游戏树

## 目录

```
VERSIONS.lock           # 上游 tag / 资产名 / sha256（升级只改这里）
build.sh                # 拉包 → 打补丁 → 覆盖文件 → 删文件 → 断言 → 打包
patches/*.patch         # 我们对上游 cfg 的差异（unified diff，-p1）
overlay/files/          # 整文件覆盖（二进制/自研插件，目前只有 dirspawn 1.6.3）
remove.txt              # 要删除的上游文件（MySQL 驱动、DB 插件…）
overrides.txt           # 预留：多包合并时的同名覆盖登记
tools/make-patches.sh   # 从"当前游戏树"重新生成 patches/（升级后重放用）
.github/workflows/build.yml
```

## 用法

```bash
bash build.sh                    # 版本号默认 日期-时间
VERSION=v1.0.0 bash build.sh     # 指定版本号
ls dist/
```

要求：`bash`、`curl`、`tar`、`patch`、`sha256sum`（没有 `patch` 时自动回退到 `git apply`）。

### Windows 上运行（Git Bash）

Git for Windows 自带 bash 5.2 / curl / tar / patch / sha256sum / git，可直接跑：

```powershell
& 'C:\Program Files\Git\bin\bash.exe' -lc 'cd /c/path/to/anne-local && VERSION=v1.0.0 bash build.sh'
```

实测（2026-11-20）：Windows 上从 GitHub 拉 release 资产 77.7 MB / 13 s（sha256 校验通过），27 个补丁、6 条断言、产 75 MB 包；注意 **WSL 访问 release 资产会超时**，本地构建请在 Windows 或 CI 里跑。

## 升级上游（例如 10-25 → 11-15）

1. 改 `VERSIONS.lock` 的 `UPSTREAM_TAG` / `UPSTREAM_ASSET` / `UPSTREAM_ASSET_SHA256`；
2. `bash build.sh`——补丁若因上游上下文变化失败，会停在对应 patch；
3. 用 `tools/make-patches.sh` 对**新基线**重新生成补丁（或手工修 patch）；
4. 断言全过后，拿 `dist/` 包在一台测试服上验一遍再上生产；
5. 提交 `VERSIONS.lock` + 新 `patches/`。

## 我们改了什么

| 类别 | 内容 |
|---|---|
| cfg | `server.cfg` 离线块（无 FastDL/rcon、join_autoupdate 0、MOTD/新人指导保留）；`generalfixes.cfg` 关 `anne_db`；`sharedplugins.cfg` 关 `updater/savechat/rpg`；13 个模式 cfg 关 DB 插件加载；9 个 `shared_settings.cfg` 把 `join_autoupdate` 改 0 |
| configs | `core.cfg`：崩溃上报清空、`DisableAutoUpdate yes`；`network_quality_hint.cfg`：关上报 |
| 插件 | `l4d2_dirspawn.smx` 1.6.3（`OnMapEnd` 清 4 个定时器句柄，修 `Invalid timer handle`） |
| 删除 | MySQL 驱动（`.so/.dll`）、`anne_db`、`rpg`、`savechat`、`updater`、`l4d_random_beam_item` |

> 启动参数 `+sv_lan 1` **不在本仓**：属于部署侧（Pod/game profile）的 argv。

## 后期并包

新增一个包时建议：

```text
vendor/<pkg>/        # 用 git subtree 拉进来，独立更新
overlay/files/       # 覆盖顺序：vendor 先，overlay 后
overrides.txt        # 同名文件登记；未登记的同名冲突让 build.sh 报错
```

`build.sh` 目前只处理"上游 + overlay"；引入第二个包时按上表扩展组合顺序，并在 `VERSIONS.lock` 里为每个包各记一行来源。
