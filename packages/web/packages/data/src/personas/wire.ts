// Types for the personas domain. Two layers live here:
//
//   * the DOMAIN types (`MeRow`, `PersonaRow`, `ServiceRow`, ... — camelCase, ISO timestamps) that
//     components consume and that stay stable across wire changes;
//   * the /v1 WIRE types (`V1*`, snake_case, `created`/`updated` in unix seconds) at the bottom of
//     the file, which only `./mappers` reads. The persona GRANT surfaces live under
//     `/v1/personas/{id}/{tools,actors,user_tools}`, approvals under `/v1/processing/persona_approvals`.
// The domain types carry full backend-schema fidelity (not just the fields today's call sites touch)
// so the toolkit stays decoupled from the hub's generated types.

/** A persona-action approval row (the human-in-the-loop decision queue). */
export interface ApprovalRow {
  id: string;
  personaId: string;
  subjectKind: "self" | "user" | "team" | "org";
  /** null for self/eco-scoped subjects */
  subjectId?: string | null;
  subjectEco: string;
  /** curated tool name, or the gateway tool 'adh_request' */
  toolName: string;
  /** the frozen invocation payload */
  args: Record<string, unknown>;
  status: "pending" | "approved" | "rejected";
  requestedBy?: string | null;
  /** the human who decided (null until then) */
  decidedBy?: string | null;
  decidedAt?: string | null;
  /** the outcome once an approved action runs (null until then) */
  result?: Record<string, unknown> | null;
  createdAt: string;
}

export interface ApprovalListRow {
  approvals: ApprovalRow[];
}

/** A grantable tool + its grant/autonomy state for one persona. */
export interface ToolCatalogItemRow {
  toolName: string;
  /** null for curated internal tools; else the source id (e.g. "web", "mcp.<server>") */
  source: string | null;
  /** human-readable label from the tool catalog; falls back to `toolName` when uncataloged */
  displayName: string;
  /** human-readable description from the tool catalog; '' when uncataloged */
  description: string;
  readOnly: boolean;
  /** true iff this persona currently holds the tool */
  granted: boolean;
  /** true = this grant skips the approval gate (except acting as self, which always
   *  gates); false when not granted */
  autonomous: boolean;
}

export interface ToolCatalogListRow {
  tools: ToolCatalogItemRow[];
}

/** A tool grant, as returned by the autonomy PATCH. */
export interface ToolGrantRow {
  toolName: string;
  /** true = this grant skips the approval gate (except acting as self, which always gates) */
  autonomous: boolean;
  createdAt: string;
}

export interface SetAutonomyBody {
  autonomous: boolean;
}

/** The subject kinds a persona may act for (always includes seeded 'self'). */
export interface MayActRow {
  kinds: ("self" | "user" | "team" | "org")[];
}

export interface MayActGrantBody {
  kind: "user" | "team" | "org";
}

/** A persona the caller may configure per-tool consent for (holds `may_act 'user'`). */
export interface UserActablePersonaRow {
  id: string;
  slug: string;
  name: string;
}

export interface UserActableListRow {
  personas: UserActablePersonaRow[];
}

/** A persona's owner-granted tool + the caller's own per-tool allow toggle. */
export interface UserToolRow {
  toolName: string;
  /** null for curated internal tools; else the source id (e.g. "web", "mcp.<server>") */
  source: string | null;
  /** human-readable label from the tool catalog; falls back to `toolName` when uncataloged */
  displayName: string;
  /** human-readable description from the tool catalog; '' when uncataloged */
  description: string;
  readOnly: boolean;
  /** true iff the calling user has allowed the persona to invoke this tool for them */
  allowed: boolean;
}

export interface UserToolListRow {
  tools: UserToolRow[];
}

export interface SetAllowedBody {
  allowed: string[];
}

/* ── Me / public profile / persona CRUD (GET rows + request bodies) ──────── */

/** The authenticated user record, exactly as `GET /auth/me` returns it (and
 *  `PATCH /auth/me` echoes back) — the customer.customers identity + effective
 *  capabilities. There is no separate `githubLogin`: GitHub is just one auth
 *  method behind the shared OAuth flow, not a field on the profile. */
export interface MeRow {
  id: string;
  email: string;
  name: string;
  avatarUrl: string;
  slug: string | null;
  /** Whether the public profile card is visible at /public/users/:slug */
  publicProfileEnabled: boolean;
  capabilities: string[];
}

