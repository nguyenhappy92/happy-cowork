---
name: backend-endpoint-review
description: Use when reviewing a backend HTTP / GraphQL handler for validation, authz, errors, performance, observability, and security, or "/backend-review". Produces a structured review with file:line citations.
tools: [cursor, claude, copilot]
---

# backend-endpoint-review

## When to use

- "review this handler / controller / resolver"
- "is this endpoint safe?"
- "check this API code"
- "/backend-review"

## Inputs

- One or more handler files plus the route registration.
- The API contract (OpenAPI / GraphQL SDL) if available.
- Optionally: the data layer (queries / repository) and tests.

## Procedure

1. **Read end-to-end first.** Trace the request: route → middleware → handler → service → data → response.

2. **Validation at the edge:**
   - Every input parsed and validated at the boundary (zod / pydantic / class-validator / joi).
   - Reject unknown fields by default.
   - Reject inputs of unbounded size (string length, array length, file size, depth).

3. **Authentication & authorization:**
   - Auth check present and runs before any data access.
   - Authorization is **per-resource** (the actor can act on **this** record), not just role-based.
   - Multi-tenant: every query scoped by `tenant_id` — no exception.
   - No IDOR: never trust IDs from the client without an ownership check.

4. **Error handling:**
   - Maps every failure mode to the contract's error codes / status.
   - No raw exception stack traces leaked to the client.
   - 4xx vs 5xx distinguished correctly.
   - Catches narrow exceptions; lets unexpected ones bubble to a central handler.
   - Idempotency for unsafe creates (Idempotency-Key) where the contract requires it.

5. **Data access & performance:**
   - **N+1 detection**: any loop that issues a query per item — flag.
   - Pagination on every list endpoint; no unbounded `SELECT *`.
   - Reads use replica / read DB if applicable.
   - Writes use a transaction when modifying multiple rows that must agree.
   - Long-running work pushed to a queue, not done inline.

6. **Concurrency & idempotency:**
   - Optimistic locking (`version` / `updated_at`) or row locks where double-write would corrupt.
   - Rate limiting per actor / IP / tenant on expensive endpoints.
   - Retries: only on idempotent operations; with backoff.

7. **Security (OWASP-ish):**
   - SQL: parameterized queries only; no string concatenation.
   - SSRF: outbound URLs validated against allow-list when user-supplied.
   - Deserialization: only trusted types; no `pickle.loads(user_input)` / `eval`.
   - Secrets read from env / secret manager, never logged.
   - PII not logged (emails, names, tokens) — or hashed/redacted.
   - CORS not `*` for credentialed endpoints.
   - File uploads: type sniffed from content; size capped; stored outside web root.

8. **Observability:**
   - Structured logs with `request_id`, `user_id`, `tenant_id`, latency, status.
   - One metric per endpoint: count, latency histogram, error rate.
   - Trace span around external calls (DB, HTTP, queue).

9. **Tests:**
   - Validation failure cases (bad input → 400 with specific code).
   - Authz cases (other tenant → 403/404, anon → 401).
   - Happy-path integration test against a real or in-memory DB.

## Output

```markdown
## Backend Endpoint Review — <method+path>

**Verdict:** ship | needs-changes | block

### Blocking
- `orders.ts:34` — query missing `tenant_id` filter (IDOR risk).
- `orders.ts:52` — N+1: `for (const o of orders) await loadItems(o.id)`.

### Suggestions
- `orders.ts:88` — wrap insert + audit in a single transaction.

### Test gaps
- No test for non-owner access returning 404.
```

## Guardrails

- Cite `file:line` for every finding.
- Don't rewrite the handler in the review — point to the fix.
- Don't suggest "add a cache" without a measured read pattern justifying it.
- Missing authz is **always blocking** — never downgrade to suggestion.
- If the endpoint has no contract, request it before reviewing.
- Adjust idioms per framework (Express / Fastify / FastAPI / NestJS / Spring / Rails) but keep the same checklist.
