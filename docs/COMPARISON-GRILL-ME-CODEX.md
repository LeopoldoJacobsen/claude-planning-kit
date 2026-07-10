# Strategy comparison: claude-planning-kit vs. grill-me-codex

Comparison baseline: `chaseai-yt/grill-me-codex` commit `fe37a7083e93e61d46e84cb8ccdd901fa8aa90fc` (2026-07-08).
Kit version analyzed: **v2.4** (hybrid adoption after multi-model council review: Grok 4.5, GPT 5.6, Fable 5).

## Shared principles

Both projects freeze a written plan before implementation, use an independent critic, bound review loops, preserve an audit artifact, and keep humans at explicit gates. Both require that **nobody grades their own work**.

## Where each is stronger

| Concern | claude-planning-kit | grill-me-codex |
|---|---|---|
| Durable state and resume | Strong: per-feature artifacts, phase files, status board, execution logs | Strong review log, but a flatter `PLAN.md` workflow; critic thread dies with the session |
| Parallel implementation | Strong: dependency/file-overlap eligibility, locks, worktrees | One external builder session; not a phase scheduler |
| Cross-model diversity | v2.4: Cursor `model:` pins + orchestrator-stamped role matrix + DEGRADED gate | Strong by construction: Claude ↔ Codex are different providers |
| Critique continuity | v2.4: resume same plan/impl critic; append-only review logs with ACCEPTED/REJECTED | Same Codex thread verifies prior objections efficiently |
| Plan executability | Exact interfaces, files, commands, acceptance criteria, migration and rollback gates | More compact plan contract; quality depends more on the dialogue |
| Role-flip build | v2.4: builder ≠ planner preferred; reviewer ≠ builder hard; reviewer runs proof | Codex builds, Claude reviews full diff — structural role flip |
| Cursor fit | Provider-neutral artifacts + installable Cursor agents/rule with `model`/`readonly` | Primarily Claude Code calling Codex CLI |
| Failure containment | Worktrees, scope fences, baseline tests, rollback; stop-and-surface at fix cap | Clean-tree gate, bounded fix loop; reviewer-takes-over after cap (reintroduces self-grading) |

## Adopted improvements (v2.4)

Transferred from Grill Me without hard-coding Codex:

1. **Append-only review logs** (`reviews/plan-review-log.md`, `reviews/phase-N-review-log.md`) with ACCEPTED/REJECTED reasons.
2. **Persistent critic threads** — round 1 fresh; rounds 2+ resume the same reviewer.
3. **Hard DEGRADED gate** — same-family review cannot authorize execution/merge alone; human override on disk required.
4. **Orchestrator-stamped role matrix** (`orchestration/roles.md`) — assignment is source of truth; agent self-report is a cross-check only.
5. **Cursor agent templates** with `model:` / `readonly: true` so diversity is configuration, not prose.
6. **Role-flip execution** — prefer builder ≠ plan author; reviewer ≠ builder; implementer proof is advisory.
7. **Clean worktree gate** before phase writes.
8. **Keep kit's stop-and-surface** at the fix cap (do not copy grill-me's "reviewer finishes the code").

Deliberately **not** copied: Codex CLI plumbing, root-level `PLAN.md`, mandatory one-question grilling for every FULL task, monolithic single-builder sessions, `--yolo` / sandbox bypass patterns.

## Recommended strategy

Use the kit as the Cursor multi-agent chassis with the **pinned trio** (`gpt-5.6-sol-max-fast`, `grok-4.5-fast-xhigh`, `claude-fable-5-thinking-max`). Use best-of-three for consequential design, then a persistent plan critic from a family different from the planner (one of the three not used as planner). Give implementation ownership to one agent per non-overlapping phase. Require a different reviewer before merge. For ad-hoc reviews of any diff, run `/multi-model-review` (ships in `templates/cursor/commands/`).
