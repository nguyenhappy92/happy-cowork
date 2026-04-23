---
description: General coding style preferences that apply across languages.
alwaysApply: true
---

# Coding style

- Prefer clarity over cleverness. If a comment is needed to explain *what* the code does, rewrite the code.
- Name things for their role, not their type. `users` beats `userList`.
- Functions do one thing. If a function needs "and" in its name, split it.
- Early returns over nested `if`s. Guard clauses at the top.
- Avoid premature abstractions. Duplicate twice, refactor on the third.
- Handle errors where they happen; don't bubble raw exceptions across module boundaries.
- No dead code. No commented-out blocks left "just in case" — git remembers.
- Tests sit next to the code they test when the language idiom allows.
