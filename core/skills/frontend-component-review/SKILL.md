---
name: frontend-component-review
description: Use when reviewing a React / Vue / Svelte / Solid component for correctness, accessibility, performance, state, and types, or "/frontend-review". Produces a structured review with file:line citations.
tools: [cursor, claude, copilot]
---

# frontend-component-review

## When to use

- "review this component"
- "is this React component well-written?"
- "check this UI for accessibility / performance"
- "/frontend-review"

## Inputs

- One or more component files (TSX / JSX / Vue / Svelte).
- Optionally: the design spec, the data hook(s) it consumes, the test file.

## Procedure

1. **Read the whole component first.** Don't comment until you've understood props, state, and the render output.

2. **Types & contract:**
   - Props typed, no `any` / `unknown` without narrowing.
   - Required vs optional matches actual usage.
   - Discriminated unions for "either A or B" props instead of optional pairs.
   - No prop drilling > 2 levels — flag for context / composition.

3. **State & data flow:**
   - State at the lowest necessary level.
   - Derived state computed in render, not stored.
   - No `useEffect` to sync derived state.
   - Async effects: cancel/cleanup on unmount; handle race on rapid prop changes.
   - Server state via TanStack Query / SWR / RTK Query for non-trivial cases.

4. **Rendering & performance:**
   - Lists have stable `key` (not array index for dynamic lists).
   - Memoize only when measured to matter.
   - Avoid recreating callbacks/objects passed to memoized children inline.
   - Lazy-load routes and heavy components (`React.lazy`, dynamic import).
   - Images: `loading="lazy"`, explicit width/height, modern format.

5. **Accessibility (a11y):**
   - Semantic elements first (`<button>`, `<a>`, `<nav>`, `<main>`) over `<div onClick>`.
   - Every interactive element keyboard-reachable; visible focus ring.
   - Labels on form controls (`<label htmlFor>`, `aria-label` only when no visible label).
   - Live regions for async messages (`aria-live="polite"` / `="assertive"`).
   - Color contrast WCAG AA (4.5:1 text, 3:1 large text / UI).
   - Modal: focus trap, restore focus on close, `Esc` to dismiss.

6. **States:** loading, empty, error, success — all four represented.

7. **Security:**
   - No `dangerouslySetInnerHTML` without sanitization (DOMPurify / equivalent).
   - URLs from user input validated before navigation / `<a href>`.
   - No secrets in client code.

8. **Tests:**
   - Cover behavior (user actions + assertions on output), not implementation.
   - One test per state (loading / empty / error / success) for data components.

## Output

```markdown
## Frontend Review — <component>

**Verdict:** ship | needs-changes | block

### Blocking
- `Form.tsx:42` — submit button not keyboard-reachable (`<div onClick>` instead of `<button>`).

### Suggestions
- `Form.tsx:88` — `useMemo` here has no measurable benefit; remove.

### Nits
- `Form.tsx:12` — extract `OrderRow` for clarity.

### Tests gap
- No test for the error state; add one.
```

## Guardrails

- Cite `file:line` for every finding. Vague feedback is rejected.
- Don't rewrite the component in the review — point to the fix.
- "Performance" claims need a reason (re-render count, bundle KB, measurement). Don't slap `useMemo` everywhere.
- Don't insist on a state library if local state is genuinely small and isolated.
- Adjust the checklist to React / Vue / Svelte / Solid idioms; don't apply React rules to Vue.
