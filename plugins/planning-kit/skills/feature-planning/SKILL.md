---
name: feature-planning
description: Context-optimized planning pipeline for features and significant changes. Use whenever the user asks to implement, build, add, create, refactor, or change anything that touches database schema, API contracts, environment variables, auth/permissions, payments, multi-tenancy, more than ~3 files, or another repository — even if they never say "plan". Also use when starting a brand-new project. Runs as a state machine (optional brainstorm → discovery → questions → plan → independent review → continuous execution) with artifacts persisted in planning/<slug>/ so any session can resume. Do NOT use for trivial one-or-two-file fixes with no schema, contract, env, auth, or payment impact.
---

# Feature Planning Pipeline (v2)

This skill is a **state machine over artifacts**. Every phase writes its output to `planning/<slug>/` — files on disk, not chat history, are the durable memory, so ANY session can resume from them.

**Session policy (v2):** run phases **continuously in the same session** by default. Do NOT stop or ask the user to `/clear` between phases. Write each artifact at its phase boundary, then keep going. Pause only when: (a) a phase needs the user's answers or decisions (QUESTIONS, plan approval, review fixes needing a call), or (b) context is degrading after a very long run — then checkpoint (state is already on disk) and suggest a fresh session as the exception, not the rule.

## Step 0 — Triage check

