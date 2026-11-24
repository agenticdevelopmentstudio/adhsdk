
- **Null and empty input**: No dead rows shows "No dead jobs." (MUST). A dead row with no last error shows
  an em dash (MUST).
- **Concurrent access**: A row retried by another operator first answers with an error, which is shown,
  and the row leaves the list on the next read (MUST).
- **Old tokens**: Tokens minted before phase 9 carry only `ai-processing:worker` and are listed as not
  pool tokens (MUST).

