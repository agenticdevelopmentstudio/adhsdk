// Integrations API client — wired to the real backend integrations subsystem
// (/api/v1/integrations). Covers two surfaces:
//   • the provider CATALOG (GET /v1/integrations/providers) — every provider the
//     platform can integrate, with its auth method + capabilities; and
//   • an ecosystem's own, owner-scoped provider CONFIGS — its OAuth client
//     credentials + optional endpoint overrides, secrets masked to `hasSecret`.
//
// `ecosystemId` == the ecosystem id (the RLS owner). The backend 403s if it isn't
// the caller's own ecosystem; that surfaces as a thrown AuthHttpError the pane
// renders inline (it never crashes).
//
// It also covers an ecosystem's CONNECTIONS (linked accounts): list / connect
// (all five auth methods) / disconnect / sync-now / per-connection sync settings,
// plus the OAuth start endpoints (connect_sessions flows oauth / install / link_token, and
// register_instance). Every
// call names the target ecosystem (list/auth-url/link-token/register-instance take
// `ecosystemId`; connect names it in `ecosystemId`); the backend authorizes the caller
// against that ecosystem (403 otherwise). Connection-scoped ops (disconnect / sync /
// settings) derive the ecosystem from the connection, so they take only its id.

import {
  authedJson,
  authedRequest,
  decodeBase64UrlJson,
  isNotFound,
  listAllV1,
  unixToIso,
  withV1Query,
} from "../http";
import { enc } from "../client-helpers";
import type {
  AdoptedInstallationRow,
  AdoptedInstallationWire,
  AdoptInstallationsBodyType,
  AdoptInstallationsResultRow,
  AdoptInstallationsResultWire,
  ConnectionWire,
  DeliverabilityWebhookWire,
  IntegrationTestResultWire,
  ProviderCatalogEntryWire,
  ProviderConfigWire,
  RegisterInstanceResultWire,
  SyncSettingsResultWire,
  TransferProviderConfigResultWire,
  AuthUrlResultRow,
  ConnectRequestBody,
  CreateProviderConfigBody,
  DeliverabilityWebhookRow,
  IntegrationTestResultRow,
  LinkTokenBodyType,
  MaskedProviderConfigRow,
  ProviderCatalogEntryRow,
  ProviderConfigInputBody,
  RegisterInstanceBodyType,
  RegisterInstanceResultRow,
  SafeConnectionRow,
  SyncSettingsBodyType,
  SyncSettingsResultRow,
  TestCredentialsBodyType,
  TransferProviderConfigBodyType,
  TransferProviderConfigResultRow,
} from "./wire";

/** A provider catalog entry (from GET /integrations/providers). */
export type ProviderCatalogEntry = ProviderCatalogEntryRow;

/** The provider auth methods that gate the config editor's field set. */
export type ProviderAuthMethod = ProviderCatalogEntry["authMethod"];

/** A stored, secret-masked provider config for an ecosystem. */
export type MaskedProviderConfig = MaskedProviderConfigRow;

/** The registration details for a provider's deliverability webhook (postmark today). */
export type DeliverabilityWebhook = DeliverabilityWebhookRow;

/** The PUT (upsert) body for a provider config — a blank/absent
 *  `clientSecret` preserves the stored secret. */
export type ProviderConfigInput = ProviderConfigInputBody;

/** The POST (create) body for a new provider config — names the target provider
 *  and a human-facing config name, plus the same input fields as the upsert body. */
export type CreateProviderConfig = CreateProviderConfigBody;

/** A caller's own connection (linked account), secrets redacted. */
export type SafeConnection = SafeConnectionRow;

/** The polymorphic connect body — a discriminated union keyed by `type`
 *  (= the provider's auth method). Every variant requires `ecosystemId`: the
 *  client names the target ecosystem, and the backend authorizes the caller
 *  against it (403 otherwise) before persisting the connection under it. */
export type ConnectRequest = ConnectRequestBody;

/** `{ url, state }` — the OAuth authorize URL + the round-trip CSRF state. */
export type AuthUrlResult = AuthUrlResultRow;
export type AdoptInstallationsBody = AdoptInstallationsBodyType;
export type AdoptInstallationsResult = AdoptInstallationsResultRow;

