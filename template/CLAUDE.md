# CLAUDE.md — {PROJECT_NAME}

> 本檔是**索引 + 最高原則**。詳細規範在 `.claude/rules/`，Hook 強制機制在 `.claude/hooks/`，slash commands 在 `.claude/commands/`。
> 違反硬禁令會被 hook 直接 block（exit 2）。
>
> **核心哲學**：AI coding agent 速度快但跨 session 容易失憶、容易偏離規格。AI-Meka 給它一份「跨 session 記憶合約」+ 硬強制機制，讓它在約束下全速執行。

---

## 絕對鐵律（違反 = 停手）

1. **任何 code 變動前必須先讀對應 SDD**，按 `.claude/rules/00-sdd-protocol.md` 的宣告格式回覆
2. **SDD 三關必須一關一關過**：requirements → design → tasks，前關沒批准不能進下關
3. **修改現有程式碼，不是新建資料夾重做**
4. **需求變動時，先跑 `/spec:impact` 看全局影響**，再決定改什麼
5. **scope 超出原 SDD 時，必須提議開新 spec**，不能硬塞進原 tasks.md
6. **每完成一個 task 立刻更新 tasks.md 的 `[x]`**，不批次
7. **正在執行的 task 標 `[🔄]`**，讓人類知道當前進度
8. **每個 task 要在單次 session 內完成**（見 `.claude/rules/05-task-granularity.md`）
9. **技術棧約束寫在 `.tech-constraints.yaml`**，違反會被 hook 擋下
10. **Task 標 `[x]` 前測試必須先通過**（見 `.claude/rules/06-tdd-protocol.md`）— 主觀判斷「我做好了」不算，測試 pass 才算

---

## 跨 Session 記憶契約

AI coding agent 每次 session 開始，必須做這三件事：

1. 讀 `tasks.md` 找 `[🔄]` 標記，知道自己做到哪
2. 讀該 task 的 **Checkpoint** 區塊，知道子步驟做到哪
3. 讀 `.tech-constraints.yaml`，重新載入技術棧約束

**沒讀這三個就動手 = 違反合約。**

---

## 工作流程（強制）

### 新功能
```
/spec:new <feature-name>
  → 討論 requirements.md（EARS 格式）
/spec:approve-req
  → 產 design.md
/spec:approve-design
  → 產 tasks.md（每個 task 在安全粒度內，含 checkpoint）
/task:run <id> 或 /task:run-all
  → 執行
```

### 修改現有功能
```
/spec:impact <feature-name>
  → 列出影響範圍
[與使用者確認範圍]
  → 更新對應 SDD（requirements / design / tasks 擇一或多）
  → 執行
```

### 發現做錯事
```
/steering:add
  → 把教訓寫進 .claude/rules/
  → 必要時同步更新 .claude/hooks/ 或 .tech-constraints.yaml
```

---

## 詳細規範索引

| 檔案 | 內容 |
|-----|------|
| `.claude/rules/00-sdd-protocol.md` | SDD 三層協議（強制流程 + 宣告格式） |
| `.claude/rules/01-tech-stack.md` | 技術棧規範（說明性） |
| `.claude/rules/02-forbidden.md` | 禁止清單（hook 強制） |
| `.claude/rules/03-architecture.md` | 架構規範 |
| `.claude/rules/04-current-progress.md` | 當前進度 + SDD 索引 |
| `.claude/rules/05-task-granularity.md` | Task 粒度紀律（避免 context 壓縮失憶） |
| `.claude/rules/06-tdd-protocol.md` | TDD 協議（task 打 [x] 前測試必須通過） |
| `.tech-constraints.yaml` | **技術棧硬約束**（hook 讀取，違反會擋） |

---

## Slash Commands

| 指令 | 用途 |
|-----|-----|
| `/spec:new <n>` | 建立新 spec（啟動三層流程） |
| `/spec:approve-req` | 批准 requirements，進入 design |
| `/spec:approve-design` | 批准 design，進入 tasks |
| `/spec:impact <n>` | 分析改動影響範圍 |
| `/spec:scope-check` | 檢查當前改動是否超出 SDD |
| `/spec:status` | 列出所有 spec 進度 |
| `/task:run <id>` | 執行單一 task |
| `/task:run-all` | 執行當前 spec 所有 tasks |
| `/task:next` | 執行下一個未完成 task |
| `/steering:add` | 把新規則寫進 steering |
| `/steering:list` | 列出所有 steering 規則 |

---

## SDD 位置

所有 SDD 在 `.agents/specs/<feature-name>/`，每個 spec 至少包含：
- `requirements.md` — EARS 格式需求
- `design.md` — 技術設計
- `tasks.md` — 可執行任務清單（含 checkpoint）

範例見 `.agents/specs/_example-feature/`（可刪除，只是給 agent 看格式的）。

---

## 專案資訊（填入實際內容）

- **專案名稱**：{PROJECT_NAME}
- **技術棧**：見 `.tech-constraints.yaml`（硬約束）+ `.claude/rules/01-tech-stack.md`（說明）
- **當前 Phase**：見 `.claude/rules/04-current-progress.md`
- **部署環境**：{DEPLOYMENT_ENV}
