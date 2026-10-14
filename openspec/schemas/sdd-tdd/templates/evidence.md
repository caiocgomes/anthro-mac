# Evidence

## Red Gate Replay

- **Red commit**: <!-- SHA from `git log --format=%h --grep='^test(red)' -n 1` -->
- **How replayed**: <!-- temporary worktree at the red SHA | clean checkout | not possible (reason; cite task 0.2 excerpts, weaker evidence) -->
- **Result**: <!-- each scenario test failed by assertion: yes / no (list exceptions) -->

## Test Freeze

- **Command**: <!-- git diff <red-sha>..HEAD --stat -- <scenario test files> -->
- **Changes found**: <!-- none | list, each matched to an entry in tests.md Test Changes After Red -->

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| <!-- cap --> | <!-- break --> | <!-- test --> | <!-- yes --> |

## Full Suite

- **Command**: <!-- exact command -->
- **Result**: <!-- passed / failed / skipped counts -->
- **Output clean**: <!-- yes / no (errors or warnings listed) -->

## TDD Path

TDD path: <!-- superpowers | embedded -->

## OpenSpec Verify

<!-- Summary of /opsx:verify CRITICAL and WARNING findings, or "verify workflow not installed". -->

## Decision

DECISION: <!-- PASS | FAIL -->

<!-- When FAIL: the blocking items. -->
