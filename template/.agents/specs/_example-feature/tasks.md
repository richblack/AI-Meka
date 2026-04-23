# Tasks: User Login

> 狀態：✅ 已批准（範例）
> 基於：design.md（已批准於 2026-04-20）
> 權威進度來源。每完成一個 task 立刻更新標記，不批次。

---

## 標記約定

- `[ ]` 未開始
- `[🔄]` 正在執行
- `[x]` 已完成且**測試通過**（見 06-tdd-protocol.md）
- `[❌]` 失敗（註記原因）
- `[⏸️]` 暫停（等依賴）

---

## Phase 0：環境與依賴

- [x] 0.1 新增 password hashing dependency
  - Test File: `tests/setup.test.ts`
  - 驗收：`pnpm install` 成功，`import { hash } from 'hashing-lib'` 不報錯，setup test pass
  - 影響檔案：`auth-service/package.json`

- [x] 0.2 設定 KV namespaces：USERS / LOGIN_ATTEMPTS / TOKEN_BLACKLIST
  - Test File: —（配置類，由後續 task 的 integration test 驗證）
  - 驗收：三個 KV binding 在 config 存在並可讀寫
  - 影響檔案：`auth-service/wrangler.toml` 或對等 config

- [x] 0.3 設定 Refresh Token Store 連線
  - Test File: `tests/integration/store-ping.test.ts`
  - 驗收：`STORE_URL` 環境變數可用，連線 ping 回應正常，test pass
  - 影響檔案：`auth-service/wrangler.toml`、`.env.example`

---

## Phase 1：核心 login/logout

- [x] 1.1 實作 `lib/password-hasher.ts`（hash + verify）
  - Test File: `tests/unit/password-hasher.test.ts`
  - 驗收：unit test 3 pass（hash 結果不同但 verify 相同密碼過、不同密碼 fail、format 符合預期）
  - 影響檔案：`auth-service/src/lib/password-hasher.ts`、`tests/unit/password-hasher.test.ts`
  - 依賴：0.1

- [x] 1.2 實作 `lib/jwt-signer.ts`（生成/驗證 access token）
  - Test File: `tests/unit/jwt-signer.test.ts`
  - 驗收：unit test 通過（sign 出的 token 能 verify、錯 secret verify fail、過期 verify fail）
  - 影響檔案：`auth-service/src/lib/jwt-signer.ts`、`tests/unit/jwt-signer.test.ts`

- [🔄] 1.3 實作 `services/login.ts`
  - Test File: `tests/unit/login.test.ts`
  - 驗收：unit test 覆蓋所有 EARS criteria（正確登入、錯密碼、email 不存在、未驗證、鎖定）
  - 影響檔案：`auth-service/src/services/login.ts`、`tests/unit/login.test.ts`
  - 依賴：1.1, 1.2

- [ ] 1.4 實作 `services/logout.ts`
  - Test File: `tests/unit/logout.test.ts`
  - 驗收：unit test（加黑名單、重複登出冪等、過期 token 不需黑名單）
  - 影響檔案：`auth-service/src/services/logout.ts`、`tests/unit/logout.test.ts`
  - 依賴：1.2

- [ ] 1.5 實作 `middleware/rate-limiter.ts`（5 次鎖 15 分鐘）
  - Test File: `tests/unit/rate-limiter.test.ts`
  - 驗收：unit test（第 5 次錯誤後回 429、過 15 分鐘自動解鎖、成功登入重設計數）
  - 影響檔案：`auth-service/src/middleware/rate-limiter.ts`、`tests/unit/rate-limiter.test.ts`

- [ ] 1.6 實作 HTTP routes（POST /login, POST /logout）
  - Test File: `tests/integration/auth-routes.test.ts`（用 miniflare 或對等 local runtime）
  - 驗收：integration test 通過
  - 影響檔案：`auth-service/src/routes/auth.ts`、`auth-service/src/index.ts`
  - 依賴：1.3, 1.4, 1.5

---

## Phase 2：Refresh token

- [ ] 2.1 實作 `lib/refresh-store.ts`（store CRUD + rotation）
  - Test File: `tests/unit/refresh-store.test.ts`
  - 驗收：unit test（建 token、使用標 used、偵測重用觸發 family 作廢）
  - 影響檔案：`auth-service/src/lib/refresh-store.ts`、`tests/unit/refresh-store.test.ts`
  - 依賴：0.3

