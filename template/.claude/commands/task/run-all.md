---
description: 一次執行當前 spec 的所有未完成 task
argument-hint: [feature-name，可省略，自動偵測]
---

# /task:run-all — 執行全部未完成 task

使用者批准一次執行全部 task。

## 你的任務

### Step 1：定位 spec

- 若 `$ARGUMENTS` 有值 → 對應 `.agents/specs/$ARGUMENTS/tasks.md`
- 若為空 → 從當前進度（04-current-progress.md）推斷活躍 spec，或問使用者

### Step 2：SDD 協議宣告（全局版）

```
📋 已讀 SDD：
- .agents/specs/<feature>/requirements.md（狀態：✅ 已批准）
- .agents/specs/<feature>/design.md（狀態：✅ 已批准）
- .agents/specs/<feature>/tasks.md（狀態：✅ 已批准）

🎯 本次任務：執行 <feature> 所有未完成 task

📋 執行計畫：
<列出所有要做的 task，按依賴順序>
- [ ] 1.1 <...>
- [ ] 1.2 <...>
- [ ] 2.1 <...>
...

🚧 執行範圍：
- 預計影響 <N> 個檔案
- 預計新增 <M> 個檔案
- 預計執行時間：<大概估計>

⏸️ 若過程中遇到 scope 超出、架構問題、test 失敗，會立刻停手。
```

### Step 3：逐個執行

**嚴格按依賴順序**。每個 task 都走完整的：

1. 標 `[🔄]`
2. 執行
3. 驗收
4. 標 `[x]`（失敗標 `[❌]` 並停手）

**不要平行執行**。即使沒依賴，也一個一個做，這樣使用者隨時能看到進度。

### Step 4：每做完一個 task 報告進度

```
✅ Task 1.1 完成
進度：1/8
下一個：1.2 ...
```

這樣讓使用者隨時能插進來喊停。

### Step 5：遇到問題立刻停

若某個 task 失敗或發現問題：
- 標該 task `[❌]` 並加註原因
- **不要繼續做後續 task**
- 報告目前狀態給使用者：
  ```
  ❌ Task X.Y 失敗
  原因：<...>
  已完成：<列清單>
  未開始：<列清單>
  建議：<下一步>
  ```

### Step 6：全部完成後

```
🎉 全部 <N> 個 task 完成

已修改檔案：<清單>
已新增檔案：<清單>
已刪除檔案：<清單>

驗收摘要：
- <每個 Phase 的驗收結果>

建議下一步：
- 跑全域測試：<指令>
- Commit：git add . && git commit -m "feat: <feature>"
- 更新 .claude/rules/04-current-progress.md 的 Phase 完成度
```

## 禁止行為

- ❌ 沒做全局宣告就開始
- ❌ 跳過任何 task（即使看起來不重要）
- ❌ 平行執行 task
- ❌ 失敗後繼續下一個（必須停手報告）
- ❌ 不即時更新 tasks.md（每個完成立刻標）

## 與 plan mode 的關係

這個 command 等同於「plan mode 已經批准」。若使用者用 plan mode（Shift+Tab），agent 會先列 plan，批准後行為和 /task:run-all 一致。
