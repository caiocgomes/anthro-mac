# Tasks

## 0. Red gate

- [ ] 0.1 Write every scenario test from tests.md and stubs with the exact signatures from Interface Under Test (neutral return values, no logic)
- [ ] 0.2 Run the scenario tests; confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [ ] 0.3 Commit tests and stubs only as `test(red): <!-- change-name -->`; write the SHA in the ledger
- [ ] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing

## 1. <!-- Capability or slice -->

- [ ] 1.1 Implement <!-- what -->; verified when [tests: <!-- test_a, test_b -->] pass
- [ ] 1.2 Implement <!-- what -->, unit tests first (inner loop); verified when [tests: <!-- test_c -->] and its unit tests pass
- [ ] 1.3 Refactor <!-- module -->; full suite stays green

## 2. Verification

- [ ] 2.1 Mutation check for <!-- capability -->: apply "Breaks if" mutation, see <!-- test --> fail, revert
- [ ] 2.2 Run the full suite fresh; all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change <!-- change-name -->`) and reach `DECISION: PASS`
- Archive the change
