# Bootstrap Prompt — NEW Project (from zero)

Paste everything below into Claude Code inside an empty directory. Replace `<PROJECT-NAME>` first. Claude will initialize the repository, install the workflow, scaffold the project memory, and hand you a ready environment.

---

You are initializing a brand-new project called **<PROJECT-NAME>** with the **claude-planning-kit** workflow (spec-driven planning + continuous lock-safe execution) composed with selected Superpowers skills. Perform every step yourself, verify as you go, and report at the end. Do not start building any feature in this session.

## Step 1 — Initialize the repository

```bash
git init -b main
printf "node_modules/\n.env\n.env.*\n!.env.example\ndist/\n.DS_Store\n" > .gitignore
printf "# <PROJECT-NAME>\n\nProject initialized with claude-planning-kit v2.\n" > README.md
```

## Step 2 — Install the planning kit (vendored copy)

```bash
git clone --depth 1 https://github.com/LeopoldoJacobsen/claude-planning-kit /tmp/cpk
mkdir -p .claude/skills .claude/agents
cp -r /tmp/cpk/plugins/planning-kit/skills/. .claude/skills/
cp -r /tmp/cpk/plugins/planning-kit/agents/. .claude/agents/
```

(Note for the human: for auto-updates instead of a vendored copy, run `/plugin marketplace add LeopoldoJacobsen/claude-planning-kit` and `/plugin install planning-kit@claude-planning-kit` yourself — skills then live under the `/planning-kit:` namespace.)

## Step 3 — Create CLAUDE.md with the triage router

Create `CLAUDE.md` at the root containing: a one-paragraph project description (name + `TBD` placeholders for stack and purpose), followed by the full "Task Triage" block copied from `/tmp/cpk/templates/CLAUDE-md-snippet.md`.

## Step 4 — Scaffold the project memory

Create `memory-bank/` with `project-brief.md`, `architecture.md`, `decisions.md`, `changelog.md`, and `glossary.md`. Fill in the project name and today's date; mark everything else `TBD`. The pipeline's DISCOVERY phase will populate these as real decisions are made.

## Step 5 — Cherry-pick Superpowers skills (execution-level only)

```bash
git clone --depth 1 https://github.com/obra/superpowers /tmp/sp
for s in brainstorming test-driven-development systematic-debugging requesting-code-review; do
  cp -r "/tmp/sp/skills/$s" .claude/skills/ 2>/dev/null || echo "skill $s not found — check /tmp/sp/skills and adjust"
done
```

**Do NOT copy** `writing-plans`, `executing-plans`, `subagent-driven-development`, or `using-git-worktrees` — they compete with the kit's planner and executor.

## Step 6 — Verify and commit

1. Confirm: `.claude/skills/feature-planning/`, `.claude/skills/plan-execution/`, both agents, the four Superpowers skills, `CLAUDE.md` with the triage block, and `memory-bank/` with five files. Show a short tree as proof.
2. Commit:

```bash
git add -A
git commit -m "chore: initialize <PROJECT-NAME> with claude-planning-kit v2 + selected Superpowers skills"
```

Clean up `/tmp/cpk` and `/tmp/sp`.

## Step 7 — Report and hand off

Summarize what was created, then tell the user exactly this: "The project is ready. Describe your first feature in plain language — Portuguese or English. If it's still a vague idea, I'll run brainstorming first and turn it into a design doc; if it's already a defined scope, the planning pipeline starts at discovery. Either way: plan → independent review → your approval → continuous execution, ending with your personal checklist of tests and inputs." Then stop — do not begin planning in this session.
