# Task 粒度紀律

> 這份規則解決一個具體問題：**AI coding agent 的 context 有壓縮風險**。
> Task 切太大，做到一半 context 壓縮後 agent 會忘記原本的約束和決策。
> Task 切太小，你會被打斷太多次。中間有個甜蜜點。

---

## 核心紀律

**一個 task 必須能在單次 agent session 內完成，不觸發 context 壓縮。**

---

## 判斷標準

拆 task 時自問：

| 維度 | 安全範圍 | 危險訊號 |
|-----|---------|---------|
| 預期產出程式碼 | < 300 行 | > 500 行 |
| 涉及檔案數 | 1-3 個 | > 5 個 |
| 跨 subsystem | 只動一個 | 跨多個 |
| 預估工作時間 | 30-60 分鐘 | > 2 小時 |
| 決策點數量 | 0-2 個 | > 3 個 |

**任何一項進危險區 → 拆成更小的 task。**

---

## 好 task vs 壞 task 對照

### ❌ 壞 task（太大）

```markdown
## Task 2: 實作 Gmail 零件
- 寫 Go code
- 寫 contract.yaml
- 寫 tests
- deploy 到 R2
- 寫文件
```

問題：跨 5 個檔案、3 個 subsystem、預計 4 小時。agent 做到一半會失憶。

### ✓ 好 task（拆開）

```markdown
## Task 2.1: 實作 Gmail 零件核心邏輯
- 檔案: registry/components/gmail/main.go
- 輸出: 符合 contract.yaml input_schema 的 WASM
- 完成條件: tinygo build 成功

## Task 2.2: 寫 Gmail 零件 contract
- 檔案: registry/components/gmail/component.contract.yaml
- 完成條件: 含 input_schema / output_schema / credentials_required

## Task 2.3: 寫 Gmail 零件測試
- 檔案: registry/components/gmail/gmail_test.go
- 完成條件: 覆蓋 contract 定義的所有 gherkin scenarios

## Task 2.4: 部署 Gmail 零件到 R2
- 指令: wrangler r2 object put ...
- 完成條件: curl R2 能拿到 .wasm
```

每個 task 都在安全範圍內，可以放飛。

---

## Checkpoint 機制

每個 task 在 tasks.md 裡寫 **checkpoint**，讓 agent 即使失憶也能恢復：

```markdown
## Task 2.1: 實作 Gmail 零件核心邏輯

### Status: [🔄] 進行中

### Acceptance（機器可驗證的完成條件）
- [ ] `tinygo build -target=wasi registry/components/gmail/main.go` 成功
- [ ] 通過 `go test ./registry/components/gmail/...`

### Checkpoint（agent 執行過程中逐步打勾）
- [ ] 讀過 .tech-constraints.yaml 確認用 TinyGo
- [ ] 讀過 component.contract.yaml 確認 input/output schema
- [ ] 寫完 input 解析
- [ ] 寫完 OAuth 注入邏輯
- [ ] 寫完 HTTP 請求
- [ ] 通過 tinygo build
- [ ] 更新 tasks.md 為 [x]

### Context Handoff（若 session 被壓縮，下次讀這個）
（agent 在每個 checkpoint 打勾時，簡單記一句當前狀態，讓下次 session 秒接）
```

---

## Session 邊界紀律

**每個 task 盡量用新 session 做**，避免 context 累積：

```
開始 task X
  ↓
agent 讀 tasks.md，看到 [🔄]
  ↓
agent 讀 task X 的 checkpoint，看做到哪
  ↓
繼續執行（或從頭開始如果 checkpoint 是空的）
  ↓
完成 → 更新 [x]，清空 [🔄]
  ↓
準備下一個 task：建議 /exit 重啟 session
```

如果在 AI-Meka 的 queue-runner 模式下，一個 project 跑完本來就是新 session，不用特別處理。

---

## 何時違反紀律也可以

以下情況 task 可以切大一點：

1. **探索階段**（requirements 還在討論）— 此時 agent 是在幫忙思考，不是在寫 code
2. **純粹的機械搬運**（例如大量重複格式的 CRUD）— 一個 task 20 個檔案也可以，因為決策少
3. **必須原子性的重構**（例如改 interface signature，所有 caller 要同時改）

但這些情況下，**checkpoint 要更密**，每做完一個檔案就打勾。

---

## 反模式

以下寫法違反此紀律：

- ❌ 一個 task 叫「實作登入功能」沒細分
- ❌ tasks.md 總共只有 5 個 task 但每個都 8 小時
- ❌ task 描述沒寫完成條件（agent 自己決定什麼算完）
- ❌ Checkpoint 只有一項（「完成」）
- ❌ task 內容包含「順便修 X」、「如果遇到問題就改 Y」（scope 模糊）

遇到這些就拆成更小的 task，或補 checkpoint。

---

## 為什麼需要這個紀律

有些工具（例如逐步批准型的 SDD 工具）每個 task 都強制人類批准才執行，人類自然會把 task 切小。

但自動化 AI coding agent 不同：它可以自動跑、跑很久、中途不打斷。這個紀律的作用是**給 agent 切出安全的放飛區間**，讓它能快又不失憶。

**agent 的強項是單 task 內全速放飛，紀律是保證每次放飛的區間都夠短。**
