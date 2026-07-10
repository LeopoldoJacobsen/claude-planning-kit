# Bootstrap Prompt — EXISTING Project

Paste everything below into Claude Code at the root of an existing repository. Claude will perform the whole installation, verify it, and commit.

---

You are setting up this repository to use the **claude-planning-kit** workflow (spec-driven planning + continuous lock-safe execution) composed with selected Superpowers skills. Perform every step yourself, verify as you go, and report at the end. Do not start any feature work in this session.

## Step 1 — Install the planning kit (vendored copy)

```bash
git clone --depth 1 https://github.com/LeopoldoJacobsen/claude-planning-kit /tmp/cpk
mkdir -p .claude/skills .claude/agents .cursor/agents .cursor/rules .cursor/commands
cp -r /tmp/cpk/plugins/planning-kit/skills/. .claude/skills/
cp -r /tmp/cpk/plugins/planning-kit/agents/. .claude/agents/
cp -r /tmp/cpk/templates/cursor/agents/. .cursor/agents/
cp /tmp/cpk/templates/cursor/planning-kit.mdc .cursor/rules/planning-kit.mdc
cp /tmp/cpk/templates/cursor/commands/multi-model-review.md .cursor/commands/multi-model-review.md
```

(Note for the human: if you prefer auto-updates over a vendored copy, run `/plugin marketplace add LeopoldoJacobsen/claude-planning-kit` and `/plugin install planning-kit@claude-planning-kit` yourself instead of Step 1 — skills then live under the `/planning-kit:` namespace. Still copy `templates/cursor/agents/` + the command for Cursor model pins.)

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

1. Confirm the two skills, all six planning-kit agents in `.claude/agents/`, the six Cursor agent templates in `.cursor/agents/` (pinned to gpt-5.6-sol-max-fast / grok-4.5-fast-xhigh / claude-fable-5-thinking-max), `.cursor/rules/planning-kit.mdc`, `.cursor/commands/multi-model-review.md`, the four Superpowers skill folders, and the Task Triage block inside `CLAUDE.md`.
2. If any of the four Superpowers skills is missing, name it explicitly in the final report (the kit degrades gracefully — plans only reference tooling that actually exists — but the user should know).
3. Confirm no competing planner skills were copied.
4. Show a short tree of `.claude/` and `.cursor/` as proof.

## Step 5 — Commit

```bash
git switch chore/claude-planning-kit 2>/dev/null || git switch -c chore/claude-planning-kit
[ "$(git branch --show-current)" = "chore/claude-planning-kit" ] || { echo "not on chore/claude-planning-kit — stop and report"; }
git add .claude .cursor/agents .cursor/rules/planning-kit.mdc .cursor/commands/multi-model-review.md CLAUDE.md
git commit -m "chore: install planning-kit v2.4 + multi-model peer review"
```

Tell the user the branch name so they can merge it, and clean up `/tmp/cpk` and `/tmp/sp`.

## Step 6 — Report and hand off

Summarize what was installed and explain: triage → discovery/questions → role matrix → GPT/Grok/Fable council → plan → persistent cross-family review → phased execution → peer diff review → human checklist. Tell Cursor users: agents are already pinned to `gpt-5.6-sol-max-fast`, `grok-4.5-fast-xhigh`, and `claude-fable-5-thinking-max`; use `/multi-model-review` anytime for a three-model adversarial pass. Claude Code–only installs will mark FULL reviews DEGRADED (expected). Then stop.
