# Feature Planning Pipeline — Standalone Prompt (paste into a fresh agent session)

Paste this whole prompt, then add your feature under FEATURE REQUEST at the bottom. Works in any agent; references to subagents/skills degrade gracefully if unavailable (do the work inline instead, keeping each report within the same word limits).

# Feature Planning Pipeline (v2.2)

This skill is a **state machine over artifacts**. Every phase writes its output to `planning/<slug>/` and **commits it** — committed files, not chat history, are the durable memory, so any session (or teammate) can resume from them.

**Session policy:** run phases **continuously in the same session**, always. NEVER stop or ask the user to `/clear`, restart, or open a new session between phases — not for context size, not for any reason. Write and commit each artifact at its phase boundary, then keep going. The ONLY legitimate pauses are when a phase needs the user's answers or decisions (QUESTIONS, plan approval, review findings needing a product call). Context stays small by design: each phase loads only its listed inputs and delegates exploration to subagents.

## Step 0 — Triage (self-contained; mirrors the CLAUDE.md router when installed)

- **DIRECT** — trivial fixes or tweaks, ≤2 files, no schema/API-contract/env/auth/payment/multi-tenancy/cross-repo impact → skip this pipeline; just do the task.
- **LIGHT** — 3–10 files, still none of those impacts → skip this pipeline; write a 5–10 line mini-plan in chat, wait for a "go", execute in this session.
- **Anything else** (new feature, new project, any of those impacts, >10 files, multi-session) → continue below. When in doubt, continue below.

## Step 0.5 — BRAINSTORM (optional, when the idea is vague)

If the feature request is a rough idea rather than a defined scope AND a brainstorming skill is installed (named `superpowers:brainstorming` when installed as a plugin, or `brainstorming` when vendored — use the name that actually appears in the installed skills list), invoke it FIRST. Its approved design doc becomes the FEATURE REQUEST: copy or link it to `planning/<slug>/design.md`, then continue to DISCOVERY. **Important:** do NOT let brainstorming hand off to any other planning skill — this pipeline owns planning. If brainstorming is not installed, compensate with broader QUESTIONS later.

## On start

1. Derive a short slug from the feature request (e.g., `affiliate-system`).
2. Decide the **integration target** now: the repo's default branch, or `feat/<slug>/integration` when the default branch is protected or the feature is large. Record it as the first line of `context-snapshot.md` (`Integration target: <branch>`); `plan.md` later copies this value instead of defining it.
3. Inspect `planning/<slug>/` and pick the next phase from the state table.
4. Announce the phase, run it, write **and commit** its artifact, and continue to the next phase in this same session.
5. The user may override the state table at any time (e.g., "run REVIEW again").

**State table (first missing artifact wins):**

| If this is missing | Run this phase |
|---|---|
| `planning/<slug>/context-snapshot.md` | DISCOVERY |
| `planning/<slug>/decisions.md` | QUESTIONS |
| `planning/<slug>/plan.md` | PLANNING |
| `planning/<slug>/plan-review.md`, or its verdict is `CHANGES REQUIRED` | REVIEW / PLAN FIX |
| — (review verdict is `APPROVED`) | EXECUTION — continuous, via the plan-execution skill |

## Global rules (every phase)

1. **Language:** the user may write in any language; ALL artifacts and output must be in American English.
2. **Never assume.** Anything unverifiable becomes a clarifying question — never a guess. Cite file paths for every claim about the project. If a new ambiguity surfaces during PLANNING, either resolve it from `decisions.md` or mark it inline as `[NEEDS CLARIFICATION: …]` and ask the user in one small batch before REVIEW. A plan containing any remaining marker is not reviewable.
3. **Context budget:** never dump whole files into the conversation. Read only the sections needed; reference by `path:line`. Artifacts contain compressed findings, not transcripts. Targets: `context-snapshot.md` ≈ 800–1,000 words; `plan.md` overview ≈ 2 pages; every phase file fully self-contained.
4. **Delegate exploration:** use the `repo-explorer` subagent for discovery (one invocation per area) and the `plan-reviewer` subagent for review. Subagents have their own context window; only their compressed reports enter this session.
5. **Read-only until execution, but commit the plan:** DISCOVERY through REVIEW must not modify any project file. Only writes allowed: `planning/<slug>/` and, for brand-new projects, the `memory-bank/` scaffold. Commit `planning/<slug>/` at every phase boundary (`plan(<slug>): <phase>`) on the **integration target** branch decided at On start — these commits touch only `planning/` and are the one exception to never-committing-to-main. Without these commits, executor worktrees are created WITHOUT the plan.
6. **Closed scope:** plan exactly the requested feature. Adjacent ideas go under "Out of scope / future work."
7. **Compose, don't duplicate:** if an installed skill or subagent already covers a procedure, the plan references it instead of restating its content — always by the EXACT name recorded in the snapshot's AVAILABLE TOOLING list (namespaces differ per install: `superpowers:test-driven-development` as a plugin vs `test-driven-development` vendored). Prefer a TDD skill for logic-heavy phases, a systematic-debugging skill for bug-hunting work, and a code-review skill as the pre-merge gate, when installed. Skill bodies are loaded by the executor at execution time, never during planning.
8. **Project principles are gates:** if `memory-bank/decisions.md`, `memory-bank/architecture.md`, or a `constitution.md` exists, the plan must comply with their recorded decisions or explicitly document the deviation and its reason in `plan.md`. The reviewer checks this.

