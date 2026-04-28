---
name: scaffold-feature
description: Use when starting a new full-stack feature and needing a vertical slice (UI + API + DB + tests) scaffolded in one pass, or "/scaffold-feature". Produces an ordered file plan with stub contents, not full implementations.
tools: [cursor, claude, copilot]
---

# scaffold-feature

## When to use

- "scaffold the <X> feature"
- "set up the files for <feature>"
- "/scaffold-feature"
- After `design-api-contract` and `design-data-model` are done.

## Preconditions

- API contract exists (OpenAPI / GraphQL SDL or markdown spec).
- Data model exists (schema + migration plan).
- Repo conventions known: which folders, which test runner, which generator.

## Procedure

1. **Confirm the slice.** One user-visible capability, end to end. If multiple, scaffold one; the rest follow.

2. **List the files in dependency order:**

   1. Migration (DB schema)
   2. Types / generated client (from the contract)
   3. Backend handler / resolver
   4. Backend unit tests
   5. Backend integration test (handler + DB, no UI)
   6. Frontend data hook (calls the typed client)
   7. Frontend component (presentational + container split)
   8. Frontend unit tests (component + hook)
   9. One E2E test for the happy path
   10. Docs / changelog entry

3. **For each file:** path (matching repo conventions), one-sentence purpose, **stub content with TODO markers** — not full implementation. Test stubs name the cases (`it("returns 404 when order not found")`), bodies TODO.

4. **Keep the slice thin.** No optional fields, no admin views, no bulk operations in the first slice.

5. **Cross-tier consistency check:**
   - UI types generated from the same spec the backend serves.
   - UI handles every error code the backend can return.
   - All 4 UI states represented (loading / empty / error / success).

## Output

```markdown
## Feature scaffold — <feature>

**Slice:** <one user capability>
**Contract:** <link to spec>
**Migration:** <number / file>

### File plan
1. `db/migrations/0042_create_orders.sql` — schema (from design-data-model).
2. `packages/api-types/orders.ts` — generated from OpenAPI; do not edit.
3. `apps/api/src/orders/handler.ts` — POST /orders handler.
4. `apps/api/src/orders/handler.test.ts` — unit tests.
5. `apps/api/test/orders.int.test.ts` — integration test against test DB.
6. `apps/web/src/features/orders/useCreateOrder.ts` — typed hook.
7. `apps/web/src/features/orders/CreateOrderForm.tsx` — form, all 4 UI states.
8. `apps/web/src/features/orders/CreateOrderForm.test.tsx` — RTL tests.
9. `e2e/orders/create-order.spec.ts` — Playwright happy path.
10. `CHANGELOG.md` — feat entry.

### Stubs
```ts
// apps/api/src/orders/handler.ts
import { CreateOrderRequest, CreateOrderResponse } from "@acme/api-types";
export async function createOrder(/* TODO */) {
  // TODO: validate -> insert -> return 201
}
```
(… one stub per file …)

### Out of scope for this slice
- Bulk create.
- Admin override of status.
- Order cancellation flow (separate slice).
```

## Guardrails

- NEVER generate full implementations — stubs with TODOs only. Scaffolding is a planning tool, not a code generator.
- NEVER scaffold across more than one vertical slice in a single invocation.
- NEVER introduce a new dependency without flagging it explicitly.
- If contract or data model is missing, stop and ask — don't guess.
- If repo conventions are unknown, ask which folder layout / test runner is used before producing paths.
- Mark generated type files "do not edit" in the stub comment.
