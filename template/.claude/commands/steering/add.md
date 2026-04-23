---
description: 把一次糾正的教訓寫進 steering，下次不再犯同樣的錯
argument-hint: [簡短的規則描述，可省略，會一問一答]
---

# /steering:add — 新增 steering 規則

使用者 剛糾正了 agent 某件事，或想預先設一條規則。目標是**把教訓寫進 `.claude/rules/`**，讓下個 session 啟動時就記得。

## 你的任務

### Step 1：確認規則內容

如果 `$ARGUMENTS` 有值 → 那就是規則的簡述
如果為空 → 問 使用者：「這次要新增的規則是什麼？一句話描述。」

### Step 2：問四個問題（一次一個，不要一次問完）

**第一問**：「這條規則屬於哪一類？」

| 類別 | 對應檔案 |
|-----|---------|
| A. 流程規範（SDD 讀取、task 更新時機等） | `.claude/rules/00-sdd-protocol.md` |
| B. 技術棧（語言、框架、儲存選擇） | `.claude/rules/01-tech-stack.md` |
| C. 禁止行為（具體不准做什麼） | `.claude/rules/02-forbidden.md` |
| D. 架構 / 核心概念（抽象定義、模組邊界） | `.claude/rules/03-architecture.md` |

等 使用者 回答後再問下一題。

**第二問**：「這條規則要不要用 hook 強制執行？」

- 🔴 **Block（擋住）**：違反就 exit 2，通常是檔案路徑 / 內容 pattern 可以 grep 到的
- 🟡 **Warning（提醒）**：偵測到就印訊息但不擋，給 agent 自己導正的機會
- 🟢 **Soft rule（文字規範）**：只寫進 rules/，靠 session-start 注入 + agent 自律

**第三問**：「背景故事是什麼？」
要讓未來的 agent / 新人看 steering 時知道為什麼有這條規則。簡短 2-3 句描述觸發這條規則的情境。

**第四問**：「有沒有例外情況？」
規則幾乎都有例外（例：禁 TS 但 AssemblyScript OK）。先問清楚避免以後每次被擋都要例外處理。

### Step 3：寫入 rules/

根據類別，把規則加到對應檔案。

**寫入格式**（統一）：

```markdown
### X.Y 禁止/要求 <具體行為>

**背景**：<觸發這條規則的情境，2-3 句>

**規則**：<具體可檢查的描述>

**例外**：<若有>

**Hook 行為**：🔴 Block / 🟡 Warning / 🟢 Soft rule

**新增日期**：<今天>
```
找檔案下方適合的 section（1.x 流程類、2.x 架構類、3.x 安全類、4.x 版本控制類、5.x SDD 同步類）插入。

### Step 4：若是 Block/Warning，更新 hook

在對應 hook 加 grep pattern：

- 檔案路徑類 → `.claude/hooks/pre-write-guard.sh`
- 檔案內容類 → `.claude/hooks/pre-write-guard.sh`
- Shell 指令類 → `.claude/hooks/pre-bash-guard.sh`

**插入位置**：找到「專案特定禁令」section，在範例註解下方加入你的新規則。

**寫法**（參考已有範例）：

```bash
# ─────────────────────────────────────────────────────────────────────────────
# 規則 X.Y：<規則標題>
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$FILE_PATH" == ... ]] && echo "$CONTENT" | grep -qE "..."; then
  block "X.Y" \
    "<原因>" \
    "<正確做法>"
fi
```

### Step 5：確認並建議 commit

完成後貼出：

```
✅ Steering 已新增

📝 規則寫入：
- .claude/rules/<對應檔>.md（新增 X.Y 條）
- .claude/hooks/<對應 hook>.sh（加入 pattern）← 若適用

📦 建議 commit：
git add .claude/
git commit -m "chore(steering): add rule X.Y - <簡述>"

下一個 session 啟動時會自動載入此規則。
```

## 禁止行為

- ❌ 不問使用者就自己決定類別 / hook 行為
- ❌ 一次問 4 題（違反「一問一答」原則）
- ❌ 寫進 rules 但忘了更新 hook（若應該是 block/warning）
- ❌ 只改 hook 不寫 rules（rule 文件是「為什麼」，hook 是「怎麼擋」，兩者必須對應）
- ❌ 寫完不告訴使用者要 commit

## 快速範例（工作流完整示意）

使用者：「我發現 agent 又自己把零件寫成 TS 了，你幫我設規則。」

agent：「好，我需要了解這條規則。**這條規則屬於哪一類？**

A. 流程規範
B. 技術棧
C. 禁止行為
D. 架構 / 核心概念

我猜是 C（禁止 TS 寫零件），但請你確認。」

使用者：「C」

agent：「OK。**這條規則要不要用 hook 強制？**

🔴 Block：偵測到在 registry/components/ 下寫 .ts 就擋
🟡 Warning：只提醒不擋
🟢 Soft：只寫文件

我建議 🔴 Block，因為這種錯前兩天我們已經犯過一次。」

使用者：「Block」

agent：「**這條規則的背景故事？** 這樣未來的 session 看到這條規則會懂為什麼。」

使用者：「之前 agent 兩次自行把後端模組寫成 TS，浪費兩天。」

agent：「最後一題。**有沒有例外？** 例如 AssemblyScript 的 `.ts` 檔其實是合法的。」

使用者：「對，有 asconfig.json 的目錄放行」

agent：「好，我寫入 .claude/rules/02-forbidden.md 和 .claude/hooks/pre-write-guard.sh……」

[寫入]

agent：「✅ Steering 已新增。規則 2.1，建議 commit...」
