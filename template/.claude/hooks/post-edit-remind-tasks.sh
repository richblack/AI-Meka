#!/bin/bash
# .claude/hooks/post-edit-remind-tasks.sh
# PostToolUse hook for Write / Edit / MultiEdit
#
# 職責：改完 code 後立刻提醒 agent 更新對應 tasks.md
# 退出 code：不 block，只提醒（exit 0）

set -o pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# 只針對程式碼檔案提醒（不含 tasks.md / rules/*.md 本身）
if [[ "$FILE_PATH" =~ \.(go|ts|tsx|js|jsx|py|rs|java|kt|swift)$ ]] && [[ "$FILE_PATH" != *"tasks.md"* ]]; then
  cat >&2 <<EOF

📌 PostEdit 提醒（by AI-Meka hook）
剛修改了：${FILE_PATH}

下一步強制動作：
  1. 找到對應的 .agents/specs/*/tasks.md
  2. 若這個 task 正在進行 → 標記 [🔄]
     若完成 → 立刻改成 [x]
  3. 若發現新的 sub-task → 立刻加入 tasks.md
  4. 不要等到 session 結束才批次更新

違反 SDD 協議會在 Stop hook 被再次提醒。建議現在就處理。

EOF
fi

# 若改的是 SDD 檔案本身（requirements/design/tasks.md），提醒要思考對 code 的影響
if [[ "$FILE_PATH" =~ \.agents/specs/.+/(requirements|design|tasks)\.md$ ]]; then
  SPEC_TYPE=$(echo "$FILE_PATH" | sed -n 's|.*/\([a-z]*\)\.md$|\1|p')
  cat >&2 <<EOF

📝 SDD 變更提醒（by AI-Meka hook）
剛修改了 SDD 檔案：${FILE_PATH}（${SPEC_TYPE}）

思考一下：
  - 這次變更是否超出原 scope？（若是，應該走 /spec:scope-check）
  - 下游的 code 是否需要同步更新？（若是，走 /spec:impact 看範圍）
  - 此變更是否需要使用者重新批准？（若是，啟動對應的 /spec:approve-* 流程）

EOF
fi

exit 0
