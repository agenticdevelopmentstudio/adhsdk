// `ecosystemUsersApi.update` sends an empty email / external id as NULL, never as ''. The
// (ecosystem_id, email) and (ecosystem_id, external_id) unique indexes admit any number of NULLs
// but a single '', and `toUser` reads NULL back as "" — so a form save that echoed "" turned every
// SSO user without an email into a '' and the second one saved in an ecosystem got a 409.
import { beforeEach, describe, expect, it, vi } from "vitest";

const authedJson = vi.fn();
const listAllV1 = vi.fn();
vi.mock("@adh-sdk/auth/client", () => ({
  authedJson: (...args: unknown[]) => authedJson(...args),
  listAllV1: (...args: unknown[]) => listAllV1(...args),
  unixToIso: (n: number) => new Date(n * 1000).toISOString(),
  withV1Query: (u: string, params: Record<string, string>) =>
    `${u}?${new URLSearchParams(params).toString()}`,
}));

import { ecosystemUsersApi } from "../customers";

const ROW = {
  id: "u1",
  ecosystem_id: "e1",
  external_id: null,
  email: null,
  display_name: "Ada",
  slug: "ada",
  avatar_url: "",
  created: 1_700_000_000,
  updated: 1_700_000_060,
};

/** The JSON body of the one POST the call made. */
function sentBody(): Record<string, unknown> {
  const [, init] = authedJson.mock.calls[0] as [string, RequestInit];
  return JSON.parse(init.body as string) as Record<string, unknown>;
}

beforeEach(() => {
  authedJson.mockReset();
  listAllV1.mockReset();
  authedJson.mockResolvedValue(ROW);
});

describe("ecosystemUsersApi.update", () => {
  // NULL, not '': the unique indexes admit any number of NULLs but a single ''.
  it("sends an empty email and external id as NULL", async () => {
    await ecosystemUsersApi.update("u1", {
      email: "",
      displayName: "Ada Lovelace",
      externalId: "",
      slug: "ada",
      avatarUrl: "",
    });
    expect(authedJson).toHaveBeenCalledWith(
      "/api/v1/customers/u1",
      expect.objectContaining({ method: "POST" }),
    );
    const body = sentBody();
    expect(body.email).toBeNull();
    expect(body.external_id).toBeNull();
  });

  it("leaves the NOT NULL columns as '' — null there would be refused", async () => {
    await ecosystemUsersApi.update("u1", { email: "", avatarUrl: "", slug: "ada" });
    const body = sentBody();
    expect(body.avatar_url).toBe("");
    expect(body.slug).toBe("ada");
  });

  it("sends a real address and external id unchanged", async () => {
    await ecosystemUsersApi.update("u1", { email: "ada@example.com", externalId: "sso|42" });
    const body = sentBody();
    expect(body.email).toBe("ada@example.com");
    expect(body.external_id).toBe("sso|42");
  });

  it("still omits a field the caller did not send", async () => {
    await ecosystemUsersApi.update("u1", { displayName: "Ada" });
    const body = sentBody();
    // `compact` drops undefined, so an absent field stays absent — NOT null, which would clear it.
    expect("email" in body).toBe(false);
    expect("external_id" in body).toBe(false);
  });

  it("reads a NULL email back as the form's empty string", async () => {
    const user = await ecosystemUsersApi.update("u1", { displayName: "Ada" });
    expect(user.email).toBe("");
    expect(user.externalId).toBe("");
  });
});

describe("ecosystemUsersApi.list", () => {
  // The hub names an ecosystem by its rdid while a customer row stores the uuid, so a filter in the
  // browser matched nothing and every Users pane read "No users yet." The server filters, and it
  // resolves the rdid itself — the client sends the id exactly as the pane holds it.
  it("asks the server for the ecosystem's rows, by the id the pane holds", async () => {
    listAllV1.mockResolvedValue([ROW]);
    const users = await ecosystemUsersApi.list("ecosystem.ads.agenticdeveloperhub");
    expect(listAllV1).toHaveBeenCalledWith(
      "/api/v1/customers?ecosystem_id=ecosystem.ads.agenticdeveloperhub",
    );
    // A row whose stored ecosystemId is a uuid is NOT dropped by a second, client-side comparison.
    expect(users.map((u) => u.id)).toEqual(["u1"]);
  });

  it("sends no filter when no ecosystem is selected", async () => {
    listAllV1.mockResolvedValue([]);
    await ecosystemUsersApi.list(undefined);
    expect(listAllV1).toHaveBeenCalledWith("/api/v1/customers");
  });
});
