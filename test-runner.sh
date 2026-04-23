#!/bin/bash
# test-runner.sh — AI-Meka 多專案測試 Runner
#
# 從 queue.md 讀專案清單，平行跑每個專案的測試，產生 test-report.md。
#
# 用法：
#   ./test-runner.sh                   # 預設：只測 # DONE 的專案
#   ./test-runner.sh --all             # 測 queue.md 所有專案（DONE/RUNNING/待執行皆測）
#   ./test-runner.sh <project-name>    # 只測指定專案（名稱需與 queue.md 一致）
#   ./test-runner.sh --jobs 4          # 限制平行度（預設 = CPU 核心數）
#
# 輸出：
#   test-report.md                     ← Markdown 表格 + 失敗輸出
#   .test-runner-logs/<project>.log    ← 每專案完整輸出
#
# 偵測規則（依序嘗試，第一個命中的就用）：
#   1. 有 package.json → pnpm test / npm test
#   2. 有 go.mod       → go test ./...
#   3. 有 Cargo.toml   → cargo test
#   4. 有 pyproject.toml / pytest.ini → pytest
#   5. 有 Makefile 且含 `test:` target → make test
#   都沒有 → 跳過，在報告標記為 "no-tests-detected"
#
# 退出 code：
#   0 = 全部 pass（或無測試的 gracefully skip）
#   1 = 至少一個專案 fail
#   2 = 內部錯誤（queue.md 不存在等）

set -o pipefail

FOREMAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUEUE="$FOREMAN_DIR/queue.md"
REPORT="$FOREMAN_DIR/test-report.md"
LOG_DIR="$FOREMAN_DIR/.test-runner-logs"

# ─── 參數解析 ────────────────────────────────────────────────────────────────
MODE="done-only"   # done-only | all | single
TARGET_NAME=""
JOBS=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      MODE="all"
      shift
      ;;
    --jobs)
      JOBS="$2"
      shift 2
      ;;
    --help|-h)
      head -30 "$0" | grep -E "^#" | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "Unknown flag: $1" >&2
      exit 2
      ;;
    *)
      MODE="single"
      TARGET_NAME="$1"
      shift
      ;;
  esac
done

# ─── 檢查前置 ─────────────────────────────────────────────────────────────────
if [[ ! -f "$QUEUE" ]]; then
  echo "❌ queue.md not found: $QUEUE" >&2
  exit 2
