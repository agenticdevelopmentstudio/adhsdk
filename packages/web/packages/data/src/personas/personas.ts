// Persona/services/me API client — the /v1 account, handle, user, provider-template,
// ai-service and persona resources.
//
// Routes: /api/v1/account (get/post), /api/v1/handles/{handle},
//         /api/v1/users?handle=, /api/v1/personas?slug= and ?owner=&slug= (public lookups),
//         /api/v1/provider_templates,
//         /api/v1/ai_services (list/create), /api/v1/ai_services/{id}
//         (post/delete/connect/refresh_models), /api/v1/models?service=,
//         /api/v1/personas (list/create), /api/v1/personas/{id} (post/delete).
//
// Every method returns the camelCase DOMAIN shapes declared below; `./mappers` is the one place
// that reads the snake_case wire.
import { authedJson, authedRequest, listAllV1, withV1Query } from "../http";
import { enc } from "../client-helpers";
import {
  connectionSpecBodyToWire,
  meFromWire,
  personaFromWire,
  providerTemplateFromWire,
  publicPersonaFromWire,
  publicUserFromWire,
  connectionSpecFromWire,
} from "./mappers";
import type {
  MeRow,
  MePatchBody,
  PublicUserRow,
  ServiceTemplateRow,
  ServiceRow,
  PersonaRow,
  PublicPersonaRow,
  ConnectionSpec,
  CannedChatConfig,
  V1Account,
  V1AccountPatchBody,
  V1AiService,
  V1AiServiceCreateBody,
  V1AiServicePatchBody,
  V1Handle,
  V1Persona,
  V1PersonaBody,
  V1ProviderTemplate,
  V1PublicPersona,
  V1PublicUser,
} from "./wire";
import type { ChatStatusConfig } from "./chat-status";

const V1 = "/api/v1";

// `/v1/account` answers the account object bare (with `object: 'account'`), for GET and for the
// POST update's echo alike.
function meRequest(): Promise<MeResponse> {
  return authedJson<V1Account>(`${V1}/account`).then(meFromWire);
}

function patchMe(body: MePatchBody): Promise<MeResponse> {
  const wire: V1AccountPatchBody = {
    name: body.name,
    slug: body.slug,
    avatar_url: body.avatarUrl,
    public_profile_enabled: body.publicProfileEnabled,
  };
  return authedJson<V1Account>(`${V1}/account`, {
    method: "POST",
    body: JSON.stringify(wire),
  }).then(meFromWire);
}

export type SlugAvailability =
  | { available: true }
  | { available: false; reason: "format" | "reserved" | "taken" };

async function slugAvailable(slug: string): Promise<SlugAvailability> {
  const r = await authedJson<V1Handle>(`${V1}/handles/${enc(slug)}`);
  return r.available ? { available: true } : { available: false, reason: r.reason ?? "taken" };
}

/** The service row as the registry UI consumes it: `models` is a jsonb column whose entries
 *  are plain model objects (their keys pass through the gateway untouched) — a bare string
 *  entry is the model id alone. */
function serviceFromWire(r: V1AiService): UserService {
  const out: UserService = {
    id: r.id,
    providerKind: r.provider_kind,
    name: r.name,
    baseUrl: r.base_url,
    hasApiKey: r.has_api_key,
    connectStatus: r.connect_status,
    models: (r.models ?? []).map((m): ModelInfo => (typeof m === "string" ? { id: m } : (m as ModelInfo))),
  };
  if (r.template_id !== undefined) out.templateId = r.template_id;
  if (r.connection_spec !== undefined) {
    out.connectionSpec = r.connection_spec ? connectionSpecFromWire(r.connection_spec) : null;
  }
  if (r.connect_error !== undefined) out.connectError = r.connect_error;
  if (r.last_connected_at !== undefined) out.lastConnectedAt = r.last_connected_at;
  if (r.documentation_url !== undefined) out.documentationUrl = r.documentation_url;
  if (r.status_url !== undefined) out.statusUrl = r.status_url;
  if (r.models_fetched_at !== undefined) out.modelsFetchedAt = r.models_fetched_at;
  return out;
}

