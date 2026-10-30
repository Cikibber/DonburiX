# SHARED TASK NOTES — Infinite UI Variants Loop

## Progress

- [x] Safety checks pass: repo clean, tests 35/35 green, runbook written.
- [ ] Wave 1: cart empty-state / checkout layout / timeline variants.
- [ ] Wave 2: refine winners.
- [ ] Wave 3: final polish, then halt.

## Winners

- None yet.

## Next Steps

- Start Wave 1 with 3 parallel agents, unique directions, iterations 1–3.
- Output under `.claude/iterations/ui-variants/N/`.
- No direct `lib/` edits; specs plus patches only.
- Agents cannot run shell. Human or CI runs `./scripts/verify.ps1`
  (or `/scripts/verify.sh`). Do not mark gates green without that result.
