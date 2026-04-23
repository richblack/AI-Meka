# Design: User Login

> 狀態：✅ 已批准（範例）
> 基於：requirements.md（已批准於 2026-04-20）
> 批准於：2026-04-20

---

## Overview

實作 email + 密碼登入系統，包含 JWT token 機制、帳號鎖定、token refresh。採 access/refresh token 雙 token 模式，避免長效 JWT 被盜用的風險。

---

## Architecture

```
Client (Web/Mobile)
    │
    │ POST /login {email, password}
    ▼
[Auth Service (HTTP API)]
    │
    ├─► [Password verifier] ── compare with stored hash
    │
    ├─► [KV: USERS]            ── 讀 user record
    ├─► [KV: LOGIN_ATTEMPTS]   ── 讀/寫錯誤次數
    ├─► [KV: TOKEN_BLACKLIST]  ── 登出後加黑名單
    │
    └─► [Refresh Token Store] ── refresh token (with rotation)
                │
                ▼
            回傳 { access_token, refresh_token }
```

模組切分：
- `auth-service/src/routes/` — HTTP routes
- `auth-service/src/services/` — login / logout / refresh business logic
- `auth-service/src/lib/` — JWT signer / password hasher / rate limiter

---

## Data Model

### KV: USERS

Key: `user:{email_hashed}`
Value:
```json
{
  "id": "usr_xxx",
  "email": "user@example.com",
  "password_hash": "<memory-hard hash>",
  "email_verified": true,
  "created_at": "2026-01-01T00:00:00Z"
}
```

（email 做 SHA256 作為 key 避免洩漏，實際 email 明文存 value 方便查詢）

### KV: LOGIN_ATTEMPTS

Key: `login_attempts:{email_hashed}`
Value:
```json
{
  "failed_count": 3,
  "last_failed_at": "2026-04-20T10:15:00Z",
  "locked_until": null
}
```

TTL: 15 分鐘（自動清理）

### KV: TOKEN_BLACKLIST

Key: `blacklist:{jti}`  （JWT 的 jti claim）
Value: `true`
TTL: access_token 剩餘有效期

### Refresh Token Store

Key: `refresh:{token_id}`
Value:
```json
{
  "user_id": "usr_xxx",
  "issued_at": "2026-04-20T10:00:00Z",
  "used": false,
  "family_id": "fam_xxx"
}
```

TTL: 30 天

**Rotation 機制**：每次使用 refresh token 就標記 `used: true` 並發新 token。若偵測到已 used 的 refresh token 被再次使用（盜用跡象），把同 `family_id` 的所有 token 全部作廢。

---

## APIs / Interfaces

### POST /login

Request:
```ts
interface LoginRequest {
  email: string;
  password: string;
}
```

Response (200):
```ts
interface LoginResponse {
  access_token: string;   // JWT, 15min
  refresh_token: string;  // opaque, 30d
  expires_in: 900;        // seconds
}
```

Error responses:
- 401: `{ error: "email 或密碼錯誤" }` （包含 email 不存在情況）
- 403: `{ error: "請先驗證 email" }`
- 429: `{ error: "帳號暫時鎖定，請 X 分鐘後再試", retry_after: 720 }`

### POST /logout

Request: `Authorization: Bearer <access_token>`
Response: 204 No Content

### POST /refresh

Request:
```ts
interface RefreshRequest {
  refresh_token: string;
}
```

Response (200): 同 LoginResponse

---

## 技術決策

### 決策 1：採用 memory-hard password hashing

- **採用**：業界當前推薦的 memory-hard 演算法（專案依實際技術棧填入具體套件）
- **捨棄**：純 CPU-bound 的舊演算法
- **原因**：抗 GPU / ASIC 攻擊更強
- **影響**：需新增對應 dependency；runtime 若有 CPU 時間限制需調整參數

### 決策 2：Access + Refresh 雙 token

- **採用**：短效 access token（15min）+ 長效 refresh token（30d，rotation）
- **捨棄**：單一長效 token
- **原因**：access token 放 header 傳送頻繁，短效降低盜用風險；refresh token 只在續期時用，且一次性，盜用可偵測
- **影響**：client 端要實作 refresh 邏輯；後端多一個 token store 實例

### 決策 3：Email 雜湊當 KV key

- **採用**：`sha256(email)` 當 key，明文 email 放 value
- **捨棄**：明文 email 當 key
- **原因**：避免從 KV list 操作洩漏用戶清單
- **影響**：每次查找多一次 hash 運算（可忽略）

### 決策 4：錯誤訊息不透露帳號是否存在

- **採用**：email 不存在和密碼錯誤回同樣的 401 訊息
- **理由**：防帳號列舉攻擊（attacker 用常見 email 列表試錯，根據回應差異知道哪些 email 有註冊）

---

## 非目標

- 不做 session 管理 UI（查看 / 踢出其他裝置）
- 不做登入歷史紀錄
- 不做 IP 黑名單
- 不做圖形驗證碼（5 次鎖定機制已經夠）

---

## 風險 / 未知

### 風險 1：Token store 依賴
- **問題**：Refresh token 存獨立 store，store 掛了登入續期會失敗
- **緩解**：Store 掛時降級為「重新登入」而非擋全部請求
- **監控**：connection error 達 1%/min 發警報

### 風險 2：Password hashing CPU 成本
- **問題**：Memory-hard 演算法比舊的慢，部分 runtime 有 CPU 時間限制
- **緩解**：調整演算法參數（memory, iterations）在 runtime 預算內
- **已驗證**：在目標 runtime 上落在預算內

### 未知 1：Token 黑名單膨脹
- **問題**：大量用戶登出會讓 TOKEN_BLACKLIST 膨脹
- **處理**：用 TTL = token 剩餘有效期，最多 15 分鐘後自動清
- **監控**：每小時採樣 size

---

## 對既有系統的影響

- **影響主要 API gateway**：需要檢查 Authorization header，呼叫 auth-service 驗證 token。新增中間件。
- **影響 `.claude/rules/01-tech-stack.md`**：新增「auth-service 為 TypeScript HTTP service」條目
- **影響 CLI**：`cli login` / `cli logout` 指令要實作，存 token 到 `~/.myapp/session`
- **影響 SDK**：Python/JS SDK 要處理 401 自動 refresh

相關 SDD：
- `.agents/specs/rate-limiting/` — 和本 spec 的鎖定機制有重疊，需確認邊界
- `.agents/specs/cli-config/` — 和本 spec 的 token 儲存有關

---

## 開放問題

- ~~Password hashing 參數要多保守？~~ → 已驗證在 runtime 預算內
- ~~要不要記錄登入 IP？~~ → 先不做（Non-goal），有需要再加
- ~~Refresh token 放哪？~~ → 獨立 store（Rotation 需要原子性 compare-and-swap）