/** What a credential test came back with. `ok: false` is an answer, not a thrown error. */
export type IntegrationTestResult = IntegrationTestResultRow;

/** Body for testing a draft credential that has not been saved yet. */
export type TestCredentialsBody = TestCredentialsBodyType;

/** Body for moving one integration to another ecosystem. */
export type TransferProviderConfigBody = TransferProviderConfigBodyType;

/** `{ config, connections, repositoryCaches }` — what a transfer moved. */
export type TransferProviderConfigResult = TransferProviderConfigResultRow;

/** Body for register-instance (self-hosted OAuth, e.g. Mastodon). */
export type RegisterInstanceBody = RegisterInstanceBodyType;

/** `{ state, authorizeUrl, clientId }` from register-instance. */
export type RegisterInstanceResult = RegisterInstanceResultRow;

/** Optional body for the Plaid link-token mint (`{ serviceType? }`). */
export type LinkTokenBody = LinkTokenBodyType;

/** Per-connection sync settings the worker reads (gmail today). */
export type SyncSettingsBody = SyncSettingsBodyType;

/** `{ ok, syncSettings }` returned by the settings PATCH. */
export type SyncSettingsResult = SyncSettingsResultRow;

const BASE = "/api/v1/integrations";

/** The synced tables `GET /v1/integrations/{resource}?connection=` serves. */
export type ConnectionDataResource =
  | "media-items"
  | "social-notifications"
  | "media-albums"
  | "email-labels"
  | "social-posts";

/** One page of that route: rows in syncVersion order; `nextCursor` is null on the last page. */
export interface ConnectionDataPage {
  rows: Array<Record<string, unknown>>;
  nextCursor: string | null;
}

/** The client route the OAuth/oauth_instance provider redirects back to with the
 *  authorization `code`. Kept as one constant so the connect flow and the callback
 *  page agree on the path. The backend must allow this path for the hub's origins
 *  (see `redirectAllowlist.ts`). */
export const OAUTH_CALLBACK_PATH = "/integrations/oauth-callback";

/** The absolute callback URL for the current origin (client-only). */
export function oauthCallbackUrl(): string {
  return `${window.location.origin}${OAUTH_CALLBACK_PATH}`;
}

/**
 * The claims the backend signs into an integration OAuth `state`.
 *
 * The backend mints `state` as `base64url(JSON(claims)) + "." + base64url(HMAC)` — the
 * claims travel IN the token, in the clear, and the signature is what makes them
 * trustworthy (`integration/oauthState.ts`). That shape is what lets
 * {@link decodeOAuthStateClaims} exist at all.
 */
export interface IntegrationOAuthStateClaims {
  /** The user the flow was started by; the backend re-checks it against the caller. */
  customerId: string;
  providerId: string;
  serviceType: string;
  /** The ecosystem uuid the connect must be filed under. */
  ecosystemId: string;
  /** Issued-at, epoch-ms. */
  iat: number;
}

/**
 * Read (never TRUST) the claims a `state` carries, or null when it is not one of ours.
 *
 * It decodes the payload half and ignores the signature ON PURPOSE, because nothing here is
 * a security decision: every value it recovers goes straight back to
 * `POST /v1/integrations/connect_sessions`, which re-verifies the signature, that the state was minted
 * for THIS caller, and that it names this ecosystem, before it writes anything. A forged
 * state gets the same 400 it would have got without this function.
 *
 * It exists because a GitHub App has ONE Setup URL for the whole app: an installation
 * started on any origin in the family returns to the SAME origin, where the pending-connect
 * stash — `sessionStorage`, which is per-origin — is empty. The state is the only thing
 * that crosses that boundary, and it already names the provider, the service type and the
 * ecosystem, which is everything the connect needs.
 */
