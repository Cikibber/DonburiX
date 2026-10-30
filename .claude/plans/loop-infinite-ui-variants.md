# Loop Runbook — Infinite UI Variants (safe mode)

Pattern: infinite agentic loop, waves of 3 parallel agents.
Mode: safe — strict quality gates and checkpoints.
Stop condition: max 3 waves, then halt regardless.

## Task spec

Generate spec-driven UI screen variants for DonburiX mobile
(`apps/mobile`), building on existing features:
Bowl Builder, Cart (`CartScreen`), Checkout (`CheckoutScreen`),
Orders (`OrdersScreen`), Order Detail (`OrderDetailScreen`).

Source of truth: `docs/tugas5/README.md`, `apps/mobile/lib/app.dart`,
`apps/mobile/lib/features/cart/presentation/cart_screen.dart`,
`apps/mobile/lib/features/orders/presentation/`.

## Wave plan

| Wave | Agent assignments (unique creative directions) |
| --- | --- |
| 1 | A1: Cart empty-state variants; A2: Checkout form layout variants; A3: Order timeline variants |
| 2 | B1: refine best Wave-1 cart variant; B2: refine best checkout variant; B3: refine best timeline variant |
| 3 | C1–C3: final polish pass on the 3 selected variants, no new directions |

Rules per agent:
- Each agent gets a unique direction and a unique iteration number.
- Output under `.claude/iterations/ui-variants/N/`.
- Never edit `lib/` directly; produce variant specs plus patch files.
- Uniqueness check against prior iterations before saving.

## Safe-mode gates per wave

1. `dart format --output=none --set-exit-if-changed lib test`
2. `flutter analyze` — zero issues required.
3. `flutter test --coverage` — all 35 tests must pass.
4. Checkpoint review before next wave: orchestrator selects winners,
   discards the rest, records decision in `SHARED_TASK_NOTES.md`.
5. No commit without passing gates. Conventional commits only.

## Context bridge

`SHARED_TASK_NOTES.md` at repo root persists across waves:

- Progress checklist (done / still need).
- Winning variant per wave and why.
- Next-wave focus.

Each wave starts by reading it and ends by updating it.

## Start commands

Wave 1 (3 parallel agents, each with full spec plus unique direction):

```bash
# A1 — cart empty-state variants, iteration 1
# A2 — checkout layout variants, iteration 2
# A3 — order timeline variants, iteration 3
```

Run each agent with the task spec above, its unique direction,
its iteration number, and a snapshot of existing iterations.

## Monitor commands

```bash
git status --short --branch
git log --oneline -8
# from apps/mobile:
flutter analyze
flutter test --coverage
```

## Stop

After wave 3: halt. Orchestrator writes final summary to
`SHARED_TASK_NOTES.md` and proposes one commit. No wave 4
without explicit user approval.
