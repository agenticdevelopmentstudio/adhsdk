// Conformance vectors for the integrations client (cookbook adh/hub/integrations).
// Only `fetch` is stubbed: the real `authedJson` / `authedRequest` / `listAllV1`, the path
// builders and the wire <-> domain mappers all run.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  decodeOAuthStateClaims,
  integrationsApi,
  isOAuthStateFresh,
  oauthCallbackUrl,
} from "../integrations";
import { fetchMock, initAt, installFetch, paramsAt, pathAt, bodyAt, respondOnce, respondWith, urlAt, v1List } from "../../__tests__/v1-fetch";

beforeEach(() => installFetch());
afterEach(() => vi.unstubAllGlobals());

const BASE = "/api/v1/integrations";

const configWire = (extra: Record<string, unknown> = {}) => ({
  id: "cfg-1",
  ecosystem_id: "eco-1",
  provider_id: "github",
  name: "Prod",
  rdid: "rd-1",
  config: {},
  has_secret: true,
  ...extra,
});

const connectionWire = {
  id: "conn-1",
  provider: "github",
  service_type: "repos",
  status: "active",
  display_name: "n",
  username: "u",
  external_account_id: "x",
  created: 1767225600,
};

// base64url of a JSON object, the way the backend builds the state prefix.
const b64url = (o: unknown) =>
  Buffer.from(JSON.stringify(o)).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const claims = { customerId: "c1", providerId: "github", serviceType: "repos", ecosystemId: "eco-1", iat: 1000 };