export function decodeOAuthStateClaims(state: string): IntegrationOAuthStateClaims | null {
  const dot = state.indexOf(".");
  if (dot <= 0 || dot === state.length - 1) return null;
  // Decoded by `auth`'s shared base64url-JSON reader rather than by an `atob` here. The
  // backend serializes these claims with `JSON.stringify` and base64s the UTF-8 bytes, and
  // `atob` hands those bytes back one per code unit — so a non-ASCII serviceType or
  // ecosystem id decoded naively becomes mojibake in the very fields that are echoed to
  // `POST /v1/integrations/connect_sessions`, where they match nothing. That decode is identical to the
  // one a JWT payload needs, and it was written three times before it was written once.
  const parsed = decodeBase64UrlJson(state.slice(0, dot));
  if (!parsed || typeof parsed !== "object") return null;
  const c = parsed as Record<string, unknown>;
  const str = (v: unknown): v is string => typeof v === "string" && v.length > 0;
  if (!str(c.customerId) || !str(c.providerId) || !str(c.serviceType) || !str(c.ecosystemId)) {
    return null;
  }
  if (typeof c.iat !== "number" || !Number.isFinite(c.iat)) return null;
  return {
    customerId: c.customerId,
    providerId: c.providerId,
    serviceType: c.serviceType,
    ecosystemId: c.ecosystemId,
    iat: c.iat,
  };
}

/**
 * How long a minted `state` stays valid, and how far ahead of us an issuer's clock may be.
 *
 * These MIRROR `OAUTH_STATE_TTL_MS` and `FUTURE_SKEW_MS` in the hub backend's
 * `integration/oauthState.ts`, which is the authority: the backend re-checks freshness on
 * every connect, and this copy is a COURTESY — it exists to say "start again" in a sentence
 * instead of forwarding the backend's rejection prose, and it must never be the thing that
 * decides a connect.
 *
 * Which is why the pre-flight window is deliberately WIDER than the backend's by
 * {@link OAUTH_STATE_CLOCK_GRACE_MS}, in both directions. The two clocks are the operator's
 * browser and a server, so mirrored bounds do not agree: they differ by whatever the drift
 * plus the round-trip is, and a client that is even a second STRICTER refuses a state the
 * backend would have taken — telling an operator to redo an installation that was about to
 * succeed, with no way to tell that from a real expiry. Being wider only ever costs the POST
 * that would have happened anyway before this check existed, answered by the backend's own
 * verdict. The grace is the drift this can absorb; past it the backend answers, as it always
 * did.
 *
 * They live here, beside the claims they judge, because the claims are the only reason a
 * client can ask the question at all.
 */
export const OAUTH_STATE_TTL_MS = 10 * 60 * 1000;
/** @see {@link OAUTH_STATE_TTL_MS} */
export const OAUTH_STATE_FUTURE_SKEW_MS = 60_000;
/** How far the two clocks may disagree before this pre-flight and the backend can differ on
 *  the same state. Added to BOTH bounds, so the client's window strictly contains the
 *  backend's and this check can only ever be the more permissive of the two.
 *  @see {@link OAUTH_STATE_TTL_MS} */
export const OAUTH_STATE_CLOCK_GRACE_MS = 30_000;

/**
 * Whether a decoded `state` is still within the window the backend will accept.
 *
 * The case this exists for is not an edge: `setup_action=request` tells the operator that an
 * org owner has to approve the installation, and an approval that arrives more than ten
 * minutes later comes back with a state the backend is certain to reject. Without this the
 * callback POSTs anyway and reports the rejection as an unexpected error — a Sentry event and
 * a line of backend prose — for the outcome its own message told the operator to expect.
 */
export function isOAuthStateFresh(
  claims: Pick<IntegrationOAuthStateClaims, "iat">,
  now: number = Date.now(),
): boolean {
  const age = now - claims.iat;
  return (
    age <= OAUTH_STATE_TTL_MS + OAUTH_STATE_CLOCK_GRACE_MS &&
    age >= -(OAUTH_STATE_FUTURE_SKEW_MS + OAUTH_STATE_CLOCK_GRACE_MS)
  );
}

const configPath = (providerOrConfigId?: string) =>
  providerOrConfigId
    ? `${BASE}/provider_configs/${enc(providerOrConfigId)}`
    : `${BASE}/provider_configs`;

