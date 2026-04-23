# SDD 三層協議（強制流程）

## 核心原則：一關一關過，不能跳關

SDD（Spec-Driven Development）流程有三關：

```
Requirements（EARS 格式需求）
    │ ← 使用者審核，/spec:approve-req
    ▼
Design（技術設計）
    │ ← 使用者審核，/spec:approve-design
    ▼
Tasks（可執行任務）
    │ ← 使用者審核，/task:run <id> 或 /task:run-all
    ▼
Implementation（執行）
```

**每一關的產物 = 下一關的輸入**。沒有通過前一關就不能進下一關。這是鐵律。

---

## 為什麼要分三關？

因為人類一次能消化的資訊有限。AI coding agent 常犯的錯是「一口氣把 requirements + design + tasks + code 全吐出來」，人類看不完也來不及反饋，錯誤就溜進去了。

三層拆解讓每次只聚焦一件事：
- **Requirements**：聚焦「要做什麼、為什麼、誰用」，不談技術
- **Design**：聚焦「用什麼技術、怎麼切模組、畫資料流」，不談細節步驟
- **Tasks**：聚焦「實際要做哪些步驟、每一步可獨立驗收」

一層沒搞清楚就進下一層 = 蓋樓打在流沙上。

---

## 每次開工必做的宣告

開始動任何 code 前，**必須**在回覆開頭貼出這個宣告：

```
📋 已讀 SDD：
- .agents/specs/<feature>/requirements.md（狀態：已批准 / 討論中）
- .agents/specs/<feature>/design.md（狀態：已批准 / 討論中 / 尚未建立）
- .agents/specs/<feature>/tasks.md（狀態：已批准 / 討論中 / 尚未建立）

🎯 本次對應 task：<task 編號，例如 "1.3 實作 auth_static_key main.go">

📐 本次 task 的 SDD 規範摘要：
- <重點 1>
- <重點 2>
- <重點 3>

🚧 執行範圍：
- 會修改：<檔案清單>
- 會建立：<檔案清單>
- 會刪除：<檔案清單>
- 預估影響：<影響哪些下游>

⏸️ 開始前確認：<如果有任何不確定，在這裡問>
```

**不做這個宣告 = 違反 SDD 協議 = 停手等使用者確認**。

---

## Requirements 階段：用 EARS 格式

EARS = Easy Approach to Requirements Syntax。看起來很笨，但清晰。

### 格式

```markdown
# Requirements: <Feature Name>

## Epic
<一句話描述這個 feature 的商業價值>

## User Stories

### US-1: <簡短標題>
**As a** <角色>
**I want** <能力>
**So that** <價值>

#### Acceptance Criteria (EARS)
- **Ubiquitous**: The system SHALL <always-true 條件>
- **Event-driven**: WHEN <事件> THE system SHALL <回應>
- **State-driven**: WHILE <狀態> THE system SHALL <行為>
- **Optional**: WHERE <條件> THE system SHALL <行為>
- **Complex**: IF <前置條件> THEN THE system SHALL <行為>

### US-2: ...
```

### 範例

```markdown
### US-1: 用戶登入

**As a** 註冊用戶
**I want** 用 email + 密碼登入
**So that** 存取我的私人資料

#### Acceptance Criteria
- WHEN 用戶輸入正確 email + 密碼 THE system SHALL 回傳 JWT token（15 分鐘有效）
- WHEN 用戶輸入錯誤密碼連續 5 次 THE system SHALL 鎖定帳號 15 分鐘
- WHILE 帳號處於鎖定狀態 THE system SHALL 回傳 429 狀態碼
- IF 用戶 email 未驗證 THEN THE system SHALL 拒絕登入並回傳提示
```

### 通過條件

使用者看過 requirements.md，覺得「做完這些事就能解決我的問題」，輸入 `/spec:approve-req`。在此之前**不能**動 design。

---

## Design 階段：技術決策

### 格式

