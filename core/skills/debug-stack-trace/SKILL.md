---
name: debug-stack-trace
description: Use when handed a stack trace, error log, or "this is broken" with a paste of output, and asked to find the root cause across frontend, backend, or DB tiers, or "/debug-trace". Produces a hypothesis tree, the evidence supporting each branch, and the next diagnostic step.
tools: [cursor, claude, copilot]
---

# debug-stack-trace

## When to use

- "what does this stack trace mean?"
- "why is this failing?"
- "/debug-trace"
- A user pastes a long error log and asks for help.

## Inputs

- The stack trace / error log / browser console output.
- Optionally: the request / input that triggered it, the recent diff, the relevant source file.

## Procedure

1. **Identify tier and language.** Browser, Node/Python/Go server, SQL, build/transpile, CI? Each has different forensic conventions.

2. **Find the root frame:**
   - Top of the trace = exception class and message.
   - First user-code frame (skip framework/library internals) = where to start reading.
   - `Caused by:` chains (JVM / .NET) — read bottom-up.

3. **Extract literal facts:** exception type & message verbatim; file:line of first user frame; inputs at that frame; timing (cold start? under load? after a deploy?).

4. **Map message → likely cause.** Cheat sheet:

   | Symptom | Common causes |
   |---|---|
   | `TypeError: Cannot read properties of undefined` | upstream null; missing default; async race |
   | `Hydration mismatch` (React/Next) | server vs client divergence — date/locale/random/window in render |
   | `ECONNREFUSED` / `ENOTFOUND` | service down; wrong host; DNS; container networking |
   | `ECONNRESET` mid-request | upstream timeout; LB idle timeout < request time; keep-alive mismatch |
   | `Connection terminated unexpectedly` (pg) | pool exhausted; DB restart; long-running query killed |
   | `deadlock detected` | inconsistent lock ordering across transactions |
   | `duplicate key value violates unique constraint` | retry without idempotency; race in upsert |
   | `Maximum call stack size exceeded` | unbounded recursion; cyclic JSON; effect loop |
   | `CORS … blocked` | server missing `Access-Control-Allow-Origin`; preflight failing |
   | `JWT expired` / `signature invalid` | clock skew; wrong key; rotated secret without rollover |
   | `OOMKilled` (k8s) | memory limit too low; leak; large allocation per request |
   | `request entity too large` | body size limit on proxy / framework |

5. **Form a hypothesis tree.** 2–4 candidate causes ranked by likelihood. For each: evidence for, evidence against, and a **single cheap diagnostic** that distinguishes.

6. **Pick the cheapest distinguishing test** and recommend it as the next step. Examples:
   - Reproduce locally with the same input.
   - Add a one-line log immediately above the failing frame.
   - Run the offending query in `psql` with `EXPLAIN`.
   - Check the deploy timeline for a correlated change.
   - Curl the endpoint from a peer pod to isolate networking.

7. **If root cause is found**, propose the fix at the right tier (don't patch a symptom in UI when the bug is in the API contract).

## Output

```markdown
## Stack trace analysis

**Tier:** frontend | backend | DB | infra | build
**Exception:** `<type>: <message>`
**First user frame:** `path/file.ts:42`

### Literal facts
- Triggered by: <input>
- Started: <timestamp / since which deploy>
- Frequency: every request | intermittent | once

### Hypotheses (ranked)
1. **<cause>** — Evidence: …  Against: …  Distinguishing test: …
2. …

### Recommended next step
<one cheap diagnostic, copy-pastable>

### If hypothesis 1 confirmed, the fix is
<minimal change, at the correct tier>
```

## Guardrails

- NEVER propose a fix without naming the hypothesis and a way to confirm it.
- NEVER `try/except: pass` to make the trace go away.
- NEVER suggest a retry loop unless the call is idempotent and the failure is genuinely transient.
- If the trace is truncated, **ask** for the full output.
- Look for correlated recent deploys / config changes before deep-diving the code.
- Distinguish "the code throws" from "the user sees an error" — sometimes the bug is in error mapping.
