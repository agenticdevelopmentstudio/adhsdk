
`ThemeStorage` is the protocol that says where custom themes are persisted. The theme model does not own a settings system: a host that already has one supplies a conformer instead of inheriting a location for preferences. The surface is deliberately exactly what `ThemeStore` touches, which is two persisted values and one change hook.

Built-in themes are never stored. `ThemeStore` concatenates them with `BuiltInThemes.all` at read time, so an empty storage still yields a full catalog. The protocol is main-actor isolated and class-bound. `ThemeManager` is the consumer of the hook, and `UserDefaultsThemeStorage` is the conformer the SDK ships for hosts with no settings system of their own. The protocol itself contains no logic; this recipe specifies the contract a conformer must meet. The theme value being stored is described in [adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.color-theme](cookbook:932449c9-b57f-4e2c-992a-1e27584742b6).

