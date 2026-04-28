---
name: design-data-model
description: Use when designing a database schema, adding a new entity, planning a migration, choosing indexes, or "/design-data". Produces a schema, migration plan, index strategy, and rollback path before any code is written.
tools: [cursor, claude, copilot]
---

# design-data-model

## When to use

- "design the schema for <feature>"
- "should this be one table or two?"
- "what indexes do I need?"
- "review this migration"
- "/design-data"

## Inputs

- The feature / API contract that drives the data needs.
- Current DB engine (Postgres, MySQL, SQLite, MongoDB, DynamoDB, …) and ORM/migration tool.
- Expected read/write patterns (rough QPS, hot queries) and data volume.

## Procedure

1. **Identify entities and relationships.** 1:1, 1:N, N:M. Aggregate roots — which entity owns the lifecycle? Soft delete vs hard delete — pick one per entity, document why.

2. **Define each table / collection:**
   - Primary key: prefer surrogate (`id uuid` / `bigint`) over natural keys.
   - Required vs nullable columns — reject "everything nullable just in case".
   - Types: pick the narrowest correct type.
   - Defaults at the DB level (`now()`, `gen_random_uuid()`, `false`).
   - `created_at` / `updated_at` on every mutable table.

3. **Constraints — push invariants down to the DB:** `NOT NULL`, `UNIQUE`, `CHECK`, `FOREIGN KEY` with explicit `ON DELETE`. Partial unique indexes for "soft-unique" rules. Don't rely on app-level uniqueness for safety.

4. **Indexes — design from the queries, not the columns:**
   - List every read query the feature will issue.
   - Smallest index that serves it (composite column order matches WHERE + ORDER BY).
   - Cover indexes for hot read paths.
   - Beware: every index slows writes and costs storage.
   - Postgres: `btree` default; `gin` for jsonb / arrays; `brin` for time-series.

5. **Migration plan — forward AND rollback:**
   - One change per migration.
   - **Online safety**: adding NOT NULL on populated table → (a) add nullable, (b) backfill, (c) add NOT NULL — three migrations across deploys.
   - Postgres index: `CREATE INDEX CONCURRENTLY` to avoid table locks.
   - Removing a column: ship a release that stops writing/reading it, then drop in the next.
   - Document rollback: SQL or migration tool command, plus data-loss implications.

6. **Performance & footprint:** estimate row count after 1 year. If > 100M, plan partitioning / archival now. Hot-row contention. Read replicas / caching — note which queries can tolerate staleness.

7. **Multi-tenant / privacy:** tenant isolation strategy (`tenant_id` + RLS, schema-per-tenant, or DB-per-tenant). PII columns flagged for encryption / masking / audit.

## Output

```markdown
## Data Model — <feature>

**Engine:** Postgres 15 | MySQL 8 | …
**Migration tool:** Prisma | Alembic | sqlc | Drizzle | Flyway

### Schema
```sql
CREATE TABLE orders (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES tenants(id),
  status      text NOT NULL CHECK (status IN ('pending','paid','cancelled')),
  total_cents int  NOT NULL CHECK (total_cents >= 0),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX orders_tenant_status_created_idx
  ON orders (tenant_id, status, created_at DESC);
```

### Queries this serves
- List recent orders for tenant by status — uses composite index.

### Migration plan
1. `0042_create_orders.sql` — additive, safe online.
2. Backfill from `legacy_orders` in `0043_backfill_orders.sql` (batched 10k rows).

### Rollback
- `DROP TABLE orders;` (no dependent data yet).

### Watch out for
- `tenant_id` cardinality vs index size — monitor after 30 days.
```

## Guardrails

- NEVER propose a migration that locks a large table during business hours without flagging it.
- NEVER drop a column or table in the same release that stops using it — phase it.
- NEVER add a NOT NULL column with no default to a populated table in one step.
- NEVER rely on `ORDER BY` without a serving index on tables > 10k rows.
- Push back on schemas with no foreign keys "for performance" — measure first.
- For tables with > 1M rows, require an explicit online-migration plan in the output.
- Reject storing JSON blobs as a substitute for normalization unless the access pattern is genuinely document-shaped.
