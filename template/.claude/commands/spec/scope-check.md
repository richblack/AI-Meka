---
description: 檢查當前改動是否超出原 SDD scope，建議是否拆成新 spec
argument-hint: [feature-name，可省略]
---

# /spec:scope-check — Scope 判斷

## 你的任務

判斷當前正在做的改動是「小修改」還是「新需求」，用工程師判斷 bug 與 feature 分開處理的邏輯。

### Step 1：辨識當前改動

查 git status，列出本 session 已經動過 / 即將動的檔案。

### Step 2：定位原 SDD

若 `$ARGUMENTS` 有值 → 讀對應 SDD
若為空 → 從最近活躍的 spec 推斷，或問使用者

### Step 3：對比原 SDD 的 Scope

讀 SDD 的 `requirements.md` 和 `design.md`，特別是：
- User Stories 涵蓋範圍
- Non-goals 列表
- Architecture 模組邊界

### Step 4：判斷類別

| 類別 | 判斷標準 | 建議動作 |
|-----|---------|---------|
| **🟢 修改（Modify）** | 改動在原 US 範圍內，只是實作細節 | 更新現有 design/tasks，加 task 到 tasks.md |
| **🟡 擴展（Extend）** | 原 US 沒涵蓋，但屬於同一 feature 脈絡 | 在原 spec 新增 US 到 requirements.md，重走 /spec:approve-req |
| **🔴 新需求（New Feature）** | 跨 feature 或改變核心架構 | 建議 /spec:new 建新 spec，舊 spec 保持穩定 |

### Step 5：輸出建議

```markdown
# Scope Check: <當前改動的簡述>

## 當前改動檔案
<列出 git status 的檔案>

## 對應的原 SDD
`.agents/specs/<feature>/`

## 原 SDD 的核心 scope
- User Stories：<簡述>
- Non-goals：<簡述>
- Architecture 邊界：<簡述>

## 判斷：<🟢 Modify / 🟡 Extend / 🔴 New Feature>

## 理由
<為什麼這樣判斷>

## 建議動作
<根據表格的建議動作>

## 給使用者的問題
- 同意這個判斷嗎？
- 要執行建議動作嗎？
```

### Step 6：等使用者決定

不要自己決定。Scope 判斷是架構決策，必須人審。

## 常見情境範例

### 範例 1：修 bug 變重構
- 原 SDD：實作 gmail 零件
- 當前改動：改 gmail 的錯誤處理 + 順便改 http_request 的錯誤處理 + 順便抽共用 utility
- 判斷：🔴 新需求（重構是獨立 scope）
- 建議：只做 gmail 錯誤處理（原 scope 內）；重構獨立開 spec

### 範例 2：新增 feature 暗度陳倉
- 原 SDD：用戶登入
- 當前改動：登入 + 順便加「忘記密碼」 + 順便加「雙因素認證」
- 判斷：🟡 Extend（屬同一 feature 但超出原 US）
- 建議：把「忘記密碼」「雙因素認證」加進 requirements.md 的 US-2/US-3，重走 approve-req

### 範例 3：純實作細節
- 原 SDD：JWT token 有效期 15 分鐘
- 當前改動：實作發現用 jose 函式庫比 jsonwebtoken 好
- 判斷：🟢 Modify（實作選擇，不影響行為）
- 建議：更新 design.md 的「技術決策」即可，無需重批

## 禁止行為

- ❌ 不判斷 scope 就繼續改
- ❌ 把多個 scope 的改動塞進同一個 tasks.md
- ❌ 自行決定要不要開新 spec（必須問使用者）
