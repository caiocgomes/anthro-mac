# Tests

## Test Strategy

- **Framework**: <!-- e.g. pytest, vitest -->
- **Full-suite command**: <!-- e.g. `uv run pytest -q` -->
- **Conventions**: <!-- file layout, naming, fixtures -->
- **Mutation tool**: <!-- mutmut | Stryker | PIT | manual -->

## Spec-to-Test Mapping

<!-- One block per scenario in specs/, scenario name verbatim. Do not restate GIVEN/WHEN/THEN; the scenario has them. -->

### Capability: <!-- capability-path -->

#### Scenario: <!-- scenario name (must match spec) -->
- **Test name**: <!-- test_descriptive_name -->
- **Test file**: <!-- tests/... -->
- **Level**: <!-- acceptance | integration -->
- **Breaks if**: <!-- the production change that would make this test fail -->
- **Expected red**: <!-- the assertion failure expected against the stubs -->

## Coverage Ledger

<!-- One row per scenario. State: planned -> red (only with red SHA and observed failure excerpt) -> green (only with the commit where it passes). Non-executable rows: N/A (non-executable), naming the mechanical check. -->

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| <!-- cap --> | <!-- scenario --> | <!-- path --> | <!-- name --> | <!-- break --> | | | planned |

## Test Changes After Red

<!-- Append-only. Empty at planning. Each entry: date, test, what changed, why, which spec change justifies it, user OK. -->
