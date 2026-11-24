"use client";

// CLIENT AUTH for one ecosystem and for one application: how the ecosystem's customers sign in
// to the developer's own apps (adhbackend/docs/designs/client-auth.md). There is one policy
// per ecosystem (Users ▸ Authentication), and it governs every sign-in. An application may have
// a login registration of its own, shaped by its platform (web or native).
//
//   GET  /api/v1/ecosystems/:id?include[]=client_auth     → EcosystemClientAuth
//   POST /api/v1/ecosystems/:id   {client_auth: {...}}    (update)
//   GET  /api/v1/applications/:id?include[]=client_auth   → ApplicationClientAuth
//   POST /api/v1/applications/:id {client_auth: {...}}    (update)
//
// An update sends only the keys it changes, and `registration: null` removes a login registration.
// The wire types are hand-written, for the reason feature-flags.ts states.

import { authedJson, withV1Query } from "../http";
import { compact, enc } from "../client-helpers";
import { authSettingsPatchToWire, toAuthSettings, type AuthSettings } from "../ecosystems/ecosystems";
import type { AuthSettingsWire } from "../ecosystems/wire";

/** The sign-in policy. It has the same shape as the ecosystem's auth settings. */
export type ClientAuthPolicy = AuthSettings;

/** A LOGIN REGISTRATION: the OIDC client an app signs its customers in through. The server
 *  assigns the client id. */
export interface LoginRegistration {
  clientId: string;
  allowedReturnOrigins: string[];
  redirectUris: string[];
}

export type LoginRegistrationInput = Omit<LoginRegistration, "clientId">;

/** An OAuth provider the platform has configured, which an ecosystem may switch on or off. */
export interface AuthProviderChoice {
  slug: string;
  name: string;
}

export interface EcosystemClientAuth {
  settings: ClientAuthPolicy;
  registration: LoginRegistration | null;
  providers: AuthProviderChoice[];
}

export interface EcosystemClientAuthUpdate {
  settings?: Partial<ClientAuthPolicy>;
  registration?: LoginRegistrationInput | null;
}

/**
 * What an application is, for signing in. Both sign in as public PKCE clients; the platform
 * decides what their registration accepts. A web app redirects to https (or http on a loopback
 * host) and may list return origins; a native app may also redirect to a custom scheme, and has
 * no return origins. Matches the backend `applications_platform_chk`.
 */
export type ApplicationPlatform = "web" | "native";

export const APPLICATION_PLATFORMS: readonly ApplicationPlatform[] = ["web", "native"];

export interface ApplicationClientAuth {
  /** Set on the application itself (its settings), not here. */
  platform: ApplicationPlatform;
  /** null means the application has no registration of its own and signs in through the
   *  ecosystem's. */
  registration: LoginRegistration | null;
}

export interface ApplicationClientAuthUpdate {
  registration: LoginRegistrationInput | null;
}

const ecosystemPath = (ecosystemId: string) => `/api/v1/ecosystems/${enc(ecosystemId)}`;
const applicationPath = (appId: string) => `/api/v1/applications/${enc(appId)}`;

interface RegistrationWire {
  client_id: string;
  allowed_return_origins: string[];
  redirect_uris: string[];
}
interface EcosystemClientAuthWire {
  settings: AuthSettingsWire;
  registration: RegistrationWire | null;
  providers: AuthProviderChoice[];
}
interface ApplicationClientAuthWire {
  platform: ApplicationPlatform;
  registration: RegistrationWire | null;
}

const toRegistration = (w: RegistrationWire | null): LoginRegistration | null =>
  w
    ? {
        clientId: w.client_id,
        allowedReturnOrigins: w.allowed_return_origins,
        redirectUris: w.redirect_uris,
      }
    : null;

const registrationToWire = (r: LoginRegistrationInput | null) =>
  r === null
    ? null
    : { allowed_return_origins: r.allowedReturnOrigins, redirect_uris: r.redirectUris };

const toEcosystemClientAuth = (w: EcosystemClientAuthWire): EcosystemClientAuth => ({
  settings: toAuthSettings(w.settings),
  registration: toRegistration(w.registration),
  providers: w.providers,
});

const toApplicationClientAuth = (w: ApplicationClientAuthWire): ApplicationClientAuth => ({
  platform: w.platform,
  registration: toRegistration(w.registration),
});

export const clientAuthApi = {
  /** The ecosystem's settings, its login registration, and the providers it can switch on. */
  async ecosystem(ecosystemId: string): Promise<EcosystemClientAuth> {
    const eco = await authedJson<{ client_auth: EcosystemClientAuthWire }>(
      withV1Query(ecosystemPath(ecosystemId), { "include[]": ["client_auth"] }),
    );
    return toEcosystemClientAuth(eco.client_auth);
  },

  /** `compact` drops the keys left undefined but keeps an explicit `registration: null`. */
  async updateEcosystem(
    ecosystemId: string,
    update: EcosystemClientAuthUpdate,
  ): Promise<EcosystemClientAuth> {
    const eco = await authedJson<{ client_auth: EcosystemClientAuthWire }>(
      ecosystemPath(ecosystemId),
      {
        method: "POST",
        body: JSON.stringify({
          client_auth: compact({
            settings: update.settings ? authSettingsPatchToWire(update.settings) : undefined,
            registration:
              update.registration === undefined ? undefined : registrationToWire(update.registration),
          }),
        }),
      },
    );
    return toEcosystemClientAuth(eco.client_auth);
  },

  async application(appId: string): Promise<ApplicationClientAuth> {
    const app = await authedJson<{ client_auth: ApplicationClientAuthWire }>(
      withV1Query(applicationPath(appId), { "include[]": ["client_auth"] }),
    );
    return toApplicationClientAuth(app.client_auth);
  },

  async updateApplication(
    appId: string,
    update: ApplicationClientAuthUpdate,
  ): Promise<ApplicationClientAuth> {
    const app = await authedJson<{ client_auth: ApplicationClientAuthWire }>(applicationPath(appId), {
      method: "POST",
      body: JSON.stringify({ client_auth: { registration: registrationToWire(update.registration) } }),
    });
    return toApplicationClientAuth(app.client_auth);
  },
};
