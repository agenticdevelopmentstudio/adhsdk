
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| progress-001 | show-progress-bar | `open={true}, done={3}, total={10}` | Progress bar shows 30% width |
| progress-002 | calculate-percentage-safely | `open={true}, done={0}, total={0}` | Progress bar shows 0%, no NaN displayed |
| progress-003 | display-completion-count | `open={true}, done={5}, total={20}` | Text displays "5 of 20" in monospace |
| progress-004 | display-status-or-current-label | `open={true}, currentLabel={"Uploading file.txt"}, finished={false}, error={null}` | Status text shows "Uploading file.txt" |
| progress-005 | display-status-or-current-label | `open={true}, currentLabel={undefined}, finished={true}` | Status text shows "Finished" |
| progress-006 | display-status-or-current-label | `open={true}, currentLabel={undefined}, finished={false}, error={…}` | Status text shows "Paused" |
| progress-007 | display-status-or-current-label | `open={true}, currentLabel={undefined}, finished={false}, error={null}` | Status text shows "Working…" |
| progress-008 | halt-on-error, show-error-block-when-halted | `open={true}, error={message: "Upload failed"}, finished={false}` | Error block visible with message "Upload failed" |
| progress-009 | show-error-block-when-halted | `open={true}, error={message: "Failed", itemLabel: "photo.jpg"}, finished={false}` | Error block shows "photo.jpg" above "Failed" message |
| progress-010 | show-results-log-when-provided | `open={true}, results=[{id: "1", label: "file1.txt", status: "ok"}]` | Results list renders with one item |
| progress-011 | render-result-label-and-status | `open={true}, results=[{id: "1", label: "file.txt", status: "ok", message: "moved"}]` | Result shows "file.txt — moved" in muted text |
| progress-012 | render-result-label-and-status | `open={true}, results=[{id: "1", label: "file.txt", status: "failed", message: "Not found"}]` | Result shows "file.txt — Not found" in red text |
| progress-013 | render-result-label-and-status | `open={true}, results=[{id: "1", label: "file.txt", status: "ok"}], okLabel={"synced"}` | Result shows "file.txt — synced" (no message provided, uses okLabel) |
| progress-014 | show-continue-and-stop-when-halted | `open={true}, error={…}, finished={false}, onContinue={fn}, onStop={fn}` | Continue and Stop buttons are visible and clickable |
| progress-015 | show-close-when-finished | `open={true}, finished={true}, onClose={fn}` | Close button is visible and clickable |
| progress-016 | hide-buttons-during-progress | `open={true}, finished={false}, error={null}` | No action buttons are visible |
| progress-017 | prevent-dismiss-mid-run | `open={true}, finished={false}` triggered by Escape | `onClose` is NOT called; modal remains open |
| progress-018 | prevent-dismiss-mid-run | `open={true}, finished={true}, onClose={fn}` triggered by Escape | `onClose` IS called |
| progress-019 | finished-overrides-halt | `open={true}, error={message: "Upload failed"}, finished={true}, onClose={fn}` | Error block and Continue/Stop buttons are NOT rendered; only Close is visible |

