# 當前進度

> SessionStart hook 會把此檔摘要注入 agent context，讓 agent 一開 session 就知道現在做到哪。
> **每完成一個里程碑立刻更新此檔**，不要依賴對話記憶。

---

## 專案狀態

- **目前 Phase**：<例：Phase 1 - 核心模組開發>
- **封測狀態**：<例：未啟用，原因：等 Phase 1 完成>
- **上次更新**：<YYYY-MM-DD>

---

## 活躍 SDD

> 列出**正在推進**的 SDD。已完成或尚未啟動的放 SDD 索引。

### SDD: `.agents/specs/<feature-name>/`

- **Requirements 狀態**：✅ 已批准 / 🔄 討論中 / ⬜ 未開始
- **Design 狀態**：✅ / 🔄 / ⬜
- **Tasks 狀態**：✅ / 🔄 / ⬜
- **當前 task**：<task 編號 + 簡述>
- **阻擋項**：<有什麼卡住>

---

## Phase 完成度摘要

| Phase | 內容 | 狀態 |
|-------|------|------|
| <例：Phase 0> | <基礎建置> | ✅ 完成 |
| <例：Phase 1> | <核心模組> | ⬜ 未開始 |
| <例：Phase 2> | <整合模組> | ⬜ 未開始 |

---

## 下個 session 第一件要做的事

<寫一句話，例如：>
1. 讀 `.agents/specs/<feature>/tasks.md`
2. 從 task X.Y 開始

---

## SDD 索引（全量）

| 子系統 | SDD 路徑 | 狀態 |
|-------|---------|------|
| <例：核心模組> | `.agents/specs/core-module/` | 進行中 |
| <例：首頁> | `.agents/specs/landing-page/` | 完成 |
| <例：技術栈詳細> | `.agents/steerings/tech.md` | 持續更新 |

---

## 最近的重大決策 / 變更記錄

> 重大架構決策變更時在此記錄，配合 git log 能重建脈絡。

- **YYYY-MM-DD**：<決策 / 變更>，理由：<...>

---

## 給 agent 的技術備註（常搞錯的事）

<把 agent 反覆搞錯的事寫這裡，越具體越好。範例>

1. <例：每個模組是獨立 service，不從儲存動態讀>
2. <例：internal routing binding = YAML URL 清單，不是平台 binding>
3. <例：orchestration 只 routing，業務邏輯在後端模組>
