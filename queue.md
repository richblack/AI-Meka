# AI-Meka 生產線排隊

> 格式：`<專案名稱> | <絕對路徑>`
> queue-runner.sh 會由上而下執行，完成後自動加上 `# DONE`，執行中會加 `# RUNNING`。
> 新增專案：在檔尾加一行。無需重啟 queue-runner（它每 30 秒檢查一次）。

---

## 範例（可刪）

# DONE 範例專案A | /path/to/your/projects/example-a
# RUNNING 範例專案B | /path/to/your/projects/example-b
# 範例專案C | /path/to/your/projects/example-c

---

## 等待執行

# 在這行下面加你的 project：
# 格式：<name> | <path>
#
# 例：
# my-app | /path/to/your/projects/my-app