/** `PATCH /auth/me` body — update the caller's own profile (name, slug, avatar,
 *  public-profile toggle). */
export interface MePatchBody {
  name?: string;
  slug?: string;
  avatarUrl?: string;
  publicProfileEnabled?: boolean;
}

/** One social link on a public profile card. */
export interface PublicSocialLinkRow {
  platform: string;
  url: string;
  handle: string;
}

/** One mailing address on a public profile card. */
export interface PublicAddressRow {
  label: string;
  line1: string;
  line2: string;
  city: string;
  region: string;
  postalCode: string;
  country: string;
}

/** The owner byline embedded in a public persona (or persona summary) — null
 *  when the owning user has no public profile. */
export interface PublicOwnerRow {
  slug: string;
  displayName: string | null;
  avatarUrl: string | null;
}

/** A public persona as it appears in a public profile card's `personas` list —
 *  a narrower projection than {@link PublicPersonaRow} (no prompt/voice/etc.). */
export interface PublicPersonaSummaryRow {
  slug: string;
  name: string;
  description: string | null;
  visibility: "public" | "hub";
  createdAt: string;
  owner: PublicOwnerRow | null;
}

/** Backend row for `GET /public/users/{slug}` — a public profile card + its
 *  public personas summary list. */
export interface PublicUserRow {
  slug: string;
  displayName: string | null;
  avatarUrl: string | null;
  createdAt: string;
  socialLinks: PublicSocialLinkRow[];
  emails: string[];
  phones: string[];
  addresses: PublicAddressRow[];
  personas: PublicPersonaSummaryRow[];
}

/** A base_url placeholder the connect UI prompts for and substitutes (e.g.
 *  `{account_id}`, `{region}`, `{resource}`). */
export interface ConnectionSpecUrlVar {
  name: string;
  label?: string;
  example?: string;
  secret?: boolean;
}

/** A header the connect UI prompts a per-connection value for and writes into
 *  `extraHeaders` (e.g. Portkey's `x-portkey-provider`). The `extraHeaders`
 *  counterpart of {@link ConnectionSpecUrlVar}: the header NAME is fixed by the
 *  template, only its value is entered per connection. */
export interface ConnectionSpecHeaderVar {
  header: string;
  label?: string;
  example?: string;
  secret?: boolean;
}

/** How the API credential is attached. `bearer`/`header` are enforced by the
 *  backend OpenAI-compat client; `sigv4`/`oauth2` are reserved (stored, not yet
 *  enforced). Mirrors the backend `llm/connectionSpec.ts` union. */
export type ConnectionSpecAuth =
  | { type: "bearer" }
  | { type: "header"; header: string; scheme: "bearer" | "raw" }
  | { type: "sigv4"; region?: string }
  | { type: "oauth2"; tokenUrl?: string };

/** Transport/auth spec for an OpenAI-wire provider — orthogonal to providerKind
 *  (the wire format). Carries URL placeholders + credential placement so Azure /
 *  cloud gateways ride the same client. Null = plain `Authorization: Bearer`. */
export interface ConnectionSpec {
  specVersion: 1;
  urlVars?: ConnectionSpecUrlVar[];
  headerVars?: ConnectionSpecHeaderVar[];
  auth?: ConnectionSpecAuth;
  defaultQuery?: Record<string, string>;
  extraHeaders?: Record<string, string>;
}

/** Sync-fed model row on a provider template (mirrors ProviderTemplateModel). */
export interface TemplateModelRow {
  id: string;
  name: string;
  description: string | null;
  metadata: Record<string, unknown> | null;
  source: "curated" | "synced";
  lastSyncedAt: string | null;
  createdAt: string;
}

/** Set ⇒ informational template: no first-party API; connect via the named templates. */
export interface TemplateAvailableVia {
  note: string;
  templates: string[];
}

/** Backend DTO for `GET /persona/provider-templates` (one `items[]` entry) — the GLOBAL
 *  provider-catalog row from `persona.service_templates`, as the hand-written route serves
 *  it: `connectionSpec.extraHeaders` REDACTED, operator-only `syncKeys` stripped, and the
 *  template's synced models nested. This route is the SOLE read surface for the table; the
 *  raw generic-CRUD `/persona/service-templates` endpoint was removed because it served the
 *  rows with `extraHeaders` unredacted. */
