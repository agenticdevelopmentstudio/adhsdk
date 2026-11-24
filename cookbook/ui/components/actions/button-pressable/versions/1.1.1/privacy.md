
- **Data collected**: None. `button-pressable.tsx` collects no user data; `held` and `pressed` are transient boolean UI state.
- **Storage**: None. `held`/`pressed` live only in in-memory React component state (`useState`) and are never written to disk, cookies, or any storage API.
- **Transmission**: None. This file makes no network calls and sends no data anywhere.
- **Retention**: None beyond the component's lifetime. State resets to `false`/`false` on every fresh mount and is discarded on unmount.

