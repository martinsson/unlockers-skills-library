# Review Protocol

Every `review-*` skill in this library shares one invocation contract, one severity
vocabulary, and one report shape. Each skill documents only its own **lens** — what it
looks for — and points here for the rest.

## Arguments

| Argument | Meaning |
|----------|---------|
| `compare_ref` | Branch to review, **or** a PR/MR number. Default: current branch. |
| `base_ref` | Branch to compare against. Default: `main`. |

## 1. Resolve refs

If `compare_ref` is a number, it is a PR/MR ID — resolve its source and target branches
from the hosting platform:

```bash
# GitHub
gh pr view <ID> --json headRefName,baseRefName

# GitLab
glab mr view <ID>

# Azure DevOps  (strip the refs/heads/ prefix from both)
az repos pr show --id <ID> --query "{source: sourceRefName, target: targetRefName}" -o json
```

Then `git fetch origin <source>`. Otherwise use `compare_ref` (or the current branch) and
`base_ref` (or `main`) as given.

## 2. Gather the diff

```bash
git log --oneline {base}..{compare}      # what the author was doing
git diff {base}...{compare} --stat       # shape and size
git diff {base}...{compare} --name-only  # files to classify
git diff {base}...{compare}              # the review surface
```

Use three dots. `{base}...{compare}` diffs against the merge base, so unrelated commits
that landed on `base` since the branch started do not appear as changes.

## 3. Read enough surrounding code

A diff alone cannot tell you whether a change fits. Before judging any file, read one or
two sibling modules in the same directory and the package's entry point. Reviews that skip
this produce findings that are locally reasonable and wrong in context.

## 4. Severity

The same three levels everywhere. Each skill's own table says what fills them.

| Severity | Meaning |
|----------|---------|
| **Critical** | Broken, exploitable, or violates an explicit project rule. Blocks merge. |
| **Major** | Real cost that will be paid later. Fix before merge, or file a follow-up. |
| **Minor** | Worth fixing, blocks nothing. |

## 5. Report

Each skill writes a Markdown file at the repo root (`code-review-issues.md`,
`security-review-issues.md`, …). Every finding carries:

```markdown
### 1. Title
**Location:** path/to/file:123
**Issue:** what is wrong — one or two sentences
**Why it matters:** the concrete consequence, not a restatement of the rule
**Suggestion:** a specific edit, not "consider refactoring"
**Reference:** an existing file in the repo that already does it right, if there is one
```

Close with a summary line: `X Critical, Y Major, Z Minor` and a one-paragraph verdict.

## Rules that apply to every reviewer

- **Report findings, do not fix them.** These skills are read-only. Fixing is a separate,
  explicitly-requested step.
- **Confirm before reporting.** A search hit is a candidate. Read the code around it and
  discard the ones that do not survive.
- **No finding without a consequence.** If you cannot state what breaks or what it costs,
  it is not a finding.
- **Cite a reference where one exists.** "Do it like `path/to/other.py:45`" is worth more
  than a paragraph of principle.
- **Say when the answer is nothing.** An empty report is a valid, useful outcome.

## The reviewers

| Skill | Lens | Report |
|-------|------|--------|
| [`review-pr`](../skills/review-pr/SKILL.md) | Catch-all: bugs, design, security, coverage in one pass | `code-review-issues.md` |
| [`review-complexity`](../skills/review-complexity/SKILL.md) | Accidental complexity | `complexity-review-issues.md` |
| [`review-testing`](../skills/review-testing/SKILL.md) | Test quality and coverage | `testing-review-issues.md` |
| [`review-architecture`](../skills/review-architecture/SKILL.md) | Boundaries, seams, dependency direction | `architecture-review-issues.md` |
| [`review-security`](../skills/review-security/SKILL.md) | Secrets, injection, authz, crypto, deps | `security-review-issues.md` |
| [`review-impact`](../skills/review-impact/SKILL.md) | Blast radius; which suites must pass | `impact-analysis.md` |

**Which to run:** `review-pr` alone for a small change. For anything substantial, the
focused passes find more than the catch-all does — they are cheap to run in parallel.
`review-impact` is the one to run *before* pushing rather than after.
