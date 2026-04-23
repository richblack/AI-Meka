#!/bin/bash
# .claude/hooks/pre-write-guard.sh
# PreToolUse guard for Write / Edit / MultiEdit
#
# 職責：擋下違反 AI-Meka rules 的檔案寫入
# 退出 code：
#   0 = 允許
#   2 = 擋下（stderr 訊息會回傳給 agent）
#
# 依賴：jq（以及 yq 若要讀 .tech-constraints.yaml）
#
# 兩層檢查：
#   1. 通用層：讀 .tech-constraints.yaml，每個 project 自己定義的技術棧約束
#   2. AI-Meka 層：流程禁令（寫 SDD 要先 /spec:new 等）
#   3. 專案特定層：往下的專案特定 grep 規則

set -o pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
CONTENT=$(echo "$INPUT" | jq -r '
  .tool_input.content
  // .tool_input.new_string
  // (.tool_input.edits // [] | map(.new_string // "") | join("\n"))
  // ""
')

block() {
  local rule="$1"
  local reason="$2"
  local fix="$3"
  cat >&2 <<EOF
❌ BLOCKED by AI-Meka rules
違反項：${rule}
檔案：${FILE_PATH}
原因：${reason}
正確做法：${fix}
參考：.claude/rules/02-forbidden.md 或 .tech-constraints.yaml
EOF
  exit 2
}

# ═════════════════════════════════════════════════════════════════════════════
# 第一層：讀 .tech-constraints.yaml（通用層，每 project 自己填）
# ═════════════════════════════════════════════════════════════════════════════

CONSTRAINTS_FILE=".tech-constraints.yaml"

if [[ -f "$CONSTRAINTS_FILE" ]]; then
  # 若有 yq 可用，做更精細的 YAML 解析
  # 若沒 yq，fallback 用 grep + sed 簡單解析
  HAS_YQ=$(command -v yq &> /dev/null && echo "yes" || echo "no")

  # ─────────────────────────────────────────────────────────────────
  # 檢查 1：forbidden_extensions（副檔名黑名單）
  # ─────────────────────────────────────────────────────────────────
  if [[ "$HAS_YQ" == "yes" ]]; then
    FORBIDDEN_EXTS=$(yq -r '.forbidden_extensions[]?' "$CONSTRAINTS_FILE" 2>/dev/null)
  else
    # 粗糙 fallback：抓 forbidden_extensions: 區塊下的 - .xxx
    FORBIDDEN_EXTS=$(awk '/^forbidden_extensions:/{flag=1;next}/^[a-z_]+:/{flag=0}flag' "$CONSTRAINTS_FILE" | grep -E "^\s*-\s+\." | sed 's/^\s*-\s*//' | tr -d ' ')
  fi

  for ext in $FORBIDDEN_EXTS; do
    if [[ "$FILE_PATH" == *"$ext" ]]; then
      block "tech-constraints.forbidden_extensions" \
        "這個專案禁止副檔名 $ext（見 .tech-constraints.yaml）" \
        "改用允許的副檔名；若需要調整約束，修改 .tech-constraints.yaml 並跟使用者確認"
    fi
  done

  # ─────────────────────────────────────────────────────────────────
  # 檢查 2：allowed_extensions（副檔名白名單，若有設定）
  # ─────────────────────────────────────────────────────────────────
  if [[ "$HAS_YQ" == "yes" ]]; then
    ALLOWED_EXTS=$(yq -r '.allowed_extensions[]?' "$CONSTRAINTS_FILE" 2>/dev/null)
  else
    ALLOWED_EXTS=$(awk '/^allowed_extensions:/{flag=1;next}/^[a-z_]+:/{flag=0}flag' "$CONSTRAINTS_FILE" | grep -E "^\s*-\s+\." | sed 's/^\s*-\s*//' | tr -d ' ')
  fi

  if [[ -n "$ALLOWED_EXTS" ]]; then
    MATCHED="no"
    for ext in $ALLOWED_EXTS; do
      if [[ "$FILE_PATH" == *"$ext" ]]; then
        MATCHED="yes"
        break
      fi
    done
    # 排除沒有副檔名的檔案（例：Makefile、Dockerfile）
    BASENAME=$(basename "$FILE_PATH")
    if [[ "$BASENAME" =~ \. ]]; then
      if [[ "$MATCHED" == "no" ]]; then
        # 取出實際副檔名
        ACTUAL_EXT=".${FILE_PATH##*.}"
        block "tech-constraints.allowed_extensions" \
          "這個專案只允許指定副檔名：$(echo $ALLOWED_EXTS | tr '\n' ' ')；你用了 $ACTUAL_EXT" \
          "改用允許清單中的副檔名；若真的需要新增，修改 .tech-constraints.yaml 並跟使用者確認"
      fi
    fi
  fi

  # ─────────────────────────────────────────────────────────────────
  # 檢查 3：forbidden_path_patterns
  # ─────────────────────────────────────────────────────────────────
  if [[ "$HAS_YQ" == "yes" ]]; then
    FORBIDDEN_PATHS=$(yq -r '.forbidden_path_patterns[]?' "$CONSTRAINTS_FILE" 2>/dev/null)
  else
    FORBIDDEN_PATHS=$(awk '/^forbidden_path_patterns:/{flag=1;next}/^[a-z_]+:/{flag=0}flag' "$CONSTRAINTS_FILE" | grep -E '^\s*-\s+' | sed 's/^\s*-\s*//' | sed 's/^"//;s/"$//')
  fi

  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
      block "tech-constraints.forbidden_path_patterns" \
        "這個專案禁止路徑 pattern: $pattern" \
        "改用允許的路徑；若約束要調整，修改 .tech-constraints.yaml"
    fi
  done <<< "$FORBIDDEN_PATHS"

  # ─────────────────────────────────────────────────────────────────
  # 檢查 4：forbidden_imports（在檔案內容中搜）
  # ─────────────────────────────────────────────────────────────────
  if [[ -n "$CONTENT" ]]; then
    if [[ "$HAS_YQ" == "yes" ]]; then
      FORBIDDEN_IMPORTS=$(yq -r '.forbidden_imports[]?' "$CONSTRAINTS_FILE" 2>/dev/null)
    else
      FORBIDDEN_IMPORTS=$(awk '/^forbidden_imports:/{flag=1;next}/^[a-z_]+:/{flag=0}flag' "$CONSTRAINTS_FILE" | grep -E '^\s*-\s+' | sed 's/^\s*-\s*//' | sed 's/^"//;s/"$//')
    fi

    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if echo "$CONTENT" | grep -qE "$pattern"; then
        block "tech-constraints.forbidden_imports" \
          "偵測到禁止的 import/依賴: $pattern" \
          "這個專案不使用此依賴；若真的需要，修改 .tech-constraints.yaml 並跟使用者確認"
      fi
    done <<< "$FORBIDDEN_IMPORTS"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# 第二層：AI-Meka 通用流程禁令（所有專案適用，寫死在 hook 裡）
# ═════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# 規則 1.4：禁止自行在 .agents/specs/ 下建新頂層 SDD 目錄
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$FILE_PATH" == *".agents/specs/"* ]]; then
  # 抓出 .agents/specs/ 後的第一個目錄名
  SPEC_DIR=$(echo "$FILE_PATH" | sed -n 's|.*\.agents/specs/\([^/]*\)/.*|\1|p')

  # 如果寫入的是新目錄下的 requirements.md，視為可能的新 spec 建立
  if [[ "$FILE_PATH" == *"/requirements.md" && -n "$SPEC_DIR" ]]; then
    # 檢查此 spec 目錄是否已存在
    if [[ ! -d ".agents/specs/$SPEC_DIR" ]]; then
      # 是全新的 spec 目錄，需要確認是否透過 /spec:new 建立
      # 透過檢查是否有對應的 .sdd-scaffold-marker
      if [[ ! -f "/tmp/sdd-scaffold-${SPEC_DIR}.marker" ]]; then
        block "1.4" \
          "偵測到在 .agents/specs/ 下建立新 SDD 目錄 '$SPEC_DIR'，但未透過 /spec:new 授權" \
          "請用 /spec:new $SPEC_DIR 走正式流程，或與使用者確認後建立 marker：touch /tmp/sdd-scaffold-${SPEC_DIR}.marker"
      fi
    fi
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 規則 3.3：禁止 hard-code secrets / API keys
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx|go|py|rs|java)$ ]]; then
  # 偵測常見 API key prefix
  if echo "$CONTENT" | grep -qE "(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|ghs_[A-Za-z0-9]{20,}|AIza[A-Za-z0-9_-]{35}|xox[abp]-[A-Za-z0-9-]{20,})"; then
    block "3.3" \
      "偵測到疑似 hard-code 的 API key / secret（OpenAI / GitHub / Google / Slack 等格式）" \
      "secret 必須透過環境變數或 secret manager，禁止寫死在 code"
  fi

  # 偵測明顯的密碼字串
  if echo "$CONTENT" | grep -qiE "(password|passwd|secret)[[:space:]]*[=:][[:space:]]*['\"][a-zA-Z0-9!@#\$%^&*]{8,}['\"]"; then
    # 排除測試用的假密碼（含 test / fake / example / dummy）
    if ! echo "$CONTENT" | grep -qiE "(test|fake|example|dummy|xxx+|placeholder)"; then
      block "3.3" \
        "偵測到疑似 hard-code 密碼" \
        "用環境變數或 secret manager；若是測試資料，請明確標記為 test/fake/dummy"
    fi
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# 第三層：專案特定禁令（填入，或交給 .tech-constraints.yaml）
# ═════════════════════════════════════════════════════════════════════════════
# 以下是範例，複製到新專案時按實際需求改寫。
#
# ※ 建議：簡單的副檔名/路徑 pattern 寫進 .tech-constraints.yaml 就好，
#   只有需要複雜邏輯（例如「特定 API 只能在特定檔案使用」）才寫在這裡。

