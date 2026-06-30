---
name: quality-gate
description: A code-quality gate that blocks an agent from finishing while the code has quality violations (over-long functions, too many parameters, high complexity, magic numbers, oversized files/classes). Use to enforce objective quality thresholds automatically via Claude Code hooks.
---

# Quality Gate

An automated quality gate for Claude Code. It enforces a small set of **objective,
language-agnostic thresholds** and stops the agent from ending its turn while violations
remain. Two complementary mechanisms are provided — use either or both.

## The Thresholds (language-agnostic)

| Metric | Limit |
|--------|-------|
| File length | ≤ 150 lines |
| Function/method length | ≤ 30 lines |
| Parameters per function | ≤ 4 |
| Cyclomatic / cognitive complexity | ≤ 10 |
| Magic numbers | flagged |
| Duplicate string literals | ≤ 3 |
| Class instance attributes / data-abstraction coupling | ≤ 6 |

These same limits are expressed per-language in [`config/`](config):
- Python → [`config/python.flake8`](config/python.flake8) (flake8 + plugins: flake8-functions, flake8-cognitive-complexity, wemake-python-styleguide, flake8-simplify)
- Java → [`config/java-checkstyle.xml`](config/java-checkstyle.xml) (Checkstyle)

Add a config for any other language using the same limits, and teach
[`hooks/check-quality.sh`](hooks/check-quality.sh) to run its linter.

## How It Works

[`hooks/check-quality.sh`](hooks/check-quality.sh) runs the available linters plus a couple
of universal AST/line checks, and prints violations (exit 1) or nothing (exit 0). Two wiring
options sit on top of it:

### Option A — Agent review hook (soft, judgment-based)

A `Stop` hook of type `agent` runs the script, then a reviewer agent reads each reported
violation, decides whether it genuinely needs refactoring, and returns `block` (with a
specific, actionable reason) or `allow`. Good when you want judgment, not a hard wall. See
[`settings.json`](settings.json).

### Option B — Hard gate hook (strict, deterministic)

A `Stop` hook that runs [`hooks/stop-quality-gate.sh`](hooks/stop-quality-gate.sh) directly.
If the script finds violations it exits 2, which blocks the agent and feeds the violation
list back so it must fix them before finishing. No judgment — any violation blocks.

## Install

1. Copy `hooks/` into your project's `.claude/hooks/` and make the scripts executable
   (`chmod +x`).
2. Copy the relevant `config/` file(s) to where your linter expects them (e.g. `.flake8`,
   `checkstyle.xml`).
3. Merge `settings.json` into your project's `.claude/settings.json` (pick Option A or B).
4. Ensure the linters are installed in your environment.

> The reference scripts default to checking a `python/` and/or `java/` subtree; adjust the
> `SRC` globs in `check-quality.sh` to match your project's layout.
