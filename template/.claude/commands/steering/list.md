---
description: 列出目前所有 steering 規則，分類呈現
---

# /steering:list — 列出所有 steering 規則

## 你的任務

掃描 `.claude/rules/*.md`，把所有規則彙整成一張表，讓使用者快速掃一遍當前的規則清單。

### Step 1：逐檔讀取

讀這 5 份檔案（存在才讀）：
- `.claude/rules/00-sdd-protocol.md`
- `.claude/rules/01-tech-stack.md`
- `.claude/rules/02-forbidden.md`
- `.claude/rules/03-architecture.md`
- `.claude/rules/04-current-progress.md`

### Step 2：抽取規則

每份檔案找出格式為 `### X.Y ...` 的條目（編號規則）。

對每條規則抽：
- 編號（X.Y）
- 標題
- Hook 行為（🔴 Block / 🟡 Warning / 🟢 Soft）
- 新增日期（若有）

### Step 3：掃描 hooks 對應

讀 `.claude/hooks/pre-write-guard.sh` 和 `pre-bash-guard.sh`，找出實際有實作的規則編號。

對每條 rule，標記：
- ✅ Hook 已實作：rule 和 hook 都有
- ⚠️ 只在 rule 沒有 hook：該 block 但 hook 漏了
- 🔶 只在 hook 沒在 rule：hook 有擋但沒文件說明（反向漏）

### Step 4：輸出

```markdown
# Steering Rules 清單

更新時間：<今天>

## 第一類：流程規範（rules/00-sdd-protocol.md）

| 編號 | 標題 | Hook | 對應檢查 |
|-----|------|------|---------|
| 1.1 | 禁止沒讀 SDD 就動 code | 🟢 Soft | - |
| 1.2 | 禁止跳關 | 🟢 Soft | - |
| 1.3 | 禁止批次更新 tasks.md | 🟡 Warning | post-edit-remind-tasks.sh |
| 1.4 | 禁止自行建新 SDD 頂層目錄 | 🔴 Block | pre-write-guard.sh ✅ |

## 第二類：架構層級（rules/02-forbidden.md）

| 編號 | 標題 | Hook | 對應檢查 |
|-----|------|------|---------|
| 2.1 | 某個路徑下禁 TS | 🔴 Block | pre-write-guard.sh ✅ |
| 2.2 | orchestration 層 TS 禁業務邏輯 | 🔴 Block | pre-write-guard.sh ✅ |
| 2.3 | 禁平行目錄（*-v2 等） | 🔴 Block | pre-write + pre-bash ✅ |

## 第三類：資料安全（rules/02-forbidden.md）

...

## 第四類：版本控制（rules/02-forbidden.md）

...

## 第五類：SDD 同步（rules/02-forbidden.md）

...

## 健康度警示

- ⚠️ 規則 X.Y 標為 🔴 Block 但 hook 沒實作 → 建議補 hook
- 🔶 Hook 中偵測到未在 rules 文件的 pattern → 建議補 rule 說明

## 總計

- 總規則數：<N>
- Block：<a>
- Warning：<b>
- Soft：<c>
- 新增於最近 7 天：<d>
```

### Step 5：建議

若偵測到 rule/hook 不一致，主動給出修補建議：

```
💡 建議：
- 規則 2.5 還沒有 hook 實作，執行 /steering:add 補一個
- pre-bash-guard.sh 第 52 行的 pattern 不在任何 rule，建議加條目到 02-forbidden.md
```

## 禁止行為

- ❌ 只讀其中一份 rules 檔（必須全讀）
- ❌ 不對照 hooks（rule vs hook 的一致性是這個 command 的核心價值）
- ❌ 自行新增規則（這是 /steering:add 的工作）
- ❌ 猜健康度警示（必須真的對比過才輸出）
