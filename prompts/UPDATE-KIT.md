# Update Prompt — refresh a vendored claude-planning-kit install

Paste everything below into Claude Code at the root of a project that already has the kit vendored in `.claude/` (installed via a bootstrap prompt). Marketplace installs do NOT need this — they update via `/plugin marketplace update claude-planning-kit`.

---

You are updating this repository's vendored copy of **claude-planning-kit** to the latest published version. Perform every step yourself, verify as you go, and report at the end. Do not start any feature work in this session.

## Step 1 — Fetch the latest kit

```bash
git clone --depth 1 https://github.com/LeopoldoJacobsen/claude-planning-kit /tmp/cpk
grep '"version"' /tmp/cpk/plugins/planning-kit/.claude-plugin/plugin.json
```

Note the version — it goes in the commit message.

## Step 2 — Overwrite ONLY the kit's own files

```bash
cp -r /tmp/cpk/plugins/planning-kit/skills/. .claude/skills/
cp -r /tmp/cpk/plugins/planning-kit/agents/. .claude/agents/
```

This overwrites `feature-planning`, `plan-execution`, `repo-explorer`, and `plan-reviewer`. Do NOT touch any other skill or agent in `.claude/` (Superpowers skills, project-specific skills).

## Step 3 — Refresh the triage router

Replace the existing `## Task Triage` section in this repo's `CLAUDE.md` with the current block from `/tmp/cpk/templates/CLAUDE-md-snippet.md`. Be idempotent: replace the section, never duplicate it. If `CLAUDE.md` or the section is missing, add it.

## Step 4 — Verify and commit

1. `git diff --stat` — confirm changes are confined to `.claude/skills/feature-planning/`, `.claude/skills/plan-execution/`, `.claude/agents/repo-explorer.md`, `.claude/agents/plan-reviewer.md`, and the Task Triage block in `CLAUDE.md`. Anything else changed → stop and report before committing.
2. Commit:

```bash
git add .claude CLAUDE.md
git commit -m "chore: update claude-planning-kit to v<version from Step 1>"
```

Clean up `/tmp/cpk`. Report the old→new differences in one short list (which files changed) and stop.
