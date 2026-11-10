
Not applicable: `displayConfig.reducedMotion` is stored verbatim (see
construction-copies-config-fields-verbatim) but never read or branched on by
`DefaultOrchestrator.ts`, `InMemoryPermissionStore.ts`, or `ScriptedBackend.ts`
— responding to it is a rendering concern for whatever UI layer reads
`displayConfig`, not this runtime.

