---
name: review-pr
description: Perform a comprehensive code review of branch or pull-request changes — bugs, design, security, test coverage. Use when you want a broad review rather than the focused testing/complexity passes.
args:
  - name: compare_ref
    description: "Branch to review, OR a PR/MR number (default: current branch). When a number is given, the source/target branches are resolved from the git platform."
    required: false
  - name: base_ref
    description: Base branch to compare against (default: main)
    required: false
---

# Code Review Skill

Performs a comprehensive AI-powered code review of changes between refs. For deeper focused
passes, also run [`review-complexity`](../review-complexity/SKILL.md) and
[`review-testing`](../review-testing/SKILL.md).

## Process

1. **Resolve refs**
   - If `compare_ref` is a number (PR/MR ID), resolve source/target from your platform:
     - GitHub: `gh pr view <ID> --json headRefName,baseRefName`
     - GitLab: `glab mr view <ID>`
     - Azure DevOps: `az repos pr show --id <ID> --query "{source: sourceRefName, target: targetRefName}" -o json` (strip `refs/heads/`)
     Then `git fetch origin <source>`.
   - Otherwise use the provided `compare_ref` (or current branch) and `base_ref` (or `main`).

2. **Gather context**
   - Commit history: `git log --oneline {base}..{compare}`
   - Diffstat: `git diff {base}...{compare} --stat`
   - Full diff: `git diff {base}...{compare}`

3. **Analyze changes**
   - Review all modified files for bugs, design issues, and quality problems.
   - Evaluate test coverage, identify security concerns, assess architectural decisions.

4. **Categorize issues by severity** (Critical / Major / Minor — see criteria below).

5. **Generate report** → `code-review-issues.md` with file locations, line numbers, clear
   problem descriptions, concrete fixes, and summary statistics.

## Review Criteria

### Critical Issues
- Logic errors and incorrect implementations
- Security vulnerabilities
- Breaking changes
- Missing error handling for critical paths
- Race conditions or concurrency bugs
- Resource leaks

### Major Issues
- Architecture violations (layering, dependency direction)
- Tight coupling between modules
- Missing abstractions
- Incomplete implementations
- Significant performance concerns
- Poor error-handling patterns

### Minor Issues
- Code duplication
- Dead code
- Inconsistent naming or patterns
- Test quality (missing tests, weak assertions)
- Missing documentation for complex logic
- Minor performance optimizations

## Exclusions

- Style/formatting (assumed handled by linters)
- Personal preferences without technical merit
- Issues already flagged by automated tools

## Output Format

```markdown
# Code Review Issues: branch-name

## Critical Issues
### 1. Title
**Location:** path/to/file:123
**Issue:** Clear description
**Fix:** Concrete suggestion

## Major Issues
...

## Minor Issues
...

## Summary
- X Critical, Y Major, Z Minor issues
- Overall assessment and recommendations
```

## Example Usage

```
review-pr              # Current branch vs main
review-pr feat/foo     # Specific branch
review-pr feat/foo dev # Different base
review-pr 3574         # PR/MR by number
```
