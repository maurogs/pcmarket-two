# CLAUDE.md

## Workflow
- At the end of each change, suggest a commit message (short English imperative subject line).
- Before finishing a task, run the relevant tests (`bin/rails test` or the specific file) and report the result.
- If a task requires more than one file change, outline the plan first, then implement.

## Communication
- All documentation (README and any other docs) must be written in English.
- Be concise: prioritize working code and test output over prose.

## Project Rules (Rails)
- **Never edit `db/schema.rb` by hand.** Every schema change goes through a reversible migration.
- **Never hardcode user-facing text.** Every new or changed string must go through Rails I18n (`config/locales/*.yml`), and keys must be kept in sync across all locale files.
- **RESTful routes only.** If you need a custom action, justify it or extract a new resource.
- **Skinny controllers, business logic in models or `app/services/`.** Do not put queries or business rules in controllers.

## Context Maintenance
- After every meaningful change, append an entry to `.claude/context/history.md` (what changed, why, files touched).
- Keep `.claude/context/project.md` up to date (decisions, code map, open items).

## Delegation Rules
You’re the primary orchestrator. Your job is to plan, review and approve.
For any code implementation task (editing files, running tests), do NOT do it yourself.
You MUST use the `opencode_execute` tool with the `build` agent and the model `opencode/deepseek-v4.1-flash-free#high` so that a subagent executes it. 
If corrections are needed, use `opencode_reply` to continue the session.
Review the diff returned by the tool before giving your approval.