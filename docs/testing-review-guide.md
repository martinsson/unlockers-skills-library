# Testing Review Guide

Tips for conducting a testing review on a PR/MR diff. The rules themselves live in
[`testing-rules.md`](testing-rules.md). Patterns below are shown for several languages;
adapt the search terms to your stack.

## Quick Scan — Red Flags in the Diff

Patterns that are almost always a violation:

| Search for | Violation |
|------------|-----------|
| `unittest.mock`, `pytest_mock`, `@patch(`, `mocker.patch`, `Mock()`, `MagicMock()` | Mocking (Python) |
| `Mockito`, `@Mock`, `mock(`, `when(...).thenReturn` | Mocking (Java) |
| `jest.mock`, `vi.mock`, `sinon.stub`, `.mockReturnValue` | Mocking (JS/TS) |
| `time.sleep(`, `Thread.sleep(`, `setTimeout`, `await delay(` (value > 0) | Fixed sleep |
| test names not matching `given_…_when_…_then_…` | Naming violation |
| multiple `assert result.<attr>` lines | Asserting individual attributes |
| copy-pasted test bodies with minor edits | Should be parametrized / table-driven |
| `test_has_…` / `test_is_…` style names | Likely trivial |
| asserting a bare `false` | Use an explicit failure with a message |

## What to Check for Each Changed Production File

1. Are new public methods/functions covered by at least one test?
2. Are new branches (if/else, switch/match, exception paths) exercised?
3. For bug fixes: is there a test that would have caught the bug?

## Test Body Size

Count statements in the test body. If it exceeds **10 statements** or **15 lines**, flag
it — there is always a refactor available (extract helper, add defaults, use positional args).

## When to Escalate

Flag for human review if:
- No fake exists for a new port being introduced.
- A test requires a real external service with no simulator.
- Async behaviour makes deterministic testing genuinely unclear.
