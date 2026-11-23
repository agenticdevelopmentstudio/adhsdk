
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `urlSelection` | `{ serviceId?: string; onSelectService: (id: string or null) => void }` | omitted | Makes the open service URL-driven and deep-linkable; omitted, selection is internal state. |
| `AiSettingsSection` props | `Omit<ServicesSectionProps, "title">` | `{}` | The same options as `ServicesSection` except the title, fixed at "AI Settings", so a host's `urlSelection` survives. |
| `title` | string | "Persona Services" for `ServicesSection`; "AI Settings" for `AiSettingsSection` | The rail level heading, for example the label a host's Settings topic uses. |
| `PERSONA_SERVICES_CACHE_KEY` | string | `"persona-services"` | The cache key of the services list, exported for callers that write services without the hook. |

