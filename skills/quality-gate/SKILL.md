---
name: quality-gate
description: An objective, threshold-based backstop for when review nudges fail to land — blocks on over-long files and functions, too many parameters, high complexity, magic numbers, oversized classes. Wire it as a final CI stage, a Claude Code Stop hook, or both.
---

# Quality Gate

A small set of **objective, language-agnostic thresholds**, enforced mechanically.

## Why this exists

Everything else in this library nudges. The reviewers report findings and hope someone acts
on them; `refactor` improves what it is pointed at. Nudges work most of the time, which is
the problem — the failures are invisible. A class grows by twenty lines a month. Each
individual diff is reasonable and each review is right to pass it. Nobody is ever wrong, and
after a year the class is unmaintainable.

This gate is the backstop for that case. It does not read the diff, it reads the code as it
now stands, so it catches accumulated drift rather than the increment that caused it. When
it fires, the finding is usually old: the file crossed the threshold months ago and every
review since has looked only at the change in front of it.

That makes it deliberately blunt. It has no judgment and no view of intent — that is the
point. Thresholds are arguable in any single case and useful precisely because they do not
argue back. **Run it last**, after the reviewers, as the thing that catches what their
nudges did not.

A firing gate is a signal about the review loop as much as about the code. If the same file
trips it every release, the reviewers have been raising it and it has not been getting
fixed; that is worth a conversation, not just a refactor.

Three wirings are provided — use whichever fit.

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
of universal AST/line checks, and prints violations (exit 1) or nothing (exit 0). It needs no
Claude Code context and no git history, so the same script serves all three wirings:

### Option A — Final CI stage (the backstop)

Run the script as the **last** stage of the pipeline, after tests, lint and any automated
review. It exits non-zero on violations, so any CI system fails the build on it:

```yaml
quality-gate:
  stage: .post           # last — after tests, lint, and automated review
  script:
    - ./.ci/check-quality.sh
```

Start it non-blocking (`allow_failure: true`, or the equivalent) on an existing codebase.
Turning it on hard against accumulated drift produces a wall of violations that nobody can
act on, and the gate gets disabled within a week. Let it report for a few weeks, fix what it
finds, then make it blocking — and keep it blocking, because a gate that can be waved
through is not a backstop.

Tune the thresholds *once*, at adoption, to sit just above what your codebase already
achieves. Raising them later to make a build pass is how the gate stops meaning anything.

### Option B — Agent review hook (soft, judgment-based)

A `Stop` hook of type `agent` runs the script, then a reviewer agent reads each reported
violation, decides whether it genuinely needs refactoring, and returns `block` (with a
specific, actionable reason) or `allow`. Good as an early warning while you are working, where a hard wall would be disruptive. It
catches violations before they reach CI, but it can be reasoned with — so it complements
Option A rather than replacing it. See [`settings.json`](settings.json).

### Option C — Hard gate hook (strict, deterministic)

A `Stop` hook that runs [`hooks/stop-quality-gate.sh`](hooks/stop-quality-gate.sh) directly.
If the script finds violations it exits 2, which blocks the agent and feeds the violation
list back so it must fix them before finishing. No judgment — any violation blocks.

## Install

1. Copy `hooks/` into your project's `.claude/hooks/` and make the scripts executable
   (`chmod +x`).
2. Copy the relevant `config/` file(s) to where your linter expects them (e.g. `.flake8`,
   `checkstyle.xml`).
3. For CI (Option A), call `check-quality.sh` from your pipeline's final stage. For the
   hooks (Options B and C), merge `settings.json` into `.claude/settings.json` — pick one.
4. Ensure the linters are installed in your environment.

> The reference scripts default to checking a `python/` and/or `java/` subtree; adjust the
> `SRC` globs in `check-quality.sh` to match your project's layout.

## Thresholds and the reviewers

The gate and [`review-complexity`](../review-complexity/SKILL.md) look at the same kind of
problem from opposite ends, and both are needed:

| | `review-complexity` | `quality-gate` |
|---|---|---|
| Input | the diff | the codebase as it stands |
| Basis | judgment, with a smell catalogue | fixed numeric thresholds |
| Catches | complexity being *introduced* | complexity that has *accumulated* |
| Answer to "but this case is fine" | accepts it | does not care |
| Runs | during review | last, after everything else |

A threshold cannot see that a 200-line file is a lookup table nobody reads. A reviewer
cannot see that this is the fourteenth reasonable increment. Neither alone is enough.
