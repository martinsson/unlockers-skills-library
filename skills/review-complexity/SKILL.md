---
name: review-complexity
description: Detect accidental complexity in code changes — unnecessary code that doesn't serve the domain problem. Use when reviewing a branch or pull request for over-engineering, defensive null checks, redundant exception handling, and similar smells.
args:
  - name: compare_ref
    description: "Branch to review, OR a PR/MR number (default: current branch). When a number is given, the source/target branches are resolved from the git platform."
    required: false
  - name: base_ref
    description: Base branch to compare against (default: main)
    required: false
---

# Accidental Complexity Review Skill

Specialized code review focused on **accidental complexity** — unnecessary code that
doesn't serve the domain problem.

## Reference

See [`docs/accidental-complexity-guide.md`](../../docs/accidental-complexity-guide.md) for
the full smell catalogue with examples and detection heuristics.

## Process

1. **Resolve refs**
   - If `compare_ref` is a number (PR/MR ID), resolve source/target from your platform:
     - GitHub: `gh pr view <ID> --json headRefName,baseRefName`
     - GitLab: `glab mr view <ID>`
     - Azure DevOps: `az repos pr show --id <ID> --query "{source: sourceRefName, target: targetRefName}" -o json` (strip `refs/heads/`)
     Then `git fetch origin <source>`.
   - Otherwise use the provided `compare_ref` (or current) and `base_ref` (or `main`).

2. **Gather diff**
   - Changed source files: `git diff {base}...{compare} --name-only`
   - Full diff: `git diff {base}...{compare}`

3. **Apply the complexity lens** — for each changed file, hunt for:

   **Critical** (design holes):
   - Null/None checks inside domain logic
   - Optional arguments that are never actually null
   - Defensive programming hiding broken contracts

   **Major** (structural complexity):
   - Multi-layer exception handling (adapter + service + caller all catching)
   - Boolean flag parameters that split behaviour
   - Always-null optional arguments
   - Middle-man classes that just delegate
   - God objects / classes doing too much

   **Minor** (code smells):
   - Long parameter lists (>4 params)
   - Speculative generality (YAGNI violations)
   - Unnecessary class/state (could be a function)
   - Primitive obsession / data clumps
   - Nested conditionals (arrow anti-pattern)

4. **Challenge each finding:**
   - Can this be removed entirely?
   - Can complexity be pushed elsewhere (up the stack, into an adapter)?
   - Is there a simpler design that eliminates the need?

5. **Generate report** → `complexity-review-issues.md`

## Severity Model

| Severity | Indicators |
|----------|------------|
| Critical | Null checks in domain logic, optional params never used as null, exception handling masking design flaws |
| Major | Multi-layer try/catch, boolean flags splitting behaviour, unnecessary delegation, feature envy |
| Minor | Long param lists, speculative generality, unnecessary state, primitive obsession |

## Output Format

```markdown
# Accidental Complexity Review: {branch-name}

## Critical Issues
### 1. Title
**Location:** path/to/file:123
**Smell:** name of the pattern
**Why it matters:** brief explanation of the hidden cost
**Suggestion:** concrete refactor to eliminate the complexity

## Major Issues
...

## Minor Issues
...

## Summary
- X Critical, Y Major, Z Minor issues
- Overall complexity health assessment
```

## Example Usage

```
review-complexity              # Current branch vs main
review-complexity feat/foo     # Specific branch
review-complexity feat/foo dev # Different base
review-complexity 3574         # PR/MR by number
```
