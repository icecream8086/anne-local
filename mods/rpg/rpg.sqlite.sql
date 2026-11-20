-- RPG 表（SQLite 方言），对应《33-RPG存储改SQLite》
-- 执行方式：sqlite3 data/sqlite/rpg-local.sq3 < rpg.sqlite.sql
-- 或在 SourceMod 启动前手工建库；插件不再运行时改表。

CREATE TABLE IF NOT EXISTS RPG (
    steamid             TEXT    NOT NULL PRIMARY KEY,
    MELEE_DATA          INTEGER NOT NULL DEFAULT 0,
    BLOOD_DATA          INTEGER NOT NULL DEFAULT 0,
    HAT                 INTEGER NOT NULL DEFAULT 0,
    HAT_ENABLED         INTEGER DEFAULT NULL,
    HAT_VIEW_FIRST      INTEGER DEFAULT NULL,
    HAT_VIEW_THIRD      INTEGER DEFAULT NULL,
    HAT_SHOW_OTHERS     INTEGER DEFAULT NULL,
    GLOW                INTEGER NOT NULL DEFAULT 0,
    SKIN                INTEGER NOT NULL DEFAULT 0,
    RECOIL              INTEGER NOT NULL DEFAULT 0,
    ANNE_GUIDE_PROMPT   INTEGER NOT NULL DEFAULT 1,
    CHATTAG             TEXT    DEFAULT NULL,
    hitsound_cfg        INTEGER NOT NULL DEFAULT 0,
    hitsound_overlay    INTEGER NOT NULL DEFAULT 0,
    hitsound_head       INTEGER NOT NULL DEFAULT 0,
    hitsound_hit        INTEGER NOT NULL DEFAULT 0,
    hitsound_kill       INTEGER NOT NULL DEFAULT 0,
    hiticon_head        INTEGER NOT NULL DEFAULT 0,
    hiticon_hit         INTEGER NOT NULL DEFAULT 0,
    hiticon_kill        INTEGER NOT NULL DEFAULT 0,
    hitsound_si_only    INTEGER NOT NULL DEFAULT 0,
    hiticon_si_only     INTEGER NOT NULL DEFAULT 0,
    hitsound_stack_mode INTEGER DEFAULT NULL,
    hitsound_headkill   INTEGER DEFAULT NULL,
    hitsound_lethal_mode INTEGER DEFAULT NULL
);
