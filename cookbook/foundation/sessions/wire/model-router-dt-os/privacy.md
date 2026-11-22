
- **Data collected**: None by this code. The types carry what callers fill in: template ids and names, match text for system prompts and user messages (`system`, `message`), provider configuration names and model ids, a Claude Code version taken from a user agent, and token counts. The built-in match texts are sentences of Claude Code's own prompts, not user content.
- **Storage**: None; the types are in-memory values. `encodedFile` produces bytes that `ModelRouterTemplateStore` writes; persistence is that store and the daemon's database.
- **Transmission**: The values travel between the daemon and its local clients as JSON. `ModelRouterProviderDTO` is declared secret-free: it carries no API key and no URL.
- **Retention**: Not applicable at this layer; retention is the daemon's.

