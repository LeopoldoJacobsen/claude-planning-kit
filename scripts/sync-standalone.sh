#!/bin/sh
# Regenerates prompts/*-standalone.md from the SKILL.md bodies (single source of truth).
# Run after editing either skill, before committing.
set -e
cd "$(dirname "$0")/.."

body() { awk '/^---$/ && n < 2 { n++; next } n >= 2' "$1"; }

{
  printf '# Feature Planning Pipeline — Standalone Prompt (paste into a fresh agent session)\n\n'
  printf 'Paste this whole prompt, then add your feature under FEATURE REQUEST at the bottom. Works in any agent; references to subagents/skills degrade gracefully if unavailable (do the work inline instead, keeping each report within the same word limits).\n'
  body plugins/planning-kit/skills/feature-planning/SKILL.md
  printf '\n---\n\n## FEATURE REQUEST\n\n<PASTE YOUR FEATURE / TASK / OBJECTIVE HERE — any language>\n'
} > prompts/feature-planning-standalone.md

{
  printf '# Plan Execution Protocol — Standalone Prompt (paste into a fresh agent session)\n\n'
  printf 'Fill in TARGET at the bottom, then paste this whole prompt into a session opened at the repo root (or inside a phase worktree).\n'
  body plugins/planning-kit/skills/plan-execution/SKILL.md
  printf '\n---\n\n## TARGET\n\nSLUG: <feature slug, e.g. affiliate-system>\nPHASE: <N, or "next" — the loop continues automatically from there>\n'
} > prompts/plan-execution-standalone.md

echo "regenerated: prompts/feature-planning-standalone.md, prompts/plan-execution-standalone.md"
