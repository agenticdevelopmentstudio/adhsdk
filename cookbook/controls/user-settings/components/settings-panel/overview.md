
The Settings Panel is the top-level container of the user-settings control family. It lays out a sidebar of pane tabs beside a detail area that shows the body of the selected pane. The CSS namespace for the family is `aws-`, and this component owns the `aws-panel` root class and the `aws-panel__*` element classes.

The component exposes two authoring styles that share one selection model:

- **Compound mode**: the caller supplies children, normally one `SettingsPanel.Sidebar` and several `SettingsPanel.Pane` elements. Each Pane registers itself with the panel and renders its own children only while selected.
- **Data-driven mode**: the caller supplies a non-empty `panes` array of entries (descriptor fields plus a `body`). The panel renders its own sidebar and a detail container with the selected entry's body.

The same selection model serves both styles. Selection is controlled when `selectedId` is supplied and internal otherwise. The selected id can optionally be persisted in browser local storage under a caller-chosen key. The panel auto-selects the first enabled pane when there is no valid selection. The component is a client component (`'use client'`) and ships as `SettingsPanel` with the properties `Sidebar` and `Pane`, plus the exported props type `SettingsPanelProps`.

