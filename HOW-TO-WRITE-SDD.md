你被要求產一份 AI-Meka 規格的 SDD。

Step 1: 讀以下檔案建立脈絡
  - template/CLAUDE.md
  - template/.claude/rules/00-sdd-protocol.md
  - template/.claude/rules/05-task-granularity.md
  - template/.claude/rules/06-tdd-protocol.md
  - template/.agents/specs/_example-feature/requirements.md
  - template/.agents/specs/_example-feature/design.md
  - template/.agents/specs/_example-feature/tasks.md

Step 2: 產出必須包含
  - requirements.md：EARS 格式，含 Non-goals
  - design.md：含技術決策、風險、影響分析
  - tasks.md：每個 task 含 Test File、Acceptance、Checkpoint、Dependency

Step 3: 驗證
  - 所有 task 都能在單一 session 完成（< 300 行 / < 5 檔案）
  - 每個 Phase 結尾有「跑測試」的 task
  - 最後 Phase 是驗收 / 交付