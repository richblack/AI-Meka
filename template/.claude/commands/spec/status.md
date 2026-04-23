---
description: 列出所有 SDD 的目前進度，幫使用者快速掌握全局
---

# /spec:status — 列出所有 spec 進度

## 你的任務

掃描 `.agents/specs/` 下所有 SDD 資料夾，列出每個的狀態。

### Step 1：掃目錄

```bash
ls -d .agents/specs/*/
```

### Step 2：逐個讀狀態

對每個 SDD 目錄：

1. 讀 `requirements.md` 的 header，抓「狀態」欄位
2. 讀 `design.md` 的 header，抓「狀態」欄位
3. 讀 `tasks.md`，統計：
   - `[ ]` 數量（未開始）
   - `[🔄]` 數量（進行中）
   - `[x]` 數量（完成）
   - `[❌]` 數量（失敗）
   - `[⏸️]` 數量（暫停）

### Step 3：輸出表格

```markdown
# SDD Status

更新時間：<今天日期>

## 活躍 SDD（有未完成 task）

| Feature | Req | Design | Tasks 進度 | 當前 task |
|---------|-----|--------|-----------|----------|
| user-login | ✅ | ✅ | 3/8 (37%) | [🔄] 1.4 實作 JWT middleware |
| oauth-flow | ✅ | 🔄 | - | 等 /spec:approve-design |
| dashboard | 🔄 | - | - | 需求討論中 |

## 已完成 SDD（全 [x]）

| Feature | 完成時間 |
|---------|---------|
| landing-page | 2026-03-15 |
| cli-init | 2026-04-01 |

## 停滯 SDD（超過 7 天無更新）

| Feature | 最後更新 | 建議 |
|---------|---------|------|
| legacy-migration | 2026-03-01 | 確認是否還要做，或刪除 |

## 健康度警示

- ⚠️ `user-login` 有 [🔄] 超過 3 天未完成 → 建議追一下
- ⚠️ `oauth-flow` 的 design.md 修改時間 > tasks.md 的修改時間 → 可能需要重新 approve-design
- ✅ 其他 spec 狀態健康
```

### Step 4：給使用者建議

在表格下方加：

```
💡 建議下一步：
- 優先完成 user-login task 1.4（卡住最久）
- oauth-flow 需要批准 design
- 決定 legacy-migration 是否繼續
```

## 禁止行為

- ❌ 只列 spec 名稱不列狀態細節
- ❌ 漏掉任何子目錄
- ❌ 表格內容是猜的（必須真的讀檔）