export interface ServiceTemplateRow {
  id: string;
  providerKind: string;
  name: string;
  baseUrl: string;
  documentationUrl: string | null;
  statusUrl: string | null;
  connectionSpec: ConnectionSpec | null;
  /** Set ⇒ informational template: no first-party API of its own, so `connect` must
   *  be hidden — a would-be user reaches this provider through the named gateway
   *  templates instead. Null/omitted ⇒ a normal, directly-connectable template.
   *  (Older backends omit the field entirely.) */
  availableVia?: TemplateAvailableVia | null;
  /** The provider's supported modalities (e.g. `["chat"]`, `["image"]`,
   *  `["audio"]`). Null/omitted ⇒ chat. Older backends omit it. (`syncKeys` is never
   *  surfaced — the provider-templates payload strips it entirely.) */
  modalities?: string[] | null;
  /** The template's catalog models, name-ordered (curated + synced). */
  models: TemplateModelRow[];
  createdAt: string;
  updatedAt: string;
}

/** Backend row for `GET /persona/services` (and a single service, redacted —
 *  never the raw apiKey). `models` is a jsonb column the spec types loosely
 *  (string | object per entry); the personas client's `ModelInfo` recovers the
 *  structured shape client-side. */
export interface ServiceRow {
  id: string;
  templateId?: string | null;
  providerKind: string;
  name: string;
  baseUrl: string;
  hasApiKey: boolean;
  connectionSpec?: ConnectionSpec | null;
  connectStatus: string;
  connectError?: string | null;
  lastConnectedAt?: string | null;
  documentationUrl?: string | null;
  statusUrl?: string | null;
  models: (string | Record<string, unknown>)[];
  modelsFetchedAt?: string | null;
}

import type { ChatStatusConfig } from "./chat-status";

/** Mirrors backend/src/adh/src/llm/canned/config.ts — the toolkit deliberately does not
 *  import backend or generated types, so this is a hand-kept, field-for-field copy. */
export interface CannedPacing {
  thinkMinMs: number; thinkJitterMs: number; tokenMinMs: number; tokenJitterMs: number;
  reveal: "word" | "char";
}
export interface CannedSeeded { match: string[]; reply: string }
export interface CannedScript {
  intro: string[]; seeded: CannedSeeded[]; fallbacks: string[];
  onExhausted: "reshuffle" | "hold-last";
}
/**
 * The ink engine's slice of the demo config. Absent or blank `source` ⇒ this persona demos on
 * the legacy keyword `script` instead; the two engines share one `enabled` flag.
 *
 * `signInLine` is what the persona says when a visitor goes off-script and there is no real
 * model to escalate to — an anonymous visitor, or one on a persona with no model. It is the
 * line most visitors will see, because a profile visit is usually anonymous.
 */
export interface CannedInk { source: string; signInLine: string }
export interface CannedChatConfig {
  enabled: boolean;
  pacing: CannedPacing;
  script: CannedScript;
  /** Optional: rows written before ink existed have no such key. */
  ink?: CannedInk | null;
}

/** Backend row for `GET /persona/personas` (and a single persona). */
export interface PersonaRow {
  id: string;
  userId: string | null;
  ownerKind: string;
  ownerId: string;
  slug: string;
  name: string;
  description: string | null;
  visibility: string;
  model: string;
  serviceId: string | null;
  appId: string | null;
  avatarAttachmentId: string | null;
  modelPrompt: string;
  voice: string | null;
  character: string | null;
  examples: string | null;
  createdAt: string;
  updatedAt: string;
  ownedEcosystemId?: string | null;
  /** DERIVED (crud/read-decorators.ts): the OWNER's realm, where this persona's special-interest
   *  corpus buckets live. NOT the same ecosystem as `ownedEcosystemId` — the Knowledge/Memory
   *  panes scope to that one, the interest-documents pane scopes to this one. */
  corpusEcosystemId?: string | null;
  cannedChat?: CannedChatConfig | null;
  chatStatus?: ChatStatusConfig | null;
}

/** Backend row for `GET /public/personas/{slug}` and `GET
 *  /public/users/{ownerSlug}/personas/{personaSlug}` — same public-persona shape
 *  either route. */
export interface PublicPersonaRow {
  slug: string;
  name: string;
  description: string | null;
  modelPrompt: string;
  provider: string | null;
  model: string;
  avatarUrl: string | null;
  voice: string | null;
  character: string | null;
  examples: string | null;
  visibility: "public" | "hub";
  createdAt: string;
  owner: PublicOwnerRow | null;
  demoEnabled: boolean;
  chatStatus?: ChatStatusConfig | null;
}

