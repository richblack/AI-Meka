# Testing Skeleton

> 新專案複製整包 `testing-skeleton/` 內容到 project root，就有完整的測試環境。
> 配合 `.claude/rules/06-tdd-protocol.md`：每個 task 必填 Test File，測試 pass 才能標 [x]。

---

## 包含什麼

| 層級 | 工具 | 位置 |
|-----|------|------|
| Unit | Vitest | `tests/unit/**/*.test.ts` |
| Integration（Cloudflare Workers 本地模擬） | Miniflare + Vitest | `tests/integration/**/*.test.ts` |
| E2E（瀏覽器 / CLI） | Playwright | `tests/e2e/**/*.spec.ts` |
| Test fixtures | 純 JSON / TS | `tests/fixtures/` |

---

## 安裝

```bash
# 從 AI-Meka template 複製到新 project
cp -R /path/to/AI-Meka/template/testing-skeleton/. ./

# 安裝依賴
pnpm install

# 安裝 Playwright 瀏覽器
pnpm exec playwright install --with-deps chromium
```

---

## 指令

```bash
pnpm test            # 跑所有測試（unit + integration + e2e）
pnpm test:unit       # 只跑 unit
pnpm test:int        # 只跑 integration（Miniflare）
pnpm test:e2e        # 只跑 e2e（Playwright）
pnpm test:watch      # watch mode（只 unit + int）
pnpm test:coverage   # 產 coverage 報告
```

---

## 在 AI-Meka 流程中怎麼用

每個 task 在 `tasks.md` 寫：

```markdown
- [ ] 1.3 實作 login service
  - Test File: `tests/unit/login.test.ts`
  - 驗收：所有 EARS criteria 的 test cases pass
```

agent 做完後：

```bash
# 1. 跑對應的 Test File
pnpm vitest run tests/unit/login.test.ts

# 2. 看到綠燈才把 [ ] 改成 [x]
# 3. post-edit-check-tdd.sh hook 會要求你回報執行結果
```

若不跑測試直接標 [x]，TDD hook 會在 stderr 注入提醒，下一輪推理會看到強制自我檢核的要求。

---

## 不用 Cloudflare Workers 的專案

只用 Vitest unit + Playwright e2e 也完全可以。刪掉 `tests/integration/` 和 `vitest.config.ts` 裡的 workers pool 設定即可。

整合測試可改用：
- Node HTTP server 直接啟動
- Testcontainers（DB / Redis）
- MSW（mock network）

相同協議，不同實作。
