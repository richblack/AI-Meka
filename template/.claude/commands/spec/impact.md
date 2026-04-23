---
description: 分析一個 SDD 或 code 變更的影響範圍，避免頭痛醫頭
argument-hint: <feature-name 或 檔案路徑>
---

# /spec:impact — 影響分析

使用者想改 `$ARGUMENTS`，但想先看全局影響再動手。

## 你的任務

**絕對不要直接開始改**。先做完整影響分析，列出範圍，等使用者確認哪些要一起改，才動手。

### Step 1：辨識目標

如果 `$ARGUMENTS` 是：
- **feature name**（如 `user-login`）→ 讀 `.agents/specs/user-login/` 底下所有檔案
- **檔案路徑**（如 `src/auth.ts`）→ 讀該檔案，找出它屬於哪個 spec

### Step 2：反向搜尋引用

用 `grep -rn` 找：
1. 其他 SDD 的 `design.md` / `tasks.md` 是否引用了這個 feature / 檔案
2. Code 中是否 import / call 了這個 feature 暴露的介面
3. `CLAUDE.md` / `.claude/rules/` 是否提到

### Step 3：列出影響清單

輸出格式：

```markdown
# Impact Analysis: $ARGUMENTS

## 目標變更
<使用者想改什麼>

## 受影響的 SDD
- `.agents/specs/xxx/` — <怎麼影響>
- `.agents/specs/yyy/` — <怎麼影響>

## 受影響的 code
- `src/a.ts` — <怎麼影響，哪個 function / 哪段 code>
- `src/b.ts` — <...>

## 受影響的 test
- `tests/a.test.ts` — <...>

## 受影響的 infra / config
- `wrangler.toml` — <...>
- `.env.example` — <...>

## 未受影響但需注意
- <看似相關但其實不會壞的模組>

## 建議的修改順序
1. <先改什麼>
2. <再改什麼>
3. <最後驗證什麼>

## 風險評估
- 🔴 高：<會破壞現有 flow 的改動>
- 🟡 中：<需要 migration 的資料變動>
- 🟢 低：<純內部重構>

## 建議的 SDD 動作
- [ ] 更新 `.agents/specs/xxx/design.md`
- [ ] 新增 task 到 `.agents/specs/xxx/tasks.md`
- [ ] 或：開新 spec（若變動超出 scope，建議 /spec:scope-check）
```

### Step 4：等使用者確認

**不要**列完清單就衝去改。等使用者看完影響後決定：
- 「範圍可以接受，按建議順序改」→ 開始走對應 /spec:approve-* 流程
- 「影響太大，拆成新 spec」→ 走 /spec:new
- 「影響太大，暫緩」→ 停手

## 禁止行為

- ❌ 只看當前 feature，不做跨 spec 搜尋
- ❌ 只看 code，不看 SDD
- ❌ 分析完直接改（必須等批准）
- ❌ 跳過風險評估
