---
name: design-api-contract
description: Use when designing a new HTTP/GraphQL API endpoint, evolving an existing one, writing or reviewing an OpenAPI / GraphQL schema, or "/design-api". Produces a contract-first design with request/response shapes, error model, and versioning notes before any code is written.
tools: [cursor, claude, copilot]
---

# design-api-contract

## When to use

- "design an API for <X>"
- "review this OpenAPI spec"
- "what should this endpoint look like?"
- "/design-api"
- Before writing any controller / handler / resolver code for a new feature.

## Inputs

- The user story or feature description.
- Existing API style guide if any (REST conventions, GraphQL naming, error envelope).
- Optional: existing related endpoints to stay consistent with.

## Procedure

1. **Clarify the resource and operation.** One verb per use case:
   - REST: `GET /resources`, `POST /resources`, `GET /resources/{id}`, `PATCH /resources/{id}`, `DELETE /resources/{id}`.
   - GraphQL: `query`, `mutation`, `subscription` — name them `<verb><Noun>` (`createOrder`, not `orderCreate`).

2. **Define the request shape:** path / query / body params with types and constraints, required vs optional, defaults, validation rules (length, regex, enum, range).

3. **Define the success response shape:** status code (200 / 201 / 204), full body schema, pagination shape (cursor preferred over offset for large sets).

4. **Define the error model:**
   - One consistent envelope: `{ error: { code, message, details? } }`.
   - Map every failure mode to a status code: 400 validation, 401 auth, 403 permission, 404 not found, 409 conflict, 422 semantic, 429 rate limit, 5xx server.
   - List every `code` the client may receive — UI must handle each.

5. **Authentication & authorization:** scope/role/ownership rule. Rate limits (per user / per IP / per tenant). Idempotency keys for unsafe creates.

6. **Performance & caching:** P95 latency budget. `Cache-Control`, `ETag`, `If-None-Match` where relevant. N+1 risk for the implementer.

7. **Versioning & evolution:** additive optional fields only on existing version; breaking changes require a new version. Document deprecation path for any field you might remove.

8. **Generate the spec.** Output as OpenAPI 3.1 YAML or GraphQL SDL. The spec is the **source of truth**; types on both tiers are generated from it.

## Output

```markdown
## API Contract — <verb> <resource>

**Style:** REST | GraphQL
**Auth:** <scope/role>
**Rate limit:** <n req/min>
**P95 budget:** <ms>

### Request
```yaml
# path / query / body
```

### Response (success)
```yaml
# 200 body
```

### Errors
| Status | code | When |
|---|---|---|
| 400 | VALIDATION_FAILED | … |
| 409 | DUPLICATE_ORDER | … |

### Notes
- Idempotency: …
- Caching: …
- Backward compat: …
```

## Guardrails

- Do NOT write handler code in this skill — output the contract only.
- Do NOT invent fields not justified by the user story; lean minimal.
- Reject `200 OK` with `{ "error": ... }` patterns — use proper status codes.
- Reject leaking internal error messages (stack traces, SQL errors) into the response body.
- If the contract conflicts with an existing endpoint's conventions, flag it and propose the consistent option.
- If the auth model is unclear, **ask** before designing — don't assume "anyone authenticated".
