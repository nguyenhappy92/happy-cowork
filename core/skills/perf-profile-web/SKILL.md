---
name: perf-profile-web
description: Use when asked to investigate a slow page, slow API, or "this feels sluggish", or "/perf-check". Produces a structured performance review across Web Vitals (frontend) and P95 latency (backend) with concrete remediations.
tools: [cursor, claude, copilot]
---

# perf-profile-web

## When to use

- "this page is slow"
- "the API is slow under load"
- "what's the LCP / INP / CLS on <page>?"
- "/perf-check"

## Inputs

- The page URL or endpoint in question.
- Recent Lighthouse / WebPageTest report (if available), or APM traces / DB slow-query log.
- Optional: target user (mobile / desktop), geography, expected QPS.

## Procedure

### Frontend (Web Vitals)

1. **Measure first.** Pull actual numbers — don't guess.
   - **LCP** < 2.5s
   - **INP** < 200ms
   - **CLS** < 0.1
   - **TTFB** < 800ms
   - **TBT / Long Tasks** — no main-thread task > 50ms

2. **Critical-path checklist:**
   - HTML small and streamed (server response < 200ms).
   - Render-blocking JS / CSS minimized; defer non-critical.
   - Above-the-fold image: explicit width/height, modern format (AVIF / WebP), `fetchpriority="high"`.
   - Web fonts: `font-display: swap`, subset, self-host or preconnect.
   - Third-party scripts: deferred, async, sandboxed, or removed.

3. **JS bundle hygiene:**
   - Total JS on first load < 200 KB compressed for content pages.
   - Route-level code splitting in place.
   - No whole-library imports (`import _ from "lodash"`).
   - Heavy components lazy-loaded.

4. **Runtime / interaction:**
   - INP regressions usually trace to long click handlers; profile the slowest interactions.
   - Virtualize lists past ~100 rows.
   - Avoid layout thrash: read DOM measurements, then write.

5. **CLS:** reserve space for images, ads, embeds (aspect-ratio). No content injection above existing content after load.

### Backend (latency)

1. **Pull the trace / profile.** APM (Datadog, New Relic, OTel) span breakdown for a representative slow request.

2. **Latency budget sketch:** total = network + app + DB + downstream. Identify which slice dominates.

3. **DB performance:**
   - Slow query log: top N by total time (not per-call time).
   - `EXPLAIN ANALYZE` on the worst — sequential scans on large tables, sort spills, hash joins blowing memory.
   - Missing index? Check the where/order/join columns.
   - **N+1**: a span fan-out of 50 small DB calls in one request.
   - Connection pool: saturated? Pool size matched to DB max connections?

4. **App layer:**
   - JSON serialization on huge responses.
   - Synchronous CPU work (hashing, parsing, regex) on the request thread.
   - ORM eager-loading wrong relations, missing `select` projection.

5. **Downstream calls:**
   - External HTTP inside the request: timeout configured? Retried? Circuit-broken?
   - Sequential awaits that could be parallel.

6. **Caching:**
   - HTTP caching (`Cache-Control`, `ETag`) on static-ish responses.
   - App cache (Redis / memcached) for expensive read-heavy results, with explicit invalidation rules.

## Output

```markdown
## Perf review — <page / endpoint>

### Measurements
| Metric | Value | Target | Status |
|---|---|---|---|
| LCP    | 4.1s  | < 2.5s | bad |
| INP    | 320ms | < 200ms | bad |
| API P95| 1.8s  | < 500ms | bad |

### Top contributors
1. Backend P95 1.8s dominated by an n+1 in `GET /orders` — 47 queries / request (`OrdersHandler:loadItems`).
2. LCP image is 850 KB JPEG, no width/height, render-blocking.
3. Main-bundle JS is 612 KB compressed; `lodash` and `moment` imported wholesale.

### Fixes (ranked by ROI)
- [ ] Batch item load with `IN (?)` query — likely cuts API P95 to < 400ms.
- [ ] Convert hero image to AVIF + width/height attrs — likely cuts LCP by ~1.5s.
- [ ] Replace `moment` with `date-fns` or native `Intl` — cuts ~70 KB.
- [ ] Code-split the `/admin` route — cuts initial bundle by ~110 KB.

### How to verify
- Re-run Lighthouse on mobile 4G profile after each change.
- Run k6 / wrk against `/orders` at 50 RPS for 5 min, check P95.
```

## Guardrails

- NEVER suggest an optimization without a measurement supporting it.
- NEVER add a cache to fix a query you haven't `EXPLAIN`ed.
- NEVER reach for `useMemo` / `React.memo` without a measured re-render problem.
- NEVER parallelize calls that have data dependencies on each other.
- If APM / RUM / Lighthouse data is missing, **say so** and recommend the cheapest way to get it before committing to a fix.
- Distinguish **lab** (Lighthouse local) from **field** (CrUX / RUM). A page can pass lab and fail field.
- Performance fixes can introduce correctness bugs (cache invalidation, race conditions) — require tests around hot-path changes.
