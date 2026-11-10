
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | partial | access-patterns |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | failed | reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | passed | security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | security |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | security |

Every logic component in this cookbook is held to at least
`separation-of-concerns` and `unit-test-coverage`. **`separation-of-concerns`**
passes: `teams.ts` owns the `Team` route stem, `team-members.ts` owns the
membership route stem, and `wire.ts` is a type-only file the other two read
— no file reaches into another's internals. **`unit-test-coverage`** is
`partial`: `teams.test.ts` exercises `toTeam` and `validateTeamIdentifier`
directly (the vectors above traced to its three assertions), but no test
file exists for `team-members.ts` at all — every `teamMembersApi` behavior
in this recipe is traced to the source code and its doc comments, not to a
test assertion. **`api-design-conventions`** is `partial`: the domain does
not follow one uniform client shape end to end — `teamsApi` maps through a
`wire.ts` row and a `toX` mapper and translates a 409 to a friendly message
on write, while `teamMembersApi` declares its type directly with no mapper
and no friendly-message translation on a duplicate-member 409 (see Design
Decisions for why the divergence is deliberate; the asymmetry itself is
real, not invented). **`idempotent-operations`** is `failed`, honestly:
neither `teamsApi.create`/`update` nor `teamMembersApi.add`/`addPersona` is
idempotent — a retry of a write that already succeeded server-side (e.g.
after a dropped response) hits a 409 conflict rather than transparently
returning the existing row, unlike the idempotent-per-triple pattern the
sibling `hub-domain-projects` recipe documents for `artifacts.link`.
**`error-recovery`** is `partial`: `teamsApi.get`'s 404 recovers to a
documented `null`, but (a) that recovery is over-broad — see
team-get-swallows-any-error-as-not-found — and (b) no method on either
client retries or backs off a transient failure. **`no-hardcoded-strings`**
is `failed`: `validateTeamIdentifier`'s two messages and the
`rethrowConflict` friendly-conflict message are fixed English literals with
no i18n key anywhere in these files (see Localization). **`secure-transport`**
passes: every call goes through `authedJson`/`authedRequest`'s Bearer-token
client, and this domain attaches no credential or cookie of its own.
**`secure-log-output`** passes because there is no logging at all in this
domain (see Logging). **`server-side-authorization`** passes: this domain
never attempts its own authorization check — team owner/admin scope and
the persona `may_act` `'team'` grant are both enforced entirely by the
backend, and this client only surfaces the resulting 403/404 (file headers
of both `teams.ts` and `team-members.ts`).

