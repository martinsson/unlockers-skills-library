---
name: review-coherence
description: Review branch or pull-request changes for coherence with the conventions and patterns already used in the repo. Use when checking whether a change looks like it belongs, rather than whether it works.
args:
  - name: compare_ref
    description: "Branch to review, OR a PR/MR number (default: current branch). When a number is given, the source/target branches are resolved from the git platform."
    required: false
  - name: base_ref
    description: Base branch to compare against (default: main)
    required: false
---

# Coherence Review Skill

Reviews changes for **coherence**: does this look like it belongs in this repo? Not "is it
correct" — that is [`review-pr`](../review-pr/SKILL.md) — but "would a maintainer be able
to tell this was written by someone else?"

**Protocol:** [`docs/review-protocol.md`](../../docs/review-protocol.md) — arguments, ref resolution, severity levels, report shape. Read it first.

## Where the rules come from

This reviewer has no rule list of its own, and it must not invent one. Coherence is defined
by two sources, in order:

1. **The project's conventions doc** — `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, a style
   guide, lint configuration. Read it at the start of every run. Anything stated there
   explicitly and violated in the diff is **Critical**, because someone wrote it down.
2. **The surrounding code** — how the neighbouring modules already solve the same problem.
   Divergence from a consistent local pattern is **Major**. Divergence from an inconsistent
   one is not a finding at all.

If neither source says anything about a habit you dislike, it is not a finding. Personal
preference dressed as coherence is the main failure mode of this skill.

## Process

1. **Resolve refs and gather the diff** — per [`review-protocol.md`](../../docs/review-protocol.md).

2. **Read the conventions doc** and extract its explicit, checkable rules into a working
   list. These become the Critical criteria for this run.

3. **Compare against neighbours.** For each modified file, read one or two sibling modules
   in the same directory and the package's entry point. A change is coherent when it
   matches these, not when it matches general good practice.

4. **Apply the coherence lens**

   **Critical** — violates a rule the project has written down. Cite the rule. A project's
   list might include: no lazy or conditional imports; absolute imports only; modern type
   syntax; a required file-I/O idiom; an injected clock rather than direct time access;
   `@override` on overriding methods; no optional constructor collaborators; a comment
   policy. *Use the rules the project actually states, not this list.*

   **Major** — diverges from how the surrounding package solves the same problem:
   - Reimplementing a utility that already exists — search for it before flagging the
     duplicate, and cite the original
   - Naming style at odds with the package's vocabulary
   - Error handling shaped differently from siblings (raise vs log-and-return, which
     exception types, where the boundary is)
   - Logging acquisition or structured-field names diverging from neighbours
   - A model or type placed in a different layer than its peers
   - Test layout or fixture style differing from existing tests in the same package
   - Wiring done inline where the package uses a registration helper

   **Minor** — local polish: docstring style mismatch within one package, import ordering
   against the lint config, a defined type alias ignored in favour of the primitive, a
   module placed at an odd level compared with similar concerns nearby.

5. **Generate report** → `coherence-review-issues.md`

## Severity Model

| Severity | Indicators |
|----------|------------|
| Critical | Violates an explicit written rule in the project's conventions doc |
| Major | Diverges from how the surrounding package solves the same problem; duplicates an existing utility |
| Minor | Local style or organisation inconsistency with no functional impact |

## Output Format

Per [`review-protocol.md`](../../docs/review-protocol.md). Two fields matter more here than
elsewhere and are required on every finding:

```markdown
**Rule:** the written rule and where it is stated, or the sibling pattern being diverged from
**Reference:** path/to/sibling/file:45 — the existing example to mirror
```

A coherence finding without a reference is an opinion. Drop it.

## Example Usage

```
review-coherence              # Current branch vs main
review-coherence feat/foo     # Specific branch
review-coherence feat/foo dev # Different base
review-coherence 3574         # PR/MR by number
```
