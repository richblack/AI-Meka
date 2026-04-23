# 架構規範（專案填入）

> 這份是**空模板**，專案第一天填入核心架構決策。
> AI coding agent 最容易搞錯的抽象概念放這裡（例如用了同名字卻指不同東西的術語）。

---

## 架構總覽

```
<畫一張 ASCII 或 mermaid 圖>

例：
Client (CLI/SDK)
    │
    ▼  HTTPS + AES-GCM encrypted secrets
[Main Worker]
    │
    ├─ KV (storage)
    ├─ R2 (WASM bucket)
    └─ HTTP fetch ──► [Component Worker 1]
                       [Component Worker 2]
                       [Component Worker 3]
                       (each = independent Worker, 1 public URL)
```

---

## 核心概念字典

> **這裡放專案獨有術語**。agent 常因為不懂領域術語而錯用。

### <Term 1>
<白話定義，特別強調「不是什麼」>

例：
### Internal Routing Binding
**不是** 某個運行平台的內建 binding。
**是** 一張 YAML 清單，寫在 workflow YAML 或存在 KV，內容是「這個 workflow 要 HTTP POST 去哪些 URL」。
**為什麼不是平台 binding**：用戶新建 workflow 不可能 redeploy，所以 workflow 層一定走 HTTP，不走 binding。

### <Term 2>
<...>

---

## 核心架構決策

### 決策 1：<標題>
- **採用**：<方案 A>
- **捨棄**：<方案 B>
- **原因**：<為什麼>
- **影響**：<下游怎麼配合>

例：
### 決策 1：每個模組獨立部署
- **採用**：N 個獨立 service，每個一個模組，透過 HTTP 互相呼叫
- **捨棄**：一個大模組內部分派給多個子功能
- **原因**：獨立部署 = 獨立更新 = 用戶自製模組也能用同樣模式
- **影響**：orchestration 層不能用 import，必須走 fetch；測試要 mock HTTP

---

## 目錄結構（專案填入）

```
{project-root}/
├── {module-1}/       ← <職責>
├── {module-2}/       ← <職責>
├── .agents/specs/    ← SDD 文件
└── .claude/          ← agent 行為規範
```

---

## 模組邊界（誰可以呼叫誰）

| 呼叫方 | 被呼叫方 | 管道 |
|-------|---------|------|
| <例：CLI> | <例：Main Worker> | <例：HTTPS REST> |
| <例：Main Worker> | <例：Component Worker> | <例：HTTPS fetch> |
| <例：Component Worker> | <例：KV / R2> | <例：host function> |

**禁止跨界呼叫**：<例：CLI 不能直接存 KV；Component 不能呼叫其他 Component>

---

## 資料流（關鍵路徑）

### 流程 1：<例如：用戶發起一個 workflow>
```
1. CLI POST → Main Worker /trigger
2. Main Worker 讀 KV 拿 workflow YAML
3. Main Worker 按 graph 順序 HTTP POST 每個 component URL
4. 每個 component 回傳 output
5. Main Worker 合併回傳給 CLI
```

---

## 命名約定（專案填入）

| 類型 | 慣例 | 例 |
|-----|-----|----|
| Worker 名 | <例：`{project}-{module}`> | <例：`myapp-auth-service`> |
| Service URL | <例：`{name-kebab}.domain.tld`> | <例：`auth-service.example.com`> |
| KV key 前綴 | <例：`{api_key}:{type}:{id}`> | <例：`ak_xxx:cred:openai`> |
| Git branch | <例：`feat/xxx`, `fix/xxx`> | — |

---

## 常見誤區（給 agent 看）

> 把你預期 agent 會搞錯的抽象概念寫這裡。Prefix: 「不是 X，是 Y」格式最有效。

例（範例說明）：

### 誤區 1：零件從中央儲存動態載入
**不是**。平台內建模組已 bundle 進各自 service，不從儲存取。
中央儲存只用於特定 Phase 的用戶自製模組。

### 誤區 2：內部 binding 串模組
**不是**。用戶不可能每次新 workflow 都 redeploy。模組串接走 HTTP URL。內部 binding 只在效能優化層保留。

### 誤區 3：orchestration 層做業務邏輯
**不是**。orchestration 只做 HTTP routing + host functions。業務邏輯全在 worker 或 WASM 零件。
