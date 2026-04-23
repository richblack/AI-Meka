# TDD 協議

> 這份規則解決一個具體問題：**「[x] 是主觀判斷，不可信」**。
> 沒測試保護的話，AI coding agent 標 [x] 只代表「它覺得做完了」，不代表功能真的能跑。
> 這份協議把 [x] 的意義綁到可執行的測試上：測試 pass 才能標 [x]。

---

## 核心紀律

**Task 標 `[x]` 的條件：該 task 的 Test File 存在，且本次 session 內跑過、且全部 pass。**

沒跑測試 = 不准標 [x]。跑了但 fail = 不准標 [x]。測試不存在 = 不准標 [x]。

---

## 為什麼

沒 TDD 的失敗模式：

1. agent 寫了 code，覺得「看起來沒問題」，標 [x]
2. 下個 task 改動了共用函式，前一個 task 默默壞掉
3. 跨 session 之後使用者才發現，全部要從頭查
4. 由於 tasks.md 顯示「全部 [x]」，信號完全失真

有 TDD 的保護：

1. agent 寫完 code → 跑 Test File → 看到綠燈 → 才標 [x]
2. 下個 task 改動共用函式 → 跑前一個 task 的 Test File → 若紅燈 → 立刻停手、回去修
3. tasks.md 的 [x] 始終對應「當下測試過的狀態」，信號不失真

---

## Tasks.md 的 Test File 欄位（強制）

每個 task 必須宣告它的 Test File。格式：

```markdown
- [ ] 1.3 實作 services/login.ts
  - Test File: `tests/unit/login.test.ts`
  - 驗收：<可由測試檢驗的條件>
  - 影響檔案：`src/services/login.ts`、`tests/unit/login.test.ts`
  - 依賴：1.1, 1.2
```

### Test File 欄位的值有四種

| 值 | 意義 | 標 [x] 的條件 |
|----|------|---------------|
| `tests/.../xxx.test.ts`（具體路徑） | 這個 task 有對應測試檔 | 檔案存在 + 跑過 + pass |
| `tests/.../xxx.test.ts`（擴充現有） | 這個 task 擴充已有測試 | 同上，擴充的 case 要在檔內 |
| `—`（一個 em-dash） | 無測試（純配置、文件） | 需要在 task 裡註明理由；必須有人類或 downstream task 的測試間接覆蓋 |
| 多個檔名 | 跨多個測試 | 全部都要 pass |

**「—」不是逃生口**。允許它是因為有些 task 本質上非 testable（例如「更新 README」），但如果一個 Phase 內超過 30% 的 task 標 `—`，那通常代表粒度切錯了：把「寫 code」和「測 code」拆在不同 task，導致寫 code 的 task 沒測試。不要這樣切。

---

## 執行流程（agent 必遵守）

開始一個 task：

```
1. 讀 tasks.md，找到該 task 的 Test File 欄位
2. 若 Test File 還不存在 → 先寫 test（紅燈）
3. 寫實作讓 test 變綠
4. 跑一次完整的 Test File
5. 全部 pass → 更新 tasks.md [x]
   有 fail → 繼續修，或標 [❌] 並註記
```

**禁止**：先寫完 code，最後才想起要 test。這會讓 test 變成 rubber-stamp（agent 寫出會 pass 它自己 code 的 test，沒抓到 bug 的能力）。

**可以**：先寫 test 再寫 code（經典 TDD），或者 test 和 code 交替寫（agent 友善版 TDD）。關鍵是 test 要真的有挑戰實作。

---

## Hook 強制機制

`post-edit-check-tdd.sh` 會在每次 tasks.md 被編輯成 `[x]` 時觸發，提醒 agent：

```
🧪 TDD Hook 檢查
偵測到 tasks.md 新增 [x] 標記。

你剛剛跑過對應的 Test File 了嗎？
  - 請在回覆中明確回報：
    "Task X.Y Test File: <path>, 執行結果: <pass/fail>, 輸出摘要: <...>"
  - 若還沒跑，立刻跑再確認 [x]
  - 若 Test File 欄位是「—」，請說明為什麼這個 task 免測試
```

Hook 不硬擋（exit 0），因為硬擋的話 agent 每次 tasks.md 編輯都會卡住。但它會在 stderr 留下強制提醒，被注入 agent 的 context，下一輪推理時會看到。

---

## 常見反模式

### ❌ 反模式 1：一個 task 裡的 test 是另一個 task

```markdown
- [ ] 1.3 實作 login service
  - Test File: —
- [ ] 1.4 寫 login service 的 test
  - Test File: `tests/login.test.ts`
```

問題：1.3 可以在沒測試的情況下標 [x]，然後 1.4 發現實作有 bug。回到 1.3 改 code 就要重新驗收，但 tasks.md 已顯示 1.3 完成。狀態失真。

正確：合併或把 test 作為 1.3 的 Test File，實作和測試都在 1.3 完成。

### ❌ 反模式 2：Test File 指一個不會跑到實作的測試

```markdown
- [ ] 2.1 實作 refresh-store 的 rotation 機制
  - Test File: `tests/integration/e2e-smoke.test.ts`
```

問題：e2e smoke test 太粗，不會 exercise rotation 的 edge cases。這個 Test File 可以全綠，rotation 卻是壞的。

正確：Test File 要是能 exercise 該 task 具體行為的測試。必要時為這個 task 新建 test 檔。

### ❌ 反模式 3：Agent 改 test 而不是改 code

Test 紅燈時，agent 可能為了讓它 pass 而改 test 的 assertion。這違反 TDD 精神。

檢測：git diff 同時看 Test File 和實作檔；如果只有 test 改、實作沒改（或僅微調），但 test 從紅變綠，高度可疑。

---

## 和 05-task-granularity 的關係

TDD 協議和 task 粒度是一對：

- 粒度紀律說：一個 task < 300 行 / < 5 檔案，能在單 session 內完成
- TDD 協議說：每個 task 要有可跑的 test

**兩條同時滿足時，[x] 才有資格被信任。**

如果一個 task 太大跑不完 test，或一個 task 沒 test，都等於放棄了 tasks.md 作為進度信號的價值。

---

## 例外情況

這些 task 可以 Test File: `—`：

1. **純設定 / 配置檔**（例：新增 `.env.example`、更新 `wrangler.toml` 的非功能欄位）
2. **純文件**（例：README、CHANGELOG、註解更新）
3. **工具腳本的 one-shot 執行**（例：`wrangler kv:namespace create`，產生的 binding id 下個 task 會用到）
4. **commit / PR task**（由 CI 跑完整測試，不額外寫 test）

這些情況下，task 描述要寫清楚「為什麼免測試」+「下游哪個 task 會間接覆蓋到」。
