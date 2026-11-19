
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

Notes: separation-of-concerns passes because the component splits into three
independent responsibilities — plugin lifecycle (`AIPluginsCoordinator`),
configuration modeling and persistence (`AIProviderConfigStore`,
`AIProviderResolver`, `AIProviderDefaults`, `AIProviderMigration`,
`PluginConfigStore`), and conversation driving (the two
`ChatConfigProvider` + chat-engine pairs) — and none reaches into another's
storage. unit-test-coverage passes because the conformance vectors trace to
`LocalChatSessionTests`, `AIProviderConfigStoreTests`,
`AIProviderResolverTests`, `AIProviderMigrationTests`, and
`AIProviderDefaultsTests`, which exercise streaming, seeding, resolution,
migration, and first-run defaults without a live provider. secure-storage
passes because every `.secret` field is persisted through a
`UserSetting<String>` constructed with `isSecure: true`, so credentials land
in the Keychain and never in plain user defaults (see Privacy).
input-sanitization and explicit-error-handling are partial because
`MCPChatToolSource.callTool` decodes the model's `argumentsJSON` with `try?`
and forwards `nil` arguments on a decode failure instead of reporting a tool
error — see mcp-tool-source-argument-validation and its Design Decision — while
the other failure paths (no configured provider, unknown tool, a throwing
MCP call) surface as explicit `ChatError` or tool-error text.
no-hardcoded-strings fails because the user-facing error strings listed
under Localization are English literals with no localization mechanism.