function personaBodyToWire(body: PersonaBody): V1PersonaBody {
  return {
    slug: body.slug,
    name: body.name,
    description: body.description,
    model_prompt: body.modelPrompt,
    voice: body.voice,
    character: body.character,
    examples: body.examples,
    avatar_attachment_id: body.avatarAttachmentId,
    service_id: body.serviceId,
    model: body.model,
    visibility: body.visibility,
    canned_chat: body.cannedChat,
    chat_status: body.chatStatus,
  };
}

/** `?workspace=<slug>` scoping, merged onto a /v1 url. */
function scoped(url: string, opts?: { workspace?: string }): string {
  return withV1Query(url, { workspace: opts?.workspace });
}

export const api = {
  me: meRequest,
  patchMe,
  slugAvailable,
  publicUser: (slug: string) =>
    authedJson<V1PublicUser>(withV1Query(`${V1}/users`, { handle: slug })).then(publicUserFromWire),
  publicPersonaByOwner: (ownerSlug: string, personaSlug: string) =>
    authedJson<V1PublicPersona>(
      withV1Query(`${V1}/personas`, { owner: ownerSlug, slug: personaSlug }),
    ).then(publicPersonaFromWire),
  // Sign-out is the shared AuthProvider's `logout()` (revoke + clear the local
  // Bearer tokens), not an api.ts call — see src/App.tsx.
  // Provider templates are the GLOBAL provider catalog: `connection_spec.extra_headers` REDACTED
  // and operator-only `syncKeys` stripped. Every page is read (the catalog is well under one).
  templates: () =>
    listAllV1<V1ProviderTemplate>(`${V1}/provider_templates`).then((rows) =>
      rows.map(providerTemplateFromWire),
    ),
  services: {
    list: () =>
      listAllV1<V1AiService>(`${V1}/ai_services`).then((rows) => rows.map(serviceFromWire)),
    create: (body: CreateServiceBody) => {
      const wire: V1AiServiceCreateBody = {
        template_id: body.templateId,
        name: body.name,
        provider_kind: body.providerKind,
        base_url: body.baseUrl,
        api_key: body.apiKey,
        connection_spec: connectionSpecBodyToWire(body.connectionSpec),
      };
      return authedJson<V1AiService>(`${V1}/ai_services`, {
        method: "POST",
        body: JSON.stringify(wire),
      }).then(serviceFromWire);
    },
    patch: (id: string, body: PatchServiceBody) => {
      const wire: V1AiServicePatchBody = {
        name: body.name,
        base_url: body.baseUrl,
        api_key: body.apiKey,
        connection_spec: connectionSpecBodyToWire(body.connectionSpec),
      };
      return authedJson<V1AiService>(`${V1}/ai_services/${enc(id)}`, {
        method: "POST",
        body: JSON.stringify(wire),
      }).then(serviceFromWire);
    },
    delete: (id: string) =>
      authedRequest(`${V1}/ai_services/${enc(id)}`, { method: "DELETE" }),
    connect: (id: string) =>
      authedJson<V1AiService>(`${V1}/ai_services/${enc(id)}/connect`, { method: "POST" }).then(
        serviceFromWire,
      ),
    // The connection's live model list. The gateway forwards the provider's model objects with
    // their own keys intact (only `object: 'model'` is added), so each is read back as ModelInfo.
    models: (id: string) =>
      listAllV1<ModelInfo & { object?: string }>(withV1Query(`${V1}/models`, { service: id })).then(
        (rows) =>
          rows.map((row) => {
            const { object: _object, ...model } = row;
            return model;
          }),
      ),
    refreshModels: (id: string) =>
      authedJson<V1AiService>(`${V1}/ai_services/${enc(id)}/refresh_models`, {
        method: "POST",
      }).then(serviceFromWire),
  },
  personas: {
    // `workspace` scopes EVERY op to the WORKSPACE'S owning principal (backend
    // `?workspace=<slug>`): list returns only personas that principal OWNS (owner_kind +
    // owner_id — never the caller-reachable set), create stamps that principal as the
    // owner (so an org workspace's new persona is org-owned), and item update/delete
    // swap the non-creator pin for the same ownership scope — so any org member can
    // edit rows other members created for the org. Omit for the caller's own
    // creator-scoped rows (the pre-workspace behavior).
    list: (opts?: { workspace?: string }) =>
      listAllV1<V1Persona>(scoped(`${V1}/personas`, opts)).then((rows) =>
        rows.map(personaFromWire),
      ),
    create: (body: PersonaBody, opts?: { workspace?: string }) =>
      authedJson<V1Persona>(scoped(`${V1}/personas`, opts), {
        method: "POST",
        body: JSON.stringify(personaBodyToWire(body)),
      }).then(personaFromWire),
    // Persona rdids are DERIVED — `persona.<owner-address>.<slug>`, where the owner segment is
    // itself an rdid (`org.<slug>` or `user.<eco-path>.<slug>`) and NOT a bare workspace slug; the
    // slug is the only user-editable segment (the leaf). The address is derived from the stored
    // slug, and this body always carries `slug`, so the update IS the rename: CRUD sees the address
    // move and cascades the new address onto the handle and every descendant. Mirrors
    // ecosystemsApi.update(), including what was removed from it — the follow-up
    // `identifiersApi.rename` was a SECOND rename of a handle the cascade had already moved, from
    // an old rdid that is now a superseded alias onto a new one the row itself already holds, and
    // that target is taken (23505 -> 409). It reported a rename that had in fact succeeded as a
    // failure. The 404-recovery branch went with it: it existed because two calls could half-land,
    // and one call has no such window.
    update: (id: string, body: PersonaBody, opts?: { workspace?: string }): Promise<Persona> =>
      // The echoed row carries the address the server DERIVED, which is the authority — callers
      // (PersonasSection) still detect the rename via the id change, now from the server's answer
      // rather than a client-side guess at what it would be.
      authedJson<V1Persona>(scoped(`${V1}/personas/${enc(id)}`, opts), {
        method: "POST",
        body: JSON.stringify(personaBodyToWire(body)),
      }).then(personaFromWire),
    delete: (id: string, opts?: { workspace?: string }) =>
      authedRequest(scoped(`${V1}/personas/${enc(id)}`, opts), { method: "DELETE" }),
    // Owner-scoped slug lookup. `GET /v1/personas?slug=` is the PUBLIC lookup (it answers one
    // public-card object, not the owner's row), so the owner's persona is found in the caller's
    // own list instead. A miss is a 404, mirroring the old endpoint.
    bySlugAsOwner: async (slug: string) => {
      const rows = await listAllV1<V1Persona>(`${V1}/personas`);
      const row = rows.find((r) => r.slug === slug);
      if (!row) throw new Error("404 Not Found");
      return personaFromWire(row);
    },
  },
  publicPersona: (slug: string) =>
    authedJson<V1PublicPersona>(withV1Query(`${V1}/personas`, { slug })).then(
      publicPersonaFromWire,
    ),
};

