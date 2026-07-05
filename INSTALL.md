# Install Guide

Three ways to install, from most to least automated.

## 1. Bootstrap prompts (recommended — Claude does everything)

- **Existing repo:** paste `prompts/BOOTSTRAP-EXISTING-PROJECT.md` into Claude Code at the repo root.
- **New project:** paste `prompts/BOOTSTRAP-NEW-PROJECT.md` into Claude Code in an empty directory.

Both install the kit, wire the CLAUDE.md triage router, cherry-pick the four compatible Superpowers skills (brainstorming, test-driven-development, systematic-debugging, requesting-code-review), verify, and commit. The prompts already point to `LeopoldoJacobsen/claude-planning-kit` — just copy and paste.

## 2. Plugin marketplace (auto-updates)

```
/plugin marketplace add LeopoldoJacobsen/claude-planning-kit
/plugin install planning-kit@claude-planning-kit
```

Skills are namespaced: `/planning-kit:feature-planning`, `/planning-kit:plan-execution`. Still add the triage block from `templates/CLAUDE-md-snippet.md` to each repo's `CLAUDE.md`, and cherry-pick the Superpowers skills per the bootstrap prompt's Step 3.

## 3. Manual copy

Copy `plugins/planning-kit/skills/*` into `.claude/skills/` and `plugins/planning-kit/agents/*` into `.claude/agents/` (project-level, committed) or into `~/.claude/` (personal, all projects). Append the triage block to `CLAUDE.md`.

## Superpowers compatibility rules

Install ONLY: `brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review` (copy their skill folders). NEVER install `writing-plans`, `executing-plans`, `subagent-driven-development`, or `using-git-worktrees` alongside this kit — two planners/executors fight for triggering. The pipeline invokes brainstorming for vague ideas and blocks its handoff to their planner.

## Day-to-day flow (v2)

1. Describe a feature normally, in Portuguese or English. The router classifies it (DIRECT / LIGHT / FULL).
2. Vague idea → brainstorming refines it into a design doc → pipeline continues from there.
3. Planning runs continuously in one session: discovery → your answers → plan (+ per-phase files + `user-tasks.md`) → independent review → your approval. It pauses only for your input.
4. You confirm Phase 0 prerequisites (keys, accounts, decisions) — collected up front, once.
5. Execution runs all agent phases back-to-back (parallel sessions welcome; locks arbitrate) and ends by handing you `user-tasks.md`: your tests, validations, and sign-offs, batched at the end so they never block the agents.
