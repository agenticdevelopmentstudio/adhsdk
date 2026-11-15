import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { invitationsApi } from "../invitations";

function jsonResponse(status: number, body?: unknown): Response {
  return new Response(body === undefined ? null : JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

const fetchMock = vi.fn();

beforeEach(() => {
  fetchMock.mockReset();
  vi.stubGlobal("fetch", fetchMock);
});
afterEach(() => {
  vi.unstubAllGlobals();
});

describe("invitationsApi (conformance vectors 020-024; 001-019 are covered by the Apple tests)", () => {
  it("invitations-020 preview folds a non-2xx response into the invalid state", async () => {
    fetchMock.mockResolvedValue(jsonResponse(404, { error: "nope" }));
    await expect(invitationsApi.preview("tok en")).resolves.toEqual({
      state: "invalid",
      ecosystemName: null,
      maskedDestination: null,
    });
    expect(fetchMock).toHaveBeenCalledWith("/api/v1/invitations/preview?token=tok%20en", { cache: "no-store" });
  });

  it("invitations-021 preview rejects when fetch itself rejects", async () => {
    const offline = new TypeError("Failed to fetch");
    fetchMock.mockRejectedValue(offline);
    await expect(invitationsApi.preview("t")).rejects.toBe(offline);
  });

  it("invitations-022 verify throws the raw status code as the message", async () => {
    fetchMock.mockResolvedValue(jsonResponse(410, { error: "expired" }));
    await expect(invitationsApi.verify("123456")).rejects.toThrow(new Error("410"));
    const [, init] = fetchMock.mock.calls[0]!;
    expect(init.method).toBe("POST");
    expect(JSON.parse(init.body)).toEqual({ code: "123456" });
  });

  const input = { email: "a@x.io", password: "pw", name: "A", invite: "tok" };

  it("invitations-023 registerWithInvite falls back to the status template", async () => {
    fetchMock.mockResolvedValue(jsonResponse(403, { unrelated: true }));
    await expect(invitationsApi.registerWithInvite(input)).rejects.toThrow(new Error("Registration failed (403)"));
    expect(JSON.parse(fetchMock.mock.calls[0]![1].body)).toEqual(input);
  });

  it("invitations-024 registerWithInvite surfaces the server's error message", async () => {
    fetchMock.mockResolvedValue(jsonResponse(409, { error: "Email already registered" }));
    await expect(invitationsApi.registerWithInvite(input)).rejects.toThrow(new Error("Email already registered"));
  });
});
