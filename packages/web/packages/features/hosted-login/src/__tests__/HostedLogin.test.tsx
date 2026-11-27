// @vitest-environment node
// HostedLogin is an async server component: each test awaits it and renders the element it
// resolves to with react-dom/server, as Next does on the server. `fetch` is stubbed to throw so a
// test that passes a context (or never reaches the context read) proves no backend call is made.
import { renderToStaticMarkup } from "react-dom/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { HostedLogin, MissingChallengeCard } from "../HostedLogin";
import type { HostedLoginContext } from "../loginContext";

const BACKEND = "http://backend.test";

const CUSTOMER: HostedLoginContext = {
  realm: "customer",
  ecosystemId: "eco-acme",
  clientSlug: "acme",
  clientName: "Acme",
  ecosystemName: "Acme",
  loginEnabled: true,
  passwordEnabled: true,
  signupMode: "open",
  providers: [],
};

let fetchMock: ReturnType<typeof vi.fn>;

beforeEach(() => {
  fetchMock = vi.fn(() => {
    throw new Error("fetch must not be called");
  });
  vi.stubGlobal("fetch", fetchMock);
});

afterEach(() => {
  vi.unstubAllGlobals();
});

async function render(props: Parameters<typeof HostedLogin>[0]): Promise<string> {
  return renderToStaticMarkup(await HostedLogin(props));
}

describe("HostedLogin", () => {
  it("renders the missing-challenge card when there is no challenge", async () => {
    const html = await render({ backendUrl: BACKEND, params: {} });

    expect(html).toBe(renderToStaticMarkup(<MissingChallengeCard />));
    expect(html).toContain("This sign-in link is missing or has expired.");
    expect(html).not.toContain("<form");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("renders the MFA form posting to the backend's /auth/oidc/login/mfa", async () => {
    const html = await render({
      backendUrl: BACKEND,
      params: { login_challenge: "chal-1", mfa_token: "mfa-tok", mfa: "totp,sms" },
    });

    expect(html).toContain("Two-factor authentication");
    expect(html).toContain(`action="${BACKEND}/auth/oidc/login/mfa"`);
    expect(html).toContain('name="mfa_token" value="mfa-tok"');
    expect(html).toContain('value="totp"');
    expect(html).toContain('value="sms"');
    // sms is offered, so the resend form is there too.
    expect(html).toContain(`action="${BACKEND}/auth/oidc/login/mfa/send"`);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("renders the sign-up code form for verify=1", async () => {
    const html = await render({
      backendUrl: BACKEND,
      params: { login_challenge: "chal-1", verify: "1", verify_token: "v-tok", code_sent: "1" },
    });

    expect(html).toContain("Check your email");
    expect(html).toContain(`action="${BACKEND}/auth/oidc/signup/verify"`);
    expect(html).toContain(`action="${BACKEND}/auth/oidc/signup/verify/send"`);
    expect(html).toContain('name="verify_token" value="v-tok"');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("renders the disabled card for a passed customer context with loginEnabled false", async () => {
    const html = await render({
      backendUrl: BACKEND,
      params: { login_challenge: "chal-1" },
      context: { ...CUSTOMER, loginEnabled: false },
    });

    expect(html).toContain("Sign in to Acme");
    expect(html).toContain("Sign-in is currently limited to administrators.");
    expect(html).not.toContain("<form");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("renders the sign-up form for mode=signup with an open customer context", async () => {
    const html = await render({
      backendUrl: BACKEND,
      params: { login_challenge: "chal-1", mode: "signup" },
      context: CUSTOMER,
    });

    expect(html).toContain("Create your Acme account");
    expect(html).toContain(`action="${BACKEND}/auth/oidc/signup"`);
    expect(html).toContain('href="?login_challenge=chal-1"');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("renders the sign-in form and a provider link for a customer context with providers", async () => {
    const html = await render({
      backendUrl: BACKEND,
      params: { login_challenge: "chal-1" },
      context: { ...CUSTOMER, providers: [{ slug: "github", name: "GitHub" }] },
    });

    expect(html).toContain("Sign in to Acme");
    expect(html).toContain(`action="${BACKEND}/auth/oidc/login"`);
    expect(html).toContain(
      `href="${BACKEND}/oauth/signin/start?clientId=acme&amp;providerId=github&amp;login_challenge=chal-1"`,
    );
    expect(html).toContain("Continue with GitHub");
    expect(html).toContain("Create account");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("renders the plain form for a passed null context without fetching", async () => {
    const html = await render({
      backendUrl: BACKEND,
      params: { login_challenge: "chal-1" },
      context: null,
    });

    expect(html).toContain(">Sign in</h1>");
    expect(html).toContain(`action="${BACKEND}/auth/oidc/login"`);
    expect(html).not.toContain("Create account");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("reads the context from the backend it is given when none is passed", async () => {
    fetchMock = vi.fn().mockResolvedValue({ ok: true, json: async () => CUSTOMER });
    vi.stubGlobal("fetch", fetchMock);

    const html = await render({ backendUrl: BACKEND, params: { login_challenge: "chal-1" } });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url] = fetchMock.mock.calls[0] as [string, unknown];
    expect(url).toBe(`${BACKEND}/auth/oidc/login/context?login_challenge=chal-1`);
    expect(html).toContain("Sign in to Acme");
  });

  it.each(["__proto__", "constructor", "toString"])(
    "falls back to the generic message for ?error=%s",
    async (error) => {
      const html = await render({
        backendUrl: BACKEND,
        params: { login_challenge: "chal-1", error },
        context: null,
      });

      expect(html).toContain("Sign in failed. Please try again.");
    },
  );

  it("offers no inherited Object.prototype key as a code method", async () => {
    const html = await render({
      backendUrl: BACKEND,
      params: { login_challenge: "chal-1", mfa_token: "mfa-tok", mfa: "__proto__,constructor" },
    });

    expect(html).not.toContain('value="__proto__"');
    expect(html).not.toContain('value="constructor"');
    expect(html).toContain("Your account uses a passkey.");
  });

  it("offers each repeated code method once, in first-seen order", async () => {
    const html = await render({
      backendUrl: BACKEND,
      params: { login_challenge: "chal-1", mfa_token: "mfa-tok", mfa: "sms,totp,sms,totp" },
    });

    expect(html.match(/value="totp"/g)).toHaveLength(1);
    expect(html.match(/value="sms"/g)).toHaveLength(1);
    expect(html.indexOf('value="sms"')).toBeLessThan(html.indexOf('value="totp"'));
  });
});
