
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `status.working` | "Working…" | Displayed when run is in progress and no `currentLabel` is provided. Hardcoded in the component; not exposed as a prop. |
| `status.paused` | "Paused" | Displayed when run is halted on error and no `currentLabel` is provided. Hardcoded; not exposed as a prop. |
| `status.finished` | "Finished" | Displayed when run is complete and no `currentLabel` is provided. Hardcoded; not exposed as a prop. |
| `action.continue` | "Continue" | Button label when halted. Hardcoded; not exposed as a prop. |
| `action.stop` | "Stop" | Button label when halted. Hardcoded; not exposed as a prop. |
| `action.close` | "Close" | Button label when finished. Hardcoded; not exposed as a prop. |
| `progress.count` | "{done} of {total}" | Count text. Word order is locale-dependent — a translation MUST be able to reorder the `{done}`/`{total}` placeholders, not just substitute the numbers. Hardcoded; not exposed as a prop. |
| `result.ok` | "done" | Default status text when result status is "ok" and no message provided (overridable via `okLabel` prop). |
| `result.failed` | "failed" | Default status text when result status is "failed" and no message provided (overridable via `failedLabel` prop). |

Only `result.ok` and `result.failed` are host-overridable (`okLabel`/`failedLabel`); every other string above is a hardcoded JSX literal in the component.