/** `ecosystem` names the owning ecosystem on every provider-config call (query on a read or a
 *  delete, body field on a write). */
const inEco = (url: string, ecosystemId: string) => withV1Query(url, { ecosystem: ecosystemId });

// ── wire <-> domain mappers (explicit, field by field) ────────────────────────

const toCatalogEntry = (w: ProviderCatalogEntryWire): ProviderCatalogEntry => ({
  providerId: w.provider_id,
  displayName: w.display_name,
  subtitle: w.subtitle,
  description: w.description,
  links: w.links,
  authMethod: w.auth_method,
  serviceTypes: w.service_types,
  capabilities: w.capabilities,
  defaultPollIntervalMs: w.default_poll_interval_ms,
  ...(w.config_fields !== undefined ? { configFields: w.config_fields } : {}),
  testable: w.testable,
});

const toWebhook = (w: DeliverabilityWebhookWire): DeliverabilityWebhook => ({
  url: w.url,
  secretHeader: w.secret_header,
  secret: w.secret,
  instruction: w.instruction,
});

const toConfig = (w: ProviderConfigWire): MaskedProviderConfig => ({
  id: w.id,
  ecosystemId: w.ecosystem_id,
  providerId: w.provider_id,
  name: w.name,
  rdid: w.rdid,
  config: w.config,
  hasSecret: w.has_secret,
  ...(w.deliverability_webhook !== undefined
    ? { deliverabilityWebhook: w.deliverability_webhook ? toWebhook(w.deliverability_webhook) : null }
    : {}),
  ...(w.updated_by !== undefined ? { updatedBy: w.updated_by } : {}),
  ...(w.created !== undefined ? { createdAt: unixToIso(w.created) } : {}),
  ...(w.updated !== undefined ? { updatedAt: unixToIso(w.updated) } : {}),
});

const toConnection = (w: ConnectionWire): SafeConnection => ({
  id: w.id,
  provider: w.provider,
  serviceType: w.service_type,
  status: w.status,
  displayName: w.display_name,
  username: w.username,
  externalAccountId: w.external_account_id,
  ...(w.last_sync_at !== undefined ? { lastSyncAt: w.last_sync_at } : {}),
  ...(w.last_error !== undefined ? { lastError: w.last_error } : {}),
  createdAt: unixToIso(w.created),
  ...(w.sync_settings !== undefined ? { syncSettings: w.sync_settings } : {}),
});

const toInstallation = (w: AdoptedInstallationWire): AdoptedInstallationRow => ({
  installationId: w.installation_id,
  accountLogin: w.account_login,
  targetType: w.target_type,
  ...(w.connection_id !== undefined ? { connectionId: w.connection_id } : {}),
  ...(w.skipped !== undefined ? { skipped: w.skipped } : {}),
  ...(w.warning !== undefined ? { warning: w.warning } : {}),
});

const toAdopted = (w: AdoptInstallationsResultWire): AdoptInstallationsResult => ({
  connected: w.connected.map(toInstallation),
  skipped: w.skipped.map(toInstallation),
});

const toTestResult = (w: IntegrationTestResultWire): IntegrationTestResult => ({
  ok: w.ok,
  summary: w.summary,
  notes: w.notes,
  ...(w.adopted !== undefined ? { adopted: toAdopted(w.adopted) } : {}),
});

const configInputToWire = (b: ProviderConfigInput) => ({
  ...(b.clientId !== undefined ? { client_id: b.clientId } : {}),
  ...(b.scopes !== undefined ? { scopes: b.scopes } : {}),
  ...(b.authUrl !== undefined ? { auth_url: b.authUrl } : {}),
  ...(b.tokenUrl !== undefined ? { token_url: b.tokenUrl } : {}),
  ...(b.userinfoUrl !== undefined ? { userinfo_url: b.userinfoUrl } : {}),
  ...(b.validateUrl !== undefined ? { validate_url: b.validateUrl } : {}),
  ...(b.credentialStyle !== undefined ? { credential_style: b.credentialStyle } : {}),
  ...(b.endpoints !== undefined ? { endpoints: b.endpoints } : {}),
  ...(b.clientSecret !== undefined ? { client_secret: b.clientSecret } : {}),
  ...(b.fields !== undefined ? { fields: b.fields } : {}),
  ...(b.enabled !== undefined ? { enabled: b.enabled } : {}),
});

