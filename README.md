# Unlockers Skills Library

A reusable library of **agent definitions**, **skills**, and the **documentation** they
reference — for code review, testing discipline, refactoring, and getting PRs merged.

Everything here is written to be **language-agnostic**: examples are concrete (mostly
Python), but the rules, smells, and workflows apply to any language and test framework.
Git-platform commands default to GitHub's `gh` CLI, with notes for GitLab (`glab`) and
Azure DevOps (`az`).

## Layout

```
agents/      Subagent definitions (autonomous task-performers)
skills/      Skills — task-scoped capabilities (SKILL.md per skill)
docs/        Reference documentation that the skills and agents point to
```

### Agents

| Agent | What it does |
|-------|--------------|
| [`merger`](agents/merger.md) | Full PR merge lifecycle: push, enable auto-merge, monitor CI and reviews, fix, rebase on conflicts, escalate to human approval. |
| [`refactor`](agents/refactor.md) | Clean-code refactoring specialist — restructures without changing behaviour. |

### Skills

| Skill | What it does |
|-------|--------------|
| [`review-pr`](skills/review-pr/SKILL.md) | Comprehensive code review of a branch/PR — bugs, design, security, coverage. |
| [`review-complexity`](skills/review-complexity/SKILL.md) | Detect accidental complexity (defensive null checks, redundant exception handling, over-engineering). |
| [`review-testing`](skills/review-testing/SKILL.md) | Review test quality and coverage against the testing rules. |
| [`write-tests`](skills/write-tests/SKILL.md) | Write/improve tests: fakes over mocks, whole-object assertions, short bodies. |
| [`move-files`](skills/move-files/SKILL.md) | Relocate files/modules and update all imports without leaving re-export shims. |
| [`quality-gate`](skills/quality-gate/SKILL.md) | Hook-based quality gate that blocks finishing while objective thresholds are violated. |

### Docs

| Doc | Referenced by |
|-----|----------------|
| [`testing-rules.md`](docs/testing-rules.md) | `write-tests`, `review-testing` |
| [`testing-review-guide.md`](docs/testing-review-guide.md) | `review-testing` |
| [`accidental-complexity-guide.md`](docs/accidental-complexity-guide.md) | `review-complexity`, `refactor` |
| [`bugfix-workflow.md`](docs/bugfix-workflow.md) | `write-tests`, testing rules |
| [`feature-workflow.md`](docs/feature-workflow.md) | feature development |
| [`design-patterns.md`](docs/design-patterns.md) | general reference |

## Using It with Claude Code

These are plain Markdown definitions. To use them in a project:

- **Agents:** copy a file from `agents/` into your project's `.claude/agents/` (or your
  user-level `~/.claude/agents/`).
- **Skills:** copy a directory from `skills/` into `.claude/skills/`. Each contains a
  `SKILL.md`; some (like `quality-gate`) also ship hook scripts and config.
- **Docs:** copy the `docs/` files alongside, and keep the relative links intact, or adjust
  the paths to wherever you place them.

The review skills and the merger agent take an optional PR/MR number or branch as an
argument and default to the current branch against `main`.

## Sources

Distilled and made language-agnostic from real project agent/skill definitions (testing
rules, the testing and complexity reviewers, the merger agent, and a hook-based quality
gate).
