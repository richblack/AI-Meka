#!/bin/bash
# .claude/hooks/post-edit-check-tdd.sh
# PostToolUse hook for Write / Edit / MultiEdit
#
# 職責：偵測 agent 是否在 tasks.md 新增 [x] 標記，若是，提醒「測試是否跑過 + pass」
# 退出 code：0（不 block，只透過 stderr 注入提醒到 agent context）
#
# 為什麼不硬 block：
#   - tasks.md 正當的編輯也會觸發（例如新增 task）
#   - 硬 block agent 會被卡住無法繼續，體驗差
#   - 改用「注入提醒」方式，agent 下一輪推理時會看到，強制它在回覆裡自我檢核
#
# 配合 .claude/rules/06-tdd-protocol.md 一起運作。

set -o pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# 只處理 tasks.md
if [[ "$FILE_PATH" != *"/tasks.md" ]]; then
  exit 0
fi

# 抓本次編輯新加入的內容
NEW_CONTENT=$(echo "$INPUT" | jq -r '
  .tool_input.content
  // .tool_input.new_string
  // (.tool_input.edits // [] | map(.new_string // "") | join("\n"))
  // ""
')

# 偵測：本次 diff 是否把 "- [ ]" 或 "- [🔄]" 改成 "- [x]"？
# 簡化判斷：new_string 裡有 "[x]" 出現
if echo "$NEW_CONTENT" | grep -qE "^\s*-\s*\[x\]"; then
  # 再看看被標 [x] 的 task 附近有沒有 Test File 欄位
  # （這只是軟檢查，目的是給 agent 提醒）
  HAS_TEST_FILE=$(echo "$NEW_CONTENT" | grep -cE "Test File:" || echo "0")

  cat >&2 <<EOF

🧪 TDD Hook 檢查（by AI-Meka hook）
偵測到 tasks.md 新增 [x] 標記：${FILE_PATH}

強制自我檢核（請在你下一則回覆裡明確回報）：

  1. 被標 [x] 的 task 編號：<X.Y>
  2. 對應的 Test File 路徑：<從 tasks.md 的 Test File 欄位取>
  3. 本次 session 內有跑過該 Test File 嗎？<是/否>
  4. 執行結果：<pass / fail / 測試檔不存在 / 免測試>
  5. 若 pass：貼出測試輸出最後幾行作為證據
  6. 若 fail：立刻把 [x] 改回 [🔄] 或 [❌]，並說明原因
  7. 若「免測試（—）」：說明為什麼這個 task 不需要測試

協議來源：.claude/rules/06-tdd-protocol.md

未經測試驗證就標 [x] = 違反 TDD 協議。
主觀判斷「我做完了」不算，測試 pass 才算。

EOF
fi

exit 0
