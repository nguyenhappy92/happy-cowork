---
description: TypeScript-specific conventions.
globs:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript

- Enable `"strict": true` in `tsconfig.json`. No implicit `any`.
- Prefer `type` for unions and shapes, `interface` for extensible object contracts.
- Never use `any`. If truly unknown, use `unknown` and narrow.
- Use `readonly` on properties that don't change. Use `as const` for literal tuples.
- Prefer `??` over `||` for defaults unless you explicitly want falsy coalescing.
- No `enum` unless interoperating with legacy code — use string literal unions.
- Top-level imports only; avoid dynamic `require`.
- Async functions return `Promise<T>`; never mix `.then()` chains with `await`.
