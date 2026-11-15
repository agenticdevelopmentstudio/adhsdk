
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| short-text-001 | fits-unchanged | `"short".shortened(to: 10)` (test: underTheLimitIsUnchanged). | `short`. |
| short-text-002 | fits-unchanged | `"0123456789".shortened(to: 10)` (test: exactlyTheLimitIsUnchanged). | `0123456789`: exactly the limit is not cut. |
| short-text-003 | cut-length, ellipsis-single | `"0123456789ABC".shortened(to: 10)` (test: overTheLimitIsCutEndingInAnEllipsis). | `0123456…`, with a `count` of 8. |
| short-text-004 | default-limit, fits-unchanged | A 60-character string, then `.shortened()` (test: see ShortTextTests). | The same 60 characters. |
| short-text-005 | default-limit, cut-length | A 61-character string of `a`, then `.shortened()` (test: see ShortTextTests). | 57 `a` characters and `…`, 58 characters in all. |
| short-text-006 | limit-three | `"abcd".shortened(to: 3)` (test: see ShortTextTests). | `…`. |
| short-text-007 | fits-unchanged | `"".shortened(to: 0)` and `"ab".shortened(to: 2)` (test: see ShortTextTests). | The empty string and `ab`; no cut, so the minimum-limit precondition is never reached. |
| short-text-008 | count-in-characters | Six repetitions of the family emoji `👨‍👩‍👧` (scalars U+1F468 U+200D U+1F469 U+200D U+1F467, one Character each) with `.shortened(to: 5)` (test: see ShortTextTests). | Two whole family emoji then `…` (`👨‍👩‍👧👨‍👩‍👧…`): no emoji is split. |
| short-text-009 | no-word-boundary | `"hello world and more".shortened(to: 9)` (test: see ShortTextTests). | `hello …`: six characters (`hello ` with its trailing space) then the ellipsis. |

