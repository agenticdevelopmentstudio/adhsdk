
**Decision**: Newly added keys are optional on decode, through hand-written decoders on `RateLimitSnapshotDTO`, `UsageRowsDTO`, `UsageHoursRowDTO` and `UsageHoursMetricDTO`.
**Rationale**: The source comments state that `./install` swaps the daemon while an older menu-bar app keeps running until relaunched, so a newly required key would throw and blank the whole Usage window during that window.
**Approved**: pending

**Decision**: `UsageHoursMetricDTO` has its own tolerant decoder even though its parent reads it with a present-or-nil call.
**Rationale**: The source comment explains that present-or-nil only catches an absent key; a missing key inside a nested type's synthesized decoder propagates straight through the outer tolerant decoder.
**Approved**: pending

**Decision**: The HUD payload is the new key `hud_quota`, not the old `hud`.
**Rationale**: The old `hud` had a different shape and an older app's synthesized decoder requires its retired keys; an absent key decodes to nil, which every shipped client already shows as a dash.
**Approved**: pending

**Decision**: `UsageAccountSectionDTO.isCurrent` is still encoded, always `false`, although no current client reads it.
**Rationale**: App builds up to 2.28.x have a synthesized decoder that requires the key; removing it blanked that app's Usage window during the daemon/app skew. The source says to keep emitting it until every shipped client tolerates its absence.
**Approved**: pending

**Decision**: Row kinds are told apart by shared label constants (`spend`, `fable quota`, `7d quota`, `5h quota`), and `resolvedWindowSeconds` falls back to the label when `windowSeconds` is absent.
**Rationale**: The label is the only marker on the wire for a spend or Fable row, and the only other window marker on a row from a daemon too old to send `windowSeconds`; one spelling shared by producer and consumer keeps the fallback working.
**Approved**: pending

**Decision**: Windows are ordered by `windowSeconds`, not by `resetsAt`.
**Rationale**: The 7d reset falls sooner than the 5h reset for most of every five-hour period, so an order built from reset instants swaps the columns under the reader; a window's width never changes.
**Approved**: pending

**Decision**: Utilization headers are always multiplied by 100.
**Rationale**: The header is a 0 to 1 fraction that exceeds 1 when over quota; the earlier "multiply only when at most 1" heuristic rendered 105% as 1.0%. `AccountQuotaTests.testReadingOverQuotaFractionIsNotTruncated` records the evidence.
**Approved**: pending

**Decision**: `oneSectionPerAccount` keeps the login over a setup token for one address.
**Rationale**: A usage display is a list of accounts, and the login is the credential Claude Code runs as, so its bucket is the one the next session draws down; an address with only a token keeps the token so it is not dropped from the display.
**Approved**: pending

**Decision**: `ClaudeCredentialDTO` carries the whole login, refresh token included, from the app to the daemon, and `probeOnly` is what the daemon keeps.
**Rationale**: The keychain items belong to the app because macOS shows the requesting process in the permission dialog and only a UI process can answer it; every judgment about the credential belongs to the daemon. Dropping the refresh token after the evaluation leaves the daemon holding only a short-lived bearer token.
**Approved**: pending

**Decision**: `credentialKind` is a raw String on sections, readings and credentials, not the enum.
**Rationale**: A kind this build has never heard of must degrade to one unlabeled section, not throw the whole payload away during version skew.
**Approved**: pending

