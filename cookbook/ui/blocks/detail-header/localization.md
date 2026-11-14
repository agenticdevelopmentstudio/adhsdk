
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `detail_header.no_api_endpoint` | "This view has no API endpoint" | Default reason for the disabled API button |
| `detail_header.no_help` | "No help for this view" | Default reason for the disabled help button |
| `detail_header.api_label` | "API" | Visible text of the disabled API button |
| `detail_header.api_disabled_name` | "API — {reason}" | Accessible name of the disabled API button |
| `detail_header.help_disabled_name` | "About this section — {reason}" | Accessible name of the disabled help button |

The accessible names are built by concatenating an English prefix, an em dash and the reason, so a translator cannot reorder them. The two reasons are overridable through props; the prefixes and the "API" text are not. The row uses `pr-2` and `px-2` plus a left-to-right order of lead, tools, title and slots, with no logical-direction classes beyond those, so a right-to-left layout would draw the slots at the physical right edge unless the host mirrors the row.

