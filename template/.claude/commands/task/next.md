---
description: 執行當前 spec 的下一個未完成 task
---

# /task:next — 執行下一個 task

## 你的任務

### Step 1：找下一個 task

掃描活躍 spec 的 `tasks.md`，找第一個**依賴都已滿足**且狀態為 `[ ]` 的 task。

優先順序：
1. 同 Phase 內有依賴關係的，先做依賴前置的
2. 不同 Phase 之間，按 Phase 編號順序

### Step 2：若找不到

可能情況：
- 所有 task 都 `[x]` → 告訴使用者「該 spec 已完成」，建議跑全域測試 + commit
- 有 task `[🔄]` → 告訴使用者「還有 task 進行中」，問是否先收尾
- 有 task `[❌]` → 告訴使用者「有失敗 task」，問要不要先處理
- 有 task `[⏸️]` → 列出暫停原因，問是否解除暫停

### Step 3：執行

走和 `/task:run <id>` 一樣的完整流程（SDD 宣告 → 標 [🔄] → 執行 → 驗收 → 標 [x]）。

## 禁止行為

- ❌ 自己決定順序（違反 task 依賴關係）
- ❌ 跳過 `[❌]` 的 task（必須先解決或明確 skip）
- ❌ 不告訴使用者哪個 task 被選中就開始做

## 和 /task:run-all 的差別

- `/task:run-all`：一次做完全部，中途只在失敗時停
- `/task:next`：只做一個，做完就停，等使用者說下一步

`/task:next` 適合保守工作流程：做一個停一個，讓使用者審。
