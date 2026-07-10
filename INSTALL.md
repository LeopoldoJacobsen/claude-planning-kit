# Install Guide

Three ways to install in Claude Code, plus Cursor support.

## Cursor (pinned Fable / GPT / Grok) — multi-model peer review

From the **consumer repository root**:

```bash
git clone --depth 1 https://github.com/LeopoldoJacobsen/claude-planning-kit /tmp/cpk
mkdir -p .claude/skills .claude/agents .cursor/rules .cursor/agents .cursor/commands
cp -R /tmp/cpk/plugins/planning-kit/skills/. .claude/skills/
cp -R /tmp/cpk/plugins/planning-kit/agents/. .claude/agents/
cp -R /tmp/cpk/templates/cursor/agents/. .cursor/agents/
cp /tmp/cpk/templates/cursor/planning-kit.mdc .cursor/rules/planning-kit.mdc
cp /tmp/cpk/templates/cursor/commands/multi-model-review.md .cursor/commands/multi-model-review.md
rm -rf /tmp/cpk
```

Defaults already pinned:

| Agent | Model |
|---|---|
| architecture-council | `gpt-5.6-sol-max-fast` |
| failure-council | `grok-4.5-fast-xhigh` |
| simplicity-council | `claude-fable-5-thinking-max` |
| plan-reviewer | `gpt-5.6-sol-max-fast` |
| implementation-reviewer | `grok-4.5-fast-xhigh` |

Use `/multi-model-review` in Cursor chat or CLI for an ad-hoc three-model adversarial review of any diff. Details: [`docs/CURSOR.md`](docs/CURSOR.md).

**Claude Code–only installs** cannot pin cross-family reviewers — FULL plans will correctly mark DEGRADED and need a per-plan human override. That is honesty, not a bug.

## 1. Bootstrap prompts (recommended — Claude does everything)

- **Existing repo:** paste `prompts/BOOTSTRAP-EXISTING-PROJECT.md` into Claude Code at the repo root.
- **New project:** paste `prompts/BOOTSTRAP-NEW-PROJECT.md` into Claude Code in an empty directory.

Both install the kit, wire the CLAUDE.md triage router, cherry-pick the four compatible Superpowers skills, install Cursor agents + `/multi-model-review`, verify, and commit.

## 2. Plugin marketplace (auto-updates)

```
/plugin marketplace add LeopoldoJacobsen/claude-planning-kit
/plugin install planning-kit@claude-planning-kit
```

Skills are namespaced: `/planning-kit:feature-planning`, `/planning-kit:plan-execution`. Still add the triage block from `templates/CLAUDE-md-snippet.md`. **For Cursor multi-model**, also copy skills into `.claude/skills/` (so the rule can find them) plus `templates/cursor/agents/`, the rule, and `templates/cursor/commands/multi-model-review.md` as in the Cursor section above.

## 3. Manual copy

Copy `plugins/planning-kit/skills/*` into `.claude/skills/` and `plugins/planning-kit/agents/*` into `.claude/agents/`. Append the triage block to `CLAUDE.md`. For Cursor, follow the Cursor section.

## Updating an existing install

- **Marketplace installs:** `/plugin marketplace update claude-planning-kit`
- **Vendored installs:** paste `prompts/UPDATE-KIT.md` — it refreshes skills/agents/Cursor assets while **preserving** customized `model:` pins when possible.

## Superpowers compatibility rules

Install ONLY: `brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`. NEVER install `writing-plans`, `executing-plans`, `subagent-driven-development`, or `using-git-worktrees` alongside this kit. The merge gate is `implementation-reviewer`; Superpowers `requesting-code-review` is optional extra, not a substitute.

## Day-to-day flow (v2.4)

1. Describe a feature normally. Triage: DIRECT / LIGHT / FULL.
2. FULL: discovery → questions → role matrix → parallel GPT/Grok/Fable council → plan → persistent cross-family review → your plan approval (+ DEGRADED override if needed) → Phase 0.
3. Execution with peer diff review; ends with `user-tasks.md`.
4. Anytime: `/multi-model-review` for a three-model adversarial pass on a diff.
