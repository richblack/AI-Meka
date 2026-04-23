# 禁止行為清單（零容忍）

> 這份清單由 `.claude/hooks/*.sh` **強制執行**。違反會 block 工具呼叫（exit 2）。
> 新增禁令時：① 在這裡加條目 ② 在對應 hook 加 grep pattern ③ session 結束時 commit。

---

## 第一類：流程層級

### 1.1 禁止沒讀 SDD 就動 code
見 `00-sdd-protocol.md`。任何 `.go` / `.ts` / `.py` / `.tsx` 變動前必須先做宣告。

**Hook 行為**：soft reminder（不 block，但 post-edit hook 會警告）。

### 1.2 禁止跳關
Requirements 沒批准就開 design；design 沒批准就開 tasks；tasks 沒批准就動 code。

**Hook 行為**：agent 必須在宣告裡標示每一關的批准狀態，使用者審。

### 1.3 禁止批次更新 tasks.md
每完成一個 task 立刻 `[x]`。正在做的標 `[🔄]`。

**Hook 行為**：`post-edit-remind-tasks.sh` 每次改 code 後提醒。

### 1.4 禁止自行在 `.agents/specs/` 下建新頂層 SDD 目錄
**必須先與使用者確認 scope**。例外：在已知 SDD 目錄內新增檔案可以。

**Hook 行為**：`pre-write-guard.sh` 擋下寫入未授權的 SDD 頂層目錄。

### 1.5 禁止測試沒跑過就標 [x]
Task 標 `[x]` 前，該 task 的 Test File 必須在本 session 跑過且 pass。主觀判斷「做完了」不算。見 `.claude/rules/06-tdd-protocol.md`。

**Hook 行為**：`post-edit-check-tdd.sh` 偵測 tasks.md 被編輯出 `[x]` 時，在 stderr 注入強制自我檢核提醒，要求 agent 回報測試執行結果。

---

## 第二類：架構層級（專案填入）

> 以下是**範例模板**，實際內容按專案填。可通過 `.tech-constraints.yaml` 實現，或在本檔和 hook 裡寫自定義規則。

### 2.1 禁止在 `{component-dir}/` 下使用 {forbidden-language}
例：某個路徑下禁止 TypeScript（零件只能 TinyGo / AssemblyScript）。

**Hook 行為**：`pre-write-guard.sh` 擋副檔名 + 路徑組合，或寫在 `.tech-constraints.yaml` 的 `forbidden_extensions`。

### 2.2 禁止在架構層裡實作業務邏輯
例：orchestration worker 不能實作 credential 解密、JWT 簽章、template 展開等屬於 WASM 零件的職責。

**Hook 行為**：`pre-write-guard.sh` 偵測特定關鍵字（例：`crypto.subtle.decrypt` 出現在不該出現的檔案）。

### 2.3 禁止為同一個模組建平行目錄
例：要改 `module-x/` 就改本身，不准建 `module-x-v2/`、`new-module-x/`、`module-x-worker/`。

**Hook 行為**：`pre-write-guard.sh` + `pre-bash-guard.sh` 擋 mkdir/Write 到 `*-v2/` `*-worker/` `new-*/`（已內建）。

### 2.4 禁止新增特定 binding / 依賴
例：某些專案禁止新增 Cloudflare Service Binding（設計上要求走 HTTP URL）。

**Hook 行為**：`pre-bash-guard.sh` 偵測特定 pattern。

---

## 第三類：資料安全（專案填入，若適用）

### 3.1 禁止在日誌輸出 secret
例：禁止 `console.log(credential)`、禁止把 token 寫進 stderr。

### 3.2 禁止把 encryption key 傳出 host function 邊界
例：`ENCRYPTION_KEY` 只在 Worker host function 內部使用，不進 stdin、不進回傳值。

### 3.3 禁止硬編碼密碼 / API key / token
例：任何 `API_KEY=sk_xxx` hard-code 都要走 secret 管理。

**Hook 行為**：`pre-write-guard.sh` 偵測高熵字串 + 特定前綴（`sk_`, `ghp_`, etc.）。

---

## 第四類：版本控制

### 4.1 禁止 force push 到 main/master
**Hook 行為**：`pre-bash-guard.sh` 擋 `git push --force.*main`。

### 4.2 禁止 `rm -rf /` 或家目錄層級遞迴刪除
**Hook 行為**：`pre-bash-guard.sh` 擋。

### 4.3 禁止 commit node_modules / .env / 敏感資料
**Hook 行為**：在 git pre-commit 層處理（非 agent hook 範圍），此處記錄避免誤導。

---

## 第五類：SDD 同步

### 5.1 禁止「改 code 不改 spec」
任何 code 變動都要同步更新對應 SDD（requirements/design/tasks 擇一或多）。

**Hook 行為**：`stop-check-sync.sh` 在 session 結束前檢查 code vs specs 的 git status 是否同步。

### 5.2 禁止「改 spec 不改 code」
例外是純討論階段（requirements 未批准）。已批准的 SDD 被改 = 觸發影響分析（`/spec:impact`）。

---

## Hook Block 訊息格式（統一）

所有 hook block 時訊息統一為：

```
❌ BLOCKED by AI-Meka rules
違反項：<禁令編號，例如 2.1>
檔案 / 指令：<被擋的對象>
原因：<簡短說明>
正確做法：<該改去哪裡、該用什麼方式>
參考：.claude/rules/02-forbidden.md
```

---

## 新增禁令的 SOP

當使用者糾正 agent 一次錯誤行為後：

1. agent 或使用者跑 `/steering:add`
2. 決定屬於哪一類（1-5）
3. 用以下格式加入本檔：
   ```
   ### X.Y 禁止 <具體行為>
   <背景說明>
   **Hook 行為**：<block / soft reminder / session-end check>
   ```
4. 若是 block 層級，編輯 `.claude/hooks/pre-write-guard.sh` 或 `pre-bash-guard.sh` 加入對應 grep pattern
5. Commit 進 git（讓團隊同步）

---

## 禁令不是限制，是保護

每一條禁令都是某次使用者跟 agent 犯錯的記錄。它們存在是為了讓同樣的錯不再發生。如果某條禁令反覆 block 合理行為，回來討論放寬，不要繞過去。