const connectToWire = (b: ConnectRequest) => {
  const base = {
    flow: "connect" as const,
    type: b.type,
    provider_id: b.providerId,
    service_type: b.serviceType,
    ecosystem_id: b.ecosystemId,
  };
  switch (b.type) {
    case "oauth":
      return { ...base, code: b.code, redirect_uri: b.redirectUri, state: b.state };
    case "api_key":
      return { ...base, fields: b.fields };
    case "app_password":
      return {
        ...base,
        ...(b.identifier !== undefined ? { identifier: b.identifier } : {}),
        ...(b.password !== undefined ? { password: b.password } : {}),
        ...(b.instanceUrl !== undefined ? { instance_url: b.instanceUrl } : {}),
        ...(b.providerConfigId !== undefined ? { provider_config_id: b.providerConfigId } : {}),
      };
    case "plaid_link":
      return { ...base, public_token: b.publicToken };
    case "oauth_instance":
      return { ...base, code: b.code, state: b.state };
    case "github_app":
      return { ...base, installation_id: b.installationId, state: b.state };
  }
};

const syncSettingsToWire = (b: SyncSettingsBody) => ({
  ...(b.gmailLabelIds !== undefined ? { gmail_label_ids: b.gmailLabelIds } : {}),
  ...(b.gmailWindowDays !== undefined ? { gmail_window_days: b.gmailWindowDays } : {}),
  ...(b.redditSubreddits !== undefined ? { reddit_subreddits: b.redditSubreddits } : {}),
  ...(b.redditKeywords !== undefined ? { reddit_keywords: b.redditKeywords } : {}),
  ...(b.audienceIds !== undefined ? { audience_ids: b.audienceIds } : {}),
});

const post = <T>(url: string, body?: unknown) =>
  authedJson<T>(url, { method: "POST", ...(body !== undefined ? { body: JSON.stringify(body) } : {}) });

const connectSession = <T>(body: Record<string, unknown>) =>
  post<T>(`${BASE}/connect_sessions`, body);

