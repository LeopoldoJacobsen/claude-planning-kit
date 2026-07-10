# CLAUDE.md snippet — Task Triage Router

Paste the block below into each repository's `CLAUDE.md` (create the file at the repo root if it does not exist). This is the only always-loaded piece: it costs ~15 lines of context and decides whether the full pipeline is needed.

---

## Task Triage (always apply)

Before executing any request, classify it and state the classification in one line:

- **DIRECT** — typo/copy fixes, config tweaks, or an isolated bug fix touching ≤2 files, with NO changes to database schema, API contracts, environment variables, auth/permissions, payments, multi-tenancy, or other repositories → just do it.
- **LIGHT PLAN** — 3–10 files or moderate logic changes, still no schema/contract/env/auth/payment/multi-tenancy/cross-repo impact → write a 5–10 line mini-plan in chat, wait for a "go", then execute in this session.
- **FULL PIPELINE** — new features, new projects, or anything touching database schema, API contracts consumed by other repos, environment variables, auth/permissions, payments, multi-tenancy, more than ~10 files, or estimated at more than one session → use the `feature-planning` skill and follow its state machine exactly (role matrix → multi-model council when available → plan → persistent review → execution). If the request is still a vague idea rather than a defined scope, run the brainstorming skill first (when installed, under whichever name your install uses); its approved design doc becomes the feature request. On Cursor, prefer the pinned trio in `.cursor/agents/` (`gpt-5.6-sol-max-fast`, `grok-4.5-fast-xhigh`, `claude-fable-5-thinking-max`) and `/multi-model-review` for ad-hoc three-model reviews. Claude Code–only installs correctly mark cross-family review as DEGRADED and need a per-plan human override.

When in doubt between two levels, choose the higher one. If a task classified as DIRECT or LIGHT PLAN grows mid-execution (new files, schema, or contracts appear), stop and re-classify upward.
