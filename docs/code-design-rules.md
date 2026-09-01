# Code Design Rules

What good looks like *inside* a type or a function. For where code goes — controllers, use
cases, ports — see [`hexagonal-architecture-rules.md`](hexagonal-architecture-rules.md).

[`accidental-complexity-guide.md`](accidental-complexity-guide.md) catalogues the smells and
how to detect them. This page states the target shape and the order to reach for it in.
Examples are Python; the rules are not.

**Rules 1 and 2 come first.** Before any architectural move, look at whether the primitives
have types and whether the data clumps have behaviour. They are cheap, they are local, and
they are where most of the leverage is. They also test well — no hidden state, no side
effects, so the tests are plain function calls with plain assertions.

## 1. Wrap Primitives in Types That Carry Their Rules

A domain concept represented as `str`, `int` or `float` has nowhere to put its rules, so the
rules end up scattered across every caller — and the type system stops helping.

```python
@dataclass(frozen=True)
class Millimetres:
    value: int

@dataclass(frozen=True)
class Chf:
    centimes: int

    def __post_init__(self) -> None:
        if self.centimes < 0:
            raise ValueError("Chf cannot be negative")
```

`Millimetres(30) + Chf(500)` no longer compiles or runs — the mistake is caught by the
type, not by a reviewer. And the negativity rule lives in one place instead of at every
site that constructs an amount.

**Consequence of skipping it:** validation gets duplicated at call sites, drifts between
them, and the case someone forgot surfaces as an exception thrown deep in the domain (see
rule 3).

**Detection:** the guide's [§5 Primitive Obsession](accidental-complexity-guide.md).

## 2. Attach Behaviour to Data Clumps, as Immutable Objects

When the same group of values travels together — `street, city, postal_code`;
`amount, currency`; `start, end` — it is an object that has not been written yet. Until it
is, the logic that belongs to it lives in whichever service happened to need it first, and
the next service that needs it writes its own copy.

Give the clump a type and move the logic onto it. Make it **immutable**: any mutation is a
named method on the object, with the narrowest visibility that works.

```python
@dataclass(frozen=True)
class DateRange:
    start: date
    end: date

    def overlaps(self, other: "DateRange") -> bool: ...
    def extended_to(self, new_end: date) -> "DateRange": ...   # returns a new range
```

Types from rules 1 and 2 belong in their own file. Left inside the service that first
needed them, they couple every later user of the type to that service.

**Consequence of skipping it:** the service classes grow, and the same rule gets
reimplemented slightly differently in each of them.

**Detection:** the guide's [§6 Data Clumps](accidental-complexity-guide.md) and
[§18 Anemic Domain Model](accidental-complexity-guide.md).

## 3. Let Exceptions Propagate

**The default is the simplest possible handling:** don't catch. Let the exception travel to
the top of the application, where one generic handler turns it into an error response.

Any other strategy — catching mid-flight, wrapping, replacing exceptions with an explicit
result type — has to be justified case by case, on that case's merits. It is a reasonable
choice sometimes; it is never the starting point.

Nested exception handling inside one class, or the same failure handled at several levels
of the application, is a design error rather than a robustness measure. Each catch is a
place a future reader must decide whether the failure was really handled.

**Where the catch is a symptom:** an exception thrown deep in the domain because an illegal
value got that far usually means the value should have been rejected at construction. Fix
it with rule 1, not with a `try`.

**Detection and the boundary cases where catching *is* right:** the guide's
[§2 Exception Handling Complexity](accidental-complexity-guide.md) — adapters translating
library errors, framework-level handlers, resource cleanup.
