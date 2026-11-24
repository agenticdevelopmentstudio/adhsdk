
Segments are written `from→to@lane`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| commit-graph-layout-001 | new-commit-slot, first-parent-slot, root-closes-slot | `C(B)`, `B(A)`, `A()` | Every row column 0, lane 0, width 1. C: top `[]`, bottom `[0→0@0]`; B: top and bottom `[0→0@0]`; A: top `[0→0@0]`, bottom `[]` (test: linearHistoryStaysInColumnZero). |
| commit-graph-layout-002 | further-parent-slot, first-parent-slot | `M(A,B)`, `A(P)`, `B(P)`, `P()` | M col 0 lane 0, bottom `[0→0@0, 0→1@1]`, width 2; A col 0, top and bottom `[0→0@0, 1→1@1]`; B col 1 lane 1, top `[0→0@0, 1→1@1]`, bottom `[0→0@0, 1→0@1]`, width 2; P col 0 lane 0, top `[0→0@0]`, bottom `[]`, width 1 (test: branchAndMergeOpensAndClosesALane). |
| commit-graph-layout-003 | leftmost-expecting-slot, first-parent-slot | `M(A,B)`, `B(P)`, `A(P)`, `P()` | B keeps column 1 with bottom `[0→0@0, 1→1@1]`; A bottom `[0→0@0, 1→1@1]`; P col 0 lane 0, top `[0→0@0, 1→0@1]`, bottom `[]`, width 2 (test: laterSlotExpectingACommitClosesIntoIt). |
| commit-graph-layout-004 | further-parent-slot, trim-right | `O(A,B,C)`, `A(R)`, `B(R)`, `C(R)`, `R()` | O bottom `[0→0@0, 0→1@1, 0→2@2]`, width 3; B bottom `[0→0@0, 1→0@1, 2→2@2]`; C col 2 lane 2, top `[0→0@0, 2→2@2]`, bottom `[0→0@0, 2→0@2]`, width 3; R top `[0→0@0]`, width 1 (test: octopusMergeOpensThreeLanes). |
| commit-graph-layout-005 | missing-parent-stays-open, monotonic-lanes | `A(X)`, `B()`, `C()` with `X` never appended | A col 0 lane 0, bottom `[0→0@0]`; B col 1 lane 1, top and bottom `[0→0@0]`, width 2; C col 1 lane 2, same segments (test: missingParentLeavesLaneOpenWithoutCrash). |
| commit-graph-layout-006 | root-closes-slot, trim-right, monotonic-lanes | `A()`, `B()` | A col 0 lane 0; B col 0 lane 1; both with no segments and width 1 (test: twoRootsBothColumnZeroAfterTrim). |
| commit-graph-layout-007 | stateful-paging | `M(A,B)`, `A(C)`, `C(D)`, `B(D)`, `D(E)`, `E()` appended as 3 + 3 | The same six rows as one append of all six (test: pagingMatchesOneShot). |

