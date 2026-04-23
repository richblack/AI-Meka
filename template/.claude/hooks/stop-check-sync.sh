#!/bin/bash
# .claude/hooks/stop-check-sync.sh
# Stop hook
#
# 職責：session 結束前檢查 code vs specs 是否同步
# 退出 code：不 block，只警告

set -o pipefail

# 檢查 .agents/specs 下本次 session 是否有變動
SPECS_DIFF=$(git status --porcelain -- '.agents/specs/' 2>/dev/null | head -20)
CODE_DIFF=$(git status --porcelain -- '*.go' '*.ts' '*.tsx' '*.js' '*.py' 2>/dev/null | head -20)

if [[ -n "$CODE_DIFF" && -z "$SPECS_DIFF" ]]; then
  cat >&2 <<EOF

⚠️  Stop hook 警告（by AI-Meka hook）

本 session 有程式碼變動，但 .agents/specs/ 下的 SDD 文件沒有任何變動。

未 commit 的程式碼變動：
$(echo "$CODE_DIFF" | head -10)

請在結束前確認：
  1. 對應的 tasks.md 是否已更新 [x]？
  2. 是否有架構變動需要更新 design.md？
  3. 是否有 scope 變動需要更新 requirements.md？

SDD 協議要求：code 和 SDD 必須同步更新。
參考：.claude/rules/00-sdd-protocol.md

EOF
fi

# 若 tasks.md 有未 commit 的變動，提醒 commit
TASKS_DIFF=$(git status --porcelain -- '.agents/specs/**/tasks.md' 2>/dev/null | head -5)
if [[ -n "$TASKS_DIFF" ]]; then
  cat >&2 <<EOF

📝 提醒：tasks.md 有未 commit 的變動
$(echo "$TASKS_DIFF")
記得在結束前 commit，讓團隊同步進度。

EOF
fi

# 檢查是否還有 [🔄] 標記的 task（表示有 task 在進行中但沒關掉）
IN_PROGRESS=$(grep -rn '\[🔄\]' .agents/specs/ 2>/dev/null | head -5)
if [[ -n "$IN_PROGRESS" ]]; then
  cat >&2 <<EOF

🔄 提醒：有 task 標記為「進行中」但 session 即將結束

$IN_PROGRESS

若已完成 → 改成 [x]
若暫停 → 改成 [⏸️] 並加註原因
若失敗 → 改成 [❌] 並加註原因

不要留 [🔄] 在 session 之間，會讓下次 resume 時狀態不清楚。

EOF
fi

exit 0
