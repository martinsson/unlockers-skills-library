# Diagrams

Visual companions to the definitions. Deliberately kept out of `AGENTS.md`, `docs/` and the
skill files — those are read by agents, where prose is the working format and a diagram is
weight. These are for humans deciding whether to adopt something, or working out how the
pieces fit.

| Diagram | Shows |
|---------|-------|
| [`merger-lifecycle.md`](merger-lifecycle.md) | Everything the merger agent does between "ready" and "merged" — the monitor loop, the fix paths, the two exits and the one escalation |
| [`library-map.md`](library-map.md) | Where each skill acts, how nudges relate to the backstop, and which docs feed which skills |

Mermaid, so they render on GitHub and Azure DevOps and stay diffable. If one contradicts the
prose, the prose is right — fix the diagram.
