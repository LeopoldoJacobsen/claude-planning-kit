# Cursor setup and multi-model workflow (v2.4)

Cursor reads project rules from `.cursor/rules/`, custom subagents from `.cursor/agents/`, and slash commands from `.cursor/commands/`. Subagent frontmatter supports `model`, `readonly`, and `is_background` ([Cursor subagents docs](https://cursor.com/docs/subagents)).

## Default model trio (pinned)

This kit ships these Task/subagent slugs as the default council and review set:

| Role | Model slug |
|---|---|
| architecture-council | `gpt-5.6-sol-max-fast` |
| failure-council | `grok-4.5-fast-xhigh` |
| simplicity-council | `claude-fable-5-thinking-max` |
| plan-reviewer | `gpt-5.6-sol-max-fast` (switch if planner is also GPT) |
| implementation-reviewer | `grok-4.5-fast-xhigh` (switch if builder is also Grok) |

**Family map for DEGRADED checks:** GPT = `gpt-*`; Grok = `grok-*`; Fable/Claude = `claude-*` / `fable` / `composer-*` treated as Anthropic-family unless stamped otherwise.

## Install into another repository

From the **consumer repo root**:

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

Then type `/multi-model-review` in Cursor chat (or Cursor CLI) to run the three-model adversarial review. Override models only by saying so after the command.

If Cursor falls back because of plan limits, Max Mode, or admin blocks, mark `unverified` / `DEGRADED` — never claim cross-model validation.

## What the orchestrator must do

1. Write `planning/<slug>/orchestration/roles.md` with the assigned model IDs (orchestrator-stamped — source of truth).
2. Run council agents in parallel; synthesize by evidence, not majority vote.
3. Plan review round 1 = fresh `plan-reviewer`. Rounds 2+ = resume the same critic when possible; else fresh + full review log. Append `reviews/plan-review-log.md`.
4. Require dated `Plan approved by user` (+ degraded override when needed) before execution.
5. Execute non-overlapping phases in worktrees. Prefer builder ≠ plan author.
6. Phase review: different model from builder; reviewer runs proof; resume same critic on fixes when possible.
7. Same-family or unverified diversity → DEGRADED only; human `APPROVED_BY_USER:<date>` required before code/merge.

## Parallelism

Phases with no dependency or file overlap may use Cursor `/multitask` or separate worktrees. Each phase has one owner. Locks + claim refs (when a remote exists) + the `plan.md` status board arbitrate.
