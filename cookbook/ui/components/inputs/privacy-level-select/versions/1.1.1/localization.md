
The source hardcodes every label, description, and badge string below as English, with no prop that lets a caller override them — see **string-externalization** and **no-hardcoded-strings** in Compliance (both `failed`). A localized implementation of this ingredient MUST externalize each of these to a locale-aware string resource; the keys below name what an implementation should externalize, using the source's current English text as the default.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `privacy_level_select.option.only_me.label` | Only me | Trigger and option label for the `only-me` level |
| `privacy_level_select.option.only_me.description` | Visible to you alone | Option description text |
| `privacy_level_select.option.hub.label` | Hub members | Trigger and option label for the `hub` level |
| `privacy_level_select.option.hub.description` | Visible to everyone on the Hub | Option description text |
| `privacy_level_select.option.public.label` | Public | Trigger and option label for the `public` level |
| `privacy_level_select.option.public.description` | Visible to anyone on the internet | Option description text |
| `privacy_level_select.option.team_org.label` | Team / Org | Disabled "coming soon" option label |
| `privacy_level_select.option.team_org.description` | Visible to members of your organization | Disabled option description |
| `privacy_level_select.badge.coming_soon` | Coming soon | Badge text on the disabled option |
| `privacy_level_select.aria_label.default` | Privacy level | Default accessible name for the trigger and listbox |