describe("integrations client conformance vectors", () => {
  it("hub-domain-integrations-001 lists the provider catalog, unwrapped from the envelope", async () => {
    respondWith(v1List([{
      provider_id: "github", display_name: "GitHub", subtitle: "", description: "", links: [],
      auth_method: "github_app", service_types: ["repos"], capabilities: [], default_poll_interval_ms: 1, testable: true,
    }]));
    const rows = await integrationsApi.listProviders();
    expect(pathAt(0)).toBe(`${BASE}/providers`);
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({ providerId: "github", authMethod: "github_app", testable: true });
  });

  it("hub-domain-integrations-002 lists provider configs scoped by ecosystem", async () => {
    respondWith(v1List([configWire()]));
    const rows = await integrationsApi.listProviderConfigs("eco-1");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs`);
    expect(paramsAt(0).get("ecosystem")).toBe("eco-1");
    expect(rows.map((r) => r.id)).toEqual(["cfg-1"]);
  });

  it("hub-domain-integrations-003 a 404 provider-id lookup resolves null", async () => {
    respondOnce({ error: { message: "nope" } }, 404);
    await expect(integrationsApi.getProviderConfig("eco-1", "github")).resolves.toBeNull();
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/github`);
  });

  it("hub-domain-integrations-004 save sends no client_secret when none is given", async () => {
    respondWith(configWire());
    await integrationsApi.putProviderConfig("eco-1", "github", { clientId: "x" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/github`);
    expect(bodyAt(0)).toEqual({ client_id: "x", ecosystem: "eco-1" });
    expect(bodyAt(0)).not.toHaveProperty("client_secret");
  });

  it("hub-domain-integrations-005 delete by provider id resolves undefined", async () => {
    respondWith({ deleted: true });
    await expect(integrationsApi.deleteProviderConfig("eco-1", "github")).resolves.toBeUndefined();
    expect(initAt(0).method).toBe("DELETE");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/github`);
    expect(paramsAt(0).get("ecosystem")).toBe("eco-1");
  });

  it("hub-domain-integrations-006 create posts to the collection route with no trailing id", async () => {
    respondWith(configWire());
    const cfg = await integrationsApi.createProviderConfig("eco-1", { providerId: "github", name: "Prod" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs`);
    expect(bodyAt(0)).toEqual({ provider_id: "github", name: "Prod", ecosystem: "eco-1" });
    expect(cfg).toMatchObject({ id: "cfg-1", ecosystemId: "eco-1", hasSecret: true });
  });

  it("hub-domain-integrations-007 get by id shares the provider-id URL shape", async () => {
    respondWith(configWire());
    await integrationsApi.getProviderConfigById("eco-1", "cfg-uuid-1");
    expect(initAt(0).method ?? "GET").toBe("GET");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/cfg-uuid-1`);
    expect(paramsAt(0).get("ecosystem")).toBe("eco-1");
  });

  it("hub-domain-integrations-008 a 404 id lookup resolves null", async () => {
    respondOnce({ error: { message: "nope" } }, 404);
    await expect(integrationsApi.getProviderConfigById("eco-1", "cfg-missing")).resolves.toBeNull();
  });

  it("hub-domain-integrations-009 update by id posts the changed field", async () => {
    respondWith(configWire({ name: "Renamed" }));
    await integrationsApi.updateProviderConfig("eco-1", "cfg-1", { name: "Renamed" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/cfg-1`);
    expect(bodyAt(0)).toEqual({ name: "Renamed", ecosystem: "eco-1" });
  });

  it("hub-domain-integrations-010 delete by id resolves undefined", async () => {
    respondWith({ deleted: true });
    await expect(integrationsApi.deleteProviderConfigById("eco-1", "cfg-1")).resolves.toBeUndefined();
    expect(initAt(0).method).toBe("DELETE");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/cfg-1`);
    expect(paramsAt(0).get("ecosystem")).toBe("eco-1");
  });

  it("hub-domain-integrations-011 a failed test result resolves rather than throws", async () => {
    respondWith({ ok: false, summary: "Invalid token", notes: [] });
    const res = await integrationsApi.testProviderConfig("eco-1", "cfg-1");
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/cfg-1/test`);
    expect(bodyAt(0)).toEqual({ ecosystem: "eco-1" });
    expect(res).toEqual({ ok: false, summary: "Invalid token", notes: [] });
  });

  it("hub-domain-integrations-012 a github_app test result carries adopted", async () => {
    respondWith({
      ok: true, summary: "ok", notes: [],
      adopted: {
        connected: [{ installation_id: "1", account_login: "acme", target_type: "Organization", connection_id: "c" }],
        skipped: [],
      },
    });
    const res = await integrationsApi.testProviderConfig("eco-1", "cfg-1");
    expect(res.adopted?.connected[0]).toMatchObject({ installationId: "1", accountLogin: "acme", connectionId: "c" });
    expect(res.adopted?.skipped).toEqual([]);
  });

  it("hub-domain-integrations-013 draft credentials reference the stored config and omit client_secret", async () => {
    respondWith({ ok: true, summary: "ok", notes: [] });
    await integrationsApi.testProviderCredentials("github", { ecosystemId: "eco-1", providerConfigId: "cfg-1" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/providers/github/test_credentials`);
    expect(bodyAt(0)).toEqual({ ecosystem_id: "eco-1", provider_config_id: "cfg-1" });
    expect(bodyAt(0)).not.toHaveProperty("client_secret");
  });

  it("hub-domain-integrations-014 transfer posts the target and maps config, connections and caches together", async () => {
    respondWith({ config: configWire({ ecosystem_id: "eco-2", rdid: "rd-new" }), connections: 3, repository_caches: 2 });
    const res = await integrationsApi.transferProviderConfig("eco-1", "cfg-1", { targetEcosystemId: "eco-2" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/cfg-1/transfer`);
    expect(bodyAt(0)).toEqual({ target_ecosystem_id: "eco-2", ecosystem: "eco-1" });
    expect(res.config.ecosystemId).toBe("eco-2");
    expect(res.config.rdid).toBe("rd-new");
    expect(res.connections).toBe(3);
    expect(res.repositoryCaches).toBe(2);
  });

  it.skip("hub-domain-integrations-015 the live-only connection count is computed server-side; the client passes the count through", () => {});

  it("hub-domain-integrations-016 rotate posts to the rotate route and returns the updated config", async () => {
    respondWith(configWire({ deliverability_webhook: { url: "u", secret_header: "h", secret: "new-secret", instruction: "i" } }));
    const cfg = await integrationsApi.rotateWebhookSecret("eco-1", "cfg-1");
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/provider_configs/cfg-1/rotate_webhook_secret`);
    expect(bodyAt(0)).toEqual({ ecosystem: "eco-1" });
    expect(cfg.deliverabilityWebhook).toEqual({ url: "u", secretHeader: "h", secret: "new-secret", instruction: "i" });
  });

  it.skip("hub-domain-integrations-017 first-secret generation on rotate is server-side behavior", () => {});

  it("hub-domain-integrations-018 lists connections scoped by ecosystem", async () => {
    respondWith(v1List([connectionWire]));
    const rows = await integrationsApi.listConnections("eco-1");
    expect(pathAt(0)).toBe(`${BASE}/connections`);
    expect(paramsAt(0).get("ecosystem_id")).toBe("eco-1");
    expect(rows[0]).toMatchObject({ id: "conn-1", serviceType: "repos", externalAccountId: "x" });
  });

  it("hub-domain-integrations-019 connect posts the oauth variant to connect_sessions in wire shape", async () => {
    respondWith(connectionWire);
    const conn = await integrationsApi.connect({
      type: "oauth", providerId: "github", serviceType: "repos", ecosystemId: "eco-1",
      code: "abc", redirectUri: "https://x/cb", state: "s.sig",
    });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/connect_sessions`);
    expect(bodyAt(0)).toEqual({
      flow: "connect", type: "oauth", provider_id: "github", service_type: "repos", ecosystem_id: "eco-1",
      code: "abc", redirect_uri: "https://x/cb", state: "s.sig",
    });
    expect(conn.id).toBe("conn-1");
  });

  it("hub-domain-integrations-020 github_app connect carries installation_id and no code", async () => {
    respondWith(connectionWire);
    await integrationsApi.connect({
      type: "github_app", providerId: "github", serviceType: "repos", ecosystemId: "eco-1",
      installationId: "12345", state: "s.sig",
    });
    expect(bodyAt(0).installation_id).toBe("12345");
    expect(bodyAt(0)).not.toHaveProperty("code");
  });

  it("hub-domain-integrations-021 app_password connect forwards inline credentials and providerConfigId together", async () => {
    respondWith(connectionWire);
    await expect(integrationsApi.connect({
      type: "app_password", providerId: "mastodon", serviceType: "posts", ecosystemId: "eco-1",
      identifier: "me", password: "pw", providerConfigId: "cfg-1",
    })).resolves.toBeDefined();
    expect(bodyAt(0)).toMatchObject({ identifier: "me", password: "pw", provider_config_id: "cfg-1" });
  });

  it("hub-domain-integrations-022 disconnect issues a DELETE on the connection", async () => {
    respondWith({ deleted: true });
    await expect(integrationsApi.disconnect("conn-1")).resolves.toBeUndefined();
    expect(initAt(0).method).toBe("DELETE");
    expect(pathAt(0)).toBe(`${BASE}/connections/conn-1`);
  });

  it("hub-domain-integrations-023 sync posts to the sync route and a 503 surfaces its status", async () => {
    respondOnce({ error: { message: "no worker" } }, 503);
    const err = await integrationsApi.sync("conn-1").catch((e) => e);
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/connections/conn-1/sync`);
    expect(err.status).toBe(503);
  });

  it("hub-domain-integrations-024 patching settings posts snake_case settings and maps the result", async () => {
    respondWith({ ok: true, sync_settings: { gmail_label_ids: ["INBOX"] } });
    const res = await integrationsApi.patchSettings("conn-1", { gmailLabelIds: ["INBOX"] });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/connections/conn-1`);
    expect(bodyAt(0)).toEqual({ gmail_label_ids: ["INBOX"] });
    expect(res).toEqual({ ok: true, syncSettings: { gmail_label_ids: ["INBOX"] } });
  });

  it("hub-domain-integrations-025 auth url opens an oauth connect session with no serviceType or scopes when unset", async () => {
    respondWith({ url: "https://p/auth", state: "s.sig" });
    const res = await integrationsApi.getAuthUrl("github", { ecosystemId: "eco-1", redirectUri: "https://x/cb" });
    expect(pathAt(0)).toBe(`${BASE}/connect_sessions`);
    expect(bodyAt(0)).toEqual({ flow: "oauth", provider: "github", ecosystem_id: "eco-1", redirect_uri: "https://x/cb" });
    expect(res).toEqual({ url: "https://p/auth", state: "s.sig" });
  });

  it("hub-domain-integrations-026 install url opens an install connect session with no redirect_uri or scopes", async () => {
    respondWith({ url: "https://p/install", state: "s.sig" });
    await integrationsApi.getInstallUrl("github", { ecosystemId: "eco-1" });
    expect(bodyAt(0)).toEqual({ flow: "install", provider: "github", ecosystem_id: "eco-1" });
  });

  it("hub-domain-integrations-027 adopt installations posts the ecosystem and config id and maps the result", async () => {
    respondWith({
      connected: [{ installation_id: "1", account_login: "a", target_type: "User" }],
      skipped: [{ installation_id: "2", account_login: "b", target_type: "User", skipped: "already connected" }],
    });
    const res = await integrationsApi.adoptInstallations("github", { ecosystemId: "eco-1", providerConfigId: "cfg-1" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/providers/github/adopt_installations`);
    expect(bodyAt(0)).toEqual({ ecosystem_id: "eco-1", provider_config_id: "cfg-1" });
    expect(res.connected[0]!.installationId).toBe("1");
    expect(res.skipped[0]!.skipped).toBe("already connected");
  });

  it.skip("hub-domain-integrations-028 required providerConfigId is a compile-time property; no runtime behavior to test", () => {});

  it.skip("hub-domain-integrations-029 adopt idempotency (second call reports skipped) is server-side behavior", () => {});

  it("hub-domain-integrations-030 register instance posts the body in wire shape and maps the result", async () => {
    respondWith({ state: "s.sig", authorize_url: "https://m/authorize", client_id: "cid" });
    const res = await integrationsApi.registerInstance("mastodon", {
      ecosystemId: "eco-1", instanceUrl: "https://example.social", redirectUri: "https://x/cb", providerConfigId: "cfg-1",
    });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe(`${BASE}/providers/mastodon/register_instance`);
    expect(bodyAt(0)).toEqual({
      ecosystem_id: "eco-1", instance_url: "https://example.social", redirect_uri: "https://x/cb", provider_config_id: "cfg-1",
    });
    expect(res).toEqual({ state: "s.sig", authorizeUrl: "https://m/authorize", clientId: "cid" });
  });

  it("hub-domain-integrations-031 link token opens a link_token connect session", async () => {
    respondWith({ link_token: "link-123" });
    const res = await integrationsApi.createLinkToken("plaid", { ecosystemId: "eco-1" });
    expect(pathAt(0)).toBe(`${BASE}/connect_sessions`);
    expect(bodyAt(0)).toEqual({ flow: "link_token", provider: "plaid", ecosystem_id: "eco-1" });
    expect(res).toEqual({ linkToken: "link-123" });
  });

  it("hub-domain-integrations-032 the OAuth callback URL is origin-relative with the fixed path", () => {
    vi.stubGlobal("window", { location: { origin: "https://app.example.test" } });
    expect(oauthCallbackUrl()).toBe("https://app.example.test/integrations/oauth-callback");
  });

  it("hub-domain-integrations-033 state without a dot decodes to null", () => {
    expect(decodeOAuthStateClaims("nodothere")).toBeNull();
  });

  it("hub-domain-integrations-034 state with a leading dot decodes to null", () => {
    expect(decodeOAuthStateClaims(".abc")).toBeNull();
  });

  it("hub-domain-integrations-035 state with a trailing dot decodes to null", () => {
    expect(decodeOAuthStateClaims("abc.")).toBeNull();
  });

  it("hub-domain-integrations-036 a well-formed state decodes to its claims", () => {
    expect(decodeOAuthStateClaims(`${b64url(claims)}.whatever`)).toEqual(claims);
  });

  it("hub-domain-integrations-037 an empty ecosystemId decodes to null", () => {
    expect(decodeOAuthStateClaims(`${b64url({ ...claims, ecosystemId: "" })}.sig`)).toBeNull();
  });

  it("hub-domain-integrations-038 the signature is never verified", () => {
    expect(decodeOAuthStateClaims(`${b64url(claims)}.not-a-valid-signature`)).toEqual(claims);
  });

  it("hub-domain-integrations-039 a state exactly at the widened upper bound is fresh", () => {
    expect(isOAuthStateFresh({ iat: 0 }, 630000)).toBe(true);
  });

  it("hub-domain-integrations-040 a state one millisecond past the widened upper bound is stale", () => {
    expect(isOAuthStateFresh({ iat: 0 }, 630001)).toBe(false);
  });

  it("hub-domain-integrations-041 the future-skew lower bound is -90000 ms inclusive", () => {
    expect(isOAuthStateFresh({ iat: 100000 }, 10000)).toBe(true);
    expect(isOAuthStateFresh({ iat: 100000 }, 9999)).toBe(false);
  });

  it("hub-domain-integrations-042 every dynamic identifier is URL-encoded", async () => {
    respondWith({ deleted: true });
    await integrationsApi.disconnect("a/b");
    expect(urlAt(0)).toBe(`${BASE}/connections/a%2Fb`);
  });

  it("hub-domain-integrations-043 nothing is cached: each call is its own request", async () => {
    await integrationsApi.listProviders();
    await integrationsApi.listProviders();
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it("hub-domain-integrations-044 a non-404 failure propagates rather than becoming null", async () => {
    respondOnce({ error: { message: "boom" } }, 500);
    const err = await integrationsApi.getProviderConfig("eco-1", "github").catch((e) => e);
    expect(err).toBeInstanceOf(Error);
    expect(err.status).toBe(500);
  });

  it("hub-domain-integrations-045 secrets are write-only: only hasSecret reaches the caller", async () => {
    respondWith(v1List([configWire({ client_secret: "leaky" })]));
    const rows = await integrationsApi.listProviderConfigs("eco-1");
    expect(rows[0]).not.toHaveProperty("clientSecret");
    expect(rows[0]).not.toHaveProperty("client_secret");
    expect(typeof rows[0]!.hasSecret).toBe("boolean");
  });

  it("hub-domain-integrations-046 a 403 for a foreign ecosystem propagates with its status", async () => {
    respondOnce({ error: { message: "forbidden" } }, 403);
    const err = await integrationsApi.listConnections("eco-2").catch((e) => e);
    expect(err.status).toBe(403);
  });

  it.skip("hub-domain-integrations-047 the 401 refresh-and-retry waterfall belongs to the shared authedFetch in @adh-sdk/auth, not this client", () => {});
});
