// Unit tests for fetchHostedLoginContext: the one server-side call the hosted OIDC
// login page (HostedLogin.tsx) makes before rendering. It must NEVER throw — a network
// error or a non-2xx both fall back to `null`, which the page reads as "render today's
// plain, realm-agnostic form".
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { fetchHostedLoginContext } from "../loginContext";

const BACKEND = "http://backend.test";

const CUSTOMER_CONTEXT = {
  realm: "customer" as const,
  ecosystemId: "eco-acme",
  clientSlug: "acme",
  clientName: "Acme",
  ecosystemName: "Acme",
  loginEnabled: true,
  passwordEnabled: true,
  signupMode: "open" as const,
  providers: [{ slug: "github", name: "GitHub" }],
};

describe("fetchHostedLoginContext", () => {
  beforeEach(() => {
    vi.stubGlobal("fetch", vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("fetches the backend's login/context with the challenge, uncached", async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => CUSTOMER_CONTEXT,
    });
    vi.stubGlobal("fetch", fetchMock);

    const result = await fetchHostedLoginContext(BACKEND, "chal-123");

    // `signal` is a fresh AbortSignal.timeout() instance each call, so it can't be
    // compared with a plain toHaveBeenCalledWith deep-equality check — assert the
    // pieces that matter individually instead.
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe(
      "http://backend.test/auth/oidc/login/context?login_challenge=chal-123",
    );
    expect(init.cache).toBe("no-store");
    expect(init.signal).toBeInstanceOf(AbortSignal);
    expect(result).toEqual(CUSTOMER_CONTEXT);
  });

  it("builds the URL from the backend it is given", async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, json: async () => CUSTOMER_CONTEXT });
    vi.stubGlobal("fetch", fetchMock);

    await fetchHostedLoginContext("https://api.other.test", "chal-123");

    const [url] = fetchMock.mock.calls[0] as [string, unknown];
    expect(url).toBe(
      "https://api.other.test/auth/oidc/login/context?login_challenge=chal-123",
    );
  });

  it("URL-encodes the challenge", async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, json: async () => CUSTOMER_CONTEXT });
    vi.stubGlobal("fetch", fetchMock);

    await fetchHostedLoginContext(BACKEND, "chal with spaces&stuff");

    const [url] = fetchMock.mock.calls[0] as [string, unknown];
    expect(url).toBe(
      "http://backend.test/auth/oidc/login/context?login_challenge=chal%20with%20spaces%26stuff",
    );
  });

  it("passes the customer realm's ecosystemId through", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, json: async () => CUSTOMER_CONTEXT }),
    );

    const result = await fetchHostedLoginContext(BACKEND, "chal-123");

    expect(result?.ecosystemId).toBe("eco-acme");
  });

  it("returns null on a non-2xx response, never throwing", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, json: async () => ({ error: "nope" }) }),
    );

    await expect(fetchHostedLoginContext(BACKEND, "chal-123")).resolves.toBeNull();
  });

  it("returns null on a network error, never throwing", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("ECONNREFUSED")));

    await expect(fetchHostedLoginContext(BACKEND, "chal-123")).resolves.toBeNull();
  });

  it("returns null when the body isn't valid JSON, never throwing", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => {
          throw new SyntaxError("Unexpected token");
        },
      }),
    );

    await expect(fetchHostedLoginContext(BACKEND, "chal-123")).resolves.toBeNull();
  });

  it("passes through a hub-realm answer (no providers, null clientSlug and ecosystemId) as-is", async () => {
    const hubContext = {
      realm: "hub" as const,
      ecosystemId: null,
      clientSlug: null,
      clientName: null,
      ecosystemName: null,
      loginEnabled: true,
      passwordEnabled: true,
      signupMode: "closed" as const,
      providers: [],
    };
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: true, json: async () => hubContext }));

    await expect(fetchHostedLoginContext(BACKEND, "chal-123")).resolves.toEqual(hubContext);
  });

  // A hung backend (accepts the connection, never answers) must not hang the whole
  // login page — the 3s AbortSignal.timeout() is what bounds that. The mock fetch
  // here never resolves on its own; it only rejects once the real signal aborts,
  // exercising the actual timeout wired into fetchHostedLoginContext (not a fake one).
  it(
    "returns null when the fetch never resolves until the timeout aborts it",
    async () => {
      vi.stubGlobal(
        "fetch",
        vi.fn().mockImplementation((_url: string, init?: { signal?: AbortSignal }) => {
          return new Promise((_resolve, reject) => {
            init?.signal?.addEventListener("abort", () => {
              reject(new DOMException("The operation was aborted.", "TimeoutError"));
            });
          });
        }),
      );

      await expect(fetchHostedLoginContext(BACKEND, "chal-123")).resolves.toBeNull();
    },
    6000,
  );
});
