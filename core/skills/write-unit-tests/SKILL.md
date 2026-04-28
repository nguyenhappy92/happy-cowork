---
name: write-unit-tests
description: Use when asked to write unit tests for a function, class, or module — table-driven where possible, edge cases enumerated, mocks minimized, or "/write-tests". Produces test files that test behavior, not implementation.
tools: [cursor, claude, copilot]
---

# write-unit-tests

## When to use

- "write tests for <function/module>"
- "add unit tests for <X>"
- "/write-tests"
- After implementing a new function with non-trivial branching.

## Inputs

- The source file(s) to be tested.
- Repo's test runner (jest / vitest / pytest / go test / …) and existing test patterns.

## Procedure

1. **Read the unit. Identify the public surface.** Test only the public API — private helpers tested transitively.

2. **Enumerate cases — branching first, then edges:**
   - Happy path (most common input).
   - Each branch (`if`, `switch`, ternary).
   - Boundary values: 0, 1, n, n+1 for collections; min, max, just-over for ranges; empty / single char / max length for strings.
   - Null / undefined / missing where the contract allows.
   - Error inputs: every documented thrown error / returned `Err`.
   - Idempotency: calling twice with the same input gives the same output.
   - Concurrency: if relevant, two callers don't corrupt shared state.

3. **One assertion per concept.**

4. **Table-driven for combinatorial inputs:**
   ```ts
   it.each([
     ["empty",     "",      null],
     ["one",       "a",     ["a"]],
     ["two",       "a,b",   ["a", "b"]],
     ["trailing",  "a,b,",  ["a", "b"]],
   ])("parseCsv(%s) → %j", (_, input, expected) => {
     expect(parseCsv(input)).toEqual(expected);
   });
   ```

5. **Mocks are a code smell — minimize them:**
   - Don't mock the system under test. Ever.
   - Mock only at I/O boundaries (HTTP, DB, clock, filesystem) and prefer fakes (in-memory DB, msw, fake timers).
   - If you need to mock four collaborators, the function probably does too much.

6. **Test behavior, not implementation:** assert on outputs and observable side effects, not on which internal method got called.

7. **Naming:** `it("returns 404 when order does not exist")`. Read the test names → understand the spec.

8. **Setup/teardown:** prefer per-test setup. `beforeEach` for fresh fakes; avoid `beforeAll` for anything mutable.

9. **Coverage as a smell, not a goal.** Use it to find untested branches; don't write tests purely to cover lines.

## Output

Produce the test file(s) directly, plus a short summary:

```markdown
## Tests added — <module>

**File:** `src/orders/parse.test.ts`
**Cases:** 9 (1 happy, 4 branch, 3 edge, 1 error)
**Mocks:** none
**Coverage delta:** 76% → 94% on `src/orders/parse.ts`

### Cases
- parses single item
- parses multiple
- trims whitespace
- rejects empty input with InvalidInputError
- …
```

## Guardrails

- NEVER test private functions directly — restructure if the surface is wrong.
- NEVER assert on log output unless logging is the contract.
- NEVER leave `it.skip` / `xit` / `it.only` in the committed file.
- NEVER rely on real network, real DB, real clock — use fakes / time freezes.
- If a test needs `sleep()`, replace with fake timers — sleeps cause flakes.
- If a function is too tangled to test cleanly, **say so** and recommend a refactor first.
- Don't paste the full source under test back into the output — link or summarize.