## PHASE: DISCOVERY → `planning/<slug>/context-snapshot.md`

If the repo is brand new or empty: create the context scaffold (`memory-bank/` with project-brief.md, architecture.md, decisions.md, changelog.md, glossary.md, plus a root `CLAUDE.md`), write a minimal snapshot marking everything `TBD` (but include an AVAILABLE TOOLING list of user-level skills/agents, which exist even in an empty repo), and continue to QUESTIONS.

For existing projects: read `AGENTS.md` / `CLAUDE.md` / memory-bank docs FIRST and obey their conventions; flag conflicts between them and the actual code. Then dispatch the `repo-explorer` subagent once per area, passing the area letter and a one-paragraph feature summary:

- **A. Boundaries & stack:** repo purpose; monorepo/multi-repo role; contracts dictated to or consumed from other repos (shared APIs, SDKs, schemas, packages); languages/frameworks/versions from manifests.
- **B. Data layer:** database(s), ORM, schema/models relevant to this feature, migration workflow.
- **C. Overlapping features & auth:** anything similar or touching (users, roles, invitations, emails, payments, commissions, dashboards, multi-tenancy); how identity, sessions, and roles work today. Reuse before rebuild.
- **D. Integrations & config:** email/payment/queue/webhook providers already wired in; env vars in use; NEW env vars this feature implies.
- **E. Deploy & conventions:** hosting, CI/CD, environments; testing framework, linting, commit style, feature flags; whether merges to the integration target go direct or via PR.
- **F. Available tooling:** installed skills (`.claude/skills/`, `~/.claude/skills/`, plugins), subagents, slash commands, MCP servers. Record name + one-line purpose from descriptions only — do NOT load any skill body during discovery.

Merge the reports into the snapshot — compress each area to ~150 words of findings **with evidence paths** — plus an **"AVAILABLE TOOLING"** list and a final **"NOT VERIFIED"** section. Continue.

## PHASE: QUESTIONS → `planning/<slug>/decisions.md`

Load ONLY `context-snapshot.md` + the feature request (+ `design.md` if brainstorming produced one). Do not re-explore the repo except targeted double-checks.

Produce a numbered list of clarifying questions for every ambiguity the snapshot cannot answer: product behavior, edge cases, data ownership, cross-repo responsibility, roles/permissions, payout/scheduling rules, UI expectations, migration of existing data — **and which inputs or actions will require the USER personally** (credentials, accounts, real test transactions, approvals). Each question: **why it matters** + **suggested default** when reasonable (so the user can reply "accept defaults"). Ask in one batch. **PAUSE and wait for answers** (this is a legitimate stop).

After the user answers, write `decisions.md` as a table: question → decision → rationale/source. Continue.

## PHASE: PLANNING → `planning/<slug>/plan.md` + `planning/<slug>/phases/phase-N.md` + `planning/<slug>/user-tasks.md`

Load ONLY the snapshot + decisions (+ design.md if present, plus targeted file checks if strictly needed). Copy the three skeletons below and fill EVERY section — write "None" rather than omitting a section.

**`plan.md`** — overview + index, max ~2 pages:

```markdown
# <Feature> — Plan
## Summary
## Goals / Non-goals
## Design & responsibilities        <!-- key decisions; what lives in this repo vs. connected repos -->
## Data model (overview)
## API surface & consumer impact
## New environment variables
## Security & multi-tenant isolation
## Risks & mitigations
## Testing & rollout
## Test baseline                    <!-- exact command(s) that run the full suite + what a pass looks like -->
## Integration target: <branch>     <!-- copy the value recorded on the first line of context-snapshot.md -->
## Merge convention: direct | PR    <!-- from the snapshot (area E); executors follow it without asking -->
## Recommended installs (optional)  <!-- ideal-but-missing tooling, as a user decision -->
## Phase index                      <!-- doubles as the execution status board -->
| # | Goal (one line) | depends-on | executor | status | branch |
|---|-----------------|------------|----------|--------|--------|
| 0 | User prerequisites | — | user | pending | — |
| 1 | <goal> | 0 | agent | pending | — |
<!-- status: pending | in-progress | awaiting-merge | done. "done" means MERGED into the integration target.
     Executors may add parenthetical notes, e.g. "awaiting-merge (chained)". -->
## Open questions                   <!-- near zero; [NEEDS CLARIFICATION] markers may not survive into REVIEW -->
```

