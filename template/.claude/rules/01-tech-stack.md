# 技術棧規範

> 這份是**空模板**。專案第一天花 30 分鐘填完，之後當成 AI coding agent 的硬限制。
> 填完後，凡違反的行為都應該反映到 `02-forbidden.md` 的 hook 規則裡。

---

## 語言分層（填入）

| 層級 | 語言 | 框架 | 位置 | 職責 |
|-----|------|------|------|------|
| Backend | <例：TypeScript> | <例：Hono> | <例：`server/`> | <例：HTTP routing> |
| Component/Business Logic | <例：TinyGo> | — | <例：`registry/components/`> | <例：業務邏輯 WASM> |
| Frontend | <例：React 19> | <例：Vite + Tailwind v4> | <例：`frontend/`> | <例：静態網頁> |
| CLI | <例：Node.js> | <例：commander> | <例：`cli/`> | <例：指令集> |
| SDK (Python) | <例：Python 3.10+> | — | <例：`python-sdk/`> | <例：HTTP wrapper + client-side crypto> |
| SDK (JS) | <例：TypeScript> | — | <例：`js-sdk/`> | <例：HTTP wrapper + Web Crypto> |

**規則**：越層 = 違規。例如 component 層出現 TypeScript，或 backend 層出現業務邏輯，都是違規。

---

## 資料儲存（填入）

| 儲存 | 用途 | Key 格式 / Schema |
|-----|------|------|
| <例：Cloudflare KV `CREDENTIALS_KV`> | <加密 credential> | <`{api_key}:cred:{name}`> |
| <例：Cloudflare R2 `WASM_BUCKET`> | <用戶自製 WASM> | <`{api_key}:cmp:{hash}`> |
| <例：PostgreSQL> | <主業務資料> | <schema 見 migrations/> |

---

## 加解密 / 認證（填入，若不適用可刪）

- **演算法**：<例：AES-GCM 256-bit>
- **加密位置**：<例：Client 端 SDK>
- **解密位置**：<例：Server 端 WASM primitive（透過 host function）>
- **Key 管理**：<例：`ENCRYPTION_KEY` 透過 Cloudflare secret，永不暴露給 WASM>

---

## 部署（填入）

- **Backend**：<例：Cloudflare Workers via Wrangler>
- **Frontend**：<例：Cloudflare Pages>
- **CI/CD**：<例：GitHub Actions>
- **網域結構**：<例：主 API 在 api.example.com，子服務在 {name}.example.com>

---

## 測試策略（填入）

- **Test runner**：<例：Vitest>
- **Pool**：<例：@cloudflare/vitest-pool-workers（for Workers）>
- **Coverage 目標**：<例：核心模組 80%+>
- **必做測試時機**：<例：每個 task 完成前必須有對應 test>

---

## 套件管理（填入）

- <例：pnpm 為主，少數歷史遺留用 npm>
- <例：Python 用 uv>
- <例：Go 用 go.mod>

---

## 版本 / Compatibility（填入）

- **Node.js**：<例：18+>
- **Python**：<例：3.10+>
- **Cloudflare Workers compatibility_date**：<例：2025-02-19>

---

## 常用指令（給 agent 參考）

```bash
# Backend dev server
<填入>

# 測試
<填入>

# 部署
<填入>

# WASM build（若適用）
<填入>
```

---

## 不使用的技術（明確列出避免誤用）

- **禁用**：<例：mongoose（改用 drizzle）>
- **禁用**：<例：moment.js（已過時，用 date-fns）>
- **禁用**：<例：Express（改用 Hono，Workers 相容）>
