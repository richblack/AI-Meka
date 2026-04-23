#!/bin/bash
# .claude/hooks/pre-bash-guard.sh
# PreToolUse guard for Bash
#
# 職責：擋下危險 shell 指令
# 退出 code：0 = 允許，2 = 擋下

set -o pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

block() {
  local rule="$1"
  local reason="$2"
  local fix="$3"
  cat >&2 <<EOF
❌ BLOCKED by AI-Meka rules
違反項：${rule}
指令：${CMD}
原因：${reason}
正確做法：${fix}
參考：.claude/rules/02-forbidden.md
EOF
  exit 2
}

# ═════════════════════════════════════════════════════════════════════════════
# 通用危險指令
# ═════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# 規則 4.2：危險的 rm -rf
# ─────────────────────────────────────────────────────────────────────────────
if echo "$CMD" | grep -qE "rm[[:space:]]+-rf?[[:space:]]+(/|/\*|~|\\\$HOME|\\\$\{HOME\})"; then
  block "4.2" \
    "偵測到對根目錄 / 家目錄的遞迴刪除" \
    "明確指定要刪的子目錄；若真的要清整個 repo，先 git commit 備份再手動確認"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 規則 4.1：force push 到 main/master
# ─────────────────────────────────────────────────────────────────────────────
if echo "$CMD" | grep -qE "git[[:space:]]+push.*(-f|--force|--force-with-lease).*(main|master|trunk)"; then
  block "4.1" \
    "禁止 force push 到 main/master" \
    "用 feature branch + PR；若真要 force push，手動執行並承擔責任"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 規則 1.4：mkdir 在 .agents/specs/ 下建頂層目錄
# ─────────────────────────────────────────────────────────────────────────────
if echo "$CMD" | grep -qE "mkdir([[:space:]]+-p)?[[:space:]]+[^|&;]*\.agents/specs/[a-zA-Z0-9_-]+[[:space:]]*(\$|[|&;])"; then
  # 只擋在 .agents/specs/ 下直接建新目錄的情況
  SPEC_NAME=$(echo "$CMD" | sed -n 's|.*\.agents/specs/\([a-zA-Z0-9_-]*\).*|\1|p')
  if [[ -n "$SPEC_NAME" && ! -d ".agents/specs/$SPEC_NAME" ]]; then
    if [[ ! -f "/tmp/sdd-scaffold-${SPEC_NAME}.marker" ]]; then
      block "1.4" \
        "偵測到 mkdir 在 .agents/specs/ 下建新 SDD 目錄 '$SPEC_NAME'，未透過 /spec:new 授權" \
        "請用 /spec:new $SPEC_NAME 走正式流程"
    fi
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# 專案特定禁令（填入）
# ═════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# 規則 2.3：禁止建立既有模組的平行目錄
# ─────────────────────────────────────────────────────────────────────────────
if echo "$CMD" | grep -qE "mkdir.*/[a-z_-]+[-_](v2|v3|new|worker|backup|copy)/"; then
  block "2.3" \
    "禁止為既有模組建立平行目錄" \
    "直接改原目錄即可；需版本管理用 git branch"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 範例：禁止特定套件安裝（若專案明確禁用某個依賴）
# ─────────────────────────────────────────────────────────────────────────────
# if echo "$CMD" | grep -qE "(npm|pnpm|yarn)[[:space:]]+add[[:space:]]+moment"; then
#   block "2.4" \
#     "偵測到要安裝被禁用的套件 moment" \
#     "改用 date-fns；若有特殊需求，先與使用者確認"
# fi

exit 0