**Executor classification & sequencing (MANDATORY):** tag every phase `executor: agent` or `executor: user`. A USER phase is anything agents cannot complete alone: manual or visual QA, real payment/affiliate/checkout test transactions, credentials or API keys, DNS and domain changes, third-party approvals, stakeholder sign-off. Sequencing rules:

1. Inputs agents need BEFORE work can start (keys, accounts, access, product decisions) are consolidated into a single **Phase 0 — User Prerequisites** checklist, collected up front — never scattered through the plan.
2. Every other USER phase is sequenced **AFTER the last agent phase**. Human validation happens at the end, in one batch, so it never blocks agents working in parallel.
3. **No agent phase may depend on a user phase** (other than Phase 0). If a mid-stream user checkpoint seems unavoidable, redesign the phase — mock, stub, sandbox/test-mode, or feature flag — so agents can finish and the human verification moves to the final block.
4. If the feature needs nothing from the user up front, keep Phase 0 in the index with goal "None — no prerequisites" and status `done`.

**`phases/phase-N.md`** — one per implementation phase; everything an executor needs **without reading anything else** (besides `plan.md`). Keep phases small — independently shippable, roughly one PR-sized change:

```markdown
# Phase N — <goal>
executor: agent | user
depends-on: [<phase numbers>]
files-to-touch:
  - <path/one>
  - <path/two>
required-tooling: <exact names from AVAILABLE TOOLING, or "none">

## Interfaces
<EXACT signatures, types, endpoints, schemas, env var names this phase creates or changes — names pinned
so the executor invents nothing. One concrete input → output example per new behavior.>

## Steps (ordered)
1. Write the failing tests that encode the acceptance criteria below (or follow the TDD skill named in required-tooling).
2. <step — imperative, one action, verifiable>

## Acceptance criteria
- WHEN <event/condition> THE SYSTEM SHALL <behavior> — verify: `<command>` → <expected result>

## Test commands
## Migrations
## Rollback
```

**`user-tasks.md`** — the consolidated human checklist:

```markdown
# User tasks — <slug>
## Phase 0 — Prerequisites (confirm before execution starts)
- [ ] <item — exact steps — what "pass" looks like>
Phase 0 confirmed by user: ____ (date)   <!-- the executor reads THIS line; fill it when the user confirms -->
## Final validations (after the last agent phase)
- [ ] <item — exact steps — what "pass" looks like — which phase it validates>
```

Write all files, commit, continue.

## PHASE: REVIEW → `planning/<slug>/plan-review.md`

Dispatch the `plan-reviewer` subagent with the paths to `plan.md`, `phases/`, `user-tasks.md`, `context-snapshot.md`, and — when brainstorming produced one — `design.md`. Its fresh context is the point: if the plan cannot be validated from the artifacts alone, it is under-specified. Among its failure classes, it will reject any user-dependent step buried mid-plan, any remaining `[NEEDS CLARIFICATION]` marker, any acceptance criterion without a runnable verification, and — when a design doc exists — any undocumented divergence from the decisions approved in brainstorming.

Save the subagent's full report verbatim to `plan-review.md`, including its verdict: `APPROVED` or `CHANGES REQUIRED` with numbered findings (severity, evidence path, suggested fix).

If changes are required, run **PLAN FIX** in this same session: findings that need a product call the artifacts cannot answer go to the user; address every other finding autonomously, update plan/phase files, mark each finding resolved, re-dispatch `plan-reviewer`. **After 3 rounds without `APPROVED`, stop and present the remaining findings to the user as decisions** (a legitimate pause). Once `APPROVED`: present the plan + the Phase 0 prerequisites checklist to the user. When the user confirms the prerequisites, **record it on disk**: check the Phase 0 boxes and fill the "Phase 0 confirmed by user" line in `user-tasks.md`, flip Phase 0's row to `done` in `plan.md`, commit — then hand off to the **`plan-execution`** skill. No later session should ever have to re-ask.

## PHASE: EXECUTION — continuous, via the plan-execution skill

Execution follows the **`plan-execution` skill** (or the standalone Plan Execution Protocol prompt if the skill is not installed). It claims and executes eligible AGENT phases **continuously in one session** — lock-protected so parallel sessions never collide — never claims `executor: user` phases, and when only user tasks remain it compiles and presents `user-tasks.md` as the final human checklist.

---

## FEATURE REQUEST

<PASTE YOUR FEATURE / TASK / OBJECTIVE HERE — any language>
