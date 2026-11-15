
This module holds the status dashboard's wording and drawing vocabulary for the server-owned board. Its header comment is explicit that every verdict is the server's: the indicator and its environment-scoped twin (`scope`), which activity rows are unresolved or running (`unresolved` / `running` / `buildInFlight` on each row), the stats-strip counts (`deployCounts`) and the board's freshness all arrive on the wire. What remains here are small, pure, synchronous helpers that map those verdicts to the sign's vocabulary and to words:

- the sign / pill vocabulary — a sign state (one of three values) plus a count.
- the wire-indicator translation map — the one translation from the server's wire-level indicator vocabulary (`operational`/`degraded`/`outage`) to the sign-state vocabulary.
- the activity-window-caption operation — the "24h" / "7d" caption for the window the server chose.
- the headline operation — the headline shared by the mobile hero sign, the desktop top-bar pill and the wallboard pill.
- the still-unresolved operation — whether a feed row is still unresolved against the current board, by looking up the problems the server named as holding it open.

Consumers read the wire-indicator translation map and the still-unresolved operation for the overview tab and (the map alone) the portfolio indicator; the activity-window-caption operation for the stats strip; the headline operation for the hero sign, the top-bar pill and the wallboard pill; and the sign-state vocabulary for the status sign and its sublabel. Types come from Board Types (the activity row, indicator and problem shapes).