/** A persona's declared special interest (`persona.special_interests`). Three levels, narrowing:
 *  general → topical → specific (Science Fiction → Space Opera → Battlestar Galactica). `stances`
 *  is the AUTHOR's opinions, rendered verbatim into the persona's system prompt. */
export interface SpecialInterestRow {
  id: string;
  personaId: string;
  slug: string;
  general: string;
  topical: string | null;
  specific: string | null;
  stances: string | null;
  position: number;
  /** Server-assigned on create; the bucket that holds this interest's research corpus. */
  bucketId: string | null;
  /** DERIVED: the row-mode `content.markdown` bucket-type inside `bucketId`. */
  bucketTypeId?: string | null;
  isDeleted: boolean;
  createdAt: string;
  updatedAt: string;
}

/* ── /v1 wire shapes (snake_case; read only by ./mappers) ───────────────────── */

/** `connection_spec` on the wire: declared keys are snake_case, the two string maps
 *  (`default_query`, `extra_headers`) pass through unchanged. */
export interface V1ConnectionSpec {
  spec_version: 1;
  url_vars?: ConnectionSpecUrlVar[];
  header_vars?: ConnectionSpecHeaderVar[];
  auth?: {
    type: "bearer" | "header" | "sigv4" | "oauth2";
    header?: string;
    scheme?: "bearer" | "raw";
    region?: string;
    token_url?: string;
  };
  default_query?: Record<string, string>;
  extra_headers?: Record<string, string>;
}

/** `GET /v1/account` (and the `POST /v1/account` echo). */
export interface V1Account {
  object?: "account";
  id: string;
  email: string;
  name: string;
  avatar_url: string;
  slug: string | null;
  public_profile_enabled: boolean;
  capabilities: string[];
}

/** `POST /v1/account` profile body. */
export interface V1AccountPatchBody {
  name?: string;
  slug?: string;
  avatar_url?: string;
  public_profile_enabled?: boolean;
}

/** `GET /v1/handles/{handle}`. */
export interface V1Handle {
  object?: "handle";
  available: boolean;
  reason?: "format" | "taken";
}

export interface V1PublicOwner {
  slug: string;
  display_name: string | null;
  avatar_url: string | null;
}

/** `GET /v1/users?handle=` — one public profile card. */
export interface V1PublicUser {
  object?: "user";
  slug: string;
  display_name: string | null;
  avatar_url: string | null;
  created: number;
  social_links: PublicSocialLinkRow[];
  emails: string[];
  phones: string[];
  addresses: {
    label: string;
    line1: string;
    line2: string;
    city: string;
    region: string;
    postal_code: string;
    country: string;
  }[];
  personas: {
    slug: string;
    name: string;
    description: string | null;
    visibility: "public" | "hub";
    created: number;
    owner: V1PublicOwner | null;
  }[];
}

/** `GET /v1/personas?slug=` / `?owner=&slug=` — one public persona. */
export interface V1PublicPersona {
  object?: "persona";
  slug: string;
  name: string;
  description: string | null;
  model_prompt: string;
  provider: string | null;
  model: string;
  avatar_url: string | null;
  voice: string | null;
  character: string | null;
  examples: string | null;
  visibility: "public" | "hub";
  created: number;
  owner: V1PublicOwner | null;
  demo_enabled: boolean;
  chat_status?: ChatStatusConfig | null;
}

/** `/v1/personas` row. `canned_chat` / `chat_status` are JSON columns: their inner keys
 *  pass through the gateway unchanged (camelCase). */
export interface V1Persona {
  object?: "persona";
  id: string;
  user_id: string | null;
  owner_kind: string;
  owner_id: string;
  slug: string;
  name: string;
  description: string | null;
  visibility: string;
  model: string;
  service_id: string | null;
  app_id: string | null;
  avatar_attachment_id: string | null;
  model_prompt: string;
  voice: string | null;
  character: string | null;
  examples: string | null;
  canned_chat?: CannedChatConfig | null;
  chat_status?: ChatStatusConfig | null;
  created: number;
  updated: number;
  owned_ecosystem_id?: string | null;
  corpus_ecosystem_id?: string | null;
}

