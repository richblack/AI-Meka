---
description: 啟動新功能的 SDD 三層流程（requirements → design → tasks）
argument-hint: <feature-name-kebab-case>
---

# /spec:new — 啟動新功能

使用者要開始一個新功能，功能名稱：`$ARGUMENTS`

## 你的任務

1. **建立 SDD 目錄**：`.agents/specs/$ARGUMENTS/`
2. **建立 marker**：`touch /tmp/sdd-scaffold-$ARGUMENTS.marker`（授權 hook 允許此目錄建立）
3. **只建立 requirements.md**（不建 design.md 和 tasks.md，避免跳關）
4. **和使用者一問一答討論需求**，絕對不要一次吐 10 個問題
5. **requirements.md 使用 EARS 格式**

## requirements.md 模板

```markdown
# Requirements: $ARGUMENTS

> 狀態：🔄 討論中（等待 /spec:approve-req）
> 建立於：<今天日期>

## Epic
<一句話描述這個 feature 的商業價值。與使用者討論後填入>

## User Stories

### US-1: <標題>
**As a** <角色>
**I want** <能力>
**So that** <價值>

#### Acceptance Criteria (EARS)
- WHEN <事件> THE system SHALL <回應>
- WHILE <狀態> THE system SHALL <行為>
- IF <前置條件> THEN THE system SHALL <行為>

## Non-goals（明確不做的事）
- <避免範圍蔓延>

## 開放問題
- <還需要討論的點>
```

## 討論流程（一問一答，不要一次問多題）

第一問：「這個 feature 要解決什麼問題？誰會用？」
等使用者回答後，再問下一題。

第二問：「核心 User Story 是什麼？用 As a / I want / So that 三句話描述」

第三問：「成功的標準是什麼？（幫忙整理成 EARS 格式的 WHEN/WHILE/IF）」

第四問：「有沒有什麼明確不做的事？（Non-goals 很重要，避免範圍蔓延）」

每問完一題，把答案寫進 requirements.md 的對應 section，**然後暫停**，等使用者繼續或補充。

## 完成後的提示

把 requirements.md 寫到一個段落後，告訴使用者：

```
📋 requirements.md 初稿完成：
.agents/specs/$ARGUMENTS/requirements.md

請 review，回饋後我會修正。
完全 OK 時，輸入 /spec:approve-req 進入 design 階段。
```

## 禁止行為

- ❌ 不要一次問超過 1 題
- ❌ 不要自行填入使用者沒講過的假設
- ❌ 不要順便建 design.md 或 tasks.md（會被 hook 擋，也違反流程）
- ❌ 不要開始寫 code
