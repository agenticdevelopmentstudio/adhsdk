
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | `ReactNode` | none | Compound-mode content; ignored when `panes` is non-empty |
| `panes` | array of pane entries | none | Data-driven entries with `id`, `title`, optional `icon`, optional `section`, optional `isDisabled` and a `body` |
| `defaultPaneId` | `string` | none | Initial selection in uncontrolled mode when nothing is persisted |
| `selectedId` | `string` | none | Makes selection controlled when not `undefined` |
| `onSelect` | `(id: string) => void` | none | Called on user selection and on auto-selection |
| `persistKey` | `string` | none | Enables local-storage persistence under `aws-settings:<persistKey>` |
| `className` | `string` | none | Extra class on the root element |
| `sidebarTitle` | `string` | none | Heading shown at the top of the sidebar |
| `Sidebar` `title` | `string` | none | Heading override for a `SettingsPanel.Sidebar` element |
| `Pane` props | `id`, `title`, `icon`, `section`, `isDisabled`, `children` | `id` and `title` required | Descriptor fields for a `SettingsPanel.Pane` element, plus its body |

