
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`server-side-authorization` passes: both fail-closed layers
(`mcp-registers-tier-set-only`, `mcp-handler-recheck`) resolve tier
entirely server-side from `c.get('tier')`, upstream of these three files;
no tool trusts a client-supplied role or tier value. `input-sanitization`
passes: every write tool's argument is parsed through its zod schema
before reaching a store call, and no tool interpolates a string argument
into a query, shell command, or rendered markup — arguments flow only into
typed store-function parameters. `secure-log-output` passes trivially — per
Logging, there is no log output in these three files to leak anything
into. `separation-of-concerns` passes: `route.ts` owns transport mounting
and the DNS-rebinding/host-allowlist concern, `server.ts` owns server
construction and the fail-closed authorization gate, and `tools.ts` owns
the tool catalog and its REST-parity delegation, with every actual
store/service operation living in files outside this recipe entirely.
`unit-test-coverage` passes: `mcp.int.test.ts` exercises the transport's
auth boundary, tier-based tool visibility, the success/failure envelope,
and both fail-closed refusal shapes; `mcp-deploy-tools.int.test.ts` covers
the deploy-project re-verification fix; `board-route.test.ts`'s MCP
`describe` block covers `get_problems`/`get_issue` parity with `GET /board`,
including the Task-14 stale-ledger regression. `explicit-error-handling` is
`partial`: every thrown `execute()` error is caught and converted to a
typed `execution_error` envelope, never silently swallowed — but a
malformed JSON `POST` body is caught and discarded
(`.catch(() => undefined)`) with no signal distinguishing it from a
bodyless `GET`/`DELETE` request, so that one specific failure mode
produces no error of its own at this layer (see Edge Cases).

