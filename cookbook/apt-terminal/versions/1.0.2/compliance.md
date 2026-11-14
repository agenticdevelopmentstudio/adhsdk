
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | failed | Reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`separation-of-concerns` is passed: configuration, authentication, request
building, resource commands, and CLI dispatch each live in their own module
(see Overview), and no module reaches into another's file or HTTP state.
`unit-test-coverage` is partial: the seven test modules (`test_auth.py`,
`test_auth_commands.py`, `test_cli.py`, `test_config.py`, `test_crud.py`,
`test_public.py`, `test_resources.py`) cover the great majority of this
contract, but `whoami()`'s 401-retry-then-fail branch, `config.py`'s
missing-file and malformed-file `load()` branches, and `save()`'s
omit-when-`None` serialization are not exercised by any given test (each is
called out individually above). `secure-storage` is partial: `save()` creates
and tightens the config file to `0o600` on every write
(`test_save_sets_0600`), but the tokens live in that plain TOML file rather
than the operating system's credential store. `input-sanitization` is
passed: `build_body` rejects unknown fields and validates enum values against
the model's declared choices before any request is sent. `secure-transport`
is partial: neither `client_factory()` nor `public_client()` enforces
`https://` on `base_url`, so an overridden base URL may be plain HTTP.
`timeout-handling` is failed: neither client passes a `timeout=` argument
(see no-request-timeout). `explicit-error-handling` is partial: every
authenticated and public request path raises a named, message-bearing
`AptError` subtype with a distinct exit code, but `logout()`'s server-side
revoke failure is swallowed with no signal to the caller — the open question
on logout-revoke-failure-swallowed.

