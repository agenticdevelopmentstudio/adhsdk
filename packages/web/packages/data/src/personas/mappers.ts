// /v1 wire <-> domain mappers for the personas domain. Every mapper is written field by field:
// the JSON bags (`canned_chat`, `chat_status`, `args`, `result`, `metadata`, `default_query`,
// `extra_headers`) keep their exact keys, so no generic snake->camel converter is used here.
import { unixToIso } from "../http";
import type {
  ApprovalRow,
  ConnectionSpec,
  MeRow,
  PersonaRow,
  PublicPersonaRow,
  PublicUserRow,
  ServiceTemplateRow,
  SpecialInterestRow,
  ToolCatalogItemRow,
  ToolGrantRow,
  UserToolRow,
  V1Account,
  V1ConnectionSpec,
  V1Persona,
  V1PersonaApproval,
  V1PersonaTool,
  V1PersonaToolGrant,
  V1ProviderTemplate,
  V1PublicOwner,
  V1PublicPersona,
  V1PublicUser,
  V1SpecialInterest,
  V1UserTool,
  PublicOwnerRow,
} from "./wire";

export function connectionSpecFromWire(spec: V1ConnectionSpec): ConnectionSpec {
  const out: ConnectionSpec = { specVersion: spec.spec_version };
  if (spec.url_vars) out.urlVars = spec.url_vars;
  if (spec.header_vars) out.headerVars = spec.header_vars;
  if (spec.auth) {
    const { type, header, scheme, region, token_url } = spec.auth;
    if (type === "bearer") out.auth = { type };
    else if (type === "header") {
      out.auth = { type, header: header ?? "", scheme: scheme ?? "bearer" };
    } else if (type === "sigv4") out.auth = region === undefined ? { type } : { type, region };
    else out.auth = token_url === undefined ? { type } : { type, tokenUrl: token_url };
  }
  if (spec.default_query) out.defaultQuery = spec.default_query;
  if (spec.extra_headers) out.extraHeaders = spec.extra_headers;
  return out;
}

export function connectionSpecToWire(spec: ConnectionSpec): V1ConnectionSpec {
  const out: V1ConnectionSpec = { spec_version: spec.specVersion };
  if (spec.urlVars) out.url_vars = spec.urlVars;
  if (spec.headerVars) out.header_vars = spec.headerVars;
  if (spec.auth) {
    const a = spec.auth;
    if (a.type === "header") out.auth = { type: a.type, header: a.header, scheme: a.scheme };
    else if (a.type === "sigv4") out.auth = a.region === undefined ? { type: a.type } : { type: a.type, region: a.region };
    else if (a.type === "oauth2") out.auth = a.tokenUrl === undefined ? { type: a.type } : { type: a.type, token_url: a.tokenUrl };
    else out.auth = { type: a.type };
  }
  if (spec.defaultQuery) out.default_query = spec.defaultQuery;
  if (spec.extraHeaders) out.extra_headers = spec.extraHeaders;
  return out;
}

/** `null` stays `null` (clears the spec), `undefined` stays absent. */
export function connectionSpecBodyToWire(
  spec: ConnectionSpec | null | undefined,
): V1ConnectionSpec | null | undefined {
  return spec ? connectionSpecToWire(spec) : spec;
}

export function meFromWire(a: V1Account): MeRow {
  return {
    id: a.id,
    email: a.email,
    name: a.name,
    avatarUrl: a.avatar_url,
    slug: a.slug,
    publicProfileEnabled: a.public_profile_enabled,
    capabilities: a.capabilities,
  };
}

function ownerFromWire(o: V1PublicOwner | null): PublicOwnerRow | null {
  return o ? { slug: o.slug, displayName: o.display_name, avatarUrl: o.avatar_url } : null;
}

export function publicUserFromWire(u: V1PublicUser): PublicUserRow {
  return {
    slug: u.slug,
    displayName: u.display_name,
    avatarUrl: u.avatar_url,
    createdAt: unixToIso(u.created),
    socialLinks: u.social_links,
    emails: u.emails,
    phones: u.phones,
    addresses: u.addresses.map((a) => ({
      label: a.label,
      line1: a.line1,
      line2: a.line2,
      city: a.city,
      region: a.region,
      postalCode: a.postal_code,
      country: a.country,
    })),
    personas: u.personas.map((p) => ({
      slug: p.slug,
      name: p.name,
      description: p.description,
      visibility: p.visibility,
      createdAt: unixToIso(p.created),
      owner: ownerFromWire(p.owner),
    })),
  };
}

