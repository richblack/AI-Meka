---
description: 批准當前 spec 的 design.md，進入 tasks 階段
argument-hint: [feature-name，可省略]
---

# /spec:approve-design — 批准 design，產 tasks.md

## 你的任務

1. **確認批准範圍**：
   - 若 `$ARGUMENTS` 有值 → 對應 `.agents/specs/$ARGUMENTS/`
   - 若為空 → 從 git status 找最近修改的 design.md，或問使用者

2. **更新 design.md header**：
   ```
   > 狀態：✅ 已批准（YYYY-MM-DD）
   ```

3. **讀 requirements.md + design.md + 01-tech-stack.md + 03-architecture.md**

4. **建立 tasks.md**，把 design 拆成可執行步驟

## tasks.md 模板

```markdown
# Tasks: <feature-name>

> 狀態：🔄 待批准（等待使用者 review 後 /task:run 執行）
> 基於：design.md（已批准於 YYYY-MM-DD）
> 權威進度來源。每完成一個 task 立刻更新標記，不批次。

## 標記約定
- `[ ]` 未開始
- `[🔄]` 正在執行
- `[x]` 已完成且**測試通過**（見 .claude/rules/06-tdd-protocol.md）
- `[❌]` 失敗（需註記原因）
- `[⏸️]` 暫停（等依賴）

## Phase 1: <階段名>

- [ ] 1.1 <具體動作，名詞動詞明確>
  - Test File: `tests/<path>/xxx.test.ts`  ← 強制欄位，見 06-tdd-protocol.md
  - 驗收：<由 Test File 可驗證的條件>
  - 影響檔案：<會動到哪些檔案，含 Test File 本身>
  - 依賴：<無 / 或 前置 task 編號>

- [ ] 1.2 <...>
  - Test File: `tests/<path>/yyy.test.ts`
  - 驗收：<...>
  - 影響檔案：<...>
  - 依賴：1.1

## Phase 2: <...>

- [ ] 2.1 <...>
  - Test File: ...

## Phase N: 驗證 / 交付

- [ ] N.1 全 suite 測試
  - Test File: 全部
  - 驗收：所有測試 pass，coverage 達標
- [ ] N.2 更新相關文件（README / CHANGELOG）
  - Test File: —（純文件，由 downstream task 間接覆蓋）
- [ ] N.3 commit + PR
  - Test File: —（CI 會跑完整測試）
```

## Task 拆解原則（重要）

- **每個 task 必須可獨立執行**（至多依賴前一個 task）
- **每個 task 必須有 Test File 欄位**（值為具體測試檔路徑，或 `—` 並註明為什麼免測試）
- **每個 task 必須有明確驗收標準**（能由 Test File 檢驗）
- **每個 task 工作量 < 2 小時**（太大要拆）
- **最後一個 Phase 一定是驗證/交付**（全 suite 測試 + commit）

### Test File 欄位的值

| 值 | 何時用 |
|----|-------|
| 具體路徑 `tests/xxx.test.ts` | 絕大多數 task（實作 / 修 bug / 加功能） |
| 多個路徑以逗號分隔 | 一個 task 橫跨多個測試檔時 |
| `—`（em-dash） | 只有純配置、純文件、commit/PR 類 task 可用，且必須在 task 內註明理由 |

一個 Phase 內 `—` 的 task 超過 30%，代表粒度切錯了：通常是把「寫實作」和「寫測試」拆成兩個 task。合併回去。

## 完成後提示

```
🎯 tasks.md 初稿完成：
.agents/specs/<feature>/tasks.md
共 <N> 個 task，分 <M> 個 Phase。

請 review task 拆解是否合理。
執行方式：
  /task:run 1.1         ← 逐個執行（保守）
  /task:run-all         ← 一次批准全部（快但需要信任 tasks.md 品質）
  /task:next            ← 執行下一個未完成 task
```

## 禁止行為

- ❌ 沒讀 design.md 就寫 tasks
- ❌ task 拆得太粗（一個 task 橫跨多個檔案/模組）
- ❌ 驗收標準寫「做好了」
- ❌ 直接開始執行（必須等使用者審 tasks.md）
