---
description: Python-specific conventions.
globs:
  - "**/*.py"
---

# Python

- Target Python 3.11+. Use `from __future__ import annotations` at the top of every file if supporting older runtimes.
- Type-hint every public function. Use `typing` (or `collections.abc`) consistently.
- Format with `ruff format`; lint with `ruff check`. No manual style debates.
- Prefer `pathlib.Path` over `os.path`.
- Use f-strings; never `%`-format or `.format()` for new code.
- Dataclasses (`@dataclass(slots=True, frozen=True)` when immutable) over raw dicts for structured data.
- No bare `except:`. Catch the narrowest exception you actually handle.
- Keep modules under ~400 lines; split when they grow.
