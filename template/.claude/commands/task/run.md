---
description: 執行單一 task（按 tasks.md 的編號）
argument-hint: <task-id，例如 1.3>
---

# /task:run — 執行單一 task

使用者要求執行 task `$ARGUMENTS`。

## 你的任務（按順序，不得跳過）

### Step 1：SDD 協議宣告

先在回覆開頭貼出宣告（格式見 `.claude/rules/00-sdd-protocol.md`）：

```
📋 已讀 SDD：
- .agents/specs/<feature>/requirements.md（狀態：✅ 已批准）
- .agents/specs/<feature>/design.md（狀態：✅ 已批准）
- .agents/specs/<feature>/tasks.md（狀態：✅ 已批准）

🎯 本次對應 task：$ARGUMENTS <task 標題>

📐 本次 task 的 SDD 規範摘要：
- <重點 1>
- <重點 2>
- <重點 3>

🚧 執行範圍：
- 會修改：<檔案清單>
- 會建立：<檔案清單>
- 會刪除：<檔案清單>
- 預估影響：<影響哪些下游>
```

### Step 2：驗證前置條件

檢查：
- 三個 SDD 檔案都 `✅ 已批准` 了嗎？
- Task `$ARGUMENTS` 的**依賴 task** 是否都 `[x]`？
- 若依賴未完成 → 停手，告訴使用者，問是否先做依賴

### Step 3：標記為進行中

把 `tasks.md` 裡 `$ARGUMENTS` 的 `[ ]` 改成 `[🔄]`。**立刻做**，這樣使用者看檔案就知道你在做什麼。

### Step 4：執行 task

按 task 的「影響檔案」和「驗收」欄位執行。
**嚴格限定在這一個 task 的範圍**，不要順便做其他 task。

### Step 5：驗收

按 task 的「驗收」欄位驗證：
- 程式碼能 build / 跑通？
- 對應的 test 有通過？
- 行為符合 design.md 的規格？

### Step 6：標記完成

- 驗收通過 → 把 `[🔄]` 改成 `[x]`
- 驗收失敗 → 改成 `[❌]`，加註原因，告訴使用者

### Step 7：報告

```
✅ Task $ARGUMENTS 完成：
- 修改：<檔案>
- 驗收：<怎麼驗證通過>
- 下一個建議 task：<若有依賴關係>

繼續下一個：/task:run <next-id> 或 /task:next
```

## 禁止行為

- ❌ 沒做 Step 1 宣告就動手
- ❌ 順便做其他 task（即使很相關）
- ❌ 驗收跳過
- ❌ 批次更新 tasks.md（必須每 task 完成立刻標記）
- ❌ 偷改 requirements.md / design.md（除非是修 typo）

## 若中途發現問題

若執行到一半發現：
- **task 描述有誤** → 停手，更新 task，請使用者重批
- **超出原 task scope** → 停手，跑 `/spec:scope-check`
- **依賴了沒標出的前置 task** → 停手，加新 task，請使用者重批
- **設計有問題** → 停手，回去改 design.md，重走 `/spec:approve-design`

**不要硬著頭皮做錯的事**。停手比硬做便宜。
