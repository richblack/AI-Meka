#!/bin/bash
# .claude/hooks/session-start-load-sdd.sh
# SessionStart hook：啟動時注入當前進度、絕對禁令、SDD 位置
#
# 輸出走 stdout，會注入到 agent 的 context

set -o pipefail

cat <<'EOF'
============================================================
🚨 AI-Meka 工作規範（SessionStart 注入）
============================================================

📌 絕對鐵律（違反會被 pre-write / pre-bash hook 直接 block）：

  1. 任何 code 變動前必須先讀對應 SDD，按 .claude/rules/00-sdd-protocol.md
     的宣告格式回覆：
        📋 已讀 SDD：<清單>
        🎯 本次對應 task：<編號>
        📐 本次 task 的 SDD 規範摘要：<重點>
        🚧 執行範圍：修改/建立/刪除 <檔案>

  2. SDD 三關必須一關一關過：
        requirements.md → /spec:approve-req
        design.md      → /spec:approve-design
        tasks.md       → /task:run 或 /task:run-all

  3. 修改現有程式碼，不是新建資料夾重做

  4. 需求變動時先跑 /spec:impact，看全局影響再動手

  5. 每完成一個 task 立刻更新 tasks.md 的 [x]，正在做的標 [🔄]

  6. 技術棧硬約束在 .tech-constraints.yaml（違反會被 hook 擋）
     軟性說明在 .claude/rules/01-tech-stack.md

  7. Task 粒度：單 task 必須能在單次 session 完成，含 checkpoint
     細節見 .claude/rules/05-task-granularity.md

  8. TDD 協議：Task 標 [x] 前，對應的測試必須跑過且通過。
     主觀判斷「我做完了」不算，測試 pass 才算。
     細節見 .claude/rules/06-tdd-protocol.md

🔁 跨 Session 記憶合約（每次 session 必做）：

  □ 讀 .agents/specs/*/tasks.md 找 [🔄] 標記 → 知道做到哪
  □ 讀該 task 的 Checkpoint 區塊 → 知道子步驟進度
  □ 讀 .tech-constraints.yaml → 重新載入技術棧約束

  沒做完這三件事就動手 = 違反合約。

📋 任務開始前必做：

  1. 讀 .claude/rules/04-current-progress.md（當前進度）
  2. 讀 .tech-constraints.yaml（技術棧約束）
  3. 讀對應 task 的 SDD（requirements + design + tasks 三份）
  4. 做宣告（格式見 .claude/rules/00-sdd-protocol.md）

🎯 常用 slash commands：

  /spec:new <n>         ← 開新功能（啟動三層流程）
  /spec:approve-req        ← 批准 requirements
  /spec:approve-design     ← 批准 design
  /spec:impact <n>      ← 分析改動影響
  /spec:scope-check        ← 檢查 scope 是否超出 SDD
  /spec:status             ← 列出所有 spec 進度
  /task:run <id>           ← 執行單一 task
  /task:run-all            ← 執行全部 task（plan mode）
  /task:next               ← 執行下一個未完成 task
  /steering:add            ← 把教訓寫進 steering
  /steering:list           ← 列出所有規則

📚 詳細規範：

  .claude/rules/00-sdd-protocol.md       — SDD 三層協議
  .claude/rules/01-tech-stack.md         — 技術棧（說明）
  .claude/rules/02-forbidden.md          — 禁止清單（hook 強制）
  .claude/rules/03-architecture.md       — 架構規範
  .claude/rules/04-current-progress.md   — 當前進度
  .claude/rules/05-task-granularity.md   — Task 粒度紀律
  .claude/rules/06-tdd-protocol.md       — TDD 協議（task 標 [x] 前測試必須通過）
  .tech-constraints.yaml                 — 技術棧硬約束（hook 讀取）

============================================================
EOF

# 如果有 .tech-constraints.yaml，摘要顯示約束內容
if [[ -f ".tech-constraints.yaml" ]]; then
  echo ""
  echo "⚙️  技術棧約束（從 .tech-constraints.yaml）："
  echo ""

  # 顯示 description 區塊
  if command -v yq &> /dev/null; then
    DESC=$(yq -r '.description // ""' .tech-constraints.yaml 2>/dev/null)
    if [[ -n "$DESC" && "$DESC" != "null" ]]; then
      echo "$DESC" | head -10
      echo ""
    fi
    echo "  allowed_extensions:    $(yq -r '.allowed_extensions // [] | join(" ")' .tech-constraints.yaml 2>/dev/null)"
    echo "  forbidden_extensions:  $(yq -r '.forbidden_extensions // [] | join(" ")' .tech-constraints.yaml 2>/dev/null)"
  else
    # fallback：直接顯示前 30 行
    head -30 .tech-constraints.yaml | grep -v '^#' | grep -v '^$' | head -15
  fi
  echo ""
fi

# 如果有 04-current-progress.md 的具體內容，額外摘要
if [[ -f ".claude/rules/04-current-progress.md" ]]; then
  echo ""
  echo "📊 當前進度摘要（從 04-current-progress.md）："
  echo ""
  # 抓出前 50 行非空非註解的內容
  head -50 .claude/rules/04-current-progress.md | grep -v '^$' | grep -v '^>' | head -30
  echo ""
  echo "（完整內容：.claude/rules/04-current-progress.md）"
fi

# 偵測未完成 task（[🔄] 或 [ ]），提醒 agent
if [[ -d ".agents/specs" ]]; then
  IN_PROGRESS=$(grep -rl "\[🔄\]" .agents/specs/ 2>/dev/null | head -3)
  if [[ -n "$IN_PROGRESS" ]]; then
    echo ""
    echo "🔄 以下 SDD 有進行中的 task（優先處理）："
    echo "$IN_PROGRESS" | while read f; do
      echo "  - $f"
    done
    echo ""
  fi
fi

exit 0
