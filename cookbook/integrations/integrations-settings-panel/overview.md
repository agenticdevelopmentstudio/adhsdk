
`IntegrationsSettingsPanel` is the "Integrations" pane of the settings window. It is a split view: a sidebar lists the integrations added so far, and the detail shows the selected one. Today the only integration is Gmail, whose detail is the Gmail settings view driven by a Gmail settings model that the panel creates from the mail client it is given.

A footer under the sidebar holds a `+` button, which offers the integrations that can be added, and a `−` button, which removes the selected integration after a confirmation. Nothing is listed until Gmail is configured on the service or the user picks it from `+`.

The panel also contributes help topics and search keywords to the settings window, and exposes two members for the landing that follows a browser sign-in: whether this panel started the latest sign-in, and a call that reloads the accounts.

