# claude-planning-kit

A context-optimized planning and execution workflow for Claude Code, packaged as a plugin marketplace. Built from real multi-repo, multi-tenant commerce work; improved after every real feature shipped.

**The loop:** triage → (brainstorm if vague) → discovery → questions → plan → independent review → continuous lock-safe execution → final human checklist.

## What's inside

```
plugins/planning-kit/
  skills/feature-planning/   # planning state machine (artifacts in planning/<slug>/)
  skills/plan-execution/     # continuous executor: locks, worktrees, scope fence, DoD
  agents/repo-explorer.md    # read-only discovery subagent (own context window)
  agents/plan-reviewer.md    # fresh-context adversarial plan reviewer
templates/CLAUDE-md-snippet.md   # 3-tier triage router for each repo's CLAUDE.md
prompts/                          # bootstrap prompts (existing/new project) + standalone versions
```

## Design principles

- **Disk over chat:** every phase writes an artifact to `planning/<slug>/`; any session resumes from files.
- **Continuous by default (v2):** phases run back-to-back in one session; `/clear` is a pressure valve, not a ritual.
- **User work at the edges (v2):** prerequisites are collected up front as Phase 0; every other human task (manual QA, real payment/affiliate tests, DNS, approvals) is sequenced AFTER the last agent phase and delivered as `user-tasks.md`. The reviewer rejects plans that bury user steps mid-stream.
- **Parallel-safe:** phases are claimed via lock files in the shared `.git` directory — independent sessions and teammates never collide.
- **Compose with Superpowers:** `brainstorming` refines vague ideas into the feature request; `test-driven-development`, `systematic-debugging`, and `requesting-code-review` plug into execution. Their planner/executor skills are intentionally NOT used.

## Install

**As a plugin (auto-updates):**

```
/plugin marketplace add <YOUR-GITHUB-USER>/claude-planning-kit
/plugin install planning-kit@claude-planning-kit
```

Skills become `/planning-kit:feature-planning` and `/planning-kit:plan-execution`. Add the triage router from `templates/CLAUDE-md-snippet.md` to each repo's `CLAUDE.md`.

**Or let Claude install it:** paste `prompts/BOOTSTRAP-EXISTING-PROJECT.md` (existing repo) or `prompts/BOOTSTRAP-NEW-PROJECT.md` (empty directory) into Claude Code.

## Improving the base

Treat skill text like code. After each real feature: read the execution logs in `planning/<slug>/execution/`, fold recurring deviations into the skills, bump the version in both manifests, commit. Projects installed via the marketplace pick up updates; vendored copies re-run the bootstrap prompt.