fi

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/*.log 2>/dev/null

# ─── 從 queue.md 擷取要測的專案 ─────────────────────────────────────────────
# queue.md 行格式：
#   [# DONE|# RUNNING|# FAILED...] <name> | <path>
# 或裸行（未執行）：
#   <name> | <path>
#
# 我們用 awk 抓出 name|path|status

extract_projects() {
  awk -F'|' '
    # 只處理含 | 且路徑像絕對路徑的行
    /\|.*\// {
      raw = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", raw)

      # 判 status
      status = "PENDING"
      line = raw
      if (raw ~ /^# DONE /)        { status = "DONE";    line = substr(raw, 8) }
      else if (raw ~ /^# RUNNING /) { status = "RUNNING"; line = substr(raw, 11) }
      else if (raw ~ /^# FAILED/)   { status = "FAILED";  sub(/^# FAILED[^ ]* /, "", line) }
      else if (raw ~ /^#/)          { next }  # 其他註解行跳過

      # 拆 name 和 path
      n = split(line, parts, "|")
      if (n < 2) next
      name = parts[1]; path = parts[2]
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", path)

      if (name == "" || path == "") next
      print name "|" path "|" status
    }
  ' "$QUEUE"
}

ALL_PROJECTS=$(extract_projects)

if [[ -z "$ALL_PROJECTS" ]]; then
  echo "⚠️  No projects detected in $QUEUE" >&2
  exit 0
fi

# 過濾
filter_projects() {
  case "$MODE" in
    all)
      echo "$ALL_PROJECTS"
      ;;
    single)
      echo "$ALL_PROJECTS" | awk -F'|' -v target="$TARGET_NAME" '$1 == target'
      ;;
    done-only)
      echo "$ALL_PROJECTS" | awk -F'|' '$3 == "DONE"'
      ;;
  esac
}

TARGET_PROJECTS=$(filter_projects)

if [[ -z "$TARGET_PROJECTS" ]]; then
  case "$MODE" in
    done-only)
      echo "ℹ️  No # DONE projects. Use --all or specify a name." >&2
      ;;
    single)
      echo "❌ Project not found in queue.md: $TARGET_NAME" >&2
      exit 2
      ;;
  esac
  exit 0
fi

PROJECT_COUNT=$(echo "$TARGET_PROJECTS" | wc -l | tr -d ' ')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AI-Meka test-runner"
echo "  mode:     $MODE"
echo "  projects: $PROJECT_COUNT"
echo "  jobs:     $JOBS"
echo "  report:   $REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── 單專案測試邏輯 ──────────────────────────────────────────────────────────
run_one_project() {
  local name="$1"
  local path="$2"
  local log_file="$LOG_DIR/${name}.log"

  local start_ts=$(date +%s)

  {
    echo "=== project: $name"
    echo "=== path:    $path"
    echo "=== started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
  } > "$log_file"

  if [[ ! -d "$path" ]]; then
    echo "RESULT=dir-not-found" >> "$log_file"
    echo "$name|$path|dir-not-found|0" > "$LOG_DIR/${name}.status"
    return
  fi

  cd "$path" || {
    echo "RESULT=cd-failed" >> "$log_file"
    echo "$name|$path|cd-failed|0" > "$LOG_DIR/${name}.status"
    return
  }

  local cmd=""
  local detected=""

  if [[ -f "package.json" ]]; then
    if grep -q '"test"' package.json; then
      detected="node"
      if command -v pnpm &> /dev/null && [[ -f "pnpm-lock.yaml" ]]; then
        cmd="pnpm test"
      elif command -v yarn &> /dev/null && [[ -f "yarn.lock" ]]; then
        cmd="yarn test"
      else
        cmd="npm test"
      fi
    fi
  fi

  if [[ -z "$cmd" && -f "go.mod" ]]; then
    detected="go"
    cmd="go test ./..."
  fi

  if [[ -z "$cmd" && -f "Cargo.toml" ]]; then
    detected="rust"
    cmd="cargo test"
  fi

  if [[ -z "$cmd" ]] && { [[ -f "pyproject.toml" ]] || [[ -f "pytest.ini" ]] || [[ -f "setup.py" ]]; }; then
    detected="python"
    if command -v uv &> /dev/null && [[ -f "pyproject.toml" ]]; then
      cmd="uv run pytest"
    else
      cmd="pytest"
    fi
  fi

  if [[ -z "$cmd" && -f "Makefile" ]] && grep -qE "^test:" Makefile; then
    detected="make"
    cmd="make test"
  fi

  if [[ -z "$cmd" ]]; then
    echo "RESULT=no-tests-detected" >> "$log_file"
    echo "$name|$path|no-tests-detected|0" > "$LOG_DIR/${name}.status"
    return
  fi

  echo "=== detected: $detected" >> "$log_file"
  echo "=== cmd:      $cmd" >> "$log_file"
  echo "" >> "$log_file"

  local exit_code=0
  if ! bash -c "$cmd" >> "$log_file" 2>&1; then
    exit_code=$?
  fi

  local end_ts=$(date +%s)
  local duration=$((end_ts - start_ts))

  echo "" >> "$log_file"
  echo "=== exit_code: $exit_code" >> "$log_file"
  echo "=== duration:  ${duration}s" >> "$log_file"

  if [[ $exit_code -eq 0 ]]; then
    echo "$name|$path|pass|$duration" > "$LOG_DIR/${name}.status"
  else
    echo "$name|$path|fail|$duration" > "$LOG_DIR/${name}.status"
  fi
}

# ─── 平行執行 ────────────────────────────────────────────────────────────────
echo ""
echo "Running tests (parallelism=$JOBS)..."

# Fork-join with simple job slot tracking
run_in_bg() {
  local name="$1"
  local path="$2"
  (
    run_one_project "$name" "$path"
    echo "  ✓ $name done"
  ) &
}

active_jobs() {
  jobs -p | wc -l | tr -d ' '
}

while IFS='|' read -r name path status; do
  [[ -z "$name" ]] && continue

  # Wait if at capacity
  while [[ $(active_jobs) -ge $JOBS ]]; do
    sleep 0.2
  done

  echo "  ▶ $name"
  run_in_bg "$name" "$path"
done <<< "$TARGET_PROJECTS"

wait

echo ""
echo "All jobs finished. Generating report..."

# ─── 產出 test-report.md ────────────────────────────────────────────────────
REPORT_TS=$(date '+%Y-%m-%d %H:%M:%S')
TOTAL=0
PASS=0
FAIL=0
NOTEST=0
MISSING=0

# 先掃一次算總數
while IFS='|' read -r sname spath sstatus sduration; do
  [[ -z "$sname" ]] && continue
  TOTAL=$((TOTAL + 1))
  case "$sstatus" in
    pass) PASS=$((PASS + 1)) ;;
    fail) FAIL=$((FAIL + 1)) ;;
    no-tests-detected) NOTEST=$((NOTEST + 1)) ;;
    dir-not-found|cd-failed) MISSING=$((MISSING + 1)) ;;
  esac
done < <(cat "$LOG_DIR"/*.status 2>/dev/null)

{
  echo "# AI-Meka Test Report"
  echo ""
  echo "> Generated: $REPORT_TS"
  echo "> Mode: \`$MODE\`  |  Projects: $TOTAL  |  Parallelism: $JOBS"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Metric | Count |"
  echo "|--------|-------|"
  echo "| Total projects | $TOTAL |"
  echo "| ✅ Pass | $PASS |"
  echo "| ❌ Fail | $FAIL |"
  echo "| ⏭️  No tests detected | $NOTEST |"
  echo "| ⚠️  Missing / cd failed | $MISSING |"
  echo ""
  echo "## Results"
  echo ""
  echo "| Project | Status | Duration | Path |"
  echo "|---------|--------|----------|------|"

  while IFS='|' read -r sname spath sstatus sduration; do
    [[ -z "$sname" ]] && continue
    local_icon=""
    case "$sstatus" in
      pass)              local_icon="✅ pass" ;;
      fail)              local_icon="❌ fail" ;;
      no-tests-detected) local_icon="⏭️  no-tests" ;;
      dir-not-found)     local_icon="⚠️  dir-missing" ;;
      cd-failed)         local_icon="⚠️  cd-failed" ;;
      *)                 local_icon="❓ $sstatus" ;;
    esac
    echo "| $sname | $local_icon | ${sduration}s | \`$spath\` |"
  done < <(cat "$LOG_DIR"/*.status 2>/dev/null)

  # 失敗專案：顯示 log tail
  if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "## Failures"
    echo ""
    while IFS='|' read -r sname spath sstatus sduration; do
      [[ "$sstatus" != "fail" ]] && continue
      echo "### ❌ $sname"
      echo ""
      echo "Path: \`$spath\`"
      echo ""
      echo "<details>"
      echo "<summary>Last 80 lines of output</summary>"
      echo ""
      echo '```'
      tail -80 "$LOG_DIR/${sname}.log" 2>/dev/null
      echo '```'
      echo "</details>"
      echo ""
      echo "Full log: \`.test-runner-logs/${sname}.log\`"
      echo ""
    done < <(cat "$LOG_DIR"/*.status 2>/dev/null)
  fi
} > "$REPORT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:  $PASS pass / $FAIL fail / $NOTEST no-tests / $MISSING missing"
echo "Report:   $REPORT"
echo "Logs:     $LOG_DIR/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

exit 0
