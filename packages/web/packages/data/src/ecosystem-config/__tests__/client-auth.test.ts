// Recipe: adhsdk ecosystem-config, the web client-auth client (vector ecosystem-config-030).
import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
}));

import { clientAuthApi } from "../client-auth";
import { authedJson } from "../../http";

const mockedJson = vi.mocked(authedJson);

beforeEach(() => {
  mockedJson.mockReset();
});

/** The `client_auth` envelope the ecosystem route answers with. */
const envelope = (settingsExtra: Record<string, unknown>) => ({
  client_auth: {
    settings: {
      signup_mode: "invite_only",
      login_enabled: true,
      password_enabled: true,
      allowed_providers: null,
      ...settingsExtra,
    },
    registration: null,
    providers: [],
  },
});

describe("the login allow-list on the wire", () => {
  it("ecosystem-config-030: reads absent as null and [] as [], and sends a null patch rather than dropping the key", async () => {
    mockedJson.mockResolvedValueOnce(envelope({}));
    expect((await clientAuthApi.ecosystem("eco-1")).settings.loginAllowedEmails).toBeNull();

    mockedJson.mockResolvedValueOnce(envelope({ login_allowed_emails: [] }));
    expect((await clientAuthApi.ecosystem("eco-1")).settings.loginAllowedEmails).toEqual([]);

    mockedJson.mockResolvedValueOnce(envelope({}));
    await clientAuthApi.updateEcosystem("eco-1", { settings: { loginAllowedEmails: null } });
    const [url, init] = mockedJson.mock.calls[2] as [string, RequestInit];
    expect(url).toBe("/api/v1/ecosystems/eco-1");
    const body = JSON.parse(String(init.body)) as {
      client_auth: { settings: Record<string, unknown> };
    };
    expect(body.client_auth.settings).toHaveProperty("login_allowed_emails", null);
  });
});
