# Bootstrap Prompt — EXISTING Project

Paste everything below into Claude Code at the root of an existing repository. Claude will perform the whole installation, verify it, and commit.

---

You are setting up this repository to use the **claude-planning-kit** workflow (spec-driven planning + continuous lock-safe execution) composed with selected Superpowers skills. Perform every step yourself, verify as you go, and report at the end. Do not start any feature work in this session.

## Step 1 — Install the planning kit (vendored copy)

```bash
git clone --depth 1 https://github.com/LeopoldoJacobsen/claude-planning-kit /tmp/cpk
mkdir -p .claude/skills .claude/agents
cp -r /tmp/cpk/plugins/planning-kit/skills/. .claude/skills/
cp -r /tmp/cpk/plugins/planning-kit/agents/. .claude/agents/
```

(Note for the human: if you prefer auto-updates over a vendored copy, run `/plugin marketplace add LeopoldoJacobsen/claude-planning-kit` and `/plugin install planning-kit@claude-planning-kit` yourself instead of Step 1 — skills then live under the `/planning-kit:` namespace.)

## Step 2 — Wire the triage router into CLAUDE.md

Append the "Task Triage" block from `/tmp/cpk/templates/CLAUDE-md-snippet.md` to this repo's `CLAUDE.md` (create the file if missing). Be idempotent: if a "## Task Triage" section already exists, replace it instead of duplicating it.

## Step 3 — Cherry-pick Superpowers skills (execution-level only)

```bash
git clone --depth 1 https://github.com/obra/superpowers /tmp/sp
for s in brainstorming test-driven-development systematic-debugging requesting-code-review; do
  cp -r "/tmp/sp/skills/$s" .claude/skills/ 2>/dev/null || echo "skill $s not found — check /tmp/sp/skills and adjust"
done
```

**Do NOT copy** `writing-plans`, `executing-plans`, `subagent-driven-development`, or `using-git-worktrees` — they compete with the kit's planner and executor. Do not install the full Superpowers plugin in this repo for the same reason.

## Step 4 — Verify

1. Confirm these exist: `.claude/skills/feature-planning/SKILL.md`, `.claude/skills/plan-execution/SKILL.md`, `.claude/agents/repo-explorer.md`, `.claude/agents/plan-reviewer.md`, the four Superpowers skill folders, and the Task Triage block inside `CLAUDE.md`.
2. If any of the four Superpowers skills is missing, name it explicitly in the final report (the kit degrades gracefully — plans only reference tooling that actually exists — but the user should know).
3. Confirm no competing planner skills were copied.
4. Show a short tree of `.claude/` as proof.

## Step 5 — Commit

```bash
git switch chore/claude-planning-kit 2>/dev/null || git switch -c chore/claude-planning-kit
[ "$(git branch --show-current)" = "chore/claude-planning-kit" ] || { echo "not on chore/claude-planning-kit — stop and report"; }
git add .claude CLAUDE.md
git commit -m "chore: install claude-planning-kit v2 + selected Superpowers skills"
```

Tell the user the branch name so they can merge it, and clean up `/tmp/cpk` and `/tmp/sp`.

## Step 6 — Report and hand off

Summarize what was installed and explain the day-to-day flow in 5 lines: describe a feature normally → triage classifies it → vague ideas go through brainstorming first → the pipeline runs discovery → questions → plan → review continuously in one session → after approval, execution runs all agent phases back-to-back and ends with the `user-tasks.md` human checklist. Then stop — do not begin planning any feature in this session.
