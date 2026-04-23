#!/bin/bash
# queue-runner.sh — AI-Meka 生產線主管
#
# 職責：
#   1. 讀 queue.md，找下一個未執行的 project
#   2. cd 到該 project 目錄
#   3. 啟動 AI coding agent（Claude Code Yolo 模式，--dangerously-skip-permissions）
#   4. Agent 退出後，標記完成，接下一個
#   5. queue 空了就等 30 秒再檢查（支援動態新增 project）
#
# 用法：
#   cd /path/to/AI-Meka
#   ./queue-runner.sh
#
# 停止：
#   Ctrl+C（當前執行的 agent session 不會被中斷，只是之後不再派新任務）
#
# 日誌：
#   running.log — 執行歷史

set -o pipefail

FACTORY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUEUE="$FACTORY_DIR/queue.md"
LOG="$FACTORY_DIR/running.log"

# ─────────────────────────────────────────────────────────────────────────────
# 工具函式
# ─────────────────────────────────────────────────────────────────────────────

log() {
  local msg="$1"
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $msg"
  echo "[$ts] $msg" >> "$LOG"
}

# 從 queue.md 取出第一個「未執行」的 project
# 未執行定義:
#   - 不是空行
#   - 不是 markdown 標題 (#)
#   - 不是註解說明 (#)
#   - 不是 # DONE / # RUNNING 標記的
# 輸出格式: "<name>|<path>"
get_next_project() {
  # 取出符合格式「<name> | <path>」且沒有 # 前綴的行
  local line=$(grep -E "^[^#[:space:]].*\|.*/" "$QUEUE" | head -1)

  if [[ -z "$line" ]]; then
    return 1
  fi

  local name=$(echo "$line" | cut -d'|' -f1 | xargs)
  local path=$(echo "$line" | cut -d'|' -f2- | xargs)

  echo "${name}|${path}"
  echo "__RAW__${line}" >&2  # stderr 傳回原始行，方便後續 sed 替換
  return 0
}

# 標記 project 為 RUNNING
mark_running() {
  local raw_line="$1"
  # 用 | 當 sed 分隔符避免路徑裡的 / 衝突
  local escaped=$(printf '%s\n' "$raw_line" | sed 's/[[\.*^$()+?{|]/\\&/g')
  sed -i.bak "s|^${escaped}$|# RUNNING ${raw_line}|" "$QUEUE"
  rm -f "${QUEUE}.bak"
}

# 標記 project 為 DONE
mark_done() {
  local raw_line="$1"
  local escaped=$(printf '%s\n' "$raw_line" | sed 's/[[\.*^$()+?{|]/\\&/g')
  sed -i.bak "s|^# RUNNING ${escaped}$|# DONE ${raw_line}|" "$QUEUE"
  rm -f "${QUEUE}.bak"
}

# 標記 project 為 FAILED
mark_failed() {
  local raw_line="$1"
  local exit_code="$2"
  local escaped=$(printf '%s\n' "$raw_line" | sed 's/[[\.*^$()+?{|]/\\&/g')
  sed -i.bak "s|^# RUNNING ${escaped}$|# FAILED(exit=${exit_code}) ${raw_line}|" "$QUEUE"
  rm -f "${QUEUE}.bak"
}

# ─────────────────────────────────────────────────────────────────────────────
# 主迴圈
# ─────────────────────────────────────────────────────────────────────────────

log "═══════════════════════════════════════════════════════════"
log "AI-Meka queue-runner 啟動"
log "Queue: $QUEUE"
log "Log:   $LOG"
log "═══════════════════════════════════════════════════════════"

# 檢查 queue.md 存在
if [[ ! -f "$QUEUE" ]]; then
  log "❌ queue.md 不存在: $QUEUE"
  exit 1
fi

# 檢查 claude 指令可用
if ! command -v claude &> /dev/null; then
  log "❌ claude 指令找不到。請先安裝 Claude Code CLI。"
  exit 1
fi

while true; do
  # 抓下一個 project
  RESULT=$(get_next_project 2> /tmp/queue-runner-raw.tmp)
  RAW_LINE=$(cat /tmp/queue-runner-raw.tmp | sed 's/^__RAW__//')
  rm -f /tmp/queue-runner-raw.tmp

  if [[ -z "$RESULT" ]]; then
    log "⏸  Queue 空了，30 秒後再檢查（新增 project 會自動接起）..."
    sleep 30
    continue
  fi

  NAME=$(echo "$RESULT" | cut -d'|' -f1)
  PROJECT_DIR=$(echo "$RESULT" | cut -d'|' -f2)

  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "▶ 開始: $NAME"
  log "  目錄: $PROJECT_DIR"

  # 檢查目錄存在
  if [[ ! -d "$PROJECT_DIR" ]]; then
    log "❌ 目錄不存在: $PROJECT_DIR"
    mark_failed "$RAW_LINE" "dir_not_found"
    continue
  fi

  # 檢查是否有 AI-Meka template（.claude/ 或 CLAUDE.md）
  if [[ ! -f "$PROJECT_DIR/CLAUDE.md" && ! -d "$PROJECT_DIR/.claude" ]]; then
    log "⚠️  警告: $PROJECT_DIR 沒有 CLAUDE.md 或 .claude/，可能不是完整的 SDD 專案"
    log "    繼續執行，但 agent 可能沒有足夠上下文"
  fi

  # 標記為 RUNNING
  mark_running "$RAW_LINE"

  # cd 到專案，啟動 agent（Claude Code Yolo 模式）
  # 注意：agent 是 interactive，會佔用 terminal
  # queue-runner 會等 agent 結束才繼續
  cd "$PROJECT_DIR"

  log "  啟動 agent（Claude Code Yolo 模式）..."
  log "  ※ session 期間，直接跟 agent 對話"
  log "  ※ 要結束 session，在 agent 內打 /exit 或按 Ctrl+D"

  # 實際啟動 agent（目前驗證對象是 Claude Code；換 agent 改下行即可）
  claude --dangerously-skip-permissions
  EXIT_CODE=$?

  cd "$FACTORY_DIR"

  if [[ $EXIT_CODE -eq 0 ]]; then
    log "✓ 完成: $NAME"
    mark_done "$RAW_LINE"
  else
    log "✗ 失敗: $NAME (exit=$EXIT_CODE)"
    mark_failed "$RAW_LINE" "$EXIT_CODE"
  fi

  log ""
done