# ─────────────────────────────────────────────────────────────────────────────
# 範例規則 2.2：特定路徑下禁用某個 API（需要 path + content 組合判斷）
# ─────────────────────────────────────────────────────────────────────────────
# if [[ "$FILE_PATH" == *"src/routes/"* && "$FILE_PATH" == *.ts ]]; then
#   # 範例：routes 層不准直接做加解密，必須呼叫專責模組
#   if echo "$CONTENT" | grep -qE "crypto\.subtle\.(encrypt|decrypt)"; then
#     block "2.2" \
#       "routes 層禁止直接操作 crypto，需呼叫 lib/crypto.ts 封裝" \
#       "把加解密移到 lib/crypto.ts，routes 只呼叫 high-level API"
#   fi
# fi

# ─────────────────────────────────────────────────────────────────────────────
# 規則 2.3：禁止建立平行複製目錄（通用，保留）
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$FILE_PATH" =~ /[a-z_-]+[-_](v2|v3|new|worker|backup|temp|copy)/ ]]; then
  # 排除明確的暫存檔
  if [[ ! "$FILE_PATH" =~ /(tmp|tmpfiles|\.temp)/ ]]; then
    block "2.3" \
      "禁止為既有模組建立平行目錄（*-v2 / *-worker / new-* / *-backup / *-copy）" \
      "直接修改原本的目錄；需要版本管理用 git branch；需要比較用 git diff"
  fi
fi

exit 0
