
The Secure Text Edit View is a settings text row. Per the source's own doc
comment, it is meant for API keys, passwords, and other secrets that are
still routed through a view model — typically one whose backing setting has
secure storage enabled and is therefore stored through a keychain-backed
storage provider.

It specializes the text edit row
([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)), overriding
its field construction to make a masking (dot-obscured) secure field, so
a stored secret shows as one dot per character, and adding two
right-aligned buttons after the field: copy, which puts the secret on the
pasteboard, and an eye, which toggles showing the secret in plain text. A
shown secret is hidden again as soon as the person could look away from it:
when the window resigns key, the app resigns active, the view leaves its
window, or the setting changes from outside. Shown is a transient state and
is never persisted. The AI Providers editor's secret fields
([adhsdk.ingredient.ai.plugins.plugin-runtime](cookbook:e886e448-6aa5-4359-979d-49fba713ab2a)) use it.

The text edit row's own row layout, theme-driven font/color styling,
commit path, and view-model sync are out of this recipe's scope; only the
delta this specialization adds — the masked field, the copy and reveal
buttons, the re-obscure rules and the ban on further specialization — is
documented here. See
[adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c) for everything a
caller instantiating this component also gets.

