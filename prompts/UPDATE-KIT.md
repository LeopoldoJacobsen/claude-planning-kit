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

## Step 2 — Preserve Cursor model pins, then refresh files

```bash
# Snapshot existing model: lines before overwrite
mkdir -p /tmp/cpk-pins
if [ -d .cursor/agents ]; then
  for f in .cursor/agents/*.md; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    grep -E '^model:' "$f" > "/tmp/cpk-pins/$base.model" || true
  done
fi

cp -r /tmp/cpk/plugins/planning-kit/skills/. .claude/skills/
cp -r /tmp/cpk/plugins/planning-kit/agents/. .claude/agents/
mkdir -p .cursor/agents .cursor/rules .cursor/commands
cp -r /tmp/cpk/templates/cursor/agents/. .cursor/agents/
cp /tmp/cpk/templates/cursor/planning-kit.mdc .cursor/rules/planning-kit.mdc
cp /tmp/cpk/templates/cursor/commands/multi-model-review.md .cursor/commands/multi-model-review.md

# Restore prior model: pins when the user had customized them (non-empty snapshot)
for pin in /tmp/cpk-pins/*.model; do
  [ -f "$pin" ] || continue
  base=$(basename "$pin" .model)
  target=".cursor/agents/$base"
  [ -f "$target" ] || continue
  old=$(cat "$pin")
  [ -n "$old" ] || continue
  # Only restore if the old pin was not the previous default inherit
  echo "$old" | grep -q 'model: inherit' && continue
  # Replace the model: line in the refreshed agent
  awk -v m="$old" 'BEGIN{done=0} /^model:/{if(!done){print m; done=1; next}} {print}' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
done
```

This overwrites only planning-kit skills/agents and its Cursor templates/rule/command. Do NOT touch unrelated project-specific or Superpowers files. Customized `model:` pins are preserved; kit defaults (Fable/GPT/Grok) remain when the user had `inherit` or no prior agents.

## Step 3 — Refresh the triage router

Replace the existing `## Task Triage` section in this repo's `CLAUDE.md` with the current block from `/tmp/cpk/templates/CLAUDE-md-snippet.md`. Be idempotent: replace the section, never duplicate it. If `CLAUDE.md` or the section is missing, add it.

## Step 4 — Verify and commit

1. `git status --porcelain` — confirm changes are confined to planning-kit skills, `.claude/agents/`, `.cursor/agents/`, `.cursor/rules/planning-kit.mdc`, `.cursor/commands/multi-model-review.md`, and the Task Triage block. Anything else changed → stop and report.
2. Confirm each `.cursor/agents/*.md` still has a `model:` line; list any that were restored from user pins.
3. Commit:

```bash
git add .claude/skills .claude/agents .cursor/agents .cursor/rules/planning-kit.mdc .cursor/commands/multi-model-review.md CLAUDE.md
git commit -m "chore: update claude-planning-kit to v<version from Step 1>"
```

Clean up `/tmp/cpk` and `/tmp/cpk-pins`. Report the old→new differences in one short list. Stop.
