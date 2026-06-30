# Feature Workflow (Spec-First, Test-First)

For bugs, see [`bugfix-workflow.md`](bugfix-workflow.md). For features, always:

1. **Business need in the work item.** Stated as *As a `<role>` / I want `<capability>` /
   so that `<outcome>`*. Restate it verbatim in the PR description. If missing, fix the
   work item or ask the user before proceeding.
2. **Propose vertical slices by default.** Split the story into the smallest end-to-end
   slices that each deliver observable value, and let the user pick the first. Implement
   one slice at a time, repeating steps 3–8 per slice. Skip slicing only if the story is
   genuinely trivial (single rule, single layer, a couple of hours).
3. **Agree business rules and the test list with the user first.** List the rules in
   domain terms, then for each rule list the tests (`given_..._when_..._then_...`, one line
   each, no code). Cover nominal, boundary, and negative cases. Get user agreement before
   writing anything.
4. **Write the agreed tests and confirm they fail** for the right reason. Follow
   [`testing-rules.md`](testing-rules.md).
5. **Implement** to make them pass. Out-of-scope work becomes a `FIXME` or a follow-up
   work item — never silent expansion. If a missing rule surfaces, go back to step 3.
6. **Run the full test suite** as your post-change verification.
7. **PR description must contain:** business need (verbatim), business rules, summary,
   changes, tests added / FIXMEs / coverage gaps, open questions, related work items.
8. **Run the review skills** (`review-pr`, `review-complexity`, `review-testing`) and fix
   what they surface, then hand off to the `merger` agent.