export function publicPersonaFromWire(p: V1PublicPersona): PublicPersonaRow {
  const out: PublicPersonaRow = {
    slug: p.slug,
    name: p.name,
    description: p.description,
    modelPrompt: p.model_prompt,
    provider: p.provider,
    model: p.model,
    avatarUrl: p.avatar_url,
    voice: p.voice,
    character: p.character,
    examples: p.examples,
    visibility: p.visibility,
    createdAt: unixToIso(p.created),
    owner: ownerFromWire(p.owner),
    demoEnabled: p.demo_enabled,
  };
  if (p.chat_status !== undefined) out.chatStatus = p.chat_status;
  return out;
}

export function personaFromWire(p: V1Persona): PersonaRow {
  const out: PersonaRow = {
    id: p.id,
    userId: p.user_id,
    ownerKind: p.owner_kind,
    ownerId: p.owner_id,
    slug: p.slug,
    name: p.name,
    description: p.description,
    visibility: p.visibility,
    model: p.model,
    serviceId: p.service_id,
    appId: p.app_id,
    avatarAttachmentId: p.avatar_attachment_id,
    modelPrompt: p.model_prompt,
    voice: p.voice,
    character: p.character,
    examples: p.examples,
    createdAt: unixToIso(p.created),
    updatedAt: unixToIso(p.updated),
  };
  if (p.owned_ecosystem_id !== undefined) out.ownedEcosystemId = p.owned_ecosystem_id;
  if (p.corpus_ecosystem_id !== undefined) out.corpusEcosystemId = p.corpus_ecosystem_id;
  if (p.canned_chat !== undefined) out.cannedChat = p.canned_chat;
  if (p.chat_status !== undefined) out.chatStatus = p.chat_status;
  return out;
}

export function providerTemplateFromWire(t: V1ProviderTemplate): ServiceTemplateRow {
  const out: ServiceTemplateRow = {
    id: t.id,
    providerKind: t.provider_kind,
    name: t.name,
    baseUrl: t.base_url,
    documentationUrl: t.documentation_url,
    statusUrl: t.status_url,
    connectionSpec: t.connection_spec ? connectionSpecFromWire(t.connection_spec) : null,
    models: t.models.map((m) => ({
      id: m.id,
      name: m.name,
      description: m.description,
      metadata: m.metadata,
      source: m.source,
      lastSyncedAt: m.last_synced_at,
      createdAt: unixToIso(m.created),
    })),
    createdAt: unixToIso(t.created),
    updatedAt: unixToIso(t.updated),
  };
  if (t.available_via !== undefined) out.availableVia = t.available_via;
  if (t.modalities !== undefined) out.modalities = t.modalities;
  return out;
}

export function specialInterestFromWire(r: V1SpecialInterest): SpecialInterestRow {
  const out: SpecialInterestRow = {
    id: r.id,
    personaId: r.persona_id,
    slug: r.slug,
    general: r.general,
    topical: r.topical,
    specific: r.specific,
    stances: r.stances,
    position: r.position,
    bucketId: r.bucket_id,
    isDeleted: r.is_deleted,
    createdAt: unixToIso(r.created),
    updatedAt: unixToIso(r.updated),
  };
  if (r.bucket_type_id !== undefined) out.bucketTypeId = r.bucket_type_id;
  return out;
}

export function approvalFromWire(a: V1PersonaApproval): ApprovalRow {
  const out: ApprovalRow = {
    id: a.id,
    personaId: a.persona_id,
    subjectKind: a.subject_kind,
    subjectEco: a.subject_eco,
    toolName: a.tool_name,
    args: a.args,
    status: a.status,
    createdAt: unixToIso(a.created),
  };
  if (a.subject_id !== undefined) out.subjectId = a.subject_id;
  if (a.requested_by !== undefined) out.requestedBy = a.requested_by;
  if (a.decided_by !== undefined) out.decidedBy = a.decided_by;
  if (a.decided_at !== undefined) out.decidedAt = a.decided_at;
  if (a.result !== undefined) out.result = a.result;
  return out;
}

export function toolFromWire(t: V1PersonaTool): ToolCatalogItemRow {
  return {
    toolName: t.tool_name,
    source: t.source ?? null,
    displayName: t.display_name,
    description: t.description,
    readOnly: t.read_only,
    granted: t.granted,
    autonomous: t.autonomous,
  };
}

export function toolGrantFromWire(t: V1PersonaToolGrant): ToolGrantRow {
  return { toolName: t.tool_name, autonomous: t.autonomous, createdAt: unixToIso(t.created) };
}

export function userToolFromWire(t: V1UserTool): UserToolRow {
  return {
    toolName: t.tool_name,
    source: t.source ?? null,
    displayName: t.display_name,
    description: t.description,
    readOnly: t.read_only,
    allowed: t.allowed,
  };
}