// The authenticated developer, as the domain sees it (mapped from `GET /v1/account`): the
// customer.customers identity + effective capabilities. There is no separate `githubLogin`
// anymore — GitHub is just one auth method behind the shared OAuth flow, not a field on the
// profile.
export type MeResponse = MeRow;
export type PublicUser = PublicUserRow;
export type Template = ServiceTemplateRow;
export type Modality = "text" | "image" | "audio" | "video" | "embedding";
export type ModelInfo = {
  id: string;
  displayName?: string;
  family?: string;
  description?: string;
  contextWindow?: number;
  maxOutputTokens?: number;
  inputUsdPerMTokens?: number;
  outputUsdPerMTokens?: number;
  inputModalities?: Modality[];
  outputModalities?: Modality[];
  supportsTools?: boolean;
  supportsVision?: boolean;
  supportsThinking?: boolean;
};
// Spec-typed, but keep the rich `models` typing: the backend column is jsonb so the
// spec documents PersonaServiceModel loosely (string | object); the registry UI needs
// the structured ModelInfo, so override just that field.
export type UserService = Omit<ServiceRow, "models"> & { models: ModelInfo[] };
// Re-exported so connect-form UIs can read a template's transport/auth spec
// (url-var placeholders, auth kind) without reaching into ./wire directly.
export type {
  ConnectionSpec,
  ConnectionSpecAuth,
  ConnectionSpecUrlVar,
  ConnectionSpecHeaderVar,
} from "./wire";
// Re-exported so the editor's demo facet can type its draft state without reaching
// into ./wire directly.
export type {
  CannedChatConfig,
  CannedInk,
  CannedPacing,
  CannedScript,
  CannedSeeded,
} from "./wire";
export {
  CHAT_STATUS_DEFAULT,
  CHAT_STATUS_KINDS,
  CHAT_STATUS_WORD_PRESETS,
  CHAT_STATUS_ICON_PRESETS,
  chatStatusBlank,
  parseChatStatus,
  parseChatStatusDraft,
  resolveChatStatus,
} from "./chat-status";
export type {
  ChatStatusConfig,
  ChatStatusKind,
  ResolvedChatStatus,
  StatusIconSet,
  StatusTint,
  StatusWordPair,
} from "./chat-status";
export type CreateServiceBody = {
  templateId?: string;
  name: string;
  providerKind: UserService["providerKind"];
  baseUrl: string;
  apiKey?: string;
  // Usually omitted: when templateId is set the backend copies the template's
  // spec onto the connection. Supply it only to override or for a template-less
  // connection. The UI has already substituted url vars into baseUrl.
  connectionSpec?: ConnectionSpec | null;
};
export type PatchServiceBody = {
  name?: string;
  baseUrl?: string;
  apiKey?: string;
  connectionSpec?: ConnectionSpec | null;
};
// The persona row as the domain sees it (mapped from `/v1/personas`) + the
// display-only `serviceName` join (no DB column). A backend column change now fails
// registry's tsc instead of at runtime.
export type Persona = PersonaRow & {
  serviceName?: string | null;
};
export type PersonaVisibility = "public" | "hub" | "private";
// The editable draft PersonaEditor works with: user-settable fields only — no
// server-assigned userId/appId, `model` nullable while unset, and the
// precise `visibility` union (the spec response types it as a plain string).
export type PersonaDraft = {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  modelPrompt: string;
  voice: string | null;
  character: string | null;
  examples: string | null;
  avatarAttachmentId: string | null;
  serviceId: string | null;
  serviceName?: string | null;
  model: string | null;
  visibility: PersonaVisibility;
  /** Demo-mode script. Owner-only — absent from every public payload. */
  cannedChat: CannedChatConfig | null;
  chatStatus: ChatStatusConfig | null;
};
// Map a loaded persona (response) into an editable draft, narrowing the spec's
// loose `visibility: string` back to the UI union.
export function toPersonaDraft(p: Persona): PersonaDraft {
  const visibility: PersonaVisibility =
    p.visibility === "public" || p.visibility === "hub" ? p.visibility : "private";
  return {
    id: p.id,
    slug: p.slug,
    name: p.name,
    description: p.description,
    modelPrompt: p.modelPrompt,
    voice: p.voice,
    character: p.character,
    examples: p.examples,
    avatarAttachmentId: p.avatarAttachmentId ?? null,
    serviceId: p.serviceId,
    serviceName: p.serviceName ?? null,
    model: p.model,
    visibility,
    cannedChat: p.cannedChat ?? null,
    chatStatus: p.chatStatus ?? null,
  };
}
export type PublicPersona = PublicPersonaRow;
export type PersonaBody = {
  slug: string;
  name: string;
  description?: string;
  modelPrompt: string;
  voice?: string;
  character?: string;
  examples?: string;
  avatarAttachmentId?: string | null;
  serviceId?: string | null;
  model?: string | null;
  visibility?: PersonaVisibility;
  cannedChat?: CannedChatConfig | null;
  chatStatus?: ChatStatusConfig | null;
};
