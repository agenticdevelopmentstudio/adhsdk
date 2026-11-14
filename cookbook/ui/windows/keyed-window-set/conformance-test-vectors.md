
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| keyed-window-set-001 | open-new, open-existing | `open("a")` twice | `open` called once, `bringForward` once, the same controller both times, `keys` `["a"]`. |
| keyed-window-set-002 | close-forgets | `open("a")`, then its `onClose` | `controller(for: "a")` is `nil`, `keys` `[]`; a third `open("a")` calls `open` again. |
| keyed-window-set-003 | restore | stored `["a", "gone", "b"]`, `open` returns `nil` for `gone` | `open` called for `a`, `gone`, `b` with `activates` false; `keys` `["a", "b"]`. |
| keyed-window-set-004 | order, open-declined | `open("b")`, `open("a")`, `open("b")`, declined `open("x")` | `keys` `["b", "a"]`. |

