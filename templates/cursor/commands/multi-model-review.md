# Multi-model review (planning-kit default trio)

Run an adversarial multi-model review using these three Task/subagent model slugs in parallel — do not substitute other models unless the user explicitly overrides in the text after this command:

1. `claude-fable-5-thinking-max`
2. `gpt-5.6-sol-max-fast`
3. `grok-4.5-fast-xhigh`

Any text the user typed after `/multi-model-review` is additional scope/context.

## Steps (mandatory)

1. **Scope:** Prefer user-specified paths/diff. Else `git diff main...HEAD` (or repo default base). Else staged + unstaged diffs. Else files from this conversation.
2. **Intent:** Write one clear paragraph of what the change is trying to accomplish.
3. **Launch in parallel:** In a single assistant turn, launch three Task subagents (`subagent_type: generalPurpose`, `readonly: true`) with `model` set to each slug above. Do not wait for one before starting the next.
4. **Same prompt for each reviewer**, including:
   - The intent paragraph
   - The code/diff under review (or paths to read)
   - Instructions: adversarial review; prioritize bugs, correctness, security, maintainability; findings with severity `critical | warning | nit`, location, evidence, optional suggestion; say `no findings` if nothing is wrong
5. **Synthesize (you, parent):** Merge findings into consensus (2+ models), lone-model findings, disagreements. Categorize: act on / consider / noted / dismissed, with brief rationale.
6. **Do not edit or commit** unless the user explicitly asks after the synthesis.

## Output format

```markdown
## Multi-model review
Models: claude-fable-5-thinking-max | gpt-5.6-sol-max-fast | grok-4.5-fast-xhigh
Intent: <one paragraph>

### Consensus (2+)
- ...

### Lone-model
- ...

### Disagreements
- ...

### Recommended actions
- Act on: ...
- Consider: ...
- Noted / dismissed: ...
```

If a selected slug is rejected at runtime, use the closest valid slug suggested by the Task tool feedback and record the substitution in the synthesis.