/** `POST /v1/personas` / `POST /v1/personas/{id}` body. */
export interface V1PersonaBody {
  slug: string;
  name: string;
  description?: string | null;
  visibility?: string;
  model?: string | null;
  service_id?: string | null;
  avatar_attachment_id?: string | null;
  model_prompt: string;
  voice?: string | null;
  character?: string | null;
  examples?: string | null;
  canned_chat?: CannedChatConfig | null;
  chat_status?: ChatStatusConfig | null;
}

export interface V1TemplateModel {
  id: string;
  name: string;
  description: string | null;
  metadata: Record<string, unknown> | null;
  source: "curated" | "synced";
  last_synced_at: string | null;
  created: number;
}

/** `GET /v1/provider_templates` row. */
export interface V1ProviderTemplate {
  object?: "provider_template";
  id: string;
  provider_kind: string;
  name: string;
  base_url: string;
  documentation_url: string | null;
  status_url: string | null;
  connection_spec: V1ConnectionSpec | null;
  available_via?: TemplateAvailableVia | null;
  modalities?: string[] | null;
  models: V1TemplateModel[];
  created: number;
  updated: number;
}

/** `/v1/ai_services` row (also what `connect` and `refresh_models` answer). */
export interface V1AiService {
  object?: "ai_service" | "refresh_model";
  id: string;
  template_id?: string | null;
  provider_kind: string;
  name: string;
  base_url: string;
  has_api_key: boolean;
  connection_spec?: V1ConnectionSpec | null;
  connect_status: string;
  connect_error?: string | null;
  last_connected_at?: string | null;
  documentation_url?: string | null;
  status_url?: string | null;
  models: (string | Record<string, unknown>)[];
  models_fetched_at?: string | null;
}

/** `POST /v1/ai_services` body. */
export interface V1AiServiceCreateBody {
  template_id?: string;
  name: string;
  provider_kind: string;
  base_url: string;
  api_key?: string;
  connection_spec?: V1ConnectionSpec | null;
}

/** `POST /v1/ai_services/{id}` body. */
export interface V1AiServicePatchBody {
  name?: string;
  base_url?: string;
  api_key?: string;
  connection_spec?: V1ConnectionSpec | null;
}

/** `/v1/special_interests` row. */
export interface V1SpecialInterest {
  object?: "special_interest";
  id: string;
  persona_id: string;
  slug: string;
  general: string;
  topical: string | null;
  specific: string | null;
  stances: string | null;
  position: number;
  bucket_id: string | null;
  bucket_type_id?: string | null;
  is_deleted: boolean;
  created: number;
  updated: number;
}

/** `/v1/processing/persona_approvals` row. */
export interface V1PersonaApproval {
  object?: "processing.persona_approval";
  id: string;
  persona_id: string;
  subject_kind: "self" | "user" | "team" | "org";
  subject_id?: string | null;
  subject_eco: string;
  tool_name: string;
  args: Record<string, unknown>;
  status: "pending" | "approved" | "rejected";
  requested_by?: string | null;
  decided_by?: string | null;
  decided_at?: string | null;
  result?: Record<string, unknown> | null;
  created: number;
}

/** `/v1/personas/{id}/tools` row. */
export interface V1PersonaTool {
  object?: "tool";
  tool_name: string;
  source: string | null;
  display_name: string;
  description: string;
  read_only: boolean;
  granted: boolean;
  autonomous: boolean;
}

/** `POST /v1/personas/{id}/tools/{tool_name}` — the autonomy update's echo. */
export interface V1PersonaToolGrant {
  object?: "tool";
  tool_name: string;
  autonomous: boolean;
  created: number;
}

/** `/v1/personas/{id}/user_tools` row. */
export interface V1UserTool {
  object?: "user_tool";
  tool_name: string;
  source: string | null;
  display_name: string;
  description: string;
  read_only: boolean;
  allowed: boolean;
}

/** `POST /v1/personas/{id}/user_tools` answer. */
export interface V1UserToolsSet {
  object?: "user_tool";
  tools: V1UserTool[];
}

/** `/v1/personas/{id}/actors` answer. */
export interface V1Actors {
  object?: "actor";
  kinds: ("self" | "user" | "team" | "org")[];
}

/** `POST /v1/personas/preview` answer. */
export interface V1PersonaPreview {
  object?: "persona";
  text: string | null;
  on_script: boolean;
  sign_in_line: boolean;
  budget_exhausted: boolean;
  choices: { text: string; keywords: string[]; off_script: boolean }[];
  diagnostics: { severity: "error" | "warning" | "info"; line: number | null; message: string }[];
  tag_placement_hint: string;
}
