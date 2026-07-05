# claude-planning-kit

**English** | [Português (BR)](README.pt-BR.md) | [Español](README.es.md)

A planning and execution kit for Claude Code. It works as a reusable "starter prompt": install it in any project (new or existing) and Claude starts planning and executing improvements in a structured way — with codebase discovery, batched questions, a plan reviewed by an independent agent, and continuous conflict-safe execution.

> **Visual overview:** [leopoldojacobsen.github.io/claude-planning-kit](https://leopoldojacobsen.github.io/claude-planning-kit/) — how it works, the full workflow, and what it does / doesn't do, on a single page.

**The full loop:**

```
triage → (brainstorm if the idea is vague) → discovery → questions → plan
      → independent review → continuous execution → final human checklist
```

Everything becomes a file in `planning/<slug>/` — any session resumes from where it stopped, without depending on chat history.

## Installation

> Kit already installed in the project? There's nothing to memorize and no command to run — just describe what you want. See [Day-to-day usage](#day-to-day-usage).

### Option 1 — Bootstrap prompt (recommended: Claude does everything)

| Situation | What to do |
|---|---|
| **Existing project** | Open Claude Code at the repository root and paste the contents of [`prompts/BOOTSTRAP-EXISTING-PROJECT.md`](prompts/BOOTSTRAP-EXISTING-PROJECT.md) |
| **New project (empty folder)** | Open Claude Code in the folder and paste [`prompts/BOOTSTRAP-NEW-PROJECT.md`](prompts/BOOTSTRAP-NEW-PROJECT.md), replacing only `<PROJECT-NAME>` with your project's name |

The prompts already point to this repository (`LeopoldoJacobsen/claude-planning-kit`) — just copy and paste. Claude installs the skills, wires the triage router into `CLAUDE.md`, pulls the 4 compatible Superpowers skills, verifies everything, and commits.

### Option 2 — Plugin marketplace (with auto-update)

Inside Claude Code:

```
/plugin marketplace add LeopoldoJacobsen/claude-planning-kit
/plugin install planning-kit@claude-planning-kit
```

The skills become available as `/planning-kit:feature-planning` and `/planning-kit:plan-execution`. Then add the "Task Triage" block from [`templates/CLAUDE-md-snippet.md`](templates/CLAUDE-md-snippet.md) to each repository's `CLAUDE.md`.

### Option 3 — Manual copy

Copy `plugins/planning-kit/skills/*` into the project's `.claude/skills/` and `plugins/planning-kit/agents/*` into `.claude/agents/` (or into `~/.claude/`, applying to all projects). Add the triage block to `CLAUDE.md`.

Full details for all three options in [INSTALL.md](INSTALL.md).

## Day-to-day usage

1. **Describe the improvement normally**, in Portuguese, English, or Spanish (e.g., "I want an affiliate system with 10% commission"). No need to say "plan".
2. The triage router classifies it on its own:

| Level | When | What happens |
|---|---|---|
| **DIRECT** | Trivial fix, ≤2 files, no schema/API/env/auth/payment impact | Just does it |
| **LIGHT** | 3–10 files, moderate logic | 5–10 line mini-plan in chat; you give the "go" |
| **FULL** | New feature, database schema, API contracts, env vars, auth, payments, multi-tenant | Full pipeline below |

3. **In the FULL pipeline:** a vague idea goes through brainstorming first. Then Claude explores the repository (discovery), asks **a single batch of questions** — the only pause before approval —, writes the plan split into phases, and an independent reviewer with a clean context validates everything.
4. **You approve the plan and confirm the Phase 0 prerequisites** (API keys, accounts, product decisions) — collected once, up front.
5. **Continuous execution:** Claude executes all agent phases back-to-back (parallel sessions welcome; locks prevent collisions) and finishes by handing you `user-tasks.md` — your list of manual tests, validations, and sign-offs, batched at the end so they never block the agents.
6. **Executing or resuming later:** in any new session, say "continue the plan" or "execute the affiliate-system plan" — or just reference the `planning/<slug>/` folder. State lives on disk, so execution picks up exactly where it stopped, even days later or on a teammate's machine.

## What's inside

```
.claude-plugin/marketplace.json    # marketplace manifest (enables /plugin marketplace add)
plugins/planning-kit/
  skills/feature-planning/         # planning state machine (artifacts in planning/<slug>/)
  skills/plan-execution/           # continuous executor: locks, worktrees, scope fence, definition of done
  agents/repo-explorer.md          # read-only discovery subagent (own context window)
  agents/plan-reviewer.md          # adversarial plan reviewer with a clean context
templates/CLAUDE-md-snippet.md     # 3-tier triage router for each repo's CLAUDE.md
prompts/                           # bootstrap prompts (new/existing project) + standalone versions
```

The standalone versions (`prompts/*-standalone.md`) are for agents without skill support: paste the whole prompt into the session and the pipeline runs the same way.

## Design principles

- **Disk > chat:** every phase writes an artifact to `planning/<slug>/`; any session resumes from the files.
- **Continuous by default (v2):** phases run back-to-back in the same session; `/clear` is a pressure valve, not a ritual.
- **Human work at the edges (v2):** prerequisites become Phase 0, collected up front; everything else that depends on you (manual QA, real payment/affiliate tests, DNS, approvals) is sequenced AFTER the last agent phase, in `user-tasks.md`. The reviewer rejects plans with human steps buried mid-stream.
- **Safe parallelism:** phases are claimed via lock files in the shared `.git` directory — independent sessions and teammates never collide.
- **Composes with Superpowers:** `brainstorming` refines vague ideas; `test-driven-development`, `systematic-debugging`, and `requesting-code-review` plug into execution. Superpowers' own planners/executors are NOT used.

## Superpowers compatibility

Install ONLY these skills: `brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`. NEVER install `writing-plans`, `executing-plans`, `subagent-driven-development`, or `using-git-worktrees` alongside the kit — two planners/executors fight for the same trigger. The bootstrap prompts already handle this automatically.

## Improving the kit

Treat skill text like code. After each real feature: read the execution logs in `planning/<slug>/execution/`, fold recurring deviations into the skills, bump the version in both manifests (`plugin.json` and `marketplace.json`), commit, and push. Projects installed via the marketplace pick up the update automatically; vendored copies re-run the bootstrap prompt.
