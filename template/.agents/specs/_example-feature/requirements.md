# Requirements: User Login

> 狀態：✅ 已批准（範例，實際專案不會有這份，這是給 AI coding agent 看格式用的）
> 建立於：2026-04-20
> 批准於：2026-04-20

---

## Epic

讓註冊用戶能安全地用 email + 密碼登入系統，取得 session token，並能登出。這是所有私人功能的前置條件。

---

## User Stories

### US-1: 基本登入

**As a** 已註冊用戶
**I want** 用 email 和密碼登入
**So that** 可以存取我的私人資料

#### Acceptance Criteria (EARS)

- **WHEN** 用戶 POST `/login` 帶正確的 email + password **THE system SHALL** 回傳 200 + JWT token（有效期 15 分鐘）
- **WHEN** 用戶 POST `/login` 帶錯誤密碼 **THE system SHALL** 回傳 401 + 錯誤訊息「email 或密碼錯誤」（不透露是哪個錯）
- **WHEN** 用戶 POST `/login` 帶不存在的 email **THE system SHALL** 回傳 401 + 和錯誤密碼一樣的訊息（避免帳號列舉攻擊）
- **IF** 連續 5 次錯誤密碼（同一 email） **THEN THE system SHALL** 鎖定該帳號 15 分鐘
- **WHILE** 帳號處於鎖定狀態 **THE system SHALL** 回傳 429 + 「帳號暫時鎖定，請 X 分鐘後再試」
- **WHEN** email 未驗證 **THE system SHALL** 回傳 403 + 「請先驗證 email」

---

### US-2: 登出

**As a** 已登入用戶
**I want** 登出
**So that** 確保我的 session 不會被別人用

#### Acceptance Criteria

- **WHEN** 用戶 POST `/logout` 帶有效 token **THE system SHALL** 把該 token 加入黑名單並回傳 204
- **WHILE** token 在黑名單內 **THE system SHALL** 拒絕該 token 的任何請求（回 401）
- **WHERE** token 已過期（15 分鐘） **THE system SHALL** 不需要加黑名單（自然失效）

---

### US-3: Token Refresh

**As a** 已登入用戶
**I want** 在 token 即將到期時自動續期
**So that** 不會一直被踢出需要重新登入

#### Acceptance Criteria

- **WHEN** 用戶 POST `/refresh` 帶 refresh token **THE system SHALL** 回傳新的 access token（15 分鐘有效）
- **WHEN** refresh token 過期（30 天）**THE system SHALL** 回傳 401 要求重新登入
- **IF** refresh token 已被使用過（一次性） **THEN THE system SHALL** 拒絕並把關聯的所有 token 加黑名單（懷疑被盜用）

---

## Non-goals（明確不做的事）

- ❌ **不做**第三方 OAuth（Google / GitHub 登入）— 獨立 spec 處理
- ❌ **不做**雙因素認證（2FA）— 獨立 spec 處理
- ❌ **不做**密碼重設流程 — 獨立 spec 處理（`forgot-password`）
- ❌ **不做**記住我 / 長效 session — 用 refresh token 機制足夠
- ❌ **不做**Session 管理 UI（列出已登入裝置）— 未來需求

---

## 開放問題

（討論過已解決，留著供參考）

- ~~Token 要放 header 還是 cookie？~~ → 決議：Authorization header，避免 CSRF
- ~~密碼雜湊演算法？~~ → 決議：採用業界推薦的 memory-hard 演算法
- ~~Refresh token 存哪？~~ → 決議：獨立 store + rotation

---

## 給 reviewer 的重點

- 安全性第一：避免帳號列舉、暴力破解
- 錯誤訊息故意模糊（不透露是 email 不存在還是密碼錯）
- Token rotation 防盜用

通過 review 後，進入 design.md 技術設計階段。