If the request is genuinely trivial (DIRECT tier per the project's CLAUDE.md triage rules: ≤2 files, no schema/contract/env/auth/payment impact), say so, skip this pipeline, and just do the task. Otherwise continue.

## Step 0.5 — BRAINSTORM (optional, when the idea is vague)

If the feature request is a rough idea rather than a defined scope AND the `superpowers:brainstorming` skill is installed, invoke it FIRST. Its approved design doc becomes the FEATURE REQUEST: copy or link it to `planning/<slug>/design.md`, then continue to DISCOVERY. **Important:** do NOT let brainstorming hand off to `superpowers:writing-plans` — this pipeline owns planning. If brainstorming is not installed, compensate with broader QUESTIONS later.

## On start

1. Derive a short slug from the feature request (e.g., `affiliate-system`).
2. Inspect `planning/<slug>/` and pick the next phase from the state table.
3. Announce the phase, run it, write its artifact, and continue to the next phase in this same session (per the session policy above).
4. The user may override the state table at any time (e.g., "run REVIEW again").

**State table (first missing artifact wins):**

| If this is missing | Run this phase |
|---|---|
| `planning/<slug>/context-snapshot.md` | DISCOVERY |
| `planning/<slug>/decisions.md` | QUESTIONS |
| `planning/<slug>/plan.md` | PLANNING |
| `planning/<slug>/plan-review.md`, or its verdict is `CHANGES REQUIRED` | REVIEW / PLAN FIX |
| — (review verdict is `APPROVED`) | EXECUTION — continuous, via the plan-execution skill |

## Global rules (every phase)

1. **Language:** the user may write in Portuguese or English; ALL output must be in American English.
2. **Never assume.** Anything unverifiable becomes a clarifying question — never a guess. Cite file paths for every claim about the project.
3. **Context budget:** never dump whole files into the conversation. Read only the sections needed; reference by `path:line`. Artifacts contain compressed findings, not transcripts. Target: `context-snapshot.md` under ~2 pages; every phase file fully self-contained.
4. **Delegate exploration:** use the `repo-explorer` subagent for discovery (one invocation per area) and the `plan-reviewer` subagent for review. Subagents have their own context window; only their compressed reports enter this session.
5. **Read-only until execution:** DISCOVERY through REVIEW must not modify any project file. Only writes allowed: `planning/<slug>/` and, for brand-new projects, the `memory-bank/` scaffold.
6. **Closed scope:** plan exactly the requested feature. Adjacent ideas go under "Out of scope / future work."
7. **Compose, don't duplicate:** if an installed skill or subagent already covers a procedure, the plan references it by name instead of restating its content. When Superpowers skills are installed, prefer naming `superpowers:test-driven-development` for logic-heavy phases, `superpowers:systematic-debugging` for bug-hunting work, and `superpowers:requesting-code-review` as the pre-merge gate — inside each phase's required tooling. Other skills are loaded by the executor at execution time, never during planning.

## PHASE: DISCOVERY → `planning/<slug>/context-snapshot.md`

If the repo is brand new or empty: create the context scaffold (`memory-bank/` with project-brief.md, architecture.md, decisions.md, changelog.md, glossary.md, plus a root `CLAUDE.md`), write a minimal snapshot marking everything `TBD` (but include an AVAILABLE TOOLING list of user-level skills/agents, which exist even in an empty repo), and continue to QUESTIONS.

For existing projects: read `AGENTS.md` / `CLAUDE.md` / memory-bank docs FIRST and obey their conventions; flag conflicts between them and the actual code. Then dispatch the `repo-explorer` subagent once per area, passing the area letter and a one-paragraph feature summary:

- **A. Boundaries & stack:** repo purpose; monorepo/multi-repo role; contracts dictated to or consumed from other repos (shared APIs, SDKs, schemas, packages); languages/frameworks/versions from manifests.
- **B. Data layer:** database(s), ORM, schema/models relevant to this feature, migration workflow.
- **C. Overlapping features & auth:** anything similar or touching (users, roles, invitations, emails, payments, commissions, dashboards, multi-tenancy); how identity, sessions, and roles work today. Reuse before rebuild.
- **D. Integrations & config:** email/payment/queue/webhook providers already wired in; env vars in use; NEW env vars this feature implies.
- **E. Deploy & conventions:** hosting, CI/CD, environments; testing framework, linting, commit style, feature flags.
- **F. Available tooling:** installed skills (`.claude/skills/`, `~/.claude/skills/`, plugins), subagents, slash commands, MCP servers. Record name + one-line purpose from descriptions only — do NOT load any skill body during discovery.

Merge the reports into the snapshot: compressed findings per area **with evidence paths**, an **"AVAILABLE TOOLING"** list, plus a final section **"NOT VERIFIED"**. Continue.

## PHASE: QUESTIONS → `planning/<slug>/decisions.md`

Load ONLY `context-snapshot.md` + the feature request (+ `design.md` if brainstorming produced one). Do not re-explore the repo except targeted double-checks.

Produce a numbered list of clarifying questions for every ambiguity the snapshot cannot answer: product behavior, edge cases, data ownership, cross-repo responsibility, roles/permissions, payout/scheduling rules, UI expectations, migration of existing data — **and which inputs or actions will require the USER personally** (credentials, accounts, real test transactions, approvals). Each question: **why it matters** + **suggested default** when reasonable (so the user can reply "accept defaults"). Ask in one batch. **PAUSE and wait for answers** (this is a legitimate stop).

After the user answers, write `decisions.md` as a table: question → decision → rationale/source. Continue.

## PHASE: PLANNING → `planning/<slug>/plan.md` + `planning/<slug>/phases/phase-N.md` + `planning/<slug>/user-tasks.md`

Load ONLY the snapshot + decisions (+ design.md if present, plus targeted file checks if strictly needed).

`plan.md` is an **overview + index**, max ~2 pages: Summary; Goals / Non-goals; key design and where each responsibility lives (this repo vs. connected repos); data-model overview; API surface and impact on consumer repos; new environment variables; security and multi-tenant isolation; risks & mitigations; testing and rollout strategy; the integration target branch (default `main`; use `feat/<slug>/integration` for large features); a phase index table (**phase, one-line goal, depends-on, executor, status: pending/in-progress/done, branch**) that doubles as the execution status board; open questions (near zero).

**Executor classification & sequencing (MANDATORY):** tag every phase `executor: agent` or `executor: user`. A USER phase is anything agents cannot complete alone: manual or visual QA, real payment/affiliate/checkout test transactions, credentials or API keys, DNS and domain changes, third-party approvals, stakeholder sign-off. Sequencing rules:

1. Inputs agents need BEFORE work can start (keys, accounts, access, product decisions) are consolidated into a single **Phase 0 — User Prerequisites** checklist, collected up front — never scattered through the plan.
2. Every other USER phase is sequenced **AFTER the last agent phase**. Human validation happens at the end, in one batch, so it never blocks agents working in parallel.
3. **No agent phase may depend on a user phase** (other than Phase 0). If a mid-stream user checkpoint seems unavoidable, redesign the phase — mock, stub, sandbox/test-mode, or feature flag — so agents can finish and the human verification moves to the final block.
4. Also write `planning/<slug>/user-tasks.md`: the consolidated human checklist (Phase 0 prerequisites + final validations), each item with exact steps and what "pass" looks like.

Each implementation phase gets its own `phases/phase-N.md` containing everything an executor needs **without reading anything else**: goal; executor tag; **required tooling** (skills/subagents/MCP servers the executor must load or dispatch — only ones confirmed in the snapshot's AVAILABLE TOOLING list; if something ideal is missing, add it to `plan.md` under "Recommended installs" as a user decision); exact files to touch; ordered steps; migrations; acceptance criteria; test commands; rollback note. Keep phases small — independently shippable and verifiable. Continue.

## PHASE: REVIEW → `planning/<slug>/plan-review.md`

Dispatch the `plan-reviewer` subagent with the paths to `plan.md`, `phases/`, `user-tasks.md`, `context-snapshot.md`, and — when brainstorming produced one — `design.md`. Its fresh context is the point: if the plan cannot be validated from the artifacts alone, it is under-specified. Among its failure classes, it will reject any user-dependent step buried mid-plan and, when a design doc exists, any undocumented divergence between the plan and the decisions approved in brainstorming.

Save the subagent's full report verbatim to `plan-review.md`, including its verdict: `APPROVED` or `CHANGES REQUIRED` with numbered findings (severity, evidence path, suggested fix).

If changes are required, run **PLAN FIX** in this same session: address every finding, update plan/phase files, mark each finding resolved, re-dispatch `plan-reviewer`. Loop until `APPROVED`. Then present the approved plan + the Phase 0 user-prerequisites checklist to the user, and — once prerequisites are confirmed — hand off to the **`plan-execution`** skill.

## PHASE: EXECUTION — continuous, via the plan-execution skill

Execution follows the **`plan-execution` skill** (or the standalone Plan Execution Protocol prompt if the skill is not installed). v2 behavior: it claims and executes eligible AGENT phases **continuously in one session** — lock-protected so parallel sessions never collide — never claims `executor: user` phases, and when only user tasks remain it compiles and presents `user-tasks.md` as the final human checklist.
