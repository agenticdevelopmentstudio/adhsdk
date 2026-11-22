
This is the client for the gated roles and permissions surface at `/api/v1/access`. It covers
feature areas, the people an ecosystem's roles can be granted to, role CRUD, role assignments,
item restriction and an effective-permission explainer. Every call names its **target**: a
workspace by slug (a personal workspace's customer slug or an org slug), or an owner-made
ecosystem by id, whose roles are its product users' roles. A bare string is a workspace slug,
which is what every caller passed before ecosystems had roles. The module's own comment states
the server-side rules: reads answer 404 to non-members, role definition is admin-only, and
assignments and restriction need the manage verb (`M`) at the target scope, with the server
enforcing no-escalation. The client holds none of those rules. It exports a target type and two
target helpers, a set of camelCase row shapes mapped from snake_case wire shapes, a fallback
feature list, two write input shapes, and the `accessApi` object with twelve operations, each a
thin request builder over the shared authenticated-request helpers. It is a headless **logic**
module with no visual surface, so Appearance, States and Accessibility are not applicable and
the runtime contract is carried by Behavioral Requirements.