export const integrationsApi = {
  /** The provider catalog — every provider the platform can integrate. */
  async listProviders(): Promise<ProviderCatalogEntry[]> {
    const rows = await listAllV1<ProviderCatalogEntryWire>(
      `${BASE}/providers`,
      {},
      { cursorOf: (r) => (r as ProviderCatalogEntryWire).provider_id },
    );
    return rows.map(toCatalogEntry);
  },

  /** The ecosystem's configured providers (secrets masked to `hasSecret`). */
  async listProviderConfigs(ecosystemId: string): Promise<MaskedProviderConfig[]> {
    const rows = await listAllV1<ProviderConfigWire>(inEco(configPath(), ecosystemId));
    return rows.map(toConfig);
  },

  /** One masked config, or null when none is stored yet (backend 404). */
  async getProviderConfig(
    ecosystemId: string,
    providerId: string,
  ): Promise<MaskedProviderConfig | null> {
    try {
      return toConfig(
        await authedJson<ProviderConfigWire>(inEco(configPath(providerId), ecosystemId)),
      );
    } catch (err) {
      if (isNotFound(err)) return null;
      throw err;
    }
  },

  /** Upsert the config. A blank/absent `clientSecret` in `body` preserves the
   *  stored secret; a present one replaces it. Returns the masked row. */
  async putProviderConfig(
    ecosystemId: string,
    providerId: string,
    body: ProviderConfigInput,
  ): Promise<MaskedProviderConfig> {
    return toConfig(
      await post<ProviderConfigWire>(configPath(providerId), {
        ...configInputToWire(body),
        ecosystem: ecosystemId,
      }),
    );
  },

  async deleteProviderConfig(ecosystemId: string, providerId: string): Promise<void> {
    await authedRequest(inEco(configPath(providerId), ecosystemId), { method: "DELETE" });
  },

  // ── id/rdid-addressed provider-config CRUD ───────────────────────────────────

  /** Create a new provider config under the ecosystem. POSTs to the collection path
   *  with a `provider_id` + `name` and the config input fields; returns the masked row. */
  async createProviderConfig(
    ecosystemId: string,
    body: CreateProviderConfigBody,
  ): Promise<MaskedProviderConfig> {
    return toConfig(
      await post<ProviderConfigWire>(configPath(), {
        provider_id: body.providerId,
        name: body.name,
        ...configInputToWire(body),
        ecosystem: ecosystemId,
      }),
    );
  },

  /** One masked config addressed by its id/rdid, or null when it doesn't exist
   *  (backend 404). */
  async getProviderConfigById(
    ecosystemId: string,
    configId: string,
  ): Promise<MaskedProviderConfig | null> {
    try {
      return toConfig(
        await authedJson<ProviderConfigWire>(inEco(configPath(configId), ecosystemId)),
      );
    } catch (err) {
      if (isNotFound(err)) return null;
      throw err;
    }
  },

  /** Update an existing provider config addressed by its id/rdid. A blank/absent
   *  `clientSecret` in `body` preserves the stored secret. Returns the masked row. */
  async updateProviderConfig(
    ecosystemId: string,
    configId: string,
    body: ProviderConfigInput & { name?: string },
  ): Promise<MaskedProviderConfig> {
    return toConfig(
      await post<ProviderConfigWire>(configPath(configId), {
        ...(body.name !== undefined ? { name: body.name } : {}),
        ...configInputToWire(body),
        ecosystem: ecosystemId,
      }),
    );
  },

  /** Delete a provider config addressed by its id/rdid. */
  async deleteProviderConfigById(ecosystemId: string, configId: string): Promise<void> {
    await authedRequest(inEco(configPath(configId), ecosystemId), { method: "DELETE" });
  },

  /**
   * Ask the provider whether a SAVED integration still works.
   *
   * FOR A GITHUB APP THIS ALSO CONNECTS. The only proof an app id and private key are real is
   * to mint a JWT and enumerate the installations the app can see, and that enumeration is
   * exactly what creates the connection rows and warms the repository cache — so pressing Test
   * is also what makes an org appear in the repository picker. The result says so on
   * `adopted`, and a caller holding a connection list must refresh it when that is present.
   *
   * A refused credential RESOLVES with `ok: false`; only a malformed request throws.
   */
  async testProviderConfig(
    ecosystemId: string,
    configId: string,
  ): Promise<IntegrationTestResult> {
    return toTestResult(
      await post<IntegrationTestResultWire>(`${configPath(configId)}/test`, {
        ecosystem: ecosystemId,
      }),
    );
  },

  /**
   * Ask the provider whether a credential that has NOT been saved works — the Test button in
   * an Add-integration dialog, where there is no row to address yet. Writes nothing: no
   * config, no connection, no cache, which is the whole difference from
   * {@link testProviderConfig}.
   *
   * Pass `providerConfigId` with a blank `clientSecret` to test a stored secret from an edit
   * dialog; see {@link TestCredentialsBody.providerConfigId} for why that is needed.
   */
  async testProviderCredentials(
    providerId: string,
    body: TestCredentialsBody,
  ): Promise<IntegrationTestResult> {
    return toTestResult(
      await post<IntegrationTestResultWire>(
        `${BASE}/providers/${enc(providerId)}/test_credentials`,
        {
          ecosystem_id: body.ecosystemId,
          ...(body.clientId !== undefined ? { client_id: body.clientId } : {}),
          ...(body.clientSecret !== undefined ? { client_secret: body.clientSecret } : {}),
          ...(body.fields !== undefined ? { fields: body.fields } : {}),
          ...(body.providerConfigId !== undefined
            ? { provider_config_id: body.providerConfigId }
            : {}),
        },
      ),
    );
  },

  /**
   * Move one integration to another ecosystem — the operator's own workspace to an
   * organization they also own, or the other way.
   *
   * The credential, the connections it minted and their cached repository lists all travel
   * together, and the integration's `integration` rdid is RE-MINTED at the destination, so the
   * address it answered to before stops resolving. The caller must manage BOTH ends.
   */
  async transferProviderConfig(
    ecosystemId: string,
    configId: string,
    body: TransferProviderConfigBody,
  ): Promise<TransferProviderConfigResult> {
    const w = await post<TransferProviderConfigResultWire>(`${configPath(configId)}/transfer`, {
      target_ecosystem_id: body.targetEcosystemId,
      ecosystem: ecosystemId,
    });
    return {
      config: toConfig(w.config),
      connections: w.connections,
      repositoryCaches: w.repository_caches,
    };
  },

  /**
   * Mint a NEW inbound webhook secret for this config and return the updated masked row (the
   * value arrives on `deliverabilityWebhook.secret` — it is never echoed anywhere else).
   *
   * DESTRUCTIVE, in the same sense as rotating a list's embed key: the previous secret stops
   * authenticating the moment this returns, so a provider still configured with it starts
   * failing silently — Postmark logs a 401 its own side and nothing in the product notices.
   * Callers must confirm before firing it.
   *
   * It is also the ONLY way a config created before per-config secrets existed gets one, so it
   * doubles as "generate" for a webhook whose `secret` is null.
   */
  async rotateWebhookSecret(
    ecosystemId: string,
    configId: string,
  ): Promise<MaskedProviderConfig> {
    return toConfig(
      await post<ProviderConfigWire>(`${configPath(configId)}/rotate_webhook_secret`, {
        ecosystem: ecosystemId,
      }),
    );
  },

  // ── connections (linked accounts for the caller's active ecosystem) ──────────

  /** The connections OWNED by ecosystem `ecosystemId` (secrets redacted), across all
   *  providers. The backend authorizes the caller against the ecosystem (403 otherwise). */
  async listConnections(ecosystemId: string): Promise<SafeConnection[]> {
    const rows = await listAllV1<ConnectionWire>(
      withV1Query(`${BASE}/connections`, { ecosystem_id: ecosystemId }),
    );
    return rows.map(toConnection);
  },

  /** One page of a connection's synced rows (`GET /v1/integrations/{resource}?connection=`),
   *  ordered by syncVersion. Pass the previous page's `nextCursor` as `cursor`; the backend
   *  defaults the limit to 50 and caps it at 200. Only the connection's own customer may read. */
  async getConnectionData(
    connectionId: string,
    resource: ConnectionDataResource,
    opts: { cursor?: string | null; limit?: number } = {},
  ): Promise<ConnectionDataPage> {
    const w = await authedJson<{ rows: Array<Record<string, unknown>>; next_cursor?: string | null }>(
      withV1Query(`${BASE}/${enc(resource)}`, {
        connection: connectionId,
        cursor: opts.cursor || undefined,
        limit: opts.limit || undefined,
      }),
    );
    return { rows: w.rows, nextCursor: w.next_cursor ?? null };
  },

  /** Finish a connect for any auth method and persist the connection. The `body`
   *  names the owning ecosystem in `ecosystemId`; the backend authorizes the caller
   *  against it (403 otherwise) before persisting the connection under it. */
  async connect(body: ConnectRequest): Promise<SafeConnection> {
    return toConnection(await connectSession<ConnectionWire>(connectToWire(body)));
  },

  /** Disconnect (soft-delete) a connection the caller owns. */
  async disconnect(connectionId: string): Promise<void> {
    await authedRequest(`${BASE}/connections/${enc(connectionId)}`, { method: "DELETE" });
  },

  /** Trigger an immediate sync. Throws AuthHttpError(503) when no worker is
   *  registered for the provider yet (caller shows an inline "not available" note). */
  async sync(connectionId: string): Promise<void> {
    await authedRequest(`${BASE}/connections/${enc(connectionId)}/sync`, { method: "POST" });
  },

  /** Update a connection's caller-tunable sync settings (gmail today). */
  async patchSettings(
    connectionId: string,
    body: SyncSettingsBody,
  ): Promise<SyncSettingsResult> {
    const w = await post<SyncSettingsResultWire>(
      `${BASE}/connections/${enc(connectionId)}`,
      syncSettingsToWire(body),
    );
    return { ok: w.ok, syncSettings: w.sync_settings };
  },

  // ── OAuth / install / instance / link-token start endpoints ─────────────────

  /** Get the provider's OAuth authorize URL + the signed round-trip `state`, for the
   *  target ecosystem (its client id drives the URL; caller authorized against it). */
  async getAuthUrl(
    providerId: string,
    params: { ecosystemId: string; redirectUri: string; serviceType?: string; scopes?: string },
  ): Promise<AuthUrlResult> {
    const w = await connectSession<{ url: string; state: string }>({
      flow: "oauth",
      provider: providerId,
      ecosystem_id: params.ecosystemId,
      redirect_uri: params.redirectUri,
      ...(params.serviceType ? { service_type: params.serviceType } : {}),
      ...(params.scopes ? { scopes: params.scopes } : {}),
    });
    return { url: w.url, state: w.state };
  },

  /**
   * Get the provider's app-INSTALLATION URL + the signed round-trip `state` (`github_app`
   * providers only; 400 otherwise).
   *
   * No `redirectUri`, and that absence is the whole difference from {@link getAuthUrl}: an
   * app returns to the setup URL configured ON THE APP at the provider, so there is nothing
   * here for a caller to point somewhere else — and no `scopes` either, because an app's
   * permissions are declared on the app, not negotiated per request.
   */
  async getInstallUrl(
    providerId: string,
    params: { ecosystemId: string; serviceType?: string },
  ): Promise<AuthUrlResult> {
    const w = await connectSession<{ url: string; state: string }>({
      flow: "install",
      provider: providerId,
      ecosystem_id: params.ecosystemId,
      ...(params.serviceType ? { service_type: params.serviceType } : {}),
    });
    return { url: w.url, state: w.state };
  },

  /**
   * Connect every installation the saved GitHub App can already see — `github_app`
   * providers only (400 otherwise).
   *
   * This is the redirect-free connect, and it is also the credential test: the backend can
   * only answer by signing a JWT the provider accepts, so a wrong app id or an unreadable
   * private key fails HERE, at the moment they were entered, rather than at the first
   * deploy. An installation already in service is reported under `skipped` rather than
   * taken, so calling it twice is safe.
   */
  async adoptInstallations(
    providerId: string,
    body: AdoptInstallationsBody,
  ): Promise<AdoptInstallationsResult> {
    return toAdopted(
      await post<AdoptInstallationsResultWire>(
        `${BASE}/providers/${enc(providerId)}/adopt_installations`,
        {
          ecosystem_id: body.ecosystemId,
          provider_config_id: body.providerConfigId,
          ...(body.serviceType !== undefined ? { service_type: body.serviceType } : {}),
        },
      ),
    );
  },

  /** Register a self-hosted OAuth instance (Mastodon) → `{ state, authorizeUrl, clientId }`. */
  async registerInstance(
    providerId: string,
    body: RegisterInstanceBody,
  ): Promise<RegisterInstanceResult> {
    const w = await post<RegisterInstanceResultWire>(
      `${BASE}/providers/${enc(providerId)}/register_instance`,
      {
        ecosystem_id: body.ecosystemId,
        instance_url: body.instanceUrl,
        redirect_uri: body.redirectUri,
        ...(body.serviceType !== undefined ? { service_type: body.serviceType } : {}),
        ...(body.providerConfigId !== undefined
          ? { provider_config_id: body.providerConfigId }
          : {}),
      },
    );
    return { state: w.state, authorizeUrl: w.authorize_url, clientId: w.client_id };
  },

  /** Mint a Plaid Link token for the provider. */
  async createLinkToken(
    providerId: string,
    body: LinkTokenBody,
  ): Promise<{ linkToken: string }> {
    const w = await connectSession<{ link_token: string }>({
      flow: "link_token",
      provider: providerId,
      ecosystem_id: body.ecosystemId,
      ...(body.serviceType !== undefined ? { service_type: body.serviceType } : {}),
    });
    return { linkToken: w.link_token };
  },
};
