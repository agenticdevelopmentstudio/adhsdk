
These three files carry, but do not author or localize, user-facing text.
`presentPermissionPrompt` stores a caller-supplied `PermissionPrompt`
(`displayPrompt`/`permission.displayPromptTemplate`) untouched in
`pendingPermissions`. Error text — `ChatUpdate`'s `error.message`,
`MessageDeliveryStatus`'s `failed.reason` — is forwarded verbatim from a
caught `Error`'s message, `String(error)`, or the inbound event's own field,
in whatever language the throwing code or the backend produced it. None of
`DefaultOrchestrator.ts`, `InMemoryPermissionStore.ts`, or `ScriptedBackend.ts`
contains a translation table, a locale lookup, or pluralization logic;
localizing any of this text is the responsibility of whatever authors it (a
`GatingHook`/`ObservingHook`, the real `Backend`, or the UI layer), which is
out of scope for this recipe.