- [ ] 2.2 在 login service 加入「同時發 refresh token」
  - Test File: `tests/unit/login.test.ts`（擴充現有）
  - 驗收：login 回傳 response 有 refresh_token 欄位；store 有記錄
  - 影響檔案：`auth-service/src/services/login.ts`
  - 依賴：1.3, 2.1

- [ ] 2.3 實作 `services/refresh.ts`
  - Test File: `tests/unit/refresh.test.ts`
  - 驗收：test（正常 refresh 發新 token、重用 refresh token 觸發作廢、過期 refresh 回 401）
  - 影響檔案：`auth-service/src/services/refresh.ts`、`tests/unit/refresh.test.ts`
  - 依賴：2.1, 1.2

- [ ] 2.4 新增 POST /refresh route
  - Test File: `tests/integration/auth-routes.test.ts`（擴充現有）
  - 驗收：integration test 通過
  - 影響檔案：`auth-service/src/routes/auth.ts`
  - 依賴：2.3

---

## Phase 3：整合既有系統

- [ ] 3.1 API gateway 新增 auth middleware（驗證 Authorization header）
  - Test File: `tests/integration/gateway-auth.test.ts`
  - 驗收：gateway 測試在有無 token 時行為正確
  - 影響檔案：`api-gateway/src/middleware/auth.ts`

- [ ] 3.2 CLI 實作 `login` / `logout` 指令
  - Test File: `tests/e2e/cli-login.spec.ts`（Playwright / CLI test runner）
  - 驗收：e2e 測試從 CLI 登入後能打通到 API gateway
  - 影響檔案：`cli/src/commands/login.ts`、`logout.ts`

- [ ] 3.3 Python SDK 加 401 自動 refresh
  - Test File: `python-sdk/tests/test_auto_refresh.py`
  - 驗收：測試 token 過期後自動續期
  - 影響檔案：`python-sdk/client.py`

- [ ] 3.4 JS SDK 加 401 自動 refresh
  - Test File: `js-sdk/tests/auto-refresh.test.ts`
  - 驗收：同上
  - 影響檔案：`js-sdk/src/client.ts`

---

## Phase 4：驗證與交付

- [ ] 4.1 全 suite 測試
  - Test File: 全部
  - 驗收：`pnpm test` 全 pass，coverage ≥ 80%

- [ ] 4.2 端對端測試：CLI → auth-service → API gateway 流程
  - Test File: `tests/e2e/full-flow.spec.ts`
  - 驗收：happy path + 至少 3 個 error cases 自動化 pass

- [ ] 4.3 安全審查
  - Test File: `tests/security/login-security.test.ts`
  - 驗收：
    - 沒 log 密碼或 token 到 console
    - 錯誤訊息不洩漏帳號存在性
    - CORS 設定正確
    - rate limit 實測 5 次鎖定生效

- [ ] 4.4 更新相關文件
  - Test File: —
  - 驗收：README 有 auth 章節、CHANGELOG 記錄、API 文件更新
  - 影響檔案：`README.md`、`CHANGELOG.md`、`docs/api/auth.md`

- [ ] 4.5 更新 `.claude/rules/04-current-progress.md`
  - Test File: —
  - 驗收：標記 user-login Phase 0-4 全完成，移到「已完成 SDD」清單

- [ ] 4.6 Commit + PR
  - Test File: —（CI 會跑全 suite）
  - 驗收：PR 描述包含 SDD 連結、測試結果、screenshot（若適用）

---

## 附註

### 每個 task 執行順序建議

Phase 0 → 1（可部分並行，但 1.3 要等 1.1+1.2）→ 2（依賴 Phase 1 完成）→ 3（依賴 Phase 2）→ 4

推薦用 `/task:run` 逐個做，Phase 1 完成後再一次 `/task:run-all` 做 Phase 2-3。

### 若發現需要新增 task

立刻加到這份檔案對應 Phase，不要只記在腦子裡。加入時格式同上（Test File + 驗收 + 影響檔案 + 依賴）。

### 若某 task 變大要拆

先在本檔把大 task 拆成 1.3.1 / 1.3.2 / 1.3.3，更新影響檔案清單。**不要**把新任務偷塞進同一個 task 的實作裡。

### 若某 task 失敗

標 `[❌]` 並加一行說明：
```
- [❌] 1.3 實作 services/login.ts
  - 原因：hashing lib 在目標 runtime 報錯，需查套件是否支援
  - 下一步：先嘗試換 v2.1.0，若仍失敗回 design.md 重議演算法選擇
```

然後停手，報告使用者。
