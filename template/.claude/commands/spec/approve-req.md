---
description: 批准當前 spec 的 requirements.md，進入 design 階段
argument-hint: [feature-name，可省略，自動偵測]
---

# /spec:approve-req — 批准 requirements，進 design

## 你的任務

1. **確認批准範圍**：
   - 若 `$ARGUMENTS` 有值 → 對應 `.agents/specs/$ARGUMENTS/`
   - 若為空 → 從 git status 找最近修改的 requirements.md，或問使用者

2. **更新 requirements.md header**：
   ```
   > 狀態：✅ 已批准（YYYY-MM-DD）
   ```

3. **讀 requirements.md + 01-tech-stack.md + 03-architecture.md**

4. **建立 design.md**，基於 requirements 開始技術討論

## design.md 模板

```markdown
# Design: <feature-name>

> 狀態：🔄 討論中（等待 /spec:approve-design）
> 基於：requirements.md（已批准於 YYYY-MM-DD）

## Overview
<技術上要做什麼，一段話>

## Architecture
<ASCII 圖 or mermaid。畫出模組與資料流>

## Data Model
<KV schema / DB table / JSON shape / API payload>

## APIs / Interfaces
<對外暴露的 endpoint / function signature，用 TypeScript interface 或 OpenAPI 風格描述>

## 技術決策
### 決策 1: <標題>
- 採用：<A>
- 捨棄：<B>
- 原因：<為什麼>
- 影響：<下游怎麼配合>

## 非目標
- <明確不做的技術項>

## 風險 / 未知
- 風險：<可能出問題的地方>
  緩解：<怎麼處理>

## 對既有系統的影響
- 影響模組 X：<怎麼相容，是否需要 migration>
- 影響 SDD Y：<需要同步更新的其他 spec>

## 開放問題
- <設計上還沒決定的點>
```

## 討論流程（一問一答）

開始 design.md 初稿後，和使用者逐項討論：

第一問：「Architecture 圖這樣拆分合理嗎？」
第二問：「Data model 要怎麼存？有沒有既有的 KV/table 需要配合？」
第三問：「對外介面長什麼樣？」
第四問：「有沒有什麼風險/未知需要先講清楚？」
第五問：「對現有系統有什麼影響？」

## 完成後提示

```
📐 design.md 初稿完成：
.agents/specs/<feature>/design.md

請 review。完全 OK 時，輸入 /spec:approve-design 進入 tasks 階段。
```

## 禁止行為

- ❌ 沒讀 requirements.md 就寫 design
- ❌ 一次問超過 1-2 題
- ❌ 直接建 tasks.md（會跳關）
- ❌ 開始寫 code

## 若 requirements.md 還有問題

若使用者回應「requirements 還要改」，**不要**批准，回去修 requirements.md 繼續討論。