```markdown
# Design: <Feature Name>

## Overview
<技術上要做什麼、達成什麼目標>

## Architecture
<畫一張圖，文字版或 mermaid。必要時切 module>

## Data Model
<KV schema / DB table / JSON shape>

## APIs / Interfaces
<對外暴露的 endpoint / function signature>

## 技術決策與理由
- 決策 1：<採用 X 而非 Y>
  理由：<為什麼>
- 決策 2：...

## 非目標（Non-goals）
- 不做 X（原因：<為什麼>）
- 不做 Y

## 風險 / 未知
- 風險 1：<可能出問題的地方>
  緩解：<怎麼處理>

## 對既有系統的影響
- 影響 A：<怎麼相容>
- 影響 B：...
```

### 通過條件

使用者看過 design.md，覺得「技術方向對、風險可控、對現有系統衝擊可接受」，輸入 `/spec:approve-design`。在此之前**不能**動 tasks。

---

## Tasks 階段：可執行清單

### 格式

```markdown
# Tasks: <Feature Name>

> 權威來源，進度以此為準。每完成一個 task 立刻標 [x]，不批次。

## Phase 1: <階段名>

- [ ] 1.1 <具體動作，名詞動詞明確>
  - 驗收：<怎麼知道做完了>
  - 影響檔案：<哪些檔案會被改>

- [ ] 1.2 <...>
  - 驗收：<...>
  - 依賴：1.1

## Phase 2: <...>
- [ ] 2.1 <...>
```

### Task 狀態標記（強制）

| 標記 | 意義 |
|-----|------|
| `- [ ]` | 尚未開始 |
| `- [🔄]` | **正在執行**（agent 開始一個 task 時立刻標上） |
| `- [x]` | 已完成且驗收通過 |
| `- [❌]` | 嘗試過但失敗（需要紀錄原因） |
| `- [⏸️]` | 暫停（等待依賴） |

**視覺進度的價值**：人類掃一眼就知道 agent 走到哪、哪裡卡住。這是跨 session 可觀測性的核心。

### 通過條件

使用者看過 tasks.md，可以：
- `/task:run 1.1` — 執行單一
- `/task:run-all` — 執行全部（plan mode 批准）
- `/task:next` — 執行下一個未完成

---

## 需求變動時：不頭痛醫頭

**agent 最容易犯的錯**：使用者說「這裡改一下」，agent 立刻改。
**正確做法**：

1. 先跑 `/spec:impact <feature-name>`，列出影響範圍
2. 判斷 scope：
   - 改動在原 SDD 範圍內 → 更新對應的 requirements/design/tasks，走完三關
   - 改動超出原 SDD → 建議開新 spec（`/spec:scope-check` 會自動判斷）
3. 使用者確認後才動 code

**不可以**：
- 不看 impact 直接改
- 把新功能塞進既有 tasks.md 硬湊
- 只改 code 不改 spec（永遠保持 spec 和 code 同步）

---

## 小改動例外

以下情況可以簡化流程（但不可跳過宣告）：

| 改動類型 | 簡化 |
|---------|------|
| 打字錯誤、變數改名 | 不需要走 SDD，直接改，但回覆要說明 |
| 10 行以內單檔改動 | 不需要新 spec，但要更新對應 tasks.md 並註記 |
| 純重構（不改行為） | 不需要 requirements，但要 design + tasks |
| Bug fix | 要在對應 spec 的 tasks.md 加一筆，或如果 spec 不存在，跟使用者確認 |

判斷不確定時：**問使用者**。問比猜快。

---

## 規則的規則

- 規則衝突時，優先順序：`CLAUDE.md` > `.claude/rules/00-sdd-protocol.md` > 其他 rules 檔 > 一般慣例
- 發現規則之間矛盾 → **停手**，告訴使用者，不要自己猜
- 使用者糾正你 → 用 `/steering:add` 立刻沉澱，不要只留在 session 記憶裡
