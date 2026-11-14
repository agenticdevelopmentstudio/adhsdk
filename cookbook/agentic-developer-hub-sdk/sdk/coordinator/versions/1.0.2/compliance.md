
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | Privacy and Data |

`explicit-error-handling` is partial: in-band SSE errors, conversation
creation failures, and stream-transport failures each surface as a typed
`InboundEvent` or thrown `PersonaChatError`, but the outbound message
body's encoding failure is swallowed by `try?` with no error path (see
the open question on message-encode-failure-swallowed), and several
malformed-payload cases — an undecodable SSE block, an unmatched
`tool_call_completed` — are dropped silently by design rather than
surfaced as an error. `graceful-degradation` passes: every one of those
malformed-input paths degrades to "drop the block and keep streaming"
rather than crashing or corrupting the transcript. `fault-tolerance` is
partial because of the open question on concurrent-turns:
`TurnControl` tracks only one in-flight task, so
overlapping `send()` calls can leave a turn `destroy()` cannot cancel, and
`ensureConversation()`'s reentrant check can create two orphaned server-side
conversations. `separation-of-concerns` passes: the coordinator holds no
history, no prompt assembly, and no credentials, delegating all three to
adh and the injected `Authorize` closure. `unit-test-coverage` is partial:
sixteen `pcc-*` vectors plus four supplementary tests cover the
SSE-translation and lifecycle contract thoroughly, but nothing in the repo
exercises `SSEParser` directly or the concurrent-`send()` scenario above.
`secure-transport` is partial: requests go through the caller's
`Authorize` closure and whatever `baseURL` scheme the host configures, but
the source never checks that `baseURL` uses `https`, so an `http://` base
would be sent unencrypted with no warning from the coordinator.
`data-minimization` and `data-retention-policy` pass: the coordinator
holds no history and retains nothing beyond the active turn and the cached
conversation id.

